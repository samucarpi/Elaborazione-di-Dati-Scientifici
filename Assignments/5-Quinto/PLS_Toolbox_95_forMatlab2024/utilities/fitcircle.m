function [xc,a,b] = fitcircle(x)
%FITCIRCLE fits circles (and spheres) to x,y (and z) data;
%  For x,y data FITCIRCLE finds the circle center (xc) and radius (a) that
%  fits the equation:
%    (x(:,1) - xc(1))^2 + (x(:,2) - xc(2))^2 = a^2
%  Parameters for a sphere can also be found.
%
%  INPUTS:
%      x = Mx2 data for a circle (class double)
%
%  OUTPUTS:
%     xc = 1x2 circle center (class double)
%      a = 1x1 circle radius.
%
%Example: circles
%  t  = (0:0.1:2*pi+0.1)';
%  a  = 5;
%  x  = a*[cos(t)+1.5, sin(t)-2];
%  [xc,a] = fitcircle(x);
%  figure, plot(x(:,1),x(:,2),'-'); grid, axis equal
%  vline(xc(1),'r'), hline(xc(2),'r'), hold on
%  plot([0 a]+xc(1),[0 0]+xc(2),'b')
%
%Example: spheres
%  [x,y,z] = sphere(20);                       %creates data
%  [xc,a] = fitcircle([x(:),y(:),z(:)]);
%  [xc,a] = fitcircle([x(:)+1,y(:)+2,z(:)+3]);
%
%I/O: [xc,a] = fitcircle(x);

% Copyright © Eigenvector Research, Inc. 2020
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

m       = size(x);
y       = sum(x.^2,2);
[x,xn]  = normaliz([x';ones(1,m(1))]); x = x';
xn(xn<1e-6) = 1e-6;                            % regularize
b       = x\y;
b       = b'*diag(1./xn);
xc      = b(1:m(2))/2;
a       = sqrt(b(end)+sum(xc.^2));

