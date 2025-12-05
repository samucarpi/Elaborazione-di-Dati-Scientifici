function varargout = subsref(obj, s)

%Copyright Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~strcmp(s(1).type,'.')
  error('Invalid indexing for evriscript object');
end

mth = setdiff(methods(obj),{'subsref'});
validmethods = [mth(:)];

subsval = s(1).subs;

switch subsval
  
  case fieldnames(struct(obj))
    varargout{1} = obj.(subsval);
    
  case {'version'}
    jclient = obj.jclient;
    ver = jclient.getClientVersion;
    varargout{1} = ver;
    
  case {'getdefaultgroup'}
    jclient = obj.jclient;
    group = jclient.getDefaultGroup;
    varargout{1} = group;   %feval(subsval,obj);
    
  case {'connect'}
    val = {};
    if length(s)>1 & strcmp(s(2).type, '()')
      val = s(2).subs;
      s = s([1 3:end]); %drop step 2
    end
    if length(val)<5
      error('One or more connection parameters missing: obj.connect(ipaddress, domain, username, password, serverprogid) expected');
    end
    if ~all(cellfun(@(i) ischar(i),val))
      error('All connection parameters must be strings');
    end
    varargout{1} = connectx(obj, val{1}, val{2}, val{3}, val{4}, val{5});
    
  case {'disconnect'}
    jclient = obj.jclient;
    jclient.disconnect;
    
  case {'read' 'write'}
    val = {};
    if length(s)>1 & strcmp(s(2).type, '()')
      val = s(2).subs;
      s = s([1 3:end]); %drop step 2
    end
    if strcmp(subsval, 'read')
      if length(val)<1
        error('Itemname to read is missing: obj.read(''itemname'') expected');
      end
      [varargout{1}] = readx(obj, val{1});
    elseif strcmp(subsval, 'write')
      if length(val)<2
        error('Itemname and value to write are required: obj.write(''itemname'',value) expected');
      end
      varargout{1} = writex(obj, val{1}, val{2});
    end
    
  case {'display' 'disp'}
    disp(obj);
    
  case validmethods
    if nargout>0;
      [varargout{1:nargout}] = feval(subsval,obj);
    else
      varargout{1} = feval(subsval,obj);
    end
    
  otherwise
    error('Unknown opcclient function called ''%s''.',subsval)
end

% need to only do this if all the s.type are '.'
if length(s)>1 & ~isempty(varargout)
  varargout{1} = subsref(varargout{1},s(2:end));
end



% B = builtin('subsref', A, S);
