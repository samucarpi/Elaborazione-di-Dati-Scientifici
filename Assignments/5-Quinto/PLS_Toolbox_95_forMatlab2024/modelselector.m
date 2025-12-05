function varargout = modelselector(varargin)
%MODELSELECTOR Create or apply a model selector model.
% A Selector Model is a special model type which, when applied to new data,
% selects between two or more "target" models based on a "trigger" model.
% It is used to implement discrete local models when a single global model
% is not sufficient for all possible scenarios. 
% 
% For example, if a single PCA or PLS model does not perform sufficiently
% for all operating conditions but the operating conditions can be split
% into two or more easier-to-model subsets, a selector model can be used to
% choose between these subset models when applying the models to new data.
%
% Selector models consist of a trigger model (trigger) which can be either
% a classification model (PLSDA, SVMDA, KNN, SIMCA, etc) or a set of one or
% more logical test strings and a set of two or more target models
% (target_1, target_2, etc) which can be any type of standard model
% structure or an empty array [ ] to indicate a null model.  
%
% Guidelines and rules for trigger models:
%  (A) A classification trigger model can be created using one of the
%      classification functions (e.g. PLSDA, SVMDA, KNN, SIMCA). The 
%      model should be built with data representative of the sample types
%      to which each target model can be applied. The number of classes
%      separated by the model dictates the number of target models which
%      can be selected from. The target models should be in the same 
%      order as the numerical class numbers used with the model (e.g. if
%      classes 1, 2 and 3 are used in the trigger model, the target models
%      should be ordered so that target_1 is appropriate if the trigger
%      model finds that a sample is class 1, target_2 is for class 2, and
%      target_3 is for class 3.)
%  (B) Simple logical test strings are specified as a trigger model by
%      passing a cell containing one or more strings which perform a
%      logical test on a variable from the data set. Variables are
%      specified using either a label in double quotes (e.g. "flowrate"),
%      or a axisscale value in quotes and square brackets (e.g. "[1530]").
%      The varaible can be used in any interpretable Matlab expression
%      (including function calls) that returns a logical result. The
%      simplest test could involve one of the Matlab logical comparison
%      operators ( <  >  <=  >=  ==  and ~= ) and a value to which the
%      given variable should be compared. For example, the target model:
%          {'"Fe">1100' '"Fe"<500'} 
%      tests if the variable named "Fe" is greater than 1100. If true, the
%      target_1 model is applied, if not true, "Fe" is tested for being less
%      than 500, and if so, target_2 is selected. If neither test is true,
%      the "default" target model (i.e. target_3) is selected. 
%      Example 2:
%          {'"[1745.3]"<=500'}
%      tests if variable 1745.3 (on the variable axiscale) is less than or
%      equal to 500. If true, target_1 is selected, if not true, default
%      target model is selected. If variable 1745.3 does not exist, it is
%      interpolated from the provided data.
%  (C) Logical test strings to be applied to the prediction from a simple
%      regression (e.g. PLS, MLR, etc) or decomposition (e.g. PCA) model.
%      When passed in this format, the first item in the cell array is a
%      model to be applied to the data followed by a sequence of one or
%      more logical tests to be performed on the predictions from the
%      model application. The format of the logical tests is the same as in
%      case (B) above EXCEPT no variable name or axisscale reference should
%      be given, only the logical operator and value (e.g. '>10'). The
%      tests will be performed on the predictions from the model. It is
%      required that the model predict only one value (thus, a regression
%      model must have only one y-value being predicted and a decomposition
%      model can only have one latent variable or principal component).
%      Example 1:
%           { regmodel '<10' '<100' }
%      applies "regmodel" to the data then tests the predicted values
%      against the tests <10 and <100 for a total of three classes. If the
%      predicted value is <10, the first target model is selected. If it is
%      <100, the second target model is selected. Otherwise, the third
%      (default) model is selected. Note that this method can not generally
%      be used on classification models. Instead, the (A) form of trigger
%      models should be used.
%
% When creating a selector model, there must be at least as many target
% models passed as there are classes (when trigger is a classification
% model) or strings (when trigger is a cell of logical test strings). There
% may also be an additional target model (i.e. the "default" model) which
% is used if none of the classes or tests were positive.
%
% Note that target models may be any standard model structure including
% another selector model (thus allowing multi-layer selector trees).
%
% To apply a selector model, a single row of new data is passed as a
% dataset along with the selector model itself. The output is the selected
% target model (target_model) along with a unique description of the
% "branch(s)" taken to select the target model as a vector of branch
% numbers (applymodel). For example, given a multi-layer selector model
% containing:
%  selector_model  -> target_1 = PCA_model_A1
%                     target_2 = Selector_model -> target_1 = PCA_model_B1
%                                                  target_2 = PCA_model_B2 
%                     target_3 = PCA_model_A2
%          
% a returned value for applymodel of [2 1] implies that the second target
% model was selected from the first layer of target models, and this model
% was another selector model. From that second selector model, the first
% target model (PCA_model_B1) was selected and that is what was returned.
%
% Note that if there are multiple "branches" (trigger models) the data
% passed to modelselector must contain all the data necessary for all
% trigger models within the selector model. If some of those variables are
% not used by a given model, modelselector will automatically discard
% unneeded variables before applying each trigger model.
%
%OPTIONS
% The following can be passed in an options structure after the target
% models:
%         waitbar : [{'off'} | 'on' ] governs display of a waitbar when
%                   making predictions on multiple samples.
%        multiple : [{'otherwise'} | 'mostprobable' | 'fail' ] Governs
%                   behavior when more than one class of a classification
%                   model is assigned. 'fail' will throw an error.
%                   'mostprobable' will choose the target that corresponds
%                   to the most probable class. 'otherwise' will use the
%                   last target (otherwise.)
%   outputfilters : {} Provides information on how to filter output results
%                   after selection of a target. The value of this option
%                   is stored in the model indicating how the output of
%                   each corresponding target should be indexed. It is a
%                   cell array equal in length to the number of targets.
%                   Each cell element can contain another cell array with
%                   one or more of the following:
%                     (A) a standard subscript indexing as defined by the
%                         Matlab "substruct" command 
%                     (B) a string or numerical constant to be included
%                         verbatim
%                   Each content of the cell(to be concatenated row-wise).
%                   If any top-level cell elements are missing or the
%                   corresponding element is empty, no filtering is done.
%                     EXAMPLE:
%                      { 
%                        {substruct('.','prediction') substruct('.','Q')}
%                        {substruct('.','prediction') [0] } 
%                        { }
%                      }
%                    Would grab the "prediction" and "Q" outputs from a
%                    model for the first target and would grab only the
%                    "prediction" field for the second target and add a 0
%                    (zero) to that. No filtering would be done on the
%                    third target.
%    usecvresults : [{'off'}| 'on' ] Governs use of cross-validation
%                   results during an "apply" of classification-based
%                   hierarchical models. This provides a way to test 
%                   the predictions of a hierarhcical model with a pseudo
%                   cross-validation. When 'on', the calibration model is
%                   serched for a sample matching the label(s) on the
%                   sample(s) being predicted. If found, and if
%                   cross-validation results exist for this sample, those
%                   results are used in place of any self-prediction. This
%                   requires that all calibration samples have unique
%                   labels.
%     applytarget : [ 'off' |{'on'}] When 'on' any target that is a model
%                   is automatically applied to the data. Note that
%                   modelselector models are ALWAYS automatically applied
%                   to the data.
%          errors : [{'throw'}| 'struct' | 'string' ] Governs handling of
%                   error targets (structure with field "error" and a
%                   string). If 'throw', the content of the error field is
%                   thrown as an error. If 'string' the string content of
%                   the error field is returned with a prefix of "ERROR: ".
%                   If 'struct' the entire error structure is returned.
%      qtestlimit : [3] Governs Q limit testing for PLSDA models (over this
%                   reduced value = otherwise branch is used) 
%     t2testlimit : [3] Governs T2 limit testing for PLSDA models (over
%                   this reduced value = otherwise branch is used)  
%   addtrigmodels : {'trendtool'} Cell array listing which model types
%                   (other than standard) are allowed as trigger models.
%                   Typically, only models that output scores or a DataSet
%                   object can be used as a trigger model.
%         waitbar : [{'off'} | 'on'] governs display of waitbar while processing
%
%I/O: model = modelselector(triggermodel,target_1,target_2,...,target_default)
%I/O: [target_model,applymodel] = modelselector(data,model)  %apply (select target)
%
%See also: KNN, LWRPRED, PLSDA, SIMCA, SVMDA

