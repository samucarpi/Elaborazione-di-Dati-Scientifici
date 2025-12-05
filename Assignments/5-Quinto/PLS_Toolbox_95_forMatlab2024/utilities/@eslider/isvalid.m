function valid = isvalid(obj)
%ISVALID Returns true if the given eslider object still exists.
%I/O: valid = isvalid(obj)

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

valid = ishandle(obj.axis) & ishandle(obj.parent);

  
