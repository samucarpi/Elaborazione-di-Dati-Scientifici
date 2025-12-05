function varargout = piconnectgui(varargin)
% PICONNECTGUI M-file for piconnectgui.fig
%      PICONNECTGUI, by itself, creates a new PICONNECTGUI or raises the existing
%      singleton*.
%
%      H = PICONNECTGUI returns the handle to a new PICONNECTGUI or the handle to
%      the existing singleton*.
%
%      PICONNECTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PICONNECTGUI.M with the given input arguments.
%
%      PICONNECTGUI('Property','Value',...) creates a new PICONNECTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before piconnectgui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to piconnectgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%TODO: add additional wait bar for "batch" mode.

if nargin == 0  % LAUNCH GUI

  h=waitbar(1,['Starting ' upper(mfilename) '...']);
  drawnow
  fig = openfig(mfilename,'new');
  %positionmanager(fig,mfilename);%Position gui from last known position.
  figbrowser('addmenu',fig); %add figbrowser link

  handles = guihandles(fig);	%structure of handles to pass to callbacks
  guidata(fig, handles);      %store it.
  gui_init(fig)            %add additional fields
  if ishandle(fig)
    set(fig,'visible','on')
  end
  
  if nargout > 0
    varargout{1} = fig;
  end

  close(h)

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
  if strcmp(getappdata(0,'debug'),'on');
    dbstop if all error
  end

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
        if nargin==1

        elseif nargout == 0;
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
elseif iscom(varargin{1})
  %ActiveX callback.
  handles = guidata(varargin{1}.guiparent);
  serverconnupdate(handles,varargin{1}.SelectedServer);
end

%--------------------------------------------------------------------
function gui_init(h)
%Initialize the the gui.
handles = guidata(h);

set(handles.listbox2,'value',1)

%Set figure to appropriate position.
set(h,'units','pixels');
set(0,'units','pixels');

%Set figure color.
set(h,'color',[.9 .9 1]);

%Get acitvex control height.
figpos = get(h,'position');
aheight = figpos(4)-42;

if ~ispc
  delete(handles.piconnectgui)
  erdlgpls('This tool is only available for Windows PC with PISDK installed.')
  return
end

try
  %Create activex control for PI server selection dropdown control.
  ah = actxcontrol('PISDKCtl.PISrvPickList', [10.0000  aheight  199.0000   19.0000],...
    h,{'Click', 'piconnectgui'});%Give callback to activex control.
  set(ah,'ConnectOnSelect',true); %Enable connection GUI if server doesn't.
  ah.addproperty('guiparent'); %Store parent handle.
  ah.guiparent = h; %Store parent handle.
  setappdata(handles.piconnectgui,'serverselecthandle',ah);%Strore handle becuase isn't found in handles.

catch
  delete(handles.piconnectgui)
  erdlgpls(['Unable to establish PI ActiveX control. Make sure PISDK is installed.\n%s' lasterr])
  return
end

%Set all objects inactive for testing.
%set(findobj(handles.piconnectgui,'Type','uicontrol'),'Enable','off')
set(findobj(handles.piconnectgui,'Tag',''),'Enable','on')

%Fill in default values based on options.
opts = getpidata('options');

if strcmp(opts.rawdata,'on')
  set(handles.querytype,'value',3);
elseif strcmp(opts.interpolate,'total')
  set(handles.querytype,'value',2);
elseif strcmp(opts.interpolate,'interval')
  set(handles.querytype,'value',1);
end

set(handles.queryval,'String',num2str(opts.interpolateval));

%Set buttons in Button Group.
if strcmp(opts.appenddir,'mode 1')
  set(handles.mode1,'Value',1)
else
  set(handles.mode3,'Value',1)
end

%Initialize appdata fields for data.
setappdata(handles.piconnectgui,'taglist','');
setappdata(handles.piconnectgui,'rangexls','');
setappdata(handles.piconnectgui,'mypath',''); %Remember path for dialog boxes.
setappdata(handles.piconnectgui,'options',getpidata('options'));
setappdata(handles.piconnectgui,'tagcache','');%Structure of cached settings and dso.
setappdata(handles.piconnectgui,'dataset',[]);%Current dataset, needed for editds.
setappdata(handles.piconnectgui,'editfig',[])
updategui(handles)

%--------------------------------------------------------------------
function serverconnupdate(handles,myServer)
%Execute loadtag method for activex control and display server info.
%myConn = actxserver('PISDKDlg.Connections');

ctrls = {'svrName' 'svrID' 'svrVer' 'svrUser' 'svrTime' 'svrTZ'};

