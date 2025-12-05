function script = evriscript(varargin)
%EVRISCRIPT Create evriscript.
% EVRISCRIPT objects allow calling various PLS_Toolbox operations in an
% object-oriented way. A script can contain one or more steps, each of
% which is a separate object with its own inputs and outputs. Each step is
% defined by a keyword which represents the type of step (known as a
% module) to perform.
%
% Creating a script:
%  Call evriscript with parameters indicating the sequence of steps to 
%  perform, each step indicated by its keyword. The list of available
%  step keywords is given by the command:  evriscript('showall')
%  Example, myscript = evriscript( 'pls', 'crossval', 'choosecomp', 'pls');
%    evriscript(keyword,keyword,...)
% 
%  'myscript' is an evriscript object. The script steps are evriscript_step
%  objects which can be accessed by indexing, 'myscript(1)', for example.
%
%  The individual steps' properties are then configured. Most steps have
%  more than one 'step_mode', for example 'calibrate', 'apply' or 'test'. 
%  You can see which step_modes are avaialable for a step by entering
%     myscript(1).step_module
%  This also shows the required and optional properties associated with the
%  step for each step_mode. The 'calibrate' step_mode lists required
%  properties as: 'x', 'y', and 'ncomp'.
%  A list of valid modes, and required fields can also be obtained using:
%     myscript(1).step_modes          %get valid step_mode settings
%     myscript(1).step_required       %get required fields
%
% Assigning step properties:
%    script(step).property = value
%  where "step" is the step number to modify and "property" is the property
%  to assign with the given value.
%  Example:
%   myscript(1).step_mode              = 'calibrate';
%   myscript(1).options.display        = 'on';
%   myscript(1).options.plots          = 'none';
%   myscript(1).options.preprocessing  = {'autoscale'};
%   myscript(1).x                      = xblock1;
%   myscript(1).y                      = yblock1;
%   myscript(1).ncomp                  = ncomp;
%  Note, that assigned variables must exist in the workspace, xblock1,
%  yblock1, ncomp, for example.
%
% Defining step mode:
%  Some step modules can operate in different "modes" and the desired
%  mode must be selected prior to script exection. Typically, modes define
%  different required inputs and provided outputs. The specifics of the
%  inputs and outputs are defined on the help page for the given module
%  (this is the same as the function help page). Examples are the
%  "calibrate", "test", and "apply" modes of the PCA, PLS, and other
%  modeling functions.
%  To define the mode for a given step, assign the "step_mode" property of
%  the given script step. Example:
%    script(1).step_mode = 'calibrate'
%  assign step one's mode to be "calibrate". Note that if a given module
%  has only one mode it can operate in, that mode is automatically
%  selected. Otherwise, the user must choose among the modes available.
%
% Executing a script:
%  Once a script is created, all the steps can be executed using the
%  "execute" method:
%    script.execute
%  The results of each step are stored in the properties of the step and
%  can be retrieved using standard property indexing:
%    script(2).property
%
% Step Output/Input Referencing (chaining):
%  The input to one step in a script can be defined "by reference" where
%  the contents will be taken from the output of a previous script step at
%  execution time. Generically the call is:
%    script.reference(fromStep,'fromProperty',toStep,'toProperty')
%  Example:
%    script.reference(1,'outputvar',2,'inputvar')
%  References can also be used in the form:
%    script(toStep).inputvar = evriscript_reference('outputvar',fromStep)
%    For example:
%    myscript(2).rm = evriscript_reference('model', myscript(1));
%
% Other Methods:
%  The following methods are also defined for EVRISCRIPT objects:
%   add(obj,step)                % Add new step to end of script
%   add(obj,step,insertIndex)    % Add new step at insertIndex position
%   swap(obj, index1, index2)    % Swap the two steps at these indices
%   delete(stepIndex)            % Delete the indicated script step number
%
% Indexing:
%  Script objects can also be indexed and modified using standard Matlab
%  array notation. For example:
%   [script evriscript('keyword')]  % add a new step to the end of script
%   script(stepIndex) = []          % delete the indicated script step
%   script(stepIndex)               % extracts indicated step(s) from script
%
%I/O: script = evriscript
%I/O: script = evriscript(keyword)
%I/O: script = svriscript(keyword1,keyword2,...)
%
%See also: EVRISCRIPTDEMO

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==1 & ischar(varargin{1}) & ismember(varargin{1},{'demo' 'test' 'options'})
  options = [];
  options.keywordonly = false;
  if nargout==0; evriio(mfilename,varargin{1},options); else; script = evriio(mfilename,varargin{1},options); end
  return
end

script = struct('evriscriptversion','1.0');
script.label = [];
script.lock = false;
script.steps = {};

script = class(script,'evriscript'); 

if nargin>0 
  for i=1:length(varargin)
    if ischar(varargin{i}) & strcmp(varargin{i},'showall')
      %handle showall keyword (special - return list only)
      script = evriscript_module('showall');
      return
    end
    script = add(script, varargin{i});
  end
else
  script.label = 'Un-named evriscript';
end
