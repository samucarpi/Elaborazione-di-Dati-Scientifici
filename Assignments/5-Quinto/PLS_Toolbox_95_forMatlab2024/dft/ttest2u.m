function result = ttest2u(x,y,test,dfapp)
%TTEST2U Two sample t-test (assuming unequal variance).
% Calculates a two sample t-test for sample (x) and (y) assuming
% unequal variance.
% 
% INPUTS:
%      x = matrix (or column vector) of data for the first sample.
%      y = matrix (or column vector) of data for the second sample.
%
% OPTIONAL INPUTS:
%   test = indicates whte type of t-test to perform:
%          -1   lower tail   H0: mean(x) <= mean(y),
%           0   two-tail     H0: mean(x) ~= mean(y) {default},
%           1   upper tail   H0: mean(x) >= mean(y).
%  dfapp = governs the algorithm for calculating degrees of freedom:
%          -1   Welch's approximate degrees of freedom {default},
%           1   indicates Satterthwaite's approximate degrees of freedom.
%
% OUTPUT:
%  result = a structure with the following fields:
%         t    : test statistic,
%         p    : probability value,
%         mean1: mean of x,
%         mean2: mean of y,
%         var1 : variance of x,
%         var2 : variance of y,
%         n1   : length of x,
%         n2   : length of y,
%         pse  : pooled standard error,
%         df   : degrees of freedom,
%         app  : 'Satterthwaite' or 'Welch',
%         hyp  : hypothesis being tested.
%
%I/O: result = ttest2u(x,y);
%I/O: result = ttest2u(x,y,test,dfapp);
%
%See also: TTEST1, TTEST2E, TTEST2P

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

nargchk(2,4,nargin) ;
if nargin == 2
	test  = 0 ;
	dfapp = -1 ;
elseif nargin == 3
	dfapp = -1 ;
end

if ~isreal(x), error('X must be real.') ; end
if ~isreal(y), error('Y must be real.') ; end
if length(test(:)) ~= 1, error('TEST must be scalar') ; end
if test~=-1 & test~=0 & test~=1, error('TEST must be in {-1,0,1}.') ; end
if length(dfapp(:)) ~= 1, error('DFAPP must be scalar') ; end
if dfapp~=-1 & dfapp~=1, error('DFAPP must be in {-1,1}.') ; end

mean1 = mean(x(:)) ;
mean2 = mean(y(:)) ;
var1  = std(x(:))^2 ;
var2  = std(y(:))^2 ;
n1    = length(x(:)) ;
n2    = length(y(:)) ;

xnam = inputname(1) ;
if isempty(xnam), xnam='x' ; end
ynam = inputname(2) ;
if isempty(ynam), ynam='y' ; end
pse = ( var1/n1 + var2/n2 ) ;
if dfapp == -1
	df  = pse^2 / ( (var1/n1)^2/(n1-1) + (var2/n2)^2/(n2-1) ) ;
	app = 'Welch' ;
else
	df  = -2 + pse^2 / ( (var1/n1)^2/(n1+1) + (var2/n2)^2/(n2+1) ) ;
	app = 'Satterthwaite' ;
end
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
	'pse',pse,'df',df,'app',app,'hyp',h) ; 
