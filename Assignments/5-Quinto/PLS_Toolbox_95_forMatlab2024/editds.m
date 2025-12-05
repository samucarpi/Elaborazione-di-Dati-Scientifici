function varargout = editds(varargin)
%EDITDS Editor for DataSet Objects.
% Optional input (dataset) is the DataSet object to edit
%
% Additional keywords and properties can be included on creation
% controlling various properties of the created editor:
%    'invisible'             = make figure invisible
%    'noharddelete'          = do not permit hard-delete on data
%    'asraw'                 = edit data as a raw matrix (no labels, etc)
%    'allowedmodes',[modes]  = specify allowable tabs (-1 = info, 0 =
%                               data, 1-n = mode labels)
%    'editfields',[1 1 1 1]  = specify which fields on label modes are editable
%    'mode',[0]              = specify which tab is selected on startup
%    'toolbar',{toobarspecs} = add specified toolbar to image (replaces
%                               default toolbar)
%    'position',[left bottom width height]   = set figure position
%
% Output (h) is the handle to editds figure.
%
%I/O: h = editds(dataset)
%I/O: h = editds(dataset,keyword,...,property,value,...)
%I/O: h = editds(command,fig,auxdata)
%
%See also: PLOTGUI

% Copyright © Eigenvector Research, Inc. 2003
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%jms 7/2003
%jms 6/04 -fixed 7.0 incompatiblity w/name box
%rsk 09/20/04 Add image loading for MIA Toolbox.
%rsk 07/15/05 Add Mac workarounds.
%rsk 01/12/06 -Fix load new data mode change bug.
%             -Fix load new data nrows bug.
%             -Fix info tab controls drift bug.
%rsk 01/26/06 -Fix menu disappear on modal figure restore.
%rsk 05/01/06 -Fix permute (jeremy add), permute orginal data.

if nargin < 2 | ~ischar(varargin{1})
  
  if nargin == 1 & isstr(varargin{1})
    options             = [];
    options.forcerenderer = '';
    options.linkselections = true;
    options.dataformat = '0.8g';
    options.axisscaleformat = '0.6g';
    if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return;
  end
  
  %If single input and shareddata then look for existing figure.
  if ~isempty(varargin) & isshareddata(varargin{1}) & isvalid(varargin{1}) & ~isempty(varargin{1}.links)
    mylinks = varargin{1}.links;
    for i = 1:length(mylinks)
      if ishandle(mylinks(i).handle) & strcmpi(get(mylinks(i).handle,'tag'),'editds')
        figure(mylinks(i).handle);
        return
      end
    end
  end
  
  %various default settings
  allowedmodes = [];
  forceposition = [];
  keepinvisible = false;
  opencmds = {'invisible'};
  editfields = {};
  addtoolbar = {
    'plot'       'dseplotdata'        'editds(''viewplot'',gcbf,[],guidata(gcbf))'         'enable' 'View Plot of Data'    'off' 'push'
    'save'       'dsesavedata'        'editds(''menu'',gcbo,[],guidata(gcbf))'         'enable' 'Save Data'    'on' 'push'
    'Deselect'   'dsedeselect'        'editds(''menu'',gcbo,[],guidata(gcbf))'         'enable' 'Deselect All'    'on' 'push'
    'shuffle'    'dseshuffle'         'editds(''menu'',gcbo,[],guidata(gcbf))'         'enable'  'Shuffle Data' 'on' 'push'
    'unshuffle'  'dseundoshuffle'     'editds(''menu'',gcbo,[],guidata(gcbf))'         'disable'  'Undo Shuffle'   'off' 'push'
   };
 
  noharddelete = false;
  asraw = false;
  mode = 0;
  
  %search through inputs for keywords and options
  j = 1;
  while j<nargin
    j=j+1;
    if ~ischar(varargin{j})
      continue;
    end
    switch varargin{j}
      case 'position'
        if nargin==j
          error('Missing value for last option');
        end
        forceposition = varargin{j+1};
        j=j+1;
        
      case 'invisible'
        %keyword "invisible" opens editor invisibily
        keepinvisible = true;
        
      case 'allowedmodes'
        if nargin==j
          error('Missing value for last option');
        end
        allowedmodes = varargin{j+1};
        j=j+1;  %skip over value
        
      case 'editfields'
        if nargin==j
          error('Missing value for last option');
        end
        editfields = varargin{j+1};
        j=j+1;  %skip over value
        
      case 'mode'
        if nargin==j
          error('Missing value for last option');
        end
        mode = varargin{j+1};
        j=j+1;  %skip over value
        
      case 'noharddelete'
        noharddelete = true;
        
      case 'asraw'
        asraw = true;
        
      case 'toolbar'
        if nargin==j
          error('Missing value for last option');
        end
        addtoolbar = varargin{j+1};
        j=j+1;  %skip over value
    end
  end
  
  %Open figure and initialize
  fig = openfig('editds.fig','new',opencmds{:});
  if ispc & checkmlversion('>=','7.3') & (~isempty(findstr(system_dependent('getos'),'Windows 2000')) | ~isempty(findstr(system_dependent('getos'),'Vista')))
    %force painters renderer if VISTA (or vista-like) and 2006b or later
    set(fig,'renderer','painters');
  end
  
  editdsoptions = editds('options');
  forcerenderer = editdsoptions.forcerenderer;
  if ~isempty(forcerenderer)
    set(fig,'renderer',forcerenderer);
  end
  setappdatas(fig,...
    'linkselections',editdsoptions.linkselections,...
    'dataformat',editdsoptions.dataformat,...
    'axisscaleformat',editdsoptions.axisscaleformat...
    );
  
  if isempty(forceposition)
    positionmanager(fig,'editds');
    resize(fig,[],guihandles(fig));
  else
    set(fig,'position',forceposition);
  end
  
  if ~keepinvisible
    set(fig,'visible','on');
  end
  
  filemenubuild(guihandles(fig));
  figbrowser('addmenu',fig);
  set(fig,'color',get(fig,'color')*.8);
  set(fig,'handlevisibility','callback');
  if ~isempty(addtoolbar)
    try
      toolbar(fig,'',addtoolbar,'customtoolbar');
    catch
      erdlgpls({'Unable to add specified toolbar to GUI' lasterr},'Toolbar Invalid')
    end
  end
  
  set(fig,'closerequestfcn',['try;' get(fig,'closerequestfcn') ';catch;delete(gcbf);end'])
  set(fig,'deletefcn','');
  
  set(fig,'resize','on');
  set(fig,'resizefcn','editds(''resize'',gcbf,[],guidata(gcbf))');
  setappdata(fig,'figuretype','EditDS');
  setappdata(fig,'noedit',0);
  
  if ~ispc;  %mod to fix menus on MAC
    uicontextmenu = [findobj(fig,'tag','labelmenu') findobj(fig,'tag','colrowmenu')];
    uicb = ['set(gcbo, ''Position'',get(gcf,''CurrentPoint'')); set(gcbo,''Visible'', ''on''); ' get(uicontextmenu(1),'callback')];
    set(uicontextmenu,'Callback',uicb);
  end
  
  handles = guihandles(fig);
  guidata(fig,handles);
  myname = '';
  
  %add customizable open-in menu:
  set(handles.fileopenanalysis,'label','&Open In','callback','');
  sendto(handles.fileopenanalysis,'editds(''filesendto'',gcbf)');

  if nargin >= 1;
    data = varargin{1};
    if isshareddata(data)
      %Using shared data.
      myid = data;
      data = myid.object;
      if ~isa(data,'dataset')
        error('Unable to edit supplied object');
      end
      linkshareddata(myid,'add',fig,'editds');
      myname = myid.properties.name;
      setdataset(fig,myid);
    elseif isa(data,'dataset');
      %standard dataset object
      myname = inputname(1);
      setdataset(fig,data);
    elseif prod(size(data))==1 & isa(data,'double') & ishandle(data)
      %old-fashioned object handle passed
      error('Handle passed to DSE.');
    else
      %something other than a dataset or link, try to make it one
      data = dataset(data);
      setdataset(fig,data);
    end
  else
    data = dataset([]);
    setdataset(fig,data);
  end
  setvarname(fig,myname);
  
  setappdata(fig,'originaldataset',data);
  setappdata(fig,'moddate',data.moddate);
  
  setappdata(fig,'undoVect',[]);
  
  %Initialize settings.
  if isempty(data)
    mode = -1; %no data? MUST use mode -1;
  end
  viewsettings.classview = 'string'; %How to display class, as 'string' (classid) or 'numeric' (class).
  setappdata(fig,'viewsettings',viewsettings);
  setappdata(fig,'editfields',editfields);
  setappdata(fig,'noharddelete',noharddelete);
  setappdata(fig,'asraw',asraw);
  
  %create settings for disallowedmodes
  if isempty(allowedmodes);
    disallowedmodes = [];
  else
    disallowedmodes = setdiff([-1:ndims(data)],allowedmodes);
    if ismember(mode,disallowedmodes)
      mode = min(allowedmodes);
    end
  end
  setappdata(fig,'disallowedmodes',disallowedmodes);
  
  initialize(handles,data,mode);
  