%Copyright (c) Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0; 
  if ~nargout
    modelselectorgui;
  else
    varargout = {modelselectorgui};
  end
  return;
end
if ischar(varargin{1}) %Help, Demo, Options
  if strcmpi(varargin{1},'drop')
    %drop command for GUI
    modelselectorgui('dropitem',[],varargin{2},varargin{5})
    return
  end

  options = [];
  options.multiple      = 'otherwise';    %Governs how to handle multiple triggers
  options.outputfilters = {};              %filters to select sub-portions of output results
  options.waitbar       = 'off';           %governs display of waitbar while applying
  options.applytarget   = 'on';               %governs applying of targets models versus returning them as-is
  options.usecvresults  = 'off';          %look for CV results instead of self-prediction (for classification only)
  options.errors        = 'throw';        %Governs handling of "error" targets   [ 'throw' | 'struct' | 'string' ]
  options.qtestlimit    = 3;          %Governs Q limit testing for classification models (over this reduced value = otherwise branch)
  options.t2testlimit   = 3;          %Governs T2 limit testing for classification models (over this reduced value = otherwise branch)
  options.addtrigmodels = {'trendtool'};   %specifies which models (other than standard) are allowed as trigger models
  options.firstcall = true;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
  
end

options = [];
if ~ismodel(varargin{end}) & isstruct(varargin{end})
  %probably an options structure at the end of the inputs
  options = varargin{end};
  varargin = varargin(1:end-1);
