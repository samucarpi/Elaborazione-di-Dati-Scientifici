function result = ttest1(x,mu,test)
%TTEST1  One sample t-test
%  Calculates a one sample t-test for sample (x). Optional
%  inputs are (mu) the null hypothesis value for the
%  mean {default = 0}, and (test) which indicates whether the
%  ttest is for 
%        -1   lower tail   H0: mean(x) <= mean(y)
%         0   two-tail     H0: mean(x) ~= mean(y) {default}
%         1   upper tail   H0: mean(x) >= mean(y)
%
%  The output (result) a structure with the following fields:
%         t        = test statistic,
%         p        = probability value,
%         mean     = mean of x,
%         var      = variance of x,
%         n        = length of x,
%         se       = standard error,
%         df       = degrees of freedom, and
%         hyp      = hypothesis being tested.
%
%Examples:
%     result = ttest1(x);
%     result = ttest1(x,mu);
%     result = ttest1(x,mu,test);
%
%I/O: result = ttest1(x,mu,test);
%
%See also: TTEST2E, TTEST2U, TTEST2P

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

nargchk(1,3,nargin) ;
if nargin < 2 
	mu = 0 ;
	test = 0 ;
elseif nargin < 3
	test = 0 ;
end

if ~isreal(x), error('X must be real.') ; end
if length(mu(:)) ~= 1, error('MU must be scalar') ; end
if length(test(:)) ~= 1, error('TEST must be scalar') ; end
if test~=-1 & test~=0 & test~=1, error('TEST must be in {-1,0,1}.') ; end

xnam = inputname(1) ;
if isempty(xnam), xnam='x' ; end 
meanx = mean(x(:)) ;
var   = std(x(:))^2 ;
n     = length(x) ; 
se    = sqrt(var/n) ;
df    = n - 1 ;
stats = [meanx var n df] ;
t     = (meanx - mu) / se ;
if test==-1 
	p = pt(t,df) ; 
	relop = '<' ;
elseif test== 0 
	p = 2*(pt(-abs(t),df)) ; 
	relop = '~=' ;
elseif test== 1 
	p = 1-pt(t,df) ; 
	relop = '>' ;
end
h = cat(2,'H0: Mean(',xnam,') ',relop,' ',num2str(mu)) ;
result = struct('t',t,'p',p,'mean',meanx,'var',var,...
	'n',n,'se',se,'df',df,'hyp',h) ;
