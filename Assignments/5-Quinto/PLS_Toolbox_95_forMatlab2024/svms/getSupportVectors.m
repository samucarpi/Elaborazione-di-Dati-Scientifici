function [values,indices] = getSupportVectors(model)
%GETSUPPORTVECTORS Gets the support vectors in array format.
%  This function gets the support vectors in array format from the Java
%  model. 
%  These are possibly preprocessed, possibly compressed X-block
%  sample values, as array sized nSVs x ny, where ny is number of included
%  variables or number of components specified if compression is used.
%  The indices variable is just an index ranging 1 to nSVs.
%
% INPUTS:
%   model  = a standard SVM/SVMDA/SVMOC model.
%
% OUTPUT:
%  values  = array nsamples x nvariables of Support Vectors
%  indices = array nsamples x nvariables where indices(i,j) = j
%
% %I/O: [values, indices] = getSupportVectors(model); get the support 
% vectors values in array format from the svm Java model. 

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

if ismodel(model)
  if strcmp(model.modeltype, 'SVM') | strcmp(model.modeltype, 'SVMDA') ...
       | strcmp(model.modeltype, 'SVMOC')
  model = model.detail.svm.model;
  model = modelToJava(model);
  else
    error('getSupportVectors: Error: input model is not of type ''SVM'' or ''SVMDA''');
  end
elseif isa(model, 'libsvm.svm_model')
  % pass through if is a libsvm.svm_model
else
  error('getSupportVectors: Error: input parameter is not a model');
end
values = libsvm.evri.Helper.getSupportVectorValues(model); 
indices = libsvm.evri.Helper.getSupportVectorIndices(model); 
