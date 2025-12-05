function [y,y1,y2] = peaksigmoid(x,p)
%PEAKSIGMOID Outputs a sigmoid function.
%  INPUTS:
%     x = 3 element vector with parameters
%      x(1) = coefficient,
%      x(2) = offset, and
%      x(3) = decay constant.
%    p = axis 1xN (independent variable).
%
%  OUTPUTS:
%     y = x(1)*(1-exp(-z))./(1+exp(-z)); %1xN
%         where z = x(3)*(p-x(2)).
%    y1 = dy/dxi, 3xN.
%    y2 = d2y/dxi^2, 3x3xN.
%  If only one output is requested the Jacobian and
%  Hessian are not evaluated (provides faster performance).
%
%I/O: [y,y1,y2] = peaksigmoid(x,p);
%
%See also: PEAKFUNCTION, PEAKEXPONENTIAL, PEAKGAUSSIAN, PEAKLORENTZIAN, PEAKPVOIGT1, PEAKPVOIGT2 

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 8/19/04
%nbg 10/11 modified PEAKExponential

%No error trapping is used to maximize speed

z   = x(3)*(p-x(2));            %z
if abs(z)>10, z = sign(z)*10; end
h   = 1+exp(-z);                %(1+exp(-z))
f   = (1-exp(-z))./h;           %f
y   = x(1)*f;                   %the sigmoid function

if nargout>1
  n  = length(p);
  y1 = zeros(2,n);
  y2 = zeros(2,2,n);

  h       = h.^2;               %(1+exp(-z))^2
  g       = 2*exp(-z)./h;  
  y1(1,:) = f;                      %dy/dx1
  y1(2,:) = -x(1)*x(3)*g ;          %dy/dx2
  y1(3,:) = x(1)*(p-x(2)).*g;       %dy/dx3

%   h       = h.^2;               %(1+exp(-z))^4
 %y2(1,1,:) = 0;                    %d2y/dx1^2
  y2(1,2,:) = -x(3)*g;              %d2y/dx1dx2 = d2y/dx2dx1
  y2(2,1,:) = y2(1,2,:);
  y2(1,3,:) = -(p-x(2)).*g;         %d2y/dx1dx3 = d2y/dx3dx1
  y2(3,1,:) = y2(1,3,:);
  g         = -x(1)*g;
  y2(2,2,:) = x(3)*x(3)*(1-exp(-2*z)).*g; %d2y/dx2^2
  g         = g./h;
  y2(2,3,:) = (1-z+2*exp(-z)+(1+z).*exp(-2*z)).*g;  %d2y/dx2dx3 = d2y/dx3dx2
  y2(3,2,:) = y2(2,3,:);
  y2(3,3,:) = (p-x(2)).*(p-x(2)).*(1-exp(-2*z)).*g; %d2y/dx3^2
end
