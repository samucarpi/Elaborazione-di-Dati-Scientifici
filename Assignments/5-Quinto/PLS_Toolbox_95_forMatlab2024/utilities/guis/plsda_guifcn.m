function varargout = plsda_guifcn(varargin)
%PLSDA_GUIFCN Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%rsk 06/02/04 Change pcsedit to text box, deselct changes back to edit.
%     -Users must make changes via ssq table.
%rsk 02/28/05 Add auto update to thresh fig.

if nargin>0;
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = analysis('options');
        options.usenewvarselect = 1;
        %add guifcn specific options here
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
      otherwise
        usereg = {'pcsedit_Callback','ploteigen_Callback','ssqtable_Callback','updatefigures','updatessqtable'};
        if ~ismember(char(varargin{1}),usereg)
          if nargout == 0;
            feval(varargin{:}); % FEVAL switchyard
          else
            [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
          end
        else
          if nargout == 0;
            reg_guifcn(varargin{:}); % FEVAL switchyard
          else
            [varargout{1:nargout}] = reg_guifcn(varargin{:}); % FEVAL switchyard
          end
        end
    end
  catch
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end
end

%----------------------------------------------------
function gui_init(h,eventdata,handles,varargin);
%create toolbar
[atb abtns] = toolbar(handles.analysis, 'plsda','');

handles  = guidata(handles.analysis);
%Create appdata for ROC/Thresh figure in ROC button.
setappdata(atb,'threshfig',[])
%Enable correct buttons.
analysis('toolbarupdate',handles)

%change pc edit label.
set(handles.pcseditlabel,'string','Number LVs:')

%Get gui options
roptions = plsda_guifcn('options');

%change pc edit box to text box.
set(handles.pcsedit,'style','text')

mytbl = getappdata(handles.analysis,'ssqtable');
mytbl = ssqsetup(mytbl,{'X-Block<br>LV' 'X-BLock<br>Cumulative' 'Y-Block<br>LV' 'y-Block<br>Cumulative' ' '},...
  '<b>&nbsp;&nbsp;&nbsp;LV',{'%6.2f' '%6.2f' '%6.2f' '%6.2f' ''},1);


% if ispc
%   tableheader = ...
%     { '                   Percent Variance Captured by Model',...
%     ' Latent                X-Block                    Y-Block  ',...
%     'Variable          LV        Cum               LV        Cum'};
%   format       = '%3.0f     %6.2f %6.2f    %6.2f %6.2f';
% else
%   tableheader = ...
%     { '           Percent Variance Captured by Model',...
%     ' Latent       X-Block              Y-Block  ',...
%     'Variable    LV      Cum          LV      Cum'};
%   format       = '%3.0f     %8.2f %8.2f    %8.2f %8.2f';
% end
set(handles.tableheader,'string','Percent Variance Captured by Model (* = suggested)','HorizontalAlignment','center');
%set(handles.tableheader,'string',tableheader);
% setappdata(handles.analysis,'tableformat',format);
% setappdata(handles.analysis,'tableheader',tableheader);

%Add view selections to dropdown.
panelinfo.name = 'SSQ Table';
panelinfo.file = 'ssqtable';

if roptions.usenewvarselect
  panelinfo(2).name = 'Variable Selection';
  panelinfo(2).file = 'variableselectiongui';
else
  panelinfo(2).name = 'iPLSDA Variable Selection';
  panelinfo(2).file = 'iplsgui';
end

% panelinfo(2).name = 'Cross Validation';
% panelinfo(2).file = 'crossvalgui';
panelmanager('add',panelinfo,handles.ssqframe)

handles = guihandles(handles.analysis);
guidata(handles.analysis,handles);

% %turn on valid crossvalidation
% crossvalgui('enable',handles.analysis);
% crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'LVs');

%change the name of the "factors" in the crossvalidate GUI
crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'LVs')

setappdata(handles.analysis,'autoselect_visible',1)

%turn on valid crossvalidation
setappdata(handles.analysis,'enable_crossvalgui','on');

%general updating
analysis('updatestatusboxes',handles)

updatefigures(handles.analysis);     %update any open figures

reg_guifcn('updatessqtable',handles)
%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
%Change pcsedit back to defualt style.
set(handles.pcsedit,'style','edit')

