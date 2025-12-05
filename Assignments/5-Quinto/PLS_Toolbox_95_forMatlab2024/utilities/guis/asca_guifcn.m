function varargout = asca_guifcn(varargin)
%ASCA_GUIFCN ASCA Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin>0;
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = analysis('options');
        options.ascafontsize = 14;%Font size on buttons.
        options.scalebuttonsize = 1; %Scale buton size. Use this for high dpi displays like Rasmus. 
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
[atb abtns] = toolbar(handles.analysis, 'asca','');
handles  = guidata(handles.analysis);

cura = getappdata(handles.analysis,'curanal');%Current analysis

%No ssq table, disable.
set(handles.ssqtable,'visible','off')

%Disable prediction blocks.
setappdata(handles.analysis,'predictionblock',1)
setappdata(handles.analysis,'noyprepro',1);

handles = guihandles(handles.analysis);
guidata(handles.analysis,handles);

%Disable crossval.
setappdata(handles.analysis,'enable_crossvalgui','off');

%Add button panel. Buttons are build/updated in gui_updatetoolbar.
mypnl = getappdata(handles.analysis,'ButtonPanel');
if isempty(mypnl)
  mypnl = ButtonPanel(handles.analysis);
else
  set(mypnl.PanelContainer,'visible','on');
  set(mypnl.ButtonPanelScrollPaneHandle,'Visible','on')
end
  
setappdata(handles.analysis,'ButtonPanel',mypnl);

panelinfo.name = 'SSQ Table';
panelinfo.file = 'ssqtable';
switch cura
  case 'asca'
    panelinfo(2).name = 'ASCA Settings';
    panelinfo(2).file = 'ascagui';
  case 'mlsca'
    panelinfo(2).name = 'MLSCA Settings';
    panelinfo(2).file = 'ascagui';
end
panelmanager('add',panelinfo,handles.ssqframe)

%Enable correct buttons.
analysis('toolbarupdate',handles)  %set buttons

%general updating
analysis('updatestatusboxes',handles)
updatefigures(handles.analysis)

%Make sure PC edit controls are not visible. NOTE: ssqvisible function in
%analysis sill turn these back on.
set(handles.findcomp,'visible','off')
set(handles.pcseditlabel,'string','Number PCs:')
set(handles.pcsedit,'enable','on')
set(handles.pcseditlabel,'visible','on');
set(handles.pcsedit,'visible','on');
set(handles.tableheader,'visible','off');

header = 'Model Statistics (* = suggested)';
set(handles.tableheader,'string',header,'HorizontalAlignment','center');
mytbl = getappdata(handles.analysis,'ssqtable');

if strcmp(cura,'mlsca')
  setappdata(handles.analysis,'ssqonly_visible',0)
  setappdata(handles.analysis,'autoselect_visible',1)
  mytbl = ssqsetup(mytbl,{'Term' 'PCs' 'Cum Eigen Val' 'Effect'},...
    'Model',{'%s' '%i' '%6.2f' '%6.2f'},1);
else
  setappdata(handles.analysis,'ssqonly_visible',1)
  setappdata(handles.analysis,'autoselect_visible',0)
  mytbl = ssqsetup(mytbl,{'Term' 'PCs' 'Cum Eigen Val' 'Effect'  'P-value'},...
    'Model',{'%s' '%i' '%6.2f' '%6.2f' '%5.4f'},1);
end

%Saved vector of mlsca submodel components and suggestions.
setappdata(handles.analysis,'mlsca_ncomp',[]);%Ncomp vector for mlsca input.
setappdata(handles.analysis,'mlsca_ncomp_suggested',[]);%Suggested ncomp from choosecomp.
setappdata(handles.analysis,'asca_submodel',[]);%Current selected submodel.

updatessqtable(handles)

%Change panel.
analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);

%--------------------------------------------------------------------
function pcsedit_Callback(h, eventdata, handles, varargin)
%Edit number of PCs for [sub] model. 

disp('edit PCs')

if strcmp(getappdata(handles.analysis,'curanal'),'asca')
  %Should never get here because controls should be disabled but return just in case.
  return
end

%Get asca/mlsca model.
modl       = analysis('getobjdata','model',handles);
if isempty(modl)
  return
end

%Get selected sub model, if empty then looking at main model.
submodlidx = getappdata(handles.analysis,'asca_submodel');%Sub mode index.
if isempty(submodlidx)
  %Set to empty and return. SSQ is display only if looking at main ASCA/MLSCA model.
  set(handles.pcsedit,'String','')
  return
