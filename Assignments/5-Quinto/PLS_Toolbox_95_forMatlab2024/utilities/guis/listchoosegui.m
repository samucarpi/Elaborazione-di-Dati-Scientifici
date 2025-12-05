function varargout = listchoosegui(varargin)
%LISTCHOOSEGUI Choose list items.
% Generic GUI for choosing and arranging list items.
%  INPUTS:
%    listone - All available items.
%    listtwo - Currently selected items (subset of listone).
%  OUTPUTS:
%    newlist   - Cell array of selected items in order.
%    btnpushed - ['ok'|'cancel'] Which button pused.
%
% NOTE: options not used yet.
%
%I/O: [newlist, btnpushed] = listchoosegui(list1)
%I/O: [newlist, btnpushed] = listchoosegui(list1,list2)
%I/O: [newlist, btnpushed] = listchoosegui(list1,list2,options) %Open gui and return gui handle.
%
%See also: ETABLE

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0 || ~ischar(varargin{1}) % LAUNCH GUI
  try
    
    %Get data if passed.
    if nargin<1
      error('LISTCHOOSEGUI requires at least one list input.')
    end
    
    %Parse inputs.
    myopts = [];
    listone = varargin{1};
    listtwo = [];
    if nargin > 1
      if isstruct(varargin{2})
        myopts = varargin{2};
      else
        listtwo = varargin{2};
      end
    end
    
    if nargin > 2;
      myopts = varargin{3};
    end
    
    myopts = reconopts(myopts,'listchoosegui');
    
    %Start GUI
    fig = figure('Tag','listchoosegui',...
      'NumberTitle', 'off', ...
      'HandleVisibility','callback',...
      'Integerhandle','off',...
      'Name', 'List Chooser',...
      'MenuBar','none',...
      'CloseRequestFcn','try;listchoosegui(''closereq_callback'',gcbo,[],guihandles(gcbf),0);catch;delete(gcbf);end',...
      'visible','off',...
      'Units','pixels');
    
    dotranspose = (size(listone,2)>1 & size(listone,1)==1);
    
    %make sure they are column vectors
    listone = listone(:);
    listtwo = listtwo(:);
    
    %Save data to appdata for gui_enable.
    setappdata(fig,'listone',listone);
    setappdata(fig,'listtwo',listtwo);
    
    %Set up gui controls.
    gui_enable(fig)
    
    %Position gui from last known position.
    positionmanager(fig,'listchoosegui');
    
    handles = guihandles(fig);
    fpos = get(handles.listchoosegui,'position');
    
    pause(.1);drawnow
    set(fig,'visible','on');
    
    uiwait(fig);

    %default is to assume "cancel" unless we find the GUI and pressed OK
    varargout{1} = listtwo;
    varargout{2} = 'cancel';
    if ishandle(fig) & getappdata(fig,'okpush')
      varargout{1} = getappdata(fig,'listtwo');
      varargout{2} = 'ok';
    end
    if dotranspose
      varargout{1} = varargout{1}(:)';  %force to be ROW vector (matches user input)
    end
    if ishandle(fig)
      delete(fig);
    end
  catch
    if ishandle(fig); delete(fig); end
    erdlgpls({'Unable to start the LISt CHOOSE GUI' lasterr},[upper(mfilename) ' Error']);
  end
  
