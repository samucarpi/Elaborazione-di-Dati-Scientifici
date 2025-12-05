function out = triangledf(method,x,a,b,c,options)
%TRIANGLEDF Triangle distribution function.
%  INPUTS:
%     method = string defining type of request (see below).
%         x = depends on call (see below).
%         a = "min" parameter (real, <= mode).
%         b = "max" parameter (real, >= mode).
%         c = "mode" parameter (real, >= min and <= max).
%
%         NOTE: Under certain conditions inputs will be resized by RESIZE
%         function. For more information type "resize help". 
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields used:
%
%I/O:  cumulative = triangledf('cumulative',x,a,b,c,options)
%            x is ordinate in range (-inf,inf)
%            For x =< c
%            f(x) = (x-a).^2 ./ ((b-a).*(c-a))
%            For x > c
%            f(x) = 1-(b-x).^2./((b-a).*(b-c))
%I/O:  density = triangledf('density',x,a,b,c,options)
%            x is ordinate in range (-inf,inf)
%            density is f(x) density distribution at x.
%            For x =< c
%            f(x) = 2.*(x-a) ./ ((b-a).*(c-a))
%            For x > c
%            f(x) = 2.*(b-x) ./ ((b-a).*(b-c))
%I/O:  quantile = triangledf('quantile',u,a,b,c,options)
%            u is cumulative distribution at q in range (-inf,inf)
%            quantile is Q ordinate.
%            f(x) = [see code]
%I/O:  random = triangledf('random',n,a,b,c,options)
%            n is the size of the random matrix to generate.
%            random is a 'n' sized matrix of random numbers drawn from f(x).
%
%See also: BETADF, CAUCHYDF, CHIDF, EXPDF, GAMMADF, GUMBELDF, LAPLACEDF, LOGNORMDF, LOGISDF, NORMDF, PARETODF, RAYDF, UNIFDF, WEIBULLDF

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
  a = 3;
end
if nargin<4
  b = 5;
end
if nargin<5
  c = 4;
end

%--Check Method
method = ck_function(method);

%--Check Inputs
if ~isreal(x), error('X must be real.'); end
if ~isreal(a), error('A must be real.'); end
if ~isreal(b), error('B must be real.'); end
if ~isreal(c), error('C must be real.'); end
% [aa, bb, cc] = resize(a,b,c);%Create temporary vars for test.
% if any(aa(:) > cc(:)) | any(bb(:) < cc(:))
%   error('Inputs a <= c and b >= c.'); 
% end

%--Run Method
switch lower(method)
  case 'cumulative'
    [x,a,b,c] = resize(x,a,b,c);
    x(find(x < a | x > b | a > c | b < c | b < a)) = NaN;
    p1 = (x-a).^2 ./ ((b-a).*(c-a));
    p2 = 1-(b-x).^2./((b-a).*(b-c));
    cumulative = p1;
    cumulative(find(x > c)) = p2(find(x > c));
    out = cumulative;
    
  case 'density'
    [x,a,b,c] = resize(x,a,b,c);
    x(find(x < a | x > b | a > c | b < c | b < a)) = NaN;
    d1 = 2.*(x-a) ./ ((b-a).*(c-a));
    d2 = 2.*(b-x) ./ ((b-a).*(b-c));
    density = d1;
    density(find(x >  c)) = d2(find(x > c));
    out = density;
    
  case 'quantile'
    if ~isprob(x), error('Input x must be probability values: 0<=x<=1.'), end
    [x,a,b,c] = resize(x,a,b,c);
    x(find(a > c | b < c | a > b)) = NaN;
    q1 = a + sqrt((b-a).*(c-a).*x);
    q2 = b - sqrt((1-x).*(b-a).*(b-c));
    quantile = q1;
    maxu = (c-a)/(b-a);
    quantile(find(x > maxu)) = q2(find(x > maxu));
    out = quantile;
    
  case 'random'
    if ~isint(x) | ~isnonneg(x)
      error('Input x must be integer > 0.');
    end
    [dummyx,a,b,c] = resize(ones(x),a,b,c);
    if any(a(:) > c(:)) | any(b(:) < c(:))
      error('Inputs a <= c and b >= c.'); 
    end
    x = size(dummyx);
    sza = size(a);
    szb = size(b);
    szc = size(c);
    %Set x to largest parameter (if didn't happen with resize).
    if ~isscal(a)
      if length(sza)~=length(x) | any(sza~=x)
        x = sza;
      end
    elseif ~isscal(b)
      if length(szb)~=length(x) | any(szb~=x)
        x = szb;
      end
    elseif ~isscal(c)
      if length(szc)~=length(x) | any(szc~=x)
        x = szc;
      end
    end
    r  = rand(x);
    maxu = (b-a)/(c-a);
    q1 = a + sqrt((c-a).*(b-a).*r);
    q2 = c - sqrt((1-r).*(c-a).*(c-b));
    random = q1;
    random(find(r>maxu)) = q2(find(r>maxu));
    out = random;

end
