function varargout = optionseditor(varargin)
%OPTIONSEDITOR Opens a grid control to edit options.
%
%  Options:
%         startpos : vertical start position on 'parentobjh' for placing objects.
%        recursive : ['yes'|{'no'}] set parent objects appdata options
%                    storage. Used with recursive calls by cells.
%           target : handle of graphics object (figure/uipanel) that stores
%                    preferences/options structure.
%        userlevel : [{'novice'} | 'intermediate' | 'advanced']default user level.
%            fname : function name (used in drop-down menu).
%          disable : [{}] cell of stings with options names to disable in GUI.
%           remove : [{}] cell of stings with options names to remove in GUI.
%
% DATA TYPES:
%  SINGLE        {'char','double'}
%  IN-LINE       {'mode' 'vector_inline'}
%  CELL          {'cell(char)' 'cell(double)' 'cell(vector)' 'cell(select)'} 
%  LOAD DIALOG   {'vector', 'matrix', 'dataset', 'preprocesing', 'directory'}
%  BOOLEAN       {'boolean'}
%  SUBSTRUCT     {'struct'} Open a sub structure in prop grid.
%
% EXAMPLES:
%  Datatype        Valid    
%  'char'          ''
%  'double'        ''
%  'double'        'float'
%  'double'        'int(1:inf)'
%  'double'        'float(1:inf)' 
%  'double'        'int(1:100)' 
%  'select'        {'final' 'all' 'off'}
%  'enable'        {'final' 'all' 'off'} %Used "_" in name field to determined what should be enabled. Only use one per definition. See baselineds for example. 
%  'matrix'        ''
%  'boolean'       ''
%  'directory'     ''
%  'cell(vector)'  '' 
%  'cell(vector)'  'loadfcn=optionsgui'
%
%I/O: opts = optionseditor(function_name)
%I/O: opts = optionseditor(options_structure)
%
%See also: @EControl, @EGrid, GRIDLIST, OPTIONSGUI, PREFOBJCB, PREFOBJPLACE

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0
  error('OPTIONSEDITOR needs at least one input.')
