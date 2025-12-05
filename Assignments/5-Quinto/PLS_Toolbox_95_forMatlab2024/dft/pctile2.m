function pctile = pctile2(x,p)
%PCTILE2 Returns the Pth percentile of a matrix or vector.
%  Inputs are the data matrix or vector (x) and (p) one or more percentiles
%  to calculate (0<p<100). The percentile is found by locating the values
%  on either side of the desired percentile, then linearally interpolating
%  between those points. This is in contrast to the pctile1 function which
%  does no interpolation.
%  The output (pctile) is the percentile. If p is a vector, the output
%  contains one row for each input percentiles requested.
%
%I/O: pctile = pctile2(x,p);
%
%See also: PCTILE1

%Copyright (c) Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

if nargin<1; x = 'io'; end
if isa(x,'char');
  options = [];
  if nargout==0; clear pctile; evriio(mfilename,x,options); else; pctile = evriio(mfilename,x,options); end
  return;
end

if size(x,1)==1 & ndims(x)==2; x = x'; end

sx = sort(x) ;
n = size(sx,1) ;
i = (n*p/100)+0.5 ;
h = mod(i,1) ;
i0 = floor(i);
i1 = min(max(i0,1),n) ;
i2 = min(max(i0+1,1),n) ;
pctile = diag(1-h)*sx(i1,:) + diag(h)*sx(i2,:) ;

if ndims(x)>2
  %reshape to n-way if needed
  sz = size(x);
  pctile = reshape(pctile,[size(pctile,1) sz(2:end)]);
end