else
  %More than one input = callback
  
  %a "table" command gets passed to editdstable sub-function
  if strcmp(varargin{1},'table')
    editdstable(varargin{2:end});
    return
  elseif strcmp(varargin{1},'updateshareddata')
    updateshareddata(varargin{2:end});
    return
  elseif  strcmp(varargin{1},'propupdateshareddata')
    propupdateshareddata(varargin{2:end});
    return
  end
  
  %parse inputs and get GUI info
  h       = varargin{2};
  if length(varargin)<3 | isempty(varargin{3});
    auxdata = [];
  else
    auxdata = varargin{3};
  end
  if length(varargin)<4 | isempty(varargin{4});
    handles = guidata(h);
  else
    handles = varargin{4};
  end
  if isempty(handles) | ~isfield(handles,'editds');
    if strcmp(varargin{1},'closegui') & ishandle(varargin{2})
      delete(varargin{2});
    end
    return;  %no handles? exit now
  end 
  fig     = handles.editds;
  
  %Need drawnow here so handles are cleared from EDT and closed. Otherwise
  %handle can still appear valid even though it's been deleted and latency
  %will cause error through shareddata. This happens with multiblocktool.
  drawnow
  
  %Get dataset
  [data, mylink]    = getdataset(fig);
  origmoddate = data.moddate;  %to watch for changes to dataset
  
  % Get UndoVect
  undoVect = getappdata(fig,'undoVect');
    
  %decide on action based on tag
  tag     = get(h,'tag');
  if h == fig; tag = varargin{1}; end    %figure itself is the object? use string input for command
  
  switch tag
    %-----------------------------------------------------
    case {'editname','cancelname','editauthor','cancelauthor','editdescription','canceldescription'}
      data = editfield(tag,handles,data);
      %-----------------------------------------------------
    case {'editclear','editexclude','editexcludeunselected','editinclude','editdeletefieldset'}
      editdstable(tag(5:end),fig,h);
      data = getdataset(fig);
      %-----------------------------------------------------
    case 'EditOptions'
      editoptions(fig);
      return
      %-----------------------------------------------------
    case 'history'
      fig = infobox(data.history');
      infobox(fig,'font','courier',10);
      %-----------------------------------------------------
    case 'userdata'
      assignin('base','userdata',char(data.userdata));
      evalin('base','openvar userdata');
      %-----------------------------------------------------
    case 'filesavefield'
      editdstable('save',fig,h)
      %-----------------------------------------------------
    case 'fileloadfield'
      editdstable('load',fig,h)
      data = getdataset(fig);
      %-----------------------------------------------------
    case 'filequit'
      editds('closegui',fig,[],handles);
      return
      %-----------------------------------------------------
    case 'closegui'
      %Flush event dispatch thead.
      drawnow;pause(.1);
      
      [data,mylink] = getdataset(fig);
      children = getappdata(fig,'children');
      children = children(ishandle(children));
      
      if isshareddata(mylink) & isvalid(mylink)
        %got a link?
        
        %get list of other items linked to this data
        links  = mylink.links;
        linked = [links.handle];
        linked = double(linked(ishandle(linked)));
        linked = setdiff(linked,handles.editds);
        
        %filter out "non-active" children (we will close them once confirmed)
        %these are children which are not linked to the data
        toclose  = setdiff(children,linked);
        
        moddate = getappdata(handles.editds,'moddate');
        if ~isempty(data) ...
            & (isempty(moddate) | any(moddate~=data.moddate)) ...
            & handles.editds==mylink.source ...
            & (isempty(linked) | ~strcmp('adopt',mylink.properties.removeAction))
          %No one will get my data, so I should figure out if it was modified...
          
          ans=evriquestdlg('Modified data has not been saved. What do you want to do?', ...
            'Data Not Saved','Close Without Saving','Save & Close','Cancel','Close Without Saving');
          switch ans
            case {'Cancel'}
              return
            case {'Save & Close'}
              data = filesave(fig,data,handles,[]);
              moddate = getappdata(handles.editds,'moddate');
              if (isempty(moddate) | any(moddate~=data.moddate));
                return
              end
          end
          
        end
        
      else
        %no link? probably empty, just close all children and leave
        toclose = children;
      end
      
      delete(toclose); %confirmed, close volitile children
      
      if ~isempty(mylink)
        %Remove link.
        linkshareddata(mylink,'remove',fig);
      end
      
      if ishandle(fig)
        positionmanager(fig,'editds','set')
        delete(fig);
      end
      return
      
      %-----------------------------------------------------
    case {'datagraph','viewplot'}
      
      [data,myid] = getdataset(fig);
      targ = [];
      
      %look for plotgui figure which is linked to this data
      links = myid.links;
      relatives = [links.handle];
      relatives = relatives(ishandle(relatives));
      for h = relatives(:)';
        if strcmp(getappdata(h,'figuretype'),'PlotGUI');
          targ = h;
          break;
        end
      end

      if isempty(targ)
        %no target? we'll create one
        %check for plotsettings
        if isfield(myid.properties,'plotsettings')
          plotsettings = myid.properties.plotsettings;
        else
          %no predefined settings - do a plot based on the displayed
          mode = getappdata(fig,'mode');
          if isempty(mode);
            mode = 0;
          end
          if mode>0 & mode<3
            modevs = 3-mode;
            if size(myid.object,modevs)==1
              mode = modevs;
            end
          end
          plotsettings = {'plotby',mode};
        end        
        if getappdata(fig,'noedit')
          plotsettings = [plotsettings 'noinclude' 1 'noload' 1];
        end
        newpg = plotgui('new',myid,plotsettings{:});
      else
        figure(targ);
      end
      
      %-----------------------------------------------------
    case {'slaveplot'}
      setappdata(fig,'slaveplot',auxdata);
      
      %-----------------------------------------------------
    case {'getdataset' 'getlink'}
      [varargout{1:nargout}] = feval(tag,fig);
      return

      %-----------------------------------------------------
    case {'setvarname'}
      setappdata(fig,'varname',auxdata);
      update(fig,data,handles,[]);
      
    case {'changeclassview'}
      vset = getappdata(fig,'viewsettings');
      if strcmp(vset.classview,'string')
        vset.classview = 'numeric';
      else
        vset.classview = 'string';
      end
      setappdata(fig,'viewsettings',vset);
      update(fig,data,handles,[]);
      
      %-----------------------------------------------------
    case {'editharddeleterows' 'editharddeletecolumns' 'editharddeleteother' 'editharddeleteall'}
      data = feval('editharddelete',fig,data,handles,auxdata,tag,mylink);
      
      %-----------------------------------------------------
    case 'initialize'
      initialize(handles,data);
    case {'updateshareddata' 'propupdateshareddata'}
      feval(varargin{1},varargin{2},varargin{3},varargin{4:end});
      
      %-----------------------------------------------------
    case 'dseshuffle'
      % todo: get user input for mode & store it somewhere
      %  todo: use a dseshuffle_Callback()
        [data,randVect,undoVect] = dseshuffle(fig,data,handles,undoVect);
    case 'dseundoshuffle'
      %  todo: use a dseundoshuffle_Callback()
      [data,undoVect]= dseundoshuffle(fig,data,handles,undoVect);
      %-----------------------------------------------------
    otherwise
      try
        data = feval(tag,fig,data,handles,auxdata);
      catch
        erdlgpls(['Error performing transform: ' lasterr],'Transform Error');
        return
      end
  end
  
  %NOTE: Some functions may not return data so we need to check below for
  %dataset before we check date - just skip this stuff if not a DSO
  if isa(data,'dataset') & any(data.moddate~=origmoddate);
    setdataset(fig,data);
    updateheader(handles);
  end
  
end

if nargout >0;
  varargout = {fig};
end

%-----------------------------------------------------------
%functions to handle saving and loading of data
function [data,mylink] = getdataset(fig,varargin);

mylink = getlink(fig);
if length(mylink)>1
  error('Too many data objects linked to EditDS figure.');
elseif isshareddata(mylink)
  data = mylink.object;
else
  data = [];
  mylink = [];
end

if isempty(data) & ~isdataset(data)
  data = dataset([]);
end

%-----------------------------------------------------------
function mylink = getlink(fig,varargin)
%Get link from appdata of figure.

mylink = [];
if ishandle(fig)
  mylink = getappdata(fig,'editdslinkeddata');
end

%-------------------------------------------
function out = ispointer(in)
out = isa(in,'double') & prod(size(in))==1 & ishandle(in);

%-------------------------------------------
function mylink = setdataset(targfig,data,keyword)

if getappdata(targfig,'noedit')
  return
end
if nargin<3;
  keyword = '';
end

%Need object so don't use getdataset.
mylink = getappdata(targfig,'editdslinkeddata');
if length(mylink)>1
  error('Too many data objects linked to EditDS figure.');
elseif isempty(mylink)
  origdata = [];
else
  origdata = getshareddata(mylink);
end

reactivate = 0;
if isempty(origdata) | ~isa(origdata,'dataset') | isempty(origdata.data) | any(origdata.moddate ~= data.moddate);
  %if data is different OR there was no data, save it
  
  numelements = prod(size(origdata));
  if numelements>0
    %make "undo" copy of data
    history = getappdata(targfig,'history');
    if isempty(history); history = {}; end
    history{end+1} = origdata;
    nsteps = floor(1e6/(8*numelements));  %base number of undo steps on size of data
    nsteps = min(10,max(1,nsteps));      %no more than 10, no fewer than 1
    history = history(max(1,end-(nsteps-1)):end);
    setappdata(targfig,'history',history);
  end
  
  %decide how to save it
  if strcmp(getappdata(targfig,'figuretype'),'volatile')
    close(targfig);
  else
    if isempty(mylink)
      if ~isshareddata(data)
        %if not a shared data object itself, we're adding data for first time.
        props = struct('removeAction','adopt');
        mylink = setshareddata(targfig,data,props);
        linkshareddata(mylink,'add',targfig,'editds');
      else
        %it is a link itself
        mylink = data;
      end
      setappdata(targfig,'editdslinkeddata',mylink);
    else
      %updating data - pass with keyword to trigger responses
      setshareddata(mylink,data,keyword);
    end
    reactivate = 1;
  end
  
  if reactivate & ishandle(targfig) & ~strcmp(get(targfig,'visible'),'off'); figure(targfig); end
  setvarname(targfig);%Add setvarname here so all changes are reflected in title bar.
end

%----------------------------------------------------------
function initialize(handles,data,mode)
%top-level set up of figure for a given dataset

drawnow;  %CRITICAL! Without this drawnow, we HANG on some systems
fig = handles.editds;

%Make edit boxes uneditable text boxes
set([handles.name handles.author],'style','text');
set(handles.description,'style','listbox','listboxtop',1,'min',0,'max',2,'value',[],'enable','inactive');

if isprop(fig,'WindowScrollWheelFcn')
  set(fig,'WindowScrollWheelFcn',@scrollWheelCallback)
end


%Add drag drop handler.
editdsdnd = evrijavaobjectedt(DropTargetList);%EVRI Custom drop target class.
editdsdnd = handle(editdsdnd,'CallbackProperties');
jFrame = get(handle(handles.editds),'JavaFrame');
%Don't think we need to run on EDT but if the need arises be sure to
%accommodate 7.0.4. 
jAxis  = jFrame.getAxisComponent;
jAxis.setDropTarget(editdsdnd);
set(editdsdnd,'DropCallback',{@dropCallbackFcn,handles.editds});

%Fill in header info
updateheader(handles)

h = [handles.editauthor handles.editname handles.editdescription handles.history handles.userdata handles.fileextract handles.editcopy handles.filesave];

if isempty(data.data)
  set(h,'enable','off');
else
  set(h,'enable','on');
end

if nargin<3
  mode = [];  %default mode
end

%create mode buttons
figpos = get(handles.editds,'position');
fpos  = get(handles.frame1,'position');
clr    = get(handles.frame1,'backgroundcolor');
offset = fpos(1);
nmodes = ndims(data); %length(size(data.data));
width  = 200;
height = 27;
fontsize = getdefaultfontsize('normal');

set(handles.infotab,'fontunits','points','fontweight','bold','units','pixels','fontsize',fontsize);
pos = get(handles.infotab,'position');
ext = get(handles.infotab,'extent');
pos = [pos(1:2) ext(3:4)*1.2];
pos = [offset+2 figpos(4)-pos(4)-offset pos(3:4)];
if getappdata(handles.editds,'asraw');
  enb = 'off';
else
  enb = 'on';
end
if ismember(-1,getappdata(handles.editds,'disallowedmodes'))
  enb = 'off';
end
set(handles.infotab,'position',pos,...
  'callback',['editds(''setmode'',gcbf,[],guidata(gcbf))'],...
  'enable',enb)
next = pos(1)+pos(3);

if ~isempty(data.data)
  
  %create datatable button
  myclr = clr;
  if strcmp(data.type,'batch')
    enb = 'off';
  else
    enb = 'on';
  end
  if getappdata(handles.editds,'asraw');
    enb = 'off';
  end
  if ismember(0,getappdata(handles.editds,'disallowedmodes'))
    enb = 'off';
  end
  pos = [next figpos(4)-height-offset width height];
  tag = ['mode0'];
  if isfield(handles,tag);
    %     h = getfield(handles,tag);
    h = getfield(handles,tag);
  else
    h = uicontrol(handles.editds,...
      'style','togglebutton',...
      'tag',tag);
  end
  if ~isempty(mode) & mode==0;
    val = 1;
  else
    val = 0;
  end
  set(h,'string',['Data'],...
    'position',pos,...
    'value',val,...
    'fontsize',fontsize,...
    'fontweight','bold',...
    'backgroundcolor',myclr,...
    'callback',['editds(''setmode'',gcbf,0,guidata(gcbf))'],...
    'enable',enb);
  ext = get(h,'extent');
  pos = [pos(1:2) ext(3:4)*1.2];
  pos = [pos(1) figpos(4)-pos(4)-offset pos(3:4)];
  set(h,'position',pos);
  next = pos(1)+pos(3);

  %plot button
  pos = [next figpos(4)-height-offset width height];
  tag = ['plottab'];
  if isfield(handles,tag);
    %     h = getfield(handles,tag);
    h = getfield(handles,tag);
  else
    h = uicontrol(handles.editds,...
      'style','pushbutton',...
      'tag',tag);
  end
  val = 0;
  enb = 'on';
  set(h,'string',['Plot'],...
    'position',pos,...
    'value',val,...
    'fontsize',fontsize,...
    'fontweight','bold',...
    'backgroundcolor',myclr.*.8,...
    'callback',['editds(''viewplot'',gcbf,-2,guidata(gcbf))'],...
    'enable',enb);
  ext = get(h,'extent');
  pos = [pos(1:2) ext(3:4)*1.2];
  pos = [pos(1) figpos(4)-pos(4)-offset pos(3:4)];
  set(h,'position',pos);
  next = pos(1)+pos(3);

  
  %create (or change) mode buttons
  for n = 1:nmodes;
    %choose color
    myclr = clr;
    if strcmp(data.type,'batch') & n==1
      enb = 'off';
    else
      enb = 'on';
    end
    if getappdata(handles.editds,'asraw');
      enb = 'off';
    end
    if ismember(n,getappdata(handles.editds,'disallowedmodes'))
      enb = 'off';
    end
    pos = [next figpos(4)-height-offset width height];
    tag = ['mode' num2str(n)];
    if isfield(handles,tag);
      %       h = getfield(handles,tag);
      h = getfield(handles,tag);
    else
      h = uicontrol(handles.editds,...
        'style','togglebutton',...
        'BusyAction','cancel',...
        'tag',tag);
    end
    if ~isempty(mode) & n == mode;
      val = 1;
    else
      val = 0;
    end
    
    if nmodes>2;
      mystr = ['Mode ' num2str(n) ' Labels'];
    else
      switch n
        case 1
          mystr = ['Row Labels'];
        case 2
          mystr = ['Column Labels'];
      end
    end
    
    set(h,'string',mystr,...
      'position',pos,...
      'value',val,...
      'fontsize',fontsize,...
      'fontweight','bold',...
      'backgroundcolor',myclr,...
      'callback',['editds(''setmode'',gcbf,' num2str(n) ',guidata(gcbf))'],...
      'enable',enb,...
      'userdata',n);
    ext = get(h,'extent');
    pos = [pos(1:2) ext(3:4)*1.2];
    pos = [pos(1) figpos(4)-pos(4)-offset pos(3:4)];
    set(h,'position',pos);
    next = pos(1)+ext(3)*1.2;
  end
  
else  %no data
  %reset window name
  setvarname(fig,'[None]');
  
  %remove all mode buttons
  nmodes = -1;
end

%clear unneeded mode buttons
for n = nmodes+1:10;
  tag = ['mode' num2str(n)];
  if isfield(handles,tag);
    delete(getfield(handles,tag));
  end
end


handles = guihandles(fig);
guidata(fig,handles);

%update field buttons as appropriate
updatefieldbuttons(handles,data)
editds('setmode',fig,mode,handles);
handles = guidata(fig);
editds('resize',fig,[],handles);

%fix for 7.0 visibility bug
set(handles.name,'style','edit');
set(handles.name,'style','text');

% set(fig,'visible','on');

%----------------------------------------------------------
function updateheader(handles)
%updates the header information

if ~ishandle(handles.editds)
  return
end

s = cell(0);

[data,mylink] = getdataset(handles.editds);

fontsize = getdefaultfontsize('normal');
set([handles.name handles.author handles.description handles.header ...
  handles.nametext handles.authortext handles.descriptiontext handles.headertext handles.historytext handles.userdatatext],...
  'fontunits','points','fontsize',fontsize)

%handle positioning of items relative to font size
resize(handles.editds,data,handles);

if isempty(data) | isempty(data.data)
  s = {'none','none'};
  setvarname(handles.editds,'[None]');
  
  set(handles.name,'string','');
  set(handles.author,'string','');
  set(handles.description,'string','');
  
else
  %Data size/class
  temp = int2str(size(data.data,1));
  tempincl = int2str(length(data.include{1}));
  for ii=2:ndims(data.data)
    temp = [temp,'x',int2str(size(data.data,ii))];
    tempincl = [tempincl 'x' int2str(length(data.include{ii}))];
  end
  s{1} = ['Class: ' class(data.data) '  Size: [' temp ']  Included: [' tempincl ']'];
  
  %Type
  s{2} = data.type;
  if strcmp(data.type, 'image')
    %Consturct sting of sizes.
    sizestr = '';
    for i = 1:length(data.imagesize);
      sizestr = [sizestr num2str(data.imagesize(i)) 'x'];
    end
    sizestr = sizestr(1:end-1); %Remove last x.
    s{2} = ['Image (size: ' sizestr ', mode: ' num2str(data.imagemode) ')'];
  end
  
  
  %Created date
  temp         = data.date;
  if isempty(temp)
    s{3} = '';
  else
    s{3} = datestr(datenum(temp(1),temp(2),temp(3),temp(4),temp(5),temp(6)),0);
  end
  
  %Modified date
  temp         = data.moddate;
  if isempty(temp)
    s{4} = '';
  else
    s{4} = datestr(datenum(temp(1),temp(2),temp(3),temp(4),temp(5),temp(6)),0);
    moddate = getappdata(handles.editds,'moddate');
    if handles.editds==mylink.source & (isempty(moddate) | any(moddate~=data.moddate)); %if length(getappdata(handles.editds,'orig_history'))~=length(data.history);
      s{4} = [s{4} ' (Modified)'];
    end
  end
  
  %set window name
  setvarname(handles.editds)
  
  set(handles.name,'string',data.name);
  set(handles.author,'string',data.author);
  descriptionstring = data.description;
  if size(data.description,1)==1
    descriptionstring = textwrap(handles.description,{descriptionstring});
  end
  set(handles.description,'string',descriptionstring);
  
end
set(handles.header,'string',s);

updatefieldbuttons(handles,data);
updateheaderbuttons(handles,data);

%--------------------------------------------------------------------------
function updateheaderbuttons(handles,data)
%updates edit buttons for header content

set([handles.editname handles.editauthor handles.editdescription handles.cancelname handles.cancelauthor handles.canceldescription],'string','')
if isempty(data.name);  set(handles.editname,'cdata',editdsicons('new'),'tooltipstring','Add Value'); else;  set(handles.editname,'cdata',editdsicons('edit'),'tooltipstring','Edit Value'); end
if isempty(data.author);  set(handles.editauthor,'cdata',editdsicons('new'),'tooltipstring','Add Value'); else;  set(handles.editauthor,'cdata',editdsicons('edit'),'tooltipstring','Edit Value'); end
if isempty(data.description); set(handles.editdescription,'cdata',editdsicons('new'),'tooltipstring','Add Value'); else;  set(handles.editdescription,'cdata',editdsicons('edit'),'tooltipstring','Edit Value'); end

%--------------------------------------------------------------------------
function updatefieldbuttons(handles,data,varargin)
%updates main field buttons for content

if isempty(data.userdata);
  set(handles.userdata,'cdata',editdsicons('new'),'string','','tooltipstring','Add Values');
else;
  set(handles.userdata,'cdata',editdsicons('edit'),'string','','tooltipstring','Edit Values');
end
%HARDCODED - DON'T ALLOW EDIT OF USERDATA YET
set(handles.userdata,'visible','off');
set(handles.userdatatext,'visible','off');
set([handles.userdata handles.userdatatext],'userdata',[]);


set(handles.history,'cdata',editdsicons('view'),'string','','tooltipstring','View History');
set(handles.datagraph,'visible','off');

%--------------------------------------------------------------------------
function data = editfield(tag,handles,data)

fig     = handles.editds;
buttons = [findobj(fig,'style','pushbutton');findobj(fig,'style','togglebutton')];
menus   = [handles.file];

switch tag
  %-----------------------------------------------------
  case {'editname','cancelname'}
    if isempty(getappdata(handles.name,'editing')); %strcmp(get(handles.name,'style'),'text')
      
      h = uicontrol('style','edit',...
        'units',get(handles.name,'units'),...
        'position',get(handles.name,'position'),...
        'string',get(handles.name,'string'),...
        'HorizontalAlignment','left',...
        'fontsize',getdefaultfontsize('normal'),...
        'backgroundcolor',[1 1 1]);
      setappdata(handles.name,'editing',h)
      set(handles.name,'visible','off');
      
      setappdata(fig,'buttonstatus',get(buttons,'enable'));
      set(buttons,'enable','off');
      setappdata(fig,'oldmode',getappdata(fig,'mode'));
      editds('setmode',fig,[],handles);
      set(menus,'enable','off');
      set(fig,'windowstyle','modal');
      set(handles.editname,'enable','on','cdata',editdsicons('check'),'tooltipstring','Accept Changes');
      set(handles.cancelname,'enable','on','visible','on','cdata',editdsicons('x'),'tooltipstring','Discard Changes');
    else
      
      h = getappdata(handles.name,'editing');
      set(handles.name,'string',get(h,'string'));
      delete(h);
      setappdata(handles.name,'editing',[])
      set(handles.name,'visible','on');
      
      if strcmp(tag,'editname');
        data.name = get(handles.name,'string');
      else
        set(handles.name,'string',data.name);
      end
      %       set(handles.name,'style','text');
      set(buttons,{'enable'},getappdata(fig,'buttonstatus'));
      set(menus,'enable','on');
      set(fig,'windowstyle','normal');
      set(handles.cancelname,'visible','off');
      updateheaderbuttons(handles,data);
      editds('setmode',fig,getappdata(fig,'oldmode'),handles);
    end
    
    %-----------------------------------------------------
  case {'editauthor','cancelauthor'}
    if isempty(getappdata(handles.author,'editing')); %  if strcmp(get(handles.author,'style'),'text')
      
      h = uicontrol('style','edit',...
        'units',get(handles.author,'units'),...
        'position',get(handles.author,'position'),...
        'string',get(handles.author,'string'),...
        'fontsize',getdefaultfontsize('normal'),...
        'HorizontalAlignment','left',...
        'backgroundcolor',[1 1 1]);
      setappdata(handles.author,'editing',h)
      set(handles.author,'visible','off');
      
      setappdata(fig,'buttonstatus',get(buttons,'enable'));
      set(buttons,'enable','off');
      setappdata(fig,'oldmode',getappdata(fig,'mode'));
      editds('setmode',fig,[],handles);
      set(menus,'enable','off');
      set(fig,'windowstyle','modal');
      set(handles.editauthor,'enable','on','cdata',editdsicons('check'),'tooltipstring','Accept Changes');
      set(handles.cancelauthor,'enable','on','visible','on','cdata',editdsicons('x'),'tooltipstring','Discard Changes');
    else
      
      h = getappdata(handles.author,'editing');
      set(handles.author,'string',get(h,'string'));
      delete(h);
      setappdata(handles.author,'editing',[])
      set(handles.author,'visible','on');
      
      if strcmp(tag,'editauthor');
        data.author = get(handles.author,'string');
      else
        set(handles.author,'string',data.author);
      end
      set(buttons,{'enable'},getappdata(fig,'buttonstatus'));
      set(menus,'enable','on');
      set(fig,'windowstyle','normal');
      set(handles.cancelauthor,'visible','off');
      updateheaderbuttons(handles,data);
      editds('setmode',fig,getappdata(fig,'oldmode'),handles);
    end
    
    %-----------------------------------------------------
  case {'editdescription','canceldescription'}
    if ~strcmp(get(handles.description,'style'),'edit')
      set(handles.description,'style','edit','enable','on');
      setappdata(fig,'buttonstatus',get(buttons,'enable'));
      set(buttons,'enable','off');
      setappdata(fig,'oldmode',getappdata(fig,'mode'));
      editds('setmode',fig,[],handles);
      set(menus,'enable','off');
      set(fig,'windowstyle','modal');
      set(handles.editdescription,'enable','on','cdata',editdsicons('check'),'tooltipstring','Accept Changes');
      set(handles.canceldescription,'enable','on','visible','on','cdata',editdsicons('x'),'tooltipstring','Discard Changes');
    else
      if strcmp(tag,'editdescription');
        data.description = get(handles.description,'string');
        %         ttip = [data.description';ones(1,size(data.description,1))*13];
        %         set(handles.description,'TooltipString',ttip(:)')
      else
        descriptionstring = data.description;
        if size(data.description,1)==1
          descriptionstring = textwrap(handles.description,{descriptionstring});
        end
        set(handles.description,'string',descriptionstring);
      end
      set(handles.description,'style','listbox','listboxtop',1,'min',0,'max',2,'value',[],'enable','inactive');
      set(buttons,{'enable'},getappdata(fig,'buttonstatus'));
      set(menus,'enable','on');
      set(fig,'windowstyle','normal');
      set(handles.canceldescription,'visible','off');
      updateheaderbuttons(handles,data);
      editds('setmode',fig,getappdata(fig,'oldmode'),handles);
    end
end

if strcmp(get(fig,'windowstyle'),'normal')
  %Resize to figure as workaround for Matlab bug R14SP3.
  %Going to modal and back to normal causes menus to disappear.
  %Submitted to TMW by SK: Service Request # 1-25WGT4
  x=get(fig,'position');
  set(fig,'position',x+1);
  set(fig,'position',x);
end

%==========================================================================

function editdstable(varargin)
%EDITDSTABLE - Edit a dataset's fields in a table form
%I/O: editdstable(fig,mode);  %implies "new"
%I/O: editdstable('action',fig)

%test for various input forms
switch nargin
  case {0,1}
    error('Unrecognized number of inputs')
    
  otherwise
    %('action',fig)
    %(fig,mode);  %implies "new"
    if isstr(varargin{1})
      %('action',fig)
      action    = varargin{1};
      fig       = varargin{2};
      mode      = [];
    else
      action = 'new';
      fig    = varargin{1};
      mode   = varargin{2};
    end
    
end

%-------------------------
% Hardcoded size settings

offset       = 2;      %pixels
gutter       = 3;      %left-edge gutter

toprows      = 4;      %rows
topbuffer    = 0.5;
bottomrows   = 0;
bottombuffer = 0.5;

cellsize   = [100 20];   %note: cellsize(1) (=width) is automatically set for "labels"
fontsize   = getdefaultfontsize('notes');
%cell size above is based on an 8-point font size (PC) or 12-point (MAC) - adjust for other font sizes
if ispc
  cellsize   = cellsize/8*fontsize;  
else
  cellsize   = cellsize/10*fontsize;  
end

maxtags = 58; %=length(tagbase)-4;  %leave four of the tagbase elements for top and bottom elements

%----------------------------
% Initialize based on action

[data,dataid] = getdataset(fig);
handles   = guidata(fig);
oldmode   = getappdata(fig,'mode');

linkselections = getappdata(fig,'linkselections');

if strcmp(action,'new') & ~isempty(oldmode) & ~isempty(mode) & oldmode==mode
  action = 'update';
end

switch action
  case 'new'  %*** Create new table
    
    if isempty(mode) | (oldmode==0 & mode>0) | (mode==0 & oldmode>0)  %unless switching between positive label modes (1->2, 2->1, etc)
      %delete table objects
      tableobjs = findobj(fig,'userdata','table');
      tableobjs = tableobjs(ishandle(tableobjs));
      if ~isempty(tableobjs);
        delete(tableobjs);
      end
      %store updated list of available handles
      handles = guihandles(fig);
      guidata(fig,handles);
      
      if isempty(mode)  %if we're going to NOTHING
        setappdata(fig,'mode',[]);
        updateheader(handles);
        return
      end
    end
    
    if isempty(oldmode) & ~isempty(mode);
      %going to SOMETHING from NOTHING
      figpos = get(fig,'position');
      f1pos  = get(handles.frame1,'position');
      btnpos = get(handles.mode0,'position');
      %resize window to match frame
      set(fig,'position',[figpos(1) figpos(2)+btnpos(2)-f1pos(4)-f1pos(1) figpos(3) figpos(4)-btnpos(2)+f1pos(4)+f1pos(1)]);
    end
    
    rowoffset = 0;
    coloffset = 0;
    
    handles = guihandles(fig);
    guidata(fig,handles);
    
    setappdata(fig,'resized',0);
    
    if isempty(data.data);
      return
    end
    
    set(fig,'pointer','watch');
    options = getfieldoptions(fig);
    
  otherwise   %*** Load info from existing figure
    
    mode      = oldmode;
    if isempty(mode);
      return
    end
    
    rowoffset = round(get(handles.offset,'max')-get(handles.offset,'value'));
    nrows     = getappdata(fig,'nrows');
    ncols     = getappdata(fig,'ncols');
    cellsize  = getappdata(fig,'cellsize');
    options   = getappdata(fig,'options');

    coloffset = 0;
    
    if mode==0
      coloffset = round(get(handles.coffset,'value'));
    end
    
end

dataformat = getappdata(fig,'dataformat');
axisscaleformat = getappdata(fig,'axisscaleformat');

%---------------------
%more size settings

width  = cellsize(1);
height = cellsize(2);

relativewidths = [0.4 1.3 0.6 0.9 0.3];   %rel. widths of columns
totalrelwidth  = sum(relativewidths)+.5;

figsize = get(fig,'position');
framesize = get(handles.frame1,'position');
figsize(4) = framesize(2)+framesize(4);
figsize(3) = framesize(1)+framesize(3);

btnclrs = {get(handles.frame1,'backgroundcolor').*[.8 .8 .8] get(handles.frame1,'backgroundcolor').*[.95 .95 1]};
btndim = .9;

%--------------------
%extract/define dataset info

switch mode
  case 1
    modestr = 'Row';
  case 2
    modestr = 'Col';
  otherwise
    modestr = '';
end

%---------------------------------------
% do various "actions"

switch action
  %--------------------------------------------------------
  % Create or update figure (create objects, extract from fields, etc.)
  case {'new','update'}
    
    if getappdata(fig,'noedit')
      editable = 'inactive';
    else
      editable = 'on';
    end
    if mode>0
      %display/edit label fields
      
      cellsize(1) = framesize(3)/totalrelwidth;
      width   = cellsize(1);
      ncols   = length(options.enable);  %predefined (irrelavent for field mode)
      
      %only assign nrows for new, otherwise creates error because of mismatched indexing.
      nrows   = floor(min([size(data,mode) framesize(4)/(cellsize(2)+offset)-toprows-topbuffer-bottomrows maxtags]));
      nrows   = max([nrows 1]);
      
      if (rowoffset+nrows)>size(data,mode);
        rowoffset = size(data,mode)-nrows;
      end
      
      if getappdata(fig,'resized') | strcmp(action,'new');
        action = 'new:resize';  %acts like "new" except for uiwait at end
        set(fig,'resizefcn','');
      end
      
      %--------------------------
      %do top rows
      row = 0;
      
      colwidths = relativewidths.*width+offset*2;
      
      %Titletext
      row = row+1;
      col   = 1;
      shift = -colwidths(col)*.3;
      cumshift = 0;
      pos   = [offset+gutter     figsize(4)-row*(height+offset)-offset-2   colwidths(1)+shift   height];
      style = 'text';
      clr   = get(handles.frame1,'backgroundcolor');
      strng = ['Title: '];
      tag = ['r' tagbase(row) 'c' tagbase(col)];
      if isfield(handles,tag)
        h = getfield(handles,tag);
      else
        h = uicontrol(handles.editds,...
          'units','pixels',...
          'position',pos,...
          'userdata','table',...
          'visible','off',...
          'tag',tag);
      end
      set(h,...
        'position',pos,...
        'backgroundcolor',clr,...
        'style',style,...
        'horizontalalignment','right',...
        'fontsize',fontsize,...
        'fontweight','bold',...
        'userdata','table',...
        'string',strng);
      
      %Title field
      col   = 2;
      cumshift = cumshift + shift;
      shift = -colwidths(col+1)/2;
      pos   = [sum(colwidths(1:col-1))+offset+gutter+cumshift     figsize(4)-row*(height+offset)-offset   colwidths(col)+colwidths(col+1)+shift  height];
      style = 'edit';
      clr   = [1 1 1];
      strng = data.title{mode};
      tag = ['r' tagbase(row) 'c' tagbase(col)];
      if isfield(handles,tag)
        h = getfield(handles,tag);
      else
        h = uicontrol(handles.editds,...
          'units','pixels',...
          'position',pos,...
          'userdata','table',...
          'visible','off',...
          'tag',tag);
        setappdata(h,'field','title')
      end
      set(h,...
        'position',pos,...
        'backgroundcolor',clr,...
        'enable',editable,...
        'style',style,...
        'horizontalalignment','left',...
        'fontsize',fontsize,...
        'fontweight','bold',...
        'callback','editds(''table'',''set'',gcbf)',...
        'string',strng);
      
      %--------------------
      %axistype label
      col   = 4;
      cumshift = cumshift + shift;
      shift = -colwidths(col)*.4;
      pos   = [sum(colwidths(1:col-1))+offset+gutter+cumshift     figsize(4)-row*(height+offset)-offset-2   colwidths(col)+shift   height];
      style = 'text';
      clr   = get(handles.frame1,'backgroundcolor');
      strng = ['Axis Type: '];
      tag = ['r' tagbase(row) 'c' tagbase(col)];
      if isfield(handles,tag)
        h = getfield(handles,tag);
      else
        h = uicontrol(handles.editds,...
          'units','pixels',...
          'position',pos,...
          'userdata','table',...
          'visible','off',...
          'tag',tag);
      end
      set(h,...
        'position',pos,...
        'backgroundcolor',clr,...
        'style',style,...
        'horizontalalignment','right',...
        'fontsize',fontsize,...
        'fontweight','bold',...
        'userdata','table',...
        'string',strng);
      
      %axistype field
      col   = 5;
      cumshift = cumshift + shift;
      shift = colwidths(col)*1.5;
      pos   = [sum(colwidths(1:col-1))+offset+gutter+cumshift     figsize(4)-row*(height+offset)-offset   colwidths(col)+shift   height];
      style = 'popup';
      clr   = [1 1 1];
      strng = data.axistype{mode};
      axtopts = {'none' 'continuous' 'discrete' 'stick'};
      value = find(ismember(axtopts,lower(strng)));
      axtopts{1} = 'none (Automatic)';

      tag = ['r' tagbase(row) 'c' tagbase(col)];
      if isfield(handles,tag)
        h = getfield(handles,tag);
      else
        h = uicontrol(handles.editds,...
          'units','pixels',...
          'position',pos,...
          'userdata','table',...
          'visible','off',...
          'tag',tag);
        setappdata(h,'field','axistype')
      end
      set(h,...
        'position',pos,...
        'backgroundcolor',clr,...
        'enable',editable,...
        'style',style,...
        'horizontalalignment','left',...
        'fontsize',fontsize,...
        'fontweight','bold',...
        'callback','editds(''table'',''set'',gcbf)',...
        'value',value,...
        'string',axtopts);

      
      %--------------------
      
      
      %Column headings
      label_uicontextmenu = findobj(fig,'tag','labelmenu');%Try to limit calls to findobj.
      column_uicontextmenu = findobj(fig,'tag','colrowmenu');
      row = row+1;
      for col = 2:ncols+1;
        pos   = [sum(colwidths(1:col-1))+offset+gutter   figsize(4)-row*(height+offset)-offset   colwidths(col)   height];
        if options.enable(col-1)
          style = 'togglebutton';
          ttip  = options.fieldtip{col-1};
          if isempty(label_uicontextmenu)
            label_uicontextmenu = findobj(fig,'tag','labelmenu');
          end
          %uicb = ['set(gcbo,''visible'',''on'');' get(uicontextmenu, 'Callback')];
          %uicb = 'set(gcbo, ''Position'',get(gcf,''CurrentPoint'')); set(gcbo,''Visible'', ''on''); editds(''(menu'',gcbo,[],guidata(gcbf))';
          %set(uicontextmenu,'Callback',uicb);
        else
          style = 'text';
          ttip  = '';
          label_uicontextmenu = [];
        end
        callback = 'editds(''table'',''toggleindex'',gcbf)';
        value = 0;
        clr   = btnclrs{2};
        strng = options.fielddesc{col-1};
        if ~isempty(strng);
          tag = ['r' tagbase(row) 'c' tagbase(col)];
          %           if ~strcmp(action,'update');
          if isfield(handles,tag)
            h = getfield(handles,tag);
          else
            h = uicontrol(handles.editds,...
              'userdata','table',...
              'units','pixels',...
              'position',pos,...
              'visible','off',...
              'value',value,...
              'fontweight','bold',...
              'tag',tag);
            setappdata(h,'field',[col-1]);
          end
          set(h,...
            'position',pos,...
            'backgroundcolor',clr,...
            'style',style,...
            'fontsize',fontsize,...
            'string',strng,...
            'tooltipstring',ttip,...
            'uicontextmenu',label_uicontextmenu,...
            'callback',callback);
        end
      end
      
      %set selection menus
      row = row+1;
      for col = 1:ncols;
        pos = [sum(colwidths(1:col))+offset+gutter   figsize(4)-row*(height+offset)-offset   colwidths(col+1)   height];
        
        switch options.fieldname{col};
          case 'label'
            nsets = size(data.label,2);
            myfield = data.label;
            myfieldname = data.labelname;
          case 'axisscale'
            nsets = size(data.axisscale,2);
            myfield = data.axisscale;
            myfieldname = data.axisscalename;
          case 'class'
            nsets = size(data.class,2);
            myfield = data.class;
            myfieldname = data.classname;
          case 'include'
            continue
          otherwise
            continue
        end
        
        %create list of usable sets
        sets = cell(0);
        for j=1:nsets;
          if isempty(myfield{mode,j});
            status = ' (empty)';
          else
            if ~isempty(myfieldname{mode,j})
              status = [': ' myfieldname{mode,j}];
            else
              status = ': (no name)';
            end
          end
          sets{j} = ['Set ' num2str(j) status];
        end
        if options.enable(col) & strcmp(editable,'on')
          sets{end+1} = 'New Set...';
        end
        tag = ['c' tagbase(col+1) 'set'];
        if isfield(handles,tag)
          h = getfield(handles,tag);
          set(h,'position',pos,...
            'fontsize',fontsize,...
            'string',sets);
        else
          h = uicontrol(handles.editds,'style','popupmenu',...
            'tag',tag,...
            'userdata','table',...
            'enable','on',...
            'visible','off',...
            'fontsize',fontsize,...
            'string',sets,...
            'callback','editds(''table'',''selectset'',gcbf)',...
            'units','pixels',...
            'backgroundcolor',[.95 .95 1],...
            'position',pos);
          setappdata(h,'field',[col])
          setappdata(h,'mode',mode);
        end
        if mode~=oldmode
          set(h,'value',1);
        end
      end
      
      %fieldNAME row
      row = row+1;
      for col = 1:ncols+1;
        
        seth = findobj(fig,'userdata','table','tag',['c' tagbase(col) 'set']);
        if isempty(seth);
          useset = 1;
        else
          useset = get(seth,'value');
        end
        
        if col == 1;
          pos = [offset+gutter   figsize(4)-row*(height+offset)-offset   colwidths(1)   height+offset*2];
          algn  = 'right';
          style = 'text';
          strng = 'Name: ';
          clr   = get(handles.frame1,'backgroundcolor');
          en    = editable;
          pos(2) = pos(2)-2;
        else
          pos = [sum(colwidths(1:col-1))+offset+gutter   figsize(4)-row*(height+offset)-offset   colwidths(col)   height+offset*2];
          algn  = 'center';
          if options.enable(col-1)
            style = 'edit';
            clr   = [1 1 1];
            en    = editable;
          else
            style = 'text';
            clr   = get(handles.frame1,'backgroundcolor');
            clr   = min([1 1 1],clr * 1.1);
          end
          switch options.fieldname{col-1};
            case 'label'
              strng = data.labelname{mode,useset};
            case 'axisscale'
              strng = data.axisscalename{mode,useset};
            case 'class'
              strng = data.classname{mode,useset};
            case 'include'
              continue
          end
        end
        tag = ['r' tagbase(row) 'c' tagbase(col)];
        
        if isfield(handles,tag)
          h = getfield(handles,tag);
        else
          h = uicontrol(handles.editds,...
            'units','pixels',...
            'position',pos,...
            'userdata','table',...
            'visible','off',...
            'tag',tag);
          setappdata(h,'field',[0 col-1])
        end
        
        set(h,...
          'position',pos,...
          'backgroundcolor',clr,...
          'style',style,...
          'fontsize',fontsize,...
          'fontweight','bold',...
          'horizontalalignment',algn,...
          'enable',en,...
          'string',strng,...
          'callback','editds(''table'',''set'',gcbf)');
      end
      
      %--------------------------
      %main table
      figclr = get(handles.frame1,'backgroundcolor');
      myincl = data.include{mode};
      for col = 1:ncols+1;
        
        seth = findobj(fig,'userdata','table','tag',['c' tagbase(col) 'set']);
        if isempty(seth);
          useset = 1;
        else
          useset = get(seth,'value');
        end
        
        %get data needed for entire column
        if col>1
          switch options.fieldname{col-1}
            case 'label'
              dat = data.label{mode,useset};
            case 'axisscale'
              dat = data.axisscale{mode,useset};
              dat_date = dat(~isnan(dat));
              asdate = all(dat_date<840059 & dat_date>693962); %if all axisvalues fall in the typical "date range" show it as a date              
              clear('dat_date');
            case 'class'
              %get class lookup table if this is "class" column
              classlookup         = data.classlookup{mode,useset};
              if isempty(classlookup)
                classlookup_numbers = [];
              else
                classlookup_numbers = [classlookup{:,1}];
              end
              classclrs           = classcolors;
              
              %adjust color map to match what PlotGUI is going to do.
              [junk,junk,clrorder]= intersect(classlookup_numbers,orderclasses(classlookup_numbers));
              
              vset = getappdata(fig,'viewsettings');
              
              %get all classes and convert to appropriate string
              dat = data.class{mode,useset};
              if isempty(dat)
                strng = {'New Class...'};
              else
                if strcmp(vset.classview,'string')
                  strng = [classlookup(:,2); {'New Class...'}];
                else
                  %Remove any spaces that could be created from num2str
                  %command (below). This can happen if numeric data in
                  %lookuptable is higher datatype (none integer).
                  clslist = strrep(str2cell(num2str(classlookup_numbers')),' ','');
                  strng = [clslist; {'New Class...'}];
                end
              end
          end
        end
        
        for row = 1:nrows;
          
          rowincl = ismember(row+rowoffset,myincl);
          pos = [sum(colwidths(1:col-1))+offset+gutter   figsize(4)-(row+toprows+topbuffer)*(height+offset)-offset   colwidths(col)   height+offset*2];
          ha  = 'center';
          enb = editable;
          value = [];
          if col==1;
            %handle row labels/buttons
            strng = [modestr ' ' num2str(row+rowoffset)];
            style = 'text';
            clr   = figclr;
            pos(2) = pos(2)-2;
            
            style = 'togglebutton';
            callback = 'editds(''table'',''toggleindex'',gcbf)';
            pos(3) = pos(3)-3;
            if linkselections
              if length(dataid.properties.selection)>=mode
                value = ismember(row+rowoffset,dataid.properties.selection{mode});   %%%For shareddata/selection code
              else
                value = 0;
              end
            else
              value = 0;
            end
            clr = btnclrs{rowincl+1}.*(1-value*(1-btndim));
            textclr = [0 0 0];
            %uicontextmenu = findobj(fig,'tag','colrowmenu');
            enb = 'on';
            
          else
            
            ha  = 'left';
            if options.enable(col-1)
              style = 'edit';
              clr   = [ 1 1 1 ];
            else
              style = 'text';
              clr   = figclr;
              clr   = min([1 1 1],clr * 1.1);
              pos(3) = pos(3)-2;
              pos(4) = pos(4)-4;
              ha  = 'center';
            end
            textclr = [0 0 0];
            
            switch options.fieldname{col-1};
              case 'label'
                if isempty(dat)
                  strng = '';
                else
                  strng = deblank(dat(row+rowoffset,:));
                end
              case 'axisscale'
                if isempty(dat)
                  strng = '';
                elseif asdate
                  if isnan(dat(row+rowoffset))
                    strng = sprintf(['%' axisscaleformat],dat(row+rowoffset));
                  else
                    strng = datestr(dat(row+rowoffset),31);
                  end
                else
                  strng = sprintf(['%' axisscaleformat],dat(row+rowoffset));
                end
              case 'class'
                style = 'popup';
                if isempty(dat)
                  value = 1;
                else
                  mycls = dat(row+rowoffset);
                  value = find(classlookup_numbers==mycls);
                  if ~isempty(findstr(computer,'MAC'));
                    %This is a fix for bug rendering background color in
                    %Matlab. Doesn't render until popup is clicked.
                    clr = [1 1 1];
                    textclr = [0 0 0];
                  else
                    clr = classclrs(mod(clrorder(mod((value-1),length(clrorder))+1)-1,size(classclrs,1))+1,:);
                    if mean(clr)<.5;
                      textclr = [1 1 1];
                    else
                      textclr = [0 0 0];
                    end
                  end
                end
                if options.enable(col-1)
                  enb = editable;
                else
                  enb = 'inactive';
                end
                
              case 'include'
                value = rowincl;
                strng = '';
                style = 'checkbox';
                if options.enable(col-1);
                  if ~getappdata(fig,'noedit') & strictedit
                    %SPECIAL CASE for include - if noedit is turned OFF but
                    %strict edit is ON, then editing this field is actually
                    %ALLOWED!
                    enb = 'on';
                  else
                    enb = editable;
                  end
                else
                  enb = 'off';
                end
                clr   = figclr;
                pos(1) = pos(1)+pos(3)/2.4;
                pos(3) = pos(3)/2;
            end
            callback = 'editds(''table'',''set'',gcbf)';
          end
          
          tag = ['r' tagbase(row+toprows) 'c' tagbase(col)];
          %           if ~strcmp(action,'update');
          if isfield(handles,tag) & ishandle(handles.(tag))
            h = getfield(handles,tag);
          else
            h = uicontrol(handles.editds,...
              'units','pixels',...
              'position',pos,...
              'userdata','table',...
              'visible','off',...
              'tag',tag);
            setappdata(h,'field',[row col-1])
            if col<2
              %Only add context menu to row headings.
              set(h,'uicontextmenu',column_uicontextmenu);
            end
          end
          
          if col>1 & strcmpi(options.fieldname{col-1},'class')
            %Have to set value to 1 here to avoid unexpeted behavior in popup
            %menu rendering. Is reset below
            set(h,'value',1);
          end
          
          set(h,...
            'position',pos,...
            'backgroundcolor',clr,...
            'ForegroundColor',textclr,...
            'fontsize',fontsize,...
            'style',style,...
            'HorizontalAlignment',ha,...
            'String',strng,...
            'enable',enb,...
            'value',value,...
            'callback',callback);
          
          if checkmlversion('>','6.5')
            set(h, 'keypressfcn','editds(''keypress'',gcbf,[],guidata(gcbf))')
          end
        end
        
      end
      
      
      %offset slider
      nitems = size(data.data,mode);
      rng    = [0 nitems-nrows];
      value  = rng(2)-rowoffset;
      if value<rng(1); value=rng(1); end
      if value>rng(2); value=rng(2); end
      enb    = 'on';
      if rng(2)==0;
        rng = [0 1];
        enb = 'off';
      end
      step   = [1/rng(2) nrows/rng(2)];
      pos = [sum(colwidths)+offset*5+gutter   figsize(4)-(toprows+topbuffer)*(height+offset)-nrows*(height+offset)   width/8   nrows*(height+offset)];
      if isfield(handles,'offset')
        h = handles.offset;
        set(h,'position',pos);
      else
        h = uicontrol(handles.editds,'style','slider',...
          'userdata','table',...
          'tag','offset',...
          'visible','off',...
          'units','pixels');
      end
      set(h,...
        'position',pos,...
        'enable',enb,...
        'min',rng(1),'max',rng(2),...
        'fontsize',fontsize,...
        'sliderstep',step,...
        'value',rng(2)-rowoffset,...
        'callback','editds(''table'',''update'',gcbf);');
      figsize(3) = pos(1)+pos(3)+offset*2;
      
      %---------------------------
      %bottom controls
      
      row = nrows+1;
      
    else
      %= = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
      %data only display
      ncols   = floor(min([size(data,2) ((framesize(3)-width/5)/(cellsize(1)+offset))-1 maxtags]));
      if ncols==size(data,2)
        sliderwidth = width/5;
        labelwidth = max(width,min(width*2,floor(framesize(3)-offset*3-sliderwidth-(ncols*width))));
        width = floor(((framesize(3)-offset*4-labelwidth-sliderwidth)/ncols)-offset);
      else
        labelwidth = width;
        sliderwidth = width/5;
      end
      ncols   = max([ncols 1]);
      if (coloffset+ncols)>size(data,2);
        coloffset = size(data,2)-ncols;
      end
      
      nrows   = floor(min([size(data,1) framesize(4)/(cellsize(2)+offset)-topbuffer-2 maxtags]));
      nrows   = max([nrows 1]);
      if (rowoffset+nrows)>size(data,1);
        rowoffset = size(data,1)-nrows;
      end
      
      if getappdata(fig,'resized') | strcmp(action,'new');
        action = 'new:resize';  %acts like "new" except for uiwait at end
        set(fig,'resizefcn','');
      end
      
      %--------------------------
      %main table
      mydata = data.data;
      incl   = data.include;
      
      figclr = get(handles.frame1,'backgroundcolor');
      
      toprows = 1; %set so that we can remove the correct # of rows later (if we shrink the window)
      
      %create boolean map of include (if we don't have one or we have an
      %out-of-date one)
      inclmap = getappdata(fig,'includemap');
      moddate = getappdata(fig,'includemoddate');
      if isempty(moddate) | ~all(moddate==data.moddate);
        moddate = data.moddate;
        sz = size(data);
        for k=1:ndims(data);
          inclmap{k} = zeros(1,sz(k));
          inclmap{k}(incl{k}) = 1;
        end
        setappdata(fig,'includemoddate',moddate);
        setappdata(fig,'includemap',inclmap);
      end

      %determine what we're using for row and column labels
      field = 'label';
      useset = 1;
      [list,listlookup] = getavlabels(data,2);
      tag = 'collabelpopup';
      if ~isempty(list)
        if length(list)==1
          sel = 1;
        elseif isfield(handles,tag) & ishandle(handles.(tag))
          sel = get(handles.(tag),'value');
        else
          sel = 0;
        end
        if sel<=size(listlookup,1) & sel>0
          [field,useset] = deal(listlookup{sel,:});
        end
      end
      [collabels,colclr] = getavcontent(data,2,field,useset,axisscaleformat);
      
      field = 'label';
      useset = 1;
      [list,listlookup] = getavlabels(data,1);
      tag = 'rowlabelpopup';
      if ~isempty(list)
        if length(list)==1
          sel = 1;
        elseif isfield(handles,tag) & ishandle(handles.(tag))
          sel = get(handles.(tag),'value');
        else
          sel = 0;
        end
        if sel<=size(listlookup,1) & sel>0
          [field,useset] = deal(listlookup{sel,:});
        end
      end
      [rowlabels,rowclr] = getavcontent(data,1,field,useset,axisscaleformat);
      
      column_uicontextmenu = findobj(fig,'tag','colrowmenu');%Try limit calls to findobj.
      for col = 0:ncols;
        for row = 0:nrows;
          
          pos     = [((col-1)*(col>0))*width+offset+gutter+(labelwidth*(col>0))   figsize(4)-(row+1+topbuffer)*(height+offset)-offset   width+offset*2   height+offset*2];
          if col==0
            pos(3)= labelwidth;
          end
          ha      = 'left';
          style   = 'text';
          enb     = 'on';
          tooltip = '';
          value = [row+rowoffset col+coloffset];
          
          if col==0;
            if row==0
              %add row-label pulldown             
              tag = 'collabelpopup';
              style = 'popup';
              tooltip = 'Select Column Labels';
              ha = 'right';
              callback = 'editds(''table'',''update'',gcbf)';              
              
              if isfield(handles,tag)
                h = getfield(handles,tag);
              else
                h = uicontrol(handles.editds,...
                  'units','pixels',...
                  'position',pos,...
                  'userdata','table',...
                  'style',style,...
                  'TooltipString',tooltip,...
                  'HorizontalAlignment',ha,...
                  'visible','off',...
                  'tag',tag,...
                  'callback',callback);
              end
              
              list = getavlabels(data,2);
              if length(list)<1
                delete(h);
              else
                set(h,'string',list,'visible','on','position',pos,'fontsize',fontsize);
              end
              
              continue
            end
            %handle row labels
            strng = [num2str(row+rowoffset)];
            if ~isempty(rowlabels);
              lbl = deblank(rowlabels(row+rowoffset,:));
              if ~isempty(lbl);
                strng = [strng ': ' lbl];
              end
            end
            tooltip = strng;
            style = 'togglebutton';
            if linkselections
              value = ismember(row+rowoffset,dataid.properties.selection{1});     %%%For shareddata/selection code
            else
              value = 0;
            end
            if isempty(rowclr)
              clr = btnclrs{inclmap{1}(row+rowoffset)+1}.*(1-value*(1-btndim));
            else
              clr = rowclr(row+rowoffset,:).*(1-value*(1-btndim));
            end
            if mean(clr)<.5;
              textclr = [1 1 1];
            else
              textclr = [0 0 0];
            end
            callback = 'editds(''table'',''toggleindex'',gcbf)';
            pos(3) = pos(3)-3;
            if isempty(column_uicontextmenu)
              column_uicontextmenu = findobj(fig,'tag','colrowmenu');
            end
          else
            if row==0
              strng = [num2str(col+coloffset)];
              if ~isempty(collabels);
                lbl = deblank(collabels(col+coloffset,:));
                if ~isempty(lbl);
                  strng = [strng ': ' lbl];
                end
              end
              tooltip = strng;
              style = 'togglebutton';
              value = 0;
              callback = 'editds(''table'',''toggleindex'',gcbf)';
              if linkselections
                value = ismember(col+coloffset,dataid.properties.selection{2});    %%%For shareddata/selection code
              else
                value = 0;
              end
              if isempty(colclr)
                clr = btnclrs{inclmap{2}(col+coloffset)+1}.*(1-value*(1-btndim));
              else
                clr = colclr(col+coloffset,:).*(1-value*(1-btndim));
              end
              if mean(clr)<.5;
                textclr = [1 1 1];
              else
                textclr = [0 0 0];
              end
              if isempty(column_uicontextmenu)
                column_uicontextmenu = findobj(fig,'tag','colrowmenu');
              end
            else
              if inclmap{1}(row+rowoffset) & inclmap{2}(col+coloffset);
                clr = [1 1 1];
              else
                clr = [.9 .9 .9];
              end
              tooltip = '';
              ha  = 'left';
              style = 'edit';
              strng = sprintf(['%' dataformat],double(mydata(row+rowoffset,col+coloffset)));
              callback = 'editds(''table'',''set'',gcbf)';
              column_uicontextmenu = [];
              if ~strictedit
                enb = editable;
              else
                enb = 'inactive';
              end
              textclr = [0 0 0];
            end
          end
          
          tag = ['r' tagbase(row+1) 'c' tagbase(col+1)];
          %           if ~strcmp(action,'update');
          if isfield(handles,tag)
            h = getfield(handles,tag);
          else
            h = uicontrol(handles.editds,...
              'units','pixels',...
              'position',pos,...
              'userdata','table',...
              'style',style,...
              'TooltipString',tooltip,...
              'HorizontalAlignment',ha,...
              'visible','off',...
              'tag',tag,...
              'uicontextmenu',column_uicontextmenu,...
              'callback',callback);
          end
          %           else
          %             h = getfield(handles,tag);
          %           end
          set(h,...
            'position',pos,...
            'fontsize',fontsize,...
            'ForegroundColor',textclr,...
            'backgroundcolor',clr,...
            'TooltipString',tooltip,...
            'HorizontalAlignment',ha,...
            'string',strng,...
            'enable',enb,...
            'value',value);
          
          if checkmlversion('>','6.5')
            set(h, 'keypressfcn','editds(''keypress'',gcbf,[],guidata(gcbf))')
          end
          
        end
      end
      
      %offset slider
      rng    = [0 size(data,1)-nrows];
      value  = rng(2)-rowoffset;
      if value<rng(1); value=rng(1); end
      if value>rng(2); value=rng(2); end
      enb    = 'on';
      if rng(2)==0;
        rng = [0 1];
        enb = 'off';
      end
      step   = [1/rng(2) nrows/rng(2)];
      pos = [(ncols*width+offset*5+gutter+labelwidth)   figsize(4)-(topbuffer)*(height+offset)-(nrows+1)*(height+offset)   sliderwidth   (nrows)*(height+offset)];
      if isfield(handles,'offset')
        h = handles.offset;
        set(h,'position',pos);
      else
        h = uicontrol(handles.editds,'style','slider',...
          'userdata','table',...
          'tag','offset',...
          'visible','off',...
          'units','pixels');
      end
      set(h,...
        'position',pos,...
        'fontsize',fontsize,...
        'enable',enb,...
        'min',rng(1),'max',rng(2),...
        'sliderstep',step,...
        'value',rng(2)-rowoffset,...
        'callback','editds(''table'',''update'',gcbf);');
      
      row = nrows+1;
      %column slider
      rng    = [0 size(data,2)-ncols];
      value  = rng(2)-coloffset;
      if value<rng(1); value=rng(1); end
      if value>rng(2); value=rng(2); end
      enb    = 'on';
      if rng(2)==0;
        rng = [0 1];
        enb = 'off';
      end
      step   = [1/rng(2) ncols/rng(2)];
      pos = [labelwidth+offset+gutter   figsize(4)-(topbuffer)*(height+offset)-(nrows+2)*(height+offset)   width*ncols   height];
      if isfield(handles,'coffset')
        h = handles.coffset;
        set(h,'position',pos);
      else
        h = uicontrol(handles.editds,'style','slider',...
          'userdata','table',...
          'tag','coffset',...
          'visible','off',...
          'units','pixels');
      end
      set(h,...
        'position',pos,...
        'enable',enb,...
        'min',rng(1),'max',rng(2),...
        'fontsize',fontsize,...
        'sliderstep',step,...
        'value',coloffset,...
        'callback','editds(''table'',''update'',gcbf);');
      
      %add row-label pulldown
      pos   = [(0)*width+offset+gutter   figsize(4)-(row+1+topbuffer)*(height+offset)-offset   labelwidth   height+offset*2];
      if ismac
        %pos = [pos(1) pos(2)-2 pos(3) pos(4)-2];
      end
      tag   = 'rowlabelpopup';
      style = 'popup';
      tooltip  = 'Select Row Labels';
      ha       = 'left';
      callback = 'editds(''table'',''update'',gcbf)';
      
      if isfield(handles,tag)
        h = getfield(handles,tag);
      else
        h = uicontrol(handles.editds,...
          'units','pixels',...
          'position',pos,...
          'userdata','table',...
          'style',style,...
          'TooltipString',tooltip,...
          'HorizontalAlignment',ha,...
          'visible','off',...
          'tag',tag,...
          'callback',callback);
      end
      
      list = getavlabels(data,1);
      if length(list)<1
        delete(h);
      else
        set(h,'string',list,'visible','on','position',pos,'fontsize',fontsize);
      end
      
      %did we loose columns (only in data mode here)?
      oldncols = getappdata(fig,'ncols');
      oldnrows = getappdata(fig,'nrows');
      if ~isempty(oldncols) & oldncols>ncols;
        for row=1:oldnrows+1;
          for col = ncols+1:oldncols;
            tag = ['r' tagbase(row) 'c' tagbase(col+1)];
            if isfield(handles,tag);
              delete(handles.(tag));
              handles = rmfield(handles,tag);
            end
          end
        end
        guidata(fig,handles);
      end
      
      
    end
    
    %did we loose rows (for both modes here)?
    oldnrows = getappdata(fig,'nrows');
    if ~isempty(oldnrows) & oldnrows>nrows;
      for row=nrows+1:oldnrows;
        for col = 1:ncols+1
          tag = ['r' tagbase(row+toprows) 'c' tagbase(col)];
          if isfield(handles,tag) & ishandle(handles.(tag))
            delete(handles.(tag));
            handles = rmfield(handles,tag);
          end
        end
      end
      guidata(fig,handles);
    end
    
    %store data and finalize figure settings
    setdataset(fig,data);
    setappdata(fig,'nrows',nrows);
    setappdata(fig,'ncols',ncols);
    setappdata(fig,'mode',mode)
    setappdata(fig,'options',options);
    setappdata(fig,'cellsize',cellsize);
    setappdata(fig,'resized',0)
    guidata(fig,guihandles(fig));
    if ~strcmp(action,'update')
      set(fig,'resize','on','resizefcn','editds(''resize'',gcbf,[],guidata(gcbf));')
    end
    
    h = findobj(fig,'userdata','table');
    if ~isempty(h);
      pos = get(h,'position');
      if checkmlversion('<','6.5');
        for j=1:size(pos,1);
          temp(j,:) = pos{j};
        end
        pos = temp;
      else
        pos = cat(1,pos{:});
      end
      offtop = (pos(:,2)+pos(:,4))>figsize(4);
      if any(offtop);
        set(h(offtop),'visible','off');
      end
      set(h(~offtop),'visible','on');
    end
    
    if strcmp(get(fig,'visible'),'off')
      set(fig,'visible','on');
    end
    
    %--------------------------------------------------------
    % called when the figure is being resized
  case 'resize'
    
    %test if the number of rows to display has changed
    if mode==0
      ncols   = floor(min([size(data,2) (framesize(3)/(cellsize(1)+offset))-1 maxtags]));
      ncols   = max([ncols 1]);
      
      nrows   = floor(min([size(data,1) framesize(4)/(cellsize(2)+offset)-topbuffer-3 maxtags]));
      nrows   = max([nrows 1]);
      
      nrowsnow = getappdata(fig,'nrows');
      ncolsnow = getappdata(fig,'ncols');
      
      %test if the top labels are off top of figure
      tag = ['r' tagbase(1) 'c' tagbase(2)];
      pos = get(getfield(handles,tag),'position');
      
      if ((pos(2)+pos(4)>figsize(4) | nrows~=nrowsnow | ncols~=ncolsnow) & nrows>0 & ncols>0) | (figsize(4)-(pos(2)+pos(4)))>4;
        setappdata(fig,'resized',1);
        %       set(allchild(fig),'visible','off');
        editds('table','update',fig);
      end
      
    else
      width   = framesize(3)/totalrelwidth;
      nrows   = floor(min([size(data,mode) figsize(4)/(cellsize(2)+offset)-toprows-topbuffer-bottomrows maxtags]));
      nrowsnow = getappdata(fig,'nrows');
      
      %test if the top labels are off top of figure
      tag = ['r' tagbase(1) 'c' tagbase(1)];
      pos = get(getfield(handles,tag),'position');
      
      if ((pos(2)+pos(4)>figsize(4) | nrows~=nrowsnow) & nrows>0) | abs(width-cellsize(1))>4 | (figsize(4)-(pos(2)+pos(4)))>6;
        setappdata(fig,'resized',1);
        %       set(allchild(fig),'visible','off');
        editds('table','update',fig);
      end
    end
    
    h = findobj(fig,'userdata','table');
    pos = get(h,'position');
    pos = cat(1,pos{:});
    offtop = (pos(:,2)+pos(:,4))>figsize(4);
    if any(offtop);
      set(h(offtop),'visible','off');
    end
    set(h(~offtop),'visible','on');
    
    %--------------------------------------------------
    % Toggle a row/column indicator for data mode
  case 'toggleindex'
    
    if nargin>2;
      obj = varargin{3};
    else
      obj = gcbo;
    end
    
    %check if shift was pressed when this button was clicked
    lastbutton = getappdata(fig,'lastbutton');
    if ~ishandle(lastbutton)
      lastbutton = obj;
    end
    %     lastkeypress_obj  = getappdata(fig,'lastkeypress_obj');
    %     prevkeypress_obj  = getappdata(fig,'prevkeypress_obj');
    %     if lastkeypress_obj == obj
    %       lastkeypress_obj = prevkeypress_obj;
    %     end
    %     lastbutton = lastkeypress_obj;

    lastkeypress_time = getappdata(fig,'lastkeypress_time');
    shiftselect = isempty(get(fig,'currentcharacter')) ...
      & ~isempty(lastkeypress_time) ...
      & abs(lastkeypress_time-now)<0.5/60/60/24;
    
    if mode == 0
      %data tab
      value = get(obj,'value');
      objlist = [obj];
      if shiftselect
        %if shift (or other non-representing character) is being held down,
        %find all the items between the previously selected item and the
        %one we're on now.
        tag1 = get(lastbutton,'tag');
        tag2 = get(obj,'tag');
        if length(tag1)>1 & length(tag2)>1 & tag1(2)=='0' & tag2(2)=='0'
          %both are column items
          ind = 4;
        elseif length(tag1)>3 & length(tag2)>3 & tag1(4)=='0' & tag2(4)=='0'
          ind = 2;
        else
          ind = [];
        end
        if ~isempty(ind);
          if tag1(ind)>tag2(ind)
            temp = tag2;
            tag2 = tag1;
            tag1 = temp;
          end
          rowlist = find(tagbase==tag1(ind)):find(tagbase==tag2(ind));
          taglist = repmat('r0c0',length(rowlist),1);
          taglist(:,ind) = tagbase(rowlist');
          for k = 1:length(rowlist);
            objlist(k) = findobj(fig,'tag',taglist(k,:));
          end
        end
      end
      
    elseif findstr(get(obj,'tag'),'c0')
      %labels mode - col/row button
      others = setdiff(selectedbtns(fig),obj);
      if ~isempty(others);
        %disable any selected label buttons
        tags = char(get(others,'tag'));
        fieldbtns = others(tags(:,4)~='0');
        set(fieldbtns,'value',0);
      end
      
      value = get(obj,'value');
      objlist = [obj];
      if shiftselect
        %if shift (or other non-representing character) is being held down,
        %find all the items between the previously selected item and the
        %one we're on now.
        tag1 = get(lastbutton,'tag');
        tag2 = get(obj,'tag');
        if tag1(2)>tag2(2)
          temp = tag2;
          tag2 = tag1;
          tag1 = temp;
        end
        rowlist = find(tagbase==tag1(2)):find(tagbase==tag2(2));
        taglist = repmat('r0c0',length(rowlist),1);
        taglist(:,2) = tagbase(rowlist');
        for k = 1:length(rowlist);
          objlist(k) = findobj(fig,'tag',taglist(k,:));
        end
      end
      
    else
      %labels mode - label button
      others = setdiff(selectedbtns(fig),obj);
      set(others,'value',0);
      if ~isempty(others);
        %disable any selected row buttons
        tags = char(get(others,'tag'));
        rowbtns = others(tags(:,4)=='0');
        for btn=rowbtns';
          set(btn,'backgroundcolor',get(btn,'backgroundcolor').*((1/btndim)-get(btn,'value')*((1/btndim)-btndim)));
        end
      end
      objlist = [];
      
    end
    
    %change color of selected items (and make them be "clicked" or
    %"unclicked" as appropriate)
    toselect = {};
    for thisobj = objlist
      if get(thisobj,'value') ~= value | thisobj == obj
        %if not in the correct state (down or up) OR this is the object
        %they clicked, change the color (and maybe value) of the button
        set(thisobj,'value',value);
        clr = get(thisobj,'backgroundcolor').*((1/btndim)-get(thisobj,'value')*((1/btndim)-btndim));
        set(thisobj,'backgroundcolor',clr);
        toselect{end+1} = get(thisobj,'tag');
      end
    end

    %make change in actual selection of object
    if linkselections & ~isempty(toselect)    %%%For shareddata/selection code
      sel = dataid.properties.selection;
      toselect = char(toselect);
      toselect = toselect(:,[2 4]);
      rows = [];
      cols = [];
      for k=1:size(toselect,1);
        rows(k) = find(tagbase==toselect(k,1));
        cols(k) = find(tagbase==toselect(k,2));
      end
      cols = cols(cols>1)-1+coloffset;
      rows = rows(rows>1)-1+rowoffset;
      if mode>0
        rows = rows-3;
        if length(sel)<mode
          sel{mode} = [];
        end
        if value
          sel{mode} = union(sel{mode},rows);
        else
          sel{mode} = setdiff(sel{mode},rows);
        end
      else
        if value
          sel{1} = union(sel{1},rows);
          sel{2} = union(sel{2},cols);
        else
          sel{1} = setdiff(sel{1},rows);
          sel{2} = setdiff(sel{2},cols);
        end
      end
      dataid.properties.selection = sel;
    end
    
    %store this object as the last selected item (used with shfit)
    setappdata(fig,'lastbutton',obj);
    
    colrowmenu(fig,data,handles,obj); %update right-click menu so it is ready for first use
    
    %--------------------------------------------------------
    % Load values for a given field
  case 'load'
    [rowcolbtn,labelbtn] = selectedbtns(gcf);
    col  = getappdata(labelbtn,'field');
    mode = getappdata(gcf,'mode');
    fld  = options.fieldname{col};
    
    %If in classid view (class stings rather than numeric values).
    vset = getappdata(fig,'viewsettings');
    if strcmp(fld,'class') && strcmp(vset.classview,'string')
      fld = 'classid';
    end
    
    %What set is selected?
    seth = findobj(fig,'userdata','table','tag',['c' tagbase(col+1) 'set']);
    if isempty(seth);
      useset = 1;
      nsets = 1;
    else
      useset = get(seth,'value');
      nsets  = length(get(seth,'string'))-1;
    end
    
    %load appropriate type
    hassets = 0;
    switch fld
      case {'axisscale'}
        ldtype = {'double','dataset'};
        hassets = true;
      case 'include'
        ldtype = {'double','dataset' 'logical'};
      case {'label'}
        ldtype = {'char','cell','dataset'};
        hassets = true;
      case {'class'  'classid'}
        ldtype = {'double','char','cell','dataset'};
        hassets = true;
    end
    [new,name,source] = lddlgpls(ldtype,['Load ' fld]);
    lookup = [];
    fromset = 1;
    if strcmp(fld,'classid')
      namefield = 'classname';
      if isnumeric(new)
        new = num2str(new(:));
      end
    else
      namefield = [fld 'name'];
    end
    if ~isempty(new) && isa(new,'dataset');
      source = new;
      if hassets
        %check for multiple sets
        names = get(source,namefield);  %get names for this field
        names = names(mode,:);
        if length(names)>1
          blnames = str2cell(sprintf('Set %i\n',1:length(names)));
          setind = find(cellfun('isempty',names));
          [names{setind}] = deal(blnames{setind});
          fromset = listdlg('ListString',names,'SelectionMode','single','PromptString','Copy from set:','name','Copy set');
          if isempty(fromset)
            return
          end
        else
          %only one set... use it
          fromset = 1;
        end
        newname = get(source,namefield,mode,fromset);
        if strcmp(fld,'class') | strcmp(fld,'classid')
          lookup = get(source,'classlookup',mode,fromset);
        end
      end
      %get value
      new = get(source,fld,mode,fromset);
      if isempty(new);
        erdlgpls({['Corresponding field ' fld ' in selected DataSet was empty'];'Check variable type'},'Unable to load','modal')
      end
    else
      %loaded object directly? set hassets to FALSE so we don't try to load
      %name or classlookup fields
      hassets = false;
    end
    if isempty(new);
      return
    end
    
    if strcmp(fld,'include') & islogical(new); new = find(new); end
    
    fail = 0;
    try
      if hassets
        if (strcmp(fld,'class') | strcmp(fld,'classid')) & ~isempty(lookup)
          set(data,'classlookup',lookup,mode,useset);
        end
        set(data,namefield,newname,mode,useset);
      end
      set(data,fld,new,mode,useset);
    catch
      erdlgpls({['Unable to load selected item into field ' fld];'Check variable size and type'},'Unable to load','modal')
      fail = 1;
    end
    if ~fail
      setdataset(fig,data);
      editds('table','update',fig);
    end
    
    %--------------------------------------------------------
    % Save values from a given field
  case 'save'
    [rowcolbtn,labelbtn] = selectedbtns(gcf);
    col = getappdata(labelbtn,'field');
    mode = getappdata(gcf,'mode');
    fld  = options.fieldname{col};
    
    %If in classid view (class stings rather than numeric values).
    vset = getappdata(fig,'viewsettings');
    if strcmp(fld,'class') && strcmp(vset.classview,'string')
      fld = 'classid';
    end
    
    %find used set and decide if we should use it as a suffix for the variable name
    suffix = [];
    seth = findobj(fig,'userdata','table','tag',['c' tagbase(col+1) 'set']);
    if isempty(seth);
      useset = 1;
      nsets = 1;
    else
      useset = get(seth,'value');
      nsets  = length(get(seth,'string'))-1;
      if nsets > 1;
        suffix = ['set' num2str(useset)];
      end
    end
    
    %get value and do save if not empty
    val = get(data,fld,mode,useset);
    if ~isempty(val);
      svdlgpls(val,['Save ' options.fielddesc{col}],[options.fieldname{col} num2str(mode) suffix]);
    else
      evrimsgbox('Field is empty and cannot be extracted','Extract field','warn','modal');
    end
    
    %--------------------------------------------------------
    % Clear all values in some field
  case 'clear'
    
    [rowcolbtn,labelbtn] = selectedbtns(gcf);
    col = getappdata(labelbtn,'field');
    seth = findobj(fig,'userdata','table','tag',['c' tagbase(col+1) 'set']);
    if isempty(seth);
      useset = 1;
    else
      useset = get(seth,'value');
    end
    
    keyword = '';
    switch options.fieldname{col};
      case 'axisscale'
        if ~isempty(data.axisscale{mode,useset});
          data.axisscale{mode,useset} = [];
          data.axisscalename{mode,useset} = '';
        else
          ox = getappdata(fig,'originaldataset');
          if size(ox.axisscale,2)>=useset;
            data.axisscale{mode,useset} = ox.axisscale{mode,useset};
            data.axisscalename{mode,useset} = ox.axisscalename{mode,useset};
          end
        end
        keyword = 'axisscale';
      case 'class'
        if ~isempty(data.class{mode,useset});
          data.class{mode,useset} = [];
          data.classname{mode,useset} = '';
          %data.classlookup{mode,useset} = {};
        else
          ox = getappdata(fig,'originaldataset');
          if size(ox.class,2)>=useset;
            data.class{mode,useset} = ox.class{mode,useset};
            data.classname{mode,useset} = ox.classname{mode,useset};
            %data.classlookup{mode,useset} = ox.classlookup{mode,useset};
          end
        end
        keyword = 'class';
      case 'label'
        if ~isempty(data.label{mode,useset});
          data.label{mode,useset} = '';
          data.labelname{mode,useset} = '';
        else
          ox = getappdata(fig,'originaldataset');
          if size(ox.label,2)>=useset;
            data.label{mode,useset} = ox.label{mode,useset};
            data.labelname{mode,useset} = ox.labelname{mode,useset};
          end
        end
        keyword = 'label';
      case 'include'
        ox = getappdata(fig,'originaldataset');
        switch length(data.include{mode})
          case 0
            %All excluded so go to original
            if isempty(ox.include{mode})
              %original was all excluded? include all
              data.include{mode} = 1:size(data.data,mode);
            else
              %get original include
              data.include{mode} = ox.include{mode};
            end
          case size(data.data,mode)
            %All included so go to clear.
            data.include{mode} = [];
          case length(ox.include{mode})
            %At original so include all.
            data.include{mode} = 1:size(data.data,mode);
          otherwise
            %include all.
            data.include{mode} = 1:size(data.data,mode);
        end
        keyword = 'include';
    end
    setdataset(fig,data,keyword);
    editds('table','update',fig);
    
    %--------------------------------------------------------
    % Choose a new active set (or create a new one)
  case 'selectset'
    obj = gcbo;
    if nargin>2
      obj = varargin{3};
    end
    newset = get(obj,'value');
    col = getappdata(obj,'field');
    field = options.fieldname{col};
    desc  = options.fielddesc{col};
    
    switch field
      case 'label'
        nsets = size(data.label,2);
      case 'axisscale'
        nsets = size(data.axisscale,2);
      case 'class'
        nsets = size(data.class,2);
    end
    
    if newset>nsets;
      ans = evriquestdlg(['Create a new ' desc ' set?'],'Create new set','Yes','No','Yes');
      if strcmp(ans,'Yes');
        switch field
          case 'label'
            data.label{mode,newset} = '';
          case 'axisscale'
            data.axisscale{mode,newset} = [];
          case 'class'
            data.class{mode,newset} = [];
        end
      else
        set(obj,'value',newset-1);
      end
    end
    
    setdataset(fig,data);
    editds('table','update',fig);
    
    %--------------------------------------------------------
    % Remove active set.
  case 'deletefieldset'
    %Get current field.
    [rowcolbtn,labelbtn] = selectedbtns(fig);
    col     = getappdata(labelbtn,'field');
    fld     = options.fieldname{col};
    
    %Find current set.
    seth = findobj(fig,'userdata','table','tag',['c' tagbase(col+1) 'set']);
    if isempty(seth);
      myset = 1;
    else
      myset = get(seth,'value');
    end
    
    try
      data = rmset(data,fld,mode,myset);
    catch
      erdlgpls(lasterr,'Error Removing Set')
      return
    end
    
    if myset>1 & myset==length(get(seth,'string'))-1
      set(seth,'value',myset-1);
    end
    
    setdataset(fig,data);
    editds('table','update',fig);

    %--------------------------------------------------------
    % Set a value in some field
  case 'set'
    if mode==0; %in 'data' mode
      obj = gcbo;
      rc  = get(obj,'value');
      strng = get(obj,'string');
      val = str2num(strng);
      if isempty(val);
        set(obj,'string',num2str(data.data(rc(1),rc(2))));
      else
        if length(val)>1;
          val = val(1);
        end
        data.data(rc(1),rc(2)) = val;
        set(obj,'string',num2str(val));
        setdataset(fig,data);
      end
      
    else  %lables mode
      
      obj = gcbo;
      rc  = getappdata(obj,'field');
      if ~isstr(rc);
        row   = rc(1);
        col   = rc(2);
        field = options.fieldname{col};
      else
        field = rc;
        col   = find(ismember(options.fieldname,field));
        row   = 0;
      end
      index = rowoffset+row;
      selected = selectedrowscols(fig);
      if ismember(index,selected{mode});
        %changed item is one of the selected rows? Apply change to ALL
        %selected
        index = selected{mode};
      end
      
      seth = findobj(fig,'userdata','table','tag',['c' tagbase(col+1) 'set']);
      if isempty(seth);
        useset = 1;
      else
        useset = get(seth,'value');
      end
      
      refresh = 0;  %we don't need to update ALL displayed fields unless something special happens (such as filling in an otherwise blank field)
      keyword = '';
      try
        switch field
          case 'title'
            data.title{mode} = get(obj,'string');
            keyword = 'title';
            
          case 'axistype'
            val = get(obj,'value');
            opts = get(obj,'string');
            newmode = opts{val};
            if val==1; %'none' is actual mode (no matter what the string says)
              newmode = 'none';
            end
            data.axistype{mode} = newmode;
            keyword = 'axistype';
            
          case 'label'
            if row>0;
              if isempty(data.label{mode,useset})
                temp = cell(0);
                [temp{1:size(data.data,mode),1}] = deal(' ');
                data.label{mode,useset} = temp;
                refresh = 1;
              end
              strng = get(obj,'string');
              if isempty(strng); strng = ' '; end
              lbls = str2cell(data.label{mode,useset});
              [lbls{index}] = deal(strng);
              data.label{mode,useset} = lbls;
              if length(index)>1
                refresh = 1;
              end
            else
              data.labelname{mode,useset} = get(obj,'string');
              refresh = 1;
            end
            keyword = 'label';
            
          case 'axisscale'
            if row>0;
              val = str2double(get(obj,'string'));
              if isempty(val) | isnan(val)
                [val,ok] = datenumplus(get(obj,'string')); %not a simple numeric? try as a date stamp
              end
              if isempty(val)
                val = 0;
              end
              if isempty(data.axisscale{mode,useset})
                data.axisscale{mode,useset} = zeros(size(data.data,mode),1);
                refresh = 1;
              end
              data.axisscale{mode,useset}(index) = val;
              set(obj,'string',sprintf(['%' axisscaleformat],val));
              if length(index)>1
                refresh = 1;
              end
            else
              data.axisscalename{mode,useset} = get(obj,'string');
              refresh = 1;
            end
            keyword = 'label';
            
          case 'class'
            if row>0;
              %Check if class set exists, if not then create one of zeros.
              class_exists = 1;
              if isempty(data.class{mode,useset})
                %Need a default value for loolup table if it doesn't exixt.
                %data.class{mode,useset} = zeros(size(data.data,mode),1);
                lkup = {0 'Class 0'};
                refresh = 1;
                class_exists = 0;
              else
                lkup = data.classlookup{mode,useset};%Get lookup table.
              end
              
              %Class view settings.
              vset = getappdata(fig,'viewsettings');
              viewmode = vset.classview;%'string' or 'numeric'
              
              %Get value.
              valstr = get(obj,'string');%Get object string (cell);
              if ischar(valstr)
                %If only one value then comes back as char, need to convert.
                valstr = {valstr};
              end
              vallst = get(obj,'value');%Get list value.
              val = valstr{vallst};
              
              %Assign value, if new val then show dialog. Allow user to
              %specify new value based on viewmode.
              if strcmp(val,'New Class...')
                newcls = max([lkup{:,1}])+1;
                newname = newclassname(lkup,newcls); %Get new unique name.
                if strcmp(viewmode,'numeric')
                  val = inputdlg({'Enter new class number (default is provided):'},'Create New Class',1,{num2str(newcls)},'on');
                else %String
                  val = inputdlg({'Enter new class name (default is provided):'},'Create New Class',1,{newname{1}},'on');
                end
                if isempty(val)
                  if class_exists
                    %Set class back to original by value.
                    val = {data.class{mode,useset}(index)};
                  else
                    %User canceled and there was no preexisting class so
                    %just return.
                    return
                  end
                else
                  %Need to make new class of zeros now since user has
                  %decided to create the class.
                  if ~class_exists
                    data.class{mode,useset} = zeros(size(data.data,mode),1);
                  end
                end
                
                if strcmp(viewmode,'numeric')
                  %Check numeric value.
                  if any(find(isletter(val{:})));
                    warning('EVRI:EditdsNonNumClassVal','Non numeric chararcter found, using new default value.')
                    val{:} = newcls;
                  else
                    val{:} = str2num(val{:});
                  end
                  data.class{mode,useset}(index) = val{:};
                else
                  %Make new class ahead of time in case user is creating
                  %duplicate name.
                  data.class{mode,useset}(index) = newcls;
                  data.classlookup{mode,useset}.assignstr = {newcls val{:}};
                end
                %for icls = 1:length(val)
                %Assign either string and numeric. DSO will interpret
                %string value as classid assignment.
                %data.class{mode,useset}(index) = val{:};
                %end
                refresh = 1;
              else
                %User made selection so update value.
                
                %There is no sorting so index should correspond to same
                %order in lookuptable.
                %lkup = data.classlookup{mode,useset};
                data.class{mode,useset}(index) = lkup{vallst,1};
                refresh = 1;
              end
              
            else
              data.classname{mode,useset} = get(obj,'string');
              refresh = 1;
            end
            keyword = 'class';
            
          case 'include'
            if get(obj,'value')  %include is turned ON
              data.include{mode} = union(data.include{mode},index);
              
              %change row button color as appropriate
              clr = btnclrs{2};
              set(findobj(fig,'tag',['r' tagbase(row+toprows) 'c0']),'backgroundcolor',clr,'value',0);
              
            else
              data.include{mode} = setdiff(data.include{mode},index);
              
              %change row button color as appropriate
              clr = btnclrs{1};
              set(findobj(fig,'tag',['r' tagbase(row+toprows) 'c0']),'backgroundcolor',clr,'value',0);
              
            end
            keyword = 'include';
            if length(index)>1;
              refresh = 1;
            end
            
        end
        setdataset(fig,data,keyword);
        updateheader(handles)
        
      catch
        erdlgpls(lasterr,'Unable to set','modal')
      end
      if refresh; editds('table','update',fig); end
    end
    if ishandle(fig) & getappdata(fig,'linkselections')  %%%For shareddata/selection code
      %if linking selections, CLEAR selections!!
      mylink = getlink(fig);
      mylink.properties.selection = {[] []};
    end

    %--------------------------------------------------------
  case {'exclude','include','excludeunselected'}
    
    selected = selectedrowscols(gcf);
    switch lower(action)
      case 'exclude'
        for onemode = 1:length(selected);
          data.include{onemode} = setdiff(data.include{onemode},selected{onemode});
        end
      case 'excludeunselected'
        for onemode = 1:length(selected);
          incl = selected{onemode};
          if ~isempty(incl);
            data.include{onemode} = incl;
          end
        end
      case 'include'
        for onemode = 1:length(selected);
          data.include{onemode} = union(data.include{onemode},selected{onemode});
        end
    end
    setdataset(fig,data,'include');
    editdstable('update',fig);
    
    if getappdata(fig,'linkselections')  %%%For shareddata/selection code
      %if linking selections, CLEAR selections!!
      mylink = getlink(fig);
      mylink.properties.selection = {[] []};
    end
    
    %--------------------------------------------------------
  case 'pastefield'
    %paste clipboard into marked field
    
    val      = clipboard('paste');
    if iscell(val);
      val = cat(2,val{:});
    end
    [rowcolbtn,labelbtn] = selectedbtns(fig);
    col     = getappdata(labelbtn,'field');
    fld     = options.fieldname{col};
    
    %If in classid view (class stings rather than numeric values).
    vset = getappdata(fig,'viewsettings');
    if strcmp(fld,'class') && strcmp(vset.classview,'string')
      fld = 'classid';
    end
    
    %find used set and decide if we should use it as a suffix for the variable name
    suffix = [];
    seth = findobj(fig,'userdata','table','tag',['c' tagbase(col+1) 'set']);
    if isempty(seth);
      useset = 1;
      nsets = 1;
    else
      useset = get(seth,'value');
      nsets  = length(get(seth,'string'))-1;
      if nsets > 1;
        suffix = ['set' num2str(useset)];
      end
    end
    
    setname = [];
    val = str2cell(val);  %convert to cell array
    if checkmlversion('>=','7')
      val = strtrim(val);
    end
    if size(val,1)==1 & size(val,2)>1;
      val = val';
    end
    if length(val)==size(data,mode)+1;  %one extra item? Try using it as "name"
      setname = val{1};
      val = val(2:end);
    end
    if ~strcmp(fld,'label') && ~strcmp(fld,'classid')  %if not supposed to be a string, try converting to a number
      if isempty(setname) & isempty(str2num(val{1})) & ~isempty(str2num(val{2}))
        %if we got here without grabbing the setname, then we don't have
        %sufficient elements to fill field, but drop what appears to be a
        %setname anyway, just to see if the length is the ONLY problem.
        setname = val{1};
        val = val(2:end);  %leave whats left (if others are non-numeric, the error below will get triggered)
      end
      val  = char(val);
      nval = str2num(val);        %if not supposed to be a string, try converting to a number
      if isempty(nval) & ~isempty(val)
        if strcmp(fld,'axisscale')
          %try date string
          [nval,ok] = datenumplus(char(val));
          if ~ok
            nval = [];
          end
        elseif strcmp(fld,'class')
          %if this going into class, use unique
          [what,where,nval] = unique(val,'rows');
        end
        if isempty(nval) & ~isempty(val)
          erdlgpls({['Clipboard contents are not appropriate for ' fld],' ','Could not be converted into numeric values'},['Paste'],'modal');
          return
        end
      end
      val = nval;
    else   %try convert string to cell array
      if size(val,2)>1;
        val = val(:,1);   %drop extra columns
      end
    end
    
    %set value if we can
    try
      set(data,fld,val,mode,useset);
    catch
      err = lasterr;
      erdlgpls({['Clipboard contents are not appropriate for ' fld],' ',err(max(find(err==10))+1:end)},['Paste'],'modal');
      return
    end
    try
      if ~isempty(setname) && ~strcmp(fld,'classid')
        set(data,[fld 'name'],setname,mode,useset);
      elseif strcmp(fld,'classid')
        set(data,['class' 'name'],setname,mode,useset);
      end
    catch
      %no error if we can't paste the field name
    end
    setdataset(fig,data);
    editdstable('update',fig);
    
    %--------------------------------------------------------
  otherwise
    disp([action ' : action not yet defined'])
    
end

if ishandle(fig); set(fig,'pointer','arrow'); end

%------------------------------------------------
function [list,listlookup] = getavlabels(data,mode)

%get label sets
lbls = data.label(mode,:);
hasset = find(~cellfun('isempty',lbls));
if ~isempty(hasset)
  lblname = data.labelname(mode,:);
  for j=find(cellfun('isempty',lblname))
    lblname{j} = sprintf('Label Set %i',j);
  end
  list = lblname(hasset);
  listlookup = [repmat({'label'},length(hasset),1) num2cell(hasset(:))];
else
  list = {};
  listlookup = {};
end

%get class sets
lbls = data.class(mode,:);
hasset = find(~cellfun('isempty',lbls));
if ~isempty(hasset)
  lblname = data.classname(mode,:);
  for j=find(cellfun('isempty',lblname))
    lblname{j} = sprintf('Class Set %i',j);
  end
  list = [list lblname(hasset)];
  listlookup = [listlookup; [repmat({'class'},length(hasset),1) num2cell(hasset(:))]];
end

%get axisscale sets
lbls = data.axisscale(mode,:);
hasset = find(~cellfun('isempty',lbls));
if ~isempty(hasset)
  lblname = data.axisscalename(mode,:);
  for j=find(cellfun('isempty',lblname))
    lblname{j} = sprintf('Axisscale Set %i',j);
  end
  list = [list lblname(hasset)];
  listlookup = [listlookup; [repmat({'axisscale'},length(hasset),1) num2cell(hasset(:))]];
end

suffix = '';
prefix = '';
if mode==1
  prefix = '^ ';
elseif mode==2
  suffix = ' >';
end
for j=1:length(list);
  list{j} = [prefix list{j} suffix];
end
    

%------------------------------------------------
function [labels,clr] = getavcontent(data,mode,field,useset,axisscaleformat)

switch field
  case 'label'
    labels = data.label{mode,useset};
    clr    = [];
    
  case 'class'
    labels   = char(data.classid{mode,useset});%data.label{1};
    value       = data.class{mode,useset};
    classlookup = data.classlookup{mode,useset};
    
    classlookup_numbers = [classlookup{:,1}];
    classclrs           = classcolors;
    [junk,junk,clrorder]= intersect(classlookup_numbers,orderclasses(classlookup_numbers));
    clr = classclrs(mod(clrorder(mod((value-1),length(clrorder))+1)-1,size(classclrs,1))+1,:);
    
  case 'axisscale'
    labels = char(str2cell(sprintf(['%' axisscaleformat '\n'],data.axisscale{mode,useset}')));
    clr    = [];
    
  otherwise
    labels = '';
    clr = [];
    
end

if ismac
  clr = [];
end

%------------------------------------------------
function data = Figure_resize(fig,data,handles,auxdata);

%Workaround for Matlab/Mac bug, resize fuction .
if ~ispc & checkmlversion('<','7.10')
  %Seems to be fixed in newer versions Matlab so don't run through this
  %code for 2010a and newer. This code causes problems in 2011b on Mac.
  count = 1;
  while 1
    figsize1 = get(handles.editds,'Position');
    pause(1);
    figsize2 = get(handles.editds,'Position');
    if figsize1 == figsize2
      break
    elseif count == 100%Counter just in case get stuck in loop.
      break
    end
    count = count + 1;
  end
end

%------------------------------------------------
function data = resize(fig,data,handles,auxdata)

minwidth = 440; %minimum width of frames

scl = getdefaultfontsize('normal')/10;
minwidth = minwidth*scl;

set(fig,'units','pixels');
figpos = get(fig,'position');

if any(figpos(3:4)<=0);  %don't do anything if figure is zero height or width
  return;
end

pos = get(handles.infotab,'position');%[left bottom width height]
fpos = get(handles.frame1,'position');
set(handles.frame1,'visible','on');

modehandles = [handles.infotab];
if isfield(handles,'plottab'); modehandles(end+1) = handles.plottab; end
if ~isempty(data) & ~isempty(data.data);
  nmodes = ndims(data); %length(size(data.data));
  if nmodes>0;
    for n = 0:nmodes;
      tag = ['mode' num2str(n)];
      if isfield(handles,tag);
        modehandles(end+1) = getfield(handles,tag);
      end
    end
  end
end

%move header items up to top of window
offset = figpos(4)-pos(2)-pos(4)-2;%figure(height) - tab(bottom) - tab(height) - 2 pixel seperationfrom top.
offset = offset./figpos(4);
if offset~=0;
  h = [modehandles handles.historytext handles.cancelauthor handles.cancelname handles.canceldescription handles.editdescription handles.editauthor ...
    handles.editname handles.userdata handles.history handles.description handles.descriptiontext handles.userdatatext handles.header handles.headertext ...
    handles.author handles.name handles.authortext handles.nametext];
  remapfig([0 0 1 1],[0 offset 1 1],fig,h);
end

%get text width and height info
ext = get(handles.authortext,'extent');
adjustpos(handles.authortext,[0 0 ext(3)+10 0],[1 1 0 1])
adjustpos(handles.nametext,[0 0 ext(3)+10 0],[1 1 0 1])
dext = get(handles.descriptiontext,'extent');
adjustpos(handles.descriptiontext,[5 0 dext(3)+10 0],[0 1 0 1])

%header height
dext = get(handles.headertext,'extent');
dpos = get(handles.headertext,'position');
pos = get(handles.header,'position');
pos(2) = pos(2)+pos(4)-dext(4);
pos(4) = dext(4);
pos(1) = dpos(1)+dext(3)+5;
set(handles.header,'position',pos);
dpos(2) = dpos(2)+dpos(4)-dext(4);
dpos(4) = dext(4);
dpos(3) = dext(3)+5;
set(handles.headertext,'position',dpos);

%adjust description header and body for height
dtpos = get(handles.descriptiontext,'position');
dtpos(2) = pos(2)-dtpos(4)-5;
set(handles.descriptiontext,'position',dtpos);
adjustpos(handles.canceldescription,[0 dtpos(2) 0 0],[1 0 1 1]);
adjustpos(handles.editdescription,[0 dtpos(2) 0 0],[1 0 1 1]);
dpos = get(handles.description,'position');
dpos(4) = max(20,dtpos(2)-5);
dpos(2) = min(dtpos(2)-5-dpos(4),2);
set(handles.description,'position',dpos);

%make header items appropriate width
figpos(3) = max(figpos(3),minwidth);

%move these relative to the edge of the frame
for h = [handles.cancelauthor handles.cancelname handles.userdata handles.history handles.canceldescription];
  set(h,'units','pixels');
  pos = get(h,'position');
  pos(1) = figpos(3)-pos(3)-4;
  bwidth = pos(3);
  set(h,'position',pos);
end
for h = [handles.historytext handles.editauthor handles.editname handles.userdatatext handles.editdescription ];
  set(h,'units','pixels');
  pos = get(h,'position');
  pos(1) = figpos(3)-pos(3)-bwidth-4;
  set(h,'position',pos);
end

%shrink these relative to objects on sides
pos = get(handles.editauthor,'position');
right = pos(1)-fpos(1);
left =  ext(3)+20*scl;
for h = [handles.author handles.name];
  pos = get(h,'position');
  pos(1) = left;
  pos(3) = right-left;
  set(h,'position',pos);
end

%shrink these relative to frame edge
for h = [handles.description handles.header];
  pos = get(h,'position');
  pos(3) = fpos(3)-pos(1)*2;
  set(h,'position',pos);
end

%make description stretch to bottom of frame
pos = get(handles.description,'position');
newheight = pos(4)+pos(2)-pos(1);  %bottom = bottom + offset from bottom - buffer
if newheight>20  %but don't let it get smaller than 20 pixels (just leave it alone if it is)
  pos(4) = newheight;
  pos(2) = pos(1);
  set(handles.description,'position',pos);
end

%move frame to cover entire window height (below mode buttons)
itpos = get(handles.infotab,'position');
fpos(2) = min([1 pos(2)]);
fpos(4) = itpos(2)-fpos(2);
fpos(3) = max(minwidth,figpos(3)-fpos(1)*2);
set(handles.frame1,'position',fpos);

editdstable('resize',fig);

%------------------------------------------------
function adjustpos(h,delta,scale)
if nargin<3
  scale = [1 1 1 1];
end
mpos = get(h,'position');
mpos = mpos.*scale+delta;
set(h,'position',mpos);


%------------------------------------------------
function scrollWheelCallback(h,action,varargin)
  
handles = guidata(h);
oh = findobj(h,'tag','offset');
coh = findobj(h,'tag','coffset');

sdir = action.VerticalScrollCount;
samount = action.VerticalScrollAmount;
if ~isempty(oh)
  value = get(oh,'value');
  mx = get(oh,'max');
  if (sdir<0 & value<mx) | (sdir>0 & value>0)
    value = value-(samount*sdir);
    value = min(max(0,value),mx);
    set(oh,'value',value);
    editds('table','update',gcbf);
  end
end

%------------------------------------------------
function data = setmode(fig,data,handles,auxdata);

oldmode = getappdata(fig,'mode');

if nargin==4;
  if auxdata>ndims(data)
    %Change newmode to 0 if exceeds ndims of data so won't cause error of
    %nonexistant tab.
    newmode = 0;
  else
    newmode = auxdata;
  end
  forceupdate = false;
else
  if oldmode>ndims(data)
    %Change newmode to 0 if exceeds ndims of data so won't cause error of
    %nonexistant tab.
    newmode = 0;
  else
    newmode = oldmode;
  end
  forceupdate = true;
end
clr     = get(handles.frame1,'backgroundcolor');

if getappdata(handles.editds,'asraw');
  newmode = 0;
end
if ~isempty(newmode) & newmode==-1
  newmode = [];
end
disallowedmodes = getappdata(fig,'disallowedmodes');
if (isempty(newmode) & ismember(-1,disallowedmodes)) | ismember(newmode,disallowedmodes)
  %not one of the allowed modes, don't do it!
  newmode = oldmode;
end

modebtn = [];
if ~isempty(newmode);
  %locate the new mode's button
  tag = ['mode' num2str(newmode)];
  if isfield(handles,tag)
    modebtn = getfield(handles,tag);
  end
  if isempty(oldmode);
    set(findobj(fig,'userdata','info'),'visible','off');
  end
else
  modebtn = handles.infotab;
  if ~isempty(oldmode);
    set(findobj(fig,'userdata','info'),'visible','on');
    set([handles.cancelname handles.cancelauthor handles.canceldescription],'visible','off');
    if getappdata(fig,'noedit')
      vis = 'off';
    else
      vis = 'on';
    end
    set([handles.editname handles.editauthor handles.editdescription],'visible',vis)
  end
end
set(modebtn,'value',0);

%activate/deactivate appropriate tabs
h = [handles.infotab];
if isfield(handles,'plottab'); h(end+1) = handles.plottab; end
if ~isempty(data.data);
  nmodes = ndims(data); %length(size(data.data));
  for n = 0:nmodes;
    tag      = ['mode' num2str(n)];
    if isfield(handles,tag);
      h(end+1) = getfield(handles,tag);
    end
  end
end
set(h,'backgroundcolor',clr.*.8,'value',0);

set(modebtn,'backgroundcolor',clr,'value',0);

if isfield(handles,'tabcover') & ishandle(handles.tabcover);
  delete(handles.tabcover)
end
guidata(fig,handles);

set(fig,'pointer','watch')

%Update table as necessary
if ispc
  %No drawnow for Mac/Matlab bug.
  drawnow
end
editdstable(fig,newmode);
drawnow

try
  set(fig,'pointer','arrow')
catch
end

%-----------------------------------------------------
function data = dsesavedata(fig,data,handles,auxdata);
data = filesave(fig,data,handles,auxdata);

%-----------------------------------------------------
function data = dsedeselect(fig,data,handles,auxdata);

mylink = getlink(fig);
mylink.properties.selection = cell(1,ndims(mylink.object));

function data = cmdeselectall(fig,data,handles,auxdata)
data = dsedeselect(fig,data,handles,auxdata);

%-----------------------------------------------------
function [data,randVect,undoVect] = dseshuffle(fig,data,handles,undoVect)
undoVect=getappdata(fig,'undoVect');
vDim=getappdata(fig,'vDim');
und = findobj(fig,'tag','dseundoshuffle');

if ~(isempty(undoVect))% & isempty(vDim)) % undo last shuffle.
  [data,randVect,undoVect]=shuffle(data,vDim,undoVect);
end
vDim = inputdlg('Enter the dimension to shuffle','Input',1);
% check vDim
if isempty(vDim)
  return;
else
  vDim=vDim{:};
  vDim = str2double(vDim);
end
if (vDim> length(size(data))) | (vDim<1)
  error('Invalid mode selected for shuffling data');
end

% Shuffle data
[data,randVect,undoVect]=shuffle(data,vDim,[]);
setappdata(fig,'vDim',vDim);
setappdata(fig,'undoVect',undoVect);
set(und,'Enable','on');

mylink = setdataset(fig,data);

if vDim == 1
  propagateblockchanges(mylink,randVect,'sort',vDim);
end

function [data,undoVect] = dseundoshuffle(fig,data,handles,undoVect)

vDim=getappdata(fig,'vDim');
data=shuffle(data,vDim,undoVect);
fixVect = undoVect;
undoVect=[];
setappdata(fig,'undoVect',undoVect);
und = findobj(fig,'tag','dseundoshuffle');
set(und,'Enable','off');
mylink = setdataset(fig,data);

if vDim == 1
  propagateblockchanges(mylink,fixVect,'sort',vDim);
end


%-----------------------------------------------------
function data = filesave(fig,data,handles,auxdata);

name = getappdata(fig,'varname');
if getappdata(fig,'asraw');
  datatosave = data.data;
else
  datatosave = data;
end
outname = svdlgpls(datatosave,'Save DataSet as',name);
if ~isempty(outname);
  setappdata(fig,'originaldataset',data);
  setappdata(fig,'moddate',data.moddate);
  setvarname(fig,outname)
  update(fig,data,handles,auxdata);
end

%-----------------------------------------------------
function data = fileload(fig,data,handles,auxdata);

forcecombinemode = '';
if isempty(auxdata)
  if getappdata(fig,'asraw');
    filetype = 'double';
  else
    filetype = '*';
  end
  [new,name,source] = lddlgpls(filetype,'Load DataSet');
else
  name = '';
  source = 'unknown';
  if isa(auxdata,'cell');
    new = auxdata{1};
    if length(auxdata)>1
      name = auxdata{2};
    end
    if length(auxdata)>2
      source = auxdata{3};
    end
    if length(auxdata)>3
      forcecombinemode = auxdata{4};
    end
  else
    new = auxdata;
  end
  if ~isempty(new) & isempty(name) & isa(new,'dataset')
    name = new.name;
  end
end

if isempty(new);
  return
end

if ~isempty(data.data) | ~isa(new,'dataset');
  data = fileimport(fig,data,handles,new,name,source,forcecombinemode);
else
  setvarname(fig,name)
  data = new;
  setdataset(fig,data);
  setappdata(fig,'originaldataset',data);
  if isempty(source);
    setappdata(fig,'moddate',data.moddate)
  end
  initialize(handles,data);
  data = [];  %don't check date back in main loop
end

%-----------------------------------------------------
function data = fileimporttype(fig,data,handles,auxdata,varargin);

[new,name,source] = autoimport(get(gcbo,'userdata'));
if ~isempty(new);
  fileimport(fig,data,handles,new,name,source);
end

%-----------------------------------------------------
function data = fileimportselect(fig,data,handles,auxdata,varargin);

[new,name,source] = autoimport;
if ~isempty(new);
  fileimport(fig,data,handles,new,name,source);
end

% importmethods = editds_defaultimportmethods;
% from = listdlg('ListString',...
%   importmethods(:,1)',...
%   'ListSize',[230 180],...
%   'SelectionMode','single',...
%   'PromptString','Import From:',...
%   'Name','Import');
%
% if ~isempty(from)
%   feval(importmethods{from,2},fig,data,handles,auxdata,varargin{:});
% end

%-----------------------------------------------------
function data = fileimport(fig,data,handles,auxdata,varargin);
%varargin can contain {data 'dataname' 'sourcename' 'forcecombinemethod'}
%  where forcecombinemethod is the string describing if a particular combine
%  mode should be forced (overwrite, augment...)

if isempty(auxdata)
  [newdata,name,source] = lddlgpls('*','Create DataSet from');
  forcecombinemethod = '';
else
  %data passed
  newdata = auxdata;
  %was variable name passed to us from caller?
  if ~isempty(varargin)
    name = varargin{1};
  elseif isa(newdata,'dataset')
    name = newdata.name;    %no, use dataset name (if any)
  else
    name = '';
  end
  if length(varargin)>1
    source = varargin{2};
  else
    source = 'unknown';
  end
  if length(varargin)>2
    forcecombinemethod = varargin{3};
  else
    forcecombinemethod = '';
  end
end

switch class(newdata)
  case 'dataset'
    %all set.
  case {'char','cell'}
    %try adding labels to existing data
    if iscell(newdata);
      %column-vectorize cell
      newdata = newdata(:);
    end
    matchmode = 1*(size(newdata,1)==size(data,1)) + 2*(size(newdata,1)==size(data,2));
    if matchmode>0
      if matchmode == 3;
        %BOTH matched!
        matchmode = evriquestdlg('Which mode do you want to add these labels to?','Add Labels To...','Rows','Columns','Cancel','Rows');
        switch matchmode
          case 'Rows'
            matchmode = 1;
          case 'Columns'
            matchmode = 2;
          case 'Cancel'
            return
        end
      end
      nsets = size(data.label,2);
      for setind = 1:nsets+1;
        if setind > nsets || isempty(data.label{matchmode,setind})
          try
            data.label{matchmode,setind} = newdata;
            break;
          catch
            erdlgpls(lasterr,'Load error','modal');
            return
          end
        end
      end
      setdataset(fig,data);
      setappdata(fig,'originaldataset',data);
      editdstable('resize',fig);
      evrimsgbox(['Character array added as new set of labels on mode ' num2str(matchmode) ],'Labels added','help','modal');
    else
      erdlgpls('Character array does not match the size of any mode of the data. Labels not added.','Labels Not Added');
    end
    return
    
  otherwise
    %try making dataset out of input
    try
      newdata = dataset(newdata);
      newdata.name = '';
    catch
      erdlgpls(lasterr,'Load error','modal');
      return
    end
end

if isempty(newdata);
  return
end

%if we already had data, see if we can concatenate in any direction
if ~isempty(data.data);
  match = getmatchdims(data,newdata);
  if strictedit
    method = evriquestdlg('Do you want to overwrite exsiting data or open the data in a new window?', ...
      'Overwrite Existing Data?', ...
      'Overwrite','New Window','Cancel','Overwrite');
    if strcmp(method,'Cancel')
      return
    end
  elseif ~any(match)
    method = evriquestdlg('New data does not match existing data. Do you want to overwrite exsiting data or open the data in a new window?', ...
      'Overwrite Existing Data?', ...
      'Overwrite','New Window','Cancel','Overwrite');
    if strcmp(method,'Cancel')
      return
    end
  else
    if ~isempty(forcecombinemethod)
      method = forcecombinemethod;
    else
      method = evriquestdlg('New data matches size of existing data. Do you want to overwrite or augment the existing data?', ...
        'Overwrite Existing Data?', ...
        'Overwrite','Augment','Cancel','Overwrite');
    end
    if strcmp(method,'Cancel')
      return
    end
  end
else
  method = 'overwrite';
end

try
  if ~isa(newdata,'dataset');
    newdata = dataset(newdata);
    newdata.name = name;
    if isempty(newdata.description) & ~isempty(source);
      newdata.description = ['Variable ' name ' from file ' source ];
    end
  end
  switch lower(method)
    case 'overwrite'
      data = newdata;
      setvarname(fig,name)
      if ~isempty(source);
        setappdata(fig,'moddate',data.moddate-1);  %force date to indicate "needs saving"
      else
        setappdata(fig,'moddate',data.moddate);
      end
    case 'new window'
      newfig = editds;
      editds('fileload',newfig,{newdata name source});
      editds('update',newfig);
      return
    otherwise
      %Augment
      data = augment(-1,data,newdata);
      if isempty(data)
        return
      end
      setvarname(fig,[])
  end
catch
  erdlgpls('Unable to create DataSet from selected data','Load error','modal');
  return
end
setdataset(fig,data);
setappdata(fig,'originaldataset',data);
initialize(handles,data);

%-----------------------------------------------------
function match = getmatchdims(data,newdata)
%GETMATCHDIMS Get matching dims for two size vectors.

szA = size(data); %size(data.data);
szA(end+1) = 1;              %allow for
szB = size(newdata);
szB(end+1:length(szA)) = 1;  %fill in remaining lengths
szA(end+1:length(szB)) = 1;  %fill in remaining lengths
match = szB.*0;     %flag indicating if a given dim can be concated.
for j=1:length(szA);
  dims = setdiff(1:length(szB),j);  %dims which must match
  %enough dims?
  if max(dims)<=length(szA)
    match(j) = all(szA(dims)==szB(dims));
  end
end
match(1) = true;  %ALWAYS allow rows (matchvars will try to reconcile)

%-----------------------------------------------------
function data = labelmenu(fig,data,handles,auxdata);

data = colrowmenu(fig,data,handles,auxdata);  %rest is same as colrowmenu
drawnow;

%---------------------------------------------------
function data = colrowmenu(fig,data,handles,auxdata);

if isempty(auxdata)
  mybtn = gco;
  if ~get(mybtn,'value')
    set(mybtn,'value',1);
    editdstable('toggleindex',fig,mybtn);
  end
else
  mybtn = auxdata;
end

[rowcolbtn,labelbtn] = selectedbtns(fig);
mode = getappdata(fig,'mode');
noedit = getappdata(fig,'noedit');

asraw = getappdata(handles.editds,'asraw');
if isempty(asraw); asraw = 0; end

% %store the row/col index of this button
%NOTE: This code disabled because we don't yet use the 'rightclicked'
%property anywhere. But we are leaving this here in case we discover a good
%use for it.
% rowoffset = round(get(handles.offset,'max')-get(handles.offset,'value'));
% if mode==0
%   coloffset = round(get(handles.coffset,'value'));
% else
%   rowoffset = rowoffset -3;
%   coloffset = 0;
% end
% toselect = char(get(mybtn,'tag'));
% toselect = toselect(:,[2 4]);
% rows = find(tagbase==toselect(1,1));
% cols = find(tagbase==toselect(1,2));
% rows = rows(rows>1)-1+rowoffset;
% cols = cols(cols>1)-1+coloffset;
% if mode==0
%   rc = {rows cols};
% else
%   rc = {[] []};
%   rc{mode} = rows;
% end
% setappdata(fig,'rightclicked',rc);

%paste option
if noedit | (mode==0 & strictedit)
  enb = 'off';
else
  enb = 'on';
end
set(handles.editpaste,'enable',enb);

%View Statistics
if ~isempty(data);
  enb = 'on';
else
  enb = 'off';
end
set(handles.cmviewstatistics,'enable','on');

%decide on fill with value
if prod(size(data))==0 | strcmp(data.type,'batch') | noedit | strictedit;
  enb = 'off';
else
  enb = 'on';
end
set([handles.editfill],'enable',enb);

%decide on arithmetic
if prod(size(data))==0 | strcmp(data.type,'batch') | noedit | strictedit;
  enb = 'off';
else
  enb = 'on';
end
set([handles.editarithmetic],'enable',enb);

%edit field option
if noedit | isempty(labelbtn)
  enb = 'off';
  fld = '';
  lbl = ['E&dit field'];
  lbl2 = '&Delete Field Set';
else
  enb = 'on';
  fld = get(labelbtn,'string');
  lbl = ['E&dit ' fld];
  lbl2 = ['&Delete ' fld ' Set'];
end

set([handles.editeditfield],'enable',enb,'label',lbl);

%Exception for include field which cannot be removed. 
if strcmpi(fld,'incl.')
  enb = 'off';
end
set([handles.editdeletefieldset],'enable',enb,'label',lbl2)

%Decide on Clear/Reset menu
if isempty(labelbtn) | ~get(mybtn,'value');
  enb = {'off' 'off' 'off' 'off'};
  lbl = {'L&oad Field','E&xtract Field'};
else
  enb = {'on' 'on' 'on' 'on'};
  if noedit
    enb = {'off' 'off' 'on' 'off'};
  end
  fld = get(labelbtn,'string');
  lbl = {['L&oad ' fld],['E&xtract ' fld]};
  if ~strcmp(fld,'Class')
    enb{4} = 'off';
  end
end
set(handles.editclear,'enable',enb{1});
set(handles.fileloadfield,'enable',enb{2},'label',lbl{1});
set(handles.filesavefield,'enable',enb{3},'label',lbl{2});
set(handles.editlookuptable,'enable',enb{4},'visible',enb{4});

%Class view settings.
vset = getappdata(fig,'viewsettings');
if strcmp(vset.classview,'numeric')
  ch = 'on';
else
  ch = 'off';
end
set(handles.changeclassview,'checked',ch,'enable',enb{4},'visible',enb{4});  %visibility and enable set from above

%Decide on include options
if isempty(rowcolbtn) | asraw | noedit;
  enb = 'off';
else
  enb = 'on';
end
set([handles.editinclude handles.editexclude handles.editexcludeunselected],'enable',enb);

if mode>0 & ~noedit & ~asraw
  enb = 'on';
else
  enb = 'off';
end
set([handles.editbulkinclude],'enable',enb);

%Decide on "make field from data" options
if isempty(rowcolbtn) | ~isempty(labelbtn) | asraw | noedit  | strictedit  | ndims(data)>2
  enb = 'off';
else
  enb = 'on';
end
set([handles.editmakeaxisscale handles.editmakeclass handles.editmakeinclude],'enable',enb);
set(handles.editmakedata,'enable','off');

if strcmp(get(labelbtn,'string'),'Incl.') | asraw | noedit | (mode==0 & (strictedit | ndims(data)>2))
  enb = 'off';
else
  enb = 'on';
end
set([handles.editsortby_a handles.editsortby_d],'enable',enb);

%special case of make class (when labels is selected)
if ~isempty(mode) & mode>0 & ~isempty(labelbtn) & ~asraw & ~noedit & strcmp(get(labelbtn,'string'),'Label')
  set([handles.editmakeclass handles.editmakedata],'enable','on');
end

if ~isempty(mode) & ndims(data)<=2 & mode>0 & ~isempty(labelbtn) & ~asraw & ~noedit & (strcmpi(get(labelbtn,'string'),'Class') | strcmpi(get(labelbtn,'string'),'Axis Scale'))
  set([handles.editmakedata],'enable','on');
end

if strictedit
  set(handles.fileextract,'enable','off')
end

if isempty(mode) | mode==0
  enb = 'off';
else
  enb = 'on';
end
set([handles.editbulkselection handles.editselectclass],'enable',enb);

%----------------------------------------------------------------------
%return the currently selected row/col and label buttons (or just all
%currently selected buttons if only one output is given:
% buttons = selectedbtns(fig);  %all selected button handles
% [rowcolbtn,labelbtn] = selectedbtns(fig);  %selected button handles, sorted
function [rowcolbtn,labelbtn] = selectedbtns(fig);

mode = getappdata(fig,'mode');

% disp('line 3185 editds: start using shareddata object to get selection')
btns = findobj(fig,'style','togglebutton','userdata','table','value',1);
if nargout == 1;
  rowcolbtn = btns;
  return
end
if isempty(mode) | isempty(btns);
  rowcolbtn = [];
  labelbtn  = [];
elseif mode==0
  rowcolbtn = btns;
  labelbtn  = [];
else
  tags = char(get(btns,'tag'));
  rowcolbtn = btns(tags(:,4)=='0');
  labelbtn  = btns(tags(:,4)~='0');
end

%-------------------------------------------------------------------------
%return a cell object containing the currently selected rows and columns
function selected = selectedrowscols(fig);

mode = getappdata(fig,'mode');

[data] = getdataset(fig);
selected = cell(1,ndims(data));

if isempty(mode); return; end   %on info tab? consider nothing selected

if getappdata(fig,'linkselections')  %%%For shareddata/selection code
  %if linking selections, use selection property on shared data instead of
  %button status
  mylink = getlink(fig);
  sel = mylink.properties.selection;

  %copy over relevant mode(s)
  if mode==0
    selected = sel;
  elseif length(sel)>=mode
    selected{mode} = sel{mode};
  end
  return
end

handles = guidata(fig);
rowoffset = round(get(handles.offset,'max')-get(handles.offset,'value'));

[rowcolbtn,labelbtn] = selectedbtns(fig);
tags = char(get(rowcolbtn,'tag'));

if isempty(tags); return; end  %nothing selected, return empty

r = tags(:,2);
c = tags(:,4);
if mode==0;
  coloffset = round(get(handles.coffset,'value'));
  
  %identify selected rows
  rows = r(c=='0');
  for k=1:length(rows);
    rows(k) = find(tagbase==rows(k));
  end
  rows = double(rows)-1+rowoffset;
  
  %identify selected columns
  cols = c(r=='0');
  for k=1:length(cols);
    cols(k) = find(tagbase==cols(k));
  end
  cols = double(cols)-1+coloffset;
  
  selected = {sort(rows) sort(cols)};
  %EVENTUALLY REPLACE WITH:    selected(1:2) = {sort(rows) sort(cols)};

else
  %mode X screen look at rows only (and insert into approp. cell of selected)
  rows = r(c=='0');
  for k=1:length(rows);
    rows(k) = find(tagbase==rows(k));
  end
  rows = double(rows)-4+rowoffset;
  
  selected{mode} = sort(rows);
  
end

%-----------------------------------------------------
function data = edit(fig,data,handles,auxdata)

[rowcolbtn,labelbtn] = selectedbtns(fig);

%Find out if there is anything selected.
myselections = selectedrowscols(fig);
anyselections = any(~cellfun(@isempty,myselections));

mode = getappdata(fig,'mode');
noedit = getappdata(fig,'noedit');
asraw = getappdata(handles.editds,'asraw');
history = getappdata(fig,'history');
if isempty(asraw); asraw = 0; end

%undo enabling
if noedit | isempty(history)
  enb = 'off';
else
  enb = 'on';
end
set([handles.editundo],'enable',enb);

if noedit | isempty(mode) | (mode>0 & isempty(labelbtn))
  enb = 'off';
  lbl = ['E&dit field'];
  lbl2 = '&Delete Field Set';
else
  enb = 'on';
  fld = get(labelbtn,'string');
  lbl = ['E&dit ' fld];
  lbl2 = ['&Delete ' fld ' Set'];
end
if strictedit & mode==0
  enb = 'off';
end
set([handles.editpaste],'enable',enb);

enb = 'off';
if ~isempty(mode) & mode>0 & ~isempty(labelbtn) & ~noedit & strcmp(get(labelbtn,'string'),'Class');
  enb = 'on';
end
set([handles.editlookuptable],'enable',enb,'visible','on');

%editfield enabling
if noedit | isempty(labelbtn)
  enb = 'off';
else
  enb = 'on';
end
set([handles.editeditfield],'enable',enb,'label',lbl);
set([handles.editdeletefieldset],'enable',enb,'label',lbl2)

%Decide on Clear/Reset menu
if isempty(labelbtn) | noedit;
  enb = 'off';
else
  enb = 'on';
end
set([handles.editclear],'enable',enb);

%decide on fill with value
if prod(size(data))==0 | strcmp(data.type,'batch') | noedit | strictedit
  enb = 'off';
else
  enb = 'on';
end
set([handles.editfill],'enable',enb);

%decide on arithmetic
if prod(size(data))==0 | strcmp(data.type,'batch') | noedit | strictedit;
  enb = 'off';
else
  enb = 'on';
end
set([handles.editarithmetic],'enable',enb);

%Decide on include options
if ~anyselections | asraw | noedit;
  enb = 'off';
else
  enb = 'on';
end
set([handles.editinclude handles.editexclude handles.editexcludeunselected],'enable',enb);

if prod(size(data))==0 | asraw | noedit;
  enb = 'off';
else
  enb = 'on';
end
set([handles.editexcludemissing],'enable',enb);

if mode>0 & ~noedit & ~asraw
  enb = 'on';
else
  enb = 'off';
end
set([handles.editbulkinclude],'enable',enb);

%Decide on "make field from data" options
if isempty(rowcolbtn) | mode~=0 | asraw | noedit | strictedit | ndims(data)>2;
  enb = 'off';
else
  enb = 'on';
end
set([handles.editmakeaxisscale handles.editmakeclass handles.editmakeinclude],'enable',enb);
set(handles.editmakedata,'enable','off');

if ~isempty(mode) & mode>0 & ~isempty(labelbtn) & ~asraw & ~noedit 
  switch get(labelbtn,'string')
    case 'Label'
      set([handles.editmakeclass handles.editmakedata],'enable','on');
    case {'Axis Scale' 'Class'}
      if ndims(data)<=2
        set([handles.editmakedata],'enable','on');
      end
  end
end

incl = data.include;
for j=1:length(incl);
  sz(j) = length(incl{j});
end
if all(sz==size(data)) | strcmp(data.type,'batch') | noedit | asraw | getappdata(fig,'noharddelete') | strictedit
  enb = 'off';
else
  enb = 'on';
end
set(get(handles.editharddelete,'Children'),'Enable','off')
set([handles.editharddelete handles.editharddeleteall],'enable',enb);

if sz(1)~=size(data,1)
  set(handles.editharddeleterows,'Enable','On')
end

if sz(2)~=size(data,2)
  set(handles.editharddeletecolumns,'Enable','On')
end

datsize = size(data);
if (length(datsize) > 2) && (any(sz(3:end)~=datsize(3:end)))
  set(handles.editharddeleteother,'Enable','On')
end

if  prod(size(data))==0 | asraw | noedit | ~evriio('mia') | ~strcmp(data.type,'image')
  enb = 'off';
else
  enb = 'on';
end
set([handles.editimageaxisscale],'enable',enb, 'visible', enb);

%-----------------------------------------------------
function data = transform(fig,data,handles,auxdata)

[rowcolbtn,labelbtn] = selectedbtns(fig);
mode = getappdata(fig,'mode');
noedit = getappdata(fig,'noedit');
asraw = getappdata(handles.editds,'asraw');
if isempty(asraw); asraw = 0; end

if  prod(size(data))==0 | asraw | noedit | ~evriio('mia')
  enb = 'off';
else
  enb = 'on';
end
set([handles.editmakeimage],'enable',enb);

if prod(size(data))==0 | ndims(data)>2 | noedit
  enb = 'off';
else
  enb = 'on';
end
set(handles.editfold3way,'enable',enb);

if prod(size(data))==0 | ndims(data)<3 |~strcmp(data.type,'data') | asraw | noedit;
  enb = 'off';
else
  enb = 'on';
end
set([handles.editpermute],'enable',enb);

if prod(size(data))==0 | noedit;
  enb = 'off';
else
  enb = 'on';
end
set(handles.editreshape,'enable',enb);
set(handles.editflip, 'enable', enb);

if prod(size(data))==0 | ndims(data)>2 | ~strcmp(data.type,'data') | asraw | noedit;
  enb = 'off';
else
  enb = 'on';
end
set([handles.edittranspose],'enable',enb);


if  (~isempty(rowcolbtn) | (~isempty(mode) & mode>0 & ~isempty(labelbtn) & ~asraw & ~noedit & ~strcmp(get(labelbtn,'string'),'Incl.'))) & ndims(data)<3
  en = 'on';
else
  en = 'off';
end
set([handles.editsortby_a handles.editsortby_d],'enable',en);

if prod(size(data))==0 | noedit
  en = 'off';
else
  en = 'on';
end
set(findobj(handles.transform,'userdata','transformchild'),'enable',en);


%-----------------------------------------------------
function data = editflip(fig, data, handles, auxdata)
szD = size(data);
dimsD = numel(szD);

modestr = '';
if dimsD>2
  for i = 1:dimsD
    modestr = [modestr {['Mode ' num2str(i)]}];
  end
else
  modestr = {'Rows', 'Columns'};
end
[dmode, brtrn] = listdlg('PromptString', 'Select Mode(s) to Flip:', ...
  'SelectionMode', 'multiple', ...
  'ListString', modestr);
if brtrn==0
  return
end

for bb = dmode
  data = flip(data,bb);
end

% setdataset(fig,data);
mode = getappdata(fig, 'mode');

mylink = setdataset(fig,data);
%Apply new index to other block.
if any(dmode==1)
  propagateblockchanges(mylink,[],'flip',[]);
end

if ~isempty(mode)
  editdstable(fig,[]);
end
editdstable(fig,mode);


%-----------------------------------------------------
function data = transformshortcut(fig,data,handles,sh)

if isempty(sh)
  return;
end
switch sh.fn
  case 'coadd'
    [data,opts] = coadd(data);
  case 'unfoldmw'
    data = unfoldmw(data);
    if ~isempty(data)
    setdataset(fig,data);
    origdata = getappdata(fig,'originaldataset');
    setappdata(fig,'originaldataset',origdata);
    mode = getappdata(fig,'mode');
    initialize(handles,data,mode);
    else
      return;
    end
  otherwise
    data = feval(sh.fn,data);
end


%-----------------------------------------------------
function data = file(fig,data,handles,auxdata)

if getappdata(fig,'noedit');
  enb = 'off';
else
  enb = 'on';
end
% set([handles.filenew handles.fileload handles.fileimport handles.fileimgload],'enable',enb);
set([handles.filenew handles.fileload handles.fileimport],'enable',enb);

if isempty(data)
  enb = 'off';
else
  enb = 'on';
end
set(handles.FileExport,'enable',enb);

[rowcolbtn,labelbtn] = selectedbtns(fig);

if ~isempty(labelbtn);
  enb = {'on' 'on'};
  if getappdata(fig,'noedit');
    enb{1} = 'off'; %no load if noedit
  end
  fld = get(labelbtn,'string');
  lbl = {['L&oad ' fld],['E&xtract ' fld]};
else
  enb = {'off' 'off'};
  lbl = {'L&oad Field','E&xtract Field'};
end
set(handles.fileloadfield,'enable',enb{1},'label',lbl{1});
set(handles.filesavefield,'enable',enb{2},'label',lbl{2});

if strictedit
  set(handles.fileextract,'enable','off')
end

dmode = getappdata(fig,'mode');
if dmode >= 1
  enb = 'on';
else
  enb = 'off';
end
set([handles.fileLoadSel_inds handles.fileSaveSel_inds], 'enable', enb);

%-----------------------------------------------------
function filemenubuild(handles)
%Build import menu here instead of dynmaicall in 'file' callback because
%will not work in Mac 2011a.

set(handles.fileimport,'callback','');
delete(allchild(handles.fileimport));
editds_addimportmenu(handles.fileimport,'editds(''menu'',gcbo,[],guidata(gcbf))');

    
%Update list of transform options
%get list of transform options
sh = browse_shortcuts([]);
sh = sh(ismember({sh.type},{'other','transform'}));
sh = sh(~cellfun('isempty',{sh.nargout}));
sh = sh([sh.nargout]>0);
sh = sh(~ismember({sh.fn},{'preprocess'}));

%Remove duplicate names (e.g., reducenn).
[junk,uidx] = unique({sh.name});
sh = sh(uidx);

sep = 'on';
delete(findobj(allchild(handles.transform),'userdata','transformchild'));
for j=1:length(sh);
  h = uimenu(handles.transform,...
    'label',sh(j).name,...
    'tag',['transform_' sh(j).fn],...
    'userdata','transformchild',...
    'separator',sep,...
    'callback',['editds(''transformshortcut'',gcbf,getappdata(gcbo,''info''),guidata(gcbf));']);
  setappdata(h,'info',sh(j));
  sep = 'off';  %separator off for all subsequent items
end

%-----------------------------------------------------
function data = view(fig,data,handles,auxdata);

if ~isempty(data.data);
  enb = 'on';
else
  enb = 'off';
end

%Class view settings.
vset = getappdata(fig,'viewsettings');
if strcmp(vset.classview,'numeric')
  ch = 'on';
else
  ch = 'off';
end
set(handles.changeclassview,'checked',ch);

set([handles.viewstatistics handles.viewclasssummary handles.viewboxplot handles.viewplot handles.changeclassview handles.viewmissingdatamap],'enable',enb);

%-----------------------------------------------------
function data = filenew(fig,data,handles,auxdata);
%called as:
% editds('filenew',fig)
% editds('filenew',fig,size)   %suggest default size

resp = {'', '0'};
if ~isempty(auxdata)
  %size was passed as third input
  resp{1} = num2str(auxdata);
end

new = [];
while isempty(new)
  resp = inputdlg({['Dataset Size. Enter as rows,columns,slabs...):'],['Initial Value (e.g. 0, NaN, rand, randn)']},'Create New Dataset',1,resp);
  if isempty(resp);
    return;
  end
  
  sz = str2num(resp{1});
  if isempty(sz) | any(sz==0);
    erdlgpls('Please specify size as a comma delimited list of positive integer dimension sizes such as ''30,20''','Size not valid');
    resp{1} = [''];
    continue
  end
  if length(sz)==1;
    sz = [1 sz];
  end
  resp{1} = [sprintf('%i, ',sz(1:end-1)) sprintf('%i',sz(end))];
  
  if strcmp(lower(resp{2}),'rand');
    new = dataset(rand(sz));
  elseif strcmp(lower(resp{2}),'randn');
    new = dataset(randn(sz));
  else
    ival = str2num(resp{2});
    if isempty(ival);
      erdlgpls('Please specify initial value as a single valid number such as ''0'', ''1'' or ''NaN''.','Initial Value not valid');
      resp{2} = ['0'];
      continue
    end
    ival = ival(1);
    
    new = dataset(ones(sz)*ival);
  end
end

if ~isempty(data.data);
  data = fileimport(fig,data,handles,new);
else
  data = new;
  data.name = 'New Data';
  setdataset(fig,data);
  setvarname(fig,'');
  setappdata(fig,'originaldataset',data);
  setappdata(fig,'moddate',data.moddate);
  initialize(handles,data);
end

%-----------------------------------------------------
function data = editharddelete(fig,data,handles,auxdata,delmode,mylink)
%Hard deletes data from dataset. Input 'delmode' is switch for deleting all
%excluded samples in particular mode.

if strictedit;
  erdlgpls('Hard Deleting is currently disabled due to strict editing controls.','Feature Not Available')
  return;
end

incl = data.include;

switch delmode
  case 'editharddeleterows'
    dmode = 1;
  case 'editharddeletecolumns'
    dmode = 2;
  case 'editharddeleteother'
    %TODO: Check to see if any data excluded for particular mode, disable
    %if not.
    modestr = '';
    for i = 1:length(incl)
      modestr = [modestr {['Mode ' num2str(i)]}];
    end
    [dmode brtrn] = listdlg('PromptString','Select Mode(s):',...
      'SelectionMode','multiple',...
      'ListString',modestr);
    if brtrn == 0
      return
    end
    %dmode = str2num(dmode{:});
  case 'editharddeleteall'
    dmode = [];
end

if ~isempty(dmode)
  allmodes = 1:length(incl);
  incl(setdiff(allmodes,dmode)) = {':'};
end

for j=1:length(incl);
  sz(j) = length(incl{j});
end
if all(sz==size(data));
  evrimsgbox('No data is excluded. Nothing to delete.','Hard Delete','warn','modal');
  return
end

if strcmp(data.type,'image') && sz(data.imagemode)<size(data,data.imagemode);
  ans = evriquestdlg('This action will remove the Image structure (information) in this DataSet and will permanently remove all excluded data. Are you certain you want to do this?','WARNING: Hard Delete','Yes','Cancel','Yes');
else
  ans = evriquestdlg('This will permanently remove excluded data from this DataSet. Are you certain you want to do this?','WARNING: Hard Delete','Yes','Cancel','Yes');
end

if strcmp(ans,'Yes');
  if any(sz==0);
    data = dataset([]);
  else
    if strcmp(data.type,'image') & sz(data.imagemode)<size(data,data.imagemode) & (isempty(dmode) | dmode==data.imagemode)
      %convert from image to data if excluding in imagemode
      data.type = 'data';
    end
    data = data(incl{:});
    if dmode == 1
      %Propogate row delete.
      propagateblockchanges(mylink,incl{1},'delete',1)
    end
  end
  setdataset(fig,data);
  setappdata(fig,'originaldataset',data);
  if ~isempty(data.data);
    editdstable('resize',fig);
  else
    initialize(handles,data);
  end
end

%-----------------------------------------------------
function data = fileextractdataset(fig,data,handles,auxdata)
data = fileextract(fig,data,handles,'dataset');
%-----------------------------------------------------
function data = fileextractraw(fig,data,handles,auxdata)
data = fileextract(fig,data,handles,'raw');
%-----------------------------------------------------
function data = fileextract(fig,data,handles,auxdata)

selected = selectedrowscols(fig);

for j = 1:length(selected);
  if isempty(selected{j});
    selected{j} = ':';
  end
end
[selected{end+1:ndims(data)}] = deal(':');        %fill in : for ND modes which aren't specified

switch auxdata
  case 'dataset'
    newdata = data(selected{:});
  otherwise
    if strcmp(data.type,'image') && ischar(selected{data.imagemode}) && strcmp(selected{data.imagemode},':')
      %Extract a full image.
      newdata = data.imagedata;
      if ~all(cellfun('isclass',selected,'char')) | ~all(ismember(selected,{':'}));
        othermodes = setdiff(1:ndims(data),data.imagemode);   %modes of unfolded which aren't image
        otherimgmodes = setdiff(1:length(data.foldedsize),data.imagemode+(1:length(data.imagesize))-1);  %modes of FOLDED which aren't image
        newdata = nindex(newdata,selected(othermodes),otherimgmodes);
      end
    else
      newdata = data.data(selected{:});
    end
end
if ~isempty(newdata);
  svdlgpls(newdata,['Save Extracted Data']);
end

%-----------------------------------------------------
function data = fileexportcsv(fig,data,handles,auxdata)

autoexport(data,'csv');

%-----------------------------------------------------
function data = fileexportxml(fig,data,handles,auxdata)

autoexport(data,'xml');

%-----------------------------------------------------
function data = fileexportasf(fig,data,handles,auxdata)

autoexport(data,'asf');

%-----------------------------------------------------
function data = fileexportspc(fig,data,handles,auxdata)

autoexport(data,'spc');

%-----------------------------------------------------
function editoptions(fig)

settings = getappdata(fig);
settings.functionname = 'editds';
opts = {
  'dataformat'        'General' 'char' ''  'novice'        'Formatting string for data. E.g. "0.12g" to give general format with 12 digits of precision. "g" and "f" are recommended formatting characters and n.m is number of total digits plus number of significant digits.';
  'axisscaleformat'   'General' 'char' ''  'novice'        'Formatting string for axis scales. E.g. "0.12g" to give general format with 12 digits of precision. See above.';
  };
settings.definitions = makesubops(opts);
optsout = optionsgui(settings);

if isempty(optsout); return; end  %cancel out

%copy these into appdata:
tocopy = {'dataformat' 'axisscaleformat'};
for j=tocopy
  setappdata(fig,j{:},optsout.(j{:}))
end

editds('table','update',fig);

%-----------------------------------------------------
function data = editcopydata(fig,data,handles,auxdata)
%Copy only data to clipboard.

data = editcopy(fig,data,handles,auxdata,true);

%-----------------------------------------------------
function data = editcopy(fig,data,handles,auxdata,dataonly)
%Copy data to the clipboard. NOTE: copying from data tab copies row and
%column labels. When copying from meta data (class/axisscale) the column
%label is included. The paste code will remove label from meta data copy
%but not from data tab copy. Use "copy data only" to copy/paste data from
%data tab to meta data.

if nargin<5
  dataonly = false;
end

mode     = getappdata(fig,'mode');

if isempty(mode); mode = 0; end
if mode > 0;
  %check for field button selection
  [rowcolbtn,labelbtn] = selectedbtns(fig);
  if ~isempty(labelbtn);
    col  = getappdata(labelbtn,'field');
    options = getfieldoptions(fig);
    fld  = options.fieldname{col};
    
    %If in classid view (class stings rather than numeric values).
    vset = getappdata(fig,'viewsettings');
    if strcmp(fld,'class') && strcmp(vset.classview,'string')
      fld = 'classid';
    end
    
    %find used set and decide if we should use it as a suffix for the variable name
    suffix = [];
    seth = findobj(fig,'userdata','table','tag',['c' tagbase(col+1) 'set']);
    if isempty(seth);
      useset = 1;
      nsets = 1;
    else
      useset = get(seth,'value');
      nsets  = length(get(seth,'string'))-1;
      if nsets > 1;
        suffix = ['set' num2str(useset)];
      end
    end
    
    %get value and do save if not empty
    val = get(data,fld,mode,useset);
    
    if strcmp(fld,'classid')
      %Change char back to cell array of strings.
      val = char(val);
    end
    
    if ~strcmp(fld,'include') && ~strcmp(fld,'classid')
      setname = get(data,[fld 'name'],mode,useset);
    elseif strcmp(fld,'classid')
      setname = get(data,['class' 'name'],mode,useset);
    else
      setname = '';
    end
    if ~isempty(val);
      if ~isa(val,'char')
        if size(val,1)==1; val = val'; end
        val = createtable(val);
      end
      val = [val ones(size(val,1),1)*10]';
      val = val(:)';
      if ~isempty(setname)
        val = [setname 10 val];
      end
      clipboard('copy',val);
    end
  else
    %no field buttons selected, act as if a mode zero selection
    mode = 0;
  end
end

if mode==0;
  selected = selectedrowscols(fig);
  for j = 1:length(selected);
    if isempty(selected{j});
      selected{j} = ':';
    end
  end
  
  temp = data.data(selected{:});
  if ~isempty(temp)
    if ndims(data)==2 && ~dataonly
      %get column and row labels (if present)
      collbls = data.label{2};
      if ~isempty(collbls)
        collbls = collbls(selected{2},:);
      end
      rowlbls = data.label{1};
      if ~isempty(rowlbls)
        rowlbls = rowlbls(selected{1},:);
        if ~isempty(collbls)
          %add one blank row of row labels if column labels exist
          rowlbls = strvcat(' ',rowlbls);
        end
        rowlbls = [rowlbls repmat(char(9),size(rowlbls,1),1)];
      end
    else
      collbls = '';
      rowlbls = '';
    end
    s = createtable(temp,collbls,'',0);
    s = [rowlbls s ones(size(s,1),1)*10]';
    s = s(:)';
    clipboard('copy',s);
  end
end

%-----------------------------------------------------
function data = editpaste(fig,data,handles,auxdata)

mode     = getappdata(fig,'mode');
val      = clipboard('paste');
if isempty(val); return; end;  %nothing interptable in clipboard

if isempty(mode); mode = 0; end
if mode > 0;
  %check for field button selection
  [rowcolbtn,labelbtn] = selectedbtns(fig);
  if ~isempty(labelbtn);
    editdstable('pastefield',fig)
    return
  else    %no field buttons selected, act as if a mode zero selection
    mode = 0;
  end
end

if mode==0;
  %paste into data field
  
  if strictedit;
    erdlgpls('Paste is currently disabled due to strict editing controls.','Feature Not Available')
    return;
  end
  
  selected = selectedrowscols(fig);
  for j = 1:length(selected);
    if isempty(selected{j});
      selected{j} = ':';
    end
  end
  
  setlabel = [];
  strval = val;
  try
    val  = parsemixed(str2cell(strval,1),struct('waitbar','off'));  %convert to DSO
    lbls = val.label;
    val  = val.data;
  catch
    val = str2num(strval);
    lbls = {};
  end
  try
    data.data(selected{:}) = val;
  catch
    err = lasterr;
    erdlgpls({['Clipboard contents are not appropriate for selection'],' ',err(max(find(err==10))+1:end)},['Paste'],'modal');
    return
  end
  try
    %try pasting labels
    for m = 1:length(lbls);
      if ~isempty(lbls{m})
        if ischar(selected{m})
          %':' (all columns)
          data.label{m} = lbls{m};
        else
          %numeric
          for item = 1:length(selected{m});
            data.label{m}{selected{m}(item)} = lbls{m}(item,:);
          end
        end
      end
    end
  catch
    %couldn't paste labels for some reason - ignore error silently
  end
  
  setdataset(fig,data);
  editdstable(fig,mode);
  
end

%-----------------------------------------------------
function data = editfill(fig,data,handles,auxdata)

selected = selectedrowscols(fig);
mode = getappdata(fig,'mode');

if strictedit & mode==0
  erdlgpls('Fill is currently disabled due to strict editing controls.','Feature Not Available')
  return;
end

if isempty(selected{1}) & ~isempty(selected{2})
  desc = 'column';
elseif ~isempty(selected{1}) & isempty(selected{2})
  desc = 'row';
elseif isempty(selected{1}) & isempty(selected{2})
  desc = 'entire data field';
else
  desc = 'selection';
end
if length(selected{1})>1 | length(selected{2})>1
  desc = [desc 's'];
end

val  = inputdlg({['Fill ' desc ' with value:']},'Fill with value',1);
if isempty(val); return; end;  %cancel pressed
val  = str2num(val{1});
if isempty(val); %nothing interptable given as input
  erdlgpls('Could not interpret your input as a value. No fill performed.','Fill with value aborted');
  return;
end;

if isempty(selected{1}) & isempty(selected{2})
  ans = evriquestdlg('WARNING: The entire data matrix will filled with this value! Continue with this action?','Replace all data','OK','Cancel','OK');
  if ~strcmp(ans,'OK');
    return
  end
end

%insert into data field
for j = 1:length(selected);
  if isempty(selected{j});
    selected{j} = ':';
  end
end

try
  data.data(selected{:}) = val;
catch
  err = lasterr;
  erdlgpls({['Unable to fill the selection with this value'],' ',err(max(find(err==10))+1:end)},['Fill with value'],'modal');
  return
end

setdataset(fig,data);
editdstable(fig,mode);

%-----------------------------------------------------
function data = editarithmetic(fig,data,handles,auxdata)

selected = selectedrowscols(fig);
mode = getappdata(fig,'mode');

if strictedit & mode==0
  erdlgpls('Arithmetic is currently disabled due to strict editing controls.','Feature Not Available')
  return;
end

p = arithmeticset('default');
if ~isempty(selected{2})
  p.userdata.mode = 2;
  p.userdata.indices = selected(2);
end
while strcmpi(p.userdata.operation,'noop')
  p = arithmeticset(p);
  if isempty(p); return; end;  %cancel pressed or noop selected
  if  strcmpi(p.userdata.operation,'noop')
    evriwarndlg('No arithmetic operation was selected','No operation');
  end
end

%apply preprocessing and insert
try
  if isempty(selected{1})
    data = preprocess('calibrate',p,data);
  else
    pdata = preprocess('calibrate',p,nindex(data,selected{1},1));
    data.data = nassign(data.data,pdata,selected{1},1);
  end  
catch
  err = lasterr;
  erdlgpls({['Unable to apply the arithmetic operation to the selection'],' ',err(max(find(err==10))+1:end)},['Arithmetic Error'],'modal');
  return
end

setdataset(fig,data);
editdstable(fig,mode);

%-----------------------------------------------------
function data = editmakeaxisscale(fig,data,handles,auxdata);
data = editmakefield(fig,data,handles,auxdata,'Axisscale');
% - - - - - - - -
function data = editmakeclass(fig,data,handles,auxdata);
data = editmakefield(fig,data,handles,auxdata,'Class');
% - - - - - - - -
function data = editmakedata(fig,data,handles,auxdata);
data = editmakefield(fig,data,handles,auxdata,'Data');
% - - - - - - - -
function data = editmakefield(fig,data,handles,auxdata,fieldname)

olddata = data;
msg = cell(0);
selected = selectedrowscols(fig);
%check which type of button is selected
[rowcolbtn,labelbtn] = selectedbtns(fig);

if getappdata(handles.editds,'mode')>0 & ~isempty(labelbtn)
  %in Labels screen - converting labels to field...
  try
    [rowcolbtn,labelbtn] = selectedbtns(fig);
    if ~isempty(labelbtn);
      col  = getappdata(labelbtn,'field');
      options = getfieldoptions(fig);
      fld  = options.fieldname{col};
      mode = getappdata(handles.editds,'mode');
      seth = findobj(fig,'userdata','table','tag',['c' tagbase(col+1) 'set']);
      
      if isempty(seth);
        useset = 1;
      else
        useset = get(seth,'value');
      end
      
      switch fld
        case 'class'
          fldval = 'classid';  %if grabbing classes, get classid
        otherwise
          fldval = fld;  %otherwise get field name
      end
      
      %get labels
      val = get(data,fldval,mode,useset);
      valname = get(data,[fld 'name'],mode,useset);

      if isempty(val);
        %nothing to actually make into labels
        evriwarndlg(sprintf('Cannot convert - %s set is empty.',fld),'Labels Empty');
        return;
      end

      %where should we put this data?
      switch lower(fieldname)
        case 'class'
          myfield = data.class;
          nextset = size(myfield,2)+1;  %assume new set
          for set = 1:nextset-1;
            if isempty(myfield{mode,set});
              nextset = set;   %unless we find another empty one before that
              break
            end
          end
          
          data.class{mode,nextset} = val;
          data.classname{mode,nextset} = valname;
          msg = [msg; {['Copied to Class set ' num2str(nextset)]}];

        case 'data'
          if ischar(val) | iscell(val)
            if ischar(val)
              [lbls,k,j] = unique(val,'rows');
              lbls = str2cell(lbls,true);
            else
              [lbls,k,j] = unique(val);
            end
            adddata    = class2logical(j);
          else
            %numeric
            adddata = dataset(val(:));
            lbls    = valname;
          end
          onmode = 3-mode;
          if onmode==1
            adddata = adddata';
          end
          adddata.label{onmode} = lbls;
          data = cat(onmode,data,adddata);
          
          switch onmode
            case 1
              onmode = 'rows';
            case 2
              onmode = 'columns';
          end
          msg = [msg; {['Copied to new ' onmode ' in the Data table']}];
          
        otherwise
          %should never make it here anyway...
          return  %can't use labels anywhere but with class
      
      end
      
    end
    
  catch
    erdlgpls({['Unable to create ' fieldname];lasterr},['Create ' fieldname],'modal');
    data = olddata;
    return
  end
  
  
else
  %in Data screen - converting column to field...
  
  if strictedit;
    erdlgpls('Fill is currently disabled due to strict editing controls.','Feature Not Available')
    return;
  end
  
  try
    for mode = 1:length(selected);
      for item = selected{mode}(:)';
        %where should we put this data?
        onmode        = setdiff(1:ndims(data),mode);  %figure out which mode this is going to be used for (the other viewed mode)
        switch lower(fieldname)
          case 'axisscale'
            myfield =  data.axisscale;
          case 'class'
            myfield = data.class;
        end
        
        nextset = size(myfield,2)+1;  %assume new set
        for set = 1:nextset-1;
          if isempty(myfield{onmode,set});
            nextset = set;   %unless we find another empty one before that
            break
          end
        end
        
        index         = cell(1,ndims(data));
        [index{:}]    = deal(':');
        index{mode}   = item;
        
        switch lower(fieldname)
          case 'axisscale'
            data.axisscale{onmode,nextset} = data.data(index{:});
            if ~isempty(data.label{mode});
              data.axisscalename{onmode,nextset} = deblank(data.label{mode}(item,:));
            end
            msg = [msg; {['Moved to Axisscale set ' num2str(nextset) ' for mode ' num2str(onmode)]}];
          case 'class'
            data.class{onmode,nextset} = data.data(index{:});
            if ~isempty(data.label{mode});
              data.classname{onmode,nextset} = deblank(data.label{mode}(item,:));
            end
            msg = [msg; {['Moved to Class set ' num2str(nextset) ' for mode ' num2str(onmode)]}];
        end
        
      end
    end
    
    %Finally, hard delete items from data
    for mode = 1:length(selected);
      data          = delsamps(data,selected{mode}(:)',mode,2);
    end
    
  catch
    erdlgpls({['Unable to create ' fieldname];lasterr},['Create ' fieldname],'modal');
    data = olddata;
    return
  end
end

if isempty(msg);
  data = olddata;
  return
end

setdataset(fig,data);
editdstable(fig,getappdata(fig,'mode'));
evrimsgbox(msg,['New ' fieldname ' Set(s) Created'],'warn','modal');

%-----------------------------------------------------
function data = editmakeinclud(fig,data,handles,auxdata);
data = editmakeinclude(fig,data,handles,auxdata);
% - - - - - - - -
function data = editmakeinclude(fig,data,handles,auxdata);

olddata  = data;
msg      = [];
selected = selectedrowscols(fig);

try
  for mode = 1:length(selected);
    onmode = setdiff(1:ndims(data),mode);  %figure out which mode this is going to be used for (the other viewed mode)
    item   = selected{mode};
    if isempty(item); continue; end  %skip to next mode if none selected here
    
    index         = cell(1,ndims(data));
    [index{:}]    = deal(':');
    index{mode}   = item;
    
    incl = all(data.data(index{:}),setdiff(1:2,onmode));
    data.include{onmode} = find(incl);
    msg = [msg; onmode];
    
    %Finally, hard delete item from data
    data = delsamps(data,item,mode,2);
    
  end
catch
  erdlgpls({['Unable to set include.'];lasterr},['Use as Include'],'modal');
  data = olddata;
  return
end
if isempty(msg);
  data = olddata;
  return
end

setdataset(fig,data);
editdstable(fig,getappdata(fig,'mode'));
evrimsgbox(['Changed Include for mode(s) ' sprintf('%i, ',msg(1:end-1)) sprintf('%i',msg(end))],'warn','modal');

%-----------------------------------------------------
function data = edittranspose(fig,data,handles,auxdata)

data = data';
setdataset(fig,data);
setappdata(fig,'originaldataset',getappdata(fig,'originaldataset')');

mode = getappdata(fig,'mode');
if ~isempty(mode);
  editdstable(fig,[]);
end
editdstable(fig,mode);

%-----------------------------------------------------
function data = editsortby_a(fig,data,handles,auxdata)
data = editsortby(fig,data,handles,auxdata);
%-----------------------------------------------------
function data = editsortby_d(fig,data,handles,auxdata)
data = editsortby(fig,data,handles,auxdata);
%-----------------------------------------------------
function data = editsortby(fig,data,handles,auxdata)
olddata = data;
msg = cell(0);
selected = selectedrowscols(fig);

%check which type of button is selected
[rowcolbtn,labelbtn] = selectedbtns(fig);

if length(labelbtn)>1
  erdlgpls('More than one column or row is currently selected. Select only one column or row to sort by.','Sort Single Row/Column');
  return
end
try
  if getappdata(handles.editds,'mode')>0 & ~isempty(labelbtn)
    %Labels screen.
    if ~isempty(labelbtn);
      col  = getappdata(labelbtn,'field');
      options = getfieldoptions(fig);
      fld  = options.fieldname{col};
      mode = getappdata(handles.editds,'mode');
      seth = findobj(fig,'userdata','table','tag',['c' tagbase(col+1) 'set']);
      if isempty(seth);
        useset = 1;
      else
        useset = get(seth,'value');
      end
      [data, myindx] = sortby(data,fld,mode,useset,auxdata);
    end
  else
    %Data screen.
    if isempty(selected{1})
      %Sort by a rows.
      [data, myindx] = sortrows(data,selected{2},auxdata);
      mode = 1;
    else
      %Sort by a columns.
      [data, myindx] = sortcols(data,selected{1},auxdata);
      mode = 2;
    end
  end
catch
  erdlgpls({['Unable to sort field.'];lasterr},['Sort Error'],'modal');
  data = olddata;
  return
end

mylink = setdataset(fig,data);
%Apply new index to other block.
if mode==1;
  propagateblockchanges(mylink,myindx,'sort',mode)
end

editdstable(fig,getappdata(fig,'mode'));

%------------------------------------------------------
function propagateblockchanges(mylink,idx,ctype,mode)
%When applying changes (hard delete, sort, flip, or shuffle) to one block (x/y val or cal),
%propagate those changes to the opposite block if it's loaded.
%  mylink - link object.
%  index  - index of sort or delete or (empty for flip)
%  ctype  - type of change ('delete' or 'sort' or 'flip' or 'shuffle')
%  mode   - mode to apply index to or flip

%Only propagate rows (mode = 1)
if mode ~= 1
  return
end

guiapp = get(mylink.source,'tag');

%Apply new index to other block.
if strcmpi(guiapp,'analysis')
  switch mylink.properties.itemType
    case 'xblock'
      oname = 'yblock';
    case 'yblock'
      oname = 'xblock';
    case 'validation_xblock'
      oname = 'validation_yblock';
    case 'validation_yblock'
      oname = 'validation_xblock';
    otherwise
      %Unrecognized block so return.
      return
  end
  oblock = analysis('getobjdata',oname,mylink.source);
elseif strcmpi(guiapp,'caltransfergui')
  switch mylink.properties.itemType
    case 'datasetx1'
      oname = 'datasetx2';
    case 'datasetx2'
      oname = 'datasetx1';
    otherwise
      return
  end
  oblock = caltransfergui('getobjdata',oname,mylink.source);
else
  return
end

if ~isempty(oblock)
  switch ctype
    case 'sort'
      oblock = nindex(oblock,idx,mode);
    case 'delete'
      incl = oblock.include;
      incl{mode} = idx;
      allmodes = 1:length(incl);
      incl(setdiff(allmodes,mode)) = {':'};
      oblock = oblock(incl{:});
    case 'flip'
      oblock = flip(oblock,1);
  end
  switch guiapp
    case 'analysis'
      analysis('setobjdata',oname,mylink.source,oblock)
    case 'caltransfergui'
      caltransfergui('setobjdata',oname,mylink.source,oblock)
  end
end


%------------------------------------------------------
function data = update(fig,data,handles,timestamp)

mode = getappdata(fig,'mode');
setmode(fig,data,handles,mode);
updateheader(handles)

if isempty(timestamp);
  timestamp = now;
end
setappdata(fig,'timestamp',timestamp);     %flag that we're already updating our links

children = getappdata(fig,'children');
children = children(ishandle(children));
parents = getappdata(fig,'parent');
parents = parents(ishandle(parents));

toupdate = [children parents];
% disp(['editds: ' num2str([fig toupdate])]);
for h = toupdate;
  oldts = getappdata(h,'timestamp');
  if isempty(oldts) | (isa(oldts,'double') & timestamp ~= oldts);
    %disp(['editds: >' num2str([h])]);
    figtype = getappdata(h,'figuretype');
    if isempty(figtype); figtype = 'other'; end
    switch figtype
      case 'PlotGUI';
        plotgui('update','figure',h,'timestamp',timestamp,'background');
      case 'EditDS';
        editds('update',h,timestamp);
      case 'volatile'
        close(h);
      otherwise
    end
  end
end

%-----------------------------------------------------
function setvarname(fig,name)

%retrieve varname (if not supplied) or store varname (if supplied)
drawnow;
if ~ishandle(fig)
  %Somehow code gets here after fig is destroyed in multiblock tool.
  return
end

if nargin<2;
  name = getappdata(fig,'varname');
else
  setappdata(fig,'varname',name)
end

[data,mylink] = getdataset(fig);

if getappdata(fig,'asraw');
  editorname = 'Data Editor';
else
  editorname = 'DataSet Editor';
end

if mylink.source~=fig;  %someone else owns this data, assume they will handle saving/etc.
  name = data.name;
  if isempty(name)
    name = '[Unnamed]';
  end
  if getappdata(fig,'noedit')
    modflag = ' [Read Only]';
  else
    modflag = '';
  end
  set(fig,'name',[name modflag ' - ' editorname]);
else  %we own this data, give modflag and name
  %check for changed moddate
  moddate = getappdata(fig,'moddate');
  if ~isempty(data) & ~isempty(data.moddate) & (isempty(moddate) | any(moddate~=data.moddate));
    modflag = '*';
  elseif getappdata(fig,'noedit')
    modflag = ' [Read Only]';
  else
    modflag = '';
  end
  
  %set window name
  if isempty(name)
    set(fig,'name',['[Unnamed]' modflag ' - ' editorname]);
  else
    set(fig,'name',[name modflag ' - ' editorname]);
  end
end

%-----------------------------------------------------
function out = tagbase(index)

out = ['0':'9' 'A':'Z' 'a':'z'];  %used to create tags (fast)
if nargin==1;
  out = out(index);
end

%-----------------------------------------------------
function data = editfields(fig,data,handles,fields);

if ~iscell(fields);
  if ischar(fields)
    fields = {fields};
  else
    error('Unrecognized input for field list - auxdata must be cell of valid dataset fields');
  end
end
setappdata(fig,'editfields',fields);


%-----------------------------------------------------
function data = noedit(fig,data,handles,stat);

setappdata(fig,'noedit',stat)
updateheader(handles)

%-----------------------------------------------------
% Get names, descriptions, etc for enabled fields
function options = getfieldoptions(fig)

options = [];

options.fieldname = {'label' 'axisscale' 'class' 'include'};
options.fielddesc = {'Label' 'Axis Scale' 'Class' 'Incl.'};
options.fieldtip  = {'Click to select Labels field' 'Click to select Axis Scale field' 'Click to select Class field' 'Click to select Include (use) field'};
options.enable    = [1 1 1 1];

editfields = getappdata(fig,'editfields');
if ~isempty(editfields);
  options.enable = ismember(options.fieldname,editfields);
end


%-----------------------------------------------------
%allow user to bulk change include of rows/cols/etc using a list dialog
function data = editbulkinclude(fig,data,handles,varargin);

mode = getappdata(fig,'mode');
if ~isempty(mode) & mode>0;

  [sel,ok] = selectfromlist(fig,data,'Included',data.include{mode});

  if ok
    if isempty(sel)
      switch mode
        case 1
          lblbase = 'rows';
        case 2
          lblbase = 'columns';
        otherwise
          lblbase = 'items';
      end          
      ans = evriquestdlg({['Warning: All ' lblbase ' excluded.'],' ','Is this what you wanted to do?'},'All Points Exclude','Yes','No/Cancel','Yes');
      if ~strcmp(ans,'Yes');
        return;
      end
    end
    data.include{mode} = sel;
    setdataset(fig,data,'include');
    editdstable('update',fig);
  end
  
end
%-----------------------------------------------------
%allow user to bulk change selection of rows/cols/etc using a list dialog
function data = editbulkselection(fig,data,handles,varargin);

mode = getappdata(fig,'mode');
if ~isempty(mode) & mode>0;

  mylink = getlink(fig);
  if length(mylink.properties.selection)<mode
    mylink.properties.selection{mode} = [];
  end
  [sel,ok] = selectfromlist(fig,data,'Selected',mylink.properties.selection{mode});

  if ok
    mylink.properties.selection{mode} = sel;
  end
  
end

%-----------------------------------------------------
%allow user to bulk change selection of rows/cols/etc using a list of classes
function data = editselectclass(fig,data,handles,varargin);

mode = getappdata(fig,'mode');

myset = get(handles.c3set,'value');

cls  = data.class{mode,myset};
classlookup = data.classlookup{mode,myset};
if isempty(cls) | isempty(classlookup)
  return;
end
validclasses = classlookup(:,2);
[class_number,ok] = listdlg('ListString',validclasses,...
  'SelectionMode','multiple','InitialValue',[],...
  'PromptString',{'Choose one or more classes' 'to select:  '},...
  'Name','Select Class');
if ~ok; return; end

class_number = cat(2,classlookup{class_number,1});

myselection = find(ismember(cls,class_number));

mylink = getlink(fig);
mylink.properties.selection{mode} = myselection;

%------------------------------------------------------------
function [sel,ok] = selectfromlist(fig,data,label,default)

mode = getappdata(fig,'mode');

if ndims(data)<3;
  switch mode
    case 1
      lblbase = 'Rows';
    case 2
      lblbase = 'Columns';
  end
else
  lblbase = ['items from mode ' num2str(mode)];
end

modesz = size(data,mode);
if modesz>10000;
  r = evriquestdlg('Bulk Change may take a long time to prepare a list with modes that have more than 10,000 items. Do you still want to do this?','Large List Warning','Yes','Cancel','Yes');
  if strcmp(r,'Cancel'); 
    sel = [];
    ok = false;
    return; 
  end
end

try
  ptr = get(fig,'pointer');
  set(fig,'pointer','watch');
  drawnow;
  
  str = [num2str((1:modesz)')];
  
  lbls = data.label{mode};
  if ~isempty(lbls);
    str = [str repmat(': ',modesz,1) lbls];
  end
  
  str = [str repmat(' [ ',modesz,1)];
  
  all_ax = data.axisscale(mode,:);
  nax = 0;
  for j=1:length(all_ax);
    ax = all_ax{j};
    if ~isempty(ax)
      str = [str num2str(ax(:))];
      str = [str repmat(' ',modesz,1)];
      nax = nax+1;
    end
  end
  if nax>0
    str = [str repmat(':',modesz,1)];
  end
  
  all_classes = data.classid(mode,:);
  for j=1:length(all_classes);
    classes = all_classes{j};
    if ~isempty(classes)
      str = [str char(classes)];
      str = [str repmat(' ',modesz,1)];
    end
  end
  
  str = [str repmat(' ]',modesz,1)];
  
  [sel,ok] = listdlg('PromptString',[label ' ' lblbase ' [axis scales : classes]'],'SelectionMode','multiple',...
    'InitialValue',default,'ListString',str,'ListSize',[300 400]);
catch
  ok = false;
  sel = [];
end
set(fig,'pointer',ptr);

%------------------------------------------------------------
function data = editeditfield(fig,data,handles,auxdata)

options = getfieldoptions(fig);
[rowcolbtn,labelbtn] = selectedbtns(fig);
mode = getappdata(fig,'mode');
col  = getappdata(labelbtn,'field');
fld  = options.fieldname{col};

%If in classid view (class stings rather than numeric values).
vset = getappdata(fig,'viewsettings');
if strcmp(fld,'class') && strcmp(vset.classview,'string')
  fld = 'classid';
end

%find used set and decide if we should use it as a suffix for the variable name
suffix = [];
seth = findobj(fig,'userdata','table','tag',['c' tagbase(col+1) 'set']);
if isempty(seth);
  useset = 1;
  nsets = 1;
else
  useset = get(seth,'value');
  nsets  = length(get(seth,'string'))-1;
  if nsets > 1;
    suffix = ['set' num2str(useset)];
  end
end

%get current value
value = get(data,fld,mode,useset);

if strcmp(fld,'classid')
  %Change cell array of strings to char array.
  value = char(value);
end

if strcmp(fld,'label') || strcmp(fld,'classid');
  %   value = str2cell(value);
  %   delim = '{}';
  delim = '[]';
else
  delim = '[]';
  value = sprintf(encode(value,'',0));
end

retry = true;
while retry
  
  retry = false;  %assume everything is OK
  
  if iscell(value); value = char(value); end
  newvalue = inputdlg({['Edit contents of ' fld ' (insert values between ' delim(1) ' ' delim(2) ')']},['Edit ' fld ],[5],{value});
  
  if ~isempty(newvalue)  %newvalue empty when cancel pressed, skip to exit
    
    if strcmp(fld,'classid')
      %Change char back to cell array of strings.
      newvalue = str2cell(newvalue{:});
    else
      newvalue = newvalue{1};
    end
    
    if ~strcmp(fld,'label') && ~strcmp(fld,'classid');
      %check for [] or {}
      if ~any(ismember(newvalue,'[{'))
        newvalue = [delim(1) newvalue];
      end
      if ~any(ismember(newvalue,']}'))
        newvalue = [newvalue delim(2)];
      end
      
      %make multi-line a single line
      if size(newvalue,1)>1;
        newvalue = newvalue';
        newvalue = newvalue(:)';
      end
      
      try
        myvalue = eval(newvalue);  %try to convert from string to variable
      catch
        err = lasterr;
        epos = max(find(err==10));
        if ~isempty(epos) & epos<length(err)
          err = err(epos+1:end);
        end
        erdlgpls({['Supplied string not interpretable for ' fld],' ',err},['Edit ' fld ' error']);
        value = newvalue;
        retry = true;
        continue  %reloop now
      end
      
    else
      %string - try direct assignment
      myvalue = newvalue;
    end
    
    %set value if we can
    try
      set(data,fld,myvalue,mode,useset);
    catch
      err = lasterr;
      erdlgpls({['Supplied data are not appropriate for ' fld],' ',err(max(find(err==10))+1:end)},['Edit ' fld ' error']);
      value = newvalue;
      retry = true;
      continue  %reloop now
    end
    
    if ~retry;
      setdataset(fig,data);
      editdstable('update',fig);
    end
  end
end

%------------------------------------------------------------
function data = editundo(fig,curdata,handles,auxdata)

history = getappdata(fig,'history');
if ~isempty(history);
  data = history{end};
  history = history(1:end-1);
  setdataset(fig,data);
  
  mode = getappdata(fig,'mode');
  if ndims(data) ~= ndims(curdata)
    initialize(handles,data,mode);
  end
  if ~isempty(mode);
    editdstable('update',fig);
  else
    updateheader(handles);
  end
  
  setappdata(fig,'history',history);
end

%--------------------------------------------------------
function data = editpermute(fig,data,handles,auxdata)

currentmodes = sprintf('%i ',1:ndims(data));
newmodes = inputdlg({'Enter new order for modes (separate with spaces or commas):'},'Permute Modes',1,{currentmodes});
if isempty(newmodes)
  return;
end
newmodes = str2num(newmodes{1});
if isempty(newmodes) | length(newmodes)~=ndims(data)
  erdlgpls('Number of modes can not change. Permute canceled.','Permute error');
  return
end

origdata = getappdata(fig,'originaldataset');
try
  data = permute(data,newmodes);
  origdata = permute(origdata,newmodes);
catch
  erdlgpls({'Permute canceled.',lasterr},'Permute error');
  return
end
setdataset(fig,data);
setappdata(fig,'originaldataset',origdata);

mode = getappdata(fig,'mode');
if ~isempty(mode);
  editdstable(fig,[]);
end
editdstable(fig,mode);

%--------------------------------------------------------
function data = editfold3way(fig,data,handles,auxdata)

if ndims(data)>2
  erdlgpls('Cannot perform fold on multi-way data.','Fold Error');
  return
end

newsize = [];
while isempty(newsize)
  newsize = inputdlg({'Number of "slabs" (size of 3rd mode):'},'Fold 3-way Data',1,{'1'});
  if isempty(newsize)
    return;
  end
  newsize = str2num(newsize{1});
  newsize = round(newsize);
  if newsize<1 | ~isfinite(newsize)
    erdlgpls('Invalid number of slabs for this data matrix.','Invalid Size');
    newsize = [];
  elseif mod(size(data,1),newsize)~=0
    erdlgpls('Number of rows cannot be folded evenly into this number of slabs.','Invalid Size');
    newsize = [];
  end
end

newsize = [size(data,1)/newsize newsize size(data,2)];
origdata = getappdata(fig,'originaldataset');
try
  data = permute(reshape(data,newsize),[1 3 2]);
  origdata = permute(reshape(origdata,newsize),[1 3 2]);
catch
  erdlgpls({'Reshape canceled.',lasterr},'Reshape error');
  return
end
setdataset(fig,data);
setappdata(fig,'originaldataset',origdata);

mode = getappdata(fig,'mode');
initialize(handles,data,mode);

%--------------------------------------------------------
function data = editreshape(fig,data,handles,auxdata)

currentsize = sprintf('%i ',size(data));
newsize = [];
while isempty(newsize)
  newsize = inputdlg({'Enter new array size (separate with spaces or commas):'},'Reshape Data',1,{currentsize});
  if isempty(newsize)
    return;
  end
  newsize = str2num(newsize{1});
  if prod(newsize)~=numel(data.data)
    erdlgpls('Number of elements must not change. Size specified does not match number of elements.','Invalid Reshape Size');
    newsize = [];
  end
end

origdata = getappdata(fig,'originaldataset');
try
  data = reshape(data,newsize);
  origdata = reshape(origdata,newsize);
catch
  erdlgpls({'Reshape canceled.',lasterr},'Reshape error');
  return
end
setdataset(fig,data);
setappdata(fig,'originaldataset',origdata);

mode = getappdata(fig,'mode');
initialize(handles,data,mode);

%--------------------------------------------------------
function data = viewmissingdatamap(fig,data,handles,auxdata)

mdcheck(data,struct('plots','final'));
child = gcf;
setappdata(fig,'children',unique([getappdata(fig,'children') child ]));  %add to editds' child list
setappdata(child,'figuretype','volatile');

%--------------------------------------------------------
function data = editexcludemissing(fig,data,handles,auxdata)

try
  [data,bad] = excludemissing(data);
catch
  erdlgpls({'Unable to exclude missing.',lasterr},'Exclude missing error');
  return
end

if all(cellfun('isempty',bad))
  evrimsgbox('No items with excessive missing data were found','Exclude Missing','help','modal');
  return
end

s = '';
for mode = 1:length(bad);
  if ndims(data)==2;
    switch mode
      case 1
        m = ' row';
      case 2
        m = ' column';
    end
  else
    m = [' mode ' num2str(mode) ' element'];
  end
  if length(bad{mode})~=1; ext = 's'; else; ext = ''; end
  s = [s '  ' num2str(length(bad{mode})) m ext '\n'];
end
evrimsgbox(sprintf(['This operation excluded the following:\n' s]),'Exclude Missing','help','modal');

setdataset(fig,data);

mode = getappdata(fig,'mode');
if ~isempty(mode);
  editdstable('update',fig);
else
  updateheader(handles);
end

%--------------------------------------------------------
function data = keypress(fig,data,handles,auxdata)

setappdata(fig,'lastkeypress_time',now)
%check for control-z
if strcmp(get(fig,'currentcharacter'),char(26))
  data = editundo(fig,data,handles,auxdata);
end

%--------------------------------------------------------
function nms = newclassname(mytbl,newcls)
%Create a new class names based on existing lookup table and a class numbers.
%Should not allow duplicate name.

tbl = mytbl;
nms = '';
for i = 1:length(newcls)
  namenum = newcls(i);
  cpver = 0;
  while 1
    if cpver>0
      newname = ['Class ' num2str(namenum) '(' num2str(cpver) ')'];
    else
      newname = ['Class ' num2str(namenum)];
    end
    if ~ismember({newname},mytbl(:,2))
      break
    elseif cpver>1000
      %Break out of loop if more than 1000.
      break
    end
    cpver = cpver+1;
  end
  nms = [nms; {newname}];
end

%--------------------------------------------------------
function data = editlookuptable(fig,data,handles,auxdata)
%Edit current (mode/set) class lookup table.

m = getappdata(fig,'mode');
if isempty(m) | m==0
  return
end

%find used set and decide if we should use it as a suffix for the variable name
seth = findobj(fig,'userdata','table','tag',['c3set']);
if isempty(seth);
  useset = 1;
else
  useset = get(seth,'value');
end

%get current value
try
  curtbl = data.classlookup{m,useset};
  curcls = data.class{m,useset};
catch
  curtbl = {};
end
if isempty(curtbl)
  evrimsgbox(['No class lookup table available for mode: ' num2str(m) ' set: ' num2str(useset)],'No Lookup Table Warning','warn','modal');
  return
else
  [mytbl,mycls] = editlookup(curtbl,curcls,fig);
  if isnumeric(mytbl)
    %user cancel
    return
    %     mytbl = curtbl;
    %     mycls = curcls;
  end
end

try
  data.classlookup{m,useset} = mytbl;
  data.class{m,useset} = mycls;
  setdataset(fig,data,'class');
  editdstable('update',fig);
  data = [];
  
catch
  err = lasterr;
  erdlgpls({['Supplied data are not appropriate for Class Lookup Table' ],' ',err(max(find(err==10))+1:end)},['Edit Class Lookup Table Error']);
end

%-----------------------------------------------
function data = filesendto(fig,data,handles,varargin)
sendto(getlink(fig));

%-----------------------------------------------
function data = editmakeimage(h,data,handles,varargin)

if ~evriio('mia')
  erdlgpls('This operation requires the MIA_Toolbox add-on product');
  return
end

switch data.type
  case 'data'
    try
      data = imageload(data);
    catch
    end
  case 'image'
    myans = evriquestdlg('Discard image information and convert to unfolded (2D) or folded (3D) data?','Discard Image Information','Discard (2D)','Discard (3D)','Cancel','Discard (2D)');
    
    if strcmp(myans,'Discard (2D)');
      data.type = 'data';
    elseif strcmp(myans,'Discard (3D)');
      idata = dataset(data.imagedata);
      data = copydsfields(data,idata,{2 3});
    else
      %User cancel.
      return
    end
  otherwise
    erdlgpls('Unable to convert data of this type into an image.','Conversion failed');
end

if ~isempty(data)
  %Use initialize here instead of updateheader in parent callback because
  %we need to refresh tabs when number of modes change.
  setdataset(handles.editds,data);
  initialize(handles,data,'');
  
  %Empty data so we don't make unneeded call to updateheader after this
  %function finishes.
  data = [];
end

%-----------------------------------------------
function data = fileLoadSel_inds(h,data,handles,varargin)

dmode = getappdata(h,'mode');
szD = size(data,dmode);

[sel,varname] = lddlgpls({'double','logical'},'Load Selection Indices');
if isempty(varname);
  return;
end
% if max(sel) > szD
%   evrierrordlg('Loaded Selection Vector is too big for Mode');
%   return
% end
if islogical(sel)
  if length(sel) ~= szD
    evrierrordlg('Loaded vector does not match dimensions of current mode','Dimension Mismatch');
    return
  else
    sel = find(sel);
  end
end
mylink = getlink(h);
try
  mylink.properties.selection{dmode} = sel;
catch
  erdlgpls(['Error performing selection: ' lasterr],'Selection Error')
end

%-----------------------------------------------
function data = fileSaveSel_inds(h,data,handles,varargin)
dmode = getappdata(h,'mode');
selinds = selectedrowscols(h);
selinds = selinds{dmode};

if isempty(selinds)
  evriwarndlg('Please make a selection', 'Nothing Selected');
  return
else
  svdlgpls(selinds,'Save Selection')
end

%-----------------------------------------------
function data = viewboxplot(h,data,handle,varargin);

boxplot(data,'plotstyle','compact');

%-----------------------------------------------
function data = viewstatistics(h,data,handle,varargin)

editds(summary(data));

%-----------------------------------------------
function data = viewclasssummary(h,data,handle,varargin)

infobox(classsummary(data));

%-----------------------------------------------
function data = cmviewstatistics(h,data,handle,varargin)

fig = handle.editds;
sel = selectedrowscols(fig);

datasub = data;
for j=1:length(sel);
  if ~isempty(sel{j});
    datasub = nindex(datasub,sel{j},j);
  end
end

viewstatistics(h,datasub,handle,varargin);

%-----------------------------------------------
function out = strictedit
%returns "true" (1) if software is currently limited to strict editing mode

persistent internal_strictedit

if isempty(internal_strictedit)
  %not yet defined
  internal_strictedit = false;   %assume NOT unless...
  
  %any add-on functions want strict editing
  fns = evriaddon('strictedit');
  for j=1:length(fns)
    if feval(fns{j});
      internal_strictedit = true;
    end
  end
  
end

out = internal_strictedit;

%-----------------------------------------------
function updateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object.
%The myobj variable comes in with the following structure.
%
%   id           - unique id of object.
%   object       - shared data (object).
%   properties   - structure of "properties" to associate with shared data.

% disp(sprintf('Editds Update: %s %s',char(keyword),myobj.properties.itemType));  %%%For shareddata/selection code
switch keyword
  case 'delete'
    if ishandle(h);
      close(h)
    end
    return;
  otherwise
    if isempty(myobj.object)
      if ~isdataset(myobj.object)
        if ishandle(h);
          close(h)
        end
        return;
      end
      editds('setmode',h,[],guidata(h));
    else
      mode = getappdata(h,'mode');
      if ~isempty(mode)
        editdstable('update',h)
      else
        editdstable(h,[]);
      end
    end
    
end

%-----------------------------------------------
function propupdateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object.
%The myobj variable comes in with the following structure.
%
%   id           - unique id of object.
%   object       - shared data (object).
%   properties   - structure of "properties" to associate with shared data.

if getappdata(h,'linkselections')  %%%For shareddata/selection code
  mode = getappdata(h,'mode');
  if ~isempty(mode);
    editdstable('update',h)
  else
    editdstable(h,[]);
  end
end

%---------------------------------------------------------------------
function dropCallbackFcn(obj,ev,varargin)
%Parse dnd object then call drop.

handles = guihandles(varargin{1});

if getappdata(handles.editds,'noedit');
  evriwarndlg('Edit not allowed, drop disabled.','No Drop/Edit');
  return
end

dropdata = drop_parse(obj,ev,'',struct('getcacheitem','on','concatenate','on'));
if isempty(dropdata) | isempty(dropdata{1})
  %Probably error.
  evriwarndlg('Unalbe to process drop, try using menu items to import data.','Drop Fail');
  return
end

%If more than one item dropped then call load data in a loop and the user
%will be queried for how to concat.
for i = 1:size(dropdata,1)
  editds('fileload',handles.editds,dropdata{i,2})
end


%--------------------------------------------------------------------------
function imgdso = editimageaxisscale(fig, imgdso, varargin)
% This function allows the user to add (or edit) imageaxisscales and
% imageaxisscalenames for an image dataset.
% Inputs is an image dataset.
% 
% The user is presented with a dialog window and asked to enter values for:
% Units                : Example, 'm', 'ft'. This hould be a short name
% Size in X direction  : Range of image in X direction in these units
% Size in Y direction  : Range of image in Y direction in these units
% 
% The function then sets imageaxisscale and imageaxisscalename
% If the image dataset has exsiting imageaxisscales then these are shown as
% the default values in the opened dialog window.
% If the input dataset is not an image dataset then it is returned
% unchanged.
%
% Output is a dataset.

imgsizePix = imgdso.imagesize;
npixy = imgsizePix(1);
npixx = imgsizePix(2);

% If the input dso is image dso and:
%  a) has existing imageaxisscale: then edit it
%  b) does not have imageaxisscale: then add it
if isdataset(imgdso) & strcmp(imgdso.type, 'image')
  % Do we have imageaxisscale x and y? 
  % Yes? then edit it. 
  if ~isempty(imgdso.imageaxisscale{1}) & ~isempty(imgdso.imageaxisscale{2})
    leny = (imgdso.imageaxisscale{1}(end) - imgdso.imageaxisscale{1}(1));
    lenx = (imgdso.imageaxisscale{2}(end) - imgdso.imageaxisscale{2}(1));
    uname = imgdso.imageaxisscalename{1};
  elseif ~isempty(imgdso.imageaxisscale{1})
    leny = (imgdso.imageaxisscale{1}(end) - imgdso.imageaxisscale{1}(1));
    lenx = leny;
    uname = imgdso.imageaxisscalename{1};
  elseif ~isempty(imgdso.imageaxisscale{2})
    lenx = (imgdso.imageaxisscale{2}(end) - imgdso.imageaxisscale{2}(1));
    leny = lenx;
    uname = imgdso.imageaxisscalename{2};
  else
    % No? then add it.
    lenx = npixx; leny = npixy; uname = 'Pixel';
  end
  [uname, lenx, leny] = setimagescale(uname, lenx, leny);
  
  % setting axisscale now will be zero based. 
  xaxisscale = (0:(npixx-1))*lenx/(npixx-1);
  yaxisscale = (0:(npixy-1))*leny/(npixy-1);
  imgdso.imageaxisscale{1} = yaxisscale;
  imgdso.imageaxisscale{2} = xaxisscale;
  imgdso.imageaxisscalename{1} = uname;
  imgdso.imageaxisscalename{2} = uname;
else
  evrierrordlg(['Input must be an image dataset, not a ' class(imgdso)]);
end

%--------------------------------------------------------------------------
function [name, lenx, leny] = setimagescale(namein, lenxin, lenyin)
% Allow user to specify x and y length of image in new units
% Returns the new units name and x,y lengths
% Input:
% namein: string
% lenxin: double
% lenyin: double
% Output:
% name:   string
% lenx:   double
% leny:   double

name = namein;
lenx = num2str(lenxin);
leny = num2str(lenyin);
if isempty(name)
  name = '';
end
str1    = 'Enter name of length scale units';
str2    = 'Enter X size of image in these units';
str3    = 'Enter Y size of image in these units';
% results = inputdlg({str1, str2, str3}, 'Set Scale', 1);
try
  numLines    = 1;
  defAns      = {name, lenx, leny};
  opts.Resize = 'on';
  results = inputdlg({str1, str2, str3}, 'Set Scale', numLines, defAns, opts);
  
  name = results{1};
  lenx = str2double(results{2});
  leny = str2double(results{3});
catch
  % return inputs
  name = namein;
  lenx = lenxin;
  leny = lenyin;
end
