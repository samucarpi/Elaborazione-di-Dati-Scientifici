function out = plotgui_toolbar(targfig,options)
%PLOTGUI_TOOLBAR Add toolbar to plotgui target figure

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0
  targfig = [];
end
if ischar(targfig)
  switch targfig
    case 'settings'
      %allow user to select
      btn = plotgui_toolbar([],struct('hide',{{}}));
      hidden = getfield(plotgui_toolbar('options'),'hide');
      sel = find(~ismember(btn(:,2),hidden));
      [s,v] = listdlg('PromptString','Show Toolbar Buttons:','SelectionMode','multiple','ListString',btn(:,5),'InitialValue',sel,'ListSize',[250 300]);
      if v
        setplspref(mfilename,'hide',btn(setdiff(1:size(btn,1),s),2));
        plotgui_toolbar(gcf,struct('forceupdate',1));
      end
      return
      
    otherwise
      %EVRIIO call
      options = [];
      options.hide = {};  %which toolbar items to hide
      options.forceupdate = false;  %whether or not to force an update
      if nargout==0; evriio(mfilename,targfig,options); else; out = evriio(mfilename,targfig,options); end
      return
  end
end

if nargin<2
  options = plotgui_toolbar('options');
else
  options = reconopts(options,mfilename);
end

if ~isempty(targfig) & ishandle(targfig)
  pgt = findobj(targfig,'tag','pgtoolbar');
  delete(pgt(2:end));  %get rid of multiples
  
  if ~getappdata(targfig,'showcontrols')
    return
  end
  
  if ~getappdata(targfig,'pgtoolbar')
    if ~isempty(pgt)
      delete(pgt(1));
    end
    return
  end
  
  data = plotgui('getdataset',targfig);
  if ~isempty(pgt) & ~isempty(data) & ishandle(pgt) & ~options.forceupdate
    d = getappdata(pgt,'moddate');
    if ~isempty(d) & datenum(data.moddate)==d
      %toolbar exists and date matches DSO moddate
      return;
    end
  end
  
  if isempty(plotgui('gethelplink',targfig))
    %hide help button if no specific plot help is present
    options.hide = [options.hide; {'pgthelp'}];
  end
  
  if strcmp(data.type,'image')
    aspressed = getappdata(targfig,'viewautocontrast');
  else
    aspressed = getappdata(targfig,'autoscale');
  end
  aopressed = getappdata(targfig,'autooffset');
  noselect = getappdata(targfig,'noselect');
  compress = getappdata(targfig,'viewcompressgaps');
  
else
  aspressed = 0;
  aopressed = 0;
  noselect = 0;
  compress = 0;
end

if aspressed
  autoscaleimage = 'autoscale_pressed';
else
  autoscaleimage = 'autoscale';
end
if aopressed
  autooffsetimage = 'autooffset_pressed';
else
  autooffsetimage = 'autooffset';
end
if compress
  compressgapsimage = 'compressgaps_pressed';
else
  compressgapsimage = 'compressgaps';
end

btn = {
  'table_edit'     'pgteditdata'        'plotgui(''menuselection'',''FileEdit'')'         'enable' 'View/Edit Data in Editor'    'off' 'push'
  'duplicate_plot' 'pgtduplicate'       'plotgui(''duplicate'',gcbf)'                     'enable' 'Create Duplicate Plot of Data' 'off' 'push'
  'viewnumbers'    'pgtviewnumbers'     'plotgui(''menuselection'',''ViewNumbers'')'      'enable' 'View Numbers on/off'         'on'  'push'
  'viewlabels'     'pgtviewlabels'      'plotgui(''menuselection'',''ViewLabels'')'       'enable' 'View Labels on/off'          'off' 'push'
  'viewaxisscale'  'pgtviewaxisscale'   'plotgui(''menuselection'',''ViewAxisscale'')'    'enable' 'View Axisscale on/off'       'off' 'push'
  'viewexcluded'   'pgtviewexcluded'    'plotgui(''menuselection'',''ViewExcludedData'')' 'enable' 'View Excluded Data on/off'   'off' 'push'
  compressgapsimage 'pgcompressgaps'     'plotgui(''menuselection'',''ViewCompressGaps'')'        'enable'  'Compress X-Axis Gaps' 'off' 'toggle'
  'findpeaks'      'pgfindpeaks'        'peakfindgui(''setup'',gcbf)'                     'enable' 'Adjust Peak Find Settings'   'off' 'push'
  'viewclasses'    'pgtviewclasses'     'plotgui(''viewclassmenu'',gcbf)'                 'enable' 'View Classes/Select Class'   'on'  'push'
  'connectclasses' 'pgtconnectclasses'  'plotgui(''connectclassmenu'',gcbf)'  'enable'  'Connect Classes'     'off' 'push'
  autoscaleimage   'pgtautoscale'       'plotgui(''menuselection'',''ViewAutoScaleToggle'')'     'enable'  'Auto Y-Scale'        'on'  'toggle'
  autooffsetimage  'pgtautooffset'      'plotgui(''menuselection'',''ViewAutoScaleOffsetToggle'')'     'enable'  'Auto Y-Offset'       'off'  'toggle'
  'zoomtool'       'pgtmagnify'         'magnifytooltoggle(gcf);'                         'enable' 'Open/Close magnified axis.'        'off' 'toggle'
  };

