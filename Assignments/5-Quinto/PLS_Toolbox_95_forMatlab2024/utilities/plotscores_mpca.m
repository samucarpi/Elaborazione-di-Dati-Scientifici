function a = plotscores_mpca(modl,test,options)
%PLOTSCORES_MPCA Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 8/25/03 -fixed bug associted with non-model input to plotscores (get
%    number of PCs from LAST MODE of scores instead of loads)

a = plotscores_pca(modl,test,options);


