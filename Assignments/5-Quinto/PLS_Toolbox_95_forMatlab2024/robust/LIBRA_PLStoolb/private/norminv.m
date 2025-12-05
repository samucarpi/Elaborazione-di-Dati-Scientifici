function q=norminv(prob,mu,sigma)
%NORMINV Inverse of the normal cumulative distribution function (cdf).
%   Q = NORMINV(PROB,MU,SIGMA) finds the inverse of the normal cdf with
%   mean, MU, and standard deviation, SIGMA.
%
%   The size of Q is the common size of the input arguments. A scalar input
%   functions as a constant matrix of the same size as the other inputs.
%
%   Default values for MU and SIGMA are 0 and 1 respectively.
%
%   See also NORMCDF, ERF, ERFC, ERFINV, ERFCINV.
%
%  INPUTS:
%     prob   = Probability level (0 to 1).
%     mu     = mean of normal distribution.
%     sigma  = standard deviation.
%
%  OUPUTS:
%     q      = quantile.
%

%Copyright Eigenvector Research, Inc. 2004-2006

if nargin<2;
  mu = 0;
end
if nargin<3;
  sigma = 1;
end
if prob<0 | prob>1;
  error('prob must be between zero (0) and one (1)')
end

q = qnorm(prob,mu,sigma);


%------------------------------------------------------------
function quantile = qchi(u,v,b)
%QCHI Quantile function for Chi-squared(V).
%  Quantile function for the input (u) with degrees of freedom given
%  by each element of (v). (u) and (v) must be real (either may be scalar).
%  The optional input is (b) {default = 0}. The distribution is defined as:
%
%                            /x    t^(v/2 - 1) * exp(-t/2)
%    Q(u) = x where F(x) =  |      -----------------------  dt  =  u
%                          /b        2^(v/2) * Gamma(v/2)
%
%I/O: quantile = qchi(u,v,b);
%
%See also: DCHI, PCHI, QNORM, RCHI

%Copyright (c) 2000 Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

nargchk(2,3,nargin) ;
if nargin==2
	b = 0 ;
end

if ~isreal(u), error('U must be real.') ;     end
if ~isreal(v), error('V must be real.') ;     end
if ~isscal(b), error('B must be scalar.') ;   end

% Have to iterate via the gamma function (CHS).
quantile = qgamma(u,v./2,2) + b ;

%------------------------------------------------------------
function quantile = qgamma(u,a,b,c)
%QGAMMA Quantile function for Gamma(A,B).  
%  Quantile function of each element of the input (u) with
%  parameter (a). Elements of (u) must be probability values.
%
%    Q(u) = x where F(x) = IncompleteBeta(x,a,b) = u
%
%I/O: quantile = qgamma(u,a,b,c);
%
%See also: DGAMMA, PGAMMA, QNORM, RGAMMA

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

if ~isreal(u), error('U must be real.') ;     end
if ~isreal(a), error('A must be real.') ;     end
if ~isreal(b), error('B must be real.') ;     end
if ~isscal(c), error('C must be scalar.') ;   end

% Note: Matlab nice enough to define epsilon for us.

[newu,newa,newb] = resize(u,a,b) ;
newa(find(newa <= 0)) = NaN ;
newb(find(newb <= 0)) = NaN ;
newu(find(newu < 0 | newu > 1)) = NaN ;

% get starting values and call the newton optimizer
ab = newa.*newb ;
kk = ab.*newb ;
mm = real(log(kk + ab.^2)) ;
mu = 2.*real(log(ab)) - 0.5*mm ;
s  = -2*real(log(ab)) + mm ;
q  = exp(qnorm(newu,mu,s)) ;

q(q > 1e006) = 1e006 ;

[quantile,ecode] = qnewton(q,'dgamma','pgamma',3,newu,newa,newb,c) ;
quantile(quantile<c) = c ;


%------------------------------------------------------------
function quantile = qnorm(u,a,b)
%QNORM Probability function for Normal(A,B^2).
%  Quantile function of each element of input (u) which must
%  be (0<u<1). Optional inputs are the distribution mean
%  (a) {default = 0}, and standard deviation (b) {default = q}.
%  The distribution is defined as:
%
%    Q(u) =  x  such that F(x) = u
%  where
%
%            /x        exp(-(y-a)^2/(2*b^2))
%    F(x) =  |         --------------------- dy
%            /-inf         sqrt(2*pi)*b
%
%Examples:
%    quantile = qnorm(u);     %where   a=0  b=1
%    qnorm(0.95)  = 1.6449
%    qnorm(0.975) = 1.9600
%    quantile = qnorm(u,a);   %where        b=1
%    quantile = qnorm(u,a,b);
%
%I/O: quantile = qnorm(u,a,b);
%
%See also: DNORM, PNORM, QBETA, QCAUCHY, QCHI, QEXP, QGAMMA,
%          QGUMBEL, QLAPLACE, QLNORM, QLOGIS, QPARETO, QRAY,
%          QTRI, QUNIF, QWEIBULL, RNORM

