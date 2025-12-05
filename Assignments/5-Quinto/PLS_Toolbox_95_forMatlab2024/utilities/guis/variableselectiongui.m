function varargout = variableselectiongui(varargin)
% VARIABLESELECTIONGUI MATLAB code for variableselectiongui.fig
%      VARIABLESELECTIONGUI, by itself, creates a new VARIABLESELECTIONGUI or raises the existing
%      singleton*.
%
%      H = VARIABLESELECTIONGUI returns the handle to a new VARIABLESELECTIONGUI or the handle to
%      the existing singleton*.
%
%      VARIABLESELECTIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VARIABLESELECTIONGUI.M with the given input arguments.
%
%      VARIABLESELECTIONGUI('Property','Value',...) creates a new VARIABLESELECTIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before variableselectiongui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to variableselectiongui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2018
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NOTES:
%  * All calculations done in vsexecute_Callback.
%  * All plotting done in update_plots. Function also updates current VS results. 
%

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

myctrls = findobj(figh,'userdata','variableselectiongui');
drawnow
handles = guihandles(figh);
%scalePosition(handles)
set(findall(myctrls,'-property','Fontsize'),'Fontsize',getdefaultfontsize)

guioptions = variableselectiongui('options');

%Gather needed inputs.
xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);
modl = analysis('getobjdata','model',handles);

%Clear old ipls status data.
setappdata(handles.analysis,'vs_use',[]);
setappdata(handles.analysis,'vs_allresults',[]);
setappdata(handles.analysis,'vs_xmoddate',[]);
setappdata(handles.analysis,'vs_ymoddate',[]);
setappdata(figh,'vs_originalInclude_x',[]);

iplsopts = ipls('options');
iplsopts.numintervals = inf; %NOTE: Hard-code to force on automatic interval selection

%Set mode.
if strcmp(iplsopts.mode,'forward')
  set(handles.iplsmode,'value',1);
else
  set(handles.iplsmode,'value',2);
end

%Set num intervals. iplsintervals
if isinf(iplsopts.numintervals)
  switch 0
    case 0
      set(handles.iplsintervals,'String','1');
      set(handles.iplsintervals_auto,'value',0);
      set(handles.iplsintervals,'enable','on');
    case 1
      set(handles.iplsintervals,'String','auto');
      set(handles.iplsintervals_auto,'value',1);
      set(handles.iplsintervals,'enable','off');
  end
else
  set(handles.iplsintervals_auto,'value',0);
  set(handles.iplsintervals,'enable','on');
  set(handles.iplsintervals,'String',num2str(iplsopts.numintervals));
end

%Set step size.
if isempty(iplsopts.stepsize)
  %Auto select.
  switch 1
    case 0
      %automatic OFF
      set(handles.iplsstepsize,'String','1');
      set(handles.iplsstepsize_auto,'value',0);
      set(handles.iplsstepsize,'enable','on');
    case 1
      %automatic ON
      set(handles.iplsstepsize,'String','auto');
      set(handles.iplsstepsize_auto,'value',1);
      set(handles.iplsstepsize,'enable','off');
  end
else
  set(handles.iplsstepsize,'String',num2str(iplsopts.stepsize));
end

%Vars per interval, start with 1.
set(handles.iplssize,'String','1');

%Set algorithm.
curanal = getappdata(handles.analysis,'curanal');
switch curanal
  case {'pls','plsda'}
    sval = 1;
  case 'pcr'
    sval = 2;
  case 'mlr'
    sval = 3;
end
set(handles.iplsalgorithm,'value',sval);

%Set rPLS defaults.
rplsopts = rpls('options');
switch rplsopts.mode
  case 'specified'
    set(handles.rplsmode,'value',1)
  case 'suggested'
    set(handles.rplsmode,'value',2)
  case 'surveyed'
    set(handles.rplsmode,'value',3)
end

set(handles.rplsiter,'String',num2str(rplsopts.maxiter));

%Set up GA.
gafig = openinga_Callback(handles,1);

%Set selectvars options.
svopts = selectvars('options');
set(handles.svfractionrm,'string',num2str(svopts.fractiontoremove))

%Default in fig file is show = off so if it's on then user has clicked it
%and we should keep it in that state because user probably clicked reset.
if get(handles.checkbox_showall,'value')
  if strcmpi(guioptions.showalloptions,'no')
    set(handles.checkbox_showall,'value',0);
  else
    set(handles.checkbox_showall,'value',1);
  end
end

%For some reason callbacks not getting copied over so manually add.
set([handles.gawindowwidth handles.galvs handles.gasubsets],'callback','variableselectiongui(''gapanel_Callback'',gcbo,[],guidata(gcbo));')

%Clear axes.
update_plot(handles)

popupmenu1_Callback(handles.popupmenu1, [], handles)

% --------------------------------------------------------------------
function panelresize_Callback(figh, frameh, varargin)
% Resize specific to panel manager. figh is parent figure, frameh is frame
% handle.

handles = gethandles(guidata(figh));

ssqpos = get(handles.ssqframe,'position');
[phandle, pname, pheight, poptions, pshortname, psimple] = getCurrentPanel(handles);

panel_L = 6;
panel_W = ssqpos(3)-12;
method_H = 45;
vars_H = max(140,ssqpos(4)-method_H-pheight-46);
vars_B = min(4,ssqpos(4)-88-pheight-vars_H);
method_W = 120;

%Set method dropdown and simplify checkbox.
set(handles.popupmenu1,'position',[panel_L ssqpos(4)-40 220 26 ])
set(handles.checkbox_showplots,'position',[panel_L+220+6 ssqpos(4)-40 140 26 ])
set(handles.checkbox_showall,'position',[panel_L+370 ssqpos(4)-40 140 26 ])

%Set panel positions.
set(handles.uipanel_method,'position',ssqpos)
if checkmlversion('>','8.3')
  set(phandle,'position',[panel_L vars_B+vars_H+38 panel_W pheight])
