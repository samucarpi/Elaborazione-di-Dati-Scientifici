function cvbias = calccvbias(model,cvpred)
%CALCCVBIAS Calculate the Cross-Validation Bias from a cross-validated model
% Calculates the cross-validated bias based on a regression model and its
% cross-validation results. If the passed model contains the cvpred
% information in the detail field, the second input (cvpred) can be
% omitted. If no cvpred information is in the model (i.e.
% model.detail.cvpred is empty), then the second input must be supplied as
% passed from crossval.
%
%I/O: cvbias = calccvbias(model)
%I/O: cvbias = calccvbias(model,cvpred)
%
%See also: CROSSVAL

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isstruct(model)
  includ = model.detail.includ{1,2};
  ydata  = model.detail.data{2}.data(includ,:);
elseif isdataset(model)
  includ = model.include{1};
  ydata  = model.data(includ,:);
else
  ydata  = model;
  includ = 1:size(ydata,1);
end

if nargin<2
  if ~isstruct(model)
    error('CVPRED is required input when model is not supplied')
  end
  cvpred = model.detail.cvpred;
  if isempty(cvpred)
    error('Cross-validation results must be embedded in model or passed as second input')
  end
end
cvpred = cvpred(includ,:,:);
ncomp = size(cvpred,3);

cvbias = ones(size(ydata,2),ncomp)*NaN;
for ycol = 1:size(ydata,2);
  cvbias(ycol,1:ncomp) = mean(scale(squeeze(cvpred(:,ycol,:))',ydata(:,ycol)'),2)';
end
