function plotkd(x,distname,kernel,userw,translate)
%PLOTKD Kernel density plot with overlay.
%  PLOTKD provides the kernel density plot of the input (x)
%  (with overlay). Optional inputs include (distname):
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
%  Others optional inputs include (kernel) a scalar defining the kernel
%    1  = biweight
%    2  = cosine
%    3  = epanechnikov {default}
%    4  = gaussian
%    5  = parzen
%    6  = rectangular
%    7  = triangle
%  (width) allows the user to specify the window width {see reference
%  manual of info on default}, and (translate) which translates the
%  x-axis {default = 0}.
%
%Examples:
%    plotkd(x)
%    plotkd(x,'normal')
%
%I/O: plotkd(x,distname,kernel,width,translate)
%
%See also: PLOTCQQ, PLOTEDF, PLOTQQ

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

nargchk(2,4,nargin) ;
if ~isreal(x), error('X must be real.') ; end

nam = inputname(1) ;
if ~isempty(nam)
  tle = cat(2,'Kernel density plot of ',nam) ;
  yla = cat(2,'Values of ',nam) ;
else
  tle = 'Kernel density plot' ;
  yla = ' ';
end

if nargin < 3
  kernel = 3 ;
elseif isempty(kernel)
  kernel = 3;
end

if nargin < 4
  k = kdensity(x,kernel) ;
elseif isempty(userw);
  k = kdensity(x,kernel);
else
  k = kdensity(x,kernel,userw) ;
end

if nargin < 5   %added 5/26/00 nbg
  translate = 0;
end

if nargin == 1
  plot(k.x,k.fx,'o-')
else
  name = getname(distname) ;
  if ~strcmp(name,'unknown')
    %estring = cat(2,'kd',name,'(x,k.x)') ;
    %ox      = real(eval(estring)) ;
    ox = real(distsub(name,x,k.x));
    plot(k.x+translate,k.fx,'o-',k.x+translate,ox,'x-') ;
    maxy = max(k.fx) ;
    maxf = max(ox) ;
    my   = max(maxy,min(2*maxy,maxf)) ;
    axis([min(k.x+translate) max(k.x+translate) 0 my]) ;
  else
    plot(k.x+translate,k.fx,'o-') ;
  end
end
ylabel(yla) ;
title(tle) ;

% ---------------------------------
% Subroutines for the distributions
% ---------------------------------

function [cx,cy] = collapse(x,y,n)
minx  = min(x) ;
maxx  = max(x) ;
range = maxx - minx ;
step  = range / n ;
xx    = minx - step / 2 ;
cx    = zeros(n,1) ;
cy    = zeros(n,1) ;
for i=1:n
  cx(i) = xx + step ;
  cy(i) = mean(y(find(x>cx(i)-step/2 & x <= cx(i)+step/2))) ;
  xx    = xx + step ;
end

function result = distsub(dist,ax,x)

switch dist

  case 'beta'
    options.offset     = min(x) - .005 ;
    options.scale   = (max(x) - min(x)) + .01 ;
    params  = parammle(ax,'beta') ;
    result  = betadf('pdf',x,params.a,params.b,options) ;

  case 'cauc'
    params  = parammle(ax,'Cauchy') ;
    result  = cauchydf('pdf',x,params.a,params.b) ;

  case 'chi2'
    if min(x) < 0
      cc = min(x) - .0001 ;
    else
      cc = 0 ;
    end
    params  = parammle(ax,'chi2') ;
    params.b = cc ;
    vals    = find(x>=params.b) ;
    result(vals)  = chidf('pdf',x(vals),params.a) ;
    result(~vals) = 0 ;

  case 'expo'
    if min(x) < 0
      cc = min(x) - .0001 ;
    else
      cc = 0 ;
    end
    params = parammle(ax,'exponential') ;
    params.b = cc ;
    vals   = find(x>=params.b) ;
    result(vals)  = expdf('pdf',x(vals),params.a) ;
    result(~vals) = 0 ;

  case 'gamm'
    params  = parammle(ax,'gamma') ;
    result  = gammadf('pdf',x,params.a,params.b) ;

  case 'gumb'
    params  = parammle(ax,'gumbel') ;
    result  = gumbeldf('pdf',x,params.a,params.b) ;

  case 'lapl'
    params  = parammle(ax,'laplace') ;
    result  = laplacedf('pdf',x,params.a,params.b) ;

  case 'logi'
    if min(x) < 0
      cc = min(x) - .0001 ;
    else
      cc = 0 ;
    end
    params  = parammle(ax,'logistic') ;
    params.c = cc ;
    result  = logisdf('pdf',x,params.a,params.b) ;

  case 'logn'
    if min(x) < 0
      cc = min(x) - .0001 ;
    else
      cc = 0 ;
    end
    params  = parammle(ax,'lognormal') ;
    params.c = cc ;
    result  = lognormdf('pdf',x,params.a,params.b) ;

  case 'norm'
    params  = parammle(ax,'normal') ;
    result  = normdf('pdf',x,params.a,params.b) ;

  case 'pare'
    if min(x) < 0
      cc = min(x) - .0001 ;
    else
      cc = 0 ;
    end
    params  = parammle(ax,'pareto') ;
    result  = paretodf('pdf',x,params.a,params.b) ;

  case 'rayl'
    params  = parammle(ax,'rayleigh') ;
    result  = raydf('pdf',x,params.a) ;

  case 'tria'
    params  = parammle(ax,'triangle') ;
    result  = triangledf('pdf',x,params.a,params.b,params.c) ;

  case 'unif'
    params  = parammle(x,'uniform') ;
    result  = unifdf('pdf',x,params.a,params.b) ;

  case 'weib'
    if min(x) < 0
      cc = min(x) - .0001 ;
    else
      cc = 0 ;
    end
    params  = parammle(ax,'weibull') ;
    params.c = cc ;
    result  = weibulldf('pdf',x,params.a,params.b) ;

  otherwise
    error('Unknown or unsupported distribution.');

end
