function varargout = xgbgui(varargin)
% XGBGUI MATLAB code for xgbgui.fig
%      XGBGUI, by itself, creates a new XGBGUI or raises the existing
%      singleton*.
%
%      H = XGBGUI returns the handle to a new XGBGUI or the handle to
%      the existing singleton*.
%
%      XGBGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in XGBGUI.M with the given input arguments.
%
%      XGBGUI('Property','Value',...) creates a new XGBGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before xgbgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to xgbgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2019
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~isempty(varargin) && ischar(varargin{1})
  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
    options.selectvars_lvs = 10;
    options.showalloptions = 'no';%Show all options or not.
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

% --------------------------------------------------------------------
function panelinitialize_Callback(figh, frameh, varargin)
%Initialize panel objects.

myctrls = findobj(figh,'userdata','xgbgui');
drawnow
%handles = guihandles(figh);
%scalePosition(handles)
set(findall(myctrls,'-property','Fontsize'),'Fontsize',getdefaultfontsize)


%Clear axes.
update_plot(figh)

% --------------------------------------------------------------------
function  panelupdate_Callback(figh, frameh, varargin)
%Update panel controls.

handles = guidata(figh);
set(handles.ssqframe,'visible','off')

ssqframe = findobj(figh,'tag','ssqframe');
if ~isempty(ssqframe)
  set(ssqframe,'visible','off')
end

update_plot(figh)

%--------------------------------------------------------------------
function panelresize_Callback(figh, frameh, varargin)
% Resize specific to panel manager. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);
mychilds = allchild(handles.uipanel_method);
ssqpos = get(handles.ssqframe,'position');

%set(myctrls,'units','pixels','visible','off','backgroundcolor',get(frameh,'backgroundcolor'));

xgbmode = getappdata(handles.analysis,'curanal');

%Set panel positions.
set(handles.uipanel_method,'position',ssqpos,'visible','on')
set(handles.vi_panel,'position',[6 6 ssqpos(3)-12 ssqpos(4)-20],'visible', 'on')
set(handles.xgb_axes,'outerposition',[40 68 ssqpos(3)-78 ssqpos(4)-122],'visible', 'on')
set(handles.xgb_help,'position',[ssqpos(3)-140 4 120 38],'visible', 'on')
set(handles.xgb_plot,'position',[ssqpos(1)+4 4 120 38],'visible', 'on')

set([mychilds],'visible','on');

%--------------------------------------------------------------------
function update_plot(figh, frameh, varargin)
%Update variable importantance plot. 

handles = guihandles(figh);

modl = analysis('getobjdata','model',handles);
x    = analysis('getobjdata','xblock',handles);

if isempty(modl) || isempty(x)
  cla(handles.xgb_axes)
  set(handles.xgb_axes,'XTickLabel','','YTickLabel','','ZTickLabel','','XTick',[],...
    'YTick',[],'ZTick',[],'XColor','white','YColor','white','ZColor','white','box','off')
  msg = {'Variable Importance Bar Chart'
    ' '
    'Variable importance provides a score that indicates '
    'how useful or valuable each variable was in the '
    'construction of the boosted decision trees within '
    'the model. The more an attribute is used to make key '
    'decisions with decision trees, the higher its '
    'relative importance.'};
  hh = text(.1,.7,msg,'Fontsize',getdefaultfontsize,'parent',handles.xgb_axes);
  ylabel('','parent',handles.xgb_axes);
  xlabel('','parent',handles.xgb_axes);
  return
end

xgb_guifcn('plotloads_Callback',figh, [], handles, handles.xgb_axes)

%--------------------------------------------------------------------
function xgb_help_Callback(hObject, eventdata, handles)
% hObject    handle to xgb_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp(getappdata(handles.analysis,'curanal'));

%--------------------------------------------------------------------
function xgb_plot_Callback(hObject, eventdata, handles)
% hObject    handle to xgb_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

 xgb_guifcn('plotloads_Callback',hObject, eventdata, handles)
