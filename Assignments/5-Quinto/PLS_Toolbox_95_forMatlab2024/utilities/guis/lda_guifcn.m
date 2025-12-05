function varargout = lda_guifcn(varargin);
%LDA_GUIFCN LDA Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

try
  if nargout == 0;
    
    feval(varargin{:}); % FEVAL switchyard
  else
    [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    
  end
catch
  erdlgpls(lasterr,[upper(mfilename) ' Error']);
end  
end

%----------------------------------------------------
function gui_init(h,eventdata,handles,varargin)

%create toolbar
[atb,abtns] = toolbar(handles.analysis, 'lda','');
handles  = guidata(handles.analysis);
analysis('toolbarupdate',handles);

%change pc edit label.
set(handles.pcseditlabel,'string','Number LVs:')
% %Change PCs to Nodes.
% set(handles.pcseditlabel,'string','Number Nodes:')

%Get gui options
roptions = plsda_guifcn('options');

%change pc edit box to text box.
set(handles.pcsedit,'style','text')
%
mytbl = getappdata(handles.analysis,'ssqtable');
mytbl = ssqsetup(mytbl,{'Eigenvalue' 'X-Block<br>LV' 'X-BLock<br>Cumulative' ' '},...
  '<b>&nbsp;&nbsp;&nbsp;LV',{'%6.2f' '%6.2f' '%6.2f' ''},1);

set(handles.tableheader,'string','Percent Variance Captured by Model (* = suggested)','HorizontalAlignment','center');

%turn off valid crossvalidation
setappdata(handles.analysis,'enable_crossvalgui','on');
crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'Nodes L1')

% Need to hack options into analysis before call to add panel because 
% panel depends on options being there.
opts = analysis('getoptshistory',handles,'lda');
if isempty(opts)
  opts = getoptions(handles);
end
setappdata(handles.analysis, 'analysisoptions',opts);

%Add view selections to dropdown.
panelinfo.name = 'SSQ Table';
panelinfo.file = 'ssqtable';
panelinfo(2).name = ['LDA Settings'];
panelinfo(2).file = 'ldagui';
panelmanager('add',panelinfo,handles.ssqframe)

handles = guihandles(handles.analysis);
guidata(handles.analysis,handles);

%Update number of nodes.
optionschange(handles.analysis)

%general updating
analysis('updatestatusboxes',handles)

updatefigures(handles.analysis);     %update any open figures
reg_guifcn('updatessqtable',handles)
end

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
closefigures(handles);

%Set crossval gui to default.
setappdata(handles.analysis,'enable_crossvalgui','on');
%Update cvgui.
analysis('updatecrossvallimits',handles)

%Set name back to PCs.
set(handles.pcseditlabel,'string','Number PCs:') %change pc edit label.

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)
%Clear table.
mytbl = getappdata(handles.analysis,'ssqtable');
clear(mytbl,'all');
end

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)
%Update toolbar buttons enabled and or shown.

if strcmpi(getappdata(handles.analysis,'statmodl'),'none')
  analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);
else
  analysis('panelviewselect_Callback',handles.panelviewselect,[],handles,1);
end

% from xgb
myanal = getappdata(handles.analysis,'curanal');

choosegrps = findobj(handles.analysis,'tag','choosegrps');
showconfusion = findobj(handles.analysis,'tag','showconfusion');
daonly = [showconfusion choosegrps];
if strcmp(myanal,'lda')
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
% out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;
end

%--------------------------------------------------------------------
function out = isyused(handles)
%Must have Y.

out = true;
end

%----------------------------------------------------
function  calcmodel_Callback(h,eventdata,handles,varargin);
%LDA Calculate model, uses similar code from reg_guifcn.

ldamode = getappdata(handles.analysis,'curanal');
statmodl = lower(getappdata(handles.analysis,'statmodl'));
if strcmp(statmodl,'calnew') & ~analysis('isloaded','rawmodel',handles)
  statmodl = 'none';
end

mytbl    = getappdata(handles.analysis,'ssqtable');

