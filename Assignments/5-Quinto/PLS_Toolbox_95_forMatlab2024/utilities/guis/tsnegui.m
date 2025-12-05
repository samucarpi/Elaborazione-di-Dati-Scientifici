function varargout = tsnegui(varargin)
% TSNEGUI MATLAB code for tsnegui.fig
%      TSNEGUI, by itself, creates a new TSNEGUI or raises the existing
%      singleton*.
%
%      H = TSNEGUI returns the handle to a new TSNEGUI or the handle to
%      the existing singleton*.
%
%      TSNEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TSNEGUI.M with the given input arguments.
%
%      TSNEGUI('Property','Value',...) creates a new TSNEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before tsnegui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to tsnegui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help tsnegui

% Last Modified by GUIDE v2.5 06-Aug-2021 13:12:22

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
myctrls = findobj(figh,'userdata','tsnegui');

%Move rest of controls to upper left of frame.
frmpos = get(frameh,'position');%[left bottom width height]

myvis = 'on';
if frmpos(4)<80
  %Not enough room to show controls so make not visible.
  myvis = 'off';
end

set(handles.frame_tsne,'position',[10 frmpos(4)+frmpos(2)-100 350 92],'Visible',myvis);
set(handles.edit_perplexity,'position',[179 frmpos(4)+frmpos(2)-40 142 27],'Visible',myvis);
set(handles.text_perplexity,'position',[19 frmpos(4)+frmpos(2)-42 151 27],'Visible',myvis);
set(handles.edit_components,'position',[179 frmpos(4)+frmpos(2)-80 142 27],'Visible',myvis);
set(handles.text_components,'position',[19 frmpos(4)+frmpos(2)-84 151 27],'Visible',myvis);

%--------------------------------------------------------------------
function  panelupdate_Callback(figh, frameh, varargin)
%Update panel objects. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);
opts = getappdata(handles.analysis, 'analysisoptions');
set(handles.edit_perplexity,'String',num2str(opts.perplexity));
set(handles.edit_components,'String',num2str(opts.n_components));

%--------------------------------------------------------------------
function panelinitialize_Callback(figh, frameh, varargin)
%Initialize panel objects. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);
myctrls = findobj(figh,'userdata','tsnegui');
set(myctrls,'units','pixels','backgroundcolor',get(frameh,'backgroundcolor'),...
  'fontsize',getdefaultfontsize);

set([handles.edit_components handles.edit_perplexity],'backgroundcolor','white');

opts = getappdata(handles.analysis, 'analysisoptions');
if isempty(opts)
  %Options were cleared so add them again. This call to ann_guifcn is
  %generic and will work with any analysis. Not true for getoptions sub
  %function. 
  ann_guifcn('setoptions',handles);
  opts = getappdata(handles.analysis, 'analysisoptions');
end

set(handles.edit_perplexity,'String',num2str(opts.perplexity));
set(handles.edit_components,'String',num2str(opts.n_components));

%----------------------------------------------------
function edit_components_Callback(hObject, eventdata, handles)
% Change ncomp

myval = round(str2num(get(hObject,'String')));
if isempty(myval) | myval<1
  myval = 2;
end
set(hObject,'String',num2str(myval));%Reset val just in case it was invalid.

opts = getappdata(handles.analysis, 'analysisoptions');
opts.n_components = myval;
setoptions(handles,opts)

%----------------------------------------------------
function edit_perplexity_Callback(hObject, eventdata, handles)
% 
myval = round(str2num(get(hObject,'String')));
if isempty(myval) | myval<1
  myval = 30;
end
set(hObject,'String',num2str(myval));%Reset val just in case it was invalid.

opts = getappdata(handles.analysis, 'analysisoptions');
opts.perplexity = myval;
setoptions(handles,opts)

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