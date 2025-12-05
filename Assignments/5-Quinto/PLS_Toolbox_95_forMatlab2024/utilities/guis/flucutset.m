function varargout = flucutset(varargin)
%FLUCUTSET GUI used to modfiy settings of FLUCUT.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI
%
%I/O:   p = flucutset(p)
% (or)  p = flucutset('default')
%
%See also: AUTO, PREPROCESS

%Copyright Eigenvector Research 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 8/3/2001
% 8/15/01 JMS fixed intro code to remove R10 warnings, corrected help
% 9/18/01 JMS rewrote from normset for detrend
% 9/18/01 JMS rewrote from detrendset for auto

if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))% LAUNCH GUI

	fig = openfig(mfilename,'reuse');
  set(fig,'WindowStyle','modal');
  centerfigure(fig,gcbf);

	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
	guidata(fig, handles);
  if nargin > 0;
    setup(handles, varargin{1})
  else
    setup(handles, []);
  end

	% Wait for callbacks to run and window to be dismissed:
	uiwait(fig);

	if nargout > 0
    if ishandle(fig);  %still exists?
      varargout{1} = encode(handles);
      close(fig);
    else
      varargout{1} = [];
    end
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


%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and 
%| sets objects' callback properties to call them through the FEVAL 
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the 
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.

% --------------------------------------------------------------------
function okbtn_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.okbtn.
uiresume(gcbf)

% --------------------------------------------------------------------
function cancelbtn_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.cancelbtn.
close(gcbf)


% --------------------------------------------------------------------
function update(handles)
%udpates all the enabling/disabling of various controls

if get(handles.r1filter,'value')
  en = 'on';
else
  en = 'off';
end
%set([handles.r1width handles.lowzero handles.r2filter],'enable',en)
set(handles.r1width,'enable',en);

if strcmp(get(handles.r1width,'string'),'')
  set(handles.r1width,'string','20');
end

%if strcmp(en,'on') & get(handles.r2filter,'value')
if get(handles.r2filter,'value')
  en = 'on';
else
  en = 'off';
end
set(handles.r2width,'enable',en)
if strcmp(get(handles.r2width,'string'),'')
  set(handles.r2width,'string','20');
end

if get(handles.ramanfilter,'value');
  en = 'on';
else
  en = 'off';
end
set([handles.ramanwidth handles.ramanshift],'enable',en)

updateplot(handles)

% --------------------------------------------------------------------
function setup(handles, p)
% p is preprocessing structure (if any)
% This routine must take the current userdata (defined in the default routine)
%  and appropriately update the GUI objects based on values therein

if nargin<2; p = []; end
p = default(p);           %get default settings (but maintain userdata if any)

%set up GUI based on decoded structure
set(handles.r1filter   ,'value',~isempty(p.userdata.lowmiss)&all(isfinite(p.userdata.lowmiss)));
set(handles.r1width    ,'string',num2str(p.userdata.lowmiss));
set(handles.r2filter   ,'value',~isempty(p.userdata.topmiss)&all(isfinite(p.userdata.topmiss)));
set(handles.r2width    ,'string',num2str(p.userdata.topmiss));
set(handles.ramanfilter,'value',strcmp(p.userdata.RamanCorrect,'on'));
set(handles.ramanwidth ,'string',num2str(p.userdata.RamanWidth));
set(handles.ramanshift ,'string',num2str(p.userdata.RamanShift));
set(handles.lowzero    ,'value',strcmp(p.userdata.LowZero,'on'));
set(handles.topzero    ,'value',strcmp(p.userdata.TopZero,'on'));
set(handles.replacemethod,'value',strcmpi(p.userdata.Interpolate,'on')+1);
enforce(handles.r1width,20,handles.r1filter);
enforce(handles.r2width,20,handles.r2filter);
enforce(handles.ramanwidth,20,handles.ramanfilter);

%store p for modification when done
setappdata(handles.settingsfigure,'settings',p)

%check for data
mydata = [];
%alldata = [];
if ~isempty(gcbf)  %(can ONLY be called from preprocess)
  try
    %get data from preprocess
    mydata = preprocess('getdataset');
    %alldata = mydata;
    %mydata = copydsfields(mydata,dataset(mean(mydata.data,1)),[2 3]);  %reduce to a single slab
    %setappdata(handles.settingsfigure,'mydata',mydata);
    setappdata(handles.settingsfigure,'mydata',mydata);
  catch
    mydata = [];
    %alldata = [];
  end
end

if isempty(mydata)
  en = 'off';
  str = {''};
  value = 1;
else
  en = 'on';
  lbl = mydata.label{1};
  if isempty(lbl)
    lbl = str2cell(sprintf('Sample %i\n',1:size(mydata,1)));
  else
    lbl = str2cell(lbl);
  end
  str = ['(none)'; lbl];
  val = p.userdata.Blank;
  if isempty(val) | isnan(val) | val<1 | val>length(str)
    value = 1;
  else
    value = val+1;
  end
