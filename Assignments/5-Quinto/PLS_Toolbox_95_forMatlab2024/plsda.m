function varargout = plsda(varargin)
%PLSDA Partial least squares discriminant analysis.
% PLSDA is a multivariate inverse least squares discrimination method used
%  to classify samples. The y-block in a PLSDA model indicates which
%  samples are in the class(es) of interest through either
%  (A) a column vector of class numbers indicating class asignments:
%     y = [1 1 3 2]';
%  (B) a matrix of one or more columns containing a logical zero (= not in
%   class) or one (= in class) for each sample (row):
%     y = [1 0 0;
%          1 0 0;
%          0 0 1;
%          0 1 0]
%  NOTE: When a vector of class numbers is used (case A, above), class zero
%  (0) is reserved for "unknown" samples and, thus, samples of class zero
%  are never used when calibrating a PLSDA model. The model will include
%  predictions for these samples.
%
%  The prediction from a PLSDA model is a value of nominally zero or one. A
%  value closer to zero indicates the new sample is NOT in the modeled
%  class; a value of one indicates a sample is in the modeled class. In
%  practice a threshold between zero and one is determined above which a
%  sample is in the class and below which a sample is not in the class
%  (See, for example, PLSDTHRES). Similarly, a probability of a sample
%  being inside or outside the class can be calculated using DISCRIMPROB.
%  The predicted probability of each class is included in the output model
%  structure in the field:
%    model.details.predprobability
%
%  INPUTS:
%        x  = X-block (predictor block) class "double" or "dataset",
%        y  = Y-block (OPTIONAL if (x) is a dataset containing classes for
%        sample mode (mode 1) otherwise, (y) is one of:
%         (A) column vector of sample classes for each sample in x -
%             OPTIONAL if (x) is a dataset containing classes for sample
%             mode (mode 1)
%         (B) a logical array with 1 indicating class membership for each
%             sample (rows) in one or more classes (columns)
%      or (C) a cell containing the classes to model: e.g. {2 3} (requires
%             x to be a dataset object)
%    ncomp  = the number of latent variables to be calculated (positive integer scalar).
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%          display: [ 'off' | {'on'} ]      governs level of display to command window.
%            plots: [ 'none' | {'final'} ]  governs level of plotting.
%    preprocessing: {[] []}  preprocessing structures for x and y blocks (see PREPROCESS).
%        priorprob: [ ] Vector of prior probabilities of observing each class.
%                   If any class prior is "Inf", the frequency of observation of that
%                   class in the calibration is used as its prior probability. If all
%                   priors are Inf, this has the effect of providing the fewest incorrect
%                   predictions assuming that the probability of observing a given class
%                   in future samples is similar to the frequency that class in the
%                   calibration set. The default [] uses all ones i.e. equal priors.
%                   NOTE: the "prior" option from older versions of the
%                   software had a bug which caused inverted behavior for
%                   this feature. The field name was changed to avoid
%                   confusion after the bug was fixed.
%         classset: [ 1 ] indicates which class set in x to use when no
%                   y-block is provided. 
%        algorithm: [ 'nip' | {'sim'} | 'dspls' | 'robustpls' ]     
%                    PLS algorithm to use: NIPALS, SIMPLS, DSPLS, or robust
%                    PLS.
%    orthogonalize: [ {'no'} | 'yes' ] Orthogonalize model to condense
%                    y-block variance into first latent variable; 'yes' =
%                    produce orthogonalized model. Regression vector and
%                    predictions are NOT changed by this option. Only the
%                    loadings, weights, and scores.
%     blockdetails: [ {'standard'} | 'all' ]  Extent of detail included in model.
%                     'standard' keeps only y-block, 'all' keeps both x- and y- blocks
%  strictthreshold: [0.5] Probability threshold for assigning a sample to a
%                   class. Affects model.classification.inclass.
%   predictionrule: { {'mostprobable'} | 'strict' ] governs which
%                   classification prediction statistics appear first in
%                   the confusion matrix and confusion table summaries.
%
%  OUTPUT:
%     model = standard model structure containing the PLSDA model (See MODELSTRUCT).
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: model = plsda(x,y,ncomp,options);  %identifies model (calibration step)
%I/O: model = plsda(x,ncomp,options);  %identifies model (calibration step)
%I/O: pred  = plsda(x,model,options);    %makes predictions with a new X-block
%I/O: valid = plsda(x,y,model,options);  %makes predictions with new X- & sample classes
%I/O: options = plsda('options');        %returns a default options structure
%I/O: plsda demo
%
%See also: CLASS2LOGICAL, COMPRESSMODEL, CROSSVAL, DISCRIMPROB, KNN, MODELSELECTOR, PLS, PLSDAROC, PLSDTHRES, SIMCA, VIP

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 3/04
%jms 4/04 -fixed to allow vector of classes as y (either row or column)
%jms 4/20/04 -changed help
%   -modified handling of dataset as Y and added support for include field
%jms 5/6/04 -added test for all samples same class
%jms 5/11/04 -make nonzero an index vector (not logical) with supplied y-block
%jms 6/9/04 -convert x to dataset if not already
%   -empty prob. matrix before pred
%jms 6/19/04 -better handle application of model to new data (use modeled
%    classes to create new y-block)
%jms 9/1/04 -fixed bugs associated with passing the class2logical output as y
%     - added support for giving {groups} as input
%jms 5/22/05 -fixed copy error when y is logical non-dataset
%jms 10/31/05 -fixed bug when no y is supplied and x is not DSO
%jms 11/7/05 -fixed bug when y is logical and no classes present.
%BK 6/21/2016 - added multi-way support for PLSDA

if nargin==0;
  analysis plsda
  return
end

nonzero = [];  %default is to include all specified samples
modelgroups = {};  %and to model all groups
ydatasource = [];  %will hold y datasource info IF we find a y-block
if nargin>1;
  % (x,ncomp,...   [calibrate]
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
      % (x,ncomp,...   [calibrate]
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
      % (x,y_nonlogical,...       [calibrate]
      uniqueclasses = unique(varargin{2});
      % Do not model class 0 if there are more than 2 classes
      if length(uniqueclasses)>2
        uniqueclasses=setdiff(uniqueclasses,0);
      end
      varargin{2} = class2logical(varargin{2}, uniqueclasses);  %force to be logical
      
    end

  else
    % (x,options,... [calibrate]
    % (x[dataset],modl,...    [validate]
    varargin(3:end+1) = varargin(2:end);
    varargin{2}       = [];           %filled in later
  end

elseif nargin==1 & ischar(varargin{1}) %Help, Demo, Options

  options = [];
  options.name          = 'options';
  options.display       = 'on';     %Displays output to the command window
  options.plots         = 'final';  %Governs plots to make
  options.preprocessing = {[] []};  %See preprocess
  options.algorithm     = 'sim';    %SIMPLS algorithm
  options.orthogonalize = 'off';
  options.blockdetails  = 'standard';  %level of details
  options.classset      = 1;    %class set to use (when no y provided)
  options.priorprob     = [];   %prior probabilities
  options.weights       = 'none';
  options.weightsvect   = [];
  options.confidencelimit = 0.95;
  options.roptions.alpha = 0.75; %Alpha for robust methods between 0.5 and 1.
  options.rawmodel      = 0;
  options.strictthreshold = 0.5;    %probability threshold for class assign
  options.predictionrule = 'mostprobable';
  options.usegaussianparams = 'yes';
  options.definitions   = @optiondefs;

  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
  
else
  error(['Input number of components (NCOMP) is missing.']);
end

%find options, reconcile and store for later
% We'll pass most options to PLS but some will be specially handled here
optsind = [];
modelind = [];
for j=1:length(varargin);
  if ismodel(varargin{j})
    modelind = j;
  elseif isstruct(varargin{j})
    optsind = j;
  end
end
if isempty(optsind);
  %no options found, create some and add to end
  varargin{end+1} = plsda('options');
  optsind = length(varargin);
else
  %found options, reconcile with standard options
  varargin{optsind} = reconopts(varargin{optsind},'plsda',{'outputversion' 'weights' 'rawmodel'});
end
options = varargin{optsind};
varargin{optsind}.plots = 'none';   %hard-set options for plots, we'll do them ourselves

if isfield(options,'prior')
  error('The option "prior" has been changed to "priorprob" and the behavior has changed. Please review the documentation for the new option before using it.');
end

%convert x to a dataset object if it isn't already
if ~isa(varargin{1},'dataset')
  varargin{1} = dataset(varargin{1});
end

%deal with missing y-block (create if we can)
if isempty(varargin{2})
  %try to create from x (if we can)

  %Check if we're doing a prediction,
  if ~isempty(modelind) & ~options.rawmodel
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

%grab datasource and include info now, before we change the dataset include field
datasource = getdatasource(varargin{1});
originalinclude = varargin{1}.include{1};

%no model? this is a calibrate call,
if isempty(modelind) | options.rawmodel
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

if length(varargin)>2 & ismodel(varargin{3}) & isdataset(varargin{2}) & islogical(varargin{2}.data)
  % plsda(x, y, model,...) case. 
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

%Call PLS (or NPLS for multi-way data)
if (ndims(varargin{1}) > 2)
  model = npls(varargin{:});
else
  model = pls(varargin{:});
end

%copy model over to PLSDA structure
if ~isempty(modelind)
  template = varargin{modelind};
else
  template = modelstruct('plsda');
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

if ~isempty(modelind)
  varargin{modelind}.modeltype = 'PLSDA';  %reset back to model type PLSDA
  if ~isfield(options,'rawmodel') | ~options.rawmodel
    model.modeltype = 'PLSDA_PRED';  %hard-code as PLSDA Prediction type model
  else
    model.modeltype = 'PLSDA';  %hard-code as PLSDA model (rawmodel call)
  end
else
  model.modeltype = 'PLSDA';  %hard-code as PLSDA type model
end

%set prediction help info
model.help.predictions  = makepredhelp({
  'Scores'           'scores'                   'vector'
  'Hotelling''s T^2' 'tsqs{1}'                  'scalar'
  'Q Residuals'      'ssqresiduals{1}'          'scalar'
  'T Contributions'  'tcon'                     'vector'
  'Q Contributions'  'qcon'                     'vector'
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

%post-process output
if ~(isempty(modelind) & isfield(options,'rawmodel') & options.rawmodel == 1)   %(unless this is a raw-model call)

  %get indices of samples which actually have classes assigned
  if ~isempty(nonzero)
    isclassed = nonzero;
    isclassed = intersect(isclassed,model.detail.includ{1,1});
  else
    if options.classset>0
      isclassed = model.detail.class{1,1, options.classset}~=0;   % classset?
    else
      isclassed = [];
    end
    if isempty(isclassed)
      if ~isempty(model.detail.data{2})
        isclassed = any(model.detail.data{2}.data,2);
      else
        isclassed = false(model.datasource{1}.size(1),1);
      end
    end
    isclassed = model.detail.includ{1,1}(isclassed(model.detail.includ{1,1}));
  end
  
  if isempty(modelind) | (~isempty(modelind) & isfield(options,'rawmodel') & options.rawmodel == 1) %no model found in inputs? this is a calibrate call
    if ~isempty(isclassed)
      %calculate thresholds and probabilities and rmsec
      for j=1:size(model.pred{2},2);
        if length(options.priorprob)>=j
          myprior = [sum(options.priorprob([1:j-1 j+1:end])) options.priorprob(j)];
        else
          myprior = [];
        end
        [threshold,misclassed,prob,distprob] = plsdthres(model.detail.data{2}.data(isclassed,model.detail.includ{2,2}(j)), ...
          model.pred{2}(isclassed,j),[],myprior,0);
        model.detail.threshold(j) = threshold;
        model.detail.probability{j} = prob;
        model.detail.distprob{j}    = distprob;
        model.detail.classerrc(j,1:varargin{3}) = nan;
        model.detail.classerrc(j,varargin{3}) = mean(mean(misclassed));
        model.detail.misclassedc{j}(1:2,1:varargin{3}) = nan;
        model.detail.misclassedc{j}(:,varargin{3}) = misclassed(:,1);
      end
      model.detail.rmsec(1:size(model.pred{2},2),1:varargin{3}) = nan;
      model.detail.rmsec(:,varargin{3})   = sqrt(mean(model.detail.res{2}(isclassed,:).^2));
    else
      %no samples were classed (?!?) clear RMSEC
      model.detail.rmsec = [];
    end
  else
    %predict call
    if ~isempty(isclassed)
      %predict mode - do RMSEP
      ncomp = size(model.loads{2,1},2);
      for j=1:size(model.pred{2},2);
        pred_inclass = (model.pred{2}(isclassed,j)>=model.detail.threshold(j));
        actually_inclass = model.detail.data{2}.data(isclassed,j);
        sumincls = sum(actually_inclass);
        sumnotincls = sum(~actually_inclass);
        %Add checks for 0 and chanage to inf to avoid divide by zero
        %warning.
        if sumincls == 0
          sumincls = inf;
        end
        if sumnotincls == 0
          sumnotincls = inf;
        end
        
        misclassed = [sum(~actually_inclass & pred_inclass)./sumnotincls;sum(actually_inclass & ~pred_inclass)./sumincls];
        model.detail.classerrp(j,1:ncomp) = nan;
        model.detail.classerrp(j,ncomp) = mean(misclassed);
        model.detail.misclassedp{j}(1:2,1:ncomp) = nan;
        model.detail.misclassedp{j}(:,ncomp) = misclassed;
      end
      model.detail.rmsep(1:size(model.pred{2},2),1:ncomp) = nan;
      %model.detail.rmsep(:,ncomp)   = sqrt(mean(model.detail.res{2}(isclassed,:).^2));
      rmsepvals = model.detail.res{2}(isclassed,:);
      %Remove NaNs if there are any.
      rmsepvals(isnan(rmsepvals)) = [];
      model.detail.rmsep(:,ncomp)   = sqrt(mean(rmsepvals.^2));
    else
      %no samples were classed - clear RMSEP
      model.detail.rmsep = [];
    end
  end

  %Convert prediction into probability scale
  model = Classif.setpredprobability(model);

end

% update .classification
mcopts.strictthreshold = options.strictthreshold;
if isempty(modelind) | options.rawmodel
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

%--------------------------
function out = optiondefs()

defs = {

%name                    tab           datatype        valid                            userlevel       description
'display'                'Display'     'select'        {'on' 'off'}                       'novice'        'Governs level of display.';
'plots'                  'Display'     'select'        {'none' 'final'}                   'novice'        'Governs level of plotting.';
'preprocessing'          'Standard'      'cell(vector)'  ''                               'novice'        'Cell of Preprocessing Steps. Cell 1 is X-block preprocessing, Cell 2 is Y-block preprocessing';
'algorithm'              'Standard'      'select'        {'nip' 'sim' 'dspls' 'robustpls'} 'novice'        'PLS algorithm to use: NIPALS (''nip''), SIMPLS (''sim''), Direct Scores PLS (''dspls''), or Robust algorithm with automatic outlier detection (''robustpls'').';
'orthogonalize'          'Standard'      'select'        {'off' 'on'}                     'novice'        'Orthogonalize model to condense y-block variance into first latent variable ''yes'' = produce orthogonalized model.';
'blockdetails'           'Standard'      'select'        {'standard' 'all'}               'novice'        'Extent of detail included in model. ''standard'' keeps only y-block, ''all'' keeps both x- and y- blocks.'
'classset'               'Standard'       'double'          'int(1:inf)'                  'novice'        'Class set to model (if no y-block passed)';
'priorprob'              'Standard'       'mode'          'float(0:inf)'                  'novice'        'Vector of prior probabilities of observing each class. If any class prior is "Inf", the frequency of observation of that class in the calibration is used as its prior probability. If all priors are Inf, this has the effect of providing the fewest incorrect predictions assuming that the probability of observing a given class in future samples is similar to the frequency that class in the calibration set. The default [] uses all ones i.e. equal priors.';
'weights'                'Standard'       'select'        {'none' 'hist' 'custom'}         'novice'        'Governs sample weighting. ''none'' does no weighting. ''hist'' performs histogram weighting in which large numbers of samples at individual y-values are down-weighted relative to small numbers of samples at other values. ''custom'' uses the weighting specified in the weightsvect option.'
'weightsvect'            'Standard'       'vector'        'float(0:inf)'                   'novice'        'Used only with custom weights. The vector specified must be equal in length to the number of samples in the y block and each element is used as a weight for the corresponding sample. If empty, no sample weighting is done.';
'confidencelimit'        'Standard'       'double'        'float(0:1)'                    'novice'        'Confidence level for Q and T2 limits (fraction between 0 and 1)';
'roptions.alpha'         'Robust Options' 'double'        'float(.5:1)'                   'novice'        '(1-alpha) measures the number of outliers the algorithm should resist. Any value between 0.5 and 1 may be specified (default = 0.75). These options are only used when algorithm is robust PCA.';
'strictthreshold'        'Classification'     'double'        'float(0:1)'                'advanced'    'Threshold probability for associating sample with a class in model.classification.inclass. (default = 0.5).';
'predictionrule'         'Classification'     'select'    {'mostprobable' 'strict' }      'advanced'    'Specifies which classification preciction results appear first in confusion matrix window opened from Analysis (default = ''mostprobable'').';
};

out = makesubops(defs);
