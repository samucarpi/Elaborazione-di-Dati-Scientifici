function out = betadf(method,x,a,b,options)
%BETADF Beta distribution function.
%  INPUTS:
%     method = string defining type of request (see below).
%         x = depends on call (see below).
%         a = Scale parameter (real and nonnegative).
%         b = Shape parameter (real and nonnegative).
%
%         NOTE: Under certain conditions inputs will be resized by RESIZE
%         function. For more information type "resize help".
%
%  OPTIONS:
%      scale : [ 1 ] value of a scale to apply to the range of data.
%     offset : [ 0 ] value of an offset for the distribution.
%
%  OUTPUT:
%I/O:  cum = betadf('cumulative',x,a,b,options)
%            (x) is ordinate in range (0,1).
%            (cum) is F(x) cumulative distribution at (x).
%               F(x) =  betainc(x,a,b)
%I/O:  density = betadf('density',x,a,b,options)
%            (x) is ordinate in range (0,1).
%            parameters (a) and (b) will be replaced by NAN if not positive.
%            (density) is f(x) density distribution at (x).
%               f(x) = ((x.^(a-1)).*((1-x).^(b-1))/beta(a,b)
%I/O:  quantile = betadf('quantile',u,a,b,options)
%            (u) is cumulative distribution at the probability point
%                (quantile) in range (0,1).
%            (quantile) is Q ordinate.
%               Q(u) = probability point.
%I/O:  random = betadf('random',n,a,b,options)
%            (n) is the size of the random matrix to generate.
%            random is a 'n' sized matrix of random numbers drawn from f(x).
%
%Example:
%  y  = betadf('c',0.1,2,2);
%  ys = betadf('q',y,2,2)
%  ys = 0.1000
%
%See also: CAUCHYDF, CHIDF, EXPDF, GAMMADF, GUMBELDF, LAPLACEDF, LOGNORMDF, LOGISDF, NORMDF, PARETODF, RAYDF, TRIANGLEDF, UNIFDF, WEIBULLDF

%Copyright (c) Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenve
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
%nbg 04/03 - mod to PLS_Toolbox
%rsk 01/09/06 - update to PLS_Toolbox

if nargin==0; method = 'io'; end
if ischar(method) & ismember(method,evriio([],'validtopics'));
  options = [];
  options.scale = 1;
  options.offset = 0;
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
if nargin<5
  %Need scale and offset options for chitest to work when given out of
  %range values i.e. not on interval [0 1]. These are provided by parammle.
  options = betadf('options');
end
options = reconopts(options,'betadf');

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
    [x, a, b] = resize(x,a,b);
    x = (x - options.offset) ./ options.scale;
    if ~isprob(x)
      error('Input x must be probability values: 0<=x<=1.')
    end
    a(find(a<0)) = NaN;
    b(find(b<0)) = NaN;
    cum = ensurep(betainc(x,a,b));
    out = cum;

  case 'density'
    [x, a, b] = resize(x,a,b);
    x = (x - options.offset) ./ options.scale;
    if ~isprob(x)
      error('Input x must be probability values: 0<=x<=1.')
    end
    a(find(a<0)) = NaN;
    b(find(b<0)) = NaN;
    tol = 1.e-10;                    % avoid possible divide by zero
    betafact = max(tol, beta(a,b));
    density = (x.^(a-1)).*((1-x).^(b-1))./betafact;
    out = density;

  case 'quantile'
    [x, a, b] = resize(x,a,b);
    a(find(a < 0)) = NaN;
    b(find(b < 0)) = NaN;
    x(find(x < 0 | x > 1)) = NaN;
    q = (a ./ (a+b)) .* ones(size(x));
    q(find(q>=1)) = 1-sqrt(eps);
    q(find(q<=0)) = sqrt(eps);
    [quantile,exitflag] = newtondf(q,'betadf',x,a,b);
    quantile = quantile .* options.scale + options.offset;
    out = quantile;

  case 'random'
    if ~isint(x) | ~isnonneg(x)
      error('Input x must be integer > 0.');
    end
    if ~ispos(a)
      error('Input a must be positive.')
    end
    if ~ispos(b)
      error('Input b must be positive.')
    end
    %Try to resize a, b, and random (x sized zeros matrix eventually for results).
    random = zeros(x) ;
    [random, a, b] = resize(random, a,b);
    x = size(random);
    sza = size(a);
    szb = size(b);
    %Set x to largest parameter (if didn't happen with resize).
    if ~isscal(a)
      if length(sza)~=length(x) | any(sza~=x)
        x = sza;
        random = zeros(x);%Regenerate random in case resized to a.
      end
    elseif ~isscal(b)
      if length(szb)~=length(x) | any(szb~=x)
        x = szb;
        random = zeros(x);%Regenerate random in case resized to b.
      end
    end

    if isscal(a);
      a = ones(x).*a;
    end
    if isvec(a) & size(a,2)== 1
      %Transpose to direction of ncur.
      a = a';
    end

    if isscal(b);
      b = ones(x).*b;
    end
    if isvec(b) & size(b,2)== 1
      %Transpose to direction of ncur.
      b = b';
    end

    ncur   = prod(x);
    accept = 1:ncur;

    while ncur>0
      z1     = rand(ncur,1).^(1./a(accept)') ;
      z2     = rand(ncur,1).^(1./b(accept)') ;
      good   = ((z1+z2) <= 1) ;
      if any(good)
        random(accept(good)) = z1(good) ./ (z1(good)+z2(good)) ;
        accept(good) = [] ;
        ncur = length(accept) ;  %how many more do we need
      end
    end
    random = options.scale.*random + options.offset;
    out = random;

end
