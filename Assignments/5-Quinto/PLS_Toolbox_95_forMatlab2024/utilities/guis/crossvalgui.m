function varargout = crossvalgui(varargin)
%CROSSVALGUI Cross-Validation.
%  The input (h) is the handle of a calling GUI
%  which must have the handles:
%    h.crossval    = uimenu that is checked when CROSSVALGUI
%      is visible and unchecked otherwise, and
%    h.crossvalgui = g; the handle of CROSSVALGUI instanced
%      by the calling GUI.
%  CROSSVALGUI has handles:
%    g.parent      = h; the handle of the calling GUI, and
%    g.scalepopup  = handle of the scaling popupmenu
%
%I/O: crossvalgui(h)

%Copyright Eigenvector Research, Inc. 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 04/01
%jms 02/02 -error checking on close and call with 0 inputs
%jms 4/03 -fixed error when gcbf was empty (hard-coded calls to gui)
%rsk 04/28/04 - Set slider step to matlab default when vector loaded.
%jms 5/04 -round #lv slider output
%bk 5/27/2016 - correction for very high resolution screens (>2K).

if nargin == 0; varargin{1} = 'io'; end

if (nargin==1)&(ishandle(varargin{1}))  % LAUNCH GUI
  fig = openfig(mfilename,'new');
  handles = guihandles(fig);	% Generate a structure of handles to pass to callbacks
  handles.parent = varargin{1};
  guidata(fig, handles);      % store it.
  set(fig,'closerequestfcn',['try;' get(fig,'closerequestfcn') ';catch;delete(gcbf);end'])
  crossvalgui_init(fig)

  if nargout > 0
    varargout{1} = fig;
  end
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
    if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return;
  end
  try
    [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
  catch
    disp(lasterr);
  end
end

%FUNCTIONS/CALLBACKS
% --------------------------------------------------------------------
function crossvalgui_init(h)
%CrossValGUI Initialize
handles   = guidata(h);
set(h,'handlevisibility','callback')
setappdata(h,'parent',handles.parent);
setappdata(h,'enable','off');
set(handles.crossvalhelp,'enable','on');

axisheight = 26;

ppos      = get(handles.parent,'Position');  %parent gui position
mpos      = getscreensize('pixels');            %screen size
% Thought the screen size is correct, this fixes a scaling issue on >2K screens when rendering windows.
if ((mpos(3) > 2048) || (mpos(4) > 1080))
  mpos(3:4)=mpos(3:4)*0.4;
end
cpos      = get(h,'Position');               %size of CrossValGUI
cpos(4)   = cpos(4)+axisheight;           %add space at top for display of pattern
rhs       = ppos(1)+ppos(3)+cpos(3)+15;
if rhs>mpos(3)
  cpos(1) = ppos(1)+ppos(3)+15-(rhs-mpos(3));
else
  cpos(1) = ppos(1)+ppos(3)+15;
end
cpos(2)   = ppos(2);
set(h,'Position',cpos)

% Clamp crossval gui within screen resolution
if(cpos(1)+ cpos(3) > mpos(3))
  cpos(1) = mpos(3) - cpos(3) - (0.1*mpos(3));
end
if(cpos(2)+ cpos(4) > mpos(4))
  cpos(2) = mpos(4) - cpos(4) - (0.1*mpos(4));
end

%create splitdisplay
axh = axes('parent',h,'units','pixels','position',[2 cpos(4)-axisheight-1 cpos(3)-6 axisheight],...
  'box','on','tag','splitdisplay');
set(h,'handlevisibility','on')
im = imagesc(zeros(1,40));
clrs = classcolors;
colormap(clrs(mod((1:41)-1,size(clrs,1))+1,:));
caxis([0 40]);
grid on
set(axh,'xtick',[0.5:39.5],'xticklabel','','ytick',[],'tag','splitdisplay')
set(h,'handlevisibility','callback')

handles.splitdisplay = axh;
guidata(h,handles);

%Add initial cv settings.
remembersettings(h)
setappdata(h,'atdefaults',true)
guistatus(h)

%Set controls to normalized so can resize for larger fonts for Donal.
set(h,'resize','on')
%set(allchild(h),'units','normalized')

allh = allchild(h);
%Bug in 2019b allows hidden annotationpane object to be found. Need to
%remove it because on some platforms it errors out with error:
% "There is no units property on the AnnotationPane class."
% https://www.mathworks.com/matlabcentral/answers/277044-there-is-no-activepositionproperty-property-on-the-figure-class-error
not_annotation = cellfun('isempty',strfind(get(allh,'type'),'annotationpane'));
allh = allh(not_annotation);
hasunits = isprop(allh,'units');
allh = allh(hasunits);
set(allh,'units','normalized');

% --------------------------------------------------------------------
function methodpopup(h, eventdata, handles, varargin)
%Method popupmenu callback
phandles = guidata(handles.parent);

s        = get(handles.methodpopup,'String');
s        = s{get(handles.methodpopup,'Value')};

cvBy = get(handles.crossvalbypopup,'String');
cvBy_s = cvBy{get(handles.crossvalbypopup,'Value')};

lvslider    = [handles.lvvaluetext handles.lvmintext handles.lvmaxtext handles.lvlabeltext handles.lvslider];
splitslider = [handles.splitvaluetext handles.splitmintext handles.splitmaxtext handles.splitlabeltext handles.splitslider];
itslider    = [handles.itvaluetext handles.itmintext handles.itmaxtext handles.itlabeltext handles.itslider];

%flag to handle switching iterations slider with blind width slider
blindmode = false;
oldblindmode = getappdata(handles.itslider,'blindmode');
if isempty(oldblindmode)
  oldblindmode = false;
end

switch s
  case 'none'
    analysis_method = get(phandles.analysis,'Name');    
    if ~isempty(regexp(analysis_method,'SVM','match'))  || ~isempty(regexp(analysis_method,'MLR','match'))
      evritip('unique_id_for_tip','Cross-Validation is still performed using a fast internal random subset method',1);  
    end
    %set([lvslider],'Enable','on')
    set([lvslider splitslider itslider handles.plotpress handles.crossvalidate handles.definecustom handles.definecustomClass handles.crossvalbypopup],'Enable','off')

  case 'leave one out'
    set([lvslider handles.crossvalidate],'Enable','on')
    set([splitslider itslider handles.plotpress handles.definecustom handles.definecustomClass],'Enable','off')
    if any(strcmp(cvBy_s, {'Classes' 'Stratified'}))
      set(handles.definecustomClass,'Enable','on')
    end

  case 'venetian blinds'
    set([itslider lvslider splitslider handles.crossvalidate],'Enable','on')
    set([handles.plotpress handles.definecustom handles.definecustomClass],'Enable','off')
    if any(strcmp(cvBy_s,  {'Classes' 'Stratified'}))
      set(handles.definecustomClass,'Enable','on')
      if strcmp(cvBy_s,  'Classes')
        set(itslider, 'Enable', 'off')
      end
    end
    blindmode = true;
    
  case 'contiguous block'
    set([lvslider splitslider handles.crossvalidate],'Enable','on')
    set([itslider handles.plotpress handles.definecustom handles.definecustomClass],'Enable','off')
    if any(strcmp(cvBy_s, {'Classes' 'Stratified'}))
      set(handles.definecustomClass,'Enable','on')
    end

  case 'random subsets'
    set([lvslider splitslider itslider handles.crossvalidate],'Enable','on')
    set([handles.plotpress handles.definecustom handles.definecustomClass],'Enable','off')
    if any(strcmp(cvBy_s, {'Classes' 'Stratified'}))
      set(handles.definecustomClass,'Enable','on')
    end

  case 'custom'
    if any(strcmp(cvBy_s, {'Classes' 'Stratified'}))
      evrierrordlg('Unable to perform Custom Cross-Validation when cross-validating by Classes or Stratified.','Custom CV Error');
      set(handles.definecustomClass,'Enable','off')
      success = false;
      resetfigure(handles.crossvalgui);
      return
    end
    set([lvslider handles.crossvalidate handles.definecustom handles.definecustomClass],'Enable','on')
    set([splitslider itslider handles.plotpress],'Enable','off')
    if isempty(getappdata(handles.crossvalgui,'cvsets'))
      t = evriquestdlg('Define Custom Cross Validation', 'Define Custom', 'Load...', 'Select Class Set...', 'Cancel', 'Load...');
      switch t
        case 'Cancel'
          success = false;
          resetfigure(handles.crossvalgui);
        case 'Load...'
          success = definecustom_Callback(h, eventdata, handles);
        case 'Select Class Set...'
          success = definecustomClass_Callback(h, eventdata, handles);
      end   
      if ~success
        %did not load custom data, switched back to old blind mode
        blindmode = oldblindmode;
      end
    end
end

%handle blinds/iterations swap
if ~blindmode
  itlabel = 'Number of Iterations';
  if blindmode~=oldblindmode
    %wasn't iterations before, swap stored setting
    %store old setting
    blindsize = get(handles.itslider,'value');
    setappdata(handles.itslider,'blindsize',blindsize)
    %get new setting
    iterations = getappdata(handles.itslider,'iterations');
    if isempty(iterations)
      iterations = 1;
      setappdata(handles.itslider,'iterations',iterations);
    end
    set(handles.itslider,'value',iterations)
    itslider_Callback(h, eventdata, handles, varargin)
  end
else
  itlabel = 'Samples per Blind (Thickness)';
  if blindmode~=oldblindmode
    %wasn't blinds before, swap stored setting
    %store old setting
    iterations = get(handles.itslider,'value');
    setappdata(handles.itslider,'iterations',iterations)
    %get new setting
    blindsize = getappdata(handles.itslider,'blindsize');
    if isempty(blindsize)
      blindsize = 1;
      setappdata(handles.itslider,'blindsize',blindsize);
    end
    set(handles.itslider,'value',blindsize)
    itslider_Callback(h, eventdata, handles, varargin)
  end
end
setappdata(handles.itslider,'blindmode',blindmode);
set(handles.itlabeltext,'string',itlabel);
set(handles.itslider,'tooltip',['Set ' itlabel]);


if ismember(char(getappdata(handles.parent,'curanal')),{'cls' 'mlr' 'svm' 'svmda' 'xgb' 'xgbda' 'ann' 'annda' 'anndl' 'anndlda'});
  set([lvslider],'Enable','off')
end

guidata(handles.parent,phandles)

guistatus(handles.crossvalgui);


% --------------------------------------------------------------------
function crossvalclose_Callback(h, eventdata, handles, varargin)
%Close Request Function
if ishandle(handles.parent);
  resetfigure(handles.crossvalgui);
  guistatus(handles.crossvalgui);
  set(h,'Visible','off');
else
  delete(handles.crossvalgui);    %orphan? just delete myself
end

% --------------------------------------------------------------------
function lvslider_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.lvslider.
pc       = round(get(handles.lvslider,'Value'));
set(handles.lvslider,'Value',pc)
set(handles.lvvaluetext,'String',int2str(pc))
set(handles.plotpress,'Enable','off')
setappdata(handles.crossvalgui,'atdefaults',false)
guistatus(handles.crossvalgui);

% --------------------------------------------------------------------
function splitslider_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.splitslider.
sp       = round(get(handles.splitslider,'Value'));
set(handles.splitslider,'Value',sp)
set(handles.splitvaluetext,'String',int2str(sp))
set(handles.plotpress,'Enable','off')
setappdata(handles.crossvalgui,'atdefaults',false)
guistatus(handles.crossvalgui);

% --------------------------------------------------------------------
function itslider_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.itslider.
it       = round(get(handles.itslider,'Value'));
set(handles.itslider,'Value',it)
set(handles.itvaluetext,'String',int2str(it))
set(handles.plotpress,'Enable','off')
setappdata(handles.crossvalgui,'atdefaults',false)
guistatus(handles.crossvalgui);

% --------------------------------------------------------------------
function success = definecustom_Callback(hObject, eventdata, handles)
% hObject    handle to definecustom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

success = false;
cvi = lddlgpls('doubdataset','Locate vector of custom cross-validation sets');
if isdataset(cvi)
  cvi = cvi.data.include;
end
parenth = getappdata(handles.crossvalgui,'parent');
X = analysis('getobjdata','xblock',parenth);
mod = analysis('getobjdata','model',parenth);

if ~isempty(X)
  sizecheck = size(X,1);
elseif ~isempty(mod)
  sizecheck = mod.datasource{1}.size(1);
else
  sizecheck = 0;
end
  
%TODO: CODE FOR FUTURE USE:
% The following code will open a dataset editor with the ability to edit
% ONLY the class of the samples. This could be used to view/edit the
% cross-validation sets
% data = dataset(zeros(length(cvi),1));
% data.class{1} = cvi;
% h=editds(data,'invisible');
% setappdata(h,'editfields',{'class'});
% setappdata(h,'disallowedmodes',[-1 0 2]);
% editds('initialize',h);
% editds('setmode',h,1);

if isempty(cvi) & isempty(getappdata(handles.crossvalgui,'cvsets'));
  %turn off cross-validation
  resetfigure(handles.crossvalgui); 
  evriwarndlg('Custom cross-validation sets not found - cross-validation reset to last good conditions','Cross-validation reset');
  success = false;
else
  cvi = cvi(:)';  %vectorize
  if length(cvi)==sizecheck
    %Set appdata cvsets to split for custom cv.
    setappdata(handles.crossvalgui,'cvsets',cvi);
    success = true;  
  else
    resetfigure(handles.crossvalgui);
    if ~isempty(cvi)
      evriwarndlg('Custom cross-validation set length does not match X block length - cross-validation reset to last good conditions','Cross-validation reset');
    end
    success = false;
  end
end

guistatus(handles.crossvalgui);

if nargout < 1
  %When called from button don't give output.
  clear success;
end

% --------------------------------------------------------------------
function interactive(fig,mode)
% turn interactive buttons on or off. Inputs are (fig) the crossvalgui
% figure handle and (mode) either 'on' or 'off'

handles = guidata(fig);
set([handles.crossvalidate handles.plotpress handles.crossvalidateframe],'Visible',mode)

% --------------------------------------------------------------------
function disable(fig)
% disable all cross-val buttons

%set(findobj(fig,'userdata','crossvalgui'),'Enable','off');
if ~isempty(fig);
  set(findobj(fig,'type','uicontrol'),'Enable','off');
  setappdata(fig,'enable','off');

  handles = guidata(fig);
  set([handles.crossvalCancel handles.crossvalhelp],'enable','on');
  if strcmpi('off',getappdata(handles.parent,'enable_crossvalgui'))
    %Current method does not support crossval so close the figure.
    crossvalclose_Callback(fig, [], guidata(fig), [])
  end
end

% --------------------------------------------------------------------
function enable(fig,mode)
% enable appropriate cross-val buttons
%  inputs are (fig) the cross-val figure and (mode) the text mode to select
%  in the method pull-down menu
%examples:
%  crossvalgui('enable',cvgui,'none');
%  crossvalgui('enable',cvgui,'contiguous blocks');

forcereset = 0;
mysettings = getappdata(fig,'cvsettings');

if nargin>1;
  %Force reset of cv controls.
  forcereset = 1;
else
  mode = mysettings.cv;
end

if ~isempty(fig);
  handles = guidata(fig);
  if strcmpi('off',getappdata(handles.parent,'enable_crossvalgui'))
    %Current method does not support crossval so disable andcclose the figure.
    disable(fig)
    return
  end
  
  setappdata(fig,'enable','on');

  %if panelmanager('ispanel',struct('file','crossvalgui'),handles.ssqframe);
  set(handles.methodpopup,'Enable','on')
  set(handles.cvmethodtext,'Enable','on')
  set(handles.crossvalhelp,'enable','on');
  setCrossValByPopup(fig,handles);
  set(handles.cvsplitinDS, 'enable', 'on');

  %Set popup to new mode.
  setpopup(handles,mode);

  %Endable controls for given mode.
  methodpopup(handles.methodpopup, [], handles);

  if forcereset
    %Save current settings since it's a forced reset then reset figure.
    remembersettings(fig);
  end
  %Reset figure to set controls to where they are expected.
  resetfigure(fig);
end
guistatus(fig);


% --------------------------------------------------------------------
function setpopup(handles,mode)
%Set popup menu to new value based on 'mode'.

  %test for short-hand method and convert into long-hand name if found
  translate = {
    'loo','leave one out';
    'vet','venetian blinds';
    'con','contiguous block';
    'rnd','random subsets'};
  
%   if (iscell(mode))
%     mode_o = mode;
%     for (i=1:length(mode))
%       if (ischar(mode{i}))
%         mode = mode{i};
%         break;
%       end
%     end
%   end
  
  selected = find(ismember(translate(:,1),mode));
  if ~isempty(selected)
    mode = translate(selected,2);
  end

  %locate selected item in pull-down menu and activate
  methods  = get(handles.methodpopup,'string');
  selected = find(ismember(methods,mode));
  if isempty(selected)
    selected = 1;  %default is 'none' if we can't find the given string
  end
  set(handles.methodpopup,'Value',selected)
  methodpopup(handles.methodpopup, [], handles);

% --------------------------------------------------------------------
function namefactors(fig,factorname)
% allow change of name for "factors" on LVSlider

handles = guidata(fig);
mystr = ['Maximum Number of ' factorname];
set(handles.lvlabeltext,'string',mystr,'tooltip',mystr)
set(handles.lvslider,'tooltip',['Set ' mystr])

% --------------------------------------------------------------------
function resetfigure(fig)
%Reset figure to saved settings.

if strcmp(get(fig,'tag'),'analysis')
  fig = getappdata(fig,'crossvalgui');  
end

handles = guidata(fig);

mysettings = getappdata(fig,'cvsettings');

setpopup(handles,mysettings.cv);
methodpopup(handles.methodpopup, [], handles);

if ~isempty(mysettings.lv)
  mysettings.lv = min([max([1 mysettings.lv]) get(handles.lvslider,'max')]);
  set(handles.lvslider,'Value',mysettings.lv);
  set(handles.lvvaluetext,'String',int2str(mysettings.lv))
end

if ~isempty(mysettings.split)
  if length(mysettings.split)>1
    mysplit = length(unique(mysettings.split));
  else
    mysplit = mysettings.split;
  end
  mysplit = min([mysplit get(handles.splitslider,'max')]);
  if mysplit<2;
    mysplit = floor(sqrt(get(handles.splitslider,'max')));
  end
  set(handles.splitslider,'Value',mysplit);
  set(handles.splitvaluetext,'String',int2str(mysplit));
end

if ~isempty(mysettings.iter)
  mysettings.iter = min([max([mysettings.iter 1]) get(handles.itslider,'max')]);
  set(handles.itslider,'Value',mysettings.iter)
  set(handles.itvaluetext,'String',int2str(mysettings.iter))
end

if ~isempty(mysettings.cvBy)
  if strcmp(mysettings.cvBy, 'Classes')
    set(handles.crossvalbypopup,'Value', 2);
  end
  if contains(mysettings.cvBy, 'Sample') | isnan(mysettings.cvBySet) | isempty(mysettings.cvBySet)
    set(handles.crossvalbypopup,'Value', 1);
  end
else
  set(handles.definecustomClass, 'enable', 'off');
end

remembersettings(fig)
% setappdata(handles.crossvalgui,'atdefaults',true)  % Causes unintended resetting 
% of number of LVs (1st slider) to default val when X block include changed.

guistatus(handles.crossvalgui);

% --------------------------------------------------------------------
function remembersettings(fig)
%write current settings to appdata of figure.

[cv,lv,split,iter,cvi,cvBy,cvBySet] = getcontrolsettings(fig);

cvsettings.cv = cv;
cvsettings.split = split;
cvsettings.iter = iter;
cvsettings.lv = lv;
cvsettings.cvi = cvi;
cvsettings.cvBy = cvBy;
cvsettings.cvBySet = cvBySet;


setappdata(fig,'cvsettings',cvsettings);

% --------------------------------------------------------------------
function forcesettings(fig,cv,lv,split,iter,cvi)

cvsettings = getappdata(fig,'cvsettings');
if ismodel(cv)
  modl = cv;
  if ~isfieldcheck(modl,'modl.detail.cv') | isempty(modl.detail.cv)
    return
  else
    cvsettings.split = modl.detail.split;
    cvsettings.iter  = modl.detail.iter;
    if isnumeric(modl.detail.cv) | strcmp(modl.detail.cv,'user')
      cvsettings.cv  = 'custom';
      cvsettings.cvi = modl.detail.cv;
      if isfield(modl.detail,'cvi') & ~isempty(modl.detail.cvi)
        cvsettings.split = modl.detail.cvi;
      end
    else
      cvsettings.cv  = modl.detail.cv;
      cvsettings.cvi = {cvsettings.cv cvsettings.split cvsettings.iter};
    end
  end
else
  
  % If cv is a cell, extract the settings
  cvO=[];
  if (iscell(cv))
    cvO = cv;
    splot=[];
    iter=[];
    ln = length(cv);
    cv = cvO{1};
    if (ln>1)
      split = cvO{2};
    end
    if (ln>2)
      iter = cvO{3};
    end
  end
  %manually passed all settings
  cvsettings.cv    = cv;
  if (nargin == 2) & (iscell(cvO))
    cvsettings.split = split;
    cvsettings.iter = iter;
    cvsettings.cvi = cvO;
  end
  if nargin>2;
    cvsettings.lv    = lv;
  end
  if nargin>3;
    cvsettings.split = split;
  end
  if nargin>4;
    cvsettings.iter  = iter;
  end
  if nargin>5;
    cvsettings.cvi   = cvi;
  end
end

setappdata(fig,'cvsettings',cvsettings);
if strcmpi(cvsettings.cv,'custom')
  %Set the cvsets appdata for custom.
  setappdata(fig,'cvsets',cvsettings.split);
end
setappdata(fig,'forcedsettings',true);

resetfigure(fig)  %update GUI to currently stored settings

setappdata(fig,'atdefaults',false)  %note that these values are NOT the default ones (probably not at least)

% --------------------------------------------------------------------
function out = forcedsettings(fig)
%returns true if the gui is in a state where the user has NOT modified the
%settings since last load or initialization

out = getappdata(fig,'forcedsettings');
if isempty(out)
  out = false;
end

% --------------------------------------------------------------------
function [cv,lv,split,iter,cvi,cvBy,cvBySet] = getsettings(fig)
mysettings = getappdata(fig,'cvsettings');

cv = 'none';
lv = 1;
split = 2;
iter = 1;
cvBy = 'Sample Index';
cvBySet = nan;
cvi = [];

opts.model = 'no';
explode(mysettings,opts);


% --------------------------------------------------------------------
function [cv,lv,split,iter,cvi,cvBy, cvBySet] = getcontrolsettings(fig)
% retrieve current settings

handles = guidata(fig);

str = get(handles.methodpopup,'string');
val = get(handles.methodpopup,'value');
myCVMethod = lower(str{val});

cvByStr = get(handles.crossvalbypopup,'string');
cvByVal = get(handles.crossvalbypopup,'value');
cvBy = cvByStr{cvByVal};
cvBySet = getappdata(handles.crossvalgui, 'classset');

switch myCVMethod
  case 'none'
    cv    = 'none';
    split = [];
    iter  = [];
    cvi = {cv split iter};
  case 'leave one out'
    cv    = 'loo';
    split = [];
    iter  = [];
    cvi = {cv split iter};
  case 'venetian blinds'
    cv    = 'vet';
    split = round(get(handles.splitslider,'Value'));
    iter  = round(get(handles.itslider,'Value'));
    cvi = {cv split iter};
  case 'contiguous block'
    cv    = 'con';
    split = round(get(handles.splitslider,'Value'));
    iter  = [];
    cvi = {cv split iter};
  case 'random subsets'
    cv    = 'rnd';
    split = round(get(handles.splitslider,'Value'));
    iter  = round(get(handles.itslider,'Value'));
    cvi = {cv split iter};
  case 'custom'
    cv    = 'custom';
    split = getappdata(handles.crossvalgui,'cvsets');
    iter  = [];
    cvi = split;
end

if ~contains(cvByStr{cvByVal}, 'Sample')
  cvi = getappdata(handles.crossvalgui,'cvsets');
end

lv = round(get(handles.lvslider,'Value'));

% ---------------------------------------------------------
function setmaximum(fig,pc,nsamps,maxiter)
%Called from within Analysis.
% Input 'fig' is crossval figure.

handles = guidata(fig);
atdefaults = getappdata(handles.crossvalgui,'atdefaults');
mysettings = getappdata(fig,'cvsettings');

%lv slider
if pc > 1;
  %validate current setting
  val = get(handles.lvslider,'value');
  if val<=1 | val>pc | atdefaults
    val = pc;
  end
  %and store range and setting
  set(handles.lvslider,'Max',pc, ...
    'Value',val, ...
    'SliderStep',[1/(pc-1) 0.1]);
  set(handles.lvmaxtext,'String',int2str(pc))
  set(handles.lvvaluetext,'String',int2str(val))
else
  set(handles.lvslider,'Max',1.1, ...
    'Value',1, ...
    'SliderStep',[.01 0.1],'enable','off');
  set(handles.lvmaxtext,'String','1')
  set(handles.lvvaluetext,'String','1')
end

%split slider
if floor(nsamps/2)>2
  splits = get(handles.splitslider,'value');
  slmax  = min([100 floor(nsamps/2)]);

  if splits<2 | atdefaults
    splits = min([mysettings.split floor(sqrt(nsamps))]);%min([10 floor(sqrt(nsamps))]);
  elseif splits>slmax
    splits = slmax;
  end
  set(handles.splitslider,'Max',slmax, ...
    'Value',splits, ...
    'SliderStep',[min(1/(slmax-2)) 0.1])
else
  slmax = 2;
  splits = 2;
  set(handles.splitslider,'Max',2.1, ...
    'Value',2,'Enable','off')
end
set(handles.splitmaxtext,'String',int2str(slmax))
set(handles.splitvaluetext,'String',int2str(splits))

%it slider
if maxiter == 1
  iter = 1;
  maxiter = 1.1;
  set(handles.itslider,'Max',1.1, ...
    'Value',1, ...
    'SliderStep',[0.01 0.10]);
else
  iter = get(handles.itslider,'value');
  if iter<1 | atdefaults
    iter = 1;
  elseif iter>maxiter
    iter = maxiter;
  end
  ss = [min([1/(maxiter-.99) .099]) 0.1];
  set(handles.itslider,'Max',maxiter, ...
    'Value',iter, ...
    'SliderStep',ss);
end
set(handles.itmaxtext,'String',int2str(maxiter))
set(handles.itvaluetext,'String',int2str(iter))

%In case we modified settings, save these settings now
remembersettings(handles.crossvalgui);

% --------------------------------------------------------------------
function changed = cvchange(figh)
%Check to see if current settings are different from saved settings.

changed = 0;

[cv,lv,split,iter,~,cvBy,cvBySet]  = getsettings(figh);

[cv_c,lv_c,split_c,iter_c,~,cvBy_c,cvBySet_c] = getcontrolsettings(figh);

%No need to check cvi becuase it's made up of other outputs.

if ~strcmp(cv,cv_c)
  changed = 1;
  return
end

if lv~=lv_c
  changed = 1;
  return
end

if length(split)~=length(split_c) | any(split(:)~=split_c(:))
  changed = 1;
  return
end

if ~strcmp(cvBy,cvBy_c)
  changed = 1;
  return
end

if iter~=iter_c
  changed = 1;
  return
end

if ~isequaln(cvBySet,cvBySet_c)
  changed = 1;
  return
end

% --------------------------------------------------------------------
function guistatus(figh)
%Checks status of figure. If any settings are changed figure becomes modal
%until settings are changed back or ok/cancel button clicked.
handles = guidata(figh);

anyChanges = cvchange(figh);

if anyChanges
  set(figh,'WindowStyle','modal')
  %Enable buttons.
  set(handles.crossvalok,'enable','on')
  set(handles.crossvalCancel,'enable','on','string','Cancel','Tooltip','Cancel and reset settings')
  set(handles.crossvalapply,'enable','on')
  set(handles.crossvalreset,'enable','on')
else
  %No changes, disable OK button.
  set(figh,'WindowStyle','normal')
  set(handles.crossvalok,'enable','off')
  set(handles.crossvalCancel,'enable','on','string','Close','Tooltip','Close Cross-Validation Settings')
  set(handles.crossvalapply,'enable','off')
  set(handles.crossvalreset,'enable','off')
end

analh = getappdata(figh,'parent');
X     = analysis('getobjdata','xblock',analh);
[cv,lv,split,iter,cvi,cvBy,cvBySet] = getcontrolsettings(figh);
if strcmpi(cv,'none')
  set(handles.crossvalbypopup, 'enable', 'off');
else
  setCrossValByPopup(figh,handles)
end
%update picture of splits
if ~contains(cvBy,'Sample') & ~strcmpi(cv,'none')
  myset = getappdata(handles.crossvalgui, 'classset');
  if  ~isnan(myset)
    if anyChanges
        cvi = makeCVIFromClass(handles,X, lower(cvBy));        
        setappdata(handles.crossvalgui, 'cvsets', cvi);
    end
  end
end
nsamp = max(2,min(100,size(X,1)));
%nsamp = max(2,size(X,1));
imh   = findobj(handles.splitdisplay,'type','image');
if ~isempty(X)
  if strcmpi(cv,'none')
    enc = zeros(nsamp,1);
  elseif strcmpi(cv,'custom') | isnumeric(cvi)
    if ~contains(cvBy, 'Sample')
      if isrow(cvi)
        enc = cvi';
      else
        enc = cvi;
      end
    else
      %Custom is hard to encode so leave blank if it's big.
      if nsamp>=100
        %Leave blank.
        %enc = 0;
        if isrow(cvi)
          enc = cvi';
        else
          enc = cvi;
        end
      else
        enc = encodemethod(nsamp,cvi);
      end
    end
  else
      enc = encodemethod(nsamp,cvi);
  end
else
  enc = [];
end
set(imh,'cdata',enc');
set(get(imh,'parent'),'XLim',[0.5 nsamp+.5],'Xtick',[0.5:nsamp+.5])  

%assess current settings relative to model
[issue,splitinfo] = reviewcrossval(getappdata(figh,'parent'));

fontsize = getdefaultfontsize;
%special handling of dismissed notice
dismissed = getappdata(handles.warnings,'dismissed');
if isempty(dismissed); dismissed = {}; end
setappdata(handles.warnings,'dismissed',{});

str = '';
color = 'white';
shown = 0;

if any(strcmp(cvBy, {'Classes' 'Stratified'})) & ~isnan(cvBySet) & ~strcmp(cv, 'none')
  classSetName = X.classname{1,cvBySet};
  color = 'green';
  switch cvBy
    case 'Classes'
      if ~isempty(classSetName)
        str = ['Cross-Validating by Class: ' classSetName];
      else
        str = ['Cross-Validating by Class Set ' num2str(cvBySet)];
      end
    case 'Stratified'
      if ~isempty(classSetName)
        str = ['Stratified cross-validation using Class: ' classSetName];
      else
        str = ['Stratified cross-validation using Class Set: ' num2str(cvBySet)];
      end
      stratWarn = getappdata(handles.crossvalgui,'stratWarning');
      if ~isempty(stratWarn)
        str = [stratWarn newline str];
        color = 'yellow';
      end
  end
end
for issueindex = 1:length(issue);
  harddismiss = getplspref('analysis',['dismiss_' issue(issueindex).issueid]);
  if isempty(harddismiss) | ~harddismiss
    if ~ismember(issue(issueindex).issueid,dismissed);
      %we got a warning, use it and it's color
      if isempty(str);
        str = issue(issueindex).issue;
      else
        str = [issue(issueindex).issue 10 '----------------------' 10 str];
      end
      color = issue(issueindex).color;
      setappdata(handles.warnings,'warningid',issue(issueindex).issueid);
      shown = shown+1;  %don't SHOW any more warnings
    else
      %previous warning happened again, keep it in dismissed
      setappdata(handles.warnings,'dismissed',[getappdata(handles.warnings,'dismissed') {issue(issueindex).issueid}]);
    end
  end
end

if ~isempty(str);
  %add split info (if present)
  if ~isempty(splitinfo)
    str = [str 10 '----------------------' 10 splitinfo];
  end
  %Get help window size and adjust size for wrapping.
  pos = get(figh,'position');
  pos(3) = max(1,pos(3)-23); %Needs to be 23 for version 6.5 widths.
  %Create a dummy control so textwrap will space correctly.
  dummyh = uicontrol(figh,'visible','off','position',pos,'Fontsize',fontsize);
  str = textwrap(dummyh,{str});
  delete(dummyh);
else
  if isempty(splitinfo) | strcmp(cv, 'none')
    str = 'No Warnings';
  else
    str = splitinfo;
  end
  color = 'green';
end

set(handles.warnings,'Value',[],'enable','on');%Want proper behavior and look so set to empty.
set(handles.warnings,'String',str,'fontsize',fontsize)
set(handles.warnings,'backgroundcolor',analysis('statuscolor',color));


% --- Executes on button press in crossvalok.
function crossvalok_Callback(hObject, eventdata, handles)
% User pressed OK, save changes, call change CV callback and then close.
% User pressed Apply, save changes and update gui.

remembersettings(handles.crossvalgui);

if ~isempty(gcbf) & ~isempty(getappdata(gcbf,'crossvalchangecallback'))
  eval(getappdata(gcbf,'crossvalchangecallback'))
end

%guistatus(handles.crossvalgui)
if strcmp(get(hObject,'tag'),'crossvalok')
  %OK
  crossvalclose_Callback(handles.crossvalgui, eventdata, handles);
else
  %Apply
  guistatus(handles.crossvalgui);
end
setappdata(handles.crossvalgui,'forcedsettings',false); %note that user changed settings

% --- Executes on button press in crossvalCancel.
function crossvalCancel_Callback(hObject, eventdata, handles)
%User press cancel. Close noramly.

crossvalclose_Callback(handles.crossvalgui, eventdata, handles);



% --- Executes on button press in crossvalhelp.
function crossvalhelp_Callback(hObject, eventdata, handles)
% hObject    handle to crossvalhelp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


evrihelp('using_cross_validation')


% --- Executes during object creation, after setting all properties.
function warnings_CreateFcn(hObject, eventdata, handles)
% hObject    handle to warnings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in definecustom.
% function definecustom_Callback(hObject, eventdata, handles)
% % hObject    handle to definecustom (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in definecustomClass.
function success = definecustomClass_Callback(hObject, eventdata, handles)
% hObject    handle to definecustomClass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

success = false;
cvBy_choice = getappdata(handles.crossvalgui,'crossvalby');
if strcmp(cvBy_choice, 'Classes')
  crossvalbypopup_Callback([], eventdata, handles)
  return
end
parenth = getappdata(handles.crossvalgui,'parent');
x_data = analysis('getobjdata','xblock',parenth);
myset = getClassSetToUse(x_data, handles);
if isempty(myset)
  resetfigure(handles.crossvalgui);
  evriwarndlg('No classes found in DataSet - cross-validation reset to last good conditions','Cross-validation reset');
  success = false;
  return
end
cvi = x_data.class{1,myset};
mod = analysis('getobjdata','model',parenth);
if ~isempty(x_data)
  sizecheck = size(x_data,1);
elseif ~isempty(mod)
  sizecheck = mod.datasource{1}.size(1);
else
  sizecheck = 0;
end

%TODO: CODE FOR FUTURE USE:
% The following code will open a dataset editor with the ability to edit
% ONLY the class of the samples. This could be used to view/edit the
% cross-validation sets
% data = dataset(zeros(length(cvi),1));
% data.class{1} = cvi;
% h=editds(data,'invisible');
% setappdata(h,'editfields',{'class'});
% setappdata(h,'disallowedmodes',[-1 0 2]);
% editds('initialize',h);
% editds('setmode',h,1);
if isempty(cvi) & isempty(getappdata(handles.crossvalgui,'cvsets'));
  %turn off cross-validation
  resetfigure(handles.crossvalgui);
  evriwarndlg('Custom cross-validation sets not found - cross-validation reset to last good conditions','Cross-validation reset');
  success = false;
else
  cvi = cvi(:)';  %vectorize
  if length(cvi)==sizecheck
    %Set appdata cvsets to split for custom cv.
    setappdata(handles.crossvalgui,'cvsets',cvi);
    success = true;
  else
    resetfigure(handles.crossvalgui);
    if ~isempty(cvi)
      evriwarndlg('Custom cross-validation set length does not match X block length - cross-validation reset to last good conditions','Cross-validation reset');
    end
    success = false;
  end
end
guistatus(handles.crossvalgui);
if nargout < 1
  %When called from button don't give output.
  clear success;
end


% --- Executes on selection change in crossvalbypopup.
function crossvalbypopup_Callback(hObject, eventdata, handles)
% hObject    handle to crossvalbypopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns crossvalbypopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from crossvalbypopup

crossvalBy_s = get(handles.crossvalbypopup, 'String');
crossvalBy_v = get(handles.crossvalbypopup, 'Value');
crossvalBy_choice = crossvalBy_s{crossvalBy_v};
setappdata(handles.crossvalgui,'crossvalby',crossvalBy_choice);
[cv,~,~,~,~] = getcontrolsettings(handles.crossvalgui);
if ~contains(crossvalBy_choice, 'Sample') & ~strcmp(cv, 'none')
  %itlabel = 'Classes per Blind (Thickness)';
  parenth = getappdata(handles.crossvalgui,'parent');
  x_data = analysis('getobjdata','xblock',parenth);
  myset = getClassSetToUse(x_data, handles);
  if ~isempty(myset)
    setappdata(handles.crossvalgui, 'classset', myset);
    if strcmp(cv,'vet') & strcmp(crossvalBy_choice,'Classes')
      set([handles.itvaluetext handles.itmintext handles.itmaxtext handles.itlabeltext handles.itslider],'Enable','off')
    else
      set([handles.itvaluetext handles.itmintext handles.itmaxtext handles.itlabeltext handles.itslider],'Enable','on')
    end
    set(handles.definecustomClass, 'enable', 'on');
  end
  if strcmp(cv, 'custom')
    evriwarndlg('Cannot do custom cross-validaiton by Classes. Setting CV Method to venetian blinds', 'Cross Val by Classes');
    set(handles.definecustomClass, 'enable', 'off');
    setpopup(handles,'vet')
  end
  if isempty(myset)
    setappdata(handles.crossvalgui, 'classset', nan);
    set(handles.definecustomClass, 'enable', 'on');
    resetfigure(handles.crossvalgui);
  end
    
%   if ~isempty(myset)
%     cvi = makeCVIFromClass(handles,x_data, lower(crossvalBy_choice));
%     setappdata(handles.crossvalgui,'cvsets',cvi);
%     set(handles.definecustomClass, 'enable', 'on');
%   else
%     setappdata(handles.crossvalgui, 'classset', nan);
%     resetfigure(handles.crossvalgui);
%   end
else
%   itlabel = 'Samples per Blind (Thickness)';
  setappdata(handles.crossvalgui, 'classset', nan);
  set([handles.itvaluetext handles.itmintext handles.itmaxtext handles.itlabeltext handles.itslider],'Enable','on')
  if ~strcmp(cv,'custom')
    set(handles.definecustomClass, 'enable', 'off');
  end
end
% set(handles.itlabeltext,'string',itlabel);
% set(handles.itslider,'tooltip',['Set ' itlabel]);
methodpopup(handles.methodpopup, [], handles);
guistatus(handles.crossvalgui);


% --- Executes during object creation, after setting all properties.
function crossvalbypopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to crossvalbypopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
function myset = getClassSetToUse(data, handles)
parenth = getappdata(handles.crossvalgui,'parent');
myCurMethod = getappdata(parenth,'curanal');

testForEmptyClass = cellfun(@isempty, data.class(1,:));
findEmptySets = find(testForEmptyClass);
if all(testForEmptyClass)
  resetfigure(handles.crossvalgui);
  evriwarndlg('No classes found in DataSet - cross-validation reset to last good conditions','Cross-validation reset');
  success = false;
  return;
end
nclassSets = size(data.class(1,:),2);
classSetsNames = data.classname(1,:);
for j=1:nclassSets
  if ~testForEmptyClass(j)
    if isempty(classSetsNames{j});
      str{j} = ['Class Set ' num2str(j)];
    else
      str{j} = [classSetsNames{1,j} ' (' num2str(j) ')'];
    end
  else
    str{j} = '<HTML><FONT color="gray"><i>Empty</i></FONT></HTML>';
  end
end

if strcmpi(analysistypes(myCurMethod, 5), 'classification')
  modelgroups = getappdata(findobj(parenth,'tag','choosegrps'),'modelgroups');
  if ~isempty(modelgroups)
    str{end+1} = 'User-defined Group';
  end
end
myset = listdlg('PromptString','Select Class Set:','SelectionMode','Single','liststring',str);
if ~contains(str{myset},'User-defined')
  if isempty(myset) | any(myset == findEmptySets)
    resetfigure(handles.crossvalgui);
    if any(myset == findEmptySets)
      evriwarndlg('Empty Class Set selected. Please choose a non-empty set.','Empty Class Set');
    end
    myset = [];
    return
  end
else
  myset = 'user-defined';
end

% --------------------------------------------------------------------
function cvi = makeCVIFromClass(handles,dso,keyword)
figh = handles.crossvalgui;
[cv,lv,split,iter,cvi_t] = getcontrolsettings(figh);
myset = getappdata(handles.crossvalgui, 'classset');
if strcmp(myset,'user-defined')
  parenth = getappdata(handles.crossvalgui,'parent');
  modelgroups = getappdata(findobj(parenth,'tag','choosegrps'),'modelgroups');
  grpClassSet = getappdata(findobj(parenth,'tag','choosegrps'),'classset');
  myOrigClassValues = dso.class{1,grpClassSet};
  newClassValues = zeros(length(myOrigClassValues),1);
  for i = 1:length(modelgroups)
    myNewClass = i;
    myOldClass = modelgroups{i};
    for j = 1:length(myOldClass)
      myOldClassIndices = myOrigClassValues==myOldClass(j);
      newClassValues(myOldClassIndices) = myNewClass;
    end
  end
  myset = newClassValues;
end

if ~isempty(myset) | ~isnan(myset)
  if isempty(cvi_t) | isnumeric(cvi_t)
    cvi_t = {cv split iter};
  end
  lastwarn('');
  switch keyword
    case 'stratified'
      cvi = stratifiedcvi(dso,myset,cvi_t);
      stratWarning = lastwarn;
      if ~contains(lastwarn, 'EVRI: The least populated class has')
        stratWarning = [];
      end
      setappdata(handles.crossvalgui,'stratWarning', stratWarning);
    case 'classes'
      if strcmp(cvi_t{1},'vet')
        blindsize = cvi_t{3};
        if blindsize ~=1
          cvi_t{3} = 1;
        end
      end
      cvi = cvifromclass(dso,myset,cvi_t);
%       stratWarning = lastwarn;
%       if ~contains(lastwarn, 'EVRI: Blindsize is too large')
%         stratWarning = [];
%       end
%       setappdata(handles.crossvalgui,'stratWarning', stratWarning);
  end
end
if isvector(myset)
  hasZeros = any(myset==0);
  if hasZeros
    cvi = cvi-1;
  end
end

% --------------------------------------------------------------------
function setCrossValByPopup(fig,handles)
analh = getappdata(fig,'parent');
X     = analysis('getobjdata','xblock',analh);
if ~isempty(X)
  canuse = find(cellfun(@(i) length(unique(i))>1,X.class(1,:)));
else
  canuse = [];
end
if ~isempty(X) & any(canuse)
  set(handles.crossvalbyText, 'enable', 'on');
  set(handles.crossvalbypopup, 'enable', 'on');
else
  set(handles.crossvalbypopup, 'tooltip', 'Requires class information');
end


% --- Executes on button press in cvsplitinDS.
function cvsplitinDS_Callback(hObject, eventdata, handles)
% hObject    handle to cvsplitinDS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% The following code will open a dataset editor with the ability to edit
% ONLY the class of the samples. This could be used to view/edit the
% cross-validation sets
figh = handles.crossvalgui;
[~,~,~,~,cvi,~,~] = getcontrolsettings(figh);
analh = getappdata(figh,'parent');
X     = analysis('getobjdata','xblock',analh);
nsamp = size(X,1);

if ~isnumeric(cvi)
  enc = encodemethod(nsamp,cvi);
else
  if isrow(cvi)
    enc = cvi';
  else
    enc = cvi; 
  end
end

leaveOutSetString = repmat('Leave-Out Set ',nsamp,1);
encString = num2str(enc);
classString = strcat(leaveOutSetString, encString);

data = dataset(zeros(length(enc),1));
%data.class{1} = enc;
data.classid{1} = classString;
h=editds(data,'invisible');
setappdata(h,'editfields',{'class'});
%setappdata(h,'editfields',{'none'});
setappdata(h,'disallowedmodes',[-1 0 2]);
editds('initialize',h);
editds('setmode',h,1);
