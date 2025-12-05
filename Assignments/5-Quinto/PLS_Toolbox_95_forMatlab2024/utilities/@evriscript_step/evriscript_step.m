function step = evriscript_step(keyword)
%EVRISCRIPT_STEP Create evriscript_step.
%I/O: step = evriscript_step

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  keyword = '';
  module  = evriscript_module;
elseif isa(keyword,'evriscript_module')
  opts = evriscript('options');
  if opts.keywordonly
    error('Building EVRISCRIPT from %s is currently disabled',class(keyword));
  end
  module  = keyword;
  keyword = module.keyword;
else
  module = evriscript_module(keyword);
end

%Create step object
step = struct('evriscript_stepversion','1.0');
step.step_keyword = keyword;
step.step_id = now+rand(1);
step.step_label = '';
step.step_lock = false;
step.step_lockedvars = {};
step.step_mode = '';
step.variables = struct;
step.step_module = [];
step.step_required = 'pseduo-property'; %filled in by subsref
step.step_inputs = 'pseduo-property';   %filled in by subsref
step.step_optional = 'pseduo-property';   %filled in by subsref
step.options = [];  % initially get script_module.options

%NOTE: the object fields are all named with the prefix "step_" in order
%to allow the user the "ease of use" assign command: 
%    step.variable = value
%By prefacing all object properties with step_, we likely differentiate
%them from possible variables the user may be assigning for the step.
%Any new fields need to respect that goal and name the new property as to
%not conflict with standard metaparameter names to PLS_Toolbox functions.

step = class(step,'evriscript_step'); 

step.step_module = module;
step.step_mode = '';
step.step_label = module.description;
step.options = step.step_module.options;  % I need to enable setting step.options.field

%if only one mode availabel use that one
modes = step.step_module.modes;
if length(modes)==1
  step.step_mode = modes{1};
end

badnamesflag = ismember(module.inputs,[fieldnames(step)]);
if any(badnamesflag)
  %does step module use one of the field names or method names we need?
  badnames = module.inputs;
  badnames = sprintf('%s ',badnames{badnamesflag});
  error('Script module "%s" contains illegal propery name(s): %s',keyword,badnames)
end

% set default variables
defvars = [];
module = step.step_module;
defs = module.default;
if ~isempty(defs)
  names = fieldnames(defs);
  for i=1:length(names)
    name = names{i};
    value = defs.(name);
    defvars.(name) = value;
  end
  step.variables = defvars;
end
