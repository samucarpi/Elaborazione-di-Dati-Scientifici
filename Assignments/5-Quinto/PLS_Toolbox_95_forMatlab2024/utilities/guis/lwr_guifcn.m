function varargout = lwr_guifcn(varargin)
%LWR_GUIFCN Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%If function not found here then call from pca_guifcn.
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
        usepca = {'biplot_Callback','crossvalidate','loadsdatabuttoncall','loadsincludchange','loadsinfobuttoncall',...
          'loadsinfobuttoncall_add','ploteigen_Callback','plotloads_Callback','scoresclasschange','scoresdatabuttoncall',...
          'scoresincludchange','scoresqconbuttoncall','scorestconbuttoncall','varcapbuttoncall'};
        if ~ismember(char(varargin{1}),usepca) 
          if nargout == 0;
            feval(varargin{:}); % FEVAL switchyard
          else
            [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
          end
        else
          if nargout == 0;
            pca_guifcn(varargin{:}); % FEVAL switchyard
          else
            [varargout{1:nargout}] = pca_guifcn(varargin{:}); % FEVAL switchyard
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
[atb abtns] = toolbar(handles.analysis, 'lwr','');
handles  = guidata(handles.analysis);

%Enable correct buttons.
analysis('toolbarupdate',handles)  %set buttons

%change pc edit label.
set(handles.pcseditlabel,'string','Number LVs:')

%Set up table.
mytbl = getappdata(handles.analysis,'ssqtable');
mytbl = ssqsetup(mytbl,{'% Variance<br>This LV' '% Variance<br>Cumulative' ' '},...
  '<b>&nbsp;&nbsp;&nbsp;LV',{'%6.2f' '%6.2f' ''},1);

% setappdata(handles.analysis,'tableformat',format);
set(handles.tableheader,'string','Percent Variance Captured by Model (* = suggested)','HorizontalAlignment','center')

%Add view selections to dropdown.
panelinfo.name = 'SSQ Table';
panelinfo.file = 'ssqtable';
panelinfo(2).name = 'LWR Settings';
panelinfo(2).file = 'lwrgui';
panelmanager('add',panelinfo,handles.ssqframe)

handles = guihandles(handles.analysis);
guidata(handles.analysis,handles);

%If there's a model around see if we can update the npts value.
modl = analysis('getobjdata','model',handles);
if ~isempty(modl) & strcmpi(modl.modeltype,'lwr')
  npts = modl.detail.npts;
  if ~isempty(npts)
    setappdata(handles.analysis,'lwr_npts',npts)
  end
end

%turn off crossvalidation
%setappdata(handles.analysis,'enable_crossvalgui','off');

%general updating
analysis('updatestatusboxes',handles)
updatefigures(handles.analysis)
updatessqtable(handles)
set(handles.pcsedit,'enable','on')

evritip analysis_lwr

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
closefigures(handles);

setappdata(handles.analysis,'enable_crossvalgui','on');

%Set crossval gui to default.
setappdata(handles.analysis,'enable_crossvalgui','on');
%Update cvgui.
analysis('updatecrossvallimits',handles)
%Clear table.
mytbl = getappdata(handles.analysis,'ssqtable');
clear(mytbl,'all');

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)
pca_guifcn('gui_updatetoolbar',h,eventdata,handles,varargin);

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)
%two-way x and y
out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%--------------------------------------------------------------------
function out = isyused(handles)
out = true;

%----------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin);
reg_guifcn('calcmodel_Callback',h,eventdata,handles,varargin)
if analysis('isloaded','model',handles)
  %Make sure SSQ table is the current "view" in panel after a calculation.
  analysis('panelviewselect_Callback',handles.analysis,[],handles,1);
end

%----------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.

%From parafac.
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

% --------------------------------------------------------------------
function plotscores_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.plotscores.
%I/O: plotscores_Callback(h,[],handles,extracmds)

pca_guifcn('plotscores_Callback',h,eventdata,handles,varargin{:});

%--------------------------------------------------------------------
function updatefigures(h)
%update any open figures

handles = guidata(h);
if strcmpi(getappdata(handles.analysis,'statmodl'),'none')
  analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);
end

pca_guifcn('updatefigures',h);
%----------------------------------------
function closefigures(handles)
%close the analysis specific figures

if strcmpi(getappdata(handles.analysis,'statmodl'),'none')
  analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);
end

pca_guifcn('closefigures',handles);

%--------------------------------------------------------------------
function out = pre_calc_check(handles)
%Check setting before calculating model.
out = false;
handles = guihandles(handles.analysis);%Update handles because they may be out of date from function handle call.
npts = str2num(get(handles.lwr_npts,'string'));
if isempty(npts)
  analysis('panelviewselect_Callback',handles.analysis, [], handles, 2);
  evrierrordlg('LWR requires number of local points be set. See LWR Settings tab.','Set Number of Local Points')
  return
end

val = get(handles.lwr_algorithm,'value');
str = get(handles.lwr_algorithm,'string');
nlvs = getappdata(handles.pcsedit,'default');
reglvs = str2num(get(handles.lwr_lvs,'string'));
if isempty(reglvs)
  reglvs = 0;
end
opts.algorithm = lower(str{val});

if strcmpi(str{val},'globalpcr')
  if nlvs>npts
    evrierrordlg('Number of LVs must be less than number of local points.','Check Number of Local Points');
    analysis('panelviewselect_Callback',handles.analysis, [], handles, 2);
    return
  end
