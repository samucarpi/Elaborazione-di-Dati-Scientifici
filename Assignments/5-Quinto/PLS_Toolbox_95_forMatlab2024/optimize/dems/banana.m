function [p,p1,p2] = banana(x)
%BANANA Rosenbrock's function
%  INPUT:
%    x  = 2 element vector [x1 x2]
%  OUTPUTS:
%    p  = P(x)  = 100(x1^2-x2)^2 + (x1-1)^2
%    p1 = P'(x) = [400(x1^3-x1x2) + 2(x1-1); -200(x1^2-x2)] 
%    p2 = P"(x) = [1200x1^2-400x2+2, -400x1; -400x1, 200]
%
%I/O: [p,p1,p2] = banana(x);

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%nbg 6/05

x12 = x(1)*x(1);
x13 = x(1)*x12;
x22 = x(2)*x(2);
alpha = 10; %1 is not very stiff, 10 is The stiff function

p   = 10*alpha*(x13*x(1)-2*x12*x(2)+x22) + x12-2*x(1)+1;
if nargout>1
  p1  = [40*alpha*(x13-x(1)*x(2)) + 2*(x(1)-1);
         -20*alpha*(x12-x(2))];
  p2  = [120*x12-40*x(2) + 2, -40*x(1);
         -40*x(1),             20]*alpha;
end
