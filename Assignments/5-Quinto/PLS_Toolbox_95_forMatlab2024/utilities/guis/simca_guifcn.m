function varargout = simca_guifcn(varargin);
%SIMCA_GUIFCN SIMCA Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%rsk 06/02/04 Change pcsedit to text box, deselct changes back to edit.
%     -Users must make changes via ssq table.
%rsk 08/11/04 Change help line.
%rsk 08/11/04 Run through updatefigures on scores button to make sure
%       - buttons disable correctly.

if nargin>0;
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = analysis('options');
        %add guifcn specific options here
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
      otherwise
        if nargout == 0;
          feval(varargin{:}); % FEVAL switchyard
        else
          [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
        end
    end
  catch
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end
end

%----------------------------------------------------
function gui_init(h,eventdata,handles,varargin);

%create toolbar
[atb abtns] = toolbar(handles.analysis, 'simca','');
handles  = guidata(handles.analysis);
%Create appdata for simca model build gui.
setappdata(atb,'simcagui',[])
%Enable correct buttons.
analysis('toolbarupdate',handles)  %set buttons


%change pc edit label.
set(handles.pcseditlabel,'string','Number PCs:')

%change pc edit box to text box.
set(handles.pcsedit,'style','text')

%change the name of the "factors" in the crossvalidate GUI
crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'PCs');

%Add view selections to dropdown.
panelinfo.name = 'SSQ Table';
panelinfo.file = 'ssqtable';
% panelinfo(2).name = 'Cross Validation';
% panelinfo(2).file = 'crossvalgui';
panelmanager('add',panelinfo,handles.ssqframe)

handles = guihandles(handles.analysis);
guidata(handles.analysis,handles);

%turn on valid crossvalidation
% crossvalgui('enable',handles.analysis);
% crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'PCs');
setappdata(handles.analysis,'enable_crossvalgui','off');

%intercept save model menu callback
cb = get(handles.savemodel,'callback');
setappdata(handles.analysis,'savemenucallback',cb);
set(handles.savemodel,'callback','simca_guifcn(''savemodel'',gcbo,[],guidata(gcbo))')

setappdata(handles.analysis,'cleartestonchange',1);

% %Check for option enabled objects.
% options = pca_guifcn('options');
%
% %Auto select button visibility.
% if exist('choosecomp.m','file')==2 && strcmp(options.autoselectcomp,'on')
%   set(handles.findcomp,'visible','on')
% else
set(handles.findcomp,'visible','off')
% end

%general updating
analysis('updatestatusboxes',handles)
updatefigures(handles.analysis)
updatessqtable(handles)

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)

%Change pcsedit back to defualt style.
set(handles.pcsedit,'style','edit')

cb = getappdata(handles.analysis,'savemenucallback');
set(handles.savemodel,'callback',cb)

setappdata(handles.analysis,'cleartestonchange',0);

setappdata(handles.analysis,'enable_crossvalgui','on');

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

simca_guifcn('closefigures',handles);

%Clear table.
mytbl = getappdata(handles.analysis,'ssqtable');
clear(mytbl,'all');


%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)

statmodl = getappdata(handles.analysis,'statmodl');
modl     = analysis('getobjdata','model',handles);
xblock_loaded     = analysis('isloaded','xblock',handles);
valxblock_loaded  = analysis('isloaded','validation_xblock',handles);
prediction_loaded = analysis('isloaded','prediction',handles);

%Model builder button enabled when data present.
%Calc button enabled when class vector loaed to button appdata.
if ~xblock_loaded & ~strcmp(statmodl,'loaded')
  set(handles.modelbuilder,'enable','off')
else
  set(handles.modelbuilder,'enable','on')
end

if isfield(handles,'calcmodel');
  %calc is harder
  if (xblock_loaded & ismember(statmodl,{'none' 'calnew'}) & ~isempty(getappdata(handles.calcmodel,'modelclasses'))) ...
      | (valxblock_loaded & ~prediction_loaded & ismember(statmodl,{'calold' 'loaded'}))
    en = 'on';
  else
    en = 'off';
  end
  
  %EXCEPTION: don't allow "apply" of PCA sub-models while in SIMCA mode
  if strcmp(statmodl,'loaded') & ~strcmpi(modl.modeltype,'simca');
    en = 'off';
  end
  set(handles.calcmodel, 'Enable',en)