if ~noselect
  btn = [btn
    {
    'Settings'       'pgtselecttool'      'plotgui(''selecttoolmenu'',gcbf);'               'enable' 'Choose Selection Tool/Select Classes'  'on'  'push'
    'Select'         'pgtselect'          'plotgui(''makeselection'',gcbf)'                 'enable' 'Make Selection'                        'off'  'push'
    'Selectinvert'   'pgtinvertselection' 'plotgui(''setselection'',{[] []},''invert'',gcbf)'  'enable' 'Invert Selection'                   'off'  'push'
    'Deselect'       'pgtdeselect'        'plotgui(''setselection'',{[] []},''set'',gcbf)'  'enable' 'Deselect All'                          'off'  'push'
    'viewselection'  'toggleselection'    @toggleselection                                  'enable' 'Toggle Selection Visibility'           'off' 'push'
    'selectopentb'   'pgdataselecttb'     'dataselecttoolbar(gcbf)'                         'enable' 'Open/Close Data Selection Toolbar'         'off' 'push'
    }];
end

if ~isempty(targfig) & ishandle(targfig);
  %allow add-on products to add/modify toolbar buttons
  fn = evriaddon('plotgui_toolbar');
  for j=1:length(fn);
    btn = feval(fn{j},btn,targfig);
  end
end

btn = [btn
  {
  'help'       'pgthelp'      'plotgui(''showhelp'',gcbf);'               'enable' 'Give Help on Plot Contents'       'on' 'push'
  }];

btn = [btn
  {
  'bgcolor'     'pgttheme'       'plotgui(''menuselection'',''ViewBackgroundCycle'');'  'enable' 'Change Figure Theme'       'on'   'push'
  'options'     'pgtsettings'    'plotgui(''menuselection'',''ViewSettings'');'         'enable' 'Edit All Settings'         'off'  'push'
  'tabone'      'pgtbuttons'     'plotgui_toolbar(''settings'');'                       'enable' 'Choose Toolbar Buttons'    'off'  'push'
  }];

%prepare to drop hidden items
todrop = ismember(btn(:,2),options.hide);
if any(todrop)
  %handle separators first by creating map of "groups" then dropping
  %members and find which toolbar buttons are first in each group after
  %dropping
  seps = ismember(btn(:,6),{'on'});
  groups = cumsum(double(seps));
  groups(todrop) = [];
  newseps = [false; diff(groups)>0];
  btn(todrop,:) = []; %drop hidden items
  [btn{newseps,6}] = deal('on');
  [btn{~newseps,6}] = deal('off');
end

if ~isempty(targfig) & ~isempty(btn);
  %Get list of toggle buttons and their current state if buttons exist.
  %This info is lost after call to toolbar.m.
  tbuttons = btn(ismember(btn(:,7),'toggle'),2);
  for i = 1:length(tbuttons)
    th = findobj(targfig,'tag',tbuttons{i,1});
    if ~isempty(th)
      %Two buttons can exist at one time so get one value only.
      thisstate = get(th,'state');
      if iscell(thisstate)
        thisstate = thisstate{1};
      end
      tbuttons{i,2} = thisstate;
      
      thiscdata = get(th,'cdata');
      if iscell(thiscdata)
        thiscdata = thiscdata{1};
      end
      tbuttons{i,3} = thiscdata;
    else
      tbuttons{i,2} = '';
      tbuttons{i,3} = [];
    end
  end
end

if nargout==0
  %create/update toolbar
  if isempty(btn); 
    %no buttons? delete and exit
    delete(findobj(targfig,'tag','pgtoolbar'));
    return; 
  end
  pgt = toolbar(targfig,'',btn,'pgtoolbar');
  if isempty(pgt) | ~ishandle(pgt)
    return
  end
  if ~isempty(data)
    setappdata(pgt,'moddate',datenum(data.moddate));
  end
  set(pgt,'buttondownfcn','plotgui_toolbar(''settings'');')
  %Switch toggle buttons back to orginal state.
  for i = 1:size(tbuttons,1)
    if ~isempty(tbuttons{i,2})
      %If this call causes latency we could check to see if state='on' and
      %only call set() in those instances since button will always be off
      %after toolbar call.
      th = findobj(targfig,'tag',tbuttons{i,1});
      if ~isempty(th)
        mystate = tbuttons{i,2};
        if strcmp(get(th,'type'),'uitoggletool')
          set(th,'state',mystate);
        end
        set(th,'cdata',tbuttons{i,3});
      end
    end
  end
else
  %asked for an output? return btn list
  out = btn;
end

%--------------------------------------------------------------------------
function toggleselection(varargin)

h = [findobj(gcf,'userdata','selection'); findobj(gcf,'tag','selection'); findobj(gcf,'DisplayName','selection')];
if ~isempty(h)
  %Note: with multiple items, we use the visibilty of the FIRST selection
  %item to set all others. Normally, they will all be the same (on or off)
  %but using only ONE to determine the new setting corrects for situation
  %when one seleciton gets out-of-phase by an update on a single sub-axes.
  switch get(h(1),'visible')
    case 'on'
      en = 'off';
    otherwise
      en = 'on';
  end
  set(h,'visible',en)
end

