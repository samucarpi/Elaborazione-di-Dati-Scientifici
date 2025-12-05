function  [kde,newx] = kdensity(x,code,width,n,at)
%KDENSITY Kernel density estimation.
%  kdensity(x,code,width,n,at) produces the kernel density estimate
%  of the data contained in the input vector (x) which must be real.
%  Optional inputs are:
%   (code) which indicates the kernel function to use in the calculation.
%           code = 1:  Biweight
%           code = 2:  Cosine
%           code = 3:  Epanechnikov {Default}
%           code = 4:  Gaussian
%           code = 5:  Parzen
%           code = 6:  Rectangular
%           code = 7:  Triangle
%   (width) which indicates the window width to use. By default, the value is
%     calculated from the data.
%   (n) is the number of points at which to estimate the density.
%   (at) allows the user to specify a vector of points at which the density 
%    should be estimated. By using this option, it makes it easier to 
%    overlay density estimates for different samples on the same graph.
%  The outputs are (kde) the kernel density estimate, and (newx) the 
%  points at which the density is estimated {default = min(50,length(x)}.
%
%Examples:
%    kde = kdensity(x);
%    kde = kdensity(x,2);
%    kde = kdensity(x,2,22.4);
%    kde = kdensity(x,2,22.4,50);
%    kde = kdensity(x,2,22.4,50,y);
%
%I/O: [kde,newx] = kdensity(x,code,width,n,at);
%
%See also: PLOTKD

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
    clear kde; 
    evriio(mfilename,x,options); 
  else; 
    kde = evriio(mfilename,x,options); end
  return; 
end

nargchk(1,5,nargin) ;
if length(x(:)) < 2, error('X may not be scalar.') ; end
if std(x(:)) == 0 ,  error('X does not vary.') ;     end
if ~isreal(x),       error('X must be real.') ;      end
newx = x(:) ;
if nargin <= 3, n = min(50,length(newx)) ; end
if nargin <= 2, width = min(std(newx),...
	(pctile1(newx,75)-pctile1(newx,25))/1.349)*.9/length(newx)^.2 ; end 
if nargin == 1,   code = 3 ;                    end 
if ~isreal(code), error('CODE must be real.') ; end
if floor(code)~=code | code < 1 | code > 7, ...
	error('CODE must be in {1,2,...,7}.') ; end
if floor(n)~=n | n<=0 | n > length(newx), ...
	error('N must be in {1,...,length(X)}.') ; end

if nargin == 2 & code ~= 3
	if code == 2
		width = width*3 ;
	elseif code ~= 3
		width = width*2.5 ;
	end
end

meanx = mean(newx) ;
varx  = std(newx).^2 ;
nx    = length(newx) ;
minx  = min(newx) ;
maxx  = max(newx) ;
delta = (maxx-minx+2*width) ./ (n-1) ;
wid   = nx*width ;
if nargin < 5
	at    = minx-width+(linspace(1,n,n)-1)*delta ;
else
	at    = sort(at) ;
	n     = length(at) ;
end


fx = zeros(n,1) ;

if code == 1							% Biweight
	dens = 'Biweight' ;
	con1 = .9375 ;
	for i=1:n
		z = (newx-at(i))/width ;
		y = con1*(1-z.^2).^2 ;
		d = sum(y(find(abs(z)<1)))/wid ;
		fx(i) = d ;
	end
elseif code == 2						% Cosine
	dens = 'Cosine' ;
	for i=1:n
		z = (newx-at(i))/width ;
		y = 1+cos(2*pi*z) ;
		d = sum(y(find(abs(z)<.5)))/wid ;
		fx(i) = d ;
	end
elseif code == 3						% Epanechnikov
	dens = 'Epanechnikov' ;
	con1  = 3/(4*sqrt(5)) ;
	con2  = sqrt(5) ;
	for i=1:n
		z = (newx-at(i))/width ;
		y = con1*(1-(z.^2/5)) ;
		d = sum(y(find(abs(z)<=con2)))/wid ;
		fx(i) = d ;
	end
elseif code == 4						% Gaussian
	dens = 'Gaussian' ;
	con1 = sqrt(2*pi) ;
	for i=1:n
		z = (newx-at(i))/width ;
		y = exp(-.5*z.^2)/con1 ;
		d = sum(y)/wid ; 
		fx(i) = d ;
	end
elseif code == 5						% Parzen
	dens = 'Parzen' ;
	con1 = 4/3 ; 
	con2 = 2*con1 ; 
	for i=1:n
		z = (newx-at(i))/width ;
		y = con1-8*z.^2+8*abs(z).^3 ;
		d = sum(y(find(abs(z)<=.5)))/wid ; 
		y = con2*(1-abs(z)).^3 ;
		d = d+sum(y(find(abs(z)>.5 & abs(z)<1)))/wid ;
		fx(i) = d ;
	end
elseif code == 6						% Rectangular
	dens = 'Rectangular' ;
	for i=1:n
		z = (newx-at(i))/width ;
		y = .5*(abs(z)<1) ;
		d = sum(y)/wid ; 
		fx(i) = d ;
	end
else								% Triangular
	dens = 'Triangular' ;
	for i=1:n
		z = (newx-at(i))/width ;
		y = 1 - abs(z) ;
		d = sum(y(find(abs(z)<1)))/wid ; 
		fx(i) = d ;
	end
end
kde = struct('x',at,'fx',fx,'n',n,'width',width,'kernel',dens) ;
