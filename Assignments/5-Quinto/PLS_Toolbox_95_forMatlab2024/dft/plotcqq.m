function vals = plotcqq(x,distname,translate)
%PLOTCQQ Conditional quantile plot.
%  Plots a conditional QQplot of a sample in vector (x).
%  The optional input (distname) specifies the distribution:
%    'beta'
%    'cauchy'
%    'chi squared'
%    'exponential'
%    'gamma'
%    'gumbel'
%    'laplace'
%    'logistic'
%    'lognormal'
%    'normal'     {default}
%    'pareto'
%    'rayleigh'
%    'triangle'
%    'uniform'
%    'weibull'
%
% Output (structure):
%     q - quantiles of the named distribution.
%     u - values at which the quantiles were evaluated.
%     
%Examples:
%        vals = plotcqq(x)
%        vals = plotcqq(x,'normal')
%        vals = plotcqq(x,'beta')
%
%I/O: vals = plotcqq(x,distname,translate);
%
%See also: PLOTEDF, PLOTKD, PLOTQQ, PLOTSYM

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
  if nargout==0; clear vals; evriio(mfilename,x,options); else; vals = evriio(mfilename,x,options); end
  return; 
end

nargchk(1,3,nargin) ;
if nargin < 3
  translate = 0 ;
end
if nargin < 2
  distname = 'normal' ;
end

if ~isreal(x), error('X must be real.') ; end
name = getname(distname) ;
if strcmp(name,'unknown')
  error(cat(2,'unknown or unsupported distribution: ', distname)) ;
end
%estring = cat(2,'cq',name,'(p,sortx)') ;

nam = inputname(1) ;
if ~isempty(nam)
  tle = cat(2,'Conditional quantile-quantile plot of ', nam) ;
  vlabel = cat(2,'Order statistics of ',nam) ;
else
  tle = 'Conditional quantile-quantile plot' ;
  vlabel = 'Order statistics' ;
end

sortx  = sort(x(:)) ;
n      = length(sortx) ;
mu     = pctile1(sortx,50) ;
uhinge = pctile1(sortx,75) ;
lhinge = pctile1(sortx,25) ;
sigma  = .75.*(uhinge - lhinge) ;

p  = (sortx - mu) ./ sigma ;
mywarn = warning; warning off; 
%fy = eval(estring) ;
fy = distsub(name,p,sortx); %Call distribution sub function.

warning(mywarn);

plot(fy.pvals+translate,sortx+translate,'o-') ;
ylabel(vlabel) ;
xlabel(fy.dlabel) ;
title(tle) ;
vals = struct('q',fy.pvals'+translate,'u',p) ;

% ---------------------------------
% Subroutines for the distributions
% ---------------------------------
function result = distsub(dist,p,x)

switch dist

  case 'beta'
    n      = length(x) ;
    params = parammle(x,'beta') ;
    range  = max(p) - min(p) ;
    options.offset = min(p) - .005*range ;
    options.scale  = range + .01*range ;
    pnew   = [0 betadf('cdf',p,params.a,params.b,options)' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = betadf('quantile',pnew,params.a,params.b,options) ;
    dlabel = 'Quantiles of Standardized Beta' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'cauc'
    n      = length(x) ;
    params = parammle(x,'cauchy') ;
    pnew   = [0 cauchydf('cdf',p,params.a,params.b)' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = cauchydf('quantile',pnew,params.a,params.b) ;
    dlabel = 'Quantiles of Standardized Cauchy' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'chi2'
    n      = length(x) ;
    params = parammle(x,'chi2') ;
    pnew   = [0 chidf('cdf',p,params.a,min(p))' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = chidf('quantile',pnew,params.a) ;
    dlabel = 'Quantiles of Standardized Chi-squared' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'expo'
    n      = length(x) ;
    params = parammle(x,'exponential') ;
    pnew   = [0 expdf('cdf',p,params.a,min(p))' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = expdf('quantile',pnew,params.a) ;
    dlabel = 'Quantiles of Standardized Exponential' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'gamm'
    n      = length(x) ;
    params = parammle(x,'gamma') ;
    pnew   = [0 gammadf('cdf',p,params.a,params.b)' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = gammadf('quantile',pnew,params.a,params.b) ;
    dlabel = 'Quantiles of Standardized Gamma' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'gumb'
    n      = length(x) ;
    params = parammle(x,'gumbel') ;
    pnew   = [0 gumbeldf('cdf',p,params.a,params.b)' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = gumbeldf('quantile',pnew,params.a,params.b) ;
    dlabel = 'Quantiles of Standardized Gumbel' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'lapl'
    n      = length(x) ;
    params = parammle(x,'laplace') ;
    pnew   = [0 laplacedf('cdf',p,params.a,params.b)' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = laplacedf('quantile',pnew,params.a,params.b) ;
    dlabel = 'Quantiles of Standardized Laplace' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'logi'
    n      = length(x) ;
    params = parammle(x,'logistic') ;
    pnew   = [0 logisdf('cdf',p,params.a,params.b)' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = logisdf('quantile',pnew,params.a,params.b) ;
    dlabel = 'Quantiles of Standardized Logistic' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'logn'
    n      = length(x) ;
    params = parammle(p,'lognormal') ;
    pnew   = [0 lognormdf('cdf',p,params.a,params.b)' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = lognormdf('quantile',pnew,params.a,params.b) ;
    dlabel = 'Quantiles of Standardized Lognormal' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'norm'
    n      = length(x) ;
    params = parammle(x,'normal') ;
    pnew   = [0 normdf('cdf',p,params.a,params.b)' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = normdf('quantile',pnew,params.a,params.b)' ;
    dlabel = 'Quantiles of Standardized Normal' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'pare'
    n      = length(x) ;
    params = parammle(x,'pareto') ;
    pnew   = [0 paretodf('cdf',p-min(p)+params.a,params.a,params.b)' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = paretodf('quantile',pnew,params.a,params.b) ;
    dlabel = 'Quantiles of Standardized Pareto' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'rayl'
    n      = length(x) ;
    params = parammle(x,'rayleigh') ;
    pnew   = [0 raydf('cdf',p-min(p)+.001,params.a)' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = raydf('quantile',pnew,params.a) ;
    dlabel = 'Quantiles of Standardized Rayleigh' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'tria'
    n      = length(x) ;
    params = parammle(x,'triangle') ;
    pnew   = [0 triangledf('cdf',(p-min(p))/(max(p)-min(p))*(params.b-params.a)+...
      params.a,params.a,params.b,params.c)' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = triangledf('quantile',pnew,params.a,params.b,params.c) ;
    dlabel = 'Quantiles of Triangle' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'unif'
    n      = length(x) ;
    params = parammle(x,'uniform') ;
    pnew   = [0 unifdf('cdf',(p-min(p))/(max(p)-min(p))*(params.b-params.a)+...
      params.a,params.a,params.b)' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = unifdf('quantile',pnew,params.a,params.b) ;
    dlabel = 'Quantiles of Standardized Uniform' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  case 'weib'
    n      = length(x) ;
    params = parammle(x,'weibull') ;
    pnew   = [0 weibulldf('cdf',p,params.a,params.b,min(p))' 1] ;
    pnew   = 0.5 .* (pnew(1:n) + pnew(3:n+2)) ;
    pvals  = weibulldf('quantile',pnew,params.a,params.b) ;
    dlabel = 'Quantiles of Standardized Weibull' ;
    result = struct('pvals',pvals,'dlabel',dlabel) ;

  otherwise
    error('Unknown or unsupported distribution.');

end
