function a = plotloads_asca(modl,options)
%PLOTLOADS_ASCA Plotloads helper function used to extract info from model.
% Called by PLOTLOADS.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Wrapper around plotascaloads
if isfield(options,'asca_submodel') & ~isempty(options.asca_submodel) & ~options.asca_submodel==0
  a = plotascaloads(modl,options.asca_submodel);
else
  a = plotascaloads(modl);
end