%Clear values.
for i = 1:length(ctrls)
  set(handles.(ctrls{i}),'String','')
end

if ~myServer.Connected
  disp(['WARNING: Server not connected. Check connection.']);
  set(handles.svrName,'String','');
  set(handles.svrID,'String','');
  set(handles.svrVer,'String','');
  set(handles.svrUser,'String','');
  set(handles.svrTime,'String','');
  set(handles.svrTZ,'String','');
  updategui(handles)
  return
end

set(handles.svrName,'String',myServer.Name);
set(handles.svrID,'String',myServer.ServerID);
set(handles.svrVer,'String',myServer.ServerVersion.Version);
set(handles.svrUser,'String',datestr(now));
set(handles.svrTime,'String',myServer.ServerTime.LocalDate);
set(handles.svrTZ,'String',myServer.PITimeZoneInfo.StandardName);

updategui(handles)

%Exmple code for getting interpoloated values.
% %--------------------------------------------------------------------
% function getvalues(hObject, eventdata, handles)
% %Code for getting interpolated values from PI.
% 
% %Need a PIAsynchStatus object to input to interpolate values. It will error
% %otherwise.
% asyncObj = actxserver('PISDKCommon.PIAsynchStatus');
% nameValObj = actxserver('PISDKCommon.NamedValues');
% myPoints = myServer.PIPoints;
% myInterp = myPoints.Item(tagname).Data.InterpolatedValues2('y-2d','t',1000,'',0,asyncObj);
% try
%   pause(1);
%   myInterpData  = myInterp.GetValueArrays;
% catch
% 
% end
% 
% %Figure out what type of data was returned.
% 
% %Make sure a digital state object isn't returned in the mix.
% numIndx = cellfun(@isnumeric,myInterpData);
% charIndx = cellfun(@ischar,myInterpData);
% objIndx = cellfun(@isobject,myInterpData);
% %Take only numeric values.
% %NOTE: Need to change this based on datatype being returned.
% myInterpNumData = myInterpData(numIndx);
% myInterpCharData = myInterpData(charIndx);
% 
% myInterpNumData = [myInterpNumData{:}]';
% plot(myInterpNumData)


%--------------------------------------------------------------------
function querytag_Callback(hObject, eventdata, handles)
%Load tag list with PI tools.
loadlist(hObject, eventdata, handles,'pi')

%--------------------------------------------------------------------
function create_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------
function loadtag_Callback(hObject, eventdata, handles)
%Load tag list from xls file.
loadlist(hObject, eventdata, handles,'xls')
%--------------------------------------------------------------------
function loadlist(hObject, eventdata, handles,loadtype)
%Load tag list based on loadtype ('xls' or 'pi').

taglist = getappdata(handles.piconnectgui,'taglist');

if ~isempty(taglist)
  button = evriquestdlg('There is an existing taglist. Do you wish to clear the list?',...
    'Continue Load List','Yes','No','Yes');
  if strcmp(button,'No')
    return
  elseif strcmp(button,'Yes')
    taglist = '';
  end
end

if strcmp(loadtype,'xls')
  %Get xls file name. Use filename in getpidata call. This will make
  %interface more responsive with the only waiting step being when user
  %creates dso.
  mypath = getappdata(handles.piconnectgui,'mypath');
  [filename,newpath] = evriuigetfile('*.xls','Select Taglist File',mypath);
  if filename == 0
    %User cancel.
    return
  end
  setappdata(handles.piconnectgui,'mypath',newpath);
  setappdata(handles.piconnectgui,'taglist',fullfile(newpath,filename))
  %set(handles.tagname,'String',['Tag File: ' filename]);
elseif strcmp(loadtype,'pi')
  %Query for tags.

  %Get point list from SDK object. This brings up a activex gui.
  myAppObject = actxserver('PISDKDlg.ApplicationObject');
  myPointList = myAppObject.TagSearch.Show;
  %NOTE: InterpolatedValues method not yet supported for List object.
  if myPointList.Count == 0
    %User cancel.
    taglist = '';
    return
  end
  %Create cell array of strings from list.
  taglist = '';
  for i = 1:myPointList.Count
    taglist = [taglist; {myPointList.Item(i).Name}];
  end
  try
    %Delete object.
    myAppObject.delete;
  end
  setappdata(handles.piconnectgui,'taglist',taglist)
end

updategui(handles)

%--------------------------------------------------------------------
function updategui(handles)
%Update controls enabled status based on loaded data.

