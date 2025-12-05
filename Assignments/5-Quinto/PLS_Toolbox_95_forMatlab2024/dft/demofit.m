function demofit(x)
%DEMOFIT Demonstration of fitting to a distribution.
%
%I/O: demofit(x)

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

if nargin<1; x = 'io'; end
if isa(x,'char');
  options = [];
  if nargout==0; 
    evriio(mfilename,x,options); 
  else; 
    evriio(mfilename,x,options); end
  return; 
end

if ~isreal(x), error('X must be a real vector') ; end 

	dists = {'Beta','Cauchy','Chi squared','Exponential','Gamma',...
		'Gumbel','Laplace','Logistic','Lognormal','Normal',...
		'Pareto','Rayleigh','Triangle','Uniform','Weibull'}' ;

	mywarn = warning; warning off;
  
	chi2 = [] ; 
	pval = [] ;
	for i = 1:15
		res  = chitest(x,char(dists(i))) ;
		chi2 = [chi2 res.chi2] ;
		pval = [pval res.pval] ;
	end

	[sp,si] = sort(pval) ;
	sn      = dists(si) ;

	f = figure ;
	h = gca ;
	set(h,'Visible','off') ;

	text(.15,1,'p-value         Distribution') ;
	for i = 1:15
		s = sprintf('%6.4f             %s',sp(16-i),char(sn(16-i))) ;
		text(.15,(18-i)/18,s) ;
	end 

	text(.10,.02,...
	'Ordered from most likely to least likely parent distribution') ;
	text(.10,-.04,...
	'P-values are for rejecting the associated distribution') ;

	warning(mywarn);

