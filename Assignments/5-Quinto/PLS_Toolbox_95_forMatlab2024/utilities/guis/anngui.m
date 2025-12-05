function varargout = anngui(varargin)
% ANNGUI MATLAB code for anngui.fig
%      ANNGUI, by itself, creates a new ANNGUI or raises the existing
%      singleton*.
%
%      H = ANNGUI returns the handle to a new ANNGUI or the handle to
%      the existing singleton*.
%
%      ANNGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANNGUI.M with the given input arguments.
%
%      ANNGUI('Property','Value',...) creates a new ANNGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before anngui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to anngui_OpeningFcn via varargin.
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
myctrls = findobj(figh,'userdata','anngui');

%Move rest of controls to upper left of frame.
frmpos = get(frameh,'position');%[left bottom width height]

annfrmpos = get(handles.frame2,'position');
cmpfrmpos = get(handles.frame3,'position');

newbottom = (frmpos(2)+frmpos(4)-annfrmpos(4)-cmpfrmpos(4)-10);
newleft = (frmpos(1)+6);

%Move help button to lower right.
set(handles.pushbutton1,'position',[annfrmpos(3)-120 newbottom-40 120 30])

%Move comopression frame to lower left.
set(handles.frame3,'position',[newleft-2 newbottom-2 annfrmpos(3) cmpfrmpos(4)])

newbottom = newbottom+6;
set(handles.text6,'position',[newleft+6 newbottom 200 20])
set(handles.edit3,'position',[newleft+210 newbottom 100 20])

newbottom = newbottom+30;
set(handles.text5,'position',[newleft+6 newbottom 200 20])
set(handles.popupmenu3,'position',[newleft+210 newbottom 100 20])

newbottom = newbottom+36;

%Move layers frame to upper left.
set(handles.frame2,'position',[newleft-2 newbottom-2 annfrmpos(3) annfrmpos(4)])

newbottom = newbottom+6;
set(handles.text4,'position',[newleft+6 newbottom 200 20])
set(handles.edit2,'position',[newleft+210 newbottom 100 20])

newbottom = newbottom+26;
set(handles.text2,'position',[newleft+6 newbottom 200 20])
set(handles.edit1,'position',[newleft+210 newbottom 100 20])

newbottom = newbottom+86;

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
myctrls = findobj(figh,'userdata','anngui');
set(myctrls,'units','pixels','backgroundcolor',get(frameh,'backgroundcolor'),...
  'fontsize',getdefaultfontsize);

set([handles.edit1 handles.edit2 handles.edit3 handles.popupmenu3],'backgroundcolor','white');
set(handles.pushbutton1,'backgroundcolor',[.929 .929 .929]);

panelresize_Callback(figh, frameh, varargin)
panelupdate_Callback(figh, frameh, varargin)

opts = getappdata(handles.analysis, 'analysisoptions');
if isempty(opts)
  %Options were cleared so add them again.
  ann_guifcn('setoptions',handles);
  opts = getappdata(handles.analysis, 'analysisoptions');
end

set(handles.edit2,'enable','on');

switch opts.compression
  case 'pca'
    set(handles.popupmenu3,'value',2);
  case 'pls'
    set(handles.popupmenu3,'value',3);
end

set(handles.edit1,'String',num2str(opts.nhid1));
set(handles.edit2,'String',num2str(opts.nhid2));
set(handles.edit3,'String',num2str(opts.compressncomp));

%--------------------------------------------------------------------
function edit1_Callback(hObject, eventdata, handles, varargin)
%Edit 1st layer.

myctrl = findobj(handles.analysis,'tag','edit1','userdata','anngui');
modl    = analysis('getobjdata','model',handles);

if nargin<4 | isempty(varargin{1})
  myval = round(str2num(get(myctrl,'String')));
else
  myval = varargin{1};
end

if isempty(myval) | myval<1
  myval = 1;
end
set(myctrl,'String',num2str(myval));%Reset val just in case it was invalid.

opts = getappdata(handles.analysis, 'analysisoptions');

%Need this code from ann_guifcn if user changes number of nodes from edit
%box instead of SSQ. 
if ~analysis('isloaded','xblock',handles) & ~isempty(modl)
  
else
  if ~isempty(modl) &  myval == modl.detail.options.nhid1;
    %User clicked back same number of PC's.
    setappdata(handles.analysis,'statmodl','calold');
  elseif ~isempty(modl) & analysis('isloaded','xblock',handles)
    %new PCs for existing model
    setappdata(handles.analysis,'statmodl','calnew');
  end
end
analysis('updatestatusboxes',handles);

opts.nhid1 = myval;
setoptions(handles,opts,0)

%--------------------------------------------------------------------
function pushbutton1_Callback(hObject, eventdata, handles)
%Open ann help page.
evrihelp('ann')

%--------------------------------------------------------------------
function edit2_Callback(hObject, eventdata, handles)
%Edit 2nd layer.

curanal = getappdata(handles.analysis,'curanal');
myctrl = findobj(handles.analysis,'tag','edit2','userdata','anngui');
myval = round(str2num(get(myctrl,'String')));
if isempty(myval) | myval<0
  myval = 0;
end
set(myctrl,'String',num2str(myval));%Reset val just in case it was invalid.

opts = getappdata(handles.analysis, 'analysisoptions');
opts.nhid2 = myval;
setoptions(handles,opts)

%--------------------------------------------------------------------
function popupmenu3_Callback(hObject, eventdata, handles)
%Change compression. 

myval   = get(hObject,'value');

opts = getappdata(handles.analysis, 'analysisoptions');

%Enable PCs edit box.
if myval==1
  set(handles.edit3,'enable','off')
else
  set(handles.edit3,'enable','on')
end

mystr = get(hObject,'string');
mystr = mystr{myval};
opts.compression = mystr;
setoptions(handles,opts)

%--------------------------------------------------------------------
function edit3_Callback(hObject, eventdata, handles)
%Change number of pcs.

myctrl = findobj(handles.analysis,'tag','edit3','userdata','anngui');
myval = round(str2num(get(myctrl,'String')));
if isempty(myval) | myval<1
  myval = 1;
end
set(myctrl,'String',num2str(myval));%Reset val just in case it was invalid.

opts = getappdata(handles.analysis, 'analysisoptions');
opts.compressncomp = myval;
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
