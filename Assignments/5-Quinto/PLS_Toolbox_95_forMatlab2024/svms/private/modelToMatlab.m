function [mmodel] = modelToMatlab(jmodel)
%MODELTOMATLAB Convert a Java libsvm.svm_model to a Matlab svmModel
% modelToMatlab converts a Java libsvm model to a matlab version model.
%
% svm_model fields:
%     'param'       % svm_param
%     'nr_class'    % int
%     'l'           % int
%     'SV'          % svm_node[nsample][nvar], where svm_node has index and
%                     value fields, int and double respt..
%     'sv_coef'     % double[][]. Regression has sv_coef[1][nsample]
%     'rho'         % double
%     'probA'       % double
%     'probB'       % double or null (regression)
%    for classification only:
%     'label'       % int[nr_class] or null (regression)
%     'nSV'         % int[]
%
% %I/O: model = modelToMatlab(model); Convert libsvm Java model to Matlab model.
%
%See also: 

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.


if(isa(jmodel, 'libsvm.svm_model'))
  mmodel = struct(jmodel);
  % param
  param = struct(jmodel.param);
  mmodel.param = param;
  
  % The SV field is converted to arrays below, so remove this Java type from the mmodel
  if isfield(mmodel, 'SV')
    mmodel = rmfield(mmodel, 'SV');
  end
  
  % SV
  if mmodel.l > 0
    mmodel.SVvalue = libsvm.evri.Helper.getSupportVectorValues(jmodel);
  end
else
  error('Input argument is not a libsvm.svm_model object')
end
