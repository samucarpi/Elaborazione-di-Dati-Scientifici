function [y,y1,y2] = peakdoublesigmoid(x,p)
%PEAKSIGMOID Outputs a double sigmoid function.
%  INPUTS:
%     x = 4 or 5 element vector with parameters
%      x(1) = coefficient,
%      x(2) = offset (left),
%      x(3) = decay constant (left),
%      x(4) = offset (right) where it is expected that x(4)>x(3) and
%      x(5) = decay constant (right).
%        Note: if length(x)==4 then x(5)=x(3) providing a symmetric
%              double sigmoid.
%    p = axis 1xN (independent variable).
%
%  OUTPUTS:
%     y = x(1)*((1-exp(-z1))./(1+exp(-z1)) + (1-exp(-z2))./(1+exp(-z2));
%         where z1 =  x(3)*(p-x(2)) and
%               z2 = -x(5)*(p-x(4)). 1xN
%    y1 = dy/dxi,    3xN.
%    y2 = d2y/dxi^2, 3x3xN.
%  If only one output is requested the Jacobian and
%  Hessian are not evaluated (provides faster performance).
%
%I/O: [y,y1,y2] = peakdoublesigmoid(x,p);
%
%See also: PEAKFUNCTION, PEAKEXPONENTIAL, PEAKGAUSSIAN, PEAKSIGMOID

% Copyright © Eigenvector Research, Inc. 2023
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%No error trapping is used to maximize speed

if length(x)==4
  x(5) = -x(3);
else
  x(5) = -x(5);
end

if nargout>1
  [y,y1,y2] = peaksigmoid(x(1:3),p);
  [z,z1,z2] = peaksigmoid(x([1 4 5]),p);
  y    = (y +z)/2;
  y1   = (y1+z1)/2;
  y2   = (y2+z2)/2;
else
  y = (peaksigmoid(x(1:3),p) + peaksigmoid(x([1 4 5]),p))/2;
end
