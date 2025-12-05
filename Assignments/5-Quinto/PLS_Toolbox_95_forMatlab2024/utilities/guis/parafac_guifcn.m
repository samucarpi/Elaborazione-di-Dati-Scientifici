function varargout = parafac_guifcn(varargin)
%PARAFAC_GUIFCN PARAFAC Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%jms/rsk 04/04 Initial coding.
%rsk 05/04/04 Disable maxpc checking in calc
%       -Change ssq table behavior.
%jms 5/11/04 Add MSC as a valid prepro option, remove savgol
%jms 5/24/04 Add handle check for pp in gui deselect.
%rsk 06/10/04 Add drop pp for non n-way prepro.
%rsk 08/11/04 Change help line.

if nargin>0;
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = analysis('options');
        %add guifcn specific options here
        options.loadsmenumode = 'uimenu';
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
[atb abtns] = toolbar(handles.analysis, 'parafac','');
handles  = guidata(handles.analysis);

%Check for how init was called. If varargin(1) is 'oldtag' from analysis
%then called from commandline as startup.
if ~isempty(varargin) & isempty(varargin{1})
  commandstart = 1;
else
  commandstart = 0;
end

model_type = getappdata(handles.analysis,'curanal');

%Enable correct buttons.
analysis('toolbarupdate',handles)  %set buttons

%change pc edit label.
set(handles.pcseditlabel,'string','Number Components:')


mytbl = getappdata(handles.analysis,'ssqtable');
mytbl = ssqsetup(mytbl,{'Fit<br>(% X)' 'Fit<br>(% Model)' 'Unique Fit<br>(% X)' 'Unique Fit<br>(% Model)' ' '},...
  '<b>&nbsp;Comp',{'%6.2f' '%6.2f' '%6.2f' '%6.2f' ''},1);

% mytbl.table_clicked_callback = {@ssqtable_Callback, handles.analysis};
% mytbl.row_clicked_callback = {@ssqtable_Callback, handles.analysis};
% mytbl.row_doubleclicked_callback = {@calcmodel_Callback,handles.analysis,[],handles};

set(handles.tableheader,'string',['Percent Variance Captured by ' upper(model_type) ' Model'],'HorizontalAlignment','center') 


% %change ssq table labels
% if ispc
%   set(handles.tableheader,'string',...
%     { '          Percent Variance Captured by PARFAC Model        ',...
%       '                         Fit               Fit                Unique Fit      Unique Fit',...
%       'Component        (%X)            (%Model)      (%X)              (%Model) ' } )
%   format       = '%3.0f       %6.2f    %6.2f    %6.2f    %6.2f';
% else
%   set(handles.tableheader,'string',...
%     { '          Percent Variance Captured by PARAFAC Model       ',...
%       '            Fit           Fit           Unique Fit    Unique Fit',...
%       'Component   (%X)          (%Model)      (%X)          (%Model)  ' } )
%   format       = '%5.0f    %10.2f    %10.2f    %10.2f    %10.2f';
% end
% setappdata(handles.analysis,'tableformat',format);

%change the name of the "factors" in the crossvalidate GUI
crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'Factors');

%turn off crossvalidation
setappdata(handles.analysis,'enable_crossvalgui','off');

%Add panel.
panelinfo.name = 'SSQ Table';
panelinfo.file = 'ssqtable';
panelmanager('add',panelinfo,handles.ssqframe)

%general updating
analysis('updatestatusboxes',handles)
updatefigures(handles.analysis)
updatessqtable(handles)
set(handles.pcsedit,'enable','on')

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)

%reset back to standard catalog
setappdata(handles.analysis,'preprocesscatalog',{preprocess('initcatalog') preprocess('initcatalog')})

setappdata(handles.analysis,'enable_crossvalgui','on');

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

%Clear table.
mytbl = getappdata(handles.analysis,'ssqtable');
clear(mytbl,'all');

