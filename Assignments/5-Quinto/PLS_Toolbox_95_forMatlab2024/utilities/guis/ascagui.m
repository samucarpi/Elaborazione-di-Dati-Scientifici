function varargout = ascagui(varargin)
% ASCAGUI Gui objects for asca panel.

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~isempty(varargin) && ischar(varargin{1})
  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
    if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return;
  end

  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
else
  fig = openfig(mfilename,'new');

  if nargout > 0;
    varargout = {fig};
  end
end

%--------------------------------------------------------------------
function panelinitialize_Callback(figh, frameh, varargin)
%Initialize panel objects.

handles = guihandles(figh);

panelresize_Callback(figh, frameh, varargin)
panelupdate_Callback(figh, frameh, varargin)

%--------------------------------------------------------------------
function  panelupdate_Callback(figh, frameh, varargin)
%Update controls in panel.

handles = guihandles(figh);
myobj = evrigui(handles.analysis);

opts = getappdata(handles.analysis, 'analysisoptions');
cura = getappdata(handles.analysis,'curanal');%Current analysis.

if isempty(opts) | ~strcmpi(opts.functionname,cura)
  opts = feval(cura,'options');
  opts.display       = 'off';
  opts.plots         = 'none';
  setappdata(handles.analysis, 'analysisoptions',opts);
end

set([handles.mlsca_radio handles.asca_radio],'value',0);

if strcmp(cura,'mlsca')
  set([handles.interactions handles.nopermutation handles.nocenterpoints],'enable','off')
  set([handles.mlsca_radio],'value',1);
else
  set(handles.nopermutation,'string',num2str(opts.npermutations));
  set([handles.asca_radio],'value',1);
  %Contrast {'contributions' 'spectra' 'auto' ''}, don't use auto.
  myinters = opts.interactions;
  if isempty(myinters)
    myinters = 0;
  end
  
  switch myinters
    case 0
      %If auto set to off.
      set(handles.interactions,'value',1);
    case 1
      set(handles.interactions,'value',2);
    case 2
      set(handles.interactions,'value',3);
    case 3
      set(handles.interactions,'value',4);
  end
  
  %No Center Points.
  if strcmp(opts.nocenterpoints,'on')
    set(handles.nocenterpoints,'value',1)
  else
    %No
    set(handles.nocenterpoints,'value',2)
  end
  
  %Check for using custom interactions.
  if isfield(opts,'interactions_custom') & ~isempty(opts.interactions_custom)
    %Disable interactions.
    set(handles.interactions,'enable','off');
  end
end

%--------------------------------------------------------------------
function panelresize_Callback(figh, frameh, varargin)
% Resize specific to panel manager. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);
myctrls = findobj(figh,'userdata','ascagui');
set(myctrls,'units','pixels','fontsize',getdefaultfontsize);

%Column widths.
w1 = 190;
w2 = 160;
w4 = 60;
w5 = w1+w2+30;

%Height
ht = 20;

%If using higher dpi then bump up size.
if get(0,'ScreenPixelsPerInch')>100
  w1 = 196;
  ht = 24;
  w5 = w1+w2+30;
end

%Move rest of controls to upper left of frame.
frmpos = get(frameh,'position');%[left bottom width height]

newbottom = (frmpos(2)+frmpos(4)-(round(1.5*ht)));
newleft1 = (frmpos(1)+10);
newleft2 = (newleft1+5+w1+4);

set(handles.asca_radio,'position',[newleft1 newbottom w1+w2 ht]);
newbottom = newbottom-32;
set(handles.mlsca_radio,'position',[newleft1 newbottom w1+w2 ht]);
set(handles.frame3,'position',[8 newbottom-8 w5 ht*2+26]);
newbottom = newbottom-34;

set(handles.text1,'position',[newleft1 newbottom w1 ht]);
set(handles.nopermutation,'position',[newleft2 newbottom w2 ht]);
set(handles.frame2,'position',[8 newbottom-6 w5 ht+10]);

newbottom = newbottom-34;
set(handles.text2,'position',[newleft1 newbottom w1 ht]);
set(handles.interactions,'position',[newleft2 newbottom w2 ht]);
%Custom not used.
set(handles.custom,'position',[newleft2+w2 newbottom w4 ht],'visible','off');

newbottom = newbottom-34;
set(handles.text3,'position',[newleft1 newbottom w1 ht]);
set(handles.nocenterpoints,'position',[newleft2 newbottom w2 ht]);
set(handles.frame1,'position',[8 newbottom-10 w5 ht*4-4]);

newbottom = newbottom-34;
set(handles.helpbtn,'position',[newleft2 newbottom w2 ht]);

%--------------------------------------------------------------------
function panelblur_Callback(varargin)

%--------------------------------------------------------------------
function control_Callback(hObject, eventdata, handles)
%Callback for all controls.
handles = guihandles(handles.analysis);
opts = getappdata(handles.analysis, 'analysisoptions');

