function varargout = glswset(varargin)
% GLSWSET M-file for glswset.fig
%      GLSWSET, by itself, creates a new GLSWSET or raises the existing
%      singleton*.
%
%      H = GLSWSET returns the handle to a new GLSWSET or the handle to
%      the existing singleton*.
%
%      GLSWSET('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GLSWSET.M with the given input arguments.
%
%      GLSWSET('Property','Value',...) creates a new GLSWSET or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before glswset_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to glswset_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Edit the above text to modify the response to help glswset

% Last Modified by GUIDE v2.5 17-Oct-2022 12:02:46

if nargin == 0  | ((nargin == 1 || nargin ==2) & isa(varargin{1},'struct'))% LAUNCH GUI

	fig = openfig(mfilename,'reuse');
  set(fig,'WindowStyle','modal');
  set(fig,'visible','off');
  set(fig,'closerequestfcn','try;glswset(''close_Callback'',gcbf,[],guidata(gcbf));catch;delete(gcbf);end');
  centerfigure(fig,gcbf);
  setappdata(fig,'parentfig',gcbf);

	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

  %resize as needed for font size
  fs = getdefaultfontsize('normal');
  scl = fs/10;
  remapfig([0 0 1 1],[0 0 scl scl],fig)
  set(allchild(fig),'fontsize',fs)
  pos = get(fig,'position');
  set(fig,'position',pos.*[1 1 scl scl]-[pos(3:4)*(scl-1) 0 0]);

  
  % Generate a structure of handles to pass to callbacks, and store it. 
  handles = guihandles(fig);
  guidata(fig, handles);
  if nargin > 0;
    setup(handles, varargin{1})
    %Load data if it's there.
    if length(varargin)>1
      %Change clutter source.
      extdatabtn_Callback(handles.extdatabtn, [], handles);
      %Load data.
      loadpbtn_Callback(handles.loadpbtn, [], handles, varargin{2})
    end
  else
    setup(handles, []);
  end
  
  set(fig,'visible','on');

	% Wait for callbacks to run and window to be dismissed:
	uiwait(fig);
  
  %Need to know what button pused for when using this gui as clutter
  %interface.
  mybutton = [];
  
	if nargout > 0
    le = [];
    if ishandle(fig);  %still exists?
      mybutton = getappdata(fig,'buttonpushed');
      try
        varargout{1} = encode(handles);
      catch
        %catch here and close figure below
        evrierrordlg({'Could not generate preprocessing due to an error.' lasterr},'Preprocessing Error');
        if nargin>0
          varargout{1} = varargin{1};
        else
          varargout{1} = [];
        end
      end
    else
      varargout{1} = [];
    end
  end
  
  if nargout == 2
    varargout{2} = mybutton;
  end

  if ishandle(fig);  %still exists?
    close_Callback(fig,[],guidata(fig));
  end
  
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
    if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return; 
  end
  
	try
    if nargout == 0;
      feval(varargin{:});
    else
      [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    end
	catch
		disp(lasterr);
	end

end

%------------------------------------------------------
function setup(handles,varargin)
%Set up gui controls.

glswset_OpeningFcn(handles.settingsfigure,[],handles);
pfig = getappdata(handles.settingsfigure,'parentfig');
if isempty(pfig)
  pdata = [];
  set(handles.clsresbtn, 'enable', 'off');
elseif strcmpi(get(pfig,'tag'),'analysis')
  pdata = analysis('getobjdata','xblock',guidata(pfig));
  fn  = getappdata(pfig,'curanal');
  if ~strcmp(fn, 'cls')
    set(handles.clsresbtn, 'enable', 'off');
  end
else
  pdata = preprocess('getdataset',pfig);%Data to preprocess.
  menu_h = getappdata(pfig,'parenthandle');%Get analysis menu item used to call this gui.
  afig = menu_h.Parent.Parent;%Travel up to get analysis figure.
  if ~isempty(afig)
    fn  = getappdata(afig,'curanal');
  else
    fn = [];
  end
  if ~strcmp(fn, 'cls')
    set(handles.clsresbtn, 'enable', 'off');
  end
end

if nargin>1 & ~isempty(varargin{1})
  %got a preprocessing structure
  pp = varargin{1};
else
  pp = default;
end

%Populate dropdown.
mydropmenuitems = '';
if ~isempty(pdata)
  myclasses = pdata.class;
  notempt = ~cellfun('isempty',myclasses(1,:));%Not empty.
  if any(notempt)
    %Add sets to menu.
    mysets = find(notempt);
    for i = find(notempt)
      clname = pdata.classname{1,i};
      if isempty(clname)
        clname = sprintf('Class Set %d',i);
      end
      mydropmenuitems = [mydropmenuitems; {clname} {i}];
    end
  end
end

setappdata(handles.settingsfigure,'ClassSetTable',mydropmenuitems)
if isempty(mydropmenuitems)
  %Disable.
  set(handles.class_set_choose,'enable','off','string',{'n/a'});
else
  %Add items.
  set(handles.class_set_choose,'string',mydropmenuitems(:,1));
  
  %Set existing class set.
  if ~isempty(pp.userdata) & isfield(pp.userdata,'classset')
    %If existing class set can be used with data then set it.
    mypos = pp.userdata.classset==[mydropmenuitems{:,2}];
    if any(mypos)
      set(handles.class_set_choose,'value',find(mypos));
    end
  end
end

hidebtn_Callback(handles.hidebtn,[],handles);  %hide details of source
setappdata(handles.settingsfigure,'preprocessing',pp);
if ~isempty(pp.userdata) & ~isstruct(pp.userdata) & isnumeric(pp.userdata)
  %alpha value only
  a = pp.userdata;
  pp.userdata = [];
  pp.userdata.a = a;
  pp.userdata.source = 'automatic';
  pp.userdata.applymean = 'yes';
  pp.userdata.meancenter = 'yes';
end

if ~isfield(pp.userdata,'applymean')
  pp.userdata.applymean = 'yes';
end

if ~isempty(pp.userdata) & isstruct(pp.userdata);
  %structure - decode options

  %get external data (if any)
  if ~isempty(pp.out) & iscell(pp.out)
    loadpbtn_Callback(handles.loadpbtn, [], handles, pp.out{1})
  end
  %set source mode
  source_str = {
    'automatic' 'gradient' 'classes'  'external' 'cls_residuals';
    'autobtn'   'yblbtn'   'xblclbtn' 'extdatabtn' 'clsresbtn'
    };
  source = source_str{2,ismember(source_str(1,:),pp.userdata.source)};
  feval([source '_Callback'],handles.(source),[],handles);

  %algorithm and alpha/num pcs
  if pp.userdata.a>=0 & isfinite(pp.userdata.a)
    %GLSW
    set(handles.alphatxt,'string',num2str(pp.userdata.a));
    alphatxt_Callback(handles.alphatxt,[],handles);
    setalgostate(1, handles);
  elseif pp.userdata.a==-inf
    %EMM
    setalgostate(2, handles);
  elseif pp.userdata.a<0
    %EPO
    set(handles.numpctxt,'string',num2str(max([1 abs(round(pp.userdata.a))])));
    setalgostate(0, handles);
  else   %probably +inf
    %None
    setalgostate(-1, handles);
  end

  %mean centering checkbox
  set(handles.meancenter,'value',strcmp(pp.userdata.meancenter,'yes'))
  if strcmp(pp.userdata.meancenter,'yes')
    amen  = 'on';
  else
    amen = 'off';
  end
  set(handles.applymean,'value',strcmp(pp.userdata.applymean,'yes'),'enable',amen)
  if strcmp(source_str, 'cls_residuals')
    set(handles.meancenter, 'value', 0, 'enable', 'off');
  end
  
else
  %default conditions if nothing passed in
  setalgostate(1, handles);  %default state is GLSW
  autobtn_Callback(handles.autobtn,[],handles);   %default source is automatic
end

%------------------------------------------------------
function out = default(varargin)

out = glsw('default');


%------------------------------------------------------
function pp = encode(handles)
%Create preprocess structure from gui settings.

pp = getappdata(handles.settingsfigure,'preprocessing');

opts = struct('a',[],'source','automatic','meancenter','yes');

if get(handles.meancenter,'value')
  opts.meancenter = 'yes';
else
  opts.meancenter = 'no';
end
if get(handles.applymean,'value')
  opts.applymean = 'yes';
else
  opts.applymean = 'no';
end


%determine what algorithm and alpha we are using
if get(handles.glswbtn,'value')
  %GLSW mode
  opts.a = str2double(get(handles.alphatxt,'string'));
elseif get(handles.epobtn,'value')
  %EPO/EMM mode
  opts.a = -str2double(get(handles.numpctxt,'string'));
else
  %none
  opts.a = inf;
  opts.meancenter = 'no';
end

%Get classset.
cltbl = getappdata(handles.settingsfigure,'ClassSetTable');
if ~isempty(cltbl)
  clval = get(handles.class_set_choose,'value');
  clset = cltbl{clval,2};
  opts.classset = clset;
else
  opts.classset = 1;
end

%identify source type
source = get([handles.autobtn handles.yblbtn handles.xblclbtn handles.extdatabtn handles.clsresbtn], 'Value');
source = find([source{:}]);
source_str = {'automatic' 'gradient' 'classes' 'external' 'cls_residuals'};
source = source_str{source};
opts.source = source;

switch source
  case 'automatic'
    cal = 'if length(otherdata)<1; otherdata = {[]}; end; out{2}=glsw(data,otherdata{1},userdata);data=glsw(data,out{2});';

  case 'gradient'
    cal = 'if length(otherdata)<1; error(''GLSW with y-gradient requires a y-block and a regression model type''); end; out{2}=glsw(data,otherdata{1},userdata);data=glsw(data,out{2});';
  
  case 'classes'
    cal = 'out{2}=glsw(data,[],userdata);data=glsw(data,out{2});';

  case 'external'
    cal = ['ext=matchvars(data,out{1});if size(ext,2)~=size(data,2);error(''GLSW FAILER: Number of columns must be equal, unable to calculate GLSW.'');end;'...
          'ext.include{2}=data.include{2};out{2}=glsw(ext,userdata);data=glsw(data,out{2});'];
    myid = getappdata(handles.settingsfigure, 'extdata');
    pp.out{1} = myid.object;

  case 'cls_residuals'
    cal = [ ...
      'if isdataset(data); ' ...
        'ix = data.include{1}; iy = data.include{2};' ...
        'if isdataset(otherdata{1}); otherdata1 = otherdata{1}.data(ix,otherdata{1}.include{2}); end;' ...
        'if ~isdataset(otherdata{1}); otherdata1 = otherdata{1};end;' ...
        'purespec = otherdata1\data.data(ix,iy); xhat = otherdata1*purespec;' ...
        'resids = nan(size(data));resids(ix,iy) = data.data(ix,iy) -xhat;' ...
        'resids = dataset(resids);resids.include{1} = ix; resids.include{2} = iy;' ...
      'else;' ...
        'purespec = otherdata{1}\data; xhat = otherdata{1}*purespec; resids = data -xhat;' ...
      'end;' ...
      'userdata.purespec = purespec;'...
      'out{2} = glsw(resids,userdata);' ...
      'out{3} = data;' ...
      'data = glsw(data,out{2});'];
    pp.keyword = 'declutter GLS Weighting';
end
pp.calibrate = {cal};

switch source
  case 'cls_residuals'
    pp.apply = {'out{4} = data; data=glsw(data,out{2});' }; 
end
pp.userdata = opts;

pp = setdescription(pp);

% --------------------------------------------------------------------
function p = setdescription(p)

switch p.userdata.source
  case 'automatic'
    desc = '';
  case 'gradient'
    desc = 'y gradient,';  
  case 'classes'
    desc = 'classes,';
  case 'external'
    desc = 'external,';
  case 'cls_residuals'
    desc = 'CLS residuals,';
end

if isempty(p.userdata.a)
  p.description = 'Disabled Clutter Filter';
else
  switch p.userdata.a
    case inf
      %NONE
      p.description = 'Disabled Clutter Filter';
    otherwise
      if p.userdata.a>0
        %GLSW mode.
        p.description = sprintf('GLS Weighting (%salpha %g)',desc,p.userdata.a);
      else
        if isfinite(p.userdata.a)
          %EPO/EMM Mode with k PCs
          p.description = sprintf('EPO/EMM Filter (%s%i PCs)',desc,abs(p.userdata.a));
        else
          %EPO/EMM Mode with k PCs
          p.description = sprintf('EMM Filter (%sFull Rank)',desc);
        end          
      end
  end
  
end

% --- Executes just before glswset is made visible.
function glswset_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to glswset (see VARARGIN)

% Choose default command line output for glswset
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes glswset wait for user response (see UIRESUME)
% uiwait(handles.figure1);
set(handles.autobtn, 'Value', 1.0);
set(handles.yblbtn, 'Value', 0.0);
set(handles.xblclbtn, 'Value', 0.0);
set(handles.extdatabtn, 'Value', 0.0);
set(handles.clsresbtn, 'Value', 0.0);
set(handles.loadpbtn, 'Enable', 'off');
set(handles.editpbtn, 'Enable', 'off');
set([handles.extdatasztxtlabel handles.extdatasztxt], 'Enable', 'off');
szstr = '<empty>';
set(handles.extdatasztxt, 'String', szstr);

%use unicode to display alpha symbol
alphaLabel = get(handles.alphalbl, 'string');
alphaLabel = insertBefore(alphaLabel, ':', ' (\x3B1)');
alphaLabel = compose(alphaLabel); 
set(handles.alphalbl, 'String', alphaLabel);

setappdata(handles.settingsfigure, 'extdata', []);

set(handles.glswbtn, 'Value', 1.0);
set(handles.epobtn, 'Value', 0.0);
set(handles.alphatxt, 'Enable', 'On');
ops = glsw('options');
set(handles.alphatxt, 'String', sprintf('%.6g', ops.a));
%set(handles.alphalbl, 'Enable', 'On');
set(handles.numpctxt, 'Enable', 'Off');
set(handles.numpctxt, 'String','1');


% --- Outputs from this function are returned to the command line.
function varargout = glswset_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in autobtn.
function autobtn_Callback(hObject, eventdata, handles)
% hObject    handle to autobtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of autobtn

setsrcstate(hObject, handles);


% --- Executes on button press in yblbtn.
function yblbtn_Callback(hObject, eventdata, handles)
% hObject    handle to yblbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of yblbtn

setsrcstate(hObject, handles);


% --- Executes on button press in xblclbtn.
function xblclbtn_Callback(hObject, eventdata, handles)
% hObject    handle to xblclbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of xblclbtn

setsrcstate(hObject, handles);


% --- Executes on button press in extdatabtn.
function extdatabtn_Callback(hObject, eventdata, handles)
% hObject    handle to extdatabtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of extdatabtn

setsrcstate(hObject, handles);
set(handles.loadpbtn, 'Enable', 'On');
set([handles.extdatasztxtlabel handles.extdatasztxt], 'Enable', 'On');

myid = getappdata(handles.settingsfigure, 'extdata');
if isempty(myid) | (isshareddata(myid) & isempty(myid.object))
  szstr = '<empty>';
  set(handles.extdatasztxt, 'String', szstr);
  set(handles.editpbtn, 'Enable', 'Off');
else
  cursize = size(myid.object);
  szstr   = sprintf('%d x ', cursize);
  szstr   = szstr(1:end-2);
  szstr   = char(szstr);
  set(handles.extdatasztxt, 'String', szstr);
  set(handles.editpbtn, 'Enable', 'On');
end

% --- Executes on button press in clsresbtn.
function clsresbtn_Callback(hObject, eventdata, handles)
% hObject    handle to clsresbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of clsresbtn

setsrcstate(hObject, handles);
set(handles.loadpbtn, 'Enable', 'Off');
set([handles.extdatasztxtlabel handles.extdatasztxt], 'Enable', 'Off');
set([handles.meancenter handles.applymean], 'value', 0, 'enable', 'off');
set([handles.cvcheckbox handles.cvbutton], 'visible', 'on');
if get(handles.glswbtn, 'value') || get(handles.epobtn, 'value')
  set(handles.cvcheckbox, 'enable', 'on');
end


%-------------------------------------------------------------
function setsrcstate(hObject, handles)
btntags  = {'autobtn' 'yblbtn' 'xblclbtn' 'extdatabtn' 'clsresbtn'};
desc = {'Automatic' 'Y-block Grad.' 'X-Classes' 'External' 'CLS Residuals'};
pbtntags = {'loadpbtn' 'editpbtn'};
txttags  = {'extdatasztxt' 'extdatasztxtlabel'};

for lll = 1:length(btntags)
  set(handles.(btntags{lll}), 'Value', 0.0);
end

set(hObject, 'Value', 1.0);
set(handles.sourcestring,'string',desc{ismember(btntags,get(hObject,'tag'))});

for mmm = 1:length(pbtntags)
  set(handles.(pbtntags{mmm}), 'Enable', 'Off');
end

for nnn = 1:length(txttags)
  set(handles.(txttags{nnn}), 'Enable', 'off');
end

set([handles.meancenter handles.applymean], 'value', 0, 'enable', 'on');
set([handles.cvcheckbox handles.cvbutton], 'visible', 'off', 'enable', 'off');
set(handles.cvcheckbox, 'value', 0);

%-------------------------------------------------------------
function setalgostate(glsmode, handles)

if isempty(glsmode)
  %glsmode: 0 = EPO, 1 = GLSW, 2 = EMM, -1 = none
  glsmode = get(handles.glswbtn,'value')*1;
  if get(handles.nonebtn,'value')
    glsmode = -1;
  end
end

if glsmode~=-1 & get(handles.nonebtn,'value')
  %WAS in none mode and leaving it - reset meancenter flag
  oldmncn = getappdata(handles.nonebtn,'meancenter');
  if ~isempty(oldmncn)
    set(handles.meancenter,'value',oldmncn)
    setappdata(handles.nonebtn,'meancenter',[]);  %clear old value
  end
end

if get(handles.clsresbtn, 'value')
  enab = 'off';
else
  enab = 'on';
end
set([handles.meancenter handles.applymean],'enable',enab);
set([handles.numpctxt handles.numpclbl handles.alphatxt handles.alphalbl handles.alphaslider handles.alphaslidermin handles.alphaslidermax],'enable','off')
set([handles.epobtn handles.nonebtn handles.glswbtn handles.emmbtn],'value',0);  %deselect all radio buttons
switch glsmode
  case -1  %NONE
    set(handles.nonebtn,'value',1)
    set([handles.meancenter handles.applymean handles.cvcheckbox handles.cvbutton],'enable','off');
    if get(handles.meancenter,'value')
      %if it was "on", store value
      setappdata(handles.nonebtn,'meancenter',get(handles.meancenter,'value'));  %store mncn value
    end
    set(handles.meancenter,'value',0);
  case 0  %EPO
    set(handles.epobtn,'value',1)
    set([handles.numpctxt handles.numpclbl handles.cvcheckbox],'enable','on');
  case 1  %GLSW
    set(handles.glswbtn,'value',1)
    set([handles.alphatxt handles.alphalbl handles.alphaslider handles.alphaslidermin handles.alphaslidermax handles.cvcheckbox],'enable','on');
  case 2  %EMM/ELS
    set(handles.epobtn,'value',1)
    set([handles.numpctxt handles.numpclbl],'enable','on');
    set(handles.numpctxt,'string','Inf');
    set(handles.cvcheckbox, 'enable','off');
end

% --- Executes on button press in loadpbtn.
function loadpbtn_Callback(hObject, eventdata, handles, extdata)
% hObject    handle to loadpbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if nargin<4;
  extdata = lddlgpls({'double' 'dataset' 'struct' 'evrimodel'},'Select External Clutter Data or Model');
end

if ~isempty(extdata)
  %share data
  if ismodel(extdata)
    %Extract loadings and pass as data.
    try
      ds = extdata.datasource{1};
      incl = extdata.detail.include{2,1};
      loads = extdata.loads{2,1}';
      extdata = zeros(size(loads,1),ds.size(2));
      extdata(:,incl) = loads;
    catch
      erdlgpls({'Unable to load model as clutter basis.' lasterr},'Error Loading Basis Model');
      return;
    end
      
  end
  if ~isdataset(extdata)
    extdata = dataset(extdata);
  end
  myid = getappdata(handles.settingsfigure,'extdata');
  if ~isshareddata(myid) | isempty(myid.object)
    myid = setshareddata(handles.settingsfigure,extdata);
    linkshareddata(myid,'add',handles.settingsfigure,'glswset');
    setappdata(handles.settingsfigure,'extdata',myid)
  else
    setshareddata(myid,extdata)
  end
  %update controls
  extdatabtn_Callback(handles.extdatabtn, [], handles);
end



% --- Executes on button press in editpbtn.
function editpbtn_Callback(hObject, eventdata, handles)
% hObject    handle to editpbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

myid = getappdata(handles.settingsfigure,'extdata');
if isshareddata(myid) & ~isempty(myid.object)
  editds(myid)
end


% --- Executes on button press in glswbtn.
function glswbtn_Callback(hObject, eventdata, handles)
% hObject    handle to glswbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of glswbtn

setalgostate(1, handles);


% --- Executes on button press in epobtn.
function epobtn_Callback(hObject, eventdata, handles)
% hObject    handle to epobtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of epobtn

setalgostate(0, handles);


%-------------------------------------------------------------
function alphatxt_Callback(hObject, eventdata, handles, varargin)
% hObject    handle to alphalbl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of alphalbl as text
%        str2double(get(hObject,'String')) returns contents of alphalbl as a double

if isempty(hObject)
  cur_str = varargin{1};
else
  cur_str = get(hObject, 'String');
end
cur_val = str2double(cur_str);

if isempty(cur_val) | cur_val<=0 | ~isfinite(cur_val)
  ops = glsw('options');
  cur_val = ops.a;
end

if isempty(hObject)
  set(handles.alphatxt, 'string', sprintf('%.6g', cur_val'));
else
  set(hObject, 'String', sprintf('%.6g', cur_val'));
end
slidervalue = -log10(cur_val);
set(handles.alphaslider,'value',slidervalue,'min',min(slidervalue,-1),'max',max(slidervalue,7));


%-------------------------------------------------------------
function numpctxt_Callback(hObject, eventdata, handles, varargin)
% hObject    handle to numpclbl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numpclbl as text
%        str2double(get(hObject,'String')) returns contents of numpclbl as a double


if isempty(hObject)
  cur_str = varargin{1};
else
  cur_str = get(hObject, 'String');
end
cur_val = str2double(cur_str);

if ~isempty(cur_val) && cur_val>0 && ~isnan(cur_val)
  set(hObject, 'String', sprintf('%d', round(cur_val)));
else
  set(hObject, 'String', '1');
end

if isempty(hObject)
  set(handles.numpctxt, 'String', sprintf('%d', round(cur_val)));
end


% --- Executes on button press in okpbtn.
function okpbtn_Callback(hObject, eventdata, handles)
% hObject    handle to okpbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(handles.extdatabtn,'value')
  myid = getappdata(handles.settingsfigure,'extdata');
  if ~isshareddata(myid) | isempty(myid.object)
    erdlgpls('You must load data to use "External Data" clutter source. Load data or change clutter source mode.','Clutter Source Invalid');
    return
  end
end

%Need a way to indicate what button is pushed for when we're using this
%interface for analysis clutter.
setappdata(handles.settingsfigure,'buttonpushed','ok')


uiresume(gcbf)

%-------------------------------------------
function updateshareddata(varargin)

handles = guidata(varargin{1});
extdatabtn_Callback(handles.extdatabtn, [], handles);

%-------------------------------------------
function propupdateshareddata(varargin)

handles = guidata(varargin{1});
extdatabtn_Callback(handles.extdatabtn, [], handles);


% --- Executes on button press in cancelpbtn.
function cancelpbtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelpbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(gcbf)

%----------------------------------------------------
function close_Callback(hObject, eventdata, handles)

myid = getappdata(handles.settingsfigure,'extdata');
if isshareddata(myid)
  delete(myid);
end
delete(handles.settingsfigure);

%---------------------------------------------------
function helpbtn_Callback(hObject, eventdata, handles)

evrihelp('GLSW_Settings_GUI')


% --- Executes on button press in meancenter.
function meancenter_Callback(hObject, eventdata, handles)
% hObject    handle to meancenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of meancenter

%Comment out code below based on request from Neal (helpdesk ticket 892544)
% if get(hObject,'Value')
%   en = 'on';
% else
%   en = 'off';
% end
% set(handles.applymean,'enable',en)
  

% --- Executes on slider movement.
function alphaslider_Callback(hObject, eventdata, handles)
% hObject    handle to alphaslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


value = get(handles.alphaslider,'value');
alpha = 10.^(-value);
alpha = str2num(sprintf('%0.2g',alpha));  %round to 2 digits
set(handles.alphatxt,'string',num2str(alpha));


% --- Executes during object creation, after setting all properties.
function alphaslider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alphaslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in detailsbtn.
function detailsbtn_Callback(hObject, eventdata, handles)
% hObject    handle to detailsbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
grps = handlegroups(handles);
set(grps.sourcefake,'visible','off');
set(grps.source,'visible','on');
resize_Callback(handles.settingsfigure,[],handles);


% --- Executes on button press in hidebtn.
function hidebtn_Callback(hObject, eventdata, handles)
% hObject    handle to hidebtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%hide the "real" source box and contents and show the "fake" source box and
%contents

grps = handlegroups(handles);
set(grps.sourcefake,'visible','on');
set(grps.source,'visible','off');
resize_Callback(handles.settingsfigure,[],handles);

%---------------------------------------------------------------
function resize_Callback(hObject,eventdata,handles)
%handle resize (only called internally for now, so only need to handle
%dynamic open/close of panels

grps = handlegroups(handles);
set(handles.settingsfigure,'units','pixels');
figpos = get(handles.settingsfigure,'position');

%get height of all visible groups (stacked)
padding = 2;  %padding between groups and at top and bottom
height = padding;
for g = fieldnames(grps)';
  grp = grps.(g{:});
  vis = get(grp(1),'visible');
  if strcmp(vis,'on')
    %group is visible, get height
    set(grp,'units','pixels');
    pos = get(grp,'position');
    pos = cat(1,pos{:});
    height = height + max(pos(:,2)+pos(:,4))-min(pos(:,2)) + padding;
  end    
end

%adjust figure size
figHeightDelta = height-figpos(4);
figpos(4) = height;
figpos(2) = figpos(2)-figHeightDelta;

%dock groups
top = figpos(4)-padding;
for g = fieldnames(grps)';
  grp = grps.(g{:});
  vis = get(grp(1),'visible');
  if strcmp(vis,'on')
    %group is visible, position
    set(grp,'units','pixels');
    pos = get(grp,'position');
    pos = cat(1,pos{:});
    oldtop = max(pos(:,2)+pos(:,4));
    pos(:,2) = pos(:,2)-(oldtop-top);
    set(grp,{'position'},mat2cell(pos,ones(length(grp),1),4))
    top = min(pos(:,2))-padding;
  end    
end

%the following line is here to fix an odd issue when setting the visibility 
%of the figure from off to on in myFigPlotAndChoose_callback, which changes 
%the width of the figure and cuts off some the controls. This line seems to 
%fix it but not sure why.
%try this line
%try setting figure to be resizable and then not resizable after line 931
%try setting enable to off on entire clutter settings gui
%figpos(3) = figpos(3); % this does not work
%figpos(3) = 340.8000;

set(handles.settingsfigure,'position',figpos);

%---------------------------------------------------------------
function grps = handlegroups(handles)
%return handles within each group

grps = [];

grps.sourcefake = [
  handles.sourcepnlfake
  handles.sourcestring
  handles.sourceheaderfake
  handles.detailsbtn
  ];

grps.source = [
  handles.sourcepnl
  handles.sourceheader
  handles.extdatasztxtlabel
  handles.hidebtn
  handles.extdatasztxt
  handles.editpbtn
  handles.loadpbtn
  handles.extdatabtn
  handles.xblclbtn
  handles.yblbtn
  handles.clsresbtn
  handles.autobtn
  handles.class_set_choose
  ];

grps.algorithm = [
  handles.algopnl
  handles.algorithmheader
  handles.epobtn
  handles.emmbtn
  handles.glswbtn
  handles.numpctxt
  handles.alphatxt
  handles.numpclbl
  handles.alphalbl
  handles.alphaslidermax
  handles.alphaslidermin
  handles.alphaslider
  handles.applymean
  handles.meancenter
  handles.nonebtn
  handles.cvbutton
  handles.cvcheckbox
];

grps.buttons = [
  handles.cancelpbtn
  handles.okpbtn
  handles.helpbtn
  ];


% --- Executes on button press in nonebtn.
function nonebtn_Callback(hObject, eventdata, handles)
% hObject    handle to nonebtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of nonebtn


setalgostate(-1, handles);


% --- Executes on selection change in class_set_choose.
function class_set_choose_Callback(hObject, eventdata, handles)
% hObject    handle to class_set_choose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns class_set_choose contents as cell array
%        contents{get(hObject,'Value')} returns selected item from class_set_choose


setsrcstate(handles.xblclbtn, handles);


% --- Executes on button press in applymean.
function applymean_Callback(hObject, eventdata, handles)
% hObject    handle to applymean (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of applymean


% --- Executes on button press in emmbtn.
function emmbtn_Callback(hObject, eventdata, handles)
% hObject    handle to emmbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of emmbtn
setalgostate(2, handles);


% --- Executes on button press in cvcheckbox.
function cvcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to cvcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cvcheckbox
cvCheckbox_value = get(handles.cvcheckbox, 'value');
if cvCheckbox_value
  enab = 'on';
else
  enab = 'off';
end
set(handles.cvbutton, 'enable', enab);

% --- Executes on button press in cvbutton.
function cvbutton_Callback(hObject, eventdata, handles)
% hObject    handle to cvbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if verLessThan('matlab','9.9')
  %Need MATLAB 2020b plus for UIFIGURE to be modal
  error('MATLAB 9.9 (2020b) or higher is required.')
end
[cvi, ~, ~, ~, ~] = getAnalysisInfo(handles);
if strcmp(cvi{1}, 'none')
  evriwarndlg('Unable to perfrom Gray CLS when cross-validation method is none.', 'Warning...');
  return;
end

if handles.glswbtn.Value
  cur_AlphaStr = get(handles.alphatxt, 'String');
  cur_AlphaVal = str2double(cur_AlphaStr);
  minValue = cur_AlphaVal/10;
  setappdata(handles.settingsfigure, 'minValue', minValue);
  maxValue = cur_AlphaVal*10;
  setappdata(handles.settingsfigure, 'maxValue', maxValue);
  setappdata(handles.settingsfigure, 'alphaWin', 11);
  
  figName = 'Alpha Cross Val Settings';
  figHeight = 160;
  controlHeight = 85;
  enab = 'on';
  myMaxLabel = 'Max Alpha:';
  myMaxTooltip = 'Less agressive declutter';
  myMinLabel = 'Min Alpha:';
  myMinTooltip = 'More aggressive declutter';
  isEditable = 'on';
  maxLimits = [cur_AlphaVal Inf];
  minLimits = [0 cur_AlphaVal];
  tooltipWord = 'alpha';
else
  cur_NumPCStr = get(handles.numpctxt, 'String');
  maxValue = str2double(cur_NumPCStr);
 [cvi, xdata, ~, ~, ~] = getAnalysisInfo(handles);
  cvmaxPC = getMaxCVallowedPCs(xdata,cvi);
  if maxValue > cvmaxPC
    maxValue = cvmaxPC;
  end
  
  figName = 'EPO Cross Val Settings';
  figHeight = 100;
  controlHeight = 50;
  enab = 'off';
  myMaxLabel = 'Max PC:';
  myMaxTooltip = 'Max number of PCs';
  myMinLabel = 'Min PC:';
  myMinTooltip = 'Min number of PCs';
  minValue = 1;
  setappdata(handles.settingsfigure, 'minValue', minValue);
  setappdata(handles.settingsfigure, 'maxValue' , maxValue);
  cur_AlphaStr = '';
  isEditable = 'off';
  maxLimits = [minValue Inf];
  minLimits = [0 1];
  tooltipWord = 'PC';
end

myfig = uifigure('Name', figName,...
  'WindowStyle','modal','Visible', 'on',...
  'Position',...
  [handles.settingsfigure.Position(1)+100 handles.settingsfigure.Position(2)+250 275 figHeight]);

myFigCancelBtn = uibutton('Parent', myfig, 'Text', 'Cancel', 'Position',[220 10 50 20], 'ButtonPushedFcn', {@cancelpbtn_Callback handles});
myFigPlotAndChoose = uibutton('Parent', myfig,'Text','Plot and Choose', 'Tooltip', ['Plot cross-validation results and choose ' tooltipWord  ' to keep'],...
  'Position',[10 10 200 20], 'ButtonPushedFcn', {@myFigPlotAndChoose_callback handles myfig});

myAlphaLabel = uilabel('Parent', myfig,'Position', [10 120 150 30], 'Text', 'Current Alpha Value:', 'Visible', enab);
myAlphaStaticField = uilabel('Parent', myfig,'Text',...
  cur_AlphaStr, 'Position', [130 120 135 30], 'Visible', enab, 'Tag', 'curValue');

pos1 = [10 controlHeight 150 30];
pos2 = [80 controlHeight 60 30];
pos3 = [145 controlHeight 150 30];
pos4 = [210 controlHeight 60 30];

myMaxLabel = uilabel('Parent', myfig,'Position', pos3, 'Text', myMaxLabel);
myMaxField = uieditfield('numeric', 'Parent', myfig, 'Editable', 'on', 'Value',...
  maxValue, 'Position', pos4, 'ValueChangedFcn', {@anyValueChange_callback handles myfig}, ...
  'Tag', 'maxValue', 'Limits', maxLimits, 'Tooltip', myMaxTooltip);

myMinLabel = uilabel('Parent', myfig,'Position', pos1, 'Text', myMinLabel);
myMinField = uieditfield('numeric', 'Parent', myfig, 'Editable', isEditable, 'Value',...
  minValue, 'Position', pos2, 'ValueChangedFcn', {@anyValueChange_callback handles myfig}, ...
  'Tag', 'minValue','Limits', minLimits, 'Tooltip', myMinTooltip, 'LowerLimitInclusive', 'off');

myAlphaStepLabel = uilabel('Parent', myfig,'Position', [10 40 160 30], 'Text', 'Number of Points:','Visible', enab);
myAlphaSpinner = uispinner('Parent', myfig,'Position', [120 40 60 30],...
  'tag', 'alphaWin','Step', 2,'value', 11, 'Limits', [3 Inf], ...
  'ValueChangedFcn', {@anyValueChange_callback handles myfig}, 'Editable', 'off', 'Visible', enab, 'Tooltip', 'Alpha values will be log spaced.');

% --- Executes when any alpha setting is changed
function anyValueChange_callback(hObject, eventdata, handles, myfig)
if handles.glswbtn.Value
  alphaMax = getappdata(handles.settingsfigure, 'maxValue');
  alphaMin = getappdata(handles.settingsfigure, 'minValue');
  curValue = findobj(myfig.Children, 'Tag', 'curValue');
  cur_AlphaStr = curValue.Text;
  cur_AlphaVal = str2double(cur_AlphaStr);
  switch hObject.Tag
    case 'minValue'
      newValue = hObject.Value;
      if newValue >= alphaMax || newValue >= cur_AlphaVal
        hObject.Value = eventdata.PreviousValue;
      end
    case 'maxValue'
      newValue = hObject.Value;
      if newValue <= alphaMin || newValue <= cur_AlphaVal
        hObject.Value = eventdata.PreviousValue;
      end
  end
  setappdata(handles.settingsfigure, hObject.Tag, hObject.Value);
  allValues = getRange(handles);
  curValue.Text = num2str(median(allValues));
  minValue = findobj(myfig.Children, 'Tag', 'minValue');
  minValue.Limits = [0 str2num(curValue.Text)];
  maxValue = findobj(myfig.Children, 'Tag', 'maxValue');
  maxValue.Limits = [str2num(curValue.Text) Inf];
else
  %handle epo case
  %should only get here when modifying max value field
  setappdata(handles.settingsfigure, 'maxValue', hObject.Value);
  [cvi, xdata, ~, ~, ~] = getAnalysisInfo(handles);
  allValues = getRange(handles);
  cvmaxPC = getMaxCVallowedPCs(xdata,cvi);
  if max(abs(allValues)) > cvmaxPC
    hObject.Value = cvmaxPC;
    setappdata(handles.settingsfigure, 'maxValue', cvmaxPC);
    evriwarndlg('WARNING: Number of PCs reduced to the rank of the cross-val subset', 'Warning...');
  end
end

% --- Executes when Plot and Choose button is pressed
function myFigPlotAndChoose_callback(hObject, eventdata, handles, myfig)
pfig = getappdata(handles.settingsfigure,'parentfig');
if strcmp(pfig.Tag,'preprocess')
  set(pfig,'visible','off')
end
currentChildrenEnable = get(handles.settingsfigure.Children, 'enable');
set(handles.settingsfigure.Children, 'enable', 'off');
set(handles.settingsfigure,'WindowStyle','normal')
[cvi, xdata, ydata, xpp, ypp] = getAnalysisInfo(handles);
xpp = clean_glsw_clsresiduals_filter(xpp);
myCLS = evrimodel('cls');
myCLS.x = xdata;
myCLS.y = ydata;
newpp = glsw('clsresiduals');

if handles.glswbtn.Value
  allValues = getRange(handles);
  newpp.userdata.a = allValues;
  axisScaleName = 'Alpha Values';
  axisScaleValues = allValues;
  plotName = 'Cross-Val over Alphas';
  viewLog = [1 0];
else
  allValues = getRange(handles);
  newpp.userdata.a = allValues;
  axisScaleValues = abs(allValues);
  axisScaleName  = 'Number of PCs';
  plotName = 'Cross-Val over Number of PCs';
  viewLog = [0 0];
end
xpp = [xpp newpp];
myCLS.options.preprocessing = {xpp ypp};
myCLS = myCLS.calibrate;
myCLS = myCLS.crossvalidate(xdata,cvi);
myInclude = myCLS.include{2,2};
myRMSEC = myCLS.detail.rmsec;
myRMSECV =  myCLS.detail.rmsecv;
myRMSECV_RMSEC = myCLS.detail.rmsecv ./ myCLS.detail.rmsec;
dat = dataset([myRMSEC; myRMSECV; myRMSECV_RMSEC]);
if length(axisScaleValues) ~= size(dat,2)
  evriwarndlg('WARNING: Number of alpha values reduced to the rank of the cross-val subset', 'Warning...');
  axisScaleValues = axisScaleValues(:,1:size(dat,2));
end
dat.axisscale{2,1} = axisScaleValues;
dat.axisscalename{2,1} = axisScaleName;
nr = size(myInclude,2);
lbls = cell(size(dat,1),1);
if isempty(myCLS.detail.label{2,2})
  for i=1:nr
    lbls{i} = sprintf(['RMSEC  Comp. %i'], myInclude(1,i));
    lbls{i+nr} = sprintf(['RMSECV  Comp. %i'], myInclude(1,i));
    lbls{i+2*nr} = sprintf(['RMSECV / RMSEC Ratio  Comp. %i'], myInclude(1,i));
  end
else
  for i=1:nr
    thisLabel = strtrim(myCLS.detail.label{2,2}(myInclude(1,i),:));
    if isempty(thisLabel)
      thisLabel = sprintf(['Comp. %i'], myInclude(1,i));
    else
      thisLabel = myCLS.detail.label{2,2}(myInclude(1,i),:);
    end
    lbls{i} = ['RMSEC ' thisLabel];
    lbls{i+nr} = ['RMSECV ' thisLabel];
    lbls{i+2*nr} = ['RMSECV / RMSEC Ratio ' thisLabel];
  end
end
dat.label{1,1} = lbls;
btnlist = {
  'selectx'      'selectonly' 'plotgui(''makeselection'',gcbf);plotgui(''menuselection'',''EditExcludeUnselected'')'  'enable' 'Choose SINGLE Value to Keep'    'off'   'push'
  'ok'           'accept'     'close(gcbf)'                                                                            'enable' 'Accept and close'         'on'    'push'
  };

%clean crossval info for plot title
if isnumeric(cvi{1})
  plotTitle = 'CV Method: Custom';
else
  switch cvi{1}
    case 'none'
      plotTitle = 'CV Method: None';
    case 'loo'
      plotTitle = 'CV Method: Leave One Out';
    case 'con'
      plotTitle = ['CV Method: Contiguous Blocks, Splits: ' num2str(cvi{2})];
    case 'vet'
      plotTitle = ['CV Method: Venetian Blinds, Splits: ' num2str(cvi{2})];
    case 'rnd'
      plotTitle = ['CV Method: Random, Splits: ' num2str(cvi{2}) ', Iterations: ' num2str(cvi{3})];
  end
end

set(myfig,'visible','off');

%share data and get plotgui to modify include field
myid = setshareddata(handles.settingsfigure,dat);
fig = plotgui('new',myid, 'name', [plotName ' ' plotTitle],...
  'plotby',1,...
  'viewclasses',1,...
  'selectionmode','x',...
  'pgtoolbar',0,'PlotType', 'line+points', 'viewlog', viewLog, 'ViewExcludedData', 1);
toolbar(fig,'',btnlist,'selectiontoolbar');
title(plotTitle);
evritip('Gray CLS', ['Use Choose SINGLE Value to Keep button to select '...
  'value to use in final model building. Use the Green check button to accept ' ...
  'the selection and close the figure.'],0);
while ishandle(fig)
  uiwait(fig);
end

for i = 1:length(currentChildrenEnable)
  set(handles.settingsfigure.Children(i),'Enable',currentChildrenEnable{i});
end
if strcmp(pfig.Tag,'preprocess')
  set(pfig,'visible','on')
end
set(handles.settingsfigure,'WindowStyle','modal')

%get include field after figure is closed
dat = myid.object;
selValue = allValues(dat.include{2});
if isempty(selValue) | length(selValue) >1
  evriwarndlg('WARNING: No value selected. Setting to last good value.', 'No Value Selected');
  close(myfig);
  return
end
removeshareddata(myid);
if handles.glswbtn.Value
  alphatxt_Callback([], [], handles, num2str(selValue));
else
  numpctxt_Callback([],[], handles, num2str(abs(selValue)));
end
set(handles.cvcheckbox, 'value', 0);
set(handles.cvbutton, 'enable', 'off');
close(myfig);

%--------------------------------------------------------------------------
function xpp_cleaned = clean_glsw_clsresiduals_filter(xpp)
% Check preprocessing and remove any using GLSW with cls residuals

xpp_cleaned = xpp;
for i=1:length(xpp)
  t1 = strcmpi(xpp(i).keyword, 'declutter GLS Weighting');
  if t1
      t2 = strcmp(xpp(i).userdata.source, 'cls_residuals');
  end
  if t1 & t2
    xpp_cleaned(i) = [];
  end
end

%--------------------------------------------------------------------------
function [cvi, xdata, ydata, xpp, ypp]  = getAnalysisInfo(handles)
pfig = getappdata(handles.settingsfigure,'parentfig');
if strcmpi(get(pfig,'tag'),'analysis')
  curAnalysis = evrigui(pfig);
else
  curAnalysis = evrigui(findobj(pfig.Parent.Children, 'Tag', 'analysis'));
end
cvi = curAnalysis.getCrossvalidation;
xdata = curAnalysis.getXblock;
ydata = curAnalysis.getYblock;
xpp = curAnalysis.getXPreprocessing;
ypp = curAnalysis.getYPreprocessing;

%--------------------------------------------------------------------------
function allValues = getRange(handles)
if handles.glswbtn.Value
  minAlpha = getappdata(handles.settingsfigure, 'minValue');
  maxAlpha = getappdata(handles.settingsfigure, 'maxValue');
  winAlpha = getappdata(handles.settingsfigure, 'alphaWin');
  minLog = log10(minAlpha);
  maxLog = log10(maxAlpha);
  allValues = flip(logspace(minLog, maxLog, winAlpha));
else
  minNumPC = getappdata(handles.settingsfigure, 'minValue');
  maxNumPC = getappdata(handles.settingsfigure, 'maxValue');
  allValues = -(minNumPC:maxNumPC);
end
