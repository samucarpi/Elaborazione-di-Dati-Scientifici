function varargout = pca_guifcn(varargin)
%PCA_GUIFCN PCA analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

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
function gui_init(h,eventdata,handles,varargin)

%create toolbar
[atb abtns] = toolbar(handles.analysis, 'pca','');
handles  = guidata(handles.analysis);
%Enable correct buttons.
analysis('toolbarupdate',handles)  %set buttons

%change pc edit label.
set(handles.pcseditlabel,'string','Number PCs:')

%change pc edit box to text box.
set(handles.pcsedit,'style','text')


mytbl = getappdata(handles.analysis,'ssqtable');

mytbl = ssqsetup(mytbl,{'Eigenvalue<br>of Cov(X)' '% Variance<br>This PC' '% Variance<br>Cumulative' ' '},...
  '<b>&nbsp;&nbsp;&nbsp;PC',{'%4.2e' '%6.2f' '%6.2f' ''},1);

header = 'Percent Variance Captured by PCA Model (* = suggested)';

set(handles.tableheader,'string',header,'HorizontalAlignment','center');

%change the name of the "factors" in the crossvalidate GUI
crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'PCs');

%turn on valid crossvalidation
%enable_crossvalgui must be set before crossvalgui('disable',cvgui); call.
setappdata(handles.analysis,'enable_crossvalgui','on');

%Check for option enabled objects.
options = pca_guifcn('options');

%Auto select button visibility.
if exist('choosecomp.m','file')==2 && strcmp(options.autoselectcomp,'on')
  setappdata(handles.analysis,'autoselect_visible',1)
else
  setappdata(handles.analysis,'autoselect_visible',0)
end

%Add view selections to dropdown.
panelinfo.name = 'SSQ Table';
panelinfo.file = 'ssqtable';
panelmanager('add',panelinfo,handles.ssqframe)

handles = guihandles(handles.analysis);
guidata(handles.analysis,handles);

%general updating
analysis('updatestatusboxes',handles)
updatefigures(handles.analysis)
updatessqtable(handles)

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
%Change pcsedit back to defualt style.
set(handles.pcsedit,'style','edit')

%Clear table.
mytbl = getappdata(handles.analysis,'ssqtable');
clear(mytbl,'all');

setappdata(handles.analysis,'autoselect_visible',0)

%Set crossval gui to default.
setappdata(handles.analysis,'enable_crossvalgui','on');

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

closefigures(handles);

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)
%Many _guifcn call here to handle imagegui.
modl = analysis('getobjdata','model',handles);

%assume imagegui disabled
set(findobj(handles.analysis,'tag','openimagegui'),'enable','off')
if ~isempty(modl) & ismember(getappdata(handles.analysis,'statmodl'),{'loaded','calold'})...
    & isfield(modl,'loads') & size(modl.loads{1},2)>1 & isfield(modl.datasource{1},'type') & strcmp(modl.datasource{1}.type,'image')
  %unless these conditions are met:
  % 1) we have a model
  % 2) it has > 1 PC
  % 3) it was built on an image DSO
  set(findobj(handles.analysis,'tag','openimagegui'),'enable','on','visible','on')
end

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)

%two-way x
out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

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

options = pca_guifcn('options');
statmodl = lower(getappdata(handles.analysis,'statmodl'));

if strcmp(statmodl,'calnew') & ~analysis('isloaded','rawmodel',handles)
  %trying to change # of components but no rawmodel = recalculate from
  %scratch
  statmodl = 'none';
end

switch statmodl
  case {'none'}
    %prepare X-block for analysis
    x = analysis('getobjdata','xblock',handles);

    if isempty(x.includ{1});
      erdlgpls('All samples excluded. Can not calibrate','Calibrate Error');
      return
    end
    if isempty(x.includ{2});
      erdlgpls('All variables excluded. Can not calibrate','Calibrate Error');
      return
    end

    if mdcheck(x);
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
      analysis('setobjdata','xblock',handles,x)
    end

    preprocessing = {getappdata(handles.preprocessmain,'preprocessing')};

    [cvmode,cvlv,cvsplit,cviter] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
    if ~strcmp(cvmode,'none')
      maxpc   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors cvlv]);
    else  %no cross-val method? Don't let the slider limit the # of LVs
      maxpc   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors]);
    end
    pc   = getappdata(handles.pcsedit,'default');

    opts = getappdata(handles.analysis,'analysisoptions');
    if isempty(opts)
      opts = pca('options');
    end
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.preprocessing = preprocessing;

    %don't allow > # of evs (in fact, consider this a reset of default)
    if isempty(pc) | pc>maxpc | pc<1;
      if isempty(pc) && exist('choosecomp.m','file')==2 && strcmp(options.autoselectcomp,'on') & strcmp(opts.algorithm,'robustpca')
        maxpc = min(50,ceil(maxpc*0.8));   %if robust and doing automatic selection, limit to some % of maximum
        pc = maxpc;  %if robust and doing automatic selection, start at maximum
      else
        pc = 1;
      end
    end;

    if ~strcmp(opts.algorithm,'robustpca')
      opts.rawmodel      = 1;
      %calculate all loads and whole SSQ table
      rawmodl    = pca(x,maxpc,opts);
      %calculate sub-set of that raw model (with limits, etc)
      modl       = pca(x,pc,rawmodl,opts);
    else
      %Robust mode? don't use rawmodel calls
      opts.rawmodel = 0;
      modl = pca(x,pc,opts);
      rawmodl = [];
    end
    modl.detail.ssq = modl.detail.ssq(1:min(maxpc,size(modl.detail.ssq,1)),:);
    modl.detail.eigsnr = getappdata(handles.analysis,'eigsnr');  %copy eigenvector snr from GUI (if previously calculated)

    %Do cross-validation
    cvinfo = [];
    if ~strcmp(cvmode,'none')
      [modl,success] = crossvalidate(handles.analysis,modl);

      if success;
        cvinfo = copycvfields(modl);
        if ~isempty(rawmodl);
          rawmodl = copycvfields(modl,rawmodl);
        end
      end
    end

    %UPDATE GUI STATUS
    %set status windows
    setappdata(handles.analysis,'statmodl','calold');
    analysis('setobjdata','model',handles,modl);
    analysis('setobjdata','rawmodel',handles,rawmodl);

    %check if we need to run autoselect and/or autoexclude
    aeopts  = [];
    aeopts.autoselectcomp = 'off';  %default is autoselectcomp is OFF
    %Auto Select button clears pcsedit appdata so check appdata see if
    %empty. If NOT empty, user has manually selected the # of PCs so keep
    %that until they clear with "AutoSelect"
    if isempty(getappdata(handles.pcsedit,'default')) && exist('choosecomp.m','file')==2 && strcmp(options.autoselectcomp,'on')
      %Make auto selection of components.
      selectpc = choosecomp(modl);
      if ~isempty(selectpc) && pc~=selectpc
        %Recalculate model
        pc = selectpc;
        if ~isempty(rawmodl)
          %recalculate using rawmodl
          modl       = pca(x,pc,rawmodl,opts);
        else
          %No rawmodel model? don't use rawmodel calls!
          opts.rawmodel = 0;
          modl = pca(x,pc,opts);
        end
        if ~isempty(cvinfo)
          for fyld = fieldnames(cvinfo)';
            modl.detail.(fyld{:}) = cvinfo.(fyld{:});
          end
        end
        modl.detail.ssq = modl.detail.ssq(1:min(maxpc,size(modl.detail.ssq,1)),:);
        modl.detail.eigsnr = getappdata(handles.analysis,'eigsnr');  %copy eigenvector snr from GUI (if previously calculated)
        analysis('setobjdata','model',handles,modl);
      end
      aeopts.autoselectcomp = options.autoselectcomp;  %if we got here, turn autoselect ON
    end
    
    %Check for autoexclude action
    if exist('autoexclude.m','file')==2 && strcmp(options.autoexclude,'on')
      modl    = autoexclude(modl,x,[],aeopts);
      if ~isempty(cvinfo)
        for fyld = fieldnames(cvinfo)';
          modl.detail.(fyld{:}) = cvinfo.(fyld{:});
        end
      end
      analysis('setobjdata','model',handles,modl);
      analysis('setobjdata','rawmodel',handles,[]);
      %get # of PCs used NOW
      pc = size(modl.loads{2},2);
      
    end
    
    updatessqtable(handles,pc);

  case {'calnew'}
    %change of # of components only
    x       = analysis('getobjdata','xblock',handles);
    rawmodl = analysis('getobjdata','rawmodel',handles);
    mytbl = getappdata(handles.analysis,'ssqtable');

    %minpc   = get(handles.ssqtable,'Value'); %number of PCs
    minpc   = getselection(mytbl,'rows');
    [cvmode,cvlv] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
    if ~strcmp(cvmode,'none')
      maxpc   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors cvlv]);
    else  %no cross-val method? Don't let the slider limit the # of LVs
      maxpc   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors]);
    end

    opts = rawmodl.detail.options;
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.rawmodel      = 1;

    modl               = pca(x,minpc,rawmodl,opts);
    modl.detail.ssq    = modl.detail.ssq(1:min(maxpc,size(modl.detail.ssq,1)),:);

    modl = copycvfields(rawmodl,modl);
    
    %Check threshold.
    if exist('autoexclude.m','file')==2 && strcmp(options.autoexclude,'on')
      aeopts  = struct('autoselectcomp','off');  %autoselect MUST be off if we're here
      modl    = autoexclude(modl,x,[],aeopts);
    end
    
    setappdata(handles.analysis,'statmodl','calold');
    analysis('setobjdata','model',handles,modl);
    updatessqtable(handles,minpc);
end

%apply model to test/validation data (if present)
if analysis('isloaded','validation_xblock',handles)
  %apply model to new data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
  if isempty(x); return; end  %some cancel action
  
  opts = getappdata(handles.analysis,'analysisoptions');
  if isempty(opts)
    opts = pca('options');
  end
  opts.display       = 'off';
  opts.plots         = 'none';
  opts.rawmodel      = 0;

  try
    test = pca(x,modl,opts);
  catch
    erdlgpls({'Error applying model to validation data.',lasterr,'Model not applied.'},'Apply Model Error');
    test = [];
  end
    
  analysis('setobjdata','prediction',handles,test);

else
  %no test data? clear prediction
  analysis('setobjdata','prediction',handles,[]);  
end

analysis('updatestatusboxes',handles);
analysis('toolbarupdate',handles)  %set buttons

%delete model-specific plots we might have had open
h = getappdata(handles.analysis,'modelspecific');
close(h(ishandle(h)));
setappdata(handles.analysis,'modelspecific',[]);

%update plots
updatefigures(handles.analysis);     %update any open figures
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

success  = 0;  %indicates failure
cvopts = crossval('options');
cvopts.plots = 'none';
cvopts.display = 'off';

switch lower(modl.modeltype)
  case 'pca'
    x = analysis('getobjdata','xblock',handles);
    y  = [];
    cvopts.preprocessing = {modl.detail.preprocessing{1} []};
  case 'mpca'
    x = analysis('getobjdata','xblock',handles);
    y  = [];
    cvopts.preprocessing = {modl.detail.preprocessing{1} []};

    incl = x.include;
    options = mpca('options');
    x  = unfoldmw(x,options.samplemode);

    if length(incl{2})<size(x,2);
      %gscale (often used with MPCA) doesn't work if any variables are
      %excluded. If found to be so, apply preprocessing now and skip during
      %cross-validation.
      evritip('mpcacrossvalexcluded','MPCA preprocessing can not be performed during cross-validation if variables have been excluded. Preprocessing will be applied before cross-validation.\n\nCross-validation results may be biased by outliers.',1);
      x = preprocess('apply',cvopts.preprocessing{1},x);
      cvopts.preprocessing{1} = [];
    end
end

if length(x.include{2})>25;
  cvopts.pcacvi = {'con' min(10,floor(sqrt(length(x.include{2}))))};
else
  cvopts.pcacvi = {'loo'};
end

cvgui = getappdata(h,'crossvalgui');
[cv,lv,split,iter,cvi] = crossvalgui('getsettings',cvgui);

if isfieldcheck('modl.detail.options.algorithm',modl) & ~isempty(strfind(lower(modl.detail.options.algorithm),'robust'))
  default = getappdata(0,'robust_crossval_default');
  if isempty(default); default = 'All Data'; end
  answer = evriquestdlg('Robust cross-validation is not fully supported. Do you want to perform cross-validation using all data, exclude the currently flagged outliers, or abort cross-validation?','Robust Cross-Validation','All Data','Exclude Outliers','Abort',default);
  switch answer
    case 'Exclude Outliers'
      x.include{1} = modl.detail.includ{1};
    case 'Abort'
      return
  end
  setappdata(0,'robust_crossval_default',answer);
else
  %non-robust... 
  %Check if the CV GUI had settings forced to it by loading or initializing.
  %If so, and if data is large (defined below), then ask user if they really
  %wanted to cross-validate...
  %(note: we don't do this for robust models to avoid having
  %too many questions be asked. If the user doesn't want to automatic
  %cross-validate with robust mode enabled, they can cancel out of the
  %above dialog)
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

end

m  = length(x.includ{1});
n  = length(x.includ{2});
lv = min([lv m n]);
try
  modl = crossval(x,y,modl,cvi,lv,cvopts);
catch
  erdlgpls({'Unable to perform cross-valiation - Aborted';lasterr},'Cross-Validation Error');
  return
end  

success  = 1;  %got here = success

%--------------------------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.

handles = guidata(h);
modl    = getsubmodel('model',handles);
mytbl   = getappdata(handles.analysis,'ssqtable');

if ~analysis('isloaded','xblock',handles) & ~isempty(modl)
  %calibration data not loaded? - do NOT change # of components
  n    = size(modl.loads{2,1},2);
  set(handles.pcsedit,'String',int2str(n))
  setselection(mytbl,'rows',n);
  %set(handles.ssqtable,'Value',n)
  setappdata(handles.pcsedit,'default',n)
else
  %allow change of # of components, if data or model are loaded then adjust
  %statmodl accordingly.
  n = getselection(mytbl,'rows');
  %n    = get(handles.ssqtable,'Value');
  set(handles.pcsedit,'String',int2str(n))
  setappdata(handles.pcsedit,'default',n)
  if ~isempty(modl) & (~isfield(modl,'loads') | n == size(modl.loads{2,1},2));
    %User clicked back same number of PC's.
    setappdata(handles.analysis,'statmodl','calold');
  elseif ~isempty(modl) & analysis('isloaded','xblock',handles)
    %new PCs for existing model
    setappdata(handles.analysis,'statmodl','calnew');
  end
  analysis('updatestatusboxes',handles);
  analysis('toolbarupdate',handles)  %set buttons
end

%--------------------------------------------------------------------
function pcsedit_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.pcsedit.
% Selects number of PCs in the editable text box.

modl    = getsubmodel('model',handles);
rawmodl = getsubmodel('rawmodel',handles);
mytbl   = getappdata(handles.analysis,'ssqtable');

n    = get(handles.pcsedit,'String');
if ~isempty(n)
  n = fix(str2num(n));
