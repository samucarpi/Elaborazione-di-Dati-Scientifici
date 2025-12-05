function [y,y1,y2] = peakexponential(x,p)
%PEAKEXPONENTIAL Outputs an exponential function.
%
%  INPUTS:
%     x = 2 element vector with parameters
%      x(1) = coefficient, and
%      x(2) = decay constant.
%    ax = axis 1xN (independent variable).
%
%  OUTPUTS:
%     y = x(1)*exp( -x(2)*p ); %1xN.
%    y1 = dy/dxi, 2xN.
%    y2 = d2y/dxi^2, 2x2xN.
%  If only one output is requested the Jacobian and
%  Hessian are not evaluated (provides faster performance).
%
%I/O: [y,y1,y2] = peakexponential(x,ax);
%
%See also: PEAKFUNCTION, PEAKGAUSSIAN, PEAKLORENTZIAN, PEAKPVOIGT1, PEAKPVOIGT2 

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 8/19/04
%nbg 8/10/05 modified PEAKGAUSSIAN

%No error trapping is used to maximize speed

f   = exp(-x(2)*p);           %f
y   = x(1)*f;                 %g the peak function

if nargout>1
  n  = length(p);
  y1 = zeros(2,n);
  y2 = zeros(2,2,n);

  y1(1,:) = f;                      %dy/dx1
  y1(2,:) = -p.*y ;                 %dy/dx2

 %y2(1,1,:) = 0;                    %d2y/dx1^2
  y2(2,2,:) = -p.*y1(2,:);          %d2y/dx2^2
  y2(1,2,:) = -p.*f;                %d2y/dx1dx2 = d2y/dx2dx1
  y2(2,1,:) = y2(1,2,:);
end
