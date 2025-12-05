function [bdata,modl] = batchfold(method,data,options)
%BATCHFOLD Transform batch data into dataset for analysis.
%  Based on 'method' type, fold/unfold data into suitable dataset for analysis.
%  Data is separated both by batch (high-level experiments) and also
%  optionally by step number (sub-divisions of batch indicating processing
%  segments or other division of batches). Identification of batch and step
%  for each sample must be in .class field. Assumes incoming data is a
%  two-way matrix consisting of samples by variables.
%
% INPUTS:
%   method          : Method type from table below.
%                                               Equal       Steps
%                                    Shape    Batch Len    Aligned?       Other
%           spca (Summary PCA)         2D         NO          NO       ( batch x (step x summary) )
%  batchmaturity (Batch Maturity)      2D         NO          YES*     Y-block maturity
%           mpca (MPCA)                3D         YES         YES
%        parafac (PARAFAC)             3D         YES         YES
%       sparafac (Summary PARAFAC)     3D         NO          NO       ( batch x step x summary )
%       parafac2 (PARAFAC2)            3D cell    NO          NO
%          other (Other 2-way Methods) 2D         NO          YES*
%                                                                * = optional alignment. 
%
%   data            : Dataset object, 2D samples by variables with all
%                     batch and step information in the .class field.
%
% Options:
%          batch_source : [{'class'}|'label'|'axisscale'] Field name of source for batch info.
%                         Use 'variable' if selecting a column of data.
%             batch_set : ['BSPC Batch'] Identifies set to use for
%                         identifying sample batches. Either a set name
%                         (string) or class set number of set to use.
%          batch_locate : {'index'|{'gap'}|'backstep'} How to use variable
%                         or axisscale to define steps.
%                          index    - boundry at straight index (1 1 1  2 2  3 3 3).
%                          gap      - boundry at gaps in data (1 2 3 4  7 8 9  20 21 22).
%                          backstep - boundry at resets (1 2 3  1 2 3 4  1 2).
%                          NOTE: At this point gap and backstep use the
%                          same algorithm.
%           step_source : ['class'] Field name of source for step info. 
%                         Use 'variable' if selecting a column of data. If
%                         empty then no steps is assumed.
%              step_set : ['BSPC Step'] Identifies set to use for
%                         identifying sample steps. Either a setname
%                         (string) or class set number of set to use.
%  step_selection_classes : [] Step numbers (as defined by the
%                         step_set) to include in analysis. Empty
%                         implies all values are steps.
%                         NOTE: This is not an index into the .class field
%                         but the actual numeric class values.
%   batch_align_options : [struct] Options for 'batchalign' function. See
%                         BATCHALIGN for more information.
%       alignment_batch_class : Numeric class of batch to use as reference 
%                               for alignment or vector of target.
%    alignment_variable_index : Index of variable (columns) in batch to use for alignment.
%      alignment_batch_target : Alignement target vector. Note that this
%                               will take precedence over
%                               alignment_batch_class if both values are
%                               present.
%
%               summary : {''} Type of summary statistics to calculate for
%                         each variable and step (as a cell array of
%                         stings). This is only used for spca and sparafac
%                         methods.
%                         'mean' - Mean
%                         'std' - Standard Deviation
%                         'min' - Minimum
%                         'max'- Maximum
%                         'range' - Range
%                         'slope' - Slope
%                         'length' - Length (of step)
%                         'percentile' - 10 25 50 75 90 percentile.
%             data_only : [{0} | 1 | 2] Only return data:
%                          0 - Run entire function
%                          1 - Make classes for data.
%                          2 - Make classes and align data.
%
% OUTPUT:
%   out   = DataSet Object suitable for loading into 'analysis' interface
%           for given 'method'.
%   model = Standard model structure containing the batchfold model (See
%           MODELSTRUCT). NOTE: Care must be taken to assure fields
%           designated in the calibration set also exist in test set or
%           application of model will fail.
%
%
%I/O:  bdata         = batchfold(method,data,options);
%I/O:  [bdata,model] = batchfold(method,data,options);
%I/O:  bdata         = batchfold(data,model);
%
%See also: ANALYSIS, BSPCGUI

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NOTES:
% * Might be nice to change this function into an object so we could
%   better organize method and utility code.
% * Little confusing on indexing into lookup table (class set) vs actually using
%   numeric classes vs using classID values. All of the dropdown menus
%   basically use the LU table classID values. So when using an "index" into
%   the class I mean indexing into the class lookup table for the
%   numeric/ID value.

if nargin==0
  method = 'io';
end

