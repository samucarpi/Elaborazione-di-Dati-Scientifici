function result = ttest2p(x,y,test)
%TTEST2P  Two sample paired t-test
%  Calculates a two sample paired t-test for samples (x) and (y).
%  Optional input (test) indicates whether the ttest is for 
%        -1   lower tail   H0: mean(x) <= mean(y)
%         0   two-tail     H0: mean(x) ~= mean(y) {default}
%         1   upper tail   H0: mean(x) >= mean(y)
%
%  The output (result) a structure with the following fields:
%         t     = test statistic
%         p     = probability value
%         mean  = mean of x-y
%         var   = variance of x-y
%         n     = length of x-y
%         se    = standard error
%         df    = degrees of freedom
%         hyp   = hypothesis being tested
%
%Examples:
%        result = ttest2p(x,y);
%        result = ttest2p(x,y,test);
%
%I/O: result = ttest2p(x,y,test);
%
%See also: TTEST1, TTEST2E, TTEST2U

%Copyright (c) Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

if nargin<1; x = 'io'; end
if isa(x,'char');
  options = [];
  if nargout==0; clear result; evriio(mfilename,x,options); else; result = evriio(mfilename,x,options); end
  return; 
end

nargchk(2,3,nargin) ;
if nargin == 2
	test = 0 ;
end

if ~isreal(x), error('X must be real.') ; end
if ~isreal(y), error('Y must be real.') ; end
if size(x) ~= size(y), error('X and Y must be conformable.') ; end
if length(test(:)) ~= 1, error('TEST must be scalar') ; end
if test~=-1 & test~=0 & test~=1, error('TEST must be in {-1,0,1}.') ; end

xnam = inputname(1) ;
if isempty(xnam), xnam = 'x' ; end
ynam = inputname(2) ;
if isempty(ynam), ynam = 'y' ; end

newx  = x-y ;
meand = mean(newx(:)) ;
var   = std(newx(:))^2 ;
n     = length(newx) ; 
df    = n - 1 ;
stats = [meand var n df] ;
se    = sqrt(var) / sqrt(n) ; 
t     = meand / se ;

if test==-1 
	p = pt(t,df) ; 
	relop = '<' ;
elseif test== 0
	p = 2*(pt(-abs(t),df)) ;
	relop = '~=' ;
else
	p = 1-pt(t,df) ; 
	relop = '>' ;
end
h = cat(2,'H0: Mean(',xnam,'-',ynam,') ',relop,' 0') ;
result = struct('t',t,'p',p,'mean',meand,'var',var,...
	'n',n,'se',se,'df',df,'hyp',h) ; 
