function flowchart_callback(handles,mode)
%FLOWCHART_CALLBACK Manage the Analysis GUI flowchart frame.
% This is a helper function called by Analysis. It manages the flowchart
% frame of the Analysis GUI.
% Inputs are the structure of handles (handles) and an optional mode:
%   'show' forces flowchart frame open ONLY
%   'hide' forces flowchart frame closed ONLY
% Otherwise, the call is considered an update call and will hide/show and
% update based on current GUI status.
%
%See also: ANALYSIS, FLOWCHART_UPDATE

%Copyright © Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%make sure the analysis figure we're going to be associated with exists
%(this sometimes gets called while Analysis is still being built, so ignore
%these calls until we're actually being called from the figure itself)

%handle force open/close calls
if nargin>1
  switch mode
    case 'hide'
      setappdata(handles.flowchart,'status','hide');
      hide_flowchart(handles);
      return
    
    case 'disable'
      setplspref('analysis','flowchart','hide');
      setappdata(handles.flowchart,'status','hide');
      hide_flowchart(handles);
      evritip('flowchartclose','Hint: Analysis flowchart has been closed and disabled. You can use the Help menu to Re-Open the Analysis Flowchart in the future.',2);
      return
    
    otherwise
      setappdata(handles.flowchart,'status','show');
  end
end

%get the list (if any exists)
if exist('flowchart_list') && ~strcmp(getappdata(handles.flowchart,'status'),'hide')
  list = flowchart_list(handles);
else
  list = {};  %force hide of flowchart
end
if isempty(list)
  %no list? 
  hide_flowchart(handles);
  return
end

show_flowchart(handles);

%Got a list, get position and set default values
pos = get(handles.flowchart,'position');
units = get(handles.flowchart,'units');
set(handles.flowchart,'BackgroundColor',[.97 .97 1]);
bh = getappdata(handles.flowchart,'handles');

%add "close" button
bsz = 15;
delete(findobj(handles.analysis,'tag','closeflowchart'));
uicontrol(handles.analysis,...
  'style','pushbutton',...
  'tag','closeflowchart',...
  'string','X',...
  'position',[pos(1)+pos(3)-bsz-1 pos(2)+pos(4)-bsz-1 bsz bsz],...
  'callback','flowchart_callback(guidata(gcbf),''disable'');');


%delete buttons which are no longer needed
if length(bh)>size(list,1);
  delete(bh(size(list,1)+1:end));
  bh = bh(1:size(list,1));
end

%add and update buttons
nbtns = size(list,1);
betweenpadding = 2;
toppadding = 3;
sidepadding = 8;
height = max(3,min(30,(pos(4)-betweenpadding*nbtns-toppadding*3)/nbtns));
for j=1:nbtns;
  %get button position
  bpos = [pos(1)+sidepadding pos(2)+pos(4)-toppadding-2-(j*height)-(j*betweenpadding) pos(3)-sidepadding*2 height];

  label     = list{j,1};
  enablecmd = list{j,2};
  callback  = list{j,3};

  %decide how this should look (depending on what the user has set in the
  %object)
  fontweight = 'normal';
  if ~isempty(callback)
    style = 'pushbutton';
    color = get(0,'defaultuicontrolbackgroundcolor');
  else
    style = 'text';
    color = get(handles.flowchart,'backgroundcolor');
    bpos(4) = bpos(4)-6*height/30;
    boldmark = findstr(label,'<b>');
    if ~isempty(boldmark)
      fontweight = 'bold';
      label(boldmark:boldmark+2) = [];
    end
  end

  %check enable status
  if isempty(enablecmd);
    stat = 1;
  else
    eval(['stat = ' enablecmd ';'],'stat=1;');
  end
  if stat;
    enb = 'on';
  else
    enb = 'off';
    color = get(handles.flowchart,'BackgroundColor')*.95;
  end
  
  %if we don't have a handle for this button position, create an object now
  if length(bh)<j || ~ishandle(bh(j));
    bh(j) = uicontrol(handles.analysis,...
      'units',units);
  end
  
  %assign values for new or existing object
  set(bh(j),...
    'backgroundcolor',color,...
    'style',style,...
    'position',bpos,...
    'string',label,...
    'enable',enb,...
    'fontweight',fontweight,...
    'horizontalalignment','center',...
    'fontsize',10,...
    'callback',callback...
    );
end

%store all handles
setappdata(handles.flowchart,'handles',bh);

%------------------------------------------------
function hide_flowchart(handles)

if strcmp(get(handles.flowchart,'visible'),'on');
  %was visible? hide frame now
  set(handles.flowchart,'visible','off');
  delete(findobj(handles.analysis,'tag','closeflowchart'));
  
  %delete any existing buttons
  bh = getappdata(handles.flowchart,'handles');
  delete(bh(ishandle(bh)));
  setappdata(handles.flowchart,'handles',[]);
  
  %and force redraw
  pos = get(handles.analysis,'position');
  fpos = get(handles.flowchart,'position');
  pos(3) = pos(3)-fpos(3);
  set(handles.analysis,'position',pos);
  
end

%------------------------------------------------
function show_flowchart(handles)

if strcmp(get(handles.flowchart,'visible'),'off');
  %was invisible? show frame now
  set(handles.flowchart,'visible','on');
  
  %and force redraw
  pos = get(handles.analysis,'position');
  fpos = get(handles.flowchart,'position');
  pos(3) = pos(3)+fpos(3);
  set(handles.analysis,'position',pos);

end