end

%disable some buttons if this is a SIMCA model
if ~isempty(modl) & strcmpi(modl.modeltype,'simca');
  set([handles.plotloads handles.biplot handles.ploteigen],'Enable','off');
  children = [getappdata(handles.plotloads,'children') ...
    getappdata(handles.biplot,'children') ...
    getappdata(handles.ploteigen,'children')];
  close(children(ishandle(children)));
  %Only enable confusion for simca, not pca.
  set(findobj(handles.analysis,'tag','showconfusion'),'enable','on')
else
  set(findobj(handles.analysis,'tag','showconfusion'),'enable','off')
end

simcagui('updatebuttons',getappdata(handles.AnalysisToolbar,'simcagui'));

%assume imagegui disabled
set(findobj(handles.analysis,'tag','openimagegui'),'enable','off')
if ~isempty(modl) & ismember(getappdata(handles.analysis,'statmodl'),{'loaded','calold'})...
    & isfield(modl,'loads') & size(modl.loads{1},2)>1 & isfield(modl.datasource{1},'type')...
    & strcmp(modl.datasource{1}.type,'image')
  %unless these conditions are met:
  % 1) we have a model
  % 2) it has > 1 PC
  % 3) it was built on an image DSO
  set(findobj(handles.analysis,'tag','openimagegui'),'enable','on','visible','on')
end

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)

%two-way x
% out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%discrim: two-way x with classes
out = xprofile.data & xprofile.ndims==2 & xprofile.class;

%discrim: two-way x with classes OR y
% out = xprofile.data & xprofile.ndims==2 & (xprofile.class | (yprofile.data & yprofile.ndims==2) );

%two-way x and y
% out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;

%--------------------------------------------------------------------
function out = isyused(handles)

out = false;


%--------------------------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin);

statmodl = lower(getappdata(handles.analysis,'statmodl'));
if strcmp(statmodl,'calnew') & ~analysis('isloaded','rawmodel',handles)
  statmodl = 'none';
end

%Turn crossval on for pca models. Gets turned off when assemble simca
%model. 
setappdata(handles.analysis,'enable_crossvalgui','on');
analysis('updatecrossvallimits',handles) %LWL added to fix crossval dropdown menu for submodels