srvname = get(handles.svrName,'String');
if isempty(srvname)
  %No server selected so disable all controls.
  %Server select activex control can't be disabled so no need to re-enable.
  set(findobj(handles.piconnectgui,'Type','uicontrol'),'Enable','off')
  set(findobj(handles.piconnectgui,'Tag',''),'Enable','on');%Enable panel labels.
  set(handles.close,'Enable','on')
  return
else
  %Endable server information panel, use 'on' rather than inactive so user
  %can cut and past information out of it if needed.
  set(get(handles.uipanel2,'Children'),'Enable','on')
  %Enable tag loading.
  set(get(handles.uipanel4,'Children'),'Enable','on')
  %set(get(handles.uipanel7,'Children'),'Enable','on')
  set(get(handles.uipanel9,'Children'),'Enable','on')
  set(handles.reset,'enable','on')
  %Remove child uipanel from list because can't set enable for it (causing error).
  tpanel = get(handles.uipanel7,'Children');
  tpanel = tpanel(~ismember(tpanel,handles.uipanel10));
  set(tpanel,'enable','on');
end

%Update taglist text box if appdata present.
tlist = getappdata(handles.piconnectgui,'taglist');
if ~isempty(tlist) && iscell(tlist)
  sz = length(tlist);
  set(handles.tagname,'String',['Number of Tags Loaded: ' num2str(sz)]);
elseif ~isempty(tlist)
  [junk fname ext] = fileparts(tlist);
  set(handles.tagname,'String',['Tag File: ' fname ext]);
end

%Update rangexls text box if appdata present.
rangexls = getappdata(handles.piconnectgui,'rangexls');
if ~isempty(rangexls)
  [junk fname ext] = fileparts(rangexls);
  set(handles.rangexls,'String',['Range File: ' fname ext]);
end

%Use UI controls String values rather than appdata here becuase user could
%have cut and paste value in.
taglist = ~isempty(get(handles.tagname,'String'));
rangefile = ~isempty(get(handles.rangexls,'String'));
startdate = ~isempty(get(handles.startdate,'String'));
enddate = ~isempty(get(handles.enddate,'String'));

if taglist && (rangefile || (startdate && enddate))
  %Enough information exists to calculate a dso.
  enbl = 'on';
else
  enbl = 'off';
end

%Enable/disable create button and dsname.
lst = {'text38' 'dsname' 'createds' 'optionsgui'};
for i = lst
  set(handles.(i{:}),'enable',enbl);
end

if rangefile
  %Enable append direction.
  set(get(handles.uipanel10,'Children'),'Enable','on')
  %Disable startdate and enddate.
  set(handles.startdate,'Enable','off')
  set(handles.enddate,'Enable','off')
else
  set(get(handles.uipanel10,'Children'),'Enable','off')
end

%Query type/val logic.
selectstr = get(handles.querytype,'String');
qryslct = get(handles.querytype,'Value');
if strcmp(selectstr{qryslct},'Raw Data')
  set(handles.queryval,'Enable','off')
else
  set(handles.queryval,'Enable','on')
end

%Always enable close function.
set(handles.close,'Enable','on')

updatecache(handles)
%--------------------------------------------------------------------
function querytype_Callback(hObject, eventdata, handles)
%Query type selection callback. Will disable value field if 'raw data'.
updategui(handles)

%--------------------------------------------------------------------
function loadrangexls_Callback(hObject, eventdata, handles)
%Load date range for multiple dates call to getpidata.

mypath = getappdata(handles.piconnectgui,'mypath');
[filename,newpath] = evriuigetfile('*.xls','Select Taglist File',mypath);
setappdata(handles.piconnectgui,'rangexls',fullfile(newpath,filename));

updategui(handles)

%--------------------------------------------------------------------
function clearrangexls_Callback(hObject, eventdata, handles)
%Clear xlsrange data and text box.
setappdata(handles.piconnectgui,'rangexls','');
set(handles.rangexls,'String','')
updategui(handles)

%--------------------------------------------------------------------
function pushbutton26_Callback(hObject, eventdata, handles)
%Clear startdate.
set(handles.startdate,'String','')
updategui(handles)

%--------------------------------------------------------------------
function pushbutton27_Callback(hObject, eventdata, handles)
set(handles.enddate,'String','')
updategui(handles)

%--------------------------------------------------------------------.
function createds_Callback(hObject, eventdata, handles)
%Try to create a dataset.
dsoname = get(handles.dsname,'String');
if isempty(dsoname)
  erdlgpls('A name is needed for the DataSet.','DataSet Name Needed');
  uicontrol(handles.dsname);%Give focus to dsname.
  return
end