plsda_guifcn('closefigures',handles);

setappdata(handles.analysis,'autoselect_visible',0)
setappdata(handles.analysis,'enable_crossvalgui','on');

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)
%Clear table.
mytbl = getappdata(handles.analysis,'ssqtable');
clear(mytbl,'all');

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)

pca_guifcn('gui_updatetoolbar',h,eventdata,handles,varargin);
statmodl = getappdata(handles.analysis,'statmodl');
y = analysis('getobjdata','yblock',handles);
if ~strcmp(statmodl,'loaded') && analysis('isloaded','xblock',handles) && isempty(y)
  test_tooltipString = get(findobj(handles.analysis,'tag','choosegrps'),'TooltipString');
  if ~strcmp(test_tooltipString, 'Select Class Groups')
    tooltip_string = 'Select Class Groups';
    set(findobj(handles.analysis,'tag','choosegrps'),'TooltipString', tooltip_string,'enable','on')
  else
    set(findobj(handles.analysis,'tag','choosegrps'),'enable','on')
  end
elseif ~strcmp(statmodl,'loaded') && analysis('isloaded','xblock',handles) && ~isempty(y)
  tooltip_string = 'To use X-block classes, remove Y-block data.';
  set(findobj(handles.analysis,'tag','choosegrps'),'TooltipString',tooltip_string,'enable','off')
else
  set(findobj(handles.analysis,'tag','choosegrps'),'enable','off')
end


%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)
%two-way x
% out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%Need to overload default xprofile.class since it only checks for first set and PLSDA can handle different set. 
x = analysis('getobjdata','xblock',fig);
if ~isempty(x)
  xprofile.class = any(~cellfun('isempty',x.class(1,:)));
end

%discrim: two-way x with classes OR y
out = xprofile.data & xprofile.ndims==2 & (xprofile.class | (yprofile.data & yprofile.ndims==2) );

%discrim: two- or n-way x with classes OR y
%out = xprofile.data & (xprofile.class | (yprofile.data & yprofile.ndims==2) );

%two-way x and y
%out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;

%--------------------------------------------------------------------
function out = isyused(handles)

if analysis('isloaded','xblock',handles.analysis);
  if analysis('isloaded','yblock',handles.analysis)
    %if y-block is loaded, we're using it
    out = true;
  else
    %if no y-block, then whether or not we need one is based on if classes
    %exist in the x-block
    x = analysis('getobjdata','xblock',handles);
    %Do custom check for classes. varprofile only checks for first set.
    out = any(~cellfun('isempty',x.class(1,:)));
  end
else
  %no x? can't decide, assume not
  out = false;
end

%----------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin)
% Callback of the uicontrol handles.calcmodel.