closefigures(handles);
%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)
pca_guifcn('gui_updatetoolbar',h,eventdata,handles,varargin);
modl = analysis('getobjdata','model',handles);
if ~isempty(modl) & isfield(modl.datasource{1},'type') & strcmp(modl.datasource{1}.type,'image')
  set(handles.modelviewer,'enable','off');
end

if ~isempty(modl) & length(modl.datasource{1}.size)~=3
  set(handles.plotloadsurf,'enable','off');
end

if ~isempty(modl) & strcmpi(modl.modeltype,'parafac2')
  %Disable for Parafac2, doesn't apply.
  set(handles.plotloadsurf,'enable','off');
end

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)

%two-way x
%out = xprofile.data & xprofile.ndims==2;

%multi-way x
out = xprofile.data & xprofile.ndims>1;

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
function calcmodel_Callback(h,eventdata,handles,varargin)

if isempty(get(handles.pcsedit, 'string')) & isempty(getappdata(handles.pcsedit, 'defualt'))
  % For parafac, number of components must be supplied. No raw model behavior
  % is supported with this method.
  evrimsgbox('Please enter Number of Components.','Enter Components','warn','modal')
  return
end

statmodltest = lower(getappdata(handles.analysis,'statmodl'));
model_type = getappdata(handles.analysis,'curanal');

switch statmodltest
  case {'none', 'calnew'}
    %prepare X-block for analysis
    x = analysis('getobjdata','xblock',handles);

    if isempty(x.includ{1});
      erdlgpls('All samples excluded. Can not calibrate','Calibrate Error');
      return
    end

    preprocessing = {getappdata(handles.preprocessmain,'preprocessing')};

    pc      = getappdata(handles.pcsedit,'default');

    opts = getappdata(handles.analysis,'analysisoptions');
    if isempty(opts)
      switch model_type
        case 'parafac'
          opts = parafac('options');
        case 'parafac2'
          opts = parafac2('options');
      end
    end
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.preprocessing = preprocessing;
    
    %calculate model
    if strcmp(statmodltest, 'none');
      %clear model cache just in case gui is in bad state.
      analysis('setobjdata','modelcache',handles,[]);
      switch model_type
        case 'parafac'
          modl    = parafac(x,pc,opts);
        case 'parafac2'
          modl    = parafac2(x,pc,opts);
      end
      analysis('setobjdata','modelcache',handles,{modl});
    else strcmp(statmodltest, 'calnew');
      %To save time, if model to be calculated already exists in cache put
      %it in appdata rather than recalculating. If not in cache, calculate
      %it then put it into cache.
      curcachemodls = analysis('getobjdata','modelcache',handles);
      if ~isempty(curcachemodls)
        %Create vector of cached pcs.
        for ii = 1:length(curcachemodls)
          tempcachemodl = curcachemodls{ii};
          tempcachemodlpcs = size(tempcachemodl.loads{2});
          cachemodlpcs(ii) = tempcachemodlpcs(end);
        end
        if any(cachemodlpcs == pc)
          modl = curcachemodls{find(cachemodlpcs == pc)};
        else
          %Model not in cache, add to cache. Calc and add.
          switch model_type
            case 'parafac'
              modl    = parafac(x,pc,opts);
            case 'parafac2'
              modl    = parafac2(x,pc,opts);
          end
          curcachemodls{length(curcachemodls) + 1} = modl;
        end
      else
        %No model cache at all, calc and add to cache.
        switch model_type
          case 'parafac'
            modl    = parafac(x,pc,opts);
          case 'parafac2'
            modl    = parafac2(x,pc,opts);
        end
        curcachemodls{length(curcachemodls) + 1} = modl;
      end
      if isempty(pc) | modl.pcs~=pc
        pc = modl.pcs;
        setappdata(handles.pcsedit,'default',pc);
        set(handles.pcsedit,'String',int2str(pc));
      end
      analysis('setobjdata','modelcache',handles,curcachemodls);
    end
    
    %UPDATE GUI STATUS
    %set status windows
    setappdata(handles.analysis,'statmodl','calold');
    analysis('setobjdata','model',handles,modl);
    
    updatessqtable(handles)
