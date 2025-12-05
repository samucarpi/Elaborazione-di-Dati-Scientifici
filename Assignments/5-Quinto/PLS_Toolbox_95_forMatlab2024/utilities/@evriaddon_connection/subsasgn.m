function obj = subsasgn(varargin)
%EVRIADDON_CONNECTION/SUBSASGN Assign fields of EVRIADDON_CONNECTION object

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = varargin{1};
S   = varargin{2};

if ~strcmp(S(1).type,'.')
  error('Assignment must be done with "obj.connection_name" format')
end

key      = S(1).subs;
newvalue = varargin{3};

switch key
  case 'name'
    if ~ischar(newvalue);
      error('Property "name" must be a string');
    end
    if length(S)>1;
      newvalue = subsasgn(obj.name,S(2:end),newvalue);
    end

  case 'priority'
    if ~isnumeric(newvalue) || length(newvalue)~=1
      error('Property "priority" must be a single numeric value');
    end
    newvalue = double(newvalue);
    
  case obj.entrypoints
    %entrypoint field
    if length(S)>1;
      newvalue = subsasgn(obj.(key),S(2:end),newvalue);
    end
    if ~iscell(newvalue);
      newvalue = {newvalue};
    end
    %validate all entries
    for k=length(newvalue):-1:1;
      if ~isa(newvalue{k},'function_handle')
        error(['Invalid function handle for "' key '"']);
      end
%       if isempty(getfield(functions(newvalue{k}),'file'))
%         newvalue = newvalue([1:k-1 k+1:end]);
%       end
    end

  otherwise
    error(['"' key '" is not a valid entry point or EVRIADDON_Connection property.'])
    
end

obj.(key) = newvalue;
