function out = expdf(method,x,a,options)
%EXPDF Exponential distribution function.
%  INPUTS:
%     method = string defining type of request (see below).
%         x = depends on call (see below).
%         a = Mean or scale parameter (real and positive).
%
%         NOTE: Under certain conditions inputs will be resized by RESIZE
%         function. For more information type "resize help". 
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields used:
%
%      NOTE: lambda = 1./a where a = mean parameter.
%
%I/O:  cumulative = expdf('cumulative',x,a,options)
%            x is ordinate in range (-inf,inf)
%            f(x) = 1 - exp(-(x).*lambda)
%I/O:  density = expdf('density',x,a,options)
%            x is ordinate in range (-inf,inf)
%            density is f(x) density distribution at x.
%            f(x) =  exp(-lambda*(x))
%I/O:  quantile = expdf('quantile',u,a,options)
%            u is cumulative distribution at q in range (0,1)
%            quantile is Q ordinate.
%            f(x) =  -real(log(1-x)) ./ lambda;
%I/O:  random = expdf('random',n,a,options)
%            n is the size of the random matrix to generate.
%            random is a 'n' sized matrix of random numbers drawn from f(x).
%
%See also: BETADF, CAUCHYDF, CHIDF, GAMMADF, GUMBELDF, LAPLACEDF, LOGNORMDF, LOGISDF, NORMDF, PARETODF, RAYDF, TRIANGLEDF, UNIFDF, WEIBULLDF

%Copyright (c) Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.

%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
%nbg 04/03 - mod to PLS_Toolbox
%rsk 01/09/06 - update to PLS_Toolbox

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
  a = 1;
end

%--Check Method
method = ck_function(method);

%--Check Inputs
if ~isreal(x)
  error('Input (x) must be real.'); 
end
if ~isreal(a) | ~ispos(a)
  error('Input (a) must be real and positive.'); 
end

%--Run Method
switch lower(method)
  case 'cumulative'
    [x,a] = resize(x,a);
    a = 1./a;
    cumulative  = 1 - exp(-(x).*a);
    cumulative = ensurep(cumulative);
    out = cumulative;
    
  case 'density'
    [x,a] = resize(x,a);
    a = 1./a;
    density = exp(-(x).*a).*a;
    out = density;
    
  case 'quantile'
    [x,a] = resize(x,a);
    x(find(x < 0 | x > 1)) = NaN;
    a = 1./a;
    quantile = -real(log(1-x)) ./ a;
    out = quantile;
    
  case 'random'
    if ~isint(x) | ~isnonneg(x)
      error('Input x must be integer > 0.');
    end
    [dummyx, a] = resize(ones(x),a);
    x = size(dummyx);
    sza = size(a);
    %Set x to largest parameter (if didn't happen with resize).
    if ~isscal(a)
      if length(sza)~=length(x) | any(sza~=x)
        x = sza;
      end
    end
    %a = 1./a;
    random = -real(log(1-rand(x))) ./ a;
    out = random;

end