if strcmp(statmodl,'none') | strcmp(statmodl,'calnew');
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
      if strcmpi(ldamode,'lda')
        erdlgpls('A y-block must be loaded to perform regression. Can not calibrate','Calibrate Error');
      else
        erdlgpls('Classes must be supplied in the X-block samples mode, or a y-block designating class membership must be loaded. Can not calibrate','Calibrate Error');
      end
      return
    end
    
    if mdcheck(x);
      ans = evriquestdlg({'Missing Data Found in X-block - Replacing with "best guess"','Results may be affected by this action.'},'Warning: Replacing Missing Data','OK','Cancel','OK');
      if ~strcmp(ans,'OK'); return; end
      drawnow;
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

    y = analysis('getobjdata','yblock',handles);
    if ~isempty(y)
      %check for missing data in y-block
      nans = any(isnan(y.data(y.include{1},y.include{2})),2);
      if all(nans)
        erdlgpls('All y-block rows contained missing data. Can not calibrate','Calibrate Error');
        return;
      end
      if any(nans);
        evrimsgbox({'Missing Data Found in Y-block - Excluding all samples with missing y-block values.'},'Warning: Excluding Missing Data Samples','warn','modal');
        y.include{1} = intersect(y.include{1},y.include{1}(find(~nans)));
        analysis('setobjdata','yblock',handles,y);    %and save back to object
      end
      if isempty(y.includ{1});
        erdlgpls('All y-block rows excluded. Can not calibrate','Calibrate Error');
        return
      end
      if isempty(y.includ{2});
        erdlgpls('All y-block columns excluded. Can not calibrate','Calibrate Error');
        return
      end

      isect = intersect(y.include{1},x.include{1}); %intersect samples includ from x- and y-blocks
      if length(x.include{1})~=length(isect) | length(y.include{1})~=length(isect);  %did either change?
        y.include{1} = isect;
        analysis('setobjdata','yblock',handles,y);   %and save back to object
        x.include{1} = isect;
        analysis('setobjdata','xblock',handles,x);    %and save back to object
      end
    else
      %     if isempty(y);
%       if strcmpi(ldamode,'lda');
%         erdlgpls('No y-block information is loaded. Can not calibrate','Calibrate Error');
%         return
%       end
      
      %no y-block, check for modelgroups from user selecting items to group
      modelgroups = getappdata(findobj(handles.analysis,'tag','choosegrps'),'modelgroups');
      if ~isempty(modelgroups)
        y = modelgroups;
      else
        y = {};  %no groups, no y, use classes as-is
      end
    end

    minlv = getselection(mytbl,'rows');
    
    preprocessing = {getappdata(handles.preprocessmain,'preprocessing') getappdata(handles.preproyblkmain,'preprocessing')};
       
    if ~strcmpi('lda', ldamode) & ~isempty(y) & all(all(y.data(y.includ{1},:) == y.data(y.includ{1}(1),1)));
      erdlgpls('All y values are identical - can not do regression analysis','Calibrate Error');
      return
    end

  try
    opts = getoptions(handles);
    % set the row in the ssqtable to be the number of components in the
    % model
    % upon first calibration, minlv will always be 1 but default for LDA is
    % 3 comps. so
    if isfinite(minlv)
      modl = analysis('getobjdata','model',handles);
      if ~isempty(modl)
        % user wants to build with different number of components, update
        % ncomp
        opts.ncomp = minlv;
      end
    end
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

    switch ldamode
      case 'lda'
        if isempty(y)
          modl      = lda(x,opts);
        else
          modl      = lda(x,y,opts);
        end
    end
    
    drawnow;
    
  catch
    erdlgpls({'Error using LDA',lasterr},'Calibrate Error');
    return
  end

  % Do cross-validation 
  if ~strcmp(cvmode,'none')
    modl = crossvalidate(handles.analysis,modl);
  end
   
  %UPDATE GUI STATUS
  setappdata(handles.analysis,'statmodl','calold');
  analysis('setobjdata','model',handles,modl);
  
  %Never use raw model, SEE ABOVE.
  analysis('setobjdata','rawmodel',handles,[]);
  
  handles = guidata(handles.analysis);

  figure(handles.analysis)
  
  
  switch ldamode
    case 'lda'
      updatessqtable(handles,modl.ncomp)
  end
end


if analysis('isloaded','validation_xblock',handles)
  %apply model to test data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
  if isempty(x); return; end  %some cancel action

  try
    opts = getoptions(handles);
    switch ldamode

      case 'lda'
        if isempty(y)
          test = lda(x,modl,opts);
        else
          test = lda(x,y,modl,opts);
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
end

% --------------------------------------------------------------------
function plotscores_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.plotscores.
%I/O: plotscores_Callback(h,[],handles,extracmds)
%  where extracmds is cell to be expanded and passed to plotgui

pca_guifcn('plotscores_Callback',h,eventdata,handles,varargin{:});
end

% --------------------------------------------------------------------
function ploteigen_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ploteigen.
end

%----------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.
% ssqtable value and pcsedit string updated by updatessqtable.

pca_guifcn('ssqtable_Callback',h,[],handles);
end

%----------------------------------------------------
function  pcsedit_Callback(h, eventdata, handles, varargin)
end

%----------------------------------------------------
function  optionschange(h)
%Updates after options have changed.
end


% --------------------------------------------------------------------
function [modl,success] = crossvalidate(h,modl,perm)
%CrossValidationGUI CrossValidateButton CallBack

handles  = guidata(h);

success  = 0;  %indicates failure

if nargin<3
  perm = 0;
end

x        = analysis('getobjdata','xblock',handles);
y        = modl.detail.data{2};
mc       = modl.detail.preprocessing;

