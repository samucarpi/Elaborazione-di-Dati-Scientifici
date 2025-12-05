function out = laplacedf(method,x,a,b,options)
%LAPLACEDF Laplace distribution function.
%  INPUTS:
%     method = string defining type of request (see below).
%         x = depends on call (see below).
%         a = Mean parameter (real and positive).
%         b = Shape parameter (real and positive).
%
%         NOTE: Under certain conditions inputs will be resized by RESIZE
%         function. For more information type "resize help". 
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields used:
%
%I/O:  cumulative = laplacedf('cumulative',x,a,b,options)
%            x is ordinate in range (-inf,inf)
%            For x =< a
%            f(x) = .5*exp(-abs(x-a)./b)
%            For x > a
%            f(x) = 1 - .5*exp(-abs(x-a)./b)
%I/O:  density = laplacedf('density',x,a,b,options)
%            x is ordinate in range (-inf,inf)
%            density is f(x) density distribution at x.
%            f(x) = exp(-abs(x-a)./b)./(2.*b);
%I/O:  quantile = laplacedf('quantile',u,a,b,options)
%            u is cumulative distribution at q in range (0,1)
%            quantile is Q ordinate.
%            For x < .5 
%            f(x) = b.*real(log(2*x)) + a
%            For x >= .5
%            f(x) = a - b.*real(log(2*(1-x)))
%I/O:  random = laplacedf('random',n,a,b,options)
%            n is the size of the random matrix to generate.
%            random is a 'n' sized matrix of random numbers drawn from f(x).
%
%See also: BETADF, CAUCHYDF, CHIDF, EXPDF, GAMMADF, GUMBELDF, LOGNORMDF, LOGISDF, NORMDF, PARETODF, RAYDF, TRIANGLEDF, UNIFDF, WEIBULLDF

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
    tmp = .5*exp(-abs(x-a)./b);
    tmp(find(x>a)) = 1 - tmp(find(x>a));
    cumulative = ensurep(tmp);
    out = cumulative;

  case 'density'
    [x,a,b] = resize(x,a,b);
    b(find(b <= 0)) = NaN;
    density = exp(-abs(x-a)./b)./(2.*b);
    out = density;
    
  case 'quantile'
    [x,a,b] = resize(x,a,b);
    x(find(x < 0 | x > 1)) = NaN;
    b(find(b <= 0)) = NaN;
    p2 = find(x>=.5);
    quantile = b.*real(log(2*x)) + a;
    q2 = a - b.*real(log(2*(1-x)));
    quantile(p2) = q2(p2);
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
    r = rand(x);
    random = laplacedf('quantile',r,a,b);
    out = random;

end
