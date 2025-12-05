function obj = evrimodel(varargin)
%EVRIMODEL/EVRIMODEL Builds an EVRI Model Object.
% An EVRIModel object is a generic object that contains a standard
% Eigenvector model object. The model can be either "empty" (uncalibrated),
% "calibrated", or "applied" (prediction on new data). The examples below
% show building and applying a model using the object's built-in methods.
%
% Model objects are also output from numerous PLS_Toolbox functions (in the
% calibrated or applied state.) The content of these models can be interrogated
% through the model properties (the object fields available depend on the model
% type and can be accessed through the "fieldnames" method).
%
% The models can also be used through the standard methods as described below.
%
% OPTIONAL INPUT:
%   modeltype = standard model object type to create. E.g. 'pls','pca'.
%
% OUTPUT:
%   model = standard model object of type (modeltype)
%
% EXAMPLES
% BUILD MODEL:
%  m = evrimodel('pls'); %creates an empty PLS model object
%  m.x = x;              %assigns data to the X-block (predictor)
%  m.y = y;              %assigns data to the Y-block (predictand)
%  m.ncomp = ncomp;      %sets the number of components in the model
%  m.options = options;  %assigns model options with a standard options structure
%  m.calibrate;          %performs calibration method
%
% CROSS-VALIDATE MODEL:
%  m.crossvalidate(x,cvi)
%
% APPLY MODEL:
%  p = m.apply(data)
%
% PLOT CONTENTS:
%  m.plotscores
%  m.plotloads
%  m.ploteigen
%
% PROPERTIES:
% The following properties can be modified through SETPLSPREF using
%   setplspref('evrimodel','property',value)
% The properties govern model method behavior and include the following:
% 
%   -- General options --
%     noobject : [ {false} | true ] Disables object use altogether.
%     usecache : [ {false} | true ] Governs use of model cache when models
%                 are calibrated or applied using object methods.
%     
%   -- Type and class testing options -- 
%     stricttesting   : [ false | {true} ] Give warning/error when code
%       tests a model by using "isstruct" or "isfield(...,'modeltype').
%       Best practices are to avoid these methods and use ismodel() instead.
%       This option helps detect code where the poor practices are used.
%     strictmodeltype : [ false | {true} ] Give warning/error when a model
%       type is changed to either an undefined model type or from one model
%       type to an incompatible model type.
%     fatalalerts     : [ {false} | true ] Governs whether above tests
%       give warnings (false) or throw errors (true).
%
%   -- Display options --
%      These settings govern the command-line output for models.
%     desc            : [ false | {true} ] Governs display of model summary
%       details (same as model.info).
%     contents        : [ {false} | true ] Governs display of model fields
%       and summary of their contents (old format of display).
%
%   -- Model application options --
%     plots           : [ {'none'} | 'final' ] Governs showing of plots
%       when model is calibrated or applied to new data.
%     display         : [ {'off'} | 'on' ] Governs display of information
%       at the command line when the model is calibrated or applied to
%       new data. 
%     matchvars       : [ 'off' | {'on'} ] Governs use of variable
%       alignment when apply the model to new data (matchvars).
%       When 'on', new data will be aligned to model before application.
%       When 'off', if the new data variables do not match the model's
%       expected variables, an error will be thrown.
%     contributions   : [ {'passed'} | 'used' | 'full' ] Governs detail
%       of returned T^2 and Q contributions. Return contributions for: 
%       'passed' = only the variables passed by the client in the order
%         passed. This mode allows the client to easily map contributions back
%         to passed data and is the preferred mode.
%       'used'   = all variables used by the model including even variables
%         which client did not provide. Variable order is that used by model
%         and may not match the order passed by the client.
%       'full'   = all variables used or excluded by the model, including even
%         variables which client did not provide. Variable order is that used
%         by model and may not match the order passed by the client.
%     reducedstats  : [ {'off'} | 'on' ] Governs whether Q and T^2 statistics
%       from models are "reduced" using the confidence limit set in the
%       model.detail.reslim and model.detail.tsqlim fields.
%       If 'on', statistics are normalized using the valuestored in the
%         appropriate detail sub-field.
%       If 'off', statistics are returned as calculated.
%
%I/O: model = evrimodel(modeltype); %creates a model object of type (modeltype)
%I/O: model = evrimodel; %creates a generic model object
%
%See also: ANALYSIS, BROWSE

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%-----------Defines Current Model Version-----------
currentversion = '9.3';
%must match logic in private/updatemod
%---------------------------------------------------

%************************************************************************
%                                                                       *
%     NOTE: If modifying existing model ADD CODE TO                     *
%                                                                       *
%           @EVRIMODEL/PRIVATE/UPDATEMOD.M                              *
%                                                                       *
%           for new fields and or fields that have changed locations.   *
%           for new version number.                                     *
%                                                                       *
%           @EVRIMODEL/PRIVATE/TEMPLATE.M                               *
%                                                                       *
%           for new fields with defaults.                               *
%                                                                       *
%                                                                       *
%           @EVRIMODEL/EVRIMODEL.M                                      *
%                                                                       *
%           for new version number.                                     *
%                                                                       *
%           @EVRISCRIPT_MODULE/PRIVATE/EVRISCRIPT_CREATECONFIG.M        *
%                                                                       *
%           for new models update evriscript_config.mat.                *
%                                                                       *
%           @EVRIMODEL/GETSSQTABLE.M                                    *
%                                                                       *
%           add/verify SSQ table logic                                  *
%                                                                       *
%************************************************************************



