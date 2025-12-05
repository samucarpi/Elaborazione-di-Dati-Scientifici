function obj = gettobj(fh,tag)
%EVRITREE/GETTOBJ Get evritree object.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
obj = [];
if ishandle(fh)
  obj = getappdata(fh,tag);
end
