function a = plotloads_mlsca(modl,options)
%PLOTLOADS_MLSCA Plotloads helper function used to extract info from model.
% Called by PLOTLOADS.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Wrapper around plotascaloads
if isfield(options,'mlsca_submodel') & ~isempty(options.mlsca_submodel) & ~options.mlsca_submodel==0
  a = plotascaloads(modl,options.mlsca_submodel);
else
  a = plotascaloads(modl);
end
