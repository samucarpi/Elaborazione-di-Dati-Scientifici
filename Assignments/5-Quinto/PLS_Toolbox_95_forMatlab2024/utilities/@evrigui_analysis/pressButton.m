function out = pressButton(obj,parent,varargin)
%PRESSBUTTON Simulate pressing of the specified Toolbar button.
%I/O: .pressButton('buttonname')

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

h = findobj(findobj(parent.handle,'tag','AnalysisToolbar'),'tag',varargin{1});
if ~isempty(h)
  gcbo = h;
  if strcmp(get(h,'enable'),'on')
    callback = get(h,'ClickedCallback');
    eval(callback);
  end
end
out = 1;