end

if n<1
  n = 1;
end

maxtblrows = mytbl.rowcount;

if ~analysis('isloaded','xblock',handles)
  if ~isempty(modl)
    %calibration data not loaded? - do NOT change # of components
    n    = size(modl.loads{2,1},2);
    set(handles.pcsedit,'String',int2str(n))
    setselection(mytbl,'rows',n);
    setappdata(handles.pcsedit,'default',n)
  else
    %Nothing loaded, allow change if table will accept.
    if n>maxtblrows
      n = maxtblrows;
    end
    setselection(mytbl,'rows',n);
    setappdata(handles.pcsedit,'default',n)
  end
else
  %allow change of # of components
  if ~isempty(n);
    if length(n)>1; n = n(1); end;       %only one number permitted
    if ~isempty(rawmodl) 
      maxlv = size(rawmodl.loads{2,1},2);
    else
      maxlv = mytbl.rowcount;
    end
    if n < 1 | n > maxlv ;     %invalid # of pcs?
      n = [];
    end
  end;
  if ~isempty(n);
    if isempty(modl)
      %Only data loaded, allow change.
      if n>maxtblrows
        n = maxtblrows;
      end
      setselection(mytbl,'rows',n);
      setappdata(handles.pcsedit,'default',n)
    else
      if n == size(modl.loads{2,1},2);
        %User clicked back same number of PC's.
        setselection(mytbl,'rows',n);
        set(handles.pcsedit,'String',int2str(n))
        setappdata(handles.pcsedit,'default',n)
        setappdata(handles.analysis,'statmodl','calold');
        analysis('updatestatusboxes',handles);
        analysis('toolbarupdate',handles)  %set buttons
      else
        setappdata(handles.pcsedit,'default',n)
        setappdata(handles.analysis,'statmodl','calnew');
        analysis('updatestatusboxes',handles)
        analysis('toolbarupdate',handles)  %set buttons
        if ~strcmp(getappdata(handles.analysis,'curanal'),'mcr')
          fn = analysistypes(getappdata(handles.analysis,'curanal'),3);
          feval(fn,'updatessqtable',handles,n);
        else
          %do NOT update the ssqtable, simply reset value
          setselection(mytbl,'rows',n)
        end
      end
    end
  else    %invalid entry, use value from ssqtable
    n    = getselection(mytbl,'rows');
    set(handles.pcsedit,'String',int2str(n))
  end;
end

%--------------------------------------------------------------------
function updatefigures(h)
%update any open figures

eventdata = [];

handles = guidata(h);

if ~strcmp(getappdata(handles.analysis,'statmodl'),'none');
  
  if ~isempty(analysis('findpg','eigenvalues',handles,'*'))
    ploteigen_Callback(handles.ploteigen, eventdata, handles);
  end
  if ~isempty(analysis('findpg','loads',handles,'*'))
    plotloads_Callback(handles.plotloads, eventdata, handles, [], []);
  end
  
  %update specific class loadings figures
  modl = analysis('getobjdata','model',handles);
  if ~isempty(modl)
  if ~isempty(modl.detail.class{2,1})
    for j=1:size(modl.detail.classlookup{2,1},1)+1;  %always do one extra in case zero wasn't in DSO but is in loadings
      if ~isempty(analysis('findpg',sprintf('loadsclass%i',j),handles,'*'))
        plotloads_Callback(handles.analysis,[],handles,2,j);
      end
    end
  end
  end
  
  if ~isempty(analysis('findpg','datahat',handles,'*'))
    plotdatahat_Callback(handles.analysis, eventdata, handles, true);  %added input "true" forces update without "which to show" GUI
  end
  if ishandle(getappdata(handles.analysis,'varcapfig')) & strcmp(getappdata(getappdata(handles.analysis,'varcapfig'),'figuretype'),'varcap');
    varcapbuttoncall(0,[], handles);    %h of zero is auto-update mode of varcapbuttoncall
  end
  if ~isempty(analysis('findpg','scores',handles,'*'))
    plotscores_Callback(handles.plotscores, eventdata, handles);
  end
  if ~isempty(analysis('findpg','biplot',handles,'*'))
    biplot_Callback(handles.biplot, eventdata, handles);
  end
  if ~isempty(analysis('findpg','threshold',handles,'*'))
    plsda_guifcn('threshold_Callback',handles.threshold, eventdata, handles);
  end
  %TODO: modify to look for openimagegui shared data (when openimagegui is updated)
  if isfield(handles,'openimagegui') & ~isempty(getappdata(handles.openimagegui,'children')) & ishandle(getappdata(handles.openimagegui,'children'))
    modl = analysis('getobjdata','model',handles);
    if ~isempty(modl) & size(modl.loads{1},2)>1
      pos = get(getappdata(handles.openimagegui,'children'),'position');
      if ishandle(getappdata(handles.openimagegui,'children'))
      delete(getappdata(handles.openimagegui,'children'));
      end
      openimagegui_Callback(handles.analysis, eventdata, handles, pos);
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

%TODO: match openimagegui itemType
%search for item types to be cleared (including 'loadsclass_' items)
ids = {'eigenvalues' 'scores' 'loads' 'threshold' 'biplot' 'imagegui' 'datahat'};
list = getshareddata(handles.analysis);
if ~isempty(list)
  list = list(:,1);
  for j=1:length(list);
    thistype = list{j}.properties.itemType;
    if ~isempty(regexp(list{j}.properties.itemType,'loadsclass*','once')) | ismember(thistype,ids)
      removeshareddata(list{j});
    end
  end
end

if ishandle(getappdata(handles.analysis,'varcapfig')) & strcmp(getappdata(getappdata(handles.analysis,'varcapfig'),'figuretype'),'varcap');
  close(getappdata(handles.analysis,'varcapfig'));
  setappdata(handles.analysis,'varcapfig',[])
end

%delete model-specific plots we might have had open
temp = getappdata(handles.analysis,'modelspecific');
close(temp(ishandle(temp)));
setappdata(handles.analysis,'modelspecific',[]);


% --------------------------------------------------------------------
function plotdatahat_Callback(h,eventdata,handles,varargin)

%grab data
modl = getsubmodel('model',handles);
data = analysis('getobjdata','xblock',handles);
test = analysis('getobjdata','validation_xblock',handles);

%Choose block to analyze
if ~isempty(test) 
  if isempty(data);
    use = 'Validation';
  else
    use = '';
  end
else
  use = 'Calibration';
end

%get previous defaults
defaults = getappdata(handles.analysis,'plotdatadefaults');
if ~isempty(defaults) & isempty(varargin);
  defaults.defaults = true;
end

if isempty(use)
  if isempty(varargin) | ~isfield(defaults,'block') | isempty(defaults.block);
    use = evriquestdlg('View Calibration data, Test/Validation data, or Both?','X_Hat Data','Calibration','Validation','Both','Both');
  else
    use = defaults.block;
  end
end
switch lower(use)
  case 'calibration'
    %data is already just data...
    linkdso = (1:ndims(data))';
    
  case 'validation'
    data = matchvars(modl,test);
    linkdso = (1:ndims(data))';
    
  otherwise
    temp = [data;matchvars(modl,test)];
    
    %choose a class set to make into the cal/val set
    cls = temp.class(1,:);
    clsempty = cellfun('isempty',cls);
    clsset = min(find(clsempty));
    if isempty(clsset)
      clsset = length(cls)+1;
    end
    temp.class{1,clsset} = [ones(1,size(data,1)) ones(1,size(test,1))*2];
    temp.classlookup{1,clsset} = {1 'Calibration'; 2 'Validation'};
    temp.classname{1,clsset} = 'Calibration/Validation';
    
    data = temp;

    linkdso = (2:ndims(data))';

end

%ask user for which info to show
[toplot,sel] = plotdatahat(modl,data,defaults);
if isempty(toplot);
  return;
end
sel.block = use;
setappdata(handles.analysis,'plotdatadefaults',sel)

%determine which items we're showing and how to label plot
t = {};
if sel.data
  t = {'Data'};
end
if sel.datahat
  t{end+1} = 'Data Estimate';
end
if sel.residuals
  t{end+1} = 'Residuals';
end
t = sprintf('%s+',t{:});
t = t(1:end-1);

%create link data
myprops = [];
myprops.datahatsettings = sel;
myprops.figurename = [t getappdata(handles.analysis,'figname_info')];

myid = analysis('setobjdata','datahat',handles,toplot,myprops);

%link to base objects (as appropriate)
for obj = {'xblock' 'validation_xblock'}
  xdataid = analysis('getobj',obj{:},handles);
  if ~isempty(xdataid)
    %link data back to x-block
    linkmap = [linkdso linkdso];
    linkshareddata(xdataid,'add',myid,'analysis',struct('linkmap',linkmap,'isdependent',1));
    linkshareddata(myid,'add',xdataid,'analysis',struct('linkmap',linkmap));
  end
end

%do plot, if none exist
fighandle = analysis('findpg',myid,handles,'*');
if isempty(fighandle);
  if ndims(toplot)==3;
    plottype = 'surface';
    axlines = [0 0 0];
  else
    plottype = '';
    axlines = [0 0 0];
    if ~sel.data & ~sel.datahat
      axlines(2) = 1;
    end
  end
  switch lower(modl.modeltype) 
    case 'parafac2'
      plotsettings = {'plotby',1,'noinclude',1,'plottype',plottype,'viewaxislines',axlines};
    otherwise
      plotsettings = {'rows','noinclude',1,'plottype',plottype,'viewaxislines',axlines};
  end
  myid.properties.plotsettings = plotsettings;

  plotgui('new',myid,plotsettings{:});
  if ndims(toplot)==3;
    view([-43 36])
    plotgui('update')
  end

else
  figure(  min(double(fighandle)) );
end

% --------------------------------------------------------------------
function ploteigen_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ploteigen.

modl = analysis('getobjdata','model',handles);

if ~ismember(lower(modl.modeltype),{'batchmaturity' 'knn' 'ann' 'annda' 'anndl' 'anndlda' 'lregda'}) & (~isfieldcheck(modl,'modl.detail.ssq') | isempty(modl.detail.ssq))
  fighandle = analysis('findpg','eigenvalues',handles,'*');
  close(fighandle);
  return
end

epopts.plots = 'none';
a = ploteigen(modl, epopts);
if isempty(a)
  return;
end

if ismember(lower(modl.modeltype),{'lregda'})
  ptitle = 'Model Parameters';
else
  ptitle = 'Model Statistics';
end
figname = [ptitle getappdata(handles.analysis,'figname_info')];

%- - - - - - - - - - - - - - - - - - - - - - - - 
%add name and callback fns
myprops = [];
myprops.itemType = 'eigenvalues';   %Name a property so we can search on it.
myprops.figurename = figname;
myprops.helplink              = 'Model Building: Plotting Eigenvalues';

%set object data (or update)
myid = analysis('setobjdata','eigenvalues',handles,a,myprops);

%See if there is a valid plotgui subscriber.
fighandle = analysis('findpg',myid,handles,'*');
if isempty(fighandle)
  str = a.label{2};
  slct = [];
  for i = 1:size(str,1)
    if strfind(str(i,:),'Classification Error')
      slct = [slct i];
    end
  end
  if length(slct)>2
    slct = slct(end-1:end);
  end
  defaultselection = {0 slct};
  if isempty(defaultselection{2});
    defaultselection = {0 setdiff(strmatch('RMSE',a.label{2})',strmatch('RMSE ',a.label{2})')};  %RMSECs, RMSECVs
    if isempty(defaultselection{2});
      defaultselection = {0 1};
    end
  end
  if length(defaultselection{2})>20
    defaultselection = {0 defaultselection{2}(1:2)};
  end
  
  plotsettings = {'name',figname,'plotby',2,'AxisMenuValues',defaultselection, ...
    'noselect',1,'linestyle','+-','plotcommand','ploteigenlimits(targfig);'};
  myid.properties.plotsettings = plotsettings;
  hh = plotgui('new',myid,plotsettings{:},'controlby',getappdata(handles.analysis,'plotgui'));
  feval('plotgui', 'dockcontrols', hh );
else
  figure(min(double(fighandle)));
end

% --------------------------------------------------------------------
function plotscores_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.plotscores.
%I/O: plotscores_Callback(h,[],handles,extracmds)
%  where extracmds is cell to be expanded and passed to plotgui

modl = analysis('getobjdata','model',handles);
prediction = analysis('getobjdata','prediction',handles);
analopts = analysis('options');

sct  = strcmp(get(handles.showcalwithtest,'checked'),'on'); %1 if show cal w/ test
showerrorbars = getfield(analopts,'showerrorbars');
showautoclass = getfield(analopts,'showautoclassscores');

forceautoclass = getappdata(handles.analysis,'forceautoclass');
if isempty(forceautoclass); forceautoclass = 0; end

asca_submodel = getappdata(handles.analysis,'asca_submodel');
mlsca_submodel = getappdata(handles.analysis,'mlsca_submodel');

%check if we're plotting predictions on an image - by default, don't show cal if pred is image
if isempty(analysis('findpg',analysis('getobj','scores',handles))) & sct & ~isempty(prediction) & strcmp(prediction.datasource{1}.type,'image')
  %if SCT is on, and prediction is on an image and modl is not an image, turn OFF SCT
  sct = 0;
  analysis('showcalwithtest',handles.analysis,[],handles);  %toggle in main GUI too
end

blockshown = [(sct | isempty(prediction)) ~isempty(prediction)];  %boolean vector showing if cal and test are shown
setappdata(handles.showcalwithtest,'shown',blockshown);

spopts       = []; %SK Options for plotscores.
spopts.sct   = sct;
spopts.plots = 'none';
spopts.autoclass = forceautoclass;
spopts.reducedstats = analopts.reducedstats;
spopts.asca_submodel = asca_submodel;
spopts.mlsca_submodel = mlsca_submodel;

a = plotscores(modl,prediction,spopts); %Get dataset from plotscores.

if isempty(strmatch('AutoClasses',a.classname(1,:)));
  %no autoclasses found
  forceautoclass = false;
  setappdata(handles.analysis,'forceautoclass',false)
end
  

extracmds = [];
if ~isempty(varargin)
  extracmds = varargin{1};
end
if ~isa(extracmds,'cell');
  extracmds = {extracmds};
end
if isempty(extracmds) | (length(extracmds)==1 & isempty(extracmds{1}))
  extracmds  = cell(0);
end