else
  myvis = 'on';
  if pheight==0
    pheight = .001;
    myvis = 'off';
  end
  set(phandle,'position',[panel_L vars_B+vars_H+38 panel_W pheight],'visible',myvis)
end

set(handles.uipanel_selectedvars,'position',[panel_L vars_B panel_W vars_H])

set(handles.vsexecute,'position',[panel_W-160 vars_B+vars_H+4 76 26])
set(handles.vsreset,'position',[panel_W-80 vars_B+vars_H+4 76 26])

%Set vars panel controls.
% set(handles.intervallist,'position',[4 90 panel_W-10 vars_H-110])
% set(handles.axes_varsused,'position',[4 36 panel_W-10 45])
set(handles.axes_varsused,'position',[10 56 panel_W-20 max(1,vars_H-170+85)])

set(handles.vsuse,'position',[panel_W-180 4 76 26])
set(handles.vsclear,'position',[panel_W-100 4 76 26])

%Toggle visibility.
mychilds = allchild(phandle);
if ~isempty(psimple) & ~get(handles.checkbox_showall,'value')
  mychilds = allchild(phandle);
  mynotvischilds = setdiff(mychilds,psimple);
  set(mynotvischilds,'visible','off');
else
  set(mychilds,'visible','on');
end

% --------------------------------------------------------------------
function  panelupdate_Callback(figh, frameh, varargin)
%Update panel controls.

%ssqframe = findobj(figh,'tag','ssqframe');
handles = gethandles(guidata(figh));
set(handles.ssqframe,'visible','off')

ssqframe = findobj(figh,'tag','ssqframe');
if ~isempty(ssqframe)
  set(ssqframe,'visible','off')
end

%Gather needed inputs.
xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);
myctrls = findobj(figh,'userdata','variableselectiongui');
myctrls = findobj(findall(myctrls),'-property','enable');
%Get var selection status data. 
xmod = getappdata(handles.analysis,'vs_xmoddate');
ymod = getappdata(handles.analysis,'vs_ymoddate');

if isempty(xblk)
  %Clear results if x has been cleared.
  setappdata(handles.analysis,'vs_allresults',[]);
end

clear_results = 0;
%Check for changes to data and clear ipls_use if changes were made.
if ~isempty(xblk) && ~isempty(xmod) && (datenum(xblk.moddate) ~= datenum(xmod))
  clear_results = 1;
  setappdata(figh,'vs_originalInclude_x',[]);
  setappdata(handles.analysis,'vs_xmoddate',xblk.moddate);
end

if ~isempty(yblk) &&  ~isempty(ymod) && (datenum(yblk.moddate) ~= datenum(ymod))
  clear_results = 1;
  setappdata(handles.analysis,'vs_ymoddate',yblk.moddate);
end

if clear_results
  setappdata(handles.analysis,'vs_use',[]);
  setappdata(handles.analysis,'vs_allresults',[]);
  openinga_Callback(handles,1);%Re initialize GA.
  update_plot(handles)
end

%Enable all controls.
if ~isempty(xblk) & (~isempty(yblk) | strcmpi(getappdata(handles.analysis,'curanal'),'plsda'))
  set(myctrls,'enable','on');
  iplsintervals_auto_Callback([], [], handles);
  iplsstepsize_auto_Callback([], [], handles);
else
  %Disable and clear.
  set(myctrls,'enable','off');
  setappdata(handles.analysis,'vs_use',[]);
  cla(handles.axes_varsused);
end

%Set enable of mustuse.
iplsintervals_iplsmode_Callback(handles.iplsmustuse, [], handles)

%Enable "Use" button. 
if ~isempty(getappdata(handles.analysis,'vs_use'))
  set([handles.vsuse handles.vsshowlist],'enable','on');
else
  set([handles.vsuse handles.vsshowlist],'enable','off');
end

%Enable "Discard" button. 
if ~isempty(getappdata(handles.analysis,'vs_originalInclude_x'))
  set(handles.vsclear,'enable','on');
else
  set(handles.vsclear,'enable','off');
  update_plot(handles);
end

%Update data status.
if ~isempty(xblk)
  setappdata(handles.analysis,'vs_xmoddate',xblk.moddate);
end

if ~isempty(yblk)
  setappdata(handles.analysis,'vs_ymoddate',yblk.moddate);
end

%Update visible controls for simple display.
showallopts = get(handles.checkbox_showall,'value');

[phandle, pname, pheight, poptions, pshortname, psimple] = getCurrentPanel(handles);

if ~isempty(psimple)
  %Current panel has simplified options.
  allctrls = allchild(phandle);
  if showallopts
    set(allctrls,'visible','on')
  else
    set(allctrls,'visible','off')
    set(psimple,'visible','on')
  end
  %Need to run resize.
  panelresize_Callback(handles.analysis, [], varargin)
end

if ismember(pshortname,{'rpls' 'ipls'})
  set(handles.checkbox_showall,'enable','on')
else
  set(handles.checkbox_showall,'enable','off')
end

% --------------------------------------------------------------------
function  panelblur_Callback(figh, frameh, varargin)
%NOT USED

% --------------------------------------------------------------------
function popupmenu1_Callback(hObject, eventdata, handles)
% Method selection.

%Get method panels.
handles = gethandles(handles);
mpanels = [handles.uipanel_rpls handles.uipanel_ipls handles.uipanel_ga handles.uipanel_selectvars];

[phandle, pname, pheight, poptions, pshortname, psimple] = getCurrentPanel(handles);

set(mpanels,'visible','off')
set(phandle,'visible','on');

panelresize_Callback(handles.analysis, [], [])

%Refresh GA settings if GA.
if strcmpi(pshortname,'ga')
  openinga_Callback(handles,0);
else
  gaopen_Callback(hObject, eventdata, handles, 'off')
end

if ismember(pshortname,{'rpls' 'ipls'})
  set(handles.checkbox_showall,'enable','on')