end

if length(varargin)<2;
  error('Insufficient number of inputs');
end

if ~isa(varargin{1},'dataset') & ~isnumeric(varargin{1})
  %========================================================================
  %Build model mode

  options = reconopts(options,mfilename);

  %check that trigger model is interpretable
  switch class(varargin{1})
    %---------------------
    % trigger is standard model structure
    case {'evrimodel' 'struct'}
      if isfield(varargin{1},'classification')
        %classification model of some sort, it's OK to use
        nclass = length(varargin{1}.classification.classnums);
      else
        error('Trigger model cannot be of type "%s"',varargin{1}.modeltype)
      end

      %---------------------
      % trigger is trigger string
    case {'cell','char'}
      if ~isa(varargin{1},'cell')
        %single trigger string (select between two models)
        varargin{1} = {varargin{1}};
      end
      %cell of trigger strings
      nclass = length(varargin{1});
      if ismodel(varargin{1}{1});
        %first cell element is a model (regression or PCA or similar model)
        %subtract one from number of classes 
        nclass = nclass-1;
        
        %and check if we can figure out how to use this model as a trigger
        mdl = varargin{1}{1};
        if isfield(mdl,'pred') & size(mdl.pred,2)>1 
          %regression model... 
        elseif isfield(mdl,'loads')
          %not regression model - use scores
        elseif ~ismember(lower(mdl.modeltype),options.addtrigmodels)
          error('Trigger models of type "%s" are not allowed',mdl.modeltype);         
        end        
      end

      %create triggerstring model from trigger strings
      trigger = local_modelstruct('triggerstring');
      trigger.triggers = varargin{1};
      
      if any(cellfun('isempty',trigger.triggers))
        error('Empty trigger string is not permitted.')
      end
      
      %extract labels from trigger strings and store in model
      labels     = cell(0);
      axisscales = [];
      for j=1:nclass;
        [newlabels,newaxisscales,reformedtrigger] = parsetriggerstring(varargin{1}{j});
        labels = [labels;newlabels];
        axisscales = [axisscales newaxisscales];
        preprocess('check_safety',reformedtrigger);
      end
      trigger.detail.label{2,1} = char(labels);
      trigger.detail.axisscale{2,1} = axisscales;

      varargin{1} = trigger;
      
    otherwise
      error('Unrecognized trigger model type')
  end
  
  %check that # of outputs of trigger model is consistent with number of targetmodels passed
  ntargets = length(varargin)-1;
  if ntargets<nclass
    error('Insufficient number of target models for number of classes predicted by trigger model')
  end
  if ntargets>nclass+1  %(allow one extra model for "none of the above" prediction)
    error('Too many target models for number of classes predicted by trigger model')
  end

  %------------------------------------------
  %Create empty modelselector model
  modl = local_modelstruct('modelselector');
  ds = varargin{1}.datasource;
  if ~isempty(ds)  %safe way to extract (in case of empty model)
    ds = ds(1);
  end
  modl.datasource = ds;
  modl.detail.options = options;

  %Insert trigger and target models
  modl.trigger = varargin{1};
  modl.targets = varargin(2:end);
  modl.outputfilters = options.outputfilters;
  
  %combine labels and axisscales of target models
  lbl = {};
  axisscale = modl.trigger.detail.axisscale{2,1};
  for j=1:length(modl.targets);
    if ismodel(modl.targets{j})
      nlbl(j) = size(modl.targets{j}.detail.label{2,1},1);
    else
      nlbl(j) = 0;
    end
  end
  %   [what,where] = sort(nlbl,'descend');  %model with most variables first
  [what,where] = sort(-nlbl);  %model with most variables first (use - to get descend order even with 6.5)
  what = -what;
  for j=where;
    if ismodel(modl.targets{j})
      newlbl = str2cell(modl.targets{j}.detail.label{2,1});
      lbl = [lbl;newlbl(~ismember(newlbl,lbl))];
      axisscale = union(axisscale,modl.targets{j}.detail.axisscale{2,1});
    end
  end

  %add trigger model items (if not already there)
  newlbl = modl.trigger.detail.label{2,1};
  if ~iscell(newlbl);
    newlbl = str2cell(newlbl);
  end
  lbl = [lbl;newlbl(~ismember(newlbl,lbl))];

  %store in top-level model
  modl.detail.label{2} = char(lbl);
  modl.detail.axisscale{2} = axisscale;

  varargout = {modl};
  
