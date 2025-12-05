function a = plotloads_als_sit(modl,options)
%PLOTLOADS_ALS_SIT Plotloads helper function used to extract info from model.
% Called by PLOTLOADS.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

modl.detail.ssq = [];

if options.mode==1
  options     = plotscores('options');
  options.sct = 0;
  a = plotscores_mcr(modl,[],options); 
else
  a = plotloads_mcr(modl,options);
end