else
  set(handles.checkbox_showall,'enable','off')
end

update_plot(handles)

% --------------------------------------------------------------------
function [phandle, pname, pheight, poptions, pshortname, psimple] = getCurrentPanel(handles)
%Get list of current method panels. The psimple variable holds handles to
%simple controls.

handles = gethandles(handles);

panelstr = get(handles.popupmenu1,'String');
popupval = get(handles.popupmenu1,'Value');
psimple = [];%Handles to simplified controls.

showallopts = get(handles.checkbox_showall,'value');%Showing simple options.

pname = panelstr{popupval};
poptions = selectvars('options');
pshortname = '';
switch pname
  case 'Automatic (VIP or sRatio)'
    phandle = handles.uipanel_rpls;%Use dummy
    pheight = 0;
    pshortname = 'auto';
  case 'GA - Genetic Algorithm'
    phandle = handles.uipanel_ga;
    pheight = 184;
    poptions = gaselctr('options');
    pshortname = 'ga';
  case 'iPLS - Interval PLS'
    phandle = handles.uipanel_ipls;
    pheight = 200;
    psimple = [handles.text4 handles.text8 handles.iplsintervals handles.iplsintervals_auto handles.iplssize];
    poptions = ipls('options');
    pshortname = 'ipls';
    if ~showallopts
      pheight = 84;
    end
  case 'rPLS - Recursive PLS'
    phandle = handles.uipanel_rpls;
    pheight = 110;
    
    %Get mode from dropdown.
    rplsmodestr = get(handles.rplsmode,'string');
    rplsmodeval = get(handles.rplsmode,'value');
    rplsmode = lower(rplsmodestr{rplsmodeval});
    
    if ~isempty(strfind(rplsmode,'specified'))
      %In specified mode so show LVs.
      psimple = [handles.text11 handles.rplsmode handles.text80 handles.rplslvs];
      %Enable RPLSLVS here because we have the info.
      set(handles.rplslvs,'enable','on')
    else
      psimple = [handles.text11 handles.rplsmode];%Default is to just show mode unless in specified.
      %Disable RPLSLVS here because we have the info.
      set(handles.rplslvs,'enable','off')
    end
    
    poptions = rpls('options');
    pshortname = 'rpls';
    if ~showallopts
      pheight = 58;
      if ~isempty(strfind(rplsmode,'specified'))
        %In specified mode so show LVs.
        pheight = 82;
      end
    end
  case 'sRatio - Selectivity Ratio'
    phandle = handles.uipanel_selectvars;
    pheight = 58;
    set(phandle,'Title','sRatio')
    pshortname = 'sratio';
  case 'VIP - Variable Importance in Projection'
    phandle = handles.uipanel_selectvars;
    pheight = 58;
    set(phandle,'Title','VIP')
    pshortname = 'vip';
end

% --------------------------------------------------------------------
function shandels = getSimpleHandles(handles)
%Get handles for simple controls for given method.

%List of method, option, and tags.
simple_list = {'ipls' 'stepsize' {''}
  'rpls' '' {}};

% --------------------------------------------------------------------
function scalePosition(handles)
% Method selection.
fs = getdefaultfontsize('normal');
%find all objects with font sizes
allh = allchild(handles.uipanel_method);
hasfont = isprop(allh,'fontsize');
allh = allh(hasfont);
set(allh,'fontunits','points','fontsize',fs);

% %look for extent problem (with typical subject)
% crh = findobj(handles.uipanel_method,'string','Crossover:');
% crex = get(crh,'extent');
% crpo = get(crh,'position');
% scladd = max((crex(3)./crpo(3))-1,0.05);
%
% %rescale
% scl = fs/10+scladd;
% remapfig([0 0 1 1],[0 0 scl scl],handles.uipanel_method);


% --------------------------------------------------------------------
function vsclear_Callback(hObject, eventdata, handles)
% Clear selected variables. "Disgard" button.

crossval_figure = getappdata(handles.analysis);
cvv = getappdata(crossval_figure.crossvalgui);
crossval_settings = cvv.cvsettings;

xblk = analysis('getobjdata','xblock',handles);
xincld = getappdata(handles.analysis,'vs_originalInclude_x');
if ~isempty(xincld) && ~isempty(xblk)
  xblk.include{2} = xincld;
  analysis('setobjdata','xblock',handles,xblk);
  evrihelpdlg('Included Variables have been reset to original ranges.','Included Variables Reset');
end

%Insure that the CV settings have not been reset when clicking 'use'
setappdata(crossval_figure.crossvalgui,'cvsettings',crossval_settings);
if strcmpi(crossval_settings.cv,'custom')
  %Set the cvsets appdata for custom.
  setappdata(crossval_figure.crossvalgui,'cvsets',crossval_settings.split);
end
crossvalgui('resetfigure',crossval_figure.crossvalgui);

panelupdate_Callback(handles.analysis, [], []);

% --------------------------------------------------------------------
function vsreset_Callback(hObject, eventdata, handles)

panelinitialize_Callback(handles.analysis,[], []);
panelupdate_Callback(handles.analysis, [], []);%Re enable controls if they were left disabled during calc callback.

% --------------------------------------------------------------------
function vsexecute_Callback(hObject, eventdata, handles, pushgamodel)
%Run the current VS method. Input pushmodel will get current GA model form
%interface without calculating again. This happens when user pushes
%execute button on GA window intead of panel. 

if nargin<4
  pushgamodel = 0;
end

if isempty(handles)
  handles = guihandles(hObject);
else
  handles = gethandles(handles);
end
curent_method = getappdata(handles.analysis,'curanal');
[phandle, pname, pheight, poptions, pshortname] = getCurrentPanel(handles);

%Gather needed inputs.
xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);
model = analysis('getobjdata','model',handles);

