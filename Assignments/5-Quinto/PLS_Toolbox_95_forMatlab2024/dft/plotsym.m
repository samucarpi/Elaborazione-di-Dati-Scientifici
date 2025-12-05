function plotsym(x)
%PLOTSYM Symmetry plot.
%  Makes the symmetry plot of the input(x). Plotted:
%  p'dist' of centered and scaled x(i) versus i/(N+1).
%
%I/O: plotsym(x)
%
%See also: PLOTCQQ, PLOTEDF, PLOTEDF, PLOTQQ

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

nargchk(1,1,nargin) ;

nam = inputname(1) ;
if ~isempty(nam)
	tle = cat(2,'Symmetry plot of ',nam) ;
else
	tle = 'Symmetry plot' ;
end
if ~isreal(x), error('X must be real.') ; end
sx  = sort(x(:)) ;
dx  = -sort(-x(:)) ;
med = median(sx) ;
n   = length(sx) ;
xx  = med - sx ;
yy  = dx - med ;
plot(xx,yy,'o-') ;
xlabel('Distance below median') ;
ylabel('Distance above median') ;
title(tle) ;

