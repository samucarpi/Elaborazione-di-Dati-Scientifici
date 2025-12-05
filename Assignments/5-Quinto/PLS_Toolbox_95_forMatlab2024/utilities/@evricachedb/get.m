function val = get(obj,prop)
%EVRICACHEDB/GET Get property of cachedb object.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

switch prop
  case 'dbobject'
    val = obj.dbobject;
  case 'version'
    val = obj.version;
end
