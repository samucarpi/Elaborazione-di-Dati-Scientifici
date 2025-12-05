function [ty,lambda,y0] = glog(y,lambda,y0,invflag)
%GLOG Generalized Log Transform
% Generalized log transform is a weighted log following the equation:
%   ty = ln( (y-y0) + sqrt((y-y0)^2 + lambda) )
% where lambda and y0 are experimentally determined constants. If the
% invflag input is passed as 1 (one), the function calculates the inverse
% transform using:
%   y  = 0.5 * ( 2*y0 - lambda*exp(-ty) + exp(ty) )
%
% INPUTS:
%    y      = matrix of data (double) to transform
% OPTIONAL INPUTS:
%    lambda  = transform parameter. If omitted or empty, an optmization
%              minimizing the difference between passed data is performed.
%              The optimized lambda is returned as an output.
%    y0      = offset for use in extended log (y0 is subtracted from y
%              before calculating the transform) if omitted, empty, or
%              zero, no offset is used (standard glog transform).
%    nsd     = passed in place of y0 ONLY when lambda is empty (indicating
%              optimization mode). Represents the number of standard
%              deviations of noise to use as an estimate for offset y0.
%    invflag = Flag governing calculation of the forward transform (when 0,
%              zero) or the inverse transform (when 1, one)
%
% OUTPUTS:
%    ty     = transformed y
%    lambda = the lambda used for transform
%    y0     = the y0 used for transform
%
% OPTIMIZATION:
% If lambda is empty or omitted, an optimization is done. If y0 is zero or
% omitted also, a simple glog optimization is performed. If y0 is non-zero,
% then an extended glog optimization is performed where the passed y0 is
% interpreted as the number of standard deviations of estimated noise to
% use for the optimization (nsd = number of standard deviations). In
% general, optimizations should be done on a set of samples which are
% expected to be the same for a given experimental condition and should
% reflect a goodly portion of non-zero responses.
%
% The glog method and the optimization is based on the paper:
%   NMR metabolomics data using the variance stabilising generalised
%   logarithm transformation
%   Parsons, Ludwig, Günther, and Viant
%   BMC Bioinformatics 2007, 8:234  doi:10.1186/1471-2105-8-234
% The electronic version of this article can be found online at: 
%     http://www.biomedcentral.com/1471-2105/8/234 
%
%I/O: ty = glog(y,lambda)         %glog
%I/O: ty = glog(y,lambda,y0)      %extended glog
%I/O: y  = glog(ty,lambda,[],1)   %INVERSE glog
%I/O: y  = glog(ty,lambda,y0,1)   %INVERSE extended glog
%I/O: [ty,lambda] = glog(y,[])         %OPTIMIZE: lambda 
%I/O: [ty,lambda,y0] = glog(y,[],nsd)  %OPTIMIZE: lambda with extended glog
%
%See also: ARITHMETIC, LOGDECAY

%Copyright Eigenvector Research, Inc. 2015
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; y = 'io'; end
if ischar(y);
  options = [];
  if nargout==0; evriio(mfilename,y,options); else ty = evriio(mfilename,y,options); end
  return;
end

switch nargin
  case 1
    % (x)
    lambda  = [];
    y0   = 0;
    invflag = false;
  case 2
    % (x,lambda)
    y0   = 0;
    invflag = false;    
  case 3
    % (x,lambda,y0)
    invflag = false;
  case 4
    % (x,lambda,y0,invflag)
    
end

%handle DSO
origx = y;
wasdso = isdataset(y);
if wasdso
  y = y.data;
end

if isempty(invflag)
  invflag = false;
end
if isempty(y0)
  y0 = 0;
end
if isempty(lambda)
  if invflag
    error('Cannot optimize and perform inverse calculation');
  end
  [lambda,y0] = optimize(y,y0);
end

if ~invflag
  %do transform
  ty = log((y-y0)+sqrt((y-y0).^2+lambda));
else
  %do inverse transform
  ty = 0.5*(2*y0-lambda*exp(-y)+exp(y));
end

%insert back into dso
if wasdso
  origx.data = ty;
  ty = origx;
end

