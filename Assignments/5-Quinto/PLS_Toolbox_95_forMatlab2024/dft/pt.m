function probability = pt(x,v,m)
%PT Probability function for Student's t(v).
%  Probability distribution function for input (x) with
%  degrees of freedom given by (v). (x) and (v) must be
%  real (either may be scalar). The optional input (m) is
%  an offset {default = 0}. The distribution is defined as:
%
%            /x   t^(v/2 - 1) * exp(-t/2)
%    F(x) =  |    ----------------------- dt
%            /0    2^(v/2) * Gamma(v/2)
%
%I/O: probability = pt(x,v,m);
%
%Examples:
%  pt(1.6449,3) = 0.9007
%  pt(1.96,3)   = 0.9276
%
%See also: PNORM

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
%nbg 6/00 changed help, 10/00 changed help

nargchk(2,3,nargin) ;
if nargin == 2 
	m = 0 ;
end

if ~isreal(x), error('X must be real.') ;        end
if ~isreal(v), error('V must be real.') ;        end
if ~isscal(m), error('M must be scalar.') ;      end

[newx,newv] = resize(x,v) ;
newv(find(newv <= 0)) = NaN ;

newx = newx - m ;
halfv = newv./2 ;
tmp = newv./(newv+newx.*newx) ;
pos = newx>=0 ;
neg = newx<0 ;
mywarn = warning; warning off; 

% Fix edge cases
tmp = max(eps, tmp);
tmp = min(1-eps, tmp);

if ~isnan(tmp)
  probp = 1-betainc(tmp,halfv,0.5)/2 ;
  probn = betainc(tmp,halfv,0.5)/2 ;
else
  probp = NaN;
  probn = NaN;
end

warning(mywarn);
p = pos.*probp + neg.*probn ;
probability = ensurep(p) ;
