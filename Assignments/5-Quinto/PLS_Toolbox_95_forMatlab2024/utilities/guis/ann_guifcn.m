function varargout = ann_guifcn(varargin);
%ANN_GUIFCN ANN Analysis-specific methods for Analysis GUI.
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
%----------------------------------------------------
function gui_init(h,eventdata,handles,varargin)

%create toolbar

[atb,abtns] = toolbar(handles.analysis, 'ann','');
handles  = guidata(handles.analysis);
analysis('toolbarupdate',handles);
%change ssq table labels
%No ssq table, disable.
set(handles.pcsedit,'Enable','off')
%set(handles.ssqtable,'Enable','off')

% mytbl = getappdata(handles.analysis,'ssqtable');

%turn off valid crossvalidation
setappdata(handles.analysis,'enable_crossvalgui','on');
crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'Nodes L1')

%Change PCs to Nodes.
set(handles.pcseditlabel,'string','Number Nodes:')

% Need to hack options into analysis before call to add panel because 
% panel depends on options being there.
opts = analysis('getoptshistory',handles,'ann');
if isempty(opts)
  opts = getoptions(handles);
end
setappdata(handles.analysis, 'analysisoptions',opts);

% %Add table column header space holder.
% mytbl = ssqsetup(mytbl,{' ' ' '},...
%   '<b>&nbsp;&nbsp;&nbsp;Nodes',{'%6.2f'  ''},1);

set(handles.tableheader,'string','ANN Model Statistics','HorizontalAlignment','center')

%Add view selections to dropdown.
panelinfo.name = ['ANN Settings'];
panelinfo.file = 'anngui';
panelmanager('add',panelinfo,handles.ssqframe)

handles = guihandles(handles.analysis);
guidata(handles.analysis,handles);

%Update number of nodes.
optionschange(handles.analysis)

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
if strcmp(myanal,'annda')
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
% out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;

%--------------------------------------------------------------------
function out = isyused(handles)
%Must have Y.

out = true;

%----------------------------------------------------
function  calcmodel_Callback(h,eventdata,handles,varargin);
%ANN Calculate model, uses similar code from reg_guifcn.

annmode = getappdata(handles.analysis,'curanal');
statmodl = lower(getappdata(handles.analysis,'statmodl'));
if strcmp(statmodl,'calnew') & ~analysis('isloaded','rawmodel',handles)
  statmodl = 'none';
end

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
      if strcmpi(annmode,'ann')
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
      if strcmpi(annmode,'ann');
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
       
    if ~strcmpi('annda', annmode) & ~isempty(y) & all(all(y.data(y.includ{1},:) == y.data(y.includ{1}(1),1)));
      erdlgpls('All y values are identical - can not do regression analysis','Calibrate Error');
      return
    end

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

    switch annmode
      case 'ann'
        modl = ann(x,y,opts);
      case 'annda'
        if isempty(y)
          modl      = annda(x,opts);
        else
          modl      = annda(x,y,opts);
        end
    end
    
    drawnow;
    
  catch
    erdlgpls({'Error using ANN',lasterr},'Calibrate Error');
    return
  end

  % Do cross-validation (Currently, only do CV if it is BPN)
  % Warn that CV only done over layer 1 nodes
  if ~strcmp(cvmode,'none') & strcmpi(modl.detail.ann.W.type, 'bpn') & modl.detail.ann.W.nhiddenlayers > 1
    evritip('ann2layerbpncv','ANN (BPN) CV Tip: CV only tests over Layer 1 nodes. Layer 2 nodes not tested', [1])
  end
  if ~strcmp(cvmode,'none') & ismember(lower(modl.detail.ann.W.type),{'bpn'})
    modl = crossvalidate(handles.analysis,modl);
    
