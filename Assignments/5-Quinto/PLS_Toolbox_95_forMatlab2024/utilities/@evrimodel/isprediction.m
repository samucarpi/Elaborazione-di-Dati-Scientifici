function out = isprediction(obj)
%EVRIMODEL/ISPREDICTION Returns status of whether object contains model predictions

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

type = obj.content.modeltype;
out = ~isempty(strfind(lower(type),'_pred'));