%- - - - - - - - - - - - - - - - - - - - - - - - 
%choose which functions have special callbacks
tcon_enable = 'on';
qcon_enable = 'on';
tconref_enable = 'on';
qconref_enable = 'on';
showconflimits = 1;
switch getappdata(handles.analysis,'curanal')
  case 'mpca'
    cbcmd = {'pca' 'pca' 'pca' 'pca'};
    btcmd = {'mpca' 'mpca' 'pca' 'pca'};
    %FIXME: add special callback for selection
    %     setappdata(handles.plotscores,'selectionchangecallback',['mpca_guifcn(''scoresselectionchange'',targfig,timestamp)'])  %mpca
  case 'simca'
    cbcmd = {'pca' 'pca' 'pca' 'pca'};
    btcmd = {'pca' 'pca'   'pca' 'pca'};
  case 'mlr'
    extracmds = [extracmds {'showlimits' 1}];
    cbcmd = {'pca' 'pca' 'pca' 'pca'};
    btcmd = {'pca' 'pca'   'pca' 'pca'};
    tcon_enable = 'off';
    qcon_enable = 'off';
    tconref_enable = 'off';
    qconref_enable = 'off';
  case 'plsda'
    cbcmd = {'pca' 'plsda' 'pca' 'pca'};
    btcmd = {'pca' 'pca'   'pca' 'pca'};
  case 'mcr'
    cbcmd = {'pca' 'pca' 'mcr' 'pca'};
    btcmd = {'pca' 'pca' 'pca' 'pca'};
    tcon_enable = 'off';
    tconref_enable = 'off';
  case {'asca' 'knn'}
    cbcmd = {'pca' 'pca' 'pca' 'pca'};
    btcmd = {'pca' 'pca' 'pca' 'pca'};
    tcon_enable = 'off';
    qcon_enable = 'off';
    tconref_enable = 'off';
    qconref_enable = 'off';
    showconflimits = 0;
  case 'parafac'
    cbcmd = {'pca' 'pca' 'pca' 'pca'};
    btcmd = {'pca' 'pca' 'pca' 'pca'};
    tcon_enable = 'off';
    qcon_enable = 'on';
    tconref_enable = 'off';
    qconref_enable = 'off';
  case 'parafac2'
    cbcmd = {'pca' 'pca' 'pca' 'pca'};
    btcmd = {'pca' 'pca' 'pca' 'pca'};
    tcon_enable = 'off';
    qcon_enable = 'on';
    tconref_enable = 'off';
    qconref_enable = 'off';
  case 'batchmaturity'
    extracmds = [extracmds {'showlimits' 1}];
    cbcmd = {'pca' 'pca' 'pca' 'pca'};
    btcmd = {'pca' 'pca' 'pca' 'pca'};
  case {'tsne' 'umap'}
    cbcmd = {'pca' 'pca' 'pca' 'pca'};
    btcmd = {'pca' 'pca' 'pca' 'pca'};
    tcon_enable = 'off';
    qcon_enable = 'off';
    tconref_enable = 'off';
    qconref_enable = 'off';
    showconflimits = 0;
  case 'clsti'
    cbcmd = {'pca' 'pca' 'pca' 'pca'};
    btcmd = {'pca' 'pca' 'pca' 'pca'};
    tcon_enable = 'off';
    qcon_enable = 'on';
    tconref_enable = 'off';
    qconref_enable = 'off';
    showconflimits = 0;
  otherwise
    cbcmd = {'pca' 'pca' 'pca' 'pca'};
    btcmd = {'pca' 'pca' 'pca' 'pca'};
end

if ~analysis('isloaded','xblock',handles) & ~analysis('isloaded','validation_xblock',handles)
  qcon_enable = 'off';
  qconref_enable = 'on';
  data_enable = 'off';
  extracmds = {extracmds{:} 'noinclude',1};     %loaded and no data? don't allow exclud changes (note: overrides input by varargin!)
else
  data_enable = 'on';
  if ~ismember('noinclude',extracmds(1:2:end))  %as long as caller didn't already set the noinclude flag,
    extracmds = {extracmds{:} 'noinclude',0};     %make sure noinclude is OFF (in case we turned it off before)
  end
end

numtag = [num2str(fix(double(handles.analysis)*10000))];
items = [];
items = setfield(items,['qcon' numtag],{...
  'style','pushbutton','string','Q con', ...
  'tooltip','Show Q contributions for selected samples.',...
  'userdata',double(handles.analysis),...
  'enable',qcon_enable,'visible','on',...
  'callback',[btcmd{1} '_guifcn(''scoresqconbuttoncall'',gcbo,[],guidata(get(gcbo,''userdata'')))']});
items = setfield(items,['qconref' numtag],{...
  'style','pushbutton','string','Q con Ref.',  ...
  'tooltip','Choose reference sample(s) for relative Q contributions.',...
  'userdata',double(handles.analysis),...
  'enable',qconref_enable,'visible','on',...
  'callback',[btcmd{2} '_guifcn(''scoressetconref'',gcbo,[],guidata(get(gcbo,''userdata'')),''Q'')']});
items = setfield(items,['tcon' numtag],{...
  'style','pushbutton','string','T con',  ...
  'tooltip','Show T2 contributions for selected samples.',...
  'userdata',double(handles.analysis),...
  'enable',tcon_enable,'visible','on',...
  'callback',[btcmd{2} '_guifcn(''scorestconbuttoncall'',gcbo,[],guidata(get(gcbo,''userdata'')))']});
items = setfield(items,['tconref' numtag],{...
  'style','pushbutton','string','T con Ref.',  ...
  'tooltip','Choose reference sample(s) for relative T2 contributions.',...
  'userdata',double(handles.analysis),...
  'enable',tconref_enable,'visible','on',...
  'callback',[btcmd{2} '_guifcn(''scoressetconref'',gcbo,[],guidata(get(gcbo,''userdata'')),''T'')']});
items = setfield(items,['data' numtag],{...
  'style','pushbutton','string','data', ...
  'tooltip','Plot raw data associated with selected samples.',...
  'userdata',double(handles.analysis),...
  'enable',data_enable,'visible','on',...
  'callback',[btcmd{3} '_guifcn(''scoresdatabuttoncall'',gcbo,[],guidata(get(gcbo,''userdata'')))']});
items = setfield(items,['info' numtag],{...
  'style','pushbutton','string','info',  ...
  'tooltip','Show raw data information associated with a single sample.',...
  'userdata',double(handles.analysis),...
  'enable','on','visible','on',...
  'callback',[btcmd{4} '_guifcn(''scoresinfobuttoncall'',gcbo,[],guidata(get(gcbo,''userdata'')))']});
if showautoclass & ~forceautoclass
  items = setfield(items,['autoclass' numtag],...
    {'style','pushbutton','string','Auto-Class','userdata',double(handles.analysis),...
    'tooltip','Automatically assign classes.',...
    'callback','pca_guifcn(''autoclass_callback'',gcbo,[],guidata(get(gcbo,''userdata'')))'});
end
items = setfield(items,['sct' numtag],...
  {'style','checkbox','string','Show Cal Data with Test','userdata',double(handles.analysis),...
  'tooltip','Show calibration data along with test data.',...
  'callback',['analysis(''showcalwithtest'',get(gcbo,''userdata''),[],guidata(get(gcbo,''userdata'')))']});
items.(['showerrorbars' numtag]) = ...
  {'style','checkbox','string','Show Error Bars','value',showerrorbars,'userdata',double(handles.analysis),...
  'tooltip','Show error bars when available.',...
  'updatecallback','if ~isempty(getappdata(targfig,''showerrorbars'')); set(h,''value'',getappdata(targfig,''showerrorbars'')); end',...
  'callback','setappdata(getappdata(gcbf,''target''),''showerrorbars'',get(gcbo,''value''));plotgui(''update'',''figure'',getappdata(gcbf,''target''))'};
pltcmd = ['plotscoreslimits(targfig,get(targfig,''userdata''));'];

figname = ['Samples/Scores' getappdata(handles.analysis,'figname_info')];


%- - - - - - - - - - - - - - - - - - - - - - - - 
%add name and callback fns
myprops = [];
myprops.figurename = figname;
myprops.includechangecallback = [cbcmd{1} '_guifcn(''scoresincludchange'',h)'];
myprops.classchangecallback   = [cbcmd{2} '_guifcn(''scoresclasschange'',h, keyword2)'];
myprops.inforeqcallback       = [cbcmd{3} '_guifcn(''scoresinfobuttoncall_add'',datasource,targfig,listboxhandle)'];
myprops.axissetchangecallback = [cbcmd{4} '_guifcn(''scoresaxissetchange'',h, keyword2)'];
myprops.helplink              = 'Model Building: Plotting Scores';

%set object data (or update)
myid = analysis('setobjdata','scores',handles,a,myprops);

if strcmpi(modl.modeltype,'mpca')
  %MPCA samples connect to mode 3
  linkmap_data   = [1 3];
  linkmap_scores = [3 1];
else
  %others are 1:1
  linkmap_data   = [1 1];
  linkmap_scores = [1 1];
end

%link to x-block (if there)
xdataid = analysis('getobj','xblock',handles);
valxdataid = analysis('getobj','validation_xblock',handles);
if ~isempty(xdataid)
  if blockshown(1)
    linkshareddata(xdataid,'add',myid,'analysis',struct('linkmap',linkmap_data));
    linkshareddata(myid,'add',xdataid,'analysis',struct('linkmap',linkmap_scores));
  else
    linkshareddata(xdataid,'remove',myid);
    linkshareddata(myid,'remove',xdataid);
  end
end
if ~isempty(valxdataid)
  if blockshown(2)
    indexoffset = 0;
    if blockshown(1) & ~isempty(xdataid)
      %add offset to index into scores if showing cal with test
      indexoffset = size(xdataid.object,linkmap_data(2));
    end
    linkshareddata(valxdataid,'add',myid,'analysis',struct('linkmap',linkmap_data,'indexoffset',indexoffset));
    linkshareddata(myid,'add',valxdataid,'analysis',struct('linkmap',linkmap_scores,'indexoffset',-indexoffset));
  else
    linkshareddata(valxdataid,'remove',myid);
    linkshareddata(myid,'remove',valxdataid);
  end
end

%get appropriate limits value from model (if options includes confidence
%limit setting)
limitsvalue = 95;  %default limits value
if isfieldcheck('modl.detail.options.confidencelimit',modl);
  limitsvalue = modl.detail.options.confidencelimit*100;
elseif isfieldcheck('modl.detail.options.cl',modl);
  limitsvalue = modl.detail.options.cl*100;
end
classset = 1;
if isfieldcheck('modl.detail.options.classset',modl);
  classset = modl.detail.options.classset;
end
viewclasses = 1;
if size(myid.object.classname,2)>=classset & strcmp(myid.object.classname{1,classset},'Cross-validation Sets');
  %DISABLE view-classes if the class set we're choosing is the
  %cross-validation set (only show this if the user CHOOSES to show it)
  viewclasses = 0;
end

%See if there is a valid plotgui subscriber.
fighandle = analysis('findpg',myid,handles,'*');
if isempty(fighandle)
  %get options and create all the plots suggested therein
  [toplot,subplots] = plotscores_defaults(getappdata(handles.analysis,'curanal'),a);
  plotsettings = {'name',figname,'plotby',2,'uicontrol',items,'viewlabels',0,'viewclasses',viewclasses,...
    'viewclassset',classset,...
    'userdata',double(handles.analysis),'conflimits',showconflimits,'limitsvalue',limitsvalue,...
    'plotcommand',pltcmd,extracmds{:},'viewaxislines',[1 1 1],'validplotby',[2]};
  
  myid.properties.plotsettings = plotsettings;

  if subplots
    %create sub-axes for each plot on same figure
    fighandle = figure;
    setappdata(fighandle,'showerrorbars',showerrorbars)
    if length(toplot)~=3
      [rows,cols] = mplot(length(toplot),struct('plots','none'));
    else
      rows = 3;
      cols = 1;
    end
    subplot(rows,cols,1);
    addsettings = {};
    for plotind = 1:length(toplot)
      %add plots as needed storing plot to display in each axes
      if ~ishandle(fighandle); return; end   %figure closed? exit now
      subplot(rows,cols,plotind);
      for pr=1:2:length(toplot{plotind})
        if strcmp(toplot{plotind}{pr},'axismenuvalues')
          setappdata(gca,toplot{plotind}{pr:pr+1});
        else
          addsettings = [addsettings toplot{plotind}(pr:pr+1)];
        end
      end
    end
    %update all axes at once
    plotgui('update','figure',fighandle,myid,'autoduplicate',1,addsettings{:},plotsettings{:},'background');
  else
    %create each plot on its own figure
    for plotind = 1:length(toplot)
      fighandle = figure;
      setappdata(fighandle,'showerrorbars',showerrorbars)
      plotgui('update','figure',fighandle,myid,plotsettings{:},toplot{plotind}{:});
    end
  end

else
  figure(  min(double(fighandle)) );
end

fighandle(~ishandle(fighandle)) = [];
if isempty(fighandle)
  %figure got closed before we got here? exit now
  return;
end

%Compare old status of data and sct with new. Clear selections if changes
%have been made.
statdata = [analysis('isloaded','xblock',handles) analysis('isloaded','validation_xblock',handles)];
statdata_scores = getappdata(handles.analysis,'scores_statdata');
sct_scores = getappdata(handles.analysis,'scores_sct');
if isempty(statdata_scores) | ~all(statdata==statdata_scores) | isempty(sct_scores) | sct~=sct_scores 
  if ~all(cellfun('isempty',myid.properties.selection))
    %data changed or sct changed - clear selection from all children
    myid.properties.selection = {[] []};
  end
  if sct 
    %when turning showcalwithtest ON, enable classes on plotgui figures
    for pghind = 1:length(fighandle);
      if strcmpi(getappdata(fighandle(pghind),'figuretype'),'plotgui')
        plotgui('update','figure',fighandle(pghind),'viewclasses',viewclasses,'viewclassset',classset);
      end
    end
  end
end
%store current settings for statdata and sct
setappdata(handles.analysis,'scores_statdata',statdata)
setappdata(handles.analysis,'scores_sct',sct);

if blockshown(1) & ~blockshown(2)
  %cal x only
  xid = xdataid;
elseif blockshown(2) & ~blockshown(1)
  %val x only
  xid = valxdataid;
else
  xid = [];
end

%turn on/off sct checkbox
if ~analysis('isloaded','prediction',handles)
  enb = 'off';
else
  enb = 'on';
end
for j=1:length(fighandle)
  %assign drilllinks to ALL figures
  setappdata(fighandle(j),'drilllink',xid);
  %set SCT checkbox on/off as needed
  set(findobj(getappdata(fighandle(j),'controlby'),'tag',['sct' numtag]),'value',sct,'enable',enb)
end

% --------------------------------------------------------------------
function autoclass_callback(h, eventdata, handles, varargin)
%add classes automatically to previously calculated scores

setappdata(handles.analysis,'forceautoclass',1)
plotscores_Callback(handles.plotscores, [], handles);

%make sure we're viewing the new classes
scrs = analysis('getobj','scores',handles);
newset = strmatch('AutoClasses',scrs.object.classname(1,:));
if ~isempty(newset);
  targfig = analysis('findpg',scrs,handles,'*');
  if ~isempty(targfig) & strcmpi(getappdata(targfig(1),'figuretype'),'plotgui')
    plotgui('update','figure',targfig,'viewclasses',1,'viewclassset',newset(1))
  end
else
  %no auto classes found? must have failed - disable setting
  setappdata(handles.analysis,'forceautoclass',0)
end

% --------------------------------------------------------------------
function scoresqconbuttoncall(h, eventdata, handles, varargin)