end

%Get number of components user entered.
n    = get(handles.pcsedit,'String');
if ~isempty(n)
  n = fix(str2num(n));
end

if n<1
  n = 1;
end

%Get sub model ncomp vector.
ncmp    = getappdata(handles.analysis,'mlsca_ncomp');
ncmpsub = ncmp(submodlidx);

%Get table and current row count.
mytbl      = getappdata(handles.analysis,'ssqtable');
maxtblrows = mytbl.rowcount;

%TODO: How to figure out max PCs?

if ~analysis('isloaded','xblock',handles)
  if ~isempty(modl)
    %calibration data not loaded? - do NOT change # of components
    set(handles.pcsedit,'String',int2str(ncmpsub))
    setselection(mytbl,'rows',ncmpsub);
    setappdata(handles.pcsedit,'default',ncmpsub)
  else
    %Nothing loaded, allow change if table will accept.
    if ncmpsub>maxtblrows
      ncmpsub = maxtblrows;
    end
    setselection(mytbl,'rows',ncmpsub);
    setappdata(handles.pcsedit,'default',ncmpsub)
  end
else
  %allow change of # of components
  if ~isempty(n);
    if length(n)>1; n = n(1); end;       %only one number permitted
    
    maxlv = mytbl.rowcount;
    if n < 1 | n > maxlv ;     %invalid # of pcs?
      n = [];
    end
  end
  
  if ~isempty(n);
    if isempty(modl)
      %Only data loaded, allow change.
      if n>maxtblrows
        n = maxtblrows;
      end
      setselection(mytbl,'rows',n);
      setappdata(handles.pcsedit,'default',n)
    else
      if n == ncmpsub;
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
        setselection(mytbl,'rows',n)
        ncmp(submodlidx) = n;
        setappdata(handles.analysis,'mlsca_ncomp',ncmp);
        %Don't think we need to update SSQ table.
        %updatessqtable(handles,n);
      end
    end
  else    %invalid entry, use value from ssqtable
    n    = getselection(mytbl,'rows');
    set(handles.pcsedit,'String',int2str(n))
  end;
end

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)

%Change pcsedit back to defualt style.
set(handles.pcsedit,'style','edit')

cb = getappdata(handles.analysis,'savemenucallback');
set(handles.savemodel,'callback',cb)

%Use appdata instead of options pref since we need it to be persistent but
%not outside of an ASCA analysis.
setappdata(handles.analysis,'predictionblock',[])
setappdata(handles.analysis,'noyprepro',0);
setappdata(handles.analysis,'mlsca_ncomp',[]);%Ncomp vector for mlsca input.
setappdata(handles.analysis,'mlsca_ncomp_suggested',[]);%Suggested ncomp from choosecomp.
setappdata(handles.analysis,'asca_submodel',[]);%Current selected submodel.

setappdata(handles.analysis,'enable_crossvalgui','on');

setappdata(handles.analysis,'ssqonly_visible',0)
set([handles.tableheader handles.pcseditlabel handles.ssqtable handles.pcsedit],'visible','on')

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

mypnl = getappdata(handles.analysis,'ButtonPanel');
if ~isempty(mypnl)
  set(mypnl.PanelContainer,'visible','off');
  set(mypnl.ButtonPanelScrollPaneHandle,'Visible','off')
end

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)
%Update toolbar after an action (load or clear data/model along with other
%actions). Called via toolbar update.

mypnl = getappdata(handles.analysis,'ButtonPanel');
if isempty(mypnl)
  return
end

%Update button panel if needed.
statmodl = getappdata(handles.analysis,'statmodl');
modl     = analysis('getobjdata','model',handles);

xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);
opts = asca_guifcn('options');

%Update fontsize in case it changed.
mypnl.FontSize = opts.ascafontsize;

if ~isempty(xblk) & ~isempty(yblk);
  set(handles.ploteffect,'enable','on');
else
  set(handles.ploteffect,'enable','off');
end

termlbls = getterms(handles);

%Make a button list for the button panel;

width_big = round(50*opts.scalebuttonsize);
width_small = round(.5*width_big);
height = round(40*opts.scalebuttonsize);

mylist = { 'button_x' 'X' '' width_big height 'button' 'asca_guifcn';
           'label_eq' '=' '' width_small height 'label'  'asca_guifcn';
           'button_x' '1m' '' width_small height 'label' 'asca_guifcn';
           'label_eq' '+' '' width_small height 'label'  'asca_guifcn'};

