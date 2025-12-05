function [out,ok] = evricommentdlg(Prompt, Title, Content)
%EVRICOMMENTDLG Expanded dialog box for large comments.
%  Uses large edit box with multiline enabled to allow longer input for
%  comments. Third input is optional default content for edit box.
%  First output (out) is the comments provided by user. Second output (ok)
%  is a flag indicating if the user clicked OK or Cancel (0 = cancel).
%
%I/O: [out,ok] = evricommentdlg(Prompt, Title, Content)
%
%See Also: INFOBOX

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


if nargin == 1 && ismember(Prompt,evriio([],'validtopics'))
  options = [];
  if nargout==0; 
    evriio(mfilename,Prompt,options);  
  else
    out = evriio(mfilename,Prompt,options);
  end
  return;
end

if inevriautomation
  %in automation, skip message
  if nargout>0
    out = '';
  end
  return
end

if nargin<1
  error('Requires at least one input.')
end

if nargin<2
  Title = 'EVRI Comment Dialog';
end

if nargin<3
  Content = '';
end

fig = figure('tag','evri_comment_dlg',...
  'name',Title,...
  'MenuBar','none',...
  'NumberTitle','off',...
  'Toolbar','none',...
  'windowstyle','modal',...
  'ResizeFcn',@comment_resize,...
  'Units','pixels');

cmt_label = uicontrol('style','text',...
  'tag','cmt_label',...
  'string',Prompt,...
  'HorizontalAlignment','left',... 
  'BackgroundColor',get(fig,'Color'),...
  'FontSize',12);

cmt_edit = uicontrol('style','edit',...
  'tag','cmt_edit',...
  'string',Content,...
  'HorizontalAlignment','left',...
  'BackgroundColor','white',...
  'max',2,...
  'min',0,...
  'FontSize',12);

cmt_ok = uicontrol('style','pushbutton',...
  'tag','cmt_ok',...
  'callback',@btn_callback,...
  'string','OK');

cmt_cancel = uicontrol('style','pushbutton',...
  'tag','cmt_cancel',...
  'callback',@btn_callback,...
  'string','Cancel');
drawnow

figpos = getnicedialoglocation([0 0 400 200],'pixels');
set(fig,'position',figpos);

if ishandle(fig)
  uiwait(fig);
end

out = '';
ok = false;
if ishandle(fig);
  if strcmp(get(fig,'UserData'),'OK'),
    out=get(cmt_edit,'string');
    ok = true;
  end
  delete(fig);
end

%----------------------
function comment_resize(obj, evt)
%Resize callback.
handles = guihandles(obj);

if ~isfield(handles,'cmt_label')
  %Controls not created yet.
  return
end

figpos = get(handles.evri_comment_dlg,'position');

set(handles.cmt_label,'position',[4 figpos(4)-24 figpos(3)-8 20]);
set(handles.cmt_edit,'position',[4 34 figpos(3)-8 figpos(4)-58]);
set(handles.cmt_ok,'position',[figpos(3)-208 4 100 30]);
set(handles.cmt_cancel,'position',[figpos(3)-104 4 100 30]);

%----------------------
function btn_callback(obj, evt)
%Button callback.

handles = guihandles(obj);
if strcmp(get(obj,'tag'),'cmt_ok')
  set(handles.evri_comment_dlg,'UserData','OK');
  uiresume(handles.evri_comment_dlg);
else
  delete(handles.evri_comment_dlg)
end

%----------------------
function figure_size = getnicedialoglocation(figure_size, figure_units)
% Matlab code for putting figure in centered position.

parentHandle = gcbf;
if ~isempty(parentHandle)
  old_u = get(parentHandle,'Units');
  set(parentHandle,'Units',figure_units);
  container_size=get(parentHandle,'Position');
  set(parentHandle,'Units',old_u);
else
  container_size = getscreensize(figure_units);
end

figure_size(1) = container_size(1)  + 1/2*(container_size(3) - figure_size(3));
figure_size(2) = container_size(2)  + 2/3*(container_size(4) - figure_size(4));
