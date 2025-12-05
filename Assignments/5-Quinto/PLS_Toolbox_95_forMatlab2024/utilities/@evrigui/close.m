function out = close(item)
%EVRIGUI/CLOSE Overload for EVRIGUI object

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ishandle(item.handle)
  close(item.handle)
end

if nargout>0
  out = 1;
end
