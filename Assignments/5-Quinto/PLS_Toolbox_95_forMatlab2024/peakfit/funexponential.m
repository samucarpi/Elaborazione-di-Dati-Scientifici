function [b,y] = funexponential(b,y,t,wts)
%FUNEXPONENTIAL Fit of an exponential function
%  Given the data (y) and a time axis (t), FUNEXPONENTIAL
%  finds the parameters (b) that minimizes
%    ||y  - b(1)*exp(-b(2)*t)|| subject to
%     b(1)>0 and b(2)>0 .
%  If weights are used, then it minimizes
%    || ( y  - b(1)*exp(-b(2)*t) ).*sqrt(wts) || .
%    
%  INPUTS:
%    b0   = initial guess of b, two-element vector.
%           (b0) can be empty [ ], and FUNEXPONENTIAL will make
%           a best guess of the parameters.
%    y    = vector of measured data, vector w/ N elements.
%    t    = time axis, vector w/ N elements.
%    wts  = a N element vector of weights, 0<wts<1.
%
%  OUTPUTS:
%    yfit = vector corresponding to the best fit exponential
%           function to the data, Nx1 vector.
%    b    = two-element vector w/ function parameters at best fit.
%
%I/O: [b,yfit] = funexponential(b0,y,t,wts);
%
%See also: FUNGAUSSIAN

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 8/8/5

if isempty(b)
  i1   = find(y>0);
  t    = t(:);
  y    = y(:);

  b    = [ones(length(i1),1) -t(i1)]\log(y(i1));
  b(1) = exp(b(1));
  if b(1)>max(y)*1.2, b(1) = max(y)*1.2; end
  if b(2)<0,          b(2) = 1e-5;   end
end

options = lmoptimizebnd('options');
options.display = 'off';
options.alow    = [1 1]';
options.aup     = [1 0]';

b      = lmoptimizebnd(@errexponential,b(:),[0; 0],[max(y)*1.2; inf],options,y,t,wts);
y      = peakexponential(b(:),t(:)');
