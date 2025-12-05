function vals = kstest(x,distname)
%KSTEST Kolmogorov-Smirnov goodness-of-fit distribution test.
%  The inputs are a vector of observations (x) and the
%  name of a distribution (distname):
%    'beta'
%    'cauchy'
%    'chi squared'
%    'exponential'
%    'gamma'
%    'gumbel'
%    'laplace'
%    'logistic'
%    'lognormal'
%    'normal'
%    'pareto'
%    'rayleigh'
%    'triangle'
%    'uniform'
%    'weibull'
%  The output consists of: Kolmogorov-Smirnov test of distribution fit.
%
%Examples:
%     vals = kstest(x,'normal');
%     vals = kstest(x,'beta');
%
%I/O: vals = kstest(x,distname);
%
%See Also: CHITEST, DISTFIT

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
  if nargout==0; 
    clear vals; 
    evriio(mfilename,x,options); 
  else; 
    vals = evriio(mfilename,x,options); end
  return; 
end

nargchk(1,2,nargin) ;
if nargin < 2
  distname = 'normal' ;
  disp 'assume test versus normal distribution' ;
end

if ~isreal(x), error('X must be real.') ; end
name = getname(distname) ;
if strcmp(name,'unknown')
  error(cat(2,'unknown or unsupported distribution: ', distname)) ;
end
%estring = cat(2,'ks',name,'(sortx)') ;

sortx  = sort(x(:)) ;
n      = length(sortx) ;
Fn     = linspace(1,n,n)./n ;

mywarn = warning; warning off;
%result = eval(estring) ;
result = ktestsub(name,sortx); %Call distribution sub function.
Fhat   = (result.pvals) ;
warning(mywarn);

% More conservative df: just use #cells - 1
Dn     = max(abs(Fn'-Fhat)) ;
df     = n - 1 - result.df ;
df     = n - 1 ;

ks = FofDn(Dn,name,n) ;

if isinf(Dn)
  Dn = NaN ;
  ks = NaN ;
  pval = 0 ;
  df = 0 ;
else
  pval = 0 ;
  Dn2  = Dn.*Dn ;
  for i = 1:6
    pval = pval + (-1).^(i-1).*exp(-2*i*i*Dn2) ;
  end
  pval = 1 - 2*pval ;
end

vals   = struct('ks',ks,'Dn',Dn,...
  'parameters',result.params) ;


% ---------------------------------
% Subroutines for the distributions
% ---------------------------------

function result = FofDn(dn,name,n)
%
% For now, just use the usual statistic without the
% special case adjustments.
%
if 1
  result = dn .* sqrt(n) ;
elseif strcmp(name,'norm')
  result = dn.*(sqrt(n)-0.01+0.85./sqrt(n)) ;
elseif strcmp(name,'expo')
  result = (dn-0.2/sqrt(n)) .* (sqrt(n) + 0.26 + 0.5./sqrt(n)) ;
elseif strcmp(name,'weib')
  result = sqrt(n).*dn ;
else
  result = (sqrt(n) + 0.12 + 0.11/sqrt(n)) .* dn ;
end

function result = ktestsub(name,x)

switch name
  case 'beta'
    params = parammle(x,'beta') ;
    options.scale = params.c;
    options.offset = params.d;
    pvals  = betadf('cdf',x,params.a,params.b,options) ;
    df     = 2 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'cauc'
    params = parammle(x,'cauchy') ;
    pvals  = cauchydf('cdf',x,params.a,params.b) ;
    df     = 2 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'chi2'
    params = parammle(x,'chi2') ;
    pvals  = chidf('cdf',x,params.a) ;
    df = 1 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'expo'
    params = parammle(x,'exponential') ;
    pvals  = expdf('cdf',x,params.a) ;
    df = 1 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'gamm'
    params = parammle(x,'gamma') ;
    pvals  = gammadf('cdf',x,params.a,params.b) ;
    df = 2 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'gumb'
    params = parammle(x,'gumbel') ;
    pvals  = gumbeldf('cdf',x,params.a,params.b) ;
    df     = 2 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'lapl'
    params = parammle(x,'laplace') ;
    pvals  = laplacedf('cdf',x,params.a,params.b) ;
    df = 2 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'logi'
    params = parammle(x,'logistic') ;
    pvals  = logisdf('cdf',x,params.a,params.b) ;
    df = 2 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'logn'
    params = parammle(x,'lognormal') ;
    pvals  = lognormdf('cdf',x,params.a,params.b) ;
    df = 2 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'norm'
    params = parammle(x,'normal') ;
    pvals = normdf('cdf',x,params.a,params.b) ;
    df = 2 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'pare'
    params = parammle(x,'pareto') ;
    pvals  = paretodf('cdf',x,params.a,params.b) ;
    df = 1 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'rayl'
    params = parammle(x,'rayleigh') ;
    pvals  = raydf('cdf',x,params.a) ;
    df = 2 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'tria'
    params = parammle(x,'tria') ;
    pvals  = triangledf('cdf',x,params.a,params.b,params.c) ;
    df     = 3 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'unif'
    params = parammle(x,'uniform') ;
    pvals  = unifdf('cdf',x,params.a,params.b) ;
    df     = 2 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;

  case 'weib'
    params = parammle(x,'weibull') ;
    pvals  = weibulldf('cdf',x,params.a,params.b) ;
    df = 3 ;
    result = struct('pvals',pvals,'df',df,'params',params) ;
  otherwise
    error('Unknown or unsupported distribution.');
end
