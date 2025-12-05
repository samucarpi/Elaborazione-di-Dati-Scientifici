function varargout = specalignset(varargin)
%SPECALIGNSET Settings used to modfiy variable alignment.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided.
% if p is 'default', default structure is returned without GUI.
%
% Default algorithm is Peak Alignment (registerspec). 
%
%I/O:   p = specalignset(p,data)
%I/O:   p = specalignset(data)
%
%See also: COW, PREPROCESS, REGISTERSPEC

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0  | ~ischar(varargin{1})% LAUNCH GUI
  
  fig = openfig(mfilename,'reuse');
  %%set(fig,'WindowStyle','modal');
  centerfigure(fig,gcbf);
  set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
  setappdata(fig,'parentfig',gcbf);
  
  % Generate a structure of handles to pass to callbacks, and store it.
  handles = guihandles(fig);
  if ismac
    %Temp solution for guide differences in Mac.
    set(handles.lbl_slack,'backgroundcolor',get(0,'defaultUicontrolBackgroundColor'));
  end
  
  guidata(fig, handles);
  if nargin > 0 & isstruct(varargin{1})
    %Save pp to appdata.
    setappdata(fig,'settings',varargin{1});
  end
  
  setup(handles)
  
  % Wait for callbacks to run and window to be dismissed:
  uiwait(fig);
  if ~ishandle(handles.btn_cancel)  %Check if user clicked cancel 
    varargout{1} = [];
    return
  end
  if nargout > 0
    if ishandle(fig);  %still exists?
      varargout{1} = encode(handles);
      close(fig);
    elseif ~isempty(varargin)
      varargout{1} = varargin{1};%return
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

%-------------------------------------------------------------
function setup(handles)
%Set default values.

p = getappdata(handles.specalignset,'settings');
p = default(p,handles);%get default settings (but maintain userdata if any)
pdata = preprocess('getdataset',getappdata(handles.specalignset,'parentfig'));%Data to preprocess.
set(handles.specalignset,'visible','on');

%Set BG callback.
set(handles.bg_specalign,'SelectionChangeFcn','specalignset(''bg_specalign_Callback'',gcbo,[],guidata(gcbo))')
setappdata(handles.specalignset,'settings',p)

%Set gui to incoming prepro structure.
mybtn = [];%Button not
switch p.userdata.function
  case 'cow'
    mybtn = handles.rb_cow;
    set(handles.txt_seglen,'string',num2str(p.userdata.window));
    maxshift = p.userdata.maxshift;
  case 'registerspec'
    mybtn = handles.rb_peak_alignment;
    set(handles.txt_seglen,'string','');%Not used, will be disabled.
    %Need to convert maxshift from axis units to index units. If the value
    %is 5 then we assume it's the default.
    maxshift = p.userdata.maxshift;
    if maxshift~=5 & ~isempty(pdata) & ~isempty(pdata.axisscale{2})
      maxshift = round(maxshift/abs(mean(diff(pdata.axisscale{2}))));
    end
end

set(handles.bg_specalign,'SelectedObject',mybtn);

%Set slack and segment.
set(handles.txt_slack,'string',num2str(maxshift));

%Set alignment function and iterative checkbox.
if ismember(p.userdata.algorithm,{'poly' 'iterativepoly'})
  set(handles.pop_alignfcn,'value',p.userdata.order+1);
  if strcmp(p.userdata.algorithm,'iterativepoly')
    set(handles.chk_poly,'value',1);
  end
elseif strcmp(p.userdata.algorithm,'pchip')
  set(handles.pop_alignfcn,'value',7);
end

%Set target dropdown.
target_list = {'Auto'};
if ~isempty(pdata)
  maxsz = min(size(pdata,1),500);
  if isempty(pdata.label{1})
    mylbl = sprintf('Sample %d\n',[1:maxsz]);
  else
    mylbl = pdata.label{1};
  end
  mylbl = str2cell(mylbl);
  target_list = [target_list; mylbl];
end
set(handles.pop_targetsample,'String',target_list);

if ~isempty(p.userdata.target)
  %First value is "auto"
  set(handles.pop_targetsample,'Value',p.userdata.target+1)
else
  set(handles.pop_targetsample,'Value',1);
end
bg_specalign_Callback(mybtn, [], handles)

%-------------------------------------------------------------
function bg_specalign_Callback(hObject, eventdata, handles)
%Change align function.

handles = guidata(handles.specalignset);
allctrls = allchild(handles.pnl_settings);
pdata = preprocess('getdataset',getappdata(handles.specalignset,'parentfig'));
set(allctrls,'enable','on');
if isa(hObject,'matlab.ui.container.ButtonGroup')
  hObject = get(hObject,'SelectedObject');