statmodl = lower(getappdata(handles.analysis,'statmodl'));
mytbl    = getappdata(handles.analysis,'ssqtable');

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
    erdlgpls('Classes must be supplied in the X-block samples mode, or a y-block designating class membership must be loaded. Can not calibrate','Calibrate Error');
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
    %no y-block, check for modelgroups from user selecting items to group
    modelgroups = getappdata(findobj(handles.analysis,'tag','choosegrps'),'modelgroups');
    if ~isempty(modelgroups)
      y = modelgroups;
    else
      y = {};  %no groups, no y, use classes as-is
    end

  end
  preprocessing = {getappdata(handles.preprocessmain,'preprocessing') getappdata(handles.preproyblkmain,'preprocessing')};

  options = plsda_guifcn('options');
  [cvmode,cvlv,cvsplit,cviter] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));

  if ~strcmp(cvmode,'none')
    maxlv   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors cvlv]);
  else  %no cross-val method? Don't let the slider limit the # of LVs
    maxlv   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors]);
  end
  minlv   = getappdata(handles.pcsedit,'default');
  if isempty(minlv); minlv = 1; end;                    %default model
  if minlv>maxlv;    minlv = 1; end;                    %don't allow > # of evs (in fact, consider this a reset of default)

  try
    opts = reg_guifcn('getoptions','plsda',handles);
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.preprocessing = preprocessing;

    if strcmp(opts.algorithm , 'robustpls')
      if isempty(y)
        modl      = plsda(x,modelgroups,minlv,opts);
      else
        modl      = plsda(x,y,minlv,opts);
      end
      rawmodl = [];  %for robust, we never use rawmodl
    elseif ndims(x)>2
      if isempty(y)
        rawmodl   = [];
        modl      = plsda(x,minlv,opts);
      else
        rawmodl   = [];
        modl      = plsda(x,y,minlv,opts);
      end
    else      
      opts.rawmodel      = 1;
      if isempty(y)
        rawmodl   = plsda(x,maxlv,opts);
        modl      = plsda(x,minlv,rawmodl,opts);
      else
        rawmodl   = plsda(x,y,maxlv,opts);
        modl      = plsda(x,y,minlv,rawmodl,opts);
      end
      modl.detail.ssq(minlv+1:size(rawmodl.detail.ssq,1),:) = rawmodl.detail.ssq(minlv+1:end,:);   %copy complete SSQ table
    end

  catch
    erdlgpls({'Error using PLSDA regression method',lasterr},'Calibrate Error');
    return
  end

  %Do cross-validation
  if ~strcmp(cvmode,'none')
    modl = crossvalidate(handles.analysis,modl);

    if ~isempty(rawmodl);
      rawmodl = copycvfields(modl,rawmodl);
    end
  else % just calculate RMSEC
    getsetcalstats(modl,handles, maxlv);
    modl=analysis('getobjdata','model',handles); %update local variable
  end

  %UPDATE GUI STATUS
  setappdata(handles.analysis,'statmodl','calold');
  analysis('setobjdata','model',handles,modl);
  analysis('setobjdata','rawmodel',handles,rawmodl);

  handles = guidata(handles.analysis);
  reg_guifcn('updatessqtable',handles,minlv);

  if isempty(getappdata(handles.pcsedit,'default')) && exist('choosecomp.m','file')==2 && strcmp(options.autoselectcomp,'on')
    %Make auto selection of components.
    selectpc = choosecomp(modl);
    if ~isempty(selectpc) && minlv~=selectpc
      %Recalculate model
      %set(handles.ssqtable,'Value',selectpc);
      setselection(mytbl,'rows',selectpc)
      statmodl = 'calnew';  %fake out logic below to recalculate model (so we don't duplicate code here)
    end
  end

  figure(handles.analysis)
end

if strcmp(statmodl,'calnew');
  %apply model to new data (or change of # of components only)

  modl = analysis('getobjdata','model',handles);
  rawmodl = analysis('getobjdata','rawmodel',handles);
  x = analysis('getobjdata','xblock',handles);
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
    isect = intersect(y.include{1},x.include{1}); %intersect samples includ from x- and y-blocks
    if length(x.include{1})~=length(isect) | length(y.include{1})~=length(isect);  %did either change?
      y.include{1} = isect;
      analysis('setobjdata','yblock',handles,y);    %and save back to object
      x.include{1} = isect;
      analysis('setobjdata','xblock',handles,x);    %and save back to object
    end

    y.includ{1}   = x.includ{1};      %copy samples includ from x-block
    if all(all(y.data(y.includ{1},:) == y.data(y.includ{1}(1),1)));
      erdlgpls('All y values are identical - can not do regression analysis','Calibrate Error');
      return
    end
  end
  minlv = getselection(mytbl,'rows');
  %minlv         = get(handles.ssqtable,'Value'); %number of PCs

  try
    opts = rawmodl.detail.options;
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.rawmodel      = 1;

    if isempty(y)
      %no y-block, check for modelgroups from user selecting items to group
      modelgroups = getappdata(findobj(handles.analysis,'tag','choosegrps'),'modelgroups');
      if ~isempty(modelgroups)
        modl = plsda(x,modelgroups,minlv,rawmodl,opts);
      else
        modl = plsda(x,minlv,rawmodl,opts);
      end
    else
      modl   = plsda(x,y,minlv,rawmodl,opts);
    end
    modl.detail.ssq(minlv+1:size(rawmodl.detail.ssq,1),:) = rawmodl.detail.ssq(minlv+1:end,:);
    
  catch
    erdlgpls({'Error using PLSDA regression method',lasterr},'Calibrate Error');
    return
  end

  [cvmode,cvlv,cvsplit,cviter] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
  if ~strcmp(cvmode,'none')   %get(cvinfo.methodpopup,'value')~=1
    %copy cross-val info into modl
    modl = copycvfields(rawmodl,modl);
  else
    % copy rmsec, r2c, & bias from oiginal model
    omodl = analysis('getobjdata','model',handles);
    if ~isempty(omodl)
      modl.detail.rmsec = omodl.detail.rmsec;
      modl.detail.bias = omodl.detail.bias;
      modl.detail.r2c = omodl.detail.r2c;
    end
  end

  setappdata(handles.analysis,'statmodl','calold');
  analysis('setobjdata','model',handles,modl);
  reg_guifcn('updatessqtable',handles,minlv);

  figure(handles.analysis)
end

if analysis('isloaded','validation_xblock',handles)
  %apply model to test data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
  if isempty(x); return; end  %some cancel action

  try
    opts = reg_guifcn('getoptions','plsda',handles);
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.rawmodel      = 0;

    if isempty(y)
      test = plsda(x,modl,opts);
    else
      test = plsda(x,y,modl,opts);
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
function [modl,success] = crossvalidate(h,modl,perm)
%CrossValidationGUI CrossValidateButton CallBack
handles  = guidata(h);
success = 0;

if nargin<3
  perm = 0;
end

x        = analysis('getobjdata','xblock',handles);
y        = modl.detail.data{2};
mc       = modl.detail.preprocessing;

[cv,lv,split,iter,cvi] = crossvalgui('getsettings',getappdata(h,'crossvalgui'));

modeltype = lower(modl.detail.options.algorithm);
if strcmp(modeltype,'robustpls')
  %       evritip('robustguicv','WARNING: Full robust cross-validation is not currently supported. Cross-validation will be performed with standard algorithm using currently-detected outliers. Cross-validation results may be influenced by un-excluded outliers.',1);
  %       x.include{1} = modl.detail.includ{1};
  %   evritip('robustguicv','WARNING: Robust cross-validation is not currently supported. Cross-validation will be performed with standard algorithm. Cross-validation results may be influenced by un-excluded outliers.',1);
  modeltype = 'sim';
  default = getappdata(0,'robust_crossval_default');
  if isempty(default); default = 'All Data'; end
  ans = evriquestdlg('Robust cross-validation is not fully supported. Do you want to perform cross-validation using all data, exclude the currently flagged outliers, or abort cross-validation?','Robust Cross-Validation','All Data','Exclude Outliers','Abort',default);
  switch ans
    case 'Exclude Outliers'
      x.include{1} = modl.detail.includ{1};
    case 'Abort'
      return
  end
  setappdata(0,'robust_crossval_default',ans);
end

m  = length(x.includ{1});
n  = length(x.includ{2});
lv = min([lv m n]);

opts = [];
opts.preprocessing = mc;
opts.display = 'off';
opts.plots   = 'none';
opts.discrim = 'yes';  %force discriminant ananlysis cross-val mode
if ~isempty(modl.detail.options.priorprob)
  opts.prior   = normaliz(modl.detail.options.priorprob,[],1);
else
  opts.prior = [];
end
opts.weights = modl.detail.options.weights;
opts.weightsvect = modl.detail.options.weightsvect;

if perm>0
  opts.permutation = 'yes';
  opts.npermutation = perm;
  opts.plotlvs = size(modl.loads{1},2);
end

try
  modl = crossval(x,y,modl,cvi,lv,opts);
catch
  erdlgpls({'Unable to perform cross-valiation - Aborted';lasterr},'Cross-Validation Error');
  return
end

if perm>0
  success = opts.plotlvs;
  return;
end
success = 1;

% --------------------------------------------------------------------
function plotscores_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.plotscores.
%I/O: plotscores_Callback(h,[],handles,extracmds)
%  where extracmds is cell to be expanded and passed to plotgui

pca_guifcn('plotscores_Callback',h,eventdata,handles,varargin{:});

% --------------------------------------------------------------------
function scoresclasschange(h)
%input h is the handle of the scores button

pca_guifcn('scoresclasschange',h);

%------------------------------------------------------------------
function threshold_Callback(h,eventdata,handles,varargin)

modl = analysis('getobjdata','model',handles);
test = analysis('getobjdata','prediction',handles);

if ~isempty(modl);
  threshfig = getappdata(handles.AnalysisToolbar, 'threshfig');
  opts = plsdaroc('options');
  opts.plots = 'final';
  if ~isempty(threshfig)&ishandle(threshfig(end))
    opts.figure = threshfig(end);
  else
    opts.figure = 'gui';
  end
  if isempty(test) | isempty(test.detail.data{2})
    plsdaroc(modl,opts);
  else
    plsdaroc(test,opts);
  end
  newfig = gcf;

  figname = ['Threshold/ROC Plot' getappdata(handles.analysis,'figname_info')];
  set(newfig,'Name',figname);

  threshfig = unique([threshfig gcf]);
  threshfig = threshfig(ishandle(threshfig));
  setappdata(handles.AnalysisToolbar, 'threshfig', threshfig)
  analysis('adopt',handles,threshfig,'methodspecific')
end

%----------------------------------------
function closefigures(handles)
%close the analysis specific figures
threshfig = getappdata(handles.AnalysisToolbar,'threshfig');
threshfig = threshfig(ishandle(threshfig));
if ~isempty(threshfig)
  close(threshfig)
end
reg_guifcn('closefigures',handles);

%--------------------------------------------------------------------
function updatefigures(h)
%update any open figures
handles = guidata(h);
eventdata = [];%Dummy var.
varargin = [];%Dummy var.

reg_guifcn('updatefigures',h)
%Update threshold figure. Stored in toolbar, not actual button.
if ~strcmp(getappdata(handles.analysis,'statmodl'),'none');
  if isfield(handles,'threshold')
    threshfig = getappdata(handles.AnalysisToolbar,'threshfig');
    threshfig(~ishandle(threshfig)) = [];
    setappdata(handles.AnalysisToolbar,'threshfig',threshfig);
    if ~isempty(threshfig)
      threshold_Callback(threshfig, eventdata, handles, varargin);
    end
  end
end

%----------------------------------------------------------------
function choosegrps_Callback(hObject,eventdata,handles)
%present GUI for group selection

x = analysis('getobjdata','xblock',handles);
if isempty(x) | isempty(x.includ{1});
  return
end
x = x(x.includ{1},:);

curanalysis = getappdata(handles.analysis,'curanal');
opts        = getappdata(handles.analysis,'analysisoptions');
if isempty(opts)
  opts = feval(curanalysis,'options');
end

btnhandle = findobj(handles.analysis,'tag','choosegrps');
grps = getappdata(btnhandle,'modelgroups');

if strcmp(curanalysis, 'knn')
  [grps_new,classset, newx, infoForKNN] = plsdagui(x,[],1, curanalysis);
else
  [grps_new,classset, newx, infoForKNN] = plsdagui(x,grps,opts.classset, curanalysis);
end
if isempty(infoForKNN)
  infoForKNN.classGroupCreatedForKNN = [];
  infoForKNN.classSetToUse = [];
else
  setappdata(handles.analysis, 'classGroupCreatedForKNN', infoForKNN.classGroupCreatedForKNN);
end
if iscell(grps_new);
  if length(grps_new)==length(grps) & opts.classset==classset
    %same number of groups? look to see if user changed anything...
    different = 0;
    for j=1:length(grps_new)
      if length(grps_new{j})~=length(grps{j}) || any(grps_new{j}~=grps{j})
        different = 1;
        break
      end
    end
    if ~different;
      %nope! return without saving or clearing
      return;
    end
  end

  %Something was different, save and clear model
  setappdata(btnhandle,'modelgroups',grps_new);
  setappdata(btnhandle,'classset',classset);
  analysis('clearmodel',handles.analysis,[],handles);
  if ~isempty(infoForKNN.classSetToUse)
      opts.classset = infoForKNN.classSetToUse;
  else
      opts.classset = classset;
  end
  analysis('setopts',handles,curanalysis,opts)  %save class set too
  if ~isempty(newx)
    analysis('setobjdata', 'xblock', handles, newx); %LWL added
  end
  analysis('updateprepro', handles, 'x');
end

%----------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.
% ssqtable value and pcsedit string updated by updatessqtable.

pca_guifcn('ssqtable_Callback',h,[],handles);

%----------------------------------------------------
function  optionschange(h)

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

