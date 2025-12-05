function out = cauchydf(method,x,a,b,options)
%CAUCHYDF Cauchy distribution function.
%  INPUTS:
%     method = string defining type of request (see below).
%         x = depends on call (see below).
%         a = Median or location parameter (real).
%         b = Scale parameter (real and positive). Desrcibes
%             distribution of data around the mode.
%
%         NOTE: Under certain conditions inputs will be resized by RESIZE
%         function. For more information type "resize help". 
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields used:
%
%I/O:  prob = cauchydf('cumulative',x,a,b,options)
%            x is ordinate in range (-inf,inf)
%            prob is F(x) cumulative distribution at x.
%               F(x) =  0.5 + (1/pi) * atan((x-offset)/scale)
%I/O:  density = cauchydf('density',x,a,b,options)
%            x is ordinate in range (-inf,inf)
%            density is f(x) density distribution at x.
%            b < 0 will be assigned NAN.
%               f(x) =  { pi*scale* [1 + ((x-offset)/scale)^2] }^(-1)
%I/O:  quantile = cauchydf('quantile',u,a,b,options)
%            u is cumulative distribution at q in range (0,1)
%            quantile is Q ordinate. b <= 0 will be assigned NAN.
%               Q(u) = offset + scale*(tan pi*(u-0.5))
%I/O:  random = cauchydf('random',n,a,b,options)
%            n is the size of the random matrix to generate.
%            random is a 'n' sized matrix of random numbers drawn from f(x).
%
%See also: BETADF, CHIDF, EXPDF, GAMMADF, GUMBELDF, LAPLACEDF, LOGNORMDF, LOGISDF, NORMDF, PARETODF, RAYDF, TRIANGLEDF, UNIFDF, WEIBULLDF

%Copyright (c) Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
%nbg 04/03 - mod to PLS_Toolbox
%jms 12/05 - revised to new format
%rsk 01/09/06 - update to PLS_Toolbox

if nargin==0; method = 'io'; end
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
method  = ck_function(method);

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
    [x, a, b] = resize(x,a,b);
    cumulative = ensurep(0.5 + atan2((x - a)./b,1)/pi);
    out = cumulative;
    
  case 'density'
    [x, a, b] = resize(x,a,b);
    density = 1./(pi*b.*(1+((x - a)./b).^2));
    density(find(b < 0)) = NaN ;
    out = density;
    
  case 'quantile'
    [x, a, b] = resize(x,a,b);
    x(find(x < 0 | x > 1)) = NaN ;
    b(find(b <= 0)) = NaN ;
    quantile = a +b.*tan(pi*(x - 0.5));
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
    random = a + b.*tan(pi*rand(x));
    out = random;
    
end