%default values for non-option fields
tomerge = struct([]);
if nargin>0
  %have an input?
  %- - - - - - - - - - - - - - - - - - - - - - -
  if isa(varargin{1},'evrimodel') & strcmpi(varargin{1}.evrimodelversion,currentversion)
    %an up-to-date model object already?
    obj = varargin{1};
    return;
    
    %- - - - - - - - - - - - - - - - - - - - - - -
  elseif isa(varargin{1},'evrimodel') | isstruct(varargin{1})   
    %an OLD evrimodel or a structure?
    varargin{1} = struct(varargin{1}); %force a structure
    
    if ~isfield(varargin{1},'modeltype') & ~isfield(varargin{1},'evrimodelversion')
      error('Unrecognized model structure');
    end
    
    %calling private updatemod which handles the actual model contents
    %fields. The wrapper fields are handled afterwards (by this function)
    if isfield(varargin{1},'evrimodelversion')
      %apparently a model which was converted to a structure - extract
      %model contents and attempt upgrade
      if ~isfield(varargin{1},'content')
        error('Unrecognized model (missing content field)');
      end
      %extract contents
      mdata = varargin{1}.content;
      mdata.modelversion = varargin{1}.evrimodelversion;  %copy version over
    else
      %just an old model (non-EVRIModel object)
      mdata = varargin{1};
    end
    
    %--Do the Call to Updatemod--
    mdata = updatemod(mdata);
    
    %grab fields from the input structure and copy them into the new object
    %This is also basically the code that defines how an old version of the
    %model (passed as a structure) gets upgraded.
    options = evrimodel('options');

    %update other top-level model wrapper fields as necessary
    %copy these fields over to the options from the passed object
    for f = {'plots' 'display' 'matchvars' 'contributions' 'reducedstats'}
      if isfield(varargin{1},f{:})
        %copy out of passed model INTO options (to be copied back later)
        options.(f{:}) = varargin{1}.(f{:});
      end
    end
    %copy other non-options fields
    for f = {'matchvarsmap'}
      if isfield(varargin{1},f{:})
        %copy out of model into "tomerge" variable (this is for fields
        %which aren't part of options)
        tomerge(1).(f{:}) = varargin{1}.(f{:});
      end
    end
          
    %- - - - - - - - - - - - - - - - - - - - - - -
  elseif nargin==1 & ischar(varargin{1}) & ismember(varargin{1},evriio([],'validtopics'))
    %evriio enabling
    options       = [];

    %disable object use altogether
    options.noobject        = false;
    
    %cache options
    options.usecache        = false;
    
    %type and class testing options
    options.stricttesting   = true;
    options.strictmodeltype = true;
    options.fatalalerts     = false;

    %display options
    options.desc            = true;
    options.contents        = false;
    
    %application options
    options.plots     = 'none';
    options.display   = 'off';
    options.matchvars = 'on';
    options.contributions = 'used';
    options.reducedstats = 'off';

    if nargout==0
      evriio(mfilename,varargin{1},options)
    else
      obj = evriio(mfilename,varargin{1},options);
    end
    return;
    
    %- - - - - - - - - - - - - - - - - - - - - - -
  else
    %other non-evriio calls with strings or non-recognized structures
    if ischar(varargin{1}) & strcmpi(varargin{1},'showall')
      obj = template;
      return
    end
    
    %not a recognized model structure? assume input to modelstruct
    mdata = template(varargin{:});

    options = evrimodel('options');
    
    %- - - - - - - - - - - - - - - - - - - - - - -
  end
else
  %no inputs - create blank model structure
  mdata   = struct('modeltype','');
  options = evrimodel('options');
end

%general wrapper for evrimodel
obj = [];
obj.evrimodelversion = currentversion;
mdata.modelversion = obj.evrimodelversion;  %copy model version into contents
obj.content = mdata;

if options.noobject;
  %special intercept - if noobject option is true, then grab contents now
  %and return as non-object (allows for better backwards compatibility with
  %older versions) But MUST be done after adding modelversion field above.
  obj = mdata;
  return;
end

obj.downgradeinfo = 'Old version model info in "content" field';
obj.parent    = [];  %will hold parent model when "apply" method is called
obj.plots     = options.plots;
obj.display   = options.display;
obj.matchvars = options.matchvars;
obj.matchvarsmap = [];
obj.contributions = options.contributions;
obj.reducedstats = options.reducedstats;
obj.calibrate    = [];

%merge in fields found in old object (or otherwise found to set)
for f=fieldnames(tomerge)';
  obj.(f{:}) = tomerge.(f{:});
end

%Look for a calibrate evriscript for this modeltype
if ~isfield(mdata,'datasource') | isempty(mdata.datasource) | isempty(mdata.datasource{1}.size)
  %as long as we don't have populated datasource...
  method = lower(mdata.modeltype);
  list = evriscript('showall');
  if ismember(method,list);
    %we've got an evriscript to build this kind of model
    scr = evriscript(method);
    if ismember('calibrate',scr(1).step_modes)
      %if this script has a "calibrate" step mode, use it, otherwise use
      %automatic mode
      scr(1).step_mode = 'calibrate';
    elseif length(scr(1).step_modes)>1
      %if there is more than one step mode for this script but calibrate
      %isn't one of them do NOT use any!!
      scr = [];
    end
    if ~isempty(scr)
      if ismember('display',fieldnames(scr.options)); scr.options.display = 'off'; end
      if ismember('plots',fieldnames(scr.options)); scr.options.plots = 'none'; end
    end
    obj.calibrate.script   = scr;  %save in evrimodel object
    obj.calibrate.calprops = {};
    obj.calibrate.calprops = getcalprops(obj);
  end
end

%make an evriscript class
obj = class(obj,'evrimodel');

  
