function params = parammle(x,distname)
%PARAMMLE  Maximum likelihood parameter estimates for DF_Toolbox.
%  Inuts are (x) the vector containing a data sample, and (distname)
%  a string variable containing the distribution name:
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
%  The output (params) is the maximum likelihood parameter estimates.
%
%I/O: params = parammle(x,distname);
%
%See also: CHITEST KSTEST

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
  if nargout==0; clear params; evriio(mfilename,x,options); else; params = evriio(mfilename,x,options); end
  return; 
end

nargchk(2,2,nargin) ;

if ~isreal(x), error('X must be real.') ;   end
if ~isvec(x),  error('X must be vector.') ; end

name = getname(distname) ;
if strcmp(name,'unknown')
  error(cat(2,'unknown or unsupported distribution: ',distname)) ;
end
estring = cat(2,'m',name,'(x)') ;

params = distsub(name,x) ;


% ---------------------------------
% Subroutines for each distribution
% ---------------------------------
function params = distsub(name,x)

mywarn = warning; warning off;

switch name
  case 'beta'
    if min(x) > 0 & max(x) < 1
      scale = 1 ;
      offset = 0 ;
    else
      range = max(x) - min(x) ;
      scale  = range + .01*range ;
      offset = min(x) - .005*range ;
    end
    x = (x - offset) ./ scale ;
    n = length(x) ;
    t1 = prod((1-x) .^ (1./n)) ;
    t2 = prod(x .^ (1./n)) ;
    t3 = 2 .* (1 - t1 - t2) ;
    a  = (1-t1) ./ t3 ;
    b  = (1-t2) ./ t3 ;
    myopts = [] ;
    [ph,opts] = fminsearch('lbeta',[a b],myopts,x) ;
    a  = ph(1) ;
    b  = ph(2) ;
    c  = scale ;
	  d  = offset ;
    params = struct('a',a,'b',b,'c',c,'d',d)  ;

  case 'cauc'
    a = pctile1(x,50) ;
    b = sqrt(sqrvar(x)) ;
    myopts = [] ;
    [phat,opts] = fminsearch('lcauchy',[a b],myopts,x) ;
    params = struct('a',phat(1),'b',phat(2)) ;

  case 'chi2'
    x = x(find(x>0)) ;
    if length(x) == 0
      a = NaN ;
    else
      a = mean(x) ;
    end
    params = struct('a',a) ;

  case 'expo'
    x = x(find(x>0)) ;
    if length(x) == 0
      a = NaN ;
    else
      a = mean(x) ;
    end
    params = struct('a',a) ;

  case 'gamm'
    x = x(find(x > 0)) ;
    if length(x) == 0
      a = NaN ;
      b = NaN ;
    else
      b = sqrvar(x) ./ mean(x) ;
      a = mean(x) ./ b ;
      myopts = [] ;
      [phat,opts] = fminsearch('lgamma',[a b],myopts,x) ;
      a = phat(1) ;
      b = phat(2) ;
    end
    params = struct('a',a,'b',b) ;

  case 'gumb'
    b = sqrt(sqrvar(x) .* 6 ./ pi^2) ;
    a = mean(x) - b*.57721 ;
    myopts = [] ;
    [phat,opts] = fminsearch('lgumbel',[a b],myopts,x) ;
    params = struct('a',phat(1),'b',phat(2)) ;

  case 'lapl'
    a = mean(x) ;
    b = std(x) / sqrt(2) ;
    params = struct('a',a,'b',b) ;

  case 'logi'
    a = mean(x) ;
    b = sqrt(3)*std(x)./pi ;
    myopts = [] ;
    [phat,opts] = fminsearch('lldis',[a b],myopts,x) ;
    params = struct('a',phat(1),'b',phat(2)) ;

  case 'logn'
    x = x(find(x>0)) ;
    n = length(x) ;
    if n == 0
      a = NaN ;
      b = NaN ;
    else
      a = mean(real(log(x))) ;
      b = sqrt(sum((real(log(x))-a).^2)./(n-1)) ;
    end
    params = struct('a',a,'b',b) ;

  case 'norm'
    a = mean(x) ;
    b = std(x) ;
    params = struct('a',a,'b',b) ;

  case 'pare'
    if length(x) == 0
      a = NaN ;
      b = NaN ;
    else
      a = min(x) ;
      b = 1./mean(real(log(x./a))) ;
    end
    params = struct('a',a,'b',b) ;

  case 'rayl'
    x = x(find(x>0)) ;
    if length(x) == 0
      a = NaN ;
    else
      a = sqrt(sum((x).*(x))./(2*length(x))) ;
    end
    params = struct('a',a) ;

  case 'stu'
    a = 10 ;
    b = mean(x) ;
    myopts = [] ;
    [phat,opts] = fminsearch('ltdis',[a b],myopts,x) ;
    params = struct('a',min(1000,phat(1)),'b',phat(2)) ;

  case 'tria'
    a = min(x) ;
    b = max(x) ;
    c = 3*mean(x) - (a+b) ;
    c = min(max(pctile2(x,10),c),pctile2(x,90)) ;
    myopts = [] ;
    [phat,opts] = fminsearch('ltrdis',[a b c],myopts,x) ;
    params = struct('a',phat(1),'b',phat(2),'c',phat(3)) ;

  case 'unif'
    a = min(x) ;
    b = max(x) ;
    params = struct('a',a,'b',b) ;

  case 'weib'
    x = x(find(x>0)) ;
    n = length(x) ;
    if n == 0
      a = NaN ;
      b = NaN ;
    else
      e = [.5./n : (1./n) : (n-.5)./n]' ;
      w = real(log(log(1./(1-e)))) ;
      z = sort(real(log(x))) ;
      t = polyfit(z,w,1) ;
      a = exp(t(2)/t(1)) ;
      b = t(1) ;
      a = a.^(-b) ;
      if ~isnan(a) & ~isnan(b)
        myopts = [] ;
        [phat,opts] = fminsearch('lweibull',[a b 0],myopts,x) ;
        a = phat(1) ;
        b = phat(2) ;
      else
        a = NaN ;
        b = NaN ;
      end
    end
    params = struct('a',a,'b',b) ;
  otherwise
    warning(mywarn);
    error('Unknown or unsupported distribution.');
end
warning(mywarn);