end

if analysis('isloaded','validation_xblock',handles)
  %apply model to test data
  modl = analysis('getobjdata','model',handles);
  x = analysis('getobjdata','validation_xblock',handles);
  
  opts = getappdata(handles.analysis,'analysisoptions');
  if isempty(opts)
    switch model_type
      case 'parafac'
        opts = parafac('options');
      case 'parafac2'
        opts = parafac2('options');
    end
  end
  opts.display       = 'off';
  opts.plots         = 'none';
  
  try
    switch model_type
      case 'parafac'
        test = parafac(x,modl,opts);
      case 'parafac2'
        test = parafac2(x,modl,opts);
    end
  catch
    erdlgpls({'Error applying model to validation data.',lasterr,'Model not applied.'},'Apply Model Error');
    test = [];
  end

  analysis('setobjdata','prediction',handles,test)
else
  analysis('setobjdata','prediction',handles,[])  
end

analysis('toolbarupdate',handles)  %set buttons
analysis('updatestatusboxes',handles);

%delete model-specific plots we might have had open
h = getappdata(handles.analysis,'modelspecific');
close(h(ishandle(h)));
setappdata(handles.analysis,'modelspecific',[]);

%update plots
updatefigures(handles.analysis);     %update any open figures
figure(handles.analysis)

% --------------------------------------------------------------------
function modelviewer_Callback(h,eventdata,handles,varargin)
%Open model viewr

%TODO: dual cal/val support

modl = analysis('getobjdata','model',handles);
test = analysis('getobjdata','prediction',handles);

if ~isempty(modl) & strcmpi(modl.modeltype,'npls')
  test = [];  %FORCE ignoring of test if NPLS - modelviewer doesn't work with prediction structures from NPLS
end

%choose which item to view (model or test)
if ~isempty(test) & ~isempty(modl);
  obj = evriquestdlg('View results for calibration or validation samples?','View Results...','Calibration','Validation','Validation');
elseif ~isempty(test)
  obj = 'Validation';
else
  obj = 'Calibration';
end

switch obj
  case 'Calibration'
    x = analysis('getobjdata','xblock',handles);
  case 'Validation'
    x = analysis('getobjdata','validation_xblock',handles);
    for j=2:ndims(x);
      x.include{j} = test.detail.includ{j};
    end
    modl = test;
end

if ~isempty(x);
  %preprocess first
  ppx  = modl.detail.preprocessing{1};
  set(handles.analysis,'pointer','watch');
  try
    xp = preprocess('apply',ppx,x);
  catch
    set(handles.analysis,'pointer','arrow');
    rethrow(lasterror);
  end
  set(handles.analysis,'pointer','arrow');  
else
  xp = [];
end

%call modelviewer
child = [];
try
  child = modelviewer(modl,xp);
  setappdata(handles.modelviewer,'children',child);
catch
  if ~isempty(child) & ishandle(child)
    delete(child);
  end
end

% --------------------------------------------------------------------
function plotloads_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.plotloads.
% use only the icol variables in the dataset

modl = analysis('getobjdata','model',handles);

if nargin>3
  mode = varargin{1};
