function varargout=subsref(x,index)
%EVRISCRIPT_MODULE/SUBSREF Enables methods in evriscript_module object
% In addition to the standard properties of an evriscript_module, the
% following pseudo properties exist:
%
%    modes = cell array of valid modes
%    inputs = cell array of all possible inputs (for all modes)

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

    

if ~strcmp(index(1).type,'.')
  error('This type of indexing not allowed on EVRIScript_module object')
end

mode = index(1).subs;
switch mode
  case fieldnames(x)
    varargout{1} = x.(mode);  % or builtin('subsref',x, index);
    if length(index)>1
      varargout{1} = subsref(varargout{1},index(2:end));
    end
    
  case 'modes'
    varargout{1} = fieldnames(x.command);
    varargout{1} = varargout{1}(:)';
    
  case {'display' 'disp'}            % these have no output
    disp(x);

  case {'inputs'}
    %generate list of inputs (required or otherwise) for every mode
    allTotal = {};
    if ~isempty(x.required)
      allreq   = struct2cell(x.required);
      allTotal = [allreq{:}];
    end
    if ~isempty(x.optional)
      allopt   = struct2cell(x.optional);
      allTotal = [allTotal{:} allopt{:}];
    end
    varargout{1} = unique(allTotal);
    
  otherwise
    error('Undefined function or method ''%s'' for input arguments of type ''evriscript_module''.',mode)

end
