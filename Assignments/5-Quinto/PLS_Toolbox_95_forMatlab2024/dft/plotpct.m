function plotpct(x)
%PLOTPCT Percentile plot.
%  Makes the percentile plot of the input (x). Plotted:
%  percentiles of centered and scaled x(i) versus i/(N+1)
%
%I/O: plotpct(x)
%
%See also: PLOTCQQ, PLOTEDF, PLOTKD, PLOTQQ, PLOTSYM

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

if nargin<1; x = 'io'; end
if isa(x,'char');
  options = [];
  if nargout==0; evriio(mfilename,x,options); else; out = evriio(mfilename,x,options); end
  return; 
end

if ~isreal(x), error('X must be real.') ; end

nam = inputname(1) ;
if ~isempty(nam)
	tle = cat(2,'Percentile plot of ',nam) ;
	yla = cat(2,'Values of ',nam) ;
else
	tle = 'Percentile plot' ;
	yla = ' ';
end
sx = sort(x(:)) ;
sx = (sx-mean(sx))./std(sx) ;
n  = length(sx) ;
aa = linspace(1,n,n) ./ (n+1)  ;
plot(aa,sx,'o-') ;
xlabel('Percentiles') ;
ylabel(yla) ;
title(tle) ;