else
  %ask user for which mode to plot
  nmodes = size(modl.loads,1);
  validmodes = str2cell([repmat('Mode ',nmodes,1) num2str([1:nmodes]')]);
  for j=1:nmodes;
    if ~isempty(modl.detail.title{j,1})
      validmodes{j} = sprintf('%s: %s',validmodes{j},modl.detail.title{j,1});
    end
  end
  
  options = parafac_guifcn('options');
  switch options.loadsmenumode
    case 'uimenu'
      %ask using uicontextmenu
      cmenu = findobj(handles.analysis,'tag','plotloadscontext');
      if isempty(cmenu)
        cmenu = uicontextmenu;
        set(cmenu,'tag','plotloadscontext');
      end
      delete(allchild(cmenu));
      for j=1:length(validmodes);
        uimenu(cmenu,'label',validmodes{j},'callback',sprintf('parafac_guifcn(''plotloads_Callback'',gcbf,[],guidata(gcbf),%i);',j));
      end
      pos = get(handles.analysis,'position');
      set(cmenu,'position',[3 pos(4)])
      set(cmenu,'visible','on')
      return
      

    otherwise
      %ask by listdlg
      mode = listdlg('ListString',validmodes,'InitialValue',2,'SelectionMode','single','PromptString','Plot loadings on which mode:');
      if isempty(mode);
        %canceled
        return
      end
  end
  
end

if mode==1 & ~strcmp(lower(modl.modeltype),'parafac2')
  pca_guifcn('plotscores_Callback',handles.analysis,[],handles)
else  
  pca_guifcn('plotloads_Callback',handles.analysis,[],handles,mode)
end

%------------------------------------------------
function plotdatahat_Callback(h,eventdata,handles,varargin)

pca_guifcn('plotdatahat_Callback',h,eventdata,handles,varargin{:});

%------------------------------------------------
function plot3dcomp_Callback(h,eventdata,handles,varargin)

m = analysis('getobjdata','model',handles);
lds = m.loads;

if size(lds,1)~=3
  evrierrordlg('Loading Surfaces can only be plotted for data with exactly 3 modes.');
  return;
end

sz = m.datasource{1}.size;
k  = size(lds{2},2);
c = nan([sz([2 3]) k]); 
incl1 = m.detail.includ{2,1};
incl2 = m.detail.includ{3,1};
for j=1:k; 
  c(incl1,incl2,j) = lds{2}(:,j)*lds{3}(:,j)'; 
end
c = copydsfields(m,dataset(c),{[2 3] [1 2]});
if size(c,3)==1
  %if only one component? force it to be a 3-way
  c = cat(3,c,c);
  c = nindex(c,1,3);
end
c.label{3} = str2cell(sprintf('Component #%i\n',1:k));
c.title{3} = 'Recovered Component';

targfig = getappdata(handles.AnalysisToolbar, 'loadssurface_figure');
if isempty(targfig) | ~ishandle(targfig)
  targfig = figure('numbertitle','off','name','Loading Surfaces','integerhandle','off');
end
settings = {'update','figure',targfig};
plotgui(settings{:},c,'plottype','surface','plotby',3);

analysis('adopt',handles,targfig,'modelspecific');
setappdata(handles.AnalysisToolbar, 'loadssurface_figure',targfig);

drawnow;
evritip('parafac2dsurf','Press the "Rotate 3D" toolbar button (top toolbar) to allow rotation of this 3D surface.',2);

%--------------------------------------------------------------------
function plotcorecondia(h,eventdata,handles,varargin)
%NPCORCONDIA Corcondia plot

model = analysis('getobjdata','model',handles);

try
  conn2=model.detail.coreconsistency.consistency;
  if conn2<0,
    conn='<0';
  else
    conn = num2str(round(conn2));
  end
  info{1} = ['Core Consistency ',conn];
catch
  info{1} = 'Core Consistency';
end
info{2} = 'The core consistency plot shows the actual core elements (red & green) calculated from the PARAFAC loadings. Ideally, these should follow the blue line which is simply a superdiagonal core with ones on the diagonal (might change if one dimension < number of factors). The red elements are those that should ideally be non-zero and the green one those that should be zero. The core consistency is measuring the deviation from the blue target. The core consistency should not be used alone for assessing the number of components. It merely provides an indication. Especially, for simulated data (that follow the model perfectly with random iid noise) the core consistency is known to be less reliable than for real data.';

if ~isfieldcheck(model,'model.detail.coreconsistency.detail') | isempty(model.detail.coreconsistency.detail)
  erdlgpls('Core consistency not available','Core Consistency Error')
  return
end

%create figure and adopt
targfig = getappdata(handles.AnalysisToolbar, 'corecondia_figure');
if isempty(targfig) | ~ishandle(targfig)
  targfig = figure('numbertitle','off','name','Core Consistency');
  setappdata(handles.AnalysisToolbar, 'corecondia_figure',targfig);
end
analysis('adopt',handles,targfig,'modelspecific');

% Do the actual plotting
E = model.detail.coreconsistency.detail;
plot([E.I(E.bNonZero);E.I(E.bZero)],'b--','LineWidth',1)
hold on
plot(E.GG(E.bNonZero),'ro','LineWidth',2)
plot(length(E.bNonZero)+1:length(E.GG),E.GG(E.bZero),'gx','LineWidth',2)
hold off

set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
axis tight 
drawnow
grid off
hline('k--'); vline('k--');
title([info{1}],'color','blue');
legend({'Target';'Ideally non-zero';'Ideally zero'});
ylabel('Target (line) and Observed (markers)');

%--------------------------------------------------------------------
function splithalf_Callback(h, eventdata, handles, varargin)

model = analysis('getobjdata','model',handles);
x = analysis('getobjdata','xblock',handles);
ppx = getappdata(handles.preprocessmain,'preprocessing');
if ~isempty(ppx)
  x = preprocess('calibrate',ppx,x);
  model.options.preprocessing = [];
end
opts = getappdata(handles.analysis,'analysisoptions');
options = [];
options.display = 'off';
options.splitmethod = opts.validation.split;
[result,fig] = splithalf(x,model,options);
analysis('adopt',handles,fig,'modelspecific');

%--------------------------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.
% ssqtable value and pcsedit string updated by updatessqtable.

%TODO: consider use of pca_guifcn callback
handles = guidata(h);
modl = analysis('getobjdata','model',handles);
mytbl = getappdata(handles.analysis,'ssqtable');
if strcmp(getappdata(handles.analysis,'statmodl'),'loaded')
  n    = size(modl.loads{2,1},2);
  %set(handles.pcsedit,'String',int2str(n))
  %set(handles.ssqtable,'Value',n)
  setappdata(handles.pcsedit,'default',n)
elseif ~strcmp(getappdata(handles.analysis,'statdata'),'none')
  n    = getselection(mytbl,'rows');
  if strcmp(getappdata(handles.analysis,'statmodl'),'none')
    %no model - just preparing selection for new calc
    %set(handles.pcsedit,'String',int2str(n))
    setappdata(handles.pcsedit,'default',n)
    analysis('updatestatusboxes',handles);
    analysis('toolbarupdate',handles)  %set buttons
  elseif n == size(modl.loads{2,1},2);
    %User clicked back same number of PC's.
    %set(handles.pcsedit,'String',int2str(n))
    setappdata(handles.pcsedit,'default',n)
    setappdata(handles.analysis,'statmodl','calold');
    analysis('updatestatusboxes',handles);
    analysis('toolbarupdate',handles)  %set buttons
  else
    %set(handles.pcsedit,'String',int2str(n))
    setappdata(handles.pcsedit,'default',n)
    setappdata(handles.analysis,'statmodl','calnew');
    analysis('updatestatusboxes',handles);
    analysis('toolbarupdate',handles)  %set buttons
  end
end
updatessqtable(handles);

%--------------------------------------------------------------------
function pcsedit_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.pcsedit.
% Selects number of PCs in the editable text box.
% ssqtable value and pcsedit string updated by updatessqtable.

pca_guifcn('pcsedit_Callback',h,[],handles);

%TODO: review behavior when editing # of components

%--------------------------------------------------------------------
function updatefigures(h)
%update any open figures

eventdata = [];
varargin = [];

handles = guidata(h);
updatessqtable(handles);
if ~strcmp(getappdata(handles.analysis,'statmodl'),'none');
  modl = analysis('getobjdata','model',handles);
  %Modelviewer
  if isfield(handles,'modelviewer') & ~isempty(getappdata(handles.modelviewer,'children')) & ishandle(getappdata(handles.modelviewer,'children'))
    if ~isempty(modl) & size(modl.loads{1},2)>1
      pos = get(getappdata(handles.modelviewer,'children'),'position');
      if ishandle(getappdata(handles.modelviewer,'children'))
        delete(getappdata(handles.modelviewer,'children'));
      end
      modelviewer_Callback(handles.analysis, eventdata, handles, pos);
    else
      if ishandle(getappdata(handles.modelviewer,'children'))
        delete(getappdata(handles.modelviewer,'children'));
      end
    end
  end
  
  %update n-way loadings figures
  for j=1:size(modl.loads,1);
    if ~isempty(analysis('findpg',['loads' num2str(j)],handles,'*'))
      plotloads_Callback(handles.analysis,[],handles,j);
    end
  end

  if ~isempty(analysis('findpg','scores',handles,'*'))
    pca_guifcn('plotscores_Callback',handles.analysis,[],handles);
  end

  
  targfig = getappdata(handles.AnalysisToolbar, 'corecondia_figure');
  if ishandle(targfig)
    plotcorecondia(handles.analysis,[],handles);
  end
  
  %Imagegui
  if isfield(handles,'openimagegui') & ~isempty(getappdata(handles.openimagegui,'children')) & ishandle(getappdata(handles.openimagegui,'children'))
    if ~isempty(modl) & size(modl.loads{1},2)>1
      pos = get(getappdata(handles.openimagegui,'children'),'position');
      if ishandle(getappdata(handles.openimagegui,'children'))
        delete(getappdata(handles.openimagegui,'children'));
      end
      pca_guifcn('openimagegui_Callback',handles.analysis, eventdata, handles, pos);
    else
      if ishandle(getappdata(handles.openimagegui,'children'))
        delete(getappdata(handles.openimagegui,'children'));
      end
    end
  end
else %no model, close figures
  closefigures(handles)
end

%----------------------------------------
function closefigures(handles)
%close the analysis specific figures
htemp = [];
if isfield(handles,'openimagegui')
  htemp = [htemp handles.openimagegui];
end

%close n-way loadings figures
ids = {'datahat' 'eigenvalues' 'scores' 'loads' 'threshold' 'biplot' 'imagegui'};
for j=1:20;  %close everything up to 20 modes (there is virtually no way we'll have more than 20 mode data!)
  ids{end+1} = ['loads' num2str(j)];
end
for id = ids
  mylink = analysis('getobj',id{:},handles);
  if ~isempty(mylink)
    removeshareddata(mylink);
  end
end

for parent = [handles.modelviewer htemp];
  toclose = getappdata(parent,'children');
  toclose = toclose(ishandle(toclose));  %but only valid handles
  if ~isempty(toclose); close(toclose); end
  setappdata(parent,'children',[]);
end
if ishandle(getappdata(handles.analysis,'varcapfig')) & strcmp(getappdata(getappdata(handles.analysis,'varcapfig'),'figuretype'),'varcap');
  close(getappdata(handles.analysis,'varcapfig'));
  setappdata(handles.analysis,'varcapfig',[])
end

%delete model-specific plots we might have had open
h = getappdata(handles.analysis,'modelspecific');
close(h(ishandle(h)));
setappdata(handles.analysis,'modelspecific',[]);

%-------------------------------------------------
function updatessqtable(handles,pc)
%Don't use raw model technique in Parafac.
%SSQ info in modl.detail.ssq.percomponent.data

%NOTE: Not using getssqtable method on this table because of caching of
%      models. Should revisit when Analysis UI is upgraded to web.

options = parafac_guifcn('options');
modl = analysis('getobjdata','model',handles);
pcs = getappdata(handles.pcsedit,'default');
mytbl = getappdata(handles.analysis,'ssqtable');
model_type = getappdata(handles.analysis,'curanal');

if isempty(pcs)
  %Put a value in if one missing.
  pcs = 1;
  setappdata(handles.pcsedit,'default',pcs)
end

%Find max length of table.
maxoption = options.maximumfactors;
curlentable = mytbl.rowcount;
maxpc = max([maxoption, curlentable, pcs]);

% s     = [];
% format = getappdata(handles.analysis,'tableformat');

%Build table of "<not caclculated>"
% for kk=1:maxpc
%   s{kk} = [blanks(3 - length(num2str(kk))) num2str(kk) blanks(5) '<not calculated>'];
% end

newtbl = nan(maxpc,4);
newtbl = num2cell(newtbl);
newtbl = [newtbl repmat({'calc model'},maxpc,1)];

if strcmpi(getappdata(handles.analysis,'statmodl'),'none')
  if ~analysis('isloaded','xblock',handles)
    %Nothing loaded, set to one.
    pcs = 1;
  end
  %No model, update everything and return.
  %Update table data.
  mytbl.data = newtbl;
  %Make selection the current PC.
  setselection(mytbl,'rows',pcs);
  %set(handles.ssqtable,'String',s,'Value',pcs,'Enable','on')
  set(handles.pcsedit,'String',int2str(pcs),'Enable','on')
  return
end

if ~isempty(modl)
  cur_pc = size(modl.loads{2},2);
else
  cur_pc = [];
end

%Cache source should be cache form calc button unless model status is
%loaded, then cache source is appdata.modl.
curcachemodls = analysis('getobjdata','modelcache',handles);
if strcmpi(getappdata(handles.analysis,'statmodl'),'loaded') | isempty(curcachemodls)
  curcachemodls = {modl};
  pcs = size(curcachemodls{1}.loads{2});
  pcs = pcs(end);
  analysis('setobjdata','modelcache',handles,curcachemodls);
end

if ~isempty(curcachemodls)
  %Create vector and display string of cached pcs.
  for ii = 1:length(curcachemodls)
    tempcachemodl = curcachemodls{ii};
    tempcachemodlpcs = size(tempcachemodl.loads{2});
    cachepclist(ii) = tempcachemodlpcs(end);
    newtbl{tempcachemodlpcs(end),5} = 'view model';
    %s{tempcachemodlpcs(end)} = [blanks(3 - length(num2str(tempcachemodlpcs(end)))) num2str(tempcachemodlpcs(end)) blanks(5) '<view model>'];
  end
else
  cachepclist = [];
end

%If current default (pcs) is a cached model,
%display it's ssq information.
if any(cachepclist == pcs)% & ~strcmp(model_type,'parafac2')
  modl = curcachemodls{find(cachepclist == pcs)};
  newtbl(1:pcs,[1 2 3 4]) = num2cell(modl.detail.ssq.percomponent.data(:,[2 3 5 6]));
  %ssqdata = [(1:pcs)' modl.detail.ssq.percomponent.data(:,2:3) modl.detail.ssq.percomponent.data(:,5:6)];
%   for jj = 1:pcs
%     s{jj}   = sprintf(format,ssqdata(jj,:));
%   end
  if strcmpi(getappdata(handles.analysis,'statmodl'),'loaded')
    %If model status loaded then allow only loaded view.
    %s = s(1:pcs);
    newtbl = newtbl(1:pcs,:);
  end
end

if ~isempty(cur_pc)
  newtbl{cur_pc,5} = 'current';
end

%Update table data.
mytbl.data = newtbl;
%Make selection the current PC.
setselection(mytbl,'rows',pcs)

%set(handles.ssqtable,'String',s,'Value',pcs,'Enable','on')
set(handles.pcsedit,'String',int2str(pcs),'Enable','on')
setappdata(handles.pcsedit,'default',pcs);

%----------------------------------------------------
function  optionschange(h)
