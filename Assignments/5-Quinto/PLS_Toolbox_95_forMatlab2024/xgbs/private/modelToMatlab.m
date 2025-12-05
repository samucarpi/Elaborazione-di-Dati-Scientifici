function [mmodel] = modelToMatlab(jmodel)
%MODELTOMATLAB Convert Java ml.dmlc.xgboost4j.java.Booster to a Matlab representation
% modelToMatlab converts a Java xgboost model to a matlab version model as
% an opaque byte array representation of the model. This can be recovered 
% to a Java Booster by using modelToJava
%
% %I/O: model = modelToMatlab(model); Convert XGBoost Java model to Matlab
%
%See also: modelToJava

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.


if(isa(jmodel, 'ml.dmlc.xgboost4j.java.Booster'))
  mmodel.bytearray = jmodel.toByteArray;
else
  error('Input argument is not a ml.dmlc.xgboost4j.java.Booster object')
end
