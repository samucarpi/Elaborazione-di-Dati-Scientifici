function pctile = pctile1(x,p)
%PCTILE1 Returns the Pth percentile of a matrix or vector.
%  Inputs are the data matrix or vector (x) and (p) one or more percentiles
%  to calculate (0<p<100). The percentile is found by locating the value
%  closest to the percentile to calculate. This algorithm does not do any
%  interpolation between values except when the percentile falls exactly on
%  a value.
%  The output (pctile) is the percentile. If p is a vector, the output
%  contains one row for each input percentiles requested.
%
%I/O: pctile = pctile1(x,p);       
%
%See also: PCTILE2

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

if size(x,1)==1; x = x'; end

sx     = sort(x) ;
n      = size(x,1);
newp   = (n*p/100) ;
ip1    = floor(newp)+1 ;
ip1    = min(max(ip1, 1),n);
pctile = sx(ip1,:) ;

if ndims(x)>2
  %reshape to n-way if needed
  sz = size(x);
  pctile = reshape(pctile,[size(pctile,1) sz(2:end)]);
end
