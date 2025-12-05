function out = weibulldf(method,x,a,b,options)
%WEIBULLDF Weibull distribution function.
%  INPUTS:
%     method = string defining type of request (see below).
%         x = depends on call (see below).
%         a = "scale" parameter (real).
%         b = "shape" parameter (real and positive).
%
%         NOTE: Under certain conditions inputs will be resized by RESIZE
%         function. For more information type "resize help". 
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields used:
%
%I/O:  cumulative = weibulldf('cumulative',x,a,b,options)
%            x is ordinate in range (-inf,inf)
%            f(x) = 1 - exp(-((x./a).^b))
%I/O:  density = weibulldf('density',x,a,b,options)
%            x is ordinate in range (-inf,inf)
%            density is f(x) density distribution at x.
%            f(x) = exp(real(log(b)) + (b-1).*real(log(x)) - b.*real(log(a)) - (x./a).^b)
%I/O:  quantile = weibulldf('quantile',u,a,b,options)
%            u is cumulative distribution at q in range (-inf,inf)
%            quantile is Q ordinate.
%            f(x) = a .* (real(log(1./(1-x)))).^(1./b)
%I/O:  random = weibulldf('random',n,a,b,options)
%            n is the number of random numbers to generate
%            random is vector of random numbers drawn from f(x).
%
%See also: BETADF, CAUCHYDF, CHIDF, EXPDF, GAMMADF, GUMBELDF, LAPLACEDF, LOGNORMDF, LOGISDF, NORMDF, PARETODF, RAYDF, TRIANGLEDF, UNIFDF

%Copyright (c) Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.

%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
%nbg 04/03 - mod to PLS_Toolbox
%rsk 01/09/06 - update to PLS_Toolbox

if nargin==0; method = 'io'; end
if nargin==1 & ischar(method) 
  switch method
    case {'cumulative' 'density' 'quantile' 'random'}
    otherwise
      options = [];
      if nargout==0; evriio(mfilename,method,options);
      else;          out = evriio(mfilename,method,options);
      end
      return;
  end
end

%--Check Missing Inputs
if nargin<2
  error([mfilename,' needs at least 2 inputs.'])
end
if nargin<3
  a = 0;
end
if nargin<4
  b = 1;
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
if ~isreal(b)
  error('Input (b) must be real.'); 
end

%--Run Method
switch lower(method)
  case 'cumulative'
    [x,a,b] = resize(x,a,b);
    p = 1 - exp(-((x./a).^b));
    cumulative = ensurep(p);
    out = cumulative;
    
  case 'density'
    [x,a,b] = resize(x,a,b);
    a(find(a<0)) = NaN;
    b(find(b<0)) = NaN;
    density = exp(real(log(b)) + (b-1).*real(log(x)) - ...
      b.*real(log(a)) - (x./a).^b);
    out = density;
    
  case 'quantile'
    if ~isprob(x), error('Input x must be probability values: 0<=x<=1.'), end
    [x,a,b] = resize(x,a,b);
    quantile = a .* (real(log(1./(1-x)))).^(1./b);
    quantile(find(x < 0 | x > 1)) = NaN;
    out = quantile;
    
  case 'random'
    if ~isint(x) | ~isnonneg(x)
      error('Input x must be integer > 0.');
    end
    [dummyx,a,b] = resize(ones(x),a,b);
    x = size(dummyx);
    sza = size(a);
    szb = size(b);
    %Set x to largest parameter (if didn't happen with resize).
    if ~isscal(a)
      if length(sza)~=length(x) | any(sza~=x)
        x = sza;
      end
    elseif ~isscal(b)
      if length(szb)~=length(x) | any(szb~=x)
        x = szb;
      end
    end
    random = a .* (real(log(1./(1-rand(x))))).^(1./b);
    out = random;

end
