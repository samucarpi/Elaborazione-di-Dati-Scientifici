function [quantile,exitflag] = newtondf(q,distfun,x,a,b,maxits,tol,varargin)
%NEWTONDF Newton's root finder.
%  Inputs are (q) the quantile point of interest,
%  (distfun) a string containing the name of the
%  distribution function, (x)
%  and (a) and (b) vector and parameters for the distribution function.
%
%  Outputs are the quantile (quantile) and (exitflag) which
%  is 0 if there is no error, and 1 if the maximum number of
%  iterations is exceeded.
%
%I/O: [quantile,exitflag] = newtondf(q,distfun,x,a);

%Copyright (c) Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.

%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
%nbg - 04/03 major mod to PLS_Toolbox

if nargin<1; q = 'io'; end
if isa(q,'char');
  options = [];
  if nargout==0; clear quantile; evriio(mfilename,q,options); else; quantile = evriio(mfilename,q,options); end
  return; 
end

myeps    = sqrt(eps) ;
i        = 0 ;         % Iteration counter
if nargin<6 | isempty(maxits)
  maxits = 150 ;       % Maximum number of iterations
end
if nargin<7 | isempty(tol)
  tol    = 1e-6 ;      % Get quantile to within 6 places.
end

spdf     = [distfun,'(''density'',q,a(1),a(2));'];
scdf     = [distfun,'(''cumulative'',q,a(1),a(2));'];

switch lower(distfun)
case {'betadf'}
	while i<maxits
    pdf = betadf('density',q,a,b);
    cdf = betadf('cumulative',q,a,b);
		pdf(find(pdf<myeps)) = myeps ;
	
		delta = (cdf-x) ./ pdf;
    j     = find(abs(q./max(delta,1e-10))<2);
		delta(j) = q(j)./2 ;
		if max(abs(cdf-x)/cdf) < tol
			quantile = q - delta ;
			exitflag = 0 ;
			return ;
		end
		q     = q - delta ;
    q(find(q<0)) = myeps;
    q(find(q>1)) = 1-myeps;
		i     = i + 1 ;
	end
case {'gammadf'}
	while i<maxits
    pdf = gammadf('density',q,a,b);
    cdf = gammadf('cumulative',q,a,b);
		pdf(find(pdf<myeps)) = myeps ;
	
		delta = (cdf-x) ./ pdf;
    j     = find(abs(q./max(delta,1e-10))<2);
		delta(j) = q(j)./2 ;
		if max(abs(cdf-x)/cdf) < tol
			quantile = q - delta;
			exitflag = 0;
			return ;
		end
		q     = q - delta;
		i     = i + 1;
	end
end
quantile  = q - delta;
exitflag  = 1;
