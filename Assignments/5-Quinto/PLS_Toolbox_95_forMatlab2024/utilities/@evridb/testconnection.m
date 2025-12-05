function [out, myerr] = testconnection(obj)
%EVRIDB/TESTCONNECTION Test db connection.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = false;
myerr = '';
try
  connstr = getconnection(obj);
  out = true;
catch
  myerr = lasterr;
end
