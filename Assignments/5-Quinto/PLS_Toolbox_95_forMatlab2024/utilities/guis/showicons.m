function icon = showicons(iconfile)
%SHOWICONS Creates clickable display of all available icons from 'iconfile'.
% Click on an icon to get the name which can be used to use that icon on a
% toolbar. See toolbar for more information on how to create a custom
% toolbar.
%
%I/O: showicons
%I/O: icon = showicons
%
%See also: GETTBICONS TOOLBAR TOOLBAR_BUTTONSETS

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  iconfile = 'tbimg7.mat';
end

icons = load(iconfile);
names = fieldnames(icons);

fh = figure('name','Please Wait...','menu','none','toolbar','none','integerhandle','off','numbertitle','off');

if nargout==0
  fm = uicontextmenu('Callback',@cmenu);
  m1 = uimenu(fm, 'Label', 'Name: ', 'tag', 'name');
  m2 = uimenu(fm, 'Label', 'Save as PNG', 'tag', 'savepng','Callback',{@savepng,iconfile});
else
  set(fh,'windowStyle','modal');
  fm = [];
end
set(fh,'pointer','watch');
drawnow;

number = length(names);
r=fix(number./ceil(sqrt(number))+.999);
c=ceil(sqrt(number));

for j=1:length(names);
  subplot(r,c,j);
  h = imagesc(icons.(names{j}));
  set(h,'userdata',names{j},'uicontextmenu',fm);
  if nargout>0
    set(h,'buttondownfcn','setappdata(gcbf,''iconname'',get(gcbo,''userdata'')); uiresume(gcbf);');
  end
  axis image
  axis off
  set(gca,'units','pixels');
  pos = get(gca,'position');
  set(gca,'position',[pos(1:2) size(icons.(names{j}),1) size(icons.(names{j}),1)]);
end
set(fh,'pointer','arrow');
if nargout==0
  set(fh,'name','RIGHT_CLICK To See Icon Name');
else
  set(fh,'name','Click Icon to Select');
end
drawnow;

if nargout>0
  uiwait(fh);
  if ishandle(fh)
    icon = getappdata(fh,'iconname');
    close(fh);
  else
    icon = [];
  end
end
    
%------------------------------------------------
function [hbtnsdef] = cmenu(hObj,varargin)
%Context menu callback. Put current name in menu item.

ih = get(gca,'Children');
name = get(ih,'Userdata');
set(findobj(get(ih,'uicontextmenu'),'tag','name'),'Label',['Name: ' name])

%------------------------------------------------
function [hbtnsdef] = savepng(hObj,varargin)
%Save current image as PNG.

ih = get(gca,'Children');
name = get(ih,'Userdata');
icons = load(varargin{2});

[FileName,PathName,FilterIndex] = evriuiputfile('*.*','Save Icon as PNG',[name '.png']);

if FileName~=0
  imwrite(icons.(name),fullfile(PathName,FileName));
end
