function varargout=subsref(x,index)
%EVRISCRIPT_REFERENCE/SUBSREF Enables methods in evriscript_reference object

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~strcmp(index(1).type,'.')
  error('This type of indexing not allowed on evriscript_module object')
end

mode = index(1).subs;
switch mode
  case fieldnames(x)
    varargout{1} = x.(mode);  % or builtin('subsref',x, index);
    if length(index)>1
      varargout{1} = subsref(varargout{1},index(2:end));
    end
  case {'display'}            % these have no output
    disp(x);
  otherwise
    if nargout>0;
      [varargout{1:nargout}] = feval(mode,x);
    else
      varargout{1} = feval(mode,x);
    end
    if length(index)>1
      varargout{1} = subsref(varargout{1},index(2:end));
    end
end
