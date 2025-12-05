function varargout = showposition(fig,intflag)
%SHOWPOSITION Display the cursor's position on the current axes
% Set as a windowbuttonmotion callback to show the current cursor position
% as moving text boxes on the axes.
% Call with second input 'delete' to remove text boxes
%
%I/O: showposition(fig,intflag)
%I/O: showposition(fig,'delete')

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0; fig = 'io'; end
if isstr(fig)
  options = [];
  if nargout==0; evriio(mfilename,fig,options); else; varargout{1} = evriio(mfilename,fig,options); end
  return;
end

if nargin<1;
  fig = gcf;
end
if nargin<2;
  intflag = 1;
end

hs = getappdata(fig,'axismarkers');

if strcmp(intflag,'delete');
  delete(hs(ishandle(hs)));
  return
end

ax = axis;
fullax = ax;
mpos = get(gca,'currentpoint');
x = mpos(1,1);
y = mpos(1,2);

%keep on-axes
if intflag
  %show as integer position
  x = round(x);
  y = round(y);
  
  ax([1 3]) = ceil(ax([1 3]));
  ax([2 4]) = floor(ax([2 4]));
end
%keep on-axes
x = min(ax(2),max(ax(1),x));
y = min(ax(4),max(ax(3),y));

%X-axis label
pos = [x fullax(4) 0];
if isempty(hs) | ~ishandle(hs(1));
  h   = text(pos(1),pos(2),num2str(x));
  set(h,'backgroundColor',[.9 .9 .9],'horizontalalignment','center')
else
  h = hs(1);
end
ext = get(h,'extent');
pos = pos + [-ext(3)/2 -ext(4)/2 0];
set(h,'string',num2str(x),'position',pos)
hs(1) = h;

%Y-axis label
pos = [fullax(2) y 0];
if length(hs)<2 | ~ishandle(hs(2));
  h = text(pos(1),pos(2),[' ' num2str(y)]);
  set(h,'horizontalalignment','left')
  set(h,'backgroundColor',[.9 .9 .9])
else
  h = hs(2);
end
ext = get(h,'extent');
pos = pos + [0 0 0];
set(h,'string',num2str(y),'position',pos);
hs(2) = h;

setappdata(fig,'axismarkers',hs)
  