elseif ischar(varargin{1}) | isstruct(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
  if strcmp(getappdata(0,'debug'),'on');
    dbstop if all error
  end
  
  try
    if ischar(varargin{1})
      switch lower(varargin{1})
        case evriio([],'validtopics')
          options = defaultoptions;
          if nargout==0
            evriio(mfilename,varargin{1},options)
          else
            varargout{1} = evriio(mfilename,varargin{1},options);
          end
          return;
        otherwise
          %Call as intialize or subfunction. Can't use 'which' function to
          %distinguish input (gui call vs function call) becuase doen't
          %work well when pcoded, so need to use convention that nargin > 2
          %is function call.
          if nargin > 2
            if nargout == 0;
              %normal calls with a function
              feval(varargin{:}); % FEVAL switchyard
            else
              [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
            end
          else
            %No subfunction located so input must be original call and not a
            %subfunction.
            
            if nargout == 0;
              %normal calls with a function
              feval(varargin{:}); % FEVAL switchyard
            else
              varargout{1} = initialize(varargin{:});
            end
          end
      end
    else
      %Inpute is structure and should be passed to guirun.
      varargout{1} = initialize(varargin{:});
    end
  catch
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
    varargout = {[]};
  end
  
end

if nargout>0 & isempty(varargout)
  varargout = {[]};
end

%------------------------------------------------------
function default = defaultoptions
%Get default options.

default = [];
default.startpos = [];
default.recursive = 'no';
default.target = [];
default.userlevel = 'novice';
default.fname = '';
default.disable = '';
default.remove = '';
default.allowsave = 'no';
default.rowheight = 18;

%--------------------------------------------------------------------
function opts = initialize(varargin)
%Create figure.
opts  = [];
try
  wbarh = waitbar(.1,'Intializing Options...');
  fname = varargin{1};
  
  %Verify that fname has definitions.
  if ischar(fname)
    opts = feval(fname, 'options');
  elseif isstruct(fname);
    opts = fname;
  else
    erdlgpls(['Input for OPTIONSEDITOR must be function name or options structure.'],[upper(mfilename) ' Error']);
  end
  
  %Check for definitions.
  if ~isfield(opts,'definitions')
    erdlgpls(['No definitions field found in options structure for (' fname ').'],[upper(mfilename) ' Error']);
    opts=[];
    close(wbarh)
    return
  else
    if isa(opts.definitions,'function_handle')
      opts.definitions = feval(opts.definitions);
    end
  end
  
  waitbar(.4,wbarh);
  
  if nargin < 2
    guioptions = optionseditor('options');
  else
    guioptions = varargin{2};
  end
  guioptions = reconopts(guioptions,mfilename);
  
  fig = figure(...
    'visible','off',...
    'busyaction','cancel',...
    'menubar','none',...
    'integerhandle','off',...
    'name','Options / Preferences',...
    'numbertitle','off',...
    'color',[1 1 1],...
    'tag','optionseditor',...
    'units','pixels',...
    'ResizeFcn','optionseditor(''resize_callback'',gcbo,[],guihandles(gcbf));');
  set(fig,'CloseRequestFcn', {@closegui,fig});
  
  waitbar(.6,wbarh);
  
  %Set appdata.
  setappdata(fig,'newopts',opts)
  setappdata(fig,'orginalopts',opts);
  
  toolbar(fig,'help');
  
  hmenu = uimenu(fig,'Label','&User Level','tag','FileMenu','callback','optionseditor(''control_callback'',gcbo,''file'');');
  uimenu(hmenu,'tag','novice','label','&Novice','callback','optionseditor(''control_callback'',gcbo,''novice'');');
  uimenu(hmenu,'tag','intermediate','label','&Intermediate','callback','optionseditor(''control_callback'',gcbo,''intermediate'');');
  uimenu(hmenu,'tag','advanced','label','&Advanced','callback','optionseditor(''control_callback'',gcbo,''advanced'');');
  uimenu(hmenu,'label','&Close','Separator','on','callback','optionseditor(''control_callback'',gcbo,''close'');');
  
  hmenu = uimenu(fig,'Label','&Help','tag','HelpMenu','callback','optionseditor(''control_callback'',gcbo,''help'');');
  uimenu(hmenu,'tag','change_font','Label','&Adjust Row Height','callback','optionseditor(''control_callback'',gcbo,''change_rowheight'');');
  uimenu(hmenu,'tag','gui_help','Label','&Help','Separator','on','callback','optionseditor(''control_callback'',gcbo,''open_help'');');
  
  positionmanager(fig,'optionseditor');%Position gui from last known position.
  
  %Add property grid parent panel.
  pg = uipanel(fig,'tag','propgrid','units','pixels','position',[2 34 400 400]);
  
  
  %Add buttons.
  %Factory reset.
  uicontrol(fig,'tag', 'reset_factory',...
    'style', 'pushbutton', ...
    'string', 'Factory Reset', ...
    'units', 'pixels', ...
    'position',[200 2 100 30],...
    'fontsize',getdefaultfontsize,...
    'tooltipstring','Reset all options to factory defaults.',...
    'callback','optionseditor(''control_callback'',gcbo,''reset_factory'');');
  
  %Session reset.
  uicontrol(fig,'tag', 'reset_current',...
    'style', 'pushbutton', ...
    'string', 'Reset', ...
    'units', 'pixels', ...
    'position',[304 2 100 30],...
    'fontsize',getdefaultfontsize,...
    'tooltipstring','Reset to current options.',...
    'callback','optionseditor(''control_callback'',gcbo,''reset'');');

  %Ok.
 okh =  uicontrol(fig,'tag', 'ok',...
    'style', 'pushbutton', ...
    'string', 'Ok', ...
    'units', 'pixels', ...
    'position',[408 2 100 30],...
    'fontsize',getdefaultfontsize,...
    'tooltipstring','Set options.',...
    'callback','optionseditor(''control_callback'',gcbo,''ok'');');

  %Cancel.
  uicontrol(fig,'tag', 'cancel',...
    'style', 'pushbutton', ...
    'string', 'Cancel', ...
    'units', 'pixels', ...
    'position',[512 2 100 30],...
    'fontsize',getdefaultfontsize,...
    'tooltipstring','Cancel',...
    'callback',{@closegui,fig});
  
  set(fig,'visible','on');%You must make visible before egrid so will render on older versions.
  %Creating grid with lots of properties takes a while so make sure waitbar
  %comes to top.
  waitbar(.7,wbarh);
  figure(wbarh)
  eg = EGrid(pg,'ShowSave',true,'PropertyData',opts,'UserLevel',guioptions.userlevel,...
             'HiddenProperties',guioptions.remove,'DisabledProperties',guioptions.disable,...
             'RowHeight',guioptions.rowheight);
  eg.UpdateGrid; %Hide the hidden props.
  eg.UpdateVisible; %If there's an "enable" option that should hide some controls then refresh the interface.  
  
  waitbar(.8,wbarh);
  figure(wbarh)
  drawnow
  
  %Make controls correct size.
  resize_callback(fig,[],[]);
  %Make userlevel menu checked.
  control_callback(fig,guioptions.userlevel)
  
  if ishandle(wbarh)
    close(wbarh)
  end
  
  try
    uiwait(fig);
  catch
    uiresume(fig)
  end
  
  if ishandle(fig) & ~isempty(getappdata(fig,'OK_Press'))
    opts = eg.NewPropertyData;
  else
    %User cancel or close.
    opts = [];
  end
  
  try
    delete(eg)
  end
  
  if ishandle(fig)
    %Save figure position.
    positionmanager(fig,'optionseditor','set')
    delete(fig)
  end
catch
  le = lasterror;
  if ishandle(wbarh)
    close(wbarh)
  end
  try
    delete(eg);
  end
  try
    delete(fig);
  end
  rethrow(le)
end

%--------------------------------------------------------------
function resize_callback(h,eventdata,handles,varargin)
%Resize callback.

%Sometimes handles aren't updated so refresh them manually.
handles = guihandles(h);
set(handles.optionseditor,'units','pixels');%Make sure we're in pixels.

%Get initial positions.
figpos = get(handles.optionseditor,'position');
%Main panel.
if ~isfield(handles,'propgrid')
  %Still initializing.
  return
end
set(handles.propgrid,'position',[4 36 max(500,figpos(3)-6) max(100,figpos(4)-36)])%Main tab group panel.

bshift = 102;

myleft = max(420,figpos(3));
myleft = myleft-bshift;
mypos = get(handles.cancel,'position');
mypos(1) = myleft;
set(handles.cancel,'position',mypos);

myleft = myleft-bshift;
mypos = get(handles.ok,'position');
mypos(1) = myleft;
set(handles.ok,'position',mypos);

myleft = myleft-bshift;
mypos = get(handles.reset_current,'position');
mypos(1) = myleft;
set(handles.reset_current,'position',mypos);

myleft = myleft-bshift;
mypos = get(handles.reset_factory,'position');
mypos(1) = myleft;
set(handles.reset_factory ,'position',mypos);

%------------------------------------------------
function closegui(varargin)

beenclosed = getappdata(varargin{end},'beenclosed');
if ~isempty(beenclosed) & beenclosed
  delete(varargin{end}); %FORCE figure to close (in case uiresume didn't work)
  return;
end
uiresume(varargin{end});
setappdata(varargin{end},'beenclosed',true); %flag that we TRIED to uiresume

%------------------------------------------------
function control_callback(varargin)
%Button callback.

fig     = ancestor(varargin{1},'Figure');
handles = guihandles(fig);
gridh   = handles.eGrid;
egobj   = get(gridh,'UserData');

switch varargin{2}
  case {'novice' 'intermediate' 'advanced'}
    ul = varargin{2};
    egobj.UserLevel = varargin{2};
    set(allchild(handles.FileMenu),'checked','off');
    set(handles.(ul),'checked','on');
    setplspref('optionseditor','userlevel',ul);
    egobj.UpdateVisible;
  case {'close' 'cancel'}
    closegui(fig);
  case 'reset'
    ResetGrid(egobj);
  case 'ok'
    %Uiresume.
    setappdata(fig,'OK_Press',1);
    uiresume(fig);
  case 'reset_factory'
    %Get function name.
    myopts = egobj.PropertyData;
    myans = evriquestdlg(['This will permanently reset your options for ' upper(myopts.functionname) ' to factory default settings. Continue?'],'Factory Reset');
    if strcmp(myans,'Yes')
      %Set back to factory.
      setplspref(myopts.functionname,'factory');
      %Get factory options.
      newopts = feval(myopts.functionname,'options');
      %Set grid to factory options.
      egobj.PropertyData = newopts;
    end
  case 'change_rowheight'
    rh = egobj.RowHeight;
    rh_set = inputdlg({'Enter new row height:'},'Row Height',1,{num2str(rh)});
    if isempty(rh_set)
      return
    end
    rh_set = round(str2num(rh_set{:}));
    if rh_set > 0
      egobj.RowHeight = rh_set;
      setplspref('optionseditor','rowheight',rh_set)
    end
  case 'open_help'
    evrihelp('optionseditor')
    
end

%------------------------------------------------
function test(varargin)
%Menu callback
f = allchild(0)
h = guihandles(f)
g = h.eGrid
eg = get(g,'UserData')
eg.PropertyData
eg.NewPropertyData
