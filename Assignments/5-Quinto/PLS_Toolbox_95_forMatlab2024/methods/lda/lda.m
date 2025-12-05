function varargout = lda(varargin)
%LDA Linear discriminant analysis.
% LDA is a Linear method for discriminant analysis applied to input X and Y blocks (or an X-block
% dataset containing class details as a row dimension class set).
% A supplied y-block indicates which samples are in the class(es) of
% interest by a vector of class numbers indicating class assignments: y = [1 1 3 2]';
% NOTE: When a vector of class numbers is used, class zero(0) is reserved for
% “unknown” samples and, thus, samples of class zero
% are never used when calibrating an LDA model. The model will include
% predictions for these samples.
%
% The predicted probability of each class is included in the output model
% structure in the field:
%
%  model.details.predprobability
%
% INPUTS:
%        x  = X-block (predictor block) class "double" or "dataset",
% OPTIONAL INPUT:
%    y = Y-block (OPTIONAL if (x) is a dataset containing classes for
%    sample mode (mode 1) otherwise, (y) is one of:
%     (A) column vector of sample classes for each sample in x -
%       OPTIONAL if (x) is a dataset containing classes for sample
%       mode (mode 1)
%     (B) a logical array with 1 indicating class membership for each
%       sample (rows) in one or more classes (columns)
%   or (C) a cell containing the classes to model: e.g. {2 3} (requires
%       x to be a dataset object)
%
% OPTIONAL INPUT:
%  options = structure array with the following fields:
%          display: [ 'off' | {'on'} ]      governs level of display to command window.
%            plots: [ 'none' | {'final'} ]  governs level of plotting.
%  preprocessing: {[] []} preprocessing structures for x and y blocks (see PREPROCESS).
%     classset: [ 1 ] indicates which class set in x to use when no
%          y-block is provided.
%     blockdetails: [ {'standard'} | 'all' ]  Extent of detail included in model.
%                     'standard' keeps only y-block, 'all' keeps both x- and y- blocks
%    algorithm: [ {'svd'} | 'eig'] 'svd' is the default option
%        ncomp: [3] Number of decomposition components to use
%		 priorprob: [ ] Vector of prior probabilities of observing each class. If any class prior
%					is "Inf", the frequency of observation of that class in the calibration is
%					used as its prior probability. If all priors are Inf, this has the effect of
%					providing the fewest incorrect predictions assuming that the probability of
%					observing a given class in future samples is similar to the frequency that
%					class in the calibration set. The default [] uses all ones i.e. equal priors.
%     lambda : [{0.001}] Regularization parameter. Only applied when
%                        'algorithm' is 'eig'
% strictthreshold: [0.5] Probability threshold for assigning a sample to a
%          class. Affects model.classification.inclass.
%   predictionrule: { {'mostprobable'} | 'strict' ] governs which
%          classification prediction statistics appear first in
%          the confusion matrix and confusion table summaries.
%         waitbar : [ 'off' |{'auto'}| 'on' ] governs use of waitbar during
%                   analysis. 'auto' shows waitbar if delay will likely be
%          longer than a reasonable waiting period.
%
% OUTPUT:
%   model = standard model structure containing the LDA model (See MODELSTRUCT).
%   pred = structure array with predictions
%   valid = structure array with predictions
%
%I/O: model = lda(x,y,options); %identifies model (calibration step)
%I/O: model = lda(x,options); %identifies model (calibration step)
%I/O: pred = lda(x,model,options);  %makes predictions with a new X-block
%I/O: valid = lda(x,y,model,options); %makes predictions with new X- & sample classes
%I/O: options = lda('options');        %returns a default options structure
%I/O: lda demo
%
%See also: LREG, CLASS2LOGICAL, CROSSVAL
%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
if nargin==0;
  analysis lda
  return
end

modelgroups = {};  %and to model all groups
ydatasource = [];  %will hold y datasource info IF we find a y-block
if nargin>1
  [varargin, modelgroups] = parsevarargin(varargin{:});
elseif nargin==1 & ischar(varargin{1}) %Help, Demo, Options
  options = [];
  options.name          = 'options';
  options.display       = 'on';
  options.plots         = 'none';
  options.blockdetails  = 'standard';  %level of details
  options.classset      = 1;    %class set to use (when no y provided)
  options.cvi           = [];
  options.preprocessing = {[] []};  %See preprocess
  options.waitbar       = 'on';
  options.algorithm     = 'svd';
  options.ncomp         = 3;        % # decomposition components to use
  options.lambda        = 0.001;
  options.priorprob     = [];       %prior probabilities
  options.strictthreshold = 0.5;    %probability threshold for class assign
  options.predictionrule = 'mostprobable';
  options.definitions   = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
  
else
  error(['Input number of components () is missing.']);
end

% find options, reconcile and store for later
% We'll pass most options to LDAIMPL but some will be specially handled here
[varargin, options, optsind, modelind] = modifyoptions(varargin{:});

%convert x to a dataset object if it isn't already
if ~isa(varargin{1},'dataset')
  varargin{1} = dataset(varargin{1});
end

%deal with missing y-block (create if we can)
[varargin, modelgroups, nonzero] = handlemissingyblock(varargin, options, optsind, modelind, modelgroups);

%grab datasource and include info now, before we change the dataset include field
datasource = getdatasource(varargin{1});
originalinclude = varargin{1}.include{1};

%no model? this is a calibrate call,
[varargin] = checkforclassesory(nonzero, modelind, optsind, varargin{:});

[varargin] = checklogicalycolumns(varargin{:});

[varargin] = yclasszero2nan(nonzero, varargin{:});

model = ldaimpl(varargin{:});
%I/O: [model] = lreg(x,y,options);
%I/O: [model] = lreg(x,y,nhid,options);
%I/O:  [pred] = lreg(x,model,options);
%I/O: [valid] = lreg(x,y,model,options);

%copy model over to DA structure
model = copytoDA(model, modelind, varargin{:});

model = resetmodeltype(model, modelind, options);

%set prediction help info
model = setpredictionhelp(model);

%store original include field
model = storeoriginalfields(model, originalinclude, modelgroups, datasource, ydatasource, varargin{:});

% % Set model.detail.probability
% model = setpredprobability(varargin{1}, model);

% update .classification
mcopts.strictthreshold = options.strictthreshold;
if isempty(modelind) %| options.rawmodel
  %calibration of model
  model = multiclassifications(model, mcopts);
else
  %when applying to new data
  model = multiclassifications(varargin{modelind},model, mcopts);
end

%deal with plots
try
  switch lower(options.plots)
    case 'final'
      if isempty(modelind)  %no model found in inputs? just show output
        plotloads(model);
        plotscores(model);
      else   %model given in inputs - this is a prediction...
        plotscores(varargin{modelind},model);
      end
  end
catch
  warning('EVRI:PlottingError',lasterr)
end

%prepare output
if nargout>0;
  varargout = {model};
end
end

%--------------------------------------------------------------------------
% augment logical array ctest to have as many columns as ccal
function ctestnew = augmentlogicalcolumns(ccal, ctest)
if ~isdataset(ccal) | ~isdataset(ctest) | ~islogical(ctest.data)
  ctestnew = ctest;
  return
end
% recover the non-logical y implied by ctest
[Y, I] = max(ctest.data,[],2);
y = ctest.class{2}(I);
y = y(:)';  %make sure it is a ROW vector (e.g. when only one class present)
ncy=size(ccal,2);
[ntx, nty] = size(ctest);

% extend ctest by as many columns are needed by extending y
nclass1 = max(1,max(y))+1;
nclass2 = nclass1-1 + ncy-nty;
y2 = [y nclass1:nclass2];
ctestnew = class2logical(y2);
ctestnew = ctestnew(1:ntx,:);
end

%--------------------------------------------------------------------------
function [varargin, modelgroups] = parsevarargin(varargin)
% varargin = varargin{1};
modelgroups = [];
nargin = length(varargin);
% (x,y,...       [calibrate]
% (x,options,... [calibrate]
% (x,modl,...    [validate/predict]
% (x,{groups},... [calibrate]
% (x,[],...       [calibrate]
if ~ismodel(varargin{2}) & ~isstruct(varargin{2})
  if isa(varargin{2},'cell') | isempty(varargin{2})
    % (x,{groups},... [calibrate]
    % (x,[],...       [calibrate]
    modelgroups = varargin{2};
    varargin{2} = [];
    
  elseif size(varargin{1},1)>1 & ~isdataset(varargin{2}) & numel(varargin{2})<=1;
    % (x,nhid,...   [calibrate]
    varargin(3:end+1) = varargin(2:end);
    varargin{2}       = [];           %filled in later
    
  elseif isa(varargin{2},'dataset')
    % (x,y_dataset,...       [calibrate]
    ydatasource = getdatasource(varargin{2});
    if ~islogical(varargin{2}.data);
      uniqueclasses = unique(varargin{2}.data(varargin{2}.include{1},varargin{2}.include{2}));
      % Do not model class 0 if there are more than 2 classes
      if length(uniqueclasses)>2
        uniqueclasses=setdiff(uniqueclasses,0);
      end
      temp = class2logical(varargin{2}.data(:,varargin{2}.include{2}),uniqueclasses);  %force to be logical
      varargin{2} = copydsfields(varargin{2},temp,1);
    end
    
  elseif ~isa(varargin{2},'logical')
    if size(varargin{1},1) == size(varargin{2},1) | ...
        (size(varargin{2},1)==1 & size(varargin{1},1) == size(varargin{2},2))
      % (x,y_nonlogical,...       [calibrate]
      uniqueclasses = unique(varargin{2});
      % Do not model class 0 if there are more than 2 classes
      if length(uniqueclasses)>2
        uniqueclasses=setdiff(uniqueclasses,0);
      end
      varargin{2} = class2logical(varargin{2}, uniqueclasses);  %force to be logical
    else
      varargin(3:end+1) = varargin(2:end);
      varargin{2}       = [];           %filled in later
    end
    
  end
  
else
  % (x,options,... [calibrate]
  % (x[dataset],modl,...    [validate]
  varargin(3:end+1) = varargin(2:end);
  varargin{2}       = [];           %filled in later
end
end

%--------------------------------------------------------------------------
function [varargin, options, optsind, modelind] = modifyoptions(varargin)
%find options, reconcile and store for later
% We'll pass most options to LDAIMPL but some will be specially handled here
optsind = [];
modelind = [];
compind = [];
for j=1:length(varargin);
  if ismodel(varargin{j})
    modelind = j;
  elseif isstruct(varargin{j})
    optsind = j;
  elseif isscalar(varargin{j})
    compind = j;
  end
end
if isempty(optsind);
  %no options found, create some and add to end
  varargin{end+1} = lda('options');
  optsind = length(varargin);
else
  %found options, reconcile with standard options
  varargin{optsind} = reconopts(varargin{optsind},'lda',{'outputversion' 'rawmodel'});
end
options = varargin{optsind};
if ~isempty(compind)
  varargin{optsind}.ncomp = varargin{compind};
end
varargin{optsind}.plots = 'none';   %hard-set options for plots, we'll do them ourselves
end

%--------------------------------------------------------------------------
function [varargin, modelgroups, nonzero] = handlemissingyblock(varargin, options, optsind, modelind, modelgroups)
%deal with missing y-block (create if we can)
nonzero     = [];  %default is to include all specified samples
if isempty(varargin{2})
  %try to create from x (if we can)
  
  %Check if we're doing a prediction,
  if ~isempty(modelind) %& ~options.rawmodel
    %doing predition...
    %try several things (different ones will work depending on the version
    %of the model they are predicting with)
    groups = {};
    caly = varargin{modelind}.detail.data{2};
    if isfield(varargin{modelind}.detail,'modelgroups')
      %are the groups stored in the model?
      groups = varargin{modelind}.detail.modelgroups;
    end
    if isempty(groups) & isfield(caly.userdata,'groups')
      %no modelgroups field in model (or was empty)?
      %look in userdata of calibration y-block for groups field
      groups = caly.userdata.groups;
    end
    if isempty(groups) & options.classset>0
      %nothing else available? base our y-block on the MODELED classes
      if size(varargin{modelind}.detail.class,3)>=options.classset ...
          & ~isempty(varargin{modelind}.detail.class{1,1,options.classset});
        for j=1:size(caly,2);
          groups{j} = unique(varargin{modelind}.detail.class{1,1,options.classset}(caly.data(:,j)==1));
        end
      end
    end
    modelgroups = groups;  %store back as if this was input by user (to store in prediction structure later)
    
    if isa(varargin{1},'dataset')
      if options.classset>0 & (~isempty(groups) | (size(varargin{1}.class,2)>=options.classset & ~isempty(varargin{1}.class{1,options.classset}) & any(varargin{1}.class{1,options.classset})))
        %if we have groups OR classes are NOT empty
        % Verify that options.classset is not larger than size(varargin{1}.classlookup,2);
        % note that class2logical uses
        % clslookup   = cls.classlookup{1,classset};   where cls is 1st arg
        if size(varargin{1}.classlookup,2) < options.classset
          class = [];
          nonzero = [];
        else
          [class,nonzero] = class2logical(varargin{1},groups,options.classset); %create y-block from x
        end
        if ~isempty(class);
          class.include{1} = varargin{1}.include{1};
        end
      else
        %if no groups are set and classes are empty, just do an empty
        %(note, this is done for prediction mode only)
        class = [];
        nonzero = [];
      end
    else
      class = [];
    end
    
  else
    %No model, just try creating from x-block classes
    groups = modelgroups;
    if isa(varargin{1},'dataset')
      [class,nonzero] = class2logical(varargin{1},groups,options.classset); %create y-block from x
      if ~isempty(class) & isempty(groups) & size(class,2)==1 & length(nonzero)<size(class,1)
        groups = {0 class.class{2}};
        [class,nonzero] = class2logical(varargin{1},groups,options.classset); %create y-block from x
      end
      if ~isempty(class);
        class.include{1} = varargin{1}.include{1};
      end
    else
      class = [];
    end
  end
  varargin{2}       = class;
  
else
  %we got classes or a logical y-block explictly, look for rows with any assignment
  temp = varargin{2};
  if isa(varargin{2},'dataset');
    if size(temp.class,2)>=options.classset
      tempclasses = temp.class{1,options.classset};
    else
      tempclasses = [];
    end
    temp = temp.data(:,temp.include{2});
  else
    tempclasses = [];
  end
  if ~islogical(temp);
    %NOT logical? include any with non-zero class assignment
    nonzero = find(any(temp,2));
  else
    %is logical so...
    if ~isempty(tempclasses)
      %did we have classes? use those to exclude items
      nonzero = find(tempclasses);
    else
      %no classes?
      if size(temp,2)>1;
        %more than one column, include everything which has non-zero row
        nonzero = find(any(temp,2));
      else
        %only one column? assume everything is valid
        nonzero = 1:size(temp,1);
      end
    end
  end
end
end

%--------------------------------------------------------------------------
function [varargin] = checkforclassesory(nonzero, modelind, optsind, varargin)
options = varargin{optsind};

if isempty(modelind) %| options.rawmodel
  %no model, we MUST have y or classes in x
  if isempty(varargin{2});
    error('Sample classes must be supplied as (y) or in (x) with classes in first mode');
  end
  
  if ~isempty(nonzero);
    %drop class=0 samples (never modeled)
    newinclude = intersect(varargin{1}.include{1},nonzero);
    if length(newinclude)~=length(varargin{1}.include{1});
      varargin{1}.include{1} = newinclude;
      if isa(varargin{2},'dataset') & size(varargin{2},1)==size(varargin{1},1);
        varargin{2}.include{1} = newinclude;
      end
      if strcmp(options.display,'on')
        disp('Warning: Samples marked as class zero were excluded from modeling');
      end
    end
  end
  %check for all samples same class
  temp = varargin{2}(varargin{1}.include{1},:);
  if isa(temp,'dataset'); temp = temp.data; end
  if length(unique(temp))==1
    error('Samples from at least two non-zero classes must be included in model');
  end
end
end

%--------------------------------------------------------------------------
function [varargin] = checklogicalycolumns(varargin);
if length(varargin)>2 & ismodel(varargin{3}) & isdataset(varargin{2}) & islogical(varargin{2}.data)
  % lda(x, y, model,...) case.
  % Ensure logical y has same number of columns as model.detail.includ{2,2}
  sizey = size(varargin{2},2);
  inc = varargin{3}.detail.includ{2,2};
  
  if sizey < length(inc)
    % augment the test data logical array to have at least as many columns
    % as model's logical detail.data{2} array.
    % (ccal = varargin{3}.detail.data{2};   ctest = varargin{2};)
    varargin{2} = augmentlogicalcolumns(varargin{3}.detail.data{2}, varargin{2});
  end
end
end

%--------------------------------------------------------------------------
function [varargin] = yclasszero2nan(nonzero, varargin);
if ~isempty(varargin{2}) & ~isempty(nonzero);
  %mark class=0 samples as NaN in y-block (so PLS knows how to handle them)
  arezero = setdiff(1:size(varargin{2},1),nonzero);
  if ~isempty(arezero);
    if isdataset(varargin{2})
      varargin{2}.data = double(varargin{2}.data);  %must be double to use NaNs
      varargin{2}.data(arezero,:) = NaN;
    else
      varargin{2} = double(varargin{2});
      varargin{2}(arezero,:) = NaN;
    end
  end
end
end

%--------------------------------------------------------------------------
function model = copytoDA(model, modelind, varargin);
%copy model over to LDA structure
if ~isempty(modelind)
  template = varargin{modelind};
else
  template = evrimodel('lda');
end
if isfield(template,'content');
  fylds = fieldnames(template.content)';
else
  fylds = fieldnames(template)';
end
fylds = setdiff(fylds,{'detail','modeltype','help','description'});
if isfield(model,'content');
  modelfylds = fieldnames(model.content)';
else
  modelfylds = fieldnames(model)';
end
fylds = intersect(fylds,modelfylds);
for f = fylds;
  template.(f{:}) = model.(f{:});
end

%copy .detail fields too
mdetail = model.detail;
tdetail = template.detail;
fylds = fieldnames(tdetail)';
for f = fylds;
  if isfield(mdetail,f{:});
    tdetail.(f{:}) = mdetail.(f{:});
  end
end
template.detail = tdetail;
model = template;

% need to add the model.classification field manually
model.classification = template.classification;
end

%--------------------------------------------------------------------------
function [model] = setpredictionhelp(model);
%set prediction help info
model.help.predictions  = makepredhelp({
  'Q Residuals'      'ssqresiduals{1}'          'scalar'
  });
model = addhelpyvars(model);

%and add indicators for class probabilities
%Grab y-block label information
yinclude = model.detail.includ{2,2};
ny = length(yinclude);  %number of y-block columns
lbl = model.detail.label{2,2};  %y-block labels
if isempty(lbl)  %no labels given, fake them
  lbl = [ones(ny,1)*'Y' num2str([1:ny]') repmat(' Probability',ny,1)];
else
  lbl = lbl(yinclude,:);
end
%create three-column cell of all info
lbl = [str2cell(lbl) str2cell(sprintf('detail.predprobability(:,%i)\n',1:ny)) repmat({'scalar'},ny,1)];
model.help.predictions = [model.help.predictions(1:ny) makepredhelp(lbl) model.help.predictions(ny+1:end)];
end

%--------------------------------------------------------------------------
function [model] = storeoriginalfields(model, originalinclude, modelgroups, datasource, ydatasource, varargin)
%store original include field
model.detail.originalinclude = {originalinclude};
model.detail.modelgroups = modelgroups;  %store modelgroup info (may be empty, but store either way)
model.datasource{1} = datasource;  %insert datasource info we grabbed earlier
if ~isempty(ydatasource)
  model.datasource{2} = ydatasource;
end

%store original y-block (logical)
temp = varargin{2};
if ~isempty(temp)
  if isa(temp,'dataset')
    temp = temp.data;
  end
  model.detail.data{2}.data = temp;
end
end

%--------------------------------------------------------------------------
function [model] = resetmodeltype(model, modelind, options)
if ~isempty(modelind)
  varargin{modelind}.modeltype = 'LDA';  %reset back to model type LDA
  if ~isfield(options,'rawmodel') | ~options.rawmodel
    model.modeltype = 'LDA_PRED';  %hard-code as LDA Prediction type model
  else
    model.modeltype = 'LDA';  %hard-code as LDA model (rawmodel call)
  end
else
  model.modeltype = 'LDA';  %hard-code as LDA type model
end
end

%--------------------------------------------------------------------------
function [model] = setpredprobability(x, model)
% Convert prediction into per class probability for all samples

  yp = model.pred{1,2};

% Calc softmax probability here for all samples using yp (preprocessed y)  
  prob = getsoftmax(yp);
  model.detail.predprobability = prob;
end

%--------------------------
function out = optiondefs()

defs = {

%name                    tab           datatype        valid                            userlevel       description
'display'                'Display'     'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
'displaymf'              'Display'     'select'        {'on' 'off'}                     'advanced'      'Governs level of minFunc display.';
'plots'                  'Display'     'select'        {'none' 'final'}                   'novice'        'Governs level of plotting.';
'preprocessing'          'Standard'    'cell(vector)'  ''                               'novice'        'Cell of Preprocessing Steps. Cell 1 is X-block preprocessing, Cell 2 is Y-block preprocessing';
'algorithm'              'Standard'    'select'        {'svd' 'eig'}           'novice'   'Decomposition method to use. "svd" is default. Regularization only is applied to "eig"'; 
'ncomp'                  'Parameters'  'double'          'int(1:inf)'                  'novice'        'Number of decomposition components to use. Default is 3.';
'lambda'                 'Parameters'  'double'        'float(0:inf)'                  'novice'         'Regularization parameter.';
'blockdetails'           'Standard'      'select'        {'standard' 'all'}               'novice'        'Extent of detail included in model. ''standard'' keeps only y-block, ''all'' keeps both x- and y- blocks.'
'classset'               'Standard'       'double'          'int(1:inf)'                  'novice'        'Class set to model (if no y-block passed)';
'priorprob'              'Standard'       'mode'          'float(0:inf)'                  'advanced'      'Not yet implemented.';
'strictthreshold'        'Classification'     'double'        'float(0:1)'                'advanced'    'Threshold probability for associating sample with a class in model.classification.inclass. (default = 0.5).';
'predictionrule'         'Classification'     'select'    {'mostprobable' 'strict' }      'advanced'    'Specifies which classification preciction results appear first in confusion matrix window opened from Analysis (default = ''mostprobable'').';
};

out = makesubops(defs);
end
