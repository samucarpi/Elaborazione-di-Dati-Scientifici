function a = plotloads_batchmaturity(modl,options)
%PLOTLOADS_BATCHMATURITY Plotloads helper function used to extract info from model.
% Called by PLOTLOADS.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

apca = plotloads(modl.submodelpca,options);
apls = plotloads(modl.submodelreg,options);

a = [apca apls];
