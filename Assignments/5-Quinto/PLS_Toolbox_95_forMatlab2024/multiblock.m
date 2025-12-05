function varargout = multiblock(varargin)
%MULTIBLOCK Create or apply a multiblock model for joining data.
%  Multiple block data joining allows for two or more datasets
%  and or models to be joined and modeled. Model fields (e.g., Scores) are
%  extracted into a dataset before joining.
%
%  This function joins data in the order it's input. 
%
%  INPUTS:
%        mx = Cell array of data and or models.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           display: [ 'off' | {'on'} ] Governs level of display to command window.
%             plots: [ 'none' | {'final'} ] Governs level of plotting.
%           waitbar: [ 'off' | {'on'} ] Show waitbar.
%   filter_defaults: [ 'off' | {'on'} ] Use default scores and Q model fields.
%     filter_prompt: [ 'off' | {'on'} ] Prompt for selecting model filter
%                    fields. If off then defaults are selected.
%            filter: [{}] n x 3 cell array of filter information (see GETMODELOUTPUTS).
%       bin_options: structure of options to pass to bin2scale for data concatenation.
%     preprocessing: [{}] Preproceessing for each block.
%   label_threshold: [.5] Threshold for label matching.
%   post_join_model: [] Model to apply after join.
%       apply_postjoin_model: [ 'off' | {'on'} ] Apply post join model if available.
%                             Set this option to 'off' if only joined data is to desired. 
%
%  OUTPUT:
%     model = standard model structure containing the multiblock model (See MODELSTRUCT)
%
%I/O: model               = multiblock({m1 d2 m3 d4}, options);           %Make multiblock model. 
%I/O: [model, joinedData] = multiblock({m1 d2 m3 d4}, options);           %Return model and joined data. 
%I/O: joinedData          = multiblock({dd1 dd2 dd3 dd4}, model);         %Get new joined data.
%I/O: model               = multiblock(model,postJoinModel);              %Add a post join model to multiblock model.
%I/O: pred                = multiblock({x1' x2' x3' x3' x4'}, model);     %Get joined data and prediction. 
%I/O: [pred, joinedData]  = multiblock({x1' x2' x3' x3' x4'}, model);     %Get joined data and prediction. 

%I/O: options = multiblock('options');        %returns default options structure
%I/O: multiblock demo                         %runs a demo of the multiblock function.
%
%See also: BIN2SCALE COADD

%Copyright Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0  % LAUNCH GUI
  fig = multiblocktool;
  if nargout>0
    varargout = {fig};
  end
  return
end

if ischar(varargin{1}) %Help, Demo, Options, subfunction.
  switch lower(varargin{1})
    case evriio([],'validtopics')
      options = [];
      options.name            = 'options';
      options.display         = 'on'; %Displays output to the command window
      options.plots           = 'final'; %Governs plots to make.
      options.filter_defaults = 'on'; %Use default model fields.
      options.filter_prompt   = 'on'; %Prompt user if empty filter found for a model.
      options.filter          = {[]};
      options.label_threshold = .5;
      options.apply_postjoin_model  = 'off';%Automatically apply model after calibration.
      options.post_join_model = [];
      options.bin_options     = bin2scale('options');
      options.preprocessing   = {[]};
      options.waitbar         = 'on';
      options.definitions     = @optiondefs;
      if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
      return;
    otherwise
      if nargout == 0;
        %normal calls with a function
        feval(varargin{:}); % FEVAL switchyard
      else
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
      end
      return
  end
end

%Parse inputs.
modl = [];
mfilter = [];
options = [];

if iscell(varargin{1})
  %First input must always be a cell of raw data or test data.
  mx = varargin{1};
end

switch nargin
  case 1
    %Supllying just raw data with no filter or options:  model = multiblock({m1 m2 x3 m3 x4});
  case {2 3}
    %If nargin==3 then calling .apply and 3rd input is options. Input
    %options are unneeded so just ignore. 
    
    if ismodel(varargin{1}) & ismodel(varargin{2})
      %Adding post join model to model options.
      modl                 = varargin{1};
      opts                 = modl.detail.options;
      opts.post_join_model = varargin{2};
      modl.detail.options  = opts;
      varargout{1}         = modl;
      return
    end
    
    if ismodel(varargin{2})
      %Applying new data:   pred = ({x1' x2' x3' x4'},model)
      modl = varargin{2};  
      options = modl.detail.options;
    elseif isstruct(varargin{2})
      %Raw data and options:   modl = ({m1' x2' x3' x4'},options)
      options = varargin{2};
    else
      error(['Unrecognized second input. Type: ''help ' mfilename '''']);
    end
  otherwise
    error('MULTIBLOCK Requires 1 or 2 inputs.');
end

%Verify options.
options = reconopts(options,mfilename);

fltr = options.filter;%Filter info.

if isempty(modl)
  %Calibrate mode, add information to MB model for applying to new data.
  mdata = {};%Model or datasource info.
  if length(fltr)==1 & isempty(fltr{1})
    %No filter at all so initialize.
    fltr = cell(1,length(mx));
  elseif length(fltr)~=length(mx)
    error('Model field filter is not correct length. Number of cells in array must equal number of data/models input.')
  end
  
  for i = 1:length(mx)
    if ismodel(mx{i})
      mdata{i} = mx{i};
      if isempty(fltr{i})
        defaultfields = [];%Full nx3 list of model fields.
        defaultfields_list = [];%Fields names only.
        if strcmpi(options.filter_defaults,'on')
          %Get default model fields.
          [defaultfields, defaultfields_list] = getmodeloutputs(mx{i},0);
        end
        
        if strcmpi(options.filter_prompt,'on')
          %Prompt user for what fields to use on this model.
          fltr{i} = getmodeloutputs(mx{i},defaultfields_list);
          drawnow;
        else
          fltr{i} = defaultfields;
        end
      end
    else
      %Dataset.
      mdata{i} = getdatasource(mx{i});
    end
  end
  
  %Set up model.
  options.filter      = fltr;
  modl = evrimodel('multiblock');
  modl.detail.options = options;
  modl.matchvars = 'off';
  modl.mdata          = mdata;
  %Add dummy datasource info, this is how model determines if it's calibrated. 
  modl.datasource = {getdatasource(1)}; 

  varargout{1}        = modl;
  if nargout==2
    %Get joined data.
    % beginning of changes to accommodate calibrated preprocessing - model
    % calibration stage
    % varargout{2} = multiblock(mx, modl);
    cdata = multiblock(mx, modl);
    varargout{1}.options.preprocessing = cdata.userdata.join_prepro;
    userdataClean = rmfield(cdata.userdata, 'join_prepro');
    cdata.userdata = userdataClean;
    varargout{2} = cdata;
    clear cdata
  end
  
else
  %Apply to new data then bin.
  matching_info = {};%Keep track of what's available for matching.
  cdata         = [];%Combined data.
  fltr          = modl.options.filter;
  prepro        = modl.options.preprocessing;
  if isPreProCalibrated(modl)
    curPPmode = 'apply';
  else
    curPPmode = 'calibrate';
  end
  
  wb = [];
  if strcmp(options.waitbar,'on')
    wb = waitbar(0,'Multiblock joining data...');
  end
  
  try
    for i = 1:length(mx)
      thisitem   = modl.mdata{i};%Pull original (sub) model or (meta) data from multiblock model.
      thisfilter = fltr{i};%Get filter for model, if data then this will be empty.
      
      out = [];
      if ismodel(thisitem)
        if isdataset(mx{i})
          %Apply model to new data.
          mypred = thisitem.apply(mx{i});
        else
          mypred = thisitem;
        end
        
        %TODO: Store Pred somewhere.
        
        %Following code is modified from modelselector.m.
        out = dataset(applyfilter(mypred,thisfilter(:,2)));
        out.label{2,1} = thisfilter(:,1);%Add filter names as labels.
        
        %Copy info (labels and axisscale) from pred.
        out = copydsfields(mypred,out,1);

      end
      
      if ~isempty(out)
        %Working with model data.
        
        %FIXME: Would apply above even work if var sizes were wrong?
        if size(thisfilter,1)~=size(out,2)
          error('Size (variable/mode 2) of new dataset does not match calibration data size.')
        end
        
      else
        %Working with dataset.
        if isdataset(mx{i})
          %Check size with expected.
          if size(mx{i},2)~=thisitem.size(2)
            error('Size (variable/mode 2) of new dataset does not match calibration data size.')
          end
        end
        out = mx{i};
      end
      
      %Apply preprocessing here.
      if length(prepro)>=i & ~isempty(prepro{i})
        [out,prepro{i}] = preprocess(curPPmode,prepro{i},out);
        %FIXME: What to do about pp that needs to be saved?
      end
      
      %Join data.
      if i == 1;
        cdata = out;
      else
        cdata = join_data(cdata,out,options);
      end
      
      if ~isempty(wb)
        waitbar(i/length(mx),wb)
      end
      
    end
    
  catch
    le = lasterror;
    if ishandle(wb)
      close(wb)
    end
    rethrow(le);
  end
  
  if ishandle(wb)
    close(wb)
  end
  
  %TODO: Use implied via outputs to determine what's output.
  if nargout == 2 | (nargout==1 & ~isempty(options.post_join_model) & strcmpi(options.apply_postjoin_model,'on'))
    %Apply model to data.
    mymod = options.post_join_model;
    mypred = mymod.apply(cdata);
    if nargout == 1
      varargout{1} = mypred;
    else
      %FIXME: What order should this be.
      varargout{1} = cdata;
      varargout{2} = mypred;
    end
  else
    % start changes to include calibrated preprocessing in returned data
    switch curPPmode
      case 'calibrate'
        cdata.userdata.join_prepro = prepro;
      case 'apply'
    end
    % end changes to include calibrated preprocessing in returned data
    varargout{1} = cdata;
  end
end

%--------------------------
function out = join_data(data_a,data_b,options)
%Match data based on general rules.
% 1 Bin - If both datasets have time axis scale with overlap then use that for
%     matching/binning.
% 2 Label - If there are labels AND labels match at over options.label_threshold
%     then use labels.
% 3 If no labels or threshold not met then check sizing and try straight
%     cat.
% 4 If size does not match then make a fake time axis scale try for best
%     match.

tax2 = [];

%Keep track of type of join.
jh = {};
if isfield(data_a.userdata,'join_history')
  jh = data_a.userdata.join_history;
end

b2sc = [];
if isfield(data_a.userdata,'bin2scale')
  b2sc = data_a.userdata.bin2scale;
end

%Case 1a, use binning on time axis.
tax1 = gettimeaxisset(data_a,1);
if ~isempty(tax1)
  tax2 = gettimeaxisset(data_b,1);
end

%Case 1b, use binning on simple monotonically-increasing axis
if isempty(tax1) & isempty(tax2)  %couldn't find time axis?
  tax1 = getsimpleaxisset(data_a,1);
  if ~isempty(tax1)
    tax2 = getsimpleaxisset(data_b,1);
  end
end

if ~isempty(tax1) & ~isempty(tax2)
  %Test for overlap before trying bin. Continue to label matching if no
  %overlap.
  seta = data_a.axisscale{1,tax1};
  setb = data_b.axisscale{1,tax2};
  if max(seta)>min(setb) & min(seta)<max(setb)
    %Bin the data with time axis.
    options.bin_options.axisscaleset = [tax1 tax2];
    %Assumes data_a is HF and data_b is LF.
    [data_a, data_b, inputflip] = bin2scale(data_a,data_b,options.bin_options);
    if inputflip
      %If data_b was higher frequency then inputs are automatically
      %flipped and need to be augmented in reverse.
      out = augment(2,data_b,data_a);
      bsudata = data_a.userdata.bin2scale;
    else
      out = augment(2,data_a,data_b);
      bsudata = data_a.userdata.bin2scale;
    end
    out.userdata = [];
    out.userdata.bin2scale = [b2sc bsudata];
    out.userdata.join_history = [jh {'Time'}];
    return
  end
end

%Case 2 - use label matching.
out = join_data_with_labels(data_a,data_b,options);
if ~isempty(out)
  if ~isstruct(out.userdata)
    %Just clear userdata for now. May try to preserve it in future.
    out.userdata = [];
  end
  out.userdata.join_history = [jh {'Label'}];
  return
end

%Case 3 - Check if same size and do straight concat.
if size(data_a,1)==size(data_b,1)
  out = augment(2,data_a,data_b);
  if ~isstruct(out.userdata)
    %Just clear userdata for now. May try to preserve it in future.
    out.userdata = [];
  end
  out.userdata.join_history = [jh {'Join'}];
  return
end

%Case 4 - Make fake time axis and concat.
if ~isempty(tax1)
  %Found a timestamp in first dataset so create fake one for second set and
  %recursively call.
  ax_a = data_a.axisscale{tax1,1};%Get known time axis.
  ax_b = linspace(min(ax_a),max(ax_a),size(data_b,1));%Make fake time axis scale using known.
  ax_b_size = size(data_b.axisscale,2);
  data_b.axisscale{1,ax_b_size+1} = ax_b;%Add fake to end of axisscales.
  out = join_data(data_a,data_b,options);%Recursive call to join.
elseif ~isempty(tax2)
  %Found a timestamp in second dataset.
  ax_b = data_b.axisscale{tax2,1};
  ax_a = linspace(min(ax_b),max(ax_b),size(data_a,1));
  ax_a_size = size(data_a.axisscale,2);
  data_a.axisscale{1,ax_a_size+1} = ax_a;
  out = join_data(data_a,data_b,options);
end

if ~isempty(out)
  %Fake call to join_data so modify last entry.
  if isempty(jh)
    jh = {''};  %if this is the ONLY join...
  end
  jh{end} = 'Time*';
  if ~isstruct(out.userdata)
    %Just clear userdata for now. May try to preserve it in future.
    out.userdata = [];
  end
  out.userdata.join_history = jh;
  return
end

error('Unable to join data sets. No match found in axisscales, lables or sizes.')

%--------------------------
function out = applyfilter(mymodl,thisfilter)
%Apply filter to model and return concatenated fields.

out = [];

%Following code is modified from modelselector.m.
for j=1:length(thisfilter);
  if iscell(thisfilter{j})
    %Filter Format:   {  label   substruct  xml}
    thisfilter{j} = thisfilter{j}{2};
  end
  if isstruct(thisfilter{j}) & isfield(thisfilter{j},'label')
    %Filter Format struct with:
    %   f.label = 'label';  f.type = ...;  f.subs = ...;
    %label{j} = thisfilter{j}.label;
    thisfilter{j} = rmfield(thisfilter{j},'label');
  else
    %Filter Format struct with:
    %   f.type = ...;  f.subs = ...;
    %OR simple content (not really a filter, just a
    %    replacement value)
  end
  if isstruct(thisfilter{j}) & isfield(thisfilter{j},'type') & isfield(thisfilter{j},'subs')
    %appears to be a substruct structure
    try
      out = [out subsref(mymodl,thisfilter{j})];
    catch
      le = lasterror;
      le.message = sprintf('Error Filtering Output\n%s',le.message);
      rethrow(le)
    end
  else
    %include contents as-is
    out = [out thisfilter{j}];
  end
end

%--------------------------
function joindata = join_data_with_labels(data_a,data_b,options)
%Get bigest overlap of label sets by scanning each combination. Inputs
%'seta' and 'setb' are cell array of character arrays as come out of
%dataset.label(1,:);

%This isn't the best matching scheme but it works for now. Doesn't not
%count duplicates and not sure how to handle that situation.

idxa = 0;
idxb = 0;
score = 0;%Longest overlap of uniqe names.
joindata = [];
albl = [];

seta = data_a.label(1,:);
setb = data_b.label(1,:);

%If either set is empty then no matches can be made so return.
if (length(seta)==1 & isempty(seta{1})) | (length(setb)==1 & isempty(setb{1}))
  return
end

for i = 1:length(seta)  %loop over all label sets
  if isempty(seta{i}); continue; end   %no labels in this set
  albl = str2cell(seta{i});%Need to make char array into cell.
  for j = 1:length(setb) %loop over all label sets
    if isempty(setb{j}); continue; end   %no labels in this set
    %see if these two sets match at all
    blbl = str2cell(setb{j});
    [commonlabels,aindex,bindex] = intersect(albl,blbl);
    if ~isempty(commonlabels)  %something in common?
      if score<length(commonlabels)
        score = length(commonlabels);
        idxa = i;
        idxb = j;
        bestlbl = commonlabels;
      end
    end
  end
end

threshold = size(albl,1)/score;%(number of set A lables)/(number of labels in best overlap)
if score==0 | options.label_threshold>threshold
  %Not enough matching label names.
  return
end

a_indx = ismember(str2cell(data_a.label{1,idxa}),commonlabels);
b_indx = ismember(str2cell(data_b.label{1,idxb}),commonlabels);

if sum(a_indx)~=sum(b_indx)
  %Size mismatch on label names. Could be because of duplicate names in one
  %dataset but not the other.
  return
end

%Do the concatenation.
joindata = augment(2,data_a(a_indx,:),data_b(b_indx,:));

%--------------------------
function out = istimeaxis(thisaxis)

out = thisaxis(1)>datenum('1/1/1900') & thisaxis(end)<datenum('1/1/2300');
  
%--------------------------
function thisset = gettimeaxisset(data,mymode)
%GETTIMEAXISSET Locate time axis in a dataset.

%Go through mode 1 of dataset and look for the first one that has a time
%stamp.
if nargin<2
  mymode = 1;
end

thisset = [];
modeax = data.axisscale(mymode,:);

for i = 1:size(modeax,2)
  thisaxis = data.axisscale{mymode,i};
  if ~isempty(thisaxis) & istimeaxis(thisaxis)
    thisset = i;
    break
  end
end

%--------------------------
function thisset = getsimpleaxisset(data,mymode)
%GETSIMPLEAXISSET Locate simple monotonically-increasing axis in a dataset.

%Go through mode 1 of dataset and look for the first one that has a time
%stamp.
if nargin<2
  mymode = 1;
end

thisset = [];
modeax = data.axisscale(mymode,:);

%look through axis scales for monotonically increasing scales (that is NOT
%a time-stamp-scale time axis)
for i = 1:size(modeax,2)
  thisaxis = data.axisscale{mymode,i};
  if ~isempty(thisaxis) & ~istimeaxis(thisaxis) & all(diff(thisaxis)>0)
    thisset = i;
    break;
  end
end

%------------------------------------------------
function drop(h,eventdata,handles,varargin)

multiblocktool('drop',h,eventdata,handles,varargin{:})

%--------------------------
function out = isPreProCalibrated(curModel)
%Determine if model has had prepro calibrated or not. 
% FIXME: Using comparevars is the best we can do right now but when
%        preprocess is refactored to use explicit calibration flag then we
%        can use that instead of implicit code below.
% NOTE: Baseline Simple was the initial pp method that caused issues to
%       show up with old code (reported to helpdesk).

allPPcell = curModel.options.preprocessing;

%Remove empty prepro cells. For example, if block doesn't have any prepro
%designated it will be an empty cell.
allPPcell(cellfun(@isempty,allPPcell)) = [];

%If any of the pp methods seem to be calibrated then assume they all have
%and we just can't detect it. NOTE: Might be an edge case where some prepro
%has been calibrated and some not. Need to investigate that, maybe just use
%a flag somehow when a user calculates a MB model.
%NOTE: We could also change this logic to be all prepro must be
%calibrated, but there are a few where it's almost impossible to tell
%(e.g., log10).
out = false;

% %Old code.
% for loopInd = 1:length(allPPcell)
%   curPP =allPPcell{loopInd};
%   out(loopInd) = all(arrayfun(@(x)isequal(length(x.out), x.caloutputs), ...
%     curPP));
% end
% out = all(out);

%New code.
for loopInd = 1:length(allPPcell)
  %Loop through data blocks.
  curPP =allPPcell{loopInd};
  for loopInd2 = 1:length(curPP)
    %Loop through prepro on each data block.
    thispp = curPP(loopInd2);
    %Check to see if .calibrate and .apply are the same. If so then don't
    %test for differences to determine cal status because the prepro might
    %use user data (e.g., baseline simple) that will cause the camparevars
    %to think there's a difference due to calibration having been
    %performed when there isn't (just points selected for example with
    %baseline selected points). 
    [issame,msg] = comparevars(thispp.calibrate,thispp.apply);
    if issame
      %Check to see if .out field has something in it. If so then assume
      %it's been calibrated. Note that it probably doesn't make huge
      %difference since both .calibrate and .apply are the same operation
      %but for some pp (like baseline simple) this is the case.
      if ~isempty(thispp.out)
        out = true;
        return
      end

    else
      defaultprepro = preprocess('default',thispp.keyword);
      %Compare current preprocessing to default. If there are changes then
      %assume it's been calibrated. If not then either it's not calibrated or
      %calibration and apply are the same so it doesn't matter.
      [issame,msg] = comparevars(thispp,defaultprepro);
      if ~issame
        out = true;
        return
      end
    end
  end
end

%--------------------------
function out = optiondefs()

defs = {
%name                    tab              datatype        valid                 userlevel       description
'filter_prompt'          'Standard'       'select'        {'on' 'off'}          'novice'        'Prompt for selecting model filter fields. If off then defaults are selected.';
'filter'                 'Standard'       'cell(vector)'  ''                    'novice'        'n x 3 cell array of filter information (see GETMODELOUTPUTS).';
'bin_options'            'Standard'       'struct'        ''                    'novice'        'Structure of options to pass to bin2scale for data concatenation.';
'preprocessing'          'Standard'       'cell(vector)'  ''                    'novice'        'Prompt for selecting model filter fields. If off then defaults are selected.';
'label_threshold'        'Standard'       'double'        'float(0:inf)'        'novice'        'n x 3 cell array of filter information (see GETMODELOUTPUTS).';
'post_join_model'        'Standard'       'struct'        ''                    'novice'        'Structure of options to pass to bin2scale for data concatenation.';
'apply_model'            'Standard'       'select'        {'on' 'off'}          'novice'        'Structure of options to pass to bin2scale for data concatenation.';
};

out = makesubops(defs);
