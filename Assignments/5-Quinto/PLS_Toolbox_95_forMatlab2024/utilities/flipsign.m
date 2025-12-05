function [x,signflip] = flipsign(x)
%FLIPSIGN Make the columns of x positive (or mostly positive).
%
%I/O: [x,signflip] = flipsign(x);
%
%See also:

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

signflip = sign(sum(x.^3));
signflip(signflip==0) = 1;
x        = x*diag(signflip);