%Get crossval preprocessing into options.
[cvmode,cvlv,cvsplit,cviter] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
if strcmpi(poptions.functionname,'selectvars')
  poptions.cvsplit = {cvmode cvsplit cviter};
end

if strcmpi(cvmode,'none')
  evrimsgbox({'Cross-validation is needed to select variables.' ...
              'Use Cross-Validation window to make selection.'},'Cross-Validation Needed','warn','modal');
  set(getappdata(handles.analysis,'crossvalgui'),'Visible','on')
  figure(getappdata(handles.analysis,'crossvalgui')); 
  return
end


%Get algorithm.
poptions.algorithm = curent_method;

if ~strcmp(cvmode,'none') & strcmpi(poptions.functionname,'ipls')
  %Retain ipls default if none. This is what was originally done in iplsgui
  poptions.cvi = {cvmode cvsplit cviter}; 
else
  poptions.cvi = {cvmode cvsplit cviter};
end

poptions.preprocessing = {getappdata(handles.preprocessmain,'preprocessing') getappdata(handles.preproyblkmain,'preprocessing')};

% If it is iplsda but yblock is not logical then convert it to be so.
if strcmpi(curent_method,'plsda') & ~isempty(yblk) & ~islogical(yblk.data)
  yblk = class2logical(yblk.data);
end

if strcmpi(curent_method,'plsda') & isempty(yblk)
  if isempty(model);
    try
      analysis('calcmodel_Callback',handles.analysis,[],handles);
      model = analysis('getobjdata','model',handles);
    catch
      %do nothing - model will still be empty so error below will be thrown
    end
  end
  if isempty(model);
    %probably had a problem calculating the model or trapped above
    erdlgpls('A PLSDA model must first be calculated with this data but something went wrong when calculating the model. Click the model icon to solve the problem and build a model, then re-execute.','No Model Present');
    return
  end
  yblk = model.detail.data{2};
end

%Get existing selections.
vs_use = getappdata(handles.analysis,'vs_use');

%Get plot val.
plotval = 'off';
if get(handles.checkbox_showplots,'value')
  plotval = 'final';
end
poptions.plots = plotval;


myctrls = findobj(findall(phandle),'-property','enable');
if ~isempty(myctrls)
  %Disable controls so user doesn't get confused about if calculation is
  %going on.
  %It's possible an error may cause controls to be disabled but pushing
  %reset button will re-enable.
  set(myctrls,'enable','off')
end

