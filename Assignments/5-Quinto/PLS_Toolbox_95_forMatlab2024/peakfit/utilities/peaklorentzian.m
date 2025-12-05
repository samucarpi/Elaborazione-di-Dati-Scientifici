function [y,y1,y2] = Peaklorentzian(x,p)
%PEAKLORENTZIAN Outputs a Lorentzian Function
%
%  INPUTS:
%     x = 3 element vector with parameters
%      x(1) = coefficient,
%      x(2) = mean, and
%      x(3) = spread (must be >0).
%    ax = axis 1xN (independent variable).
%
%  OUTPUTS:
%     y = x(1)*1./(1 + ((p-x(2))/x(3)).^2 ); %1xN.
%    y1 = dy/dxi, 3xN Jacobian.
%    y2 = d2y/dxi^2, 3x3xN Hessian.
%  If only one output is requested the Jacobian and
%  Hessian are not evaluated (provides faster performance).
%
%I/O: [y,y1,y2] = peaklorentzian(x,ax);
%
%See also: PEAKFUNCTION, PEAKGAUSSIAN, PEAKPVOIGT1, PEAKVOIGT2

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 4/19/04
%nbg 10/05 modified the help

%No error trapping is used to maximize speed

z   = (p - x(2))/x(3);
zz  = z.*z;
d   = 1 + zz;
f   = 1./d;
y   = x(1)*f;  %This is the peak function

if nargout>1
  n  = length(p);
  y1 = zeros(3,n);
  y2 = zeros(3,3,n);
  A      = 2.*f.*f;

  y1(1,:) = f;                       %dy/dx1
  y1(2,:) = x(1)*A.*z/x(3);          %dy/dx2
  y1(3,:) = z.*y1(2,:);              %dy/dx3

 %y2(1,1,:) = 0;                                 %d2y/dx1^2
%   y2(2,2,:) = x(1)*A.*(4*zz.*f-1)/x(3)/x(3);     %d2y/dx2^2
%   y2(3,3,:) = x(1)*A.*zz.*(4*zz.*f-3)/x(3)/x(3); %d2y/dx3^2
%   y2(1,2,:) = A.*z/x(3);                         %d2y/dx1dx2 = d2y/dx2dx1
%   y2(2,1,:) = y2(1,2,:);
%   y2(1,3,:) = squeeze(y2(1,2,:))'.*z;       %d2y/dx1dx3 = d2y/dx3dx1
%   y2(3,1,:) = y2(1,3,:);
%   y2(2,3,:) = 2*x(1)*A.*z.*(2*zz.*f-1)/x(3)/x(3);  %d2y/dx2dx3 = d2y/dx3dx2
%   y2(3,2,:) = y2(2,3,:);
%  y2 = 0; %If peak error requires 2nd derivs and x-terms comments must be removed
end
