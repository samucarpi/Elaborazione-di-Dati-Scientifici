function [count] = getSupportVectorsCount(model)
%GETSUPPORTVECTORSCOUNT Gets the number of support vectors in model.
%  This function gets the number of support vectors from the Java model
%
% %I/O: out = getSupportVectors(model); get the number ofsupport vectors from the svm Java model

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.


count = 0;

try
  if ~isempty(model.detail.svm.model.l) & isnumeric(model.detail.svm.model.l)
    count = model.detail.svm.model.l;
  end
catch
  count = 0;
end
