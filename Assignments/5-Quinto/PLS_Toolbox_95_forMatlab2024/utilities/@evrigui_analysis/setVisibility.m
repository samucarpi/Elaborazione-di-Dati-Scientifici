function out = setVisibility(obj,parent,varargin)
%SETVISIBILITY Sets the GUI visibility (0 = invisible, 1 = visible)
%I/O: .setVisibility(vis)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

if varargin{1}
  set(parent.handle,'visible','on')
else
  set(parent.handle,'visible','off');
end
out = true;
