function vals = chitest(x,distname,classes)
%CHITEST Chi-squared goodness-of-fit distribution test.
%  The input (x) is a vector data sample.
%  Optional inputs are (distname) the name of a specific distribution:
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
%  and (classes) the number of equally spaced probability intervals
%  for counts to be collected for the test.
%  The output (vals) is a structure array with the following fields
%    distname   = distribution name for the given fit,
%    function   = function used to evaluate this distribution,
%    chi2       = value of chi-squared test statistic,
%    pval       = p-value associated witht the test statistic,
%    df         = degrees of freedom,
%    classes    = number of intervals for obtaining counts,
%    parameters = maximum likelihood estimates,
%    E          = expected counts for classes, and
%    O          = observed counts for classes.
%
%I/O: vals = chitest(x,distname,classes);
%
%Example: vals = chitest(x);
%         vals = chitest(x,'normal');
%         vals = chitest(x,'normal',20);
%
%See Also: DISTFIT, KSTEST, PLOTCQQ, PLOTKD, PLOTQQ

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
  classes = floor((max(x)-min(x))/(3.5*sqrt(sqrvar(x)))*length(x)^(1/3))+1 ;
end
if nargin < 2
  distname = 'normal' ;
  disp 'assume test versus normal distribution' ;
end

if ~isreal(x), error('X must be real.') ; end
if classes < 3, error('CLASSES must be greater than 2') ; end
if classes > length(x), error('CLASSES must be smaller than len(X)') ; end
name = getname(distname) ;
if strcmp(name,'unknown')
  error(cat(2,'unknown or unsupported distribution: ', distname)) ;
end
%estring = cat(2,'ch',name,'(p,sortx)') ;

sortx  = sort(x(:)) ;
n      = length(sortx) ;
p      = linspace(min(x),max(x),classes+1) ;

observ = zeros(classes,1) ;
for i=1:classes
  observ(i) = sum(sortx >= p(i) & sortx < p(i+1)) ;
end
observ(classes) = observ(classes) + sum(sortx==p(classes+1)) ;

mywarn = warning; warning off;
%result = eval(estring) ;
result = distsub(name,p,sortx); %Call distribution sub function.
expect = (result.pvals) ;

% Get real differences (ignore zero counts)
vv = find(expect>0) ;
observ = observ(vv) ;
expect = expect(vv) ;

begin  = (observ-expect).^2 ./ expect ;
chisq  = sum(begin(find(expect~=0 & ~isnan(expect)))) ;

% More conservative df: just use #cells - 1
% df     = classes - 1 - result.df ;
df     = sum(expect~=0 & ~isnan(expect)) - 1 ;
pval   = 1-chidf('cdf',chisq,df) ;

if df <= 0
  chisq = NaN ;
  pval  = 0 ;
  df = 0 ;
end

vals   = struct('distname',distname,'function',result.distfn,'chi2',chisq,'pval',pval,'df',df,'classes',classes,...
  'parameters',result.params,'E',expect','O',observ') ;

warning(mywarn);

% ---------------------------------
% Subroutines for the distributions
% ---------------------------------
function result = distsub(dist,p,x)