if ischar(method) & ismember(method,evriio([],'validtopics'))
  options = [];
  options.batch_source = 'class';
  options.batch_set = 'BSPC Batch';
  options.batch_locate = 'gap';
  options.step_source = 'class';
  options.step_set  = 'BSPC Step';
  options.step_selection_classes = [1];
  options.batch_align_options = batchalign('options');
  options.alignment_batch_class    = 1;
  options.alignment_variable_index = 1;
  options.alignment_batch_target   = [];
  options.summary          = {'mean' 'std' 'min' 'max' 'range' 'slope' 'skew' 'kurtosis' 'length' 'percentile'};
  options.data_only        = 0;
  options.align_waitbar    = 'off';
  
  if nargout==0; evriio(mfilename,method,options); else; bdata = evriio(mfilename,method,options); end
  return;
end

%Init output.
bdata = [];

%Check first input.
modl = [];
if ismodel(data)
  modl = data;
  data = method;
  method  = modl.fold_method;
  options = modl.detail.options;
end

%Check options.
if nargin<3 & isempty(modl) 
  options = [];
end

options = reconopts(options,mfilename);

%Make sure options are lower case.
options.summary = lower(options.summary);

if ismember(method,{'parafac2'})
  %Don't look for steps.
  options.step_source = '';
end

%Check for indexes and add classes if needed.
[data, bidx, sidx] = findsets(data,options);

%Return aligned data.
if options.data_only==1
  bdata = data;
  return
end

%Run alignment.
if ismember(method,{'mpca' 'parafac' 'batchmaturity' 'other'})
  if isempty(bidx)
    error('Batches must be defined for "%s" processing',upper(method));
  end
  wb = [];
  if strcmp(options.align_waitbar,'on')
    wb = waitbar(0,'Aligning Data');
  end
  try
    if ~isempty(sidx) & sidx~=bidx
      %Create aligned data with selected step classes otherwise aligning with
      %cow will cause size mismatches with selected steps.
      asteps          = data.class{1,sidx};
      align_subdata   = data(ismember(asteps,options.step_selection_classes),:);
    else
      align_subdata   = data;
    end
    mybatches       = align_subdata.class{1,bidx};%Batch class vector.
    bclassLU        = align_subdata.classlookup{1,bidx};%Batch lookup table.
    %Run batchalign.
    baopts = options.batch_align_options;
    baopts.display      = 'off';      %Displays output to the command window
    %Savgol order must always be >= deriv.
    baopts.savgolorder = max(3,baopts.savgolderiv);
    
    %Get numeric class of alignment batch.
    if isempty(options.alignment_batch_target)
      abatch_class = options.alignment_batch_class;
      mytarget     = align_subdata(mybatches==abatch_class);%Get alignment batch dataset.
      
      if isempty(mytarget)
        evrierrordlg(['Can''t locate alignment batch (class = ' num2str(abatch_class) '), check Alignment Batch value.'],'Empty Alignment Batch');
        if ishandle(wb)
          delete(wb);
        end
        return
      end
      
      if ~isempty(mytarget)
        mytarget     = mytarget(:,options.alignment_variable_index);
        %Need to add vector to options so gets into model and can be used
        %in prediction.
        options.alignment_batch_target = mytarget;
      end
    else
      abatch_class = -1;%Need to spoof target batch class for code below.
      mytarget  = options.alignment_batch_target;
    end

    %Loop through data and align.
    adata = [];%Aligned data.
    if ~strcmp(baopts.method,'none')
      for i = 1:length([bclassLU{:,1}])
        if bclassLU{i,1}==abatch_class
          %Alignment batch so just cat without align.
          adata = [adata;align_subdata(mybatches==bclassLU{i,1},:)];
        else
          thisdata = align_subdata(mybatches==bclassLU{i,1},:);
          if ~isempty(thisdata)
            %Don't cat empty batches.
            if ~strcmp(baopts.method,'none')
              tempadata = batchalign(thisdata,options.alignment_variable_index,mytarget,baopts);
            else
              tempadata = thisdata;
            end
            adata     = [adata;tempadata];
          end
        end
        if ~isempty(wb)
          waitbar(i/length([bclassLU{:,1}]),wb);
        end
      end
    else
      adata = align_subdata;
    end
    
  catch
    if ishandle(wb)
      delete(wb);
    end
    rethrow(lasterror)
  end
  delete(wb)
  
  %Add back class lookup on mode 1.
  
  %CopyDS fields on mode 2.
  adata = copydsfields(data,adata,2);
  data = adata;
  %Clear the data we're not using anymore.
  clear adata;
  clear align_subdata;
end

%Return aligned data.
if options.data_only==2
  bdata = data;
  return
end

