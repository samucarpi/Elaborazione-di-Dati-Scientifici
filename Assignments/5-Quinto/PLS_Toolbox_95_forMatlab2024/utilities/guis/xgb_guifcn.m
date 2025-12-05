function varargout = xgb_guifcn(varargin);
%XGB_GUIFCN XGBoost Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2018
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin>0;
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = analysis('options');
        %add guifcn specific options here
        options.variable_importance_ticlimit = 20;%NOT USED YET
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
xgmode = getappdata(handles.analysis,'curanal');

[atb,abtns] = toolbar(handles.analysis, 'xgb','');
handles  = guidata(handles.analysis);
analysis('toolbarupdate',handles);
%change ssq table labels
%No ssq table, disable.
set(handles.pcsedit,'Enable','off')
%set(handles.ssqtable,'Enable','off')

%Set crossval gui to default.
setappdata(handles.analysis,'enable_crossvalgui','on');
crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'<Unused>')

%general updating
set([handles.pcseditlabel handles.ssqtable handles.pcsedit],'visible','off')

% Need to hack options into analysis before call to add panel because 
% panel depends on options being there.
opts = analysis('getoptshistory',handles,lower(xgmode));
if isempty(opts)
  opts = getoptions(handles);
end
setappdata(handles.analysis, 'analysisoptions',opts);

%Add view selections to dropdown.
panelinfo.name = [upper(xgmode) ' Variable Importance Plot'];
panelinfo.file = 'xgbgui';
panelmanager('add',panelinfo,handles.ssqframe)

handles = guihandles(handles.analysis);
guidata(handles.analysis,handles);

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
closefigures(handles);

%Set crossval gui to default.
setappdata(handles.analysis,'enable_crossvalgui','on');
%Update cvgui.
analysis('updatecrossvallimits',handles)

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)

myanal = getappdata(handles.analysis,'curanal');

choosegrps = findobj(handles.analysis,'tag','choosegrps');
showconfusion = findobj(handles.analysis,'tag','showconfusion');
daonly = [showconfusion choosegrps];
if strcmp(myanal,'xgbda')
  %Set confusion table and choose groups to visible on. 
  set(daonly,'visible','on')
  
  %see if we can use choose groups
  statmodl = getappdata(handles.analysis,'statmodl');
  if ~strcmp(statmodl,'loaded') && analysis('isloaded','xblock',handles) && isempty(analysis('getobjdata','yblock',handles))
    en = 'on';
  else
    en = 'off';
  end
  set(choosegrps,'enable',en);
  
else
  set(daonly,'enable','off','visible','off')
  set(findobj(handles.analysis,'tag','calcmodel'),'separator','on')
end


%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)
%two-way x
% out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%discrim: two-way x with classes OR y
out = xprofile.data & xprofile.ndims==2 & (xprofile.class | (yprofile.data & yprofile.ndims==2) );

%two-way x and y
%out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;

%--------------------------------------------------------------------
function out = isyused(handles)
%Y or classes.

if analysis('isloaded','xblock',handles.analysis);
  if analysis('isloaded','yblock',handles.analysis)
    %if y-block is loaded, we're using it
    out = true;
  else
    %if no y-block, then whether or not we need one is based on if classes
    %exist in the x-block
    x = analysis('getobjdata','xblock',handles);
    xprofile = analysis('varprofile',x);
    out = ~xprofile.class;
  end
else
  %no x? can't decide, assume true
  out = true;
end

%----------------------------------------------------
function  calcmodel_Callback(h,eventdata,handles,varargin);
%xgb Calculate model, uses similar code from reg_guifcn.

xgbmode = getappdata(handles.analysis,'curanal');
statmodl = lower(getappdata(handles.analysis,'statmodl'));
if strcmp(statmodl,'calnew') & ~analysis('isloaded','rawmodel',handles)
  statmodl = 'none';
end