[cv,lv,split,iter,cvi] = crossvalgui('getsettings',getappdata(h,'crossvalgui'));
if strcmp(cv,'none')
  return;
end

opts = [];
opts.preprocessing = mc;
opts.display = 'off';
opts.plots = 'none';

if perm>0
  opts.permutation = 'yes';
  opts.npermutation = perm;
%   lv = modl.detail.options.lambda;
end

% limit to the max that will be useful, nclasses-1
lv = modl.detail.lda.numClasses-1;
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
end

%--------------------------------------------------------------------
function updatefigures(h)

pca_guifcn('updatefigures',h);
end

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
end

%-------------------------------------------------
function updatessqtable(handles,varargin)
%Update SSQ table. 
if nargin>1
  pc = varargin{1};
else
  pc = Inf; % needs to be non-empty. It will be reduced later.
end

% pca_guifcn('updatessqtable',handles);
reg_guifcn('updatessqtable',handles,pc);
end

% --------------------------------------------------------------------
function opts = getoptions(handles)
%Returns options strucutre

ldamode = getappdata(handles.analysis,'curanal');
%See if there are old/curent options (loaded in analysis under
%enable_method.
opts  = getappdata(handles.analysis,'analysisoptions');

if isempty(opts) | ~strcmp(opts.functionname, ldamode)
  switch ldamode
    case 'lda'
      opts = lda('options');
  end
end
opts.display       = 'off';
opts.plots         = 'none';
end

% --------------------------------------------------------------------
function opts = setoptions(handles)
%Set options from history.
curanal = getappdata(handles.analysis,'curanal');
opts = analysis('getoptshistory',handles,lower(curanal));
if isempty(opts)
  opts = getoptions(handles);
end
setappdata(handles.analysis, 'analysisoptions',opts);
end

%----------------------------------------------------
function showconfusion_Callback(h, eventdata, handles, varargin)
%Generate both a confusion table and confusion matrix and displays the results in an infobox. 

modl = analysis('getobjdata','model',handles);
test = analysis('getobjdata','prediction',handles);

if isempty(modl);
  return
end

% Get confusion matrix and table results for each case, most probable and 
% strict, and merge all results for presentation
contentmp = getcontent(modl, test, 'mostprobable');
contentst = getcontent(modl, test, 'strict');
maxlen1   = max(cellfun(@length,contentmp));
breakline = {repmat('-',1, maxlen1)};
if strcmp(modl.detail.options.predictionrule, 'mostprobable')
  content = [contentmp {' '} breakline contentst];
else
  content = [contentst {' '} breakline contentmp];
end
content = char(content);

ibh = infobox(content,struct(...
'visible','on',...
'fontname','courier',...
'figurename','Confusion Matrix',...
'helplink','Confusionmatrix',...
'openmode','new'));
analysis('adopt',handles,ibh,'modelspecific');
end

%--------------------------------------------------------------------------
function content = getcontent(modl, test, predrule);
% Get confusion matrix and table content for the specified predrule,
% either 'mostprobable' or 'strict'

[ja,jb,tt1] = confusionmatrix(modl, false, predrule);
[ja,jb,tt2] = confusiontable(modl, false, predrule);

hascv = false;
if isfield(modl.detail,'cvclassification') & ~isempty(modl.detail.cvclassification) & ...
    ~isempty(modl.detail.cvclassification.probability)
  [ja,jb,tt1cv] = confusionmatrix(modl, true, predrule);
  [ja,jb,tt2cv] = confusiontable(modl, true, predrule);
  hascv = true;
end

hastest = false;
if ~isempty(test)
  [ja,jb,tt3] = confusionmatrix(test, false, predrule); 
  [ja,jb,tt4] = confusiontable(test, false, predrule); 
  hastest = true;
end

if strcmp('mostprobable', predrule)
  predruleinfo = {sprintf('%s Classification Using Rule: Pred Most Probable', modl.modeltype)};
else
  predruleinfo = {sprintf('%s Classification Using Rule: Pred Strict (using strictthreshold = %4.2f)' ...
    , modl.modeltype, modl.detail.options.strictthreshold)};
end

if strcmp(lower(modl.modeltype), 'simca') | strcmp(lower(modl.modeltype), 'simca_pred')
  mopts = modl.detail.options.rule;
  optsinfo = sprintf('  Options: rule.name = ''%s'', rule.limit.t2 = %4.2f, rule.limit.q = %4.2f', ...
    mopts.name, mopts.limit.t2, mopts.limit.q);
  content = [predruleinfo {optsinfo} ];
else
  content = [predruleinfo];
end
  
content = [content {' '} {'MODEL RESULTS'}  tt1 {' '} tt2];
if hascv 
  content = [ content {' '} {'CV RESULTS'}  tt1cv {' '} tt2cv {' '}];
end
if hastest
  content = [ content {' '} {'PREDICTION RESULTS'} tt3 {' '} tt4];
end
end




