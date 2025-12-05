function out = normdf(method,x,a,b,options)
%NORMDF Normal / Gaussian distribution function.
%  INPUTS:
%     method = string defining type of request (see below).
%         x = depends on call (see below).
%         a = Mean parameter (real).
%         b = Standard deviation parameter (real and positive).
%
%         NOTE: Under certain conditions inputs will be resized by RESIZE
%         function. For more information type "resize help". 
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields used:
%         name: 'options'.
%
%  OUTPUT:
%      prob = depends on call (see below).
%
%I/O:  cumulative = normdf('cumulative',x,a,b,options)
%            x is ordinate in range (-inf,inf)
%            f(x) = erfc(-(x-a)./(sqrt(2).*b))./2
%I/O:  density = normdf('density',x,a,b,options)
%            x is ordinate in range (-inf,inf)
%            density is f(x) density distribution at x.
%            f(x) = 1/(sqrt(2)*sqrt(pi))./b .* exp(-(x-a).^2 ./ (2*b.^2))
%I/O:  quantile = normdf('quantile',u,a,b,options)
%            u is cumulative distribution at q in range (0,1)
%            quantile is Q ordinate.
%            f(x) = sqrt(2.*b.^2) .* erfinv(2.*x-1) + a
%I/O:  random = normdf('random',n,a,b,options)
%            n is the size of the random matrix to generate.
%            random is a 'n' sized matrix of random numbers drawn from f(x).
%
%  For more information type "normdf help".
%
%I/O: prob = normdf(x,options);
%I/O: normdf demo
%
%See also: BETADF, CAUCHYDF, CHIDF, EXPDF, GAMMADF, GUMBELDF, LAPLACEDF, LOGNORMDF, LOGISDF, PARETODF, RAYDF, TRIANGLEDF, UNIFDF, WEIBULLDF

%Copyright (c) Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.

%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
%nbg 04/03 - mod to PLS_Toolbox
%rsk 01/09/06 - update to PLS_Toolbox

if nargin==0; method = 'io'; end
if ~ischar(method)
  error('First input must be a method category ("cumulative", "density", "quantile", "random").')
end
if ismember(method,evriio([],'validtopics'));
  options = [];
  options.name     = 'options';
  
  if nargout==0; evriio(mfilename,method,options);
  else;          out = evriio(mfilename,method,options); end
  return;
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
    b(find(b <= 0)) = NaN;
    p = erfc(-(x-a)./(sqrt(2).*b))./2;
    cum = ensurep(p);
    out = cum;

  case 'density'
    [x,a,b] = resize(x,a,b);
    b(find(b <= 0)) = NaN;
    factor = 0.398942280401433 ./ b;
    density = factor .* exp(-(x-a).^2 ./ (2*b.^2));
    out = density;

  case 'quantile'
    [x,a,b] = resize(x,a,b);
    x(find(x < 0 | x > 1)) = NaN;
    b(find(b <= 0)) = NaN;
    quantile = sqrt(2.*b.^2) .* erfinv(2.*x-1) + a;
    out = quantile;

  case 'random'
    if ~isint(x) | ~isnonneg(x)
      error('Input x must be integer > 0.');
    end
    if ~ispos(b)
      error('Input b must be positive.')
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
    random = b.*randn(x) + a;
    out = random;

end