list = [];
switch pname
  case 'GA - Genetic Algorithm'
    %GA Settings are pushed into the window via openinga_Callback
    gafig = openinga_Callback(handles,0);
    gahandles = guihandles(gafig);
    %Store maxlv in options so can be used in crossval call in
    %update_plot.
    poptions.maxlv = round(get(gahandles.lvs,'value'));
    
    modl = getappdata(gafig,'modl');
    if ~isempty(modl)
      modl.detail.options.display = 'off';
      if strcmpi(plotval,'off')
        gaplotwin = getappdata(gafig,'GAResultsPlot');
        if ~isempty(gaplotwin) & ishandle(gaplotwin)
          delete(gaplotwin)
        end
        modl.detail.options.plots = 'off';
      else
        modl.detail.options.plots = 'intermediate';
      end
      setappdata(gafig,'modl',modl);
    end
    
    if ~pushgamodel
      gawh = [];
      try
        if strcmpi(plotval,'off')
          %Need some indication GA is running.
          gawh = waitbar(.5,'Running Genetic Algorithm...', 'windowstyle', 'modal');
        end
        genalg('garun',gafig);
        if ~isempty(gawh) & ishandle(gawh)
          close(gawh)
        end
      catch
        if ~isempty(gawh) & ishandle(gawh)
          close(gawh)
        end
        rethrow(lasterror)
      end
      
    end
    vs_results = genalg('updatemodel',gafig);
    
    if ~isempty(vs_results) & ~isempty(vs_results.icol)
      [rmsecv_sort,rmsecv_sort_idx] = sort(vs_results.rmsecv);
      icolbest = vs_results.icol(rmsecv_sort_idx(1),:);
      list = xblk.include{2}(logical(icolbest));
    end
    %Fool GUI into thinking it's ok to close without warnings. 
    setappdata(gahandles.saveresults,'timestamp',vs_results.time)
  case 'iPLS - Interval PLS'
    int_width = str2num(get(handles.iplssize,'String'));
    %Store maxlv in options so can be used in crossval call in
    %update_plot.
    poptions.maxlv = cvlv;
    
    modeval = get(handles.iplsmode,'value');
    modestr = get(handles.iplsmode,'string');
    poptions.mode = modestr{modeval};
    
    algval = get(handles.iplsalgorithm,'value');
    algstr = get(handles.iplsalgorithm,'string');
    poptions.algorithm = algstr{algval};
    
    stepstr = get(handles.iplsstepsize,'string');
    if strcmpi(stepstr,'auto')
      stepstr = '';
    end
    poptions.stepsize = str2num(stepstr);
    poptions.mustuse  = str2num(get(handles.iplsmustuse,'string'));
    
    if ~isempty(vs_use)
      switch poptions.mode
        case 'forward'
          switch evriquestdlg('Should current selections add to the previously selected intervals or start a new selection?','Previous Selection Found','Add To Previous','Start New','Cancel','Add To Previous');
            case 'Cancel'
              return;
            case 'Add To Previous'
              poptions.mustuse = vs_use;  %force ipls to use these windows
            otherwise
              %start with nothing
          end
        case 'reverse'
          switch evriquestdlg('Should previouly selected intervals be removed or start a new selection?','Previous Selection Found','Remove From Previous','Start New','Cancel','Remove From Previous');
            case 'Cancel'
              return;
            case 'Remove From Previous'
              xblk.include{2} = intersect(xblk.include{2},vs_use);   %pre-exclude the ones already thrown away
            otherwise
              %start with only whatever is included in xblock
          end
      end
    end
    
    poptions.numintervals = str2num(get(handles.iplsintervals,'string'));
    if isempty(poptions.numintervals);
      poptions.numintervals = inf;
    end
    
    try
      xblk = missingdatacheck(xblk,cvlv);
      vs_results = ipls(xblk,yblk,int_width,cvlv,poptions);
      if isempty(vs_results)
        %User cancel.
        return
      end
      analysis('adopt',handles,vs_results.figh,'methodspecific');
      
      %create a description of the selected variables
      list = vs_results.use;
      
    catch
      myerr = lasterr;
      try
        %Try to delete waitbar if it's out there.
        delete(findobj(0,'tag','iplswaitbar'));
      end
      erdlgpls(['Error occured while trying to execute ipls:      ' myerr],'iPLS Error');
    end
  case 'rPLS - Recursive PLS'
    if strcmpi(curent_method,'mlr')
      %This is how it's done in iplsgui.
      poptions.algorithm = 'pls';
    end
    
    try
      set(handles.analysis,'pointer','watch')
      pause(.01);drawnow%Make sure pointer updated.
      
      rplsmodestr = get(handles.rplsmode,'string');
      rplsmodeval = get(handles.rplsmode,'value');
      rplsmode = rplsmodestr{rplsmodeval};
      
      rpsmaxiter = str2num(get(handles.rplsiter,'String'));
      %Store maxlv in options so can be used in crossval call in
      %update_plot.
      
      rplslv = cvlv;
      if ~isempty(strfind(rplsmode,'specified'))
        if ~isempty(get(handles.rplslvs,'String'))
          rplslv = str2num(get(handles.rplslvs,'String'));
          rflag = 0;
          if ~isint(rplslv)
            rflag = 1;
            rplslv = round(rplslv);
          end
          
          if rplslv<1
            rflag = 1;
            rplslv=1;
          end
          
          if rflag
            %Update field with repaired value.
            set(handles.rplslvs,'String',num2str(rplslv));
          end
          cvlv = rplslv;  % 'specified' uses user-specified #lvs
        else
          %Add value from CV.
          set(handles.rplslvs,'String',num2str(rplslv));
        end
        
      end
      
      poptions.display = 'off';
      poptions.mode = rplsmode;
      poptions.maxlv = rplslv;
      poptions.maxiter = rpsmaxiter;
      
    catch
      myerr = lasterr;
      if ishandle(handles.analysis)
        set(handles.analysis,'pointer','arrow');
      end
      erdlgpls(['Error occured while trying to execute rpls:      ' myerr],'rPLS Error');
      return
    end
    
    try
      xblk = missingdatacheck(xblk,cvlv);
      vs_results = rpls(xblk,yblk,cvlv,poptions);
      
      if ~isempty(vs_results)
        list = vs_results.selectedIdxs{vs_results.selected};
        if ~isempty(vs_results.figh)
          analysis('adopt',handles,vs_results.figh,'methodspecific');
        end
      end
      
    catch
      myerr = lasterr;
      if ishandle(handles.analysis)
        set(handles.analysis,'pointer','arrow');
      end
      erdlgpls(['Error occured while trying to execute rpls:      ' myerr],'rPLS Error');
    end
    set(handles.analysis,'pointer','arrow');
    
  case {'Automatic (VIP or sRatio)' 'VIP - Variable Importance in Projection' 'sRatio - Selectivity Ratio'}
    poptions.method = 'auto';
    poptions.plots = plotval;
    if strcmpi('sRatio - Selectivity Ratio', pname)
      poptions.method = 'sratios';
    elseif strcmpi('VIP - Variable Importance in Projection', pname)
      poptions.method = 'vip';
    end
    
    try
      fracrm = str2num(get(handles.svfractionrm,'string'));
      poptions.fractiontoremove = fracrm;
      %Store maxlv in options so can be used in crossval call in
      %update_plot.
      poptions.maxlv = cvlv;
      %frac2tst = str2num(get(handles.svfractionrm,'string'));
      xblk = missingdatacheck(xblk,cvlv);
      vs_results = selectvars(xblk,yblk,cvlv,poptions);
      if ~isempty(vs_results)
        %If not empty then should be results avaibale sometimes even if
        %user cancel before complete.
        list = vs_results.use;
        analysis('adopt',handles,vs_results.figh,'methodspecific');
      end
    catch
      myle = lasterr;
      evrierrordlg({['Error running: ' upper(poptions.method) ' method.'] ' ' myle},'Variable Selection Error');
      
    end
end

if ~isempty(myctrls)
  set(myctrls,'enable','on')
end

if ~isempty(list)
  %Store current results.
  myresults = getappdata(handles.analysis,'vs_allresults');
  myresults.(pshortname).list = list;
  myresults.(pshortname).options = poptions;
  myresults.(pshortname).vs_results = vs_results;
  setappdata(handles.analysis,'vs_allresults',myresults);
 
  %Save the raw index.
  setappdata(handles.analysis,'vs_use',list); 
  
  update_plot(handles);
end

% --------------------------------------------------------------------
function xblk = missingdatacheck(xblk,mylvs)
opt=mdcheck('options');
opt.max_pcs=mylvs;
[flag,missmap,xblk] = mdcheck(xblk,opt);

% --------------------------------------------------------------------
function update_plot(handles)
%Update plot based on xdata and selected vars if available.

handles = gethandles(handles);

xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);

[phandle, pname, pheight, poptions, pshortname] = getCurrentPanel(handles);

%Update saved info for given method.
myresults = getappdata(handles.analysis,'vs_allresults');
thisresult = [];
list = [];
if ~isempty(myresults)
  if isfield(myresults,pshortname) & ~isempty(myresults.(pshortname))
    thisresult = myresults.(pshortname);
    list = thisresult.list;%List of selected var index.
    options = thisresult.options;
  end
end

myax = handles.axes_varsused;

