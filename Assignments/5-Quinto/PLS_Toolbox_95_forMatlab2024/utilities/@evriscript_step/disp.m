function disp(obj,idetail)
%EVRISCRIPT_STEP/DISP Overload for display function.
%I/O: disp(evriscript_step)     Display keyword, label and id of evriscript_step
%I/O: disp(evriscript_step, 0)  Display keyword, label and id of evriscript_step
%I/O: disp(evriscript_step, 1)  Display more fields of evriscript_step
%I/O: disp(evriscript_step, 2)  Display more detail of the evriscript_module

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==1
  idetail = 0;
elseif nargin==2 & (isempty(idetail) | ~isnumeric(idetail))
  idetail = 0;
end

disp(' EVRIScript_step Object');
disp(sprintf('    step_keyword: ''%s''', obj.step_keyword));
disp(sprintf('      step_label: ''%s''', obj.step_label));
modes = fieldnames(obj.step_module.command);
if isempty(modes)
  modes = {''};
end
disp(['       step_mode: ''' obj.step_mode '''']);
disp(['      step_modes: { ' sprintf('''%s'' ',modes{:}) '}']);
if isempty(obj.step_mode)
  required = 'n/a ';
else
  required = obj.step_module.required.(obj.step_mode);
  required = sprintf('''%s'' ',required{:});
end
disp(['   step_required: { ' required '}']);
if obj.step_lock
  lockstr = 'LOCKED (1)';
else
  lockstr = 'Unlocked (0)';
end
disp(['       step_lock: ' lockstr]);

if idetail > 0
  if idetail == 2
    disp(sprintf('         step_id:%20.12f', obj.step_id));
  end
  if idetail == 1
    % Less detail on evriscript_module, and do not show options
    disp(sprintf('     step_module: ''%s''', obj.step_module.keyword));
  end
end

disp('  + properties ');

%assigned variables
if ~isempty(obj.variables) & isstruct(obj.variables) & ~isempty(fieldnames(obj.variables))
  assigned = fieldnames(obj.variables)';
else
  assigned = {};
end

%identify inputs and grand list of everything
if idetail==0 & ~isempty(obj.step_mode);
  inputs = obj.step_module.required.(obj.step_mode);
  inputs = union(inputs,obj.step_module.optional.(obj.step_mode));
  list   = union(inputs,obj.step_module.outputs.(obj.step_mode));
else
  inputs = obj.step_module.inputs;
  outs   = struct2cell(obj.step_module.outputs);
  outs   = [outs{:}];
  list   = union(inputs,outs);
end
list     = union(list,assigned);
readonly = setdiff(list,inputs);

%options (if any)
if ~isempty(obj.options)
  list = union(list,{'options'});
end
locked = obj.step_lockedvars;

nchars = size(char(list),2)+2;  %determine # of spaces to pad to align all

%display each item
for f = list(:)';
  if ismember(f{:},locked)
    vartype = '(*Locked*)';
  elseif ismember(f{:},readonly)
    vartype = '(*Read Only*)';
  else
    vartype = '';
  end
  if ismember(f{:},assigned) & ~isempty(obj.variables.(f{:}))
    var    = obj.variables.(f{:});
    sz     = size(var);
    if isnumeric(var) & sz(1)==1 & sz(2)<4
      desc = sprintf('%s ',num2str(var));
      if sz(2)>1
        desc = [' [ ' desc ']'];
      end
    elseif isa(var,'evriscript_reference')
      desc = sprintf('[ reference : ''%s'' ]',var.ref_variable);
    elseif ischar(var) & sz(1)==1 & sz(2)<30
      desc = sprintf('''%s''',var);
    else
      %more complicated, do generic description
      szdesc = sprintf('%ix',sz);
      szdesc = szdesc(1:end-1);
      cls    = class(var);
      desc   = sprintf('[ %s %s ]',szdesc,cls);
    end
  elseif strcmp(f{:},'options')
    %options (if any)
    badopts = {'name','definitions' 'functionname'};
    fnames  = fieldnames(obj.options);
    fnames  = setdiff(fnames,badopts);
    desc    = sprintf('(%i options)',length(fnames));
    if obj.step_lock
      %options are always locked with main lock
      vartype = '(*Locked*)';
    end
  else
    desc = '(unassigned)';
  end
  disp(sprintf('  %s%s: %s %s',blanks(nchars-length(f{:})),f{:},desc,vartype))
end

if idetail==2
  disp(' ');
  disp(' + script_module ');
  obj.step_module.display;
end
