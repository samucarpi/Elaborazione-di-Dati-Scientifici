function varargout = mcr_guifcn(varargin);
%MCR_GUIFCN Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%jms/rsk 04/04 Initial coding.
%rsk 05/04/04 Disable maxpc checking in calc
%       -Change ssq table behavior.
%jms 5/7/04 Re-added test for "bad" preprocessing

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
          'scoresincludchange','scoresqconbuttoncall','scorestconbuttoncall','varcapbuttoncall' 'scoresinfobuttoncall_add'};
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
[atb abtns] = toolbar(handles.analysis, 'mcr','');
handles  = guidata(handles.analysis);
set(findobj(handles.AnalysisToolbar,'tag','plotscores'), 'ClickedCallback', 'mcr_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))')

%Enable correct buttons.
analysis('toolbarupdate',handles)  %set buttons

%change pc edit label.
set(handles.pcseditlabel,'string','Number Components:')

mytbl = getappdata(handles.analysis,'ssqtable');
mytbl = ssqsetup(mytbl,{'Fit<br>(%Model)' 'Fit<br>(%X)' 'Fit<br>Cumulative (%X)' ' '},...
  '<b>&nbsp;&nbsp;&nbsp;PC',{'%6.2f' '%6.2f' '%6.2f' ''},1);

set(handles.tableheader,'string','Percent Variance Captured by MCR Model','HorizontalAlignment','center');
%Add view selections to dropdown.
panelinfo.name = 'SSQ Table';
panelinfo.file = 'ssqtable';
panelinfo(2).name = 'MCR Constraints';
panelinfo(2).file = 'mcrgui';
panelmanager('add',panelinfo,handles.ssqframe)

%turn off crossvalidation
setappdata(handles.analysis,'enable_crossvalgui','off');

%general updating
analysis('updatestatusboxes',handles)
analysis('setobjdata','modelcache',handles,[]);
updatefigures(handles.analysis)
updatessqtable(handles)
set(handles.pcsedit,'enable','on')

evritip analysis_mcr

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
closefigures(handles);
analysis('setobjdata','modelcache',handles,[]);
setappdata(handles.analysis,'enable_crossvalgui','on');
%Update cvgui.
analysis('updatecrossvallimits',handles)

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)
pca_guifcn('gui_updatetoolbar',h,eventdata,handles,varargin);

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

out = analysis('isloaded','yblock',handles.analysis);


%----------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin);
if isempty(get(handles.pcsedit, 'string')) & isempty(getappdata(handles.pcsedit, 'defualt'))
  % For mcr, number of components must be supplied. No raw model behavior
  % is supported with this method.
  erdlgpls('Number of Components must be selected','Enter Components')
  return
end

statmodltest = lower(getappdata(handles.analysis,'statmodl'));

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
      opts = mcr('options');
    end
    
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.preprocessing = preprocessing;
    
    y = analysis('getobjdata','yblock',handles);
    yblockmode = 'none';
    if ~isempty(y)
      yblockmode = evriquestdlg('A y-block is currently loaded. Do you want to use these values as an initial guess for the MCR model concentrations or ignore the y-block altogether?','Use Y-block in MCR','Initial MCR Guess','Ignore','Initial MCR Guess');
      switch yblockmode
        case 'Initial MCR Guess'
          pc = y;
          statmodltest = 'none';  %force model to be "none" because we're doing something special
        otherwise
          %do nothing
      end
    end
    
    %calculate model
    modl = [];  %start with empty (as indicator that we didn't find one in the cache)
    curcachemodls = analysis('getobjdata','modelcache',handles);
    
    if strcmp(statmodltest, 'none');
      %Before we do this, test for "bad" preprocessing methods
      if ~strcmp(opts.alsoptions.scon,'none') & ~strcmp(opts.alsoptions.ccon,'none') & ...
          ~isempty(preprocessing{1}) & any(ismember({preprocessing{1}.description},{ 'Autoscale' 'Center' 'Mean Center' 'Median Center' 'SNV' 'Detrend' }));
        switch evriquestdlg({'One or more of your selected preprocessing methods is incompatible with non-negative constraints in MCR (see the Edit/Options menu to change constraints). This may give a very poor fit to the data.',...
            ' ','Are you sure you want to calculate an MCR model now?'},'Preprocessing Warning','Yes','No','Yes');  
        case 'No'
          evritip mcrbadnonneg 
          return
        end
      end

      %clear model cache just in case gui is in bad state.
      curcachemodls = [];
      
    elseif strcmp(statmodltest, 'calnew');
      %To save time, if model to be calculated already exists in cache put
      %it in appdata rather than recalculating. If not in cache, calculate
      %it then put it into cache.
      cacheind = locateincache(curcachemodls,pc);
      if ~isempty(cacheind)
        modl = curcachemodls{cacheind(1)};
      end
    end

    if isempty(modl);
      modl    = mcr(x,pc,opts);
      pc      = size(modl.loads{2},2);   %may have been reduced from what we asked for
      
      cacheind = locateincache(curcachemodls,pc);
      if isempty(cacheind)
        cacheind = length(curcachemodls) + 1;
      end
      curcachemodls{cacheind} = modl;      
    end

    %setappdata(handles.calcmodel, 'modelcache', curcachemodls);
    analysis('setobjdata','modelcache',handles,curcachemodls);
    
    %UPDATE GUI STATUS
    %set status windows
    setappdata(handles.analysis,'statmodl','calold');
    analysis('setobjdata','model',handles,modl);

    analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 1);
    updatessqtable(handles,pc);

