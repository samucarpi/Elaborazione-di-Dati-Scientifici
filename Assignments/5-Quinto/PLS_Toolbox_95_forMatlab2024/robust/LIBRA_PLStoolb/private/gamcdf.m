function p = gamcdf(varargin)
%GAMCDF The gamma probability distribution function.
%  Extracted from Distribution Fitting Toolbox from Eigenvector Research
%  for use ONLY with LIBRA and PLS_Toolbox. 
%
%  Probablity density function for input (x) with parameter (a).
%  Optional inputs are (b) {default = 1} and (c) {default = 0}.
%  (x), (a), and (b) must be real. (a) and (b) must be positive.
%
%I/O: probability = gamcdf(x,a,b,c);

%Copyright (c) 2005-2006 Eigenvector Research, Inc.

p = pgamma(varargin{:});

%-----------------------------------------------------------------
function probability = pgamma(x,a,b,c)
%PGAMMA Probability function for Gamma(A,B).
%  Probablity density function for input (x) with parameter (a).
%  Optional inputs are (b) {default = 1} and (c) {default = 0}.
%  (x), (a), and (b) must be real. (a) and (b) must be positive.
%  The probability function is defined as:
%
%           (x/b)^(a-1) exp(-x/b) 
%    f(x) = --------------------- 
%               b*Gamma(a)
%
%I/O: probability = pgamma(x,a,b,c);
%
%See also: DGAMMA, PNORM, QGAMMA, RGAMMA

%Copyright (c) 2000 Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

nargchk(2,4,nargin) ;
if nargin <= 3
	c = 0 ;
	if nargin == 2 
		b = 1 ; 
	end
end

if ~isreal(x), error('X must be real.') ;     end
if ~isreal(a), error('A must be real.') ;     end
if ~isreal(b), error('B must be real.') ;     end

[newx,newa,newb] = resize(x,a,b) ;
newa(find(newa <= 0)) = NaN ;
newb(find(newb <= 0)) = NaN ;
newx = newx - c ;

p = gammainc(newx ./ newb, newa) ;
probability = ensurep(p) ;

%----------------------------------------------------------------
function probability = ensurep(x)
%ENSUREP verifies that x contains only probabilities in [0,1].
%
%I/O: probability = ensurep(x);

%Copyright (c) 2000 Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

x(find(x>1 & ~isnan(x) & ~isinf(x))) = 1 ;
x(find(x<0 & ~isnan(x) & ~isinf(x))) = 0 ;
x(find(imag(x)~=0)) = NaN ;
probability = x ;

%----------------------------------------------------------------
function varargout = resize(varargin);
%dummy function for un-needed check

varargout = varargin;