%Copyright (c) 2000 Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
% nbg 6/00, changed help, 10/00 changed help

nargchk(1,3,nargin) ;
if nargin<=2, b=1 ; end
if nargin==1, a=0 ; end

if ~isreal(u), error('U must be real.') ;     end
if ~isreal(a), error('A must be real.') ;     end
if ~isreal(b), error('B must be real.') ;     end

[newu,newa,newb] = resize(u,a,b) ;
newu(find(newu < 0 | newu > 1)) = NaN ;
newb(find(newb <= 0)) = NaN ;
quantile = sqrt(2.*newb.^2) .* erfinv(2.*newu-1) + newa ;


%------------------------------------------------------------
function [quantile,code] = qnewton(q,pdfs,cdfs,nargs,newu,varargin)
%QNEWTON
%  Loop includes check that iteration does not go forever where 
%  the maximum number of loops as 500.
%  This is standard approach used in several quantile functions.
%
%I/O: [quantile,code] = qnewton(q,pdfs,cdfs,nargs,newu,arg1,arg2,arg3,arg4);

%Copyright (c) 2000 Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

% old call: function [quantile,code] = qnewton(q,pdfs,cdfs,nargs,newu,arg1,arg2,arg3,arg4)

myeps    = sqrt(eps) ;
i        = 0 ;
infinite = 150 ;
ndig     = 1e-6 ;	% Get quantile to within 6 places.

% pdfstr = cat(2,pdfs,'(q') ;
% cdfstr = cat(2,cdfs,'(q') ;
% for i = 1:nargs
% 	pdfstr = cat(2,pdfstr,',arg',num2str(i)) ;
% 	cdfstr = cat(2,cdfstr,',arg',num2str(i)) ;
% end
% pdfstr = cat(2,pdfstr,')') ;
% cdfstr = cat(2,cdfstr,')') ;

while i<infinite
  pdf = feval(pdfs,q,varargin{:});
  cdf = feval(cdfs,q,varargin{:});
% 	pdf = eval(pdfstr) ;
% 	cdf = eval(cdfstr) ;
	pdf(find(pdf<myeps)) = myeps ;
	delta = (cdf-newu) ./ pdf ;
	delta(find(abs(q./max(delta,1e-10))<2)) = ...
		q(find(abs(q./max(delta,1e-10))<2))./2 ;
	if max(abs(cdf-newu)/cdf) < ndig
		quantile = q - delta ;
		code = 0 ;
		return ;
	end
	q = q-delta ;
	i = i+1 ;
end
quantile = q - delta ;
code = 1 ;

%-------------------------------------------------------------------
function density = dgamma(x,a,b,c)
%DGAMMA Density function for Gamma(A,B).
%  Gamma density function of each element of  input (x)
%  with parameter (a). Optional inputs are (b) {default = 1},
%  and (c) {default = 0}. (x) must be real, (a) and (b) must
%  be real and positive, and (c) is a scalar.
%
%           (x/b)^(a-1) exp(-x/b) 
%    f(x) = --------------------- 
%               b*Gamma(a)
%
%I/O: density = dgamma(x,a,b,c);
%
%See also DNORM, PGAMMA, QGAMMA, RGAMMA

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
if ~isscal(c), error('C must be scalar.') ;   end

[newx,newa,newb] = resize(x,a,b) ;

ta = newa ;
tb = newb ;
ta(find(ta < 0)) = NaN ;
tb(find(tb < 0)) = NaN ;
newx = newx - c ;
logdens = (ta-1).*real(log(newx)) - newx./tb - gammaln(ta) - ta.*real(log(tb)) ;
density = exp(logdens) ;


%----------------------------------------------------------------
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


%----------------------------------------------------------------
function binary = isscal(x)
%ISSCAL verifies that (x) is a scalar.
%  Returns a 1 if true and a 0 otherwise.
%
%I/O: binary = isscal(x);

%Copyright (c) 2000 Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

[r,c] = size(x) ;
if r*c > 1
	binary = 0 ;
else
	binary = 1 ;
end