mytag = get(hObject,'tag');

switch mytag
  case 'nopermutation'
    %Number of permutations.
    myval = str2num(get(handles.nopermutation,'string'));
    if myval<0
      myval = 0;
      set(handles.nopermutation,'string','0')
    end
    
    opts.npermutations = myval;

  case 'interactions'
    myval = get(hObject,'value');
    switch myval
      case 1
        %None.
        opts.interactions = [];
      case 2
        opts.interactions = 1;
      case 3
        opts.interactions = 2;
      case 4
        opts.interactions = 3;
    end
  case 'nocenterpoints'
    %Remove center points.
    myval = get(hObject,'value');
    if myval==1
      opts.nocenterpoints =  'on';
    else
      opts.nocenterpoints =  'off';
    end
  case 'custom'
    %Get Y and open custom interactions interface.
    y = analysis('getobjdata','yblock',handles);
    if isempty(y)
      evriwarndlg('Y-Block data is needed to define custom interactions. Load Y block.','No Y-Block')
      return
    end
    
    [yint,column_ID] = doeinteractions(y, 3);
    %Grab labels and column ids and put into quick GUI.
    customint = getcutomid(yint.label{2},column_ID);
    
end

analysis('setopts',handles,'asca',opts)
change_options(handles)

%--------------------------------------------------------------------
function out = change_options(handles)
%ASCA Option has been changed so check to see if need to clear all models.

%Code from analysis/editoptions callback.
statmodl = getappdata(handles.analysis,'statmodl');
if ~strcmp(statmodl,'none')
  %Clear model without prompting.
  analysis('clearmodel',handles.analysis, [], handles, []);
end

%--------------------------------------------------------------------
function helpbtn_Callback(hObject, eventdata, handles)
% Open HTML help page.
evrihelp(getappdata(handles.analysis,'curanal'));

%--------------------------------------------------------------------
function custom_Callback(hObject, eventdata, handles)
% Not used right now.

%--------------------------------------------------------------------
function out = getcutomid(mylbls,colmids)
%Make small gui for custom interations.
out = [];

fig = figure('Tag','customidgui',...
  'NumberTitle', 'off', ...
  'HandleVisibility','callback',...
  'Integerhandle','off',...
  'Name', 'Custom Iterations',...
  'Renderer','OpenGL',...
  'MenuBar','none',...
  'visible','on',...
  'Units','pixels');

colstr = {};
for i = 1:length(colmids)
  colstr = [colstr; {sprintf('%d ',colmids{i})}];
end

tdata = [str2cell(mylbls) colstr repmat({false},length(colstr),1)];
%Add blank table.
mytbl = etable('parent_figure',fig,'tag','cutominteractions_table','autoresize','AUTO_RESIZE_SUBSEQUENT_COLUMNS',...
  'column_sort','off','column_labels',{'Interaction Name' 'Column Indices' 'Use'},...
  'data',tdata);
mytbl.column_format = {'%s' '%s' 'bool'};
mytbl.units = 'normalized';
mytbl.position = [0 .1 1 .89];

okbtn = uicontrol(fig,'style','pushbutton','tag','savebutton','String','Save',...
  'units','normalized','position',[.57 .01 .14 .07],'Callback','ascagui(''customgui_Callback'',gcbo,[],guidata(gcbo))');
cnslbtn = uicontrol(fig,'style','pushbutton','tag','clearbutton','String','Clear',...
  'units','normalized','position',[.71 .01 .14 .07],'Callback','ascagui(''customgui_Callback'',gcbo,[],guidata(gcbo))');
cnslbtn = uicontrol(fig,'style','pushbutton','tag','cancelbutton','String','Close',...
  'units','normalized','position',[.85 .01 .14 .07],'Callback','close(gcbf)');

setappdata(fig,'table',mytbl);

%--------------------------------------------------------------------
function customgui_Callback(hObject, eventdata, handles)
%Callback for all controls.

mystr = get(hObject,'String');
fig = ancestor(hObject,'figure');
mytbl = getappdata(fig,'table');

switch mystr
  case 'Clear'
    mydat = mytbl.data;
end

%--------------------------------------------------------------------
function asca_radio_Callback(hObject, eventdata, handles)
% Change current analysis to asca.
handles = guihandles(handles.analysis);
set(handles.mlsca_radio,'value',0);
mymenu = findobj(handles.analysis,'tag','asca');
analysis('enable_method',mymenu(1),[],handles);


%--------------------------------------------------------------------
function mlsca_radio_Callback(hObject, eventdata, handles)
% Change current analysis to mlsca.
handles = guihandles(handles.analysis);
set(handles.asca_radio,'value',0);
mymenu = findobj(handles.analysis,'tag','mlsca');
analysis('enable_method',mymenu(1),[],handles);
