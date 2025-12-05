function out = eq(a,b)
%EVRIGUI/EQ Overload for EVRIGUI object

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~isa(b,class(a))
  out = false;
else
  out = (a.handle==b.handle);
end