for i = 1:length(termlbls);
  mylist = [mylist; {['button_' num2str(i)] termlbls{i}  '' width_big height 'button' 'asca_guifcn'}];
  mylist = [mylist; {['label_' num2str(i)] '+' '' width_small height 'label' 'asca_guifcn'}];
end

mylist = [mylist; {'button_ERR' 'E'  '' width_big height 'button' 'asca_guifcn'}];

% if strcmp(getappdata(handles.analysis,'curanal'),'mlsca')
%   mylist = [mylist; {'button_ERR' 'E'  '' 50 40 'button' 'asca_guifcn'}];
% else
%   mylist = [mylist; {'button_ERR' 'E'  '' 25 40 'label' 'asca_guifcn'}];
% end

mypnl.ButtonList = mylist;

myidx = getappdata(handles.analysis,'asca_submodel');
if ~isempty(myidx)
  BoldSingleButton(mypnl,myidx+1)
end

%----------------------------------------------------
function termlbls = getterms(handles)
%Get term index and labels.

yblk = analysis('getobjdata','yblock',handles);
modl = analysis('getobjdata','model',handles);
opts = asca_guifcn('options');

termidx = {};%Terms index.
termlbls = {};%Labels for buttons.

%Make model take precedence in determining terms. If only a model is
%loaded (without data) you should still be able to see results.
if ~isempty(modl)
  termlbls = str2cell(modl.detail.label{2,2,1});
  modincd  = modl.detail.include{2,2};
  % Alternative to avoid empty termlbls:
  if isempty(termlbls) | length(termlbls)<max(modincd)
    termlbls = modl.detail.effectnames(2:(length(modincd)+1));
  else
    termlbls = termlbls(modincd);
  end
end

if ~isempty(yblk) & isempty(termlbls)
  if isfield(opts,'column_ID')
    %Check options.
    termidx = opts.column_ID;
  elseif isfieldcheck(yblk.userdata,'.DOE')
    %Get indexes of DOE terms.
    termidx = yblk.userdata.DOE.col_ID;
  else
    %Nothing to indicate there are interactions.
    termlbls = doeinteractions(yblk,1);
  end
  if isdataset(yblk)
    %Get labels if any.
    termlbls = str2cell(yblk.label{2});
    if ~isempty(termlbls)
      termlbls = termlbls(yblk.include{2});
    end
  end
end

if isempty(termlbls)
  %Make labels.
  if isempty(termidx) & ~isempty(yblk)
    %Must have loaded a simple yblk and options not set so assume no
    %interactions and build one.
    termidx = num2cell(1:size(yblk,2));
  else
    %Make dummy buttons.
    termidx = {1};
  end
  
  trmlen = length(termidx);
  for i = 1:trmlen
    thislbl = sprintf('F%d*',termidx{i});
    thislbl(end) = [];
    termlbls{i} = thislbl;
  end
end

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)

%two-way x
% out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%discrim: two-way x with classes
%out = xprofile.data & xprofile.ndims==2 & xprofile.class;

%discrim: two-way x with classes OR y
% out = xprofile.data & xprofile.ndims==2 & (xprofile.class | (yprofile.data & yprofile.ndims==2) );

%two-way x and y
out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;

%--------------------------------------------------------------------
function out = isyused(handles)

out = true;

%--------------------------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin)
%Calculate model button clicked.

statmodl = lower(getappdata(handles.analysis,'statmodl'));
mytbl    = getappdata(handles.analysis,'ssqtable');
cura = getappdata(handles.analysis,'curanal');%Current analysis

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
  if isempty(y);
    erdlgpls('No y-block information is loaded. Can not calibrate','Calibrate Error');
    return
  end
  
  preprocessing = {getappdata(handles.preprocessmain,'preprocessing') getappdata(handles.preproyblkmain,'preprocessing')};

  analysisopts = analysis('options');

  try
    opts = getoptions(handles);
    opts.preprocessing = preprocessing;
    
    switch cura
      case 'asca'
        modl = asca(x,y,analysisopts.maximumfactors,opts);
      case 'mlsca'
        ncmp = getappdata(handles.analysis,'mlsca_ncomp');
        
        if isempty(ncmp)
          modl = mlsca(x,y,inf,opts);
          subm = modl.submodel;
          ncmp = [];
          for i = 1:length(subm)
            mycmp = choosecomp(subm{i});
            if isempty(mycmp)
              mycmp = subm{i}.ncomp;
            end
            ncmp(i) = mycmp;
          end
          setappdata(handles.analysis,'mlsca_ncomp',ncmp)
          setappdata(handles.analysis,'mlsca_ncomp_suggested',ncmp)
        end
        
        modl = mlsca(x,y,ncmp,opts);
    end
  catch
    erdlgpls({sprintf('Error using %s method',cura),lasterr},'Calibrate Error');
    return
  end

  %UPDATE GUI STATUS
  setappdata(handles.analysis,'statmodl','calold');
  analysis('setobjdata','model',handles,modl);

  handles = guidata(handles.analysis);
  %reg_guifcn('updatessqtable',handles,minlv);

  analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 1);

