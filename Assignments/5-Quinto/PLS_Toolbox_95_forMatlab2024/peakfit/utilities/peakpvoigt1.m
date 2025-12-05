function [y,y1,y2] = peakpvoigt1(x,p)
%PEAKPVOIGT1 Pseudo-Voigt 1 (Gaussian with Lorentzian)
%
%  INPUTS:
%     x = 4 element vector with parameters
%      x(1) = coefficient,
%      x(2) = peak center,
%      x(3) = spread (must be >0), and
%      x(4) = fraction guassian (0<x(4)<1).
%    ax = axis 1xN (independent variable).
%
%  OUTPUTS:
%     z = p-x(2)
%     y = x(1)*( x(4)*exp(-4*ln(2)*z.^2/x(3)^2) + 
%               (1-x(4))*x(3)^2./(x(3)^2+z.^2) ); %1xN.
%    y1 = dy/dxi,    4xN Jacobian.
%    y2 = d2y/dxi^2, 4x4xN Hessian.
%
%I/O: [y,y1,y2] = peakpvoigt1(x,p);
%
%See also: PEAKFUNCTION, PEAKGAUSSIAN, PEAKLORENTZIAN, PEAKPVOIGT2

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 12/1/05

%No error trapping is used to maximize speed

z   = p - x(2);
zz  = z.*z;
x32 = x(3)*x(3);
a   = 4*log(2);
d   = zz+x32;
f1  = exp(-a*zz/x32);  %f1
f2  = x32./d;          %f2

aa  = x(4)*f1;
bb  = (1-x(4))*f2;
y   = x(1)*(aa + bb);  %This is the peak function

if nargout>1
  n  = length(p);
  y1 = zeros(4,n);
  y2 = zeros(4,4,n);
  
  f12 = 2*a*z.*f1/x32;
  f13 = f12.*z/x(3);
  f22 = 2*z.*f2./d;
  f23 = 2*x(3)*zz./d./d;

  y1(1,:) = aa + bb;                             %dy/dx1
  y2(1,2,:) = x(4)*f12+(1-x(4))*f22;             %d2y/dx1dx2
  y1(2,:) = x(1)*squeeze(y2(1,2,:))';            %dy/dx2
  y2(1,3,:) = x(4)*f13+(1-x(4))*f23;             %d2y/dx1dx3
  y1(3,:) = x(1)*squeeze(y2(1,3,:))';            %dy/dx3
  y1(4,:) = x(1)*(f1-f2);                        %dy/dx4

 %y2(1,1,:) = 0;                                           %d2y/dx1^2
%   y2(2,2,:) = x(1)*2*(x(4)*a*(z.*f12-f1)/x32 + ...
%                  (1-x(4))*f2.*(3*zz-x32)./d./d);           %d2y/dx2^2
%   y2(3,3,:) = x(1)*2*zz.*(x(4)*a*(f13-3*f1/x(3))/x32/x(3) + ...
%                  (1-x(4))*(zz+x32+4*x(3)*z)./d./d./d);     %d2y/dx3^2
 %y2(4,4,:) = 0;                                           %d2y/dx4^2
 
%   y2(2,1,:) = y2(1,2,:);                         %d2y/dx1dx2 = d2y/dx2dx1
%   y2(3,1,:) = y2(1,3,:);                         %d2y/dx1dx3 = d2y/dx3dx1
%   y2(1,4,:) = f1-f2;                             %d2y/dx1dx4 = d2y/dx4dx1
%   y2(4,1,:) = y2(1,4,:);
%   y2(2,3,:) = 2*x(1)*z.*(a*x(4)*(f13-2*f1/x(3))/x32 + ...
%               (1-x(4))*(f23-2*x(3)*f2./d)./d);   %d2y/dx2dx3 = d2y/dx3dx2
%   y2(3,2,:) = y2(2,3,:);
%   y2(2,4,:) = x(1)*(f12-f22);                    %d2y/dx2dx4 = d2y/dx4dx2
%   y2(4,2,:) = y2(2,4,:);
%   y2(3,4,:) = x(1)*(f13-f23);                    %d2y/dx3dx4 = d2y/dx4dx3
%   y2(4,3,:) = y2(3,4,:);
end