if isempty(xblk)
  set(myax,'tag','axes_varsused','XTickLabel','','YTickLabel','','ZTickLabel','','XTick',[],...
    'YTick',[],'ZTick',[],'XColor','black','YColor','white','ZColor','white')
  return
else
  %Add mean of data to plot.
  origXmean = mean(xblk.data);
  
  myaxscl = 1:size(xblk,2);
  if ~isempty(xblk.axisscale{2}) & ...
      ~any(diff(sign(diff(xblk.axisscale{2}))))%Can't use axis scale if it's not monotonic.
    myaxscl = xblk.axisscale{2};
    myaxscl = myaxscl(~isnan(myaxscl));
    %scale_half_step = mean(abs(diff(myaxscl)))/2;%Padding
    %if scale_half_step==0; scale_half_step = .5; end;
  end
  cla(myax);
  h = plot(myax,myaxscl,origXmean,'-k');
  set(myax,'YTickLabel','','YTick',[]);
  legendname(h,['Mean Sample']);
  axlim = axis(myax);
  %axis([min(myaxscl)-scale_half_step max(myaxscl)+halscale_half_stepf axlim(3:4)]);
end

if ~isempty(xblk) & ~isempty(list)
  axlist = myaxscl(list);
  %Add selected vars as bar plot.
  hold(myax,'on');
  h = bar(myax,axlist,origXmean(:,list),'g','edgecolor','none'); %bar(idx,mean(originaldsox.data(:,idx)));
  legendname(h,['Selected Variables']);
  hold(myax,'off');
end

if ~isempty(list)
  %Turn the use button on so user can add use to include field.
  set([handles.vsuse handles.vsshowlist],'enable','on');
  setappdata(handles.analysis,'vs_use',list);   
end
axis(myax,'tight')
set(myax,'tag','axes_varsused')

%Get cv results.
if ~isempty(xblk) & ~isempty(yblk) & ~isempty(list)
  cvopts = crossval('options');
  cvopts.display = 'off';
  cvopts.plots = 'none';
  cvopts.cvi   = options.cvi;
  cvopts.rm    = options.algorithm;
  cvopts.norecon  = 'true';
  cvopts.waitbartrigger = inf;
  cvopts.preprocessing = options.preprocessing;
  
  %1 = all variables.
  %2 = selected variables. 
  for i = 1:2
    %do initial "all variables" assessment (for reference line)
    %First value is best overall, and second is best of selected vars.
    if i ==1
      %Do crossval on full data.
      mymaxlv = min([options.maxlv length(xblk.includ{1}) length(xblk.includ{2})]);
      if mymaxlv>0
        res = crossval(xblk,yblk,cvopts.rm,cvopts.cvi, mymaxlv,cvopts);
      else
        error('Max LVs less than 1, crossval can''t be called.')
      end
    else
      %Crossval with selected variables.
      mymaxlv = min([options.maxlv length(list) length(intersect(xblk.include{2},list))]);
      if mymaxlv>0
        res = crossval(xblk(:,list),yblk,cvopts.rm,cvopts.cvi,min([options.maxlv length(list) length(intersect(xblk.include{2},list))]),cvopts);
      else
        %Should never get here because VS methods should not use data
        %outside included variables. 
        error('Max LVs less than 1, crossval can''t be called.')
      end
    end
    if islogical(yblk.data) & ~isempty(res.classerrcv)
      yunitslabel{i} = 'Missclassification rate';
      fullrmsecv = res.classerrcv;
    else
      yunitslabel{i} = 'RMSECV';
      fullrmsecv = res.rmsecv;
    end
    if length(yblk.include{2})>1 | size(fullrmsecv,1)>1
      %Deal with more than one y column. 
      fullrmsecv = rmse(fullrmsecv);
    end
    [bestfullrmsecv(i),bestfullnlvs(i)] = min(fullrmsecv);
    maxremsecv(i) = max(fullrmsecv);
  end
  
  %Scale values to data height (based on max rmse of all variables
  %maxremsecv(1)) and plot. Try average height of selected vars as best
  %fit.
  axlim = axis(myax);
  best_selected = mean(axlim(3:4))*(bestfullrmsecv(2)/(maxremsecv(1)));
  best_overall = mean(axlim(3:4))*(bestfullrmsecv(1)/(maxremsecv(1)));
  
  hold(myax,'on');
  
  h = plot(myax,axlim(1:2),[1 1]*best_selected,'b-');
  set(h,'linewidth',2);
  legendname(h,['Selected Variables (RMSECV:'  num2str(bestfullrmsecv(2),'%.3g') ')']);
  
  h = plot(myax,axlim(1:2),[1 1]*best_overall,'r-');
  set(h,'linewidth',2);
  legendname(h,['All Variables (RMSECV:'  num2str(bestfullrmsecv(1),'%.3g') ')']);
  
  set(myax,'tag','axes_varsused')
  
  mylgnd = legend(myax,'show');
  set(mylgnd,'FontSize',getdefaultfontsize);
  hold(myax,'off');
  
end


% --------------------------------------------------------------------
function vsuse_Callback(hObject, eventdata, handles)
%Click "use" button and add vars to include field.

%Gather needed inputs.
xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);

vsuse = getappdata(handles.analysis,'vs_use');

%Get include info.
xincld = getappdata(handles.analysis,'vs_originalInclude_x');
oinclude = xblk.include{2};