end
set(handles.blanksubtract,'enable',en,'string',str,'value',value)

set(handles.settingsfigure,'resize','on','resizefcn',@resize);

update(handles)
% -------------------------------------------------------------------
function resize(varargin)
%adjust axes size if figure is resized

h = varargin{1};
handles = guidata(h);

if strcmp(get(handles.settingsfigure,'resize'),'off')
  return;
end
set([handles.axes1 handles.settingsfigure],'units','pixels');
fpos = get(handles.settingsfigure,'position');

apos = get(handles.axes1,'position');
apos(3) = max(10,fpos(3)-apos(1)-5);
apos(4) = max(10,fpos(4)-apos(2)-5);

set(handles.axes1,'position',apos);

% --------------------------------------------------------------------
function p = encode(handles)
% encode the GUI's settings into the Preprocessing structure
% This routine must take the current GUI object settings and "encode" them
%  into the userdata property (as well as any other structure changes)

onoff = {'off' 'on'};
p          = getappdata(handles.settingsfigure,'settings');
blank = get(handles.blanksubtract,'value');
if blank==1
  blank = nan;
else
  blank = blank -1;
end
p.userdata = struct(...
  'lowmiss'      ,str2num(get(handles.r1width,'string')),...
  'topmiss'      ,str2num(get(handles.r2width,'string')),...
  'RamanCorrect' ,onoff{get(handles.ramanfilter,'value')+1},...
  'RamanWidth'   ,str2num(get(handles.ramanwidth,'string')),...
  'RamanShift'   ,str2num(get(handles.ramanshift,'string')),...
  'LowZero'      ,onoff{get(handles.lowzero,'value')+1},...
  'TopZero'      ,onoff{get(handles.topzero, 'value')+1},...
  'Interpolate'  ,onoff{get(handles.replacemethod,'value')},...
  'Blank'        ,blank ...
  );
p.userdata.plots = 'none';

if ~get(handles.r1filter,'value')
  p.userdata.lowmiss = nan;
end
if ~get(handles.r2filter,'value')
  p.userdata.topmiss = nan;
end

str = p.description;
addstr = '';
if all(isfinite(p.userdata.lowmiss))
  val = p.userdata.lowmiss;
  addstr = [addstr sprintf('R1 +/-%i nm, ',val)];
  if strcmp(p.userdata.LowZero,'on')
    addstr = [addstr ' low zero, '];
  end
  if strcmp(p.userdata.TopZero, 'on')
    addstr = [addstr ' top zero, '];
  end
end
if all(isfinite(p.userdata.topmiss))
  val = p.userdata.topmiss;
  addstr = [addstr sprintf('R2 +/-%i nm, ',val)];
end
if strcmp(p.userdata.RamanCorrect,'on')
  addstr = [addstr sprintf('Raman %4g 1/cm +/-%i nm, ',p.userdata.RamanShift,p.userdata.RamanWidth)];
end
if isfinite(p.userdata.Blank)
  % only do if blank was specified
  addstr = [addstr sprintf('Blank: sample %d, ', blank)];
end
if ~isempty(addstr); 
  str = [str ' (' addstr(1:end-2) ')'];
else
  str = [str ' (DISABLED)'];
end
p.description = str;


% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end
         
p = preprocess('validate',p);  %validate what was passed in
  
p.description   = 'EEM Filtering';
p.calibrate     = {'data = flucut(data,userdata.lowmiss,userdata.topmiss,userdata);'};
p.apply         = {'data = flucut(data,userdata.lowmiss,userdata.topmiss,userdata);'};
p.undo          = {};
p.out           = {};
p.settingsgui   = 'flucutset';
p.settingsonadd = 1;
p.usesdataset   = 1;
p.caloutputs    = 0;
p.keyword       = 'eemfilter';
p.tooltip       = 'Remove scatter from fluorescence EEM data';
p.category      = 'Filtering';

defaults = [];
temp = flucut('options');          %get defaults
defaults.lowmiss = 20;
defaults.topmiss = nan;
defaults.LowZero = temp.LowZero;
defaults.TopZero = temp.TopZero;
defaults.RamanCorrect = temp.RamanCorrect;
defaults.RamanWidth = temp.RamanWidth;
defaults.RamanShift = temp.RamanShift;
defaults.Interpolate = temp.Interpolate;
defaults.Blank       = temp.Blank;
defaults.plots = 'none';

if isempty(p.userdata);
  %no userdata yet
  p.userdata = defaults;
else
  p.userdata = reconopts(p.userdata,defaults);
end

%---------------------------------------------
function enforce(h,default,checkbox)
val = str2num(get(h,'string'));
if isempty(val) | ~isfinite(val) | val<0; val = default; end
if val==0
  set(checkbox,'value',0);
  val = default;
end
set(h,'string',num2str(val));

% --------------------------------------------------------------------
function r1width_Callback(h, eventdata, handles, varargin)

enforce(handles.r1width,20,handles.r1filter);
update(handles)


