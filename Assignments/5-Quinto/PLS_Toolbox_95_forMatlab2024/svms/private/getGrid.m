function [x,y] = getGrid(mx, my)
%GETGRID Generate vectors x and y of coordinates of points in an mx-by-my grid
% x varies from 0 to mx-1; y varies from 0 to my-1.
%
% %I/O: [x y] = convertToLibsvmArgNames(mx, my); Generate x and y vectors

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

z = 0:(mx*my-1);
x = mod(z,mx);
y = floor(z/mx);
