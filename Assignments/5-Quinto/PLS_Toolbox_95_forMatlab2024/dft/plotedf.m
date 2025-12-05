function plotedf(x)
%PLOTEDF Empirical distribution plot.
%  PLOTEDF(X) is the empirical distribution function
%  plot of the input (x).
%
%I/O: plotedf(x)
%
%See also: PLOTCQQ, PLOTPCT, PLOTQQ, PLOTKD

%Copyright (c) Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

if nargin<1; x = 'io'; end
if isa(x,'char');
  options = [];
  if nargout==0; evriio(mfilename,x,options); else; out = evriio(mfilename,x,options); end
  return; 
end

nargchk(1,1,nargin) ;
nam = inputname(1) ;
if ~isempty(nam)
	tle = cat(2,'Empirical CDF of ',nam) ;
	xla = cat(2,'Values of ',nam) ;
else
	tle = 'Empirical CDF' ;
	xla = ' ' ;
end

if ~isreal(x), error('X must be real.') ; end

sx  = sort(x(:)) ;
n   = length(sx(:)) ;
csx = linspace(1,n,n) ./ n ;
stairs(sx,csx,'-') ;
xlabel(xla) ;
ylabel('Empirical Distribution') ;
title(tle) ;
