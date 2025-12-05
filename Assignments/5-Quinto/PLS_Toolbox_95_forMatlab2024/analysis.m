function varargout = analysis(varargin)
%ANALYSIS Graphical user interface for data analysis.
%  Performs various analysis methods using a graphical user
%  interface. Data can be loaded from the workspace into the tool through the
%  File menu and viewed/edited with the Edit menu. Analysis method is
%  selected in the Analysis menu. Preprocessing can be set in the
%  Preprocessing menu and cross-validation options can be set
%  through the Tools menu. The "Calc" button calculates a model.
%  Eigenvalues/cross-validation, scores, loadings, biplots and raw
%  data can be viewed by clicking on the appropriate buttons.
%  Models can be saved and loaded through the File menu.
%  Previous models can thus be applied to new data.
%
%I/O: analysis
%
%See also: BROWSE, CLUSTER, MCR, PARAFAC, PCA, PCR, PLS

%Copyright © Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%rsk 04/04  Initial coding from PCA.
%rsk 05/05/04 Make pp custom only for ndims>2 data.
%rsk 06/08/04 Add warn dialog where model clear automatically.
%jms 08/09/04 fix status window display on startup
%rsk 08/09/04 disable crossval when one column being used.
%rsk 09/20/04 Add image loading for MIA Toolbox.
%jms 11/29/04 Fix Java Exception problem on close (7.0.1)
%rsk 05/04/05 Change image size display to one row.
%rsk 11/23/05 Add options gui code.
%rsk 02/03/06 add context menu code for model/data status.
%rsk 02/16/06 add help window,
%rsk 05/09/06 Add parafac optionsgui support.
%bk 05/27/2016 Fixed crossval window issue on high res screens.

if nargin == 0  % LAUNCH GUI

  if ~exist('isdeployed') | ~isdeployed | ~isempty(findall(0,'type','figure'))
    %unless this is deployed and is the FIRST figure to be opened, give waitbar
    h=waitbar(0,['Starting ' upper(mfilename) '...']);
    set(h,'userdata','analysis_startup_waitbar');
    drawnow
    tmr = updatewaitbar(h);
  else
    h = [];
    tmr = [];
  end
  try
    fig = [];
    fig = openfig(mfilename,'new');
    figbrowser('addmenu',fig); %add figbrowser link

    handles = guihandles(fig);	%structure of handles to pass to callbacks
    guidata(fig, handles);      %store it.
    gui_init(fig)            %add additional fields
    set(fig,'visible','on')
  catch
    erdlgpls({'Unable to start the Analysis GUI' lasterr},[upper(mfilename) ' Error']);
    if ishandle(fig); delete(fig); end
  end
  if ishandle(h); close(h); end
  try; stop(tmr); catch; end
  delete(tmr);

  if nargout > 0
    varargout{1} = fig;
  end
  if ~ishandle(fig); 
    %load failed - exit now
    return
  end

  evritip('analysis');

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
  if strcmp(getappdata(0,'debug'),'on');
    dbstop if all error
  end

  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = [];
        options.maximumfactors  = 20;
        options.displayhelp     = 'on';
        options.displaystatusinfobox = 'on';
        options.quickopenprepro = 'off';
        options.flowchart       = 'show';
        options.clutterbutton   = 'show';
        options.predictionblock = 'show';
        options.defaultcacheview = 'date';
        options.autoselectcomp  = 'on';
        options.autoexclude     = 'off';
        options.filternwayprepro = 'on';
        options.panelselector   = 'buttons';
        options.defaultxpreprocessing = 'autoscale';
        options.defaultypreprocessing = 'autoscale';
        options.defaultimportmethod = 'prompt';
        options.defaultcv       = 'vet';
        options.showcalwithtest = 'off';
        options.showerrorbars   = false;
        options.showautoclassscores = false;
        options.splitclassedvars = true;
        options.showyinbiplot   = true;
        options.showpanel       = {};
        options.hidepanel       = {};
        options.reducedstats    = 'both';
        options.pushclasses     = 'on';
        options.cachewidth      = .85; %percent of space given to modelcache viewer after minimumns are met.
        if ispc
          options.ssqfontsize   = 10;
        else
          options.ssqfontsize   = 12;
        end
        options.definitions     = @optiondefs;
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
      otherwise
        if nargin==1 & ~strcmp(varargin{1},'savestatus')
          %try auto-starting with given method enabled
          methods = analysistypes;
          methods = lower(methods(:,1:2));
          if ismember(char(varargin{1}),methods);         %check for valid tag or symbol
            h = analysis;
            try
              enable_method(h,[],guidata(h),varargin{1})
            catch
              erdlgpls('Unable to intialize for given method','Analysis')
            end
          else
            erdlgpls('Unrecognized Analysis Method Name','Analysis')
          end
          if nargout>0;
            varargout = {h};
          end
        elseif nargout == 0;
          %normal calls with a function
          hidestatusinfobox;
          feval(varargin{:}); % FEVAL switchyard
        else
          [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
        end
    end
  catch
    if ~isempty(gcbf);
      pointer(gcbf,'arrow');  %no "handles" exist here so try setting callback figure
    end
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end

end

%FUNCTIONS/CALLBACKS
% --------------------------------------------------------------------
function gui_init(h)

%Initialize the analysis, helper GUIs, and get Preferences
handles              = guidata(h);

set(handles.analysis,'closerequestfcn',['try;' get(handles.analysis,'closerequestfcn') ';catch;delete(gcbf);end'])

opts = analysis('options');
% none - no model 
% calold - model has been calculated ('calold' is used right after a model is calculated).
% calnew - new PCs for existing model, need to recalculated (model icon has exclamation mark) 
% loaded - model is calculated but cal data is not available so no changes can be made.  
setappdata(handles.analysis,'statmodl','none') %'none','calold','calnew','loaded'

setappdata(handles.analysis,'apply_only',0)  %default is off unless one of these addons turn it on later

%Turn off viewer here so it doesn't get rendered in resize callback before
%figure is visible because of bug in 2008b.
setappdata(handles.analysis,'showcacheviewer',0);

%set figure to appropriate position
set(h,'units','pixels');
set(0,'units','pixels');

%default position.
figpos = get(h,'position');
screensize = getscreensize;
figpos(2) = screensize(4)-figpos(4)-50;
set(h,'position',figpos);

%turn flowchart on or off (based on last saved position
flowchart_callback(handles,'hide')
%get last figure position (stored previously)
positionmanager(h,'analysis')
centerfigure(h);

%Add status image.
statusimage(handles);

%Add new table.
delete(handles.ssqtable)
%Row header width of 1 to hide default row numbers. Will use spoofed column
%for # of PCs.
mytbl = etable('parent_figure',h,'tag','ssqtable','autoresize','AUTO_RESIZE_SUBSEQUENT_COLUMNS',...
  'custom_cell_renderer','on','cell_click_selection','row','column_sort','off','row_multiselection','off');
mytbl.grid_color = [.9 .9 .9];%Grid color is light grey.
mytbl.row_header_width = 70;
mytbl.editable = 'off';%Don't allow edits on ssqtable.
handles = guihandles(h);

%Add drag drop handler.
try
  analysisdnd = evrijavaobjectedt(DropTargetList);%EVRI Custom drop target class.
catch
  le = lasterror;
  if ~isempty(strfind(le.message,'DropTargetList'))
    error('Missing Java object (DropTargetList). Please RESTART Matlab and try again.')
  end
  rethrow(le)
end
analysisdnd = handle(analysisdnd,'CallbackProperties');
jFrame = get(handle(handles.analysis),'JavaFrame');
%Don't think we need to run on EDT but if the need arises be sure to
%accommodate 7.0.4. 
jAxis  = jFrame.getAxisComponent;
jAxis.setDropTarget(analysisdnd);
set(analysisdnd,'DropCallback',{@dropCallbackFcn,handles.analysis});
%set(analysisdnd,'DragOverCallback',{@dragOverCallbackFcn,fig,'wstree'});%Disable drag over other parts of figure.

%Add window button motion callback to display infobox for stauts image
%icons.
set(h,'WindowButtonMotionFcn',@windowbuttonmotion_Callback)

%Initiate CrossValGUI (before first resize call because code looks for cv
%settings).
cvgui = crossvalgui(handles.analysis); %initiate cross-validation gui
crossvalgui('interactive',cvgui,'off');  %hide interactive buttons
crossvalgui('disable',cvgui);  %disable all items
setappdata(cvgui,'crossvalchangecallback','analysis(''crossvalchange'',gcbf)')
setappdata(handles.analysis,'crossvalgui',cvgui);

% This part helps address the issues on screens > 2K.
sSize= getscreensize('pixels');
if ((sSize(3) <= 2048) || (sSize(4) <= 1080))
  setpos(cvgui,'left',getpos(h,'right')+5);
  setpos(cvgui,'top',getpos(h,'top')-1);
  positionmanager(cvgui,'crossvalgui','onscreen');
else
  setpos(cvgui,'top',getpos(h,'top'));
  setpos(cvgui,'left',getpos(h,'right'));
end



%Enable whether crossvalgui can be displayed. This setting is used within
%crossvalgui.m as well as in analysis.m. Set this in the gui_init and
%gui_deslect functions of the method_guifcn.m file. Default setting is on
%which will allow gui to be shown, existing code will enable disable the
%controls.
setappdata(handles.analysis,'enable_crossvalgui','on');

if ~isempty(opts.defaultcv)
  try
  	crossvalgui('forcesettings',cvgui,opts.defaultcv);
    
    % Clamp crossval gui within screen resolution
    cpos = get(cvgui,'Position');
    mpos      = getscreensize('pixels');
    % Check if crossval gui's position needs adjusting
    if ((mpos(3) > 2048) || (mpos(4) > 1080))
      mpos(3:4)=mpos(3:4)*0.4;
    end
    if(cpos(1)+ cpos(3) > mpos(3))
      cpos(1) = mpos(3) - cpos(3) - (0.15*mpos(3));
      %setpos(cvgui,'left',cpos(1));
    end
    if(cpos(2)+ cpos(4) > mpos(4))
      cpos(2) = mpos(4) - cpos(4) - (0.15*mpos(4));
      %setpos(cvgui,'top',cpos(2));
    end
    positionmanager(cvgui,'crossvalgui','onscreen');
    set(cvgui,'position',cpos);
  catch
    %couldn't use setting for some reason - skip it for now
  end
end

set(h,'resizefcn','analysis(''resize_callback'',gcbf,[],guidata(gcbf))')
toolbar(handles.analysis, 'help','');
resize_callback(h,[],handles);

%Default font size in Mac is 10 and looks too small for ssq fixed width
%font so up the size to default ssq size (set in options).
set(handles.tableheader,'Fontsize',opts.ssqfontsize);
%set(handles.ssqtable,'Fontsize',opts.ssqfontsize);
set(handles.helpwindow,'Fontsize',opts.ssqfontsize);
if ~ispc
  set(handles.tableheader,'FontName','FixedWidth')
end

drawnow;

%prep data and callbacks
setobjdata('xblock',handles,[]);          %raw x-block that has not been preprocessed
setobjdata('yblock',handles,[]);          %raw y-block that has not been preprocessed

%prep other properties
setappdata(handles.analysis,'preprocesscatalog',{})    %preprocess catalog, one cell per mode. 
setappdata(handles.preprocessmain,'preprocessing',[])  %x-block preprocessing structure in preprocess submenu control
setappdata(handles.preproyblkmain,'preprocessing',[])  %y-block preprocessing structure in preprocess submenu control
setappdata(handles.analysis,'autoclearwarn',[])        %Warning status for auto-clear of model.
setappdata(handles.analysis,'loadbothwarn',[])         %Warning for clearing both x and y blocks during loadboth.
setappdata(handles.analysis,'analysisoptions',[])      %options structure for given analysis.
setappdata(handles.analysis,'analysisoptions_history',[]);  %options history
setappdata(handles.analysis,'optionsedit',1)           %[0 1] edit options enable/disable.
setappdata(handles.analysis,'panel_defaults',{'asca' 2; 'mlsca' 2; 'lwr' 2}) %Use second (settings) panel for asca, mlsca, and lwr.

if strcmp(opts.displayhelp,'on')
  setappdata(handles.analysis,'displayhelp',1)
else
  setappdata(handles.analysis,'displayhelp',0)
end

if strcmp(opts.displaystatusinfobox,'on')
  setappdata(handles.analysis,'displaystatusinfobox',1);
else
  setappdata(handles.analysis,'displaystatusinfobox',0);
end

set(handles.loadmodel,'UserData',[]) %clear holding userdatas
set(handles.loadxdata,'UserData',[])  %clear holding userdatas
set(handles.loadydata,'UserData',[])  %clear holding userdatas
setobjdata('prediction',handles,[]);

%initialize model
clearall(h, [], guidata(handles.analysis))

%Initialize panel selection.
set(handles.panelviewselect,'String',' ','enable','off');

%Add preprocess catalog.
setappdata(handles.analysis,'preprocesscatalog',{preprocess('initcatalog') preprocess('initcatalog')})

%Initiate preprocess
opts = preprodefault(handles, opts);

%Set static plot children.
setappdata(handles.analysis, 'staticchildplot',[])

%Initialize menus since dynamic menus don't work in 2011a Mac.
analysismenubuild(h, [], handles, [])
filemenubuild(h, [], handles, [])

%Hide unused/special menu items
set(handles.showcalwithtest,'visible','off','checked',opts.showcalwithtest)
set(handles.analysispref,'visible','off')

%set up initial view of controls
set([handles.pcseditlabel handles.ssqtable handles.pcsedit],'visible','off')
set(handles.tableheader,'string', {'Load Data and Select Method from Analysis Menu'},'horizontalalignment','center')

%make sure curanal is character
setappdata(handles.analysis,'curanal',char(getappdata(handles.analysis,'curanal')))

resize_callback(h,[],handles);

%change the name of the "factors" in the crossvalidate GUI
crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'PCs');

%Set up SSQ Table area objects.
%change pc edit label.
set(handles.pcseditlabel,'string','')
%Note: both appdata and visible for findcomp have to be managaed by _guifcn
%init and deselect functions. We may want to push this behavior into panel
%manager in the future. 
setappdata(handles.analysis,'autoselect_visible',0)
set(handles.findcomp,'visible','off')

setappdata(handles.analysis,'noyprepro',0);

%If only ssq table is to be visible (with ASCA etc).
setappdata(handles.analysis,'ssqonly_visible',0)

%get list of transform options
sh = browse_shortcuts([]);
sh = sh(ismember({sh.type},{'other','transform'}));
sh = sh(~cellfun('isempty',{sh.nargout}));
sh = sh([sh.nargout]>0);
sh = sh(~ismember({sh.fn},{'preprocess'}));
rnn_loc = find(ismember({sh.fn},{'reducennsamples'}));
if length(rnn_loc)>1
  sh(rnn_loc(2:end)) = [];
end
set(handles.status_data_transform,'callback','','userdata',sh); %store all shortcuts in userdata

%if stand-alone, change help labels to "Solo" (or whatever is appropriate)
if exist('isdeployed') & isdeployed;
  [ver,prodname] = evrirelease;
  ch = findobj(handles.analysis,'type','uimenu'); 
  set(ch,{'label'},strrep(get(ch,'label'),'PLS_Toolbox',prodname))
end

%update flowchart (if needed and requested)
handles = guidata(h);

flowchart_callback(handles,opts.flowchart);

%make analysis have focus
figure(handles.analysis)
figbrowser on

%Figure out if cache viewer can be displayed.
%Set appdata for showcacheviewer here so it's easily accessible from
%elsewhere.
set(h,'visible','on')%Set visible on here because bug in 2008b doesn't allow java object size to be retrieved when visible off.
h = findobj(allchild(0),'userdata','analysis_startup_waitbar');
if ~isempty(h); figure(h); end
%if getmlversion('long')<7.01 | ~exist('evritreefcn','file')
if checkmlversion('<','7.01') | ~exist('evritreefcn','file')
  setappdata(handles.analysis,'showcacheviewer',0);
  setappdata(handles.analysis,'cacheview','hide');
  setplspref('analysis','defaultcacheview','hide');
else
  setappdata(handles.analysis,'showcacheviewer',1)
  %Grab current pref for cache view.
  setappdata(handles.analysis,'cacheview',opts.defaultcacheview);
  
  %Run menu callback to place viewer on figure if needed.
  cachemenu_callback(handles.analysis, [], handles, [])
  
  %Need to add a windowbuttondownfcn to figure so CurrentPoint get's
  %updated so drag and drop from cache can work correctly.
  
end
resize_callback(handles.analysis,[],handles);

%call add-on post gui init functions
fns = evriaddon('analysis_post_gui_init');
for j=1:length(fns)
  feval(fns{j},handles.analysis);
end

% --------------------------------------------------------------------
function enable_method(h,eventdata,handles,varargin)
% Enables a method selected from the analysis menu or forced through input
% TO FORCE AN ANALYSIS METHOD: pass the appropriate tag name (should be the
% same as the modeltype) as the 4th input:
%    enable_method(h,[],handles,'pca')

if nargin==3;
  newtag = get(h,'tag');
  forcenewtag = false;
else
  newtag = lower(varargin{1});
  forcenewtag = true;  %don't test if this is a new method (forces update)
end
oldtag = getappdata(handles.analysis,'curanal');

if forcenewtag | ~strcmp(newtag,oldtag)  %if the user actually selected a NEW analysis method

  %check if the model type is supported
  if isempty(analysistypes(newtag))
    erdlgpls('Model type not supported by Analysis GUI','Model Type Not Supported')
    return
  end
  
  %confirm clear model if any is there
  savedtimestamp = getappdata(handles.savemodel,'timestamp');
  modl           = getobjdata('model',handles);
  if ~isempty(modl) & ~strcmp(lower(modl.modeltype),newtag)
    if ~modelsaved(handles);
      ans=evriquestdlg('Model not saved. What do you want to do?', ...
        'Model Not Saved','Clear Without Saving','Save & Clear','Cancel','Clear Without Saving');
      switch ans
        case {'Cancel'}
          return
        case {'Save & Clear'}
          if isempty(savemodel(handles.savemodel, [], handles, []))
            return
          end
      end
    end
    clearmodel(handles.analysis, [], handles, 1)
  end
  
  %Close method specific plots.
  h = getappdata(handles.analysis,'methodspecific');
  close(h(ishandle(h)));
  setappdata(handles.analysis,'methodpecific',[]);


  %doing any "deselection" steps for current analysis method
  fn  = analysistypes(oldtag,3);
  if ~isempty(fn);
    try
      feval(fn,'gui_deselect',h,eventdata,handles,varargin);
    catch
      %Currently NOT doing anything - just try moving on
      %       erdlgpls(lasterr,'Error Changing Modes');
    end
  else
    %default "deselection" steps
    set([handles.tableheader handles.pcseditlabel handles.ssqtable handles.pcsedit],'visible','on')
    set(handles.tableheader,'string', { '' },'horizontalalignment','left')
  end
  
  %Delete options if analysis has changed. Set new options before panel
  %update (via gui_init) because some panels rely on options.
  opts = getappdata(handles.analysis, 'analysisoptions');
  if ~isfield(opts,'functionname') | ~strcmp(opts.functionname, newtag)
    opts = getoptshistory(handles,newtag);  %get previous or empty options
    if isempty(opts)
      %Get default options.
      opts = feval(newtag, 'options');      
    end
    setappdata(handles.analysis, 'analysisoptions',opts);
  end
  
  %do initialization for new mode
  setappdata(handles.analysis,'curanal',newtag);
  fn  = analysistypes(newtag,3);
  if ~isempty(fn);
    try
      feval(fn,'gui_init',handles.analysis,[],handles,oldtag);
    catch
      erdlgpls('Unable to initialize for the given analysis mode','Set Analysis Mode Failed');
      if ~strcmpi(oldtag,newtag);
        setappdata(handles.analysis,'curanal',oldtag);
        enable_method(h,[],handles,oldtag)
      end
      return;
    end
  end
  
  fns = evriaddon('analysis_enable_method');
  for j=1:length(fns)
    feval(fns{j},handles.analysis,[],handles,newtag,oldtag);
  end
  
  if ~cvguienabled(handles)
     set(getappdata(handles.analysis,'crossvalgui'),'Visible','off')
  end    
  
end
updatepreprocatalog(handles)
updatecrossvallimits(handles)%Some methods modify crossval gui.
%force resize of GUI (adjust for lables changes)
resize_callback(handles.analysis,[],handles);
%Update panel selection
panelupdate(h, eventdata, handles)

if ~strcmpi(getappdata(handles.analysis,'curanal'),'clsti')
  %enable menus if not the CLSTI Analysis interface
  %these get disabled in clsti_guifcn.m
  %these menu items are not applicable for clsti models
  set(handles.preprocess,'enable','on');
  set(handles.refine,'enable','on');
  set(handles.tools,'enable','on');
end

%Get panel default.
panel_default = getappdata(handles.analysis,'panel_defaults');
pidx = ismember(panel_default(:,1),newtag);
if any(pidx)
  %Not SSQ.
  panelviewselect_Callback(h, eventdata, handles,panel_default{pidx,2})
else
  %SSQ
  panelviewselect_Callback(h, eventdata, handles)
end

% --------------------------------------------------------------------
function out = isdatavalid(handles)

%give warning if data doesn't match method selected
%Construct x block profile.
x = getobjdata('xblock',handles);
xprofile = varprofile(x);

%Construct y block profile.
y = getobjdata('yblock',handles);
yprofile = varprofile(y);

fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
out = exist(fn,'file') & feval(fn,'isdatavalid',xprofile,yprofile,handles.analysis);

% --------------------------------------------------------------------
function showcalwithtest(h,eventdata,handles, varargin)
%Menu Show Cal with Test CallBack
switch get(handles.showcalwithtest,'Checked')
  case 'on'
    set(handles.showcalwithtest,'Checked','off')
  case 'off'
    set(handles.showcalwithtest,'Checked','on')
end
fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
if ~isempty(fn);
  feval(fn,'updatefigures',handles.analysis);
end

% --------------------------------------------------------------------
function truebiplot(h,eventdata,handles, varargin)
%True Biplot checkbox CallBack
fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
if ~isempty(fn);
  pca_guifcn('biplot_Callback',handles.analysis,[],handles);
  %   feval(fn,'updatefigures',handles.analysis);
end

% --------------------------------------------------------------------
function pcsedit_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.pcsedit.
% Selects number of PCs in the editable text box.
% Appdata field 'defualt' holds number of components.

fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
if ~isempty(fn);
  feval(fn,'pcsedit_Callback',handles.analysis,[],handles);
end
toolbarupdate(handles)
% --------------------------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.

if strcmp(get(handles.analysis,'selectiontype'),'open') & ~strcmp(getappdata(handles.analysis,'statmodl'),'loaded')
  set(handles.analysis,'selectiontype','normal');
  calcmodel_Callback(h, [], handles);
  return
end

fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
if ~isempty(fn);
  feval(fn,'ssqtable_Callback',handles.analysis,[],handles);
end
toolbarupdate(handles)

% --------------------------------------------------------------------
function updatessqtable_Callback(h, eventdata, handles, varargin)
%Update data in ssq table.
% 
%Two types of updates, with and without model caching.

fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
gfoptions = feval(fn,'options');
modl = getobjdata('model',handles);
pcs = getappdata(handles.pcsedit,'default');
mytbl = getappdata(handles.analysis,'ssqtable');

%Add auto select button enable here becuase this function is called by
%analysis every time data is changed. May or may not be visible.
if ~analysis('isloaded','xblock',handles);
  set(handles.findcomp,'enable','off')
else
  set(handles.findcomp,'enable','on')
end

if isempty(pcs)
  %Put a value in if one missing.
  pcs = 1;
  setappdata(handles.pcsedit,'default',pcs)
end

%Find max length of table.
maxoption = gfoptions.maximumfactors;
curlentable = mytbl.rowcount;
maxpc = max([maxoption, curlentable, pcs]);

mycols = 3;%Standard is 3 numeric columns plus status.
if ismember(fn,'reg')
  mycols = 4;
end

%Build table of "-" with empty col at end.
newtbl = nan(maxpc,mycols);
newtbl = num2cell(newtbl);
newtbl = [newtbl repmat({' '},maxpc,1)];

if isempty(modl)
  %Update table data.
  mytbl.data = newtbl;
  %Make selection the current PC.
  setselection(mytbl,'rows',pcs);
  set(handles.pcsedit,'String','','Enable','inactive');%TODO: CHECK THIS
  return
end

%TODO: Check this.
if isempty(rawmodl)
  rawmodl = modl;
end



% --------------------------------------------------------------------
function panelupdate(h, eventdata, handles, varargin)
% Update panelselect dropdown to reflect current seletions available from
% panelmanager.
info = panelmanager('getpanels',handles.ssqframe);
if isempty(info)
  %Put [space] place holder in string so can disable without warning.
  set(handles.panelviewselect,'string',' ','value',1,'enable','off');
else
  set(handles.panelviewselect,'string',{info.name},'value',1,'enable','on');
end

options = analysis('options');

if strcmp(options.panelselector,'buttons');
  %hide panelveiwselect
  set(handles.panelviewselect,'visible','off');

  buttons = getappdata(handles.panelviewselect,'buttons');
  if isempty(info);
    %no items? delete all buttons
    if ~isempty(buttons);
      delete([buttons(ishandle([buttons.handle])).handle]);
    end
    buttons = [];
  else
    %create new buttons
    if ~isempty(buttons);
      delete([buttons(ishandle([buttons.handle])).handle]);
    end

    %calculate allowable width of each button
    spos  = get(handles.panelviewselect,'position');
    fpos  = get(handles.ssqframe,'position');
    lpos  = get(handles.panelviewlabel,'position');
    width = min(180,((fpos(3)-lpos(3))/length(info))-2);

    %create buttons
    buttons = info;
    enb = 'on';
    bcount = 0;
    for bind = 1:length(info);
      %create one button for each item in info
      if ismember(info(bind).file,options.hidepanel) | (~isempty(options.showpanel) & ~ismember(info(bind).file,options.showpanel))
        vis = 'off';
      else
        bcount = bcount+1;
        vis = 'on';
      end

      pos = [spos(1)+(bcount-1)*(width+2) spos(2) width spos(4)];
      h = uicontrol(handles.analysis,'style','pushbutton',...
        'position',pos,...
        'enable',enb,...
        'visible',vis,...
        'string',info(bind).name,...
        'callback',sprintf('analysis(''panelviewselect_Callback'',gcbf,[],guidata(gcbf),%i);',bind));
      backgroundcolor = get(h,'backgroundcolor');
      buttons(bind).handle = h;
      if bind==1;
        set(buttons(bind).handle,'backgroundcolor',[1 1 1]);
      end
    end
    setappdata(handles.panelviewselect,'backgroundcolor',backgroundcolor)
  end
  setappdata(handles.panelviewselect,'buttons',buttons);
end
drawnow

% --------------------------------------------------------------------
function  panelviewselect_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.panelviewselect.
%
%If selection is SSQ Table then make all userdata = panel invisible and
%make ssq table visible.
if nargin>3;
  %fourth input is index into panelvewselect we want to use (note: this is
  %used by the tab buttons used by view
  set(handles.panelviewselect,'value',varargin{1});
end

mystr = get(handles.panelviewselect,'string');
myval = get(handles.panelviewselect,'value');

if myval>length(mystr)
  %Reset to one if list becomes smaller than selection. This can happen
  %when switch methods.
  myval = 1;
  set(handles.panelviewselect,'value',myval)
end

%if using buttons instead of selector, set color of all buttons and selected button
buttons = getappdata(handles.panelviewselect,'buttons');
if ~isempty(buttons)
  color = getappdata(handles.panelviewselect,'backgroundcolor');
  set([buttons.handle],'backgroundcolor',color);
  set(buttons(myval).handle,'backgroundcolor',[1 1 1]);
end

if iscell(mystr) & length(mystr)>=myval
  myselection = mystr{myval};
else
  myselection = mystr;
end
panels = panelmanager('getpanels',handles.ssqframe);

if ~isempty(panels)
  idx = ismember(lower({panels.name}),lower(myselection));
else
  myselection = 'empty';
end

switch lower(myselection)
  case 'ssq table'
    panelmanager('invisibleall',handles.ssqframe)
    ssqvisible(handles,'on')
  case 'empty'
  
  otherwise
    ssqvisible(handles,'off')
    drawnow
    %Resize and update code will get called auotmatically.
    panelmanager('visible',panels(idx),handles.ssqframe);
end

% --------------------------------------------------------------------
function calcmodel_Callback(h, eventdata, handles, varargin)

if ~exist('handles') | isempty(handles) | ~isfield(handles,'analysis')
  cbf = gcbf;
  if (~isempty(cbf));
    handles = guidata(gcbf);
  end
end

fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
model = getobjdata('model',handles);
if isempty(fn) | (isempty(getobjdata('xblock',handles)) & (isempty(model) | isempty(getobjdata('validation_xblock',handles))))
  erdlgpls('You must select an analysis method and load data before calculating a model. You can also load a previously created model to use.','Error Calculating Model');
  return
end
%check if apply_only is on and if we're allowed to calculate a model
% NOTE: if apply_only is selected, the user should never be able to get
% xblock data loaded and, thus, they should never be able to get to this
% point (the above test will catch that scenario). However, we add this
% test to make absolutely sure. If the user gets around the load data
% tests, this will keep them from building a model.
if getappdata(handles.analysis,'apply_only') & isempty(model)
  erdlgpls('Calibration of a model is disabled - You may only apply models. Contact your system administrator for more information.','Cannot Calculate Model');
  return
end

%try calling into any "calcmodel_callback" add-on functions
%trap errors - but errors thrown by callback stop calcmodel from completing
fns = evriaddon('analysis_calcmodel_callback');
for j=1:length(fns)
  try
    feval(fns{j},handles.analysis,[],handles);
  catch
    %errors thrown in these callbacks indicate "abort calibrate" action
    return
  end
end

%do actual calcmodel
try
  setappdata(handles.analysis,'suggestedpc',[]);
  pointer(handles.analysis,1);
  set(handles.calcmodel,'enable','off');
  set(handles.helpwindow,'String','Calculating Model... Please Wait...','backgroundcolor',statuscolor('yellow'));   %help window message
  drawnow;
  if ~isempty(fn);
    feval(fn,'calcmodel_Callback',handles.analysis,[],handles);
  end
catch
end

% % valid model type:PLS,PCR,MLR,NPLS,PLSDA,*LWR,*ANN
% % *works but disabled (very slow). To re-enable, add to the variable below.
% vld_mdls = {'PLS','PCR','MLR','NPLS','PLSDA'};
% modl = getobjdata('model',handles);
% 
% % Calculate RMSEP values, used when predictions are calculated with a pre-existing model (in Analysis GUI) 
% if (~(isempty(modl)) & ismember(modl.modeltype,vld_mdls))
%   prd = getobjdata('prediction',handles);
%   if ~(isempty(prd)) %~(isempty(modl)) & ~(isempty(prd))
%     mxncomps = size(modl.detail.rmsec,2);
%     if strcmpi(modl.modeltype,'LWR')
%       npts = modl.detail.npts;
%     end
%     
%     if isempty(modl.detail.rmsep) | (mxncomps ~= size(modl.detail.rmsep,2)) | any(any(isnan(prd.detail.rmsep)))
%       %mark the RMSEP values that need to be calculated
%       modl.detail.rmsep = nan(size(modl.detail.rmsec));
%       tocalc = true(1,mxncomps);
%       for i=1:size(prd.detail.rmsep,2)
%         if~(isnan(prd.detail.rmsep(1,i))) & ~(isempty(prd.detail.rmsep(1,i)))
%           tocalc(i) = false;
%         end
%       end
%       opts = modl.detail.options;
%       if isfield(opts,'rawmodel') % rawmodel field must be removed
%         opts=rmfield(opts,'rawmodel');
%       end
%       xb_cal = getobjdata('xblock',handles);
%       if isempty(xb_cal)
%         xb_cal = modl.datasource{1};
%       end
%       yb_cal = getobjdata('yblock',handles);
%       if isempty(yb_cal) & length(modl.datasource)>1
%         yb_cal = modl.datasource{2}; %if empty, don't use it.
%       end
%       % get validation datasets
%       xb_val = getobjdata('validation_xblock',handles);
%       if isempty(xb_val)
%         xb_val = prd.datasource{1};
%       end
%       yb_val = getobjdata('validation_yblock',handles);
%       if isempty(yb_val) & length(prd.datasource)>1
%         yb_val = prd.datasource{2}; %if empty, don't use it.
%       end
%       
%       if isempty(xb_cal) | ~(isa(xb_cal,'dataset')) | isempty(xb_val) % no xb_val or xb_val? Don't calculate RMSEP
%         gocalc = false;
%       else
%         gocalc = true;
%       end
%       if (gocalc)
%         for i=1:mxncomps
%           if ~(tocalc(i))
%             modl.detail.rmsep(:,i) = prd.detail.rmsep(:,i);
%           else
%             %TODO: try to figure out how to do this without feval()
%             % build calibration & pred models
%             if isempty(yb_cal) % for models without yblock?
%               lil_m = feval(lower(modl.modeltype),xb_cal,i,opts);
%               lil_p = feval(lower(modl.modeltype),xb_val,lil_m,opts);
%             else
%               if strcmpi(modl.modeltype,'LWR') % to handle LWR
%                 lil_m = feval(lower(modl.modeltype),xb_cal,yb_cal,i,npts,opts);
%               else % to handle PLS, PCR, MLR, NPLS, PLSDA
%                 if strcmpi(modl.modeltype,'ANN') % to handle ANN
%                   opts.nhid1=i;
%                 end
%                 lil_m = feval(lower(modl.modeltype),xb_cal,yb_cal,i,opts);
%               end
%               lil_p = feval(lower(modl.modeltype),xb_val,yb_val,lil_m,opts);
%             end
%             for j=1:size(modl.detail.rmsec,1)
%               if (modl.detail.rmsep(j,i) ~= lil_p.detail.rmsep(j,i)) & ~(isnan(lil_p.detail.rmsep(j,i)) | isempty(lil_p.detail.rmsep(j,i)))
%                 modl.detail.rmsep(j,i) = lil_p.detail.rmsep(j,i);
%                 modl.detail.bias(j,i) = lil_m.detail.bias(j,i);
%                 prd.detail.rmsep(j,i) = lil_p.detail.rmsep(j,i);
%                 prd.detail.predbias(j,i) = lil_p.detail.predbias(j,i);
%                 prd.detail.bias(j,i) = lil_m.detail.bias(j,i);
%               end
%             end
%           end
%         end
%         setobjdata('model',handles,modl);
%         setobjdata('prediction',handles,prd);
%       end
%     else % The RMSEP values are already present (do nothing).
%     end
%   end
% end

set(handles.calcmodel,'enable','on');
pointer(handles.analysis,0);
toolbarupdate(handles)
printinfo_update(handles)  %update infobox
resize_callback(handles.analysis,[],handles);

%Update cache and tree. In PLSTB 6.0 an error can occur in this function when trying to
%update the tree but we don't want it to be fatal so use trycac
cachecurrent(handles);

fns = evriaddon('analysis_post_calcmodel_callback');
for j=1:length(fns)
  try
    feval(fns{j},handles.analysis,[],handles);
  catch
  end
end

drawnow
if ~strcmpi(get(handles.analysis,'pointer'),'arrow')
  %Make absolutely sure pointer is arrow. Mac users reporting that pointer
  %is not getting set.
  pointer(handles.analysis,0);
end

% --------------------------------------------------------------------
function cachecurrent(handles)
% take the current model and/or prediction settings and cache them

if exist('modelcache','file') & ~strcmp(getfield(modelcache('options'),'cache'),'readonly')
  if isloaded('model',handles) | isloaded('prediction',handles);
    try
      %store model and data in model history
      if isloaded('xblock',handles)
        data = {getobjdata('xblock',handles) getobjdata('yblock',handles)};
        modelcache(getobjdata('model',handles),data)
      end
      if isloaded('prediction',handles);
        data = {getobjdata('validation_xblock',handles) getobjdata('validation_yblock',handles)};
        modelcache(getobjdata('model',handles),data,getobjdata('prediction',handles));
      end
    end

    %Update cacheview.
    updatecacheview(handles);

  end

end

% --------------------------------------------------------------------
function updatecacheview(handles)
%Update cacheview.
if getappdata(handles.analysis,'showcacheviewer')
  opts = analysis('options');
  if ~strcmp(opts.defaultcacheview,'hide')
    %In PLSTB 6.0 we saw some errors here with getsourcedata/checkcache
    %probalby due to duplicate records in persistent var. Make sure
    %this isn't a fatal error.
    try
      evritreefcn(handles.analysis,'update');
    catch
      %Maybe do a modelcache('reset') if we start seeing a lot of
      %errors here.
    end
  end
end

% --------------------------------------------------------------------
function preprocesschange(h,blockchange)
%Clear model if changing preprocessing. h can be handle to pp figure or
%analysis handles structure.
%if input h is the handle of the preprocess
%getappdata(h,'parenthandle') is handle of analysis
if ishandle(h)
  handles = guidata(getappdata(h,'parenthandle'));
else
  handles = h;
end

%Input 'blockchange' indicates which preproc block was changed.
%'x' = xblock, 'y' = 'yblock', 'b' = both/all.
if nargin < 2
  blockchange = 'b';
end

%Set clutter.


autoclear(handles)
clearmodel(handles.analysis,[],handles)
updateprepro(handles,blockchange)
updatestatusimage(handles);

% --------------------------------------------------------------------
function updateprepro(handles,blockchange)
%Update preprocessed data but ONLY if preprocess figures open
%inputs are:
%       handles : analysis handles
%   blockchange : block which should be updated
%         'x' = update x only
%         'y' = update y only
%         'b' or empty = update both

if nargin<2 | isempty(blockchange)
  blockchange = 'b';
end

pxh = findpg('xblockprepro',handles);
pyh = findpg('yblockprepro',handles);
if ~isempty(pxh) & (strcmp(blockchange,'x')|strcmp(blockchange,'b'))
  viewprepro(handles.analysis, [], handles, 'x')
end
if ~isempty(pyh) & (strcmp(blockchange,'y')|strcmp(blockchange,'b'))
  viewprepro(handles.analysis, [], handles, 'y')
end

% --------------------------------------------------------------------
function crossvalchange(h)
%input h is the handle of the crossvalgui
%getappdata(h,'parenthandle') is handle of analysis
handles              = guidata(getappdata(h,'parent'));
autoclear(handles)
clearmodel(handles.analysis,[],handles)
updatestatusimage(handles)
toolbarupdate(handles)  %set buttons

% --------------------------------------------------------------------
function editxblock(h, eventdata, handles, varargin)

if isloaded('xblock',handles)
  editds(getobj('xblock',handles));
end

% --------------------------------------------------------------------
function edityblock(h, eventdata, handles, varargin)

if isloaded('yblock',handles)
  editds(getobj('yblock',handles));
end

% --------------------------------------------------------------------
function editblock(h, eventdata, handles, varargin)
%Edit block.
%TODO: Map all edit code to here.

switch varargin{1}
  case {'x' 'xblock'}
    mylink = getobj('xblock',handles);
    myid   = 'xblock';
  case {'y' 'yblock'}
    mylink = getobj('yblock',handles);
    myid   = 'yblock';
  case {'x_val' 'validation_xblock'}
    mylink = getobj('validation_xblock',handles);
    myid   = 'validation_xblock';
  case {'y_val' 'validation_yblock'}
    mylink = getobj('validation_yblock',handles);
    myid   = 'validation_yblock';
end

if ~isempty(mylink)
  editds(mylink);
end

% --------------------------------------------------------------------
function plotblock(h, eventdata, handles, varargin)
%Plot a data block.

name = '';

switch varargin{1}
  case {'x' 'xblock'}
    name = 'Calibration X-Block';
    mylink = getobj('xblock',handles);
  case {'y' 'yblock'}
    name = 'Calibration Y-Block';
    mylink = getobj('yblock',handles);
  case {'x_val' 'validation_xblock'}
    name = 'Validation X-Block';
    mylink = getobj('validation_xblock',handles);
  case {'y_val' 'validation_yblock'}
    name = 'Validation Y-Block';
    mylink = getobj('validation_yblock',handles);
end

plotgui('new',mylink,'plotby',0,'name',[name ' Data']);

% --------------------------------------------------------------------
function plotxblock(h, eventdata, handles, varargin)

plotgui('new',getobj('xblock',handles),'plotby',0,'name','X-data');

% --------------------------------------------------------------------
function plotyblock(h, eventdata, handles, varargin)

plotgui('new',getobj('yblock',handles),'plotby',0,'name','Y-data');

% --------------------------------------------------------------------
function editselectycols(h, eventdata, handles, varargin)

yblk = getobjdata('yblock',handles);

ncols = size(yblk.data,2);
include = yblk.include{2};
lbls    = yblk.label{2};
for j=1:ncols;
  if isempty(lbls);
    str{j} = ['Column ' num2str(j)];
  else
    str{j} = [lbls(j,:) num2str(j)];
  end
end

[selection,ok] = listdlg('ListString',str,'SelectionMode','multiple','InitialValue',include,'PromptString','Select Y-Columns to use','Name','Select Y-Columns');

if ok & ~isempty(selection)
  if length(yblk.include{2})~=length(selection) | any(yblk.include{2}~=selection)
    yblk.include{2} = selection;
    setobjdata('yblock',handles,yblk);
  end
end

% --------------------------------------------------------------------
function [rmlist, dslist] = optionsdisablelist(curanalysis)
%Get list of options to remove and disable for use in analysis.

rmlist = '';
dslist = '';

if nargin<1
  curanalysis = getappdata(handles.analysis,'curanal');
end

dlist  = '';
if ~isempty(curanalysis)
  %Create disable list for each type of analysis.
  rmlist = {'preprocessing'};
  switch curanalysis
    case 'purity'
      rmlist = [rmlist {'interactive' 'select' 'resolve' 'display' 'offset' 'returnfig'}];
    case 'simca'
      rmlist = [rmlist {'display' 'plots' 'staticplots' 'rawmodel'}];
    case {'svm' 'svmda'}
      %svmtype and splits are handled by panel.
      rmlist = [rmlist {'display' 'plots' 'splits' ''}];
    case {'xgb' 'xgbda'}
      %svmtype and splits are handled by panel.
      rmlist = [rmlist {'display' 'plots' 'splits' 'algorithm' 'xgbtype'}];
    case 'parafac'
      rmlist = [rmlist {'display' 'plots'}];
    case {'ann' 'annda'}
      rmlist = [rmlist {'display' 'plots' 'anntype' 'nhid1' 'nhid2' 'cvmethod' 'cvsplits' 'compression' 'compressncomp'}];
    case {'lreg' 'lregda'}
      rmlist = [rmlist {'display' 'plots' 'lregtype' 'algorithm' 'lambda'        'cvmethod' 'cvsplits'}];
    case {'lda'}
      rmlist = [rmlist {'display' 'plots' 'lambda' 'cvmethod' 'cvsplits'}];

    otherwise
      rmlist = [rmlist {'rawmodel' 'display' 'plots' 'outputversion' 'alsoptions.sclc' 'alsoptions.scls'}];
  end
end

% --------------------------------------------------------------------
function opts = getsafeoptions(h, eventdata, handles, varargin)
%Get options with removed options.
curanalysis = getappdata(handles.analysis,'curanal');

opts = getappdata(handles.analysis,'analysisoptions');
if isempty(opts)
  opts = feval(curanalysis, 'options');
end

%Create remove/disable list for each type of analysis.
[rmlist, dslist] = optionsdisablelist(curanalysis);

%Resolve options list.
rmlist = rmlist(ismember(rmlist,fieldnames(opts)));
opts = rmfield(opts,rmlist);

% --------------------------------------------------------------------
function editoptions(h, eventdata, handles, varargin)
%Edit options using optionsGUI for current analysis.
curanalysis = getappdata(handles.analysis,'curanal');

opts = getappdata(handles.analysis,'analysisoptions');
dlist  = '';
if ~isempty(curanalysis)
  %Create remove/disable list for each type of analysis.
  [rmlist, dslist] = optionsdisablelist(curanalysis);
  if strcmp(curanalysis,'parafac')
    if ~isloaded('xblock',handles)
      evrimsgbox('Options cannot be set for PARAFAC until data has been loaded.','PARAFAC Options Warning','warn','modal');
      return
    else
      %Add correct number of cells for .constraints field so optionsgui functions properly.
      ds = getobjdata('xblock',handles);
      if isempty(opts)
        paraopts = parafac('options');
        defaultcnst = paraopts.constraints{1};%Get default.
        paraopts.constraints = {};%Clear constraints.
        ds = getobjdata('xblock',handles);
        for i = 1:ndims(ds)
          paraopts.constraints{i,1} = defaultcnst;
        end
      else
        if length(opts.constraints)>ndims(ds)
          %reduce the length of constraints cell to ndims
          opts.constraints = opts.constraints(1:ndims(ds));
        elseif length(opts.constraints)<ndims(ds)
          %request a temporary (clean) copy of the parafac options and copy
          %the temp.constraints{1} into options.constraints{end+1:ndims(ds)}
          temp = parafac('options');
          [opts.constraints{end+1:ndims(ds)}] = deal(temp.constraints{1});
        end
        paraopts = opts;
      end
    end
  end
  o.disable = dlist;
  o.remove  = rmlist;
  %Disable options menu so can access analysis gui but not create new optionsgui.
  setappdata(handles.analysis,'optionsedit',0)
  try
    if strcmp(curanalysis,'parafac')
      outopts = optionsgui(paraopts,o);
    elseif ~isempty(opts) & strcmp(opts.functionname, curanalysis)
      %Use stored options.
      outopts = optionsgui(opts,o);
    else
      %Switched analysis type (or none loaded), get new options.
      outopts = optionsgui(curanalysis,o);
    end
  catch
    setappdata(handles.analysis,'optionsedit',1)
    error(lasterr);
    return
  end
  setappdata(handles.analysis,'optionsedit',1)
  if isempty(outopts)
    %User cancel optionsgui.
    return
  end
  statmodl = getappdata(handles.analysis,'statmodl');
  if ~strcmp(statmodl,'none')
    default = 'Clear Without Saving';
    if modelsaved(handles)
      %saved (or model cache is running)
      ans = 'Clear Without Saving';
    else
      if strcmp(statmodl,'loaded')
        default = 'Keep Model';
      end
      ans=evriquestdlg('Some option changes may not have an affect unless the model is reclaculated. Do you want to clear the current model now?', ...
        'Changing Options','Clear Without Saving',...
        'Save & Clear','Keep Model',default);
    end
    switch ans
      case {'Save & Clear'}
        if ~isempty(savemodel(handles.savemodel, [], handles, []))
          clearmodel(handles.analysis, [], handles, []);
        end
      case {'Clear Without Saving'}
        clearmodel(handles.analysis, [], handles, []);
    end
  end
  %store options
  setopts(handles,curanalysis,outopts)
  updateprepro(handles, 'x');  
  fn  = analysistypes(curanalysis,3);
  if ~isempty(fn);
    feval(fn,'optionschange',handles.analysis);
  end
  
end

% --------------------------------------------------------------------
function editanalysisoptions(h, eventdata, handles, varargin)
%Edit Analysis GUI options.
setappdata(handles.analysis,'optionsedit',0)

%Remove auto select/exclude functionality unless functions exist.
options.remove = [];

if ~(exist('choosecomp.m','file')==2)
  options.remove = [options.remove {'autoselectcomp'}];
end

if ~(exist('autoexclude.m','file')==2)
  options.remove = [options.remove {'autoexclude'}];
end

try
  newopt = optionsgui('analysis',options);
catch
  setappdata(handles.analysis,'optionsedit',1)
  error(lasterr);
  return
end
setappdata(handles.analysis,'optionsedit',1)

if isempty(newopt)
  %User cancel optionsgui.
  return
end

%copy these options into plsprefs
oldopt = analysis('options');
doclearmodel = 0;
for f = {'maximumfactors' 'autoselectcomp' 'autoexclude'}
  %if these have changed, note that the model should PROBABLY be cleared
  try
    if ~comparevars(oldopt.(f{:}),newopt.(f{:}))
      setplspref('analysis',f{:},newopt.(f{:}));
      doclearmodel = 1;
    end
  end
end

for f = {'pushclasses' 'showerrorbars' 'showautoclassscores' 'splitclassedvars' 'reducedstats' 'flowchart' 'cachewidth' ...
    'defaultcv' 'defaultimportmethod' 'ssqfontsize' 'clutterbutton' 'quickopenprepro' 'filternwayprepro' 'predictionblock' ...
    'showyinbiplot'};
  %these don't require clearing of the model
  setplspref('analysis',f{:},newopt.(f{:}));
end

flowchart_callback(handles,newopt.flowchart);
resize_callback(handles.analysis,[],handles);

if doclearmodel
  %handle clearing of model and updating of GUI
  curanal = getappdata(handles.analysis,'curanal');
  fn  = analysistypes(curanal,3);
  statmodl = getappdata(handles.analysis,'statmodl');
  do_gui_init = 1;
  if ~strcmp(statmodl,'none')
    do_gui_init = 0;
    default = 'Clear Without Saving';
    if modelsaved(handles)
      %saved (or model cache is running)
      ans = 'Clear Without Saving';
    else
      %not saved
      if strcmp(statmodl,'loaded')
        default = 'Keep Model';
      end
      ans=evriquestdlg('Some option changes may not have an affect unless the model is reclaculated. Do you want to clear the current model now?', ...
        'Changing Options','Clear Without Saving',...
        'Save & Clear','Keep Model',default);
    end
    switch ans
      case {'Save & Clear'}
        if ~isempty(savemodel(handles.savemodel, [], handles, []))
          clearmodel(handles.analysis, [], handles, []);
          do_gui_init = 1;
        end
      case {'Clear Without Saving'}
        clearmodel(handles.analysis, [], handles, []);
        do_gui_init = 1;
    end
  end

  %Run gui_init for current analysis so auto select button visibility is
  %updated.
  if ~isempty(fn) & do_gui_init
    feval(fn,'gui_init',handles.analysis,[],handles,[]);
  end
end

% --------------------------------------------------------------------
function editdocksettings(h, eventdata, handles, varargin)
%Open docking settings gui as modal and wait for response.

f = autodocsettings;
evriwindowstyle(f,[],1);
uiwait(f)

% --------------------------------------------------------------------
function yblockpermute(h,eventdata,handles,varargin)
%Perform a shuffle on the y-block

curanal = getappdata(handles.analysis,'curanal');
damethods = {'svmda' 'plsda' 'knn' 'simca'};

if ~isloaded('xblock',handles) | (~ismember(curanal,damethods) & ~isloaded('yblock',handles))
  return
end

%get model (and calculate it if we need to)
model = getobjdata('model',handles);
if isempty(model);
  calcmodel_Callback(handles.analysis,[],handles);
  model = getobjdata('model',handles);
end
if isempty(model)
  erdlgpls('Unable to perform permutation testing without current model','Permutation Test');
  return;
end

%ask user for number of iterations
perm = inputdlg('Number of Iterations:','Permutation Test',1,{'50'});
drawnow;
if isempty(perm)
  return
end
perm = str2num(perm{1});
if isempty(perm) | perm==0
  return
end

%call crossvalidate with permute flag
fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
[results,nlvs] = feval(fn,'crossvalidate',handles.analysis,model,perm);
if isempty(results) | ismodel(results)
  erdlgpls('Unable to perform permutation tests on this model','Permutation Test');
  return;
end
  
%got results, display them
pfig = permuteplot(results,nlvs);
infofig = infobox(permuteprobs(results,nlvs),struct('openmode','reuse','figurename','Permutation Results','helplink','Tools: Permutation Test'));
infobox(infofig,'font','courier',10);

adopt(handles,infofig,'modelspecific')
adopt(handles,pfig,'modelspecific')

% --------------------------------------------------------------------
function transformdata(h,eventdata,handles,blk,sh)

data = getobjdata(blk,handles);
if nargin<5
  %no shortcut passed? do nothing
  return;
end

switch sh.fn
  case 'coadd'
    [out,opts] = coadd(data);
   
   case 'polytransform_browse'
      [out,opts] = polytransform_browse(data);
    
  otherwise
    out = feval(sh.fn,data);
end

if ~isempty(out) & any(out.moddate~=data.moddate)
  %modified - store original data in cache (if we can)
  nocache = false;
  try
    modelcache([],data);
  catch
    nocache = true;
  end

  %and overwrite this block
  setobjdata(blk,handles,out);

  %special opposite-block handling
  switch sh.fn
    
    case 'polytransform_browse'
      if isloaded('validation_xblock', handles)
        xvaliddata = getobjdata('validation_xblock',handles'); 
      end
      if exist('xvaliddata')
        setobjdata('validation_xblock',handles,polytransform(xvaliddata,opts));
      end
      
    case 'coadd'
      switch blk
        case 'xblock'
          opblk = 'yblock';
        case 'yblock'
          opblk = 'xblock';
        case 'validation_xblock'
          opblk = 'validation_yblock';
        case 'validation_yblock'
          opblk = 'validation_xblock';
      end          
      if isloaded(opblk,handles) & opts.dim==1
        opdata = getobjdata(opblk,handles);
        if ~nocache
		  try
            modelcache([],opdata);
          catch
            %do nothing
          end
        end          
        setobjdata(opblk,handles,coadd(opdata,opts));
      end
  end
  
  %give notice to user we're done
  if nocache
    evrihelpdlg('Data has been transformed and replaced.','Data Transformed');
  else
    updatecacheview(handles);
    evrihelpdlg('Data has been transformed and replaced. Original data stored in model cache.','Data Transformed');
  end
end

updatecrossvallimits(handles)

% --------------------------------------------------------------------
function resetInclude_build(h,eventdata, handles, varargin)

blk = varargin{1};
originalDataSet = getappdata(handles.analysis, ['originalLoadedData_' blk]);
origDataInclField = originalDataSet.include;
fldname = varargin{2};
delete(allchild(handles.(fldname)));
set(handles.(fldname), 'callback', '');
set(handles.(fldname), 'visible', 'off');
set(handles.(fldname), 'enable', 'off');
block_data = getobjdata(blk, handles);
noHardDelete = isequal(size(originalDataSet), size(block_data)); %check if there has been a hard delete
if numel(size(block_data)) == 2
  rows_Xcal  = size(block_data,1);
  cols_Xcal  = size(block_data,2);
  inclField  = block_data.include;
  set(handles.(fldname), 'callback', '');
  
  if rows_Xcal ~= size(origDataInclField{1},2) || cols_Xcal ~= size(origDataInclField{2},2) && noHardDelete
    buildResetOriginal = 1;
  else
    buildResetOriginal = 0;
  end
  if buildResetOriginal
    if size(inclField{1},2) ~= size(origDataInclField{1},2) || size(inclField{2},2) ~= size(origDataInclField{2},2)
      enbl = 'on';
      set(handles.(fldname), 'visible', 'on');
      set(handles.(fldname), 'enable', 'on');
    else
      enbl = 'off';
    end
    uimenu(handles.(fldname),...
      'label','Reset Included to &Original',...
      'tag','status_reset_includedOriginal',...
      'enable', enbl,...
      'callback',['analysis(''resetInclude_Callback'',gcbo,[],guidata(gcbo),''' blk ''', ''Original'')']);
  end
  
  if rows_Xcal ~= size(inclField{1},2) && cols_Xcal ~= size(inclField{2},2)
    enbl = 'on';
    set(handles.(fldname), 'visible', 'on');
    set(handles.(fldname), 'enable', 'on');
  else
    enbl = 'off';
  end
  uimenu(handles.(fldname),...
    'label','Include &All Rows and Columns',...
    'tag','status_reset_includedAll',...
    'enable', enbl,...
    'callback',['analysis(''resetInclude_Callback'',gcbo,[],guidata(gcbo),''' blk ''', ''All'')']);
  if rows_Xcal ~= size(inclField{1},2)
    enbl = 'on';
    set(handles.(fldname), 'visible', 'on');
    set(handles.(fldname), 'enable', 'on');
  else
    enbl = 'off';
  end
  uimenu(handles.(fldname),...
    'label','Include All &Rows',...
    'tag','status_reset_includedRows',...
    'separator','on',...
    'enable', enbl,...
    'callback',['analysis(''resetInclude_Callback'',gcbo,[],guidata(gcbo),''' blk ''', ''Rows'')']);
  if cols_Xcal ~= size(inclField{2},2)
    enbl = 'on';
    set(handles.(fldname), 'visible', 'on');
    set(handles.(fldname), 'enable', 'on');
  else
    enbl = 'off';
  end
  uimenu(handles.(fldname),...
    'label','Include All &Columns',...
    'tag','status_reset_includedCols',...
    'enable', enbl,...
    'callback',['analysis(''resetInclude_Callback'',gcbo,[],guidata(gcbo),''' blk ''', ''Columns'')']);
elseif numel(size(block_data)) > 2 %n-way data
  num_modes = numel(size(block_data));
  findExs = zeros(1,num_modes);
  for mds=1:num_modes
    findExs_Original(mds) = size(block_data,mds) ~= size(origDataInclField{mds},2);
  end
  if any(findExs_Original) && noHardDelete
    buildResetOriginal = 1;
  else
    buildResetOriginal = 0;
  end

  if buildResetOriginal
    for mds=1:num_modes
      findExs(mds) = size(block_data.include{mds},2) ~= size(origDataInclField{mds},2);
    end
    if any(findExs==1)
      enbl = 'on';
      set(handles.(fldname), 'visible', 'on');
      set(handles.(fldname), 'enable', 'on');
    else
      enbl = 'off';
    end
    uimenu(handles.(fldname),...
      'label','Reset Included to &Original',...
      'tag','status_reset_includedOriginal',...
      'enable', enbl,...
      'callback',['analysis(''resetInclude_Callback'',gcbo,[],guidata(gcbo),''' blk ''', ''nway'', ''original'')']);
  end
  
  
  for mds=1:num_modes
    findExs(mds) = size(block_data,mds) == size(block_data.include{mds},2);
  end
  if any(findExs==0) || buildResetOriginal
    set(handles.(fldname), 'visible', 'on');
    set(handles.(fldname), 'enable', 'on');
  else
    set(handles.(fldname), 'visible', 'off');
    set(handles.(fldname), 'enable', 'off');
  end
  
  if sum(findExs(:))>=2
    en_bl = 'off';
  else
    en_bl = 'on';
  end

  uimenu(handles.(fldname),...
    'label','Include All for &All Modes',...
    'tag','reset_include_all_modes',...
    'enable',en_bl,...
    'callback',['analysis(''resetInclude_Callback'',gcbo,[],guidata(gcbo),''' blk ''', ''nway'', ''all'')']);
  
  for mds=1:num_modes
    if findExs(mds) == 0
      en_bl = 'on';
    else
      en_bl ='off';
    end
    if mds == 1
      sep_set = 'on';
    else
      sep_set = 'off';
    end
    uimenu(handles.(fldname),...
      'label',['Include All for Mode &' num2str(mds)],...
      'tag',['reset_include_mode_' num2str(mds)],...
      'enable',en_bl,...
      'separator', sep_set,...
      'callback',['analysis(''resetInclude_Callback'',gcbo,[],guidata(gcbo),''' blk ''', ''nway'', ''' num2str(mds) ''')']);
  end
end
% --------------------------------------------------------------------
function resetInclude_Callback(h,eventdata, handles, varargin)
blk  = varargin{1};
data = getobjdata(blk,handles);
mode = varargin{2};


isxl = isloaded('xblock',handles);
isyl = isloaded('yblock',handles);
isvxl = isloaded('validation_xblock',handles);
isvyl = isloaded('validation_yblock',handles);

rws_toIncl = 1:size(data,1);
cols_toIncl = 1:size(data,2);
otherBlock = [];
switch mode
  case 'Original'
    originalDataSet = getappdata(handles.analysis, ['originalLoadedData_' blk]);
    toInclude = originalDataSet.include;
    rws_toIncl = toInclude{1};
    cols_toIncl = toInclude{2};
    data.include{1} = rws_toIncl;
    data.include{2} = cols_toIncl;
    if strcmp(blk, 'xblock') & isyl
      otherBlock = 'yblock';
    elseif strcmp(blk, 'yblock') & isxl
      otherBlock = 'xblock';
    elseif strcmp(blk, 'validation_xblock') & isvyl
      otherBlock = 'validation_yblock';
    elseif strcmp(blk, 'validation_yblock') & isvxl
      otherBlock = 'validation_xblock';
    end
    if ~isempty(otherBlock)
      otherBlock_data = getobjdata(otherBlock, handles);
      otherBlock_data.include{1} = rws_toIncl;
    end

  case 'All'
    data.include{1} = rws_toIncl;
    data.include{2} = cols_toIncl;
    if strcmp(blk, 'xblock') & isyl
      otherBlock = 'yblock';
    elseif strcmp(blk, 'yblock') & isxl
      otherBlock = 'xblock';
    elseif strcmp(blk, 'validation_xblock') & isvyl
      otherBlock = 'validation_yblock';
    elseif strcmp(blk, 'validation_yblock') & isvxl
      otherBlock = 'validation_xblock';
    end
    if ~isempty(otherBlock)
      otherBlock_data = getobjdata(otherBlock, handles);
      otherBlock_data.include{1} = rws_toIncl;
    end
  case 'Rows'
    data.include{1} = rws_toIncl;
    if strcmp(blk, 'xblock') & isyl
      otherBlock = 'yblock';
    elseif strcmp(blk, 'yblock') & isxl
      otherBlock = 'xblock';
    elseif strcmp(blk, 'validation_xblock') & isvyl
      otherBlock = 'validation_yblock';
    elseif strcmp(blk, 'validation_yblock') & isvxl
      otherBlock = 'validation_xblock';
    end
    if ~isempty(otherBlock)
      otherBlock_data = getobjdata(otherBlock, handles);
      otherBlock_data.include{1} = rws_toIncl;
    end
  case 'Columns'
    data.include{2} = cols_toIncl;
  case 'nway'
    nway_mode = varargin{3};
    switch nway_mode
      case 'original'
        originalDataSet = getappdata(handles.analysis, ['originalLoadedData_' blk]);
        toInclude = originalDataSet.include;
        for j = 1:numel(size(data))
          toIncl = toInclude{j};
          data.include{j} = toIncl;
        end
        if strcmp(blk, 'xblock') & isyl
          otherBlock = 'yblock';
        elseif strcmp(blk, 'yblock') & isxl
          otherBlock = 'xblock';
        elseif strcmp(blk, 'validation_xblock') & isvyl
          otherBlock = 'validation_yblock';
        elseif strcmp(blk, 'validation_yblock') & isvxl
          otherBlock = 'validation_xblock';
        end
        if ~isempty(otherBlock)
          otherBlock_data = getobjdata(otherBlock, handles);
          otherBlock_data.include{1} = toInclude{1};
        end
      case 'all'
        for j = 1:numel(size(data))
          toIncl = 1:size(data,j);
          data.include{j} = toIncl;
        end
        data.include{1} = rws_toIncl;
        if strcmp(blk, 'xblock') & isyl
          otherBlock = 'yblock';
        elseif strcmp(blk, 'yblock') & isxl
          otherBlock = 'xblock';
        elseif strcmp(blk, 'validation_xblock') & isvyl
          otherBlock = 'validation_yblock';
        elseif strcmp(blk, 'validation_yblock') & isvxl
          otherBlock = 'validation_xblock';
        end
        if ~isempty(otherBlock)
          otherBlock_data = getobjdata(otherBlock, handles);
          otherBlock_data.include{1} = rws_toIncl;
        end
      otherwise
        num_nwayMode = str2double(nway_mode);
        toIncl = 1:size(data,num_nwayMode);
        data.include{num_nwayMode} = toIncl;
        if num_nwayMode == 1
          data.include{1} = rws_toIncl;
          if strcmp(blk, 'xblock') & isyl
            otherBlock = 'yblock';
          elseif strcmp(blk, 'yblock') & isxl
            otherBlock = 'xblock';
          elseif strcmp(blk, 'validation_xblock') & isvyl
            otherBlock = 'validation_yblock';
          elseif strcmp(blk, 'validation_yblock') & isvxl
            otherBlock = 'validation_xblock';
          end
          if ~isempty(otherBlock)
            otherBlock_data = getobjdata(otherBlock, handles);
            otherBlock_data.include{1} = rws_toIncl;
          end
        end
    end
end

setobjdata(blk,handles,data);
if ~isempty(otherBlock)
  setobjdata(otherBlock, handles, otherBlock_data);
end

% --------------------------------------------------------------------
function makexcolumnyblock(h,eventdata,handles,varargin)
%makes a user-selected column of the x-block into the y-block
% varargin{1} = 'x' then xblock, varargin{1} = 'x_val' the validation xblock.

%Varargin may be dynamically generated from status menu so do checks here.
if nargin<4 | strcmp(varargin{1},'x') | strcmp(varargin{1},'xblock')
  varargin{1} = '';
elseif strcmp(varargin{1},'x_val') | strcmp(varargin{1},'validation_') | strcmp(varargin{1},'validation_xblock')
  varargin{1}='validation_';
else
  varargin{1} = '';
end

xdso = getobjdata([varargin{1} 'xblock'],handles);
y = getobjdata([varargin{1} 'yblock'],handles);
if isempty(xdso)
  return
end

fromWhere = varargin{2}; %cols or axis or class
fromCols = 0;
switch fromWhere
  case 'cols'
    fromCols = 1;
    findEmptySets = [];
    ncols = size(xdso.data,2);
    lbls    = xdso.label{2};
    for j=1:ncols;
      if isempty(lbls);
        str{j} = ['Column ' num2str(j)];
      else
        str{j} = [lbls(j,:) ' (' num2str(j) ')'];
      end
    end
  case 'axis'
    
    testForEmptyAxis = cellfun(@isempty, xdso.axisscale(1,:));
    findEmptySets = find(testForEmptyAxis);
    if all(testForEmptyAxis)
      evrierrordlg('No mode 1 axis scale sets detected in X-block DataSet Object', 'No Axis Scale Sets');
      return;
    end
    naxisscaleSets = size(xdso.axisscale(1,:),2);
    axisscaleSetsNames = xdso.axisscalename(1,:);
    for j=1:naxisscaleSets;
      if ~testForEmptyAxis(j)
        if isempty(axisscaleSetsNames{j});
          str{j} = ['Axis Scale Set ' num2str(j)];
        else
          str{j} = [axisscaleSetsNames{1,j} ' (' num2str(j) ')'];
        end
      else
        str{j} = 'Empty';
      end
    end
  case 'class'
    [classGroups, classSetSelected] = plsdagui(xdso,[],1,[]);
    if isempty(classSetSelected) | ~iscell(classGroups)
      return;
    end
    newy = class2logical(xdso, classGroups, classSetSelected);
    curLookUp = xdso.classlookup{1,classSetSelected};
    classInds = cell2mat(curLookUp(:,1));
    classNames = curLookUp(:,2);
    matchInds = cellfun(@(x)find(ismember(classInds, x)),classGroups, 'uni', false);
    yblockLabels = cellfun(@(x)strjoin(classNames(x)', '_and_'), matchInds, 'uni', false);
    newy.label{2,1} = yblockLabels;
    newy.classname{1,end} = xdso.classname{1,classSetSelected};
    newy = rmset(newy, 'class',2,1);
    loaddata_callback(h, [], handles, [varargin{1} 'yblock'], newy);
    return;
end

%[selection,ok] = listdlg('ListString',str,'SelectionMode','multiple','InitialValue',[],'PromptString','Select column(s) for Y-block','Name','X-columns as Y-block');
[selection, actionToPerform] = makeyfromx(str, fromCols, findEmptySets);

if isempty(selection)
  return;
end

%get the column(s) to use
if fromCols
  newy = nindex(xdso,selection,2);
elseif ~fromCols
  newy = dataset(zeros(size(xdso,1),length(selection)));
  for i = 1:length(selection)
    newy.data(:,i) = xdso.axisscale{1,selection(i)};
    varNames(i) = str(selection(i));
  end
  newy.label{2,end} = varNames;
  newy.name = 'Y block made from X block';
end

newy.include{2} = 1:size(newy,2);  %make all selected columns included (no matter what they were in X)
loaddata_callback(h, [], handles, [varargin{1} 'yblock'], newy);
tempy = getobjdata([varargin{1} 'yblock'],handles);
if isempty(y) | ~isdataset(y) | any(tempy.moddate~=y.moddate)
  %user allowed replacement of existing y (or no y was there), now update x
  %to exclude those columns
  last_used = getappdata(handles.analysis,[varargin{1} 'lastusedxcolumn']);
  o_incld   = getappdata(handles.analysis,[varargin{1} 'lastusedxinclude']);
  if isempty(o_incld)
    %Save original include field so we don't inadvertently change original it.
    setappdata(handles.analysis,[varargin{1} 'lastusedxinclude'],xdso.include{2})
  end
  
  if strcmp(actionToPerform, 'moveDelete')
    if fromCols
      xdso = delsamps(xdso,selection,2,2);
    else
      xdso = rmset(xdso, 'axisscale', 1, selection);
    end
  else %if move/move and exclude
    if fromCols
      incl = xdso.include{2};
      %Add last used back to include field if it wasn't excluded to begin with.
      if any(last_used==o_incld)
        incl = union(incl,last_used);
      end
      xdso.include{2} = setdiff(incl,selection);  %exclude column(s)
    else
      %do nothing to axisscales
    end
  end
  
  %incl_r = x.include;
  %incl_r(1) = {':'};
  %x = x(incl_r{:});
  setappdata(handles.analysis,[varargin{1} 'lastusedxcolumn'],selection);  %note which we excluded (to unexclude if we switch to another column)
  setobjdata([varargin{1} 'xblock'],handles,xdso); %store data
end

% --------------------------------------------------------------------
function splitcalval_callback(h,eventdata,handles,varargin)

[junk,fig] = experimentreadr(evrigui(handles.analysis));
adopt(handles,fig);

% --------------------------------------------------------------------
function augmentval_callback(h,eventdata,handles,varargin)
%Augment validation to calibration. Can only get here if data is loaded and
%not x cal/val, y cal/val, all loaded.
if ~isempty(varargin)
  xToAdd = varargin{1};
  yToAdd = varargin{2};
  haveValData = 0;
else
  xToAdd = getobjdata('validation_xblock',handles);
  yToAdd = getobjdata('validation_yblock',handles);
  haveValData = 1;
end
if isloaded('xblock', handles)
  x = getobjdata('xblock',handles);
end
if isloaded('yblock', handles)
  y = getobjdata('yblock', handles);
end
newx = [];
newy = [];
try
  new_val = matchvars(x,xToAdd);
  newx = augment(1,x,new_val); 
  if ~isempty(yToAdd)
    new_val = matchvars(y,yToAdd);
    newy = augment(1,y,new_val);
  end
catch ME
  catError = contains(ME.message, 'All data sets must match in size except dim 1');
  if catError
    erdlgpls(['Unable to augment validation data to calibration data.' ...
      newline 'All data sets must match in size except dim 1'],'Augment Error');
  else
    erdlgpls('Unable to augment validation data to calibration data.','Augment Error');
  end
  return
end

recalcmodel = isloaded('model',handles);

%Remove val data.
if haveValData
  cleardata_callback(h, eventdata, handles, 'validation_xblock')
  cleardata_callback(h, eventdata, handles, 'validation_yblock')
end
clearmodel(handles.analysis, [], handles, []);
cleardata_callback(h, eventdata, handles, 'xblock')
cleardata_callback(h, eventdata, handles, 'yblock')

%Add new cal data.
if ~isempty(newx)
loaddata_callback(h,[],handles,'xblock',newx);
end

if ~isempty(newy)
  loaddata_callback(h,[],handles,'yblock',newy);
end

%Recalculate.
if recalcmodel
  calcmodel_Callback(handles.analysis, [], handles, []);
end

% --------------------------------------------------------------------
function datachangecallback(id)
%TODO: rewrite datachangecallback for cal/val simultaneous analysis
handles = guidata(id.source);

switch id.properties.itemType
  case {'xblock' 'yblock'}

    switch id.properties.itemType
      case 'xblock'
        clearmod = ~isempty(id.object) & ~iscaldata(handles,id.object,nan);
      case 'yblock'
        clearmod = ~isempty(id.object) & ~iscaldata(handles,nan,id.object);
    end
    if clearmod
      autoclear(handles)
      clearmodel(handles.analysis,[],handles)
    end
    setappdata(handles.analysis,'eigsnr',[]);

  case {'validation_xblock' 'validation_yblock'}

    if isloaded('prediction',handles)
      %if a prediction had been made, clear it now and update figures
      setobjdata('prediction',handles,[]);
      fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
      if ~isempty(fn);
        feval(fn,'updatefigures',handles.analysis);
      end
    end

end

toolbarupdate(handles);
updateprepro(handles);
updatestatusimage(handles);
updatecrossvallimits(handles)

% --------------------------------------------------------------------
function dataincludechange(id)
%input h is the handle of the analysis figure

handles = guidata(id.source);

forceclear = getappdata(handles.analysis,'cleartestonchange');
if isempty(forceclear); forceclear = 0; end

switch id.properties.itemType
  case 'xblock'  %includ on x-block?
    if isloaded('yblock',handles);  %do we have a y-block?
      x = getobjdata('xblock',handles);
      y = getobjdata('yblock',handles);
      y.includ{1} = x.includ{1};                          %copy includ from x samples to y-block
      setobjdata('yblock',handles,y);
    end
    autoclear(handles)
    clearmodel(handles.analysis,[],handles)
    
    %Remove reference to Y from X Block include field settings.
    setappdata(handles.analysis,'lastusedxcolumn',[]);
    setappdata(handles.analysis,'lastusedxinclude',[]);

  case 'yblock'  %includ on y-block or combo
    x = getobjdata('xblock',handles);
    y = getobjdata('yblock',handles);
    x.includ{1} = y.includ{1};                          %copy includ from y samples to x-block
    setobjdata('xblock',handles,x);
    autoclear(handles)
    clearmodel(handles.analysis,[],handles)

  case 'validation_xblock'
    if isloaded('validation_yblock',handles);  %do we have a y-block?
      x = getobjdata('validation_xblock',handles);
      y = getobjdata('validation_yblock',handles);
      y.includ{1} = x.includ{1};                          %copy includ from x samples to y-block
      setobjdata('validation_yblock',handles,y);
    end
    
    %Remove reference to Y from X Block include field settings.
    setappdata(handles.analysis,'validation_lastusedxcolumn',[]);
    setappdata(handles.analysis,'validation_lastusedxinclude',[]);
    
  case 'validation_yblock'
    x = getobjdata('validation_xblock',handles);
    y = getobjdata('validation_yblock',handles);
    x.includ{1} = y.includ{1};                          %copy includ from y samples to x-block
    setobjdata('validation_xblock',handles,x);

  case {'xblockprepro' 'yblockprepro'}
    %preprocessing change - copy to other blocks
    incl = id.object.include;
    b = id.properties.itemType(1);
    x = getobjdata([b 'block'],handles);
    id.properties.includechangecallback = '';
    for m = 1:length(id.object.include);
      x.include{m} = incl{m};
    end
    setobjdata([b 'block'],handles,x);

    %and copy sample include field to other block
    if b=='x'
      ob = 'y';
    else
      ob = 'x';
    end
    if isloaded([ob 'block'],handles)
      y = getobjdata([ob 'block'],handles);
      y.include{1} = incl{1};
      setobjdata([ob 'block'],handles,y);
    end
    return;
    
end

if isloaded('prediction',handles) & strcmp(id.properties.itemType,'validation_xblock')
  test = getobjdata('prediction',handles);
  valx = getobjdata('validation_xblock',handles);
  if ~forceclear;  %flag that we should ALWAYS clear test (don't try intelligent reconciliation)

    if strcmp(getappdata(handles.analysis,'curanal'),'mpca')
      sampledim = 3;
      vardim = 1:2;
    else
      sampledim = 1;
      vardim = 2;
    end

    %but do handle changes to included SAMPLES
    if ~isempty(test) & (length(valx.includ{sampledim,1}) ~= length(test.detail.includ{1,1}) | any(valx.includ{sampledim,1} ~= test.detail.includ{1,1}));  
      %any change in sample dim?

      if isfield(test.detail,'rmsep')
        test.detail.rmsep = [];
      end
      test.detail.includ{1,1} = valx.includ{sampledim,1};
      setobjdata('prediction',handles,test);
      fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
      if ~isempty(fn);
        feval(fn,'updatefigures',handles.analysis);
      end
    else
      %not a change in sample dim? force clear of application
      forceclear = 1;
    end
  end
  
  if forceclear;  %flag that we should ALWAYS clear test (don't try intelligent reconciliation)

    setobjdata('prediction',handles,[]);

    fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
    if ~isempty(fn);
      feval(fn,'updatefigures',handles.analysis);
    end
    toolbarupdate(handles);
  end

end

updatestatusimage(guidata(handles.analysis))
updateprepro(handles);

% --------------------------------------------------------------------
function exitpca(h, eventdata, handles, varargin)
% Callback for closereqfunction

fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);

try
  %Model check.
  if ~modelsaved(handles);
    ans=evriquestdlg('Model not saved. What do you want to do?', ...
      'Model Not Saved','Quit Without Saving','Save & Quit','Cancel','Quit Without Saving');
    switch ans
      case {'Cancel'}
        return
      case {'Save & Quit'}
        if isempty(savemodel(handles.savemodel, [], handles, []))
          return
        end
    end
  end

  if ishandle(getappdata(handles.analysis,'preprocess'))
    delete(getappdata(handles.analysis,'preprocess'))
  end
  if ishandle(getappdata(handles.analysis,'preprocessyblk'))
    delete(getappdata(handles.analysis,'preprocessyblk'))
  end
  if ishandle(getappdata(handles.analysis,'crossvalgui'))
    delete(getappdata(handles.analysis,'crossvalgui'))
  end
  if ishandle(getappdata(handles.analysis,'varcapfig')) & strcmp(getappdata(getappdata(handles.analysis,'varcapfig'),'figuretype'),'varcap')
    delete(getappdata(handles.analysis,'varcapfig'))
    setappdata(handles.analysis,'varcapfig',[])
  end

  %GUI deselect.
  if ~isempty(fn);
    feval(fn,'gui_deselect',h,eventdata,handles,varargin);
  end
  %GUI Close figures.
  if ~isempty(fn);
    feval(fn,'closefigures',handles);
  end

  %close all children
  children = getappdata(handles.analysis,'staticchildplot');
  for j=findobj(handles.analysis)';   %find children in ANY sub-object
    children=[children getappdata(j,'children')];
  end
  children = children(ishandle(children));
  children = children(ismember(char(get(children,'type')),{'figure'}));
  close(children);

  %unlink all data
  mydata = linkshareddata(handles.analysis);
  for j=1:size(mydata,1)
    linkshareddata(mydata{j,1},'remove',handles.analysis);
  end
  %Set stat data/modl to 'none' because position manager will call into
  %resize and genreate error when can't find data/modl.
  setappdata(handles.analysis,'statmodl','none');
  
  %hide flowchart (for correct position)
  flowchart_callback(handles,'hide');
  %Save figure position.
  positionmanager(handles.analysis,'analysis','set')
  
  %Need to run through delete table mehtod to avoid ugly java error when
  %row column header has non-empty string.
  pause(.2)%For some reason need a pause here for ML 7.0.4 otherwise error.
  mytbl = getappdata(handles.analysis,'ssqtable');
  delete(mytbl)

catch
end

drawnow;
if ishandle(handles.analysis)
  delete(handles.analysis)
end

browse reactivate  %bring browse to front if it already exists

%---------------------------------------------------------------------
function dropCallbackFcn(obj,ev,varargin)
%Parse dnd object then call drop.

handles = guihandles(varargin{1});

dropdata = drop_parse(obj,ev,'',struct('concatenate','on'));%call w/ empty string to return data.
if isempty(dropdata{1})
  %Probably error.
  %TODO: Process workspace vars.
  return
end

if strcmp(dropdata{1},'treenode')
  %Droping single cache item or multiple items from workspace.
  dropnode = dropdata{end,2};
  myval = evrijavamethodedt('getValue',dropnode);
  if strfind(myval,'cachestruct|')
    %Dropping cache item.
    loadcacheitem(handles.analysis, [], handles)
  elseif strfind(myval,'demo/')
    %Dropping demo node, spoof call to tree dbl click.
    myname = strrep(myval,'demo/','');
    mystruct.val = 'demo';%Fake the struct.
    tree_double_click(handles.analysis,myname,mystruct,[])
  else
    %Drop workspace node.
    myud = get(dropnode,'UserData');
    if ~isempty(myud) & isstruct(myud) & isfield(myud,'location') & strcmp(myud.location,'workspace')
      %Check for multiple items.
      myvars = browse('get_multiple_tree_selections',findobj(allchild(0),'tag','eigenworkspace'));
      myitems = {};
      for i = 1:length(myvars)
        myitems{i} = evalin('base',myvars(i).name);
      end
      if isempty(myitems)
        return;
      end
      drop(handles.analysis, [], handles, myitems{:});
    end
    bfig = findobj(allchild(0),'tag','eigenworkspace');
    if ~isempty(bfig)
      myvar = browse('get_multiple_tree_selections',bfig);
    end
  end
else
  %Probably dropping a file.
  drop(handles.analysis, [], handles, dropdata{:,2})
end

%---------------------------------------------------------------------
function pointer(h,type)

if isnumeric(type)
  if type
    type = 'watch';
  else
    type = 'arrow';
  end
end
set(h,'pointer',type);
setappdata(h,'savedpointer',type);

%---------------------------------------------------------------------
function drop(h, eventdata, handles, varargin)

%If trying to load a prediction then make sure data and model are available
%first. Assumes only pred is being dropped (from cache viewer).
group = '';
pointer(handles.analysis,1);
set(handles.helpwindow,'String','Loading Items... Please Wait...');   %blank help window
if ismodel(varargin{1}) & ...
    length(varargin{1}.modeltype)>4 & ...
    strcmp(varargin{1}.modeltype(end-4:end),'_PRED')
  mypred = varargin{1};
  if length(varargin)==1
    %Dropping a prediction with no other inputs so try to load related
    %cached items.
    itemfound = dropcacheitems(mypred,'prediction',handles);
    if ~itemfound
      %Manually load pred just as if user had used context menu to load.
      loadtest(h, eventdata, handles, mypred);
    end
    pointer(handles.analysis,0);
    return
  end
elseif ~ismodel(varargin{1}) & ~ispreprocessing(varargin{1}) & isstruct(varargin{1})
  %not a model, but a structure? Extract individual fields and attempt to
  %load
  st = varargin{1};
  fylds = fieldnames(st)';
  for f = 1:length(fylds);
    varargin{f} = st.(fylds{f});
  end
elseif iscell(varargin{1}) & length(varargin{1})>=2 & iscell(varargin{1}{2})
  %  {  model  {data...} ... }
  % model cache export object
  temp = varargin{1};
  varargin = [temp(1) temp{2} temp(3:end)];
  empty = cellfun('isempty',varargin);
  varargin(empty) = [];
  group = 'Calibration';
end

%first check for a model
clr = false(1,length(varargin));
mymodel = [];
for j = 1:length(varargin);
  if ismodel(varargin{j})
    if any(clr);
      evrimsgbox({'Only one model may be loaded at a time.','Additional models ignored.'},'Load Model','warn');
      break;
    end
    mymodel = varargin{j};
    loaded = loadmodel(h, eventdata, handles, mymodel,1); %load non-silently
    if ~loaded
      %failure to load a model cancels all other load events
      return;
    end
    handles = guidata(h);
    clr(j) = 1;
  end
end
varargin(clr) = [];  %clear models from varargin

%check for preprocessing
clr = false(1,length(varargin));
ppblock = 'x';
for j = 1:length(varargin);
  if ispreprocessing(varargin{j})
    if sum(clr)>1;
      evrimsgbox({'Only two preprocessing methods may be loaded at a time.','Additional preprocessing ignored.'},'Load Preprocessing','warn');
      break;
    end
    loadpreprocessing(h, eventdata, handles, ppblock, varargin{j})
    handles = guidata(h);
    clr(j) = 1;
    ppblock = 'y';  %increment to next block
  end
end
varargin(clr) = [];  %clear preprocessing from varargin

%if isempty(varargin) & (strcmp(statdata,'cal') | strcmp(statdata,'none'))
if isempty(varargin)
  %If no other items included with varargin, try loading data associated with a model (if no data exists) from cache.
  if ~isempty(mymodel);
    dropcacheitems(mymodel,'model',handles);
  end
  pointer(handles.analysis,0);
  return
elseif isempty(varargin)
  %Nothing left so retrun.
  pointer(handles.analysis,0);
  return
end

%Now, assume anything else is data and try to load it. Can only load 2 at a
%time for now, otherwise need logic to figure out X and Y and cal and val
%because drop order may not be corret. 

if length(varargin)>2
  evrimsgbox({'No more than two data items may be dropped at a time.','Try dropping the data into the base workspace first.'},'Drop Data Failed','error');
  pointer(handles.analysis,0);
  return;
end

if length(varargin)==2;
  %Loading two blocks, assume x and y.
  if size(varargin{1},2)<size(varargin{2},2)
    %reverse input order if input #1 has fewer columns than input #2 (input
    % 2 is probably the x-block!)
    varargin = varargin([2 1]);
  end
  if isempty(group)
    group = evriquestdlg('Load this data as Calibration or Validation data?','Load Data','Calibration','Validation','Cancel','Calibration');
  end
  switch group
    case 'Calibration'
      loaddata_callback(handles.analysis, [], handles,'xblock', varargin{1});
      loaddata_callback(handles.analysis, [], handles,'yblock', varargin{2});
    case 'Validation'
      loaddata_callback(handles.analysis, [], handles,'validation_xblock', varargin{1});
      loaddata_callback(handles.analysis, [], handles,'validation_yblock', varargin{2});
  end
elseif length(varargin)==1
  %Loading a single block.
  if all(~isloaded({'xblock' 'validation_xblock' 'model'},handles))
    %Nothing loaded = cal
    block = 'Calibration X';
  elseif isloaded('model',handles) & all(~isloaded({'xblock' 'validation_xblock'},handles))
    %Ask xcal or xval
    block = evriquestdlg('Load this data as Calibration X-block or Validation X-block data?','Load Data','Calibration X','Validation X','Cancel','Calibration X');
  elseif inevriautomation
    %in an automation call? check for first empty
    block = 'Calibration X';  %default
    blktypes = {'xblock' 'yblock' 'validation_xblock' 'validation_yblock'};
    desc     = {'Calibration X' 'Calibration Y' 'Validation X' 'Validation Y'};
    for bind = 1:4;
      if ~isloaded(blktypes{bind},handles)
        block = desc{bind};
        break;
      end
    end
  else
    %all other scenarios, use full-featured load data gui
    block = loaddatagui(handles.analysis);
  end
  
  switch block
    case 'Calibration X'
      %try load as x-block
      loaddata_callback(handles.analysis, [], handles,'xblock', varargin{:});
    case 'Calibration Y'
      %try load as y-block
      loaddata_callback(handles.analysis, [], handles,'yblock', varargin{:});
    case 'Validation X'
      %try load as y-block
      loaddata_callback(handles.analysis, [], handles,'validation_xblock', varargin{:});
    case 'Validation Y'
      %try load as y-block
      loaddata_callback(handles.analysis, [], handles,'validation_yblock', varargin{:});
  end
end

toolbarupdate(handles)
printinfo_update(handles)  %update infobox
updatestatusimage(handles)
pointer(handles.analysis,0);

% --------------------------------------------------------------------
function block = loaddatagui(parent)
%Asks user which data block they want to load data into
%I/O: block = loaddatagui

fig = figure('visible','on',...
  'name','Load Data',...
  'tag','loaddatafig',...
  'numbertitle','off',...
  'integerhandle','off',...
  'units','pixels',...
  'menubar','none',...
  'toolbar','none',...
  'position',[520   661   324   140],...
  'color',[0.9412    0.9412    0.9412]);

uicontrol(fig,'style','text','units','pixels','position',[ 15 102 294 30 ],...
  'backgroundcolor',[0.9412    0.9412    0.9412],...
  'fontsize',getdefaultfontsize,'fontweight','bold',...
  'string','Load into which data block?')

b = [];
b(1) = uicontrol(fig,'style','pushbutton','string','Calibration X','backgroundcolor',[0 0.2 0.6],'units','pixels','position',[ 22 61 134 32 ]);
b(2) = uicontrol(fig,'style','pushbutton','string','Calibration Y','backgroundcolor',[0 0.2 0.6],'units','pixels','position',[ 22 22 134 32 ]);
b(3) = uicontrol(fig,'style','pushbutton','string','Validation X','backgroundcolor',[0.4 0 0.6],'units','pixels','position',[ 166 61 134 32 ]);
b(4) = uicontrol(fig,'style','pushbutton','string','Validation Y','backgroundcolor',[0.4 0 0.6],'units','pixels','position',[ 166 22 134 32 ]);
set(b,'fontsize',getdefaultfontsize,'foregroundcolor',[1 1 1],'fontweight','bold','callback','set(gcbf,''userdata'',get(gcbo,''string''));uiresume(gcbf);')

centerfigure(fig,parent);
evriwindowstyle(fig,0,1)
uiwait(fig);

if ~ishandle(fig);
  block = '';
else
  block = get(fig,'userdata');
  delete(fig);
end


% --------------------------------------------------------------------
function itemfound = dropcacheitems(myitem,itemkind,handles)
%Try loading all associated items for a given cache item. I.e., load model
%and data for a given prediction or load data for a given model.
% NOTE: Only load if data is empty.
% Input: 
%    myitem   - (string) name of item.
%    itemkind - (string) type of item being loaded [model | prediciton].
%    handles  - (struct) analysis figure handles.
% OUTPUT:
%    itemfound - Flag for if item not found. 
%

cacheitems = modelcache('find',myitem);
itemfound = 0;

if isempty(cacheitems)
  %Nothing returned from cache.
  if ~isfield(myitem,'datasource')
    return
  end
  links = {};
  for j=1:length(myitem.datasource)
    links{end+1} = safename([myitem.datasource{j}.uniqueid '_' encodedate(myitem.datasource{j}.moddate)]);
  end
  if ~isempty(links)
    cacheitems = [];
    cacheitems.links = struct('target',links);
  end
end

if isempty(cacheitems)
  %nothing found in cache via links OR raw datasource info
  return;
end

pdat = [];
pmod = [];
for i = 1:length(cacheitems.links)
  %Don't generate error if item can't be loaded because un-loadable objects
  %are clearly listed in cache (ticket #550).
  loadable = modelcache('exist',cacheitems.links(i).target);
  if loadable{1}
    pitem = modelcache('get',cacheitems.links(i).target);
    if ~isempty(pitem)
      if isstruct(pitem)
        pmod = pitem;
      else
        pdat = [pdat {pitem}];
      end
    else
      evriwarndlg('Cache item not available for loading prediction. Not items can be loaded.')
      return
    end
  end
end
%figure out which is x and y block becuase we don't know what order they
%my have been returned in from the cache.
if length(pdat)>1
  %Two blocks.
  if strcmp(pdat{1}.name,myitem.datasource{1}.name)
    %Pdat{1} is xblock;
    xblk = pdat{1};
    yblk = pdat{2};
  else
    xblk = pdat{2};
    yblk = pdat{1};
  end
elseif ~isempty(pdat)
  xblk = pdat{1};
  yblk = [];
else
  xblk = [];
  yblk = [];  
end

switch itemkind
  case 'prediction'
    %Clear data so we don't accidentally end up with confused y-block.
    clearboth(handles.analysis, [], handles, 'val')

    loaddata_callback(handles.analysis, [], handles,'validation_xblock', xblk);
    loaddata_callback(handles.analysis, [], handles,'validation_yblock', yblk);
    loadmodel(handles.analysis, [], handles, pmod,1); %load non-silently
    %Load cal data.
    handles = guidata(handles.analysis);%Need to update handles after load model because some controls may have been recreated with new handles.
    %Try loading cal data.
    try
      dropcacheitems(pmod,'model',handles);
    catch
      evriwarndlg('Could not load Calibration data associated with Prediction');
      return
    end
    setobjdata('prediction',handles,myitem);
    %setappdata(handles.analysis,'statmodl','calold')
    toolbarupdate(handles)
    updatestatusimage(handles)
    itemfound = 1;

  case 'model'
    if iscaldata(handles,xblk,yblk); %do NOT load this data if it isn't the calibration data
      if ~isempty(xblk) & ~isloaded('xblock',handles)
        loaddata_callback(handles.analysis, [], handles,'xblock', xblk);
        itemfound = 1;
      end
      if ~isempty(yblk) & ~isloaded('yblock',handles)
        loaddata_callback(handles.analysis, [], handles,'yblock', yblk);
        itemfound = 1;
      end
      if itemfound
        updatecrossvallimits(handles)%Some methods modify crossval gui.
      end
    end
    
  otherwise

end

% --------------------------------------------------------------------
function out = ispreprocessing(obj)

if isstruct(obj) & isempty(setdiff(fieldnames(obj),fieldnames(preprocess('default'))))
  out = true;
else
  out = false;
end

% --------------------------------------------------------------------
function loaderr = loaddata_callback(h, eventdata, handles, block, varargin)
%Load data. Test for existing data, overwrite warning if data
%exits. Test for existing model, goto test/apply mode if model loaded.
%
% Use same terminology as shareddata:
%   block = ['xblock' | 'yblock' | 'validation_xblock' |'validation_yblock']
%
% If varargin is empty, user is prompted for data to load, if it isn't
% empty, it is assumed to be one of the following:
%    ..., data)
%    ..., data, name)  %where name is used for DSO name if empty
% Where data is either a matrix or a DSO.
%
% Output 'loaderr' if true when cancel or other error in loading. Use this
% flag in loadboth function.

loaderr = false;

if ~ismember(block,{'xblock' 'yblock' 'validation_xblock' 'validation_yblock'})
  %Fatal error for bug checking.
  error('Unrecognized block being loaded. Block must be one of the following [''xblock'' | ''yblock'' | ''validation_xblock'' |''validation_yblock''].');
end

if getappdata(handles.analysis,'apply_only') & ismember(block,{'xblock' 'yblock'})
  %load is disabled, exit now WITHOUT notice. It is assumed that the only
  %way we got here was that the user got around the menu and other
  %disabling code (or some other outside method tried to laod xblock or
  %yblock data)
  return
end

%execute any PRE loaddata addon actions 
fns = evriaddon('analysis_pre_loaddata_callback');
for j=1:length(fns)
  feval(fns{j},handles.analysis,block);
end

%Need opposite block for checking later.
isy = false;%Flag for yblock.
if ~isempty(findstr(block,'x'))
  block_op = strrep(block,'x','y');
else
  isy = true;
  block_op = strrep(block,'y','x');
end

augbutton = '';
if isloaded(block,handles)
  augbutton = evriquestdlg(['There is existing ' upper(block) ' data. Do you wish to overwrite, augment, or cancel?'],...
    'Continue Load Data','Overwrite','Augment','Cancel','Overwrite');
  if strcmp(augbutton,'Cancel')
    loaderr = true;
    return
  end
end

isval = false;%Flag for validation data.
if ~isempty(findstr(block,'validation'))
  isval = true;
end

%lddlgpls cell settings.
if isy
  dlgsetting = {'double' 'dataset' 'logical'};
else
  dlgsetting = {'double' 'dataset'};
end

%check if trying to load into Validation Y-block and use in line 2843
isvaly = false;
if isval & isy
  isvaly = true;
end
h = handles.analysis;  %input h refers to the uimenu load data
%Load Data Into the GUI
if isempty(varargin)
  [rawdata,name,location] = lddlgpls(dlgsetting,['Select ' upper(block) ' Data']);
  if isempty(rawdata)
    return
  end
else
  rawdata = varargin{1};
  if length(varargin)>1;
    name = varargin{2};
  else
    name = '';
  end
end
if ~isempty(rawdata)
  if ~isa(rawdata,'dataset')
    if isnumeric(rawdata)
      rawdata             = dataset(rawdata);
      rawdata.name        = name;
      rawdata.author      = '';
    else
      erdlgpls('Item not numeric. Data not loaded.','Error on Load.')
      rawdata = [];
      return
    end
  end
  
  if isempty(rawdata.name) && ~isempty(name)
    rawdata.name = name;
  end
  
  if ~isreal(rawdata.data)
    qans = evriquestdlg('Data contains imaginary portions. This data may be ignored during analysis.','Imaginary Data Found',...
      'Continue', 'Cancel', 'Cancel');
    if strcmp(qans,'Cancel')
      loaderr = true;
      return
    end
  end

  if strcmp(augbutton,'Augment')
    %Augment on rows or columns.
    method = evriquestdlg('Augment in which direction? Make it new:', ...
      'Augment Data', 'Samples', 'Variables','Cancel','Samples');
    if strcmp(method,'Cancel')
      loaderr = true;
      return
    end
    
    if strcmp(method,'Samples')
      if isloaded(block_op,handles)
        augquest = evriquestdlg(['Augment will cause data size mismatch. Data cannot be augmented until opposite block cleared.'],'Clear on Augment',...
          'Clear Block', 'Cancel', 'Clear Block');
        if strcmp(augquest,'Clear Block')
          cleardata_callback(h, eventdata, handles, block_op)
        else
          loaderr = true;
          return
        end
      end
    end
    %Augment data.
    olddata = getobjdata(block,handles);
    
    if strcmp(method,'Samples')
      %augment as new rows
      rawdata = augment(1,olddata,rawdata);
    elseif strcmp(method,'Variables')
      %augment as new columns (match samples if posible)
      tempolddata = permute(olddata,[2 1 3:ndims(olddata)]);
      rawdata     = permute(rawdata,[2 1 3:ndims(rawdata)]);
      [rawdata,unmap] = matchvars(tempolddata,rawdata,struct('axismode','discrete'));
      rawdata = permute(rawdata,[2 1 3:ndims(rawdata)]);%rawdata';
      if ~isempty(unmap)
        rawdata = cat(2,olddata,rawdata);
      else
        %No label or axisscale so pad out with NaN.
        rawdata = augmentdata(2,olddata,rawdata);
      end
    else
      loaderr = true;
      return
    end
  end
  
  if isempty(rawdata.data)
    erdlgpls('Item empty. Data not loaded.','Error on Load.')
    rawdata = [];
  elseif isloaded(block_op,handles) & size(getobjdata(block_op,handles),1)~=size(rawdata.data,1);
    if isy & size(rawdata.data,2)==size(getobjdata(block_op,handles),1);
      %Y block may come in as row OR column vector so try to transpose.
      %TODO: add logic to align y-block to x-block using labels (if
      %present)
      rawdata = rawdata';
    else
      qans = evriquestdlg('Number of samples must match in X- and Y-blocks. Data cannot be loaded until opposite block cleared.','Block size mismatch.',...
               'Clear Block', 'Cancel', 'Clear Block');
      if strcmp(qans,'Clear Block')
        cleardata_callback(h, eventdata, handles, block_op)
      else 
        loaderr = true;
        return
      end
    end
  elseif ~isvaly & numel(rawdata.data)==1
    erdlgpls('Item must be vector or matrix. Block not loaded.','Error on Load.')
    loaderr = true;
    rawdata = [];    
  elseif isy & ndims(rawdata.data)>2
    erdlgpls('Item must be 2-way matrix. Y-block not loaded.','Error on Load.')
    loaderr = true;
    rawdata = [];
  end

  if ~isempty(rawdata)
    statmodl = getappdata(handles.analysis,'statmodl');
    if ~isval
      %Calibration data being loaded.
      if ~strcmp(statmodl,'none')
        switch block
          case 'xblock'
            testblocks = {rawdata nan};
          case 'yblock'
            testblocks = {nan rawdata};
          otherwise  %should never get here...
            testblocks = {};
        end
        if ~iscaldata(handles,testblocks{:});
          clearmodel(handles.analysis,[],handles)
          statmodl = 'none';
        else
          statmodl = 'calold';
        end
      end
      setappdata(handles.analysis,'statmodl',statmodl);
    else
      %Validation data being loaded, no change to statmodl.
    end

    %WARNING!!! MAKE NO CHANGES to the dataset when loading it. The moddate
    %must remain EXACTLY as it was when loaded or we will break the
    %model.datasource connection to its calibration data!!!
    
    setobjdata(block,handles,rawdata,getdataprops);
    if ~isval
      updatepreprocatalog(handles);  %make sure preprocessing works for this data
    end

    handles.datasource = {getdatasource(rawdata) []};

    setobjdata('prediction',handles,[]);

    if ~isval 
      if ~(strcmpi(getappdata(handles.analysis,'statmodl'),'calold'))
        %update settings if validation x-block was changed
        updatecrossvallimits(handles);
      else
        %Enable crossval gui.
        crossvalgui('enable',getappdata(handles.analysis,'crossvalgui'));
      end
    end

  end

end

if isval
  if isloaded('model',handles)
    modl = getobjdata('model',handles);
    if isfieldcheck('modl.detail.rmsep',modl) & ~isempty(modl.detail.rmsep)
      %Clear rmsep from model if new test data (ticket 1170).
      modl.detail.rmsep = [];
      setobjdata('model',handles,modl);
    end
  end
end

setappdata(handles.analysis,'eigsnr',[]);
toolbarupdate(handles);
updatestatusimage(handles)

fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
if ~isempty(fn);
  feval(fn,'updatefigures',handles.analysis);
  feval(fn,'updatessqtable',handles);
end

if(strcmpi(augbutton,'Overwrite') | strcmpi(augbutton,'Augment'))
  cvgui = getappdata(handles.analysis,'crossvalgui'); %initiate cross-validation gui
  cvsettings = getappdata(cvgui,'cvsettings');
  if (strcmpi(cvsettings.cv,'Custom'))
    defaultcv = analysis('options');
    defaultcv = defaultcv.defaultcv;
    cvsettings.cv = 'Vet';
    cvsettings.cvi=[];
    cvsettings.split=2;
    if (isa(defaultcv,'char')) % old defaultcv syntax: 'Vet'
      cvsettings.cv = defaultcv; 
    elseif (isa(defaultcv,'cell')) % new defaultcv syntax: {'Vet' [10] [1]}
    if (isa(defaultcv{1},'char'))
      cvsettings.cv = defaultcv{1};
    end
    else
    end
    
    % Set the cvgui to default value
    setappdata(handles.analysis,'crossvalgui',cvgui);
    setappdata(cvgui,'cvsettings',cvsettings);
    setappdata(handles.analysis,'enable_crossvalgui','on');
    crossvalgui('resetfigure',cvgui);
    setobjdata(block,handles,rawdata,getdataprops);
  end
end

setappdata(handles.analysis, ['originalLoadedData_' block], rawdata);

%execute any POST loaddata addon actions 
fns = evriaddon('analysis_post_loaddata_callback');
for j=1:length(fns)
  feval(fns{j},handles.analysis,block);
end

%-----------------------------------
function loadboth(h, eventdata, handles, varargin)
%Check to see if loading validation data from context menu. Note, use
%findstr because of html in validation label.

if nargin<4
  %Calling clear both from statusbox image so determine 4th input.
  axh = findobj(allchild(handles.analysis),'tag','statusimage');
  [btn_name, group] = status_location(axh);
  if strcmpi(group,'validation')
    varargin{1} = 'val';
  else
    varargin{1} = 'cal';
  end
end

if strcmpi(varargin{1},'val')
  xblk = 'validation_xblock';
  yblk = 'validation_yblock';
elseif strcmpi(varargin{1},'cal')
  xblk = 'xblock';
  yblk = 'yblock';
end

augbutton = '';
if isempty(getappdata(handles.analysis, 'loadbothwarn')) & isloaded(xblk,handles) & ~isloaded(yblk,handles)
  evrimsgbox('Clearing both X and Y blocks (This warning will will be given only once).','Clear X and Y','warn','modal');
  setappdata(handles.analysis, 'loadbothwarn',1)
elseif isloaded(xblk,handles) & isloaded(yblk,handles)
  augbutton = evriquestdlg(['There is existing X and Y data. Do you wish to overwrite, augment, or cancel?'],...
    'Continue Load Data','Overwrite','Augment','Cancel','Overwrite');
  if strcmp(augbutton,'Cancel')
    return
  end
end

if isempty(augbutton) | strcmp(augbutton, 'Overwrite')
  clearboth(h, eventdata, handles, varargin)
  
  loaderr = loaddata_callback(h, eventdata, handles,xblk);
  if isloaded(xblk,handles) & ~loaderr
    loaddata_callback(h, eventdata, handles,yblk);
  end
elseif strcmp(augbutton, 'Augment')
  
  [xrawdata,xname,xlocation] = lddlgpls({'double' 'dataset'},'Select X-Block Data');
  if isempty(xrawdata)
    return
  end
  [yrawdata,yname,ylocation] = lddlgpls({'double' 'dataset' 'logical'},'Select Y-Block Data');
  if isempty(yrawdata)
    return
  end
  augmentval_callback(h,eventdata,handles,xrawdata, yrawdata);
end

%-----------------------------------
function loadoptions(h, eventdata, handles, varargin)
%Load options structure.
if nargin<4
  [rawopts,name,location] = lddlgpls({'struct'},'Select Options Structure');
else
  rawopts = varargin{1};
end

if isempty(rawopts)
  return
end
curanalysis = getappdata(handles.analysis,'curanal');

if isfield(rawopts,'functionname') & strcmp(rawopts.functionname, curanalysis)
  setopts(handles,curanalysis,rawopts);
  fn  = analysistypes(curanalysis,3);
  if ~isempty(fn);
    feval(fn,'optionschange',handles.analysis);
  end
else
  if ~isfield(rawopts,'functionname')
    erdlgpls([{'Selected item is not a valid options structure.'}],'Load Options Error');
  else    
    erdlgpls({['Seleted item contains ' upper(rawopts.functionname) ' options and can not be used with analysis method ' upper(curanalysis) '. Change analysis method before loading.']},'Load Options Error');
  end
end

%-----------------------------------
function loadpreprocessing(h, eventdata, handles, varargin)
%Load preprocessing structure.
if nargin<4
  %assume x if nothing given
  varargin{1} = 'x';
end

if nargin<5
  [newpp,name,location] = lddlgpls({'struct'},['Select ' upper(varargin) '-Block Preprocessing Structure']);
  if isempty(name) %if NAME is empty, they canceled out (note: allows loading of empty preprocessing)
    return;
  end
else
  newpp = varargin{2};
  name = 'n/a';
end

if ~isempty(newpp) & ismodel(newpp)
  try
    %got a model, see if we can extract preprocessing from it
    if isfieldcheck(newpp,'newpp.detail.options.preprocessing');
      switch varargin{1}
        case 'x'
          newpp = newpp.detail.options.preprocessing{1};
        case 'y'
          newpp = newpp.detail.options.preprocessing{2};
      end
    elseif  isfieldcheck(newpp,'newpp.detail.preprocessing');
      switch varargin{1}
        case 'x'
          newpp = newpp.detail.preprocessing{1};
        case 'y'
          newpp = newpp.detail.preprocessing{2};
      end
    end
  catch
    newpp = [];
  end
end

try
  newpp = preprocess('validate',newpp);
catch
  erdlgpls('Invalid preprocessing structure','Load Preprocessing Error');
  name = '';
end

if isempty(name)
  %Cancel
  return
end

switch varargin{1}
  case 'x'
    curpp = getappdata(handles.preprocessmain,'preprocessing');
    if comparevars(curpp,newpp)
      %No changes.
      return
    else
      setappdata(handles.preprocessmain,'preprocessing',newpp)
    end
  case 'y'
    curpp = getappdata(handles.preproyblkmain,'preprocessing');
    if comparevars(curpp,newpp)
      %No changes.
      return
    else
      setappdata(handles.preproyblkmain,'preprocessing',newpp)
    end
end

%Remove model and update any plotted data if pp has changed.
preprocesschange(handles,varargin{1})

% --------------------------------------------------------------------
function varargout = savepreprocessing(h, eventdata, handles, varargin)
if nargin<4
  %assume x if nothing given
  varargin{1} = 'x';
end

switch varargin{1}
  case 'x'
    [what,where] = svdlgpls(getappdata(handles.preprocessmain,'preprocessing'),'Save Preprocessing Structure');
  case 'y'
    [what,where] = svdlgpls(getappdata(handles.preproyblkmain,'preprocessing'),'Save Preprocessing Structure');
end
varargout{1} = what;

%-----------------------------------------------------------------
function preprocesssetdefault(h, eventdata, handles, varargin)
if nargin<4
  %assume x if nothing given
  varargin{1} = 'x';
end

switch varargin{1}
  case 'x'
    pp = getappdata(handles.preprocessmain,'preprocessing');
    setplspref('analysis','defaultxpreprocessing',pp)
  case 'y'
    pp = getappdata(handles.preproyblkmain,'preprocessing');
    setplspref('analysis','defaultypreprocessing',pp)
end


%-----------------------------------------------------------------
function opts = getoptshistory(handles,curanalysis)

optionshistory = getappdata(handles.analysis, 'analysisoptions_history');
if isfield(optionshistory,curanalysis);
  opts = getfield(optionshistory,curanalysis);
else
  opts = [];
end

%-----------------------------------------------------------------
function setopts(handles,curanalysis,opts)

if isfield(opts,'rawmodel'); opts = rmfield(opts,'rawmodel'); end
setappdata(handles.analysis,'analysisoptions',opts)

if isempty(curanalysis);
  curanalysis = getappdata(handles.analysis,'curanal');
end
if isempty(curanalysis) | ~isstr(curanalysis);
  return;
end

optionshistory = getappdata(handles.analysis, 'analysisoptions_history');
optionshistory = setfield(optionshistory,curanalysis,opts);
setappdata(handles.analysis, 'analysisoptions_history',optionshistory);

%-----------------------------------------------------------------
function fileimport(h,eventdata,handles,varargin)

% tempobj = uicontrol('visible','off');  %create a temporary uicontrol to store data
% editdshandle = editds(tempobj,'invisible');
% set(editdshandle,'visible','off');
% editds('fileimportselect',editdshandle);drawnow;
% delete(editdshandle);
% data = getappdata(tempobj,'dataset');
% delete(tempobj);

if ~isempty(findstr(get(h,'tag'),'status_'))
  %Loading from status menu so construct varargin from tag/label info.
  if ~isempty(findstr(get(handles.status_loadname,'Label'),'Validation'))
    varargin{1} = [varargin{1} '_val'];
  end
end

%if there is a default, use it
if length(varargin)<2 | isempty(varargin{2})
  options = analysis('options');
  if strcmp(options.defaultimportmethod,'prompt');
    varargin{2} = '';
  else
    varargin{2} = options.defaultimportmethod;
  end
end

%Some importers can specify data block so include in call to autoimport.
aopts = autoimport('options');
aopts.block = 'x';
if ismember(varargin{1},{'y' 'yblock' 'y_val' 'validation_yblock'})
  aopts.block = 'y';
end

if ~strcmpi(getappdata(handles.analysis,'curanal'),'clsti') | (any(strcmpi(varargin{1},{'x_val' 'validation_xblock'})) | any(strcmpi(varargin{1},{'y_val' 'validation_yblock'})))
  data = autoimport(varargin{2:end},aopts);
  if isempty(data)  %canceled out of import?
    return;
  end
else
  return;
end


switch varargin{1}
  case {'x' 'xblock'}
    loaddata_callback(h,[],handles,'xblock',data);
  case {'y' 'yblock'}
    loaddata_callback(h,[],handles,'yblock',data);
  case {'x_val' 'validation_xblock'}
    loaddata_callback(h,[],handles,'validation_xblock',data);
  case {'y_val' 'validation_yblock'}
    loaddata_callback(h,[],handles,'validation_yblock',data);
end

%-----------------------------------------------------------------
function fileloadimage(h,eventdata,handles,varargin)
%tempobj = uicontrol('visible','off');  %create a temporary uicontrol to store data
%editdshandle = editds(tempobj,'invisible');

editdshandle = editds([],'invisible');
set(editdshandle,'visible','off');
editds('fileimgload',editdshandle);
data = editds('getdataset',editdshandle);
close(editdshandle);

if isempty(data);  %canceled out of import?
  return;
end

if strcmp(varargin{1},'x')
  loaddata_callback(h,[],handles,'xblock',data);
else
  loaddata_callback(h,[],handles,'yblock',data);
end

%-----------------------------------------------------------------
function newdata(h,eventdata,handles,varargin)

%determine default size
sz = [];
switch varargin{1}
  case {'y' 'yblock'}
    x = getobjdata('xblock',handles);
    if ~isempty(x)
      sz = [size(x,1),1];
    end
  case {'y_val' 'validation_yblock'}
    x = getobjdata('validation_xblock',handles);
    if ~isempty(x)
      sz = [size(x,1),1];
    end
end

editdshandle = editds([],'invisible');
set(editdshandle,'visible','off');
editds('filenew',editdshandle,sz);
data = editds('getdataset',editdshandle);
close(editdshandle);

if isempty(data);  %canceled out of new?
  return;
end

switch varargin{1}
  case {'x' 'xblock'}
    loaddata_callback(h,[],handles,'xblock',data);
  case {'y' 'yblock'}
    loaddata_callback(h,[],handles,'yblock',data);
  case {'x_val' 'validation_xblock'}
    loaddata_callback(h,[],handles,'validation_xblock',data);
  case {'y_val' 'validation_yblock'}
    loaddata_callback(h,[],handles,'validation_yblock',data);
end

% --------------------------------------------------------------------
function updatecrossvallimits(handles)
%set cross-validation slider limits

options = analysis('options');
rawdata = getobjdata('xblock',handles);
cvigui  = getappdata(handles.analysis,'crossvalgui');
if ~ishandle(cvigui)
  %if not there, we may be closing down, just exit
  return;
end

curanal = getappdata(handles.analysis,'curanal');
if ~isempty(rawdata)
  switch lower(curanal)
    case 'ann'
      pc = options.maximumfactors;
    case 'anndl'
      pc = 100;   % this is the default unit for both sklearn and tensorflow
    otherwise
      pc     = min([size(rawdata,1) size(rawdata,2) options.maximumfactors]);    %lv slider
      if pc<1
        pc = 1;
      end
  end
  nsamps = size(rawdata,1); %split slider
  crossvalgui('setmaximum',cvigui,pc,nsamps,pc);
  crossvalgui('enable',cvigui);
  
  %Post setup settings.
  switch lower(curanal)
    case 'ann'
      %Force LVs (nodes for ANN) to be 1 since if it's set to higher values
      %it's majorly slow.
      [cv,lv,split,iter,cvi] = crossvalgui('getsettings',cvigui);
      crossvalgui('forcesettings',cvigui,cv,1,split,iter,cvi);
  end
else
  crossvalgui('disable',cvigui);
end

%-----------------------------------
function loaderr = loadtest(h, eventdata, handles, varargin)
%Load a prediction.

if isloaded('prediction',handles)
  button = evriquestdlg(['There is an existing prediction structure. Do you wish to overwrite it?'],...
    'Continue Load Prediction','Yes','No','Yes');
  if strcmp(button,'No')
    loaderr = true;
    return
  end
end

if length(varargin)==0;
  [mypred,name,location] = lddlgpls('struct','Select Prediction');
else
  mypred = varargin{1};
end

if isempty(mypred);  return; end

%check mypred is legal model
if ~ismodel(mypred) 
  erdlgpls('Not a valid prediction','Error on Prediction Load')
  return
end

modl = getobjdata('model',handles);
if isempty(modl)
  %If loading pred created using object notation (.apply) then this takes
  %precedence.
  modl = mypred.parent;
  if isempty(modl)
    %Try looking in modelcache.
    objs = modelcache('getparents',mypred);
    for i = 1:length(objs)
      if ismodel(objs{i})
        modl = objs{i};
      end
    end
  end
  
  if ~isempty(modl)
    %Parent model included with pred object so load that.
    loaded = loadmodel(h, eventdata, handles, modl,1); %load non-silently
    if ~loaded
      %failure to load a model cancels all other load events
      return;
    end
  else
    erdlgpls('Cannot load prediction without model. Load corresponding model first.','Error on Prediction Load')
    return
  end
end

%check mypred to see if it matches the model
if ~strcmpi([modl.modeltype '_PRED'],mypred.modeltype)
  erdlgpls('Prediction object does not match current model type.','Error on Prediction Load')
  return
end

setobjdata('prediction',handles,mypred);

if strcmpi(getappdata(handles.analysis,'curanal'),'clsti')
  feval('clsti_guifcn','gui_updatetoolbar',handles.analysis,[],handles);
end
updatestatusimage(handles)


% --------------------------------------------------------------------
function loaded = loadmodel(h, eventdata, handles, varargin)
%load a model structure
% if varargin is passed, it is assumed to have at least a model (in cell
% position 1). This model will be loaded using "quiet" mode (not changing
% analysis modes or closing any existing figures). If any second item is
% included in varargin, it will turn off "quiet" mode.
%  varargin = {model};  %load in silent mode
%  varargin = {model 1};  %load in normal mode (as if from file/load model)

quiet = length(varargin)==1;
if nargout 
  loaded = false;
end

%Check for overwrite of model
force_clearmodel = 0;
if ~quiet & ~modelsaved(handles);
  ans=evriquestdlg('Current model has not been saved. What do you want to do?', ...
    'Model Not Saved','Overwrite Without Saving','Save & Overwrite','Cancel','Overwrite Without Saving');
  switch ans
    case {'Cancel'}
      return
    case {'Save & Overwrite'}
      if isempty(savemodel(handles.savemodel, [], handles, []))
        return
      end
  end
  force_clearmodel = 1;  %force a clear of model if we actually get a model
end

if isempty(varargin)
  [modl,name,location] = lddlgpls('struct','Select Model');
else
  modl = varargin{1};
end

if isempty(modl);  return; end

try
  modl = updatemod(modl);
catch
  erdlgpls('Not a valid model','Error on Load')
  return
end

if strfind(lower(modl.modeltype),'_pred')
  erdlgpls('This is a prediction object, not a model. Original model must be loaded as "Model" then this object can be loaded in the "Prediction" block.','Prediction Object Error')
  return
end
if isempty(analysistypes(lower(modl.modeltype)))
  loaderror = true;
  if isa(modl,'evrimodel')
    try
      edit(modl);
      loaderror = false;
    catch
    end
  end
  if loaderror
    erdlgpls(sprintf('Unable to load model into %s interface.',modl.modeltype),'Model Type Not Supported')
  end
  %NOTE: loaded returns FALSE here because it wasn't an Analysis model (so
  %it technically didn't get loaded)
  return
end
if ~modl.iscalibrated
  erdlgpls('This model has not been calibrated yet and cannot be loaded. Only calibrated models can be loaded.','Uncalibrated Model Error')
  return
end

%Check to see if any cal data exists and reconcile with model.
if ~isloaded('xblock',handles) & isloaded('yblock',handles)
  %Force a clear of yblock if no xblock because this is an unlikely
  %situation and it's safer to reload from cache. This situation also
  %doesn't return true from iscaldata.
  setobjdata('yblock',handles,[]);
end

testblocks = {modl getobjdata('xblock',handles) getobjdata('yblock',handles)};
if ~iscaldata(handles,testblocks{:});
  if isloaded('xblock',handles)
    ok = evriquestdlg('Current data is not the calibration data for the model being loaded (model ID or modificaton date does not match). Clear data or Cancel?','Model and Data Mismatch','Clear Data','Cancel','Clear Data');
  else
    ok = '';
  end
  switch ok
    case 'Cancel'
      return
    case 'Clear Data'
      clearboth(handles.analysis,[],handles,'cal')
  end
end

if ~strcmp(getappdata(handles.analysis,'statmodl'),'none') & force_clearmodel  %modl exists?
  clearmodel(h, eventdata, handles, 1)
end

%Update appdata.
setobjdata('model',handles,modl);
setobjdata('rawmodel',handles,[]);
setappdata(handles.savemodel,'timestamp',modl.time)
if nargout
  loaded = true;
end


%Load options.
if isfieldcheck('modl.detail.options',modl);
  mopts = modl.detail.options;
  if ~isempty(mopts)
    mopts = reconopts(mopts,lower(modl.modeltype),0);
    setopts(handles,lower(modl.modeltype),mopts);
  end
end

%check if we can load data from the model
usemodeldat = 0;

if ~isloaded('xblock',handles) ...
    & isfieldcheck('modl.detail.data',modl)
  modldata = modl.detail.data;
  %The moddate fields from model and data may not be equal and cuase
  %iscaldata to come back false, so use a flag to force statmodl into
  %'calold'.
  if iscell(modldata) & ~isempty(modldata) & ~isempty(modldata{1})
    usemodeldat = 1;
    loaddata_callback(handles.analysis, [], handles,'xblock', modldata{1});
    if length(modldata)>1
      loaddata_callback(handles.analysis, [], handles, 'yblock', modldata{2});
    end
  end
end     
  
%check status of GUI
if iscaldata(handles) | usemodeldat
  %this appears to be the data we calibrated with
  statmodl = 'calold';
  caldata = 1;
else
  statmodl = 'loaded';
  caldata = 0;
  %TODO: SCOTT clear data here (we SHOULD NOT leave data loaded which isn't the calibration data)
end
setappdata(handles.analysis,'statmodl',statmodl);

if ~quiet;
  %True if not in quiet mode.
  %Not in quiet mode, enable method.
  if strcmpi(modl.modeltype, 'clsti') && strcmpi(getappdata(handles.analysis,'curanal'),'clsti')
    %do nothing
  else
    enable_method(handles.analysis,[],handles,lower(modl.modeltype));
  end
  %Enable_method changes handles, reload.
end
handles = guidata(handles.analysis);

%Load groups (must be here after enable_method because data stored in button).
if isfieldcheck('modl.detail.modelgroups',modl);
  btnhandle = findobj(handles.analysis,'tag','choosegrps');
  if ~isempty(btnhandle)
    setappdata(btnhandle,'modelgroups',modl.detail.modelgroups);
  end
end

%Don't get pp from modl.detail.preprocessing{1}, this will have applied
%settings. Among other things this will cause models to look different when
%using comparevars.
if isfieldcheck('modl.detail.options.preprocessing',modl) & ~strcmpi(modl.modeltype,'simca')
  pp = modl.detail.options.preprocessing;
  if ~isempty(pp{1}) & ~isstruct(pp{1});
    pp{1} = preprocess('default',pp{1});
  end
  setappdata(handles.preprocessmain,'preprocessing',pp{1})
  if length(modl.datasource)==2 & length(pp)>1
    %2 block method, load y-block preprocessing.
    if ~isempty(pp{2}) & ~isstruct(pp{2});
      pp{2} = preprocess('default',pp{2});
    end
    setappdata(handles.preproyblkmain,'preprocessing',pp{2})
  end
end

cvigui  = getappdata(handles.analysis,'crossvalgui');
crossvalgui('forcesettings',cvigui,modl);
updatecrossvallimits(handles); %update crossval and FORCE these cross-validation settings into GUI

%clear any old "apply" info
if ~quiet & isloaded('prediction',handles)
  setobjdata('prediction',handles,[]);
end

updatestatusimage(handles);  %update status boxes
toolbarupdate(handles)  %set buttons
printinfo_update(handles)  %update infobox

if ~quiet;
  %close figures if manual load.
  fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
  if ~isempty(fn);
    feval(fn,'closefigures',handles);
  end
else
  %Update figures if in silent mode
  fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
  if ~isempty(fn);
    feval(fn,'updatefigures',handles.analysis);
    feval(fn,'updatessqtable',handles);
  end
end

% --------------------------------------------------------------------
function importmodel(h, eventdata, handles, varargin)
%Import model file.

%Default list.
defaultlist = {'Extensible Markup (*.xml)'   'importxmlmodel'   '.xml';
               'Vision Air (*.plt)'          'pltreadr'         '.plt'};

if exist('importmodel_customlist','file');
  %Append custom list (to top).
  mylist = [importmodel_customlist; defaultlist];
else
  %just use default list
  mylist = defaultlist;
end

%Create filter spec.
fspec = {};
for i = 1:size(mylist,1)
  fspec = [fspec; {['*' mylist{i,3}]} mylist(i,1)];
end

%Import a model structure from xml.
[FileName,PathName,FilterIndex] = evriuigetfile(fspec,'Import Model');
if ~FileName
  %User cancel.
  return
end

modl = feval(mylist{FilterIndex,2},fullfile(PathName,FileName));

if ~isempty(modl)
  loadmodel(h, eventdata, handles, modl, 1);
end

% ----------------------------------------------------------------------
function modl = importxmlmodel(filename)

%Parse xmle file.
modl = parsexml(filename);
%Pull model up from root xml tag.
fname = fieldnames(modl);
modl = modl.(fname{1});

%--------------------------------------------------------------------
function stat = iscaldata(handles,varargin)

stat = false;

modl = getobjdata('model',handles);

xdata = getobjdata('xblock',handles);
ydata = getobjdata('yblock',handles);

%parse additional inputs
blockindex = 0;
for j=1:length(varargin);
  switch class(varargin{j})
    case {'struct' 'evrimodel'}
      modl = varargin{j};
    otherwise
      blockindex = blockindex+1;
      if blockindex==1;
        xdata = varargin{j};
      else
        ydata = varargin{j};
      end
  end
end

%Move this test here (instead of above) so we don't return if modl hasn't been
%loaded but is passed in with varargin.
if isempty(modl) | ~isfield(modl,'datasource') | isempty(modl.datasource)
  return
end

%get data info and compare to model
xinfo = getdatasource(xdata);
yinfo = getdatasource(ydata);

%check if NaN passed as either element (only testing ONE block)
ignorex = false;
ignorey = false;
if isnumeric(xdata) & numel(xdata)==1 & ~isfinite(xdata);
  ignorex = true;
end
if isnumeric(ydata) & numel(ydata)==1 & ~isfinite(ydata);
  ignorey = true;
end

% if ~strcmp(xinfo.name,modl.datasource{1}.name) ...
%     | length(xinfo.moddate)~=length(modl.datasource{1}.moddate) | ~all(xinfo.moddate==modl.datasource{1}.moddate) ...
%     | length(xinfo.size)~=length(modl.datasource{1}.size) | ~all(xinfo.size==modl.datasource{1}.size)
%   if ~ignorex; return; end
% end
%
% lines commented out above were in use before introducing "simcaMode"

simcaMode = false;

if strcmpi(modl.modeltype, 'simca')
  simcaMode = true;
else
  if strcmpi(modl.modeltype, 'pca')
    simcaguiHdls = findobj(allchild(0), 'tag', 'simcagui');
    if ~isempty(simcaguiHdls)
      figInd = find(ismember(arrayfun(@(x)getappdata(x, 'parenthandle'), ...
        simcaguiHdls), handles.analysis));
      if ~isempty(figInd)
        
        subMdls = getappdata(simcaguiHdls(figInd), 'simcasubmodels');
        if ~isempty(subMdls)
          if ismember(modl.uniqueid, cellfun(@(x)x.uniqueid, subMdls, 'uni', false))
            % made it here - which shows that
            % a)  the current model is PCA
            % b)  the SIMCA model builder is open
            % c)  the SIMCA model builder is the child of the current analysis window
            % d)  the PCA model is one of the PCA submodels of the SIMCA model
            simcaMode = true;
          end
        end
      end
    end
  end
end


      
  
if ~strcmp(xinfo.name,modl.datasource{1}.name) ...
    | length(xinfo.moddate)~=length(modl.datasource{1}.moddate) | ~all(xinfo.moddate==modl.datasource{1}.moddate) ...
    | length(xinfo.size)~=length(modl.datasource{1}.size) | ~all(xinfo.size==modl.datasource{1}.size)
  if simcaMode
    % comparison of mod dates does not need to be as stringent for SIMCA
    % models
    % for example - changing the .include{2} field triggers a change in the
    % dataset .moddate field, yet we are allowing for SIMCA models to have
    % different included variables for each of the individual PCA submodels
    if strcmp(xinfo.name, modl.datasource{1}.name) && ...
        length(xinfo.moddate)==length(modl.datasource{1}.moddate) && ...
        length(xinfo.size)==length(modl.datasource{1}.size) && ...
        all(xinfo.size == modl.datasource{1}.size)
      % made it here - SIMCA model, x-block matches data used for model
      % _except_ for mod date => go ahead!
      stat = true;
      return
    else
      if ~ignorex; return; end
    end
  else
    if ~ignorex; return;end
  end
end

%x-matches, check for y
if length(modl.datasource)>1 & ~isempty(ydata)
  if ~strcmp(yinfo.name,modl.datasource{2}.name) ...
      | length(yinfo.moddate)~=length(modl.datasource{2}.moddate) | any(yinfo.moddate~=modl.datasource{2}.moddate) ...
      | length(yinfo.size)~=length(modl.datasource{2}.size) | any(yinfo.size~=modl.datasource{2}.size)
    if ~ignorey; return; end
  end
end
stat = true;

% --------------------------------------------------------------------
function savedata(h, eventdata, handles, varargin)
%Save data MENU enable/disable code.

ppx = getappdata(handles.preprocessmain,'preprocessing');
ppy = getappdata(handles.preproyblkmain,'preprocessing');

set([handles.savexblock handles.saveyblock handles.saveppxblock handles.saveppyblock], 'Enable','off')

if isloaded('xblock',handles)
  set(handles.savexblock,'Enable','on')
  if ~isempty(ppx)
    set(handles.saveppxblock,'Enable','on')
  end
end

if isloaded('yblock',handles)
  set(handles.saveyblock,'Enable','on')
  if ~isempty(ppy)
    set(handles.saveppyblock,'Enable','on')
  end
end

set([handles.savexblock_val handles.saveyblock_val handles.saveppxblock_val handles.saveppyblock_val], 'Enable','off')

if isloaded('validation_xblock',handles)
  set(handles.savexblock_val,'Enable','on')
  if ~isempty(ppx)
    set(handles.saveppxblock_val,'Enable','on')
  end
end

if isloaded('validation_yblock',handles)
  set(handles.saveyblock_val,'Enable','on')
  if ~isempty(ppy)
    set(handles.saveppyblock_val,'Enable','on')
  end
end

% --------------------------------------------------------------------
function varargout = savedata_callback(h, eventdata, handles, varargin)
%Generic save data callback.
pp = false;
switch varargin{1}
  case {'x' 'xblock'}
    str = 'Calibration X-Block';
    block = 'xblock';
  case {'y' 'yblock'}
    str = 'Calibration Y-Block';
    block = 'yblock';
  case {'x_val' 'validation_xblock'}
    str = 'Validation X-Block';
    block = 'validation_xblock';
  case {'y_val' 'validation_yblock'}
    str = 'Validation Y-Block';
    block = 'validation_yblock';
  case 'xpp'
    str = 'Preprocessed Calibration X-Block';
    block = 'xblock';
    pp = true;
  case 'ypp'
    str = 'Preprocessed Calibration Y-Block';
    block = 'yblock';
    pp = true;
  case 'xpp_val'
    str = 'Preprocessed Validation X-Block';
    block = 'validation_xblock';
    pp = true;
  case 'ypp_val'
    str = 'Preprocessed Validation Y-Block';
    block = 'validation_yblock';
    pp = true;
  otherwise
    error('Unable to identify data to be saved.')
end

if ~pp
  %no preprocessing
  data = getobjdata(block,handles);
else
  data = viewprepro(handles.analysis, [], handles, block);
end

if isempty(data);
  varargout{1} = [];
  return
end
if ~isempty(data.name) & length(data.name)<63
  name = data.name;
else
  name = 'data';
end
[what,where] = svdlgpls(data,['Save ' str ' Data'],name);
varargout{1} = what;

% --------------------------------------------------------------------
function varargout = savetest(h, eventdata, handles, varargin)
test = analysis('getobjdata','prediction',handles);
targname = defaultmodelname(test);
data = getobjdata('validation_xblock',handles);

if ~isempty(data) & ~isempty(data.name) & length(data.name)<63
  name = [data.name];
else
  name = 'newdata';
end
targname = [targname '_test_' name];
[what,where] = svdlgpls(test,'Save Test Results',targname);
varargout{1} = what;

% --------------------------------------------------------------------
function varargout = saveoptions(h, eventdata, handles, varargin)
[what,where] = svdlgpls(getappdata(handles.analysis,'analysisoptions'),'Save Options Structure');
varargout{1} = what;

% --------------------------------------------------------------------
function varargout = savemodel(h, eventdata, handles, varargin)

modl = savemodel_check(handles);

%Save model
targname = defaultmodelname(modl,'variable','save');
[what,where] = svdlgpls(modl,'Save Model',targname);
varargout{1} = what;
if ~isempty(what);
  setappdata(handles.savemodel,'timestamp',modl.time);
end

% --------------------------------------------------------------------
function savemodelasCallback(h, eventdata, handles, varargin)

modl = savemodel_check(handles);
savemodelas(modl,get(h,'userdata'));

% --------------------------------------------------------------------
function exportmodel_openfluor(h, eventdata, handles, varargin)
%Need data and model to export to openfluor so use custom code rather than
%savemodelas.m. 
modl = savemodel_check(handles);
x = getobjdata('xblock',handles);

if isempty(x)
  evrierrordlg('To export model to OpenFluor the calibration X block must be also be present in order to export the model' ,'X Block is missing');
  return
end


if ~isempty(modl) && ~isempty(x)
  parafacforopenfluor(x,modl,'')
  web('http://models.life.ku.dk:8083/database/query','-browser');
end

% --------------------------------------------------------------------
function exportmodel_mfile(h, eventdata, handles, varargin)

doexportmodel(handles,'matlab');

% --------------------------------------------------------------------
function exportmodel_xml(h, eventdata, handles, varargin)

doexportmodel(handles,'xml');

% --------------------------------------------------------------------
function exportmodel_tcl(h, eventdata, handles, varargin)

doexportmodel(handles,'tcl');

% --------------------------------------------------------------------
function exportmodel_python(h, eventdata, handles, varargin)

doexportmodel(handles,'python');

% --------------------------------------------------------------------
function doexportmodel(handles,method)

modl = savemodel_check(handles);
if ~exist('exportmodel','file');
  switch evriquestdlg('Exporting Predictors requires Model_Exporter (not installed on this system).','Model_Exporter Not Found','OK','More Information','OK');
    case 'More Information'
      web('http://www.eigenvector.com/software/model_exporter.htm','-browser');
  end
  return
end
exportmodel(modl,method);

% --------------------------------------------------------------------
function exportregvec_Callback(h, eventdata, handles, varargin)

modl = savemodel_check(handles);
exportmodelregvec(modl);

% --------------------------------------------------------------------
function exportbuilder(h, eventdata, handles, varargin)

modl = savemodel_check(handles);
encodemodelbuilder(modl);

% --------------------------------------------------------------------
function exporthelp(h, eventdata, handles, varargin)

evrihelp('exporting_models')


% --------------------------------------------------------------------
function exportpredres(h, eventdata, handles, varargin)
%export scores from either model or predictions

switch varargin{1}
  case 'model'
    if ~isloaded('model',handles)
      return
    end
    blk = {savemodel_check(handles)};
  case 'prediction'
    if ~isloaded('model',handles) | ~isloaded('prediction',handles)
      return
    end
    blk = {savemodel_check(handles) getobjdata('prediction',handles)};
      
  otherwise
    return
end  

forceautoclass = getappdata(handles.analysis,'forceautoclass');
if isempty(forceautoclass); forceautoclass = 0; end
opts = struct('sct',false,'autoclass',forceautoclass);
scores = plotscores(blk{:},opts);
autoexport(scores)

% --------------------------------------------------------------------
function modl = savemodel_check(handles)
%reset various objects - just in case they chose a new # of PCs and didn't
%hit apply

modl = getobjdata('model',handles);
mytbl = getappdata(handles.analysis,'ssqtable');
if isempty(modl); return; end

if isfield(modl,'loads');
  n = size(modl.loads{2,1},2);
  % only execute if loads field is nonempty/ method has a ssqtable
  if n>0
    if n ~= getappdata(handles.pcsedit,'default')
      evrimsgbox('Because Analysis is waiting for you to recalculate the model, the model being saved/exported is not the model currently displayed.','Save/Export Model Warning','warn','modal');
    end
    set(handles.pcsedit,'String',int2str(n))
    setselection(mytbl,'rows',n)
    setappdata(handles.pcsedit,'default',n)
  else
    return
  end
end

%update model as necessary
s   = fieldnames(modl);
if ~isempty(strmatch('scale',s))
  modl     = updatemod(modl);
  setobjdata('model',handles,modl);
end

% --------------------------------------------------------------------
function printinfo(h, eventdata, handles, varargin)
%Show model or prediction details.

mode = 'model';
if nargin==4 | ~isempty(varargin)
  mode = varargin{1};
end

modl = getobjdata('model',handles);
test = getobjdata('prediction',handles);

switch mode
  case 'prediction'
    modl = test;  %show TEST results instead of model results
  case 'model'
    %Add any model specific code here.
end

if ~strcmp(getappdata(handles.analysis,'statmodl'),'none') & ~isempty(modl)
  if isfield(modl,'loads') & ~strcmpi(getappdata(handles.analysis,'curanal'),'clsti')
    info = [modlrder(modl)';ssqtable(modl,size(modl.loads{2,1},2))'];
  else
    try
      info = modlrder(modl)';
    catch
      return
    end
  end
  infofig = infobox(info,struct('openmode','reuse','figurename','Model Details'));
  infobox(infofig,'font','courier',10);
  adopt(handles,infofig,'methodspecific');
  setappdata(infofig,'analysisblockmode',mode)
  setappdata(handles.analysis,'modeldetails',infofig);
end
%---------------------------------------------------------------------
function printinfo_update(handles)

h = getappdata(handles.analysis,'modeldetails');
if ~isempty(h) & ishandle(h)
  mode = getappdata(h,'analysisblockmode');
  printinfo(handles.analysis,[],handles,mode);
end

% --------------------------------------------------------------------
function report_callback(h, eventdata, handles, varargin)
%Generate or open report.

mode = 'html';
if nargin==4 | ~isempty(varargin)
  mode = varargin{1};
end
ropts = reportwriter('options');

switch mode
  case {'html' 'powerpoint' 'word'}
    opts.notificationdialog  = 'off';
    opts.autoopening         = 'on';
    
    %     %create dialog for questions
    %     cmtfig = figure('handlevisibility','callback','numbertitle','off',...
    %       'menubar','none','toolbar','none',...
    %       'name','Report Writer Settings','units','pixels','position',[626   602   448   309],...
    %       'visible','off','color',[1 1 1]);
    %     centerfigure(cmtfig);
    %     h1 = uicontrol('parent',cmtfig,'style','checkbox','position',[4 275 440 35],'fontsize',getdefaultfontsize,...
    %       'string','Auto-Generate standard plots for report?','tag','autogenerate','value',1);
    %     h2 = uicontrol('parent',cmtfig,'style','edit','position',[4 4 440 232]);
    %     set(cmtfig,'visible','on');
    
    [msg,ok] = evricommentdlg('Comment to be added to your report (empty=none):','Report Comment');
    if ~ok  %"cancel" clicked"
      return;
    end
    msg = str2cell(msg);
    msg = sprintf('%s\n',msg{:});
    
    genplt = evriquestdlg('Auto-generate standard plots for the report?','Auto-Generate Plots','Yes','No','Yes');
    if isempty(genplt)   %figure closed without answer? =cancel
      return;
    end
    opts.autocreateplots = genplt;
    
    reportwriter(mode, handles.analysis,msg,opts)
  case 'open'
    
    mydir = ropts.outdir;
    if isempty(mydir)
      mydir = fullfile(evridir,'analysisreports');
    end
    
    if exist(mydir)
      if ispc
        winopen(mydir);
      elseif ismac
        system(['open ' mydir]);
      else
        try
          %Only works with java 1.6, 2008a+
          java.awt.Desktop.getDesktop.open(java.io.File(mydir));
        end
      end
    end
    return
  case 'changedir'
    startdir = fullfile(evridir,'analysisreports');%Start in evridir as default.
    if ~isempty(ropts.outdir)
      %start in old default.
      startdir = ropts.outdir;
    end
    mydir = evriuigetdir(startdir,'New Report Folder');
    if mydir~=0
      setplspref('reportwriter','outdir',mydir)
    end
end

% --------------------------------------------------------------------
function testrobust(h, eventdata, handles, varargin)
%Execute testrobustness for val data (cal data if val isn't available).
%  varargin{1} should be 'shift' or 'interferent'

if isloaded('model',handles)
  mod = getobjdata('model',handles);
  x = [];
  y = [];
  if isloaded('validation_xblock',handles) & isloaded('validation_yblock',handles)
    x = getobjdata('validation_xblock',handles);
    y = getobjdata('validation_yblock',handles);
  elseif isloaded('xblock',handles) & isloaded('yblock',handles)
    x = getobjdata('xblock',handles);
    y = getobjdata('yblock',handles);
  end
  try
    % try to match the included analytes
    y.include{2} = mod.detail.includ{2,2};
  catch
    error('Model include field selections will not work with current y-block.');
  end
  if ~isempty(x) & ~isempty(y)
    [results,fig] = testrobustness(mod,x,y,varargin{1});
    adopt(handles,fig,'methodspecific')
  end
end
% --------------------------------------------------------------------

function calcshap(h,eventdata,handles,varargin)
if isloaded('model',handles)
  mod = getobjdata('model',handles);
end
if isloaded('xblock',handles)
  x = getobjdata('xblock',handles);
end
app = shapleygui;
if ~isdataset(x)
  x = dataset(x);
end
app.LoadCalXButton(x,x.name);
app.LoadModelButton(mod);
adopt(handles,app.UIFigure,'modelspecific');



% --------------------------------------------------------------------
function hierarchicalmodeling(h, eventdata, handles, varargin)

modelselectorgui

% --------------------------------------------------------------------
function analysispref(h, eventdata, handles, varargin)
% disp('Not yet available.')

% --------------------------------------------------------------------
function close_plotgui(h)
set(h,'Visible','off')

% --------------------------------------------------------------------
function clutter_callback(h, eventdata, handles, varargin)
%Clutter menu callback. All calls to glswset should be atomic in that they
%return a pp structure or empty that is then inserted into the main pp
%structure.

mode = varargin{1};

if ~strcmp(mode,'clear')
  %look for n-way data and forbid changes (other than clear)
  if isloaded('xblock',handles) & ndims(getobjdata('xblock',handles))>2
    evritip('nonwayclutter','Clutter cannot be used with multi-way data',1);
    return
  end
end

curpp = getappdata(handles.preprocessmain,'preprocessing');
cpos = find_clutter(curpp);

%Get default or existing.
if isempty(cpos)
  myclutter = preprocess('glsw','default');
  myclutter.userdata = inf;  %default is "none"
else
  myclutter = curpp(cpos);
end

switch mode
  case 'settings'
    %Open glswset.
    [newclutter, mybutton] = glswset(myclutter);
    if isempty(mybutton)
      %Aborted settings.
      return
    end
    if newclutter.userdata.a==inf
      %"a" of +inf indicates "none" in algorithm
      newclutter = [];
      if ~isempty(cpos)
        curpp(cpos) = [];
      end
    end
    if comparevars(myclutter,newclutter)
      %no change made
      return
    end
  case {'import' 'load'}
    switch mode
      case 'import'
        %Import data only.
        rawdata = autoimport(varargin{2:end});
        
      case 'load'
        %Can load data, model, or existing clutter pp struct. Push into glswset
        %after load.
        rawdata = lddlgpls({'double' 'dataset' 'struct'},['Select Clutter']);
    end
    if isempty(rawdata);
      return;
    end
    if isstruct(rawdata) & isfield(rawdata,'keyword') & isfield(rawdata,'description')
      %assume this is a preprocessing structure
      myclutter = rawdata;
      [newclutter, mybutton] = glswset(myclutter);
    else
      %not a preprocessing structure - either real data or a model
      if ismodel(rawdata)
        %Extract loadings and pass as data.
        rawdata = rawdata.loads{2,1}';
      end
      [newclutter, mybutton] = glswset(myclutter,rawdata);
    end
    if isempty(mybutton)
      return
    end
  case 'save'
    %Save existing clutter.
    if isempty(cpos)
      erdlgpls('There is no declutter filter to save.','Save Declutter Error')
    else
      svdlgpls(myclutter,'Save Declutter Filter');
    end
    return
  case 'clear'
    %Clear clutter pp from xblock pp struct.
    curpp(cpos) = [];
    newclutter = [];
end

if ~isempty(newclutter)
  %Add Clutter to keyword and description if it's not there.
  if isempty(strfind(lower(newclutter.keyword),'declutter'))
    newclutter.keyword = ['declutter ' myclutter.keyword];
  end
  
  %Insert newclutter into pp struct according to rules.
  userule = false;
  if isempty(cpos)
    %No existing clutter.
    if ~isempty(newclutter.out)
      %Using external data so goes at top.
      curpp = [newclutter curpp];
    else
      %Need to employ rule.
      userule = true;
    end
  else
    %Existing clutter so put back into original position unless there's
    %been a switch between external/internal data.
    if isempty(myclutter.out)==isempty(newclutter.out)
      %No change, just put it back where it was.
      curpp(cpos) = newclutter;
    else
      %Need to get rid of existing clutter and apply rule.
      curpp(cpos) = [];
      userule = true;
    end
    
  end
  
  if userule
    %Insert before auto/mncn.
    if isempty(curpp)
      curpp = newclutter;
    else
      %look at what is in there now and position accordingly
      curpp = curpp(:)';  %make sure its a row vector of items
      list   = lower({curpp.keyword});
      am_pos = min([find(strcmp('autoscale',list)) find(strcmp('mean center',list))]);
      if ~isempty(am_pos)
        %Goes before auto/mncn.
        curpp = [curpp(1:am_pos-1) newclutter curpp(am_pos:end)];
      else
        %Goes at end.
        curpp = [curpp newclutter];
      end
    end
  end
  
end

setappdata(handles.preprocessmain,'preprocessing',curpp)
preprocesschange(handles,'x')

%---------------------------------------------------------------------
function cpos = find_clutter(curpp)
%locate clutter in preprocessing (if any)
%input is either the preprocessing to search OR the handles structure of
%the analysis window to look in (preprocessmain field)

if isfield(curpp,'preprocessmain')
  %passed handles instead of current preprocessing? get preprocessing
  curpp = getappdata(curpp.preprocessmain,'preprocessing');
end

cpos = [];%Clutter position.

if ~isstruct(curpp)
  return;
end

%Find existing clutter struct.
for i = 1:length(curpp)
  if strfind(lower(curpp(i).keyword),'declutter')
    cpos = i;
    return
  end
end

%no "declutter" item? look for glsw
for i = 1:length(curpp)
  if strfind(lower(curpp(i).keyword),'gls weighting')
    cpos = i;
    return
  end
end

% --------------------------------------------------------------------
function preprocesscustom(h, eventdata, handles, varargin)
%Open preprocess gui (modal).
%varargin{1} should identify the block, 'x' or 'y'. 

catalog = getappdata(handles.analysis,'preprocesscatalog'); %x-catalog in first cell.
if nargin<4
  %assume x if nothing given
  varargin{1} = 'x';
end
switch varargin{1}
  case 'x'
    curpp = getappdata(handles.preprocessmain,'preprocessing'); %Get current preprocessing.
    myid = getobj('xblock',handles);
    [xpp,ppchange,catalog{1}]= preprocess('setup',handles.preprocessmain,'Name','Preprocessing X-block', ...
      'catalog',catalog{1},'addtoparent',handles.analysis, curpp, myid);
    %Will return orginal pp if cancel so just set appdata as needed.
    setappdata(handles.preprocessmain,'preprocessing',xpp)
  case 'y'
    curpp = getappdata(handles.preproyblkmain,'preprocessing'); %Get current preprocessing.
    myid = getobj('yblock',handles);

    [ypp,ppchange,catalog{2}]= preprocess('setup',handles.preproyblkmain,'Name','Preprocessing Y-block', ...
      'catalog',catalog{2},'addtoparent',handles.analysis,curpp,myid);
    %Will return orginal pp if cancel so just set appdata as needed.
    setappdata(handles.preproyblkmain,'preprocessing',ypp)
end

if ppchange
  setappdata(handles.analysis,'preprocesscatalog',catalog); %update catalog (if changed in preprocess)
  %Remove model and update any plotted data if pp has changed.
  preprocesschange(handles,varargin{1})
end

% --------------------------------------------------------------------
function preprocessnone(h, eventdata, handles, varargin)
%Preprocess none.
%varargin{1} should identify the block, 'x' or 'y'. 

newpp = preprocess('none');
switch varargin{1}
  case 'x'
    setappdata(handles.preprocessmain,'preprocessing',newpp);
  case 'y'
    if ~isempty(getappdata(handles.analysis,'curanal')) & ismember(getappdata(handles.analysis,'curanal'),{'pls' 'pcr' 'mlr'});
      evritip('yblockppnone','Y-block Preprocessing Warning:  Many algorithms which use the y-block data expect that the y-block data has been centered (usually mean-centered).\n\nUsing preprocesing of "None" for the y-block may degrade model performance and also cause the sum-squared variance table to be incorrect. Consider using Mean Centering on the y-block.',1);
    end
    setappdata(handles.preproyblkmain,'preprocessing',newpp);
end

preprocesschange(handles,varargin{1})

% --------------------------------------------------------------------
function preprocessmean(h, eventdata, handles, varargin)
%Preprocess mean. 
%varargin{1} should identify the block, 'x' or 'y'. 

newpp = preprocess('meancenter');
switch varargin{1}
  case 'x'
    setappdata(handles.preprocessmain,'preprocessing',newpp);
  case 'y'
    setappdata(handles.preproyblkmain,'preprocessing',newpp);
end

preprocesschange(handles,varargin{1})

% --------------------------------------------------------------------
function preprocessauto(h, eventdata, handles, varargin)
%Preprocess auto. 
%varargin{1} should identify the block, 'x' or 'y'. 

newpp = preprocess('autoscale');
switch varargin{1}
  case 'x'
    setappdata(handles.preprocessmain,'preprocessing',newpp);
  case 'y'
    setappdata(handles.preproyblkmain,'preprocessing',newpp);
end

preprocesschange(handles,varargin{1})

% --------------------------------------------------------------------
function opts = preprodefault(handles, opts)
%Set preprocessing to default in options.

%Initiate preprocess
if ismember(class(opts.defaultxpreprocessing),{'char','cell'})
  try
    opts.defaultxpreprocessing = preprocess('default',opts.defaultxpreprocessing);
  catch
    opts.defaultxpreprocessing = [];
  end
end
if ismember(class(opts.defaultypreprocessing),{'char','cell'})
  try
    opts.defaultypreprocessing = preprocess('default',opts.defaultypreprocessing);
  catch
    opts.defaultypreprocessing = [];
  end
end
setappdata(handles.preprocessmain,'preprocessing',opts.defaultxpreprocessing)
setappdata(handles.preproyblkmain,'preprocessing',opts.defaultypreprocessing)



% --------------------------------------------------------------------
function preproquickopen(h, eventdata, handles, varargin)
%Change quick open status

if strcmpi(getfield(analysis('options'),'quickopenprepro'),'on')
  ch = 'off';
else
  ch = 'on';
  evritip('quickopen','Quick Open preprocessing mode is now ON. Left-click "P" will open preprocessing interface. Use right-click on "P" to acceses context menu.',1)
end
setplspref('analysis','quickopenprepro',ch);

% --------------------------------------------------------------------
function preproyblknone(h, eventdata, handles, varargin)
error('bad pp menu call')
% if ismember(getappdata(handles.analysis,'curanal'),{'pls' 'pcr' 'mlr'});
%   evritip('yblockppnone','Y-block Preprocessing Warning:  Many algorithms which use the y-block data expect that the y-block data has been centered (usually mean-centered).\n\nUsing preprocesing of "None" for the y-block may degrade model performance and also cause the sum-squared variance table to be incorrect. Consider using Mean Centering on the y-block.',1);
% end
% newpp = preprocess('none');
% setappdata(handles.preproyblkmain,'preprocessing',newpp);
% preprocesschange(handles,'y')

% --------------------------------------------------------------------
function preproyblkmean(h, eventdata, handles, varargin)
% newpp = preprocess('meancenter');
% setappdata(handles.preproyblkmain,'preprocessing',newpp);
% preprocesschange(handles,'y')
error('bad pp menu call')
% --------------------------------------------------------------------
function preproyblkauto(h, eventdata, handles, varargin)
% newpp = preprocess('autoscale');
% setappdata(handles.preproyblkmain,'preprocessing',newpp);
% preprocesschange(handles,'y')
error('bad pp menu call')
% --------------------------------------------------------------------
function crossvalmenu(h, eventdata, handles, varargin)
%Enable crossval.

if ~strcmp(get(h,'type'),'figure');
  h   = get(get(h,'parent'),'parent');
end
set(getappdata(h,'crossvalgui'),'Visible','on')
figure(getappdata(h,'crossvalgui'));    %bring to front

% --------------------------------------------------------------------
function out=cvguienabled(handles)
%returns true when crossvalGUI is enabled
out = ~strcmp(char(getappdata(handles.analysis,'enable_crossvalgui')),'off');

% --------------------------------------------------------------------
function preprocessmenu(h, eventdata, handles, varargin)

childh = [get(handles.preprocessmain, 'children'); ...
  get(handles.preproyblkmain, 'children')];

set(childh, 'checked','off','enable','on');

%Enable proper pp menu item.
ppx = getappdata(handles.preprocessmain,'preprocessing');
ppy = getappdata(handles.preproyblkmain,'preprocessing');

if isempty(ppx)
  set(handles.preprocessnone,'checked','on');
  set(handles.preprosave_x,'enable','off')
elseif length(ppx) == 1
  set(handles.preprosave_x,'enable','on')
  switch lower(ppx.description)
    case 'mean center'
      set(handles.preprocessmean,'checked','on');
    case 'autoscale'
      set(handles.preprocessauto,'checked','on');
    otherwise
      set(handles.preprocesscustom,'checked','on');
  end
else
  set(handles.preprosave_x,'enable','on')
  set(handles.preprocesscustom,'checked','on');
end

if isempty(ppy)
  set(handles.preproyblknone,'checked','on');
  set(handles.preprosave_y,'enable','off')
elseif length(ppy) == 1
  set(handles.preprosave_y,'enable','on')
  switch lower(ppy.description)
    case 'mean center'
      set(handles.preproyblkmean,'checked','on');
    case 'autoscale'
      set(handles.preproyblkauto,'checked','on');
    otherwise
      set(handles.preproyblkcustom,'checked','on');
  end
else
  set(handles.preprosave_y,'enable','on')
  set(handles.preproyblkcustom,'checked','on');
end

%If current analysis is MPCA or empty then allow normall PP for 2+ dims
%otherwise disable. Parafac can only use n-way PP, MPCA will work with
%standard PP becuase data is unfolded.

cura = getappdata(handles.analysis,'curanal');

if ~strcmp(cura,'mpca') & ndims(getobjdata('xblock',handles))>2
  set(handles.preprocessnone,'enable','on');
  set(handles.preprocessmean,'enable','off');
  set(handles.preprocessauto,'enable','off');
%   set(handles.preprocesscustom,'checked','on');
  set(handles.preprocesscustom,'enable','on');
end

if ~strcmp(cura,'mpca') & ndims(getobjdata('yblock',handles))>2
  set(handles.preproyblknone,'enable','on');
  set(handles.preproyblkmean,'enable','off');
  set(handles.preproyblkauto,'enable','off');
  set(handles.preproyblkcustom,'enable','off');
%   set(handles.preproyblkcustom,'checked','on');
  set(handles.preproyblkcustom,'enable','on');
end


%Enable parent menus.
if ~isloaded('xblock',handles) | strcmp(getappdata(handles.analysis, 'statmodl'),'loaded')
  en = 'off';
else
  en = 'on';
end
set([handles.preprocessmain],'enable',en)

if (~isloaded('yblock',handles) ...
    & ~ismember(cura,{'plsda'}))...
    | strcmp(getappdata(handles.analysis, 'statmodl'),'loaded') ...
    | getappdata(handles.analysis,'noyprepro')
  set(handles.preproyblkmain,'enable','off')
else
  set(handles.preproyblkmain,'enable','on')
end

%Enable Save menu
if ~isloaded('xblock',handles) & ~isloaded('model',handles)
  en = 'off';
else
  en = 'on';
end
set([handles.preprosave],'enable',en)


%Enable view preprocess menu items.
if ~isloaded('xblock',handles) & ~isloaded('yblock',handles) & ~isloaded('validation_xblock',handles) & ~isloaded('validation_yblock',handles)
  set([handles.savepreprocessed handles.viewpreprocess],'enable','off')
else
  set([handles.savepreprocessed handles.viewpreprocess],'enable','on')
  if ~isloaded('xblock',handles)
    set([handles.savepreprox handles.viewpreprox],'enable','off')
  else
    set([handles.savepreprox handles.viewpreprox],'enable','on')
  end

  if ~isloaded('yblock',handles)
    set([handles.savepreproy handles.viewpreproy],'enable','off')
  else
    set([handles.savepreproy handles.viewpreproy],'enable','on')
  end
  
  if ~isloaded('validation_xblock',handles)
    set([handles.savepreprox_val handles.viewpreprox_val],'enable','off')
  else
    set([handles.savepreprox_val handles.viewpreprox_val],'enable','on')
  end

  if ~isloaded('validation_yblock',handles) | ~isyused(handles)
    set([handles.savepreproy_val handles.viewpreproy_val],'enable','off')
  else
    set([handles.savepreproy_val handles.viewpreproy_val],'enable','on')
  end
end

%Enable clutter menu.
if isempty(find_clutter(handles))
  en = 'off';
else
  en = 'on';
end
set([handles.clutter_save handles.clutter_clear],'enable',en);

%disable some if n-way
if isloaded('xblock',handles) & ndims(getobjdata('xblock',handles))>2
  en = 'off';
else
  en = 'on';
end
set([handles.clutter_settings handles.clutter_load handles.clutter_import],'enable',en);

%add import options
allch = allchild(handles.clutter_import);
if ~isempty(allch)
  delete(allch);
end
set(handles.clutter_import,'callback','');
editds_addimportmenu(handles.clutter_import,'analysis(''clutter_callback'',gcbf,[],guidata(gcbf),''import'',get(gcbo,''userdata''));');

% --------------------------------------------------------------------
function toolsmenu(h, eventdata, handles, varargin)
%Performs checking and setup of tools menu.

x = getobjdata('xblock',handles);
modl = getobjdata('model',handles);

if ~strcmp(getappdata(handles.analysis,'statmodl'),'none')  %modl exists?
  en = 'on';
else
  en = 'off';
end
set(handles.printinfo,'enable',en);

if isloaded('prediction',handles)
  en = 'on';
else
  en = 'off';
end
set(handles.showpredictiondetails,'enable',en);

set([handles.reportwriter handles.report_html handles.report_powerpoint handles.report_word],'enable','on');
if ~ispc
  set([ handles.report_powerpoint handles.report_word],'enable','off');
end

%disable estimatefactors if no data
if isloaded('xblock',handles) & ndims(x)==2
  en = 'on';
else
  en = 'off';
end
set(handles.estimatefactors, 'enable',en)

%Disable if no data or multiway.
if ~(isloaded('xblock',handles) && isloaded('yblock',handles)) | ndims(getobjdata('xblock',handles))>2
  set(handles.xycorrcoefplot, 'enable','off')
else
  set(handles.xycorrcoefplot, 'enable','on')
end

%Disable if no data or multiway.
if (~isloaded('xblock',handles) | ndims(getobjdata('xblock',handles))>2) ...
    & (~isloaded('yblock',handles) | ndims(getobjdata('yblock',handles))>2)
  set(handles.correlationmap,'enable', 'off')
else
  set(handles.correlationmap,'enable', 'on')
  if ~isloaded('xblock',handles) | ndims(getobjdata('xblock',handles))>2
    set(handles.xblock_correlationmap, 'enable','off')
  else
    set(handles.xblock_correlationmap, 'enable','on')
  end
  if ~isloaded('yblock',handles) | ndims(getobjdata('yblock',handles))>2
    set(handles.yblock_correlationmap, 'enable','off')
  else
    set(handles.yblock_correlationmap, 'enable','on')
  end
end



rawdata = getobjdata('xblock',handles);
en = 'on';
if isempty(rawdata)
  en = 'off';
elseif strcmp(getappdata(handles.analysis,'statmodl'),'loaded')
  en = 'off';
else
  if cvguienabled(handles)
    en = 'on';
  else
    en = 'off';
  end
end
%check check status for menu item
chk = 'off';
cvgui = getappdata(handles.analysis,'crossvalgui');
if ~isempty(cvgui) & ishandle(cvgui) & ~strcmp(crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui')),'none') & cvguienabled(handles)
  chk = 'on';
end
set(handles.crossval, 'enable',en,'checked',chk)

set(handles.showcalwithtest,'visible','off');

%Hide EWFA.
if evriio('mia')
  if isloaded('xblock',handles) & strcmp(x.type,'image')
    en = 'on';
  else
    en = 'off';
  end
  set(handles.ewfa,'visible','on','enable',en)
else
  set(handles.ewfa,'visible','off')
end

%Enable cache viewer.
if getappdata(handles.analysis,'showcacheviewer')
  set(handles.cacheview,'enable','on');
  
  cvh = getappdata(handles.analysis,'treeparent');
  if isempty(cvh) | ~ishandle(cvh)  
    set(handles.hidecacheviewer,'Enable','Off')%There is no tree so can't hide anything.
  else
    set(handles.hidecacheviewer,'Enable','On')%There is a tree so allow hiding.
  end
else
  set(handles.cacheview,'enable','off');
end

%Enable component naming.
if ~isempty(modl) & isfieldcheck(modl,'modl.detail.componentnames')
  set(handles.addcomponentnames,'Enable','On')
else
  set(handles.addcomponentnames,'Enable','Off')
end

if ~isempty(modl) & ismember(lower(modl.modeltype),MCCTObject.supportedModelTypes)
  set(handles.sendtomcct,'Enable','On')
else
  set(handles.sendtomcct,'Enable','Off')
end

% --------------------------------------------------------------------
function refinemenu(h, eventdata, handles, varargin)
%Performs checking and setup of tools menu.

x = getobjdata('xblock',handles);

%Disable testrobust if no model, x/y.
curanal  = char(getappdata(handles.analysis,'curanal'));
to = testrobustness('options');
if ismember(curanal,to.validmodeltypes)
  if ~isloaded('model',handles)
    en = 'off';
  else
    if isloaded('validation_xblock',handles) & isloaded('validation_yblock',handles)
      en = 'on';
    elseif isloaded('xblock',handles) & isloaded('yblock',handles)
      en = 'on';
    else
      en = 'off';
    end
  end
else
  en = 'off';
end
set(handles.testrobust,'Enable',en)

if isloaded('xblock',handles) && isloaded('model',handles)
  set(handles.shap,'Enable',1)
else
  set(handles.shap,'Enable',0)
end

%enable/disable "permute" test menu item
if isloaded('xblock',handles) & (ismember(curanal,{'svmda' 'plsda' 'knn'}) | isloaded('yblock',handles))
  en = 'on';
  ch = 'off';
else
  en = 'off';
  ch = 'off';
end
set(handles.toolspermute,'Enable',en,'Checked',ch)

%Enable Orthogonalize.
set(handles.orthogonalizemodel,'visible','on','enable','off','checked','off');
if ismember(lower(curanal),{'pls' 'plsda'})
  opts = getsafeoptions(h, eventdata, handles, varargin);
  if strcmpi(opts.orthogonalize,'on')
    set(handles.orthogonalizemodel,'checked','on');
  end
  set(handles.orthogonalizemodel,'enable','on');
end

% --------------------------------------------------------------------
function editmenu(h, eventdata, handles, varargin)
%Performs checking and setup of edit menu.

for childh = get(handles.edit, 'children')
  set(childh, 'enable','off')
end
%Needs more code, enable edit x-block only.

%Gather loaded info once for convenience.
isxl = isloaded('xblock',handles);
isyl = isloaded('yblock',handles);
isvxl = isloaded('validation_xblock',handles);
isvyl = isloaded('validation_yblock',handles);


if ~isxl
  set([handles.editxblock handles.editplotxblock handles.makeyblock_cal], 'enable','off')
else
  set([handles.edit_cal handles.editxblock handles.editplotxblock handles.makeyblock_cal], 'enable','on')
  resetInclude_build(gcbo,[],guidata(gcbo), 'xblock', 'resetIncluded_xCal');
end

if ~isyl
  set([handles.edityblock handles.editplotyblock handles.editselectycols], 'enable','off')
  set(handles.resetIncluded_yCal, 'visible', 'off');
else
  set([handles.edit_cal handles.edityblock handles.editplotyblock handles.editselectycols], 'enable','on')
  resetInclude_build(gcbo,[],guidata(gcbo), 'yblock', 'resetIncluded_yCal');
end

if ~isvxl
  set([handles.editxblock_val handles.editplotxblock_val handles.makeyblock_val], 'enable','off')
  set(handles.resetIncluded_xVal, 'visible', 'off');
else
  set([handles.edit_val handles.editxblock_val handles.editplotxblock_val handles.makeyblock_val], 'enable','on')
  resetInclude_build(gcbo,[],guidata(gcbo), 'validation_xblock', 'resetIncluded_xVal');
end

if ~isvyl
  set([handles.edityblock_val handles.editplotyblock_val], 'enable','off')
  set(handles.resetIncluded_yVal, 'visible', 'off');
else
  set([handles.edit_val handles.edityblock_val handles.editplotyblock_val], 'enable','on')
  resetInclude_build(gcbo,[],guidata(gcbo), 'validation_yblock', 'resetIncluded_yVal');
end

%Enable options flyout and analysis options.
set([handles.editoptionsmenu handles.editanalysisopts], 'enable', 'on');

curanal = getappdata(handles.analysis,'curanal');
displayopts = 0;
if ~isempty(curanal) & getappdata(handles.analysis,'optionsedit')
  getappdata(handles.analysis,'curanal');
  tempopts = feval(curanal, 'options');
  if isfield(tempopts,'definitions')
    displayopts = 1;
  end
end

if strcmp(curanal,'parafac') & ~isloaded('xblock',handles)
  %Can't use optionsgui with parafac until there is data, contraints are
  %based on number of modes in data.
  displayopts = 0;
end

if ~displayopts
  set([handles.editoptions], 'enable', 'off')
  set([handles.editoptions], 'Label', 'Method Options'); 
else
  set([handles.editoptions], 'enable', 'on')
  set([handles.editoptions], 'Label', ['Method Options (' upper(curanal) ')']);
end
set(handles.analysispref, 'enable','off')

%disable Dock settings in deployed R2008a or later
% if exist('isdeployed') & isdeployed & checkmlversion('>','7.6')
%   set(handles.editdocksettings, 'visible','off');
% end

%Don't allow editting of Analysis options if other options open.
if ~getappdata(handles.analysis,'optionsedit')
  set(handles.editanalysisopts, 'enable', 'off');
end

set(handles.augmentval, 'enable', 'off');
%Augment val to cal.
if (isxl & isyl & isvxl & isvyl) | ...
   (isxl & ~isyl & isvxl & ~isvyl) | ...
   (~isxl & isyl & ~isvxl & isvyl)
  %All loaded.
  set(handles.augmentval, 'enable', 'on');
end

% --------------------------------------------------------------------
function helpmenu(h, eventdata, handles, varargin)
%Performs checking and setup of help menu.
disphelp = getappdata(handles.analysis,'displayhelp');
if disphelp
  %Help is on, set string to "disable"
  set(handles.helpwindowenable, 'Label', 'Hide Analysis &Help Pane')
else
  %Help is off, set string to "enable"
  set(handles.helpwindowenable, 'Label', 'Show Analysis &Help Pane')
end

flowchart = strcmp(get(handles.flowchart,'visible'),'on');
if flowchart
  %Help is on, set string to "disable"
  set(handles.flowchartenable, 'Label', 'Hide Analysis F&lowchart')
else
  %Help is off, set string to "enable"
  set(handles.flowchartenable, 'Label', 'Show Analysis F&lowchart')
end

%Status Infobox
dispsinfobox = getappdata(handles.analysis,'displaystatusinfobox');
if dispsinfobox
  set(handles.statusinfoboxenable,'Label','Hide Status Info Box');
else
  set(handles.statusinfoboxenable,'Label','Show Status Info Box');
end
  
if strcmp(evriupdate('mode'),'disabled')
  enb = 'off';
else
  enb = 'on';
end
set(handles.help_checkupdates,'visible',enb);

if getplspref('evristats','accumulate')
  ch = 'on';
else
  ch = 'off';
end
set(handles.help_evristats,'checked',ch)

% --------------------------------------------------------------------
function flowchartmenu(h, eventdata, handles, varargin)

flowchart = strcmp(get(handles.flowchart,'visible'),'on');
if flowchart
  %on, so want to turn it off.
  flowchart_callback(handles,'hide');
  setplspref('analysis','flowchart','hide');
else
  %off, so want to turn it on.
  flowchart_callback(handles,'show');
  setplspref('analysis','flowchart','show');

end

resize_callback(handles.analysis,[],handles);
updatestatusimage(handles);

% --------------------------------------------------------------------
function helpwindowmenu(h, eventdata, handles, varargin)

%NOTE:HARDCODE Hiding of dismisswarning - not yet funtional
warnid = getappdata(handles.helpwindow,'warningid');
if ~isempty(warnid)
  enb = 'on';
else
  enb = 'off';
end
set([handles.dismisswarning],'enable',enb);

% --------------------------------------------------------------------
function showhelpwindowmenu(h,eventdata,handles,varargin)

if strcmp(get(gcbf,'selectiontype'),'normal');
  set(handles.disableHelpWindow,'position',get(handles.analysis,'currentpoint'))
  set(handles.disableHelpWindow,'visible','on');
  helpwindowmenu(h, [], handles);
end

% --------------------------------------------------------------------
function warning_dismissonce(h, eventdata, handles, varargin)

setappdata(handles.helpwindow,'dismissed',[getappdata(handles.helpwindow,'dismissed') {getappdata(handles.helpwindow,'warningid')}]);
setappdata(handles.helpwindow,'warningid','');
updatestatusimage(handles);

% --------------------------------------------------------------------
function warning_dismissalways(h, eventdata, handles, varargin)

setplspref('analysis',['dismiss_' getappdata(handles.helpwindow,'warningid')],1);
updatestatusimage(handles);

% --------------------------------------------------------------------
function helpenable(h, eventdata, handles, varargin)

disphelp = getappdata(handles.analysis,'displayhelp');
if disphelp
  %Help is on, so want to turn it off.
  setappdata(handles.analysis,'displayhelp',0)
  setplspref('analysis','displayhelp','off')
else
  %Help is off, so want to turn it on.
  setappdata(handles.analysis,'displayhelp',1)
  setplspref('analysis','displayhelp','on')
end

resize_callback(handles.analysis,[],handles);
updatestatusimage(handles);

% --------------------------------------------------------------------
function filemenu(h, eventdata, handles, varargin)
%Performs checking and setup of file menu.

cura = getappdata(handles.analysis,'curanal');

%Load data should always be enabled. Changes will be handled by load code.
if strcmpi(cura,'clsti')
  en = 'off';
else
  en = 'on';
end
set(handles.fileimportxblock,'enable',en);
set(handles.fileimportyblock,'enable',en);
set(handles.filenewxblock,'enable',en);
set(handles.filenewyblock,'enable',en);
set(handles.loadxdata, 'enable', en)
set(handles.loadydata, 'enable', en)
set(handles.loadboth,'enable', en)
set(handles.loadxdata_val, 'enable', 'on')
set(handles.loadydata_val, 'enable', 'on')

%Set titles disabled.
set([handles.Untitled_93 handles.Untitled_94 handles.Untitled_68 handles.Untitled_69 ...
     handles.Untitled_72 handles.Untitled_73 handles.Untitled_90 handles.Untitled_91 ...
     handles.Untitled_77 handles.Untitled_78 handles.viewprepro_cal handles.viewprepro_val ...
     handles.saveprepro_cal handles.saveprepro_val], 'enable', 'off')

%Load model, should operate like load data.
set(handles.loadmodel, 'enable', 'on')

%Save Data Always on, sub menus will be toggled.
set(handles.savedata, 'enable', 'on')

%Set export model to off.
set(handles.exporttopredictor, 'enable', 'off');

%Export model to types...
set(handles.savemodelas,'label','To &File','callback','');
mylist = savemodelas;

if ~ismember(cura,{'pls' 'plsda' 'ann' 'svm' 'mlr' 'pca' 'simca' 'knn' 'svmda'})
  %Remove PLT export.
  mylist = mylist(~ismember(mylist(:,3),'.plt'),:);
end

delete(allchild(handles.savemodelas));
for j=1:length(mylist);
  mh = uimenu(handles.savemodelas,'label',mylist{j,1},...
    'callback',['analysis(''savemodelasCallback'',gcbo,[],guidata(gcbf),get(gcbo,''userdata''))']);
  set(mh,'userdata',j);
end

if strcmpi(cura,'parafac')
  %Add export to openfluor since it's a special case.
  mh = uimenu(handles.savemodelas,'label','OPENFLUOR TXT-file (*.txt)',...
    'callback',['analysis(''exportmodel_openfluor'',gcbo,[],guidata(gcbf),get(gcbo,''userdata''))']);
  set(mh,'userdata',j+1);
end

%Export Prediction.
if ~isloaded('model',handles)
  set(handles.exportpredrescal,'enable','off');
else
  set(handles.exportpredrescal,'enable','on');
end

if ~isloaded('prediction',handles)
  set(handles.exportpredresval,'enable','off');
else
  set(handles.exportpredresval,'enable','on');
end

%Save model.
if ~isloaded('model',handles)
  set(handles.savemodel, 'enable', 'off')
  set(handles.savemodelas, 'enable', 'off')
  set([handles.exportregvec handles.exporttopredictor handles.exportmodelbuilder], 'enable', 'off')
  set(handles.exportmodelbuilder, 'enable', 'off')
else
  set(handles.savemodel, 'enable', 'on')
  set(handles.savemodelas, 'enable', 'on')
  if ismember(getappdata(handles.analysis,'curanal'),{'pls','pcr'})
    set(handles.exportregvec, 'enable', 'on')
  else 
    set(handles.exportregvec, 'enable', 'off')
  end
  set([handles.exporttopredictor handles.exportmodelbuilder], 'enable', 'on')
  set(handles.exportmodelbuilder, 'enable', 'on')
end

%Save prediction.
if ~isloaded('prediction',handles)
  set([handles.savetest handles.clearprediction], 'enable', 'off')
else
  set([handles.savetest handles.clearprediction], 'enable', 'on')
end

%Clear menu.
set(handles.clearmenu, 'enable', 'on')

%Clear data.
if ~isloaded('xblock',handles);
  set(handles.cleardata, 'enable', 'off')
else
  set(handles.cleardata, 'enable', 'on')
end

%Clear ydata.
if ~isloaded('yblock',handles);
  set(handles.clearydata, 'enable', 'off')
else
  set(handles.clearydata, 'enable', 'on')
end

%Clear data.
if ~isloaded('validation_xblock',handles);
  set(handles.cleardata_val, 'enable', 'off')
else
  set(handles.cleardata_val, 'enable', 'on')
end

%Clear ydata.
if ~isloaded('validation_yblock',handles);
  set(handles.clearydata_val, 'enable', 'off')
else
  set(handles.clearydata_val, 'enable', 'on')
end


%Clear model.
if strcmp(getappdata(handles.analysis,'statmodl'),'none');
  set(handles.clearmodel, 'enable', 'off')
else
  set(handles.clearmodel, 'enable', 'on')
end

%Clear all.
set(handles.clearboth, 'enable', 'on')

%Clear options.
if isempty(getappdata(handles.analysis,'analysisoptions'));
  set(handles.clearoptions, 'enable', 'off')
else
  set(handles.clearoptions, 'enable', 'on')
end

%Load options.
if isempty(getappdata(handles.analysis,'curanal'));
  set(handles.loadoptions, 'enable', 'off')
else
  set(handles.loadoptions, 'enable', 'on')
end

if isempty(getappdata(handles.analysis,'analysisoptions'))
  set(handles.saveoptions, 'enable', 'off')
else
  set(handles.saveoptions, 'enable', 'on')
end

%enable/disable certain items based on apply_only flag
if getappdata(handles.analysis,'apply_only');
  en = 'off';
else
  en = 'on';
end
set(findobj(handles.file,'label','&Calibration'),'visible',en,'enable',en)

% --------------------------------------------------------------------
function filemenubuild(h, eventdata, handles, varargin)
%Build menu items for file menu. Can't be done dynamically on Mac 2011a.

%add import options
ihandles = [handles.fileimportxblock handles.fileimportyblock handles.fileimportxblock_val handles.fileimportyblock_val];
inames   = {'x' 'y' 'x_val' 'y_val'};
allch = allchild(ihandles);
delete([allch{:}]);
set(ihandles,'callback','');
for jj = 1:length(ihandles)
  editds_addimportmenu(ihandles(jj),['analysis(''fileimport'',gcbf,[],guidata(gcbf),''' inames{jj} ''',get(gcbo,''userdata''));']);
end

if checkmlversion('>=','7.0') & (ismac & checkmlversion('>=','7.12') & checkmlversion('<','7.14'))%Mac 2011a can't have html menus.
  %Remove HTML because won't render in mac 2011a.
  set([handles.Untitled_93 handles.Untitled_68 handles.Untitled_72 handles.Untitled_77 ...
    handles.Untitled_90 handles.viewprepro_cal],'Label','Calibration')
  set([handles.Untitled_94 handles.Untitled_69 handles.Untitled_73 handles.Untitled_91 ...
    handles.Untitled_78 handles.viewprepro_val],'Label','Validation')
  %Add seperator.
  set([handles.loadxdata handles.loadxdata_val handles.fileimportxblock handles.fileimportxblock_val ...
    handles.filenewxblock handles.filenewxblock_val handles.savexblock handles.savexblock_val ...
    handles.cleardata handles.cleardata_val handles.viewpreprox handles.viewpreprox_val ...
    handles.saveprepro_cal handles.saveprepro_val],'separator','on');
end

% --------------------------------------------------------------------
function clearboth(h, eventdata, handles, varargin)
%Clear either val or cal x and y blocks. varargin{1} should be either 'cal'
%or 'val'

if nargin<4
  %Calling clear both from statusbox image so determine 4th input.
  axh = findobj(allchild(handles.analysis),'tag','statusimage');
  [btn_name, group] = status_location(axh);
  if strcmpi(group,'validation')
    varargin{1} = 'val';
  else
    varargin{1} = 'cal';
  end
end

mysfx = '';
if strcmp(varargin{1},'val')
  mysfx = '_val';
end

%Use handles.analysis as 'h' to fool cleardata_callback into not checking
%for a context menu call.
cleardata_callback(handles.analysis, eventdata, handles, ['x' mysfx])
cleardata_callback(handles.analysis, eventdata, handles, ['y' mysfx])

% --------------------------------------------------------------------
function clearall(h, eventdata, handles, varargin)
%Clear all data. 

clearboth(handles.analysis, eventdata, handles, 'val')
clearboth(handles.analysis, eventdata, handles, 'cal')
clearmodel(h, [], guidata(handles.analysis), 1)
clearoptions(h, eventdata, handles, varargin)
%Set pp back to default.
preprodefault(handles, analysis('options'));
%Prediction cleared in cleardata_callback.

% --------------------------------------------------------------------
function cleardata_callback(h, eventdata, handles, varargin)
%Clear data.
%
% Clear General
%
% Clear Cal X
%   Clear cal Y data.
%   Set statmodl to "loaded" so can't make changes to it.
%   Disable PCs selection if not set to current modl # of pcs.
%   Disable crossval.
%   Don't need to close all children.
%   
% Clear Cal y
%
% Clear Val x
%   Clear prediction.
%   Clear val y data.
%
% Clear Val y
%
%TODO: Consolidate clear data code.

switch varargin{1}
  case {'x' 'xblock'}
    setobjdata('xblock',handles,[]);
    
    %Remove reference to Y from X Block include field settings.
    setappdata(handles.analysis,'lastusedxcolumn',[]);
    setappdata(handles.analysis,'lastusedxinclude',[]);
    
    modl = getobjdata('model',handles);
    if ~strcmp(getappdata(handles.analysis,'statmodl'),'none')
      %Can't make changes to model.
      setappdata(handles.analysis,'statmodl','loaded');
      %lock # of PCs/LVs at currently applied #
      % (this should be redundant unless they selected a new # of PCs without
      % hitting "apply" before clearing data)
      if isfieldcheck('modl.loads',modl)
        n = size(modl.loads{2,1},2);
        if n>0 %Fix for clsti model having loads field but it being 0, error will occur below because there is no ssq table for clsti
          set(handles.pcsedit,'String',int2str(n))
          mytbl = getappdata(handles.analysis,'ssqtable');
          setselection(mytbl,'rows',n)
          %set(handles.ssqtable,'Value',n)
          setappdata(handles.pcsedit,'default',n)
        end
      end
    end
    updatecrossvallimits(handles);
    setappdata(handles.pcsedit,'default',[])   %clear default # of PCs

    fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
    if ~isempty(fn);
      feval(fn,'updatefigures',handles.analysis);
    end

  case {'y' 'yblock'}
    cleary = true; %Clear y status.
    fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
    modlstat = getappdata(handles.analysis,'statmodl');
    %Construct x block profile.
    x = getobjdata('xblock',handles);
    xprofile = varprofile(x);

    %Construct y block profile.
    y = [];
    yprofile = varprofile(y);
    if ~strcmp(modlstat,'loaded')
      if ~isempty(fn) & feval(fn,'isdatavalid',xprofile,yprofile,handles.analysis);
        %Data is still valid, do nothing.
      else
        %Data is no longer valid. Handle model.
        if strcmp(modlstat,'calold')
          %if we had a calibrated model, make it a "loaded" model
          setappdata(handles.analysis,'statmodl','loaded');
        elseif strcmp(modlstat,'calnew')
          %Need to clear model.
          if ~modelsaved(handles);
            ans=evriquestdlg('Must clear model. Do you wish to save?', ...
              'Model Not Saved','Clear Without Saving','Save & Clear','Cancel','Clear Without Saving');
          else
            ans = 'Clear Without Saving';
          end
          switch ans
            case {'Cancel'}
              %Restore y data and return
              cleary = false;
            case {'Save & Clear'}
              if isempty(savemodel(handles.savemodel, [], handles, []))
                return
              end
              clearmodel(handles.analysis, [], handles);
            case {'Clear Without Saving'}
              clearmodel(handles.analysis, [], handles);
          end
        else
          %Model status 'none' do nothing.
        end
      end
    end
    if cleary
      setobjdata('yblock',handles,[]);
    end
  case {'x_val' 'validation_xblock'}
    setobjdata('validation_xblock',handles,[]);
    
    %Remove reference to Y from X Block include field settings.
    setappdata(handles.analysis,'validation_lastusedxcolumn',[]);
    setappdata(handles.analysis,'validation_lastusedxinclude',[]);
    
    cleartest(h, [], handles)
  case {'y_val' 'validation_yblock'}
    setobjdata('validation_yblock',handles,[]);
    if isyused(handles)
      %The current analysis uses a y block so clearing it will cause
      %prediction to be invalid.
      cleartest(h, [], handles)
    end
end
updatestatusimage(handles);
toolbarupdate(handles);

% --------------------------------------------------------------------
function cleartest(h, eventdata, handles, varargin)
%Clear prediction.
setobjdata('prediction',handles,[]);
updatestatusimage(handles);

%Update figures.
fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
if ~isempty(fn);
  feval(fn,'updatefigures',handles.analysis);
  
  %validtype:PLS,PCR,NPLS,MLR,PLSDA,*LWR,*ANN
  vld_mdls = {'PLS','PCR','NPLS','MLR','PLSDA'};
  %Update model (remove RMSEP old values)
  modl = getobjdata('model',handles);
  if ~(isempty(modl)) & (ismember(modl.modeltype,vld_mdls))
    modl.detail.rmsep = [];
    setobjdata('model',handles,modl);
  end
end

% --------------------------------------------------------------------
function clearmodel(h, eventdata, handles, varargin)
%Clear the model
%Don't clear options here becuase want to retain settings if build
%addtional model. 
%If third input is a "1" (true) then any figures associated with the model
%will be forced closed. This also happens if the user explictly closes via
%the menu items

modlstat = getappdata(handles.analysis,'statmodl');
if strcmp(modlstat,'none');
  return
end

setappdata(handles.analysis,'statmodl','none');      %'calold', 'calnew', 'loaded'
setobjdata('model',handles,[]);
setobjdata('rawmodel',handles,[]);
setobjdata('prediction',handles,[]);
setobjdata('modelcache',handles,[]);

%handle closing of figures
if nargin<4 | isempty(varargin{1})
  varargin{1} = false;
end
if ~isempty(gcbf) & ~isempty(gcbo) & gcbf==handles.analysis & ismember(get(gcbo,'tag'),{'clearmodel','clearboth','status_model_clear'});   %called from the clear model menu item?
  %force this on for calls from certain menu items
  varargin{1} = true;
end
if varargin{1}
  %close figures
  fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
  if ~isempty(fn);
    feval(fn,'closefigures',handles);
  end
else
  autoclear(handles)
  %  calcmodel_Callback(handles.analysis, [], handles)  %uncomment to automatically rebuild model!!
end

toolbarupdate(handles)  %set buttons
updatestatusimage(handles);

fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
if ~isempty(fn);
  feval(fn,'updatessqtable',handles);
end

% --------------------------------------------------------------------
function clearoptions(h, eventdata, handles, varargin)
%Clear saved optoins.
setopts(handles,[],[]);

%Call change callback.
curanalysis = getappdata(handles.analysis,'curanal');
fn  = analysistypes(curanalysis,3);
if ~isempty(fn);
  feval(fn,'optionschange',handles.analysis);
end

%----------------------------------------------------------------------
function rebuildmodel(h, eventdata, handles, varargin)

clearmodel(h, [], handles, 0)
calcmodel_Callback(h,[],handles);


%----------------------------------------------------------------------
function updatestatusboxes(handles)
%TODO: update all calls to updatestatusboxes.
updatestatusimage(handles)
%----------------------------------------------------------------------
function updatestatusimage(handles)
%Update status image.

statusimage(handles);

%Since this is a primary update function update the following items.
flowchart_callback(handles);
updatehelpstatus(handles)
autoselect_update(handles);

%Update panel manager.
panelmanager('update',handles.ssqframe)

%Make sure any errant axes except status image are deleted.
delete_bad_axes(handles.analysis);
assignguiname(handles)

%--------------------------------------------------------------------
function delete_bad_axes(fig)
%Make sure any errant axes except status image are deleted.

persistent lastrun

if isempty(lastrun)
  lastrun = 0;
end
if (now-lastrun)*24*60*60 < 0.5 %don't run more frequently than this number of seconds
  return;  
end
lastrun = now;

badax = findobj(fig,'type','axes','tag','');
if ~isempty(badax)
  ch = get(badax,'children');
  if length(ch)~=1 | ~strcmp(get(ch(1),'type'),'image')
    delete(badax)
  end
end

%--------------------------------------------------------------------
function assignguiname(handles)

if isloaded('xblock',handles)
  x = getobjdata('xblock',handles);
  y = getobjdata('yblock',handles);

  %get some block info
  names   = x.name;
  handles.datasource = {getdatasource(x) []};
  datsize = sprintf('%i x ',handles.datasource{1}.size(1:end-1));
  datsize = [datsize sprintf('%i',handles.datasource{1}.size(end))];
  if strcmp(x.type,'image')
    sizedata = size(x);
    im = x.imagemode;
    if im > 1
      sizedata = [sizedata(1:im - 1) x.imagesize sizedata(im+1:end)];
    else
      sizedata = [x.imagesize sizedata(2:end)];
    end
    datsize = sprintf('%i x ',sizedata(1:end-1));
    datsize = [datsize sprintf('%i',sizedata(end))];
  end

  if ~isempty(y) & isyused(handles,true)
    names   = [names   ', ' y.name];
    handles.datasource{2} = getdatasource(y);
    datsize = [datsize ', ' sprintf('%i x ',handles.datasource{2}.size(1:end-1))];
    datsize = [datsize sprintf('%i',handles.datasource{2}.size(end))];
  end

  figname_data = [' - ' names];
else
  figname_data = '';
end

figname_model = [deblank(upper(getappdata(handles.analysis,'curanal'))) ' (No Model)'];
modl = getobjdata('model',handles);
if ~isempty(modl)

  figname_model = [modl.modeltype];

  if isfield(modl,'loads');
    nlvs = size(modl.loads{2,1},ndims(modl.loads{2,1}));
  else
    nlvs = 0;
  end
  switch lower(modl.modeltype)
    case {'pls' 'plsda'};
      figname_model   = [figname_model ' ' num2str(nlvs) ' LVs'];
    case 'mlr';
      %don't show
    case {'pcr' 'pca' 'mpca'}
      figname_model   = [figname_model ' ' num2str(nlvs) ' PCs'];
    case 'simca'
      figname_model   = [figname_model];
    case 'knn'
      nlvs = modl.k;
      figname_model   = [figname_model ' (' num2str(nlvs) ')'];
    otherwise
      if nlvs>0
        figname_model   = [figname_model ' ' num2str(nlvs) ' comp'];
      end
  end
end

%add appropriate name to this GUI
figname = [' - ' figname_model figname_data];

%make sure this name is unique
dupname = double(findobj(allchild(0),'type','figure','name',['Analysis' figname]));
thishandle = double(handles.analysis);
basefigname = figname;
if ~isempty(dupname) & (length(dupname)>1 | dupname(1)~=thishandle)
  dupname = setdiff(dupname,thishandle);
  index = 1;
  while any(dupname)
    index = index+1;
    figname = [basefigname sprintf(' (%i)',index)];
    dupname = double(findobj(allchild(0),'type','figure','name',['Analysis' figname]));
    dupname = setdiff(dupname,thishandle);
  end
end
set(handles.analysis,'name',['Analysis' figname]);
setappdata(handles.analysis,'figname_info',figname);


%----------------------------------------------------------------------
function color = statuscolor(name)

colors.red     = [ 0.9725    0.7294    0.7294 ];
colors.yellow  = [ 0.9922    1.0000    0.6078 ];
colors.green	 = [ 0.7961    1.0000    0.7686 ];
colors.grey	   = [ 0.8745    0.8745    0.8745 ];
colors.white   = [ 1.0000    1.0000    1.0000 ];

if nargin==0
  color = colors;
else
  color = colors.(name);
end

%----------------------------------------------------------------------
function updatehelpstatus(handles)
%Update help window.

opts = analysis('options');

statmodl = getappdata(handles.analysis,'statmodl'); %'none','calold','calnew','loaded'

str = message(handles);
color = 'white';
setappdata(handles.helpwindow,'warningid','');

%This the best place to update font size of ssq header, ssq table, and
%helpwindow that I cna think of.
set(handles.tableheader,'Fontsize',opts.ssqfontsize);
%set(handles.ssqtable,'Fontsize',opts.ssqfontsize);
set(handles.helpwindow,'Fontsize',opts.ssqfontsize);

%special handling of dismissed notice
dismissed = getappdata(handles.helpwindow,'dismissed');
if isempty(dismissed); dismissed = {}; end
setappdata(handles.helpwindow,'dismissed',{});

if ismember(statmodl,{'calold' 'calnew'})
  issue = reviewmodel(handles.analysis);
else
  issue = reviewcrossval(handles.analysis);
end

shown = 0;  %number of warnings shown
waiting = 0; %number of warnings waiting
hidden = 0;  %number we've hidden
for issueindex = 1:length(issue);
  harddismiss = getplspref('analysis',['dismiss_' issue(issueindex).issueid]);
  if isempty(harddismiss) | ~harddismiss
    if ~ismember(issue(issueindex).issueid,dismissed);
      %we got a warning, use it and it's color
      if shown<1;  %unless we've exceeded the allowed number of warnings
        str = [issue(issueindex).issue 10 '----------------------' 10 str];
        switch color
          case 'red'
            %never override a red
          case 'yellow'
            %only red can change yellow
            if strcmpi(issue(issueindex).color,'red')
              color = 'red';
            end
          otherwise
            %take whatever color
            color = issue(issueindex).color;
        end
        setappdata(handles.helpwindow,'warningid',issue(issueindex).issueid);
        shown = shown+1;  %don't SHOW any more warnings
      else
        waiting = waiting+1;  %note that there are some warning waiting
      end
    else
      %previous warning happened again, keep it in dismissed
      setappdata(handles.helpwindow,'dismissed',[getappdata(handles.helpwindow,'dismissed') {issue(issueindex).issueid}]);
      hidden = hidden+1;
    end
  end
end

if shown>0
  str = ['<html><b><font color="red">[' num2str(hidden+1) ' of ' num2str(hidden+shown+waiting) ']</font></b> ' str '</html>'];
end

%Get help window size and adjust size for wrapping.
pos = get(handles.helpwindow,'position');
pos(3) = max(1,pos(3)-23); %Needs to be 23 for version 6.5 widths.
%Create a dummy control so textwrap will space correctly.
dummyh = uicontrol(handles.analysis,'visible','off','position',pos,'Fontsize',opts.ssqfontsize);
str = textwrap(dummyh,{str});
set(handles.helpwindow,'Value',[]);%Want proper behavior and look so set to empty.
set(handles.helpwindow,'String',str)
set(handles.helpwindow,'backgroundcolor',statuscolor(color));
set(handles.helpwindow,'buttondownfcn','analysis(''showhelpwindowmenu'',gcbo,[],guidata(gcbf))');
delete(dummyh);

%---------------------------------------------------------------------
function correlationmap(h, eventdata, handles, varargin)

pointer(handles.analysis,1);
%Do preprocessing (this is a general-use block of code!)
x   = getobjdata('xblock',handles);
y   = getobjdata('yblock',handles);
ppx = getappdata(handles.preprocessmain,'preprocessing');
ppy = getappdata(handles.preproyblkmain,'preprocessing');

ppwb = waitbar(.5,'Applying Preprocessing...');
try
  if ~isempty(x) & ~isempty(y)
    yp = preprocess('calibrate',ppy,y);
    xp = preprocess('calibrate',ppx,x,yp);
  elseif ~isempty(x)
    xp = preprocess('calibrate',ppx,x);
  elseif ~isempty(y)
    yp = preprocess('calibrate',ppy,y);
  end
catch
  pointer(handles.analysis,0);
  close(ppwb)
  rethrow(lasterror)
end
close(ppwb);
  
if nargin<4;
  regroup = 'std';
else
  regroup = varargin{1};
  block = varargin{2};
end

try
  %calculate corrmap
  if strcmp(block,'x')
    corrmap(xp,regroup);
  else
    corrmap(yp, regroup)
  end
  adopt(handles,gcf)  %get handle of figure created by corrmap
catch
  erdlgpls({'Unable to create correlation map', lasterr},'Correlation Map');
end
pointer(handles.analysis,0);

%---------------------------------------------------------------------
function xycorrcoefplot(h, eventdata, handles, varargin)

pointer(handles.analysis,1);
%Do preprocessing (this is a general-use block of code!)
x   = getobjdata('xblock',handles);
y   = getobjdata('yblock',handles);
if isempty(y)
  erdlgpls({'Y-Block required for correlation coefficients plot.'},'XYCORRCOEF Y-Block Required');
  return
end
ppx = getappdata(handles.preprocessmain,'preprocessing');
ppy = getappdata(handles.preproyblkmain,'preprocessing');

ppwb = waitbar(.5,'Applying Preprocessing...');
try
  yp = preprocess('calibrate',ppy,y);
  xp = preprocess('calibrate',ppx,x,yp);
catch
  pointer(handles.analysis,0);
  close(ppwb)
  rethrow(lasterror)
end
close(ppwb);

try
  %calculate corrmap
  xycorrcoef(xp,yp);
  adopt(handles,gcf)  %get handle of figure created by corrmap
catch
  erdlgpls({'Unable to create correlation coefficients plot.', lasterr},'Correlation Coefficients Plot Error');
end
pointer(handles.analysis,0);

%---------------------------------------------------------------------
function addcomponentnames_Callback(h, eventdata, handles, varargin)
%Show gui to add component names to specific model types (see model object).

modl = getobjdata('model',handles);

if isempty(modl) | ~isfieldcheck(modl,'modl.detail.componentnames')
  return
end

fig = uifigure('visible','on',...
  'name','Add Component Names',...
  'tag','loaddatafig',...
  'numbertitle','off',...
  'integerhandle','off',...
  'units','pixels',...
  'menubar','none',...
  'toolbar','none',...
  'position',[520   661   324   340],...
  'color',[0.9412    0.9412    0.9412]);

% uicontrol(fig,'style','text','units','pixels','position',[ 15 102 294 30 ],...
%   'backgroundcolor',[0.9412    0.9412    0.9412],...
%   'fontsize',getdefaultfontsize,'fontweight','bold',...
%   'string','Load into which data block?')
%6 rows of controls.
grid1 = uigridlayout(fig,[2 1]);
grid1.RowHeight = {'1x'  45};

mydata = [num2cell([1:modl.ncomp]') modl.componentnames'];

mytable = uitable(grid1,'Data',mydata,'ColumnName',{'Component Number' 'Component Name'},...
  'ColumnEditable',[false true],'ColumnFormat',{'numeric' 'char'},'RowName',{},...
  'RowStriping',false);
columncenterstyle = uistyle('HorizontalAlignment','center');
addStyle(mytable,columncenterstyle,'column',1);


%Factory object filter.
grid2 = uigridlayout(grid1,[1 3]);
grid2.ColumnWidth = {'1x' 100 100};

grid3 = uigridlayout(grid2);%Spacer

b1 = uibutton(grid2,'push','text','OK');
b2 = uibutton(grid2,'push','text','Cancel');
set([b1 b2],'fontsize',getdefaultfontsize,'ButtonPushedFcn',@(btn,event) addComponentNameButtonPushed(btn,fig));

centerfigure(fig,handles.analysis);
evriwindowstyle(fig,0,1)
uiwait(fig);

if ishandle(fig)
  ud = get(fig,'userdata');
  if strcmpi(ud,'ok')
    mydata = mytable.Data;
    modl.detail.componentnames = mydata(:,2)';
    setobjdata('model',handles,modl);
  end
  delete(fig);
end

%---------------------------------------------------------------------
function addComponentNameButtonPushed(btn,fig)
%Add flag to fig then resume so code above runs. 
set(fig,'UserData',lower(get(btn,'Text')));
uiresume(fig);

%---------------------------------------------------------------------
function sendtomcct_Callback(h, eventdata, handles, varargin)
%Send current model to MCCTTool.

modl = getobjdata('model',handles);
if ~isempty(modl)
  MCCTTool(modl);
end


%---------------------------------------------------------------------
function estimatefactors_Callback(h, eventdata, handles, varargin)

pointer(handles.analysis,1);

%get preprocessing
x   = getobjdata('xblock',handles);
ppx = getappdata(handles.preprocessmain,'preprocessing');
modl = getobjdata('model',handles);
rawmodl = getobjdata('rawmodel',handles);

try
  %calculate estimated factors
  opts = [];
  opts.preprocessing = {ppx};
  opts.plots = 'final';
  eigsnr = estimatefactors(x,opts);

  %adopt figure and change name
  fig = gcf;
  adopt(handles,fig)  %get handle of figure created by corrmap
  set(fig,'name','Estimated Factor Signal to Noise Ratio');

  setappdata(handles.analysis,'eigsnr',eigsnr);  %this will be copied (?) into new models by pca_guifcn

  %save results in model (if a field exists for this info)
  if ~isempty(modl)
    if isfieldcheck('modl.detail.eigsnr',modl)
      modl.detail.eigsnr = eigsnr;
      setobjdata('model',handles,modl);
    end
  end
  if ~isempty(rawmodl) & isfieldcheck('modl.detail.eigsnr',rawmodl)
    rawmodl.detail.eigsnr = eigsnr;
    setobjdata('rawmodel',handles,rawmodl);
  end
  
catch
  erdlgpls({'Unable to estimate factor signal to noise', lasterr},'Correlation Map');
end
pointer(handles.analysis,0);

%---------------------------------------------------------------------
function ewfa_Callback(h, eventdata, handles, varargin)
%Run EWFA on image.

pointer(handles.analysis,1);

%get preprocessing
x   = getobjdata('xblock',handles);
ppx = getappdata(handles.preprocessmain,'preprocessing');

try
  %Run ewfa similar to how corrmap is called.
  xp = preprocess('calibrate',ppx,x);
  ewfa_set = inputdlg({'Window Size (x and y direction, odd):' 'Noise Level:'},'EWFA Settings',1,{'5 5' '0'});

  if isempty(ewfa_set)
    pointer(handles.analysis,0);
    return
  end
  mywindow = str2num(ewfa_set{1});
  if isempty(mywindow)
    pointer(handles.analysis,0);
    return
  end
  mynoise = str2num(ewfa_set{2});
  if isempty(mynoise)
    mynoise = 0;
  end

  %Run ewfa
  opts.plots = 'final';
  ewfa_result = ewfa_img(xp,mywindow,mynoise,opts);

  %adopt figure and change name
  fig = gcf;
  adopt(handles,fig)  %get handle of figure created by corrmap
  set(fig,'name','Evolving Window Factor Analysis');
  
catch
  erdlgpls({'Unable to run EWFA on Image.', lasterr},'EWFA Error');
end
pointer(handles.analysis,0);

%---------------------------------------------------------------------
function ppdata = viewprepro(h, eventdata, handles, varargin)
%Plot the preprocessed x-block and the preprocessed y-block
%fourth input (varargin{1}) must be one of the strings:
%  'x' 'xblock' 'y' 'yblock' 'x_val' 'y_val'

if nargout>0
  ppdata = [];
end
x   = getobjdata('xblock',handles);
y   = getobjdata('yblock',handles);
ppx = getappdata(handles.preprocessmain,'preprocessing');
ppy = getappdata(handles.preproyblkmain,'preprocessing');
curAnalysis = getappdata(handles.analysis, 'curanal');
opts = getappdata(handles.analysis, 'analysisoptions');

if strcmp(getappdata(handles.analysis,'statmodl'),'loaded')
  modl = getobjdata('model',handles);
  if ~isfieldcheck('modl.detail.preprocessing',modl);
    erdlgpls('View Preprocessed Data can not be used with this model type.','View Preprocessing Canceled');
    return
  end
  ppx = modl.detail.preprocessing{1};
  if length(modl.detail.preprocessing)>1
    ppy = modl.detail.preprocessing{2};
  else
    ppy = [];
  end
end

%check all xblock preprocessing methods for osc keyword
if ~isempty(ppx)
  hasOSC = ismember({ppx.keyword}, 'osc');
% else
%   hasOSC = [];
end
%if doing OSC preprocessing and classification with no y block
%create a y block from class set using class2logical
if isempty(y) & any(hasOSC)
    thisMethodType = analysistypes(curAnalysis, 5);
    if strcmp(thisMethodType, 'Classification')
        modelGroups =  getappdata(findobj(handles.analysis, 'tag', 'choosegrps'),'modelgroups');
        myClassSet = opts.classset;
        if isempty(modelGroups)
            y = class2logical(x, [], myClassSet);
        else
            y = class2logical(x, modelGroups, myClassSet);
        end
    else
        if ~isempty(x.class{1})
            y = class2logical(x, [],1);
        end
    end
end

pointer(handles.analysis,1);
ppwb = waitbar(.5,'Applying Preprocessing...');

switch varargin{1}
  case {'x' 'xblock'}
    for i = 1:length(x.include)
      if isempty(x.include{i})
        %Can't display if everything is excluded.
        erdlgpls('All samples excluded. Can not display','View Preprocess Error');
        if ishandle(ppwb); close(ppwb); end
        pointer(handles.analysis,0);
        return
      end
    end
    %preprocess first
    try
      if strcmp(getappdata(handles.analysis,'statmodl'),'loaded')
        if ~isempty(y);
          xp = preprocess('apply',ppx,x);
        else
          xp = preprocess('apply',ppx,x);
        end
      else
        if ~isempty(y);
          yp = preprocess('calibrate',ppy,y); %'apply/cal string
          xp = preprocess('calibrate',ppx,x,yp);
        else
          xp = preprocess('calibrate',ppx,x);
        end
      end
    catch
      if ishandle(ppwb); close(ppwb); end
      erdlgpls(lasterr,'Unable to plot preprocessed data');
      if nargout==0;
        xp = x;
      else
        xp = [];
      end
    end

    if nargout==0;
      %make plot
      updatepreproplot(handles,xp,'Preprocessed X-data','x');
    else
      ppdata = xp;
    end

  case {'y' 'yblock'}
    %similar code for y-menu
    if ~isempty(y);
      for i = 1:length(y.include)
        if isempty(y.include{i})
          %Can't display if everything is excluded.
          erdlgpls('All samples excluded. Can not display','View Preprocess Error');
          if ishandle(ppwb); close(ppwb); end
          pointer(handles.analysis,0);
          return
        end
      end
      %preprocess first
      try
        if strcmp(getappdata(handles.analysis,'statmodl'),'loaded')
          yp = preprocess('apply',ppy,y); %'apply/cal string
        else
          yp = preprocess('calibrate',ppy,y); %'apply/cal string
        end
      catch
        pointer(handles.analysis,0);
        close(ppwb)
        rethrow(lasterror)
      end

      if nargout==0;
        %make plot
        updatepreproplot(handles,yp,'Preprocessed Y-data','y');
      else
        ppdata = yp;
      end
    end

  case {'x_val' 'y_val' 'validation_xblock' 'validation_yblock'}
    myblock = varargin{1};
    modl = getobjdata('model',handles);

    if isempty(modl)
      erdlgpls('View Preprocessed Data can not be used without a model calculated. Please calculate a model first.','View Preprocessing Canceled');
      if ishandle(ppwb); close(ppwb); end
      pointer(handles.analysis,0);
      return
    end

    ppx = modl.detail.preprocessing{1};
    if length(modl.detail.preprocessing)>1
      ppy = modl.detail.preprocessing{2};
    else
      ppy = [];
    end

    if strcmp(myblock,'x_val') | strcmp(myblock,'validation_xblock')
      dat = getobjdata('validation_xblock',handles);
      dat = matchvars(modl,dat);
      dat.include{2} = modl.detail.includ{2,1};
      mypp = ppx;
      mylabel = 'X';
    else
      dat = getobjdata('validation_yblock',handles);
      [junk,dat] = matchvars(modl,getobjdata('validation_xblock',handles),dat);
      dat.include{2} = modl.detail.includ{2,2};
      mypp = ppy;
      mylabel = 'Y';
    end

    try
      ppdat = preprocess('apply',mypp,dat);
    catch
      pointer(handles.analysis,0);
      if ishandle(ppwb); close(ppwb); end
      rethrow(lasterror)
    end

    if nargout==0;
      %make plot
      updatepreproplot(handles,ppdat,['Preprocessed Validation ' mylabel '-data'],lower(['validation_' mylabel]));
    else
      ppdata = ppdat;
    end
end

if ishandle(ppwb);
  waitbar(1,ppwb);
  close(ppwb);
end

pointer(handles.analysis,0);

%----------------------------------------------------------
function updatepreproplot(handles,ppval,titlename,block)
%Update prepro sharedddata.
%  handles   - handles structure.
%  ppval     - preprocessed data.
%  titlename - Title/name value for plotgui.
%  block     - 'x' or 'y' or 'x_val' or 'y_val' specifying the data block being updated

item = [block 'blockprepro'];%Name a property so we can search on it.
myid = getobj(item,handles);

if isempty(myid)
  %no existing shared preprocessed data
  newplot = 1;
else
  %existing shared data See if there is a valid plotgui subscriber.
  myplotfigs = findpg(myid);
  newplot    = isempty(myplotfigs);  %create new figure if no figures exist
end

%set new data (also updates existing figures)
myprops = [];
myprops.includechangecallback = 'dataincludechange(myobj.id)';
myprops.name = titlename;
myid = setobjdata(item,handles,ppval,myprops);
linkshareddata(getobj([block 'block'],handles),'add',myid,'analysis',struct('linkmap',':','isdependent',1));
linkshareddata(myid,'add',getobj([block 'block'],handles),'analysis',struct('linkmap',':'));

if newplot
  plotgui('new',myid,'plotby',0,'name',titlename);
else
  figure(min(double(myplotfigs)));  %bring figure to the front
end


%----------------------------------------------------------
function toolbarupdate(handles)

statmodl = getappdata(handles.analysis,'statmodl');

%easy - no model, disable buttons
if strcmp(statmodl,'none') | strcmp(statmodl,'calnew');
  toolbar(handles.analysis, 'disable');
else
  toolbar(handles.analysis, 'enable')
end

if isfield(handles,'calcmodel');
  %calc is harder
  if (isloaded('xblock',handles) & ~isloaded('model',handles)) ... 
    | (isloaded('validation_xblock',handles) & ~isloaded('prediction',handles)) ...
    | strcmp(statmodl,'calnew')
    set(handles.calcmodel, 'Enable','on')
  else
    set(handles.calcmodel, 'Enable','off')
  end
end

if isfield(handles,'preprotbbtn')
  %update preprocessing button (if there)
  if ~isloaded('xblock',handles) | strcmp(getappdata(handles.analysis, 'statmodl'),'loaded')
    set(handles.preprotbbtn,'enable','off');
  else
    set(handles.preprotbbtn,'enable','on');
  end
end

fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
if ~isempty(fn);
  feval(fn,'gui_updatetoolbar',handles.analysis,[],handles);
end

%make duplicate toolbar items in tools menu
handles = guidata(handles.analysis);%Update handles so don't create duplicate toolbarmenu
if ~isfield(handles,'toolbarmenu')
  uimenu(handles.tools,'label','Toolbar','tag','toolbarmenu','callback','analysis(''toolbarmenu'',gcbo,[],guidata(gcbf));');
  handles = guihandles(handles.analysis);
  guidata(handles.analysis,handles);
end

toolbarmenu(handles.analysis,[],handles);

%----------------------------------------------------------
function toolbarmenu(h,eventdata,handles,varargin)

tmenu = handles.toolbarmenu(end);
tb = findobj(handles.analysis,'tag','AnalysisToolbar');
tblist = get(tb,'children');
tblist = flipud(tblist); %order to same as toolbar sequence
tbtags = get(tblist,'tag');

%If only one button then tags are a char not cell so put into cell to avoid
%error in for loop.
if ~iscell(tbtags)
  tbtags = {tbtags};
end

for j=1:length(tbtags)
  tbtags{j} = ['toolbarmenu_' tbtags{j}];
end

menulist = get(tmenu,'children');
menutags = get(menulist,'tag');
if ~isempty(menutags)
  %remove unneeded menu items
  if ~iscell(menutags); menutags = {menutags}; end
  to_remove = ~ismember(menutags,tbtags);
  if any(to_remove)
    delete(menulist(to_remove));
    menulist(to_remove) = [];
    menutags(to_remove) = [];
  end
else
  menutags = {};
end
%add missing menu items
to_add = ~ismember(tbtags,menutags);
if any(to_add)
  for j=find(to_add)'
    uimenu(tmenu,'label',get(tblist(j),'tooltip'),'callback',get(tblist(j),'ClickedCallback'),'separator',get(tblist(j),'separator'),'tag',tbtags{j});
  end
end
%update other items
to_update = ~to_add;
if any(to_update)
  for j=find(to_update)'
    set(menulist(ismember(menutags,tbtags{j})),'position',j,'label',get(tblist(j),'tooltip'),'callback',get(tblist(j),'ClickedCallback'),'separator',get(tblist(j),'separator'),'tag',tbtags{j});
  end
end

%enable/disable as needed
for j=1:length(tblist)
  mobj = findobj(tmenu,'tag',tbtags{j});
  if ~isempty(mobj)
    set(mobj,'enable',get(tblist(j),'enable'));
  end
end

%----------------------------------------------------------
function analysismenu(h, eventdata, handles, varargin)
%ANALYSISMENU Performs checking and setup of analysis menu.
%
%  INPUTS:
%        handles        = Handle of analysis figure.
%  OUTPUT:

%Current value.
curanalysis = getappdata(handles.analysis,'curanal');
set(allchild(handles.analysisalg),'Checked','off');
%Re-check current analysis
mymenu = findobj(handles.analysisalg,'Tag', curanalysis);
set(mymenu, 'Checked', 'On');

%visibility rules 
header = findobj(handles.analysisalg,'userdata','header');
flyout = findobj(handles.analysisalg,'userdata','flyout');
header_child = findobj(handles.analysisalg,'userdata','header_child');
flyout_child = findobj(handles.analysisalg,'userdata','flyout_child');

% set([header;header_child],'visible','on');
% set([flyout;flyout_child],'visible','off');
% return;

set(mymenu,'visible','on')
flyoutparent = get(mymenu,'parent');
if iscell(flyoutparent)
  for j=1:length(flyoutparent);
    if flyoutparent{j}~=handles.analysisalg
      flyoutparent = flyoutparent{j};
      break;
    end
  end
end
if ~isempty(flyoutparent) & ~iscell(flyoutparent)
  lastopened = getappdata(handles.analysisalg,'lastopened');
  lastselected = getappdata(handles.analysisalg,'lastselected');
  if isempty(lastopened) | isempty(lastselected) | (lastselected~=flyoutparent)
    setappdata(handles.analysisalg,'lastopened',lastselected);
    lastopened = lastselected;
  end
  setappdata(handles.analysisalg,'lastselected',flyoutparent);
  if ~isempty(lastopened)
    keepopen = getappdata(lastopened,'sibling');
    keepopen = [keepopen;getappdata(keepopen,'children')'];
  else
    keepopen = [];
  end
  
  %close most items first
  set([header_child;header;lastopened],'visible','off')
  set([flyout_child;setdiff(flyout,lastopened);keepopen],'visible','on');
  set(setdiff(flyout_child,mymenu),'checked','off')
  
  %now the selected one
  sibh = getappdata(flyoutparent,'sibling');
  if ~isempty(sibh);
    set(flyoutparent,'visible','off');
    set(sibh,'visible','on');
    children = getappdata(sibh,'children');
    set(children,'visible','on');
  end
end


%----------------------------------------------------------
function analysismenubuild(h, eventdata, handles, varargin)
%Build analysis menu for platform.

%Current value.
curanalysis = getappdata(handles.analysis,'curanal');

simplify = getappdata(handles.analysis,'simplify_analysis');
if isempty(simplify)
  simplify = strcmp(getfield(optionsgui('options'),'userlevel'),'novice');
  setappdata(handles.analysis,'simplify_analysis',simplify);  
end

if isempty(analysistypes('pca'))
  set(findobj(handles.analysisalg,'tag','pca'),'visible','off');
end

%Remove old menu items.
delete(allchild(handles.analysisalg));

%create new menu items for each analysis type
a_list = analysistypes;
shortcut_list = analysistypes_sym;
if ~isempty(shortcut_list)
  for j=1:size(shortcut_list,1);
    shortcut_list{j,3} = ['*' shortcut_list{j,3}];
  end
  a_list = [a_list;shortcut_list];
end
if size(a_list,2)>4
  [c_list, m] = unique(a_list(:,5));
  myorder = [a_list{m,end}];
  [junk,IX] = sort(myorder);
  c_list = c_list(IX)';
else
  %list doesn't have categories? use blank (will also use separator column
  %to determine how to split the list)
  c_list = {''};
  [a_list{1:end,5}] = deal('');
  [a_list{1:end,6}] = deal(1);
end

for c_item = c_list;
  idx = ismember(a_list(:,5),c_item);
  my_methods = a_list(idx,:);

  if simplify
    %reduce down to only ONE option
    my_methods = my_methods(1,:);
    if ~isempty(my_methods{1,5});
      %replace name with category
      my_methods{1,2} = [my_methods{1,5} ' (' my_methods{1,2} ')'];
    end
    ch = [];
    chs = [];
    usesep = false;
    if ismember(lower(c_item),{'multiway'});
      continue;  %skip this category for simplified menu
    end
  else
    %Standard menu options
    if ~isempty(c_item{:})
      %if there is a category, assign a header for it (unless old Matlab
      %which doesn't allow HTML in menus)
      if ~(ismac & (checkmlversion('>=','7.12') & checkmlversion('<=','8.2'))) %Mac 2011a can't have html menus, 13b and newer work. Some <13b may work but can't test them. 
        lblA = ['<html><font color="blue"><u>' upper(c_item{:}) '</u></font></html>'];
        lblB = ['<html><font color="blue">' upper(c_item{:}) '</font></html>'];
      else
        lblA = ['-- ' upper(c_item{:}) ' -- (help)'];
        lblB = upper(c_item{:});
      end
      sep = 'on';
      if strcmpi(c_item{:},c_list{1});  sep = 'off'; end  %no separator on first list item
      ch = uimenu(handles.analysisalg,'label',lblA,...
        'enable','on','separator',sep,'Callback',['analysis(''helplinks'',guidata(gcbf),''' c_item{:} ''')'],'tag',['help_' c_item{:}],...
        'userdata','header');
      chs = uimenu(handles.analysisalg,'label',lblB,...
        'enable','on','separator',sep,'tag',['subtype_' c_item{:}],'userdata','flyout');
      setappdata(chs,'sibling',ch);
      usesep = false;
    else
      %no category OR old Matlab version, skip header but note we should use
      %sep flag
      ch = [];
      chs = [];
      usesep = true;
    end
  end
  myhandles = [];
  for j = 1:size(my_methods,1)
    en = 'on';
    oldhandle = uimenu(handles.analysisalg);
    set(oldhandle(1),'userdata','header_child');
    if ~isempty(chs) & ~simplify
      oldhandle(2) = uimenu(chs);
      set(oldhandle(2),'userdata','flyout_child');
      set(ch,'visible','off');
      set(oldhandle(1),'visible','off');
    end
    if usesep
      sep = my_methods{j,4};
    else
      sep = 'off';
    end
    if my_methods{j,3}(1)~='*'
      callback = 'analysis(''enable_method'',gcbo,[],guidata(gcbf))';
    else
      callback = my_methods{j,3}(2:end);
    end
    set(oldhandle,...
      'label',my_methods{j,2},...
      'tag',my_methods{j,1},...
      'callback', callback, ...
      'checked','off',...
      'separator',sep,...
      'enable',en);
    myhandles(j) = oldhandle(1);
  end
  if ~isempty(ch)
    setappdata(ch,'children',myhandles)
  end
end

%add help menu item
oldhandle = findobj(handles.analysisalg,'tag','analysis_menu_help');
if isempty(oldhandle)
  oldhandle = uimenu(handles.analysisalg);
end
set(oldhandle,...
  'label','Analysis Methods Help',...
  'tag','analysis_menu_help',...
  'callback', 'helppls(''analysis_menu'')', ...
  'checked','off',...
  'enable','on',...
  'separator','on');

%add Simplify menu option
% oldhandle = findobj(handles.analysisalg,'tag','analysis_menu_simple');
% if isempty(oldhandle)
%   oldhandle = uimenu(handles.analysisalg);
% end
% if ~simplify
%   ch = 'off';
%   lbl = 'Simplify Menu';
% else
%   ch = 'off';
%   lbl = 'Full Menu';
% end
% set(oldhandle,...
%   'label',lbl,...
%   'tag','analysis_menu_simple',...
%   'callback', 'analysis(''simplify_Callback'',gcbo,[],guidata(gcbf));', ...
%   'checked',ch,...
%   'enable','on',...
%   'separator','off');


%Re-check current analysis
set(findobj(handles.analysisalg,'Tag', curanalysis), 'Checked', 'On');

%----------------------------------------------------------
function simplify_Callback(h,eventdata,handles,varargin)

simplify = getappdata(handles.analysis,'simplify_analysis');
if isempty(simplify)
  simplify = 0;
end
setappdata(handles.analysis,'simplify_analysis',~simplify);
analysismenubuild(h, eventdata, handles, varargin)

%----------------------------------------------------------
function helplinks(handles,topic)
%Open help for specific topic.

switch topic
  case {'Decomposition' 'Clustering'}
    helppls('analysis_menu.html#Exploratory_and_Cluster_Analysis_Methods')
  case 'Regression'
    helppls('analysis_menu.html#Quantitative_Analysis_Methods')
  case 'Classification'
    helppls('analysis_menu.html#Classification_Methods')
  otherwise
    helppls('analysis_menu.html')
end

%----------------------------------------------------------
function profile = varprofile(x)
%create a variable profile for testing validity for various methods

%default profile is "nothing"
profile.data = 0;         %is there any [non-excluded] data
profile.ndims = 0;        %number of dims in dataset
profile.class = 0;        %does dataset have classes
profile.type  = 'none';   %variable type (e.g. double, logical, etc)

%now, check for various relevent items
if ~isempty(x) & isa(x,'dataset');
  profile.data = ~isempty(x.includ{1}) & ~isempty(x.includ{2});
  profile.ndims = ndims(x);
  profile.class = ~isempty(x.class{1});;
  profile.type  = x.type;
end

%-------------------------------------------------------------
function adopt(handles,child,field)
%add a given child handle to a child list
% Some standards:
%  'staticchildplot' - generic plots which should be closed on exit of GUI
%  'modelspecific'   - model-specific plot which should be close on clear
%                       of model.
%  'methodspecific'  - method-specific plots should be closed when switch
%                      method.
if nargin<3;
  field = 'staticchildplot';
end
children = getappdata(handles.analysis,field);
children = union(children,child);
setappdata(handles.analysis,field,children);

%-------------------------------------------------------------
function   status = modelsaved(handles)

savedtimestamp = getappdata(handles.savemodel,'timestamp');
modl           = getobjdata('model',handles);
%Model check.
if ~isempty(modl) & ~isempty(modl.time) & (isempty(savedtimestamp) | any(modl.time ~= savedtimestamp));
  if exist('modelcache','file')
    %model cache exists - if it is being used, assume model is saved
    mcoptions = modelcache('options');
    status = strcmp(mcoptions.cache,'on');
  else
    status = 0;
  end
else
  status = 1;  %model has been saved or doesn't exist
end

%-------------------------------------------------------------
function out = curdatavalid(handles)

fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);

%Construct x block profile.
x = getobjdata('xblock',handles);
xprofile = varprofile(x);

%Construct y block profile.
y = [getobjdata('yblock',handles)];
yprofile = varprofile(y);

out = feval(fn,'isdatavalid',xprofile,yprofile,handles.analysis);

%-------------------------------------------------------------
function updatepreprocatalog(handles, silent)
%Update catalog and drop inappropriate preprocessing based on size of data.

%Except for mpca, if data is > 2D then only allow n-way pp methods in
%catalog and drop any current pp that is not n-way.
silent = 0;
if nargin == 1
  %If set to 1 then will silently drop inappropriate pp.
  silent = 0;
end

fn  = analysistypes(getappdata(handles.analysis,'curanal'),1);

ds = {getobjdata('xblock',handles)};
ds = [ds {getobjdata('yblock',handles)}];

dsdim = [];
for i = 1:length(ds)
  dsdim = [dsdim ndims(ds{i})];
end
ppfieldname = {'preprocessmain' 'preproyblkmain'};

if ~strcmpi(fn,'mpca')
  for i = 1:length(dsdim)
    if isempty(ds{i})
      continue
    end
    if dsdim(i)>2 & strcmpi(getfield(analysis('options'),'filternwayprepro'),'on')
      %hide invalid preprocessing items
      mycat  = getappdata(handles.analysis,'preprocesscatalog');
      %Add loop item to nway list
      newcat = preprocess('initcatalog');
      touse = [1 find(ismember({newcat.category},'Favorites'))];
      toallow = {'Abs'  'arithmetic'  'eemfilter'    'log10'   'msc'    'Normalize' 'msc_median' ...
        'Centering'    'Scaling'    'referencecorrection'    'trans2abs'  'whittaker'  'baseline' 'window_filter'};
      touse = union(touse,find(ismember({newcat.keyword},toallow)));
      newcat = newcat(touse);
      mycat{i} = newcat;
      setappdata(handles.analysis,'preprocesscatalog',mycat);

      %Check for invalid n-way pp
      curpp = getappdata(getfield(handles,ppfieldname{i}),'preprocessing');

      curcat = {newcat.description};
      newpp = [];
      for j = 1:length(curpp)
        if ismember(curpp(j).description, curcat)
          newpp = [newpp curpp(j)];
        end
      end

      if ~isequal(newpp, curpp) & ~silent
        setappdata(getfield(handles,ppfieldname{i}),'preprocessing',newpp)
        evritip('nwayprepro',['Certain types of preprocessing are not compatible '...
          'with n-way data and have been removed from the list of possible '...
          'preprocessing steps for the current data set.'],1); %once a day tip     
      elseif ~isequal(newpp, curpp) & silent
        %Started from command line, change pp silently.
        setappdata(getfield(handles,ppfieldname{i}),'preprocessing',newpp)
      end
    else
      %Set up normal catalog.
      mycat  = getappdata(handles.analysis,'preprocesscatalog');
      mycat{i} = preprocess('initcatalog');
      setappdata(handles.analysis,'preprocesscatalog',mycat)
    end
  end
else
  %Set up normal catalog.
  setappdata(handles.analysis,'preprocesscatalog',{preprocess('initcatalog') preprocess('initcatalog')})
end

%--------------------------------------------------------------
function resize_callback(h,eventdata,handles,varargin)
%varargin used by cacheviewer to indicate if it should look up old size of
%panel.
drawnow
if nargin > 3
  useold = varargin{1};
else
  useold = 0;
end
if nargin > 4
  %did one of the repositioning sliders get moved? which?
  reposition = varargin{2};
else
  reposition = '';
end

%Get options.
opts = analysis('options');

%get current figure size/position
set(handles.analysis,'units','pixels');
figpos = get(handles.analysis,'position');
orginalpos = figpos;

%Use table header as minimum width measure.
ext = get(handles.tableheader,'extent');
if ext(3)<503
  %Set minimum size, this keeps most panels in view and solves overlap
  %problems.
  ext(3) = 503;
end


%Need to know flowchat width to position modelcacheviewer.
pos = get(handles.flowchart,'position');

%Flowchart presumed size.
if strcmp(get(handles.flowchart,'visible'),'on');
  fcwidth = pos(3);
else
  fcwidth = 0;
end

switch char(reposition)
  case 'cache'
    %cache was resized - recalculate % to use for cache
    crpos = get(handles.cacheresizebtn,'position');
    w = (figpos(3)-crpos(1))./(figpos(3)-ext(3)-fcwidth);
    minw = 50/(figpos(3)-ext(3)-fcwidth);%limit narrowest by this many PIXELS
    w = max(minw,min(.98,w));
    setappdata(handles.analysis,'cachewidth',w)
  case 'help'
    crpos = get(handles.helpresizebtn,'position');
    setpos(handles.helpwindow,'height',min(300,crpos(2)-2))
end

%If modelviewer is visible adjust size.
if getappdata(handles.analysis,'showcacheviewer') & ~strcmp(getappdata(handles.analysis,'cacheview'),'hide')
  %Sizing should be relative. Width of cache viewer should expand at opts.cachewidth of
  %left over space.
  cvh = getappdata(handles.analysis,'treeparent');
  treecontainer = getappdata(handles.analysis,'treecontainer');
  
  %check figure for customized position
  mycachewidth = getappdata(handles.analysis,'cachewidth');
  if ~isempty(mycachewidth)
    opts.cachewidth = mycachewidth;
  end
  
  if useold
    oldpos = getappdata(handles.analysis,'lastcachefigposition');
    if ~isempty(oldpos)
      %Expand figure back out to max of old pos or min width.
      figpos(3) = max([(ext(3)+pos(3)+200) oldpos(3)]);
      set(handles.analysis,'Position',figpos);
    end
      
  end
  
  if ~isempty(cvh) & ishandle(cvh)
    %set(cvh,'Units','Pixels');
    mvpos = get(cvh,'PixelPosition');
    mvminwidth = 1; %Model cache viewer minimum width.

    %Cachviewer should get opts.cachewidth of minheader+minflowchart - figwidth.
    mv_leftover = figpos(3)-(ext(3)+fcwidth);
    mv_space = floor(opts.cachewidth*mv_leftover);
    figpos(3) = figpos(3)-mv_space;

    %Left
    mvpos(1) = round(figpos(3)+8);
    %Bottom
    mvpos(2) = 4;
    %Width.
    mvpos(3) = max(3,round(max([mvminwidth mv_space-9])));
    %Height
    mvpos(4) = max(3,round(figpos(4)-4));
    
    %Bug in Matlab doesn't move the container so have to move it manually.
    set(cvh,'units','normalized');  %make sure cvh is in normalized units before getting its position
    %Note: cache viewer is Java object so use 'PixelPosition'.
    %Note: put set 'PixelPosition' AFTER set 'units' (above). The set
    %'units' seems to be cuasing a bug that puts the container size back to
    %it's orginal size, not the new size.
    set(cvh,'PixelPosition',mvpos);
    set(treecontainer,'Units','Pixels','Position',mvpos)
    %Add close button.
    evritreefcn(handles.analysis,'addclose');
    
    %move resize button
    rbpos = [mvpos(1)-7 2 6 max(3,round(figpos(4)-4))];
    set(handles.cacheresizebtn,'visible','on','position',rbpos,'cdata',zeros(5,5,3),'backgroundcolor',[1 1 1])
    setappdata(handles.cacheresizebtn,'minsize',rbpos(3:4));
    moveobj('x',handles.cacheresizebtn);
    setappdata(handles.cacheresizebtn,'buttonupfcn','analysis(''resize_callback'',gcbf,[],guidata(gcbf),0,''cache'')')
    
  else
    set(handles.cacheresizebtn,'visible','off')
  end
else
  set(handles.cacheresizebtn,'visible','off')
end


%if flowchart is visible, adjust size
if strcmp(get(handles.flowchart,'visible'),'on');
  if figpos(3)-pos(3)>ext(3)
    %as long as controls are at least 1/2 of figure
    pos(1) = figpos(3)-pos(3)-2;  %move to right side of figure
    figpos(3) = pos(1)-2;   %adjust apparent figure width 
  else
    %otherwise, position at 1/2 width of frame
    pos(1) = ext(1)+ext(3)+4;
    figpos(3) = ext(1)+ext(3)+2;
  end
  if figpos(4)>pos(2)+2;
    pos(4) = figpos(4)-2; %stretch to top of figure
  end
  set(handles.flowchart,'position',pos);
  %   flowchart_callback(handles);
  %%% NOTE: above line is disabled because it gets called in
  %%% updatestatusboxes (which is ALWAYS called below)
end

%turn helpwindow on or off depending on appdata
disphelp = getappdata(handles.analysis,'displayhelp');
if disphelp
  set([handles.helpwindow handles.helpresizebtn],'visible','on')
else
  set([handles.helpwindow handles.helpresizebtn],'visible','off')
end

%set hieght for fixed-height objects
ext = get(handles.tableheader,'extent');
setpos(handles.tableheader,'height',20);
setpos(handles.pcseditlabel,'height',getpos(handles.pcsedit,'height'));

%set appropriate heights for objects
%Calculate remaining height after static objects and buffers are added.
height = figpos(4);
height = height - 2;  %subtract top buffer
height = height - 8; %top/bottom buffer for status boxes
height = height - 20; %Subtract height of panel display controls (and buffer).
height = height - 2;  %subtract between-frame buffer
height = height - getpos(handles.pcseditlabel,'height') - 2;    %subtract PCs edit text height and top/bottom buffer too
height = height - getpos(handles.tableheader,'height') - 2;    %- top/bottom buffer too
if disphelp
  height = height - getpos(handles.helpwindow,'height') - 9;    %- help window height and buffer
end
height = height - 2; %top/bottom buffer for ssqtable
height = height - 2;  %subtract bottom buffer

%distribute left-over to status and ssqtable boxes
% set([handles.modelstatus handles.datastatus],'units','pixels')
% modlext = get(handles.modelstatus,'extent');
% dataext = get(handles.datastatus,'extent');
% statusheight = min([height*.5 max([modlext(4) dataext(4)]+10)]);  %lesser of X% of height or tallest extent size
% statusheight = max([statusheight 89]);       %keep > min height
statusheight = 94;%Make status window/image fixed height.

%set status heights and dock to top
setpos(handles.modelstatus,'height',statusheight);
setpos(handles.datastatus,'height',statusheight);
setpos(handles.statusframe,'height',statusheight+4);
setpos(handles.modelstatus,'top',figpos(4)-4);
setpos(handles.datastatus,'top',figpos(4)-4);
setpos(handles.statusframe,'top',figpos(4)-2);

%Set status boxes visible off and show new status axis.
set([handles.datastatus handles.modelstatus handles.statusframe],'visible','off');
statush = findobj(allchild(handles.analysis),'tag','statusimage');
%left bottom width height]
%statpos = get(statush,'Position');

bp = getappdata(handles.analysis,'ButtonPanel');
buttonpaneloffset = 2;
if ~isempty(bp) & ishandle(bp.PanelContainer) & strcmp(get(bp.PanelContainer,'visible'),'on')
  buttonpaneloffset = 70;
  setpos(bp.PanelContainer,'left',3)
  setpos(bp.PanelContainer,'height',64)
  setpos(bp.PanelContainer,'top',figpos(4)-2)
  setpos(bp.PanelContainer,'width',figpos(3)-4)
  %Reposition handled scroll pane to fix problem of it not showing up. Use
  %.001 normalized position becuase looks a little better on windows.
  set(bp.ButtonPanelScrollPaneHandle,'position',[0.001 0.001 1 1])
end


%Set SSQ position.
ssqvis = getappdata(handles.analysis,'ssqonly_visible');
ssqonlyheight = 0;
if ssqvis
  %Add the height of table header and pc edit box since they are
  %not visible so SSQ table takes up all space in panel.
  ssqonlyheight = getpos(handles.pcsedit,'height')+getpos(handles.tableheader,'height');
end

ssqheight = max([height-statusheight-buttonpaneloffset+ssqonlyheight 1]);   %keep > min height
setpos(handles.ssqtable,'left',6);
setpos(handles.ssqtable,'height',ssqheight);

setpos(statush,'top',figpos(4)-buttonpaneloffset);
setpos(statush,'left',4);

%set middle-object positions
setpos(handles.helpwindow,'bottom',3);
if disphelp
  setpos(handles.ssqframe,'bottom',getpos(handles.helpwindow,'top')+9)  %extra input = STRETCH to top
else
  setpos(handles.ssqframe,'bottom',2)
end

setpos(handles.panelviewlabel,'top',getpos(statush,'bottom')-4)
setpos(handles.panelviewselect,'top',getpos(statush,'bottom')-3)
buttons = getappdata(handles.panelviewselect,'buttons');
if isfield(buttons,'handle');
  for h = [buttons.handle];
    if ishandle(h);
      setpos(h,'top',getpos(statush,'bottom')-3);
    end
  end
end

setpos(handles.ssqframe,'top',getpos(statush,'bottom')-22,1)% 2 buffer plus 20 for panel view controls.

%Other controls above ssq table (sometimes these are not visible).
setpos(handles.pcseditlabel,'top',getpos(handles.ssqframe,'top')-2)
setpos(handles.pcsedit,'top',getpos(handles.ssqframe,'top')-2)
setpos(handles.findcomp,'top',getpos(handles.ssqframe,'top')-2)
setpos(handles.tableheader,'top',getpos(handles.pcsedit,'bottom')-2)
if ssqvis
  setpos(handles.ssqtable,'top',getpos(handles.ssqframe,'top')-2)
else
  setpos(handles.ssqtable,'top',getpos(handles.tableheader,'bottom')-2)
end

%WIDTHS:
setpos(handles.statusframe,'width',figpos(3)-4);
setpos(handles.datastatus,'width',(figpos(3)-4)/2-4)
setpos(handles.modelstatus,'width',(figpos(3)-4)/2-4)
setpos(handles.modelstatus,'left',getpos(handles.datastatus,'right')+2)
setpos(handles.helpwindow,'width',figpos(3)-4);
setpos(statush,'width',figpos(3)-4);

ext = get(handles.pcseditlabel,'extent');
setpos(handles.pcseditlabel,'width',ext(3));
setpos(handles.pcsedit,'left',getpos(handles.pcseditlabel,'right')+2)
setpos(handles.findcomp,'left',getpos(handles.pcsedit,'right')+2)
ext = get(handles.tableheader,'extent');
width = max([ext(3) figpos(3)-10]);  %don't get smaller than extent of table header
setpos(handles.ssqframe,'width',width+6);
%setpos(handles.helpwindow,'width',width+6);%don't need to worry about disphelp adjust of width
setpos(handles.tableheader,'width',width);
setpos(handles.ssqtable,'width',width);

updatestatusimage(handles); %resize helpwindow text.


%Resize panel selector
setpos(handles.panelviewselect,'width',((figpos(3)-4)/2-4)-6)
buttons = getappdata(handles.panelviewselect,'buttons');
if ~isempty(buttons);
  spos  = get(handles.panelviewselect,'position');
  fpos  = get(handles.ssqframe,'position');
  lpos  = get(handles.panelviewlabel,'position');
  width = min(180,((fpos(3)-lpos(3))/length(buttons))-4);
  for j=1:length(buttons);
    setpos(buttons(j).handle,'width',width);
    setpos(buttons(j).handle,'left',spos(1)+(j-1)*(width+2))
  end
end

%Resize panel manager.
panelmanager('resize',handles.ssqframe)

%resize help resize control
rbpos = get(handles.helpwindow,'position');
rbpos = [rbpos(1) rbpos(2)+rbpos(4)+1 rbpos(3) 6];
set(handles.helpresizebtn,'position',rbpos,'cdata',zeros(5,5,3),'backgroundcolor',[1 1 1])
setappdata(handles.helpresizebtn,'minsize',rbpos(3:4));
moveobj('y',handles.helpresizebtn);
setappdata(handles.helpresizebtn,'buttonupfcn','analysis(''resize_callback'',gcbf,[],guidata(gcbf),0,''help'')')

%--------------------------------------------------------------
function ph = statusimage(handles)
%Construct composite image. These are the columns in image matrix.
persistent im
%see if we have images already loaded and, if not, load them now
if isempty(im)
  temp = load('statusimages','im');
  im   = temp.im;
end

%get status of all objects
pressed = false(1,7);
items = {'xblock' 'model' 'validation_xblock' 'prediction' 'yblock' 'validation_yblock'};
lookup = {'cal_x' 'model' 'val_x' 'pred' 'cal_y' 'val_y' 'clutter'};  %what field name in im.lookup matches the above items

for i = 1:length(items)
  if isloaded(items{i},handles)
    pressed(im.lookup.(lookup{i})) = true;
  end
end

%determine clutter status
pressed(im.lookup.clutter) = ~isempty(find_clutter(handles));

%Check to see if there the cv gui handle is valid. It will not be if
%analysis is closing (cv gui is already closed) so skip the settings call to avoid error.
cvh = getappdata(handles.analysis,'crossvalgui');
if ishandle(cvh) & cvguienabled(handles)
  cv= crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
else
  cv = 'none';
end
cv = ~strcmp(cv,'none');

no_y = ~isyused(handles);

%fields of im include:
%                  pressed: [97x501x3 uint8]
%               pressed_cv: [97x501x3 uint8]
%     pressed_cv_outofdate: [97x501x3 uint8]
%              pressed_noy: [97x501x3 uint8]
%        pressed_outofdate: [97x501x3 uint8]
%                unpressed: [97x501x3 uint8]
%             unpressed_cv: [97x501x3 uint8]
%            unpressed_noy: [97x501x3 uint8]
%
% SHOW IMAGES:
%   data = load('statusimages','im');
%   ff = fieldnames(data.im);
%   ff = ff(~ismember(ff,{'map' 'lookup'}));
%   f = figure;
%   for i = 1:length(ff)
%     subplot(4,5,i);
%     imagesc(data.im.(ff{i}));
%     title(ff{i});
%   end
%
% EXPORT IMAGES:
%   imwrite(data.im.unpressed_noy,'unpressed_noy.jpg')
%   imwrite(data.im.pressed_noy,'pressed_noy.jpg')
%
% ADD IMAGES:
%   A = imread('unpressed_noxy.jpg');
%   B = imread('pressed_noxy.jpg');
%   data = load('statusimages','im');
%   im = data.im;
%   im.unpressed_clsti = A;
%   im.pressed_clsti = B;
%   mystatusimage = which('statusimages.mat');
%   save(mystatusimage,im)

btnstyle = repmat({'unpressed'},1,length(pressed));
btnstyle(pressed) = deal({'pressed'});

%determine special model images
if pressed(im.lookup.model) & strcmp(getappdata(handles.analysis,'statmodl'),'calnew') 
  if ~cv
    btnstyle{im.lookup.model} = 'pressed_outofdate';
  else
    btnstyle{im.lookup.model} = 'pressed_cv_outofdate';
  end
else
  if cv
    %Display active crossval.
    if pressed(im.lookup.model)
      btnstyle{im.lookup.model} = 'pressed_cv';
    else
      btnstyle{im.lookup.model} = 'unpressed_cv';
    end
  end
end

%determine special prediction images
if (pressed(im.lookup.val_x) & ~pressed(im.lookup.pred) & pressed(im.lookup.model)) | (pressed(im.lookup.pred) & strcmp(getappdata(handles.analysis,'statmodl'),'calnew'))
  btnstyle{im.lookup.pred} = 'pressed_outofdate';
end

if no_y
  %Use image without y conection lines.
  if pressed(im.lookup.cal_y)
    btnstyle{im.lookup.cal_y} = 'pressed_noy';
  else
    btnstyle{im.lookup.cal_y} = 'unpressed_noy';
  end
  if pressed(im.lookup.val_y)
    btnstyle{im.lookup.val_y} = 'pressed_noy';
  else
    btnstyle{im.lookup.val_y} = 'unpressed_noy';
  end
end

%special modifications for certain model types
switch char(lower(getappdata(handles.analysis,'curanal')))
  case {'asca' 'mlsca'}
    if ismember(btnstyle{im.lookup.cal_x},{'pressed','unpressed'})
      btnstyle{im.lookup.cal_x} = [btnstyle{im.lookup.cal_x} '_asca'];
    end
    if ismember(btnstyle{im.lookup.cal_y},{'pressed','unpressed'})
      btnstyle{im.lookup.cal_y} = [btnstyle{im.lookup.cal_y} '_asca'];
    end
  
  case 'cls'
    if pressed(im.lookup.cal_y)
      addcls = '';
    else
      addcls = '_cls_pure';
    end
    if ismember(btnstyle{im.lookup.cal_x},{'pressed','unpressed'})
      btnstyle{im.lookup.cal_x} = [btnstyle{im.lookup.cal_x} addcls];
    end
    if ismember(btnstyle{im.lookup.cal_y},{'pressed','unpressed'})
      btnstyle{im.lookup.cal_y} = [btnstyle{im.lookup.cal_y} '_cls'];
    end    
    if ismember(btnstyle{im.lookup.val_y},{'pressed','unpressed'})
      btnstyle{im.lookup.val_y} = [btnstyle{im.lookup.val_y} '_cls'];
    end  
    
  case {'clsti' 'clsti_pred'}
    if ismember(btnstyle{im.lookup.cal_x},{'pressed','unpressed'})
      btnstyle{im.lookup.cal_x} = [btnstyle{im.lookup.cal_x} '_clsti'];
    end
    if ismember(btnstyle{im.lookup.cal_y},{'pressed','unpressed'})
      btnstyle{im.lookup.cal_y} = [btnstyle{im.lookup.cal_y} '_clsti'];
    end
    if ismember(btnstyle{im.lookup.val_y},{'pressed','unpressed'})
      btnstyle{im.lookup.val_y} = [btnstyle{im.lookup.val_y} '_clsti'];
    end
    if ismember(btnstyle{im.lookup.val_x},{'pressed','unpressed'})
      btnstyle{im.lookup.val_x} = [btnstyle{im.lookup.val_x} '_clsti'];
    end
        
end

%manage hiding of particular items
noclutter = strcmp(getfield(analysis('options'),'clutterbutton'),'hide');
if strcmpi(getappdata(handles.analysis,'curanal'),'clsti')
  noclutter = true;
end

nopred    = strcmp(getfield(analysis('options'),'predictionblock'),'hide');
if getappdata(handles.analysis,'noyprepro');
  noyprepro = true;
else
  noyprepro = false;
end

if ~isempty(getappdata(handles.analysis,'predictionblock')) & getappdata(handles.analysis,'predictionblock')
  %No pred being forced on (by ASCA). 
  nopred = 1;
end

%construct full image
composite = im.unpressed;
imsz = size(composite);
usz = [prod(imsz(1:2)) imsz(3)];
composite = reshape(composite,usz);  %unfold into 2-way
for j=1:length(pressed);  %add subsection of appropriate image
  myim = reshape(im.(btnstyle{j}),usz);
  if noclutter;
      %clutter turned off? hide it
    if j==im.lookup.clutter
      %hide for the clutter button itself
      myim(:,:) = repmat(myim(min(find(im.map{j})),:),size(myim,1),1);
    elseif j==im.lookup.cal_x & strcmp(btnstyle{j},'unpressed')
      %hide for the nub on the unpressed x-block "line"
      ind = [ 12627 12628 12629 12630 12631 12632 12633 12724 12725 12726 12727 12728 12729 12730 ...
        12724 12725 12726 12727 12728 12729 12730 12627 12628 12724 12725 12821 12822 12918 12919 13015 13016 13112 13113 13209 13210 13306 ...
        13307 13403 13404 13500 13501 13597 13598 13694 13695 13791 13792 13888 13889 13985 13986 14082 14083 14179 14180 14276 14277 ];
      myim(ind,:) = repmat(myim(12625,:),length(ind),1);
    end
  end
  if noyprepro & j==im.lookup.cal_y & strcmp(btnstyle{j},'pressed')
    %hide y preprocessing P if not permitted
    z = zeros(imsz(1:2));
    z(53:79,112:144) = 1;
    ind = find(z);
    blockim = reshape(im.unpressed,usz);
    myim(ind,:) = blockim(ind,:);
  end
  
  composite(im.map{j},:) = myim(im.map{j},:);
end
composite = reshape(composite,imsz);   %refold into 3-way

if nopred
  bg = squeeze(composite(5,5,:));
  for j=1:3;
    composite(:,250:end,j) = bg(j);
    composite(2:end-1,254:256,j) = 0;
    composite(2:4,250:253,j) = 0;
    composite(end-3:end-1,250:253,j) = 0;
    composite(44:48,242:249,j) = repmat(composite(49,242:249,j),5,1);
  end
  composite = composite(:,1:257,:);
end

%adjust width as necessary
pos = [ 10 10 size(composite,2) size(composite,1) ];
ph = findobj(allchild(handles.analysis),'tag','statusimage');
if isempty(ph)
  ph = axes('Parent',handles.analysis,'units','pixels','tag','statusimageaxes');
end

%Find axes pos so can use existing left and bottom.
apos = get(ph,'position');
pos(1:2) = apos(1:2);

%adjust image width to match width
delta = floor(apos(3)-pos(3));
if delta>0
  %   expat = [80 225 325 480];  %button faces only
  %   expat = [113 254 358];  %between buttons only
  %   expat = [80 113 145 225 254 325 358 375 480];
  %   expat = [80 113 225 254 325 358 375 480];
  if ~nopred
    expat = [11 95 113 225 246 254 325 358 370 476 488];
  else
    expat = [12 12 12 95 225 246 246 246];
  end

  if true;  %use expansion?
    nexppts   = length(expat);
    subdelta  = floor(delta/nexppts);
    fillers   = [repmat(expat,1,subdelta) repmat(expat(end),1,floor(mod(delta,nexppts)))];
    nind      = sort([1:size(composite,2) fillers]')';
    composite = composite(:,nind,:);
    pos(3)    = apos(3);
  else
    for j=1:length(expat);
      composite(:,expat(j),:) = 0;
    end
    nind = 1:size(composite,2);
  end
else
  nind = 1:size(composite,2);
end

%Fix for 6.5, imagesc will open a new figure if showhidden is off and not
%visible.
try
  if checkmlversion('<','7')
    set(0,'ShowHiddenHandles','on')
    set(handles.analysis,'CurrentAxes',ph,'visible','on')
  end
  h = imagesc(composite,'Parent',ph);
  set(0,'ShowHiddenHandles','off')
catch
  set(0,'ShowHiddenHandles','off')
  error(lasterr);
end
axis(ph,'image','off');
set(ph,'tag','statusimage','position',pos,'handlevisibility','off');
set(h,'buttondownfcn','analysis(''statusmenu'',gcbo,[],guidata(gcbf))');
setappdata(ph,'statusimagemap',nind);

mystatus = findobj(handles.analysis,'tag','statuscmenu');
set(mystatus,'callback',[])
set(h,'uicontextmenu',mystatus)

%--------------------------------------------------------------
function [btn_name, group] = status_location(axish)
%Itentify which icon the mouse cursor is on and return icon name, index,
%and position.

persistent im
%see if we have images already loaded and, if not, load them now
if isempty(im)
  temp = load('statusimages','im');
  im   = temp.im;
end
btn_name = '';
group = '';

%get location of pointer
pos = get(axish,'currentpoint');
if isempty(pos); return; end
pos = pos(1,1:2);
clickmap = getappdata(axish,'statusimagemap');
pos(1,1) = interp1(1:length(clickmap),clickmap,pos(1,1),'nearest');

pos = round(pos);
if pos(1,1)>0 & pos(1,1)<size(im.map{1},2) & pos(1,2)>0 & pos(1,2)<size(im.map{1},1)
  for j=1:length(im.map);
    pressed(j) = im.map{j}(pos(1,2),pos(1,1));
  end
  pressed = max(find(pressed));
else
  pressed = 0;
end

if pressed>0
  switch pressed
    case im.lookup.cal_x
      if pos(1)>111
        btn_name = 'x_prepro';
        group = 'preprocess';
      else
        btn_name = 'xblock';
        group = 'calibration';
      end
    case im.lookup.cal_y
      if pos(1)>111;
        btn_name = 'y_prepro';
        group = 'preprocess';
      else
        btn_name = 'yblock';
        group = 'calibration';
      end
    case im.lookup.model
      if pos(1)>227 & pos(2)<46 & pos(1)<255 & pos(2)>10
        btn_name = 'crossval';
        group = 'crossval';
      else
        btn_name = 'model';
        group = 'model';
      end
    case im.lookup.val_x
      btn_name = 'validation_xblock';
      group = 'validation';
    case im.lookup.val_y
      btn_name = 'validation_yblock';
      group = 'validation';
    case im.lookup.pred
      btn_name = 'prediction';
    case im.lookup.clutter;
      if ~strcmp(getfield(analysis('options'),'clutterbutton'),'hide')...
          || ~strcmpi(getappdata(axish.Parent,'curanal'),'clsti')
        btn_name = 'clutter';
      end
  end
end

%--------------------------------------------------------------
function ssqvisible(handles,visval)
%Make ssq table controls visible (on/off). Input 'visval' can be 'on' or 'off'.

ssqvis = getappdata(handles.analysis,'ssqonly_visible');
if ssqvis
  ssqvis = 'off';
else
  ssqvis = visval;
end

set(handles.pcseditlabel,'visible',ssqvis);
set(handles.pcsedit,'visible',ssqvis);
set(handles.tableheader,'visible',ssqvis);
set(handles.ssqtable,'visible',visval);

if getappdata(handles.analysis,'autoselect_visible')
  set(handles.findcomp,'visible',visval);
else
  set(handles.findcomp,'visible','off');
end

%--------------------------------------------------------------
function autoclear(handles)
%Warn user that their model is about to be cleared automaticlly do to their
%actions. Happens once per instance of Analysis.

%Check for model existing and autoclearwarn appdata.
modelstat = getappdata(handles.analysis, 'statmodel');
if isempty(modelstat)
  modelstat = 'none';
end

if ~strcmp(modelstat, 'none')
  evritip('automodelclear')
end

%- - - - - - - - - - - - - -
function setpos(h,dim,sz,stretch)

if nargin<4;
  stretch = 0;
end
set(h,'units','pixels');
uipos = get(h,'position');
switch dim
  case 'bottom'
    uipos(2) = sz;
    if stretch
      uipos(4) = uipos(4)+sz;
    end
  case 'top'
    if ~stretch
      uipos(2) = sz-uipos(4);
    else
      uipos(4) = sz-uipos(2);
    end
  case 'left'
    uipos(1) = sz;
    if stretch
      uipos(3) = uipos(3)+sz;
    end
  case 'right'
    if ~stretch
      uipos(1) = sz-uipos(3);
    else
      uipos(3) = sz-uipos(1);
    end

  case 'width'
    if ~stretch
      uipos(3) = sz;
    else
      uipos(1) = uipos(1)-sz;
    end
  case 'height'
    if ~stretch
      uipos(4) = sz;
    else
      uipos(2) = uipos(2)-sz;
    end
end
limit = (3:4);
uipos(limit(uipos(limit)<1)) = 1;
set(h,'position',uipos);

%- - - - - - - - - - - - - -
function sz = getpos(h,dim)
set(h,'units','pixels');
uipos = get(h,'position');
switch dim
  case 'bottom'
    sz = uipos(2);
  case 'top'
    sz = uipos(2)+uipos(4);
  case 'left'
    sz = uipos(1);
  case 'right'
    sz = uipos(1)+uipos(3);
  case 'width'
    sz = uipos(3);
  case 'height'
    sz = uipos(4);
end

% --------------------------------------------------------------------
function display_help_CreateFcn(hObject, eventdata, handles)
if ispc
  set(hObject,'BackgroundColor','white');
else
  set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
% --------------------------------------------------------------------

function str = message(handles)
%Returns string with message based on status of loaded objects.

usey = isyused(handles);
fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);

%Figure out stat data: 'none','new','cal','test'
isxloaded = isloaded('xblock',handles);
isyloaded = isloaded('yblock',handles);
if usey & isxloaded  & isyloaded
  isloaded_cal = true;
elseif isxloaded
  isloaded_cal = true;
else
  isloaded_cal = false;
end

isxloaded_val = isloaded('validation_xblock',handles);
isyloaded_val = isloaded('validation_yblock',handles);
if usey & isxloaded_val  & isyloaded_val
  isloaded_val = true;
elseif isxloaded_val
  isloaded_val = true;
else
  isloaded_val = false;
end

statmodl  = getappdata(handles.analysis,'statmodl'); %'none','calold','calnew','loaded'
isloaded_pred = isloaded('prediction',handles);

str = '';
if ~isloaded_cal & strcmp(statmodl,'none')
  str = ['Analysis Help Pane: Neither data nor a model is currently loaded. Data can be'...
    ' loaded or imported and/or a model can be loaded using the File menu.'];
elseif isloaded_cal & strcmp(statmodl,'none')
  if isempty(fn)
    str = ['Data has been loaded but no model exists. Select an analysis'...
      ' method to apply to the data (Analysis menu) or load a previous'...
      ' model (File menu). The data can be viewed and edited from the Edit menu.'];
  else
    str = ['Data has been loaded but no model exists. Set the preprocessing'...
      ' and other options (from the Preprocess and Tools menus) and'...
      ' calibrate a model (click on "Model" icon in the status pane). Data can be viewed'...
      ' and edited by clicking on the "X" and/or "Y" icons.'];
  end
  if strcmp(fn, 'knn_guifcn') & getappdata(handles.analysis, 'classGroupCreatedForKNN') 
    strNew = '**ATTENTION: X-block DataSet Object modified by addition of Class Set for KNN**';
    strsToJoin = {strNew, str}; 
    str = strjoin(strsToJoin, '\n');
  end
elseif strcmp(statmodl,'calnew')
  str = ['The modeling settings have changed and the model must be'...
    ' recalculated (click on "Model").'];
elseif ~isloaded_val
  if isloaded_cal
    str = ['A model has been calibrated from the data. Review the model'...
      ' using the toolbar button(s), save the model (File menu),'...
      ' or load test (validation) data (File menu). The number of'...
      ' components, preprocessing options,'...
      ' and other settings can also be modified to adjust the model.'...
      ' The data can be viewed and edited from the Edit menu.'];
    if strcmp(fn,'umap_guifcn')
      opts = getappdata(handles.analysis,'analysisoptions');
      if opts.n_components==1
        str = [str '**ATTENTION: Residual information for UMAP models built with 1 component are not calculated.**'];
      end
    end
  else
    str = ['A model has been loaded but no data is loaded. A test'...
      ' (validation) data set can now be loaded (File menu).'];
  end
elseif ~isloaded_pred
  str = ['A model and test (validation) data have been loaded.'...
    ' Apply the model to the test data using the Calibrate'...
    ' button.'];
elseif isloaded_pred
  if isloaded_cal
    str = ['The model had been calibrated from the calibration data and'...
      ' applied to the test (validation) data.'...
      ' Review the prediction results using the Toolbars buttons.'...
      ' The number of components, preprocessing options,'...
      ' and other settings can also be modified to adjust the model.'...
      ' The data can be viewed and edited from the Edit menu.'];
  else
    str = ['The model had been applied to the test (validation) data.'...
      ' Review the prediction results using the Toolbars buttons'...
      ' or save the predictions using the File menu.'];
  end
else
  str = ' Analsysis Help Pane: No assisstance can be offered at this time.';
end

% --------------------------------------------------------------------
function autoselect_Callback(h, eventdata, handles, varargin)

%Clear selected PCs.
setappdata(handles.pcsedit,'default',[]);
if strcmp(getappdata(handles.analysis,'curanal'),'mlsca')
  setappdata(handles.analysis,'mlsca_ncomp',[])
end

%Clear model.
clearmodel(h, eventdata, handles, 0);
%calcmodel Callback will use automated when called.
calcmodel_Callback(h, eventdata, handles, varargin);

% --------------------------------------------------------------------
function autoselect_update(handles)

%decide if anything should be done with the autoselect button
if isempty(getappdata(handles.pcsedit,'default'))
  %set color of autoselect button
  bgclr = getappdata(handles.findcomp,'stdcolor');
  if ~isempty(bgclr)
    set(handles.findcomp,'backgroundcolor',bgclr);
  end
  overridden = false;
else
  % number of pcs manually overridden? set color of autoselect button to show
  %we're not using it.
  bgclr = getappdata(handles.findcomp,'stdcolor');
  if isempty(bgclr)
    bgclr = get(handles.findcomp,'backgroundcolor');
    setappdata(handles.findcomp,'stdcolor',bgclr)
  end
  set(handles.findcomp,'backgroundcolor',bgclr.*[1 .8 .8]);
  overridden = true;
end

modlstat = getappdata(handles.analysis,'statmodl');
enb = 'off';
switch modlstat
  case 'calold'
    if isloaded('xblock',handles) & overridden
      enb = 'on';
    end
  case {'calnew' 'none'}
    if isloaded('xblock',handles) 
      enb = 'on';
    end
end
vis = getappdata(handles.analysis,'autoselect_visible');
panel = panelmanager('visible',handles.ssqframe);
if isempty(vis); vis = 0; end
if vis & isempty(panel);
  vis = 'on';
else
  vis = 'off';
end

set(handles.findcomp,'enable',enb,'visible',vis);

% --------------------------------------------------------------------
function [myid, myitem] = getobj(item,handles)
%Get current item, 'myid' is sourceID.

if ~isstruct(handles)
  handles = guidata(handles);
end

if isempty(item)
  %nothing passed? return empty
  myid = [];
  myitem = item;
  return;
end

switch item
  case {'dataset' 'xblock'}
    myitem = 'xblock';
  case {'datasetyblk' 'yblock'}
    myitem = 'yblock';
  case {'modl' 'model'}
    myitem = 'model';
  case {'rawmodl' 'rawmodel'}
    myitem = 'rawmodel';
  case {'test' 'pred' 'prediction'}
    myitem = 'prediction';
  case {'xblockprepro'}
    myitem = 'xblockprepro';
  case {'yblockprepro'}
    myitem = 'yblockprepro';
  case {'validation_xblock'}
    myitem = 'validation_xblock';
  case {'validation_yblock'}
    myitem = 'validation_yblock';
%   case {'x_valblockprepro'}
%     myitem = 'x_valblockprepro';
%   case {'y_valblockprepro'}
%     myitem = 'y_valblockprepro';
  otherwise
    myitem = item;
end
%Get a list of objects for given item type.
queryprops.itemType = myitem;
queryprops.itemIsCurrent = 1;
myid = searchshareddata(handles.analysis,'query',queryprops);

if length(myid)>1
  error(['There appears to be more than one current ' myitem ' registered to the analysis GUI.']);
elseif isempty(myid)
  myid = [];
elseif length(myid)>1
  myid = myid{1};
end

% --------------------------------------------------------------------
function out = isloaded(item,handles)
%Determine if item is currently loaded. If 'item' is a cell array of
%strings then out is a logical array.

if ~isstruct(handles)
  handles = guidata(handles);
end
out = [];
if iscell(item)
  for i = 1:length(item)
    out = [out ~isempty(getobjdata(item{i},handles))];
  end
else
  out = ~isempty(getobjdata(item,handles));
end
% --------------------------------------------------------------------
function out = isloadedset(itemset,handles)
%Determine if "set" is currently loaded. A set is the the "cal" or "val"
%data sets needed for the current analysis.

if ~isstruct(handles)
  handles = guidata(handles);
end

out = false;

usey = isyused(handles,nan);
if ~isfinite(usey); return; end
    
switch itemset
  case {'cal' 'calibration'}
    if isloaded('xblock',handles)
      if ~usey
        out = true;
      elseif isloaded('yblock',handles)
        out = true;
      end
    end
  case {'val' 'validation'}
    if isloaded('validation_xblock',handles)
      if ~usey
        out = true;
      elseif isloaded('validation_yblock',handles)
        out = true;
      end
    end
end

% --------------------------------------------------------------------
function out = getobjdata(item,handles)
%Get a data object. 
%  Inputs:
%    item       - is the type of object (e.g., "xblock" or "yblock").
%    handles    - handles structure or figure handle.

if ~isstruct(handles)
  handles = guidata(handles);
end

myid = getobj(item,handles);

out = getshareddata(myid);

% --------------------------------------------------------------------
function myid = setobjdata(item,handles,obj,myprops,userdata)
%Update or add a data object to the figure.
%  Inputs:
%    item    - is the type of object (e.g., "xblock" or "yblock").
%    handles - handles structure.
%    obj     - data object (e.g., DSO, model, or prediction).
%  OPTIONAL INPUTS:
%    myprops  - properties to set with the object
%    userdata - userdata to set with the link in analysis

%If adding for first time (i.e., there's no data for current "item" then
%set the currentitem flag for that item). NOTE: this functionality is not
%currently in use but should allow for multiple versions of the same "item"
%to be loaded at one time.
%
% Use the following properties to define behavior.
%   itemType      - How the item is assigned in the gui (e.g., "xblock" or
%                   "model", etc).
%   itemIsCurrent - (boolean) if there are multiple items of the same type loaded,
%                   which item is currently being used (has focus).
%   itemReadOnly  - (boolean) can the current item be modified.

if ~isstruct(handles)
  handles = guidata(handles);
end

if getappdata(handles.analysis,'apply_only')
  if ismember(lower(item),{'xblock' 'yblock'}) & ~isempty(obj)
    %load is disabled, exit now WITHOUT notice. It is assumed that the only
    %way we got here was that the user got around the menu and other
    %disabling code (or some other outside method tried to laod xblock or
    %yblock data)   
    return
  end
end

[myid, myitem] = getobj(item,handles);

%Not used yet but leaving place holder.
% fns = evriaddon('analysis_pre_setobjdata_callback');
% for j=1:length(fns)
%   feval(fns{j},handles.analysis,item,obj,myid);
% end

if nargin<4
  myprops = [];
end
if nargin<5;
  userdata = [];
end

if isempty(myid)
  if~isempty(obj)
    %Adding for the first time.
    myprops.itemType = myitem;
    myprops.itemIsCurrent = 1;
    myprops.itemReadOnly = 0;
    myid = setshareddata(handles.analysis,obj,myprops);
    linkshareddata(myid,'add',handles.analysis,'analysis',userdata);
  else
    %Don't add an empty data object.
  end
else
  if ~isempty(obj)
    %Update shareddata.
    if ~isempty(myprops)
      %update properties (quietly - without propogating callbacks)
      updatepropshareddata(myid,'update',myprops,'quiet')
    end
    setshareddata(myid,obj);
  else
    %Set to empty = clear shareddata.
    removeshareddata(myid,'standard');
  end
end

fns = evriaddon('analysis_post_setobjdata_callback');
for j=1:length(fns)
  %Used in multiblock. 
  feval(fns{j},handles.analysis,item,obj,myid);
end
%-----------------------------------------------
function [xout,yout,modlout] = getreconciledvalidation(handles)
%get the validation X and Y data with reconcilliation with the model
%variables, if needed

xout = []; yout = []; modlout = [];

modl = analysis('getobjdata','model',handles);

x = analysis('getobjdata','validation_xblock',handles);
y = analysis('getobjdata','validation_yblock',handles);

if ~isempty(y); y.includ{1}   = x.includ{1}; end      %copy samples includ from x-block

try
  if isempty(y)
    [cx,unmapx] = matchvars(modl,x);
    cy = [];
  else
    [cx,cy,unmapx,unmapy] = matchvars(modl,x,y);
  end
catch
  %errors during varible matching should be shown as a dialog then return
  %empty
  erdlgpls({'Error matching variables' lasterr},['Data Matching Error']);
  return
end
if ~all(x.moddate==cx.moddate) | (~isempty(y) & ~all(y.moddate==cy.moddate) )
  if ~isempty(unmapx) & all(isnan(unmapx))
    erdlgpls('The Validation X-block has no variables in common with the model','X Block Mismatch')
    return
  end
  if ~isempty(y) & ~isempty(unmapy) & all(isnan(unmapy))
    erdlgpls('The Validation Y-block has no variables in common with the model','Y Block Mismatch')
    return
  end
  resp = evriquestdlg('Variables in data and model do not match. Attempt variable alignment using axisscales and/or labels?','Variable mismatch','Auto-Align','Cancel','Auto-Align');
  if strcmp(resp,'Cancel')
    erdlgpls('Can not apply model to data','Variable Mismatch');
    return
  end
  %copy modified data over into x and y
  x = cx;
  y = cy;
  if (~isempty(unmapx) & any(isnan(unmapx))) | (~isempty(y) & ~isempty(unmapy) & any(isnan(unmapy)))
    resp = evriquestdlg({'WARNING: Some variables were not needed and will be discarded.','Overwrite original data with aligned data?'},'Varibles Discarded','OK','Cancel','OK');
  else
    %if we were expanding or just changing order, always save (easy to undo)
    resp = 'OK';
  end
  switch resp
    case 'Cancel'      
      return;
    case 'OK'
      setobjdata('validation_xblock',handles,x);
      if ~isempty(y)
        setobjdata('validation_yblock',handles,y);
      end
  end
end

xout = x; 
yout = y; 
modlout = modl;

%-----------------------------------------------
function updateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object. 
%The myobj variable comes in with the following structure.
%
%   id           - unique id of object.
%   object       - shared data (object).
%   properties   - structure of "properties" to associate with shared data.

if isempty(keyword); keyword = 'Modify'; end
% disp(sprintf('Analysis Update: %s %s',keyword,myobj.id.properties.itemType));

if ~isempty(keyword)
  keyword2 = [];
  if strcmp(keyword, 'class_create')
    keyword = 'class';
    keyword2 = 'create';
  elseif strcmp(keyword, 'axisset_modify')
    keyword = 'axisset';
    keyword2 = 'modify';
  elseif strcmp(keyword, 'axisset_create')
    keyword = 'axisset';
    keyword2 = 'create'; 
  end
end

if isshareddata(h)
  
  %connection link
  if strcmp(keyword,'delete') & isfield(userdata,'isdependent') & userdata.isdependent
    removeshareddata(h);
  end

elseif ishandle(h)

  %subscriber link
  cb = '';
  switch char(keyword)
  
    case {'class' 'include' 'axisscale' 'axisset'}

      if isfield(myobj.properties,[keyword 'changecallback'])
        cb = myobj.properties.([keyword 'changecallback']);
      end
      if isempty(cb) & isfield(myobj.properties,'datachangecallback')
        cb = myobj.properties.datachangecallback;
      end
      
    case 'delete'
      
    otherwise
      if isfield(myobj.properties,'datachangecallback')
        cb = myobj.properties.datachangecallback;
      end
      
  end
  if ~isempty(cb)
    try
      eval(cb);
    catch
      disp(encode(lasterror))
      erdlgpls(sprintf('Error executing callback for keyword ''%s'' on object ''%s''',keyword,myobj.properties.itemType),'Callback Error');
    end
  end

end

%-----------------------------------------------
function propupdateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object. 
%The myobj variable comes in with the following structure.
%
%   id       - unique id of object.
%   myobj    - shared data (object).
%   keyword  - keyword for what was updated (may be empty if nothing specified
%   userdata - additional data associated with the link by user

if nargin<4;
  userdata = [];
end

id = myobj.id;
if ~isempty(keyword)
  switch keyword
    case {'selection'}
      %Selection updated

      myobj.properties.selection = plotgui('validateselection',myobj.properties.selection,myobj.object);
      
      if ishandle(h)  %'subscriber'
        %call related to analysis' link to this object (subscriber)

        %In the future, we may put "callback" actions here
        
      else  %'connection'        
        %call related to linking to another object (connection)
        try
          last_timestamp = searchshareddata(h,'getval','timestamp');
        catch
          %any error in finding object, just skip it
          return
        end
        timestamp      = myobj.properties.timestamp;
        if last_timestamp~=timestamp
          %figure out what kind of selection mapping we need
          if ~isfield(userdata,'linkmap')
            if ~isstruct(userdata)
              userdata = [];
            end
            userdata.linkmap = ':';
          end
          newselection = myobj.properties.selection;
          if ~isnumeric(userdata.linkmap)
            %not numeric? pass entire selection as is
            myselection = newselection;
          else
            %matrix mapping mode to mode, pass only those modes
            % FORMAT: {1 2}  copies TO mode 1 FROM mode 2
            % FORMAT: {1 2; 2 1} ALSO copies FROM 2 TO 1!
            myselection = h.properties.selection;
            oldselection = myselection;
            %see if there is an offset between selection indices
            if isfield(userdata,'indexoffset') & ~isempty(userdata.indexoffset)
              %NOTE: In either case below, indexoffset is expected to be
              %equal in length to number of ROWS of linkmap (to allow for
              %multiple mode mapping
              for j=1:size(userdata.linkmap,1)
                if ~iscell(userdata.indexoffset)
                  %add offset as needed
                  temp = newselection{userdata.linkmap(j,2)}+userdata.indexoffset(j);
                  temp(temp<1) = [];
                else
                  %cell means indexoffset is a lookup vector, use selected
                  %samples to index into indexoffset to find corresponding
                  %samples in the linked-to block.
                  % e.g. if one block has a indexoffset of [2 4 6] then
                  % samples 1-3 would map to samples 2, 4, and 6 in the
                  % other block. The other block would have an indexoffset
                  % of [0 1 0 2 0 3]
                  temp = newselection{userdata.linkmap(j,2)};
                  temp(temp<1 | temp>length(userdata.indexoffset{j})) = []; %drop elements which will go outside vector limits
                  temp = userdata.indexoffset{j}(temp);
                  temp(temp<1) = [];  %any selected sample that maps to zero doesn't have a corresponding sample in the other block
                end
                newselection{userdata.linkmap(j,2)} = temp;
              end
            end              
            %copy selection over
            myselection(1,userdata.linkmap(:,1)) = newselection(userdata.linkmap(:,2));
            if comparevars(oldselection,myselection)
              %no change actually made? skip!
              return
            end
          end
          
          %create properties structure and update connection
          props = [];
          props.selection = myselection;
          props.timestamp = timestamp;
%           disp(sprintf('%s : %s ---> %s  COPIED',datestr(timestamp),myobj.id.properties.itemType,h.properties.itemType))
          updatepropshareddata(h,'update',props,'selection')
        end
      end
  end
end

% --------------------------------------------------------------------
function dataprops = getdataprops
%define data callback properties

dataprops = [];
dataprops.datachangecallback = 'datachangecallback(myobj.id)';
dataprops.includechangecallback = 'dataincludechange(myobj.id)';

% --------------------------------------------------------------------
function cacheview_closeFcn(h)
%Instructions for closing cache viewer (executed before deleting objects).

handles = guihandles(h);
setplspref('analysis','defaultcacheview','hide');
setappdata(handles.analysis,'cacheview','hide');

%Uncheck every menu item.
set([handles.viewbylineage handles.viewbydate handles.viewbytype],'Checked','Off')

%and force redraw
myT = getappdata(h,'treeparent');
if ~isempty(myT) & ishandle(myT)
  pos = get(handles.analysis,'position');%[L B W H]
  setappdata(handles.analysis,'lastcachefigposition',pos);
  fpos = get(myT,'PixelPosition');
  pos(3) = min([pos(3) ((pos(3)+2) - (pos(3)-fpos(1)))]);%(fpos(3)-((fpos(3)+fpos(1))-pos(3)));
  set(handles.analysis,'position',pos);
end
  
resize_callback(h,[],guihandles(h));

% --------------------------------------------------------------------
function loadcacheitem(h, eventdata, handles, varargin)
%Load item from menu in cache viewer.

t = getappdata(handles.analysis,'treeparent');
fcn = get(t,'GetSelectedCacheItem');

myitem = fcn(handles.analysis);

if ~iscell(myitem)
  myitem = {myitem};
end

if ~isempty(myitem{:})
  drop(handles.analysis, eventdata, handles, myitem{:});
end

% --------------------------------------------------------------------
function comparecacheitem(h, eventdata, handles, varargin)
%Load item from menu in cache viewer.

t = getappdata(handles.analysis,'treeparent');
fcn = get(t,'GetSelectedCacheItem');

myitem = fcn(handles.analysis);

if ~iscell(myitem)
  myitem = {myitem};
end

for idx = 1:length(myitem);
  modeloptimizer('snapshot',myitem{idx});
end
mofh = modeloptimizergui;
pause(.1)
if ~isempty(mofh) & ishandle(mofh)
  modeloptimizergui('update_callback',guihandles(mofh))
end

% --------------------------------------------------------------------
function renamecacheitem(h, eventdata, handles, varargin)
%Rename cache item.

t = getappdata(handles.analysis,'treeparent');
fcn = get(t,'RenameSelectedCacheItem');

fcn(handles.analysis);

% --------------------------------------------------------------------
function removecacheitem(h, eventdata, handles, varargin)
%Rename cache item.

t = getappdata(handles.analysis,'treeparent');
fcn = get(t,'RemoveSelectedCacheItem');

fcn(handles.analysis);

% --------------------------------------------------------------------
function importcacheitem(h, eventdata, handles, varargin)
%Rename cache item.

modelcache('importobj');

% --------------------------------------------------------------------
function exportcacheitem(h, eventdata, handles, varargin)
%Rename cache item.

t = getappdata(handles.analysis,'treeparent');
fcn = get(t,'GetSelectedCacheItem');

myitem = fcn(handles.analysis);
if iscell(myitem)
  myitem = myitem{1};
end
modelcache('exportobj',myitem);

% --------------------------------------------------------------------
function orthogonalizemodel_callback(h, eventdata, handles, varargin)
%Toggle othogonalize in pls options. Should not get here from any other
%method.

recalcmodel = isloaded('model',handles);
opts = getsafeoptions(h, eventdata, handles, varargin);
if strcmpi(opts.orthogonalize,'on')
  opts.orthogonalize = 'off';
  set(handles.orthogonalizemodel,'checked','off');
else
  opts.orthogonalize = 'on';
  set(handles.orthogonalizemodel,'checked','on');
end
curanal  = lower(char(getappdata(handles.analysis,'curanal')));
setopts(handles,curanal,opts);
clearmodel(handles.analysis, [], handles, []);
if recalcmodel
  calcmodel_Callback(handles.analysis, [], handles, []);
end

% --------------------------------------------------------------------
function showcacheitem(h, eventdata, handles, varargin)
%Open cache item in its native veiwer.

t = getappdata(handles.analysis,'treeparent');
fcn = get(t,'GetSelectedCacheItem');

myitem = fcn(handles.analysis);
myitem = myitem{:};

if ismodel(myitem)
  if isfield(myitem,'loads');
    info = [modlrder(myitem)';ssqtable(myitem,size(myitem.loads{2,1},2))'];
  else
    try
      info = modlrder(myitem)';
    catch
      return
    end
  end
  infofig = infobox(info,struct('openmode','reuse','figurename','Model Details'));
  infobox(infofig,'font','courier',10);
  adopt(handles,infofig)
elseif isa(myitem,'dataset')
  editds(myitem);
else
  %Assume test.
  try
    info = modlrder(myitem)';
    infofig = infobox(info,struct('openmode','reuse','figurename','Prediction Details'));
    infobox(infofig,'font','courier',10);
    adopt(handles,infofig)
  catch
    warning('EVRI:AnalysisCacheDisplay','Could not display selected cache item.')
  end

end

% --------------------------------------------------------------------
function saveascacheitem(h, eventdata, handles, varargin)
%Save cache item to workspace/file.

t = getappdata(handles.analysis,'treeparent');
fcn = get(t,'GetSelectedCacheItem');

myitem = fcn(handles.analysis);
myitem = myitem{:};

if ismodel(myitem)
  %Save model
  targname = defaultmodelname(myitem,'variable','save');
  [what,where] = svdlgpls(myitem,'Save Cache Model Item',targname);

elseif isa(myitem,'dataset')

  if ~isempty(myitem.name) & length(myitem.name)<63
    name = myitem.name;
  else
    name = 'data';
  end
  [what,where] = svdlgpls(myitem,'Save Cache Data Item',name);

else
  %Assume test.
  try
    if ~isempty(myitem.name) & length(myitem.name)<63
      name = [myitem.name '_test'];
    else
      name = 'test';
    end
    [what,where] = svdlgpls(myitem,'Save Cache Data Item',name);
  catch
    warning('EVRI:AnalysisCacheSave','Could not save selected cache item.')
  end
end


% --------------------------------------------------------------------
function opennewcacheitem(h, eventdata, handles, varargin)

newh = analysis;
newhandles = guihandles(newh);

t = getappdata(handles.analysis,'treeparent');
fcn = get(t,'GetSelectedCacheItem');

myitem = fcn(handles.analysis);
if ~isempty(myitem{:})
  drop(newh, eventdata, newhandles, myitem{:});
end

% --------------------------------------------------------------------
function cachemenu_callback(h, eventdata, handles, varargin)
%Menu functionality for Cache Viewer sub menus. This controls
%adding/hiding/changeing cache views.

%Check to see if cache viewing is enabled.
if getappdata(handles.analysis,'showcacheviewer')

  %Get current view setting. If not changing via menu selection then use what's
  %current.
  curview = getappdata(handles.analysis,'cacheview');

  %Use tag of calling object (below) to determine what to change to.
  mytag = get(h,'tag');

  %%Delete existing object so we can rebuild new (selected) object.
  %%evritreefcn(handles.analysis,'hide');

  set([handles.viewbylineage handles.viewbydate handles.viewbytype],'Checked','Off');

  %Flag for startup.
  strt = 0;

  if strcmp(mytag,'analysis')
    %Must be startup.
    mytag = curview;
    strt = 1;
  end

  if isempty(mytag)
    mytag = 'hide';
  end

  addcache = 0;
  
  %Give default position at right side of figure so looks better when starting,
  %figure MUST be visible for java objects to get built.
  figpos = get(handles.analysis,'position');
  
  if isempty(getappdata(handles.analysis,'treeparent'))
    opts.position = [max(figpos(3)-200,1) 4 200 max(3,round(figpos(4)-4));];
  else
    %Use existing position
    opts = [];
  end

  switch mytag
    case {'hidecacheviewer' 'closecacheviewer' 'hide'}
      %Only enabled if tree is showing so hide it.
      evritreefcn(handles.analysis,'hide');
      addcache = 0;
      myview = 'hide';
      if ~strt
        %Don't show tip on startup, otherwise show once.
        evritip('closecache');
      end
    case {'viewbylineage' 'lineage'}
      treeh = evritreefcn(handles.analysis,'show','lineage',opts);
      set(handles.viewbylineage,'Checked','On');
      addcache = 1;
      myview = 'lineage';
    case {'viewbydate' 'date'}
      treeh = evritreefcn(handles.analysis,'show','date',opts);
      set(handles.viewbydate,'Checked','On');
      addcache = 1;
      myview = 'date';
    case {'viewbytype' 'type'}
      treeh = evritreefcn(handles.analysis,'show','type',opts);
      set(handles.viewbytype,'Checked','On');
      addcache = 1;
      myview = 'type';
    case {'opencachesettings'}
      %Change settings then rebuild tree.
      modelcache('settings');
      drawnow;
      myview = curview;
      if ~strcmp(myview,'hide')
        treeh = evritreefcn(handles.analysis,'show',curview);
        set(handles.(['viewby' myview]),'Checked','On');
        addcache = 1;
      else
        addcache = 0;
      end
    case {'opencachehelp'}
      evrihelp('model_cache')
      return
    case {'importtocache'}
      modelcache('importobj')
      return
  end

  %     if addcache
  %       %If adding cache make sure figure is at least a minimum width.
  %       figpos = get(handles.analysis,'position');
  %       if figpos(3)<320
  %         figpos(3)=320;
  %         set(handles.analysis,'position',figpos)
  %       end
  %     end

  %Set view before call to resize becuase resize checks for current
  %"view".
  setappdata(handles.analysis,'cacheview',myview);
  resize_callback(handles.analysis,[],handles,1);

  %Save last view chosen so can be recalled when opening window.
  setplspref('analysis','defaultcacheview',myview);

  if addcache
    %If adding cache, make sure first n pixels viewer are visible.
    cvh = getappdata(handles.analysis,'treeparent');
    treecontainer = getappdata(handles.analysis,'treecontainer');

    cvpos = get(cvh,'PixelPosition');

    mincachewidth = 150;
    if figpos(3)<cvpos(1)+mincachewidth
      figpos(3) = cvpos(1)+mincachewidth;
      set(handles.analysis,'position',figpos);
    end
  end

else
  set(handles.cacheview,'enable','off');
end

%-----------------------------------------------
function statusmenu(h,eventdata,handles)
%Display left click content menu for status image.

axh = findobj(allchild(handles.analysis),'tag','statusimage');
btn_name = status_location(axh);
use_y = isyused(handles,true);
statmodl = getappdata(handles.analysis,'statmodl');
stype = get(handles.analysis,'SelectionType');

apply_only = getappdata(handles.analysis,'apply_only');
if apply_only & ismember(lower(btn_name),{'xblock' 'yblock'})
  return; 
end  
if getappdata(handles.analysis,'noyprepro');
  noyprepro = true;
else
  noyprepro = false;
end


if strcmpi(stype,'normal')
  %convert certain normal clicks into open clicks (under certain conditions)
  switch lower(btn_name)
    case {'model' 'prediction'}
      if ~isloaded(btn_name,handles) | strcmp(statmodl,'calnew')
        stype = 'open';
      end
    case {'xblock' 'yblock' 'validation_xblock' 'validation_yblock'}
      if ~isloaded(btn_name,handles)
        stype = 'open';
      end
    case {'crossval'}
      stype = 'open'; %always
    case { 'x_prepro' 'y_prepro' }
      if strcmpi(getfield(analysis('options'),'quickopenprepro'),'on')
        stype = 'open'; %if option is on
      end
    case 'clutter'
      stype = 'open'; %always
  end
  pause(0.2);
end

%check for accidental duplicate open command
last = getappdata(handles.analysis,'laststatusopen');
if ~isempty(last) & (now-last)<1/60/60/24   %less than some time between "opens"
  return
end
setappdata(handles.analysis,'laststatusopen',now)


if strcmpi(stype,'open')
  %handle double-click action
  
  %determine how to handle this open call
  switch btn_name
    case {'model' 'prediction'}
      if (isloaded('xblock',handles) & ~isloaded('model',handles)) | (isloaded('model',handles) & isloaded('validation_xblock',handles) & ~isloaded('prediction',handles)) | strcmp(statmodl,'calnew')
        calcmodel_Callback(h, eventdata, handles, [])
      elseif isloaded(btn_name,handles)
        printinfo(h, [], handles, btn_name)
      else
        switch btn_name
          case 'model'
            loadmodel(h, [], handles)
          case 'prediction'
            loadtest(h, [], handles)
        end
      end
    case 'crossval'
      if ~cvguienabled(handles)
        return;  %don't show when cv disabled
      end
      set(getappdata(handles.analysis,'crossvalgui'),'Visible','on')
      figure(getappdata(handles.analysis,'crossvalgui')); 
    case 'x_prepro'
      if isloaded('xblock',handles)
        preprocesscustom(handles.analysis, [], handles,'x')
      end
    case 'y_prepro'
      if use_y & isloaded('yblock',handles) & ~noyprepro
        preprocesscustom(handles.analysis, [], handles,'y')
      end
    case 'clutter'
      if ~strcmpi(getappdata(handles.analysis,'curanal'),'clsti')
        clutter_callback(h, eventdata, handles, 'settings')
      end
      
    case {'xblock' 'yblock' 'validation_xblock' 'validation_yblock'}
      if ~isloaded(btn_name,handles)
        %Open import.
        fileimport(h,eventdata,handles,btn_name)
      else
        %Open editor.
        editblock(h, eventdata, handles, btn_name)
      end
      
  end
  setappdata(handles.analysis,'laststatusopen',now)
else
  if strcmp(btn_name,'y_prepro') & (~use_y | noyprepro)
    return;
  end
  statuscmenu_Callback(handles.analysis,[],handles);
end

%Toggle infobox.
infoh = infoboxhandle(handles.analysis);
if ~isempty(infoh)  %Delete box.
  delete(infoh);
end

%-----------------------------------------------
function statusinfoboxenable(h,eventdata,handles,varargin)
%Disable/enable status infobox.
curibox = getappdata(handles.analysis,'displaystatusinfobox');

if curibox
  setappdata(handles.analysis,'displaystatusinfobox',0);
else
  setappdata(handles.analysis,'displaystatusinfobox',1);
end

%-----------------------------------------------
function statuscmenu_Callback(h,eventdata,handles,varargin)
%Display right-click context menu.
statusmenu = findobj(handles.analysis,'tag','statuscmenu');
axh = findobj(allchild(handles.analysis),'tag','statusimage');
btn_name = status_location(axh);

chld = allchild(statusmenu);
set(chld,'visible','off')
bname = '';
blockid = '';
apply_only = getappdata(handles.analysis,'apply_only');

switch btn_name
  case 'xblock'
    bname = 'Calibration';
    key = 'data';
    blockid = 'x';
    if apply_only; return; end   %do NOT show this menu when apply-only mode
  case 'yblock'
    bname = 'Calibration';
    key = 'data';
    blockid = 'y';
    if apply_only; return; end   %do NOT show this menu when apply-only mode
  case 'validation_xblock'
    bname = 'Validation';
    key = 'data';
    blockid = 'x';
  case 'validation_yblock'
    bname = 'Validation';
    key = 'data';
    blockid = 'y';
  case 'x_prepro'
    bname = 'Calibration';
    key = 'pp';
    blockid = 'x';
  case 'y_prepro'
    bname = 'Calibration';
    key = 'pp';
    blockid = 'y';
  case 'model'
    key = 'model';
    set([handles.status_report_writer allchild(handles.status_report_writer)'],'visible','on');
  case 'crossval'
    key = 'cv';
    if apply_only; return; end   %do NOT show this menu when apply-only mode
    if ~cvguienabled(handles)
      return  %don't show when cv disabled too
    end
  case 'prediction'
    key = 'pred';
  case 'clutter'
    key = 'clutter';
  otherwise
    %Can't find a button.
    return
end

%Enalbel status menu items based on key name "status_".
for i = 1:length(chld)
  if ~isempty(strfind(get(chld(i),'tag'),['status_' key]))
    set(chld(i),'Visible','On')
  end
end

if ~isempty(bname) & ~isempty(ismember(key,{'data' 'pp'}))
  %Label val/cal at top of context menu flyout.
  if checkmlversion('>=','7')
    ht1 = '<html><font color="blue"><b>';
    ht2 = '</b></font></html>';
  else
    ht1 = '';
    ht2 = '';
  end
  %NOTE: Turn this display on if block labeling is wanted.
  set([handles.status_name],'Label',[ht1 upper(blockid) '-Block' ht2],'Enable','Off','Visible','Off');
  statuscmenuenable(key,bname,handles,blockid);
end

if strcmp(key,'model') | strcmp(key,'pred') | strcmp(key,'clutter')
  statuscmenuenable(key,bname,handles,blockid);
end

if strcmp(key,'pp')
  %Change callback on pp for particular block.
  set(handles.status_ppnone,'Callback',['analysis(''preprocessnone'',gcbo,[],guidata(gcbo),''' blockid ''')' ]);
  set(handles.status_ppmean,'Callback',['analysis(''preprocessmean'',gcbo,[],guidata(gcbo),''' blockid ''')' ]);
  set(handles.status_ppauto,'Callback',['analysis(''preprocessauto'',gcbo,[],guidata(gcbo),''' blockid ''')' ]);
  set(handles.status_ppcustom,'Callback',['analysis(''preprocesscustom'',gcbo,[],guidata(gcbo),''' blockid ''')' ]);
  set(handles.status_pp_load,'Callback',['analysis(''loadpreprocessing'',gcbo,[],guidata(gcbo),''' blockid ''')' ]);
  set(handles.status_pp_save,'Callback',['analysis(''savepreprocessing'',gcbo,[],guidata(gcbo),''' blockid ''')' ]);
  set(handles.status_pp_viewppdata,'Callback',['analysis(''viewprepro'',gcbo,[],guidata(gcbo),''' blockid ''')' ]);
  set(handles.status_pp_saveppdata,'Callback',['analysis(''savedata_callback'',gcbo,[],guidata(gcbo),''' [blockid 'pp'] ''')' ]);
  set(handles.status_setppdefault,'Callback',['analysis(''preprocesssetdefault'',gcbo,[],guidata(gcbo),''' blockid ''')' ]);
  set(handles.status_pp_quickopen,'Callback','analysis(''preproquickopen'',gcbo,[],guidata(gcbo))');
end

if ~strcmp(get(handles.analysis,'selectiontype'),'alt') | ismac
  %If not right-click manually set pos and visible.
  %Need to manually set position and visible on mac because of Java
  %rendering bug not rendering import flyout menu (as well as others).
  set(statusmenu,'position',get(handles.analysis,'currentpoint'))
  set(statusmenu,'visible','on');
end

infoh = infoboxhandle(handles.analysis);
if ~isempty(infoh)
  delete(infoh);
end

%-----------------------------------------------
function statuscmenuenable(key,group,handles,blockid)
%Enable valid menu item handles for what's curretly loaded.
% Input 'key' is the group being set to visible (e.g., data model or pred).

%NOTE: This code has been through several iterations and may need
%refactoring in the future.

cura = getappdata(handles.analysis,'curanal');

%Gather loaded info once for convenience.
isxl = isloaded('xblock',handles);
isyl = isloaded('yblock',handles);
isvxl = isloaded('validation_xblock',handles);
isvyl = isloaded('validation_yblock',handles);
isml = isloaded('model',handles);
ispl = isloaded('prediction',handles);
use_y = isyused(handles,true);
if strcmpi(cura, 'clsti')
  doingCLSTI = true;
else
  doingCLSTI = false;
end

switch key
  case 'data'
    switch lower(group)
      case 'calibration'
        if strcmp(blockid,'x')
          blk = 'xblock';
        elseif strcmp(blockid,'y')
          blk = 'yblock';
        elseif ~isempty(blockid)
          error('Unrecognized block selected in status menu.')
        end
      case 'validation'
        if strcmp(blockid,'x')
          blk = 'validation_xblock';
        elseif strcmp(blockid,'y')
          blk = 'validation_yblock';
        elseif ~isempty(blockid)
          error('Unrecognized block selected in status menu.')
        end
    end
    
    if strcmp(blk,'none') | (strcmp(blk,'xblock') & doingCLSTI) |(strcmp(blk,'yblock') & doingCLSTI)
      set(allchild(handles.statuscmenu),'visible','off')
      return
    end
    
    enbl = 'On';
    if ~isloaded(blk,handles)
      enbl = 'Off';
    end
    
    %Update enable and callbacks for each data menu item.
    %     hlist  = [handles.status_data_load  handles.status_data_edit  ...
    %               handles.status_data_plot  handles.status_data_clear ...
    %               handles.status_data_save  handles.status_data_makeyblock ...
    %               handles.status_data_transform    handles.status_data_new];
    
    hlist  = [handles.status_data_load  handles.status_data_edit  ...
      handles.status_data_plot  handles.status_data_clear ...
      handles.status_data_save  ...
      handles.status_data_transform    handles.status_data_new];
    %cblist = {'loaddata_callback' 'editblock' 'plotblock' 'cleardata_callback' 'savedata_callback' 'makexcolumnyblock' 'transformdata' 'newdata'};
    cblist = {'loaddata_callback' 'editblock' 'plotblock' 'cleardata_callback' 'savedata_callback' 'transformdata' 'newdata'};

    for i = 1:length(hlist)
      set(hlist(i),'Enable',enbl,'Callback',['analysis(''' cblist{i} ''',gcbo,[],guidata(gcbo),''' blk ''')'])
    end
    
    if strcmp(blk, 'xblock')
      blk_forMakeYfromX = 'x';
    elseif strcmp(blk, 'validation_xblock')
      blk_forMakeYfromX = 'x_val';
    else
      blk_forMakeYfromX = '';
    end
    set(handles.status_data_makeyblock, 'Enable', enbl);
    set(handles.statusmenu_yfromxcolumns, 'callback', ['analysis(''makexcolumnyblock'',gcbf,[],guidata(gcbf),''' blk_forMakeYfromX ''',''cols'');']);
    set(handles.statusmenu_yfromxaxisscale, 'callback', ['analysis(''makexcolumnyblock'',gcbf,[],guidata(gcbf),''' blk_forMakeYfromX ''',''axis'');']);
    
    %Always allow loading of data.
    set([handles.status_data_load handles.status_data_new],'Enable','On')
    
    %Set editycols.
    if strcmp(blk,'yblock')
      set(handles.status_data_editselectycols, 'visible','on')
      if isyl
        set(handles.status_data_editselectycols, 'enable','on')
      else
        set(handles.status_data_editselectycols, 'enable','off')
      end
    else
      set(handles.status_data_editselectycols, 'visible','off')
    end
    
    %manage select cal/val menu
    if isxl | isvxl
      enb = 'on';
    else
      enb = 'off';
    end
    set(handles.status_data_calval,'enable',enb);

    %add import options
    delete(allchild(handles.status_data_import));
    set(handles.status_data_import,'callback','');
    editds_addimportmenu(handles.status_data_import,['analysis(''fileimport'',gcbf,[],guidata(gcbf),''' blk ''',get(gcbo,''userdata''));']);
    
    %Update list of transform options
    delete(allchild(handles.status_data_transform));
    set(handles.status_data_transform,'callback','');
    sh = get(handles.status_data_transform,'userdata');
    for j=1:length(sh);
      uimenu(handles.status_data_transform,...
        'label',sh(j).name,...
        'tag',['transform_' sh(j).fn],...
        'userdata',sh(j),...
        'callback',['analysis(''transformdata'',gcbf,[],guidata(gcbf),''' blk ''',get(gcbo,''userdata''));']);
    end 
    
    
    set(handles.status_data_augmentval, 'enable', 'off');
    %Augment val to cal.
    if (isxl & isyl & isvxl & isvyl) | ...
        (isxl & ~isyl & isvxl & ~isvyl) | ...
        (~isxl & isyl & ~isvxl & isvyl)
      %All loaded.
      set(handles.status_data_augmentval, 'enable', 'on');
      if strcmpi(group,'validation')
        set(handles.status_data_augmentval,'label','Augment onto Calibration');
      else
        set(handles.status_data_augmentval,'label','Augment with Validation');
      end
    end
    %Code for shortcut to reset included field
    if isloaded(blk,handles)
      resetInclude_build(gcbo,[],guidata(gcbo), blk , 'status_reset_include');
    end
 
  case 'model'
    mymodlist = [handles.status_model_showdetails handles.status_model_save ...
      handles.status_model_export handles.status_model_clear handles.exportmodelbuilder ...
      handles.status_exportregvec handles.status_model_rebuild handles.status_calculateshapleymodel];
    if isml
      set(mymodlist,'Enable','On');
      curModel = getobjdata('model', handles);
      curXPP   = curModel.detail.options.preprocessing{1};
      if ~ismember(cura,{'pls','pcr','mlr'})
        set(handles.status_exportregvec, 'enable', 'off')
      elseif length(curXPP) > 1
        set(handles.status_exportregvec, 'enable', 'off')
      else
        if isequal(length(curXPP), 1) && isempty(regexpi(curXPP.keyword, '(mean center|autoscale)'))
          set(handles.status_exportregvec, 'enable', 'off')
        end
      end
      %Export model to types...
      set(handles.status_savemodelas,'label','To &File','callback','');
      mylist = savemodelas;
      delete(allchild(handles.status_savemodelas));%status_savemodelas
      for j=1:length(mylist);
        mh = uimenu(handles.status_savemodelas,'label',mylist{j,1},...
          'callback',['analysis(''savemodelasCallback'',gcbo,[],guidata(gcbf),get(gcbo,''userdata''))']);
        set(mh,'userdata',j);
      end
      
      if strcmpi(cura,'parafac')
        %Add export to openfluor since it's a special case.
        mh = uimenu(handles.status_savemodelas,'label','OPENFLUOR TXT-file (*.txt)',...
          'callback',['analysis(''exportmodel_openfluor'',gcbo,[],guidata(gcbf),get(gcbo,''userdata''))']);
        set(mh,'userdata',j+1);
      end
      
    else
      set(mymodlist,'Enable','Off');
    end
    
    %Disable testrobust if no model, x/y.
    to = testrobustness('options');
    if ismember(cura,to.validmodeltypes)
      if ~isml
        en = 'off';
      else
        if isvxl & isvyl
          en = 'on';
        elseif isxl & isyl
          en = 'on';
        else
          en = 'off';
        end
      end
    else
      en = 'off';
    end
    set(handles.status_model_testrobust,'Enable',en)
    
    if isxl && isml
      set(handles.status_calculateshapleymodel,'visible','on','enable','on');
    else
      set(handles.status_calculateshapleymodel,'visible','on','enable','off');
    end
    
    set(allchild(handles.status_report_writer),'enable','on');
    if ~ispc
      set([handles.status_report_word handles.status_report_powerpoint],'enable','off');
    end
    
    %Set Orthogonalize model.
    set(handles.status_model_orthogonalizemodel,'visible','off','checked','off');
    if ismember(lower(cura),{'pls' 'plsda'})
      opts = getsafeoptions(handles.analysis, [], handles, []);
      if strcmpi(opts.orthogonalize,'on')
        set(handles.status_model_orthogonalizemodel,'checked','on');
      end
      set(handles.status_model_orthogonalizemodel,'visible','on');
    end
    
  case 'pred'
    if ispl
      set([handles.status_pred_showdetails handles.status_pred_save handles.status_pred_clear],'Enable','On');
    else
      set([handles.status_pred_showdetails handles.status_pred_save handles.status_pred_clear],'Enable','Off');
    end
    %%% The following code is disabled so that we can give an error message
    %%% explaining that the model must be loaded first
    %     if isloaded('model',handles)
    %       en = 'on';
    %     else
    %       en = 'off';
    %     end
    %     set(handles.status_pred_load,'Enable',en)
  case 'pp'
    set(get(handles.status_pp_preprocessing, 'children'), 'checked','off','enable','on');
    %set([handles.status_ppnone handles.status_ppmean handles.status_ppauto handles.status_ppcustom handles.status_setppdefault],'visible','on','checked','off','enable','on');
    switch blockid
      case 'x'
        data = getobjdata('xblock',handles);
        pp = getappdata(handles.preprocessmain,'preprocessing');
      case 'y'
        data = getobjdata('yblock',handles);
        pp = getappdata(handles.preproyblkmain,'preprocessing');
        if ~use_y | getappdata(handles.analysis,'noyprepro');
          %not allowed to do y-block preprocessing? hide preprocessing context menu
          set(get(handles.statuscmenu,'children'),'visible','off');
          return;
        end
    end
    if isempty(data)
      %no data? hide preprocessing context menu
      set(get(handles.statuscmenu,'children'),'visible','off');
      return;
    end
    set(handles.status_setppdefault,'visible','on');
    
    if strcmpi(getfield(analysis('options'),'quickopenprepro'),'on')
      ch = 'on';
    else
      ch = 'off';
    end
    set(handles.status_pp_quickopen,'visible','on','checked',ch);
    
    if isempty(pp)
      set(handles.status_ppnone,'checked','on');
      set([handles.status_pp_saveppdata handles.status_pp_save],'enable','off')
    else
      set([handles.status_pp_saveppdata handles.status_pp_save],'enable','on')
      if length(pp)==1
        switch lower(pp.description)
          case 'mean center'
            set(handles.status_ppmean,'checked','on');
          case 'autoscale'
            set(handles.status_ppauto,'checked','on');
          otherwise
            %none...
        end
      end
    end

    %If current analysis is MPCA or empty then allow normall PP for 2+ dims
    %otherwise disable. Parafac can only use n-way PP, MPCA will work with
    %standard PP becuase data is unfolded.
    
    if ~strcmp(cura,'mpca') & ndims(data)>2
      set(handles.status_ppnone,'enable','on');
      set(handles.status_ppmean,'enable','off');
      set(handles.status_ppauto,'enable','off');
      set(handles.status_ppcustom,'enable','on');
    end
    
  case 'clutter'
    %enable some if loaded
    if isempty(find_clutter(handles)) || strcmpi(cura,'clsti')
      en = 'off';
    else
      en = 'on';
    end
    set([handles.status_clutter_save handles.status_clutter_clear],'enable',en);
    
    %disable some if n-way
    if isxl & ndims(getobjdata('xblock',handles))>2 || strcmpi(cura,'clsti')
      en = 'off';
    else
      en = 'on';
    end
    set([handles.status_clutter_settings handles.status_clutter_load handles.status_clutter_import],'enable',en);
    
    %add import methods
    delete(allchild(handles.status_clutter_import));
    set(handles.status_clutter_import,'callback','');
    editds_addimportmenu(handles.status_clutter_import,['analysis(''clutter_callback'',gcbf,[],guidata(gcbf),''import'',get(gcbo,''userdata''));']);
    
end

%any add-on functions want strict editing
fns = evriaddon('analysis_status_contextmenu_callback');
for j=1:length(fns)
  feval(fns{j},handles.analysis,key);
end

% --------------------------------------------------------------------
function windowbuttonmotion_Callback(obj,event)
%Show status icon infobox when mouseover. This code should be put into sub
%function if more functionality is added to WBM callback.

persistent last_mouse_pos

switch ismac
  case false
    %non-MAC, always call sub function
    le = lasterror;
    try
      windowbuttonmotion_Callback_sub(obj,event);
    catch
      lasterror(le);
    end
    
  case true
    if isempty(last_mouse_pos)
      last_mouse_pos = get(0,'PointerLocation');
    end
    newpos = get(0,'PointerLocation');
    
    if ~all(last_mouse_pos==newpos) | isstruct(event)
      %User has not moved mouse so don't need to update anything. This
      %helps stop recursive calls in 13b+ on Mac where every drawnow
      %triggers windowbuttonmotion. If isstruct(event) then callback being
      %called by timer so we do need to run motion callback. Note that on
      %14b+ event is not empty.
      le = lasterror;
      try
        windowbuttonmotion_Callback_sub(obj,event);
      catch
        lasterror(le);
      end
    end
    last_mouse_pos = newpos;
end


% --------------------------------------------------------------------
function windowbuttonmotion_Callback_sub(obj,event)
%Show status icon infobox when mouseover. This code should be put into sub
%function if more functionality is added to WBM callback.

if isa(obj,'timer')
  obj = obj.userdata;
end
handles = guidata(obj);

delete_bad_axes(handles.analysis)
curibox = getappdata(handles.analysis,'displaystatusinfobox');
if ~curibox
  %Infobox is turned off.
  return
end

cp         = get(obj,'CurrentPoint');
axh        = handles.statusimage;
btn_name   = status_location(axh);
infoh      = infoboxhandle(handles.analysis);
apply_only = getappdata(handles.analysis,'apply_only');

no_y = ~isyused(handles);

if length(infoh)>1
  %There is more than one infobox around. This will cause errors so delete
  %them all so next call will start over.
  delete(infoh);
  return
end

if isempty(btn_name)
  %reset pointer to whatever is appropriate right now
  savedpointer = getappdata(handles.analysis,'savedpointer');
  if ~isempty(savedpointer)
    set(handles.analysis,'pointer',savedpointer);
  end
  if isempty(infoh)
    return
  else
    %There's an info box displayed, delete it if the mouse is not over it
    %or the correct icon. Icon name stored in userdata.
    myicon = get(infoh,'userdata');
    if strcmp(myicon,btn_name)
      %Mouse is over the correct icon.
      return
    else
      delete(infoh);
    end
  end
end

%see about changing the pointer to the hand (to show this is "active")
savedpointer = getappdata(handles.analysis,'savedpointer');
if isempty(savedpointer)
  savedpointer = get(handles.analysis,'pointer');
  if ~strcmp(savedpointer,'hand') & checkmlversion('>=','7.2')
    set(handles.analysis,'pointer','hand');
  end
end

%check for dwell in the same place
if isempty(infoh) & isempty(event)  %no info box yet?
  mytimer = getappdata(axh,'movetimer');
  if isempty(mytimer) | ~isvalid(mytimer)
    mytimer = timerfind('tag','movetimer');
    if isempty(mytimer) | ~isvalid(mytimer)
      mytimer = timer;
    end
  end
  if ~strcmp(mytimer.Running,'off')
    stop(mytimer);
  end
  mytimer.StartDelay = .3;
  mytimer.TimerFcn = @windowbuttonmotion_Callback;
  mytimer.userdata = handles.analysis;
  mytimer.tag = 'movetimer';
  start(mytimer);
  setappdata(axh,'movetimer',mytimer);
  return;
end

if checkmlversion('>=','7')
  ht1 = '<html><font color="blue"><b>';
  ht2 = '</b></font></html>';
else
  ht1 = '';
  ht2 = '';
end

statuspos = get(axh,'position');
modl = [];
dat = [];
pp = [];
cv = [];
cdat = [];
info = '';
switch btn_name
  case 'model'
    bname = 'Model';
    leftpos = 150;
    modl = getobjdata('model',handles);
    if isempty(modl)
      if isloaded('xblock',handles);
        info = [ht1 'Click to calculate model' ht2];
      else
        info = [ht1 'Click to load model' ht2];
      end
    end
  case 'prediction'
    bname = 'Prediction';
    leftpos = 392;
    modl = getobjdata('prediction',handles);
    if isempty(modl)
      if isloaded('validation_xblock',handles) & isloaded('xblock',handles);
        if isloaded('model',handles);
          info = [ht1 'Click to apply model' ht2];
        else
          info = [ht1 'Click to calculate model' ht2];
        end
      end
    end
  case 'xblock'
    bname = 'Calibration X-Block';
    leftpos = 20;
    dat = getobjdata('xblock',handles);
    if isempty(dat)
      info = [ht1 'Click to import calibration X-block data' ht2];
    end
    if apply_only
      if checkmlversion('>=','7')
        ht1 = '<html><font color="red"><b>';
      end
      info = [ht1 '* Apply-only mode: cannot load calibration data' ht2];
    end
  case 'yblock'
    bname = 'Calibration Y-Block';
    leftpos = 20;
    dat = getobjdata('yblock',handles);
    if isempty(dat)
      info = [ht1 'Click to import calibration Y-block data' ht2];
    end
    if apply_only
      if checkmlversion('>=','7')
        ht1 = '<html><font color="red"><b>';
      end
      info = [ht1 '* Apply-only mode: cannot load calibration data' ht2];
    end
  case 'validation_xblock'
    bname = 'Validation X-Block';
    leftpos = 260;
    dat = getobjdata('validation_xblock',handles);
    if isempty(dat)
      info = [ht1 'Click to import validation X-block data' ht2];
    end
  case 'validation_yblock'
    bname = 'Validation Y-Block';
    leftpos = 260;
    dat = getobjdata('validation_yblock',handles);
    if isempty(dat)
      info = [ht1 'Click to import validation Y-block data' ht2];
    end
  case 'x_prepro'
    bname = 'Calibration X-Block';
    leftpos = 120;
    pp = getappdata(handles.preprocessmain,'preprocessing');
    if ~isloaded('xblock',handles)
      %Make empty so won't show pp if there's no data.
      pp = [];
    elseif isempty(pp)
      %pp may come back as empty struct so use subscript to avoid error.
      pp(1).description = 'None';
    end
  case 'y_prepro'
    if getappdata(handles.analysis,'noyprepro');
      %not allowed to edit... don't show
      pp = [];
    else
      %show yprepro
      bname = 'Calibration Y-Block';
      leftpos = 120;
      pp = getappdata(handles.preproyblkmain,'preprocessing');
      if ~isloaded('yblock',handles) | no_y
        %Make empty so won't show pp if there's no data.
        pp = [];
      elseif isempty(pp)
        %pp may come back as empty struct so use subscript to avoid error.
        pp(1).description = 'None';
      end
    end
  case 'clutter'
    if ~strcmpi(getappdata(handles.analysis,'curanal'),'clsti')
      bname = 'Clutter';
      leftpos = 150;
      cpos = find_clutter(handles);
      if isempty(cpos)
        info = [ht1 'Click to enable clutter filtering' ht2];
      else
        cdat = getappdata(handles.preprocessmain,'preprocessing');
        cdat = cdat(cpos);
        info = [ht1 'Click to edit declutter settings' ht2];
      end
    end
    
  case 'crossval'
    bname = 'Cross-Validation Settings';
    leftpos = 235;
    [cv.cv,cv.lv,cv.split,cv.iter,cv.cvi] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
    if ~cvguienabled(handles)
      cv = [];  %don't show when cv disabled
    end
  otherwise
    if ~isempty(infoh) & ishandle(infoh)
      delete(infoh)
      return
    end
end

if ~isempty(dat)
  %Data infobox string.
  names   = dat.name;
  handles.datasource = {getdatasource(dat) []};
  datsize = sprintf('%i x ',handles.datasource{1}.size(1:end-1));
  datsize = [datsize sprintf('%i',handles.datasource{1}.size(end))];
  if strcmp(dat.type,'image')
    sizedata = size(dat);
    im = dat.imagemode;
    if im > 1
      sizedata = [sizedata(1:im - 1) dat.imagesize sizedata(im+1:end)];
    else
      sizedata = [dat.imagesize sizedata(2:end)];
    end
    datsize = sprintf('%i x ',sizedata(1:end-1));
    datsize = [datsize sprintf('%i',sizedata(end))];
  end
  included = sprintf('%i x ',handles.datasource{1}.include_size(1:end-1));
  included = [included sprintf('%i',handles.datasource{1}.include_size(end))];
  
  info = {[ht1 '' bname ' (double-click to edit)' ht2], ...
    ['       Name: ',names], ...
    ['       Size: ', datsize], ...
    ['   Included: ', included], ...
    ['  Samp Lbls: ',dat.labelname{1}], ...
    ['   Var Lbls: ', dat.labelname{2}]};
end

if ~isempty(modl)
  %Model infobox string.
  try
    info = modlrder(modl)';
  catch
    return
  end
  %Replace empty first line with label.
  info{1} = [ht1 bname ' Information (double-click to spawn)' ht2];
end

if ~isempty(pp)
  %Preprocessing info box string.
  info = {[ht1 'Preprocessing: ' bname ' (click to edit)' ht2]};
  for i = 1:length(pp)
    info = [info, {['  ' pp(i).description]}];
  end
  %info{end} = [info{end} ht3];
end

if ~isempty(cdat)
  info = [info, {['  ' cdat.description]}];
end

if ~isempty(cv)
  if isnumeric(cv.cv)
    cv.cv = 'Custom';
  end
  add = {};
  switch cv.cv
    case 'none';
      cv.cv = 'None';
    case 'loo';
      cv.cv = 'Leave One Out';
    case 'con'
      cv.cv = 'Contiguous Blocks';
      add = { ['  LV/PCs:  ', num2str(cv.lv)], ...
        ['  Splits:  ',num2str(cv.split)]};
    case 'vet'
      cv.cv = 'Venetian Blinds';
      add = { ['  LV/PCs:  ', num2str(cv.lv)], ...
        ['  Splits:  ',num2str(cv.split)]};
    case 'rnd'
      cv.cv = 'Random';
      add = { ['  LV/PCs:  ', num2str(cv.lv)], ...
        ['  Splits:  ',num2str(cv.split)], ...
        ['  Iterations:  ', num2str(cv.iter)]};
  end
  
  try
    [issues,splitinfo] = reviewcrossval(handles.analysis);
    splitinfo = regexprep(['  ' splitinfo],':','::');
    splitinfo = regexprep(splitinfo,'[:,]\s',[10 '    ']);
    splitinfo = str2cell(splitinfo);
    add = [add splitinfo(:)'];
  catch
    %do NOT throw error, but don't hide it from unit testing
  end
  info = {[ht1 bname ht2], ...
    ['  CV Method:  ',cv.cv], ...
    add{:}};
end

if ~isempty(info)
  if ~iscell(info)
    info = {info};
  end
  len = max(cellfun('length',info(2:end)));
  if ~isempty(len) & len>50 & ~isempty(strtrim(info{end}))
    %add blank line at bottom to pad for slider if longest line is likely
    %to push us over the max characters
    info{end+1} = ' ';
  end
  figpos = get(handles.analysis,'position');
  leftpos = max(3,min(figpos(3)-400,leftpos));
  newpos = [leftpos statuspos(2)-200 400 200];
  if isempty(infoh)
    set(0,'currentfigure',obj);
    set(obj,'handlevisibility','on');
    oldinfoh = infoboxhandle(handles.analysis);
    if ~isempty(oldinfoh)
      delete(oldinfoh);
    end
    infoh = uicontrol('style','listbox','tag','status_infobox','backgroundcolor',[1 1 1],'userdata',btn_name,'Max',2,'Min',0,'FontName','Courier');
    infoboxhandle(handles.analysis,infoh);
    set(obj,'handlevisibility','callback');
  end
  set(infoh,'position',newpos,'string',info);
  ext = get(infoh,'extent');
  pos = get(infoh,'position');
  newheight = ext(4);
  delta = pos(4)-newheight;
  set(infoh,'position',[pos(1) pos(2)+delta pos(3) newheight]);
  set(infoh,'value',[]);
else
  if ~isempty(infoh) & ishandle(infoh)
    delete(infoh)
    return
  end
end

%-----------------------------------------------
function infoh  = infoboxhandle(h,infoh)

if nargin>1
  if ~isempty(infoh) & ~ishandle(infoh);
    infoh = [];
  end
  setappdata(h,'status_infobox_handle',infoh);
  clear infoh
else
  %GET value
  infoh      = getappdata(h,'status_infobox_handle');
  if ~isempty(infoh) & ~ishandle(infoh);
    infoh = [];
    setappdata(h,'status_infobox_handle',[]);
  end
end

%-----------------------------------------------
function hidestatusinfobox
%hide info box if this is a callback to any item on the analysis window

obj = gcbo;
if ~isempty(strfind(class(obj),'javahandle'))
  %TODO: find a way to locate parent figure from javahandle
  obj = gcbf;
elseif ishandle(obj) & isprop(obj,'type')
  %locate parent figure
  while ~strcmp(get(obj,'type'),'figure') & ~isempty(obj)
    try
      obj = get(obj,'parent');
    catch
      obj = [];
    end
  end
else
  return;
end

%if it is an analysis figure, look for infobox handle and delete it
if ~isempty(obj) & strcmp(get(obj,'tag'),'analysis')
  infoh = infoboxhandle(obj);
  if ~isempty(infoh)
    delete(infoh);
  end
  delete_bad_axes(obj);
end

%-----------------------------------------------
%returns true if the current method uses the y-block, and false if it
%does not. If no method is currently selected, returns (default) which
%itself defaults to false
function usey = isyused(handles,default)

if nargin<2
  default = false;
end

fn  = analysistypes(getappdata(handles.analysis,'curanal'),3);
if ~isempty(fn)
  usey = feval(fn,'isyused',handles);  %boolean for wether valid method for y block
else
  usey = default;
end


%-----------------------------------------------
function out = findpg(myid,handles,ftype)
%Find plotgui figure handle for given ID. 
%Input: 
%   myid    - shared data id OR name of item.
%   handles - handles structure.
%   ftype   - which figure type to search for, 'plotgui' or 'editds' or
%             '*' (for either)

out = [];
if nargin<3
  ftype = 'plotgui';
end

if ischar(myid)
  if nargin<2;
    error('Find PlotGUI must be given handles if myid is an itemType');
  end
  myid = getobj(myid,handles);
end
  
if ~isempty(myid)
  mysubs = linkshareddata(myid,'find');
  mysubs(~ishandle(mysubs)) = [];
  if ~ishandle(mysubs)
    return
  end
  mysubs = findobj(mysubs,'type','figure');
  for i = 1:length(mysubs)
    ispg = isappdata(mysubs(i),'figuretype') & strcmpi(getappdata(mysubs(i),'figuretype'),'plotgui');
    isdse = strcmpi(get(mysubs(i),'tag'),'editds');
    switch ftype
      case 'plotgui'
        if ispg
          out = [out mysubs(i)];
        end
      case 'editds'
        if isdse
          out = [out mysubs(i)];
        end
      otherwise
        if ispg | isdse
          out = [out mysubs(i)];
        end
    end
  end
end

%--------------------------
function savestatus

h = findobj(allchild(0),'tag','analysis');

if isempty(h)
  error('No Analysis GUIs could be found');
end

toremove = {'GUIDEOptions' 'Listeners' 'UsedByGUIData_m'};
status = {};
for j=1:length(h);
  info = getappdata(h(j));
  for f = toremove
    info.(f{:}) = '** CLEARED **';
  end 
  status{j} = info;
end

[file,pth] = uiputfile('analysis_status.mat');
if ~isnumeric(file)
  save(fullfile(pth,file),'status')
end

%--------------------------
%Simple function used through a timer to keep updating the "opening" waitbar
function t = updatewaitbar(obj,event)

if nargin==1
  %call with single input is initialization and obj is handle of waitbar
  needed = { '@timer\private\deleteAsync' ; '@timer\private\getSettableValues' ;    '@timer\private\isJavaTimer' ; 'allchild' ;    'analysis' ; 'analysistypes' ; 'auto' ; 'autoset' ;
    'axis' ; 'baseline' ; 'baselineset' ; 'besttime' ;    'cachestruct' ; 'cell.ismember' ; 'cell.setdiff' ;    'cell.sort' ; 'cell.strcat' ; 'cell.strmatch' ;
    'cell.unique' ; 'cellstr' ; 'cla' ; 'close' ;    'closereq' ; 'colormap' ; 'crossvalgui' ;    'datacursormode' ; 'datenum' ; 'datestr' ;
    'deal' ; 'dec2hex' ; 'detrendset' ; 'double.superiorfloat' ;    'evriaddon.addon_pls_toolbox' ; 'evriaddon.evriaddon' ;    'evriaddon.products' ; 'evriaddon.subsref' ;
    'evriaddon_connection.evriaddon_connection' ;    'evriaddon_connection.subsasgn' ; 'evriaddon_connection.subsref' ;    'evriio' ; 'evritip' ; 'evritreefcn' ; 'explode' ;
    'figbrowser' ; 'figureToolbarCreateFcn' ;    'fileparts' ; 'filesep' ; 'findall' ; 'fliplr' ;    'flowchart_callback' ; 'fullfile' ; 'gca' ;
    'gcbf' ; 'gcbo' ; 'gcf' ; 'genvarname' ;    'getfield' ; 'checkmlversion' ; 'getpixelposition' ;    'getplspref' ; 'getpref' ; 'getshareddata' ;
    'gettbicons' ; 'getuimode' ; 'glsw' ; 'graphics.datacursormanager.addlistener' ;    'graphics.datacursormanager.datacursormanager' ;    'graphics.datacursormanager.deserializeDatatips' ;
    'graphics.datacursormanager.schema' ; 'graphics\private\clo' ;    'gscaleset' ; 'guidata' ; 'guihandles' ;    'hasuimode' ; 'hgload' ; 'imagesc' ; 'initprintexporttemplate' ;
    'int2str' ; 'interp1' ; 'intmax' ; 'isactiveuimode' ;    'iscellstr' ; 'isfieldcheck' ; 'ishold' ;    'iskeyword' ; 'ismember' ; 'ismethod' ; 'ispc' ;
    'isprop' ; 'isunix' ; 'javachk' ; 'javacomponent' ;    'lineseries' ; 'linspace' ; 'log10' ; 'logdecayset' ;    'makesubops' ; 'medcnset' ; 'mncnset' ; 'modelcache' ;
    'movegui' ; 'mscorrset' ; 'newplot' ; 'normset' ;    'now' ; 'npreprocenterset' ; 'npreproscaleset' ;    'num2str' ; 'objbounds' ; 'opaque.char' ;
    'opaque.double' ; 'opaque.toChar' ; 'openfig' ;    'oscset' ; 'panelmanager' ; 'plotedit' ;    'positionmanager' ; 'preprocatalog' ; 'preprocess' ;
    'preprouser' ; 'reconopts' ; 'repmat' ; 'rotate3d' ;    'savgolset' ; 'searchshareddata' ; 'setdiff' ;    'setfield' ; 'setpixelposition' ; 'setplspref' ;
    'setpref' ; 'snv' ; 'snvset' ; 'sortrows' ;    'str2double' ; 'str2num' ; 'strjust' ; 'strmatch' ;    'strtok' ; 'tempdir' ; 'textwrap' ; 'timefun\private\formatdate' ;
    'timer.get' ; 'timer.isvalid' ; 'timer.length' ;    'timer.set' ; 'timer.start' ; 'timer.stop' ;    'timer.subsasgn' ; 'timer.subsref' ; 'timer.timer' ;
    'timer.timercb' ; 'timercb' ; 'timerfind' ;    'toolbar' ; 'toolbar_buttonsets' ; 'uigetmodemanager' ;    'uimode' ; 'uitools.uimode.createuimode' ;
    'uitools.uimode.schema' ; 'uitools.uimode.setCallbackFcn' ;    'uitools.uimodemanager.getMode' ; 'uitools.uimodemanager.registerMode' ;
    'uitools.uimodemanager.uimodemanager' ; 'uitools\private\addlistener' ;    'uitools\private\prefutils' ; 'uitools\private\uitree_deprecated' ;
    'uitools\private\uitreenode_deprecated' ;    'uitools\private\usev0dialog' ; 'uitree' ;    'uitreenode' ; 'union' ; 'unique' ; 'usejava' ;
    'usejavacomponent' ; 'waitbar' ; 'wlsbaseline' ;   'wlsbaselineset' ; 'zoom';
    '@etable\private\getcolumnlabels' ; '@etable\private\getcustomcellrenderer' ;
    '@etable\private\getdata' ; '@etable\private\uitable_o' ;
    '@etable\private\warningtoggle' ; '@opaque\private\fromOpaque' ;
    'browse_shortcuts' ; 'browseicons' ; 'cell2mat' ;
    'classcenter' ; 'editds_addimportmenu' ;
    'editds_defaultimportmethods' ; 'editds_importmethods' ;
    'etable.addcallbacks' ; 'etable.addcolumnsorting' ;
    'etable.clear' ; 'etable.etable' ; 'etable.initialize' ;
    'etable.set' ; 'etable.setobj' ; 'etable.settablealignment' ;
    'etable.subsasgn' ; 'etable.subsref' ; 'etable.updatecolumns' ;
    'etable.updatetable' ; 'evricachedb.addproject' ;
    'evricachedb.checkcachedb' ; 'evricachedb.checkproject' ;
    'evricachedb.createcachedb' ; 'evricachedb.evricachedb' ;
    'evricachedb.getcachedates' ; 'evricachedb.getcacheindex' ;
    'evricachedb.getdatabaseobj' ; 'evricachedb.getdates' ;
    'evricachedb.getlinks' ; 'evricachedb.subsref' ;
    'evridb.closeconnection' ; 'evridb.evridb' ;
    'evridb.getconnection' ; 'evridb.getconnectionstring' ;
    'evridb.getpersistentconnection' ; 'evridb.runquery' ;
    'evridb.setdriverdefault' ; 'evridb.setpersistentconnection' ;
    'evridb.subsasgn' ; 'evridb.subsref' ; 'evridir' ;
    'evrijavaobjectedt' ; 'evrijavasetup' ; 'evriwhich' ;
    'flipud' ; 'hrmethodreadr' ; 'iofun\private\urlreadwrite' ;
    'iofun\private\xmlstringinput' ; 'isdataset' ;
    'ismac' ; 'javaclasspath' ; 'mltimerpackage' ;
    'moveobj' ; 'num2cell' ; 'onCleanup' ; 'opaque.strcmp' ;
    'optionsgui' ; 'parsexml' ; 'pathsep' ; 'pca' ;
    'pca_guifcn' ; 'poissonscale' ; 'poissonset' ;
    'pwd' ; 'shiftdim' ; 'specalignset' ; 'ssqsetup' ;
    'strread' ; 'timefun\private\dateformverify' ;
    'timer.isempty' ; 'uitable' ; 'uitools\private\save__listener__' ;
    'uitools\private\uitable_deprecated' ;
    'uitools\private\uiwaitbar' ; 'uitools\private\warnfiguredialog' ;
    'updateClasspathWithJar' ; 'urlread' ; 'workspacefunc' ;
    'xmlread' };
  
  t = timer;
  t.userdata = [double(obj) 0 length(setdiff(inmem,needed)) length(needed)];
  t.TimerFcn = @updatewaitbar;
  t.Period   = .3;
  t.StartDelay = 1;
  t.ExecutionMode = 'fixedDelay';
  start(t);
  return
end

%timer callback itself
info = get(obj,'userdata');
info(2) = (length(inmem)-info(3))/info(4)+obj.TasksExecuted/500;

if ishandle(info(1)) & info(2)<1
  waitbar(info(2),info(1))
else
  stop(obj);
end

set(obj,'userdata',info)

%--------------------------------------------------------------------
function tree_callback(fh,keyword,mystruct,jleaf)
%Left click callback switch for tree control.

%Execute menu callback based on tree node name (they are named the same).
if ~isempty(keyword)
  menuitem = findobj(fh,'tag',keyword,'type','uimenu');
  if ~isempty(menuitem)
    %Spoof call from menu item.
    analysis('cachemenu_callback',menuitem,[],guihandles(fh))
    return
  end
end

%--------------------------------------------------------------------
function tree_double_click(fh,keyword,mystruct,jleaf)
%Double click on tree, load demo data.

if strcmp(mystruct.val(1:4),'demo')
  if strcmp(keyword,'showdemopage')
    %Open help page
    evrihelp('demonstration_datasets');
    return
  end
  [load_data,load_order,load_idx] = getdemodata(keyword,'analysis');
  if isempty(load_data)
    evriwarndlg('This demo dataset could not be loaded into Analysis. Try loading it into the workspace in the Workspace Browser window.','Unable to Load Demo Data');
    return;
  end
  for i = 1:4
    if ~isempty(load_data{i})
      loaddata_callback(fh, [], guidata(fh), load_order{i}, load_data{i});
    end
  end
end

%--------------------------
function out = optiondefs()

defs = {
  %name             tab            datatype        valid           userlevel       description
  'maximumfactors'  'Defaults'    'double'        'int(1:inf)'  'intermediate'  '[ {''20''}] governs number of PCs/Factors displayed in the ssq table pane of the Analysis GUI.';
  'autoselectcomp'  'Tools'       'select'        {'on' 'off'}  'novice'        'Governs the display of ''Automated Component Selection'' button.';
  'autoexclude'     'Tools'       'select'        {'on' 'off'}  'novice'        'Governs auto thresholding.';
  'flowchart'       'Tools'       'select'        {'show' 'hide'} 'novice'          'Governs the display of the model-building flowchart.';
  'predictionblock' 'Tools'       'select'        {'show' 'hide'} 'novice'          'Governs the display of the prediction block in the status pane.';
  'quickopenprepro' 'Tools'       'select'        {'on' 'off'}    'novice'          'Governs behavior of left-click on Preprocessing buttons. ''on'' opens preprocessing interface. ''off'' opens context menu.';
  'clutterbutton'   'Tools'       'select'        {'show' 'hide'} 'novice'          'Governs the display of the clutter button in the status pane.';
  'pushclasses'     'Tools'       'select'        {'on' 'off'}  'novice'        'Governs setting of classes in original data by modifying scores plots. When "on", classes set on a scores plot are pushed back to the original data and into the model. When "off", classes set on scores are for visualization only. Note that some methods (PLSDA, SIMCA) will always push classes because the model is often based on these values.';
  'filternwayprepro' 'Tools'      'select'        {'on' 'off'}  'intermediate'  'Governs filtering of preprocessing to valid methods when multiway data is loaded. When "off" all preprocesssing methods are shown (although some may be invalid for multiway data).'
  'showcalwithtest' 'Tools'       'select'        {'on' 'off'}  'novice'        'Governs the default of whether calibration scores are shown with test scores when a model is applied to test data. Checkbox on Plot Controls changes state interactively.';
  'showerrorbars'   'Tools'       'boolean'       ''            'novice'        'Governs default display of error bars on scores plots (when avaialble). If disabled, error bars are not shown by default but can be displayed by checking checkbox on Plot Controls.'
  'showautoclassscores' 'Tools'   'boolean'       ''            'novice'        'Governs display of "Auto-Class" button in Scores plots. When available, scores can be analyzed automatically and classes assigned to natural clusters.'
  'splitclassedvars' 'Tools'      'boolean'       ''            'novice'        'Governs offering user the option to plot subsets of loadings when classes are defined on the variables of a data set.'
  'showyinbiplot'   'Tools'       'boolean'       ''            'novice'           'Governs display of y-block loadings in Bi-Plots. When true (1) the y-block loadings will be shown in bi-plots.'
  'reducedstats'    'Tools'       'select'        {'none' 'both' 'only'} 'novice'  'Governs display of reduced statistics (when applicable). ''none'' shows only standard statistics; ''both'' shows both standard and reduced statistcs; ''only'' shows only reduced statistics.'
  'defaultimportmethod'   'Defaults' 'select'     [{'prompt'} autoimport('methods')]    'novice'        'Default import method to use when left-clicking on empty data block. "prompt" = ask user, otherwise this specifies the file type to load.';
  %Can set default pp from pp menu so disable here.
  %'defaultxpreprocessing' 'Defaults' 'cell(vector)' ''          'novice'        'Default preprocessing for x-block. Enter keyword(s) in ''single quotes'' separated by spaces.';
  %'defaultypreprocessing' 'Defaults' 'cell(vector)' ''          'novice'        'Default preprocessing for y-block. Enter keyword(s) in ''single quotes'' separated by spaces.';
  'defaultcv'       'Defaults'    'select'        {'none' 'loo' 'con' 'vet' 'rnd'}    'novice'        'Default cross-validation mode when Analysis first opens. See help button on Cross-validation window for definitions.';
  'cachewidth'      'Defaults'    'double'        'float(0:1)'  'novice'        'Governs width allotted to cache viewer after minimums are assigned. Fraction of remaining space to use for model cache. (default = 0.85)';
  'ssqfontsize'     'Defaults'    'double'        'int(1:inf)'  'novice'        'Governs font size of SSQ table, header, and help pane (default = 10/12 PC/NIX).';
   };

out = makesubops(defs);



