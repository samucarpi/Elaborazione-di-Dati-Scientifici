function varargout = subsref(obj,S)
%EVRIMODEL/SUBSREF Access fields in object.

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%list of virtual fields which are simple indexes:
virtual = virtualfields(obj);

%check for () indexing
if strcmp(S(1).type,'()')
  %array indexing
  if length(S(1).subs)~=1 | length(S(1).subs{1})>1 | S(1).subs{1}~=1
    error('EVRIModel objects do not allow array indexing');
  end
  S = S(2:end);  %drop model(1) indexing (that is the ONLY subsindex we allow)
end

%check for other types of indexing (generally invalid)
if ~strcmp(S(1).type,'.')
  error('Invalid indexing for EVRIModel object')
end

%find field or method to access
fyld = lower(S(1).subs);
switch fyld
  
  %--------------------------------------------------
  case {'content' 'downgradeinfo' 'evrimodelversion' 'parent' 'matchvars' 'contributions' 'reducedstats'}
    %object properties which can be accessed directly
    varargout{1} = obj.(fyld);
    
    %--------------------------------------------------
  case { 'plots' 'display' }
    %object properties which depend on the state of calibration or not
    if ~iscalibrated(obj) & cancalibrate(obj) & ismember('options',getcalprops(obj)) & isfield(obj.calibrate.script.options,fyld)
      %script exists and this is in the options field
      varargout{1} = obj.calibrate.script.options.(fyld);
    else
      %calibrated already, OR script DOES NOT exist, or this isn't in the
      %options (or there are no options)
      varargout{1} = obj.(fyld);
    end
    
    %--------------------------------------------------
  case 'evrimodel'
    %just returns the model itself...
    varargout{1} = obj;
    
    %--------------------------------------------------
  case getcalprops(obj)
    %reference to one of the calibrate properties (getcalprops will be
    %empty if is calibrated already, so this section will be ignored at
    %that point)
    varargout{1} = obj.calibrate.script.(fyld);
    
  case {'inputs'}
    %calibration properties
    p = getcalprops(obj);
    if ~isempty(p)
      %not calibrated and properties exist
      varargout{1} = [p 'plots' 'display'];
    elseif ~iscalibrated(obj)
      %not calibrated but no properties...
      varargout{1} = {};
    else
      %calibrated...
      varargout{1} = {'plots' 'display' 'matchvars'};
    end
    
    %--------------------------------------------------
  case {'ncomp' 'lvs' 'pcs'}
    %number of components virtual field
    if isfield(obj.content,'loads')
      switch lower(obj.content.modeltype)
        case 'parafac2'
          varargout{1} = size(obj.content.loads{2},2);
        otherwise
          varargout{1} = size(obj.content.loads{1},2);
      end
    else
      switch lower(obj.content.modeltype)
        case {'knn' 'knn_pred'}
          varargout{1} = obj.content.k;
        case {'ann' 'ann_pred'}
          varargout{1} = obj.content.detail.options.nhid1;                
        case {'anndl' 'anndl_pred'}
          varargout{1} = getanndlnhidone(obj);          
        case {'svm' 'svm_pred'}
          varargout{1} = length(obj.content.detail.rmsep);  % tempdos: check if rmsep 
        otherwise
          varargout{1} = 1;
      end
    end
    
    %--------------------------------------------------
  case virtual(:,1);
    % Other virtual fields defined by virtualfields.m
    ind = ismember(virtual(:,1),fyld);
    try
      temp = subsref(obj.content,virtual{ind,2});
    catch
      temp = []; %error('Field "%s" not valid for this model type',fyld);
    end
    varargout{1} = temp;
    
    %--------------------------------------------------
  case {'q' 't2'}
    switch fyld
      case 'q'
        valuefield = 'ssqresiduals';
        limfield = 'reslim';
      case 't2'
        valuefield = 'tsqs';
        limfield = 'tsqlim';
    end
    temp = [];
    if isfield(obj.content,valuefield) & iscell(obj.content.(valuefield)) & ~isempty(obj.content.(valuefield))
      temp = obj.content.(valuefield){1};
    end      
    lim = [];
    if strcmpi(obj.reducedstats,'on') & isfield(obj.content.detail,limfield) & iscell(obj.content.detail.(limfield)) & ~isempty(obj.content.detail.(limfield))
      lim  = obj.content.detail.(limfield){1};
    end
    if isempty(lim)
      lim = 1;
    end
    varargout{1} = temp./lim;
    
    %--------------------------------------------------
  case {'qcon' 'tcon'}
    % T2 and Q contributions
    if length(S)>1
      if ~strcmp(S(2).type,'()')
        error('Invalid format for %s method. Try: model.%s(data)',fyld,fyld);
      end
      addin = S(2).subs;
      if length(addin)==1 & ( isdataset(addin{1}) | isnumeric(addin{1}) )
        % _con(dataset)  : uses dataset for source
        S = S(2:end);
        if strcmp(obj.matchvars,'on')
          try
            [addin{1},unmap] = matchvars(obj,addin{1});
          catch
            %error when using matchvars? just ignore it
            unmap = [];
          end
          obj.matchvarsmap = unmap;
        end
      else
        % _con(index,...)  : index into results
        addin = {};
      end
    else
      addin = {};
    end
    
    switch fyld
      case 'qcon'
        varargout{1} = qconcalc(addin{:},obj);
        
      case {'tcon'}
        varargout{1} = tconcalc(addin{:},obj);
    end
    
    %handle reconciling the order of the variables of the contributions
    varargout{1} = conrearrange(varargout{1},obj);
    
    %--------------------------------------------------
  case 'xhat'
    %  m.xhat -> model.pred{1} (if empty, use datahat w/m.x if present, else give error)
    if isfield(obj.content,'pred') & ~isempty(obj.content.pred{1})
      %get from .pred{1}
      varargout{1} = obj.pred{1};
    else
      %try calling datahat
      if length(S)>1
        if ~strcmp(S(2).type,'()')
          error('Invalid format for %s method. Try: model.%s(data)',fyld,fyld);
        end
        addin = S(2).subs;
        if length(addin)==1 & ( isdataset(addin{1}) | isnumeric(addin{1}) )
          % _con(dataset)  : uses dataset for source
          % _con(matrix)  : uses dataset for source
          if strcmp(obj.matchvars,'on')
            try
              [addin{1},unmap] = matchvars(obj,addin{1});
            catch
              %error when using matchvars? just ignore it
              unmap = [];
            end
            obj.matchvarsmap = unmap;
          end
          S = S(2:end);
        else
          % _con(index,...)  : index into results
          addin = {};
        end
      else
        addin = {};
      end
      varargout{1} = datahat(obj,addin{:});
    end
    
    %--------------------------------------------------
  case 'prediction'
    %virtual field: get appropriate prediction field for this object
    if ~iscalibrated(obj)
      error('Model must be calibrated before predictions can be retreived');
    end
    if isfield(obj.content,'classification')
      %classification model
      lu = obj.content.classification.inclass;
      temp = {};
      [temp{1:length(lu),1}] = deal('');
      temp(lu>0) = obj.content.classification.classids(lu(lu>0));
    elseif length(obj.content.pred)>1
      %model with y-block
      temp = obj.content.pred{2};
    elseif isfield(obj.content,'loads')
      %other model with scores & loadings
      temp = obj.content.loads{1};
    else
      error('Field "%s" not valid for this model type',fyld);
    end
    varargout{1} = temp;
    
  case 'predictionlabel'
    %virtual field: get appropriate prediction field labels for this object
    if ~iscalibrated(obj)
      error('Model must be calibrated before predictions can be retreived');
    end
    if isfield(obj.content,'classification')
      %classification model
      temp = {'Predicted Class'};
    elseif length(obj.content.pred)>1
      %model with y-block
      temp = repmat({''},size(obj.content.pred{2},2),1);  %default if we can't find what we need
      if isfield(obj.content.detail,'data') & length(obj.content.detail.data)>1 & ~isempty(obj.content.detail.data{2}) & isdataset(obj.content.detail.data{2})
        lbl  = obj.content.detail.data{2}.label{2};
        incl = obj.content.detail.includ{2,2};
        if size(lbl,1)>=max(incl)
          temp = str2cell(lbl(incl,:));
        end
      end
    elseif isfield(obj.content,'loads')
      %other model with scores & loadings
      % UMAP and TSNE do not have loadings but still need prediction labels
      if ismember(lower(obj.content.modeltype),{'tsne' 'umap'})
        temp = str2cell(sprintf('Embeddings for Component %i\n',1:size(obj.content.loads{1},2)));
      else
        temp = str2cell(sprintf('Component %i Scores\n',1:size(obj.content.loads{2},2)));
      end
    else
      error('Field "%s" not valid for this model type',fyld);
    end
    varargout{1} = temp;
    
    %--------------------------------------------------
  case {'iscalibrated' 'isprediction' 'cancalibrate' 'loadobj' 'isclassification' 'encode'}
    %generic methods which just take the object as input and always return
    %a value (whether or not nargout is >0)
    varargout{1} = feval(lower(fyld),obj);
    
    %--------------------------------------------------
  case 'encodexml'
    %encodexml support
    varargout{1} = encodexml(obj,'model');
    
    %-------------------------------------------------
  case {'isa' 'isfield' 'isfieldcheck' 'isstruct' 'subsasgn' 'subsref' }
    %methods which take the object AND other items as input. This allows
    %calls like:   obj.isfield('test')
    
    if length(S)==1
      error('Model %s method requires data as input: model.%s(data,...)',fyld,fyld);
    elseif ~strcmp(S(2).type,'()')
      error('Invalid format for %s method. Try: model.%s(...)',fyld,fyld);
    end
    addin = S(2).subs;
    S = S(2:end);
    
    varargout{1} = feval(lower(fyld),obj,addin{:});
    
    
    %--------------------------------------------------
  case {'knnscoredistance' 'scoredistance' 'esterror' 'ils_esterror'}
    %generic methods which always output (and require parent models)
    
    switch fyld
      %translate some field names
      case 'scoredistance'
        fn = 'knnscoredistance';
      case 'esterror'
        fn = 'ils_esterror';
      otherwise
        fn = fyld;
    end
    
    inputs = {obj};
    if length(S)>1
      inputs = [inputs S(2).subs];
      S = S(2:end);
    end
    if isprediction(obj) & (length(inputs)<2 | ~ismodel(inputs{2})) & ~isempty(obj.parent)
      %predictions require parent models - no parent model passed, and
      %parent is present in pred structure, insert it as FIRST item in list
      inputs = [{obj.parent} inputs];
    end
    if length(inputs)>1 & ismodel(inputs{1}) & ismodel(inputs{2}) & isprediction(inputs{1}) & ~isprediction(inputs{2})
      %if model and prediction are in wrong order, reverse them
      %(model,pred) is correct
      [inputs{1:2}] = deal(inputs{[2 1]});
    end
    if isprediction(inputs{1})
      %if the first input is still a prediction, we don't have a model
      error('%s on a prediction model object requires the original model as input',fyld)
    end
    varargout{1} = feval(lower(fn),inputs{:});

    %For score distance, normalize by max of model
    if strcmpi(fn,'knnscoredistance') & ~isempty(varargout{1})
      if length(inputs)>1 & ismodel(inputs{2}) & isprediction(inputs{2})
        scd = knnscoredistance(inputs{[1 3:end]});
      else
        scd = varargout{1};
      end
      limit = max(scd(inputs{1}.content.detail.includ{1}));
      varargout{1} = varargout{1}./limit;
    end
    
    %--------------------------------------------------
  case {'plotloads' 'plotscores' 'ploteigen'}
    %generic methods which just take the object as input but are sensitive
    %to nargout
    inputs = {obj};
    if length(S)>1
      inputs = [inputs S(2).subs];
      S = S(2:end);
    end
    if nargout>0;
      varargout{1} = feval(lower(fyld),inputs{:});
    else
      feval(lower(fyld),inputs{:});
    end
    
    %--------------------------------------------------
  case {'disp' 'edit' 'openvar'}
    %generic methods which NEVER return output
    if nargout>0
      error('The "%s" method does not return any output',fyld)
    end
    feval(lower(fyld),obj);
    
    %--------------------------------------------------
  case 'info'
    %overload of info (calls model reader)
    if nargout>0 | length(S)>1
      varargout{1} = modlrder(obj);
    else
      modlrder(obj);
    end
    
    %--------------------------------------------------
  case 'validmodeltypes'
    %list of model types which this object can be assigned
    if isempty(obj.content.modeltype)
      %if undefined, return all possible tyeps
      varargout{1} = template;
    else
      %if already defined, it is only the type we've got
      mt = obj.content.modeltype;
      varargout{1} = mt;
    end
    
    %--------------------------------------------------
  case 'uniqueid'
    %unqiue ID
    varargout{1} = uniquename(obj);
    
    %--------------------------------------------------
  case 'isyused'
    varargout{1} = 0;
    if ismember('y',getcalprops(obj)) | (isfield(obj.content,'datasource') & length(obj.content.datasource)>1)
      varargout{1} = 1;
    end
    
    %--------------------------------------------------
  case 'crossvalidate'
    %handle cross-validation of a model
    if length(S)>1 & ~strcmp(S(2).type,'()')
      error('Invalid format for crossvalidate method. Try: model = model.crossvalidate(x,cvi,maxncomp)');
    end
    if length(S)>1
      addin = S(2).subs;
      S = S(2:end);
    else
      addin = {};
    end
    varargout{1} = crossvalidate(obj,addin{:});
    
    if nargout==0 & length(S)==1
      try %The inputname function may not work in 15b or newer.
        %assign back in caller's workspace if no outputs requested
        name = inputname(1);
        if ~isempty(name)
          assignin('caller',name,varargout{1});
          varargout = {};
        end
      catch
        error(['Object could not be assigned back into workspace. Use output in call, example:   mymodel = mymodel.crossvalidate'])
      end
    end
    
    %--------------------------------------------------
  case 'calibrate'
    %call calibrate method
    if length(S)>1
      error('Calibrate method takes no additional parameters');
    end
    varargout{1} = calibrate(obj);

    if nargout==0 & length(S)==1
      try %The inputname function may not work in 15b or newer.
        %assign back in caller's workspace if no outputs requested
        name = inputname(1);
        if ~isempty(name)
          assignin('caller',name,varargout{1});
          varargout = {};
        end
      catch
        error(['Object could not be assigned back into workspace. Use output in call, example:   mymodel = mymodel.calibrate'])
      end
    end
    
    %--------------------------------------------------
  case 'apply'
    %call apply method
    if ~exist(lower(obj.content.modeltype),'file')
      error('Models of type "%s" cannot be applied',obj.content.modeltype);
    end
    if ~iscalibrated(obj)
      error('Model must be calibrated before it can be applied');
    end
    if length(S)==1
      error('Apply method requires data as input: model.apply(data,...)');
    elseif ~strcmp(S(2).type,'()')
      error('Invalid format for apply method. Try: model.apply(data,...)');
    end
    addin = S(2).subs;
    
    %look for options...
    optsdefaults = struct('plots',obj.plots,'display',obj.display,'waitbar','off');
    optsind = 0;
    for j=2:length(addin)
      if isstruct(addin{j})
        optsind = j;
        break;
      end
    end
    if optsind==0
      %add options if we can't find them
      addin{end+1} = optsdefaults;
      optsind = length(addin);
    else
      %reconcile with defaults
      addin{optsind} = reconopts(addin{optsind},optsdefaults);
    end
    
    %add model to addin list (always just before options)
    addin = [addin(1:optsind-1) {obj} addin(optsind:end)];
    
    %Get variables aligned (if necessary)
    if ~isdataset(addin{1}) && ~strcmpi(obj.content.modeltype,'multiblock')
      %Multiblock models should not transform incoming data, models may be
      %passed causing error here. 
      addin{1} = dataset(addin{1});
    end
    if strcmp(obj.matchvars,'on')
      if strcmpi(obj.content.modeltype,'caltransfer')
        warning('EVRI:CalTransferMatchVars','Applying calibration transfer slave data with matchvars turned "on" may produce unexpected/undesired results.')
      end
      
      try
        [addin{1},unmap] = matchvars(obj,addin{1});        
      catch
        %error when using matchvars? just ignore it
        unmap = [];
      end
      if ~isempty(unmap) & all(isnan(unmap))
        error('Data has no variables in common with model');
      end
    else
      unmap = [];
    end
    S = S(2:end);
    try
      varargout{1} = feval(lower(obj.content.modeltype),addin{:});
      if ismodel(varargout{1});
        varargout{1}.parent = obj;%Parent model after apply.
      end
    catch
      err = lasterror;
      err.stack = err.stack(1:end-1);
      rethrow(err);
    end

    if ismodel(varargout{1});
      %store whatever unmap values we got from applying
      varargout{1}.matchvarsmap = unmap;
      
      if getfield(evrimodel('options'),'usecache')
        %add results to model cache (if possible)
        modelcache(obj,addin(1:min(2,optsind-1)),varargout{1});
      end
    end
    
    %--------------------------------------------------
  case 'componentnames'
    if ~isfieldcheck(obj,'obj.detail.componentnames')
      error(['COMPONENTNAMES not availalbe for model type: ' obj.content.modeltype])
    end
    
    ncomp = subsref(obj,struct('type','.','subs','ncomp'));
    out = obj.content.detail.componentnames;
    if length(out)<ncomp
      out = [out repmat({''},1,ncomp-length(out))];
    end
    varargout{1} = out;
    %--------------------------------------------------
  case 'ssqtable'
    varargout{1} = getssqtable(obj,[],'table');
    %--------------------------------------------------
  case 'ssqtext'
    varargout{1} = getssqtable(obj,[],'text');
    %--------------------------------------------------
  case 'ssqcell'
    varargout{1} = getssqtable(obj,[],'cell');
    %--------------------------------------------------
  otherwise
    %not a special model call? Assume it is indexing directly into content
    
    %special handling of help field
    if strcmpi(fyld,'help') & length(S)==1
      %help field
      out = obj.content.help;
      if isempty(obj.content.modeltype)
        %no model type?
        doc('modelstruct');
        out.url = which('modelstruct.html');
      else
        doc(obj.content.modeltype);
        out.url = which([lower(obj.content.modeltype) '.html']);
      end
      if nargout>0
        varargout = {out};
      end
      return
    end
    
    %handle .detail "collapsing" (make .detail fields accessible through
    %top-level of object)
    if ~isfield(obj.content,fyld) & isfield(obj.content,'detail')
      if isfield(obj.content.detail,fyld) | strcmp(fyld,'include')
        S = [substruct('.',fyld) S];
        fyld = 'detail';
      else
        error('Reference to non-existent field ''%s''.',fyld)
      end
    end
    
    varargout{1} = obj.content.(fyld);
    
    %index into .detail field...
    if strcmpi(fyld,'detail') & length(S)>1
      if strcmp(S(2).type,'.') & strcmpi(S(2).subs,'include')
        %translate .detail.include to be .detail.includ
        S(2).subs = 'includ';
      end
      %check if subscript is valid for detail field
      if strcmp(S(2).type,'.') & ~isfield(obj.content.detail,S(2).subs)
        error('Field "detail.%s" is not valid for model type "%s"',S(2).subs,obj.content.modeltype)
      end
    end
    
end
S = S(2:end);

%do any remaining subscripting
if exist('varargout','var') & ~isempty(varargout) & ~isempty(S)
  temp = varargout{1};
  for j=1:length(S);
    temp = subsref(temp,S(j));
  end
  varargout{1} = temp;
end