end

switch get(hObject,'tag')
  case 'rb_cow'
    %Turn align fcn and iterative off.
    set([handles.lbl_alignfcn handles.pop_alignfcn handles.lbl_poly handles.chk_poly],'enable','off');
    set([handles.lbl_maxseglen handles.txt_maxseglen],'enable','off');
    set([handles.lbl_minslack handles.txt_minslack],'enable','off');
    %Add default value of seg len if empty.
    if isempty(get(handles.txt_seglen,'String'))
      set(handles.txt_seglen,'String','50')
    end
    set(handles.lbl_seglen,'String','Segment Length (Window):');
    set(handles.lbl_slack,'String','Slack (Shift):');

  case 'rb_peak_alignment'
    %Disable Window, will be too time consuming.
    set([handles.lbl_seglen handles.txt_seglen],'enable','off');
    set([handles.lbl_maxseglen handles.txt_maxseglen],'enable','off');
    set([handles.lbl_minslack handles.txt_minslack],'enable','off');
    set(handles.lbl_slack,'String','Slack (Shift):');
    
  case 'rb_optimized_cow'
    %Turn align fcn and iterative off.
    set([handles.lbl_alignfcn handles.pop_alignfcn handles.lbl_poly handles.chk_poly],'enable','off');
    %Add default value of seg len if empty.
    if isempty(get(handles.txt_seglen,'String'))
      set(handles.txt_seglen,'String','50')
    end
    if isempty(get(handles.txt_maxseglen,'String'))
      set(handles.txt_maxseglen,'String',num2str(min(200,size(pdata,2))))
    end
    if isempty(get(handles.txt_minslack,'String'))
      set(handles.txt_minslack,'String','2')
    end
    set(handles.lbl_seglen,'String','Segment Length (Min Window):');
    set(handles.lbl_slack,'String','Slack (Max Shift):');
    
end
%-------------------------------------------------------------
function txt_slack_Callback(hObject, eventdata, handles)
%Edit slack text field. Slack must be >=1 and <(Segment Length-4).
slackval = str2num(get(hObject,'String'));
segval = str2num(get(handles.txt_seglen,'String'));

if slackval<1
  evriwarndlg('Slack must be >= 1','Slack Value Warning');
  set(hObject,'String','1');
elseif slackval>segval-4
  evriwarndlg('Slack must be < (Segment Length-4)','Slack Value Warning');
  set(hObject,'String',num2str(segval-4));
end

%-------------------------------------------------------------
function txt_seglen_Callback(hObject, eventdata, handles)
%Edit segment length. Segment Length must be >=5 and < 0.5*size(x,2)
%(if x is not available, then no maximum).
pdata = preprocess('getdataset',getappdata(handles.specalignset,'parentfig'));
segval = str2num(get(hObject,'String'));

if segval<5
  evriwarndlg('Segment length must be >= 5','Segment Length Warning');
  set(hObject,'String','5');
  segval = 5;
elseif ~isempty(pdata) & segval>0.5*size(pdata,2)
  evriwarndlg('Segment length must be < 1/2 the number of variables.','Segment Length Warning');
  segval = floor(size(pdata,2)/2-1);
  set(hObject,'String',num2str(segval));
end

%Check slack.
txt_slack_Callback(handles.txt_slack, eventdata, handles);

%-------------------------------------------------------------
function txt_maxseglen_Callback(hObject, eventdata, handles)
%Edit segment length. Segment Length must be >=5 and < 0.5*size(x,2)
%(if x is not available, then no maximum).
pdata = preprocess('getdataset',getappdata(handles.specalignset,'parentfig'));
segval = str2num(get(hObject,'String'));

if segval<5
  evriwarndlg('Segment length must be >= 5','Segment Length Warning');
  set(hObject,'String','5');
  segval = 5;
elseif ~isempty(pdata) & segval>0.5*size(pdata,2)
  evriwarndlg('Segment length must be < 1/2 the number of variables.','Segment Length Warning');
  segval = floor(size(pdata,2)/2-1);
  set(hObject,'String',num2str(segval));
end

%Check slack.
txt_minslack_Callback(handles.txt_minslack, eventdata, handles);

%-------------------------------------------------------------
function pop_alignfcn_Callback(hObject, eventdata, handles)
%Change alignment function, iterative Polynomial is ONLY enabled with Alignment 
% Function is one of the polynomial settings.