%   if isempty(getappdata(handles.pcsedit,'default')) && exist('choosecomp.m','file')==2 && strcmp(options.autoselectcomp,'on')
%     %Make auto selection of components.
%     selectpc = choosecomp(modl);
%     if ~isempty(selectpc) && minlv~=selectpc
%       %Recalculate model
%       %set(handles.ssqtable,'Value',selectpc);
%       setselection(mytbl,'rows',selectpc)
%       statmodl = 'calnew';  %fake out logic below to recalculate model (so we don't duplicate code here)
%     end
%   end

  figure(handles.analysis)
end

%TODO: What to do if 'calnew'

analysis('toolbarupdate',handles)
analysis('updatestatusboxes',handles);

updatessqtable(handles)

%delete model-specific plots we might have had open
h = getappdata(handles.analysis,'modelspecific');
close(h(ishandle(h)));
setappdata(handles.analysis,'modelspecific',[]);

updatefigures(handles.analysis);     %update any open figures

%--------------------------------------------------------------------
function updatefigures(h)
%update any open figures

handles = guidata(h);

%Don't change panel back to settings. If user is adjusting Num PCs then
%will not want to jump back to settings panel when changing sub model.
% %Delete this comment after PLS_Toolbox 8 is released.
% if strcmpi(getappdata(handles.analysis,'statmodl'),'none')
%   analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);
% end

pca_guifcn('updatefigures',h);

%----------------------------------------
function closefigures(handles)
%close the analysis specific figures

if strcmpi(getappdata(handles.analysis,'statmodl'),'none')
  analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);
end

pca_guifcn('closefigures',handles);


%-------------------------------------------------
function updatessqtable(handles,varargin)
%Updaste ssq table. Panel buttons can set SSQ table to display PCA sub
%model results but if this function gets called we should clear everything
%and go back to ASCA display.

if strcmpi(getappdata(handles.analysis,'statmodl'),'none')
  analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);
end

modl = analysis('getobjdata','model',handles);
mytbl = getappdata(handles.analysis,'ssqtable');

clear(mytbl);%Clear data in case there is PCA information.
setappdata(handles.analysis,'asca_submodel',[]);%Reset submodel index. 

if ~isempty(modl)
  [ssq_table,column_headers,column_format] = getssqtable(modl,[],'raw',14,true);
  
  mytbl.data = ssq_table;
  mytbl.column_labels = column_headers;
  mytbl.column_format = column_format;
end

drawnow

% --------------------------------------------------------------------
function storedopts = getoptions(handles)
%Returns options strucutre.

storedopts  = getappdata(handles.analysis,'analysisoptions');

if isempty(storedopts)
  storedopts = asca('options');
end

storedopts.display       = 'off';
storedopts.plots         = 'none';

%----------------------------------------------------
function ButtonPanelCallback(varargin)
%Clicking one of the ButtonPanel buttons. Switch view of ssq table.

bp = varargin{1};
btn = varargin{2};
fig = bp.ParentFigure;
handles = guihandles(fig);
n = 1;

