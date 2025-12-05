function [g,g1,g2] = glowbound(x,a,d)
%GLOWBOUND penalty function for lower boundd
%  Exponential external penalty function 
%    g = exp(-a0*(x-d)) for x-d>=0,  a0 set in function
%    g = -a0*(x-d)+1    for x-d<0
%
%  INPUTS:
%      x = Nx1 vector, independent variable.
%      a = Nx1 vector of penalty magnitudes, all >= 0.
%      d = Nx1 vector, lower boundary.
%
%  OUTPUTS:
%     g  = 1x1 scalar, objective funtion value at x.
%     g1 = Nx1 vector, Jacobian dg/dx at x.
%     g2 = NxN matrix, Hessian d2g/dx2 at x.
%
%Example:
%     x = [0:0.0001:0.1]; a = 1; d = 0.01;
%     plot(x,glowbound(x,a,d)), vline(d), axis([0.008 0.012 0 0.25])
%     xlabel('Independent Variable, X'), ylabel('Penalty Function, g(X)')
%  Note that typically, only a single value of X is passed into GNONNEG.
%
%I/O: [g,g1,g2] = glowbound(x,a,d);
%
%See also: GUPBOUND

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NBG 1/05, 6/05

%No input checking for speed.
g0    = 0.001;
a0    = -log(1e-8)/g0;
x     = x - d + g0;
c     = a0^2/2;

g     = zeros(length(x),1);
i1    = find(x<0);
i2    = find(x>=0);

g(i1) = 1-a0*x(i1)+c*x(i1);
g(i2) = exp(-a0*x(i2));
if nargout>1
  g1      = zeros(length(x),1);
  g2      = zeros(length(x),1);
  g1(i1)  = -a0+2*c*x(i1);
  g1(i2)  = -a0*g(i2);
  g1      = g1.*a;
  g2(i1)  = 2*c;
  g2(i2)  = -a0*g1(i2);
  g2      = diag(g2.*a);
end
g    = a'*g;
