function varargout = umapgui(varargin)
% UMAPGUI MATLAB code for umapgui.fig
%      UMAPGUI, by itself, creates a new UMAPGUI or raises the existing
%      singleton*.
%
%      H = UMAPGUI returns the handle to a new UMAPGUI or the handle to
%      the existing singleton*.
%
%      UMAPGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UMAPGUI.M with the given input arguments.
%
%      UMAPGUI('Property','Value',...) creates a new UMAPGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before umapgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to umapgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help umapgui

% Last Modified by GUIDE v2.5 06-Aug-2021 15:57:44

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
function panelresize_Callback(figh, frameh, varargin)
% Resize specific to panel manager. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);
myctrls = findobj(figh,'userdata','umapgui');

%Move rest of controls to upper left of frame.
frmpos = get(frameh,'position');%[left bottom width height]

myvis = 'on';
if frmpos(4)<80
  %Not enough room to show controls so make not visible.
  myvis = 'off';
end

set(handles.frame_umap,'position',[10 frmpos(4)+frmpos(2)-128 350 121],'Visible',myvis);
set(handles.edit_nneighbors,'position',[179 frmpos(4)+frmpos(2)-44 142 27],'Visible',myvis);
set(handles.text_nneighbors,'position',[19 frmpos(4)+frmpos(2)-44 151 27],'Visible',myvis);
set(handles.edit_mindistance,'position',[179 frmpos(4)+frmpos(2)-78 142 27],'Visible',myvis);
set(handles.text_mindistance,'position',[19 frmpos(4)+frmpos(2)-78 151 27],'Visible',myvis);
set(handles.edit_ncomp,'position',[179 frmpos(4)+frmpos(2)-114 142 27],'Visible',myvis);
set(handles.text_ncomp,'position',[19 frmpos(4)+frmpos(2)-114 200 27],'Visible',myvis);

%--------------------------------------------------------------------
function  panelupdate_Callback(figh, frameh, varargin)
%Update panel objects. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);
opts = getappdata(handles.analysis, 'analysisoptions');
set(handles.edit_nneighbors,'String',num2str(opts.n_neighbors));
set(handles.edit_mindistance,'String',num2str(opts.min_dist));
set(handles.edit_ncomp,'String',num2str(opts.n_components));

%--------------------------------------------------------------------
function panelinitialize_Callback(figh, frameh, varargin)
%Initialize panel objects. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);
myctrls = findobj(figh,'userdata','umapgui');
set(myctrls,'units','pixels','backgroundcolor',get(frameh,'backgroundcolor'),...
  'fontsize',getdefaultfontsize);

set([handles.edit_mindistance handles.edit_nneighbors handles.edit_ncomp],'backgroundcolor','white');

opts = analysis('getoptshistory',handles,'umap');
if isempty(opts)
  opts = umap('options');
  opts.display       = 'off';
  opts.plots         = 'none';
end
%setoptions(handles,opts)

%--------------------------------------------------------------------
function edit_nneighbors_Callback(hObject, eventdata, handles)
% Edit nearest neighbor.
myval = round(str2num(get(hObject,'String')));
if isempty(myval) | myval<1
  myval = 15;
end
set(hObject,'String',num2str(myval));%Reset val just in case it was invalid.

opts = getappdata(handles.analysis, 'analysisoptions');
opts.n_neighbors = myval;
setoptions(handles,opts);

%--------------------------------------------------------------------
function edit_mindistance_Callback(hObject, eventdata, handles)
% Edit min dist.
myval = str2num(get(hObject,'String'));
if isempty(myval) | myval<0
  myval = 0.1000;
end
set(hObject,'String',num2str(myval));%Reset val just in case it was invalid.

opts = getappdata(handles.analysis, 'analysisoptions');
opts.min_dist = myval;
setoptions(handles,opts);
%--------------------------------------------------------------------
function edit_ncomp_Callback(hObject, eventdata, handles)
% Edit ncomp
myval = round(str2num(get(hObject,'String')));
if isempty(myval) | myval<1
  myval = 2;
end
set(hObject,'String',num2str(myval));%Reset val just in case it was invalid.

opts = getappdata(handles.analysis, 'analysisoptions');
opts.n_components = myval;
setoptions(handles,opts);
%--------------------------------------------------------------------
function setoptions(handles,newoptions,clearmodel)
%Set options in analysis gui and call change callback.

if nargin<3
  clearmodel = 1;
end

curanal = getappdata(handles.analysis,'curanal');
analysis('setopts',handles,curanal,newoptions);

if clearmodel
  analysis('clearmodel',handles.analysis, [], handles, []);
end