else
  if reglvs>npts
    evrierrordlg('Number of regression model LVs must be less than number of local points.','Check Number of Local Points');
    analysis('panelviewselect_Callback',handles.analysis, [], handles, 2);
    return
  end
end

out = true;

%----------------------------------------------------
function pcsedit_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.pcsedit.
% Selects number of PCs in the editable text box.

pca_guifcn('pcsedit_Callback',h,eventdata,handles,varargin{:});

%-------------------------------------------------
function updatessqtable(handles,pc)
%Don't use raw model technique.

%NOTE: Not using getssqtable method on this table because of caching of
%      models. Should revisit when Analysis UI is upgraded to web.

if strcmpi(getappdata(handles.analysis,'statmodl'),'none')
  analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);
end

options = lwr_guifcn('options');
modl = analysis('getobjdata','model',handles);
pcs = getappdata(handles.pcsedit,'default');
mytbl = getappdata(handles.analysis,'ssqtable');

if isempty(pcs)
  %Put a value in if one missing.
  pcs = 1;
  setappdata(handles.pcsedit,'default',pcs)
end

%Find max length of table.
maxoption = options.maximumfactors;
curlentable = mytbl.rowcount;
maxpc = max([maxoption, curlentable, pcs]);

%Build table of "<not caclculated>"
newtbl = nan(maxpc,2);
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

%Cache source should be cache from calc button unless model status is
%loaded, then cache source is appdata.modl.
curcachemodls = analysis('getobjdata','modelcache',handles);
if (strcmpi(getappdata(handles.analysis,'statmodl'),'loaded') | isempty(curcachemodls)) & ~isempty(modl)
  curcachemodls = {modelcache('save_uniquename','model',modl)};
  pcs = size(modl.loads{2});
  pcs = pcs(end);
  analysis('setobjdata','modelcache',handles,curcachemodls);
end

%Create vector and display string of cached pcs.
cachepclist = [];
try
  for ii = 1:length(curcachemodls)
    tempcachemodl = modelcache('get',curcachemodls{ii});
    if ~isempty(tempcachemodl)
      tempcachemodlpcs = size(tempcachemodl.loads{2});
      cachepclist(ii) = tempcachemodlpcs(end);
      newtbl{tempcachemodlpcs(end),3} = 'view model';
    end
  end
catch
  %couldn't get models from cache
end

%add current model's information
if ~isempty(modl)
  tempcachemodlpcs = size(modl.loads{2});
  cachepclist(ii) = tempcachemodlpcs(end);
  newtbl{tempcachemodlpcs(end),3} = 'view model';
end

%If current default (pcs) is a cached model,
%display it's ssq information.
if any(cachepclist == pcs)
  if isempty(modl) | size(modl.loads{2},2)~=pcs
    modl = curcachemodls{find(cachepclist == pcs)};
    modl = modelcache('get',modl);
  end
  newtbl(1:pcs,[1 2]) = num2cell(modl.detail.ssq(:,[2 3]));
  if strcmpi(getappdata(handles.analysis,'statmodl'),'loaded')
    %If model status loaded then allow only loaded view.
    newtbl = newtbl(1:pcs,:);
  end
end

if ~isempty(cur_pc)
  newtbl{cur_pc,3} = 'current';
end

%Identify additional columns to add
clbls      = mytbl.column_labels;
lastheader = clbls{end};
clfmt      = mytbl.column_format;
lastfmt    = clfmt{end};

try
  ev = ploteigen(modl); %search Eigenvalues plot for information to include
  myfmt = '%0.5g';
  toadd = find(~cellfun('isempty',regexp(str2cell(ev.label{2}),'^RMSECV')));
catch
  %errors during ploteigen should NOT keep the rest of the code from
  %running (would cause serious issues in GUI status)
  %HOWEVER: we are NOT resetting the lasterror value because we want to be
  %able to catch the error during unit testing, so no lasterror(le) here!  
  ev = [];
  toadd = [];
end
if ~isempty(toadd)
  for addind = 1:length(toadd);
    addfld = toadd(addind);
    val = ev.data(:,addfld);
    m = min(size(newtbl,1),length(val));
    %move last column over by one
    newtbl(:,end+1) = newtbl(:,end);
    %add new column before that one
    newtbl(1:m,end-1) = num2cell(val(1:m));
    [newtbl{m+1:maxpc,end-1}] = deal(nan);
    %add header
    lbl =  ev.label{2}(addfld,:);
    lbl = getheaderlabel(lbl);%Add HTML <br> if needed.
    clbls{size(newtbl,2)-1} = ['<html>' lbl '</html>'];
    if iscell(myfmt)
      clfmt{size(newtbl,2)-1} = myfmt{addind};
    else
      clfmt{size(newtbl,2)-1} = myfmt;
    end
  end
end
nc = size(newtbl,2);
clbls{nc} = lastheader;
clfmt{nc} = lastfmt;
clbls = clbls(1:nc);
clfmt = clfmt(1:nc);

%Update table data.
mytbl.data = newtbl;
mytbl.column_labels = clbls;
mytbl.column_format = clfmt;

%Make selection the current PC.
setselection(mytbl,'rows',pcs)

%set(handles.ssqtable,'String',s,'Value',pcs,'Enable','on')
set(handles.pcsedit,'String',int2str(pcs),'Enable','on')
setappdata(handles.pcsedit,'default',pcs);



%----------------------------------------------------
function  optionschange(h)

handles = guidata(h);
analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);