else
  %========================================================================
  %Apply mode
  if nargin<2;
    error('Input of selector model required for predict mode')
  end

  valid = [];
  switch length(varargin) %NOTE: cannot use "nargin" here because we may have had options we've removed
    case 2
      %(data,model)
      data = varargin{1};
      model = varargin{2};
    case 3
      %(x,y,model)
      data  = varargin{1};
      valid = varargin{2};
      model = varargin{3};
      if size(valid,1)~=size(data,1)
        error('Number of samples in validation input do not match number of samples in data')
      end
    otherwise
      error('Unrecognized number of inputs')
  end      
  
  if ~ismodel(model) | ~strcmpi(model.modeltype,'modelselector')
    error('Model must be a MODELSELECTOR model type')
  end

  options = reconopts(options,model.detail.options);
  options = reconopts(options,mfilename);

  %- - - - - - - - - - - - - - - - - - - - - - - - - - 
  %1) Apply trigger model 
  predopts = [];
  predopts.plots = 'none';
  predopts.display = 'off';

  switch lower(model.trigger.modeltype)
    case 'triggerstring'
      %special "trigger string" model (logical string test)
      
      localdata = data;
      %check if first item is a model, and apply that first
      if ismodel(model.trigger.triggers{1})
        %apply model and get predictions (as .pred or scores)
        mdl = model.trigger.triggers{1};
        mdl.reducedstats = model.reducedstats;
        pred = mdl.apply(localdata);
        if isdataset(pred) | isnumeric(pred)
          %output was a DSO or numeric? use as-is
          localdata = pred;
        elseif ismodel(pred)
          if isfield(pred,'pred') & size(pred.pred,2)>1
            localdata = dataset(pred.pred{2});
          elseif isfield(pred,'loads')
            localdata = dataset(pred.loads{1});
          else
            error('Cannot interpret output of model type "%s"',mdl.modeltype)
          end
          tempadd = [];
          for addfield = {'t2' 'T2' 'q' 'Q'}
            if ~isempty(pred.(addfield{:}))
              temp = dataset(pred.(addfield{:}));
              temp.label{2} = addfield{:};
              tempadd = [tempadd temp];
            end
          end
          localdata = [localdata tempadd];
        end
        model.trigger.triggers = model.trigger.triggers(2:end); %dump model from list
      end

      applymodel = nan(size(localdata,1),1);  %default if nothing found
      
      ny     = length(model.trigger.triggers);
      %evaluate triggerstrings
      for j=1:ny
        %locate variables and reformed test string needed for this test
        [mylabels,myaxisscales,reformedtrigger] = parsetriggerstring(char(model.trigger.triggers{j}));
        if isempty(mylabels)
          mylabels = myaxisscales;
          if ~isempty(myaxisscales) & isempty(localdata.axisscale{2})
            %axisscale needed, but none exists? assume index
            localdata.axisscale{2} = 1:size(localdata,2);
          end
        end
        %get the necessary data
        mdata = matchvars(mylabels,localdata);
        if ~isempty(mdata)
          mdata = mdata.data;
        else
          errmsg = 'Unable to apply trigger string: %s\nNo matching data found\n';
          if length(mylabels)==1 & ismember(mylabels,{'Q' 'T2' 'q' 't2'})
            errmsg = [errmsg sprintf('Check if model type has parameter %s', mylabels{1})];
          end           
          error(errmsg,model.trigger.triggers{j})       
        end
        
        try
          preprocess('check_safety',reformedtrigger);
          use = eval(reformedtrigger);
        catch
          error('Unable to apply trigger string: %s\nWhen executed as: %s\nError Message: %s',model.trigger.triggers{j},reformedtrigger,lasterr)
        end
        applymodel(use & isnan(applymodel)) = j;
        if ~any(isnan(applymodel))
          %got all we need, stop now
          break;
        end
      end

    otherwise
      if model.trigger.isclassification
        % one of the classification models - apply model
        mdata  = matchvars(model.trigger,data);
        submod = model.trigger;
        submod.reducedstats = model.reducedstats;
        trpred = submod.apply(mdata);
        
        applymodel = trpred.classification.mostprobable;
        multiples  = (sum(trpred.classification.inclasses,2)>1);
                
        %locate cv results for sample(s)
        if strcmpi(options.usecvresults,'on')
          cvlbl = submod.detail.label{1}(submod.detail.includ{1},:);
          cvprd = submod.detail.cvclassification.mostprobable;
          if  ~isempty(cvprd)
            cvmult = (sum(submod.detail.cvclassification.inclasses,2)>1);
            [~,tind,cvind]= intersect(str2cell(mdata.label{1},1),str2cell(cvlbl,1));
            if ~isempty(cvind)
              applymodel(tind) = cvprd(cvind);
              multiples(tind) = cvmult(cvind);
            end
          end
        end
        
        if any(multiples)
          switch options.multiple
            case 'fail'
              error('More than one model was triggered')
            case 'mostprobable'
              %already done above
            otherwise %probably 'otherwise' - say none were triggered
              applymodel(multiples) = nan;
          end
        end
        
        %check for overlimit T2 and/or Q if asked
        if ~isempty(trpred.Q) & options.qtestlimit > 0
          lim = options.qtestlimit;
          if isfield(trpred.detail,'reslim') & strcmp(trpred.reducedstats,'off')
            lim = lim * trpred.detail.reslim{1};
          end
          applymodel(trpred.Q>lim) = nan;
        end
        if ~isempty(trpred.T2) & options.t2testlimit > 0
          lim = options.t2testlimit;
          if isfield(trpred.detail,'tsqlim') & strcmp(trpred.reducedstats,'off')
            lim = lim * trpred.detail.tsqlim{1};
          end
          applymodel(trpred.T2>lim) = nan;
        end

        ny = length(trpred.classification.classnums);
        
      else
        error(['Trigger model cannot be of type ' model.trigger.modeltype])
      end
  end
      
  %- - - - - - - - - - - - - - - - - - - - - - - - - - 
  %2) Use trigger model results to select appropriate sub-model
  if any(isnan(applymodel))
    %none were triggered?
    if length(model.targets)==ny
      error('No models were triggered and no otherwise (default) model was found');
    end
    %"otherwise" model? Use it
    applymodel(isnan(applymodel)) = length(model.targets);
  end
  
  %Identify sub-groups of applymodel assignments and do the next
  %part for each sub-group with all items from the block
  branches     = unique(applymodel);
  appliedmodel = applymodel;
  
  if isnumeric(options.waitbar)
    wbh = options.waitbar;
    options.waitbar = 'recursive';
  elseif strcmpi(options.waitbar,'on') & length(branches)>1
    wbh = waitbar(0,'Applying Hierarchical Model');
  else
    wbh = [];
  end
  
  for gind=1:length(branches);
    try
      use = (applymodel==branches(gind));
      
      submodel = model.targets{branches(gind)};
      if ismodel(submodel);
        %(if empty, just pass out empty)
        type = submodel.modeltype;
        switch lower(type)
          case 'modelselector'
            %If sub-model is selector model, call model selector recursively
            suboptions = options;
            suboptions.firstcall=false;
            if ~isempty(wbh)
              suboptions.waitbar = wbh;
            end
            submodel.reducedstats = model.reducedstats;
            [submodel,subapplymodel]  = modelselector(nindex(data,use,1),submodel,suboptions);
            appliedmodel(use,1:size(subapplymodel,2)+1) = [appliedmodel(use,1) subapplymodel];
            
          otherwise
            %not selector model
            if strcmp(options.applytarget,'on')
              %first look for output filter
              if length(model.outputfilters)>=branches(gind)
                myfilter = model.outputfilters{branches(gind)};
                if ~isempty(myfilter)
                  if ~iscell(myfilter)
                    myfilter = {myfilter};
                  end
                end
              else
                myfilter = {};
              end
              
              %apply model
              submodel.reducedstats = model.reducedstats;
              if ~isempty(myfilter) | sum(use)==1
                %apply normally - we've got a filter
                submodel = submodel.apply(nindex(data,use,1));
              else
                %apply peacemeal to get one prediction object per data item
                mymodel  = submodel;
                submodel = cell(size(data,1),1);
                useind = find(use);
                for j=1:length(useind);
                  submodel{j} = mymodel.apply(nindex(data,useind(j),1));
                end
              end
              
              %apply any output filter we've got
              if ~isempty(myfilter)
                out = [];
                myclass = {};
                myclasslbl_index = [];
                label = {};
                [label{1:length(myfilter)}] = deal('');
                
                for j=1:length(myfilter);
                  label{j} = '';
                  if iscell(myfilter{j})
                    %Filter Format:   {  label   substruct  }
                    label{j} = myfilter{j}{1};
                    myfilter{j} = myfilter{j}{2};
                  end
                  if isstruct(myfilter{j}) & isfield(myfilter{j},'label')
                    %Filter Format struct with:
                    %   f.label = 'label';  f.type = ...;  f.subs = ...;
                    label{j} = myfilter{j}.label;
                    myfilter{j} = rmfield(myfilter{j},'label');
                  else
                    %Filter Format struct with:
                    %   f.type = ...;  f.subs = ...;
                    %OR simple content (not really a filter, just a
                    %    replacement value)
                  end
                  if isstruct(myfilter{j}) & isfield(myfilter{j},'type') & isfield(myfilter{j},'subs')
                    %appears to be a substruct structure
                    try
                      thisresult = subsref(submodel,myfilter{j});
                      %*********** This will break if only text is output I think **************** need to test 
                      if iscell(thisresult)
                        %Make class from text output.
                        myclass = [myclass thisresult];
                        myclasslbl_index = [myclasslbl_index j];
                      else
                        %Add to numeric data.
                        out = [out thisresult];
                      end
                    catch
                      le = lasterror;
                      le.message = sprintf('Error Filtering Output\n%s',le.message);
                      rethrow(le)
                    end
                  else
                    %include contents as-is
                    out = [out myfilter{j}];
                  end
                end
                
                if any(~cellfun('isempty',label))
                  %if labels were present, use as column labels in a DSO
                  if ~isdataset(out)
                    out = dataset(out);
                  end
                  
                  for iii = 1:size(myclass,2)
                    %Add text info as class.
                    out.classid{1,iii} = myclass(:,iii);
                    out.classname{1,iii} = label(myclasslbl_index(iii));
                  end
                  %Remove class labels from data column labels.
                  label(myclasslbl_index) = [];
                  out.label{2} = label;
                end
                
                submodel = out;
                
              end
            end
        end
      elseif isstruct(submodel) & isfield(submodel,'error') & length(fieldnames(submodel))==1
        % submodel.error = '...'   means throw an error with that message
        switch options.errors
          % [ 'throw' | 'struct' | 'string' ]
          case 'struct'
            %keep as-is
          case 'string'
            submodel = ['ERROR: ' submodel.error];
          otherwise
            if ~isempty(wbh) & ishandle(wbh)
              delete(wbh);
            end
            error(submodel.error)
        end
      else
        %other types... pass through
      end
      groupout{gind} = submodel;
      groupuse(:,gind) = use;
      
    catch
      le = lasterror;
      if ~isempty(wbh) & ishandle(wbh)
        delete(wbh)
      end
      rethrow(le)
    end
  
    if strcmpi(options.waitbar,'on') | strcmpi(options.waitbar,'recursive')
      pct = gind/length(branches);
      if isempty(wbh)
        wbh = waitbar(pct,'Applying Hierarchical Model');
      elseif ~ishandle(wbh)
        error('User Terminated Model Application')
      else
        waitbar(pct,wbh);
      end
    end
    
  end  %for branches

  outputs = reconcileoutput(groupout,groupuse);
  if isdataset(outputs)
    %add classes to indicate which model was selected
    cl = 1;
    clname = 'Selected Branch';
    while cl<= size(outputs.class,2) & ~isempty(outputs.class{1,cl}) & ~strcmpi(outputs.classname{1,cl},clname)
      cl=cl+1;
    end
    outputs.class{1,cl} = str2cell(num2str(appliedmodel));
    outputs.classname{1,cl} = clname;
    
    % Add uniqueID labels
    if (options.firstcall)
        outputs=ms_adduniqueID(outputs,model);
    end
  end
  
  %augment any 'valid' input to data (if it is an appropriate type)
  if ~isempty(valid)
    if (isnumeric(outputs) | isdataset(outputs)) & (isnumeric(valid) | isdataset(valid))
      outputs = [outputs valid];
    end
  end
  
  varargout = {outputs appliedmodel};
  
  if ~isempty(wbh) & ishandle(wbh) & strcmpi(options.waitbar,'on')
    delete(wbh);
  end

