function out = getButtons(obj,parent,varargin)
%GETBUTTONS Returns list of toolbar buttons currently available on GUI.
%I/O: .getButtons

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

h = findobj(parent.handle,'tag','AnalysisToolbar');
out = {};
if ~isempty(h)
  out = get(get(h,'children'),'tag');
  if iscell(out)
    out = fliplr(out(:)');
  else
    out = {out};
  end
end