else % INVOKE NAMED SUBFUNCTION OR CALLBACK
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = [];
        
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
      otherwise
        if nargout == 0;
          %normal calls with a function
          feval(varargin{:}); % FEVAL switchyard
        else
          [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
        end
    end
  catch
    if ~isempty(gcbf);
      set(gcbf,'pointer','arrow');  %no "handles" exist here so try setting callback figure
    end
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end
  
end

%--------------------------------------------------------------------
function varargout = gui_enable(fig)
%Initialize the the gui.

%Get handles and save options.
handles = guihandles(fig);
gopts = listchoosegui('options');

listone = getappdata(fig,'listone');
listtwo = getappdata(fig,'listtwo');

if isempty(listtwo)
  endstr = '<none>';
else
  endstr = '<end>';
end

%Get position.
figpos = get(fig,'position');
figcolor = [.92 .92 .92];
set(fig,'Color',figcolor);

%Set extra fig properties.
set(fig,'Toolbar','none')

%Add menu items.
% hmenu = uimenu(fig,'Label','&File','tag','menu_file');
%
% uimenu(hmenu,'tag','loaddatamenu','label','&Load Workspace Data','callback','listchoosegui(''loaddata'',gcbo,[],guidata(gcbf),''load'')');
% uimenu(hmenu,'tag','importdatamenu','label','&Import Data','callback','listchoosegui(''loaddata'',gcbo,[],guidata(gcbf),''import'')');
% uimenu(hmenu,'tag','loadmodelmenu','Separator','on','label','&Load Model','callback','listchoosegui(''loadmodel'',gcbo,[],guidata(gcbf))');
% uimenu(hmenu,'tag','savedatamenu','Separator','on','label','&Save Data','callback','listchoosegui(''save_callback'',gcbo,[],guidata(gcbf),''data'')');
% uimenu(hmenu,'tag','savemodelmenu','label','Save &Model','callback','listchoosegui(''save_callback'',gcbo,[],guidata(gcbf),''model'')');

fsz = getdefaultfontsize('normal');
fszh = getdefaultfontsize('heading');

%Add two list boxes.
uicontrol(fig,'style','listbox','tag','listone','units',...
  'normalized','position',[.01 .13 .34 .85],'tooltip','Available items.',...
  'string',listone,'BackgroundColor','white','fontsize',fsz,'max',2,'callback',@listoneclick);
uicontrol(fig,'style','listbox','tag','listtwo','units',...
  'normalized','position',[.51 .13 .34 .85],'tooltip','Selected items.',...
  'string',[listtwo;endstr],'value',length(listtwo)+1,'BackgroundColor','white','fontsize',fsz,'max',1,'callback',@listtwoclick);

%Add buttons, use tag name to find action
uicontrol(fig,'style','pushbutton','tag','rightone','units',...
  'normalized','position',[.38 .8 .1 .1],'tooltip','Add selected item/s.',...
  'string','>','FontSize',fszh,'Fontweight','bold',...
  'callback','listchoosegui(''mvbutton_Callback'',gcbo,[],guidata(gcbf))');
uicontrol(fig,'style','pushbutton','tag','rightall','units',...
  'normalized','position',[.38 .68 .1 .1],'tooltip','Add all items.',...
  'string','>>','FontSize',fszh,'Fontweight','bold',...
  'callback','listchoosegui(''mvbutton_Callback'',gcbo,[],guidata(gcbf))');
uicontrol(fig,'style','pushbutton','tag','leftone','units',...
  'normalized','position',[.38 .56 .1 .1],'tooltip','Remove selected item/s.',...
  'string','<','FontSize',fszh,'Fontweight','bold',...
  'callback','listchoosegui(''mvbutton_Callback'',gcbo,[],guidata(gcbf))');
uicontrol(fig,'style','pushbutton','tag','leftall','units',...
  'normalized','position',[.38 .44 .1 .1],'tooltip','Remove all items.',...
  'string','<<','FontSize',fszh,'Fontweight','bold',...
  'callback','listchoosegui(''mvbutton_Callback'',gcbo,[],guidata(gcbf))');

uicontrol(fig,'style','pushbutton','tag','up','units',...
  'normalized','position',[.87 .8 .1 .1],'tooltip','Move item up in list.',...
  'string','Up','FontSize',fsz,'Fontweight','normal',...
  'callback','listchoosegui(''mvbutton_Callback'',gcbo,[],guidata(gcbf))');
uicontrol(fig,'style','pushbutton','tag','down','units',...
  'normalized','position',[.87 .68 .1 .1],'tooltip','Move item down in list.',...
  'string','Down','FontSize',fsz,'Fontweight','normal',...
  'callback','listchoosegui(''mvbutton_Callback'',gcbo,[],guidata(gcbf))');

uicontrol(fig,'style','pushbutton','tag','ok','units',...
  'normalized','position',[.57 .01 .2 .09],'tooltip','Return selected items.',...
  'string','OK','FontSize',fsz,'Fontweight','normal',...
  'callback','listchoosegui(''mvbutton_Callback'',gcbo,[],guidata(gcbf))');
uicontrol(fig,'style','pushbutton','tag','cancel','units',...
  'normalized','position',[.79 .01 .2 .09],'tooltip','Cancel.',...
  'string','Cancel','FontSize',fsz,'Fontweight','normal',...
  'callback','listchoosegui(''mvbutton_Callback'',gcbo,[],guidata(gcbf))');

handles = guihandles(fig);
guidata(fig,handles);

%--------------------------------------------------------------------
function closereq_callback(h,eventdata,handles,varargin)
%Close gui.

if isempty(handles)
  handles = guihandles(h);
end

%Save figure position.
positionmanager(handles.listchoosegui,'listchoosegui','set')

if ishandle(handles.listchoosegui)
  delete(handles.listchoosegui)
end

%--------------------------------------------------------------------
function mvbutton_Callback(h,eventdata,handles,varargin)
%Button callback.
mybtn = get(h,'tag');

listone = getappdata(handles.listchoosegui,'listone');
listtwo = getappdata(handles.listchoosegui,'listtwo');

oneval = get(handles.listone,'value');
twoval = get(handles.listtwo,'value');
myidx = 1:length(listtwo);

myresume = 0;
switch(mybtn)
  case 'rightone'
    if ~isempty(listtwo)
      toadd = listone(oneval);
      toremove = ismember(listtwo,toadd);  %items in list 2 we're adding again
      listtwo(toremove) = [];
      twoval = findindx([myidx(~toremove) myidx(end)+1],twoval);  %new insert point
      listtwo = [listtwo(1:twoval-1); toadd; listtwo(twoval:end)];
      twoval = twoval+length(toadd)-1;
    else
      listtwo = listone(oneval);
    end
    set(handles.listone,'value',min(length(listone),max(oneval)+1))
    twoval = max(twoval)+1;
  case 'rightall'
    listtwo = listone;
  case 'leftone'
    if ~isempty(listtwo)
      listtwo = listtwo(setdiff(myidx,twoval));
    end
  case 'leftall'
    listtwo = [];
  case {'up' 'down'}
    if ~isempty(listtwo)
      if strcmp(mybtn,'up')
        newval = max(1,twoval-1);
      else
        newval = min(length(listtwo),twoval+1);
      end
      tmp = listtwo;
      listtwo(newval) = tmp(twoval);
      listtwo(twoval) = tmp(newval);
      twoval = newval;
    end
  case 'ok'
    setappdata(handles.listchoosegui,'okpush',1)
    myresume = 1;
  case 'cancel'
    listtwo = [];
    myresume = 1;
end

twoval = max(1,min(twoval,length(listtwo)+1));
setappdata(handles.listchoosegui,'listtwo',listtwo);
if isempty(listtwo)
  endstr = '<none>';
else
  endstr = '<end>';
end
set(handles.listtwo,'string',[listtwo; endstr],'value',twoval);

if myresume
  uiresume(handles.listchoosegui);
end

%----------------------------------------------
function listoneclick(varargin)

fig = gcbf;
handles = guidata(fig);
if strcmpi(get(fig,'selectiontype'),'open')
  val = get(handles.listone,'value');
  mvbutton_Callback(handles.rightone,[],handles)
  set(handles.listone,'value',val);  %move cursor back to double-clicked item
end

%----------------------------------------------
function listtwoclick(varargin)

fig = gcbf;
handles = guidata(fig);
if strcmpi(get(fig,'selectiontype'),'open')
  mvbutton_Callback(handles.leftone,[],handles)
end

