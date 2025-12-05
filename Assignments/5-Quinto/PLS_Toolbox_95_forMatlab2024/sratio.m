function [sr,fstat,bs,pp] = sratio(x,model,options)
%SRATIO Calculates selectivity ratio for a given regression model.
% Inputs are the calibration data (x) and the regression model calculated
% from those data (model). Output is the selectivity ratio. The larger the
% selectivity ratio, the more useful the given variables are for the
% prediction. Variables with lower selectivity ratio may be excluded
% without degrading the performance of the model (and exclusion may help
% performance).
%
% INPUTS:
%        x = calibration data (optionally: preprocessed calibration data,
%            see options.preprocessed flag)
%    model = regression model (PLS, PCR, MLR, etc)
%
% OPTIONAL INPUTS:
%  options = Options structure containing the fields:
%        preprocessed: [{false}| true ] When true, treat x as if it is
%                      already preprocessed and ignore preprocessing
%                      stored in model. (Used when preprocessing has
%                      already been performed and can be skipped.)
%         probability: probability point for f-statistic {default = 0.95}
%          stdxfactor: [0.001] fraction of the standard deviation of x to
%                      add to the denominator of the sratio calculation
%                      This is used to stabilize the result for variables
%                      with "perfect" fit by a model. A value of zero
%                      reproduces the original publication result.
%
% OUTPUTS:
%       sr = selectivity ratio for each variable included in the model.
%    fstat = approximate cutoff criterion based on f-test.
%       bs = sign of corresponding regression vector such that sr.*bs
%            adds the sign information to the sr plots.
%       pp = probability point (0<pp<1) obtained from an inverse F-test.
%
% Example: figure, plot(sr.*bs), hline(fstat,'r')
%
% See O.M. Kvalheim, "Interpretation of partial least squares regression
% models by means of target projection and selectivity ratio plots,"
% J. Chemometics 2010; 24; 496-504.
%
%I/O: [sr,fstat,bs,pp] = sratio(x,model,options);
%
%See also: GENALG, IPLS, PLOTLOADS, VIP

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0; x = 'io'; end
if ischar(x)
  options = [];
  options.preprocessed = false;
  options.probability  = 0.95;
  options.stdxfactor   = 0.001;
  if nargout==0; clear sr; evriio(mfilename,x,options); else; sr = evriio(mfilename,x,options); end
  return;
end

if nargin<3
  options = [];
end
options = reconopts(options,mfilename);

%get preprocessed data (but only the data used in model)
if ~options.preprocessed
  x = preprocess('apply',model.detail.preprocessing{1},x);
end
if ~isdataset(x)
  x = dataset(x);
end
incl = x.include;
x    = x.data(incl{:});

%loop over y-columns
m    = size(x);
sr   = zeros(size(model.reg,2),m(2));
stdx = std(x);  %calculate this only once (for speed)
for i=1:size(model.reg,2);
  %get regression vector
  b = model.reg(:,i);
  b = b/norm(b);
  
  %get estimate of X as a projection of X on b
  t = x*b;
  p = t'*x/(t'*t);
  xhat = t*p;
  
  %ratio of variance in estimate to variance in residuals
  denom = std(x-xhat).^2 + options.stdxfactor*stdx.^2;
  denom(denom==0) = 1;
  sr(i,:) = (std(xhat).^2)./(denom);
end

if nargout>2
  bs = sign(model.reg)';
  bs(bs==0) = 1;
end
if nargout>1
  %Round to limits INSIDE of 0 and 1 (NOTE: this approach keeps the
  %response with probability moving towards and outside the range linear
  %as opposed to the old method which reset probability to 0.95 - a poor
  %way to reset the limit)
  options.probability = min(max(options.probability,0.0000001),.9999999);
  fstat = ftest(1-options.probability,m(1)-2,m(1)-3);
end
if nargout>3
  pp    = 1-ftest(sr(1,:),m(1)-2,m(1)-3,2);
end