if ~strcmpi(getappdata(handles.analysis,'curanal'),'clsti')
  cal_loaded  = analysis('isloaded','xblock',handles);
  val_loaded  = analysis('isloaded','validation_xblock',handles);
  modl        = getsubmodel('model',handles);
  
  if ~cal_loaded & ~val_loaded
    evriwarndlg(['Calibration or test data must be available to calculate Q contributions.', ...
      ' Contributions cannot be calculated.'],'Q Contributions')
    return
  end
  if ~ismember(getappdata(handles.analysis,'statmodl'),{'calold' 'loaded'})
    evriwarndlg(['Model information not available.', ...
      ' Contributions cannot be calculated.'],'Q Contributions')
    return
  end
  if ~isfield(modl,'ssqresiduals') | isempty(modl.ssqresiduals{1,1})
    evriwarndlg('Contributions cannot be calculated for this model type.','Q Contributions')
    return
  end
else
  val_loaded  = analysis('isloaded','validation_xblock',handles);
  myGuiObj = evrigui(handles.analysis);
  myPredObj = myGuiObj.getPrediction;
  modl = myGuiObj.getModel;
end

fig = getappdata(get(h,'parent'),'target');
figure(fig)
mode = getappdata(fig,'selectionmode');
if isempty(mode); mode = 'rbbox'; end
ii = gselect(mode,finddataobj,1);
if isempty(ii); return; end
for k=2:length(ii); if length(ii{1})==length(ii{k}); ii{1} = or(ii{1},ii{k}); end; end

myii=find(ii{1})';
if isempty(myii);  return; end

setplotselection(fig,myii);    %mark these items as selected in plot

%sort out into cal/val
[cal,val] = sortselection(myii,handles);