%Create call to getpidata. The button is not enabled unless there is
%enough info in the controls to try a query so assume it exists and leave
%checking to other functions.

taglist = getappdata(handles.piconnectgui,'taglist');
if isempty(taglist)
  %No appdata so see if string is in uicontrol. User may have cut/paste a
  %file and path.
  taglist =  get(handles.taglist,'String');
end

%If there's an entry into the date range field it has presedence.
rangestr = getappdata(handles.piconnectgui,'rangexls');
if isempty(rangestr)
  %No appdata so see if string is in uicontrol. User may have cut/paste a
  %file and path.
  rangestr = get(handles.rangexls,'String');
end

if isempty(rangestr)
  %No range data.
  userange = 0;
else
  userange = 1;
end

opts = getappdata(handles.piconnectgui,'options');

switch get(handles.querytype,'value')
  case 1
    opts.interpolate = 'interval';
  case 2
    opts.interpolate = 'total';
  case 3
    opts.rawdata = 'on';
end

opts.interpolateval = str2num(get(handles.queryval,'String'));
opts.diplaywarnings = 'off';
if get(handles.mode3,'value')
  opts.appenddir = 'mode 3';
end

if userange
  [pidso warnlog] = getpidata(taglist,rangestr,opts);
else
  [pidso warnlog] = getpidata(taglist,get(handles.startdate,'String'),get(handles.enddate,'String'),opts);
end

tagcache = getappdata(handles.piconnectgui,'tagcache');
tagcache(end+1).name    = dsoname;
tagcache(end).startdate = get(handles.startdate,'String');
tagcache(end).enddate   = get(handles.enddate,'String');
tagcache(end).xslrange  = rangestr;
tagcache(end).options   = opts;
tagcache(end).dso       = pidso;
tagcache(end).warnings  = warnlog;
tagcache(end).taglist   = taglist;
setappdata(handles.piconnectgui,'tagcache',tagcache);

updatecache(handles);

%--------------------------------------------------------------------
function reset_Callback(hObject, eventdata, handles)
%Clear all edit boxes and appdata.

setappdata(handles.piconnectgui,'taglist','');
setappdata(handles.piconnectgui,'rangexls','');

lst = {'tagname' 'startdate' 'enddate' 'rangexls' 'dsname'};

for i = lst
  set(handles.(i{:}),'String','');
end

updategui(handles);

%--------------------------------------------------------------------
function updatecache(handles)
%Update cachetable.
tagcache = getappdata(handles.piconnectgui,'tagcache');

if ~isempty(tagcache)
  dispstr = '';
  for i = 1:length(tagcache)
    szstr = '';
    for j = 1:ndims(tagcache(i).dso)  
      szstr =  [szstr num2str(size(tagcache(i).dso,j)) 'x'];% num2str(size(tagcache(i).dso,2))];
    end
    szstr = szstr(1:end-1);
    
    if ~isempty(tagcache(i).xslrange)
      [junk fname ext] = fileparts(tagcache(i).xslrange);
      timestr = ['   start: ' fname ext];
    else
      timestr =  ['   start: ' tagcache(i).startdate ' end:' tagcache(i).enddate];
    end

    str = [tagcache(i).name  '   (size: ' szstr timestr ')'];
    
    %Find ** in warning and note in str.
    wrns = strfind(tagcache(i).warnings, '**');
    if ~isempty([wrns{:}])
      %A warning was issued, a * to indicate.
      str = [str ' *'];
    end
    dispstr = [dispstr {str}];
  end

  set(handles.listbox2,'String',dispstr);
  set(handles.listbox2,'Enable','on')
  set(handles.text17,'Enable','on')

  %Enable buttons.
  enbl = 'on';
else
  set(handles.listbox2,'String','')
  set(handles.listbox2,'Enable','off')
  set(handles.text17,'Enable','off')
  enbl = 'off';
end

btns = {'loadsettings' 'viewwarning' 'saveall' 'save' 'cleards'};
for i = btns
  set(handles.(i{:}),'enable',enbl)
end

%--------------------------------------------------------------------
function close_Callback(hObject, eventdata, handles)

try
  delete(getappdata(handles.piconnectgui,'editfig'));
end
close(handles.piconnectgui);


%--------------------------------------------------------------------
function save_Callback(hObject, eventdata, handles)
%Save selected ds.
tagcache = getappdata(handles.piconnectgui,'tagcache');
listval = get(handles.listbox2,'Value');
mydat = tagcache(listval);
ds = mydat.dso;
nm = mydat.name;

