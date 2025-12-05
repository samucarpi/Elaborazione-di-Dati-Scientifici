function [b,theta] = ridge_hkb(xblock,yblock)
%RIDGE_HKB Ridge regression by Hoerl-Kennard-Baldwin.
%  This function performs ridge regression. This is a stripped down version
%  of ridge.m for MLR purposes.
%
%I/O: [b,theta] = ridge_hkb(xblock,yblock);
%
%See also: ANALYSIS, MLR, PCR, PLS, REGCON, RIDGECV, RINVERSE

% Copyright © Eigenvector Research, Inc. 2022
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin == 0; xblock = 'io'; end
varargin{1} = xblock;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear b; evriio(mfilename,varargin{1},options); else; b = evriio(mfilename,varargin{1},options); end
  return; 
end

[m,n] = size(xblock);
dfs = m - n - 1;
b = zeros(n,1);
b(:,1) = xblock\yblock;
ridi = diag(diag(xblock'*xblock));
dif = xblock*b(:,1)-yblock;
ssqerr = dif'*dif;
theta = n*(ssqerr/dfs)/sum((ridi.^0.5*b(:,1)).^2);

b = inv(xblock'*xblock + ridi*theta)*xblock'*yblock;

