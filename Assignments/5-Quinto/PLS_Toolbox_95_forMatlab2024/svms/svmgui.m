function varargout = svmgui(varargin)
% SVMGUI M-file for svmgui.fig
%      SVMGUI, by itself, creates a new SVMGUI or raises the existing
%      singleton*.
%
%      H = SVMGUI returns the handle to a new SVMGUI or the handle to
%      the existing singleton*.
%
%      SVMGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SVMGUI.M with the given input arguments.
%
%      SVMGUI('Property','Value',...) creates a new SVMGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before svmgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to svmgui_OpeningFcn via varargin.
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

%--------------------------------------------------------------------
function svmtype_Callback(hObject, eventdata, handles)
%Change svmtype.
svmmode = getappdata(handles.analysis,'curanal');
opts = getappdata(handles.analysis, 'analysisoptions');
this_type = get(hObject,'tag');

switch this_type
  case 'svc_c'
    this_type = 'c-svc';
  case 'svc_nu'
    this_type = 'nu-svc';
  case 'svr_e'
    this_type = 'epsilon-svr';
  case 'svr_nu'
    this_type = 'nu-svr';
end

if ~strcmpi(opts.svmtype,this_type)
  opts.svmtype = this_type;
  %change_options(handles)
  analysis('clearmodel',handles.analysis, [], handles, []);
  analysis('setopts',handles,svmmode,opts)
else
  return
end

%Turn off all radio buttons.
set([handles.svc_c handles.svc_nu handles.svr_e handles.svr_nu],'value',0);

if strcmpi(svmmode,'svm')
  %In regression mode.
  if strcmpi(lower(opts.svmtype),'epsilon-svr')
    set(handles.svr_e,'value',1);
  else
    set(handles.svr_nu,'value',1);
  end
else
  %In classification mode "svmda".
  if strcmpi(lower(opts.svmtype),'c-svc')
    %Need to set svmtype to default classification options.
    set(handles.svc_c,'value',1);
  else
    set(handles.svc_nu,'value',1);
  end
end

%--------------------------------------------------------------------
function out = change_options(handles)
%SVM Option has been changed so check to see if need to clear all models.

%Code from analysis/editoptions callback.
statmodl = getappdata(handles.analysis,'statmodl');
if ~strcmp(statmodl,'none')
  default = 'Clear Without Saving';
  if strcmp(statmodl,'loaded')
    default = 'Keep Model';
  end
  ans=evriquestdlg('Some option changes may not have an affect unless the model is reclaculated. Do you want wish to clear the model/s now?', ...
    'Changing Options','Clear Without Saving',...
    'Save & Clear','Keep Model',default);
  switch ans
    case {'Save & Clear'}
      if ~isempty(analysis('savemodel',handles.savemodel, [], handles, []))
        analysis('clearmodel',handles.analysis, [], handles, []);
      end
    case {'Clear Without Saving'}
      analysis('clearmodel',handles.analysis, [], handles, []);
  end
end

%--------------------------------------------------------------------
function panelinitialize_Callback(figh, frameh, varargin)
%Initialize panel objects. figh is parent figure, frameh is frame
% handle.

panelresize_Callback(figh, frameh, varargin)
panelupdate_Callback(figh, frameh, varargin)

%--------------------------------------------------------------------
function  panelupdate_Callback(figh, frameh, varargin)
%Update panel objects. figh is parent figure, frameh is frame
% handle.
handles = guihandles(figh);
svmmode = getappdata(handles.analysis,'curanal');
opts = getappdata(handles.analysis, 'analysisoptions');
if isempty(opts)
  %Options were cleared so add them again.
  svm_guifcn('setoptions',handles);
  opts = getappdata(handles.analysis, 'analysisoptions');
end

%Turn off all radio buttons.
set([handles.svc_nu handles.svc_c handles.svr_e handles.svr_nu] ,'value',0);

if strcmpi(svmmode,'svm')
  %In regression mode.
  if strcmpi(lower(opts.svmtype),'epsilon-svr')
    set(handles.svr_e,'value',1);
  else
    set(handles.svr_nu,'value',1);
  end
else
  %In classification mode "svmda".
  if strcmpi(lower(opts.svmtype),'c-svc')
    %Need to set svmtype to default classification options.
    set(handles.svc_c,'value',1);
  else
    set(handles.svc_nu,'value',1);
  end
end

%Update compression.
switch opts.compression
  case 'none'
    set(handles.xblock_compression, 'value',1);
    set(handles.svm_comps,'string','','enable','off')
  case 'pca'
    set(handles.xblock_compression, 'value',2);
    set(handles.svm_comps,'string',num2str(opts.compressncomp),'enable','on')
  case 'pls'
    set(handles.xblock_compression, 'value',3);
    set(handles.svm_comps,'string',num2str(opts.compressncomp),'enable','on')
end
set(handles.xblock_compression,'backgroundcolor','white');

%Probability estimates are an option of svmengine but are added to the svm
%options because svm will deal with the option.
if ~isfield(opts,'probabilityestimates')
  opts.probabilityestimates = 0;
  opts.q = 1;%Make output quiet, was seeing output from java library.
  analysis('setopts',handles,svmmode,opts)
end

%Update probability.
if strcmpi(opts.functionname,'svm')
  %no probability with svm
  set(handles.prob_est,'value',1,'enable','off')%off
  set(handles.prob_est_label,'enable','off');