%check for reference points
scrs = analysis('getobj','scores',handles);
refset = findset(scrs.object,'class',1,'QCon Reference');
if ~isempty(refset)
  %sort out reference
  qconref = find(scrs.object.class{1,refset}');
  [calref,valref] = sortselection(qconref,handles);
  allcal = unique([cal;calref]);
  allval = unique([val;valref]);
  isref  = [ismember(allcal,calref);ismember(allval,valref)];
  onlyref = [~ismember(allcal,cal);~ismember(allval,val)];
else
  %no reference
  qconref = [];
  allcal = cal;
  allval = val;
end

calx = [];
valx = [];
samplelabels = {};
if ~isempty(allcal)
  %calibration data
  ii = cal;
  if ~cal_loaded
    evriwarndlg(['Original calibration data not available for this point.', ...
      ' Contributions cannot be calculated.'],'Q Contributions')
    return
  end
  calx = analysis('getobjdata','xblock',handles);
  calx = delsamps(calx,setdiff(1:size(calx.data,1),allcal),1,2);
  blocklabel = 'Calibration';
  samplelabels = str2cell(sprintf('Calibration sample %u\n',cal));
end
if ~isempty(allval)
  %test data
  ii = val;
  if ~val_loaded
    evriwarndlg(['Original validation data not available for this point.', ...
      ' Contributions cannot be calculated.'],'Q Contributions')
    return
  end
  valx = analysis('getobjdata','validation_xblock',handles);
  valx = delsamps(valx,setdiff(1:size(valx.data,1),allval),1,2);
  blocklabel = 'Test';
  samplelabels = [samplelabels;str2cell(sprintf('Test sample %u\n',blocklabel,val))];
  
  %handle missing data and excluded variables
  if ~comparevars(valx.include{2},modl.detail.includ{2});
    missing = setdiff(modl.detail.includ{2},valx.include{2});
    valx.data(:,missing) = nan;  %replace expected but missing data with NaN's to force replacement
    valx.include{2,1} = modl.detail.includ{2};
  end 
  if mdcheck(valx.data(:,valx.include{2,1}));
    valx = replacevars(modl,valx);
  end
  
end
if ~isempty(cal) & ~isempty(val);
  ii = [cal; val];
end
x = [calx;valx];
x.include{1} = 1:size(x,1);
x.include{2} = modl.detail.includ{2};
if ~strcmpi(getappdata(handles.analysis,'curanal'),'clsti')
  [xhat,y] = datahat(modl,x);
else
  y = myPredObj.detail.res{1}(myii,:);
end

if isempty(y)
  evriwarndlg('Contributions cannot be calculated for this model type.','Q Contributions')
  return
end

if ~isempty(qconref)
  %remove reference values and use to correct non-reference values
  yref = nindex(y,isref,1);          %extract t-cons for reference values
  y = nindex(y,~onlyref,1);          %remove ref-only values in y
  x = nindex(x,~onlyref,1);
  y = scale(y,mean(yref,1));  %do correction to make these RELATIVE t-contributions
end

z        = sum((y(:,:).^2)')';
newfig   = figure('numbertitle','off','name','Q Residual Contributions');
analysis('adopt',handles,newfig,'modelspecific');

if ndims(y)==2;
  if isempty(x.axisscale{2,1}) | length(unique(x.axisscale{2,1}))~=size(x,2)
    xax            = modl.detail.includ{2,1};
  else
    xax            = x.axisscale{2,1}(1,modl.detail.includ{2,1});
  end
  if ~isempty(x.title{2,1})
    xlbl           = x.title{2,1};
  elseif ~isempty(x.labelname{2,1})
    xlbl           = x.labelname{2,1};
  else
    xlbl           = 'Variable';
  end
  if length(ii) == 1;
    bh = bar(xax,y','b');
    setappdata(gcf,'drillaxisscale',xax);
    setappdata(gcf,'drillinclude',modl.detail.includ{2,1});
    xlabel(xlbl)
  else
    bh = bar(xax,y');
    setappdata(gcf,'drillaxisscale',xax);
    setappdata(gcf,'drillinclude',modl.detail.includ{2,1});
    for j=1:length(bh);
      legendname(bh(j),samplelabels{j});
    end
  end
  if isempty(qconref)
    ylabel('Q Residual Contribution')
  else
    ylabel('Q Residual Relative Contribution')
  end
  if length(ii)==1;
    if isempty(x.label{1})
      ttl=(sprintf('%s Sample %u Q Residual = %5.4g ',blocklabel,ii,z));
    else
      ttl=(sprintf(['%s Sample %u ',deblank(x.label{1}),' Q Residual = %5.4g '],blocklabel,ii,z));
    end
  else
    ttl = 'Multiple Samples';
  end
  title(ttl);
  s                = ' ';
  
  lbls = [];
  if ~isempty(x) & ~isempty(x.label{2,1}) & length(modl.detail.includ{2,1})<100;
    lbls = x.label{2,1}(modl.detail.includ{2,1},:);
  elseif ~isempty(modl.detail.label{2,1}) & length(modl.detail.includ{2,1})<100;
    lbls = modl.detail.label{2,1}(modl.detail.includ{2,1},:);
  end
  if ~isempty(lbls);
    h = text(xax,max([zeros(1,size(y,2)); y]),[s(ones(size(lbls,1),1)) lbls], 'rotation',90);
    ext = get(h,'extent');
    ext = cat(1,ext{:});
    top = max(ext(:,2)+ext(:,4));
    ax = axis;
    if ax(4)<top;
      axis([ax(1:3) top]);
    end
  else
    h = [];
  end
  set(h,'interpreter','none')
  
  %create DSO of this info
  temp = ones(size(y,1),modl.datasource{1}.size(2))*nan;
  temp(:,modl.detail.includ{2,1}) = y;
  y = dataset(temp);
  y = copydsfields(modl,y,2);
%   y = copydsfields(x,y,1);  % Do not use. It fails if x is image DSO
  y.name = ttl;
  y.title{2} = ttl;
  setshareddata(newfig,y);
  
  %assign button down functions
  setappdata(newfig,'analysishandle',double(handles.analysis));
  set([h(:)' bh gca],'buttondownfcn','pca_guifcn(''condrilldown'',gcbf)');
  
else
  %n-way data - do plotgui plot
  
  if length(ii)==1
    if isempty(x.label{1})
      ttl=(sprintf('%s Sample %u Q Residual = %5.4g ',blocklabel,ii,z));
    else
      ttl=(sprintf(['%s Sample %u ',deblank(x.label{1}),' Q Residual = %5.4g '],blocklabel,ii,z));
    end
  else
    ttl = 'Multiple Samples';
  end
  
  %create DSO of this info
  temp = ones([size(y,1) modl.datasource{1}.size(2:end)])*nan;
  temp = nassign(temp,y,modl.detail.includ(2:end,1),2:size(modl.detail.includ,1));
  y = dataset(temp);
  y = copydsfields(modl,y,2);
  y = copydsfields(x,y,1);
  y.name = ttl;
  y.title{2} = ttl;
  
  figure(newfig);
  plotgui('update','figure',newfig,y,'rows','noinclude',1);
  
end


% --------------------------------------------------------------------
function condrilldown(fig,mode)

if nargin<2
  if strcmp(get(fig,'selectiontype'),'alt');
    mode = 'interactive';
  else
    mode = 'data';
  end
end

switch mode
  case 'interactive'
    %control or right-click? Give interactive plot
    ax = axis(gca);
    myid = shareddata(fig);  %There should only be one data object on fig so we don't have to specify.

    items = [];
    items = setfield(items,['drilldown'],{
      'style','pushbutton','string','Drill Down', ...
      'tooltip','Drill-down to raw data for selected variable.',...
      'callback',['pca_guifcn(''condrilldown'',gcbf,''plotguidrilldown'')']});    
    plotgui('update','figure',fig,myid,'rows',...
      'plottype','bar','linestyle','-','noinclude',1,...
      'viewlabels',1,'viewlabelminy',0,'viewlabelangle',90,...
      'uicontrol',items);
    axis(ax);

  case 'plotguidrilldown'
    %info request from plotgui
    fig = getappdata(gcbf,'target');
    figure(fig);
    target_handle = findobj(allchild(gca),'userdata','data');
    ii = gselect('nearest',target_handle,1);
    if isempty(ii); return; end
    if iscell(ii)
      ii = find(ii{1});
    else
      xax = getappdata(gcf,'drillaxisscale');
      incl = getappdata(gcf,'drillinclude');
      ii = incl(findindx(xax,ii(1)));
    end
    h  = getappdata(fig,'analysishandle');
    loadsdatabuttoncall(h, [], guidata(h), ii, get(fig,'selectiontype'));

  otherwise
    %normal click? drill down to data
    h = getappdata(fig,'analysishandle');
    ii = get(gca,'currentpoint');
    xax = getappdata(gcf,'drillaxisscale');
    incl = getappdata(gcf,'drillinclude');
    ii = incl(findindx(xax,ii(1)));
    loadsdatabuttoncall(h, [], guidata(h), ii, get(fig,'selectiontype'));
end

% --------------------------------------------------------------------
function scoressetconref(h, eventdata, handles, varargin)

if nargin<3
  type = 'T';
else
  type = upper(varargin{1});
end

fig = getappdata(get(h,'parent'),'target');
figure(fig)
mode = getappdata(fig,'selectionmode');
if isempty(mode); mode = 'rbbox'; end

options = [];
options.modal = 'True';
options.helptext = 'Select sample(s) to use as relative contributions reference. Press [Esc] or choose no samples to turn off relative contributions.';
ii = gselect(mode,finddataobj,options);
if isempty(ii); return; end
for k=2:length(ii); if length(ii{1})==length(ii{k}); ii{1} = or(ii{1},ii{k}); end; end

myii=find(ii{1})';
scrs = analysis('getobj','scores',handles);

%update classes on scores
cls = zeros(1,size(scrs.object,1));
cls(myii) = 1;
lookup = {0 'Standard Sample'; 1 [type '-Contributions Reference']};
[scrs.object,setnum] = updateset(scrs.object,'class',1,cls,[type 'Con Reference'],lookup);

plotgui('update','figure',fig,'viewclasses',1,'viewclassset',setnum);

% --------------------------------------------------------------------
function scorestconbuttoncall(h, eventdata, handles, varargin)

modl        = getsubmodel('model',handles);
test        = getsubmodel('prediction',handles);

if ~ismember(getappdata(handles.analysis,'statmodl'),{'calold' 'loaded'})
  evriwarndlg(['Model information not available.', ...
      ' Contributions cannot be calculated.'],'T^2 Contributions')
  return
end
if ~isfield(modl,'tsqs') | ismember(lower(modl.modeltype),{'parafac'})
  evriwarndlg('Contributions cannot be calculated for this model type.','T^2 Contributions')
  return
end

fig = getappdata(get(h,'parent'),'target');
figure(fig)
mode = getappdata(fig,'selectionmode');
if isempty(mode); mode = 'rbbox'; end
ii = gselect(mode,finddataobj,1);
if isempty(ii); return; end
for k=2:length(ii); if length(ii{1})==length(ii{k}); ii{1} = or(ii{1},ii{k}); end; end

myii=find(ii{1})';
if isempty(myii);  return; end

setplotselection(fig,myii);    %mark these items as selected in plot

%sort out into cal/val
[cal,val] = sortselection(myii,handles);

%check for reference points
scrs = analysis('getobj','scores',handles);
refset = findset(scrs.object,'class',1,'TCon Reference');
if ~isempty(refset)
  %sort out reference
  tconref = find(scrs.object.class{1,refset}');
  [calref,valref] = sortselection(tconref,handles);
  isref  = [false(1,length(cal)) true(1,length(calref)) false(1,length(val)) true(1,length(valref))];
  allcal = [cal;calref];
  allval = [val;valref];
else
  %no reference
  tconref = [];
  allcal = cal;
  allval = val;
end

%get data
ii = [];
loads = [];
tsqs = [];
x = [];
samplelabels = {};
if ~isempty(allcal);
  %do for model data...
  ii = cal;
  loads = modl.loads{1,1}(allcal,:);
  tsqs  = modl.tsqs{1,1}(cal);
  x = analysis('getobjdata','xblock',handles);
  blocklabel = 'Calibration';
  samplelabels = str2cell(sprintf('Calibration sample %u\n',cal));
end
if ~isempty(allval);
  %do for test data... (MAY be adding to calibration data so do carefully)
  ii = [ii;val];
  loads = [loads; test.loads{1,1}(allval,:)];
  tsqs  = [tsqs; test.tsqs{1,1}(val)];
  x = analysis('getobjdata','validation_xblock',handles);
  blocklabel = 'Test';
  samplelabels = [samplelabels; str2cell(sprintf('Test sample %u\n',val))];
end

pred = modl;  %fake a pred structure to pass to tconcalc
pred.loads{1,1} = loads;  %insert necessary scores into fake pred structure
y = tconcalc(pred,modl);

if ~isempty(tconref)
  %remove reference values and use to correct non-reference values
  yref = nindex(y,isref,1);        %extract t-cons for reference values
  y = nindex(y,~isref,1);          %leave non-ref values in y
  y = scale(y,mean(yref,1));       %do correction to make these RELATIVE t-contributions
end

z = tsqs;

newfig = figure('numbertitle','off','name','T^2 Contributions');         %T^2
analysis('adopt',handles,newfig,'modelspecific');

if isempty(modl.detail.axisscale{2,1})  | length(unique(modl.detail.axisscale{2,1}))~=length(modl.detail.axisscale{2,1})
  %if empty or has duplicate values (not allowed by bar)
  xax            = modl.detail.includ{2,1};
else
  xax            = modl.detail.axisscale{2,1}(1,modl.detail.includ{2,1});
end
if ~isempty(x) & ~isempty(x.title{2,1})
  xlbl           = x.title{2,1};
elseif ~isempty(x) & ~isempty(x.labelname{2,1})
  xlbl           = x.labelname{2,1};
else
  xlbl           = 'Variable';
end
if length(ii) == 1;
  bh = bar(xax,y','b');
  setappdata(gcf,'drillaxisscale',xax);
  setappdata(gcf,'drillinclude',modl.detail.includ{2,1});
  xlabel(xlbl)
else
  bh = bar(xax,y');
  setappdata(gcf,'drillaxisscale',xax);
  setappdata(gcf,'drillinclude',modl.detail.includ{2,1});
  for j=1:length(bh);
    legendname(bh(j),samplelabels{j});
  end
end

if isempty(tconref)
  ylabel('Hotelling T^2 Contribution')
else
  ylabel('Hotelling T^2 Relative Contribution')
end
if length(ii)==1;
  if isempty(x) | isempty(x.label{1})
    ttl = sprintf('%s Sample %u Hotelling T^2 = %5.4g ',blocklabel,ii,z);
  else
    ttl = sprintf(['%s Sample %u ',deblank(x.label{1}(ii,:)),' Hotelling T^2 = %5.4g '],blocklabel,ii,z);
  end
else
  ttl = ['Multiple Samples'];
end
title(ttl)
s                = ' ';

lbls = [];
if ~isempty(x) & ~isempty(x.label{2,1}) & length(modl.detail.includ{2,1})<100;
  lbls = x.label{2,1}(modl.detail.includ{2,1},:);
elseif ~isempty(modl.detail.label{2,1}) & length(modl.detail.includ{2,1})<100;
  lbls = modl.detail.label{2,1}(modl.detail.includ{2,1},:);
end
if ~isempty(lbls)
  h = text(xax,max([zeros(1,size(y,2)); y]),[s(ones(size(lbls,1),1)) lbls], 'rotation',90);
  ext = get(h,'extent');
  ext = cat(1,ext{:});
  top = max(ext(:,2)+ext(:,4));
  ax = axis;
  if ax(4)<top;
    axis([ax(1:3) top]);
  end
else
  h = [];
end
set(h,'interpreter','none')

%create DSO of this info
temp = ones(size(y,1),modl.datasource{1}.size(2))*nan;
temp(:,modl.detail.includ{2}) = y;
y = dataset(temp);
y = copydsfields(modl,y,2);
%y.label{1} = repmat(ttl,length(ii),1); %Old way of labeling. 
y.label{1} = samplelabels;%Use sample labels per Bob/helpdesk request.
y.name = ttl;
y.title{2} = ttl;
setshareddata(newfig,y);

%assign button down functions
setappdata(newfig,'analysishandle',double(handles.analysis));

set([h(:)' bh gca],'buttondownfcn','pca_guifcn(''condrilldown'',gcbf)');

% --------------------------------------------------------------------
function scoresdatabuttoncall(h, eventdata, handles, varargin)

cal_loaded  = analysis('isloaded','xblock',handles);
val_loaded  = analysis('isloaded','validation_xblock',handles);
modl        = getsubmodel('model',handles);

if ~cal_loaded & ~val_loaded
  evriwarndlg('Data not available.', ...
    'Plot Data')
  return
end

fig = getappdata(get(h,'parent'),'target');
figure(fig);
mode = getappdata(fig,'selectionmode');
if isempty(mode); mode = 'rbbox'; end
ii = gselect(mode,finddataobj,...
  struct('modal','true','helptextpre','View Data:','helptextpost','Hold down [Shift] to add to currently viewed data.'));
if isempty(ii); return; end
for k=2:length(ii); if length(ii{1})==length(ii{k}); ii{1} = or(ii{1},ii{k}); end; end
ii = find(ii{1});
if isempty(ii); return; end

%decide where we should map this selection to in the data
if strcmpi(getappdata(handles.analysis,'curanal'),'mpca')
  sampmode = 3;
else
  sampmode = 1;
end

setplotselection(fig,ii);    %mark these items as selected in plot

[cal_ii,val_ii] = sortselection(ii,handles);

viewexcluded = getappdata(fig,'viewexcludeddata');
viewlabels   = getappdata(fig,'viewlabels');
viewclasses  = getappdata(fig,'viewclasses');

for block = {'xblock' 'validation_xblock' 'xblockprepro' 'datahat'};
  openfig = true;
  switch block{:}
    case 'xblock'
      ii = cal_ii;
      name = 'Calibration X-Block';
    case 'xblockprepro'
      ii = cal_ii;
      name = 'Preprocessed X-Block';
      openfig = false;
    case 'validation_xblock'
      ii = val_ii;
      name = 'Validation X-Block';
    case 'datahat'      
      defaults = getappdata(handles.analysis,'plotdatadefaults');
      if ~isfield(defaults,'block')
        continue;
      end
      if cal_loaded
        calsamp = size(analysis('getobjdata','xblock',handles),sampmode);
      else
        calsamp = 0;
      end
      if val_loaded
        valsamp = size(analysis('getobjdata','validation_xblock',handles),sampmode);
      else
        valsamp = 0;
      end
      switch lower(defaults.block)
        case 'validation'
          ii = [val_ii val_ii+valsamp val_ii+(valsamp*2)];
        case 'calibration'
          ii = [cal_ii cal_ii+calsamp cal_ii+(calsamp*2)];
        case 'both'
          ii = [cal_ii val_ii+calsamp];
          ii = [ii ii+(calsamp+valsamp) ii+(calsamp+valsamp)*2];          
      end
      xhat = analysis('getobjdata',block{:},handles);
      ii(ii>size(xhat,1)) = [];  %except drop items above range of data
      name = 'Data Estimate';
      openfig = false;
  end
  if isempty(ii) | ~analysis('isloaded',block{:},handles); continue; end

  %see if we can find an existing plotgui figure which is already a child of the top level GUI
  target = min(double(analysis('findpg',block{:},handles)));
  if isempty(target); %no existing figure found, create new
    if ~openfig; continue; end;  %unless we aren't supposed to open this type if not open
    targetcode = {'new'};
  else
    targetcode = {'update','figure',target};  %cell will be expanded in plotgui line
    %see if we already had some points selected in current data
    if getappdata(target,'plotby')==sampmode && strcmp(get(fig,'selectiontype'),'extend')
      current_selection = getappdata(target,'axismenuindex');
      ii = union(ii,current_selection{2});
    end
  end

  plotgui(targetcode{:},analysis('getobj',block{:},handles),'axismenuvalues',{0 ii},'viewclasses',viewclasses,'viewexcludeddata',viewexcluded,'viewlabels',viewlabels,'plotby',sampmode,'name',name)
end
  
% --------------------------------------------------------------------
function scoresinfobuttoncall(h, eventdata, handles, varargin)

if strcmp(getappdata(handles.analysis,'statmodl'),'none')
  evriwarndlg(['Model information not available.'],'Plot Scores')
  return
end

targfig = getappdata(get(h,'parent'),'target');
figure(targfig);
ii                 = gselect('nearest',finddataobj,1);
if isempty(ii); return; end
for k=2:length(ii); if length(ii{1})==length(ii{k}); ii{1} = or(ii{1},ii{k}); end; end
ii                 = find(ii{1});
if isempty(ii); return; end

[newselection,oldselection] = setplotselection(targfig,ii);
plotgui('menuselection','EditGetInfo');         %call plotgui's GetInfo (it will call the next routine)
%DISABLED... plotgui('setselection',oldselection,'set',targfig);%reset selection back to what was there before we messed with it

% --------------------------------------------------------------------
function [newselection,oldselection] = setplotselection(targfig,ii)

%get current selection
oldselection    = plotgui('getselection',targfig);
newselection    = oldselection;
newselection{1} = ii;
plotgui('setselection',newselection,'set',targfig);%set selection to what WE want to see

if nargout==0
  clear newselection
end

% --------------------------------------------------------------------
function scoresinfobuttoncall_add(h,targfig,listboxhandle);

handles = guidata(h.source);
modl = getsubmodel('model',handles);
test = getsubmodel('prediction',handles);
sel  = h.properties.selection{1};

if ~isempty(sel) & ~strcmp(getappdata(handles.analysis,'statmodl'),'none');
  
  s_orig = get(listboxhandle,'string');
  s_waiting = '** Please Wait... Gathering Information';
  
  s_all = cell(0);
  for iind = 1:length(sel);
    
    ii = sel(iind);    
    if mod(iind,8)==0
      if ~ishandle(listboxhandle)
        return;
      end
      set(listboxhandle,'string',{s_orig{:},' ',[s_waiting ones(1,mod(floor(iind/8),5)).*'.']});
      drawnow;
    end
    
    s{1}  = ''; s = s(ones(5,1));
    sy    = cell(0);
    [cal,val] = sortselection(ii,handles);
    if ~isempty(cal)
      %from calibration set
      if strcmpi(modl.modeltype,'simca')
        s{2}         = '';
        s{3}         = 'Values for each submodel:';
        s{4}         = sprintf('Q Residual =     %s',num2str(modl.rq(ii,:),'%4.3g  '));
        s{5}         = sprintf('Hotelling T^2 =  %s',num2str(modl.rtsq(ii,:),'%4.3g  '));
      else
        if isfield(modl,'ssqresiduals') & ~isempty(modl.ssqresiduals{1,1})
          s{2}         = sprintf('Q Residual =     %4.3g ',modl.ssqresiduals{1,1}(ii));
        end
        if isfield(modl,'tsqs') & ~isempty(modl.tsqs{1,1})
          s{4}         = sprintf('Hotelling T^2 =  %4.3g ',modl.tsqs{1,1}(ii));
        end
      end

      if isfieldcheck('modl.detail.data',modl) & length(modl.detail.data) > 1 & ~isempty(modl.detail.data{2});
        sy{end+1}           = ['Y Measured  =' sprintf(' %g ',modl.detail.data{2}.data(ii,modl.detail.includ{2,2}))];
      else
        y           = analysis('getobjdata','yblock',handles);
        if ~isempty(y);
          sy{end+1}           = ['Y Measured  =' sprintf(' %g ',y.data(ii,y.includ{2}))];
        end
      end
      if isfieldcheck('modl.pred',modl) & length(modl.pred) > 1 & ~isempty(modl.pred{2});
        sy{end+1}           = ['Y Predicted =' sprintf(' %g ',modl.pred{2}(ii,:))];
      end
      if isfieldcheck('modl.pred',modl) & length(modl.pred) > 1 & ~isempty(modl.detail.res{2});
        sy{end+1}           = ['Y Residuals =' sprintf(' %g ',modl.detail.res{2}(ii,:))];
      end

    else
      %from test set
      ii = val;
      if strcmpi(modl.modeltype,'simca')
        s{2}         = '';
        s{3}         = 'Values for each submodel:';
        s{4}         = sprintf('Q Residual =     %s',num2str(test.rq(ii,:),'%4.3g  '));
        s{5}         = sprintf('Hotelling T^2 =  %s',num2str(test.rtsq(ii,:),'%4.3g  '));
      elseif isfield(test,'ssqresiduals') & ~isempty(test.ssqresiduals{1,1})
        s{2}         = sprintf('Q Residual =     %4.3g ',test.ssqresiduals{1,1}(ii));
        s{4}         = sprintf('Hotelling T^2 =  %4.3g ',test.tsqs{1,1}(ii));
      end

      %y-data?
      if isfieldcheck('test.detail.data',test) & length(test.detail.data) > 1 & ~isempty(test.detail.data{2});
        sy{end+1}           = ['Y Measured  =' sprintf(' %g ',test.detail.data{2}.data(ii,test.detail.includ{2,2}))];
      end
      if isfieldcheck('test.pred',test) & length(test.pred) > 1 & ~isempty(test.pred{2});
        sy{end+1}           = ['Y Predicted =' sprintf(' %g ',test.pred{2}(ii,:))];
      end
      if isfieldcheck('test.pred',test) & length(test.pred) > 1 & ~isempty(test.detail.res{2});
        sy{end+1}           = ['Y Residuals =' sprintf(' %g ',test.detail.res{2}(ii,:))];
      end

    end
    if isfieldcheck('modl.detail.options.confidencelimit',modl)
      pct = modl.detail.options.confidencelimit*100;
    else
      pct = 95;
    end
    if ~strcmpi(modl.modeltype,'simca') & isfieldcheck(modl,'modl.detail.reslim') & isfieldcheck(modl,'modl.detail.tsqlim') 
      s{3}             = sprintf(' (%4.1f%% limit =  %4.3g) ',pct,modl.detail.reslim{1});
      s{5}             = sprintf(' (%4.1f%% limit =  %4.3g) ',pct,modl.detail.tsqlim{1});
    end
    
    emptycell = cellfun('isempty',s);
    emptycell(1) = false;
    s(emptycell) = [];
    
    s_all(end+1:end+length(s)) = s;
    if ~isempty(sy); s_all(end+1:end+length(sy)) = sy; end
  end
  
  if ~ishandle(listboxhandle)
    return;
  end
  set(listboxhandle,'string',{s_orig{:},' ',s_all{2:end}});
end

% --------------------------------------------------------------------
function scoresincludchange(h)
%input h is the handle of the analysis window

handles = guidata(h);
modl = getsubmodel('model',handles);
test = getsubmodel('prediction',handles);
t    = analysis('getobjdata','scores',handles);

%determine dim of interest
if ~strcmpi(getappdata(handles.analysis,'curanal'),'mpca');
  sampmode = 1;
else
  sampmode = 3;
end

%Sort out selection between cal and val
[cal_first,val_first] = sortselection(1,handles);  %simple test for cal being present (see if first sample is in cal)
[cal,val] = sortselection(t.includ{1,1},handles);
updatefigs = 0;
if analysis('isloaded','xblock',handles) & ~isempty(cal_first)
  %we have the calibration x-block
  x     = analysis('getobjdata','xblock',handles);
  y     = analysis('getobjdata','yblock',handles);

  %any change in dim of interest?
  if ~isempty(x) & (length(x.includ{sampmode,1}) ~= length(cal) |  ~isempty(setdiff(x.includ{sampmode,1},cal)))     
    x.includ{sampmode,1} = cal;  %copy include field
    analysis('setobjdata','xblock',handles,x)
    if ~isempty(y);
      y.includ{1} = cal;
      analysis('setobjdata','yblock',handles,y)
    end
  end

else
  %do NOT have calibration data
  if analysis('isloaded','model',handles)
    %we have a model, ignore any changes in the include field
    updatefigs = 1;
  end
end
  
if analysis('isloaded','validation_xblock',handles)
  %we have the validation x-block
  x = analysis('getobjdata','validation_xblock',handles);
  y = analysis('getobjdata','validation_yblock',handles);

  %any change in dim of interest?
  %if ~isempty(x) & (length(x.includ{sampmode,1}) ~= length(val) | any(x.includ{sampmode,1} ~= val));
  if ~isempty(x) & (length(x.includ{sampmode,1}) ~= length(val) | ~isempty(setdiff(x.includ{sampmode,1},val)))
    x.includ{sampmode,1} = val;
    analysis('setobjdata','validation_xblock',handles,x)
    if ~isempty(y);
      y.includ{1} = val;
      analysis('setobjdata','validation_yblock',handles,y)
    end
    if analysis('isloaded','prediction',handles)
      test.detail.rmsep = [];
      test.detail.includ{1,1} = val;
      analysis('setobjdata','prediction',handles,test);
      updatefigs = 1;
    end
  end
else
  %do NOT have validation data
  if analysis('isloaded','prediction',handles)
    %we have a model, ignore any changes in the include field
    updatefigs = 1;
  end
end
  
if updatefigs;
  updatefigures(handles.analysis);     %update any open figures
end

% --------------------------------------------------------------------
function scoresclasschange(h, keyword)

%input h is the handle of the analysis GUI
handles  = guidata(h);
sct      = strcmp(get(handles.showcalwithtest,'checked'),'on'); %1 if show cal w/ test
modl     = getsubmodel('model',handles);
shown    = getappdata(handles.showcalwithtest,'shown');
t        = analysis('getobjdata','scores',handles);
% scrs     = analysis('getobj','scores',handles);
% targfig = analysis('findpg',scrs,handles,'plotgui');
[targfig,fig] = plotgui('findtarget',gcbf);

%classesshown = getappdata(targfig,'viewclasses');
curset = getappdata(targfig,'viewclassset'); %get current class set being plotted
%have a cross-val class set
haveCV_class = find(contains(t.classname(1,:),'Cross-validation'));

if curset > haveCV_class
  curset_forXDSO =  curset-1;
else
  curset_forXDSO = curset;
end

curanal  = getappdata(handles.analysis,'curanal');
if ~isempty(keyword) & strcmp(keyword, 'create')
  addNewClass = 1;
else
  addNewClass = 0;
end

 fixCalSet = 0;
if addNewClass && shown(1) == 0 && shown(2) == 1
  fixCalSet = 1;
end


if ~ismember(lower(curanal),{'plsda' 'simca'});
  pushclasses = strcmp(getfield(analysis('options'),'pushclasses'),'on');
else
  %always push classes for this model type
  pushclasses = true;
end

if ~strcmpi(curanal,'mpca');
  sampmode = 1;
else
  sampmode = 3;
end

[cal,val] = sortselection(1:size(t,1),handles);
if ~isempty(cal);
  val = val+max(cal);  %create index into t (rather than index into x which is normal output from sortselection)
end

if shown(1) & pushclasses;
  %calibration data is shown - check classes (but only if pushing of
  %classes is enabled)
  x   = analysis('getobjdata','xblock',handles);
  if isempty(t.class{1,1})    %class of scores has been emptied? do an "empty" push of classes
    cal = [];
  end
  if addNewClass
    if isempty(x.class{sampmode,end})
      addToEnd = 0;
    else
      addToEnd = 1;
    end
    x.classname{sampmode,end+addToEnd} = t.classname{sampmode,end};
    x.classlookup{sampmode,end} = t.classlookup{sampmode,end};
    x.class{sampmode,end} = t.class{sampmode,end}(cal);
  elseif ~isempty(x) & (length(x.class{sampmode,curset}) ~= length(t.class{1,curset}(cal)) | any(x.class{sampmode,curset} ~= t.class{1,curset}(cal)));  %any change in dim of interest?
    x.classlookup{sampmode,curset_forXDSO} = t.classlookup{sampmode,curset};
    x.class{sampmode,curset_forXDSO}       = t.class{sampmode,curset}(cal);
  end
  analysis('setobjdata','xblock',handles,x)
end

if shown(2)
  %validation data
  x   = analysis('getobjdata','validation_xblock',handles);
  if isempty(t.class{1,1})    %class of scores has been emptied? do an "empty" push of classes
    val = [];
  end
  
  if addNewClass
    x.classname{sampmode,end+1} = t.classname{sampmode,end};
    x.classlookup{sampmode,end} = t.classlookup{sampmode,end};
    x.class{sampmode,end} = t.class{sampmode,end}(val);
  elseif ~isempty(x) & length(x.class{sampmode,curset}) ~= length(t.class{1,curset}(val)) | any(x.class{sampmode,curset} ~= t.class{1,curset}(val));  %any change in dim of interest?
    %copy classes into data
    x.classlookup{sampmode,1} = t.classlookup{1,1};
    x.class{sampmode,1}       = t.class{1,1}(val);
    

    %NOTE: code below is commented out because it could never be used. We
    %never get "true" in this test because the above setobj command will
    %ALWAYS clear the prediction object...
    %     if analysis('isloaded','prediction',handles);
    %       if ~strcmpi(curanal,'simca');
    %         %convey into prediction too
    %         test = getsubmodel('prediction',handles);
    %         test.detail.classlookup{sampmode,1} = t.classlookup{1,1};
    %         test.detail.class{sampmode,1} = t.class{1,1}(val);
    %         test.datasource{1} = getdatasource(x);
    %         if ~isempty(test.detail.data{1});
    %           test.detail.data{1} = x;
    %         end
    %         analysis('setobjdata','prediction',handles,test);
    %       else
    %         %do NOT attempt simple correction - just clear prediction
    %         analysis('setobjdata','prediction',handles,[]);
    %       end
    %     end

  end
  analysis('setobjdata','validation_xblock',handles,x)
  if fixCalSet
    x_cal = analysis('getobjdata', 'xblock', handles);
    x_cal.classname{sampmode,end+1} = t.classname{sampmode,end};
    x_cal.classlookup{sampmode,end} = x_cal.classlookup{sampmode,1};
    x_cal.class{sampmode,end} = x_cal.class{sampmode,1};
    analysis('setobjdata','xblock',handles,x_cal)
  end
    
end

% --------------------------------------------------------------------
function scoresaxissetchange(h, keyword)

%input h is the handle of the analysis GUI
handles  = guidata(h);
t        = analysis('getobjdata','scores',handles);
x        = analysis('getobjdata','xblock',handles);

[targfig,fig] = plotgui('findtarget',gcbf);
mode = getappdata(targfig, 'editAxis_mode');
axisSet =  getappdata(targfig, 'editAxis_set');

% if ~strcmpi(curanal,'mpca');
%   sampmode = 1;
% else
%   sampmode = 3;
% end

[cal,val] = sortselection(1:size(t,1),handles);
if ~isempty(cal);
  val = val+max(cal);  %create index into t (rather than index into x which is normal output from sortselection)
end

switch keyword
  case 'create'
    if axisSet == 1
      x.axisscalename{mode,axisSet} = t.axisscalename{mode,end};
      x.axisscale{mode,axisSet} = t.axisscale{mode,end}(cal);
    else
      x.axisscalename{mode,end+1} = t.axisscalename{mode,end};
      x.axisscale{mode,end} = t.axisscale{mode,end}(cal);
    end
  case 'modify'
    x.axisscalename{mode,axisSet} = t.axisscalename{mode,axisSet};
    x.axisscale{mode,axisSet} = t.axisscale{mode,axisSet}(cal);
end
analysis('setobjdata','xblock',handles,x)

% --------------------------------------------------------------------
function [cal,val] = sortselection(ind,handles)
% Sort a given set of selected scores samples into calibration and
% validation samples based on current plot settings

x           = analysis('getobjdata','xblock',handles);
modl        = getsubmodel('model',handles);
shown       = getappdata(handles.showcalwithtest,'shown');

if strcmpi(getappdata(handles.analysis,'curanal'),'mpca')
  sampmode = 3;
else
  sampmode = 1;
end

if shown(1)
  %calibration is present,
  if ~isempty(modl)
    if isfield(modl,'loads');
      mcal = size(modl.loads{1,1},1);
    else
      mcal = modl.datasource{1}.size(sampmode);
    end
  elseif ~isempty(x)
    mcal = size(x,sampmode);
  else  
    %no way to tell what is what so drop all points
    cal = []; 
    val = [];
    return
  end
  incal = ind<=mcal;
  cal   = ind(incal);
  if shown(2)
    % if both calibration AND validation are shown - ind corresponds to both cal and val
    val   = ind(~incal)-mcal;
  else
    % if only calibration is shown, don't alter validation include
    xval           = analysis('getobjdata','validation_xblock',handles);
    if ~isempty(xval)
      val = xval.include{1};
    else
      val = [];
    end
  end
else
  %not showing calibration? they HAVE to be validation samples
  val = ind;
  cal = [];
  return
end

% --------------------------------------------------------------------
function plotloads_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.plotloads.
% use only the icol variables in the dataset

if nargin<4 | isempty(varargin{1})
  sourcemode = 2;
else
  sourcemode = varargin{1};
end

undopre = getappdata(handles.analysis,'undoloadsprepro');
if isempty(undopre)
  undopre = 'no';
end

asca_submodel = getappdata(handles.analysis,'asca_submodel');

ldopts.plots = 'none';
ldopts.mode  = sourcemode;
ldopts.undopre = undopre;
ldopts.asca_submodel = asca_submodel;

a = plotloads(handles.analysis,ldopts);

modl = analysis('getobjdata','model',handles);

if any(strcmpi(modl.modeltype,{'pca' 'pcr' 'pls' 'cls' 'lwr' 'mcr' 'plsda'}))
  varcapstatus = 'on';
else
  varcapstatus = 'off';
end
if ~analysis('isloaded','xblock',handles);
  buttonstatus = 'off';
else
  buttonstatus = 'on';
end

numtag = [num2str(fix(double(handles.analysis)*10000))];
items = [];
items = setfield(items,['varcap' numtag],{
  'style','pushbutton','string','varcap', ...
  'enable',varcapstatus,...
  'userdata',double(handles.analysis),...
  'tooltip','Variance Captured on each variable by component.',...
  'callback',['pca_guifcn(''varcapbuttoncall'',gcbo,[],guidata(get(gcbo,''userdata'')))']});
items = setfield(items,['loadsdata' numtag],{
  'style','pushbutton','string','data',  ...
  'enable',buttonstatus,...
  'userdata',double(handles.analysis),...
  'tooltip','Plot raw data associated with a single variable.',...
  'callback',['pca_guifcn(''loadsdatabuttoncall'',gcbo,[],guidata(get(gcbo,''userdata'')))']});
items = setfield(items,['loadsinfo' numtag],{
  'style','pushbutton','string','info',  ...
  'enable',buttonstatus,...
  'userdata',double(handles.analysis),...
  'tooltip','Show raw data information associated with a single variable.',...
  'callback',['pca_guifcn(''loadsinfobuttoncall'',gcbo,[],guidata(get(gcbo,''userdata'')))']});

figname = ['Variables/Loadings' getappdata(handles.analysis,'figname_info')];

%special items depending on mode
switch lower(modl.modeltype)
  case 'mpca'
    %MPCA loadings are 3
    plotbymode = 3;
    %add Explore button
    items = setfield(items,['loadsexplore' numtag],{
      'style','pushbutton','string','explore',  ...
      'tooltip','Explore individual variables from the displayed item.',...
      'userdata',double(handles.analysis),...
      'callback',['mpca_guifcn(''loadsexplore'',gcbo,[],guidata(get(gcbo,''userdata'')))']});
    %set callbacks to point at MPCA
    callbackfcn = 'mpca';
    linkmap_data = [1 1];
    linkmap_loads = [1 1];
    myname = 'loads';    
    
  case 'parafac'
    %PARAFAC has user-selected mode ability
    plotbymode = 2;
    callbackfcn = 'pca';
    linkmap_data = [1 sourcemode];
    linkmap_loads = [sourcemode 1];
    myname = ['loads' num2str(sourcemode)];
    figname = sprintf('Mode %i Loadings%s',sourcemode,getappdata(handles.analysis,'figname_info'));
    
  case 'lregda'
    %LREGDA 
    plotbymode = 2;
    callbackfcn = 'pca';
    linkmap_data = [1 2];
    linkmap_loads = [2 1];
    myname = ['thetas' ];
    figname = ['Variables/Thetas' getappdata(handles.analysis,'figname_info')];
    
    items = setfield(items,['loadspre' numtag],{
      'style','checkbox','string','Undo Preprocessing',  ...
      'value',strcmp(undopre,'yes'),...
      'enable','on',...
      'userdata',double(handles.analysis),...
      'tooltip','Show loadings with preprocessing removed.',...
      'callback',['pca_guifcn(''toggleloadsprepro'',gcbo,[],guidata(get(gcbo,''userdata'')))']});
      
  otherwise
    %all other loadings use these settings
    plotbymode = 2;
    callbackfcn = 'pca';
    linkmap_data = [1 2];
    linkmap_loads = [2 1];
    myname = 'loads';
    
    items = setfield(items,['loadspre' numtag],{
      'style','checkbox','string','Undo Preprocessing',  ...
      'value',strcmp(undopre,'yes'),...
      'enable','on',...
      'userdata',double(handles.analysis),...
      'tooltip','Show loadings with preprocessing removed.',...
      'callback',['pca_guifcn(''toggleloadsprepro'',gcbo,[],guidata(get(gcbo,''userdata'')))']});

end

%handle subsetting of loadings
indexoffset_data  = {};
indexoffset_loads = {};
variableclass = [];
if getfield(analysis('options'),'splitclassedvars') & length(unique(a.class{1}))>1 & sourcemode==2
  %more than one class used in variables?
  classlist = a.classlookup{1};

  if length(varargin)<2
    %no variable group passed in?
    %give menu to user prompting for mode to show
    cmenu = findobj(handles.analysis,'tag','plotloadscontext');
    if isempty(cmenu)
      cmenu = uicontextmenu;
      set(cmenu,'tag','plotloadscontext');
    end
    delete(allchild(cmenu));
    uimenu(cmenu,'label','All Variables (One Plot)','callback',sprintf('pca_guifcn(''plotloads_Callback'',gcbf,[],guidata(gcbf),%i,[]);',sourcemode),'separator','off');
    sep = 'on';
    for j=1:size(classlist,1);
      if ismember(classlist{j,1},a.class{1})  %if this class is USED in the class set
        uimenu(cmenu,'label',[classlist{j,2} ' (only)'],'callback',sprintf('pca_guifcn(''plotloads_Callback'',gcbf,[],guidata(gcbf),%i,%i);',sourcemode,j),'separator',sep);
        sep = 'off';  %turn off after first item
      end
    end
    pos = get(handles.analysis,'position');
    set(cmenu,'position',[3 pos(4)])
    set(cmenu,'visible','on')
    drawnow;
    return
      
  end

  if ~isempty(varargin{2})
    %user selected one or more classes
    variableclass = varargin{2};
    useonly = find(ismember(a.class{1},classlist{variableclass,1}));
    reversemap = zeros(1,size(a,1));
    reversemap(useonly) = 1:length(useonly);
    indexoffset_data = repmat({reversemap},1,size(linkmap_data,1));
    indexoffset_loads = repmat({useonly},1,size(linkmap_data,1));
    a = a(useonly,:);
    myname = sprintf('loadsclass%i',variableclass);
    figname = sprintf('%s Loadings%s',classlist{variableclass,2},getappdata(handles.analysis,'figname_info'));
  end
end

%- - - - - - - - - - - - - - - - - - - - - - - - 
%add name and callback fns
myprops = [];
myprops.figurename = figname;
myprops.includechangecallback = [callbackfcn '_guifcn(''loadsincludchange'',h,myobj)'];
myprops.inforeqcallback      = 'pca_guifcn(''loadsinfobuttoncall_add'',datasource,targfig,listboxhandle)';
myprops.sourcemode        = sourcemode;
myprops.sourceindexoffset = indexoffset_loads;
myprops.variableclass     = variableclass;
myprops.helplink          = 'Model Building: Plotting Loads';

%set object data (or update)
myid = analysis('setobjdata',myname,handles,a,myprops);

%link to x-block (if there)
xdataid = analysis('getobj','xblock',handles);
if ~isempty(xdataid)
  linkshareddata(xdataid,'add',myid,'analysis',struct('linkmap',linkmap_data,'indexoffset',{indexoffset_data}));
  linkshareddata(myid,'add',xdataid,'analysis',struct('linkmap',linkmap_loads,'indexoffset',{indexoffset_loads}));
end

%See if there is a valid plotgui subscriber.
fighandle = analysis('findpg',myid,handles,'*');
if isempty(fighandle);
  plotsettings = {'name',figname,'plotby',plotbymode,'userdata',double(handles.analysis),'uicontrol',items, ...
    'plotcommand', 'plotloadslimits(targfig);',...
    'viewlabels',0,'controlby',getappdata(handles.analysis,'plotgui'),'axismenuvalues',{0 1},'viewaxislines',[1 1 1],...
    'validplotby',plotbymode};
  myid.properties.plotsettings = plotsettings;
  plotgui('new',myid,plotsettings{:});
else
  figure(min(double(fighandle)));
end

% --------------------------------------------------------------------
function toggleloadsprepro(h, eventdata, handles, varargin)
%Undo/redo prepro.

undopre = getappdata(handles.analysis,'undoloadsprepro');
if isempty(undopre) | strcmp(undopre,'no')
  undopre = 'yes';
else
  undopre = 'no';
end
setappdata(handles.analysis,'undoloadsprepro',undopre);

if ~analysis('isloaded','model',handles);
  %Exit quietly otherwise call below will error (ticket 888).
  return
end

plotloads_Callback(h,[],handles);

% --------------------------------------------------------------------
function varcapbuttoncall(h, eventdata, handles, varargin)
%VarCap - Note: warnings not given if h is 0 (zero) This is considered the
%  "automatic update" mode

modl = getsubmodel('model',handles);
if strcmp(getappdata(handles.analysis,'statmodl'),'none')
  if h~=0;
    evriwarndlg(['Model information not available.', ...
        ' Contributions cannot be calculated.'],'Plot Variance Captured')
  end
  return
end

x              = analysis('getobjdata','xblock',handles);
if isempty(x)
  if h~=0;
    evriwarndlg('Raw data not available from original calibration data.', ...
      'Plot Variance Captured')
  end
  return
end
x = preprocess('apply',modl.detail.preprocessing{1},x);  %preprocess before we remove vars    
if ~isempty(x.name)
  tlbl = sprintf(['Variance Captured for a %u LV Model of ',x.name],size(modl.loads{2,1},2));
else
  tlbl = sprintf('Variance Captured for a %u LV Model',size(modl.loads{2,1},2));
end

if ~isempty(x.axisscale{2,1})
  scl              = x.axisscale{2,1}(1,x.includ{2,1});
  if numel(scl)~=numel(unique(scl))
    evriwarndlg('Axis data values not unique, plotting against variable number.','Unique Axis Value Warning');
    scl              = x.includ{2,1};
  end
else
  scl              = x.includ{2,1};
end
if ~isempty(x.label{2,1})
  lbl              = deblank(x.label{2,1}(x.includ{2,1},:));
else
  lbl              = [];
end
if ~isempty(x.title{2,1})
  xlbl             = x.title{2,1};
elseif ~isempty(x.labelname{2,1})
  xlbl             = x.labelname{2,1};
else
  xlbl             = 'Variable';
end

%add code to do "auto-updating" varcap figures
fig = getappdata(handles.analysis,'varcapfig');
if isempty(fig) | ~ishandle(fig) | ~strcmp(getappdata(fig,'figuretype'),'varcap');
  fig = figure;
  setappdata(handles.analysis,'varcapfig',fig);
  setappdata(fig,'figuretype','varcap');
else
  figure(fig);
end
plots = 2;    %plot mode for varcap (2=plot on current figure)
vc = varcap(x.data(modl.detail.includ{1,1},modl.detail.includ{2,1}),modl,scl,plots);
title(tlbl)
s  = ' ';

%Find first subsciber to loadings data and see if its labels are turned on.
%If so, add varcap labels.
myid = analysis('findpg','loads',handles);
if ~isempty(myid) & ishandle(myid);
  myid = myid(1);%Just check first plot if there are multiple (might be good place for &&).
  switch getappdata(myid,'viewlabels')
    case 1
      labelset = getappdata(myid,'viewlabelset');
      lbl = x.label{2,labelset};
      if ~isempty(lbl)
        text(scl,max([zeros(1,length(scl)); vc(end,:)]), ...
          [s(ones(length(scl),1)) lbl(x.includ{2,1},:)], 'rotation',90)
      end
  end
end

analysis('adopt',handles,fig,'modelspecific');

% --------------------------------------------------------------------
function loadsdatabuttoncall(h, eventdata, handles, varargin)

cal_loaded  = analysis('isloaded','xblock',handles);
val_loaded  = analysis('isloaded','validation_xblock',handles);
modl        = getsubmodel('model',handles);

if ~cal_loaded & ~val_loaded
  evriwarndlg('Calibration or test data must be available to drill down.','Data Drill-Down')
  return
end
if nargin<4;
  %button callback - no sample indicated, use gselect to get sample
  fig = getappdata(get(h,'parent'),'target');
  figure(fig);
  viewexcluded = getappdata(fig,'viewexcludeddata');
  viewlabels   = getappdata(fig,'viewlabels');
  if ~isempty(modl) & strcmp(lower(modl.modeltype),'mpca');
    [ii,ij] = gselect('x');
    selmode = 3;
  else
    mode = getappdata(fig,'selectionmode');
    if isempty(mode); mode = 'rbbox'; end
    ii = gselect(mode,finddataobj,...
      struct('modal','true','helptextpre','View Raw Data:','helptextpost','Hold down [Shift] to add to currently viewed raw data.'));
    if isempty(ii); return; end
    for k=2:length(ii); if length(ii{1})==length(ii{k}); ii{1} = or(ii{1},ii{k}); end; end
    ii                 = find(ii{1});
    selmode = 2;
  end
  selectiontype = get(fig,'selectiontype');
  
  setplotselection(fig,ii);

else
  %items to show were passed in (not called by plotgui) don't select
  ii = varargin{1};
  if nargin<5
    selectiontype = 'extend';
  else
    selectiontype = varargin{2};
  end
  viewexcluded = 0;
  viewlabels = 0;
  if ~isempty(modl) & strcmp(lower(modl.modeltype),'mpca');
    selmode = 3;
  else
    selmode = 2;
  end
end
if isempty(ii); return; end

for block = {'xblock' 'validation_xblock'};
  if analysis('isloaded',block{:},handles);
    
    if strcmp(block,'xblock')
      name = 'Calibration X-Block';
    else
      name = 'Validation X-Block';
    end
    
    myid = analysis('getobj',block{:},handles);
    %Find a plotgui figure that's pointing at an x-block.
    target = analysis('findpg',myid);

    if isempty(target); %no existing figure found, create new
      targetcode = {'new',myid};
    else
      targetcode = {'update','figure',target};  %cell will be expanded in plotgui line
      %see if we already had some points selected in current data
      if getappdata(target,'plotby')==selmode && strcmp(selectiontype,'extend')
        current_selection = getappdata(target,'axismenuindex');
        ii = union(ii,current_selection{2});
      end
    end

    plotgui(targetcode{:},'axismenuvalues',{0 ii},'viewexcludeddata',viewexcluded,'viewlabels',viewlabels,'plotby',selmode,'name',name)
  end
end
% --------------------------------------------------------------------
function loadsinfobuttoncall(h, eventdata, handles, varargin)
%Get info on selection in loads plot.

if strcmp(getappdata(handles.analysis,'statmodl'),'none')
  evriwarndlg(['Model information not available.'],'Plot Loads')
  return
end

targfig = getappdata(get(h,'parent'),'target');
figure(targfig);
ii                 = gselect('nearest',finddataobj,1);
if isempty(ii); return; end
for k=2:length(ii); if length(ii{1})==length(ii{k}); ii{1} = or(ii{1},ii{k}); end; end
ii                 = find(ii{1});
if isempty(ii); return; end

newselection = setplotselection(targfig,ii);    %mark these items as selected in plot
plotgui('getselectioninfo',targfig,[],newselection)

% --------------------------------------------------------------------
function loadsinfobuttoncall_add(h,targfig,listboxhandle);

handles = guidata(h.source);
modl = getsubmodel('model',handles);

for ii=h.properties.selection{1};
  s{1}             = ''; s = s(ones(5,1));
  if analysis('isloaded','xblock',handles)
    x              = analysis('getobjdata','xblock',handles);
    s{4}           = sprintf('test data mean = %4.3g',mean(x.data(:,ii)));
    s{5}           = sprintf('test data std  = %4.3g',std(x.data(:,ii)));
  end
  if isfieldcheck(modl,'modl.detail.means') & ~isempty(modl.detail.means) & length(modl.detail.means{1})>=ii
    s{2}             = sprintf('calibration mean = %4.3g',modl.detail.means{1}(ii));
  end
  if isfieldcheck(modl,'modl.detail.stds') & ~isempty(modl.detail.stds) & length(modl.detail.stds{1})>=ii
    s{3}             = sprintf('calibration std  = %4.3g',modl.detail.stds{1}(ii));
  end
  
  s_orig = get(listboxhandle,'string');
  set(listboxhandle,'string',{s_orig{:},s{2:end}});
  
end

% --------------------------------------------------------------------
function loadsincludchange(h,myobj,block)

if nargin<3
  block = 'x';
end

switch block
  case 'x'
    block_ind = 1;
    loads_name = 'loads';
  case 'y'
    block_ind = 2;
    loads_name = 'yloads';
end

handles = guidata(h);
modl    = getsubmodel('model',handles);
x       = analysis('getobjdata',[block 'block'],handles);
indexoffset = {};

if nargin>1
  %passed an object? use its info (including the "sourcemode" value)
  p = myobj.object;
  sourcemode = myobj.properties.sourcemode;
  if isempty(sourcemode);
    sourcemode = 2;
  end
  if isfield(myobj.properties,'sourceindexoffset')
    indexoffset = myobj.properties.sourceindexoffset;
    switch length(indexoffset)
      case 0
        %do nothing
      case 1
        indexoffset = indexoffset{1};
      otherwise
        indexoffset = {};  %more than one block? treat as "no model"
        x = [];
    end
  end
else
  %assume standard loadings
  p = analysis('getobjdata',loads_name,handles);
  sourcemode = 2;
end

if ~isempty(x) & ~strcmp(getappdata(handles.analysis,'statmodl'),'loaded');
  pinclude = p.includ{1,1};
  joinedinclude = pinclude;   %default is that x and p match so just copy all include
  xinclude  = x.includ{sourcemode};
  
  if ~isempty(indexoffset)
    %if we have a indexoffset map, use that to adjust
    pinclude = indexoffset(pinclude);   %translate from loadings to data include
    
    %create logical map of included vars on x
    xisincluded = false(1,size(x,sourcemode));
    xisincluded(setdiff(xinclude,indexoffset)) = true;  %keep as-is regions NOT USED by these loadings
    xisincluded(pinclude) = true;  %mark regions NOW SET on these loadings
    joinedinclude = find(xisincluded);
    
    %downsample xinclude to ONLY be the items of interest
    xinclude = intersect(xinclude,indexoffset); 
    
  end
  
  if length(xinclude) ~= length(pinclude) | any(xinclude ~= pinclude);  %any change in dim of interest?
    x.includ{sourcemode} = joinedinclude;
    analysis('setobjdata',[block 'block'],handles,x)
    analysis('autoclear',handles)
    analysis('clearmodel',handles.analysis,[],handles)
  end
else    %model was "loaded" don't change included variables
  modlinclude = modl.detail.includ{sourcemode,block_ind};
  if ~isempty(indexoffset)
    %if indexoffset was used, set include to whichever of those are present
    %in model
    modlinclude = intersect(modlinclude,indexoffset);
    modlinclude = find(ismember(indexoffset,modlinclude));
  end    
  p.includ{1,1} = modlinclude;
  analysis('setobjdata',loads_name,handles,p)
end

% --------------------------------------------------------------------
function biplot_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.biplot.


analopts = analysis('options');

modl = getsubmodel('model',handles);
test = getsubmodel('prediction',handles);
sct  = strcmp(get(handles.showcalwithtest,'checked'),'on'); %1 if show cal w/ test

%convert compact PCA_PRED structure to expected "full model" fieldnames and format
if isfield(test,'scores');
  test.loads = {test.scores};
  test.pred  = {test.pred};
  test.tsqs  = {test.tsqs};
  test.ssqresiduals = {test.ssqresiduals};
end

if isempty(modl.detail.ssq)
  erdlgpls('Cannot view Biplot for models with zero components','BiPlot Error')
  return
end

%scores
norms = [];
scalefac = [];
if ~isempty(modl)
  %precalculate norms and scalefac from calibration data
  [~, norms, scalefac] = normscores(modl, [], []);
end

if ~isempty(test);
  % Use calibration norms and scaling if available
  [a, norms, scalefac] = normscores(test, norms, scalefac);
  a = dataset(a);
  a      = copydsfields(test,a,1,1);
  a.name = test.datasource{1}.name;
  if isempty(a.name);
    a.name   = 'Validation';
  end
  a.title{1} = ['Biplot of ',a.name];
  cls = ones(1,size(a,1))*2;
else
  a = [];
  cls = [];
end

if ~isempty(modl) & (isempty(test) | sct)
  %if test isn't present or Show Cal With Test is on...
  b = normscores(modl, [],[]);
  b = dataset(b);
  b    = copydsfields(modl,b,1,1);
  temp = modl.datasource{1}.name;
  if isempty(temp);
    temp = 'Calibration';
  end
  if isempty(a);
    b.name = temp;
  else
    b.name   = [temp,' & ',a.name];
  end
  b.title{1} = ['Biplot of ',b.name];
  cls        = [cls ones(1,size(b,1))];

  if isempty(a)
    a = b;
  else
    %we are showing both cal and test
    a = [a;b];        
  end
end

pc  = size(modl.loads{2,1},2);
lbl = cell(pc,1);
for ii=1:pc
  switch lower(modl.modeltype)
    case 'pca'
      lbl{ii} = sprintf('PC %u (%0.2f%%)',ii,modl.detail.ssq(ii,3));
    case 'pcr'
      lbl{ii} = sprintf('PC %u (%0.2f%%)',ii,modl.detail.ssq(ii,2));
    case {'pls' 'plsda'}
      lbl{ii} = sprintf('LV %u (%0.2f%%)',ii,modl.detail.ssq(ii,2));
    otherwise
      lbl{ii} = sprintf('Comp %u (%0.2f%%)',ii,modl.detail.ssq(ii,2));
  end  
end
a.label{2,1} = lbl;

%X loadings
icol        = modl.detail.includ{2,1};
if strcmpi(modl.modeltype,'purity')
  nvars     = modl.datasource{1}.size(2);
else
  nvars     = prod(modl.datasource{1}.size(2:end));
end
b           = zeros(nvars,size(modl.loads{2,1},2));
b(icol,:)   = modl.loads{2,1};    %insert around nan's (to match original data var #)
b           = dataset(b);
b           = copydsfields(modl,b,{2 1},1);

m      = length(modl.detail.includ{1,1});
eig    = modl.detail.ssq(1:size(modl.loads{2,1},2),2);
a.data = a.data*diag(sqrt(eig*(m-1))/(m-1));
b.data = b.data*diag(sqrt(eig*(m-1))/(m-1));
if ~strcmpi(a.type,b.type)
  a.type = 'data';
  b.type = 'data';
end
a      = [a; b];
cls    = [cls ones(1,size(b,1))*3];

%Y loadings
if analopts.showyinbiplot & length(modl.datasource)>1 & ~isempty(modl.datasource{2}.include_size) & size(modl.loads,2)>1
  %if we have a y-block
  icol        = modl.detail.includ{2,2};
  nvars       = modl.datasource{2}.size(2);
  b           = zeros(nvars,size(modl.loads{2,2},2));
  b(icol,:)   = modl.loads{2,2};    %insert around nan's (to match original data var #)
  b           = b./max(abs(b(:)))./length(icol);
  b           = dataset(b);
  b           = copydsfields(modl,b,{2 1},{2 1});
  
  m      = length(modl.detail.includ{1,1});
  eig    = modl.detail.ssq(1:size(modl.loads{2,1},2),2);
  b.data = b.data*diag(sqrt(eig*(m-1))/(m-1));
  a      = [a; b];
  cls    = [cls ones(1,size(b,1))*4];
end

%add classes to show what is what
%search for empty cell to store cal/test classes
j = 1;
while j<=size(a.class,2);
  if isempty(a.class{1,j});
    break;
  end
  j = j+1;
end
a.class{1,j} = cls;  %store classes there
a.classlookup{1,j} = {1 'Calibration sample scores';2 'Validation sample scores';3 'X-Block Loadings'; 4 'Y-Block Loadings' };
a.classname{1,j} = 'Cal/Val Scores/Loadings';
descclass = j;

if pc==1
  axmenval         = {1 1};
else
  axmenval         = {1 2};
end

if isempty(test)
  a.history = sprintf('Biplot for model "%s"',uniquename(modl));
else
  a.history = sprintf('Biplot for model "%s" and predictions "%s"',uniquename(modl),uniquename(test));
end

if j>1
  a = modBiplotClassIDs(a, j);
end

%- - - - - - - - - - - - - - - - - - - - - - - - 
%generate figure specific information
figname = ['Biplot' getappdata(handles.analysis,'figname_info')];
truebiplottag = ['truebiplot' num2str(fix(double(handles.analysis)*10000))];
loadingsorigintag = ['loadingsorigin' num2str(fix(double(handles.analysis)*10000))];

%See if there is a valid plotgui subscriber.
fighandle = analysis('findpg','biplot',handles);
truebiplot = 1;  %default setting for true biplot checkbox
if ~isempty(fighandle)
  tbphandle = findobj(getappdata(fighandle(1),'controlby'),'tag',truebiplottag);
  if ~isempty(tbphandle);
    truebiplot = get(tbphandle,'value');
  end
end

loadings2origin = 0;
if ~isempty(fighandle)
  l2ohandle = findobj(getappdata(fighandle(1),'controlby'),'tag',loadingsorigintag);
  if ~isempty(l2ohandle);
    loadings2origin = get(l2ohandle,'value');
  end
end

%add name and callback fns
myprops = [];
myprops.figurename = figname;
myprops.trueBiPlot = truebiplot;
myprops.loadingsToOrigin = loadings2origin;

%set object data (or update)
myid = analysis('setobjdata','biplot',handles,a,myprops);

%turn on/off sct checkbox
if ~analysis('isloaded','prediction',handles)
  enb = 'off';
else
  enb = 'on';
end

%- - - - - - - - - - - - - - - - - - - - - - - - - -
scttag = ['sct' num2str(fix(double(handles.analysis)*10000))];
if isempty(fighandle)
  %controls for figure
  items = [];
  items.temp = 'a';
  items = setfield(items,scttag,...
    {'style','checkbox','string','Show Cal Data with Test','userdata',[double(handles.analysis)],...
    'tooltip','Show calibration data along with test data.',...
    'enable',enb,'callback',['analysis(''showcalwithtest'',get(gcbo,''userdata''),[],guidata(get(gcbo,''userdata'')))']});
  items = setfield(items,truebiplottag,...
    {'style','checkbox','string','True Biplot','userdata',[double(handles.analysis)],...
    'enable','on','value',truebiplot,...
    'tooltip','Scale axes equally to give true orthogonal-axis biplot.',...
    'callback',['pca_guifcn(''truebiplot'',get(gcbo,''userdata''),[],guidata(get(gcbo,''userdata'')))']});
  items = setfield(items,loadingsorigintag,...
    {'style','checkbox','string','Loadings To Origin','userdata',[double(handles.analysis)],...
    'enable','on','value',0,...
    'tooltip','Include lines drawn from loadings points to origin.',...
    'callback',['pca_guifcn(''biplot_connectorigin'',get(gcbo,''userdata''),[],guidata(get(gcbo,''userdata'')))']});

  items = rmfield(items,'temp');

  plotcommand = 'plotbiplotlimits(targfig);';

  plotsettings = {'name',figname,'plotby',2,'viewclasses',1,'viewclassset',descclass,'viewlabels',0,'uicontrol',items, ...
    'plotcommand', plotcommand, 'viewaxislines', [1 1 1],'validplotby',[2],...
    'axismenuvalues',axmenval,'noinclude',1,'vsindex',[0 0]};
  myid.properties.plotsettings = plotsettings;
  
  bh = plotgui('new',myid,plotsettings{:},'controlby',getappdata(handles.analysis,'plotgui'));
else
  set(findobj(getappdata(fighandle(1),'controlby'),'tag',scttag),'value',sct,'enable',enb)
  figure(fighandle(1));
end

%-------------------------------------------------
function dobj = finddataobj
%locate data userdata object (including looking for hidden handle)
dobj = findobj(gca,'userdata','data');
if isempty(dobj)
  dobj = findobj(allchild(gca),'userdata','data');
end


%-------------------------------------------------
function [scrs, norms, scalefac] = normscores(modl, norms, scalefac)
% Normalize scores per PC
% and scale scores by scores array aspect ratio
scrs = modl.loads{1,1};
if isempty(norms)
  inclscrs = scrs(modl.detail.includ{1,1},:);  %keep only included scores
  inclscrs = inclscrs(all(isfinite(inclscrs),2),:);  %keep only finite scores
  [inclscrs,norms] = normaliz(inclscrs');
end
scrs = scale(scrs,zeros(1,size(scrs,2)),norms');

if isempty(scalefac)
  scalefac = sqrt(length(modl.detail.includ{1,1})./length(modl.detail.includ{2,1}));
end
scrs = scrs.*scalefac;


%-------------------------------------------------
function openimagegui_Callback(h,eventdata,handles,varargin)
%Callback for opening imagegui.
drawnow; %Fix matlab bug with draw queue.
modl = getsubmodel('model',handles);
h = imagegui(modl);
if ~isempty(varargin) %Reposition.
  set(h,'position',varargin{1});
end
setappdata(handles.openimagegui,'children',h);

%-------------------------------------------------
function updatessqtable(handles,pc)

options = pca_guifcn('options');
modl    = getsubmodel('model',handles);
rawmodl = getsubmodel('rawmodel',handles);
mytbl   = getappdata(handles.analysis,'ssqtable');
%setbackground(mytbl,'table',[],'white')

%Add auto select button enable here becuase this function is called by
%analysis every time data is changed.
if ~analysis('isloaded','xblock',handles);
  set(handles.findcomp,'enable','off')
else
  set(handles.findcomp,'enable','on')
end

if isempty(modl)
  %Show empty 4 columns.
  clear(mytbl);%Clear data.
  %set(handles.ssqtable,'String',{},'Value',1,'Enable','off')
  set(handles.pcsedit,'String','','Enable','inactive')
  return
end
if isempty(rawmodl)
  rawmodl = modl;
end

%PCs not given? assume max from model
if nargin<2
  pc = size(modl.loads{2});
  pc = pc(end);
end

%Find max length of table.
maxoption = options.maximumfactors;
curlentable = size(mytbl.data,1);%length(get(handles.ssqtable,'string'));
editpcsvalue = getappdata(handles.pcsedit,'default');
%Edit pcs may be empty, change to 0 if empty so if statemets below work correctly.
if isempty(editpcsvalue)
  editpcsvalue = 0;
end

maxpc = max([maxoption, curlentable, editpcsvalue, pc]);
maxcalcpc = min([size(rawmodl.detail.ssq,1); maxpc]);

if exist('choosecomp.m','file')==2 && strcmp(options.autoselectcomp,'on')
  suggestedpc = choosecomp(modl);
else
  suggestedpc = [];
end

[ssq_table,column_headers,column_format] = getssqtable(rawmodl,maxcalcpc,'raw',11,true);
ssq_table = [ssq_table repmat({' '},size(ssq_table,1),1)];
column_headers{end+1} = '<html>Status</html>';
column_format{end+1} = '';

% Fill out rest of SSQ table.
statmodl = lower(getappdata(handles.analysis,'statmodl'));
opts = getappdata(handles.analysis,'analysisoptions');
if isempty(opts);
  opts = pca('options');
end

if isfield(opts,'algorithm') & ~isempty(findstr(opts.algorithm , 'robust')) & ~strcmp(statmodl,'loaded')
  for jj=maxcalcpc+1: maxpc
    ssq_table{jj,end} = 'not calculated';
  end
end

%don't allow > # of evs
if pc > maxpc;
  pc = 1; 
end

if ~isempty(suggestedpc)
  ssq_table{suggestedpc,end} = 'suggested';
end

if ~isempty(suggestedpc) && suggestedpc==pc
  ssq_table{pc,end} = 'current*';
else
  ssq_table{pc,end} = 'current';
end

mytbl.data = ssq_table;
mytbl.column_labels = column_headers;
mytbl.column_format = column_format;

%Make selection the current PC.
setselection(mytbl,'rows',pc)

%Indicate current PC.
set(handles.pcsedit,'String',int2str(pc),'Enable','inactive')
if ~isempty(getappdata(handles.pcsedit,'default'))
  setappdata(handles.pcsedit,'default',pc);
end

% --------------------------------------------------------------------
function truebiplot(h,eventdata,handles, varargin)
%True Biplot checkbox CallBack

myid = analysis('getobj','biplot',handles);
myid.properties.trueBiPlot = ~myid.properties.trueBiPlot;

% --------------------------------------------------------------------
function biplot_connectorigin(h,eventdata,handles, varargin)
%Plot loadings to origin checkbox CallBack

myid = analysis('getobj','biplot',handles);
myid.properties.loadingsToOrigin = ~myid.properties.loadingsToOrigin;

% --------------------------------------------------------------------
function obj = getsubmodel(myitem,handles)
%Get a submodel if needed (e.g., batchmaturity).

thisobj = analysis('getobjdata',myitem,handles);

if strcmpi(getappdata(handles.analysis,'curanal'),'batchmaturity') &...
    ~isempty(thisobj) & (strcmpi(myitem,'model') | strcmpi(myitem,'rawmodel') | strcmpi(myitem,'prediction'))
  obj = thisobj.submodelpca;
else
  obj = thisobj;  
end

%----------------------------------------------------
function  optionschange(h)
%Add code here for options change of method. Often used by panelmanager.


%--------------------------------------------------------------------
function out = modBiplotClassIDs(in, lastSet)
% add Loadings designations to class sets other than the last
indsX = ~cellfun(@(x)isempty(x), regexp(in.classid{1, lastSet}, 'X-Block Loadings'));
indsY = ~cellfun(@(x)isempty(x), regexp(in.classid{1, lastSet}, 'Y-Block Loadings'));
pttrn = '^Class\s{1,}[0-9]{1,}$';
for classInd = lastSet-1:-1:1
  curClassID = in.classid{1, classInd};
  modClassID = curClassID(indsX);
  subInds    = ~cellfun(@(x)isempty(x), regexp(modClassID, pttrn));
  %  rationale:  indsX and indsY are the indices for the x-block
  %  and y-block variables, respectively  
  %  modClassID is the extraction of the class IDs of those entries in the
  %  dataset for class sets other than the last one . . . the last class
  %  set is the one created specifically for biplots
  %  these samples will have classes carried over by from the original
  %  dataset and the variables will have their own classes carried over by
  %  means of copydsfields (if the variables have classes)
  %  variables _not_ having other class information will be designated as
  %  Class 0, Class 1, etc (again, through copydsfields)
  %  here we check for variables (x-block or y-block) designated as Class
  %  0, Class 1, . . . and replace these class IDs as "loadings - x" or
  %  "loadings - y" as appropriate
  %  if the variables have specified class assignments from the original
  %  datasets, then "(loadings - x)" or "(loadings - y)" are appended to
  %  the original class IDs.
  if any(subInds)
    subModClassID = modClassID(subInds);
    subModClassID(subInds) = {'loadings - x'};
    modClassID(subInds) = subModClassID;
  end

  subInds = ~subInds;

  if any(subInds)
    subModClassID = modClassID(subInds);
    subModClassID(subInds) = cellfun(@(x)sprintf('%s (loadings - x)', x),...
      subModClassID(subInds), 'uni', false);
    modClassID(subInds) = subModClassID;
  end

  curClassID(indsX) = modClassID;
  if any(indsY)
    modClassID = curClassID(indsY);
    subInds    = ~cellfun(@(x)isempty(x), regexp(modClassID, pttrn));
    if any(subInds)
      subModClassID = modClassID(subInds);
      subModClassID(subInds) = {'loadings - y'};
      modClassID(subInds) = subModClassID;
    end

    subInds = ~subInds;
    if any(subInds)
      subModClassID = modClassID(subInds);
      subModClassID(subInds) = cellfun(@(x)sprintf('%s (loadings - y)', x), ...
        subModClassID(subInds), 'uni', false);
      modClassID(subInds) = subModClassID;
    end
    curClassID(indsY) = modClassID;
  end
  in.classid{1, classInd} = curClassID;
end

out = in;
