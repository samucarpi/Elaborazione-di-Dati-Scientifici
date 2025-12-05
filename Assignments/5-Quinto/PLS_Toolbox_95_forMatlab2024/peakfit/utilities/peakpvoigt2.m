function [y,y1,y2] = peakpvoigt2(x,p)
%PEAKPVOIGT2 Pseudo-Voigt 2 (Gaussian with Lorentzian)
%
%  INPUTS:
%     x = 4 element vector with parameters
%      x(1) = coefficient,
%      x(2) = mean,
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
%I/O: [y,y1,y2] = peakpvoigt2(x,ax);
%
%See also: PEAKFUNCTION, PEAKGAUSSIAN, PEAKLORENTZIAN, PEAKPVOIGT1

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 4/19/04

%No error trapping is used to maximize speed

z   = (p - x(2))/x(3);
zz  = z.*z;
d   = 1./(1 + zz); %d
f   = exp(-zz/2);  %f
a   = x(4)*f;
b   = (1-x(4))*d;
y   = x(1)*(a + b);  %This is the peak function

if nargout>1
  n  = length(p);
  y1 = zeros(4,n);
  y2 = zeros(4,4,n);
   c      = x(1)*z/x(3);
   bb     = 2*b.*d;      %2(1-x4)/d2


  y1(1,:) = a + b;                               %dy/dx1
  y1(2,:) = c.*(a + bb);                         %dy/dx2
  y1(3,:) = z.*y1(2,:);                          %dy/dx3
  y1(4,:) = x(1)*(f - d);                        %dy/dx4

%  %y2(1,1,:) = 0;                                     %d2y/dx1^2%stopped here
%   y2(2,2,:) = x(1)*((zz-1).*a+bb.*(4*zz.*d-1))/x(3)/x(3); %d2y/dx2^2
%   y2(3,3,:) = x(1)*zz.*((zz-3).*a+bb.*(4*zz.*d-3))/x(3)/x(3);    %d2y/dx3^2
%  %y2(4,4,:) = 0;                                    %d2y/dx4^2
% % 
%   y2(1,2,:) = z.*(a+2*bb)/x(3);                       %d2y/dx1dx2 = d2y/dx2dx1
%   y2(2,1,:) = y2(1,2,:);
%   y2(1,3,:) = z.*squeeze(y2(1,2,:))';               %d2y/dx1dx3 = d2y/dx3dx1
%   y2(3,1,:) = y2(1,3,:);
%   y2(1,4,:) = f-d;                                  %d2y/dx1dx4 = d2y/dx4dx1
%   y2(4,1,:) = y2(1,4,:);
%   y2(2,3,:) = c.*((zz-2).*a+(2*zz.*d-1).*bb*2)/x(3);  %d2y/dx2dx3 = d2y/dx3dx2
%   y2(3,2,:) = y2(2,3,:);
%   y2(2,4,:) = c.*(f-2*d.*d);                        %d2y/dx2dx4 = d2y/dx4dx2
%   y2(4,2,:) = y2(2,4,:);
%   y2(3,4,:) = z.*squeeze(y2(2,4,:))';               %d2y/dx3dx4 = d2y/dx4dx3
%   y2(4,3,:) = y2(3,4,:);
end
