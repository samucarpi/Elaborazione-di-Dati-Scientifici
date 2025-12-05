function [xx,yy] = hliner(n)
%HLINER hline with ginput
%
%  Optional Input:
%    n = number of horizontal lines to draw.
%
%I/O: [xx,yy] = hliner(n);
%
%See also: HLINE, VLINER, GINPUT

%Copyright Eigenvector Research, Inc. 2018
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  n     = 1;
end

[xx,yy] = ginput(n);
set(hline(yy,'r'),'linewidth',0.5)
if nargout==0
  clear xx yy
end