if strcmp(statmodl,'none')
  x = analysis('getobjdata','xblock',handles);
  if isempty(x.includ{1});
    erdlgpls('All samples excluded. Can not calibrate','Calibrate Error');
    return
  end
  if isempty(x.includ{2});
    erdlgpls('All x-block variables excluded. Can not calibrate','Calibrate Error');
    return
  end

  if ~analysis('isdatavalid',handles);
    if strcmpi(xgbmode,'xgb')
      erdlgpls('A y-block must be loaded to perform regression. Can not calibrate','Calibrate Error');
    else
      erdlgpls('Classes must be supplied in the X-block samples mode, or a y-block designating class membership must be loaded. Can not calibrate','Calibrate Error');
    end
    return
  end

  if mdcheck(x.data);
    ans = evriquestdlg({'Missing Data Found - Replacing with "best guess"','Results may be affected by this action.'},'Warning: Replacing Missing Data','OK','Cancel','OK');
    if ~strcmp(ans,'OK'); return; end
    try
      if strcmpi(getfield(modelcache('options'),'cache'),'on')
        modelcache([],x);
        evritip('missingdatacache','Original data (with missing values) has been stored in the model cache.',1)
      end
    catch
    end
    [flag,missmap,x] = mdcheck(x,struct('toomuch','ask'));
    analysis('setobjdata','xblock',handles,x);
  end

  %Deal with y block if present.
  y = analysis('getobjdata','yblock',handles);
  if ~isempty(y);

    nans = any(isnan(y.data(y.include{1},y.include{2})),2);
    if any(nans);
      evrimsgbox({'Missing Data Found in Y-block - Excluding all samples with missing y-block values.'},'Warning: Excluding Missing Data Samples','warn','modal');
      y.include{1} = intersect(y.include{1},y.include{1}(find(~nans)));
      analysis('setobjdata','yblock',handles,y);   %and save back to object
    end
    if isempty(y.includ{2});
      erdlgpls('All y-block columns excluded. Can not calibrate','Calibrate Error');
      return
    end
    if length(y.includ{2})>1
      erdlgpls('XGB cannot operate on multivariate y. Choose a single column to operate on.','Calibrate Error')
      analysis('editselectycols',handles.analysis,[],handles);
      return
    end
    isect = intersect(y.include{1},x.include{1}); %intersect samples includ from x- and y-blocks
    if length(x.include{1})~=length(isect) | length(y.include{1})~=length(isect);  %did either change?
      y.include{1} = isect;
      analysis('setobjdata','yblock',handles,y);   %and save back to object
      x.include{1} = isect;
      analysis('setobjdata','xblock',handles,x);   %and save back to object
    end

    if all(all(y.data(y.includ{1},:) == y.data(y.includ{1}(1),1)));
      erdlgpls('All included samples are in the same class - can not do discriminant analysis','Calibrate Error');
      return
    end
  else
    %no y-block,
    if strcmpi(xgbmode,'xgb');
      erdlgpls('No y-block information is loaded. Can not calibrate','Calibrate Error');
      return
    end
    
    %no y-block, check for modelgroups from user selecting items to group
    modelgroups = getappdata(findobj(handles.analysis,'tag','choosegrps'),'modelgroups');
    if ~isempty(modelgroups)
      y = modelgroups;
    else
      y = {};  %no groups, no y, use classes as-is
    end
    
  end
  preprocessing = {getappdata(handles.preprocessmain,'preprocessing') getappdata(handles.preproyblkmain,'preprocessing')};

  try
    opts = getoptions(handles);
    opts.preprocessing = preprocessing;
    
    [cvmode,cvlv,cvsplit,cviter] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
    switch cvmode
      case 'none'
        opts.cvi = {};
      otherwise
        opts.cvi = {cvmode cvsplit cviter};
    end
    opts.cvi_orig = opts.cvi;
    
    if exist('cvmode', 'var') & exist('cvsplit', 'var') & ~isempty(cvmode) & ~isempty(cvsplit)
      if strcmp(cvmode, 'custom')
        cvi0 = {'custom' cvsplit};
      else
        cvi0 = encodemethod(size(x,1), cvmode, cvsplit, 1);
        if exist('cviter', 'var') & ~isempty(cviter)
          cvi0 = encodemethod(size(x,1), cvmode, cvsplit, cviter);
        end
      end
      opts.cvi = cvi0;
    end

    switch xgbmode
      case 'xgb'
        modl = xgb(x,y,opts);
      case 'xgbda'
        if isempty(y)
          modl      = xgbda(x,opts);
        else
          modl      = xgbda(x,y,opts);
        end
    end
    
  catch
    erdlgpls({'Error using XGB',lasterr},'Calibrate Error');
    return
  end

  %UPDATE GUI STATUS
  setappdata(handles.analysis,'statmodl','calold');
  analysis('setobjdata','model',handles,modl);
  %Never use raw model with xgb.
  analysis('setobjdata','rawmodel',handles,[]);
  
  handles = guidata(handles.analysis);

  figure(handles.analysis)
end