end

%------------------------------------------------
function out = reconcileoutput(res,use)

ngroups  = length(res);
nsamples = sum(use,1);

if ngroups==1 & nsamples==1
  %only one item, just return it
  out = res{1};
  return;
end

type.dso      = cellfun('isclass',res,'dataset');
type.numeric  = cellfun(@(x) isnumeric(x),res) | cellfun('isclass',res,'logical');
type.char     = cellfun('isclass',res,'char');
type.cell     = cellfun('isclass',res,'cell');
type.charcell = false(1,ngroups);
type.charcell(type.cell) = cellfun(@(x) all(cellfun('isclass',x,'char')),res(type.cell));
type.struct   = cellfun('isclass',res,'struct');
type.error    = false(1,ngroups);
type.error(type.struct) = cellfun(@(x) isfield(x,'error'),res(type.struct)) & cellfun(@(x) length(fieldnames(x))==1,res(type.struct));
type.struct(type.error) = false;

%expand singleton types into appropriately sized matrix or cell array

%char and cell arrays of char
for j=find(type.char | type.charcell)
  content = res{j};
  if ischar(content)
    if size(content,1)==1;
      %single row string
      content = repmat({content},nsamples(j),1);
    else
      content = str2cell(content,1);
    end
  end
  if length(content)<nsamples(j)
    [content{end+1:nsamples(j)}] = deal('');
  elseif length(content)>nsamples(j)
    content = content(1:nsamples(j));
  end
  res{j} = content;  %replace with a charcell
  type.charcell(type.char) = true;
  type.char(:) = false;
