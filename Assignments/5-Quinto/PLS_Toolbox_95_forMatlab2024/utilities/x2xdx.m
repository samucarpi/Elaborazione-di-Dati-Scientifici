function [xdx,sf,sconind] = x2xdx(x,w,o,d,wt,sf,ncomp)
%X2XDX Augments to [x,sf*dx]
%  Calculates dx=SavGol(x,w,o,d) and augments to [x,sf*dx]
%  For p = floor(w/2), the ends 1:p and N-p+1:N are excluded
%  (soft deleted).
%
%  INPUT:
%      x = MxN measured data (class DataSet).
%          Input (x) is usually a set of spectra with each spectrum in a
%          row of (x).
%
%  OPTIONAL INPUTS:
%      w = SAVGOL filter width (width) {default = 15}, [see SAVGOL].
%      o = filter order (order)  {default = 2}.
%      d = filter derivative (deriv) {default = 1}.
%     wt = filter weighting [ {''}, | '1/d' ]
%     sf = scale factor [if empty it is calculated as the ratio
%            norm(x,'fro')/norm(xdx,'fro')]
%  ncomp = number of components K for sconind
%
%  OUTPUT:
%    xdx = Mx2N martix [x,sf*dx] (class DataSet).
%     sf = scale factor (scalar). 
%          If (sf) is input then the output sf = input sf.
%          If not input or is empty, (sf) is calculated as the ratio
%            norm(x,'fro')/norm(xdx,'fro')
%  sconind = [ones(ncomp,N), zeroes(ncomp,N)] for ALS and/or MCR.
%            E.g., see MCR options.alsoptions.sconind.
%
%I/O: [xdx,sf,sconind] = x2xdx(x,w,o,d,wt,sf,ncomp);

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<2
  w     = 15;
end
if nargin<3
  o     = 2;
end
if nargin<4
  d     = 1;
end
if nargin<5
  wt    = '';
end
if nargin<7 || isempty(ncomp)
  ncomp = 0;
end
if ~isdataset(x)
  error('Input (x) must be class DataSet.')
end
m       = [size(x),length(x.include{2})];

xdx     = savgol(x,w,o,d,struct('wt',wt));
p       = floor(w/2);
xdx     = delsamps(xdx,       1:p,   2,1);  
xdx     = delsamps(xdx,m(2)-p+1:m(2),2,1);
if nargin<6 || isempty(sf)
  sf    = norm(x.data.include,'fro')/norm(xdx.data.include,'fro');
end
xdx.data  = xdx.data*sf;
if ncomp>0
  sconind = [ones(ncomp,m(2)), zeros(ncomp,m(2))];
end
xdx     = [x,xdx];

end %X2XDX
