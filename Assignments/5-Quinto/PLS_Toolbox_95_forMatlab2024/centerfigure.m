function varargout = centerfigure(fig,targfig)
%CENTERFIGURE Places a given figure into a centered default position.
% Given a figure handle, CENTERFIGURE positions the figure based on the
% height and width of the figure and the default figure position.
%
% If second input 'targfig' is given then CENTERFIGURE tries to place the
% fig centered on top of targfig.
%
%I/O: centerfigure(fig)
%I/O: centerfigure(fig,targfig)
%
%See also: POSITIONMANAGER

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%rsk 08/31/06 Add second input.

if nargin == 0; fig = 'io'; end
varargin{1} = fig;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin == 1 || isempty(targfig)
  dpos = get(0,'defaultfigureposition');
else
  tu = get(targfig, 'units');
  set(targfig,'units','pixels');
  dpos = get(targfig, 'position');
  set(targfig,'units',tu);
end
units = get(fig,'units');
set(fig,'units','pixels');
pos = get(fig,'position');
pos = [dpos(1)+dpos(3)/2-pos(3)/2 dpos(2)+dpos(4)-pos(4) pos(3:4)];
set(fig,'position',pos);
set(fig,'units',units);