switch statmodl
  case {'none'}
    %prepare X-block for analysis
    x             = analysis('getobjdata','xblock',handles);
    
    modelclasses = getappdata(handles.calcmodel,'modelclasses');
    if isempty(modelclasses)
      evritip('calcwomodelbuild','Please use the Model Builder window to select one or more classes to model',1)
      modlbuilder_Callback(h, [], handles)
      return
    end
    
    if isempty(x.includ{1});
      erdlgpls('All samples excluded. Can not calibrate','Calibrate Error');
      return
    end
    if isempty(x.includ{2});
      erdlgpls('All variables excluded. Can not calibrate','Calibrate Error');
      return
    end
    
    if mdcheck(x.data(x.includ{1},x.includ{2}));
      ans = evriquestdlg({'Missing Data Found - Replacing with "best guess"','Results may be affected by this action.'},'Warning: Replacing Missing Data','OK','Cancel','OK');
      if ~strcmp(ans,'OK'); return; end
      try
        if strcmpi(getfield(modelcache('options'),'cache'),'on')
          modelcache([],x);
          evritip('missingdatacache','Original data (with missing values) has been stored in the model cache.',1)
        end
      catch
      end
      [flag,missmap,replaced] = mdcheck(x.data(x.includ{1},x.includ{2},struct('toomuch','ask')));
      x.data(x.includ{1},x.includ{2}) = replaced;
      analysis('setobjdata','xblock',handles,x);
    end
    
    preprocessing = {getappdata(handles.preprocessmain,'preprocessing')};
    options = simca_guifcn('options');

    opts               = simcasub('options');
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.preprocessing = preprocessing;
    opts.rawmodel      = 1;
    
    simcaopts = getappdata(handles.analysis,'analysisoptions');
    if isfield(simcaopts,'classset')
      opts.classset = simcaopts.classset;
    end
    
    usedsamples = intersect(x.includ{1},find(ismember(x.class{1,opts.classset},modelclasses)));
    
    [cvmode,cvlv,cvsplit,cviter] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
    if ~strcmp(cvmode,'none')
      maxpc   = min([length(usedsamples) length(x.includ{2}) options.maximumfactors cvlv]);
    else  %no cross-val method? Don't let the slider limit the # of LVs
      maxpc   = min([length(usedsamples) length(x.includ{2}) options.maximumfactors]);
    end
    pc   = getappdata(handles.pcsedit,'default');
    
    %don't allow > # of evs (in fact, consider this a reset of default)
    if isempty(pc) | pc>maxpc;
      pc = 1;
    end;
    
    %calculate all loads and whole SSQ table
    rawmodl            = simcasub(x,modelclasses,maxpc,opts);    
    pc = min(pc,size(rawmodl.detail.ssq,1)); %make sure #pc doesn't exceed available # of PCs
    
    %calculate sub-set of that raw model (with limits, etc)
    modl = simcasub(x,modelclasses,pc,rawmodl,opts);
    modl.detail.ssq = rawmodl.detail.ssq(1:min(maxpc,size(rawmodl.detail.ssq,1)),:);
  
    %Do cross-validation
    if ~strcmp(cvmode,'none')
      modl = crossvalidate(handles.analysis,modl);
      rawmodl = copycvfields(modl,rawmodl);
    end
    
    %UPDATE GUI STATUS
    %set status windows
    setappdata(handles.analysis,'statmodl','calold');
    analysis('setobjdata','model',handles,modl);
    analysis('setobjdata','rawmodel',handles,rawmodl);
    
    updatessqtable(handles,pc);
    
  case {'calnew'}
    %change of # of components only
    rawmodl = analysis('getobjdata','rawmodel',handles);
    x       = analysis('getobjdata','xblock',handles);
    mytbl   = getappdata(handles.analysis,'ssqtable');
    
    preprocessing = {getappdata(handles.preprocessmain,'preprocessing') []};
    
    %minpc   = get(handles.ssqtable,'Value'); %number of PCs
    minpc   = getselection(mytbl,'rows');
    
    modelclasses = getappdata(handles.calcmodel,'modelclasses');
    
    opts               = simcasub('options');
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.preprocessing = preprocessing;
    opts.rawmodel      = 1;
    simcaopts = getappdata(handles.analysis,'analysisoptions');
    if isfield(simcaopts,'classset')
      opts.classset = simcaopts.classset;
    end
    
    modl       = simcasub(x,modelclasses,minpc,rawmodl,opts);
    
    modl.detail.rmsec  = rawmodl.detail.rmsec;
    modl.detail.rmsecv = rawmodl.detail.rmsecv;
    modl.detail.cv     = rawmodl.detail.cv;
    modl.detail.split  = rawmodl.detail.split;
    modl.detail.iter   = rawmodl.detail.iter;
    
    setappdata(handles.analysis,'statmodl','calold');
    analysis('setobjdata','model',handles,modl);
    updatessqtable(handles)
    
end

if analysis('isloaded','validation_xblock',handles)
  %apply model to test data
  %prepare X-block for analysis
  modl = analysis('getobjdata','model',handles);
  x    = analysis('getobjdata','validation_xblock',handles);
  
  fn = lower(modl.modeltype);
  opts = getappdata(handles.analysis,'analysisoptions');
  if isempty(opts)
    opts = feval(fn,'options');
  end
  opts.display       = 'off';
  opts.plots         = 'none';
  opts.rawmodel      = 0;
  
  try
    test = feval(fn,x,modl,opts);
  catch
    erdlgpls({'Error applying model to validation data.',lasterr,'Model not applied.'},'Apply Model Error');
    test = [];
  end
  
  analysis('setobjdata','prediction',handles,test)
  
  if strcmp(fn,'simca')
    simcaguih = getappdata(handles.AnalysisToolbar,'simcagui');
    if ~isempty(simcaguih) & ishandle(simcaguih)
      %Call simcagui in "view model" mode.
      simcagui('populatemodels', simcaguih)
    end
  end
