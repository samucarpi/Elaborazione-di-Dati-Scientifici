function mm=missmean(X)
%MISSMEAN Mean of a matrix X with NaN's.
%
%I/O: [mm]=missmean(X)
%

% Copyright Eigenvector Research, Inc. 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Insert zeros for missing, correct afterwards
missidx = isnan(X);
i = find(missidx);
X(i) = 0;

%Find the number of real(non-missing objects)
if min(size(X))==1,
   n_real=length(X)-sum(missidx);
else
   n_real=size(X,1)-sum(missidx);
end

i=find(n_real==0);
if isempty(i) %All values are real and can be corrected
   mm=sum(X)./n_real;
else %There are columns with all missing, insert missing
   n_real(i)=1;
   mm=sum(X)./n_real;
   mm(i)=i + NaN;
end
