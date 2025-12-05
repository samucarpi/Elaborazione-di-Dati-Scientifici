function module = evriscript_module(keyword)
%EVRISCRIPT_MODULE Create evriscript_module to wrap function call in an object.
% EVRISCRIPT_MODULE objects are the base object used by EVRISCRIPT objects.
% Each module defines an operation which can be done in a step of an
% EVRISCRIPT script. It defines the PLS_Toolbox function which it is
% wrapping as well as the inputs expected by that function, outputs it will
% return, and default options for any needed options input.
% 
% Create an empty instance of a module:
%    module = evriscript_module;
%  After creating instance of evriscript_module, the following operations
%  can be done to customize the module for its particular operation.
%
% Specify the keyword to instance the module through evriscript objects:
%    module.keyword = 'knn';
%
% Provide a description of the module:
%    module.description = 'KNN K-nearest neighbor classifier';
%
% Add a new mode:
%    module.command.calibrate = 'var.model = knn(var.x,var.k,options);';
%  Creating a new mode starts by defining the "command" property for the
%  mode. This consists of specifying the command property, followed by the
%  mode name ("calibrate" in the example above) and the command to execute
%  for this mode. The mode name is also used to specify mode-specific
%  settings in the "required", "optional" and "outputs" properties of the
%  EVRISCRIPT_MODULE object.
%
%  Note that inputs and outputs from the function are prefixed with "var."
%  to indicate these are properties on the evriscript object (see
%  "required" and "optional" properties below). The "options" input never
%  has a var. prefix as it refers to the EVRISCRIPT_STEP options
%  specifically.
%
%  Any number of modes can be defined for a given module. If only one is
%  defined, this will be the default mode when the given module is added to
%  a script. Otherwise, the default mode will be empty and the user will be
%  forced to choose a mode before the script step containing this module is
%  run.
%
% Define the list of required inputs for the mode:
%    module.required.calibrate = {'x'};
%  This cell array indicates what inputs MUST be defined prior to executing
%  the module in this mode.
%
% Define the list of optional inputs for the mode:
%    module.optional.calibrate = {'k'};
%  This cell array indicates what inputs can be left undefined prior to
%  executing the module in this mode. An optional input, if not defined by
%  the caller, is passed with the value defined in the "default" field (see
%  below). Options are always considered "optional" and need not be
%  listed. The options listed in the "options" field will be passed for
%  these values.
%
% Defining default values for optional inputs:
%    module.default.k = 3;
%  Provide values which are used if the given optional input is not
%  provided by the user. If no inputs are optional, this field will be
%  empty. Note that the default is the same for all modes (this field is
%  not indexed by the mode name.)
%
% Define the list of outputs expected from the mode:
%    module.outputs.calibrate  = {'model'};
%  This cell array indicates the outputs expected. Outputs will be mapped
%  to properties of the evriscript object and, unless listed as a required
%  or optional input for this mode, will be marked as "read only".
%
% Define the options: 
%    module.options = knn('options');
%  Provides a sub-structure which will contain the default options for this
%  function. Only one set of default options can be provided and that will
%  be used for all modes. If different modes of calling this module require
%  different options, then separate modules must be created.
%
% Renaming a mode:
%    module = rename(module,'onecall','mycall')
%  Renames the mode 'onecall' to be 'mycall'.
%
% Locking a module:
%    module.lock = 1
%  Forces the module into "read-only" mode indicating that no additional
%  changes can be made to the object.
% 
%I/O: module = evriscript_module
%I/O: module = evriscript_module('pls')  %return module for this keyword
%
%See also: EVRISCRIPT, EVRISCRIPT_STEP

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  keyword = '';
end

module = struct('evriscript_moduleversion','1.0');
module.keyword = keyword;
module.command = struct([]);   
module.required = struct([]);   
module.optional = struct([]);   
module.default = struct([]);  
module.outputs = struct([]);  
module.options = struct([]);  
module.description = '';
module.lock = false;

module = class(module,'evriscript_module'); 

if isempty(keyword)
  %no keyword given? return empty module
  return;
end


% Read config info for this evriscript_module from .mat file written by evriscript_createConfig.m
projRepository = evriwhich('evriscript_config.mat','-all');  %note: returns a CELL
if isempty(projRepository)
  projRepository = {fullfile(tempdir,'evriscript_config.mat')};
end
if ~iscell(projRepository)
  %force string into a cell
  projRepository = {projRepository};
end

%check if there are any addon products that want to insert evriscript
%methods
toadd = evriaddon('evriscript_configfile');
for j=1:length(toadd)
  item = feval(toadd{j});
  if ~iscell(item)
    item = {item};
  end
  projRepository = [item(:);projRepository(:)];
end

%automatically make sure all those objects are read and consolidated
modules = struct;
for j=length(projRepository):-1:1
  try
    if exist(projRepository{j},'file')
      somemodules = load(projRepository{j});
      if isstruct(somemodules)
        for f=fieldnames(somemodules)';
          %merge in modules from this file into master modules list
          modules.(f{:}) = somemodules.(f{:});
        end
      end
    end
  catch
    error('Error reading in contents of evriscript configuration file %s\n%s', projRepository{j},lasterr);
  end
end

% check that keyword is a field name of modules, i.e., that there is configuration info for this fn.
if ~ischar(keyword)
  error('Invalid input of class "%s"',class(keyword));
elseif strcmp('showall', keyword)
  list = {};
  for f = fieldnames(modules)';
    if isa(modules.(f{:}),'evriscript_module')
      list{end+1} = modules.(f{:}).keyword;
    end
  end
  module = list;
else
  %look for field with matching keyword
  module = [];
  for f = fieldnames(modules)';
    if isa(modules.(f{:}),'evriscript_module') & strcmpi(modules.(f{:}).keyword,keyword)
      module = modules.(f{:}); %grab matching field
      break;
    end
  end
  if isempty(module);
    error('No configuration information found for keyword = ''%s''', keyword);
  end
end
