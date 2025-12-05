function [y,y1,y2] = peakgaussianskew(x,p)
%PEAKGAUSSIANSKEW Outputs a Skewed Gaussian Function
%
%  INPUTS:
%     x = 3 element vector with parameters
%      x(1) = coefficient,
%      x(2) = mean,
%      x(3) = spread, and
%      x(4) = skew parameter.
%    ax = axis 1xN (independent variable).
%
%  OUTPUTS:
%     y = f(x);      1xN Function.
%    y1 = dy/dxi,    4xN Jacobian.
%    y2 = d2y/dxi^2, 4x4xN Hessian.
%  If only one output is requested the Jacobian and
%  Hessian are not evaluated (provides faster performance).
%
%I/O: [y,y1,y2] = peakgaussianskew(x,ax);
%
%See also: PEAKFUNCTION, PEAKGAUSSIAN, PEAKLORENTZIAN, PEAKPVOIGT1, PEAKPVOIGT2 

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 4/19/04 modified peakgaussian 1/11

%No error trapping is used to maximize speed

z   = (p - x(2))/x(3);      %z
zz  = z.*z;                 %z.^2
f1  = exp(-zz/2);           %f1
f2  = (1+erf(x(4)*z/sqrt(2)))/2; %f2
y   = x(1)*f1.*f2;          %g the peak function

if nargout>1
  n  = length(p);
  y1 = zeros(4,n);
  y2 = 0;%zeros(4,4,n); %not used in peakerror
   A      = z.*y/x(3);
   B      = z.*A;

  y1(1,:) = f1.*f2;                     %dy/dx1
  f2      = f1.*exp(-x(4)^2*zz/2)/x(3);
  y1(2,:) = A-f2 ;                      %dy/dx2
  y1(3,:) = z.*A-x(4)*z.*f2;            %dy/dx3
  y1(4,:) = (p-x(2)).*f2;               %dy/dx4

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
