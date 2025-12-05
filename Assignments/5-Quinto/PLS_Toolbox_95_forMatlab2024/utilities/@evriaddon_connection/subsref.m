function val = subsref(varargin)
%EVRIADDON_CONNECTION/SUBSREF Retrieve add-on connection information.

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = varargin{1};
S   = varargin{2};
if ~strcmp(S(1).type,'.')
  error('Invalid indexing for EVRIAddOn_Connection object');
end

switch S(1).subs
  case [obj.entrypoints {'name' 'priority'}]
    val = obj.(S(1).subs);

  case 'help'
    if length(S)>1 
      if strcmp(S(2).type,'()');
        S(2).subs = S(2).subs{end};
      end
      if strcmp(S(2).type,'.') | strcmp(S(2).type,'()')
        if isfield(obj.help,S(2).subs)
          val = obj.help.(S(2).subs);
        else
          error(['"' S(2).subs '" is not a valid EVRIAddOn_Connection entry point name']);
        end
      else
        error('Help requests must provide an entry point:  obj.help.entrypoint')
      end
      S = S([1 3:end]);
    else
      error('Help requires entry point to retrieve')
    end
      
    
  case 'entrypoints'
    val = obj.entrypoints;
    
  otherwise
    error(['"' S(1).subs '" is not a valid EVRIAddOn_Connection entry point name']);
    
end

if length(S)>1;
  val = subsref(val,S(2:end));
end
