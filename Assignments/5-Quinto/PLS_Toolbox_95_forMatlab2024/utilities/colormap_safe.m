function colormap_safe(fig,varargin)
%COLORMAP_SAFE Call colormap with handles not hidden.
% Colormap doens't work properly in some instances when handles aren't
% visible. 
%
%See also: PLOTGUI

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

myhvis = get(fig,'handlevisibility');
set(fig,'handlevisibility','on');
cf = get(0,'currentfigure');
set(0,'currentfigure',fig);
try
  colormap(varargin{:});
catch
  le = lasterror;
  set(fig,'handlevisibility','callback');
  set(0,'currentfigure',cf);
  rethrow(le);
end
set(fig,'handlevisibility',myhvis);
set(0,'currentfigure',cf);
