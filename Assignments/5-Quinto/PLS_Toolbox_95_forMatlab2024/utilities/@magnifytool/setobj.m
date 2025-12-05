function setobj(obj)
%MAGNIFYTOOL/SETOBJ Save object to appdata of display axis.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

setappdata(obj.display_axis,'magnifytool',obj);