end

%convert numerics to appropriately sized matrix
for j=find(type.numeric)
  content = res{j};
  nrows = size(content,1);
  nd    = ndims(content);
  if nrows==0
    %EMPTY?
    content = {{[]}};
    type.cell(j) = true;   %treat this as a CELL now
    type.numeric(j) = false;
  elseif nrows==1
    %single row content
    fill = repmat({1},1,nd-1);
    content = repmat(content,nsamples(j),fill{:});
  elseif nrows>nsamples(j)
    content = nindex(content,1:nsamples(j),1);
  elseif nrows<nsamples(j)
    sz = size(content);
    content = cat(1,content,nan([nsamples(j)-nrows,sz(2:end)]));
  end
  res{j} = content;
end

if all(type.charcell | type.error)
  %strings or errors?
  
  %convert errors to strings 
  for j=find(type.error)
    content = ['ERROR: ' res{j}.error];
    content = repmat({content},nsamples(j),1);
    res{j} = content;  %replace with a new DSO
  end
  
  out = cat(1,res{:});
  
  out = reorder(out,use);
  return
end

if all(type.dso | type.charcell | type.numeric | type.error)
  %all are convertable to DSO? Do that
  
  %convert strings to DSO with no values but class of given string
  for j=find(type.charcell)
    temp = dataset(nan(nsamples(j),1));
    temp.classid{1,1} = res{j};
    temp.classname{1,1} = 'Result';
    res{j} = temp;  %replace with a new DSO
  end
  
  %convert errors to DSO with no values but error class of given string
  for j=find(type.error)
    temp = dataset(nan(nsamples(j),1));
    content = res{j}.error;
    content = repmat({content},nsamples(j),1);
    temp.classid{1,2} = content;
    temp.classname{1,2} = 'Error';
    res{j} = temp;  %replace with a new DSO
  end
  
  %convert numerics to appropriately sized DSO
  for j=find(type.numeric)
    res{j} = dataset(res{j});
  end
  
  %everything is now a DSO - join them
  temp = res{1};
  for j=2:length(res)
    toadd = res{j};
    la = str2cell(temp.label{2},1);
    lb = str2cell(toadd.label{2},1);
    [junk,ii]=setdiff(lb,la);
    if ~isempty(ii)
      %labels to add... use matchvars
      ltarget = [la;lb(sort(ii))];
      temp    = matchvars(ltarget,temp);
      toadd   = matchvars(ltarget,toadd);
    else
      if ~isempty(la)
        toadd   = matchvars(la,toadd);
      end
      ltarget = {};  %no change in temp labels needed
    end
    %they either match because of labels OR they had no labels and the sizes are different
    if size(toadd,2)<size(temp,2)
      toadd = [toadd nan(size(toadd,1),size(temp,2)-size(toadd,2))];
    elseif size(toadd,2)>size(temp,2)
      temp = [temp nan(size(temp,1),size(toadd,2)-size(temp,2))];
    end
    if ~isempty(ltarget)
      temp.label{2} = ltarget;
    end
    temp = [temp;toadd];
  end    
  
  if ~isempty(temp.class{1,2}) & any(temp.class{1,2}==0)
    %fill in "no error" flag if we have ANY errors
    temp.classlookup{1,2}.assignstr = {0 'No Error'};
  end
  if ~isempty(temp.class{1,1}) & any(temp.class{1,1}==0)
    %fill in "no error" flag if we have ANY errors
    temp.classlookup{1,1}.assignstr = {0 'No Result'};
  end
  
  out = temp;
  out = reorder(out,use);