if analysis('isloaded','validation_xblock',handles)
  %apply model to test data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
  if isempty(x); return; end  %some cancel action
  
  try
    opts = getoptions(handles);
    
    switch xgbmode
      case 'xgb'
        test = xgb(x,y,modl,opts);
      case 'xgbda'
        if isempty(y)
          test = xgbda(x,modl,opts);
        else
          test = xgbda(x,y,modl,opts);
        end
    end

  catch
    erdlgpls({'Error using applying model',lasterr,'Model not applied to validation data.'},'Apply Model Error');
    test = [];
  end
  analysis('setobjdata','prediction',handles,test);

else
  analysis('setobjdata','prediction',handles,[]);
end

analysis('toolbarupdate',handles)
analysis('updatestatusboxes',handles);

%delete model-specific plots we might have had open
h = getappdata(handles.analysis,'modelspecific');
close(h(ishandle(h)));
setappdata(handles.analysis,'modelspecific',[]);

updatefigures(handles.analysis);     %update any open figures

% --------------------------------------------------------------------
function plotscores_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.plotscores.
%I/O: plotscores_Callback(h,[],handles,extracmds)
%  where extracmds is cell to be expanded and passed to plotgui

pca_guifcn('plotscores_Callback',h,eventdata,handles,varargin{:});

% --------------------------------------------------------------------
function ploteigen_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ploteigen.
modl = analysis('getobjdata','model',handles);

fig = [];  %create new UNLESS...

%see if we can find a modelspecific chilid figure with the right tag
figs = getappdata(handles.analysis,'modelspecific');
figs(~ishandle(figs)) = [];
if ~isempty(figs)
  tags = get(figs,'tag');
  if ~iscell(tags); tags = {tags}; end
  match = ismember(tags,'xgboptresults');
  if any(match)
    fig = min(double(figs(match)));  %use old
  end
end

f = double(xgbcvplot(modl,[],fig));
if isempty(f)
  evriwarndlg('No optimization information is available for this model.','XGB Optimization Plot');
  return
end
set(f,'name','Parameter Optimization Results','tag','xgboptresults');

if ~isappdata(f, 'model')
  % add the model to the figure if it is not present
  setappdata(f,'model', modl);
end

analysis('adopt',handles,f,'modelspecific')

% --------------------------------------------------------------------
function plotloads_Callback(h, eventdata, handles, varargin)
% Plot variable importance as a "loadings" plot. 

modl = analysis('getobjdata','model',handles);
x    = analysis('getobjdata','xblock',handles);

myax = [];
if nargin>3
  if ishandle(varargin{1}) && strcmp(get(varargin{1},'tag'),'xgb_axes')
    myax = varargin{1};
  end
end

if isempty(modl) || isempty(x)
  return
end

xopts = xgb_guifcn('options');%NOT USED, might need to limit number of variable displayed.

fs = modl.detail.xgb.featurescores;
fsids = modl.detail.xgb.featureIDs;
[sfs, isort] = sort(fs, 'ascend');
figs = getappdata(handles.analysis,'modelspecific');

if isempty(myax)
  %Creating new figure with plot.
  myfig = [];
  try
    myfig = findobj(figs,'tag','xgb_variable_importance');
  end
  
  if isempty(myfig)
    fig = figure('Name','Variable Importance','tag','xgb_variable_importance');
  else
    fig = myfig;
  end
  
  figure(fig);
  ax = gca;
else
  %Using panel version of plot.
  myfig = -1;%Dummy so don't try to adopt.
  ax = myax;
  axes(ax);
end

cla;

numvars = length(sfs);