%FIXME: The model.detail.rmsec/cv/p field is not updated when using rawmodel so
% disable for now (4/19/17). 
%
%     if ~strcmp(statmodl,'calnew');
%       modl = crossvalidate(handles.analysis,modl);
%       analysis('setobjdata','rawmodel',handles,modl)
%     else
%       rawmodl = analysis('getobjdata','rawmodel',handles);
%       modl = copycvfields(rawmodl,modl);
%     end
%   else
%     %Never use raw model without crossval call
%     analysis('setobjdata','rawmodel',handles,[]);
  end
   
  %UPDATE GUI STATUS
  setappdata(handles.analysis,'statmodl','calold');
  analysis('setobjdata','model',handles,modl);
  
  %Never use raw model, SEE ABOVE.
  analysis('setobjdata','rawmodel',handles,[]);
  
  handles = guidata(handles.analysis);

  figure(handles.analysis)
  
  
  switch annmode
    case 'ann'
      updatessqtable(handles,opts.nhid1)
    case 'annda'
      % throws error when updatessqtable calls ploteigen...   % *** tempdos
  end
  
end


if analysis('isloaded','validation_xblock',handles)
  %apply model to test data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
  if isempty(x); return; end  %some cancel action

  try
    opts = getoptions(handles);
    switch annmode
      case 'ann'
        if isempty(y)
          test = ann(x,modl,opts);
        else
          test = ann(x,y,modl,opts);
        end
      case 'annda'
        if isempty(y)
          test = annda(x,modl,opts);
        else
          test = annda(x,y,modl,opts);
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

%----------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.

handles = guidata(h);
modl    = analysis('getobjdata','model',handles);
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
  if ~isempty(modl) &  n == modl.detail.options.nhid1;
    %User clicked back same number of PC's.
    setappdata(handles.analysis,'statmodl','calold');
  elseif ~isempty(modl) & analysis('isloaded','xblock',handles)
    %new PCs for existing model
    setappdata(handles.analysis,'statmodl','calnew');
  end
  anngui('edit1_Callback',[], [], handles, n)
  analysis('updatestatusboxes',handles);
  analysis('toolbarupdate',handles)  %set buttons
end

%----------------------------------------------------
function  pcsedit_Callback(h, eventdata, handles, varargin)

%----------------------------------------------------
function  optionschange(h)
%Updates after options have changed.

handles = guihandles(ancestor(h,'figure'));
%Updaste pc edit box. 
opts = getoptions(handles);
set(handles.pcsedit,'String',num2str(opts.nhid1))
setappdata(handles.pcsedit,'default',opts.nhid1)


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
  lv = modl.detail.options.nhid1;
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
%Update SSQ table. Model is so different from other regression methods that
%not efficient to call reg_guifcn version of updatessq table.

%SSQ Table not used for ANN or ANNDA. Somehow it looks like it gets created
%in some legacy code so code below works. It can be enabled by uncommenting
%in the future. Return for now.
return

% options = getoptions(handles);
% modl    = analysis('getobjdata','model',handles);
% pcs     = getappdata(handles.pcsedit,'default');
% mytbl   = getappdata(handles.analysis,'ssqtable');
% 
% if isempty(modl)
%   clear(mytbl);%Clear data.
%   return
% end
% 
% [ssq_table,column_headers,column_format] = getssqtable(modl,pcs,'raw',11,true);
% ssq_table = [ssq_table repmat({' '},size(ssq_table,1),1)];
% column_headers{end+1} = '<html>Status</html>';
% column_format{end+1} = '';
% 
% newtbl{pcs,end} = 'current';
% 
% %Update table data.
% mytbl.data = ssq_table;
% mytbl.column_labels = column_headers;
% mytbl.column_format = column_format;

% --------------------------------------------------------------------
function opts = getoptions(handles)
%Returns options strucutre

annmode = getappdata(handles.analysis,'curanal');
%See if there are old/curent options (loaded in analysis under
%enable_method.
opts  = getappdata(handles.analysis,'analysisoptions');

if isempty(opts) | ~strcmp(opts.functionname, annmode)
  switch annmode
    case 'ann'
      opts = ann('options');
    case 'annda'
      opts = annda('options');
  end
end
opts.display       = 'off';
opts.plots         = 'none';

% --------------------------------------------------------------------
function opts = setoptions(handles)
%Set options from history.
curanal = getappdata(handles.analysis,'curanal');
opts = analysis('getoptshistory',handles,lower(curanal));
if isempty(opts)
  opts = getoptions(handles);
end
setappdata(handles.analysis, 'analysisoptions',opts);