algval = get(handles.pop_alignfcn,'value');
if algval>5
  %Disable iterative.
  set(handles.chk_poly,'value',0);
  set(handles.chk_poly,'enable','off')
else
  set(handles.chk_poly,'enable','on')
end

%-------------------------------------------------------------
function chk_poly_Callback(hObject, eventdata, handles)
%Check iterative polynomial checkbox.


%-------------------------------------------------------------
function btn_ok_Callback(hObject, eventdata, handles)
%Ok button callback.
uiresume(gcbf);

%-------------------------------------------------------------
function btn_help_Callback(hObject, eventdata, handles)
%Show help.

evrihelp('Variable_Alignment_Settings');

%-------------------------------------------------------------
function btn_cancel_Callback(hObject, eventdata, handles)
%Cancel.
close(gcbf)

%--------------------------------------------------------------------
function p = encode(handles)
% encode the GUI's settings into the Preprocessing structure
% This routine must take the current GUI object settings and "encode" them
%  into the userdata property (as well as any other structure changes)

p  = getappdata(handles.specalignset,'settings');
pdata = preprocess('getdataset',getappdata(handles.specalignset,'parentfig'));

%Get alignment algorithm (COW or peak align).
myalg = get(handles.bg_specalign,'SelectedObject');

%Get target index.
tval = get(handles.pop_targetsample,'value');
if tval == 1
  p.userdata.target = [];
else
  p.userdata.target = tval-1;
end

p.userdata.maxshift = str2num(get(handles.txt_slack,'string'));
p.userdata.window   = str2num(get(handles.txt_seglen,'string'));
p.calibrate     = regspec_calibrate;
p.apply         = regspec_apply;
switch get(myalg,'tag')
  case 'rb_cow'
    %Get slack and segment.
    p.description   = sprintf('Variable Alignment (COW, slack = %i, segmentlength = %i)',p.userdata.maxshift,p.userdata.window);
    p.userdata.function = 'cow';
    p.usesdataset   = 0;
  case 'rb_peak_alignment'
    p.description   = sprintf('Variable Alignment (Peaks, slack = %i)',p.userdata.maxshift);
    p.userdata.function = 'registerspec';
    p.usesdataset   = 1;
    %Adjust units to those of axisscale for registerspec only.
    if ~isempty(pdata)&~isempty(pdata.axisscale{2})
      d = abs(mean(diff(pdata.axisscale{2})));
      p.userdata.maxshift = p.userdata.maxshift*d;
    end
    
  case 'rb_optimized_cow'
    if isempty(pdata)
      error('Data is required for optimization. Aborting.')
    end
    % get parameters for optimization
    minslack = str2num(get(handles.txt_minslack,'String'));
    maxwindow = str2num(get(handles.txt_maxseglen,'String'));
    space = [p.userdata.window maxwindow minslack p.userdata.maxshift];
    options = [0 3 50 0.15];
    %results = [];
    [f,h] = disp_progress;
    %{
    timerhandle = timer('TimerFcn', {@checkoptimprocess, 'check'}, ...
                            'StopFcn',  {@checkoptimprocess, 'stop'}, ...
                            'StartFcn',{@optimize pdata space options}, ...
                            'BusyMode', 'drop', ...
                            'ExecutionMode', 'fixedSpacing', ...
                            'Period', 10,...
                            'TasksToExecute',1,...
                            'UserData',{results f h});
    start(timerhandle);
    wait(timerhandle);
    %}
    optimalargs = optim_cow(pdata.data, space, options, pdata.data(tval,:));
    if ishandle(f)
      close(f);
    end
    if ishandle(h)
      close(h);
    end
    p.userdata.window  = optimalargs(1);
    p.userdata.maxshift = optimalargs(2);
    p.description   = sprintf('Variable Alignment (COW, slack = %i, segmentlength = %i)',p.userdata.maxshift,p.userdata.window);
    p.userdata.function = 'cow';
    p.usesdataset   = 0;
end

algval = get(handles.pop_alignfcn,'value');
itrval = get(handles.chk_poly,'value');
if itrval
  p.userdata.algorithm = 'iterativepoly';
elseif algval==7
  p.userdata.algorithm = 'pchip';
else
  p.userdata.algorithm = 'poly';
  p.userdata.order     = algval-1;
end

%--------------------------------------------------------------------
function p = default(p,handles)
%Create default structure for this preprocessing method if "p" is passed
%in, only the userdata from that structure is kept.
% .maxshift and .window must be in axis units.

pdata = [];
if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
else
  pdata = preprocess('getdataset',getappdata(handles.specalignset,'parentfig'));
end