%Pull index info for use in folding.
if ~isempty(bidx)
  mybatches       = data.class{1,bidx};%Batch class vector.
  bclassLU        = data.classlookup{1,bidx};%Batch lookup table.
else
  mybatches = ones(1,size(data,1));
  bclassLU = {1 'Batch 1'};
end
if ~isempty(sidx)
  mysteps         = data.class{1,sidx};%Step class vector.
  selected_steps  = options.step_selection_classes;%Selected classes.
else
  %No steps indicated so spoof one step per batch.
  mysteps         = ones(size(data,1),1);
  selected_steps  = 1;%Selected classes.
end

original_size   = size(data);%Original size.

switch method
  case 'spca'
    bdata = createpca(data,mysteps,bclassLU,mybatches,selected_steps,options);
  case 'mpca'
    bdata = creatempca(data,mysteps',bclassLU,mybatches',selected_steps,options);
  case {'batchmaturity' 'other'}
    %Batch maturity.
    bdata = data;
    if ~isempty(options.step_selection_classes) & ~isempty(sidx)
      bdata = data(ismember(data.class{1,sidx},options.step_selection_classes),:);
    end
    %Add axiscale (linear index) per step as 1:length.
    myax = ones(length(mybatches),1);
    for i = 1:size(bclassLU,1)
      myax(mybatches==bclassLU{i,1})=1:length(find(mybatches==bclassLU{i,1}));
    end
    bdata.axisscale{1} = myax;
  case 'parafac'
    bdata = creatempca(data,mysteps',bclassLU,mybatches',selected_steps,options);
    %Permute from: Time (step) x Variable x Batch
    %          to: Batch x Variable x Time (step)
    bdata = permute(bdata,[3 2 1]);
  case 'sparafac'
    bdata = createpca(data,mysteps,bclassLU,mybatches,selected_steps,options);
    %Reshape from : Batch x Step+Stats
    %          to : Batch x Stats x Steps
    
    %Try to get labels for first step and use those in folded data.
    mode2_lbls = bdata.label{2,end};
    %TODO: Make classes for folded data.
    statsclass = bdata.class{2,2};
    classlu    = bdata.classlookup;
    
    %Get length of requested normal (calculated per step) stats.
    lbl_length = length(options.summary(ismember(options.summary,{'mean' 'std' 'min' 'max' 'range' 'slope' 'skew' 'kurtosis' })));
    
    if ismember('percentile',options.summary)
      %Percentile has 5 stats per batch.
      lbl_length = lbl_length+5;
    end
    lbl_length = original_size(2)*lbl_length;
    
    if ismember('length',options.summary)
      %Length has only one.
      lbl_length = lbl_length+1;
    end
    
    %Get single steps worth of labels.
    mode2_lbls = str2cell(mode2_lbls(1:lbl_length,:));
    
    %Remove repeated step name.
    for i = 1:size(mode2_lbls,1)
      mode2_lbls{i,:} = strrep(mode2_lbls{i,:},['Step ' num2str(selected_steps(1)) ' '],'');
    end
    mode3_lbls = sprintf('Step %d\n',selected_steps);
    
    sz = size(bdata);
    ssz = sz(2)/length(selected_steps);
    bdata = reshape(bdata,sz(1),ssz,length(selected_steps));
    
    %Add labels and classes.
    bdata.label{2,1} = mode2_lbls;
    bdata.classname{2,1} = 'Summary Statistics';
    bdata.class{2,1} = statsclass(1:ssz);
    bdata.classlookup{2,1} = classlu{2,2};
    
    if ndims(bdata)<=2
      %If this is a one step process then add 3rd dim.
      data3 = cat(3,bdata,nan(size(bdata)));
      bdata = data3(:,:,1);
    end
    bdata.label{3,1} = str2cell(mode3_lbls);
    bdata.classname{3,1} = 'Steps';
    bdata.class{3,1} = selected_steps;
    bdata.classlookup{3,1} = classlu{2,1};
    
  case 'parafac2'
    %Make batch DSO.
    bdata = [];
    for i = 1:size(bclassLU,1)
      bdata = [bdata {data.data(mybatches==bclassLU{i,1},:)}];
    end
    bdata = dataset(bdata);
    %Not sure they're used but copy over mode 2 labels.
    bdata = copydsfields(data,bdata,2);
  otherwise
    bdata = data;
end

if ~isempty(bdata)
  %Add name to dataset.
  myname = 'Batch Data';
  if ~isempty(method) & ~strcmpi(method,'other')
    myname = [myname ' ' upper(method)];
  end
  
  bdata.name = myname;
end