else
  %no test data? clear prediction
  analysis('setobjdata','prediction',handles,[]);
end

analysis('toolbarupdate',handles)  %set buttons
analysis('updatestatusboxes',handles);

%delete model-specific plots we might have had open
h = getappdata(handles.analysis,'modelspecific');
close(h(ishandle(h)));
setappdata(handles.analysis,'modelspecific',[]);

%update plots
simca_guifcn('updatefigures',handles.analysis);     %update any open figures
figure(handles.analysis)

% --------------------------------------------------------------------
function [modl,success] = crossvalidate(h,modl,perm)
%CrossValidationGUI CrossValidateButton CallBack
handles  = guidata(h);

success = 0;

if nargin>2 & perm>0
  %not available - return empty
  modl = [];
  return;
end

x        = analysis('getobjdata','xblock',handles);
y        = [];
mc       = {modl.detail.preprocessing{1} []};

[cv,lv,split,iter,cvi] = crossvalgui('getsettings',getappdata(h,'crossvalgui'));

% modeltype = 'simcasub';
%NOTE: until simcasub works in crossval, we're going to hard-code the
%cross-validation logic here and use PCA. Eventually, we should also get
%misclassification info from crossval.
modeltype = 'pca';
modelclasses = getappdata(handles.calcmodel,'modelclasses');
classset = modl.detail.options.classset;
x.includ{1} = intersect(x.includ{1},find(ismember(x.class{1,classset},modelclasses)));

%non-robust...
%Check if the CV GUI had settings forced to it by loading or initializing.
%If so, and if data is large (defined below), then ask user if they really
%wanted to cross-validate...
%(note: we don't do this for robust models to avoid having
%too many questions be asked. If the user doesn't want to automatic
%cross-validate with robust mode enabled, they can cancel out of the
%above dialog)
cvgui = getappdata(h,'crossvalgui');

if crossvalgui('forcedsettings',cvgui) & size(x,1)>2000
  r = questdlg('Cross-validation was automatically enabled but may be slow on this data. Do you want to Cross-Validate Now, Skip Cross-Validation for just this model, or Turn Off Cross-Validation?','Automatic Cross-Validation','Cross-Validate Now','Skip CV','Turn Off CV','Cross-Validate Now');
  drawnow;
  if strcmpi(r,'Skip CV')
    return;
  elseif strcmpi(r,'Turn Off CV')
    crossvalgui('forcesettings',cvgui,'none'); %Turn it off...
    return;
  end
  setappdata(cvgui,'forcedsettings',false);  %User has now accepted this cross-validation - don't warn again until they are forced into it by loading a model (e.g.)
end


m  = length(x.includ{1});
n  = length(x.includ{2});
lv = min([lv m n]);

cvopts = crossval('options');
cvopts.plots = 'none';
cvopts.display = 'off';

% loo can be very slow if there are many variables, so modify if so
if length(x.include{2})>25;
  cvopts.pcacvi = {'con' min(10,floor(sqrt(length(x.include{2}))))};
else
  cvopts.pcacvi = {'loo'};
end

cvopts.preprocessing = {modl.detail.preprocessing{1} []};
try
  res = crossval(x,modelclasses,modl,cvi,lv,cvopts);
catch
  erdlgpls({'Unable to perform cross-valiation - Aborted';lasterr},'Cross-Validation Error');
  return
end 

modl = copycvfields(res,modl);

success = 1;


%--------------------------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.
modl = analysis('getobjdata','model',handles);
mytbl = getappdata(handles.analysis,'ssqtable');

if ~isempty(modl) & strcmpi(modl.modeltype,'simca')
  %open model builder
  modlbuilder_Callback(handles.analysis, [], handles)
  %set(handles.ssqtable,'Value',[]);
else
  %PCA model
  pca_guifcn('ssqtable_Callback',h,[],handles);
end
%--------------------------------------------------------------------
function pcsedit_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.pcsedit.
% Selects number of PCs in the editable text box.

pca_guifcn('pcsedit_Callback',h,[],handles);

