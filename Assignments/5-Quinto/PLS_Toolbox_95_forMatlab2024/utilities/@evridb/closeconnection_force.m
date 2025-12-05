function out = closeconnection_force(obj,conn)
%EVRIDB/CLOSECONNECTION Close evrdb database without regard to .persistent.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

obj.keep_persistent = 'no';

if nargin<2
  out = closeconnection(obj);
else
  out = closeconnection(obj,conn);
end