switch btn
  case 'button_x'
    updatessqtable(handles);
    set(handles.pcsedit,'String','','Enable','inactive');%Inactivate edit box since ssq is info only.
    %Clear sub model, this will cause user to be prompted when clicking
    %scores button.
    setappdata(handles.analysis,'asca_submodel',[]);
    BoldSingleButton(bp,1)
  otherwise
    set(handles.pcsedit,'String','','Enable','on')
    modl  = analysis('getobjdata','model',handles);
    mytbl = getappdata(handles.analysis,'ssqtable');
    mytbl = ssqsetup(mytbl,{'Eigenvalue<br>of Cov(X)' '% Variance<br>This PC' '% Variance<br>Cumulative' ' '},...
      '<b>&nbsp;&nbsp;&nbsp;PC',{'%4.2e' '%6.2f' '%6.2f' '%s'},0);
      
    termlbls = getterms(handles);
    if strcmp(btn,'button_ERR')
      myidx = length(termlbls)+1;
    else
      termlbls = getterms(handles);
      jbtn = varargin{3};
      mytxt = char(jbtn.getText);
      myidx = find(ismember(termlbls,mytxt));
    end

    if isempty(modl)
      aopts = asca_guifcn('options');
      myssq = cell(aopts.maximumfactors,4);
    else
      myssq = modl.submodel{myidx}.detail.ssq;
      myssq = num2cell(myssq(:,2:end));
      if strcmp(getappdata(handles.analysis,'curanal'),'mlsca')
        %If MSLCA, add suggested/current column to ssq table.
        myssq = [myssq repmat({' '},size(myssq,1),1)];
       
        %Get ncomp info.
        ncmp = getappdata(handles.analysis,'mlsca_ncomp');
        ncmps = getappdata(handles.analysis,'mlsca_ncomp_suggested');
        
        if ~isempty(ncmp)
          n = ncmp(myidx);%Actual number of components.
        end
        
        %Add suggested and current indication.
        if ~isempty(ncmps)
          myssq{ncmps(myidx),4} = 'suggested';
        end
        
        if ~isempty(ncmps)
          if ncmps(myidx)==n
            myssq{n,4} = 'current*';
          else
            myssq{n,4} = 'current';
          end
        end
      end
    end
    
    mytbl.data = myssq;
    setselection(mytbl,'rows',n)
    %Scores will be for this sub model.
    setappdata(handles.analysis,'asca_submodel',myidx)
    BoldSingleButton(bp,myidx+1)
    
end

%Set to new value.
set(handles.pcsedit,'String',int2str(n))
setappdata(handles.pcsedit,'default',n)

updatefigures(handles.analysis)

%-------------------------------------------------
function plotscores_Callback(h,eventdata,handles,varargin)
%Plot scores toolbar button callback.

termlbls = getterms(handles);
submodlindex = getappdata(handles.analysis,'asca_submodel');
mypnl = getappdata(handles.analysis,'ButtonPanel');
mylist = mypnl.ButtonList;

if isempty(submodlindex)
  if ~inevriautomation
    %Ask user what sub model to plot scores for using plot loads uicontextmenu.
    cmenu = findobj(handles.analysis,'tag','plotloadscontext');
    if isempty(cmenu)
      cmenu = uicontextmenu;
      set(cmenu,'tag','plotloadscontext');
    end
    delete(allchild(cmenu));
    for j=1:length(termlbls);
      uimenu(cmenu,'label',termlbls{j},'callback',['asca_guifcn(''plotscores_cmenu_Callback'',gcbf,[],guidata(gcbf),' num2str(j) ');']);
    end
    uimenu(cmenu,'label','All','Separator','on','callback',['asca_guifcn(''plotscores_cmenu_Callback'',gcbf,[],guidata(gcbf),' num2str(0) ');']);
    pos = get(handles.analysis,'position');
    set(cmenu,'position',[3 pos(4)])
    set(cmenu,'visible','on')
    return
  else
    plotscores_cmenu_Callback(h,[],handles,0);
    return
  end
end

pca_guifcn('plotscores_Callback',h,eventdata,handles,{'connectclasses',1,'connectclassmethod','spider','noinclude',1});

%-------------------------------------------------
function plotscores_cmenu_Callback(h,eventdata,handles,varargin)
%Callback from context menu of what submodel to plot scores on.

setappdata(handles.analysis,'asca_submodel', varargin{1})
plotscores_Callback(h,eventdata,handles,varargin)

%-------------------------------------------------
function plotloads_Callback(h,eventdata,handles,varargin)

pca_guifcn('plotloads_Callback',h,eventdata,handles,varargin{:});


%---------------------------------------------------
function plotvareffects(h,eventdata,handles,varargin)

cmenu = findobj(handles.analysis,'tag','ploteffectscontext');
if isempty(cmenu)
  cmenu = uicontextmenu;
  set(cmenu,'tag','ploteffectscontext');
end
delete(allchild(cmenu));
uimenu(cmenu,'label','Raw Variable Responses','callback','asca_guifcn(''plotvareffects_plot'',guidata(gcbf),0);');
uimenu(cmenu,'label','Preprocessed Variable Responses','callback','asca_guifcn(''plotvareffects_plot'',guidata(gcbf),1);');
pos = get(handles.analysis,'position');
set(cmenu,'position',[3 pos(4)])
set(cmenu,'visible','on')