%---------------------------------------------------
function [lambda, y0] = optimize(x,nsd)
% The following optimization algorithm is modified from the original
% published as:
%
% NMR metabolomics data using the variance stabilising generalised
% logarithm transformation
% Helen M Parsons1, Christian Ludwig2, Ulrich L Günther2† and Mark R Viant13*†	
%     * Corresponding author: Mark R Viant M.Viant@bham.ac.uk
%     † Equal contributors
% Author Affiliations
% 1 Centre for Systems Biology, The University of Birmingham, Edgbaston, Birmingham, B15 2TT, UK
% 2 The Henry Wellcome Building for Biomolecular NMR Spectroscopy, The University of Birmingham, Edgbaston, Birmingham, B15 2TT, UK
% 3 School of Biosciences, The University of Birmingham, Edgbaston, Birmingham, B15 2TT, UK
% 
% BMC Bioinformatics 2007, 8:234  doi:10.1186/1471-2105-8-234
%
% The electronic version of this article can be found online at: 
%     http://www.biomedcentral.com/1471-2105/8/234 
%
% Usage:
% [lambda, y0]=optimize(x,nsd);
% lambda = transformation 'strength' parameter
% y0 = offset for extended transform
% x = input in row-wise format
% nsd = number of standard deviations for noise estimate (for extended glog
%       only; use zero for standard glog)

if nargin<2 | isempty(nsd) | nsd==0
  noise = 0;
  tolx  = 1e-16;
  tolfun = 1e-15;
else
  % find noise and use as initial y0 guess
  noise = nsd*mean(std(x(1:min(end,100),:)));
  tolx  = 1e-3;
  tolfun = 1e-3;
end

% find starting point (Durbin & Rocke, 2003)
Lm=median(x,1);
Lm=median(Lm);
lambda0=(Lm)^2;

options=optimset('TolX',1e-16,'TolFun',1e-15,'MaxFunEvals',1e3,'MaxIter',1e3);
p=fminsearch(@SSE,lambda0,options,x,noise);

y0  = glog_slope(p,noise); % find slope offset

if abs(p)~=p
  lambda0 = 1;
  options = optimset('TolX',tolx,'TolFun',tolfun,'MaxFunEvals',1e3,'MaxIter',1e3);
  p = fminsearch(@SSE,lambda0,options,x,noise);
  
  y0 = glog_slope(p,noise);
  
  if abs(p)~=p % Using "best guess"
    % create variables
    x_var = var(x);
    x_ext = [x_var; x];
    leny   = size(x,2);
    srt   = round(leny/10); %look at 10-20th % for low var
    
    % rank by variance
    x_sort = sortrows(x_ext',1);
    % work out 'low' variance (not noise) and high variance
    av_low_var = mean(x_sort(srt:(2*srt)),2);
    av_high_var = mean(x_sort((leny-9):leny));  % calculate mean of 10 largest variances
    
    p = av_low_var / av_high_var;  % gives starting value
    y0  = glog_slope(p,noise);
  end
end

lambda = p;

%---------------------------------------------------------------------
function L = SSE(lambda,y,noise) % Calculate sum of squared errors

y0 = glog_slope(lambda,noise);
z = jglog(y,y0,lambda);

mean_spec = mean(z,1);
for i=1:size(y,1)
  z(i,:) = z(i,:)-mean_spec;
end
L = sum(sum(z.^2));

%---------------------------------------------------------------------
function slope = glog_slope(lam,noise) % find where slope of glog starts

switch noise
  case 0  %special case - revert to normal glog
    slope = 0;
    return;
end
y = linspace(-1,0.002,1e6);
% find maximum of second derivative
d2z   = -y.*(y.^2+lam).^(-3/2);
[max_val, index] = max(d2z);
slope = -y(index) + noise;

%---------------------------------------------------------------------
function [zj, jac]=jglog(y,y0,lambda) 
% Rescale variables using Jacobian: w = J*z
% Note slight difference in format to Durbin paper - makes eqn computational
% (has extra multiplicative term only; moving minimum up)

z   = glog(y,lambda,y0);
jac = exp(mean(log(sqrt((y-y0).^2+lambda)),2));
zj  = z.*(jac*ones(1,size(z,2)));