if nargout>1
  %Create new model, otherwise just pass out original model.
  if isempty(modl)
    modl = modelstruct('batchfold');
    modl.date = date;
    modl.time = clock;
    modl.fold_method    = method;
    modl.datasource{1}  = getdatasource(data);
    modl.detail.options = options;
  end
end

%--------------------------------
function [mydata,bidx,sidx] = findsets(mydata,options)
%Get batch and step indexes. Create the classes if needed.

bidx = [];
sidx = [];

if isnumeric(options.batch_set)
  bidx = options.batch_set;
else
  bidx = findset(mydata,'class',1,options.batch_set);
  if isempty(bidx)
    %erdlgpls({['Unable to locate Batch class for: ' options.batch_set]},['Batch Locate Error'],'modal');
    return
  end
end

if ~strcmpi(options.batch_source,'class')
  %Need to create a batch from field.
  [mydata,bidx] = makeclass(mydata,options.batch_source,1,bidx,'BSPC Batch',[],options);
end

if ~isempty(options.step_source)
  if isnumeric(options.step_set)
    sidx = options.step_set;
  else
    sidx = findset(mydata,'class',1,options.step_set);
    if isempty(sidx)
      return
    end
  end
  
  if ~strcmpi(options.step_source,'class')
    %Need to create a batch from field.
    [mydata,sidx] = makeclass(mydata,options.step_source,1,sidx,'BSPC Step',[],options);
    if isempty(options.step_selection_classes)
      %Make selected steps 'all' if empty.
      options.step_selection_classes = unique(mydata.class{1,sidx});
    end
  end
else
  sidx = [];
end

%--------------------------------------------------------------------
function [outdata,nextset] = makeclass(indata,fieldname,fieldmode,fieldset,newclassname,newval,options)
%Make a class from another field in a dataset. Based on editds code. 
%Overwrite existing 'BSCPC Batch/Step' class if present.

%TODO: Make this a method in DSO.

outdata = indata;  %default if we fail
if nargin<6
  newval = [];
end

nextset = [];