else
  %they are NOT objects that we can combine into a DSO...
  %%%TODO: Handle hard cases... (deal out objects into individual cells)  
  
  %%% 1) split numerics and DSOs into separate cells
  %%% 2) split other ~(type.dso | type.charcell | type.numeric | type.error)
  %%%    objects into separate cells if equal in length to # of required
  %%%    items
  %%% 3) replicate other ~(type.dso | type.charcell | type.numeric |
  %%%    type.error) objects which are single elements
  
  temp = {};
  for j=1:length(res);
    item = res{j};
    if (type.dso(j) | type.numeric(j))
      %DSO or Numeric
      if size(item,1)==nsamples(j)
        %correct number of rows - split into cells
        items = {};
        for k=1:nsamples(j);
          items{k,1} = item(k,:);
        end
        temp = [temp;items];
      else
        %replicate as needed for all items
        temp = [temp;repmat({item},nsamples(j),1)];
      end
      
    elseif iscell(item)
      %cells - expand if we can
      if length(item)==nsamples(j)
        %correct number of sub-items, expand
        temp = cat(1,temp,item{:});
      else
        if length(item)==1;
          %extract if a single cell item
          item = item{1};
        end
        %replicate as needed
        temp = [temp;repmat(item,nsamples(j),1)];
      end
      
    else
      %expand if we can
      if length(item)==nsamples(j)
        %correct number of sub-items, expand
        items = {};
        for k=1:nsamples(j);
          if (nsamples(j) > 1)
            items{k,1} = item(k);
          else
            items{k,1} = item;
          end
        end
        temp = [temp;items];
      else
        if length(item)==1;
          %extract if a single cell item
          item = item{1};
        end
        %replicate as needed
        temp = [temp;repmat(item,nsamples(j),1)];
      end

    end
  end
  
  out = temp;
  if size(out,1)==1 & size(out,2)>1;
    out = out';
  end
  