try
  xblk.include{2} = vsuse;
  crossval_figure = getappdata(handles.analysis);
  cvv = getappdata(crossval_figure.crossvalgui);
  crossval_settings = cvv.cvsettings;
  analysis('setobjdata','xblock',handles,xblk);
  
  %Insure that the CV settings have not been reset when clicking 'use'
  setappdata(crossval_figure.crossvalgui,'cvsettings',crossval_settings);
  if strcmpi(crossval_settings.cv,'custom')
    %Set the cvsets appdata for custom.
    setappdata(crossval_figure.crossvalgui,'cvsets',crossval_settings.split);
  end
  crossvalgui('resetfigure',crossval_figure.crossvalgui);
  
  %Set orginal include here otherwise it gets cleared in update callback above.
  if isempty(xincld)
    setappdata(handles.analysis,'vs_originalInclude_x',oinclude);
  end
  
  %Set flag for mod date on both blocks.
  setappdata(handles.analysis,'vs_xmoddate',xblk.moddate);
  if ~isempty(yblk)
    setappdata(handles.analysis,'vs_ymoddate',yblk.moddate);
  end
  evrihelpdlg('Current variables set to those selected.','Use Selected Variables');
  
  panelupdate_Callback(handles.analysis, [], []);
catch
  error('Unable to asign selection results to current xblock.');
end

% --------------------------------------------------------------------
function iplsintervals_iplsmode_Callback(hObject, eventdata, handles)

myval = get(handles.iplsmode,'value');
if myval == 1
  set(handles.iplsmustuse,'enable','on');
else
  set(handles.iplsmustuse,'enable','off');
end

% --------------------------------------------------------------------
function iplsintervals_auto_Callback(hObject, eventdata, handles)

handles = gethandles(handles);

if get(handles.iplsintervals_auto,'value')==1
  set(handles.iplsintervals,'String','auto');
  set(handles.iplsintervals,'enable','off');
else
  if isempty(str2num(get(handles.iplsintervals,'String')))
    set(handles.iplsintervals,'String','1');
  end
  set(handles.iplsintervals,'enable','on');
end

% --------------------------------------------------------------------
function iplsstepsize_auto_Callback(hObject, eventdata, handles)

handles = gethandles(handles);

if get(handles.iplsstepsize_auto,'value')==1
  set(handles.iplsstepsize,'String','auto');
  set(handles.iplsstepsize,'enable','off');
else
  if isempty(str2num(get(handles.iplsstepsize,'String')))
    set(handles.iplsstepsize,'String','1');
  end
  set(handles.iplsstepsize,'enable','on');
end

% --------------------------------------------------------------------
function windowwidth_Callback(hObject, eventdata, handles)
%Update current width.
ww = round(get(handles.windowwidth,'Val'));
set(handles.windowwidthtext,'String',num2str(ww));

% --------------------------------------------------------------------
function sx = scale2one(x)
%Scale data to 0-1 for background image.
m       = size(x,1);
minx    = min(x);
rangx   = max(x) - minx;
rangx(rangx==0) = 1;
sx = 30*(x + minx(ones(m,1),:))./rangx(ones(m,1),:);

% --------------------------------------------------------------------
function gafig = openinga_Callback(handles,forceGA)
% Open genalg window but don't make visible.

gafig = [];
xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);

obj = evrigui(handles.analysis);
cvi = obj.getCrossvalidation;
[cvmode,cvlv,cvsplit,cviter] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));

if strcmpi(getappdata(handles.analysis,'curanal'),'plsda') & ~isempty(yblk) & ~islogical(yblk.data)
  yblk = class2logical(yblk.data);
end
  
if strcmpi(getappdata(handles.analysis,'curanal'),'plsda') & isempty(yblk) & ~isempty(xblk)
  model = analysis('getobjdata','model',handles);
  if isempty(model);
    %Originally a model was automatically calculated but this code is run
    %on initialize which causes model to be calculated when switching
    %methods. This is unexpected so just retrun instead.
    return
%     try
%       analysis('calcmodel_Callback',handles.analysis,[],handles);
%       model = analysis('getobjdata','model',handles);
%     catch
%       %do nothing - model will still be empty so error below will be thrown
%     end
  end
  if isempty(model);
    %probably had a problem calculating the model or trapped above
    erdlgpls('A PLSDA model must first be calculated with this data but something went wrong when calculating the model. Click the model icon to solve the problem and build a model, then re-execute.','No Model Present');
    return
  end
  yblk = model.detail.data{2};
end

if isempty(xblk) | isempty(yblk)
  return
end

gafig = getappdata(handles.analysis,'varselect_genalgfigure');
if forceGA & ~isempty(gafig) & ishandle(gafig)
  delete(gafig);
end

if isempty(gafig) | ~ishandle(gafig)
  gafig = genalg(xblk,yblk,struct('show_figure_on_start','no'));
  set(gafig,'visible','off');
  setappdata(handles.analysis,'varselect_genalgfigure',gafig);
  analysis('adopt',handles,gafig,'methodspecific');
  setappdata(gafig,'control_mode',1);%Tell GA window not to check for saving of model.
  gahandles = guihandles(gafig);
  setappdata(gafig,'analysis_parent',handles.analysis);%Add reference for parent so can update panel with changes made on ga window.
  
  handles = gethandles(handles);
  
  %Get window width from GA window.
  myww = get(gahandles.windowwidth,'Value');
  set(handles.windowwidthmin,'String','1');
  set(handles.windowwidthmax,'String',get(handles.windowwidthmax,'String'));
  set(handles.gawindowwidth,'Value',myww,'min',1,'max',str2num(get(gahandles.windowwidthmax,'String')));
  set(handles.gawindowwidthtext,'String',num2str(myww));
  
  %Get crossval LVs from GA window.
  mylvs = get(gahandles.lvs,'Value');
  set(handles.lvsmin,'String','1');
  set(handles.lvsmax,'String',get(gahandles.lvsmax,'String'));
  set(handles.galvs,'Value',mylvs,'min',1,'max',str2num(get(gahandles.lvsmax,'String')));
  set(handles.galvstext,'String',num2str(mylvs));
  
  %Get crossval splits from GA window.
  myss = get(gahandles.subsets,'Value');
  set(handles.subsetsmin,'String','2');
  set(handles.subsetsmax,'String',get(gahandles.subsetsmax,'String'));
  set(handles.galvs,'Value',myss,'min',2,'max',str2num(get(gahandles.subsetsmax,'String')));
  set(handles.gasubsetstext,'String',num2str(myss));
  switch obj.getMethod
    case 'mlr'
      genalg('mlr',gafig);
    otherwise
      genalg('pls',gafig);
  end
  
  if ~isempty(cvmode) & ~strcmpi(cvmode,'none')
    %Push CV settings from CV window to GA.
    set(gahandles.subsets,'value',cvsplit);
    genalg('actsubsets',gafig);
    set(handles.galvs,'Value',cvsplit,'min',2,'max',str2num(get(gahandles.subsetsmax,'String')));
    set(handles.gasubsetstext,'String',num2str(cvsplit));
    
    %Genalg has max LVs hardcoded to 25 (around line 204) so don't let cvlv
    %be greater than 25 or slider will throw warning and won't render.
    if cvlv>25
      cvlv = 25;
    end
    set(gahandles.lvs,'value',cvlv);
    genalg('actlvs',gafig,cvlv);
    set(handles.galvs,'Value',cvlv,'min',1,'max',str2num(get(gahandles.lvsmax,'String')));
    set(handles.galvstext,'String',num2str(cvlv));
    
    switch cvmode
      case 'rnd'
        genalg('random',gafig);
        gapanel_Callback(handles.garandom, [], handles)
      otherwise
        genalg('contiguous',gafig);
        gapanel_Callback(handles.gacontiguous, [], handles)
    end
  end
  
