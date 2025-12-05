function varargout = tsne_guifcn(varargin)
%CLUSTER_GUIFCN CLUSTER Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%rsk 08/11/04 Change help line and add ssqupdate to keep error from appearing.
%rsk 01/16/06 Fix bug for cancel number cluster dialog.

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
%----------------------------------------------------
function gui_init(h,eventdata,handles,varargin);
%create toolbar
[atb abtns] = toolbar(handles.analysis, 'tsne','');
handles  = guidata(handles.analysis);
analysis('toolbarupdate',handles);

%turn off valid crossvalidation
setappdata(handles.analysis,'enable_crossvalgui','off');
crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'Nodes L1')

%{
%change pc edit label.
set(handles.pcseditlabel,'string','Neighbors (k):')
%change ssq table labels
set(handles.pcsedit,'Enable','on')
set(handles.pcsedit,'string','3');
setappdata(handles.pcsedit,'default',3);


%turn on valid crossvalidation
setappdata(handles.analysis,'enable_crossvalgui','on');
crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'Neighbors')
%}

%general updating
%set(handles.tableheader,'string', {'Enter (k) above and click the calculate button (gears) to perform analysis' },'horizontalalignment','center')
%No ssq table, disable.
set(handles.ssqtable,'visible','off')
set([handles.pcseditlabel handles.pcsedit],'visible','on')

%Add panel.
panelinfo.name = ['TSNE Settings'];
panelinfo.file = 'tsnegui';
panelmanager('add',panelinfo,handles.ssqframe)

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
closefigures(handles);
set([handles.tableheader handles.pcseditlabel handles.ssqtable handles.pcsedit],'visible','on')
set(handles.tableheader,'string', { '' },'horizontalalignment','left')

setappdata(handles.analysis,'enable_crossvalgui','on');

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)

choosegrps = findobj(handles.analysis,'tag','choosegrps');

%see if we can use choose groups
statmodl = getappdata(handles.analysis,'statmodl');
if ~strcmp(statmodl,'loaded') && analysis('isloaded','xblock',handles) && isempty(analysis('getobjdata','yblock',handles))
  en = 'on';
else
  en = 'off';
end
set(choosegrps,'enable',en);

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)
%two-way x
% out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%discrim: two-way x with classes
out = xprofile.data & xprofile.class & xprofile.ndims==2;

%two-way x and y
% out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;


%--------------------------------------------------------------------
function out = isyused(handles)

out = false;

%----------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin);

statmodl = getappdata(handles.analysis,'statmodl');

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
  %{
  if ~analysis('isdatavalid',handles);
    erdlgpls('Classes must be supplied in the X-block samples mode. Can not calibrate','Calibrate Error');
    return
  end
%}
  if mdcheck(x);
    ans = evriquestdlg({'Missing Data Found - Replacing with "best guess"','Results may be affected by this action.'},'Warning: Replacing Missing Data','OK','Cancel','OK');
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
    analysis('setobjdata','xblock',handles,x);
  end

  preprocessing = {getappdata(handles.preprocessmain,'preprocessing')};

  options = tsne_guifcn('options');
  %maxk   = min([length(x.includ{1}) options.maximumfactors]);
  %mink   = getappdata(handles.pcsedit,'default');
  %if isempty(mink); mink = 3; end;                    %default model
  %if mink>maxk;     mink = 1; end;                    %don't allow > # of evs (in fact, consider this a reset of default)

  try
    opts = getoptions(handles);
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.preprocessing = preprocessing;

    modl      = tsne(x,opts);

  catch
    erdlgpls({'Error using TSNE method',lasterr},'Calibrate Error');
    return
  end

  %   %Do cross-validation
  %modl = crossvalidate(handles.analysis,modl);
  
  %UPDATE GUI STATUS
  setappdata(handles.analysis,'statmodl','calold');
  analysis('setobjdata','model',handles,modl);
end

if analysis('isloaded','validation_xblock',handles)
  evriquestdlg('TSNE cannot be applied to new data.', 'TSNE validation data', 'OK','OK');
  return;
  %{
  %apply model to new data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
  if isempty(x); return; end  %some cancel action

  opts = getoptions(handles);
  opts.display  = 'off';
  opts.plots    = 'none';

  try
    test = tsne(x,opts);
  catch
    erdlgpls({'Error applying model to validation data.',lasterr,'Model not applied.'},'Apply Model Error');
    test = [];
  end

  analysis('setobjdata','prediction',handles,test);
  %}

else
  %no test data? clear prediction
  analysis('setobjdata','prediction',handles,[]);  
end
opts = getoptions(handles);
opts.classset = 1;
setappdata(handles.analysis,'analysisoptions', opts);
handles = guidata(handles.analysis);
analysis('updatestatusboxes',handles);
analysis('toolbarupdate',handles)
guidata(handles.analysis,handles)

updatefigures(handles.analysis);     %update any open figures
figure(handles.analysis)


%----------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)

%----------------------------------------------------
function pcsedit_Callback(h, eventdata, handles, varargin)
val = get(handles.pcsedit,'string');
val = str2double(val);
default = getappdata(handles.pcsedit,'default');
if ~isfinite(val) || val<1  %not valid? reset
  set(handles.pcsedit,'string',default);
  return
end
if val==default;
  return
end
val = round(val);

setappdata(handles.pcsedit,'default',val);
analysis('clearmodel',handles.analysis,[],handles);

% --------------------------------------------------------------------
function [modl,success] = crossvalidate(h,modl,perm)
handles  = guidata(h);
success = 0;

if nargin<3
  perm = 0;
end

[cv,lv,split,iter,cvi] = crossvalgui('getsettings',getappdata(h,'crossvalgui'));
if strcmp(cv,'none')
  return;
end

x        = analysis('getobjdata','xblock',handles);
y        = modl.detail.class{1,1,modl.detail.options.classset}';
mc       = modl.detail.preprocessing;

opts = [];
opts.preprocessing = mc;
opts.display = 'off';
opts.plots   = 'none';
opts.discrim = 'yes';  %force discriminant ananlysis cross-val mode

if perm>0
  opts.permutation = 'yes';
  opts.npermutation = perm;
  lv = modl.k;
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
  success = 1;
end

%--------------------------------------------------------------------
function updatefigures(h)

handles = guidata(h);
if ~strcmp(getappdata(handles.analysis,'statmodl'),'none');
  if ~isempty(analysis('findpg','scores',handles,'*'))
    plotscores_Callback(handles.plotscores, [], handles);
  end
end

%----------------------------------------
function closefigures(handles)
%close the analysis specific figures

pca_guifcn('closefigures',handles);


%-------------------------------------------------
function updatessqtable(handles,pc)

%-------------------------------------------------
function storedopts = getoptions(handles)
%Returns options strucutre for tsne 

storedopts  = getappdata(handles.analysis,'analysisoptions');
curanalysis = getappdata(handles.analysis,'curanal');

if isempty(storedopts) | ~strcmp(storedopts.functionname, curanalysis)
  storedopts = tsne('options');
end

storedopts.display       = 'off';
storedopts.plots         = 'none';

%-------------------------------------------------
function plotscores_Callback(h,eventdata,handles,varargin)

pca_guifcn('plotscores_Callback',h,eventdata,handles,varargin{:});

%----------------------------------------------------
function  optionschange(h)
handles = guidata(h);
panelmanager('update',handles.ssqframe)