p = preprocess('validate',p);  %validate what was passed in

p.description   = 'Variable Alignment';
p.calibrate     = regspec_calibrate;
p.apply         = regspec_apply;
p.undo          = {};   %cannot undo
p.out           = {};
p.settingsgui   = 'specalignset';
p.settingsonadd = 1;
p.usesdataset   = 1;
p.caloutputs    = 0;
p.keyword       = 'specalign';
p.category      = 'Filtering';
p.tooltip       = 'Variable alignment using COW or Peak Alignment.';

%Get default value for maxshift, if no axisscale then assume step size is one. 
if ~isempty(pdata)&~isempty(pdata.axisscale{2})
  maxshift = 5*abs(mean(diff(pdata.axisscale{2})));
else
  maxshift = 5;
end

%Window is not used for registerspec but need default (in variable index
%units) for COW, 1/2 of x or (if no x) 50.
mywindow = 50;
if ~isempty(pdata)
  mywindow = .5*size(pdata,2);
end

%Default user data.
if isempty(p.userdata);
  p.userdata = struct('function','registerspec','peaks',[],'order',0,'algorithm','poly','maxshift',maxshift,'window',mywindow,'target',[]);   %defaults for NEW instances
end

%----------------------------
function pop_targetsample_Callback(hObject, eventdata, handles)
%Change target sample.

%----------------------------
function out = get_unit_value(handles,field,type)
%Get unit value of max shift. If current value is not integer, assume
%switch back to int and if int, switch to ax units. Type indicates what 

%------------------------------
function out = regspec_calibrate


out = {[
  'if strcmpi(userdata.function,''cow'');'...
  '  if isempty(userdata.target); targdata = data(1,:); else; targdata = data(userdata.target,:); end; '...
  '  out{2} = targdata; [out{1},data] = cow(targdata,data,userdata.window,userdata.maxshift);' ...
  'else; '...
  '  if isempty(userdata.peaks); '...
  '    if isempty(userdata.target);'... 
  '      targdata = data(1,:);'... 
  '      else;'...
  '        targdata = data(userdata.target,:);'...
  '    end; '...
  '    out{1} = registerspec(targdata,struct(''display'',''off'',''order'',userdata.order,''algorithm'',userdata.algorithm,''maxshift'',userdata.maxshift));'...
  '  else; '...
  '    out{1} = userdata.peaks; '...
  '  end;' ...
  '  data = registerspec(data,out{1},struct(''display'',''off'',''order'',userdata.order,''algorithm'',userdata.algorithm,''maxshift'',userdata.maxshift));'...
  'end'...
  ]};


%------------------------------
function out = regspec_apply


out = {[
  'try;'...
  '  if strcmpi(userdata.function,''cow'');'...
  '    [junk,data] = cow(out{2},data,userdata.window,userdata.maxshift);'...
  '  else;'  ...
  '    data = registerspec(data,out{1},struct(''display'',''off'',''order'',userdata.order,''algorithm'',userdata.algorithm,''maxshift'',userdata.maxshift));'...
  '  end;  '...
  'catch;'...
  '  error(''Preprocessing must be calibrated before applying or undoing'');  '...
  'end'...
  ]};



function txt_minslack_Callback(hObject, eventdata, handles)
% hObject    handle to txt_minslack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_minslack as text
%        str2double(get(hObject,'String')) returns contents of txt_minslack as a double


% --- Executes during object creation, after setting all properties.
function txt_minslack_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_minslack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function txt_maxseglen_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_maxseglen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function [f,h] = disp_progress

pos = get(groot,'DefaultFigurePosition');
f = uifigure('Position',[pos(1) pos(2) 398 139]);
h = uiprogressdlg(f,...
                  'Message','Optimizing COW parameters, please wait...',...
                  'Title','COW Optimization',...
                  'Cancelable',0,...
                  'Indeterminate',1);



function timerhandle = optimize(varargin)

[timerhandle,junk, pdata,space,options] = deal(varargin{:});
optimal_args = optim_cow(pdata.data,space,options,pdata.data(1,:));
timerhandle.results = optimal_args;


function checkoptimprocess(timerhandle, EventData, Cmd)
results = timerhandle.UserData{1};
progfighandle = timerhandle.UserData{2};
proghandle = timerhandle.UserData{3};

switch Cmd
  case 'check'
    % did user cancel?
    if proghandle.CancelRequested || ~isempty(results)
      close(progfighandle);
      stop(timerhandle);
    end
    % did run complete?
    
  case 'stop'
    % stop timer
    error('stop')
end


%-------------------------------------------------------------------------%

