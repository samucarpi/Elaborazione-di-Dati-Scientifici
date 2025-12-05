function obj = subsasgn(obj,S,val)
%EVRIMODEL/SUBSASGN Assign fields in object.

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~isa(obj,'evrimodel')
  %If we got here because val was a model but obj isn't, just call into the
  %standard subsasgn
  obj = builtin('subsasgn',obj,S,val);
  return
end

if strcmpi(S(1).subs,'modeltype')
  if ~isempty(strfind(val,'_PRED'));
    %turning the object into a PREDICTION object!
    %TODO: um... do SOMETHING!
  end
end

if strcmp(S(1).type,'()')
  %array indexing
  error('EVRIModel objects do not allow array indexing');
end

if ~strcmp(S(1).type,'.')
  error('Invalid indexing for EVRIModel object')
end

%list of virtual fields which are simple indexes:
virtual = virtualfields(obj);

fyld = lower(S(1).subs);
historyfield = fyld;
historyval = '';
switch fyld
  %---------------------------------------------------
  case {'calibrate' 'apply' 'plotscores' 'ploteigen' 'plotloads' 'crossvalidate'}
    error('"%s" is a method, not a property',fyld)
    
  case {'iscalibrated' 'isprediction' 'isyused' 'isclassification' 'cancalibrate' 'uniqueid' 'validmodeltypes' 'prediction' 'inputs' }
    error('"%s" is a read-only property',fyld)

    %---------------------------------------------------
  case { 'plots' 'display' 'matchvars' 'contributions' 'reducedstats'}
    val = lower(val);
    switch fyld
      case 'plots'
        if ~ismember(val,{'final','none'})
          error('''%s'' is not a valid setting for plots property (expected ''final'' or ''none'')',val);
        end
      case {'display' 'matchvars'}
        if ~ismember(val,{'off','on'})
          error('''%s'' is not a valid setting for %s property (expected ''on'' or ''off'')',val,fyld);
        end
      case 'contributions'
        if ~ismember(val,{'passed' 'used' 'full'})
          error('''%s'' is not a valid setting for %s property (expected ''passed'', ''used'' or ''full'')',val,fyld);
        end
      case 'reducedstats'
        if ~ismember(val,{'off' 'on'})
          error('''%s'' is not a valid setting for %s property (expected ''off'' or ''on'')',val,fyld);
        end
    end
    
    %object properties which depend on the state of calibration or not
    if ~iscalibrated(obj) & cancalibrate(obj) & ismember('options',getcalprops(obj)) & isfield(obj.calibrate.script.options,fyld)
      %script exists and this is in the options field
      obj.calibrate.script.options.(fyld) = val;
    end
    %always store the property in the top-level field too... These are used
    %when the object is calibrated already, OR script DOES NOT exist, or
    %this isn't in the options (or there are no options)
    obj.(fyld) = val;
    
    historyval = val;
    
    %---------------------------------------------------
  case 'modeltype'
    %special case when assinging modeltype
    newtype = regexprep(lower(val),'_pred','');
    oldtype = regexprep(lower(obj.content.modeltype),'_pred','');
    if strictmodeltype & ~isempty(obj.content.modeltype) ...
        & (~strcmpi(newtype,'lwr') | ~strcmpi(oldtype,'lwrpred'))...
        & (~strcmpi(newtype,'PCA') | ~strcmpi(oldtype,'MPCA'))...
        & (~strcmpi(newtype,'MPCA') | ~strcmpi(oldtype,'PCA'))...
        & ~strcmpi(newtype,oldtype)
      recordevent(sprintf('!!! Changing %s to %s',obj.content.modeltype,val));
    end
    
    if ~ismember(regexprep(lower(val),'_pred',''),template)
      error('Invalid model type "%s"',val)
    end
    if isempty(obj.content.modeltype)
      %No current model type?
      obj = evrimodel(val);  %call to create a new model structure with this model type
    else
      %reassign existing model type (?!?)
      obj.content.modeltype = val;
    end
    historyval = val;
    
    %---------------------------------------------------
  case getcalprops(obj)
    %assignment to one of the calibrate properties - store value
    if comparevars(substruct('.','options','.','plots'),S) ...
        | comparevars(substruct('.','options','.','display'),S)
      %if one of the options we're echoing at the top-level, recursive call
      %into the logic above which assigns this to both the top-level and
      %the calibrate properties
      obj = subsasgn(obj,S(2),val);
    else
      %all other evriscript object assign properties
      obj.calibrate.script = subsasgn(obj.calibrate.script,S,val);
    end
    historyval = val;
    
  case [virtual(:,1)' 'qcon' 'tcon' 'xhat']
    error('"%s" is a read-only property',fyld)
    
  case {'ncomp'}
    %properties that are calibrate properties sometimes and are otherwise
    %read-only go here... (ncomp CAN be assigned if it is a cal prop)
    error('"%s" is a read-only property',fyld)
    
    %---------------------------------------------------
  case 'componentnames'
    %componentnames needs to be cell array of strings not longer than
    %ncomp.
    if ~isfieldcheck(obj,'obj.detail.componentnames')
      error(['COMPONENTNAMES not availalbe for model type: ' upper(mode.modeltype)])
    end
    
    if all(cellfun('isempty',val))
      val = [];
    end
    
    if ~isempty(val)
      %Subsref will take care of empty value.
      
      if ~iscell(val)
        error('COMPONENTNAMES must be cell array of strings.')
      end
      ncomp = subsref(obj,struct('type','.','subs','ncomp'));
      if length(val)>ncomp
        error(['COMPONENTNAMES must be less than or equal to ncomp:  ' num2str(ncomp)])
      end
      
      if length(val)<ncomp
        val = [val repmat({''},1,ncomp-length(val))];
      end
      
      %Component names shouldn't be all empty or all filled so plotting is easier.
      if any(cellfun('isempty',val))
        for i = 1:length(val)
          if isempty(val{i})
            val{i} = ['Component ' num2str(i)];
          end
        end
      end
    end
    
    obj.content.detail.componentnames = val;
    
  otherwise
    %not a special model call? Assume it is indexing directly into content
    
    %handle .detail "collapsing" (make .detail fields accessible through
    %top-level of object)
    if ~isfield(obj.content,fyld)
      if isfield(obj.content.detail,fyld) | strcmp(fyld,'include')
        S = [substruct('.','detail') S];
        fyld = 'detail';
      else
        error('Field "%s" is not valid for model type "%s"',S(1).subs,obj.content.modeltype)
      end
    end
    
    %translate .detail.include to be .detail.includ
    if strcmpi(fyld,'detail') & length(S)>1
      if strcmp(S(2).type,'.') & strcmpi(S(2).subs,'include')
        S(2).subs = 'includ';
      end
      if strcmp(S(2).type,'.') & ~isfield(obj.content.detail,S(2).subs)
        tem = evrimodel(obj.content.modeltype);
        if isfield(tem.content.detail,S(2).subs)
          error('Model was not updated to current version correctly (missing field "detail.%s")',S(2).subs)
        else
          error('Field "detail.%s" is not valid for model type "%s"',S(2).subs,obj.content.modeltype)
        end
      end
    end
    historyval = val;
    
    if length(S)>1
      %encode subscripting for history field
      ind = 2;
      for i=ind:length(S)
        if strcmpi(S(i).type,'.')
          historyfield = [historyfield '.' S(i).subs];
          continue;
        end          
        notchar = cellfun(@(item) ~ischar(item),S(i).subs,'uniformoutput',true);
        scalar = cellfun(@(item) numel(item)==1,S(i).subs,'uniformoutput',true);
        subs = S(i).subs;
        subs(notchar & scalar) = cellfun(@(item) num2str(item),subs(notchar & scalar),'uniformoutput',false);
        [subs{notchar & ~scalar}] = deal('...');
        historyfield = [historyfield S(i).type(1) subs{1}];
        if length(subs)>1
          historyfield = [historyfield sprintf(',%s',subs{2:end})];
        end
        historyfield = [historyfield S(i).type(2)];
      end
    end
    
    %clear out calibration script as soon as datasource is assigned
    if strcmpi(fyld,'datasource')
      obj.calibrate = [];
    end
    
    if length(S)>1 & strcmpi(S(2).type,'.') & strcmpi(S(2).subs,'history')
      if ~ischar(val)
        error('History comments must be strings')
      end
      val = sethistory(obj.content.detail.history,'','',['%%% COMMENT: ' val]);
      historyfield = '';  %do NOT do a history entry for this
    end
          
    %check for assignment into nested model and split into before and
    %after portions
    subfield = obj.content;
    for i = 1:length(S)-1
      if ~strcmp(S(i).type,'.')
        %found non . before we found an object
        break;
      end
      if ~isfield(subfield,S(i).subs);
        break;
      end
      subfield = subsref(subfield,S(i));
      if isa(subfield,'evrimodel')
        %found a model, split here, grab the sub-model and do remainder of S
        %assignment into that directly.
        val = subsasgn(subfield,S(i+1:end),val);
        S = S(1:i);  %leave only the part that gets us up to the sub-model and re-assign submodel there
        break;
      end
    end
    
    if ischar(S(end).subs) & strcmp(S(end).subs,'componentnames')
      %Make recursive call to top level subsasgn logic (see above).
      obj = subsasgn(obj,S(2),val);
    else
      obj.content = builtin('subsasgn',obj.content,S,val);
    end
end

if ~isempty(historyfield) & isfieldcheck(obj.content,'content.detail.history')
  obj.content.detail.history = sethistory(obj.content.detail.history,historyfield,historyval);
end

%-------------------------------------------------
function out = strictmodeltype
persistent val
if isempty(val);
  val = getfield(evrimodel('options'),'strictmodeltype');
end
out = val;
