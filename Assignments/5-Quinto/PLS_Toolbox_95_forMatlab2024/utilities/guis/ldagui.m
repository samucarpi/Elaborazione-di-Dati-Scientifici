function varargout = ldagui(varargin)
% LDAGUI MATLAB code for ldagui.fig
%      LDAGUI, by itself, creates a new LDAGUI or raises the existing
%      singleton*.
%
%      H = LDAGUI returns the handle to a new LDAGUI or the handle to
%      the existing singleton*.
%
%      LDAGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LDAGUI.M with the given input arguments.
%
%      LDAGUI('Property','Value',...) creates a new LDAGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ldagui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ldagui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2013
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

%--------------------------------------------------------------------
function panelresize_Callback(figh, frameh, varargin)
% Resize specific to panel manager. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);
myctrls = findobj(figh,'userdata','ldagui');


%Move rest of controls to upper left of frame.
frmpos = get(frameh,'position');%[left bottom width height]

cmpfrmpos = get(handles.frame3,'position');

newbottom = (frmpos(2)+frmpos(4)-cmpfrmpos(4)-10);
newleft = (frmpos(1)+6);


%Move comopression frame to lower left.
set(handles.frame3,'position',[newleft-2 newbottom-2 cmpfrmpos(3) cmpfrmpos(4)])

newbottom = newbottom+6;
set(handles.text6,'position',[newleft+6 newbottom 100 20])
set(handles.edit3,'position',[newleft+110 newbottom 200 20])
% 
% newbottom = newbottom+30;
% set(handles.text5,'position',[newleft+6 newbottom 100 20])
% set(handles.popupmenu3,'position',[newleft+110 newbottom 200 20])

newbottom = newbottom-6;

%Move help button to lower right.
set(handles.pushbutton1,'position',[cmpfrmpos(3)-110 newbottom-40 120 30])


%--------------------------------------------------------------------
function  panelupdate_Callback(figh, frameh, varargin)
%Update panel objects. figh is parent figure, frameh is frame
% handle.


%----------------------------------------------------
function panelblur_Callback(varargin)

%--------------------------------------------------------------------
function panelinitialize_Callback(figh, frameh, varargin)
%Initialize panel objects. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);
myctrls = findobj(figh,'userdata','ldagui');
set(myctrls,'units','pixels','backgroundcolor',get(frameh,'backgroundcolor'),...
  'fontsize',getdefaultfontsize);

set([handles.edit3],'backgroundcolor','white');
set(handles.pushbutton1,'backgroundcolor',[.929 .929 .929]);

panelresize_Callback(figh, frameh, varargin)
panelupdate_Callback(figh, frameh, varargin)

opts = getappdata(handles.analysis, 'analysisoptions');
if isempty(opts)
  %Options were cleared so add them again.
  lda_guifcn('setoptions',handles);
  opts = getappdata(handles.analysis, 'analysisoptions');
end

set(handles.edit3,'String',num2str(opts.lambda))


%--------------------------------------------------------------------
function pushbutton1_Callback(hObject, eventdata, handles)
%Open lda help page.
evrihelp('lda')

%--------------------------------------------------------------------
function edit3_Callback(hObject, eventdata, handles)
%Change lambda value.

myctrl = findobj(handles.analysis,'tag','edit3','userdata','ldagui');

myval = str2num(get(myctrl,'String'));

if isempty(myval) | myval<0
  myval = 0;
end

set(myctrl,'String',num2str(myval));%Reset val just in case it was invalid.

opts = getappdata(handles.analysis, 'analysisoptions');
opts.lambda = myval;
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

fn  = analysistypes(curanal,3);
if ~isempty(fn);
  feval(fn,'optionschange',handles.analysis);
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);