end


%-------------------------------------------------------
function out = reorder(out,use)

if size(use,2)==1
  return;
end

order = find(use(:,1));
for j=2:size(use,2)
  order = [order;find(use(:,j))];
end

%adjust order to match use
reorder = [];
reorder(order) = 1:length(order);
reorder(reorder==0) = []; %drop any missing items (?!?)
out = nindex(out,reorder,1);


%-------------------------------------------------------
function model = local_modelstruct(type)
%create empty model structures used by this function

model = modelstruct(type);
model.date = date;
model.time = clock;

switch type
  case 'triggerstring'

  case 'modelselector'
    model.detail.options = modelselector('options');

end


%-------------------------------------------------
function [labels,axisscales,reform] = parsetriggerstring(str,varname)
%PARSETRIGGERSTRING 
% parse a trigger string for the embedded labels and/or axisscale values
% embedded therein
%  embedding is expected as "Label" and "[axisscale]" (including quotes!)
%
% Inputs:
%     str : string to be parsed
%     varname : optional name of array for variable in output reform
% Returns: 
%     labels : column cell array of labels found
%     axisscales : row vector of axis scale values found
%     reform : reformed string with "mdata(:,index)" inserted for each
%               label or axisscale value (in order found)

if nargin<2
  varname = 'mdata';
end

if ismodel(str)
  %this item is a model? then we should extract values from details
  labels = str2cell(str.detail.label{2});
  axisscales = str.detail.axisscale{2};
  reform = '';
  return
end

labels = {};
axisscales = [];
varindex = 0;
reform = [];

%drop up to first quoted string
if ~isempty(str) & str(1)~='"'
  [reform,str] = strtok(str,'"');
  if isempty(str)
    %NO quotes? check for [ ] and add quotes around it
    openparens = regexp(reform,'\[');
    closeparens = regexp(reform,'\]');
    if length(openparens)==1 & length(closeparens)==1
      %take [...] and add quotes and assign into str and reform
      str = ['"' reform(openparens:closeparens) '"' reform(closeparens+1:end)];
      reform = '';
    end
  end
end
if isempty(str)
  %empty here means there were no quotes. We have to assume this operates
  %on the entire data matrix (and data is expected to be a single column)
  reform = [varname reform];
  return
end
  

%look for standard quoted label
[lbl,str] = strtok(str,'"');
while ~isempty(lbl)
  varindex = varindex+1;
  if lbl(1)=='[';
    axisscales(1,varindex) = str2num(lbl(2:end-1));
  else
    labels{varindex,1} = lbl;
  end
  reform = [reform varname '(:,' num2str(varindex) ')'];
  if ~isempty(str);
    str = str(2:end);  %drop closing "
  end
  %drop up to next quoted string
  if ~isempty(str) & str(1)~='"'
    [junk,str] = strtok(str,'"');
    reform = [reform junk];
  end
  [lbl,str] = strtok(str,'"');
end

function ds_out = ms_adduniqueID(ds_in, ms_model)
%Adds a Model ID class set using the unique ID of each used model.

ds_out = [];
try
  branch_cell = ds_in.('Selected Branch');
  branch_cell = cellfun(@(x)regexp(x, '\s{1,}', 'split'), branch_cell, ...
    'uni', false);
  for jl = 1:length(branch_cell)
    cur_branch = branch_cell{jl};
    cur_branch = cellfun(@(x)str2num(x), cur_branch);
    branch_cell{jl} = cur_branch;
  end
  
  uniq_ID     = repmat({''}, size(ds_in,1), 1);
  
  for jl = 1:length(branch_cell)
    cur_branch = branch_cell{jl};
    lj = 1;
    cur_model = ms_model;
    while lj <= length(cur_branch)
      cur_ind = cur_branch(lj);
      if ~isequal(cur_ind, 0)
        cur_model = cur_model.targets{cur_ind};
      end
      lj = lj + 1;
    end
    if isa(cur_model, 'evrimodel')
      uniq_ID{jl} = cur_model.uniqueid;
    else
      uniq_ID{jl} = class(cur_model);
    end
  end
catch
  return
end

num_classsets = size(ds_in.classname,2);
ds_out = ds_in;
ds_out.classid{1, num_classsets+1} = uniq_ID;
ds_out.classname{1, num_classsets+1} = 'model ID';
