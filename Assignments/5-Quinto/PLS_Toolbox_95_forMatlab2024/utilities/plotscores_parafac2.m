function a = plotscores_parafac2(modl,test,options)
%PLOTSCORES_PARAFAC2 Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2016
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

modl.detail.ssq = [];
if ~isempty(test); test.detail.ssq = [];end
a = plotscores_mcr(modl,test,options);
