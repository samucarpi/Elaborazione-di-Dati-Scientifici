function varargout = lwrgui(varargin)
% LWRGUI M-file for lwrgui.fig
%      LWRGUI, by itself, creates a new LWRGUI or raises the existing
%      singleton*.
%
%      H = LWRGUI returns the handle to a new LWRGUI or the handle to
%      the existing singleton*.
%
%      LWRGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LWRGUI.M with the given input arguments.
%
%      LWRGUI('Property','Value',...) creates a new LWRGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lwrgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lwrgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2010
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

% --- Executes just before lwrgui is made visible.
function lwrgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lwrgui (see VARARGIN)

% Choose default command line output for lwrgui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes lwrgui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = lwrgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%--------------------------------------------------------------------
function lwr_npts_Callback(hObject, eventdata, handles)
%Change number of points.

nlvs = getappdata(handles.pcsedit,'default');
npts = str2num(get(handles.lwr_npts,'String'));
old_npts = getappdata(handles.analysis,'lwr_npts');

val = get(handles.lwr_algorithm,'value');
str = get(handles.lwr_algorithm,'string');
reglvs = str2num(get(handles.lwr_lvs,'string'));

if strcmpi(str{val},'globalpcr')
  if nlvs>npts 
    evrierrordlg('Number of LVs must be less than number of points.','Check Number of Local Points');
    analysis('panelviewselect_Callback',handles.analysis, eventdata, handles, 2);
    return
  end
else   
  if reglvs>npts 
    evrierrordlg('Number of regression model LVs must be less than number of local points.','Check Number of Local Points');
    analysis('panelviewselect_Callback',handles.analysis, [], handles, 2);
    return
  end
end

setappdata(handles.analysis,'lwr_npts',str2num(get(handles.lwr_npts,'String')));

if old_npts ~= npts
  %Changed an option so clear model/s.
  change_options(handles)
end

%--------------------------------------------------------------------
function lwr_algorithm_Callback(hObject, eventdata, handles)
%Algorithm callback, disable lv's if global.

opts = getappdata(handles.analysis, 'analysisoptions');

val = get(hObject,'value');
str = get(hObject,'string');

if ~strcmpi(opts.algorithm,str{val})
  opts.algorithm = lower(str{val});
  analysis('setopts',handles,'lwr',opts)
  change_options(handles)
else
  return
end

panelupdate_Callback(handles.analysis, [],[])

%--------------------------------------------------------------------
function lwr_lvs_Callback(hObject, eventdata, handles)
%Save lvs to options.
opts = getappdata(handles.analysis, 'analysisoptions');

if isempty(opts.reglvs)
  if isempty(get(handles.lwr_lvs,'string'))
    %Same empty value, do nothing.
    return
  else
    %Changed from empty to value.
    opts.reglvs = str2num(get(handles.lwr_lvs,'string'));
    analysis('setopts',handles,'lwr',opts)
    change_options(handles)
  end
else
  if isempty(get(handles.lwr_lvs,'string')) || opts.reglvs~=str2num(get(handles.lwr_lvs,'string'))
    %Changed from value to empty or value to different value.
    opts.reglvs = str2num(get(handles.lwr_lvs,'string'));
    analysis('setopts',handles,'lwr',opts)
    change_options(handles)
  else
    return
  end
end
  

%--------------------------------------------------------------------
function out = change_options(handles)
%LWR Option has been changed so check to see if need to clear all models.

%Code from analysis/editoptions callback.
statmodl = getappdata(handles.analysis,'statmodl');
if ~strcmp(statmodl,'none')
  %Clear model without prompting.
  analysis('clearmodel',handles.analysis, [], handles, []);
  
%   default = 'Clear Without Saving';
%   if strcmp(statmodl,'loaded')
%     default = 'Keep Model';
%   end
%   ans=evriquestdlg('Some option changes may not have an affect unless the model is reclaculated. Do you want wish to clear the model/s now?', ...
%     'Changing Options','Clear Without Saving',...
%     'Save & Clear','Keep Model',default);
%   switch ans
%     case {'Save & Clear'}
%       if ~isempty(savemodel(handles.savemodel, [], handles, []))
%         analysis('clearmodel',handles.analysis, [], handles, []);
%       end
%     case {'Clear Without Saving'}
%       analysis('clearmodel',handles.analysis, [], handles, []);
%   end
end

%--------------------------------------------------------------------
function panelinitialize_Callback(figh, frameh, varargin)
%Initialize panel objects. figh is parent figure, frameh is frame
% handle.

panelresize_Callback(figh, frameh, varargin)
panelupdate_Callback(figh, frameh, varargin)


handles = guihandles(figh);

