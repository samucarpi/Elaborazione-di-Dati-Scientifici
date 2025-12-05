function plabels = makeplabels(lab1,lab2);
%MAKEPLABELS Helper function for UNFOLDMW.

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

[m1,n1] = size(lab1);
[m2,n2] = size(lab2);
plabels = char(zeros(m1*m2,n1+n2+3));
k = 0;
for j = 1:m2
  for i = 1:m1
    k = k+1;
    plabels(k,:) = [lab1(i,:) ' & ' lab2(j,:)];
  end
end
