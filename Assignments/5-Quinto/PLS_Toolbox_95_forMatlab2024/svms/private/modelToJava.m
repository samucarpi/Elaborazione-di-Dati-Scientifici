function [jmodel] = modelToJava(mmodel)
%MODELTOJAVA Convert a Matlab svmModel to a Java libsvm.svm_model
% modelToJava converts a Matlab representation of the libsvm model to a
% Java libsvm model.
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
% %I/O: model = modelToJava(model); Convert matlab model to libsvm Java model.
%
%See also: 

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

svmParameter = libsvm.svm_parameter;
% initialize the svm_parameter:
pnames = fieldnames(mmodel.param);
skip = {'C_SVC' 'NU_SVC' 'ONE_CLASS' 'EPSILON_SVR' 'NU_SVR' ...
  'LINEAR' 'POLY' 'RBF' 'SIGMOID' 'PRECOMPUTED' 'param' 'SVvalue'};
for ifn=1:length(pnames);
  if ismember(pnames{ifn},skip); continue; end
  try
    svmParameter.(pnames{ifn}) = mmodel.param.(pnames{ifn});
  catch
    disp(['Skipping parameter fieldname ' pnames{ifn}])
  end
end
% Check: there may be a problem with the type of weight_label. It needs to be
% int[] in Java, but appears to be double[]

jmodel = libsvm.svm_model;
% initialize the svm_model
p1names = fieldnames(mmodel);
for ifn=1:length(p1names);
  if ismember(p1names{ifn},skip); continue; end
  try
    jmodel.(p1names{ifn}) = mmodel.(p1names{ifn});
  catch
    %   disp(['modelToJava: Skipping unnecessary field: ' p1names{ifn}])
  end
end

jmodel.param = svmParameter;
% Still need to set jmodel.SV
% First, reconstruct the SVindex: 
dim1 = 0; dim2=0;
if isfield(mmodel, 'SVvalue')
  [dim1 dim2] = size(mmodel.SVvalue);
else
  mmodel.SVvalue = repmat(1:dim2, dim1, 0);;
end

% [dim1 dim2] = size(mmodel.SVvalue);
SVindex = repmat(1:dim2, dim1, 1);
libsvm.evri.Helper.putSupportVectors(jmodel, mmodel.SVvalue, SVindex);
if jmodel.l==0
    mmodel.sv_coef = nan(1,0);
end