% %Get old options or create new then udpate gui.
% opts = analysis('getoptshistory',handles,'lwr');
% if isempty(opts)
%   opts = lwr('options');
%   setappdata(handles.analysis, 'analysisoptions',opts);
% end

panelresize_Callback(figh, frameh, varargin)
panelupdate_Callback(figh, frameh, varargin)

%--------------------------------------------------------------------
function  panelupdate_Callback(figh, frameh, varargin)
%Update panel objects. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);

opts = getappdata(handles.analysis, 'analysisoptions');
if isempty(opts)||~strcmpi(opts.functionname,'lwr')
  %Options were cleared so add them again.
  %Use svm_guifcn to "set options", the code is generic.
  svm_guifcn('setoptions',handles);
  opts = getappdata(handles.analysis, 'analysisoptions');
end

switch lower(opts.algorithm)
  case 'globalpcr'
    set(handles.lwr_algorithm,'value',1);
  case 'pcr'
    set(handles.lwr_algorithm,'value',2);
  case 'pls'
    set(handles.lwr_algorithm,'value',3);
end

set(handles.lwr_lvs,'string',num2str(opts.reglvs));
set(handles.lwr_npts,'string',num2str(getappdata(handles.analysis,'lwr_npts')));

val = get(handles.lwr_algorithm,'value');
if val == 1
  set(handles.lwr_lvs,'enable','off')
else
  set(handles.lwr_lvs,'enable','on')
end

%--------------------------------------------------------------------
function panelresize_Callback(figh, frameh, varargin)
% Resize specific to panel manager. figh is parent figure, frameh is frame
% handle.


handles = guihandles(figh);
myctrls = findobj(figh,'userdata','lwrgui');
set(myctrls,'units','pixels');

%Move rest of controls to upper left of frame.
frmpos = get(frameh,'position');%[left bottom width height]

txtpos = get(handles.text1,'position');
newbottom = (frmpos(2)+frmpos(4)-(24+8));
newleft1 = (frmpos(1)+6);
newleft2 = (frmpos(1)+180+4);

%Column widths.
w1 = 170;
w2 = 120;


%Height
ht = 24;
ht2 = 24;

%Division size.
smdiv = 2;

set(handles.text1,'position',[newleft1 newbottom w1 ht]);
set(handles.lwr_npts,'position',[newleft2 newbottom+2 w2 ht]);
set(handles.surveypts,'position',[newleft2+w2+2 newbottom+2 w2 ht]);

newbottom = newbottom-34;
set(handles.text4,'position',[newleft1 newbottom w1+w2+10 34]);

newbottom = newbottom-(ht+smdiv)-2;

set(handles.text2,'position',[newleft1 newbottom w1 ht]);
set(handles.lwr_algorithm,'position',[newleft2 newbottom+2 w2 ht]);

newbottom = newbottom-44;
set(handles.text5,'position',[newleft1 newbottom w1+w2+10 44]);


newbottom = newbottom-(ht+smdiv);

set(handles.text3,'position',[newleft1 newbottom w1 ht]);
set(handles.lwr_lvs,'position',[newleft2 newbottom+2 w2 ht]);

newbottom = newbottom-54;
set(handles.text6,'position',[newleft1 newbottom w1+w2+10 54]);

% t4pos = get(handles.text4,'position');
% newbottom = newbottom-t4pos(4)-4;
% set(handles.text4,'position',[newleft1 newbottom frmpos(3)-12 t4pos(4)]);
% %make sure it is tall enough
% ext = get(handles.text4,'extent');
% t4pos = get(handles.text4,'position');
% if ext(4)>t4pos(4);
%   %make taller and adjust down to fit needed extent
%   delta = ext4-t4pos(4);
%   t4pos(4) = t4pos(4)+delta;
%   t4pos(2) = t4pos(2)-delta;
%   set(handles.text4,'position',t4pos);
% end

%------------------------------------------------
function panelblur_Callback(varargin)


% --- Executes on button press in surveypts.
function surveypts_Callback(hObject, eventdata, handles)
% hObject    handle to surveypts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

npts = get(handles.lwr_npts,'string');
if isempty(npts)
  npts = '10';
end
rng = inputdlg('Enter values to test (space or comma delimited)','Survey Number of Points',1,{npts});

if isempty(rng) %cancel
  return;
end

rng = str2num(rng{1});
if isempty(rng)
  return;
end

for j=1:length(rng)
  if isfinite(rng(j))
    set(handles.lwr_npts,'string',num2str(rng(j)))
    lwr_npts_Callback(handles.lwr_npts,[],handles);
    if j==1 | j==length(rng)
      modeloptimizergui('clientsnapshot',handles.analysis);
    else
      modeloptimizer('snapshot',handles.analysis);
    end
  end
end