end

%apply model to test/validation data (if present)
if analysis('isloaded','validation_xblock',handles)
  %apply model to new data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
  if isempty(x); return; end  %some cancel action

  opts = getappdata(handles.analysis,'analysisoptions');
  if isempty(opts)
    opts               = mcr('options');
  end
  opts.display       = 'off';
  opts.plots         = 'none';
  
  try
    test = mcr(x,modl,opts);
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

%----------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.
% ssqtable value and pcsedit string updated by updatessqtable.

%pca_guifcn('ssqtable_Callback',h,[],handles);

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

%----------------------------------------------------
function pcsedit_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.pcsedit.
% Selects number of PCs in the editable text box.
% ssqtable value and pcsedit string updated by updatessqtable.

pca_guifcn('pcsedit_Callback',h,[],handles);

%--------------------------------------------------------------------
function updatefigures(h)
%update any open figures

pca_guifcn('updatefigures',h);

%----------------------------------------
function closefigures(handles)
%close the analysis specific figures

pca_guifcn('closefigures',handles);

%-------------------------------------------------
function plotscores_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.plotscores.
%I/O: plotscores_Callback(h,[],handles,extracmds)
%  where extracmds is cell to be expanded and passed to plotgui

pca_guifcn('plotscores_Callback',h,eventdata,handles,varargin{:});


%-------------------------------------------------
function updatessqtable(handles,pc)
%Don't use raw model technique in Parafac.
%SSQ info in modl.detail.ssq.percomponent.data

%NOTE: Not using getssqtable method on this table because of caching of
%      models. Should revisit when Analysis UI is upgraded to web.

options = mcr_guifcn('options');
modl = analysis('getobjdata','model',handles);
mytbl = getappdata(handles.analysis,'ssqtable');
pcs = getappdata(handles.pcsedit,'default');

if isempty(pcs)
  %Put a value in if one missing.
  pcs = 1;
  setappdata(handles.pcsedit,'default',pcs)
end

%Find max length of table.
maxoption = options.maximumfactors;
curlentable = mytbl.rowcount;
maxpc = max([maxoption, curlentable, pcs]);

s     = [];
format = getappdata(handles.analysis,'tableformat');

%Build table of "<not caclculated>"
newtbl = nan(maxpc,3);
newtbl = num2cell(newtbl);
newtbl = [newtbl repmat({'not calculated'},maxpc,1)];



% %Build table of "<not caclculated>"
% for kk=1:maxpc
%   s{kk} = [blanks(3 - length(num2str(kk))) num2str(kk) blanks(5) '<not calculated>'];
% end
if strcmpi(getappdata(handles.analysis,'statmodl'),'none') & isempty(modl)
  if ~analysis('isloaded','xblock',handles)
    %Nothing loaded, set to one.
    pcs = 1;
  end
  %No model, update everything and return.
  %Update table data.
  mytbl.data = newtbl;
  %Make selection the current PC.
  setselection(mytbl,'rows',pcs)
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
if (strcmpi(getappdata(handles.analysis,'statmodl'),'loaded') | isempty(curcachemodls)) & ~isempty(modl)
  curcachemodls = {modl};
  pcs = size(curcachemodls{1}.loads{2});
  pcs = pcs(end);
  analysis('setobjdata','modelcache',handles,curcachemodls);
end

%Create vector and display string of cached pcs.
if ~isempty(curcachemodls)
  for ii = 1:length(curcachemodls)
    tempcachemodl = curcachemodls{ii};
    tempcachemodlpcs = size(tempcachemodl.loads{2});
    cachepclist(ii) = tempcachemodlpcs(end);
    newtbl{tempcachemodlpcs(end),4} = 'view model';
    %s{tempcachemodlpcs(end)} = [blanks(3 - length(num2str(tempcachemodlpcs(end)))) num2str(tempcachemodlpcs(end)) blanks(5) '<view model>'];
  end
else
  cachepclist = [];
end
%If current default (pcs) is a cached model,
%display it's ssq information.
if any(cachepclist == pcs)
  modl = curcachemodls{find(cachepclist == pcs)};
  newtbl(1:pcs,[1 2 3]) = num2cell(modl.detail.ssq(:,[2 3 4]));
  if ~analysis('isloaded','xblock',handles)
    %If calibration data isn't loaded then allow only loaded view.
    %s = s(1:pcs);
    newtbl = newtbl(1:pcs,:);
  end
end

if ~isempty(cur_pc)
  newtbl{cur_pc,4} = 'current';
end

%Update table data.
mytbl.data = newtbl;
%Make selection the current PC.
setselection(mytbl,'rows',pcs)

%set(handles.ssqtable,'String',s,'Value',pcs,'Enable','on')
set(handles.pcsedit,'String',int2str(pcs),'Enable','on')
if ~isempty(getappdata(handles.pcsedit,'default'));
  setappdata(handles.pcsedit,'default',pcs);
end

%------------------------------------------------
function ind = locateincache(cache,lookfor)

ncomp = [];
for j=1:length(cache);
  ncomp(j) = size(cache{j}.loads{2,1},2);
end

ind = find(ncomp==lookfor);


%---------------------------------------------------
function optionschange(h,varargin)
%Update options in panel.

handles = guihandles(h);
mcrgui('panelupdate_Callback',handles.analysis, []); 
