function mns = means(x)
%MEANS Arithmethic, geometric, and harmonic means.
%  The input is a vector (x) and the output (mns) is a structure
%  array with the following fields:
%    amean  - arithmetic mean
%    na     - number of obs used in amean calculations.
%    hmean  - harmonic mean.
%    nh     - numver of obs used in hmean calculation.
%    gmean  - gemetric mean.
%    ng     - number of obs used in gmean calculation. 
%
%I/O: mns = means(x);
%
%See also: SUMMARY

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
  if nargout==0; clear mns; evriio(mfilename,x,options); else; mns = evriio(mfilename,x,options); end
  return; 
end

k = find(~isinf(x) & ~isnan(x)) ;
if ~isvec(x(k)),  error('X must be a vector.') ; end
if ~isreal(x(k)), error('X must be real.') ;     end

xa = x(k) ;
na = length(xa) ;
xh = xa(find(xa~=0)) ;
nh = length(xh) ;
xg = xa(find(xa>0)) ;
ng = length(xg) ;

amn = mean(xa) ; 
hmn = nh ./ sum(1./xh) ;
gmn = exp(mean(real(log(xg)))) ;
mns = struct('amean',amn,...
		'na', na, ...
		'hmean',hmn,...
		'nh', nh, ...
		'gmean', gmn, ...
		'ng', ng) ;
