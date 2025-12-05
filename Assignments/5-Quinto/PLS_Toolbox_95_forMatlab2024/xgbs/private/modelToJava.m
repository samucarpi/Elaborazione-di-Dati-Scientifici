function [jmodel] = modelToJava(mmodel)
%MODELTOJAVA Convert a Matlab xgbModel to a Java ml.dmlc.xgboost4j.java.Booster
% modelToJava converts a Matlab representation of the xgboost model to a
% Java xgboost model (Booster).
%
% %I/O: model = modelToJava(model); Convert matlab model to Java model.
%
%See also: modelToMatlab

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

try
  bytearr   = mmodel.bytearray;
  bytearris = java.io.ByteArrayInputStream(bytearr);
  jmodel    = ml.dmlc.xgboost4j.java.XGBoost.loadModel(bytearris);
catch ME
  if strfind(ME.message, 'java.lang.UnsatisfiedLinkError:') > 0 && ...
      strcmpi(computer,'maca64')
    msg = 'XGB/XGBDA not available for MATLAB/Solo that is running Apple Silicon natively. This method will be available in the next release.';
    error(msg);
  else
    error(encode(ME.message));
  end
end
