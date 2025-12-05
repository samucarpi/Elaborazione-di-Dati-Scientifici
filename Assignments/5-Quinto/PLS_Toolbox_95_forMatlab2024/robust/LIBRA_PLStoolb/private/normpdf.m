function density = normpdf(varargin)
%NORMPDF The normal density function.
%  Extracted from Distribution Fitting Toolbox from Eigenvector Research
%  for use ONLY with LIBRA and PLS_Toolbox. 
%
%  Density function for input (x) which must be real.
%  Optional inputs are (a) {default = 0}, and (b) {default = 1}.
%
%I/O: density = normpdf(x,a,b);

%Copyright (c) 2005-2006 Eigenvector Research, Inc.

density = dnorm(varargin{:});

%--------------------------------------------------------
function density = dnorm(x,a,b)
%DNORM Density function for Normal(A,B^2).
%  Calculates the density function for each element of input(x)
%  Optional inputs are parameters (a) {default = 0}, and (b)
%  {default = 1}. (x) must be real. The density is defined as:
%
%            exp(-(x-a)^2/(2*b^2))
%    f(x) =  ---------------------
%                sqrt(2*pi)*b
%
%Examples:
%    dnorm(x)            %where  a=0  b=1
%    dnorm(1.6449) = 0.1031
%    dnorm(1.96)   = 0.0584
%    dnorm(x,a)          %where       b=1
%    dnorm(x,a,b)
%
%I/O: density = dnorm(x,a,b);
%
%See also: DBETA, DCAUCHY, DEXP, DGAMMA, DGUMBEL, DLAPLACE,
%          DLNORM, DLOGIS, DPARETO, DRAY, DTRI, DUNIF, DWEIBULL,
%          PNORM, QNORM, RNORM.

%Copyright (c) 2000 Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

nargchk(1,3,nargin) ;
if nargin<=2, b=1 ; end
if nargin==1, a=0 ; end

if ~isreal(x), error('X must be real.') ;     end
if ~isreal(a), error('A must be real.') ;     end
if ~isreal(b), error('B must be real.') ;     end

[newx,newu,news] = resize(x,a,b) ;
news(find(news <= 0)) = NaN ;
factor = 0.398942280401 ./ news ;
density = factor.*exp(-(newx-newu).^2./(2*news.^2)) ;

%----------------------------------------------------------------
function varargout = resize(varargin);
%dummy function for un-needed check

varargout = varargin;