switch dist
  
  case 'beta'
    params = parammle(x,'beta') ;
    pvals  = zeros(length(p)-1,1) ;
    options.scale = params.c;
    options.offset = params.d;
    for i = 1:length(p)-1
      pvals(i) = (						    ...
        betadf('cdf',p(i+1),params.a,params.b,options) - ...
        betadf('cdf',p(i),params.a,params.b,options)	    ...
        ) * length(x) ;
    end
    
    df = 1 ;
    result = struct('distfn','betadf','pvals',pvals,'df',df,'params',params) ;


  case 'cauc'
    params = parammle(x,'cauchy') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (					...
        cauchydf('cdf',p(i+1),params.a,params.b) -	...
        cauchydf('cdf',p(i),params.a,params.b)		...
        ) * length(x) ;
    end
    
    df = 1 ;
    result = struct('distfn','cauchydf','pvals',pvals,'df',df,'params',params) ;


  case 'chi2'
    params = parammle(x,'chi2') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (					...
        chidf('cdf',p(i+1),params.a) -	...
        chidf('cdf',p(i),params.a)		...
        ) * length(x) ;
    end
    
    df = 1 ;
    result = struct('distfn','chidf','pvals',pvals,'df',df,'params',params) ;


  case 'expo'
    params = parammle(x,'exponential') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (					...
        expdf('cdf',p(i+1),params.a) -	...
        expdf('cdf',p(i),params.a)		...
        ) * length(x) ;
    end

    df = 1 ;
    result = struct('distfn','expdf','pvals',pvals,'df',df,'params',params) ;


  case 'gamm'
    params = parammle(x,'gamma') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (						...
        gammadf('cdf',p(i+1),params.a,params.b) -	...
        gammadf('cdf',p(i),params.a,params.b)		...
        ) * length(x) ;
    end
    
    df = 2 ;
    result = struct('distfn','gammadf','pvals',pvals,'df',df,'params',params) ;


  case 'gumb'
    params = parammle(x,'gumbel') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (					...
        gumbeldf('cdf',p(i+1),params.a,params.b) -	...
        gumbeldf('cdf',p(i),params.a,params.b)		...
        ) * length(x) ;
    end
    
    df = 2 ;
    result = struct('distfn','gumbeldf','pvals',pvals,'df',df,'params',params) ;


  case 'lapl'
    params = parammle(x,'laplace') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (					...
        laplacedf('cdf',p(i+1),params.a,params.b) -	...
        laplacedf('cdf',p(i),params.a,params.b)	...
        ) * length(x) ;
    end
    
    df = 2 ;
    result = struct('distfn','laplacedf','pvals',pvals,'df',df,'params',params) ;


  case 'logi'
    params = parammle(x,'logistic') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (						...
        logisdf('cdf',p(i+1),params.a,params.b) -	...
        logisdf('cdf',p(i),params.a,params.b)		...
        ) * length(x) ;
    end
    
    df = 2 ;
    result = struct('distfn','logisdf','pvals',pvals,'df',df,'params',params) ;


  case 'logn'
    params = parammle(x,'lognormal') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (						...
        lognormdf('cdf',p(i+1),params.a,params.b) -	...
        lognormdf('cdf',p(i),params.a,params.b)		...
        ) * length(x) ;
    end

    df = 2 ;
    result = struct('distfn','lognormdf','pvals',pvals,'df',df,'params',params) ;


  case 'norm'
    params = parammle(x,'normal') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (					...
        normdf('cdf',p(i+1),params.a,params.b) -	...
        normdf('cdf',p(i),params.a,params.b)		...
        ) * length(x) ;
    end

    df = 2 ;
    result = struct('distfn','normdf','pvals',pvals,'df',df,'params',params) ;


  case 'pare'
    params = parammle(x,'pareto') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (						...
        paretodf('cdf',p(i+1),params.a,params.b) -	...
        paretodf('cdf',p(i),params.a,params.b)	...
        ) * length(x) ;
    end

    df = 1 ;
    result = struct('distfn','paretodf','pvals',pvals,'df',df,'params',params) ;


  case 'rayl'
    params = parammle(x,'ray') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (			...
        raydf('cdf',p(i+1),params.a) -	...
        raydf('cdf',p(i),params.a)	...
        ) * length(x) ;
    end
    df = 2 ;
    result = struct('distfn','raydf','pvals',pvals,'df',df,'params',params) ;


  case 'tria'
    params = parammle(x,'triangle') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (						...
        triangledf('cdf',p(i+1),params.a,params.b,params.c) -	...
        triangledf('cdf',p(i),params.a,params.b,params.c)		...
        ) * length(x) ;
    end
    df = 3 ;
    result = struct('distfn','triangledf','pvals',pvals,'df',df,'params',params) ;


  case 'unif'
    params = parammle(x,'uniform') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (					...
        unifdf('cdf',p(i+1),params.a,params.b) -	...
        unifdf('cdf',p(i),params.a,params.b)		...
        ) * length(x) ;
    end
    df = 2 ;
    result = struct('distfn','unifdf','pvals',pvals,'df',df,'params',params) ;


  case 'weib'
    params = parammle(x,'weibull') ;
    pvals  = zeros(length(p)-1,1) ;
    for i = 1:length(p)-1
      pvals(i) = (						...
        weibulldf('cdf',p(i+1),params.a,params.b) -	...
        weibulldf('cdf',p(i),params.a,params.b)	...
        ) * length(x) ;
    end
    df = 3 ;
    result = struct('distfn','weibulldf','pvals',pvals,'df',df,'params',params) ;
    
  otherwise
    error('Unknown or unsupported distribution.');

end
