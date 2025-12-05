function varargout = lreg_guifcn(varargin);
%LREG_GUIFCN LREG Analysis-specific methods for Analysis GUI.
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

[atb,abtns] = toolbar(handles.analysis, 'lreg','');
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
opts = analysis('getoptshistory',handles,'lreg');
if isempty(opts)
  opts = getoptions(handles);
end
setappdata(handles.analysis, 'analysisoptions',opts);

% %Add table column header space holder.
% mytbl = ssqsetup(mytbl,{' ' ' '},...
%   '<b>&nbsp;&nbsp;&nbsp;Nodes',{'%6.2f'  ''},1);

set(handles.tableheader,'string','LREG Model Statistics','HorizontalAlignment','center')

%Add view selections to dropdown.
panelinfo.name = ['LREG Settings'];
panelinfo.file = 'lreggui';
panelmanager('add',panelinfo,handles.ssqframe)

handles = guihandles(handles.analysis);
guidata(handles.analysis,handles);

%Update number of nodes.
optionschange(handles.analysis)
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
if strcmp(myanal,'lregda')
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
%LREG Calculate model, uses similar code from reg_guifcn.

lregmode = getappdata(handles.analysis,'curanal');
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
      if strcmpi(lregmode,'lreg')
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
      if strcmpi(lregmode,'lreg');
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
       
    if ~strcmpi('lregda', lregmode) & ~isempty(y) & all(all(y.data(y.includ{1},:) == y.data(y.includ{1}(1),1)));
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

    switch lregmode
      case 'lreg'
        modl = lreg(x,y,opts);
      case 'lregda'
        if isempty(y)
          modl      = lregda(x,opts);
        else
          modl      = lregda(x,y,opts);
        end
    end
    
    drawnow;
    
  catch
    erdlgpls({'Error using LREG',lasterr},'Calibrate Error');
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
  
  
  switch lregmode
    case 'lreg'
      updatessqtable(handles,opts.lambda)
    case 'lregda'
      % throws error when updatessqtable calls ploteigen...
  end
end


if analysis('isloaded','validation_xblock',handles)
  %apply model to test data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
  if isempty(x); return; end  %some cancel action

  try
    opts = getoptions(handles);
    switch lregmode
      case 'lreg'
        if isempty(y)
          test = lreg(x,modl,opts);
        else
          test = lreg(x,y,modl,opts);
        end
      case 'lregda'
        if isempty(y)
          test = lregda(x,modl,opts);
        else
          test = lregda(x,y,modl,opts);
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
  lv = modl.detail.options.lambda;
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
function updatessqtable(handles,pc)
%Update SSQ table. 
end

% --------------------------------------------------------------------
function opts = getoptions(handles)
%Returns options strucutre

lregmode = getappdata(handles.analysis,'curanal');
%See if there are old/curent options (loaded in analysis under
%enable_method.
opts  = getappdata(handles.analysis,'analysisoptions');

if isempty(opts) | ~strcmp(opts.functionname, lregmode)
  switch lregmode
    case 'lreg'
      opts = lreg('options');
    case 'lregda'
      opts = lregda('options');
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



