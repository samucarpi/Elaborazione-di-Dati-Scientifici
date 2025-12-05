function out = tdf(method,x,a,options)
%TDF Student's t-distribution function.
%  INPUTS:
%     method = string defining type of request (see below).
%         x = depends on call (see below).
%         a = degrees of freedom. (real and positive).
%
%         NOTE: Under certain conditions inputs will be resized by RESIZE
%         function. For more information type "resize help".
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields used:
%
%I/O:  cumulative = tdf('cumulative',x,a,options)
%            x is ordinate in range (-inf,inf)
%
%I/O:  density = tdf('density',x,a,options)
%            x is ordinate in range (-inf,inf)
%            density is f(x) density distribution at x.
%            WARNING: 'density' is not available for this distribution
%
%I/O:  quantile = tdf('quantile',u,a,options)
%            u is cumulative distribution at q in range (0,1)
%            quantile is Q ordinate.
%
%I/O:  random = tdf('random',n,a,options)
%            n is the size of the random matrix to generate.
%            random is a 'n' sized matrix of random numbers drawn from f(x).
%
%See also: BETADF, CAUCHYDF, CHIDF, EXPDF, GAMMADF, GUMBELDF, LAPLACEDF, LOGNORMDF, LOGISDF, NORMDF, PARETODF, TRIANGLEDF, UNIFDF, WEIBULLDF

%Copyright (c) Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.

%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998


if nargin==0; method = 'io'; end
if ischar(method) & ismember(method,evriio([],'validtopics'));
  options = [];
  if nargout==0; evriio(mfilename,method,options);
  else;          out = evriio(mfilename,method,options);
  end
  return;
end

%--Check Missing Inputs
if nargin<2
  error([mfilename,' needs at least 2 inputs.'])
end
if nargin<3
  a = 2;
end

%--Check Method
method = ck_function(method);

%--Check Inputs
if ~isreal(x)
  error('Input (x) must be real.');
end
if ~isreal(a)
  error('Input (a) must be real.');
end

%--Run Method
switch lower(method)
  case 'cumulative'
    [x,a] = resize(x,a);
    a(a <= 0) = NaN;   
    negtflag = x<0.;  % negative T-statistic case
    x = x(:)';
    negtflag = negtflag(:)';
    out(~negtflag) = 1-ttestp(x(~negtflag),a);
    out(negtflag)  = ttestp(-x(negtflag),a);

  case 'density'
    error('Density is not available for t distribution function')
    
  case 'quantile'
    % calculate T-statistic for given probability
    [x,a] = resize(x,a);   
    negtflag = x<0.5;  % T-statistic is negative for p<0.5
    x(( x > 1)) = NaN;
    a((a <= 0)) = NaN;  
    x = x(:)';
    negtflag = negtflag(:)';
    out(~negtflag) = ttestp(1-x(~negtflag),a,2);
    out(negtflag) = -ttestp(x(negtflag),a,2);
    
  case 'random'
    if ~isint(x) | ~isnonneg(x)
      error('Input x must be integer > 0.');
    end
    if ~ispos(a)
      error('Input a must be positive.')
    end
    [dummyx,a] = resize(ones(x),a);
    x = size(dummyx);
    sza = size(a);
    %Set x to largest parameter (if didn't happen with resize).
    if ~isscal(a)
      if length(sza)~=length(x) | any(sza~=x)
        x = sza;
      end
    end
    r = rand(x);
    random = tdf('quantile',r,a);
    out = reshape(random, x);

end
