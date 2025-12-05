function out = setMarkers(obj,parent,varargin)
%SETMARKERS Assigns markers model being used by TrendTool.
%I/O: .setMarkers(markers)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

if isempty(varargin{1});
  clearMarkers(obj,parent);
else
  trendmarker('loadmarkers',parent.handle,varargin{1});
end
out = 1;  

