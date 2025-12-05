function result = ttest2e(x,y,test)
%TTEST2E Two sample t-test (assuming equal variance).
%  Calculates a two sample t-test for sample (x) and (y)
%  assuming equal variance. The optional input is (test)
%  which indicates whether the ttest is for 
%        -1   lower tail   H0: mean(x) <= mean(y)
%         0   two-tail     H0: mean(x) ~= mean(y) {default}
%         1   upper tail   H0: mean(x) >= mean(y)
%
%  The output (result) a structure with the following fields:
%         t        = test statistic,
%         p        = probability value,
%         mean1    = mean of x,
%         mean2    = mean of y,
%         var1     = variance of x,
%         var2     = variance of y,
%         n1       = length of x,
%         n2       = length of y,
%         pse      = pooled standard error,
%         df       = degrees of freedom, and
%         hyp      = hypothesis being tested.
%
%Examples:
%     result = ttest2e(x,y);
%     result = ttest2e(x,y,test);
%
%I/O: result = ttest2e(x,y,test);
%
%See also: TTEST1, TTEST2U, TTEST2P

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
if length(test(:)) ~= 1, error('TEST must be scalar') ; end
if test~=-1 & test~=0 & test~=1, error('TEST must be in {-1,0,1}.') ; end

xnam  = inputname(1) ;
if isempty(xnam), xnam = 'x' ; end
ynam  = inputname(2) ;
if isempty(ynam), ynam = 'y' ; end
mean1 = mean(x(:)) ;
mean2 = mean(y(:)) ;
var1  = std(x(:))^2 ;
var2  = std(y(:))^2 ;
n1    = length(x(:)) ;
n2    = length(y(:)) ;
pse  = ( ((n1-1)*var1 + (n2-1)*var2) / (n1+n2-2) ) * (1/n1 + 1/n2) ;
df    = n1+n2-2 ;
t     = (mean1 - mean2) / sqrt(pse) ;
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
h = cat(2,'H0: Mean(',xnam,') ',relop,' Mean(',ynam,')') ;
result = struct('t',t,'p',p,'mean1',mean1,'mean2',mean2,...
	'var1',var1,'var2',var2,'n1',n1,'n2',n2,...
	'pse',pse,'df',df,'hyp',h) ; 
