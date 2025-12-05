function varargout = mcrgui(varargin)
% MCRGUI Gui objects for mcr panel.

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
function panelinitialize_Callback(figh, frameh, varargin)
%Initialize panel objects.

handles = guihandles(figh);

panelresize_Callback(figh, frameh, varargin)
panelupdate_Callback(figh, frameh, varargin)

%--------------------------------------------------------------------
function  panelupdate_Callback(figh, frameh, varargin)
%Update controls in panel.

%TODO: Options for closure = none not preserved.

handles = guihandles(figh);
myobj = evrigui(handles.analysis);

opts = getappdata(handles.analysis, 'analysisoptions');
if isempty(opts)||~strcmpi(opts.functionname,'mcr')
  opts = mcr('options');
  opts.display       = 'off';
  opts.plots         = 'none';
  setappdata(handles.analysis, 'analysisoptions',opts);
end

mycontrast = lower(opts.alsoptions.contrast);
if isempty(mycontrast)
  mycontrast = '';
end

%Contrast {'contributions' 'spectra' 'auto' ''}, don't use auto.
switch mycontrast
  case {'auto' ''}
    %If auto set to off.
    set(handles.contrastctrl,'value',1);
  case 'contributions'
    set(handles.contrastctrl,'value',2);
  case 'spectra'
    set(handles.contrastctrl,'value',3);
end

%Closure {'none' 'all' 'choose'}.
closr = opts.alsoptions.closure;
if isempty(closr)
  closr = false;
end
ncomp = myobj.interface.getComponents;
set(handles.closurelist,'enable','off','string',num2str([1:ncomp]'))
nclosr = numel(closr);
if nclosr==1
  if closr==0
    set(handles.closurectrl,'value',1);
    set(handles.closurelist,'value',[])
  else
    set(handles.closurectrl,'value',2);
    set(handles.closurelist,'value',[1:ncomp])
  end
else
  %Choose from logical value in closuer.
  if nclosr>ncomp
    %Closure longer than number of components.
    closr = closr(1:ncomp);
  elseif nclosr<ncomp
    %Closure shorter than number of components.
    closr(ncomp) = false;
  end
  set(handles.closurectrl,'value',3);
  set(handles.closurelist,'enable','on')
  set(handles.closurelist,'value',find(closr))
end
drawnow
%Equality is seperate window.


%--------------------------------------------------------------------
function panelresize_Callback(figh, frameh, varargin)
% Resize specific to panel manager. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);
myctrls = findobj(figh,'userdata','mcrgui');
set(myctrls,'units','pixels','fontsize',getdefaultfontsize);

%Move rest of controls to upper left of frame.
frmpos = get(frameh,'position');%[left bottom width height]
newbottom = (frmpos(2)+frmpos(4)-(20+8));
newleft1 = (frmpos(1)+10);
newleft2 = (frmpos(1)+161+4);
newleft3 = (frmpos(1)+245+4);

%Column widths.
w1 = 136;
w2 = 120;
w3 = 70;
w4 = w1+w2+30;

%Height
ht = 20;
ht2 = 20;

set(handles.contrastlbl,'position',[newleft1 newbottom w1 ht]);
set(handles.contrastctrl,'position',[newleft2 newbottom w2 ht]);
set(handles.contrastframe,'position',[8 newbottom-6 w4 ht+10]);

newbottom = newbottom-34;
set(handles.closurelbl,'position',[newleft1 newbottom w1 ht]);
set(handles.closurectrl,'position',[newleft2 newbottom w2 ht]);

newbottom = newbottom-84;
set(handles.closurelist,'position',[newleft1 newbottom w4-12 ht*4])
set(handles.closureframe,'position',[8 newbottom-6 w4 ht*6-4]);

newbottom = newbottom-34;
set(handles.equalitylbl,'position',[newleft1 newbottom w1 ht]);
set(handles.equalityctrl,'position',[newleft2 newbottom w2 ht]);
set(handles.equalityframe,'position',[8 newbottom-4 w4 ht+10]);

newbottom = newbottom-30;
set(handles.helpbtn,'position',[newleft2 newbottom w2 ht]);


%--------------------------------------------------------------------
function control_Callback(hObject, eventdata, handles)
%Callback for all controls.
handles = guihandles(handles.analysis);
opts = getappdata(handles.analysis, 'analysisoptions');

mytag = get(hObject,'tag');

switch mytag
  case 'contrastctrl'
    myval = get(hObject,'value');
    switch myval
      case 1
        opts.alsoptions.contrast = '';
      case 2
        opts.alsoptions.contrast = 'contributions';
      case 3
        opts.alsoptions.contrast = 'spectra';
    end
  case 'closurectrl'
    myval = get(hObject,'value');
    mylist = get(handles.closurelist,'string');
    switch myval
      case 1
        %None.
        opts.alsoptions.closure = [];
        set(handles.closurelist,'enable','off','value',[]);
      case 2
        %All.
        opts.alsoptions.closure = true;
        set(handles.closurelist,'enable','off','value',[1:size(mylist,1)]);
      case 3
        %Choose, enable list select and select all.
        set(handles.closurelist,'enable','on');
        mylist = get(handles.closurelist,'string');
        set(handles.closurelist,'enable','on','value',[1:size(mylist,1)]);
        opts.alsoptions.closure = true(1,size(mylist,1));
    end
  case 'closurelist'
    %TODO: Update lable with count.
    mylist = get(handles.closurelist,'string');
    val    = get(handles.closurelist,'value');
    cval   = false(1,size(mylist,1));
    cval(val) = true;
    opts.alsoptions.closure = cval;
  case 'equalityctrl'
    %Open equality gui.
    xblk  = analysis('getobjdata','xblock',handles);
    ncomp = getappdata(handles.pcsedit,'default');

    if isempty(xblk)
      %If there's no xblock then empty is returned. If opts.alsoptions is set
      %to empty it will cause error in panelupdate_Callback.
      evriwarndlg('Equality constraints can''t be editted without X-block data.','Missing X-Block')
      return
    else
      opts.alsoptions = equalitygui(xblk,ncomp,opts.alsoptions);;
    end
    
end

analysis('setopts',handles,'mcr',opts)
change_options(handles)

%--------------------------------------------------------------------
function out = change_options(handles)
%MCR Option has been changed so check to see if need to clear all models.

%Code from analysis/editoptions callback.
statmodl = getappdata(handles.analysis,'statmodl');
if ~strcmp(statmodl,'none')
  %Clear model without prompting.
  analysis('clearmodel',handles.analysis, [], handles, []);
end


% --- Executes on button press in helpbtn.
function helpbtn_Callback(hObject, eventdata, handles)
% hObject    handle to helpbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp('MCR_Constraints');