switch fieldname
  case {'label' 'axisscale'}
    %in Labels screen - converting labels to field...
    try
      %Get data to move into class.
      if isempty(newval)
        val = get(indata,fieldname,fieldmode,fieldset);
      else
        val = newval;
      end
      
      if strcmp(fieldname,'axisscale')&~isempty(val)&~strcmp(options.batch_locate,'index')
        %Get batch/step based on incremental value change.
        dax = abs(diff(val));
        val = [1 cumsum(dax>(2*percentile(dax',.9)))+1];
      end
      
      if isempty(val)
        %Make sure empty value is of type double because empty char causes
        %an error.
        val = [];
      end
      
      [indata,nextset] = updateset(indata,'class',1,val,newclassname,{});
      
    catch
      erdlgpls({['Unable to create ' fieldname];lasterr},['Create ' fieldname],'modal');
      return
    end
  
  otherwise
    %Extract data for class then delete field.
    try
      %where should we put this data?
      fieldmode = 2;%Hack for selecting variable, need to switch mode to 2 so code (from editds) below works.
      
      index         = cell(1,ndims(indata));
      [index{:}]    = deal(':');
      index{fieldmode}   = fieldset;
      
      if isempty(newclassname) & ~isempty(indata.label{fieldmode});
        %Use labelname if no class name provided.
        newclassname = deblank(indata.label{fieldmode}(fieldset,:));
      end
      
      val = indata.data(index{:});
      if strcmp(fieldname,'variable')&~isempty(val)&~strcmp(options.batch_locate,'index')
        %Get batch/step based on incremental value change.
        dax = abs(diff(val))';
        val = [1 cumsum(dax>(2*percentile(dax',.9)))+1];
      end
      
      [indata,nextset] = updateset(indata,'class',1,val,newclassname,{});
      
      %Not sure if/why we need to hard delete so exclude instead so it allows
      %test data to be checked for needed column when applying processor
      %model to new data.
      myincld = indata.include{fieldmode};
      myincld = myincld(myincld~=fieldset);
      indata.include{fieldmode} = myincld;
      %indata = delsamps(indata,fieldset,fieldmode,2);
      
    catch
      erdlgpls({['Unable to create ' fieldname];lasterr},['Create ' fieldname],'modal');
      return
    end
end

outdata = rename_lookup_class(indata,fieldmode,nextset,newclassname);

%--------------------------------------------------------------------
function mydata = rename_lookup_class(mydata,fieldmode,nextset,newclassname)
%Replace "Class" with "Batch" or "Step" in lookup table.

luname = 'Class';

%Update lookup table.
if strcmp(newclassname,'BSPC Batch')
  luname = 'Batch';
end

if strcmp(newclassname,'BSPC Step')
  luname = 'Step';
end

lu = mydata.classlookup{fieldmode,nextset};
%FIXME: This doesn't work.
for i = 1:size(lu,1)
  lu{i,2} = strrep(lu{i,2},'Class',luname);
end

mydata.classlookup{fieldmode,nextset} = lu;



%======================================================================
function [out,options] = createpca(data,steps,classLU,wafergroups,stepsdesired,options)
%steps = numeric class repeating per batch (len of data)
%classLU = label names of batches (cell array of strings)
%wafergroups = class of groups (len of data)
%stepsdesired = list of numerical step classes wanted.
%desc = description

%TODO: Add class sets for:
%   1) Statistic *** DONE
%   2) Step *** DONE
%   3) Original variable.

out = [];

wb = waitbar(0,'Initializing Summary Parameters');
statlist        = {'Mean' 'Standard Deviation' 'Minimum' 'Maximum' 'Range' 'Slope' 'Skewness' 'Kurtosis' 'Length (of step)' 'Five-Number Summary'};%Long pretty name.
statlistabbr    = {'Mean' 'STD'                'Min'     'Max'     'Range' 'Slope' 'Skew'     'Kurtosis' 'Length'           'Percentile'};%Short pretty name.
percentilestats = {'10th Percentile' '25th Percentile' '50th Percentile' '75th Percentile' '90th Percentile'};

%Index of stats being requested.
desiredstats = find(ismember(lower(statlistabbr),options.summary));

%---------------------------------------------

label     = {{};{}};
labelname = {['Batch ID'];'Variables'};
classes   = {[] [];[] []};
classname = {'','','';'Step Number','Statistic Type','Original Variables'};
sclasslu  = {};%Lookup table for stats.
%Original variable class.
myvars    = 1:size(data,2);
varlbls   = data.label{2,1};
if isempty(varlbls)
  varlbls = sprintf('Variable %d\n', myvars);
end
varlu = [num2cell(myvars') str2cell(varlbls); {max(myvars)+1} {'Length'}];
varclass = [];

%TODO: Create better way of doing this instead of hardcoding. Need to
%hardcode for now to accomodate legacy code.

per_pos = ~ismember(options.summary,'percentile');%Percentile position in list.
if ~all(per_pos)
  %Special variable: dump it from desiredstats and just note that we should include length
  desiredstats(desiredstats==10) = [];
  plength = 5;
else
  plength = 0;
end

len_pos = ~ismember(options.summary,'length');%Length position in list.
if ~all(len_pos)
  %Special variable: dump it from desiredstats and just note that we should include length
  desiredstats(desiredstats==9) = [];
  includelength = 1;
else
  includelength = 0;
end

nsummarystats = length(desiredstats);
nnewcols      = size(data,2)*nsummarystats + includelength + size(data,2)*plength;  % number of new columns per step

%build up class description of summary stats (different class for each
%statistics type)
desiredstats_class = ones(size(data,2),1)*[1:nsummarystats];
desiredstats_class = desiredstats_class(:)';
sclasslu = [num2cell([1:nsummarystats]') statlist(desiredstats)'];

%Keep track of additional stats, can't use nsummarystats because it's used
%in labeling below.
addstats = nsummarystats;

%Construct variable class.
varset = [repmat(myvars,1,length(desiredstats))];

%Add length to end of class.
if includelength
  desiredstats_class = [desiredstats_class nsummarystats+1];
  sclasslu = [sclasslu; {nsummarystats+1 'Length (of step)'}];
  addstats = addstats+1;
  varset(end+1) = max(myvars+1);
end

%Add percentile class info.
if plength
  %Start number as if length is being used even if it's not
  pstats = ones(size(data,2),1)*[(addstats+1):(addstats+1)+plength-1];%Make matrix of repeat classes.
  desiredstats_class = [desiredstats_class pstats(:)'];%Concat expanded matrix.
  sclasslu = [sclasslu; [num2cell([(addstats)+[1:plength]]') percentilestats']];
  varset = [varset repmat(myvars,1,5)];
end

desiredstats_class = repmat(desiredstats_class,1,length(stepsdesired));%Variables*NoStats*Steps
classes{2,2} = desiredstats_class;
wafervals    = unique(wafergroups);%Unique numeric class values.

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

if plength
  for stat = percentilestats;
    lblset = strvcat(lblset,[repmat([' ' stat{:} ' '],size(data,2),1) dslabels]);
  end
end

for step = stepsdesired
  lbl = strvcat(lbl,[repmat(sprintf('Step %i',step),size(lblset,1),1) lblset]);
  varclass = [varclass varset];
end
label{2,1} = lbl;

%create include for columns
myvarincl = logical(zeros(1,size(data,2)));
myvarincl(data.include{2}) = true;
varincl = repmat(myvarincl,1,nsummarystats);
if includelength
  varincl(end+1) = true;  %add one for "length" variable
end

if plength
  %Add five percentile groups.
  varincl = [varincl repmat(myvarincl,1,5)];
end

varincl = repmat(varincl,1,length(stepsdesired));

incl1 = zeros(size(data,1),1);
incl1(data.include{1}) = 1;

out = zeros(length(wafervals),length(varincl))*nan;
oldpct = 0;
for j=1:length(wafervals);
  if ishandle(wb)
    waitbar(j/length(wafervals),wb,['Calculating Summary Statistics for Batch: ' num2str(j) '    (Close to Cance)'])
  else
    out = [];
    return
  end
  waferuse = (wafergroups==wafervals(j));
  
  inwafer = find(incl1' & waferuse);
  
  label{1,1}{j} = classLU{[classLU{:,1}]==wafervals(j),2};
  
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
      p10   = mn;
      p25   = mn;
      p50   = mn;
      p75   = mn;
      p90   = mn;
      skew  = mn;
      kurt  = mn;
    else
      %Use summary for
      %    mean  = mean,
      %    std   = standard deviation,
      %    min   = minimum,
      %    max   = maximum,
      %    p10   = 10th percentile,
      %    p25   = 25th percentile,
      %    p50   = 50th percentile,
      %    p75   = 75th percentile,
      %    p90   = 90th percentile,
      %    skew  = skewness,
      %    kurt  = kurtosis.
      sumdat = summary(subdata);
      mn   = sumdat.mean.data;
      sd   = sumdat.std.data;
      smin = sumdat.min.data;
      smax = sumdat.max.data;
      
      %       mn   = mean(subdata,1);
      %       sd   = std(subdata,0,1);
      %       smin = min(subdata,[],1);
      %       smax = max(subdata,[],1);
      srng = smax-smin;
      sslope = [ones(1,size(subdata,1));1:size(subdata,1)]'\subdata;
      sslope = sslope(2,:);
      len = length(use);   %length of wafer
      p10   = sumdat.p10.data;
      p25   = sumdat.p25.data;
      p50   = sumdat.p50.data;
      p75   = sumdat.p75.data;
      p90   = sumdat.p90.data;
      skew  = sumdat.skew.data;
      kurt  = sumdat.kurt.data;
      
    end
    
    %add this group onto data for this wafer and step
    mystats = [mn' sd' smin' smax' srng' sslope' skew' kurt'];
    mystats = mystats(:,desiredstats);  %grab columns of desired stats
    mystats = mystats(:)';  %make one long vector
    outvars = (stepindex-1)*nnewcols+[1:nnewcols];
    if includelength  %add length if desired
      mystats = [mystats len];
    end
    
    if plength>0  %add length if desired
      mystats = [mystats p10 p25 p50 p75 p90];
    end
    
    out(j,outvars) = mystats;
    if j==1
      classes{2,1} = [classes{2,1} ones(1,nnewcols)*step];
    end
  end
  
end

%---------------------------------------------

%result is matrix looking like this:
%Step1                                                 Step2 ...
%mean     std      #pts     min      max      range    mean  ...
%v1 v2 v3 v1 v2 v3 v1 v2 v3 v1 v2 v3 v1 v2 v3 v1 v2 v3 v1 v2 v3
if ishandle(wb)
  waitbar(j/length(wafervals),wb,['Make Labels and Classes'])
else
  out = [];
  return
end

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
    %     if ~options.automatic
    %       evrimsgbox(sprintf('%i sample(s) were excluded due to missing data',length(toexclude)),'Samples Excluded','help','modal');
    %     end
  end
end
sd = std(out.data(out.include{1},:));
out.include{2} = find(sd~=0 & ~isnan(sd) & varincl);

%Add stats and step lookup tables.
mylu = out.classlookup{2,1};%Step lookup.
for i = 1:size(mylu,1)
  if mylu{i,1}~=0
    mylu{i,2} = strrep(mylu{i,2},'Class','Step');
  end
end
out.classlookup{2,1} = mylu;%Step class.

out.classlookup{2,2}=sclasslu;%Stats class.

%Add variable class.
out.class{2,3} = varclass;
out.classname{2,3}   = classname{2,3};
out.classlookup{2,3} = varlu;

%Add batch lookup table back into data. There may be a better way to do this but
%will need to examine code above carefully to figure it out. Use this for
%now.
bidx = options.batch_set;%Batch
if ~isnumeric(bidx)
  bidx = findset(data,'class',1,bidx);
end
if ~isempty(bidx)
  %Batch is first classset in mode 3.
  out.classlookup{1,bidx} = data.classlookup{1,bidx};
end

if ishandle(wb)
  close(wb)
end

%=============================================================
function out = creatempca(data,steps,classLU,wafergroups,stepsdesired,options)
%steps = numeric class repeating per batch (len of data)
%classLU = label names of batches (cell array of strings)
%wafergroups = class of groups (len of data)
%stepsdesired = list of numerical step classes wanted.
%options = main function options.

%MPCA sizing: Time (step) x Variable x Batch
wb = waitbar(0,'Initializing MPCA Parameters');

out = [];

label = {{};{};{}};
labelname = {'';'Signal ID';['Batch ID']};
classes = {[];[];[]};
classname = {'BSPC Step';'';'BSPC Batch'};

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
% stepsize = zeros(length(wafervals),length(stepsdesired));
for j=1:length(wafervals);
  %for each wafer...
  waferuse   = (wafergroups==wafervals(j)); %identify rows in this wafer
  inwafer{j} = find(incl1 & waferuse); %INCLUDED rows in this wafer
end

% targetlength = median(stepsize)

%prep output and start cycling through wafers
% out = zeros(sum(targetlength),size(data,2),length(wafervals));

%Check steps per batch
mystepslen = length(steps)/length(wafervals);
if ~isint(mystepslen)
  erdlgpls({'Inconsistent batch data size. Unable to concatenate batch in mode 3. Check aligment settings.'},'MPCA Concat Error')
  if ishandle(wb)
    delete(wb)
  end
  out = [];
  return
end

%Initialize out.
out = zeros(mystepslen,size(data,2),length(wafervals));

oldpct = 0;
for j=1:length(wafervals);      %for each wafer/batch...
  
  if ishandle(wb)
    waitbar(j/length(wafervals),wb,['Folding Batch: ' num2str(j) '    (Close to Cance)'])
  else
    out = [];
    return
  end
  
  slab = [];   %each wafer will be built up in its own slab
  
  waferuse = (wafergroups==wafervals(j)); %identify rows in this wafer
  label{3,1}{j} = classLU{[classLU{:,1}]==wafervals(j),2};  %get a generic label for this wafer
  
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
    %Loop through classes of mode 1 per batch (waferuse).
    if ~isempty(data.class{1,setindex});
      %look for consistent classes for this set
      unq = unique(data.class{1,setindex}(waferuse));
      if length(unq)==1
        classes{3,setindex}(1,j) = unq;
      end
      classname{3,setindex} = data.classname{1,setindex};
    end
  end

  try
    out(:,:,j) = data.data(inwafer{j},:);  %[time x var]
  catch
    erdlgpls({'Inconsistent batch data size. Unable to concatenate batch in mode 3. Check aligment settings.',lasterr},'MPCA Concat Error')
    if ishandle(wb)
      delete(wb)
    end
    out = [];
    return
  end

end

%Result is matrix looking like this:
% Step x Var x Batch

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
for m=1:size(classes,1);%Each mode in new 3D dso.
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

%Add lookup table back into data. There may be a better way to do this but
%will need to examine code above carefully to figure it out. Use this for
%now.
bidx = options.batch_set;%Batch
if ~isnumeric(bidx)
  %bidx = findclassset(data,bidx);
  bidx = findset(data,'class',1,bidx);
end
if ~isempty(bidx)
  %Batch is first classset in mode 3.
  out.classlookup{3,1} = data.classlookup{1,bidx};
end
sidx = options.step_set;%Step index.
if ~isnumeric(sidx)
  %sidx = findclassset(data,sidx);
  sidx = findset(data,'class',1,sidx);
end
if ~isempty(sidx)
  %Step is first classset in mode 1.
  out.class{1,1}       = data.class{1,sidx}(inwafer{j});
  out.classlookup{1,1} = data.classlookup{1,sidx};
end

if ishandle(wb)
  close(wb)
end

%------------------------------
function makedemo

options = batchfold('options')

load arch
arch.class{1,2} = repmat([1 2 3 4 5],1,15);
arch.classname{1,2} = 'BSPC Step';

bclass = [];
for i = 1:15
  bclass = [bclass [i i i i i]];
end
arch.class{1,3} = bclass;
arch.classname{1,3} = 'BSPC Batch';


options.step_selection_classes = [3 4 5];
[a,m] = batchfold('spca',arch,options);
b = batchfold(arch,m);
comparevars(a,b)
%10 variables x 13 stats + length = 131 values per step * 3 steps = 393 columns


load plsdata
x = xblock1(:,5:9);
x.class{1,1} = [ones(1,100) ones(1,100)*2 ones(1,100)*3];
x.classname{1,1} = 'BSPC Batch';
x.classlookup{1,1}={1 'Batch 1'; 2 'Batch 2'; 3 'Batch 3'};

x.class{1,2} = [repmat([ones(1,25) ones(1,20)*2 ones(1,30)*3 ones(1,25)*4],1,3)];
x.classname{1,2} = 'BSPC Step';
x.classlookup{1,2}={1 'Step 1';2 'Step 2';3 'Step 3';4 'Step 4'};

options.step_selection_classes = [2 3 5];
[a,m] = batchfold('spca',x,options);
b = batchfold(x,m);
comparevars(a,b)

[a,m] = batchfold('parafac2',x,options);
b = batchfold(x,m);
comparevars(a,b)

[a,m] = batchfold('mpca',x,options);
b = batchfold(x,m);
comparevars(a,b)

options.summary          = {'mean' 'STD' 'MIN' 'MAX' 'range'};
[a,m] = batchfold('sparafac',x,options);
b = batchfold(x,m);
comparevars(a,b)

options.summary          = {'mean' 'std' 'min' 'range' 'length' 'percentile'};
[a,m] = batchfold('sparafac',x,options);
b = batchfold(x,m);
comparevars(a,b)

load Dupont_BSPC

[a,m] = batchfold('spca',dupont_cal,options);
b = batchfold(dupont_test,m);

%Truncated batch data.
dupont_cal_trunc = [dupont_cal(1:90,:);dupont_cal(101:190,:);dupont_cal(201:290,:);...
  dupont_cal(301:390,:);dupont_cal(401:490,:);dupont_cal(511:590,:);dupont_cal(611:690,:);...
  dupont_cal(711:790,:);dupont_cal(801:end,:)];

a = batchfold('parafac',dupont_cal_trunc,options)

%**************************
load arch
opts = batchfold('options');
opts.batch_source = 'variable';
opts.batch_set    = 1;
opts.step_source  = 'variable';
opts.step_set     = 2;

out = batchfold('mpca',arch,opts);

opts = batchfold('options');
opts.batch_source = 'class';
opts.batch_set    = 1;
opts.step_source  = 'variable';
opts.step_set     = 2;

out = batchfold('mpca',arch,opts);

opts = batchfold('options');
opts.batch_source = 'label';
opts.batch_set    = 1;
opts.step_source  = 'class';
opts.step_set     = 1;

out = batchfold('mpca',arch,opts);

ax = [ [1:25] [30:54] [60:84]];%Should make three classes.

arch.axisscale{1,2} = ax;
opts = batchfold('options');
opts.batch_source = 'axisscale';
opts.batch_set    = 2;
opts.step_source  = 'class';
opts.step_set     = 1;

out = batchfold('mpca',arch,opts);
dupont_cal_lblonly = dupont_cal
dupont_cal_lblonly.labelname{1} = 'Batch Name';
dupont_cal_lblonly.label{1} = str2cell(sprintf('Batch Row %d\n',dupont_cal.class{1}));

dupont_cal_lblonly.labelname{1,2} = 'Step Name';
dupont_cal_lblonly.label{1,2} = str2cell(sprintf('Step Row Class %d\n',dupont_cal.class{1,2}));

dupont_cal_lblonly.class{1} = [];
dupont_cal_lblonly.class{1,2} = [];
dupont_cal_lblonly.classname{1} = '';
dupont_cal_lblonly.classname{1,2} = '';
dupont_cal_lblonly.classlookup{1} = [];
dupont_cal_lblonly.classlookup{1,2} = [];



load Dupont_BSPC

cal_opts = batchfold('options');
cal_opts.step_selection_classes = [ 2:7 ];
cal_opts.alignment_batch_class = 3;%What to batch to align on.
cal_opts.alignment_variable_index = 5;%What variable to align on.

cal_opts.batch_align_options.method = 'cow';%Use linear alignment.

tst_opts = cal_opts;
tst_opts.alignment_batch_class = 37;

mpca_options = mpca('options');
mpca_options.preprocessing = preprocess('default','autoscale');

[batch_cal_data,cal_mpca_modl] = batchfold('mpca',dupont_cal,cal_opts);
%Apply alingment via model to new data.
[batch_tst_data,tst_mpca_modl] = batchfold(dupont_test,cal_mpca_modl);


%No steps.
load Dupont_BSPC

d = dataset(dupont_cal.data)
d.classname{1}    = 'BSPC Batch';
d.class{1}        = dupont_cal.class{1};
d.classlookup{1}  = dupont_cal.classlookup{1};

