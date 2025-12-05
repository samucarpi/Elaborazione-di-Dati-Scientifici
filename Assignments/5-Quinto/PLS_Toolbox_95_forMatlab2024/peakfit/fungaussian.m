function [b,y] = fungaussian(b,y,t,wts)
%FUNGAUSSIAN Fit of a Gaussian function
%  Given the data (y) and an axis (t), FUNGAUSSIAN
%  finds the parameters (b) that minimizes
%    ||y  - b(1)*exp(-(t-b(2)).^2 /2/b(3)^2 )|| .
%  subject to
%    b(1)>=0, b(3)>=0
%    b(1)<max(y)
%    
%  INPUTS:
%    b0   = initial guess of b, 3-element vector.
%           (b0) can be empty [ ], and FUNGAUSSIAN will make
%           a best guess of the parameters.
%    y    = vector of measured data, vector w/ N elements.
%    t    = axis, vector w/ N elements.
%    wts  = a N element vector of weights, 0<wts<1.
%
%  OUTPUTS:
%    y = vector corresponding to the best fit gaussian
%        function to the data, Nx1 vector.
%    b = 3-element vector w/ function parameters at best fit.
%
%I/O: [b,yfit] = fungaussian(b0,y,t,wts);
%
%See also: FUNEXPONENTIAL

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 8/9/5

if isempty(b) %make first guess
  i1   = find(y>0);
  t    = t(:);
  y    = y(:);
  
  b    = [ones(length(i1),1) t(i1) -t(i1).^2]\y(i1);
  b(3) = 1/2/b(3); %c^2
  if b(3)<1e-5,     b(3) = 1e-5;   end
  b(2) = b(2)*b(3);
  b(1) = exp(b(1)+(b(2)^2)/2/b(3));
  b(1) = min(b(1),max(y));
  b(3) = sqrt(b(3))/2;
end

options = lmoptimizebnd('options');
options.display = 'off';
options.alow    = [1 0 1]';
options.aup     = [0 0 1]';

[b,fval,exitflag,out]    = lmoptimizebnd(@errgaussian,b(:),[0 -inf 0]',[max(y)*1.2 inf 10]',options,y,t,wts);
y    = peakgaussian(b(:),t(:)');
