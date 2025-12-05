function a = plotloads_npls(varargin)
%PLOTLOADS_NPLS Plotloads helper function used to extract info from model.
% Called by PLOTLOADS.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


if varargin{2}.block==2
  %y-block laodings
  a = plotloads_builtin(varargin{:});
else
  %x-block loadings
  a = plotloads_mcr(varargin{:});
end