else %with SMVDA it is OK
  set([handles.prob_est handles.prob_est_label],'enable','on');
  set(handles.prob_est,'value',1)%off
  if opts.probabilityestimates==1
    set(handles.prob_est,'value',2)%on
  end
end

%hide slider
set([handles.svm_comps handles.cvsplit_slider handles.slider_frame handles.cvsplit_label handles.split_begin handles.split_end handles.cur_val],'visible','off')

%--------------------------------------------------------------------
function panelresize_Callback(figh, frameh, varargin)
% Resize specific to panel manager. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);
myctrls = findobj(figh,'userdata','svmgui');
set(myctrls,'units','pixels','visible','off','backgroundcolor',get(frameh,'backgroundcolor'));

svmmode = getappdata(handles.analysis,'curanal');

%Move rest of controls to upper left of frame.
frmpos = get(frameh,'position');%[left bottom width height]

newbottom = (frmpos(2)+frmpos(4)-(24+8));
newleft = (frmpos(1)+6);
% 
% if strcmpi(svmmode,'svm')
%   set(handles.svr_e,'position',[newleft newbottom 360 26],'visible','on');
%   newbottom = newbottom-28;
%   set(handles.svr_nu,'position',[newleft newbottom 360 26],'visible','on');
% else
%   set(handles.svc_c,'position',[newleft newbottom 360 26],'visible','on');
%   newbottom = newbottom-28;
%   set(handles.svc_nu,'position',[newleft newbottom 360 26],'visible','on');
% end
% 
% %Move frame around radio buttons.
% set(handles.radio_frame,'position',[newleft-2 newbottom-2 364 58],'visible','on')

%Move compression controls.
%newbottom = newbottom-32;
%set(handles.xblock_comp_label, 'position',[newleft+4 newbottom 210 20],'visible','on')
set(handles.xblock_compression,'value',1);
%set(handles.xblock_compression, 'position',[newleft+220 newbottom 136 20],'visible','on')

newbottom = newbottom;
set(handles.comp_label, 'position',[newleft+4 newbottom 210 24],'visible','on')
set(handles.svm_comps, 'position',[newleft+220 newbottom 136 24],'visible','on','backgroundcolor','white')

%Move compression frame.
%set(handles.comp_frame,'position',[newleft-2 newbottom-4 364 54],'visible','on')

%Move probability controls.
newbottom = newbottom;
set(handles.prob_est_label, 'position',[newleft+4 newbottom 210 24],'visible','on')
set(handles.prob_est,'value',1);
set(handles.prob_est, 'position',[newleft+220 newbottom 136 24],'visible','on','backgroundcolor','white')

%Move probability frame.
set(handles.est_frame,'position',[newleft-2 newbottom-2 364 30],'visible','on')

newbottom = newbottom-30;
newleft = newleft + 22;
newleft = newleft + 224;

%hide slider
set([handles.cvsplit_slider handles.slider_frame handles.cvsplit_label handles.split_begin handles.split_end handles.cur_val],'visible','off')

%Move help button.
newbottom = newbottom-7;
%Ticket 755, change "Show Help" to "Help" easiest to do here rather than
%fig file.
set(handles.showsvmhelp,'position',[newleft-4 newbottom 120 30],'visible','on','String','Help')

%--------------------------------------------------------------------
function cvsplit_slider_Callback(hObject, eventdata, handles)
%CV Slider callback, clear model then update slider value.
update_slider_Callback(hObject, [], handles)


%--------------------------------------------------------------------
function update_slider_Callback(hObject, eventdata, handles)
%Update options with slider value.

%--------------------------------------------------------------------
function xblock_compression_Callback(hObject, eventdata, handles)
%Change compresison dropdown.
opts = getappdata(handles.analysis, 'analysisoptions');
svmmode = getappdata(handles.analysis,'curanal');
myval = get(handles.xblock_compression,'value');

switch myval
  case 1
    myval = 'none';
  case 2
    myval = 'pca';
  case 3
    myval = 'pls';
end

if strcmpi(opts.compression,myval)
  return
else
  opts.compression = myval;
end

analysis('setopts',handles,svmmode,opts)

analysis('clearmodel',handles.analysis, [], handles, []);

%Update to enable ncomp if needed.
panelupdate_Callback(handles.analysis, handles.ssqframe, [])

%--------------------------------------------------------------------
function svm_comps_Callback(hObject, eventdata, handles)
%Change ncomp for compression.
opts = getappdata(handles.analysis, 'analysisoptions');
svmmode = getappdata(handles.analysis,'curanal');

myval = str2num(get(handles.svm_comps,'string'));
if opts.compressncomp == myval
  return
else
  opts.compressncomp = myval;
end

analysis('setopts',handles,svmmode,opts)
analysis('clearmodel',handles.analysis, [], handles, []);

%--------------------------------------------------------------------
function prob_est_Callback(hObject, eventdata, handles)
%On/off probablility.
opts = getappdata(handles.analysis, 'analysisoptions');
svmmode = getappdata(handles.analysis,'curanal');
myval = get(handles.prob_est,'value');
myval = myval-1;%account for index offset

if ~isfield(opts,'probabilityestimates')
  opts.probabilityestimates = 0;
end

if opts.probabilityestimates == myval
  return
else
  opts.probabilityestimates = myval;
end

analysis('setopts',handles,svmmode,opts)
analysis('clearmodel',handles.analysis, [], handles, []);


%--------------------------------------------------------------------
function showsvmhelp_Callback(hObject, eventdata, handles)
%Open svm help page.
evrihelp('svm_function_settings')