else
  return
end

genalg('preproxblk',gafig,obj.getXPreprocessing);
genalg('preproyblk',gafig,obj.getYPreprocessing);


% --------------------------------------------------------------------
function gaopen_Callback(hObject, eventdata, handles, myvis)
%Open current GA window (make if visible).
if nargin<4
  myvis = [];
end

xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);

if strcmpi(getappdata(handles.analysis,'curanal'),'plsda') & isempty(yblk) & ~isempty(xblk)
  model = analysis('getobjdata','model',handles);
  if isempty(model);
    %Comment this out for now (12/3/2018), causing confusion for Rasmus. 
    %evriwarndlg('A PLSDA model must first be calculated with this data but something went wrong when calculating the model. Click the model icon to solve the problem and build a model, then re-execute.','No Model Present')
    return
  end
end

if ~isempty(myvis)
  set(getGAFig(handles),'visible',myvis)
else
  myvis = get(getGAFig(handles),'visible');
  %Toggle
  if strcmpi(myvis,'on')
    set(getGAFig(handles),'visible','off')
  else
    set(getGAFig(handles),'visible','on')
  end
end

% --------------------------------------------------------------------
function gapause_Callback(hObject, eventdata, handles)
%Pause current GA run.

gafig = getGAFig(handles);
genalg('stop',gafig);
vsexecute_Callback(hObject, eventdata, handles, 1)
% --------------------------------------------------------------------
function gafig = getGAFig(handles)
%Get current GA fig. Create if not available.

gafig = getappdata(handles.analysis,'varselect_genalgfigure');
if isempty(gafig) | ~ishandle(gafig)
  gafig = openinga_Callback(handles,0);
end

% --------------------------------------------------------------------
function gapanel_Callback(hObject, eventdata, handles)
%Change GA crossval method.

gafig = getGAFig(handles);
if isempty(gafig)
  %No data yet so won't open.
  return
end
handles = gethandles(handles);
gahandles = guihandles(gafig);

mybutton = get(hObject,'tag');

slval = [];%slider value.
if strcmpi('slider',get(hObject,'style'))
  slval = get(hObject,'value');
  slval = round(slval);
end

switch mybutton
  case 'garandom'
    set(handles.garandom,'Value',1);
    set(handles.gacontiguous,'Value',0);
    genalg('random',gafig);
  case 'gacontiguous'
    set(handles.garandom,'Value',0);
    set(handles.gacontiguous,'Value',1);
    genalg('contiguous',gafig);
  case 'gawindowwidth'
    %Update panel.
    set(handles.gawindowwidthtext,'String',num2str(slval))
    
    %Update GA figure.
    set(gahandles.windowwidth,'Value',slval);
    set(gahandles.windowwidthtext,'String',num2str(slval))
  case 'galvs'
    %Update panel.
    set(handles.galvstext,'String',num2str(slval))
    
    %Update GA figure.
    set(gahandles.lvs,'Value',slval);
    set(gahandles.lvstext,'String',num2str(slval))
  case 'gasubsets'
    %Update panel.
    set(handles.gasubsetstext,'String',num2str(slval))
    
    %Update GA figure.
    set(gahandles.subsets,'Value',slval);
    set(gahandles.subsetstext,'String',num2str(slval))
end


% --------------------------------------------------------------------
function rplsmode_Callback(hObject, eventdata, handles)
% Selection of RPLS method, enable number of LVs.

panelupdate_Callback(handles.analysis, [], []);

% --------------------------------------------------------------------
function vsshowlist_Callback(hObject, eventdata, handles)
%Show list of selected variables in info box. 

xblk = analysis('getobjdata','xblock',handles);
mylist = getappdata(handles.analysis,'vs_use');

if isempty(mylist)
  return
end

if ~isempty(xblk) & ~isempty(xblk.axisscale{2})
  mylist = xblk.axisscale{2}(mylist);
end

listtxt = encode(mylist,'');
listtxt = textwrap({listtxt},45);

infofig = infobox(listtxt,struct('figurename','Selected Variables','fontsize',getdefaultfontsize));

analysis('adopt',handles,infofig,'methodspecific');

% --------------------------------------------------------------------
function handles = gethandles(handles)
%Get handles and keep copy to help performance. 

if ~isfield(handles,'iplsintervals_auto') | ~ishandle(handles.iplsintervals_auto)
  %Refresh.
  handles = guihandles(handles.analysis);
end

% --------------------------------------------------------------------
function pushbutton8_Callback(hObject, eventdata, handles)
%Open help page.

evrihelp('variableselectiongui')
