function out = gammadf(method,x,a,b,options)
%GAMMADF Beta distribution function.
%  INPUTS:
%         x = depends on call (see below), and
%         a = Scale parameter (real and positive).
%         b = Shape parameter (real and positive).
%
%         NOTE: Under certain conditions inputs will be resized by RESIZE
%         function. For more information type "resize help".
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields used:
%         name: 'options',
%
%  OUTPUT:
%      prob = depends on call (see below).
%
%I/O:  prob = gammadf('cumulative',x,a,b,options)
%         x is ordinate in range (0,inf), and
%         prob is F(x) cumulative distribution at x.
%           F(x) =  gammainc(x./b,a)
%I/O:  density = gammadf('density',x,a,b,options)
%         x is ordinate in range (0,inf), and
%         prob is f(x) density distribution at x.
%           F(x) = exp((a-1).*real(log(x)) - x./b - gammaln(a) - a.*real(log(b)))
%I/O:  quantile = gammadf('quantile',u,a,b,options)
%         u is cumulative distribution at q in range (0,1)
%         quantile is Q ordinate.
%           F(x) = exp(normdf('inv',x,mu,s))
%I/O:  random = gammadf('random',n,a,b,options)
%         n is the size of the random matrix to generate.
%         random is a 'n' sized matrix of random numbers drawn from f(x).
%
%  For more information type "gammadf help".
%
%See also: BETADF, CAUCHYDF, CHIDF, EXPDF, GUMBELDF, LAPLACEDF, LOGNORMDF, LOGISDF, NORMDF, PARETODF, RAYDF, TRIANGLEDF, UNIFDF, WEIBULLDF

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

  if nargout==0; evriio(mfilename,method,options);
  else;          out = evriio(mfilename,method,options); end
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
%     if ~isnonneg(x)
%       error('Input (x) must nonnegative.');
%     end
    [x, a, b] = resize(x,a,b);
    a(find(a <= 0)) = NaN;
    b(find(b <= 0)) = NaN;
    cum = ensurep(gammainc(x./b,a));
    out = cum;

  case 'density'
%     if ~isnonneg(x)
%       error('Input (x) must nonnegative.');
%     end
    [x, a, b] = resize(x,a,b);
    a(find(a < 0)) = NaN;
    b(find(b < 0)) = NaN;
    logdens = (a-1).*real(log(x)) - x./b - gammaln(a) - a.*real(log(b));
    density = exp(logdens);
    out = density;

  case 'quantile'
    [x, a, b] = resize(x,a,b);
    a(find(a <= 0)) = NaN;
    b(find(b <= 0)) = NaN;
    x(find(x < 0 | x > 1)) = NaN;
    ab = a.*b;
    kk = ab.*b;
    mm = real(log(kk + ab.^2));
    mu = 2.*real(log(ab)) - 0.5*mm;
    s  = -2*real(log(ab)) + mm;
    q  = exp(normdf('inv',x,mu,s));

    q(q > 1e006) = 1e006 ;

    [quantile,exitflag] = newtondf(q,'gammadf',x,a,b,500,1e-8) ;
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
    random = zeros(x) ;
    [random, a, b] = resize(random, a,b);
    x = size(random);
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
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %FIXME: ncur transpose for b input causes problems.
      b = b;
    end

    random   = zeros(x) ;

    % a<1 (Johnk)
    accept = find(a<1);
    ncur   = length(accept);
    if ncur>0
      arg1(accept) = 1./a(accept) ;
      arg2(accept) = 1./(1-a(accept)) ;
      arg1 = arg1(:);
      arg2 = arg2(:);
      while (ncur > 0)
        z = rand(ncur,1).^(arg1(accept)) ;
        y = rand(ncur,1).^(arg2(accept)) ;
        good = ((z+y) <= 1) ;
        if any(good)
          rx = -real(log(rand(sum(good),1))) ;
          random(accept(good)) = rx .* z(good) ./ (z(good)+y(good)) ;
          accept(good) = [] ;
          ncur = length(accept) ;
        end
      end
      random     = b.*random;
    end

    % a=1	(exponential)
    accept = find(a==1);
    ncur = length(accept);
    if ncur>0
      arg1 = -b(accept);
      arg1 = arg1(:);
      random(accept) = arg1 .* real(log(rand(ncur,1)));
    end

    % a>1	(Best)
    accept = find(a>1);
    ncur = length(accept);
    if ncur>0
      arg1(accept)   = a(accept) - 1 ;  %note: leave blanks for items we're not using so that (accept) can be used to index later
      arg2(accept)   = 3*a(accept) - .75 ;
      arg1 = arg1(:);
      arg2 = arg2(:);
      while (ncur > 0) ;
        u = rand(ncur,1) ;
        v = rand(ncur,1) ;
        w = u .* (1 - u) ;
        y = sqrt(arg2(accept) ./ w) .* (u - .5) ;
        z = arg1(accept) + y ;
        posx = find(z >= 0) ;
        if ~isempty(posx)
          z = 64 .* (w.^3) .* (v.^2) ;
          bool  = (z(posx) <= (1 - (2 .* y(posx).^2) ./ z(posx))) ;
          good1 = posx(find(bool)) ;
          random(accept(good1)) = z(good1) ;
          good2 = posx(find(~bool)) ;
          good2 = good2(find( ...
            real(log(z(good2)))<=2.*(arg1(accept(good2)).*real(log(z(good2)./arg1(accept(good2))))-y(good2)) )) ;
          random(accept(good2)) = z(good2) ;
          accept([good1 ; good2]) = [] ;
        end
        ncur = length(accept) ;
      end
      random     = b.*random;
    end
    out = random;

end
