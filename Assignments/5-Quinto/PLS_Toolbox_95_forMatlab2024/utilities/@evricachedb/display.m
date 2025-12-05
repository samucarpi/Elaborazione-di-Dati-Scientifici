function display(obj)
%EVRICACHEDB/DISPLAY Display evricachedb object.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


disp('EVRI Cache Object');
disp(['-----------------------------------'])
disp(['Date Type: ' obj.date_source])
disp(['Date Sort: ' obj.date_sort])
disp([' '])
disp(['-----------------------------------'])
% disp(sprintf('Location     : %s',obj.cachedir))
% disp(['-----------------------------------'])
% disp(sprintf('DatabaseObject'))
% disp(' ')
% disp(' ')
disp(obj.dbobject)
