function [y,y1,y2] = peakgaussian(x,p)
%PEAKGAUSSIAN Outputs a Gaussian Function
%
%  INPUTS:
%     x = 3 element vector with parameters
%      x(1) = coefficient,
%      x(2) = mean, and
%      x(3) = spread.
%    ax = axis 1xN (independent variable).
%
%  OUTPUTS:
%     y = x(1)*exp( -(( p-x(2) ).^2)/( 2*x(3)^2 ); %1xN.
%    y1 = dy/dxi, 3xN Jacobian.
%    y2 = d2y/dxi^2, 3x3xN Hessian.
%  If only one output is requested the Jacobian and
%  Hessian are not evaluated (provides faster performance).
%
%I/O: [y,y1,y2] = peakgaussian(x,ax);
%
%See also: PEAKFUNCTION, PEAKLORENTZIAN, PEAKPVOIGT1, PEAKPVOIGT2 

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 4/19/04

%No error trapping is used to maximize speed

z   = (p - x(2))/x(3);      %z
zz  = z.*z;                 %z.^2
f   = exp(-zz/2);           %f
y   = x(1)*f;               %g the peak function

if nargout>1
  x3s = x(3)*x(3);
  n  = length(p);
  y1 = zeros(3,n);
  y2 = zeros(3,3,n);
   A      = z.*f/x(3);
   B      = z.*A;

  y1(1,:) = f;                          %dy/dx1
  y1(2,:) = x(1)*A ;                    %dy/dx2
  y1(3,:) = x(1)*B;                     %dy/dx3

 %y2(1,1,:) = 0;                        %d2y/dx1^2
%   y2(2,2,:) = y.*(zz-1)/x3s;            %d2y/dx2^2
%   y2(3,3,:) = x(1)*B/x(3).*(zz - 3) ;   %d2y/dx3^2
%   y2(1,2,:) = A;                        %d2y/dx1dx2 = d2y/dx2dx1
%   y2(2,1,:) = y2(1,2,:);
%   y2(1,3,:) = B;                        %d2y/dx1dx3 = d2y/dx3dx1
%   y2(3,1,:) = y2(1,3,:);
%   y2(2,3,:) = x(1)*A/x(3).*(zz - 2);    %d2y/dx2dx3 = d2y/dx3dx2
%   y2(3,2,:) = y2(2,3,:);
end
