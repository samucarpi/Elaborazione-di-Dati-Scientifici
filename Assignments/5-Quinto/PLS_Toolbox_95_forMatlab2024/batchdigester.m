function [out,options] = batchdigester(data,options)
%BATCHDIGESTER Parse wafer or batch data into MPCA or Summary PCA form.
% Rearranges and optionally summarizes two-way dataset of batch or wafer
% data. Input DataSet must contain labels which identify different wafers
% or batches which should be split out of the data. Classes in DataSet are
% (optionally) used to split each time profile of the batch/wafer into
% steps which can then be selected for inclusion in the output. If input
% DataSet is of type='batch', then labels on individual batches are
% expanded and batches are concatenated such that they can be processed
% correctly by batchdigester.
%
% MPCA mode: If data is rearranged into MPCA data, each wafer/batch is
% arranged as one slab of a 3-way matrix. Each row is a time point and each
% column is one of the original variables. Only selected steps are included
% in the output.
%
% Summary PCA mode: If data is summarized into Summary PCA data, all time
% points for a given step in a given process are summarized using one or more
% statistics:
%     Mean
%     Standard Deviation
%     Minimum
%     Maximum
%     Range
%     Slope
%     Length (of step)
% The time profile for each original variable is summarized using the given
% statistic(s) and turned into a single variable (column) of the output
% data. If steps are used, this is repeated for each step segment (each
% creating a new, separate variable in the output). Each wafer/batch is
% thus a single row of the output data with all of the steps and original
% variables summarized as new variables. 
%
%Optional input (options) is a structure containing one or more of the
% following fields:
%   object : { 'batch' | 'wafer' } A string specifying the type of object
%                being digested. This is used for display ONLY. The same
%                algorithms are used in both cases but this option allows
%                customization of the wording in the user prompts.
%   stepclassname : A string specifying the name of the class which should
%                   be used to indicate steps in the process.
%    stepsdesired : A vector of steps which should be included in the
%                   digestion.
%       labelname : A string specifying the name of the label set which
%                   should be used to split data into batches/wafers.
%        nbatches : The number of equally-sized batches to split the data
%                   into. Used ONLY when labelname is 'fixed'. 
%   digestiontype : [ 'mpca' | 'spca' ] Specifies which digestion
%                    algorithm to use on the data. MPCA, or SPCA (=summary
%                    PCA)
%      statistics : A cell specifying the statistics to be used on the
%                    data. Used ONLY when digestiontype = 'spca';
%
% If sufficent information is provided in these options, the processing of
% data will be automatic and the user will not have to answer any
% responses in the GUIs. Otherwise, only prompts for missing information
% will be given. The options which can be used to re-process using a given
% digestion "recipe" will be returned as the second output to any digestion
% request.
%
%I/O: [out,options] = batchdigester(data,options);
%
%See also: BATCHFOLD, MPCA, PARAFAC

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 9/2006 

if nargin>0 & ischar(data)
  options = [];
  options.object = 'batch';
  options.stepclassname = '';
  options.stepsdesired = [];
  options.labelname = '';
  options.nbatches   = [];
  options.digestiontype = '';
  options.statistics = {};
  
  if nargout==0; evriio(mfilename,data,options); else; out = evriio(mfilename,data,options); end
  return; 
end

if nargin<2; options = []; end
options = reconopts(options,mfilename);
options.automatic = true;  %flag to indicate the user was NOT prompted for input and we do not need to save options

switch options.object
  case 'wafer'
    desc = {'wafer' 'wafers'};
  otherwise
    desc = {'batch' 'batches'};
end