%---------------------------------------------------
function plotvareffects_plot(handles,prepro,varargin)
opts = boxplot('options');
opts.boxstyle = 'filled';
opts.labelorientation = 'inline';

xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);

varlist = xblk.label{2};
if isempty(varlist)
  varlist = sprintf('Variable %i\n',1:size(xblk,2));
end
varlist = str2cell(varlist);

[selection,ok] = listdlg('ListString',varlist,'SelectionMode','multiple','InitialValue',1,'PromptString','Select X-Variable to View:','Name','Variable Effect Plot');
if ~ok
  return;
end

%determine what we should use to group
opts.groupings = {1 2};  %default
if ~isempty(xblk.class{1,1}) & ~isempty(xblk.class{1,2})
  %two classes defined in X - use those...
  opts.groupings = {1 2};
elseif ~isempty(yblk.class{1,1}) & ~isempty(yblk.class{1,2})
  %two classes defined in Y - use those
  opts.groupings = yblk.classid(1,1:2);
else
  if size(yblk,2)>1
    opts.groupings = {yblk.data(:,1) yblk.data(:,2)};
  else
    opts.groupings = {yblk.data(:,1) []};
  end
end

if prepro
  ppx = getappdata(handles.preprocessmain,'preprocessing');
  ppy = getappdata(handles.preproyblkmain,'preprocessing');
  try
    if ~isempty(yblk);
      yp   = preprocess('calibrate',ppy,yblk); %'apply/cal string
      xblk = preprocess('calibrate',ppx,xblk,yp);
    else
      xblk = preprocess('calibrate',ppx,xblk);
    end
  catch
    erdlgpls(lasterr,'Unable to plot preprocessed data');
    return;
  end
end

boxplot(xblk(:,selection),opts);
fig = gcf;

if length(selection)==1
  ylabel(varlist{selection});
else
  ylabel('Multiple Variables')
end

analysis('adopt',handles,fig,'methodspecific')

%---------------------------------------------------
function optionschange(h,varargin)
%Update options in panel.

handles = guihandles(h);
ascagui('panelupdate_Callback',handles.analysis, []); 

%---------------------------------------------------
function ssqtable_Callback(h,varargin)
%placeholder for SSQ callback (no operation)

handles    = guidata(h);

if strcmp(getappdata(handles.analysis,'curanal'),'asca')
  %No ssq table interaction with ASCA, only MLSCA.
  return
end

modl       = analysis('getobjdata','model',handles);

submodlidx = getappdata(handles.analysis,'asca_submodel');%Sub mode index.
if isempty(submodlidx)
  %Probably clicking on X, main model, so don't try to update.
  return
end

ncmp = getappdata(handles.analysis,'mlsca_ncomp');

mytbl   = getappdata(handles.analysis,'ssqtable');

if ~analysis('isloaded','xblock',handles)
  %calibration data not loaded? - do NOT change # of components
  thismodl   = modl.submodel{submodlidx};
  n    = size(thismodl.loads{2,1},2);
  set(handles.pcsedit,'String',int2str(n))
  setselection(mytbl,'rows',n);
  %set(handles.ssqtable,'Value',n)
  setappdata(handles.pcsedit,'default',n)
else
  %allow change of # of components, if data or model are loaded then adjust
  %statmodl accordingly.
  n = getselection(mytbl,'rows');
  set(handles.pcsedit,'String',int2str(n))
  
  ncmp(submodlidx) = n;
  setappdata(handles.analysis,'mlsca_ncomp',ncmp);
  
end

calstatus = getappdata(handles.analysis,'statmodl');

%Check for calnew.
if ~isempty(modl)
  for i = 1:length(modl.submodel)
    thismodl   = modl.submodel{i};
    if thismodl.ncomp~=ncmp(i)
      calstatus = 'calnew';
      break
    end
  end 
end

setappdata(handles.analysis,'statmodl',calstatus)

analysis('updatestatusboxes',handles);
analysis('toolbarupdate',handles)  %set buttons

if strcmpi(getappdata(handles.analysis,'statmodl'),'none') & ~strcmp(getappdata(handles.analysis,'curanal'),'mlsca')
  analysis('panelviewselect_Callback',handles.panelviewselect, [], handles, 2);
end