% --- Executes on button press in help.
function help_Callback(hObject, eventdata, handles)
% hObject    handle to help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp('flucut')


% --- Executes on button press in r1filter.
function r1filter_Callback(hObject, eventdata, handles)
% hObject    handle to r1filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of r1filter
update(handles)


function r2width_Callback(hObject, eventdata, handles)
% hObject    handle to r2width (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of r2width as text
%        str2double(get(hObject,'String')) returns contents of r2width as a double
enforce(handles.r2width,20,handles.r2filter);
update(handles)

% --- Executes during object creation, after setting all properties.
function r2width_CreateFcn(hObject, eventdata, handles)
% hObject    handle to r2width (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in r2filter.
function r2filter_Callback(hObject, eventdata, handles)
% hObject    handle to r2filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of r2filter
update(handles)


function ramanwidth_Callback(hObject, eventdata, handles)
% hObject    handle to ramanwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ramanwidth as text
%        str2double(get(hObject,'String')) returns contents of ramanwidth as a double
enforce(handles.ramanwidth,20,handles.ramanfilter);
update(handles)

% --- Executes during object creation, after setting all properties.
function ramanwidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ramanwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ramanfilter.
function ramanfilter_Callback(hObject, eventdata, handles)
% hObject    handle to ramanfilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ramanfilter
update(handles)


function ramanshift_Callback(hObject, eventdata, handles)
% hObject    handle to ramanshift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ramanshift as text
%        str2double(get(hObject,'String')) returns contents of ramanshift as a double
enforce(handles.ramanshift,3600,handles.ramanfilter);
update(handles)

% --- Executes during object creation, after setting all properties.
function ramanshift_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ramanshift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in lowzero.
function lowzero_Callback(hObject, eventdata, handles)
% hObject    handle to lowzero (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of lowzero
update(handles)

%----------------------------------------------------
function updateplot(handles)

p = encode(handles);
opt = p.userdata;
opt.plots = 'none';
% opt.Blank = nan;
data = getappdata(handles.settingsfigure,'mydata');
if ~isempty(data)
  le = lasterror;
  try
    znew = flucut(data,opt.lowmiss,opt.topmiss,opt);
    dataToPlot = mean(znew.data,1);  %reduce to a single slab
    ax2 = data.axisscale{2};
    if isempty(ax2); ax2 = 1:size(data,2); end
    ax3 = data.axisscale{3};
    if isempty(ax3); ax3 = 1:size(data,3); end
    
    ndata = squeeze(dataToPlot);
    switch 2
      case 1
        ih = imagesc(ax3,ax2,ndata,'Parent',handles.axes1);
        set(handles.settingsfigure,'currentaxes',handles.axes1)
        axis(handles.axes1,'image','xy','tight')
    
        cover = ~isfinite(ndata);
        zeros = ndata==0;
        if any(cover(:)) | any(zeros(:));
          set(ih,'alphadata',((~zeros)*.5+.5).*(~cover))
        end
        
      case 2
        [az,el] = view(handles.axes1);
        surf(ax3,ax2,ndata,'Parent',handles.axes1);
        shading(handles.axes1,'flat')
        set(handles.settingsfigure,'currentaxes',handles.axes1)
        axis(handles.axes1,'xy','tight')
        
        rotate3d(handles.axes1,'on');
        if (az==0 & el==90); 
          az = 52;
          el = 64;
        end
        view(handles.axes1,[az el]);
        
    end
    
  catch
    %error during calculation? turn plotting OFF
    data = [];
    setappdata(handles.settingsfigure,'mydata',[]);
    lasterror(le)  %restore previous error state
  end
end

if isempty(data)  %note: done outside of previous "if" so failures can turn off plotting immediately
  %no data? hide axes (if not hidden) and reduce size of dialog
  if strcmp(get(handles.axes1,'visible'),'on')
    set(handles.axes1,'visible','off','units','pixels');
    set(handles.settingsfigure,'units','pixels')
    pos = get(handles.settingsfigure,'position');
    axpos = get(handles.axes1,'position');
    pos(3) = axpos(1)- 35;
    set(handles.settingsfigure,'position',pos);
  end
  %no data? do NOT allow resize of figure!
  set(handles.settingsfigure,'resize','off')
end


% --- Executes on selection change in replacemethod.
function replacemethod_Callback(hObject, eventdata, handles)
% hObject    handle to replacemethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns replacemethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from replacemethod
update(handles)


% --- Executes during object creation, after setting all properties.
function replacemethod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to replacemethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in blanksubtract.
function blanksubtract_Callback(hObject, eventdata, handles)
% hObject    handle to blanksubtract (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns blanksubtract contents as cell array
%        contents{get(hObject,'Value')} returns selected item from blanksubtract
update(handles)


% --- Executes during object creation, after setting all properties.
function blanksubtract_CreateFcn(hObject, eventdata, handles)
% hObject    handle to blanksubtract (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in topzero.
function topzero_Callback(hObject, eventdata, handles)
% hObject    handle to topzero (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of topzero
update(handles)