out = [];
try

  phases = {
    [desc{1} ' Digester'] ''
    'stepselection' 'Select steps to analyze'
    'waferselection' ['Identify ' desc{2}]
    'choosemode' 'Select digestion mode'
    'choosestats' 'Choose summary statistics'
    'summarize' 'Process step data'
    'createoutput' 'Create output DataSet'
    };

  if nargin==0;
    data = lddlgpls('dataset','Choose Data to Process');
    if isempty(data);
      return
    end
  end

  if ~isdataset(data);
    data = dataset(data);
  end

  if strcmp(data.type,'batch');
    %batch DSO? convert to vertical standard DSO with appropriate labels
    bdata = data.data;
    %look for labels in that DSO which we can use to describe each batch
    bset = [];
    all_lbls = data.label(1,:);
    for set = 1:length(all_lbls);
      if length(unique(all_lbls{set},'rows'))==length(bdata)
        bset = set;
        break;
      end
    end
    %(only labels that make it here are ones that are long enough and
    %unique enough to identify each batch. If we don't have any, we'll need
    %to create some)
    if isempty(bset);
      for j=1:length(bdata);
        lbls{j} = sprintf('%s %i',desc{1},j);
      end
      lbls = char(lbls);
      all_lbls = [lbls all_lbls];  %put synthetic labels first
    else
      %make selected label set the first
      all_lbls = all_lbls([bset setdiff(1:length(all_lbls),bset)]);
    end

    %create unfolded DSO
    newdso = dataset(cat(1,bdata{:}));
    newdso = copydsfields(data,newdso,[2 2]);
        
    %Now, expand labels out into a cell array appropriate for the concatenated
    %batches
    for set=1:length(all_lbls);
      if isempty(all_lbls{set}); break; end
      lbls = {};
      for j=1:length(bdata);
        %first do necessary batch labels
        lbls = [lbls;repmat({all_lbls{set}(j,:)},size(bdata{j},1),1)];
      end
      newdso.label{1,set} = lbls;
    end
        
    %expand classes out into a cell array appropriate for the concatenated
    %batches
    all_classes = data.class(1,:);
    for set=1:length(all_classes);
      if isempty(all_classes{set}); break; end
      cls = [];
      for j=1:length(bdata);
        %first do necessary batch labels
        cls = [cls all_classes{set}(j)*ones(1,size(bdata{j},1))];
      end
      newdso.classlookup{1,set} = data.classlookup{1,set};
      newdso.class{1,set} = cls;
    end

    %overwrite Data with new unfolded DSO
    data = newdso;
    
    %now, look for a variable which can be used as a step variable
    %get each variable name
    names = str2cell(data.label{2});
    init = [];
    for j=1:length(names)
      if isempty(names{j})
        names{j} = sprintf('Variable %i',j);
      elseif strfind(lower(names{j}),'step') & isempty(init)
        init = j;
      end
    end
    names{end+1} = 'None / Use all data';
    if isempty(init);
      init = 1;
    end

    if ~isempty(options.stepclassname)
      if strcmp(options.stepclassname,'none');
        classindex = length(names);
      else
        classindex = strmatch(options.stepclassname,names);
        if isempty(classindex)
          error('Specified class name does not exist in data')
          return
        end
      end
    else
      %ask user for which to use
      options.automatic = false;
      [classindex,OK] = listdlg('PromptString','Which variable gives step number?',...
        'SelectionMode','single',...
        'InitialValue',init,...
        'ListString',names);
      if isempty(classindex) | ~OK
        progress
        return
      end
    end

    if classindex>0 && classindex<=size(data,2);
      %valid column selected? take that variable and make it a class
      data.class{1} = data.data(:,classindex);
      data.classname{1} = strtrim(data.label{2}(classindex,:));
      data = delsamps(data,classindex,2,2);  %hard delete that column
      options.stepclassname = names{classindex};  %store name for automatic application later
    end

  end
    
  
  %---------------------------------------------
  progress(phases,'stepselection');
  
  classindex = [];
  %find all non-empty classes on rows
  validclass = ones(1,size(data.class,2));
  for j=1:size(data.class,2);
    validclass(j) = ~isempty(data.class{1,j});
  end
  validclass = find(validclass);
  
  if ~isempty(validclass)
    %choose which step to use
    
    %get each class name
    names = data.classname(1,validclass);
    init = [];
    for j=1:length(names)
      if isempty(names{j})
        names{j} = sprintf('Class %i',j);
      elseif strfind(lower(names{j}),'step') & isempty(init)
        init = j;
      end
    end
    names{end+1} = 'None / Use all data';
    if isempty(init);
      init = 1;
    end
    
    if ~isempty(options.stepclassname)
      if strcmp(options.stepclassname,'none');
        classindex = length(names);
      else
        classindex = strmatch(options.stepclassname,names);
        if isempty(classindex)
          error('Specified class name does not exist in data')
          return
        end
      end
    else
      %ask user for which to use
      options.automatic = false;
      [classindex,OK] = listdlg('PromptString','Which class gives step number?',...
        'SelectionMode','single',...
        'InitialValue',init,...
        'ListString',names);
      if isempty(classindex) | ~OK
        progress
        return
      end
    end
    if classindex < length(names)
      %choose the indicated class
      classindex = validclass(classindex);
      steps = data.class{1,classindex};
      data.class{1,classindex} = [];
    else
      %"none" - consider all samples the same step number
      steps = ones(1,size(data,1));
    end
    options.stepclassname = names{classindex};
  else
    %no classes at all? just use all data
    steps = ones(1,size(data,1));
    options.stepclassname = 'none';
  end

  %given those step numbers...
  uniquesteps = unique(steps);

  %ask user for which to use (if more than one present)
  steplist = num2str(uniquesteps(:));
  if size(steplist,1)==1;
    stepsdesired = uniquesteps;
  else
    if ~isempty(options.stepsdesired)
      stepsdesired = intersect(options.stepsdesired,uniquesteps);
    else
      options.automatic = false;
      [desiredindex,OK] = listdlg('PromptString','Select step(s) to summarize:',...
        'SelectionMode','multiple',...
        'InitialValue',[1:length(uniquesteps)],...
        'ListString',steplist);
      if ~OK
        progress
        return
      end
      stepsdesired = uniquesteps(desiredindex);
    end
  end
  options.stepsdesired = stepsdesired;
  if isempty(stepsdesired);
    progress
    error('No steps selected');
  end

  %---------------------------------------------
  progress(phases,'waferselection');
  %ask how we should parse data into wafers
  labels = data.label;
  use = ~cellfun('isempty',labels(1,:));
  if any(use)
    %have at least one label
    if sum(use)>1;
      use = find(use);
      lbls = [data.labelname(1,use)];
      for j=1:length(use)
        lbls = [lbls {['* Change in ' data.labelname{1,use(j)}]}];
      end
      lbls = [lbls {['* Use Step restarts as "new-' desc{1} '" trigger']}];
      lbls = [lbls {['* Specify a number of equal-length ' desc{2}]}];
      
      if ~isempty(options.labelname)
        useindex = strmatch(options.labelname,lbls);
      else
        options.automatic = false;
        useindex = listdlg('PromptString',['Which label identifies ' desc{2} '?'],...
          'SelectionMode','single',...
          'InitialValue',length(lbls)-1,...
          'ListSize',[240 200],...
          'ListString',lbls);
        if isempty(useindex)
          progress
          return
        end
      end
      if useindex<=length(use);
        waferlbl = labels{1,use(useindex)};
      elseif useindex<length(lbls)-1;
        %user asked for change in some label
        waferlbl = labels{1,use(useindex-length(use))};
        waferlbl = any(diff(double(waferlbl)),2);
        waferlbl = [0;cumsum(waferlbl)]+1;
      elseif useindex==length(lbls)-1
        %user asked to use step restarts
        waferlbl = [0;0;cumsum(diff(steps(1:end-1)')<0)]+1;
      else
        waferlbl = [];  %prompt user for number of batches
      end
      options.labelname = lbls{useindex};
    else
      waferlbl = labels{1,use};
      options.labelname = data.labelname(1,use);
    end
  else
    %no labels at all... skip this prompt to next
    waferlbl = [];
    options.labelname = ['* Specify a number of equal-length ' desc{2}];
  end
  if isempty(waferlbl)
    %no labels? ask user to specify the number of equal-sized batches
    if isprime(size(data,1))
      %unless it is a prime number - i.e. it MUST be a single batch
      nbatches = 1;
    elseif ~isempty(options.nbatches)
      %specified in options? use that
      nbatches = options.nbatches;
      if mod(size(data,1),nbatches)~=0
        progress
        error(['Unable to split data into specified number of ' desc{2}]);
      end
    else
      %prompt user
      options.automatic = false;
      ans = evriquestdlg(['No labels could be found to split data into ' desc{2} '. Do you want to specify the nubmer of (fixed-length) ' desc{2} ' or cancel the operation?'],'No Labels Located','Specify','Cancel','Specify');
      if strcmp(ans,'Cancel')
        progress
        return
      end
      nbatches = [];
      while isempty(nbatches)
        nbatches = inputdlg({['Number of ' desc{2} ' in data?']},['Specify ' desc{2}]);
        if isempty(nbatches)
          progress
          return
        end
        nbatches = str2num(nbatches{1});
        if ~isempty(nbatches) && mod(size(data,1),nbatches)~=0
          erdlgpls(['Data can not be split into that number of ' desc{2} '. Please try again.'],'Indivisible Size');
          nbatches = [];  %force re-try
        end
      end
    end
    %create labels which will split as desired
    waferlbl = num2str(encodemethod(size(data,1),'con',nbatches));
    waferlbl = [repmat([desc{1} ' '],size(waferlbl,1),1) waferlbl];
    options.nbatches = nbatches;
  end
  %wafergroups identifies which rows belong to which wafer
  [waferIDs,lblindex,wafergroups] = unique(waferlbl,'rows');
  switch class(waferIDs)
    case 'char'
      waferIDs = str2cell(waferIDs);
    case 'cell'
      %all set
    otherwise
      waferIDs = str2cell(num2str(waferIDs));
  end
  %reorder waferIDs to match original data
  [what,order] = sort(lblindex);
  waferIDs = waferIDs(order);
  gr(order) = 1:length(order);
  if length(order) > 1                % skip in 1 case because wafergroups gets transposed then
    wafergroups = gr(wafergroups)';   % but there is no net transposing if length(gr) > 1 
  end                                 % (and length(gr) = length(order))
  
  %-------------------------------------------------------
  progress(phases,'choosemode');

  if ~isempty(options.digestiontype)
    mode = options.digestiontype;
  else
    options.automatic = false;
    mode = evriquestdlg('Which type of digestion do you want to perform?','Digestion Mode','Summary (PCA)','Raw Data (MPCA)','Summary (PCA)');
  end

  switch mode
    case {'Raw Data (MPCA)' 'mpca'}
      options.digestiontype = 'mpca';
      out = creatempca(data,steps,waferIDs,wafergroups,stepsdesired,phases,options,desc);

    case {'Summary (PCA)' 'spca'}
      options.digestiontype = 'spca';
      [out,options] = createpca(data,steps,waferIDs,wafergroups,stepsdesired,phases,options,desc);

  end

  if nargout==0;
    svdlgpls(out,'Save digested data as...');
    if ~options.automatic
      options = rmfield(options,'automatic');
      svdlgpls(options,'Save digestion options as...');
    end
  end
  if isfield(options,'automatic');
    options = rmfield(options,'automatic');
  end
  
catch
  erdlgpls(lasterr,[desc{1} ' Digester']);
end
progress;

if nargout==0;
  clear out;
end

%=============================================================
function out = creatempca(data,steps,waferIDs,wafergroups,stepsdesired,phases,options,desc)

out = [];

phases = {
  [desc{1} ' Digester'] ''
  'stepselection' 'Select steps to analyze'
  'waferselection' ['Identify ' desc{2}]
  'choosemode' 'Select Digestion Mode'
  'getsteps' 'Determine step lengths'
  'summarize' 'Process step data'
  'createoutput' 'Create output DataSet'
  };

%---------------------------------------------
progress(phases,'getsteps');

label = {{};{};{}};
labelname = {'';'Signal ID';[desc{1} ' ID']};
classes = {[];[];[]};
classname = {'Step';'';''};

wafervals     = unique(wafergroups);

%create labels for columns
label{2,1} = data.label{2};
if isempty(label{2,1})
  label{2,1} = str2cell(sprintf('Variable %i\n',1:size(data,2)));
end

%create include for columns
varincl = logical(zeros(1,size(data,2)));
varincl(data.include{2}) = true;

incl1 = zeros(size(data,1),1);
incl1(data.include{1}) = 1;

%[(time x step) x var x wafer]
%calculate the length of each step
inwafer = {};
stepsize = zeros(length(wafervals),length(stepsdesired));
for j=1:length(wafervals);
  %for each wafer...
  waferuse   = (wafergroups==wafervals(j)); %identify rows in this wafer
  inwafer{j} = find(incl1 & waferuse); %INCLUDED rows in this wafer

  %locate each requested step and determine length
  for stepindex = 1:length(stepsdesired);
    step = stepsdesired(stepindex);
    %figure out which items are in this step
    use = inwafer{j}(steps(inwafer{j})==step);
    stepsize(j,stepindex) = length(use);
  end
  if mod(j,10)==0
    progress(phases,'getsteps',j/length(wafervals));
  end

end
targetlength = median(stepsize);

%----------------------------------------------------------
progress(phases,'summarize');
%prep output and start cycling through wafers
out = zeros(sum(targetlength),size(data,2),length(wafervals));
oldpct = 0;
for j=1:length(wafervals);      %for each wafer...
  slab = [];   %each wafer will be built up in its own slab

  waferuse = (wafergroups==wafervals(j)); %identify rows in this wafer
  label{3,1}{j} = waferIDs{wafervals(j)};  %get a generic label for this wafer

  for setindex = 1:size(data.label,2);
    if ~isempty(data.label{1,setindex});
      %look for consistent labels for this set
      unq = data.label{1,setindex}(waferuse,:);
      if all(min(unq)==max(unq))
        unq = unq(1,:);
        label{3,setindex+1}{j,1} = unq;
      end
      labelname{3,setindex+1} = data.labelname{1,setindex};
    end
  end
  for setindex = 1:size(data.class,2);
    if ~isempty(data.class{1,setindex});
      %look for consistent classes for this set
      unq = unique(data.class{1,setindex}(waferuse));
      if length(unq)==1
        classes{3,setindex}(1,j) = unq;
      end
      classname{3,setindex} = data.classname{1,setindex};
    end
  end

  %locate each requested step and summarize
  for stepindex = 1:length(stepsdesired);
    step = stepsdesired(stepindex);

    %figure out which items are in this step
    use = inwafer{j}(steps(inwafer{j})==step);
    subdata = data.data(use,:);  %[time x var]

    %adjust subdata length to match target length for this step
    if size(subdata,1)~=targetlength(stepindex);
      if size(subdata,1)==0;  %does not have this step!
        subdata = zeros(2,size(subdata,2));
      end
      subdata = interp1(linspace(0,1,size(subdata,1)),subdata,linspace(0,1,targetlength(stepindex)));
    end

    slab = [slab;subdata];  %add as new columns to slab

    if j==1;
      %first wafer - develop class IDs for steps
      classes{1,1} = [classes{1,1} ones(1,targetlength(stepindex))*step];
    end

  end
  out(:,:,j) = slab;  %add to whole answer

  pct = j/length(wafervals);
  if floor(pct*100)>oldpct;
    progress(phases,'summarize',pct);
    oldpct = floor(pct*100);
  end

end

%---------------------------------------------
progress(phases,'createoutput');

%Result is matrix looking like this:
%v1                v2                v3
%Step1 Step2 Step3 Step1 Step2 Step3 Step1 Step2 Step3 ...

out = dataset(out);
out.name = data.name;

for m=1:size(label,1);
  toset = 0;
  for setind=1:size(label,2);
    if ~isempty(label{m,setind})
      toset = toset + 1;
      out.label{m,toset} = label{m,setind};
      out.labelname{m,toset} = char(labelname{m,setind});
    end
  end
end
for m=1:size(classes,1);
  toset = 0;
  for setind=1:size(classes,2);
    if ~isempty(classes{m,setind})
      toset = toset + 1;
      if length(classes{m,setind})<size(out,m);
        classes{m,setind}(size(out,m)) = 0;  %infill with zeros to appropriate length
      end
      out.class{m,toset} = classes{m,setind};
      out.classname{m,toset} = char(classname{m,setind});
    end
  end
end

%mark no-variance columns as "exclude" (as well as those excluded by user
%in source data)
sd = std(unfoldmw(out.data,2)');
out.include{2} = find(sd~=0 & ~isnan(sd) & varincl);

%======================================================================
function [out,options] = createpca(data,steps,waferIDs,wafergroups,stepsdesired,phases,options,desc)

out = [];

progress(phases,'choosestats');
statlist = {'Mean' 'Standard Deviation' 'Minimum' 'Maximum' 'Range' 'Slope' 'Length (of step)'};
statlistabbr = {'Mean' 'StdDev' 'Min' 'Max' 'Range' 'Slope'};

if ~isempty(options.statistics)
  desiredstats = find(ismember(statlist,options.statistics));
  if isempty(desiredstats)
    progress
    error('Specified statistics were not recognized')
  end
else
  options.automatic = false;
  desiredstats = listdlg('PromptString','Select summary statistics to generate:',...
    'SelectionMode','multiple',...
    'ListSize',[240 200],...
    'InitialValue',[1:length(statlist)],...
    'ListString',statlist);
  if isempty(desiredstats)
    progress;
    return
  end
  options.statistics = statlist(desiredstats);
end
%---------------------------------------------
progress(phases,'summarize');

label = {{};{}};
labelname = {[desc{1} ' ID'];'Variables'};
classes = {[] [];[] []};
classname = {'','';'Step Number','Statistic Type'};

if ismember(length(statlist),desiredstats)
  %last item in list (always "length") included?
  %Special variable: dump it from desiredstats and just note that we should include length
  desiredstats = setdiff(desiredstats,length(statlist));
  includelength = 1;
else
  includelength = 0;
end

nsummarystats = length(desiredstats);
nnewcols      = size(data,2)*nsummarystats + includelength;  % number of new columns per step

%build up class description of summary stats (different class for each
%statistics type)
desiredstats_class = ones(size(data,2),1)*[1:nsummarystats];
desiredstats_class = desiredstats_class(:)';
if includelength
  desiredstats_class = [desiredstats_class nsummarystats+1];
end
desiredstats_class = repmat(desiredstats_class,1,length(stepsdesired));
classes{2,2} = desiredstats_class;

wafervals     = unique(wafergroups);

%create labels for columns
lbl = '';
lblset = '';
dslabels = data.label{2};
if isempty(dslabels)
  dslabels = char(str2cell(sprintf('Variable %i\n',1:size(data,2))));
end

for stat = statlistabbr(desiredstats);
  lblset = strvcat(lblset,[repmat([' ' stat{:} ' '],size(data,2),1) dslabels]);
end
if includelength
  lblset = strvcat(lblset,' Length');
end
for step = stepsdesired
  lbl = strvcat(lbl,[repmat(sprintf('Step %i',step),size(lblset,1),1) lblset]);
end
label{2,1} = lbl;

%create include for columns
varincl = logical(zeros(1,size(data,2)));
varincl(data.include{2}) = true;
varincl = repmat(varincl,1,nsummarystats);
if includelength
  varincl(end+1) = true;  %add one for "length" variable
end
varincl = repmat(varincl,1,length(stepsdesired));

incl1 = zeros(size(data,1),1);
incl1(data.include{1}) = 1;

out = zeros(length(wafervals),length(varincl))*nan;
oldpct = 0;
for j=1:length(wafervals);

  waferuse = (wafergroups==wafervals(j));

  inwafer = find(incl1 & waferuse);

  label{1,1}{j} = waferIDs{wafervals(j)};

  for setindex = 1:size(data.label,2);
    if ~isempty(data.label{1,setindex});
      %look for consistent labels for this set
      unq = data.label{1,setindex}(waferuse,:);
      if all(min(unq)==max(unq))
        unq = unq(1,:);
      end
      if size(unq,1)==1
        label{1,setindex+1}{j,1} = unq;
      end
      labelname{1,setindex+1} = data.labelname{1,setindex};
    end
  end
  for setindex = 1:size(data.class,2);
    if ~isempty(data.class{1,setindex});
      %look for consistent classes for this set
      unq = unique(data.class{1,setindex}(waferuse));
      if length(unq)==1
        classes{1,setindex}(1,j) = unq;
      end
      classname{1,setindex} = data.classname{1,setindex};
    end
  end

  %locate each requested step and summarize
  for stepindex = 1:length(stepsdesired);
    step = stepsdesired(stepindex);

    %figure out which items are in this step
    use = inwafer(steps(inwafer)==step);
    subdata = data.data(use,:);

    %calculate statistics from step
    if isempty(subdata);
      mn = ones(1,size(data,2))*nan;
      sd = mn; 
      smin = mn; 
      smax = mn; 
      srng = mn; 
      sslope = mn;
      len = 0;
    else
      mn   = mean(subdata,1);
      sd   = std(subdata,0,1);
      smin = min(subdata,[],1);
      smax = max(subdata,[],1);
      srng = smax-smin;
      sslope = [ones(1,size(subdata,1));1:size(subdata,1)]'\subdata;
      sslope = sslope(2,:);
      len = length(use);   %length of wafer
    end

    %add this group onto data for this wafer and step
    mystats = [mn' sd' smin' smax' srng' sslope'];
    mystats = mystats(:,desiredstats);  %grab columns of desired stats
    mystats = mystats(:)';  %make one long vector
    outvars = (stepindex-1)*nnewcols+[1:nnewcols];
    if includelength  %add length if desired
      mystats = [mystats len];
    end
    out(j,outvars) = mystats;
    if j==1
      classes{2,1} = [classes{2,1} ones(1,nnewcols)*step];
    end
  end

  pct = j/length(wafervals);
  if floor(pct*100)>oldpct;
    progress(phases,'summarize',pct);
    oldpct = floor(pct*100);
  end

end

%---------------------------------------------
progress(phases,'createoutput');

%result is matrix looking like this:
%Step1                                                 Step2 ...
%mean     std      #pts     min      max      range    mean  ...
%v1 v2 v3 v1 v2 v3 v1 v2 v3 v1 v2 v3 v1 v2 v3 v1 v2 v3 v1 v2 v3


out = dataset(out);
if ~isempty(data.name)
  out.name = ['Summary of ' data.name];
else
  out.name = 'Summary of unnamed data';
end

for m=1:size(label,1);
  toset = 0;
  for setind=1:size(label,2);
    if ~isempty(label{m,setind})
      toset = toset + 1;
      try
      out.label{m,toset} = label{m,setind};
      out.labelname{m,toset} = char(labelname{m,setind});
      catch
        toset = toset -1;
      end
    end
  end
end
for m=1:size(classes,1);
  toset = 0;
  for setind=1:size(classes,2);
    if ~isempty(classes{m,setind})
      toset = toset + 1;
      if length(classes{m,setind})<size(out,m);
        classes{m,setind}(size(out,m)) = 0;  %infill with zeros to appropriate length
      end
      out.class{m,toset} = classes{m,setind};
      out.classname{m,toset} = char(classname{m,setind});
    end
  end
end

%mark no-variance columns as "exclude" (as well as those excluded by user
%in source data)
badsamples = find(any(isnan(out.data),2));
if length(badsamples)<size(out,1);
  %if not all samples have NaN's, exclude those that have "too much
  %missing"
  toexclude = [];
  mdopts = mdcheck('options');
  for j = badsamples(:)';
    f = mdcheck(out.data(j,:));
    if f>mdopts.max_missing;
      toexclude = [toexclude j];
    end
  end
  if ~isempty(toexclude)
    out = delsamps(out,toexclude);
    if ~options.automatic
      evrimsgbox(sprintf('%i sample(s) were excluded due to missing data',length(toexclude)),'Samples Excluded','help','modal');
    end
  end
end
sd = std(out.data(out.include{1},:));
out.include{2} = find(sd~=0 & ~isnan(sd) & varincl);

%================================================================
function progress(phases,phase,complete);

persistent statusboxhandle failure

if ~ishandle(statusboxhandle)
  statusboxhandle = [];
end
if nargin==0
  if ~isempty(statusboxhandle);
    delete(statusboxhandle)
  end
  return
end

%grab title from phases input
progresstitle = phases{1,1};
phases = phases(2:end,:);

mystep = strmatch(phase,phases(:,1));

if nargin>2
  pct = sprintf('-(%2i%%)-> ',floor(complete*100));
else
  pct = '-(---)-> ';
end
pre = strvcat(repmat([' ( X )  '],max(0,mystep-1),1),pct,repmat([' (   )  '],max(0,size(phases,1)-mystep),1));
phaselist = strvcat([pre strvcat(phases{:,2})],' ',' ');

try
  ibopts = struct('figurename',progresstitle,'fontsize',12,'fontname','Courier','maxsize',[100 200]);
  if ishandle(statusboxhandle);
    infobox(statusboxhandle,'string',phaselist,ibopts);
  else
    statusboxhandle = infobox(phaselist,ibopts);
  end
  pos = get(statusboxhandle,'position');
  pos(3:4) = [450 150];
  set(statusboxhandle,'position',pos);
  delete(findobj(allchild(statusboxhandle),'type','uimenu'));
  drawnow
  figure(statusboxhandle);
catch
  failure = failure+1;
  if failure>1
    error('Aborted by user');
  end
end