barh(ax,1:numvars, sfs)
ylabel('Variable Score')
xlabel('Gain')
varlabs = x.label{2};
if isempty(varlabs)
  varlabs = str2cell((sprintf('Variable %d\n',[1:size(x,2)]')));
end
varlabsi = varlabs(x.include{2}, :);

if ~isempty(modl.detail.compressionmodel)
  varlabsi = fsids;  % using compression
end

set(ax,'ytick',[1:length(sfs)],'yticklabel',varlabsi(isort,:),'userdata',isort(sfs>0))
try;set(ax,'TickLabelInterpreter','none');end     % for var labels a_1, etc
if isempty(myfig)
  analysis('adopt',handles,fig,'modelspecific')
end

%Add tag back to handle because it gets lost sometimes. 
if ~isempty(myax)
  set(myax,'tag','xgb_axes')
end

mymenu = findobj(handles.analysis,'type','uicontextmenu','tag','xgb_plotmenu');
if ~isempty(myax) && ishandle(myax)
  if isempty(mymenu)
    mymenu = uicontextmenu('parent',handles.analysis,'tag','xgb_plotmenu');
    m1 = uimenu(mymenu,'Label','Copy Variable Importance Index','Callback',{@copyindex,ax});
    m2 = uimenu(mymenu,'Label','Include Only Top N Variables','Callback',{@includeindex,ax});
  end
  set(myax,'uicontextmenu',mymenu);
end

%----------------------------------------------------
function  copyindex(varargin)
%Get index of selected variables. 
handles = guidata(varargin{1});

myax = findobj(handles.analysis,'tag','xgb_axes');
if ~isempty(myax)
  mydata = get(myax,'userdata');
  if ~isempty(mydata)
    clipboard('copy',flipud(mydata));
  end
end

%----------------------------------------------------
function  includeindex(varargin)
%Ask user how many (importance ranked) variables to set as included. 

numIncludVars = inputdlg('Enter top N variables set as included in dataset:','Top N Variables',1);

if isempty(numIncludVars)
  return;
else
  numIncludVars=numIncludVars{:};
  numIncludVars = str2double(numIncludVars);
end

if isnan(numIncludVars)
  %Bad character in input so just return.
  return
end

figH = ancestor(varargin{1},'figure');
handles = guihandles(figH);
x = analysis('getobjdata','xblock',handles);

if numIncludVars> size(x,2) 
  error(['Number if variables to include must be less than size of data in mode 2 (columns) ' num2str(size(x,2)) '.']);
end

myax = findobj(handles.analysis,'tag','xgb_axes');
if ~isempty(myax)
  topVars = get(myax,'userdata');
  if ~isempty(topVars)
    if length(topVars)<numIncludVars
      evriwarndlg('Variables to included is greater than number available.','Top N Too Large')
      return
    end
    topVars = topVars(1:numIncludVars);
    x.include{2,1} = topVars;
    analysis('setobjdata','xblock',handles,x);
  end
end

%----------------------------------------------------
function  ssqtable_Callback(h, eventdata, handles, varargin)

%----------------------------------------------------
function  pcsedit_Callback(h, eventdata, handles, varargin)

%----------------------------------------------------
function  optionschange(h)

% --------------------------------------------------------------------
function [modl,success] = crossvalidate(h,modl,perm)
%CrossValidationGUI CrossValidateButton CallBack
handles  = guidata(h);

if nargin<3
  perm = 0;
end

success  = 0;  %indicates failure

x        = analysis('getobjdata','xblock',handles);
y        = analysis('getobjdata','yblock',handles);

[cv,lv,split,iter,cvi] = crossvalgui('getsettings',getappdata(h,'crossvalgui'));

if perm>0
  opts.permutation = 'yes';
  opts.npermutation = perm;
    lv = 1;
end

try
  modl = crossval(x,y,modl,cvi,lv,opts);
catch
  erdlgpls({'Unable to perform cross-valiation - Aborted';lasterr},'Cross-Validation Error');
  return
end

if perm>0
  success = lv;
else
  success  = 1;  %Got here, everything was OK
end

%--------------------------------------------------------------------
function updatefigures(h)

pca_guifcn('updatefigures',h);

%----------------------------------------
function closefigures(handles)
%close the analysis specific figures
for parent = [handles.calcmodel];
  toclose = getappdata(parent,'children');
  toclose = toclose(ishandle(toclose));  %but only valid handles
  if ~isempty(toclose)
    delete(toclose); 
  end
  setappdata(parent,'children',[]);
end

pca_guifcn('closefigures',handles);

%-------------------------------------------------
function updatessqtable(handles,pc)

% --------------------------------------------------------------------
function opts = getoptions(handles)
%Returns options strucutre

xgbmode = getappdata(handles.analysis,'curanal');
%See if there are old/curent options (loaded in analysis under
%enable_method.
opts  = getappdata(handles.analysis,'analysisoptions');

if isempty(opts) | ~strcmp(opts.functionname, xgbmode)
  switch xgbmode
    case 'xgb'
      opts = xgb('options');
    case 'xgbda'
      opts = xgbda('options');
    case 'lwr'
      opts = lwr('options');
  end
end
opts.display       = 'off';
opts.plots         = 'none';

% --------------------------------------------------------------------
function opts = setoptions(handles)
%Set options from history.
xgbmode = getappdata(handles.analysis,'curanal');
opts = analysis('getoptshistory',handles,lower(xgbmode));
if isempty(opts)
  opts = getoptions(handles);
end
setappdata(handles.analysis, 'analysisoptions',opts);