%--------------------------------------------------------------------
function updatefigures(h)
%update any open figures

%check status of simcagui
handles = guidata(h);
sgh = getappdata(handles.AnalysisToolbar,'simcagui');
if ishandle(sgh)
  simcagui('updatemodellist',sgh);
end

pca_guifcn('updatefigures',h);


%----------------------------------------
function closefigures(handles)
%close the analysis specific figures
if ishandle(getappdata(handles.AnalysisToolbar,'simcagui'))
  delete(getappdata(handles.AnalysisToolbar,'simcagui'))
end
pca_guifcn('closefigures',handles);


% --------------------------------------------------------------------
function plotscores_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.plotscores.
%I/O: plotscores_Callback(h,[],handles,extracmds)
%  where extracmds is cell to be expanded and passed to plotgui

pca_guifcn('plotscores_Callback',h,eventdata,handles,varargin{:});

%--------------------------------------------------------------------
function modlbuilder_Callback(h, eventdata, handles, varargin)
%Create modlbuilder GUI if not already there.

%Check children field.
simcaguih = getappdata(handles.AnalysisToolbar,'simcagui');
if isempty(simcaguih) | ~ishandle(simcaguih)
  %No gui yet so create one.
  simcagui(handles.analysis);
else
  %Bring focus to existing figure.
  figure(simcaguih);
end

%-------------------------------------------------
function updatessqtable(handles,pc)

modl = analysis('getobjdata','model',handles);
mytbl = getappdata(handles.analysis,'ssqtable');

%SSQ table changes depending on state of GUI so need to update column
%headers here.

if isempty(modl) | strcmp(lower(modl.modeltype),'simca')
  clear(mytbl);%Clear data.
  %set(handles.ssqtable,'String',{},'Value',1,'Enable','off','max',1)
  set(handles.pcsedit,'String','','Enable','off')
  
  mytbl = ssqsetup(mytbl,{'Total<br>Samples' 'Modeled<br>Class(es)'},...
    '<b>&nbsp;&nbsp;&nbsp;Sub-<br>Model',{'%5i' '%s'},0);
  
  if ~isempty(modl);  %SIMCA model here
    %s = '';
    classset = modl.detail.options.classset;
    newtable = {};
    for j=1:length(modl.submodel);
      classes = num2str(unique(modl.submodel{j}.detail.class{1,1,classset}(modl.submodel{j}.detail.includ{1})));
      newtable{j,1} = length(modl.submodel{j}.detail.includ{1});
      newtable{j,2} = classes;
      %s{j} = [sprintf('%2i     %5i       %s',j,length(modl.submodel{j}.detail.includ{1}),classes)];
    end
    %set(handles.ssqtable,'string',s,'Value',[],'max',2,'enable','on');
    %Update table data.
    mytbl.data = newtable;
  end
  
  set(handles.tableheader,'string',{'Classes Modeled by SIMCA Sub-Models'},'HorizontalAlignment','center');
  return
end

mytbl = ssqsetup(mytbl,{'Eigenvalue<br>of Cov(X)' '% Variance<br>This PC' '% Variance<br>Cumulative' ' '},...
  '<b>&nbsp;&nbsp;&nbsp;PC',{'%4.2e' '%6.2f' '%6.2f' ''},1);

if nargin==2;
  pca_guifcn('updatessqtable',handles,pc);
else
  pca_guifcn('updatessqtable',handles);
end
drawnow
%--------------------------------------------------
function savemodel(h,eventdata,handles,varargin)

modl = analysis('getobjdata','model',handles);
statmodl = getappdata(handles.analysis,'statmodl');

if ~strcmp(statmodl,'none') & ~strcmp(lower(modl.modeltype),'simca')
  erdlgpls('Please build or select the entire SIMCA model in the Model Builder window before saving','Unable to save');
  return
end

analysis('savemodel',h,eventdata,handles)

%----------------------------------------------------
function  optionschange(h)

handles = guidata(h);
sgh = getappdata(handles.AnalysisToolbar,'simcagui');
if ishandle(sgh)
  simcagui('autorebuild',sgh); %force rebuild of model if it exists
end
