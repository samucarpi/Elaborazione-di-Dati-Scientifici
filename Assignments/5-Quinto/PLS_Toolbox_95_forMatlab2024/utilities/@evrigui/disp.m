function out = disp(item)
%EVRIGUI/DISP Display command for EVRIGUI object.

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = {
  sprintf('  EVRIGUI Object')
  sprintf('         type = ''%s''',item.type)
  };

if ~isvalid(item)
  out{end+1} = sprintf('       handle = **Invalid** (closed)');
else
  hstr = sprintf('%g (visibility: %s)',double(item.handle),get(item.handle,'handlevisibility'));
  out{end+1} = sprintf('       handle = %s',hstr);
  out{end+1} = sprintf('    interface = [%i interface methods]',length(validmethods(item.interface)));
end

if nargout==0
  disp(char(out));
  clear out
end
