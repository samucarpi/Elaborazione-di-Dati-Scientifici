function obj = rename(obj,mode,newmode)
%EVRISCRIPT_MODULE/RENAME Renames an EVRIScript_Module mode.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<3
  error('Requires both the current mode name and the new mode name')
end

if obj.lock
  error('Module is locked - cannot assign values')
end

if ~isfield(obj.command,mode)
  error('Mode "%s" does not exist in script module',mode)
end

for f = {'outputs' 'optional' 'required' 'command'};
  obj.(f{:}).(newmode) = obj.(f{:}).(mode);
  obj.(f{:}) = rmfield(obj.(f{:}),mode);
end