if isdataset(ds)
  %Put settings in userdata.
  mydat = rmfield(mydat,'dso');
  ds.userdata.querysettings = mydat;
end

if ~isempty(ds)
  %Save model
  [what,where] = svdlgpls(ds,'Save DataSet',nm);
end

%--------------------------------------------------------------------
function cleards_Callback(hObject, eventdata, handles)
%Clear selected data.
tagcache = getappdata(handles.piconnectgui,'tagcache');
listval = get(handles.listbox2,'Value');

tagcache = [tagcache(1:listval-1) tagcache(listval+1:end)];
setappdata(handles.piconnectgui,'tagcache',tagcache)

if listval - 1<=0
  listval = 1;
else
  listval = listval-1;
end

set(handles.listbox2,'Value',listval);

updategui(handles)

%--------------------------------------------------------------------
function saveall_Callback(hObject, eventdata, handles)
%Save all cached data.
tagcache = getappdata(handles.piconnectgui,'tagcache');

if ~isempty(tagcache)
  %Save model
  [what,where] = svdlgpls(tagcache,'Save DataSet','DataSet Cache');
end

%--------------------------------------------------------------------
function loadsettings_Callback(hObject, eventdata, handles)
%Load settings from cached dataset.

reset_Callback(hObject, eventdata, handles);%Clear gui.

tagcache = getappdata(handles.piconnectgui,'tagcache');
listval = get(handles.listbox2,'Value');

mycache = tagcache(listval);

set(handles.dsname,'String',mycache.name);
set(handles.startdate,'String',mycache.startdate);
set(handles.enddate,'String',mycache.enddate);

setappdata(handles.piconnectgui,'options',mycache.options);

%Updategui should populate text box info.
setappdata(handles.piconnectgui,'taglist',mycache.taglist);
setappdata(handles.piconnectgui,'rangexls',mycache.xslrange);

%Update query type.
if strcmp(mycache.options.rawdata,'on')
  set(handles.querytype,'Value',3);
elseif strcmp(mycache.options.interpolate,'interval')
  set(handles.querytype,'Value',1);
elseif strcmp(mycache.options.interpolate,'total')
  set(handles.querytype,'Value',2);
end

set(handles.queryval,'String',mycache.options.interpolateval)

updategui(handles)

%--------------------------------------------------------------------
function viewwarning_Callback(hObject, eventdata, handles)
%View warnings for selected data.
tagcache = getappdata(handles.piconnectgui,'tagcache');
listval = get(handles.listbox2,'Value');
if ~isempty(listval)
  wrn = tagcache(listval).warnings;
  options.figurename = 'PI Query Warnings';
  options.fontname   = get(0,'FixedWidthFontName');
  options.fontsize   = 10;
  fig = infobox(wrn,options);
end

%--------------------------------------------------------------------
function listbox2_Callback(hObject, eventdata, handles)
%Open dataset if double click.

get(handles.piconnectgui,'SelectionType');
if strcmp(get(handles.piconnectgui,'SelectionType'),'open')
  tagcache = getappdata(handles.piconnectgui,'tagcache');
  listval = get(handles.listbox2,'Value');

  mycache = tagcache(listval);
  if isdataset(mycache.dso)
    try
      setappdata(handles.piconnectgui,'dataset',mycache.dso)
      %Create a shareddata object for edits to work with.
      myprops.itemType = 'piconnectData';
      myprops.itemIsCurrent = 1;
      myprops.itemReadOnly = 0;
      myid = setshareddata(handles.piconnectgui,mycache.dso,myprops);
      
      fig = editds(myid);
      setappdata(handles.piconnectgui,'editfig',fig);
      %Disable main figure so user can't change state.
      set(findobj(handles.piconnectgui,'Type','uicontrol'),'Enable','off')
      set(findobj(handles.piconnectgui,'Tag',''),'Enable','on');%Enable panel labels.
      uiwait(fig);

      tagcache(listval).dso = getshareddata(myid); %Store any editted data into cache.
      
      setappdata(handles.piconnectgui,'tagcache',tagcache)
      updategui(handles)
    catch
      updategui(handles)

    end
  end
end

%--------------------------------------------------------------------
function optionsgui_Callback(hObject, eventdata, handles)
%Show options for getpidata.

opts = getappdata(handles.piconnectgui,'options');
o.remove = {'tagsearch' 'interpolate' 'server' 'interpolateval' 'savefile'...
            'diplaywarnings' 'rawdata' 'appenddir'};
        
opts = optionsgui(opts,o);

if ~isempty(opts)
  setappdata(handles.piconnectgui,'options',opts);
end


