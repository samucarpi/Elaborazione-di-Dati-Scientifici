function varargout = plotgui(varargin)
%PLOTGUI Interactive DataSet object viewer.
%  Plots input (data) and provides control toolbar to select
%   portions of data to view. The toolbar allows interactive selection, 
%   exclusion and classing of rows or columns of data. PLOTGUI has 
%   various additional display options which are given as 
%   'PropertyName', PropertyValue pairs or as a single keyword. 
%   See extended documentation for more information (type 
%   'plotgui examples' and 'plotgui options'). 
%  Some properties and keywords are:
%   'Plotby',[dim] = Dimension [mode] of (data) from which 
%                    pull-down controls should offer selections (1=rows,
%                    2=columns, 
%                    etc. 0 = special "data browser").
%          'Image' = Keyword to display 2 or 3-way array as image, allowing 
%                    selection, classing and exclusion of individual pixels
%                    [e.g., plotgui(x,'image') where (x) is an array].
%   'AxisMenuValues',{[x] [y] [z]} = Three element cell containing indicies or
%                    strings indicating which item or items should be selected 
%                    on each of the three axis pull-down menus.
%   'Figure',[handle] = Property specifying handle of target figure for display of data.
%            'New' =  Keyword to display data in new figure instead of current figure.
%
%  PLOTGUI returns as output (fig) the handle of the figure in which
%  the data is displayed.
%
%I/O: fig = plotgui(data)
%I/O: fig = plotgui(data,'PropertyName',PropertyValue,...)
%
%See also: ANALYSIS, BOXPLOT, DATASET/DATASET, EDITDS, GSELECT, MODELVIEWER, MPLOT, PLOTEIGEN, PLOTLOADS, PLOTSCORES, TRENDTOOL

%NOTE: adding new properties
%  add to defaultoptions()
%  add to validateoptions()

%Copyright Eigenvector Research 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% BK 6/7/2016 plotgui now using positionmanager to remember last position.
% BK 6/15/2016 fixed the 'moving window' artifact.

if nargin == 0  % LAUNCH GUI
  
  fig = openfig(mfilename,'new');
  figbrowser('addmenu',fig);
  
  % Generate a structure of handles to pass to callbacks, and store it. 
  handles = guihandles(fig);
  guidata(fig, handles);

  %Bug work-around for R2011b
  set(handles.xaxismenu,'string',{' '});
  set(handles.zaxismenu,'string',{' '});
  
  drawnow;
  %create eslider next to yaxismenu
  w = 13; %width of eslider
  offset = 22; %padding between yaxismenu and eslider
  set(handles.dataselectorframe,'visible','off');  %HIDE dataselector frame (necessary to see eslider)
  pos = get(handles.yaxismenu,'position');
  epos = [pos(1)+pos(3)+offset pos(2) w pos(4)];
  es = eslider('parent',fig,'range',25,'page_size',500,'position',epos,'callbackfcn','plotgui');
  setappdata(handles.yaxismenu,'eslider',es);
  
  %assign appdata defaults and update figure
  assigndefaults(fig);       %assign default properties
  setappdata(fig,'iscontrolfigure',1);
  sendto(handles.FileOpenIn,'sendto(plotgui(''getlink'',plotgui(''findtarget'',gcbf)))');
  updatefigure(fig);
  set(fig,'visible','on');    %make it visible
  
  if nargout > 0
    varargout{1} = fig;
  end
  
else
  
  if isfield(0,'debug') & strcmp(getappdata(0,'debug'),'on');
    dbstop if all error
  end
  
  if ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
    
     try
      switch lower(varargin{1})
        case evriio([],'validtopics')
          options = defaultoptions;
          if nargout==0
            evriio(mfilename,varargin{1},options);
          else
            varargout{1} = evriio(mfilename,varargin{1},options);
          end
          return; 
        otherwise 
          if nargout == 0;
            feval(varargin{:});
          else
            [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
          end
      end
    catch
      if ~isempty(findstr(['Undefined function ''' varargin{1} ''''],lasterr));     %couldn't find function varargin{1}?
        try  
          if nargout == 0;
            feval('update',varargin{:})
          else
            [varargout{1:nargout}] = feval('update',varargin{:}); %try as an update call
          end;
        catch
          evrierrordlg(lasterr,'Plotting Error');
          if nargout>0
            %with error, make sure we return something to caller (otherwise,
            %errors are squelched because of "output not returned" message)
            [varargout{1:nargout}] = deal([]);
          end
        end
      elseif ~isempty(findstr('etappdata',lasterr)) & ~isempty(findstr('object handle',lasterr)) %getappdata or setappdata object handle error
        %squelch error and exit
        if nargout>0
          %with error, make sure we return something to caller (otherwise,
          %errors are squelched because of "output not returned" message)
          [varargout{1:nargout}] = deal([]);
        end
      else
        %unrecognized error
        evrierrordlg(lasterr,'Plotting Error');
        if nargout>0
          %with error, make sure we return something to caller (otherwise,
          %errors are squelched because of "output not returned" message)
          [varargout{1:nargout}] = deal([]);
        end
      end
    end
    
  else      %DEFAULT MODE IS UPDATE (used if first argument isn't a character)
    
    try
      if nargout == 0;
        feval('update',varargin{:})
      else
        [varargout{1:nargout}] = feval('update',varargin{:}); %default mode call
      end;
    catch
      erdlgpls(lasterr,'Plotting Error');
      if nargout>0
        %with error, make sure we return something to caller (otherwise,
        %errors are squelched because of "output not returned" message)
        [varargout{1:nargout}] = deal([]);
      end
    end
    
  end
  
  %Position gui from last known position.
%   if strcmp(varargin{1}, 'getdataset')
%     fig = varargin{2};
%     figpos = get(fig,'position');
%     oldpos = positionmanager(fig,'plotgui','get');
%     newpos=[1,1,figpos(1,3),figpos(1,4)];
%     if ~isempty(oldpos)
%       newpos(1,1:2)= oldpos(1,1:2);
%     else
%       figpos = get(fig,'position');
%       newpos(1,1:2) = figpos(1,1:2);
%       oldpos = figpos;
%     end
%     
%     set(fig,'position',newpos);
%     positionmanager(fig,'plotgui','onscreen');
%   end
end

%------------------------------------------------------
%Define default property values (may be superseeded by setplspref values)
function default = defaultoptions;

default.asimage = [];
default.axismenuvalues    = {[] [] []};
default.axismenuindex     = {[] [] []};
default.axismenuenable    = [1 1 1];
default.axisautoinvert    = 1;
default.autoduplicate     = 1;
default.autopopulate      = 1;
default.autosizemarkers   = 0;
default.brushwidth        = [];
default.classsymbol       = '';
default.classsymbolsize   = [];
default.classcolormode    = '';
default.classfacecolor    = 1;
default.classmodeuser     = [];%Class mode that user can specify (when in summary mode).
default.classcoloruser    = 0;%Force user defined class colors to be used, this is a shortcut for user to define class colors via context menu. It will override all color choices when turned on.  
default.connectclassmethod = 'pca';
default.connectclasslimit  = .95;
default.connectclassitems  = [];
default.connectitems      = [];
default.connectitemsstyle = '';
default.connectitemslinewidth = 2;
default.closeguicallback  = [];
default.colorby           = [];
default.colorbybins       = 30;
default.colorbyscale      = 'linear';
default.colorbydirection  = 'lines';%If data is square, what direction should be the defualt to apply colorby ('lines' or 'points'). Direction is inferred by data size otherwise.
default.colorscalelock   = -1; %-1=no lock, 0=lock to min max, [c1 c2] = custom min max.
default.conflimits        = [0];
default.connectclasses    = [0];
default.declutter         = [0.5];
default.declutter_usewaitbar = 0; 
default.declutter_chunksize = 0;
default.declutter_usepixels = 1; 
if checkmlversion('>=','8.4')%2015b or newer
  default.declutter_usepixels = 0;%Speed up label declutter.
end
default.drilllink         = [];
default.findpeakswidth    = [];
default.findpeakssettings = [];
default.figuretheme       = [];
default.targetaxestag     = '';
default.helplink          = '';
default.imagegunorder     = [1 2 3];
default.iscontrolfigure   = [0];
default.labelselected     = [1];
default.labelwithnumber   = 'auto'; %'on' 'off' 'auto'
default.limitsvalue  = [95];
default.linestyle    = [];
default.menulabelset = [1];
default.maximumitems  = [500];
default.maximumyitems = [200000];
default.maximumdatasummary = 1000;
default.maxclassview = [200];
default.densitybinsmax = 512;
default.densitybinsmin = 64;
default.noinclude    = [0];
default.noload       = [0];
default.noselect     = [0];
default.plotby       = [inf];
default.plotcommand  = [];
default.plottype     = [];
default.automonotonic = 0;
default.autoscale        = 0;
default.autooffset       = 0;
default.autoscaleorder   = 1;
default.autoscalewindow  = {};
default.autoscalebaseline = 1;
default.selection        = [];
default.selectioncolor     = [1 0 1];
default.selectionmarker    = [];
default.selectionmode      = 'rbbox';
default.selectpersistent   = [0];
default.imageselection     = 'overlay';
default.selectiontimestamp = [];
default.showcontrols       = [1];
default.slabcolorcontrast  = 0.8;
default.slabcolormode      = 'rgb';
default.pgtoolbar         = [1];
default.showlimits        = [0];
default.status            = [];
default.symbolset         = '';
default.symbolsize        = [];
default.linewidth         = [];
default.textinterpreter   = 'none';
default.uicontrol         = [];
default.usespecialmarkers = [0];
default.validplotby       = [];
default.viewautocontrast  = [0];
default.viewaxislines     = [0 0 0];
default.viewaxisplanes    = [0];
default.viewdiag          = [0];
default.viewclasses       = [0];
default.viewclassset      = [1];
default.viewclassesasoverlay = [0];
default.viewcompressgaps   = 0;
default.viewdensity       = [1];
default.viewexcludeddata  = [0];
default.viewinterpolated  = [0];
default.viewlabels        = [0];
default.viewlabelangle    = [0];
default.viewlabelset      = [1];
default.viewlabelprespace = 1 + 2*ismac;
default.viewlabelmaxy     = [];
default.viewlabelminy     = [];
default.viewlabelmoveobjectthreshold = 500;
default.viewaxisscale     = [0];
default.viewaxisscaleset  = [1];
default.viewpixelscale    = 0;
default.viewlog           = [0 0 0];
default.viewnumbers       = [0];
default.viewtable         = [0];
default.viewtimeaxis      = [0 0 0];
default.viewtimeaxisauto  = [1];
default.viewmaxlabelcount = [];%Absolute max number of labels to show (declutter is done after this is applied).
default.viewlegend3dhandlevis = [0];%Remove handle visibility on plotted 3D data. 
default.viewlegendmarkersize = [];%Marker size on a legend.
default.vsindex           = [1 0];
default.definitions = optiondefs;

%------------------------------------------------------
function assigndefaults(fig);
%ASSIGNDEFAULTS sets the default PlotGUI properties for the current figure
% USAGE: assigndefaults(fig)
%   fig is an optional parameter specifying which figure (if other than the 
%    current figure) to assign defaults

if nargin==0; fig=gcf; end

default = plotgui('options');

%set some additional fields not defined in the options structure but
%required internally
default.figuretype        = 'PlotGUI';
default.axismenuindex     = [];
default.buttonhandles     = [];
default.children    = [];
default.controlby   = [];
default.dataset     = [];
default.modes       = [];
default.target      = [];

%Technically, any unassigned appdata property will have a default value of
% the empty set. We are listing all the properties here to make it easier
% to assign new defaults

%Assign all the appdata properties
setappdatas(fig,default);

%Assign other figure properties
set(fig,'closerequestfcn','try;plotgui(''closegui'',gcbf);catch;delete(gcbf);end');


% --------------------------------------------------------------------
function menuselection(varargin)
% clearing house for any menu selection
% Normally called from GUI menu
%  menuselection()
% Can be called with inputs:
%  menuselection('tagname')  %issues a command as if 'tagname' menu was selected

fig = gcbf;   %callback figure is current

if isempty(fig) | (~isempty(get(fig,'tag')) & ~strcmp(get(fig,'tag'),'PlotGUI') & ~strcmp(char(getappdata(fig,'figuretype')),'PlotGUI'))
  fig = gcf;%if not available, do current figure
  cbo = '';
else
  %Do gcbo
  cbo = gcbo;
end      

[targfig,fig] = findtarget(fig);     %get target figure (if any)
handles = guidata(fig);              %get handles
if getappdata(fig,'target')~=targfig
  dockcontrols(targfig);
end

if nargin ~= 1 | ~ischar(varargin{1});
  menu    = get(gcbo,'tag');
else
  menu  = varargin{1};
end

if isempty(cbo) | cbo==targfig | cbo==fig
  cbo = findobj(fig,'tag',menu);
  if ~isempty(cbo);
    cbo = cbo(1);
  end
end
topmenu = get(get(cbo,'parent'),'tag');

switch menu
  case {'PlotMenu'}    %-- Plot-By Modes --

    mydataset = getdataset(targfig);
    plotby    = getappdata(targfig,'plotby');
    pbhandles = [handles.ViewPlotBy_0 handles.ViewPlotBy_1 handles.ViewPlotBy_2 handles.ViewPlotBy_3 handles.ViewPlotBy_4 handles.ViewPlotBy_n];
    set(pbhandles(4:end),'checked','off','visible','off');      %uncheck all modes
    set(pbhandles(1:3),'checked','off','visible','on','enable','off');      %show but disable standard modes
    if ~isempty(plotby) & ~isempty(mydataset) & isa(mydataset,'dataset') & ~isempty(mydataset.data);
      if isempty(getappdata(targfig,'asimage'));    %not asimage... normal plotby command...
        validplotby = getappdata(targfig,'validplotby');
        if isempty(validplotby); validplotby = 0:length(pbhandles)-1; end;
        set(pbhandles(validplotby+1),'visible','on','enable','on');      %make all modes visible (except those not in validplotby)
        for mode = ndims(mydataset)+1:4;   %turn off ones beyond the size of the dataset
          set(pbhandles(mode+1),'visible','off');
        end;
        set(pbhandles(1+1),'label','Rows');
        set(pbhandles(end),'visible','off');
        set(pbhandles(plotby+1),'checked','on','visible','on','enable','on');   %check current item
      else    %special code for asimage mode...
        set(pbhandles,'visible','off');      %make all modes invisible
        set(pbhandles(1+1),'label','Pixels');

        set(pbhandles([0 1 3]+1),'visible','on','enable','off');   %except the ones of interest to this mode        
        validplotby = getappdata(targfig,'validplotby');
        if ismember(2,validplotby); validplotby(validplotby==2) = 3; end  %switch 2 to be 3 if present
        if isempty(validplotby); validplotby = [0 1 3]; end;
        set(pbhandles(validplotby+1),'visible','on','enable','on');      %make all modes visible (except those not in validplotby)

        if plotby < 2;
          set(pbhandles(plotby+1),'checked','on');
        else
          set(pbhandles(3+1),'checked','on');
        end
      end
    end
    
  case {'ViewPlotBy_0' 'ViewPlotBy_1' 'ViewPlotBy_2' 'ViewPlotBy_3' 'ViewPlotBy_4' 'ViewPlotBy_n'};
    
    set(get(get(cbo,'parent'),'children'),'checked','off');
    set(cbo,'checked','on');
    
    tag     = get(cbo,'tag');
    plotby  = str2num(tag(end));
    if ~isempty(plotby);
      update('figure',targfig,'plotby',plotby);
    end
        
    %================================================================
  case {'View'}   %update menu and check statuses
    
    if (targfig == fig & isempty(getappdata(targfig,'children')) & isloaded(targfig));    %No childfigs and no data? No anything in edit!
      enable = 'off';
    else
      enable = 'on';
    end
    
    for childtag = {'ViewLabels', 'ViewLabelAngle', 'ViewAxisscale', 'ViewNumbers', 'ViewExcludedData', 'ViewCompressGaps', 'ViewClasses', 'ViewInterpolated', 'ViewAutoContrast', 'ViewTable', 'ViewAutoScale'};     %for only these items
      set(getfield(handles,childtag{:}),'enable',enable);
    end
    set([handles.ViewDuplicate handles.ViewSubplots handles.ViewSpawn handles.ViewAxisLines handles.ViewDiag handles.ViewLog handles.ViewDeclutter],'enable',enable);    
    
    %-- extract some settings from target figure --
    for childtag = {'ViewLabels', 'ViewAxisscale', 'ViewNumbers', 'ViewExcludedData', 'ViewCompressGaps', 'ViewClasses', 'ViewInterpolated', 'ViewAutoContrast', 'ViewTable' 'ViewDiag'};     %for only these items
      h = getfield(handles,childtag{:});
      val = getappdata(targfig,lower(childtag{:}));

      %special test for viewtable
      if strcmp(childtag,'ViewTable');  
        databox = getappdata(targfig,'databoxhandle');
        if isempty(databox) | ~ishandle(databox); 
          val = 0;      %reset value if databox figure is gone
          setappdata(targfig,'databoxhandle',[]);   %and clear handle
        end 
        setappdata(targfig,lower(childtag{:}),val);
      end
      
      if ~isempty(val)    %appdata value defined for given figure?
        if val;           %set menu based on appdata value
          set(h,'checked','on');
        else
          set(h,'checked','off');
        end
      else    %NO appdata value defined for given figure?
        setappdata(targfig,lower(childtag{:}),strcmp(get(h,'checked'),'on'));    %set appdata based on menu option
      end
    end
    
%     %-- labels, classes, and numbers --
     mydataset = getdataset(targfig);
     
     %2011a+ Can't do dynamic menus. Menus are updated at end of update
     %subfunction.
     if ~ismac | checkmlversion('>=','8,2')
       %Dynamic menuses seem to work in newer versions of Mac.
       dynamicmenubuild(targfig,handles)
     end
     
    %handle enabling of View Numbers
    if isempty(mydataset) | ~isa(mydataset,'dataset') | isempty(mydataset.data) ...
        | ~isempty(getappdata(targfig,'asimage')) | ndims(mydataset)>2;
      set(handles.ViewNumbers,'enable','off','checked','off');
      setappdata(targfig,'viewnumbers',0);
    else
      set(handles.ViewNumbers,'enable','on');
    end      
    
    %-- View Options related to Images --
    h = findobj(allchild(get(targfig,'currentaxes')),'userdata','data');
    if ~isempty(mydataset) & (strcmp(mydataset.type,'image') | (~isempty(h) & strcmp(getappdata(h(1),'plottype'),'image')));
      set(handles.ViewAutoContrast,'visible','on','enable','on');
      %       if getappdata(targfig,'plotby')==0;
      set(handles.ViewInterpolated,'visible','off','checked','off');
      setappdata(targfig,'viewinterpolated',0);
      set(handles.ViewAutoScale,'visible','off');
      %       else
      %         set(handles.ViewInterpolated,'visible','on','enable','on');
      %       end
    else
      set(handles.ViewAutoContrast,'visible','off','checked','off');
      setappdata(targfig,'viewautocontrast',0);
      set(handles.ViewInterpolated,'visible','off','checked','off');
      setappdata(targfig,'viewinterpolated',0);
      set(handles.ViewAutoScale,'visible','on');
    end      

    %ViewAutoScale settings
    scl = getappdata(targfig,'autoscale');
    sclorder = getappdata(targfig,'autoscaleorder');
    offset = getappdata(targfig,'autooffset');
    autoscalebaseline = getappdata(targfig,'autoscalebaseline');
    set([handles.ViewAutoScale allchild(handles.ViewAutoScale)'],'checked','off');
    if scl>0 & sclorder>0
      set(handles.ViewAutoScale,'checked','on');
      fld = ['ViewAutoScale' num2str(sclorder)];
      if isfield(handles,fld);
        set(handles.(fld),'checked','on');
      end
      set(handles.ViewAutoScaleWindow,'enable','on');
      if ~isempty(getappdata(targfig,'autoscalewindow'))
        set(handles.ViewAutoScaleClear,'enable','on');
      else
        set(handles.ViewAutoScaleClear,'enable','off');        
      end
      if autoscalebaseline
        chk = 'on';
      else
        chk = 'off';
      end
      set(handles.ViewAutoScaleBaseline,'checked',chk,'enable','on')

    elseif offset
      set(handles.ViewAutoScale,'checked','on');
      set(handles.ViewAutoScaleOffset,'checked','on');
      set(handles.ViewAutoScaleWindow,'enable','on');
      if ~isempty(getappdata(targfig,'autoscalewindow'))
        set(handles.ViewAutoScaleClear,'enable','on');
      else
        set(handles.ViewAutoScaleClear,'enable','off');        
      end
      set(handles.ViewAutoScaleBaseline,'checked','on','enable','off')

    else
      set(handles.ViewAutoScale0,'checked','on');
      set([handles.ViewAutoScaleWindow handles.ViewAutoScaleClear],'enable','off');
      set(handles.ViewAutoScaleBaseline,'checked','off','enable','off')
    end

    
    %--Dock Controls and Settings --
    if fig == targfig;
      set(handles.ViewDockControls,'enable','off','checked','off');
      set(handles.ViewSettings,'enable','off');
    else
      set(handles.ViewDockControls,'enable','on');
      set(handles.ViewSettings,'enable','on');
    end

  case {'ViewClassesAsOverlay'}
    update('figure',targfig,'viewclassesasoverlay',~getappdata(targfig,'viewclassesasoverlay'));
    
  case {'ViewBackgroundCycle'}
    figuretheme(targfig,'next');
    
  case {'ViewSubplots'}
    
  case {'ViewSubplots1' 'ViewSubplots2' 'ViewSubplots3' 'ViewSubplots4' 'ViewSubplots5' 'ViewSubplots6' 'ViewSubplots7' 'ViewSubplots8' 'ViewSubplots9' 'ViewSubplotsCustom'}
    nplts = str2num(menu(13:end));
    if isempty(nplts)
      nplts = inputdlg({['Enter total number of desired subplots, or number of rows and columns (comma separated)']},'Custom Subplots',1,{''});
      if isempty(nplts)
        return;
      end
      nplts = str2num(nplts{1});
      if isempty(nplts)
        return;
      end
    elseif ismember(nplts,[3 5 7])
      nplts = [nplts 1];
    end      
    figure(targfig);
    if ~getappdata(targfig,'autopopulate')
      mplot(nplts);
    else
      [pr,pc] = mplot(nplts);
      
      %get current selection and add appropriate new selections to all
      %subplots
      amv = getappdata(targfig,'axismenuvalues');
      ami = getappdata(targfig,'axismenuindex');
      maxy = length(get(handles.yaxismenu,'string'));
      offset = ami{2}-1;
      for j=1:nplts;
        subplot(pr,pc,j);
        if j>1;
          selitem = mod(j+offset-1,maxy)+1;
          amv{2} = selitem;
          ami{2} = selitem;
        end
        setappdatas(gca,struct('axismenuvalues',{amv},'axismenuindex',{ami}))
      end
    end
    %update all plots
    if nplts>1
      addcmd = {'autoduplicate',1};
    else
      addcmd = {};
    end
    update('figure',targfig,addcmd{:});
    
  case {'ViewAutoScale'}
  case {'ViewAutoScale0' 'ViewAutoScale1' 'ViewAutoScale2' 'ViewAutoScaleInf' ...
      'ViewAutoScaleWindow' 'ViewAutoScaleOff' 'ViewAutoScaleOffset'  'ViewAutoScaleOn' 'ViewAutoScaleToggle' 'ViewAutoScaleOffsetToggle'}

    autoscale = [];  %default is no change
    autooffset = [];
    %get order (if setting)
    if any(~ismember(menu(14:end),['0':'9']))
      if strcmpi(menu(14:end),'Inf')
        order = inf;
      else
        order = [];
      end
    else
      order = str2num(menu(14:end));
    end
    if ~isempty(order)
      if order~=0
        %actual non-zero value? set it along with turning on autoscale
        settings = {'autoscale',1,'autoscaleorder',order,'autooffset',0};
        autoscale = 1;
        autooffset = 0;
      else
        %zero? do NOT actually store this as autoscaleorder, only turn it
        %off (equivalent to 'Off')
        settings = {'autoscale',0,'autooffset',0};
        autoscale = 0;
        autooffset = 0;
      end      
    else
      %No number? one of the other options
      switch menu(14:end)
        case 'On'
          settings = {'autoscale',1,'autooffset',0};
          autoscale = 1;
          autooffset = 0;
        case 'Off'
          settings = {'autoscale',0,'autooffset',0};
          autoscale = 0;
          autooffset = 0;
        case 'Window'
          %only setting window, don't do anything with the other settings
          settings = {};
        case 'Offset'
          settings = {'autoscale',0,'autooffset',1};
          autoscale = 0;          
          autooffset = 1;
        case 'OffsetToggle'
          autooffset = getappdata(targfig,'autooffset');
          if ~autooffset
            autoscale = 0;
            autooffset = 1;
          else
            autoscale = 0;
            autooffset = 0;
          end
          settings = {'autoscale',autoscale,'autooffset',autooffset};
        case 'Toggle'
          autoscale = getappdata(targfig,'autoscale');
          if ~autoscale
            autoscale = 1;
            autooffset = 0;
          else
            autoscale = 0;
            autooffset = 0;
          end
          settings = {'autoscale',autoscale,'autooffset',autooffset};
      end
    end
    
    %set current view as autoscale window
    axh = get(targfig,'currentaxes');
    ax = get(axh,'xlim');
    dh = findobj(allchild(axh),'userdata','data');
    if isempty(dh)
      erdlgpls('Data must be plotted before setting Auto Scale window','Window Not Set');
      return;
    end
    xdata = get(dh(1),'xdata');
    win = find(xdata>=ax(1) & xdata<=ax(2));
    update('figure',targfig,settings{:},'autoscalewindow',win);

   
    %update autoscale and autooffset button images
    bh = findobj(targfig,'tag','autoscalebutton');
    if isempty(bh)
      bh = findobj(targfig,'tag','pgtautoscale');
    end
    if ~isempty(autoscale) & ishandle(bh)
      %update button status and image
      if autoscale
        set(bh,'state','on');
        cdata = gettbicons('autoscale_pressed');
      else
        set(bh,'state','off');
        cdata = gettbicons('autoscale');
      end
      set(bh,'cdata',cdata);
    end

    bh = findobj(targfig,'tag','autooffsetbutton');
    if isempty(bh)
      bh = findobj(targfig,'tag','pgtautooffset');
    end
    if ~isempty(autooffset) & ishandle(bh)
      %update button status and image
      if autooffset
        set(bh,'state','on');
        cdata = gettbicons('autooffset_pressed');
      else
        set(bh,'state','off');
        cdata = gettbicons('autooffset');
      end
      set(bh,'cdata',cdata);
    end

    
  case {'ViewAutoScaleBaseline'} 
    val = getappdata(targfig,'autoscalebaseline');
    update('figure',targfig,'autoscalebaseline',~val);
    
  case {'ViewAutoContrast'}
    val = getappdata(targfig,lower(menu));
    val = ~val;
    setappdata(targfig,lower(menu),val);
    plotds(targfig);

    bh = findobj(targfig,'tag','autoscalebutton');
    if isempty(bh)
      bh = findobj(targfig,'tag','pgtautoscale');
    end
    if ishandle(bh)
      %update button status and image
      if val
        set(bh,'state','on');
        cdata = getfield(gettbicons,'autoscale_pressed');
      else
        set(bh,'state','off');
        cdata = getfield(gettbicons,'autoscale');
      end
      set(bh,'cdata',cdata);
    end

  case {'ViewAutoScaleClear'}
    %clear window orders
    update('figure',targfig,'autoscalewindow',[]);    
    
  case {'ViewAxisLines'}
    
    stat = getappdata(targfig,'viewaxislines');
    if length(stat)<3;
      stat(3)=0;      %only two values? make Z be "off"
    end
    %     menuindex = getappdata(targfig,'axismenuindex');
    %     if menuindex{3}>0;
    set(handles.ViewAxisLinesZ,'enable','on');
    %     else
    %       set(handles.ViewAxisLinesZ,'enable','off');
    %       stat(3) = 0; %turn off zaxis line if only 2D
    %     end
    set([handles.ViewAxisLinesAll handles.ViewAxisLinesX handles.ViewAxisLinesY],'enable','on');
    
    setappdata(targfig,'viewaxislines',stat);   %save in case we made some change above
    
    tags = {'ViewAxisLinesX' 'ViewAxisLinesY' 'ViewAxisLinesZ'};
    for k = 1:3;
      if stat(k);
        val = 'on';
      else
        val = 'off';
      end
      set(getfield(handles,tags{k}),'checked',val);
    end
    
    if getappdata(targfig,'viewaxisplanes')
      en = 'on';
    else
      en = 'off';
    end
    set(handles.ViewAxisPlanes,'checked',en);
    
  case 'ViewAxisPlanes'
    
    val = getappdata(targfig,'viewaxisplanes');
    plotgui('update','figure',targfig,'viewaxisplanes',~val);
    
  case {'ViewAxisLinesX' 'ViewAxisLinesY' 'ViewAxisLinesZ'}
    
    if strcmp(get(cbo,'checked'),'on')
      set(cbo,'checked','off')
    else
      set(cbo,'checked','on')
    end
    stat = [strcmp(get(handles.ViewAxisLinesX,'checked'),'on') ...
        strcmp(get(handles.ViewAxisLinesY,'checked'),'on') ...
        strcmp(get(handles.ViewAxisLinesZ,'checked'),'on')];
    setappdata(targfig,'viewaxislines',stat);
    plotds(targfig);
    
  case {'ViewAxisLinesAll'}
    
    stat = [1 1 1];
    setappdata(targfig,'viewaxislines',stat);
    plotds(targfig);
    
  case {'ViewAxisLinesNone'}
    
    stat = [0 0 0];
    setappdata(targfig,'viewaxislines',stat);
    plotds(targfig);
  case {'ViewDensityToggle'}
    %Toggle state of view density.
    vd = getappdata(targfig,'viewdensity');
    update('figure',targfig,'viewdensity',~vd);    
    
  case {'ViewCompressGaps'}
    cg = ~getappdata(targfig,'viewcompressgaps');
    update('figure',targfig,'viewcompressgaps',cg);    

    %update autoscale and autooffset button images
    bh = findobj(targfig,'tag','pgcompressgaps');
    if ishandle(bh)
      %update button status and image
      if cg
        set(bh,'state','on');
        cdata = gettbicons('compressgaps_pressed');
      else
        set(bh,'state','off');
        cdata = gettbicons('compressgaps');
      end
      set(bh,'cdata',cdata);
    end

  case {'ViewLog'}
    
    cax = get(targfig,'currentaxes');
    stat = ismember(get(cax,{'xscale' 'yscale' 'zscale'}),'log');
    menuindex = getappdata(targfig,'axismenuindex');
    if menuindex{3}>0;
      set(handles.ViewLogZ,'enable','on');
    else
      set(handles.ViewLogZ,'enable','off');
      stat(3) = 0; %turn off zaxis line if only 2D
    end
    set([handles.ViewLogAll handles.ViewLogX handles.ViewLogY],'enable','on');
    
%     setappdata(targfig,'viewlog',stat);   %save in case we made some change above
    
    tags = {'ViewLogX' 'ViewLogY' 'ViewLogZ'};
    for k = 1:3;
      if stat(k);
        val = 'on';
      else
        val = 'off';
      end
      set(getfield(handles,tags{k}),'checked',val);
    end
    
  case {'ViewLogX' 'ViewLogY' 'ViewLogZ'}
    
    if strcmp(get(handles.(menu),'checked'),'on')
      set(handles.(menu),'checked','off')
    else
      set(handles.(menu),'checked','on')
    end
    stat = [strcmp(get(handles.ViewLogX,'checked'),'on') ...
      strcmp(get(handles.ViewLogY,'checked'),'on') ...
      strcmp(get(handles.ViewLogZ,'checked'),'on')];
    mode = {'linear' 'log'};
    cax = get(targfig,'currentaxes');
    set(cax,{'xscale','yscale','zscale'},mode(stat+1))
    plotds(targfig);
  
  case {'ViewLogAll'}
    
    cax = get(targfig,'currentaxes');
    set(cax,{'xscale','yscale','zscale'},{'log' 'log' 'log'})
    plotds(targfig);
    
  case {'ViewLogNone'}
    
    cax = get(targfig,'currentaxes');
    set(cax,{'xscale','yscale','zscale'},{'linear' 'linear' 'linear'})
    plotds(targfig);
 
  case {'ViewDeclutter'}
    
    set([handles.ViewDeclutterNone handles.ViewDeclutterLight handles.ViewDeclutterModerate handles.ViewDeclutterMaximum],'checked','off');
    lvl = getappdata(targfig,'declutter');
    if lvl>0 & lvl<1;
      set(handles.ViewDeclutterLight,'checked','on');
    elseif lvl>=1 & lvl<5;
      set(handles.ViewDeclutterModerate,'checked','on');
    elseif lvl>5;
      set(handles.ViewDeclutterMaximum,'checked','on');
    else
      set(handles.ViewDeclutterNone,'checked','on');
    end
    if getappdata(targfig,'labelselected')
      enb = 'on';
    else
      enb = 'off';
    end
    set(handles.ViewDeclutterSelected,'checked',enb);
    
  case {'ViewDeclutterNone', 'ViewDeclutterLight', 'ViewDeclutterModerate', 'ViewDeclutterMaximum'}
    
    switch menu
      case {'ViewDeclutterLight'}
        setappdata(targfig,'declutter',.5);
      case {'ViewDeclutterModerate'}
        setappdata(targfig,'declutter',1);
      case {'ViewDeclutterMaximum'}
        setappdata(targfig,'declutter',10);
      otherwise
        setappdata(targfig,'declutter',0);
    end
    plotds(targfig);

  case {'ViewDeclutterCustom'}
    fact = getappdata(targfig,'declutter');
    newfact = inputdlg({['Enter Decluttering Factor' 10 '(0 None, 0-1 Slight, 1-5 Moderate, 5+ Strong):']},'Set Declutter Level',1,{num2str(fact)});
    if ~isempty(newfact);
      newfact = abs(str2num([newfact{:}]));
      if isnan(newfact) | length(newfact)>1;
        return
      else
        setappdata(targfig,'declutter',newfact);
        plotds(targfig);
      end
    end
    
  case {'ViewDeclutterSelected'}
    
    if strcmp(get(cbo,'checked'),'on');
      setappdata(targfig,'labelselected',0)
      set (cbo,'checked','off')
    else
      setappdata(targfig,'labelselected',1)
      set (cbo,'checked','on')
    end
    plotds(targfig);
    
  case {'ViewDeclutterDefault'}
    
    setplspref('plotgui','declutter',getappdata(targfig,'declutter'));
    setplspref('plotgui','labelselected',getappdata(targfig,'labelselected'));
    evrimsgbox('The current declutter settings will be used for future plots (not including "duplicated" figures).','Set Declutter Defaults');
    
  case {'ViewDuplicate'}
    
    duplicate(targfig);
    
  case {'ViewSpawn'}
    
    spawn(targfig);
    
  case {'ViewDockControls'}
    if strcmp(get(cbo,'checked'),'on')
      set(cbo,'checked','off')
    else
      set(cbo,'checked','on')
    end
    %check or uncheck command
    dockcontrols(fig);        %update controls
    
  case {'ViewDiag' 'ViewLabels', 'ViewAxisscale', 'ViewNumbers', 'ViewExcludedData', 'ViewClasses', 'ViewInterpolated', 'ViewTable'}
    val = getappdata(targfig,lower(menu));
    setappdata(targfig,lower(menu),~val);
    plotds(targfig);

  case 'ViewClassesNext'

    mydataset = getdataset(targfig);
    plotby = getappdata(targfig,'plotby');
    if plotby == 0;               %if special plot mode, figure out which dim we're actually selecting on
      dim = get(handles.xaxismenu,'value');
      plotby = 2-dim+1;
      if plotby < 1; plotby = 1; end
    end
    plotvs = 2-plotby+1;
    if plotvs<1; plotvs = 1; end

    if isempty(mydataset.class{plotvs})
      frommode = plotby;
    else
      frommode = plotvs;
    end

    nclasses = size(mydataset.class,2);
    if getappdata(targfig,'viewclasses')
      cls = getappdata(targfig,'viewclassset');
    else
      cls = 0;
    end
    startcls = cls;
    cls = cls+1;
    if cls<=nclasses
      %look for non-empty class set
      while isempty(mydataset.class{frommode,cls})
        cls = cls+1;
        if cls==startcls | cls>nclasses
          %back to start or beyond end of classes, stop now
          break
        end
      end
    end
    if cls>nclasses
      cls = 0;
    end
    if cls==startcls | cls==0
      %got back to where we started? turn OFF classes
      setappdata(targfig,'viewclasses',0)
      setappdata(targfig,'viewclassset',1)
      plotds(targfig);
    else
      %choose new class
      setappdata(targfig,'viewclasses',1)
      setappdata(targfig,'viewclassset',cls)
      plotds(targfig);
    end
    classsetnotice(targfig);
    
  case 'ViewLabelAngle'
    angle = getappdata(targfig,'viewlabelangle');
    set(allchild(handles.ViewLabelAngle),'checked','off');
    switch angle
      case {0,45,90,135,180,225,270,315}
        set(getfield(handles,['ViewLabelAngle' num2str(angle)]),'checked','on');
      otherwise
        set(handles.ViewLabelAngleCustom,'checked','on');
    end
    
  case {'ViewLabelAngle0' 'ViewLabelAngle45' 'ViewLabelAngle90' 'ViewLabelAngle135' 'ViewLabelAngle180' 'ViewLabelAngle225' 'ViewLabelAngle270' 'ViewLabelAngle315'}
    angle = str2num(menu(15:end));
    setappdata(targfig,'viewlabelangle',angle);
    plotds(targfig);

  case 'ViewLabelAngleCustom'
    angle = getappdata(targfig,'viewlabelangle');
    %     newangle = inputdlg({['Enter Label Angle in Degrees:']},'Set Label Angle',1,{num2str(angle)});

    anglefig = figure('color',[1 1 1]);
    %make figure smaller
    pos = get(anglefig,'position');
    pos = [pos(1:2)+pos(3:4)*.25 pos(3:4)*.5];
    set(anglefig,'position',pos);  
    %plot circle and current angle
    h = plot(cos([0:360]/180*pi),sin([0:360]/180*pi),'k',[0 cos(angle/180*pi)],[0 sin(angle/180*pi)],'r-');
    set(h(2),'linewidth',3);
    axis square off
    
    set(anglefig,'windowstyle','modal');
    ans = gselect('nearest',h(1),struct('btndown','True','poslabel','none','helpbox','off'));
    newangle = [];
    if ~isempty(ans)
      newangle = find(ans{1});
    end
    delete(anglefig);
    
    if ~isempty(newangle);
%       newangle = abs(str2num([newangle{:}]));
      if isnan(newangle) | length(newangle)>1;
        return
      else
        setappdata(targfig,'viewlabelangle',newangle);
        plotds(targfig);
      end
    end

    
  case 'ViewLabelAngleDefault'
    
    setplspref('plotgui','viewlabelangle',getappdata(targfig,'viewlabelangle'));
    evrimsgbox('The current label angle settings will be used for future plots (not including "duplicated" figures).','Set Label Angle Default');
    
  case 'ViewClassSet'
    viewclasses = getappdata(targfig,'viewclasses');
    classset = get(gcbo,'userdata');
    currentset = getappdata(targfig,'viewclassset');
    if classset == 0 | (viewclasses & classset==currentset);
      setappdata(targfig,'viewclasses',0);
      notice = false;
    else
      setappdata(targfig,'viewclassset',classset);
      setappdata(targfig,'viewclasses',1);
      notice = true;
    end
    plotds(targfig);

    if notice
      classsetnotice(targfig);
    end
    
    if ismac
      %Refresh menus.
      update('figure',targfig)
    end

  case {'ViewConnectClasses' 'ConnectClassMethodNone'}
    setappdata(targfig,'connectclasses',0);
    plotds(targfig);

  case {'ConnectClassMethodOutline' 'ConnectClassMethodPCA' 'ConnectClassMethodConnect'  'ConnectClassMethodSpider' 'ConnectClassMethodMeans' 'ConnectClassMethodSequence'}
    
    setappdata(targfig,'connectclasses',1)
    setappdata(targfig,'connectclassmethod',lower(menu(19:end)));
    plotds(targfig);

  case {'ConnectClassMethodNext'}
    
    methods = connectclasslist(2);
    methods = lower(methods(:,1)');
    methods{end+1} = '';
    if ~getappdata(targfig,'connectclasses');
      %turn it on
      setappdata(targfig,'connectclasses',1)
      setappdata(targfig,'connectclassmethod',methods{1});
      plotds(targfig);
      return
    end
      
    %cycle to next method
    mth = getappdata(targfig,'connectclassmethod');
    ind = find(ismember(methods,lower(mth)))+1;
    if isempty(ind)
      ind = length(methods);
    end

    if ~isempty(methods{ind})
      setappdata(targfig,'connectclasses',1)
      setappdata(targfig,'connectclassmethod',methods{ind});
    else
      setappdata(targfig,'connectclasses',0)
    end
    plotds(targfig);
      
        
  case 'ConnectClassMethodLimit'
    val = num2str(getappdata(targfig,'connectclasslimit')*100);
    newval = nan;
    while isnan(newval);
      newval = inputdlg({['Enter the new outline classes confidence limit:']},'Set Outline Confidence Limit',1,{val});
      if ~isempty(newval);
        newval = str2double([newval{:}]);
        if newval>=1 & newval< 100
          newval = newval/100;
        end
        if isnan(newval) | length(newval)>1 | newval<=0 | newval>=1;
          evrimsgbox('Confidence limit must be a single numerical value between zero and one. To keep current limit, click "Cancel"','Set Limit Error','error','modal');
          newval = nan;
        end
      else
        newval = [newval{:}];
      end
    end
    if isempty(newval); return; end
    setappdata(targfig,'connectclasslimit',newval);
    setappdata(targfig,'connectclasses',1)
    setappdata(targfig,'connectclassmethod','pca')
    plotds(targfig);
    
  case 'ViewAxisscaleSet'
    viewaxisscale = getappdata(targfig,'viewaxisscale');
    axisscaleset = get(gcbo,'userdata');
    currentset = getappdata(targfig,'viewaxisscaleset');
    if viewaxisscale & axisscaleset==currentset;
      setappdata(targfig,'viewaxisscale',0);
    else
      setappdata(targfig,'viewaxisscaleset',axisscaleset);
      setappdata(targfig,'viewaxisscale',1);
    end
    plotds(targfig);
    
  case 'ViewLabelSet'
    viewlabels = getappdata(targfig,'viewlabels');
    labelset = get(gcbo,'userdata');
    currentset = getappdata(targfig,'viewlabelset');
    if viewlabels & labelset==currentset;
      setappdata(targfig,'viewlabels',0);
    else
      setappdata(targfig,'viewlabelset',labelset);
      setappdata(targfig,'viewlabels',1);
    end
    plotds(targfig);
      
    if ismac
      %Refresh menus.
      update('figure',targfig)
    end
    
    %================================================================
  case {'selectionmenu'}
    if getappdata(targfig,'noselect');
      set([findobj(cbo,'tag','EditExcludeSelection') findobj(cbo,'tag','EditIncludeSelection') ...
          findobj(cbo,'tag','EditExcludeUnselected') findobj(cbo,'tag','EditSelectionMode') ...
          findobj(cbo,'tag','EditSelectAll') ...
          findobj(cbo,'tag','EditDeselectAll') ...
          findobj(cbo,'tag','EditSelectClass') ...
          findobj(cbo,'tag','EditGetStats') ...
          findobj(cbo,'tag','EditGetInfo')],'enable','off');
      set(findobj(cbo,'tag','EditSetClass'),'enable','off');     
      
    else
      set([findobj(cbo,'tag','EditSelectionMode') findobj(cbo,'tag','EditSelectAll')],'enable','on');
      selection = getselection(targfig);
      if isempty(selection); selection = {[]}; end
      for k = 1:length(selection); sz(k) = length(selection{k}); end
      
      if isempty(selection) | all(sz==0);
        set([findobj(cbo,'tag','EditExcludeSelection') findobj(cbo,'tag','EditExcludeUnselected') findobj(cbo,'tag','EditIncludeSelection') findobj(cbo,'tag','EditDeselectAll') findobj(cbo,'tag','EditGetInfo') findobj(cbo,'tag','EditGetStats')],'enable','off');
        set([findobj(cbo,'tag','EditSetClass') findobj(cbo,'tag','EditSetAxisScale')],'enable','off');     
      else
        set(findobj(cbo,'tag','EditDeselectAll'),'enable','on');
        if sum(sz>1)>1;   %selections in more than one dim
          set([findobj(cbo,'tag','EditExcludeSelection') findobj(cbo,'tag','EditExcludeUnselected') findobj(cbo,'tag','EditIncludeSelection') ...
              findobj(cbo,'tag','EditSelectAll')],'enable','off');
        else        
          set([findobj(cbo,'tag','EditExcludeSelection') findobj(cbo,'tag','EditExcludeUnselected') findobj(cbo,'tag','EditIncludeSelection') ...
              findobj(cbo,'tag','EditDeselectAll')],'enable','on');
        end
        
        %can we get info? (we can have only one selection OR two singles in two dims)
        if sum(sz==1)==2 | sum(sz>0)==1  %revised to allow any # on ONE dim or one on TWO dims  ~any(sz>1);    %Two with only one selection?
          set([findobj(cbo,'tag','EditGetInfo') findobj(cbo,'tag','EditGetStats')],'enable','on');
        else
          set([findobj(cbo,'tag','EditGetInfo') findobj(cbo,'tag','EditGetStats')],'enable','off');
        end
        
        %can we set classes?
        if sum(sz>0)==1 & ~strictedit;
          set(findobj(cbo,'tag','EditSetClass'),'enable','on');
        else
          set(findobj(cbo,'tag','EditSetClass'),'enable','off');
        end
        
      end
      if getappdata(targfig,'plotby')>2;
        set(findobj(cbo,'tag','EditSelectAll'),'enable','off');
      end  
      if getappdata(targfig,'viewclasses')
        set(findobj(cbo,'tag','EditSelectClass'),'enable','on','visible','on');
      end

    end
    
    if getappdata(targfig,'noinclude');
      set([findobj(cbo,'tag','EditExcludeSelection') findobj(cbo,'tag','EditExcludeUnselected') findobj(cbo,'tag','EditIncludeSelection')],'enable','off');
    end
   
    %Add histcontrast button enable code here.
    if evriio('mia') & ~isempty(getappdata(targfig,'asimage'));
      %enable histcontrast selection.
      set(findobj(cbo,'tag','EditHistSelection'),'visible','on','enable','on');       
      set(findobj(cbo,'tag','EditLockCLim'),'visible','on','enable','on');
      set(findobj(cbo,'tag','EditColorMap'),'enable','on','visible','on');
      
      if checkmlversion('<','8.4') | ~exist('parula','file')
        set(findobj(cbo,'tag','EditColorMapParula'),'visible','off');
        set(findobj(cbo,'tag','EditColorMapJet'),'label','Jet (Default)')
      end
      
    else
      %disable histcontrqast selection.
      set(findobj(cbo,'tag','EditHistSelection'),'visible','off','enable','off');      
      set(findobj(cbo,'tag','EditLockCLim'),'visible','off','enable','off');      
      set(findobj(cbo,'tag','EditColorMap'),'enable','off','visible','off');
      
      %but enable standard histogram option
      set(findobj(cbo,'tag','EditHistogram'),'enable','on','visible','on');
      
    end
    if getappdata(targfig,'viewclasses')
      set(findobj(cbo,'tag','EditClassStats'),'enable','on','visible','on');
    else
      set(findobj(cbo,'tag','EditClassStats'),'enable','off','visible','on');
    end

    %================================================================
  case {'Edit'}
    
    set([handles.EditDeselectClass],'visible','off');   %DISABLED!!
    
    if (targfig == fig & isempty(getappdata(targfig,'children')) & isloaded(targfig));    
      %No childfigs and no data? No anything in edit!
      set([handles.EditExcludeSelection handles.EditExcludeUnselected handles.EditIncludeAll handles.EditIncludeSelection handles.EditSelectionMode ...
        handles.EditSelectAll handles.EditSelectExcluded handles.EditDeselectAll handles.EditGetInfo handles.EditGetStats],'enable','off');
      set([handles.EditExcludePlotted handles.EditIncludePlotted handles.EditExcludeNotPlotted handles.EditSearchBar],'enable','off');
      set([handles.EditPlotClass handles.EditSelectClass handles.EditSelectNextClass handles.EditSelectPreviousClass handles.EditDeselectClass handles.EditSetClass handles.EditSetAxisScale],'enable','off');
      set([handles.EditExcludeSelection handles.EditExcludeUnselected handles.EditIncludeSelection handles.EditIncludeAll],'enable','off');
      set([handles.EditCopyData handles.EditCopyFigure handles.EditMakeSelectionMissing],'enable','off');
      return
    end

    set([handles.EditCopyData handles.EditCopyFigure handles.EditIncludeAll handles.EditSearchBar],'enable','on');

    if getappdata(targfig,'noinclude');
      set([handles.EditIncludeAll handles.EditExcludePlotted handles.EditIncludePlotted handles.EditExcludeNotPlotted],'enable','off');
    else
      set([handles.EditIncludeAll handles.EditExcludePlotted handles.EditIncludePlotted handles.EditExcludeNotPlotted],'enable','on');
    end
    
     mydataset = getdataset(targfig);
    if getappdata(targfig,'noselect');
      set([handles.EditExcludeSelection handles.EditExcludeUnselected handles.EditIncludeSelection handles.EditIncludeAll handles.EditSelectionMode ...
          handles.EditSelectAll handles.EditSelectExcluded handles.EditDeselectAll handles.EditGetInfo handles.EditGetStats],'enable','off');
      set([handles.EditSetClass handles.EditSetAxisScale],'enable','off');
      set([handles.EditSelectClass handles.EditSelectNextClass handles.EditSelectPreviousClass handles.EditDeselectClass handles.EditMakeSelectionMissing],'enable','off');
    else
      set([handles.EditSelectionMode handles.EditSelectAll handles.EditSelectExcluded],'enable','on');
      selection = getselection(targfig);
      if isempty(selection); selection = {[]}; end
      for k = 1:length(selection); sz(k) = length(selection{k}); end
      
      if isempty(selection) | all(sz==0);
        set([handles.EditExcludeSelection handles.EditMakeSelectionMissing handles.EditExcludeUnselected handles.EditIncludeSelection handles.EditDeselectAll handles.EditGetInfo handles.EditGetStats],'enable','off');
        set([handles.EditSetClass handles.EditSetAxisScale],'enable','off');
      else
        set(handles.EditDeselectAll,'enable','on');
        if sum(sz>1)>1;   %selections in more than one dim
          set([handles.EditExcludeSelection handles.EditExcludeUnselected handles.EditIncludeSelection handles.EditSelectAll],'enable','off');
        else        
          set([handles.EditExcludeSelection handles.EditExcludeUnselected handles.EditIncludeSelection handles.EditDeselectAll],'enable','on');
        end
        
        %can we get info? (we can have only one selection OR two singles in two dims)
        %if sum(sz==1)==2 | ~any(sz>1);    %Two with only one selection?
        if sum(sz==1)==2 | sum(sz>0)==1  %revised to allow any # on ONE dim or one on TWO dims  ~any(sz>1);    %Two with only one selection?
          set([handles.EditGetInfo handles.EditGetStats],'enable','on');
        else
          set([handles.EditGetInfo handles.EditGetStats],'enable','off');
        end
        
        %can we set classes?
        if sum(sz>0)==1 & ~strictedit;
          set([handles.EditSetClass handles.EditSetAxisScale],'enable','on');
        else
          set([handles.EditSetClass handles.EditSetAxisScale],'enable','off');
        end
        
        plotby = getappdata(targfig,'plotby');
        if plotby>0 & ~strictedit
          set(handles.EditMakeSelectionMissing,'enable','on');
        else
          set(handles.EditMakeSelectionMissing,'enable','off');
        end
      end
      
      %can we select/deselect by class?
      plotby = getappdata(targfig,'plotby');
      if plotby == 0;               %if special plot mode, figure out which dim we're actually selecting on
        dim = get(handles.xaxismenu,'value');
        plotby = 2-dim+1;
        if plotby < 1; plotby = 1; end
      end
      plotvs = 2-plotby+1; 
      if plotvs<1; plotvs = 1; end
      if isempty(mydataset) | ~isa(mydataset,'dataset') | isempty(mydataset.class{plotvs}) | ndims(mydataset)>2;
        set([handles.EditSelectClass handles.EditSelectNextClass handles.EditSelectPreviousClass handles.EditDeselectClass],'enable','off');
      else
        set([handles.EditSelectClass handles.EditSelectNextClass handles.EditSelectPreviousClass handles.EditDeselectClass],'enable','on');
        if isempty(selection) | all(sz==0);
          set(handles.EditDeselectClass,'enable','off');
        end
      end
      if isempty(mydataset) | ~isa(mydataset,'dataset') | isempty(mydataset.class{plotby})
        en = 'off';
      else
        en = 'on';
      end
      set([handles.EditPlotClass],'enable',en);
      
      %Don't allow select all if > 2 dims
      if getappdata(targfig,'plotby') >2;
        set(handles.EditSelectAll,'enable','off');
      end  
    end
    
    %determine if we can Select Classes in current plotby mode
    set(handles.EditPlotClass,'enable','off','visible','on')
    opts = getappdata(targfig);
    if opts.plotby>0
      plotby = opts.plotby;
      if ~isfield(opts,'viewclassset')
        opts.viewclassset = 1;
      end
      if size(mydataset.class,2)>= opts.viewclassset
        %as long as there is a possiblilty of having a class set here
        cls  = mydataset.class{plotby,opts.viewclassset};
        if ~isempty(cls)
          %see if it is populated and enable menu
          set(handles.EditPlotClass,'enable','on')
        end
      end
    end
    
    if getappdata(targfig,'noinclude');
      set([handles.EditExcludeSelection handles.EditExcludeUnselected handles.EditIncludeSelection handles.EditMakeSelectionMissing],'enable','off');
    end

        %================================================================
  case {'EditColorMap'}
    
  case {'EditColorMapCool' 'EditColorMapGray' 'EditColorMapHot' 'EditColorMapHsv' ...
      'EditColorMapJet' 'EditColorMapParula' 'EditColorMapRkb' 'EditColorMapRwb'}
    
    m = menu(13:end);
    switch lower(m);
      case 'rkb'
        rkb;  %automatically handles applying to colorbar
      otherwise
        %otherwise, get map and apply with colormap
        cm = eval(lower(m));
        colormap(cm);
    end
    
    %================================================================

  case 'EditNewFromData'

    [dat, tags] = tabledata(targfig);
    tags = str2cell(tags);
    if length(dat)>1
      axisscale = dat{1};
      axisscalename = tags{1};
      dat = dat(2:end);
      tags = tags(2:end);
    else
      axisscale = [];
      axisscalename = '';
    end
    data = dataset(cat(1,dat{:}));
    data.label{1} = tags;
    if ~isempty(axisscale)
      data.axisscale{2} = axisscale;
      data.axisscalename{2} = axisscalename;
    end
    addcmd = {};
    if getappdata(targfig,'asimage') & length(dat)==1 & size(dat{1},1)>1
      addcmd = [addcmd 'image' 'axismenuvalues' {{[0] [1:size(data,3)] []}}];
    else
      addcmd{end+1} = 'rows';
    end
    plotgui('new',data,addcmd{:})
    return
    
  case 'EditCopyData'
    %Export data to clipboard using disptable.
    [dat, tags] = tabledata(targfig);
    line = createtable(dat, tags);
    
    %convert to cell if it isn't already
    if ~isa(line,'cell'); 
      line = mat2cell(line,ones(size(line,1),1),size(line,2));
    end;   
    
    tocopy = sprintf(['%s' 10],line{:});
    clipboard('copy',tocopy);
    
  case 'EditCopyFigure'
    exportfigure('clipboard',targfig);    
    
  case {'EditIncludeAll' 'EditExcludeSelection', 'EditIncludeSelection', 'EditExcludeUnselected'}
    
    plotby = getappdata(targfig,'plotby');
    if plotby == 0;               %if special plot mode, figure out which dim we're actually selecting on
      plotby = get(handles.xaxismenu,'value');
    else
      plotby = 2-plotby+1;
    end
    if plotby < 1; plotby = 1; end

    [mydataset,myid] = getdataset(targfig);
    if strcmp(menu,'EditIncludeAll');
      ans = evriquestdlg('This will re-include ALL excluded data in the currently displayed mode. Are you certain you wan to do this?','Confirm Include All','Include All','Cancel','Include All');
      if ~strcmp(ans,'Include All');
        return;
      end
      selection = {};
      for k=1:ndims(mydataset);
        selection{k} = 1:size(mydataset,k);
      end
    else
      selection = getselection(targfig);
    end
    
    if iscell(selection);
      if ~isempty(mydataset) & isa(mydataset,'dataset');
        if length(selection) > ndims(mydataset);
          if strcmp(menu,'EditIncludeSelection');
            evrimsgbox({'Selection does not match DataSet size.','No Data Included.'},'Include Selection Error','Error','modal')
          else
            evrimsgbox({'Selection does not match DataSet size.','No Data Excluded.'},'Exclude Selection Error','Error','modal')
          end
          return
        end
        
        %update the includ information
        selectcell = cell(1,ndims(mydataset));
        if ~ismember(menu,{'EditExcludeUnselected' 'EditIncludeAll'});
          for k = 1:length(selection);
            switch menu
              case 'EditIncludeSelection'
                mydataset.includ{k} = union(mydataset.includ{k},selection{k}(:));
              case 'EditExcludeSelection'
                mydataset.includ{k} = setdiff(mydataset.includ{k},selection{k}(:));
                if ~getappdata(targfig,'viewexcludeddata'); evritip('plotgui_exclude'); end
            end
          end
        else        %'EditExcludeUnselected'
          mydataset.includ{plotby} = selection{plotby}(:);
        end
        
        %update selection as appropriate
        if fig~=targfig & strcmp(get(handles.ViewDockControls,'checked'),'on');
          dockcontrolsstatus = 'on';
          set(handles.ViewDockControls,'checked','off'); 
        else
          dockcontrolsstatus = 'off';
        end

        %store the data
        setobjdata(targfig,mydataset,'include');
        
        %deselect everything
        if isvalid(myid);
          myid.properties.selection = cell(1,ndims(mydataset));
        end
        
        set(handles.ViewDockControls,'checked',dockcontrolsstatus);    %reset dock controls status
                
      end
    end      
    
    figure(targfig);   %reactivate original target
    
  case {'EditSelectClass' 'LineSelectClass'}
    opts = getappdata(targfig);

    if opts.plotby==0
      ind = GetMenuIndex(targfig);
      plotvs = ind{1}+1;
    else
     plotvs = 3-opts.plotby;
    end
    
    if ~isfield(opts,'viewclassset')
      opts.viewclassset = 1;
    end
    data = getdataset(targfig);
    cls  = data.class{plotvs,opts.viewclassset};
    classlookup = data.classlookup{plotvs,opts.viewclassset};
    if isempty(cls) | isempty(classlookup)
      return;
    end
    validclasses = classlookup(:,2);

    select = cell(1,ndims(data));    
    if ~isempty(gcho)
      class_number = getappdata(gcho,'classset');
    else
      class_number = [];
    end
    if isempty(class_number)
      if strcmpi(menu,'LineSelectClass'); return; end %line select MUST have class_number value
      [class_number,ok] = listdlg('ListString',validclasses,...
        'SelectionMode','multiple','InitialValue',[],...
        'PromptString',{'Choose one or more classes' 'to select:  '},...
        'Name','Select Class');
      if ~ok; return; end
      class_number = cat(2,classlookup{class_number,1});
    end
    select{plotvs} = find(ismember(cls,class_number));
    if ~getappdata(targfig,'viewexcludeddata');
      %not showing excluded data?
      select{plotvs} = intersect(select{plotvs},data.include{plotvs});
    end
    setselection(select,'normal',targfig);
    
  case 'EditSelectNextClass'
    cycleselectybyclass(targfig,'f')
  case 'EditSelectPreviousClass'
    cycleselectybyclass(targfig,'r')
  case {'EditGetInfo'}
    getselectioninfo(targfig,handles)
  case {'EditGetStats'}
    getselectionstats(targfig,handles)
  case {'EditSelectAll', 'EditDeselectAll', 'EditSelectExcluded'}
    
    mydataset = getdataset(targfig);
    
    plotby = getappdata(targfig,'plotby');
    
    if ~isempty(mydataset) & isa(mydataset,'dataset') | isempty(mydataset.data);     
      
      if plotby == 0;               %if special plot mode, figure out which dim we're actually selecting on
        dim = get(handles.xaxismenu,'value');
        plotby = 2-dim+1;
        if plotby < 1; plotby = 1; end
      end
      
      selectcell = cell(1,ndims(mydataset));     %create the m element cell of selected points
      
      if strcmp(menu, 'EditSelectAll');   %select all
        
        selection = gselect('all',findobj(allchild(get(targfig,'currentaxes')),'userdata','data'));       %select only from displayed data
        selectcell = insertselection(selection,targfig);
        setselection(selectcell,'set',targfig);
        
      elseif strcmp(menu, 'EditSelectExcluded');   %select excluded data

        currentselection = getselection(targfig);
        if ~isempty(currentselection) & iscell(currentselection)
          selectcell = currentselection;
        end
        someselected = false;
        for mode = setdiff(1:ndims(mydataset),plotby)
          excl = setdiff(1:size(mydataset,mode),mydataset.include{mode});
          if ~isempty(excl); someselected = true; end
          selectcell{mode} = union(selectcell{mode},excl);
        end
        if someselected;
          setselection(selectcell,'set',targfig);
          if ~getappdata(targfig,'viewexcludeddata')
            evritip('selexclnoview','Excluded data has been selected, but View/Excluded Data is not currently "on" so you may not be able to see the selected points. If you want to view the selection, Choose "View/Excluded Data" from the Plot Controls menus.',1);
          end
        else
          evrimsgbox('There is no excluded data to select. Current selection remains unmodified.','Nothing excluded','warn','modal');
        end        
      else
        setselection(selectcell,'set',targfig);   %deselect all - set to empty set
      end
      
    end      
    
  case {'EditSelectionMode'}
    
    selectionmode = getappdata(targfig,'selectionmode');    %get current mode
    selectionmode = lower(selectionmode);
    selectionmode(1) = upper(selectionmode(1));         %w/capitol first char
    
    set(get(cbo,'children'),'checked','off');             %turn off checks
    set(findobj(cbo,'tag',['SelectionMode' selectionmode]),'checked','on');    %except selected mode
    set(handles.SelectionModeLasso,'visible','on');
    
  case {'SelectionModePaint', 'SelectionModeLasso', 'SelectionModeRbbox', 'SelectionModePolygon', 'SelectionModeX', 'SelectionModeY', 'SelectionModeXs', 'SelectionModeYs', ...
        'SelectionModeNearest' 'SelectionModeNearests' 'SelectionModeCircle' 'SelectionModeEllipse'}
    
    setappdata(targfig,'selectionmode',lower(menu(14:end))); %grab end of string as selectionmode property
    
    
  case {'EditMakeSelectionMissing'}

    if strictedit; return; end
    
    mydataset = getdataset(targfig);
    selection = getselection(targfig);
    plotby = getappdata(targfig,'plotby');

    if plotby == 0;
      return
    end

    ans = evriquestdlg('This will permanently remove the selected data from this DataSet. Are you certain you want to do this?','WARNING: Make Missing Data','Yes','Cancel','Yes');
    if ~strcmp(ans,'Yes');
      return
    end

    plotvs = 2-plotby+1;
    if plotvs<1; plotvs = 1; end

    [ind1,ind2,ind3] = GetMenuIndex(targfig);
    mydataset.data = nassign(mydataset.data,nan,{selection{plotvs} ind2},[plotvs plotby]);
    
    if fig~=targfig & strcmp(get(handles.ViewDockControls,'checked'),'on');
      dockcontrolsstatus = 'on';
      set(handles.ViewDockControls,'checked','off'); 
    else
      dockcontrolsstatus = 'off';
    end
            
    %store the data
    setobjdata(targfig,mydataset);

    %clear selection
    updatepropshareddata(getlink(targfig),'update',struct('selection',{cell(1,ndims(mydataset))}),'selection')

    set(handles.ViewDockControls,'checked',dockcontrolsstatus);    %reset dock controls status
    
    figure(targfig);   %reactivate original target

  case {'ViewChangeSymbolsSelect'}

    sym = get(gcbo,'userdata');
    if ischar(sym)
      sym = classmarkers(sym);
      if ~isempty(sym)
        %save if they didn't cancel
        plotgui('update','figure',targfig,'classcolormode','','symbolset',sym);
      end
    end

  case {'LineChangeSymbol'}
    
  case {'LineChangeLineColors'}
    
    %allow user to change class colors
    %Colors are saved in setplspref 'classcolors' then override is done in
    %plotgui_platscatter around line 1695
    classcolors(-1);
    plotgui('update','figure',targfig);
    
  case {'ViewChangeSymbols' 'ViewChangeSymbolsCustom'}

    %get index from selected object (if any)
    if ~isempty(gcho);
      index = getappdata(gcho,'autosymbol');
    else
      index = 1;
    end
    if isempty(index)
      index = 1;
    end      
    %allow user to modify symbol set (with current symbol selected)
    sym = getappdata(targfig,'symbolset');
    if isempty(sym) & ~isempty(gcho)
      %nothing specified by user?
      sym = getappdata(gcho,'symbolset'); %see what was used within plotclasses
    end
    if ischar(sym)
      %set name given? get set from classmarkers
      sym = classmarkers(sym);
    end
    %edit set
    sym = symbolstyle(index,sym);
    if ~isempty(sym)
      %save if they didn't cancel
      plotgui('update','figure',targfig,'classcolormode','','symbolset',sym);
    end

  case {'LineSymbolSize'}
    set(allchild(gcbo),'checked','off');
    if ~isempty(gcho) & isprop(gcho,'markersize')
      
      msize = getappdata(targfig,'symbolsize');
      if ~isempty(msize)
        ch = findobj(gcbo,'tag',sprintf('LineSymbolSize%02i',msize));
      else
        ch = findobj(gcbo,'tag','LineSymbolSizeAuto');
      end
      if ~isempty(ch)
        set(ch,'checked','on');
      end
    end
    
  case {'LineSymbolSize02' 'LineSymbolSize04' 'LineSymbolSize05' 'LineSymbolSize06' 'LineSymbolSize07' 'LineSymbolSize08'...
      'LineSymbolSize10' 'LineSymbolSize12' 'LineSymbolSize18' 'LineSymbolSize24' 'LineSymbolSize48' 'LineSymbolSizeAuto'}
    
    if strcmpi(menu,'LineSymbolSizeAuto')
      msize = get(0,'defaultlinemarkersize');
      css = [];
    else
      msize = str2num(menu(end-1:end));
      css = msize;
    end
    if ~isempty(gcho) & isprop(gcho,'markersize');
      set(gcho,'markersize',msize)
    end
    update('figure',targfig,'classsymbolsize',css,'symbolsize',css);

    
  case {'LineLineWidth'}
    set(allchild(gcbo),'checked','off');
    
    if isempty(getappdata(targfig,'linewidth'))
      hauto = findobj(gcbo,'tag','LineLineWidthAuto');
      set(hauto,'checked','on');
    else
      if ~isempty(gcho) & isprop(gcho,'linewidth')
        width = get(gcho,'linewidth');
        ch = findobj(gcbo,'tag',sprintf('LineLineWidth%03i',width*10));
        if ~isempty(ch)
          set(ch,'checked','on');
        end
      end
    end
  case {'LineLineWidthAuto' 'LineLineWidth005' 'LineLineWidth010' 'LineLineWidth020' 'LineLineWidth030' ...
      'LineLineWidth040' 'LineLineWidth050' 'LineLineWidth060' 'LineLineWidth070' ...
      'LineLineWidth080' 'LineLineWidth090' 'LineLineWidth100' 'LineLineWidth110' 'LineLineWidth120'}
    
    if strcmpi(menu,'LineLineWidthAuto')
      width = get(0,'defaultlinelinewidth');
      setwidth = [];
    else
      width = str2num(menu(end-2:end))/10;
      setwidth = width;
    end
    if ~isempty(gcho) & isprop(gcho,'linewidth');
      set(gcho,'linewidth',width)
    end
    update('figure',targfig,'linewidth',setwidth);

    
  case {'EditSetClass' 'LineSetClass'}
    
    if strictedit; return; end
    
    default = [];
    viewclassset = getappdata(targfig,'viewclassset');
    if isempty(viewclassset)
      viewclassset = 1;
    end
    mydataset = getdataset(targfig);
    
    switch menu
      case 'EditSetClass'
        plotby = getappdata(targfig,'plotby');
        if plotby==0
          [plotvs,ind2,ind3] = GetMenuIndex(fig);
          plotvs = plotvs+1;  %add one for indexing on X menu
        else
          plotvs = 2-plotby+1;
        end
        if plotvs<1; plotvs = 1; end
        mode = plotvs;

        selection_all = getselection(targfig);
        selection{mode} = selection_all{mode};
        z = mydataset.class{mode,viewclassset};         %Grab old classes
        if ~isempty(z)
          default = unique(z(selection{mode}));
          if length(default)>1;
            default = [];
          end
        end
        item = 'selection';
      case 'LineSetClass'
        obj = gcho; %get current object (hidden included)
        if isempty(obj); return; end
        selection = cell(1,ndims(mydataset));
        mode = getappdata(obj,'mode');
        ind  = getappdata(obj,'index');
        selection{mode} = ind;
        z = mydataset.class{mode,viewclassset};         %Grab old classes
        if ~isempty(z)
          default = z(ind);
        end
        item = 'selected line';
    end
      
    classlookup = mydataset.classlookup{mode,viewclassset};
    createNewClassSet = 0;
    if ~isempty(classlookup)
      %have user select existing class (or say they want a new one)
      %       validclasses = [classlookup(:,2); {'New Class...'}];
      if checkmlversion('>=','7');
        prefix = '<html><b><em>';
        postfix = '</em></b></html>';
      else
        prefix = '';
        postfix = '';
      end
      
      validclasses = classlookup(:,2);
      mylist_setClass = [classlookup(:,2); {'New Class...'}; {[prefix 'New Class Set...' postfix]}];
      if ~isempty(default);
        default = find(cat(2,classlookup{:,1})==default);
      end
      [index,ok] = listdlg('ListString',mylist_setClass,...
        'SelectionMode','single','InitialValue',default,...
        'PromptString',{'Choose new class assignment:'},...
        'Name','Select Class');
      if ~ok
        return;
      end
    else
      %no classes, it must be new
      index = 1;
      validclasses = {};
      mylist_setClass = {};
      newclass = inputdlg({['Enter the new string class for the ' item ':']},'Set Class',1,{''});
    end
    if index<=length(validclasses)
      %pre-defined class
      newclass = classlookup{index,2};
    else
      if ~isempty(mylist_setClass)
        if ~isempty(strfind(mylist_setClass{index}, 'Set...'))
          createNewClassSet = 1;
          prompt = {'Enter new class set name:','Enter new class name of selected:'};
          dlgtitle = 'Set Class Info';
          dims = [1 35];
          definput = {'New Class Set Name','New Class Name'};
          responses = inputdlg(prompt,dlgtitle,dims,definput);
          if isempty(responses)
            return
          end
          newclassSetName = responses{1};
          newclass = responses{2};
          mydataset.classname{mode,end+1} = newclassSetName;          
        else
          newclass = inputdlg({['Enter the new string class for the ' item ':']},'Set Class',1,{''});
        end
      end
%       newclass = inputdlg({['Enter the new string class for the ' item ':']},'Set Class',1,{''});
      if isempty(newclass);
        return;
      elseif ~createNewClassSet
        %extract entry
        newclass = [newclass{:}];
      end   
    end
    if isempty(newclass); return; end

    %make sure classes exist
    z = mydataset.class{mode,viewclassset};         %Grab old classes
    if isempty(z);
      mydataset.class{mode,viewclassset} = zeros(1,size(mydataset,mode));      %set to all zeros if was empty
    end
    %TODO: This is probably slow with large datasets, maybe use numbers.
    
    %now, assign samples using classid (strings)
    classid = mydataset.classid{mode,viewclassset};
    for ind = selection{mode}(:)';
      classid{ind} = newclass;     %insert new classes (based on selection)
    end
    if createNewClassSet
      mydataset.classid{mode,end} = classid;
    else
      mydataset.classid{mode,viewclassset} = classid;
    end

    %update figures as necessary
    if fig~=targfig & strcmp(get(handles.ViewDockControls,'checked'),'on');
      dockcontrolsstatus = 'on';
      set(handles.ViewDockControls,'checked','off'); 
    else
      dockcontrolsstatus = 'off';
    end
    
    switch menu
      case 'EditSetClass'
        setselection(cell(1,ndims(mydataset)),'set',targfig,'noplot')   %clear selection
    end
    
    setappdata(targfig,'viewclasses',1);
    setappdata(targfig,'viewclassset',viewclassset);
    set(handles.ViewClasses,'checked','on');
    
    
    %store the data
    if createNewClassSet
      setobjdata(targfig,mydataset, 'class_create');
    else
      setobjdata(targfig,mydataset, 'class');
    end
    
    set(handles.ViewDockControls,'checked',dockcontrolsstatus);    %reset dock controls status
    selectcell = cell(1,ndims(mydataset));
    setselection(selectcell,'set',targfig);
    figure(targfig);   %reactivate original target
    
  case {'EditSetAxisScale' 'EditSetAxis'}
    
    mydataset = getdataset(targfig);
    plotby = getappdata(targfig,'plotby');
    if plotby==0
      [plotvs,ind2,ind3] = GetMenuIndex(fig);
      plotvs = plotvs+1;  %add one for indexing on X menu
    else
      %[plotvs_t,ind2,ind3] = GetMenuIndex(fig);
      plotvs = 2-plotby+1;
    end
    if plotvs<1; plotvs = 1; end
    mode = plotvs;
    
    
    testForEmptyAxis = cellfun(@isempty, mydataset.axisscale(mode,:));
    %findEmptySets = find(testForEmptyAxis);

    if all(testForEmptyAxis)
      createNewAxisSet = 1;
      selAxisScaleSet = [];
    else
      createNewAxisSet = 0;
      naxisscaleSets = size(mydataset.axisscale(mode,:),2);
      axisscaleSetsNames = mydataset.axisscalename(mode,:);
      for j=1:naxisscaleSets;
        if ~testForEmptyAxis(j)
          if isempty(axisscaleSetsNames{j});
            str{j} = ['Axis Scale Set ' num2str(j)];
          else
            str{j} = [axisscaleSetsNames{1,j} ' (' num2str(j) ')'];
          end
        else
          str{j} = 'Empty';
        end
      end
      if checkmlversion('>=','7');
        prefix = '<html><b><em>';
        postfix = '</em></b></html>';
      else
        prefix = '';
        postfix = '';
      end
      strToUse = [str'; {[prefix 'New Axis Scale Set...' postfix]}];
      
      [selAxisScaleSet,ok] = listdlg('ListString',strToUse,'SelectionMode','single','InitialValue',[],'PromptString','Create or Modify Current Axis Scale Set','Name','Axis Scale Set');
      if ~ok
        return;
      end
      
      if selAxisScaleSet > naxisscaleSets %create new axis set
        createNewAxisSet = 1;
      end
    end
    
    selection_all = getselection(targfig);
    selection{mode} = selection_all{mode};
    if  createNewAxisSet
      %questdlg(['Text on line 1' sprintf('\n') 'Text on line 2'])
      prompt = {['ATTENTION:' sprintf('\n') 'This action will clear your model!' sprintf('\n\n') 'Enter Name for New Axis Scale Set:'],'Enter Axis Scale Value of Selected:'};
      dlgtitle = 'Set Axis Scale';
      dims = [1 40];
      definput = {'New Axis Scale Set','0'};
      response = inputdlg(prompt,dlgtitle,dims,definput);
      if isempty(response)
        return
      else
        newAxisScaleName = response{1};
        newAxisValue = str2double(response{2});
      end
    else
      prompt = ['ATTENTION:' sprintf('\n') 'This action will clear your model!' sprintf('\n\n') 'Enter Axis Scale Value of Selected:'];
      dlgtitle = 'Set Axis Scale';
      dims = [1 40];
      definput = {'0'};
      response = inputdlg(prompt,dlgtitle,dims,definput);
      if isempty(response)
        return
      else
        newAxisValue = str2double(response{1});
      end
    end
    if isnan(newAxisValue)
      evriwarndlg('Invalid Axis Value: Please enter a number to use as axis value','WARNING');
    end
    if createNewAxisSet
      newAxis = nan(size(mydataset,mode),1);
     else
       newAxis = mydataset.axisscale{mode,selAxisScaleSet};
    end
    for ind = selection{mode}(:)';
      newAxis(ind) = newAxisValue;
    end
    if createNewAxisSet
      if all(testForEmptyAxis)
        selAxisScaleSet = 1;
        mydataset.axisscale{mode,1} = newAxis;
        mydataset.axisscalename{mode,1} = newAxisScaleName;
      else
        mydataset.axisscale{mode,end+1} = newAxis;
        mydataset.axisscalename{mode,end} = newAxisScaleName;
      end
    else
      mydataset.axisscale{mode,selAxisScaleSet} = newAxis;
    end
    setappdata(targfig, 'editAxis_mode',mode);
    setappdata(targfig, 'editAxis_set',selAxisScaleSet);
    
    %store the data
    if createNewAxisSet
      setobjdata(targfig,mydataset,'axisset_create');
    else
      setobjdata(targfig,mydataset,'axisset_modify');
    end
      
    
    
    %update figures as necessary
    if fig~=targfig & strcmp(get(handles.ViewDockControls,'checked'),'on');
      dockcontrolsstatus = 'on';
      set(handles.ViewDockControls,'checked','off');
    else
      dockcontrolsstatus = 'off';
    end
    
    setselection(cell(1,ndims(mydataset)),'set',targfig,'noplot')   %clear selection
    
    set(handles.ViewDockControls,'checked',dockcontrolsstatus);    %reset dock controls status
    selectcell = cell(1,ndims(mydataset));
    setselection(selectcell,'set',targfig);
    figure(targfig);   %reactivate original target
    
    
    
    
  case {'LineClassStats' 'EditClassStats'}
    %show table of class information for the currently shown class set
    
    if ~getappdata(targfig,'viewclasses')
      return;
    end
    
    viewclassset = getappdata(targfig,'viewclassset');
    if isempty(viewclassset)
      viewclassset = 1;
    end
    %get dataset and class info
    [mydataset,myid] = getdataset(targfig);
    plotby = getappdata(targfig,'plotby');
    if plotby==0
      inds = getappdata(targfig,'axismenuindex');
      dim = inds{1}+1;
      plotby = 2-dim+1;
      if plotby < 1; plotby = 1; end
    end
    plotvs = 3-plotby;
    sel = myid.properties.selection{plotvs};    
    cl  = mydataset.class{plotvs,viewclassset};
    if isempty(cl)
      %no classes? check other mode
      cl = mydataset.class{plotby,viewclassset};
      if isempty(cl)
        return;
      end
      %using classes from other mode, make sure we use right lookup table
      plotvs = plotby;
      sel    = [];
    end
    lu = mydataset.classlookup{plotvs,viewclassset};
    
    if ~getappdata(targfig,'viewexcludeddata')
      %if show exclued is NOT on, exclude all excluded items so they aren't
      %counted
      incl = mydataset.include{plotvs};
      if ~isempty(sel)
        sel = intersect(sel,incl);
      end
    else
      incl = 1:length(cl);
    end

    %count items and prepare strings we'll use for box
    [hy,hx] = hist(cl(incl),[lu{:,1}]);
    hyp = normaliz(hy,0,1)*100;
    len = 8;
    for j=1:size(lu,1);
      len = max(len,length(lu{j,2}));
    end
    len = num2str(len);

    txt = {'Class Population Statistics'};
    if ~isempty(sel); txt{end} = [txt{end} ' (All Samples)']; end
    txt{end+1} = sprintf(  ['  % ' len 's    % 8s     % 5s'],'Class Name','Count','Percent (All Samples)');
    for j=1:size(lu,1);
      txt{end+1} = sprintf(['  % ' len 's    % 8i     % 6.1f%%'],lu{j,2},hy(j),hyp(j));
    end
    
    if ~isempty(sel);
      %count SELECTED items and add strings
      [hysel,hxsel] = hist(cl(sel),[lu{:,1}]);
      hypsel = hysel./max(hy,1)*100;
      
      txt{end+1} = '  ';
      txt{end+1} = 'Class Population Statistics (Selected Samples)';
      txt{end+1} = sprintf(  ['  % ' len 's    % 16s    % 5s'],'Class Name','Count of Total','Percent (Of Class)');
      for j=1:size(lu,1);
        txt{end+1} = sprintf(['  % ' len 's    % 6i of % 6i     % 6.1f%%'],lu{j,2},hysel(j),hy(j),hypsel(j));
      end     
    end
    
    infobox(char(txt),struct('maxsize',[inf inf]));
    
  case {'axiscontext'}
    
    mydataset = getdataset(targfig);
    plotby = getappdata(targfig,'plotby');
    
    if getappdata(targfig,'noinclude') | isempty(mydataset) | ~isa(mydataset,'dataset') | plotby == 0;
      set([handles.EditExcludePlotted handles.EditIncludePlotted handles.EditExcludeNotPlotted handles.EditDivideByPlotted handles.EditSubtractPlotted],...
        'enable','off');
    else
      set([handles.EditExcludePlotted handles.EditIncludePlotted handles.EditExcludeNotPlotted handles.EditDivideByPlotted handles.EditSubtractPlotted],...
        'enable','on');
    end      
    
    set(handles.EditPlotClass,'enable','off','visible','on')
    opts = getappdata(targfig);
    if opts.plotby>0
      plotby = opts.plotby;
      if ~isfield(opts,'viewclassset')
        opts.viewclassset = 1;
      end
      cls  = mydataset.class{plotby,opts.viewclassset};
      if ~isempty(cls)
        set(handles.EditPlotClass,'enable','on')
      end
    end
      
      
    %DISABLE while code is being developed, except developers
    allowmath = getappdata(targfig,'allowmath');
    if isempty(allowmath) | allowmath ~= 1;
      set([handles.EditDivideByPlotted handles.EditSubtractPlotted],'visible','off');
    end
    
  case {'EditPlotClass'}
    
    opts = getappdata(targfig);
    plotby = opts.plotby;
    if ~isfield(opts,'viewclassset')
      opts.viewclassset = 1;
    end
    mydataset = getdataset(targfig);
    cls  = mydataset.class{plotby,opts.viewclassset};
    classlookup = mydataset.classlookup{plotby,opts.viewclassset};
    validclasses = classlookup(:,2);

    [class_number,ok] = listdlg('ListString',validclasses,...
                                'SelectionMode','multiple','InitialValue',[],...
                                'PromptString',{'Choose one or more classes' 'to plot:  '},...
                                'Name','Select Class');
    
    if ok
      class_number = cat(2,classlookup{class_number,1});
      val = GetMenuIndex(targfig);
      val{2} = find(ismember(cls,class_number));
      plotgui('update','figure',targfig,'axismenuvalues',val);
    end
    
  case {'EditExcludePlotted','EditIncludePlotted','EditExcludeNotPlotted'}
    
    plotby = getappdata(targfig,'plotby');
    if plotby == 0; return; end    %can not do this if special plot mode
    
    %get axis menu item(s) selected
    [ind1,displayed,ind3] = GetMenuIndex(targfig);
    if isempty(displayed); return; end      %nothing selected? can't do anything
    
    mydataset = getdataset(targfig);
    if isempty(mydataset) | ~isa(mydataset,'dataset'); return; end  %no data? exit
    
    %update the includ information
    switch menu
      case 'EditIncludePlotted'
        mydataset.includ{plotby} = union(mydataset.includ{plotby},displayed(:));
      case 'EditExcludePlotted'
        mydataset.includ{plotby} = setdiff(mydataset.includ{plotby},displayed(:));
      case 'EditExcludeNotPlotted'
        mydataset.includ{plotby} = displayed(:);
    end
    
    %store the data
    setobjdata(targfig,mydataset,'include');
    
    figure(targfig);   %reactivate original target
    
    
  case {'EditDivideByPlotted','EditSubtractPlotted'}
    
    isdivide   = abs(strcmp(menu,'EditDivideByPlotted'));
    issubtract = abs(strcmp(menu,'EditSubtractPlotted'));
    
    mydataset = getdataset(targfig);
    plotby = getappdata(targfig,'plotby');
    [ind1,displayed,ind3] = GetMenuIndex(targfig);
    if isempty(displayed); return; end
    
    slct         = cell(1,ndims(mydataset));
    [slct{:}]    = deal(':');
    slct{plotby} = displayed;
    ref          = mydataset.data(slct{:});
    
    if length(displayed)>1;
      ref          = mean(ref,plotby);
      if sum(size(ref)>1)>1; return; end   %do not allow refs with > 1 dim
    end
    
    switch plotby
      case 1
        if issubtract;
          mydataset.data = scale(mydataset.data, ref);
        else
          mydataset.data = scale(mydataset.data, ref.*0, ref);
        end      
      case 2
        if issubtract;
          mydataset.data = scale(mydataset.data', ref')';
        else
          mydataset.data = scale(mydataset.data', ref'.*0, ref')';
        end      
    end
    
    %store the data
    setobjdata(targfig,mydataset);
    
  case {'ViewSettings'}  
    
    odefs = optiondefs;
    options = [];
    for f = {odefs.name}; 
      options.(f{:}) = getappdata(targfig,f{:}); 
    end
    options.definitions = odefs;
    options.functionname = 'plotgui'; %required so allowsave works
    options = optionsgui(options,struct('allowsave','yes'));
    drawnow;
    if ~isempty(options);
      plotgui('update','figure',targfig,options)
    end

    %================================================================
  case 'File'
    
    [mydataset,myid] = getdataset(targfig);
    %if we have our own data, allow load; if someone else has our data, don't allow load
    if (isempty(mydataset) | myid.source==targfig) & ~getappdata(targfig,'noload');
      set(handles.FileLoadData,'enable','on');
    else
      set(handles.FileLoadData,'enable','off');
    end    

    if ~isempty(mydataset) & isa(mydataset,'dataset') & ~isempty(mydataset.data);
      enb = 'on';
    else
      enb = 'off';
    end    
    set([handles.FileSaveData handles.FileOpenIn handles.FileEdit handles.FileLoadSelection handles.FileSaveSelection],'enable',enb);
    if ~ispc 
      enb = 'off';
    end    
    set( handles.FileExportFigure,'enable',enb);
    
  case 'FileLoadSelection'
    
    [sel,varname] = lddlgpls({'double','logical'},'Load Selection Indicies');
    if isempty(varname);
      return;
    end
    if islogical(sel);
      sel = find(sel);
    end

    mydataset = getdataset(targfig);
    plotby = getappdata(targfig,'plotby');
    if plotby == 0;               %if special plot mode, figure out which dim we're actually selecting on
      plotby = get(handles.xaxismenu,'value');
    else
      plotby = 2-plotby+1;
    end
    if plotby < 1; plotby = 1; end
    
    selectcell = cell(1,ndims(mydataset));
    selectcell{plotby} = sel;
    setselection(selectcell,'set',targfig);
    
  case 'FileSaveSelection'
    
    plotby = getappdata(targfig,'plotby');
    if plotby == 0;               %if special plot mode, figure out which dim we're actually selecting on
      plotby = get(handles.xaxismenu,'value');
    else
      plotby = 2-plotby+1;
    end
    if plotby < 1; plotby = 1; end

    selection = getselection(targfig);
    if isempty(selection)
      sel = [];
    else
      sel = selection{plotby};
    end
    
    svdlgpls(sel,'Save Selection')
      
  case 'FileSaveData'
    
    svdlgpls(getdataset(targfig),'Save Data')
    
  case 'FileLoadData'
    
    data = lddlgpls('*','Load Data');
    if ~isempty(data); 
      if targfig == fig; 
        update('new',data);
      else
        update('figure',targfig,data); 
      end
    end
    
  case 'FileEdit'
    
    mydat = getlink(targfig);
    mylinks = mydat.links;
    editdsfig = [];
    for i = 1:length(mylinks)
      if ishandle(mylinks(i).handle)&&strcmpi(get(mylinks(i).handle,'tag'),'editds')
        editdsfig = mylinks(i).handle;
      end
    end
    if isempty(editdsfig)
      editdsfig = editds(getlink(targfig),'position',get(targfig,'position'));
    end
    editds('noedit',editdsfig,getappdata(targfig,'noinclude'))
    figure(editdsfig);
    
  case 'FileOpenIn'
    sendto('update',gcbo);
    
    %-----------------------------------------------------

  case 'FileExportPowerpoint'
    exportfigure('powerpoint',targfig);
  case 'FileExportWord'
    exportfigure('word',targfig);
  case 'FileExportHTML'
    reportwriter('html',targfig);
    
    %======================================================
  case {'PlotGUITargetMenu'}   %update menu and check statuses
    
    if fig==targfig | isempty(fig);
      delete(cbo)
    else
      set(get(cbo,'children'),'enable','on');
      if getappdata(targfig,'autoduplicate')
        en = 'on';
      else
        en = 'off';
      end
      set(findobj(cbo,'tag','AutoDuplicate'),'checked',en);
    end
    
  case {'AutoDuplicate'}
    setappdata(targfig,'autoduplicate',~getappdata(targfig,'autoduplicate'));      
    
  case {'FindControls'}
    
    findcontrols(fig);
    

  case {'linemenu'}

    targethandles.LineExclude = findobj(gcbo,'tag','LineExclude');
    targethandles.LineInclude = findobj(gcbo,'tag','LineInclude');
    targethandles.LineSetClass = findobj(gcbo,'tag','LineSetClass');
    targethandles.LineClassStats = findobj(gcbo,'tag','LineClassStats');
    targethandles.LineChangeSymbol = findobj(gcbo,'tag','LineChangeSymbol');
    targethandles.LineSelectClass  = findobj(gcbo,'tag','LineSelectClass');
    targethandles.LineLineWidth    = findobj(gcbo,'tag','LineLineWidth');
    targethandles.LineSymbolSize   = findobj(gcbo,'tag','LineSymbolSize');
    targethandles.LineChangeLineColors = findobj(gcbo,'tag','LineChangeLineColors');

    set(targethandles.LineSetClass,'separator','on');

    set([targethandles.LineExclude targethandles.LineInclude targethandles.LineSetClass targethandles.LineSelectClass],'enable','off');
    if getappdata(targfig,'viewclasses')
      set([targethandles.LineChangeSymbol targethandles.LineClassStats],'enable','on','visible','on');
    else
      set([targethandles.LineChangeSymbol targethandles.LineClassStats],'enable','off','visible','off');
    end
    if isprop(gcho,'linewidth') & ~strcmp(get(gcho,'LineStyle'),'none')
      set(targethandles.LineLineWidth,'enable','on','visible','on','separator','on');
      set(targethandles.LineChangeSymbol,'enable','off','visible','off');
      set([targethandles.LineExclude targethandles.LineInclude],'visible','on');
    else
      set(targethandles.LineLineWidth,'enable','off','visible','off');
      if getappdata(targfig,'viewclasses') & ~getappdata(targfig,'noselect');
        set(targethandles.LineSelectClass,'visible','on','enable','on');
      end
      set([targethandles.LineExclude targethandles.LineInclude],'visible','off');
    end

    if getappdata(targfig,'viewclasses')
      vis = 'on';
    else
      vis = 'off';
    end
    
    if ~getappdata(targfig,'classcoloruser')
      %Only show if user defined color is turned on. This overrides colors
      %for all class sets. Off by defualt. 
      vis = 'off';
    end
    set(targethandles.LineChangeLineColors,'visible',vis,'enable','on');
    
    if isprop(gcho,'markersize') & ~strcmp(get(gcho,'marker'),'none')
      en = 'on';
      set(targethandles.LineLineWidth,'separator','off');
    else
      en = 'off';
      set(targethandles.LineLineWidth,'separator','on');
    end
    if strcmpi(get(targethandles.LineChangeSymbol,'visible'),'on')
      sep = 'off';
    else
      sep = 'on';
    end
    set(targethandles.LineSymbolSize,'enable',en,'visible',en,'separator',sep);

    set(findobj(cbo,'tag','LineHistogram'),'enable','on','visible','on');
    classsymbolmenu(findobj(cbo,'tag','LineChangeSymbol'));
    
    if ~getappdata(targfig,'noinclude');
      obj = gcho; %get current object (hidden included)
      if isempty(obj); return; end
      plotby = getappdata(obj,'mode');
      ind    = getappdata(obj,'index');
      [mydataset] = getdataset(targfig);
      if isempty(plotby) | isempty(ind) | isempty(mydataset) | ~isa(mydataset,'dataset'); return; end  %no data? exit

      if ~strictedit
        set([targethandles.LineSetClass],'enable','on');  %if marked, allow setting of class
      end

      set(targethandles.LineSelectClass,'visible','off','enable','off');
      
      if ismember(ind,mydataset.include{plotby}) %included already?
        set([targethandles.LineExclude],'enable','on');
      else
        set([targethandles.LineInclude],'enable','on');
      end
    end

  case {'LineExclude' 'LineInclude'}
    
    obj = gcho; %get current object (hidden included)
    if isempty(obj); return; end
    
    plotby = getappdata(obj,'mode');
    ind    = getappdata(obj,'index');
    mydataset = getdataset(targfig);
    if isempty(plotby) | isempty(ind) | isempty(mydataset) | ~isa(mydataset,'dataset'); return; end  %no data? exit
    
    %update the includ information
    switch menu
      case 'LineInclude'
        mydataset.includ{plotby} = union(mydataset.includ{plotby},ind);
      case 'LineExclude'
        mydataset.includ{plotby} = setdiff(mydataset.includ{plotby},ind);
        inds = getappdata(targfig,'axismenuindex');
        if ismember(ind,inds{2}) & length(inds{2})>1
          inds{2} = setdiff(inds{2},ind);
          update('figure',targfig,'axismenuvalues',inds)
        end
    end
    
    %store the data
    setobjdata(targfig,mydataset,'include');
        
    figure(targfig);   %reactivate original target    
    
  case {'identifycurve'}
    
    set(0,'currentfigure',targfig);
    obj = gcho; %get current object (hidden included)
    if isempty(obj); return; end
    if ishandle(obj);
      %find/create "remove" context menu
      hmenu = labelmenu(targfig);

      tag = legendname(obj);
      if ~isempty(tag);
        pos = get(gca,'currentPoint');
        dx = diff(get(gca,'xlim'))*.02*(strcmp(get(gca,'xdir'),'normal')*2-1);
        dy = diff(get(gca,'ylim'))*.02;
        h = text(pos(1,1)+dx,pos(1,2)+dy,pos(1,3),tag);
        useti = getappdata(targfig,'textinterpreter');
        if ~isempty(useti)
          set(h,'interpreter',useti);
        end
        set(h,'uicontextmenu',hmenu,'tag','identifycurvetag');
        moveobj(h);
        %         infobox(tag)
      end
    end
    
  case {'probplotnormal' 'probplotchi2' 'probplotlognormal' 'probplotother' 'probplotauto'}
    
    obj = gcho; %get current object (hidden included)
    if isempty(obj); return; end
    if ishandle(obj);
      switch get(obj,'type')
        case 'line'
          xdata = get(obj,'xdata');
          ydata = get(obj,'ydata');
          ydata = ydata(:,~isnan(xdata));  %only included data
          %           clr   = get(obj,'color');
        case 'image'
          ydata = get(obj,'cdata');
        otherwise
          return
      end
      tag = legendname(obj);
      if isempty(tag)
        tag = 'Plotted Data';
      end

      disttype = menu(9:end);
      if strcmp(disttype,'other')
        disttype = 'select';
      end
      options = [];
      options.varname = tag;
      options.histogram = 'on';
      options.plots = 'final';
      plotqq(ydata,disttype,options);
      children = getappdata(targfig,'children');
      setappdata(targfig,'children',unique([children gcf]));
      
    end
      
    
  case {'EditHistSelection'}
    histcontrast('create',targfig)
  
  case {'EditHistX' 'EditHistY'}
    histaxes(targfig,lower(menu(end)));
    
  case {'EditLockCLim'}
    %Change color scale locking.
    cslock = evriquestdlg('Change color scale locking.','Color Scale Locking','Auto','Custom','None','None');
    if ~isempty(cslock)
      switch lower(cslock)
        case 'none'
          setappdata(targfig,'colorscalelock',-1)
        case 'auto'
          setappdata(targfig,'colorscalelock',0)
        case 'custom'
          cslockval = inputdlg('Enter values for min and max (e.g., "1 100").','Custom Color Scale',1,{'1 100'});
          if ~isempty(cslockval)
            setappdata(targfig,'colorscalelock',str2num(cslockval{:}))
          end
      end
      plotgui('update','figure',targfig)
    end
    
  case {'EditSearchBar'}
    
    htb = getappdata(targfig,'PlotguiSearchBar');
    if targfig==fig
      %Target figure is plot controls so don't add toolbar.
      return
    end
    
    if ~isempty(htb)
      if ~isempty(htb.getParent)
        %close seasrch bar
        htb = getappdata(targfig,'PlotguiSearchBar');
        plotgui_searchbar('closetoolbar',[],[],targfig,htb)
      end
    else
      %Open toolbar.
      plotgui_searchbar(targfig)
    end
    
  otherwise
    disp(['Menu ' topmenu ':' menu ' is not yet defined']);

end

%---------------------------------------------------------------
function obj = gcho; 
%get current object (hidden included)
obj = gco;
if isempty(obj)
  try
    set(0,'showhiddenhandles','on')
    obj = gco;
    set(0,'showhiddenhandles','off')
  catch
    set(0,'showhiddenhandles','off')
  end
end

% --------------------------------------------------------------------
function link = gethelplink(varargin)

link = '';
%check shared data for help link first
targfig = varargin{1};
mylink = getlink(targfig);
if ~isempty(mylink) & isvalid(mylink)
  if isfield(mylink.properties,'helplink')
    link = mylink.properties.helplink;
  end
end

if isempty(link)
  %nothing specified in shared data? look at figure
  link = getappdata(targfig,'helplink');
end
  
% --------------------------------------------------------------------
function showhelp(varargin)

if isnumeric(varargin{1}) | isa(varargin{1},'matlab.ui.Figure')
  varargin{1} = double(varargin{1}); %make sure figure handle is double
  [targfig,fig] = findtarget(varargin{1});
  link = gethelplink(targfig);
else
  link = varargin{1};
end
if ~isempty(findstr(link,'//'));
  %URL
  web(link);
else
  %wiki link (probably)
  local = regexprep(link,'[: ]','_');
  pos = findstr(local,'#');
  if isempty(pos)
    pos = length(local)+1;
  else
    pos = pos(1);
  end
  local = [local(1:pos-1) '.html'];
  local = which(local);    %look for local copy
  if ~isempty(local)
    %found local - show it
    web([local  link(pos:end)]);
  else
    %no local copy? get web version
    web(['http://wiki.eigenvector.com/index.php?title=' link]);
  end
  
end

% --------------------------------------------------------------------
function closegui(varargin)
% close figure after doing some housekeeping

if nargin == 1;
  figin = varargin{1};
else
  figin = gcf;
end
for fig = figin;

  if ~ismember(fig,allchild(0));   %no longer exists? just exit
    return;
  end

  validatefamily(fig)
  children  = getappdata(fig,'children');    %get children number(s)
  controlby = getappdata(fig,'controlby');  %get controlby figure #
  target    = getappdata(fig,'target');     %get any target for a control figure
  
  if ~isempty(controlby)
    validatefamily(controlby)
  end

  if strcmp(get(fig,'tag'),'PlotGUI')
    %If this is Plot Controls then just make invisible and never delete so
    %it's faster to open AND won't complicate the "reuse" of it.
    set(fig,'windowstyle','normal','visible','off');
    drawnow;
    return
  end

  if ~isempty(getappdata(fig,'closeguicallback'));
    try
      %positionmanager(fig,'plotgui','set');%Save position
      eval(getappdata(fig,'closeguicallback'));
    catch
      disp(lasterr)
      disp(['Error executing CloseGUICallback (fig ' num2str(fig) ')']);
    end
  end


  mylink = getlink(fig);
  if ~isempty(mylink)
    %Remove link.
    try
      linkshareddata(mylink,'remove',fig);
    catch
    end
  end

  for k = children(:)';
    if ishandle(k) & k~=fig; %ismember(k,allchild(0)) & k~=fig;  %as long as it is a handle and it's not ME
      %close this child:
      delete(k);
    end
  end

  %Dump unused useritems
  if ~isempty(controlby) & ishandle(controlby);
    
    %get list of useritems used by each child figure (except this one)
    uitems = [];
    for k = setdiff(getappdata(controlby,'children'),fig)
      if ishandle(k)
        uitems = [uitems,getappdata(k,'useritems')];
      end
    end
    uitems = unique(uitems);
    
    %set master list of user items to those we found
    alluitems = getappdata(controlby,'useritems');  %note all we currently have in our list
    setappdata(controlby,'useritems',uitems);  %keep only those used by a child

    %remove useritems not used by any child
    todelete = setdiff(alluitems,uitems);
    todelete(~ishandle(todelete)) = [];
    delete(todelete);
    
    %remove from plot controls "children" list
    pgchildren = getappdata(controlby,'children');
    pgchildren = setdiff(pgchildren,fig);
    setappdata(controlby,'children',pgchildren);
    setappdata(controlby,'target',min(double(pgchildren)));
    if isempty(pgchildren);
      %no other children? hide controls
      if evriwindowstyle(controlby)
        delete(controlby);
      else
        set(controlby,'visible','off');
      end
    else
      %refocus controls on another target
      updatecontrols(controlby);  %and update them
    end
    
  end
  positionmanager(fig,'plotgui','set');%Save position
  delete(fig);     %OK.. now close me
end

% --------------------------------------------------------------------
function closechildren(varargin)
% close children of specified handle (called from external programs)

if nargin == 1;
  fig = varargin{1};
else
  fig = gcf; 
end

if ~ishandle(fig);   %no longer exists? just exit
  return;
end

children = getappdata(fig,'children');    %get children number(s)

if ~isempty(children);
  for k = children(:)';
    if ismember(k,allchild(0));
      plotgui('closechildren',k)  %close it's children
      close(k);    %close this figure itself
    end
  end
end

% --------------------------------------------------------------------
function spawn(targfig)
%create static copy of figure

pause(.25); drawnow;  %give axes time to reset after keypress (if thats how we got here)
h        = get(targfig,'children');  %get top-level handles
cm       = get(targfig,'colormap');
h        = h(~ismember(get(h,'type'),{'uicontextmenu','uimenu','uitoolbar'}));  %drop uimenus and uicontextmenus and toolbars!!
newfig   = newfigure;  %create new figure
evricopyobj(h,newfig);  %copy objects
set(findobj(newfig),'uicontextmenu',[]);   %remove context menu pointers on any copied objects
set(newfig,'colormap',cm);
pos      = get(targfig,'position');
pos(1:2) = pos(1:2)+[20 -20];
set(newfig,'position',pos);
set(newfig,'CloseRequestFcn','closereq', ...
      'KeyPressFcn','', ...
      'KeyReleaseFcn','', ...
      'ResizeFcn','', ...
      'SizeChangedFcn','', ...
      'WindowButtonDownFcn','', ...
      'WindowButtonMotionFcn','', ...
      'WindowButtonUpFcn','', ...
      'WindowKeyPressFcn','', ...
      'WindowKeyReleaseFcn','', ...
      'WindowScrollWheelFcn','', ...
      'CreateFcn','');
figuretheme(newfig);

% --------------------------------------------------------------------
function varargout = duplicate(fig)
% create a new plotgui figure with current figure's settings

[targfig,fig] = findtarget(fig);
mylink = getlink(targfig);

try
  setptr(targfig,'watch')
  donotcopy = {'selection' 'selectiontimestamp' 'usespecialmarkers' 'viewtable' 'currentaxes' 'uicontrol' 'autoduplicate' 'viewlog'};
  tocopy = setdiff(fieldnames(plotgui('options')),donotcopy);
  tocopy = tocopy(:)';%Make sure it's a row.
  
  if ~isempty(getappdata(targfig,'modes'));
    modes = fieldnames(getappdata(targfig,'modes'));
  else
    modes = cell(0);
  end
  
  list = {mylink,modes{:}};    %start with dataset link and any modes
  
  for feyld = tocopy;     %then copy all properties extracted (as listed above)
    list(end+1) = feyld;
    list(end+1) = {getappdata(targfig,feyld{:})};
  end
  
  %get linear/log info
  cax = get(targfig,'currentaxes');
  stat = ismember(get(cax,{'xscale' 'yscale' 'zscale'}),'log');
  list = [list {'viewlog' stat}];
  
  %get new figure
  pos = get(targfig,'position');
  pos(1:2) = pos(1:2)+[20 -20];
  
  newfig = newfigure;
  guidata(newfig,guidata(targfig));
  setappdata(newfig,'useritems',getappdata(targfig,'useritems'));  %copy handles of user items to new figure (so they will show up on the new figure)
  set(newfig,...
    'position',pos,...
    'name',get(targfig,'name'),...
    'numbertitle',get(targfig,'numbertitle'),...
    'userdata',get(targfig,'userdata'));      %copy various figure props.
  
  update('figure',newfig,list{:});   %create/update figure with other plotgui properties as extracted from targfig
  
  setptr(targfig,'arrow')
catch
  le = lasterror;
  setptr(targfig,'arrow')
  rethrow(le)
end

if nargout>0
  varargout{1} = newfig;
end

% --------------------------------------------------------------------
function xaxismenu_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.xaxismenu.
[targfig,fig] = findtarget(gcbf);
setappdata(targfig,'axismenuvalues',GetMenuSettings(fig))
setappdata(targfig,'axismenuindex',GetMenuIndex(fig))
if get(handles.autobtn,'value');
  plotds(targfig);             %plot data
else
  set(handles.plotbtn,'backgroundcolor',[1 .5 .5]);
end
if gcf ~= gcbf; figure(gcbf); end    %reactivate callback figure


% --------------------------------------------------------------------
function yaxismenu_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.yaxismenu.
[targfig,fig] = findtarget(gcbf);

%get eslider info
obj = getappdata(fig,'eslider');

%reconcile current listbox contents back into master list of selected items
str = get(handles.yaxismenu,'string');
val = get(handles.yaxismenu,'value');
oldlbt = get(handles.yaxismenu,'listboxtop');

if ~isempty(val)
  if length(val)>1;
    %ALL are selected? check for prev/next items
    val = setdiff(val,find(ismember(str,{'Previous page ...' 'Next page ...'})));
    set(handles.yaxismenu,'value',val);
    str = '';
  else
    %only one item, check if it is prev/next link
    str = str{val};
  end      
else
  str = '';
end
%page up or page down - just move slider (don't consider this a real click)
switch str
  case 'Previous page ...'
    obj.value = obj.value-obj.page_size;
    return
  case 'Next page ...'
    obj.value = obj.value+obj.page_size;
    return
end

%Actual item clicked... get the current listbox selection (in units of the
%whole list) and reconcile this with the "master" All Selected list. This
%logic allows deselection as well as selection.
sel = obj.value+val-1;
allsel = obj.selection;
if obj.value ~= 1
  sel = sel-1;  %subtract another one for the offset of "previous page" link
  if length(allsel)==1 & allsel==1
    allsel = [];  %if we're not at the top, and the first item is the ONLY one selected, clear it
  end
end
allsel = setdiff(allsel,obj.value:obj.value+obj.page_size);  %drop everything handled by the listbox now
allsel = union(allsel,sel);  %then add the items actually selected in the listbox
obj.selection = allsel;

%Now - do normal callback for y-axis menu change
if isempty(getpd(handles.yaxismenu,'value'))
  indx = getappdata(targfig,'axismenuindex');
  if isempty(indx) | ~iscell(indx) | isempty(indx{2})
    indx = cell(1,3);
    indx{2} = 1;  %default if nothing stored in figure
  end
  setpd(handles.yaxismenu,'value',indx{2});
else
  set(handles.yaxismenu,'listboxtop',oldlbt);
end
setappdata(targfig,'axismenuvalues',GetMenuSettings(fig))
setappdata(targfig,'axismenuindex',GetMenuIndex(fig))
if get(handles.autobtn,'value');
  plotds;             %plot data
else
  set(handles.plotbtn,'backgroundcolor',[1 .5 .5]);
end
if gcf ~= gcbf; figure(gcbf); end    %reactivate callback figure

% --------------------------------------------------------------------
function eslider_clear(varargin)

obj = varargin{1};
fig = obj.parent;
[targfig,fig] = findtarget(fig);
handles = guidata(fig);

obj.value = 1;
eslider_update(getappdata(fig,'eslider'));
set(handles.yaxismenu,'listboxtop',1);

setappdata(targfig,'axismenuvalues',GetMenuSettings(fig))
setappdata(targfig,'axismenuindex',GetMenuIndex(fig))
if get(handles.autobtn,'value');
  plotds;             %plot data
else
  set(handles.plotbtn,'backgroundcolor',[1 .5 .5]);
end

% --------------------------------------------------------------------
function eslider_update(varargin)
%handle the update call when the eslider is moved (updates the listbox)

%Callback gets the object.
obj = varargin{1};
%Get the listbox.
handles = guidata(obj.parent);
%Get the list.
mylist = getappdata(handles.yaxismenu,'string');
%Set list to current page.
ind = obj.value:min([obj.value+obj.page_size  obj.range  length(mylist)]);
offset = obj.value-1;
this_list = mylist(ind);
if length(mylist)>max(ind)
  this_list = [this_list; {'Next page ...'}];
end
if obj.value ~= 1
  this_list = [{'Previous page ...'}; this_list];
  offset = offset-1;
end

%re-select appropriate items in this segment
allsel = obj.selection;
sel = allsel(allsel>=obj.value & allsel<=obj.value+obj.page_size)-offset;
lbt = min(sel);
if isempty(lbt);
  lbt = 1;
end
set(handles.yaxismenu,'value',sel,'string',this_list,'ListboxTop',lbt);

% --------------------------------------------------------------------
function zaxismenu_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.zaxismenu.
[targfig,fig] = findtarget(gcbf);
setappdata(targfig,'axismenuvalues',GetMenuSettings(fig))
setappdata(targfig,'axismenuindex',GetMenuIndex(fig))
if get(handles.autobtn,'value');
  plotds;             %plot data
else
  set(handles.plotbtn,'backgroundcolor',[1 .5 .5]);
end
if gcf ~= gcbf; figure(gcbf); end    %reactivate callback figure


% --------------------------------------------------------------------
function statusbox_Callback(h, eventdata, handles, varargin)
% Deal with changing of target statusbox pulldown menu
value    = get(h,'value');
children = getappdata(handles.PlotGUI,'children');
if value > length(children); value = length(children); end;
if value < 1; value = 1; end;

if ~isempty(children);
  findtarget(children(value),1);
end

% --------------------------------------------------------------------
function plotbtn_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.plotbtn.
plotds;             %plot data
if gcf ~= gcbf; figure(gcbf); end    %reactivate callback figure


% --------------------------------------------------------------------
function autobtn_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.autobtn.
if get(gcbo,'value');
  plotds;             %plot data
else
  set(handles.plotbtn,'enable','on','value',0);
  evritip('autoplotoff','You have turned "auto-update" OFF. To update the figure after making a change, you must click the "Plot" button.',1);
end
if gcf ~= gcbf; figure(gcbf); end    %reactivate callback figure


% --------------------------------------------------------------------
function limitsbox_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.limitsbox.

[targfig,fig] = findtarget(handles.PlotGUI);
if get(h,'value');
  set(handles.limitsvalue,'enable','on');
  setappdata(targfig,'showlimits',1);
else
  set(handles.limitsvalue,'enable','off');
  setappdata(targfig,'showlimits',0);
end

plotds;             %plot data

if gcf ~= gcbf; figure(gcbf); end    %reactivate callback figure


% --------------------------------------------------------------------
function limitsvalue_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.limitsvalue.

[targfig,fig] = findtarget(handles.PlotGUI);
limit = get(h,'string');
limit = str2num(limit);
if limit >= 100 | limit <= 0;   limit = []; end
if isnan(limit) | isinf(limit); limit = []; end
if isempty(limit); limit =  95; end

set(gcbo,'string',num2str(limit));
set(gcbo,'value',limit);
setappdata(targfig,'limitsvalue',limit);

plotds;             %plot data

if gcf ~= gcbf; figure(gcbf); end    %reactivate callback figure

% --------------------------------------------------------------------
function varargout = newfigure(varargin)

targfig = figure('visible','off',varargin{:});
figbrowser('addmenu',targfig)

%check if exact position as another figure
figs = findobj(allchild(0),'type','figure');
figs = setdiff(figs,targfig);
if ~isempty(figs);
  pos = get(figs,'position');
  if iscell(pos)
    pos = cat(1,pos{:});
  end
  targpos = get(targfig,'position');

  overlap = true;
  while overlap
    overlap = any(all(scale(pos,targpos)==0,2));
    if overlap
      %overlaps another figure
      targpos = targpos + [20 -20 0 0];
      set(targfig,'position',targpos)
    end
  end
end
set(targfig,'visible','on');

%assign necessary callbacks
assigngetfocus(targfig);
varargout{1} = targfig;

% --------------------------------------------------------------------
function Figure_ResizeFcn(h, eventdata, handles, varargin)
% Resize function called from plotgui.fig.
% Using code from file exchange to get around continuous calls to resize as
% you drag. There is code in updatefigure to handle this but it's not
% working well in compiled Solo+MIA for some reason. 
% https://www.mathworks.com/matlabcentral/answers/570829-slow-sizechangedfcn-or-resizefcn

persistent blockCalls  % Reject calling this function again until it is finished

figH = gcbf;
if isempty(figH); figH = gcf; end

if any(blockCalls), return, end
blockCalls = true;
doResize = true;
while doResize   % Repeat until the figure does not change its size anymore
   siz = get(figH, 'Position');
   pause(.3);
   drawnow;
   
   doResize = ~isequal(siz, get(figH, 'Position'));
end
blockCalls = false;  % Allow further calls again


PlotGUI_ResizeFcn(h, eventdata, handles, varargin)

% --------------------------------------------------------------------
function PlotGUI_ResizeFcn(h, eventdata, handles, varargin)
% Stub for ResizeFcn of the figure handles.PlotGUI.

fig = gcbf;
if isempty(fig); fig = gcf; end

pos = get(fig,'position');
if ismac & pos(3)==191
  %Default width of plotgui figure is too small for mac, some menu bar
  %items get chopped off. So widen if current width is default.
  pos(3) = 250;
  set(fig,'position',pos)
end
  

handles = guidata(fig);
if isstruct(handles); updatefigure(fig,1); end    %thats all!

% --------------------------------------------------------------------
function child_WindowButtonDownFcn(h, eventdata, handles, varargin)

persistent callindex

%callindex helps us keep track of the order of clicks (some versions of
%Matlab will do an "open" prior to the "normal" click, so we need to use
%this to filter those out
if isempty(callindex)
  callindex = 0;
end
callindex = callindex + 1;
myindex = callindex;

targfig = gcbf;

switch get(targfig,'selectiontype')
  case 'alt'
    %also do addon calls
    wbdcmd = evriaddon('plotgui_windowbuttondown_rightclick');
    for cbitem = 1:length(wbdcmd)
      feval(wbdcmd{cbitem},targfig);
    end
    return;
    
  case 'open'
    %Double click.
    %also do addon calls
    wbdcmd = evriaddon('plotgui_windowbuttondown_doubleclick');
    for cbitem = 1:length(wbdcmd)
      feval(wbdcmd{cbitem},targfig);
    end
    
  case {'extend'}
    objtype = get(gcho,'type');
    if strcmpi(objtype,'axes') | strcmpi(objtype,'image')
      scrollzoom('buttonDown',targfig);
      showtempnotice(targfig,'Shift-Click or Wheel-Click and drag to pan','panwheel',2);
      return;
    end
    
end
setappdata(gca,'oldpanpoint',[]);

if strcmp(get(gco,'tag'),'doubleclicknotice')
  delete(gco);
  return; 
end

%if autoduplicate is on and they clicked on an object (and there was more
%than one axis, duplicate this figure (current axis only)
[currentaxes,myaxes] = findaxes(targfig);
if getappdata(targfig,'autoduplicate') & get(targfig,'currentobject')~=targfig & ~isempty(findobj(allchild(currentaxes),'userdata','data'));
  autoduplicate = length(myaxes)>1;
  if strcmp(get(targfig,'selectiontype'),'normal');
    if isempty(findobj(allchild(targfig),'tag','doubleclicknotice'))
      %give double-click notice
      if length(myaxes)>1
        showtempnotice(targfig,'Double-click axes to view in new window, or press a number key to create sub-plots.','dblclick',4);
      else
        showtempnotice(targfig,'Press a number key to create sub-plots.','dblclick',4);
      end
    end
  end
else
  autoduplicate = false;
end

if ~autoduplicate | ~strcmp(get(targfig,'selectiontype'),'open');
  %handle line identification
  cobj = gcho;
  cax  = gca;
  if strcmpi(get(cobj,'type'),'line') & ~ismember(get(cobj,'tag'),{'cross_line' 'cross_line_point1' 'cross_line_point2' 'drillpoint'})
    %reset previous line if needed
    lw = getappdata(cax,'oldlinewidth');
    lastclicked = getappdata(cax,'lastclickedobj');
    if ~isempty(lastclicked) & ishandle(lastclicked) & ~isempty(lw)
      set(lastclicked,'linewidth',lw);
      setappdata(lastclicked,'preselectlinewidth',[]);
      showtempnotice(targfig,'','leftclick',0);
    end
    if strcmpi(get(targfig,'selectiontype'),'normal')
      delete(findobj(allchild(cax),'tag','identifycurvetag'));
    end
    if isempty(lastclicked) | lastclicked~=cobj      
      %identify newly clicked line
      lw = get(cobj,'linewidth');
      setappdata(cax,'lastclickedobj',cobj)
      setappdata(cax,'oldlinewidth',lw);
      setappdata(cobj,'preselectlinewidth',lw);
      set(cobj,'linewidth',lw+2);
      uistack(cobj,'top');
      %add a label
      menuselection('identifycurve');      
      showtempnotice(targfig,legendname(cobj),'leftclick');
    else
      %second click on same object? Send to back
      uistack(cobj,'bottom');
      setappdata(cax,'lastclickedobj',[])
    end
  end
end

%update plotGUI controls to match current axes (always, autoduplicate or
%not!)
set(targfig,'PaperPositionMode','auto');
[PlotGUItags(2) PlotGUItags(1)] = dockcontrols(targfig);
if myindex==callindex;  %unless another call has happened in the meantime...
  figure(targfig);
end

%do auto-duplicate (if active and the correct kind of click)
if autoduplicate & strcmp(get(targfig,'selectiontype'),'open');
  %"open" (double-click)? duplicate
  tm = getappdata(targfig,'lastduplicate');  %avoid double-double-click problem
  if isempty(tm) | ((now-tm)*60*60*24)>3
    set(targfig,'selectiontype','normal')  %force the figure's selection type to be "normal" so we'll NEVER do this twice on the same click
    setappdata(targfig,'lastduplicate',now)
    delete(findobj(allchild(targfig),'tag','doubleclicknotice'));
    newfig=duplicate(targfig);
    dockcontrols(newfig);
    figure(newfig);
  end
end

%also do addon calls
wbdcmd = evriaddon('plotgui_windowbuttondown');
for cbitem = 1:length(wbdcmd)
  feval(wbdcmd{cbitem},targfig);
end

% --------------------------------------------------------------------
function child_WindowButtonMotionFcn(h, eventdata, handles, varargin)

persistent lastcheck

if isempty(lastcheck)
  lastcheck = 0;
end

if ~isempty(varargin)
  fig = varargin{1};
else
  fig = gcbf;
end

if scrollzoom('buttonMotion',fig); return; end

if (now-lastcheck)*60*60*24>1
  %do thsese things only every so often (improves performance)
  lastcheck = now;
  %change pointer if selection button is pressed indicating selection mode
  cfig = getappdata(fig,'controlby');
  if ~getappdata(fig,'noselect') & ~isempty(cfig) & ishandle(cfig) & get(findobj(cfig,'tag','select'),'value');
    setptr(fig,'crosshair');
    select_toolbar_btn(fig,1);
  else
    if strcmp(get(fig,'pointer'),'crosshair');
      setptr(fig,'arrow');
    end
    select_toolbar_btn(fig,0);
  end
end

% %look for current point
% axh = gca;
% axs = axis;
% pos = get(axh,'currentpoint');
% sel = findobj(axh,'tag','selection');
% dat = findobj(allchild(axh),'userdata','data');
% if ~isempty(dat)
%   datxy = [get(dat,'xdata'); get(dat,'ydata')]';
%   dist  = sum(scale(datxy,pos(1,1:2),abs([axs(2)-axs(1) axs(4)-axs(3)])).^2,2);
%   [w,i] = min(dist);
%   if ~isempty(sel)
%     set(sel,'xdata',datxy(i,1),'ydata',datxy(i,2))
%   end
% end

%also do addon calls
wbmcmd = evriaddon('plotgui_windowbuttonmotion');
for cbitem = 1:length(wbmcmd)
  feval(wbmcmd{cbitem},fig);
end

% --------------------------------------------------------------------
function child_WindowButtonUpFcn(varargin)

if ~isempty(varargin)
  fig = varargin{1};
else
  fig = gcbf;
end

scrollzoom('buttonUp',fig);
showtempnotice(fig,'','scrlwheel',0);

% --------------------------------------------------------------------
function child_WindowScrollWheelFcn(varargin)

scrollzoom('scrollWheel',varargin{:});

% --------------------------------------------------------------------
function notice = showtempnotice(targfig,desc,addtag,delay)
%I/O: notice = showtempnotice(targfig,'description for notice','tag',delay)
%I/O: showtempnotice(targfig)   %clear ALL temp notices

if nargin<2
  %two inputs? clear all temp notices
  objs = findobj(allchild(targfig),'userdata','tempnoticeaxes');
  delete(objs);
  return;
end

if nargin<3
  addtag = '';
end
if nargin<4;
  delay = 8;
end
mytag = ['tempnoticeaxes' addtag];
curax = get(targfig,'currentaxes');  %note current axes so we can make them current again later
tempnoticeaxes = findobj(allchild(targfig),'tag',mytag);
delete(tempnoticeaxes);

%check for other visible tempnotices and bump up if needed
objs = findobj(allchild(targfig),'userdata','tempnoticeaxes');
pos = ones(1,length(objs))*-.04;
for j=1:length(objs)
  if ~ishandle(objs(j)); continue; end 
  if any(ismember(get(get(objs(j),'children'),'visible'),'on'))
    temp = get(objs(j),'position');
    pos(j) = temp(2);
  end
end
top = max(pos)+.04;
offset = min(setdiff([0:.04:top],pos));
if isempty(offset)
  offset = 0;
end

cf = get(0,'currentfigure');
if isempty(cf) | cf~=targfig
  set(0,'currentfigure',targfig);
end
noticeax = axes(...
  'visible','off',...
  'color',get(targfig,'color'),...
  'position',[1 offset .001 .001],...
  'userdata','tempnoticeaxes',...
  'tag',mytag);
notice = text(0,0,desc);
set(notice,...
  'horizontalalignment','right',...
  'VerticalAlignment','bottom',...
  'color',[.66 0 0],...
  'fontsize',10,...
  'backgroundcolor',get(targfig,'color'),...
  'tag',['tempnotice' addtag],...
  'buttondownfcn','delete(gcbo);');
set(noticeax,'handlevisibility','off');
if ishandle(curax)
  set(targfig,'currentaxes',curax);   %reset current axes back to real ones
end

%create timer to automatically clear notice after some period of time
try
  delobj_timer(['tempnoticetimer' addtag num2str(round(double(targfig)*1e6))],notice,delay);
catch
  if ishandle(notice)
    delete(notice);
  end
end

set(0,'currentfigure',cf);


% --------------------------------------------------------------------
function classsetnotice(targfig)

%give class set name notice
if getappdata(targfig,'viewclasses');
  classset = getappdata(targfig,'viewclassset');
  mydataset = getdataset(targfig);
  plotby = getappdata(targfig,'plotby');
  if plotby == 0;               %if special plot mode, figure out which dim we're actually selecting on
    inds = getappdata(targfig,'axismenuindex');
    dim = inds{1}+1;
    plotby = 2-dim+1;
    if plotby < 1; plotby = 1; end
  end
  plotvs = 2-plotby+1;
  if plotvs<1; plotvs = 1; end
  
  %if plotvs is empty, use class labels from OTHER mode
  if isempty(mydataset.class{plotvs})
    frommode = plotby;
  else
    frommode = plotvs;
  end
  if isempty(mydataset.class{frommode,classset})
    lbl = '';  %do NOT show notice (hide it, in fact)
  else
    lbl = mydataset.classname{frommode,classset};
    if isempty(lbl)
      lbl = sprintf('#%i',classset);
    end
    lbl = ['Class Set: ' lbl];
  end
  showtempnotice(targfig,lbl);
else
  showtempnotice(targfig,'');
end

% --------------------------------------------------------------------
function timer_child_WindowButtonMotionFcn(varargin)
if isa(varargin{1},'timer') 
  fig = varargin{1}.userdata;
  if ishandle(fig)
    child_WindowButtonMotionFcn(varargin{1}.userdata,[],[],varargin{1}.userdata);
    stop(varargin{1});
    delete(varargin{1});
  end
end

% --------------------------------------------------------------------
function child_ResizeFcn(h, eventdata, handles, varargin)

fig = gcbf;
if getappdata(fig,'autosizemarkers')
  update;
else
  ch = findall(fig,'userdata','data');
  for j=1:length(ch);
    if strcmp(getappdata(ch(j),'plottype'),'density')
      
      %method 2: (re)start a timer
      tm = timerfindall('tag','redrawtimer');
      if isempty(tm)
        tm = timer;
        tm.tag = 'redrawtimer';
        tm.TimerFcn = @autoupdate;
      end
      stop(tm);
      tm.StartDelay = 0.5;
      set(tm,'userdata',fig);
      start(tm);      
      drawnow;
      break;
    end
  end
end
return
%(remainder disabled until future modification can solve 7.1/7.0 conflict)
% setappdata(gcbf,'in_resizefcn','true');
if strcmp(get(gcbf,'selectiontype'),'alt'); return; end
set(gcbf,'PaperPositionMode','auto');
[PlotGUItags(2) PlotGUItags(1)] = dockcontrols(gcbf,[],0);
% setappdata(gcbf,'in_resizefcn','');

%-------------------------------------
function autoupdate(varargin)
%auto-update associated with timer

if isvalid(varargin{1})
  figure(get(varargin{1},'userdata'))
end
drawnow;
update

% --------------------------------------------------------------------
function windowbuttonmotion_Callback
% Deal with changing of target statusbox pulldown menu

target = getappdata(gcbf,'target');
target = target(ishandle(target));

%hide figure if we discover there is no target
if isempty(target) & getappdata(gcbf,'iscontrolfigure')
  children = getappdata(gcbf,'children');
  children = children(ishandle(children));
  if isempty(children);
    set(gcbf,'visible','off'); 
    return; 
  end
end

cf = get(0,'currentfigure');
if ~isempty(target) & ~isempty(cf) & ~isempty(getappdata(cf,'controlby')) & strcmp(getappdata(cf,'figuretype'),'PlotGUI');
  findtarget(cf);
end;

% --------------------------------------------------------------------
function updatefigure(fig,fixmode)
%update frame positions and axes positions on figure

if nargin == 0;
  fig = gcf;                      %use current figure
end
if nargin < 2;
  fixmode = 2;
end

%get figure position
if getappdata(fig,'inUpdateFigure')
  %avoid recursive updatefigure calls caused by getting of position below
  return
end
origunits = get(fig,'units');             %save original units
set(fig,'units','pixels')
setappdata(fig,'inUpdateFigure',true); %flag to catch Matlab-induced recursion
try
  figpos   = get(fig,'position');
catch; end
setappdata(fig,'inUpdateFigure',false);

%get handle and frame info
handles = guidata(fig);                   %get handle info
groups = framegroups(handles);            %get frame group handles

%Get some reference points
set(handles.dataselectorframe,'units','pixels');
refframe = get(handles.dataselectorframe,'position');
offset   = refframe(1);     %make y-offset down from top the same as x-offset from left side of figure (current(1))
%which won't be changing and is set by initial figure setup
bottom   = figpos(4);   %default "bottom" of stack (used for Show All button decisions)

%Update fontsize:
try
  set(findall(allchild(fig),'-property','Fontsize'),'Fontsize',getdefaultfontsize)
catch
  disp('bad text size');
end

%make buttons frame invisible if no buttons are defined for it
if length(groups{3}) == 1;  %button group with only 1 handle means no buttons
  set(groups{3},'enable','off','visible','off');
else
  set(groups{3}(1),'enable','on','visible','on');

  set(setdiff(groups{3},getappdata(fig,'useritems')),'visible','on');

  buttonlist = findobj(groups{3}(2:end),'visible','on')';

  %make sure buttons are in correct order
  order = [];
  addindex = length(buttonlist);
  for j=1:length(buttonlist);
    myorder = getappdata(buttonlist(j),'buttonorder');
    if isempty(myorder)
      addindex = addindex+1;
      myorder  = addindex;
    end
    order(j) = myorder;
  end
  reorder(order) = 1:length(order);
  reorder(reorder==0) = [];
  buttonlist = buttonlist(reorder);

  if ~isempty(buttonlist);
    set(handles.buttonframe,'units','pixels');     %our units of use
    fpos = get(handles.buttonframe,'position');     %get the current frame position
    fpos(3) = figpos(3)-offset*2;
    set(handles.buttonframe,'position',fpos);

    %handle "select" button separately
    ind = 0;
    addrows = 0;
    sublist = [min(double(findobj(buttonlist,'string','Select'))) double(findobj(buttonlist,'userdata',1))'];
    if ~isempty(sublist);
      for h = sublist;
        ind = ind +1;
        [k,j] = ind2sub([1 100],ind);
        shift = 6*strcmp(get(h,'style'),'checkbox');
        pos = [fpos(1)+((fpos(3)-6)/(2-(length(buttonlist)==1)))*(k-1)+3+shift   fpos(2)+fpos(4)-1-25*(j) ...
          (fpos(3)-6)-1-shift   23];
        set(h,'units','pixels','position',pos);
      end
      buttonlist(ismember(buttonlist,sublist)) = [];  %remove from list
      addrows = j;
    end

    j = 0;
    ind = 0;
    if ~isempty(buttonlist)
      buttonstyle = get(buttonlist,'style');
      if ~iscell(buttonstyle); buttonstyle = {buttonstyle}; end
      for hind = 1:length(buttonlist);
        h = buttonlist(hind);
        ind = ind +1;
        if ~strcmp(buttonstyle{hind},'pushbutton') | length(buttonlist)==1;
          %not a button? make sure it is on its own line
          ind = ind+mod(ind+1,2);
          wide = 1;
          addafter = 1;
        elseif  mod(ind,2)==1 & (hind==length(buttonlist) ...
            | (hind<length(buttonlist) & ~strcmp(buttonstyle{hind+1},'pushbutton')))
          %odd number of buttons (and we're at end OR next object is not a
          %button)
          wide = 1;
          addafter = 0;
        else
          wide = 0;
          addafter = 0;
        end
        [k,j] = ind2sub([2 100],ind);
        shift = 6*strcmp(get(h,'style'),'checkbox');
        pos = [fpos(1)+((fpos(3)-3)/(2-(length(buttonlist)==1)))*(k-1)+3+shift   fpos(2)+fpos(4)-1-25*(j+addrows) ...
          (fpos(3)-6)/(2-wide)-(2-wide)*1.5-shift   23];
        set(h,'units','pixels','position',pos,'visible','on');
        ind = ind+addafter;
      end
    end
    set(handles.buttonframe,'units','pixels','position',[fpos(1)  fpos(2)+fpos(4)-25*(j+addrows)-4  fpos(3)  25*(j+addrows)+4])
  else
    set(groups{3}(1),'enable','off','visible','off');
    set(groups{3},'visible','off');
  end

end

groups = groups([1 4 3 2 5:end]);       %patch to make limits be below buttons
%run through frame groups, docking each to one above
for k = 1:length(groups);
  set(groups{k},'units','pixels')
  current = get(groups{k}(1),'position');  %get our current frame position
  current(~isfinite(current))=1;

  %   set(groups{k}(1),'position',[current(1:2) figpos(3)-offset*2 current(4)])   %adjust width of frame to figure width
  current(3) = figpos(3)-offset*2;
  set(groups{k}(1),'position',current)   %adjust width of frame to figure width

  if k == 1;  %Choose our target point for the top of the frame
    target = [figpos(3:4)-offset 1 1];    %relative to figure for first set - y offset
  else
    target = get(groups{k-1}(1),'position');   %relative to previous for all others
  end

  if figpos(4)>0;
    %     if strcmp(get(groups{k}(1),'enable'),'on');    %frame turned on, dock top to bottom one above
    %       moveby = 1+(target(2)-current(4)-current(2))./figpos(4);
    %     else    %otherwise, dock bottom to bottom of one above
    %       moveby = 1+(target(2)-current(2))./figpos(4);
    %     end
    %     remapfig([1 1 1 1],[1 moveby 1 1],fig,groups{k});
    if strcmp(get(groups{k}(1),'enable'),'on');    %frame turned on, dock top to bottom one above
      moveby = (target(2)-current(4)-current(2));
    else    %otherwise, dock bottom to bottom of one above
      moveby = (target(2)-current(2));
    end
    hpos = get(groups{k},'position');
    if iscell(hpos);
      hpos = cat(1,hpos{:});
    end
    hpos(:,2) = hpos(:,2)+moveby;
    for hind = 1:length(groups{k}); set(groups{k}(hind),'position',hpos(hind,:)); end
  end

  %handle widths
  itemstyle = get(groups{k},'style');
  for item = 2:length(groups{k})
    if strcmp(itemstyle(item),'popupmenu') | strcmp(itemstyle(item),'listbox') | groups{k}(item)==handles.colorbybtn;
      itempos = get(groups{k}(item),'position');
      itempos(3) = current(3)-itempos(1)-offset;
      %adjust for eslider width
      hasslider = getappdata(groups{k}(item),'eslider');
      if ~isempty(hasslider)
        es = getappdata(fig,'eslider');
        itempos(3) = itempos(3)-es.position(3)-2;
        es.position = [itempos(3)+22 itempos(2)+2 es.position(3) itempos(4)-4];
      end
      %assign object
      set(groups{k}(item),'position',itempos);
    end
  end
  if isfield(handles,'selectframe') && handles.selectframe==groups{k}(1);  %is this the selectframe?
    itempos = get(groups{k}(2:3),'position');
    itempos = cat(1,itempos{:});
    ratio = itempos(1,3)/(itempos(1,3)+itempos(2,3));  %width ratio
    itempos(1,3) = (current(3)-offset*4)*ratio;
    itempos(2,3) = (current(3)-offset*4)*(1-ratio);
    itempos(2,1) = itempos(1,1)+itempos(1,3)+offset;
    set(groups{k}(2),'position',itempos(1,:));
    set(groups{k}(3),'position',itempos(2,:));
  end

  %If this frame was visible, then use it's bottom position as the new bottom of stack
  if strcmp(get(groups{k}(1),'visible'),'on');
    current = get(groups{k}(1),'position');
    bottom = current(2);
  end
end
groups = groups([1 4 3 2 5:end]);       %patch to make limits be below buttons
% drawnow

%Now doc user items (all at once) to bottom of previous group
% (except those associated with the buttons frame (group 3))
useritems = setdiff(getappdata(fig,'useritems'),groups{3});
useritems = useritems(ishandle(useritems));
if ~isempty(useritems);
  units = get(fig,'units');
  for k = 1:length(useritems);
    set(useritems(k),'units',units);
    poss(k,:) = get(useritems(k),'position');
    isvisible(k) = strcmp(get(useritems(k),'visible'),'on');
  end

  if any(isvisible)   %something is visible
    top       = max(poss(isvisible,2)+poss(isvisible,4));   %find highest (visible) user item top
  else   %none are visible
    top       = min(poss(:,2));     %if none are visible, find the lowest point, and move that to be in line with "bottom"
  end
  poss(:,2) = poss(:,2) + bottom-top+1;   %move all items so that top matches bottom of other objects above

  for k = 1:length(useritems);
    set (useritems(k),'position',poss(k,:));
  end

  if any(isvisible)   %something is visible
    bottom    = min(poss(isvisible,2));    %new bottom is lowest point in user items
  end
end

%Uncomment next line to limit width of controls to control frame width
% figpos(3) = refframe(3)+offset*2;     %figure width = control frame width

if evriwindowstyle(fig)
  fixmode = 1;
end

need = -bottom+offset;      %calc how much we need to move by

if abs(need)>=1
  switch fixmode
    case 1         %keep length of window the same, resize the y-axis menu to fit in screen
      if resizeyaxismenu(handles,-need);
        updatefigure(fig,0);
      end
    case 2
      figpos(2) = figpos(2)-need;  %and set that to bottom and height
      figpos(4) = figpos(4)+need;
  end
end
if figpos(3)<1; figpos(3)=1; end
if figpos(4)<1; figpos(4)=1; end

if ~evriwindowstyle(fig)
  set(fig,'position',figpos);     %store new figure position
  set(fig,'resize','on');        % and allow resizing
end

pos = get(handles.dataselectorframe,'position');
fpos = get(fig,'position');
if (fpos(4)-(pos(2)+pos(4)))<0; updatefigure(fig); end

%reset figure units back to original units
set(fig,'units',origunits);


% ---------------------------------------------------------------------
function resetcontrols(oldh)
%resets position of all controls on a given plotgui controls figure

if nargin==0 | isempty(oldh);
  oldh = gcf;
end
[childfig,oldh] = findtarget(oldh);

newh = plotgui;
newhand = findobj(newh,'type','uicontrol');
oldhand = findobj(oldh,'type','uicontrol');
handmap = find(ismember(get(oldhand,'tag'),get(newhand,'tag')));
set(oldhand(handmap),{'position'},get(newhand,'position'))
set(oldh,'position',get(newh,'position'));
plotgui('updatefigure',oldh)
delete(newh);

% ---------------------------------------------------------------------
function findcontrols(fig,moveonly)
%input (moveonly) makes sure the controls are on-screen and does NOT bring
%the controls to the front

if nargin<2;
  moveonly = 0;
end

[childfig,fig] = findtarget(fig);

% if strcmp(getappdata(childfig,'in_resizefcn'),'true');
%   return;
% end

if ishandle(fig) & strcmp(get(fig,'type'),'figure') & fig ~= childfig & ~evriwindowstyle(fig)
  %make sure its on screen
  scrn = getscreensize;
  set(fig,'units','pixels');
  pos = get(fig,'position');
  pos = [max(min(pos(1),scrn(3)-pos(3)),scrn(1)) max(min(pos(2),scrn(4)-pos(4)-25),scrn(2)) pos(3:4)];
  set(fig,'position',pos);
  if ~moveonly; figure(fig); end
end


% ---------------------------------------------------------------------
function [offset,width,height] = controlsize(fig)
% returns size of PlotGUI controls (non userdefined ones)

[targfig,fig] = findtarget(fig);
updatefigure(fig);
handles = guidata(fig);

refframe1 = get(handles.dataselectorframe,'position'); 
refframe2 = get(handles.buttonframe,'position'); 

offset = refframe1(1);      %selector left
width = refframe1(3);       %selecotr width

height = refframe1(2)+refframe2(4)-refframe2(2);    %selector bottom + height - buttons bottom

% ---------------------------------------------------------------------
function groups = framegroups(varargin)
% Return cell of handles organized by functional group or vector of handles for a single group
% USAGE:  groups = PlotGUI('framegroups',handles)
%   < or >    groups = PlotGUI('framegroups',group_number,handles);
%   < or from another subfunction > 
%         groups = framegroups(handles);
%         groups = framegroups(group_number,handles);
%  where group_number is an optional input to return ONLY one group's handles
%  handles is also optional. Current figure handles are used if handles is not passed

%parse input variables
handles = [];
group_number = [];
for k = 1:nargin;
  if isstruct(varargin{k});
    handles = varargin{k};
  else
    group_number = varargin{k};
  end
end

%didn't supply handles? get them from the current figure
if isempty(handles);
  if ~strcmp(getappdata(gcf,'figuretype'),'PlotGUI');
    error(['Not a valid PlotGUI figure']);
  end
  handles = guidata(gcf);
end

%Define frame groups (first handle in group is frame)
% DataSelectorFrame (pull-down menus to select what to plot)
% groups = {[handles.dataselectorframe, handles.xaxismenu, handles.yaxismenu, handles.zaxismenu, handles.plotbtn, handles.plotstylebtn, handles.autobtn, ...
groups = {[handles.dataselectorframe, handles.xaxismenu, handles.yaxismenu, handles.zaxismenu, handles.plottypebtn, handles.plotbtn, handles.autobtn, ...
           handles.statusbox, handles.xaxischooselabel, handles.yaxischooselabel, handles.zaxischooselabel, handles.colorbybtn]};    
% LimitsFrame (confidence-limts checkbox and value)
groups(2) = {[handles.limitsframe, handles.limitsbox, handles.limitsvalue, handles.limitslabel]};
% ButtonFrame (extra buttons)
buttonlist = getappdata(handles.PlotGUI,'buttonhandles');
if iscell(buttonlist); buttonlist = [buttonlist{:}].'; end
buttonlist = buttonlist(:)';    %row-vectorize
groups(3) = {[handles.buttonframe; intersect(findall(handles.PlotGUI),buttonlist(:))]};   %intersect to make sure the buttons still exist on this figure
groups(4) = {[handles.selectframe, handles.select, handles.selecttool]};
if ~isempty(group_number);
  if max(group_number) > length(groups) | min(group_number) < 1;
    error(['group_number must be  > 0 and  < ' num2str(length(groups))])
  end
  groups = [groups{group_number}];
end


% --------------------------------------------------------------------
function ison = limits(varargin)
% Turn the confidence limits tools on or off.
%I/O: limits(mode,fig)
%I/O: limits(mode,fig,silent)
%  where mode is 'on' to turn ON confidence limits access, 'off' to turn access OFF 
%   or absent to toggle the access and fig is the plotgui figure to change (both are optional)
%   if silent flag is true, updatefigure will not be called (unless a
%   target figure change is noted on the controls)

fig = [];
mode = [];
if nargin == 1;
  if ~isa(varargin{1},'char');
    fig = varargin{1};
  else
    mode = varargin{1};
  end
end
if nargin >= 2;
  mode = varargin{1};
  fig = varargin{2};
end
if nargin>=3;
  silent = varargin{3};
else
  slient = false;
end
  
if isempty(fig);
  fig = gcf;
end;

if ~strcmp(getappdata(fig,'figuretype'),'PlotGUI');
  error(['Not a valid PlotGUI figure']);
end

[targfig,fig] = findtarget(fig);

handles = guidata(fig);
limitsgroup = framegroups(2,handles);
ison = strcmp(get(limitsgroup(1),'enable'),'on');

if nargout==1 & isempty(mode)
  return;
end

%if they didn't say on or off, just toggle based on whether or not limits is enabled
if isempty(mode);
  turnon = ~ison;
else
  turnon = strcmp(mode,'on');
end

%if we're actually making a CHANGE
if (turnon & ~ison) | (~turnon & ison)
  
  if turnon;
    set(framegroups(2,handles),'enable','on','visible','on');
  else
    set(framegroups(2,handles),'enable','off','visible','off');
    %     set(handles.limitsbox,'value',0);     %turn off checkbox
    %     setappdata(targfig,'showlimits',0);   %and clear the appdata value also
  end
  
  if ~silent
    updatefigure(fig);
  end
  
end


% --------------------------------------------------------------------
function zaxis(varargin)
% Turn the Z-axis on or off. Call using:
%  PlotGUI('zaxis',mode,fig)
%  where mode is 'on', 'off' or absent to toggle the z axis mode
%  and fig is the plotgui figure to change (both are optional)
%  Turning on the zaxis automatically turns on the yaxis

fig = [];
mode = [];
if nargin == 1;
  if ~isa(varargin{1},'char');
    fig = varargin{1};
  else
    mode = varargin{1};
  end
end
if nargin == 2;
  mode = varargin{1};
  fig = varargin{2};
end

if isempty(fig);
  fig = gcf;
end;

if ~strcmp(getappdata(fig,'figuretype'),'PlotGUI');
  error(['Not a valid PlotGUI figure']);
end

[targfig,fig] = findtarget(fig);

handles = guidata(fig);

%save original units
origunits = get(fig,'units');
%and set units to something we have references for
set(fig,'units','pixels')

status = getappdata(handles.zaxismenu,'PlotGUIenabled');
if isempty(status); status = 'on'; end

%if they didn't say on or off, just toggle based on whether or not zaxismenu is enabled
if isempty(mode);
  h = ~strcmp(status,'on');
else
  h = strcmp(mode,'on');
end

if h;
  set([handles.zaxismenu handles.zaxischooselabel],'enable','on')
else
  set([handles.zaxismenu handles.zaxischooselabel],'enable','off')
end


% --------------------------------------------------------------------
function yaxis(varargin)
% Turn the Y-axis on or off. Call using:
%  PlotGUI('yaxis',mode,fig)
%  where mode is 'on', 'off' or absent to toggle the y axis mode
%  and fig is the plotgui figure to change (both are optional)
%  Turning off yaxis also automatically turns off zaxis

fig = [];
mode = [];
if nargin == 1;
  if ~isa(varargin{1},'char');
    fig = varargin{1};
  else
    mode = varargin{1};
  end
end
if nargin == 2;
  mode = varargin{1};
  fig = varargin{2};
end

if isempty(fig);
  fig = gcf;
end;

if ~strcmp(getappdata(fig,'figuretype'),'PlotGUI');
  error(['Not a valid PlotGUI figure']);
end

[targfig,fig] = findtarget(fig);

handles = guidata(fig);

%save original units
origunits = get(fig,'units');
%and set units to something we have references for
set(fig,'units','pixels')

status = getappdata(handles.yaxismenu,'PlotGUIenabled');
if isempty(status); status = 'on'; end

%if they didn't say on or off, just toggle based on whether or not yaxismenu is enabled
if isempty(mode);
  h = ~strcmp(status,'on');
else
  h = strcmp(mode,'on');
end

if h;
  setpd([handles.yaxismenu handles.yaxischooselabel],'enable','on')
else
  setpd([handles.yaxismenu handles.yaxischooselabel],'enable','off')
end

%---------------------------------------------------------------------
function success = resizeyaxismenu(handles, offset)
% Resize the yaxismenu (and other items below it) a given
%  amount of pixels (offset). updatefigure should be called after
%  this routine
% Returns 1 if resize was successful, 0 if not. 

success = 1;    %successful unless we find otherwise

minheight = 61;
if ~isstruct(handles)
  handles = guidata(handles);
end

menupos = get(handles.yaxismenu,'position'); 

%check for too-small menu
if menupos(4)+offset < minheight;
  offset = minheight - menupos(4);   %make minimum height
  success = 0;                %and note lack of success
end
setpd(handles.yaxismenu,'position',menupos(1:4)+[0 -offset 0 +offset]); 

for item = [handles.zaxismenu handles.zaxischooselabel ...
      handles.plotbtn handles.colorbybtn handles.autobtn handles.plottypebtn]
%       handles.plotbtn handles.plotstylebtn handles.autobtn]
  set(item,'units','pixels')
  get(item,'position');
  set(item,'position',ans+[0 -offset 0 0])
end;

ans = get(handles.dataselectorframe,'position');
set(handles.dataselectorframe,'position',ans+[0 -offset 0 +offset])

% ---------------------------------------------------------------------
function varargout = new(varargin)
% alternate entry point for PlotGUI
% just calls update

if nargout == 0;
  update('new',varargin{:});
else
  [varargout{1:nargout}] = feval('update','new',varargin{:}); % FEVAL switchyard
end


% ---------------------------------------------------------------------
function drop(h,eventdata,handles,data,varargin)
% drop(h,eventdata,handles,data)

[targfig,fig] = findtarget(h);
update('figure',targfig,data)

% ---------------------------------------------------------------------
function varargout = update(varargin)
% Main entry point for PlotGUI
% Plot data and/or set options

% - - - - - - - - - - - - - - - - - -
%lists of properties (note: real properties are all lower case)
%These properties only get used when "duplicate" a plotgui figure.
valid_figprops = {'HandleVisibility','MenuBar','Name','NumberTitle','Position',...
    'Resize','Tag','ToolBar','Units','UserData','Visible','WindowStyle'} ;  %can be set through plotgui by user
readonly_properties = {'Selection','FigureType','DataSet','Target'};

persistent options_properties

if isempty(options_properties)
  options_properties  = fieldnames(defaultoptions);
end

valid_properties    = {'Children','ControlBy','Figure','TimeStamp','functionname',...
    options_properties{:}, readonly_properties{:}, valid_figprops{:}};
valid_modes = {'Image','New','Unfold','Rows','Cols','Columns','Summary','Background','Quiet'};
% - - - - - - - - - - - - - - - - - -

forceredraw = 0;
background = 0;  %bring figure to front unless caller asks for "background update" mode

%Start by parsing
data = cell(0);     %initialize cell to hold numerical input data
buttons = cell(0);
%---------------------
%defalut buttons here!
% buttons{end+1} = {'tag','select','style','togglebutton',...
%     'string','Select','ToolTipString','Make selection in plot. Use [Shift]-click to add to current selection.','callback','plotgui(''makeselection'');'};
%---------------------
options = [];
modes = [];

% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%parse input arguments
arg = 1;
while arg <= nargin;
  switch class(varargin{arg});
    
    case 'char'
      if any(size(varargin{arg}) == 1);   %not a character array?
        %property keyword or mode keyword 
        
        if any(strcmpi(varargin{arg},valid_properties));
          if any(strcmpi(varargin{arg},readonly_properties));
            error(['Attempted to set read-only property ' varargin{arg}]);
          end
          %its a valid property... save it
          if arg+1 > nargin;
            error(['Unmatched Property / Value pair (end of list)']);
          end
          options = setfield(options,lower(varargin{arg}),varargin{arg+1});
          arg = arg+1;  %skip over value argument
          
        elseif any(strcmpi(varargin{arg},valid_modes));
          %Valid mode? just assign as a 1 in the options 
          modes = setfield(modes,lower(varargin{arg}),[1]);
          
        else
          error(['Unrecognized Property or Mode Keyword ''' varargin{arg} ''''])
        end
        
      else      %multiple line string?, must be data not keyword
        data{end+1} = varargin{arg};
      end
      
    case 'struct'
      %validate options structure and copy to options
      for k = fieldnames(varargin{arg})';
        if ~any(strcmpi(char(k),valid_properties)) & ~any(strcmpi(char(k),valid_modes));
          error(['Unrecognized Property keyword ''' char(k) ''' in options structure'])
        end
        if any(strcmpi(char(k),valid_properties));
          options = setfield(options,lower(char(k)),getfield(varargin{arg},char(k)));  
        else
          modes = setfield(modes,lower(char(k)),[1]);
        end
      end
      
    otherwise    %data to be plotted/etc
      
      if ~isa(varargin{arg},'cell');
        data{end+1} = varargin{arg};
      else
        data(end+1:end+length(varargin{arg})) = varargin{arg};
      end
      
  end
  arg = arg+1;    %move to next argument
end
%done parsing...

% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%find the figure to use (if not specified in command line)
if isfield(options,'figure');     %did they give us one on the command line?
  
  forceredraw = 1;
  %more than one figure # specified? Do this command (whatever it was) for all figures listed
  if length(options.figure) > 1;
    options.timestamp = now;          %keep us from updating lineage twice
    for j = 1:length(options.figure);
      if ishandle(options.figure(j))
        figtype = getappdata(options.figure(j),'figuretype');
        oldts = getappdata(options.figure(j),'timestamp');
        if isempty(oldts) | (isa(oldts,'double') & options.timestamp ~= oldts);
          if strcmp(figtype,'PlotGUI');
            update(varargin{:},'figure',options.figure(j),'timestamp',options.timestamp);   
          elseif strcmp(figtype,'EditDS');
            editds('update',options.figure(j),options.timestamp,[],data);  
          end
        end
      end
      %note, although varargin includes a "figure" command (the one we're dealing with in this loop),
      % the inclusion of a second "figure" command on this update line will superseede the first one.
    end
    if nargout == 1; varargout = {options.figure}; end
    return        %and exit
  else
    figtype = getappdata(options.figure,'figuretype');
    if strcmp(figtype,'EditDS');
      if ~isfield(options,'timestamp'); options.timestamp = now; end
      editds('update',options.figure,options.timestamp,[],data);  
      return
    end
  end
  
  fig = options.figure;
  if ~ishandle(fig);
    figure(fig);
  end
  options = rmfield(options,'figure');
else      %nope, See if there is a current figure
  fig = get(0,'CurrentFigure');         
  if strcmp(get(fig,'visible'),'off'); fig = []; end     %don't use if invisible
  if strcmp(get(fig,'tag'),'modelselectorgui') || strcmp(get(fig,'tag'),'eigenworkspace')
    %Don't take over a modelselectorgui. Modelselectorgui sets itself as
    %CurrentFigure manually (even though integerhandle is off) so we need
    %to not set it as a plotgui figure.
    %Also don't use browse window, this can happen when data is dropped on
    %the browrse shortcut icon.
    fig = [];
  end
end

if isempty(fig) | isfield(modes,'new');  %if there wasn't a figure or we were told "new"
  if isfield(options,'position');
    addfigprop = {'position' options.position};
  else
    addfigprop = {};
  end
  fig = newfigure(addfigprop{:});     %create a new target figure
  figpos = get(fig,'position');
  oldpos = positionmanager(fig,'plotgui','get');
  newpos=[1,1,figpos(1,3),figpos(1,4)];
  if ~isempty(oldpos)
    newpos(1,1:2)= oldpos(1,1:2);
  else
    figpos = get(fig,'position');
    newpos(1,1:2) = figpos(1,1:2);
    oldpos = figpos;
  end
  set(fig,'position',newpos);
  positionmanager(fig,'plotgui','onscreen');
end

if ~strcmp(getappdata(fig,'figuretype'),'PlotGUI');   %not already a plotgui figure
  assigndefaults(fig);        %assign default properties
end


% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%CONTROLBY: handle assignment of controlby figure

if isfield(options,'controlby');
  if ~isempty(options.controlby);
    if prod(size(options.controlby)) ~= 1 | ~ismember(options.controlby,allchild(0));    %vector or not a valid handle?
      error(['ControlBy must be single, valid figure handle']);
    end
    if ~strcmp(getappdata(fig,'figuretype'),'PlotGUI');     %Valid PlotGUI figure?
      error(['ControlBy must be a PlotGUI figure']);
    end
    while ~isempty(getappdata(options.controlby,'controlby')) & isfinite(getappdata(options.controlby,'controlby'));
      options.controlby = getappdata(options.controlby,'controlby');    %adopt controlby parent if user specified a controled figure
    end
    if ~isempty(getappdata(fig,'target'));    %do we have a target?
      error(['Currently a controlling figure. Cannot set ControlBy'])
    end
    
    %make it active
    setappdata(options.controlby,'children',union(getappdata(options.controlby,'children'),fig));     %and set as a child of controlfig
    
  else    
    if ~isempty(getappdata(fig,'controlby'));
      controlfig = getappdata(fig,'controlby');
      setappdata(controlfig,'children',setdiff(getappdata(controlfig,'children'),fig));  %and remove this as a child of that parent
      setappdata(controlfig,'target',[nan]);     %set controlby figure's target NOT to us
      assigngetfocus(fig,0);            %turn off GetFocus callback
    end
  end
  
  setappdata(fig,'controlby',options.controlby); 
  options = rmfield(options,'controlby');
  
end

%Now, deal with stored controlby status (may be new status, may be existing one)
if ~isempty(getappdata(fig,'controlby'));
  assigngetfocus(fig);              %turn on GetFocus callbacks
end

% drawnow;  %here is works in 7.0 but NOT in 7.1
[targfig,fig] = findtarget(fig);      %get target figure (if any)
% drawnow;  %here it works in neither 7.1 nor 7.0

if targfig == fig;    %don't plot on a controlby figure
  targfig = newfigure;
  assigndefaults(targfig);        %assign default properties
  assigngetfocus(targfig);        %turn on GetFocus callbacks
end

handles = guidata(fig);             %get handle info from [control] figure

% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%MODES: define special mode objects, buttons, etc.
% These modes can set fields in options or buttons or directly set appdata properties
% The input data can also be sorted out based on expected inputs
% The modes activated will be stored in the [target-]figure in appdata "modes"
if ~isempty(modes);
  for k = fieldnames(modes)';
    switch char(k);     %NOTE: will be lower case by this point      
      case 'new'
        %NOTE: NEW mode is handled above in the creation of a new figure so we need no code here
        modes = rmfield(modes,'new');  %except to remove the field name!
      case 'background'
        modes = rmfield(modes,'background');
        background = 1;
      case 'unfold'
        %unfold handled in data section
      case 'image'
        %image handled in data section      
      case {'rows','cols','columns'}
        options.plotby = char(k);
      case {'summary'}
        options.plotby = 0;
      case 'quiet'
        %nothing
      otherwise
        disp([char(k) ' mode not yet enabled'])
    end
  end
  setappdata(targfig,'modes',modes);      
end


% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%UICONTROLS : try to create uicontrols specified in uicontrol field
if isfield(options,'uicontrol') & ~isempty(options.uicontrol);
  if ~isstruct(options.uicontrol);
    error('UIControl option must be a structure')
  end
  visibleitems = [];
  for k = fieldnames(options.uicontrol)';
    %get properties and values to set
    uiprops = getfield(options.uicontrol,char(k));
    if ~iscell(uiprops);
      error(['UIControl settings must be a cell of property/value pairs (object: ''' char(k) ''')'])
    end
    if mod(length(uiprops),2) ~= 0;
      error(['UIControl settings for ' char(k) ' does not have matched pairs of properties & values'])
    end
    
    useritems = getappdata(targfig,'useritems');
    useritemtags = get(useritems,'tag');
    if ~isempty(useritemtags) & ~iscell(useritemtags); useritemtags={useritemtags}; end
    
    if any(strcmpi('position',uiprops(1:2:end))) | ismember(char(k),useritemtags);
      
      %position specified or already exists?, do a custom object
      
      if isempty(useritemtags) | ~ismember(char(k),useritemtags)
        h = uicontrol(fig,'tag',char(k),'visible','off');
        setappdata(fig,'useritems',unique([getappdata(fig,'useritems'),h]));   %store handle in controls
        setappdata(targfig,'useritems',unique([getappdata(targfig,'useritems'),h]));   %store handle in target too
      else
        h = useritems(strcmp(char(k),useritemtags));
      end
      set(h,'visible','on');
      visibleitems(end+1) = h;
      ucind = strmatch('updatecallback',uiprops(1:2:end));
      if ~isempty(ucind)
        %user supplied an "updatecallback" - set that as appdata and remove
        ucind = (ucind*2)+(-1:0);  %expand to include property and value
        setappdata(h,uiprops{ucind});
        uiprops(ucind) = [];  %drop from list
      end        
      set(h,uiprops(1:2:end),uiprops(2:2:end));      %set properties as specified
      
    else      %No position? add it to list of automatically created button-frame buttons 
      
      buttons{end+1} = [uiprops {'tag' char(k)}];
      
    end
  end
  set(setdiff(getappdata(fig,'useritems'),visibleitems),'visible','off');
  updatefigure(fig);
  dockcontrols(fig);
else
  %fix for 2008a resize problem
  set(setdiff(getappdata(fig,'useritems'),getappdata(targfig,'useritems')),'visible','off');
end


% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%FIGURE PROPERTIES: handle figure property fields in options structure
% check to see if any of the valid figure properties are present in the options structure
% Note: valid_figprops may contain uppercase characters, but option field
% MUST be all lower-case (i.e. user must pass field name in lower case)
options_figprops = [];
if ~isempty(options)
  hasfigprops = ismember(lower(valid_figprops),lower(fieldnames(options)));
  if any(hasfigprops)
    for k = valid_figprops(hasfigprops);
      if isfield(options,lower(char(k)));
        try
          set(targfig,char(k),options.(lower(char(k))));   %if we find the field, try setting it
          options_figprops.(char(k)) = options.(lower(char(k)));   %store for propogation to child plots
        catch
          disp(lasterr);
        end
        options = rmfield(options,lower(char(k)));
      end
    end
  end
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%CHECK OPTIONS: validate all fields which are left in options
options = validateoptions(options,fig,targfig);

% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%PLOTBY: test for change in plotby
if isfield(options,'plotby') & ~background & getappdata(targfig,'plotby')~=options.plotby;
  forceredraw = 1;
  setappdata(targfig,'axismenuvalues',cell(1,3)); %clear STORED axismenuvalues (old selections may not be valid)
  setappdata(targfig,'axismenuindex',cell(1,3)); %clear STORED axismenuvalues (old selections may not be valid)
  %(might be set by options in a moment)
  for oneaxis = findobj(targfig,'type','axes')';
    setappdata(oneaxis,'axismenuvalues',cell(1,3)); %clear STORED axismenuvalues (old selections may not be valid)
    setappdata(oneaxis,'axismenuindex',cell(1,3)); %clear STORED axismenuvalues (old selections may not be valid)
  end
  if options.plotby==0 & ~isfield(options,'axismenuvalues')
    if ~isempty(data)
      if iscell(data);
        if isshareddata(data{end})
          ncols = size(data{end}.object,2);
        else
          ncols = size(data{end},2);
        end
      else
        if isshareddata(data)
          ncols = size(data.object,2);
        else
          ncols = size(data,2);
        end
      end
    else
      ncols = size(getobjdata(targfig),2);
    end
    if ncols==1
      options.axismenuvalues = {2 2 0};
    else
      options.axismenuvalues = {1 2 0};
    end
  end
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%AXISMENUVALUES: if manually setting values we must redraw (to look up new indices)
if (isfield(options,'axismenuvalues') & any(cellne(getappdata(targfig,'axismenuvalues'),options.axismenuvalues)))...
    | (isfield(options,'axismenuindex') & any(cellne(getappdata(targfig,'axismenuindex'),options.axismenuindex)));
  forceredraw = 1;
  currentaxes = findaxes(targfig);
  if ~isempty(currentaxes) & strcmp(get(currentaxes,'tag'),getappdata(targfig,'targetaxestag'))
    setappdata(currentaxes,'axismenuvalues',cell(1,3))
    setappdata(currentaxes,'axismenuindex',cell(1,3))
  end
  
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%STORE OPTIONS: store options structure into appdata fields
if ~isempty(options); 
  setappdatas(targfig,options); 
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%BUTTONS: try to create buttons/controls in button frame
if ~isempty(buttons);
  %get current list of buttons
  buttonlist = getappdata(fig,'buttonhandles');
  if isempty(buttonlist); buttonlist = cell(0); end
  buttonlist = buttonlist(ishandle([buttonlist{:}]));  %drop non-existant items
  
  %create all the objects first
  for k = 1:length(buttons);
    tagindex = find(strcmp('tag',buttons{k}));
    if ~isempty(tagindex);    %did they provide a tag?
      matchedbutton = strcmp(buttons{k}{tagindex+1},get([buttonlist{:}],'tag'));
      if ~any(matchedbutton);
        h = uicontrol(fig);                               %create control
      else
        h = buttonlist{matchedbutton};              %get handle of existing button
      end
    else
      h = uicontrol(fig);           %create it (no others exists yet)
    end
    setappdata(h,'buttonorder',k)
    
    ucind = strmatch('updatecallback',buttons{k}(1:2:end));
    if ~isempty(ucind)
      %user supplied an "updatecallback" - set that as appdata and remove
      ucind = (ucind*2)+(-1:0);  %expand to include property and value
      setappdata(h,buttons{k}{ucind});
      buttons{k}(ucind) = [];  %drop from list
    end
    set(h,buttons{k}(1:2:end),buttons{k}(2:2:end));   %assign properties
    
    if strcmp(get(h,'string'),'Select')
      %if this is the Select button, add a context menu (based on the
      %selection tools menu)
      set(h,'uicontextmenu',selecttoolmenu(fig));
    end
    
    if ~any(strcmpi('BackgroundColor',buttons{k}(1:2:end)));
      set(h,'BackgroundColor',get(handles.plotbtn,'BackgroundColor'));
    end
    
    %add handle to list of handles in buttonframe
    if isempty(buttonlist) | ~any([buttonlist{:}] == h);   %not already in list?
      buttonlist{end+1,1} = h;
    end
    
    setappdata(fig,'useritems',unique([getappdata(fig,'useritems'),h]));   %store handle in controls
    setappdata(targfig,'useritems',unique([getappdata(targfig,'useritems'),h]));   %store handle in target too
    
  end
  setappdata(fig,'buttonhandles',buttonlist);
  drawnow;
  updatefigure(fig);
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%Verify family links
validatefamily(targfig)

% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%DATA: Now figure out what to do with the data
if ~isempty(data)
  
  if prod(size(data)) > 1;
    for j = 1:length(data); dclass{j} = class(data{j}); end      %find classes of data objects
    datasetpos = find(strcmp('dataset',dclass));                    %find which are datasets (if any)
    if length(datasetpos) > 1; error('Only one data set object can be passed'); end
    if length(datasetpos) == 1;
      data = data([datasetpos 1:datasetpos-1 datasetpos+1:end]);    %reorder with the dataset at front
    end
  end
  
  if ~isa(data{1},'dataset');   %not a dataset?
    if prod(size(data{1})) == 1 %& ishandle(data{1}) & ~isempty(getappdata(data{1},['dataset'])); %Got a valid UIControl handle?
      if ishandle(data{1})
        warning('EVRI:PlotGUIHandle','Handle passed to PlotGUI. Stack to follow:');
        disp(encode(dbstack))
        mylink = getappdata(data{1},'linkeddata');
        data{1} = setobjdata(targfig,mylink);
      else
        %Add data here if source ID was used. Data will be "added" again
        %below.
        data{1} = setobjdata(targfig,data{1});
        mylink = [];
      end
      
    else
      %no dataset object and not a handle/id
      if length(data)>1;
        %more than one input, try 
        if length(data)==2 & any(size(data{1})==1)...
            & any(length(data{1})==size(data{2}));       % inputs are (vector,something_else)?
          
          data([1 2]) = data([2 1]);  %swap 1 and 2
          try
            data{1} = dataset(data{1});       
          catch
            %deal with error below when we try again...
          end
          
          if isa(data{1},'dataset');  %assign axis info if we made a dataset
            %assign provided x-values to appropriate axis
            xdim    = max(find(size(data{1}.data)==length(data{2})));
            data{1}.axisscale{xdim} = data{2};
            
            %force plotby to be the dim OPPOSITE the one we're doing
            plotby = 2-xdim+1;
            if plotby < 1; plotby = 1; end
            setappdata(targfig,'plotby',plotby)
          end
          
        end
      end
      
      %try to make a dataset of the provided info
      if ~isa(data{1},'dataset');
        try
          data{1} = dataset(data{1});       
        catch
          drawnow;
          erdlgpls('Unable to plot provided data','PlotGUI');
          data{1} = dataset;
        end
      end
    end
  end
    
  %do we need to do anything special with the data RE images?
  if (isfield(modes,'unfold')|isfield(modes,'image')) & size(data{1},2)>1;
    for j = 1:length(size(data{1}));
      sz{j} = size(data{1},j);
    end
    if length(sz)<3; sz{3}=1; end;
    data{1} = dataset(reshape(data{1}.data,sz{1}*sz{2},sz{3:end}));
    setappdata(targfig,'asimage',[sz{1:2}])
  end

  %If this isn't apparently the same dataset, force redraw of controls
  oldds = getobjdata(targfig);
  if isempty(oldds) | ~isa(oldds,'dataset') | ~isa(data{1},'dataset') | ~all(oldds.moddate==data{1}.moddate)
    forceredraw = 1;
  end
  
  setobjdata(targfig,data{1});
  
  mydataset = getdataset(targfig);
  if ~ishandle(targfig); return; end
  if isinf(getappdata(targfig,'plotby'))
    %inf? (default plotby setting)
    if ndims(mydataset)<3
      if size(mydataset,1)==1
        plotby = 1;
      else
        plotby = 2;
      end
      setappdata(targfig,'plotby',plotby);
    end
  end
  if getappdata(targfig,'plotby') > ndims(mydataset);
    setappdata(targfig,'plotby',ndims(mydataset));     %don't allow plotby > ndims of new data
  end
  
end

mydataset = getdataset(targfig);
%MORE: do we need to do anything special with the data RE images?
if strcmp(mydataset.type,'image') & ~isempty(mydataset.imagemode) & mydataset.imagemode==1
  %NOTE: This will keep the user from manually setting a new asimage size
  %  we might want to allow the user to resize at some point?
  setappdata(targfig,'asimage',mydataset.imagesize);
  if isfield(options,'asimage');
    options.asimage = mydataset.imagesize;
  end
  forceredraw = 1;
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%ASIMAGE: handle the special asimage mode
if ~isempty(getappdata(targfig,'asimage'))
  
  asimage = getappdata(targfig,'asimage');
  mydataset = getdataset(targfig);
  %Check if its valid (i.e. data is there AND is 2-way AND asimage product is = dim 1 size)
  if isempty(mydataset) | isempty(mydataset.data) | size(mydataset.data,1) ~= prod(asimage) | ndims(mydataset)>2; %dims don't add up?
    setappdata(targfig,'asimage',[]);     %invalid, clear it
    asimage = [];
  end
  
  if strcmp(mydataset.type,'image') & ~isempty(mydataset.imagesize) & ~isempty(asimage) & ~all(mydataset.imagesize==asimage);
    asimage = mydataset.imagesize;
    setappdata(targfig,'asimage',asimage);     %overwrite any user-defined value with hard-coded size
  end
  
  if ~isempty(asimage) & getappdata(targfig,'plotby') > 1;
    if isfield(options,'asimage');   %they just SET asimage
      forceredraw = 1;
      setappdata(targfig,'axismenuvalues',cell(1,3));     %clear STORED axismenuvalues (old selections may not be valid)
    end
    setappdata(targfig,'plotby',2);                     %force plotby 2 mode with asimage mode
  end
  
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - -
%Other stuff
if isloaded(fig)
  axismenuvalues = getappdata(targfig,'axismenuvalues');
  axismenuindex = getappdata(targfig,'axismenuindex');
  if forceredraw | all(~cellne(cell(size(axismenuvalues)),axismenuvalues)) | all(~cellne(cell(size(axismenuindex)),axismenuindex));
    setappdata(fig,'target',[]);          %force update of controls in plotds
    findtarget(targfig);                %force update of controls (this is our first time through with this figure)
  end
  plotds(targfig,background);                        %plot data
  handles = guihandles(fig); guidata(fig, handles);             %update handles list
else
  %note plotds will do this too, so we only have to do this if we DON'T
  %call plotds
  handles = guihandles(fig); 
  guidata(fig, handles);             %update handles list
  updatefigure(fig);     %update view of uicontrols on figure
end

%Update dynamic menus
dynamicmenubuild(targfig,handles)

% - - - - - - - - - - - - - - - - - - - - - - - - - - -

if nargout == 1; 
  varargout{1} = targfig; 
end


%------------------------------------------------------
function options=validateoptions(options,fig,targfig);
% VALIDATEOPTIONS makes certain that all fields of options are valid
%  (to the extent we can tell) We know they are valid properties, but check
%  classes and sizes, etc.

% if nargin < 2; fig = gcf; end
% if nargin < 3; targfig = fig; end
% if nargin < 1; error('Must provide options structure'); end

if isempty(options); return; end  %no error if it is just empty
if ~isa(options,'struct'); error('Options must be a structure'); end

Fname = 1; Fclass = 2; Fsizemin = 3; Fsizemax = 4; Fvalue = 5;
%     Field Name              Class      min max     expected values
flds = {
  'AxisMenuIndex',            'cell',     0, 3,      [];
  'AxisMenuValues',           'cell',     0, 3,      []; 
  'AxisMenuEnable',           'double',   2, 3,      [0 1]; 
  'AxisAutoInvert',           'double',   0, 1,      [-1 0 1];
  'AutoSizeMarkers',          'double',   0, 1,      [0 1];
  'BrushWidth',               'double',   0, 1,      [0:100];
  'Children',                 'double',   0, 50,     'figure';
  'ClassSymbol',              '',         0, 9,      [];
  'ClassSymbolSize',          'double',   0, 1,      [];
  'SymbolSize',               'double',   0, 1,      [];
  'LineWidth',                'double',   0, 1,      [];
  'ClassColorMode',           'char',     0, 1024,   [];
  'ClassFaceColor',           'double',   0, 1,      [0 1];
  'connectclassmethod',       '',         0, 25,      connectclasslist;
  'connectclassitems',        'double',   0, 1024    [];
  'connectclasslimit',        'double',   1, 1,      [];
  'CloseGUICallback',         'char',     0, 1024,   [];
  'ControlBy',                'double',   0, 1,      'figure';
  'Figure',                   'double',   1, 1,      'figure';
  'findpeakswidth',           'double',   0, 1,      [];
  'ConfLimits',               'double',   0, 1,      [0:1];
  'labelwithnumber',          '',         0, 4,      {'auto' 'on' 'off'};
  'LineStyle',                'char',     0, 15,     [];
  'LimitsValue',              'double',   0, 10,     [];
  'NoLoad',                   'double',   0, 1,      [0 1];
  'NoSelect',                 'double',   0, 1,      [0 1];
  'NoInclude',                'double',   0, 1,      [0 1];
  'PlotBy',                   '',         1, 20,     'plotby';
  'PlotType',                 'char',     0, 512,    [{'none',''} plotguitypes];
  'AutoMonotonic'             'double',   0, 1,      [0 1];
  'SelectionMode',            'char',     0, 8,      {'none','x','xs','y','ys','lasso','rbbox','paint','polygon','nearest','nearests','circle','ellipse'};
  'SelectionMarker',          'char',     0, 15,     [];
  'ShowControls',             'double',   0, 1,      [0 1];
  'ShowLimits',               'double',   0, 1,      [0 1];
  'SlabColorContrast',        'double',   1, 1,      [];
  'SlabColorMode',            'char',     0, 512,    [];
  'Status',                   'char',     0, 512,    [];
  'UseSpecialMarkers',        'double',   1, 1,      [0 1];
  'ValidPlotBy',              'double',   0, 20,     [0:20];
  'VsIndex',                  'double',   0, 2,      [0 1];
  'ViewAxisLines',            'double',   2, 3,      [0 1];
  'ViewDiag',                 'double',   1, 1,      [0 1];
  'ViewTable',                'double',   1, 1,      [0 1];
  'ViewAutoContrast',         'double',   1, 1,      [0 1];
  'ViewClasses',              'double',   1, 1,      [0 1];
  'ViewClassSet',             'double',   1, 20,     [];
  'ViewClassesAsOverlay'      'double',   1, 1,      [0 1];
  'ViewCompressGaps'          'double'    0, 1,      [0 1];
  'ConnectClasses',           'double',   0, 1,      [0 1];
  'ViewInterpolated',         'double',   1, 1,      [0 1];
  'imageselection',           'char',     0, 20,     {'overlay' 'outline'};
  'ViewLabels',               'double',   1, 1,      [0 1];
  'ViewLabelAngle',           'double',   1, 1,      [];
  'ViewLabelSet',             'double',   1, 20,     [];
  'ViewLabelPreSpace',        'double',   1, 1,      [];
  'ViewLog',                  'double',   0, 3,      [0 1];
  'ViewAxisscale',            'double',   1, 1,      [0 1];
  'ViewNumbers',              'double',   1, 1,      [0 1];
  'ViewTimeAxis',             'double',   2, 3,      [0 1];
  'ViewTimeAxisAuto',         'double',   1, 1,      [0 1];
  'ViewExcludedData',         'double',   1, 1,      [0 1];
};

for k = fieldnames(options)';
  which = find(strcmp(lower(flds(:,Fname)),k));
  if ~isempty(which);
    value = getfield(options,k{:});
    if isa(value,'logical'); value = double(value); end
    if ~isempty(value) & ~isempty(flds{which,Fclass}) & ~isa(value,flds{which,Fclass});        %check class
      if strcmp(flds{which,Fclass},'double') & isa(value,'char') & ~isempty(str2num(value));
        value = str2num(value);     %if double is needed and we can convert char to valid double, then do.
        options = setfield(options,k{:},value);   %store in options  
      else    %otherwise, give an error
        error(['Property ' flds{which,Fname} ' must be of class ' flds{which,Fclass}]);
      end
    end
    if length(value)<flds{which,Fsizemin};    %check min size
      error(['Property ' flds{which,Fname} ' must be at least length ' int2str(flds{which,Fsizemin}) ])
    elseif length(value)>flds{which,Fsizemax};    %check max size
      error(['Property ' flds{which,Fname} ' cannot be longer than ' int2str(flds{which,Fsizemax})])
    elseif ~isempty(value) & ~isempty(flds{which,Fvalue});    %if we've got possible values
      if isa(value,'char') & strcmp(flds{which,Fclass},'char'); %got a char (and needed a char)
        if ~any(strcmp({value},flds{which,Fvalue}));    %check fields
          str=cell(1,length(flds{which,Fvalue})*2-1);
          str(1:2:end)=flds{which,Fvalue};
          str(2:2:end)={', '};
          error(['Invalid value for property ' flds{which,Fname} '  Valid values are: ' [str{:}]])
        end
      else    %value is a double or cell
        
        if isa(flds{which,Fvalue},'char');  %value is keyword!
          
          switch flds{which,Fvalue}
            case {'figure'};
              if ~ismember(value,allchild(0));
                error(['Property ' flds{which,Fname} ' must be a valid figure handle'])
              end
            case {'plotby'};
              if isa(value,'char');
                switch lower(value)
                  case {'data','browser','databrowser','data browser','zero','0'}
                    value = 0;
                  case {'rows','row','r','sample','samples','one','1'}
                    value = 1;
                  case {'columns','cols','col','c','variable','variables','two','2'}
                    value = 2;
                  case {'slabs','slab','three','3'}
                    value = 3;
                  otherwise
                    if ~isempty(str2num(value))
                      value = str2num(value);
                      value = value(1);
                    else
                      value = [];     %don't change if we can't figure it out
                    end
                end
                if ~isempty(value);
                  options = setfield(options,k{:},value);   %store in options  
                else
                  options = rmfield(options,k{:},value);    %remove from options
                end
              elseif ~isa(value,'double')
                error(['Property ' flds{which,Fname} ' must be a string or a double']);
              elseif value<0
                error(['Property ' flds{which,Fname} ' must be >0'])
              end
          end
          
        else
          if ~all(ismember(value,flds{which,Fvalue}));
            error(['Invalid value for property ' flds{which,Fname} ' valid values are: ' encode(flds{which,Fvalue},'')])
          end
        end
        
      end
    end
  end
end

%-----------------------------------------------------
function out = optiondefs()

defs = {

  'plotby'	        'Plot Settings'	'double'	'int(1:inf)'	'intermediate'	'Specifies the mode of the data to select in the Plot Control''s axis menus. Expects a numeric value between 1 and the number of dimensions in the data.'
  'linestyle'	      'Plot Settings'	'char'	[]	'novice'	'Specifies an overriding line style to use in plots. Empty uses the default line type. Typical settings include a single marker style character such as:  x o . * p h  and/or a linestyle: - --  :  .- '
  'symbolsize'      'Plot Settings' 'double' [] 'novice'  'Specifies an overriding symbol size to use in plots. Empty or zero uses default symbol size.'
  'linewidth'       'Plot Settings' 'double' [] 'novice'  'Specifies an overriding line width to use in plots. Empty or zero uses default line width.'
  'plottype'	      'Plot Settings'	'select'	[{''} plotguitypes]	'novice'	'Specifies the type of plot to use. Default (empty) is automatic line/scatter plot. Notice: Some plot types are not supported with some data types and some plot types do not support all options.'
  'automonotonic'   'Plot Settings' 'boolean'   []                'novice'  'Specifies whether or not Monotonic is acceptable as an automatic selection for plot type. When 0, this disables the possible auto-selection of Monotonic plot types which are typically only used with time-based data.'
  'viewexcludeddata' 'Plot Settings'	'boolean'	[]	'intermediate'	'Governs the display of excluded data. If "Yes" data will be displayed in spite of being excluded from the DataSet.'
  'viewlog'	        'Plot Settings'	'select'	{[0 0 0] [1 0 0] [0 1 0] [1 1 0] [1 0 1] [0 1 1] [1 1 1]}	'intermediate'	'Governs the use of log axis scales for the [X Y Z] axes. A value of "1" shows the specified axis on a log scale.'
  'viewcompressgaps' 'Plot Settings' 'boolean' []  'novice'   'Squeeze out points which are excluded, compressing the x-axis to leave out gaps.'
  'autoscale'	      'Plot Settings'	'boolean'	[]	'intermediate'	'Use automatic y-scaling on each plotted item (puts all items on the same scale.'
  'autoscaleorder'	'Plot Settings'	'double'	'int(0:inf)'	'intermediate'	'Define type of automatic y-scaling to use on each plotted item. 0 = none, 1 = mean area, 2 = normalized length, inf = min/max scaling (0/1).'
  'autoscalewindow'	'Plot Settings'	'vector'	[]	'intermediate'	'Cell containing indices to use as window for scaling (see autoscale option). There is one cell for each mode of the data.'
  'viewaxislines'	  'Plot Settings'	'select'	{[0 0 0] [1 0 0] [0 1 0] [1 1 0] [1 0 1] [0 1 1] [1 1 1]}	'intermediate'	'Governs the display of axis = 0 lines for the [X Y Z] axes. A value of "1" shows the axis=0 line for the specified axis.'
  'viewaxisplanes'	'Plot Settings'	'boolean'	[]	'intermediate'	'Governs the display of axis "planes" in 3D plots when view axis lines is ON for any axis.'
  'viewdiag'	      'Plot Settings'	'boolean'	[]	'intermediate'	'Governs the display of a 1:1 diagonal line on the plot. Does not apply to 3-dimensional plots.'
  'viewtable'	      'Plot Settings'	'boolean'	[]	'intermediate'	'Governs the display of a table showing the currently-plotted values.'
  'findpeakswidth'  'Plot Settings' 'double'  [] 'novice' 'Enables peak finding using the specified width window for peak sensitivity threshold. 0 or empty disables peak finding.'
  'usespecialmarkers'	'Plot Settings'	'boolean'	[]	'intermediate'	'Use complex symbols on different scatter-plot items (i.e. on a non-continuous x-axis). Complex symbols shift both inner and outer color to increase the number of possible unique element styles.'
  'viewtimeaxisauto'	'Plot Settings'	'boolean'	[]	'novice'	'Governs the automatic detection of a time-stamp x-axis scale. When "Yes", the x-axis scale is examined and, if it appears to be a time stamp, dates and times are used instead of raw numbers.'
  'viewtimeaxis'	    'Plot Settings'	'select'	{[0 0 0] [1 0 0] [0 1 0] [1 1 0] [1 0 1] [0 1 1] [1 1 1]}	'intermediate'	'Forces the interpretation of one or more axes as time-stamps (labeled using dates and times instead of raw time-stamp numbers). Specified for each of the [X Y Z] axes.'
  
  'selectionmode'	  'Selections'	'select'	{'x','xs','y','ys','lasso','rbbox','paint','polygon','nearest','nearests','circle','ellipse'}	'intermediate'	'Specifies the selection tool.'
  'selectioncolor'	'Selections'	'mode'	[]	'novice'	'Specifies the color to use for selections. Set using a three-element vector indicating [red green blue] where each value is between zero and one.'
  'selectionmarker'	'Selections'	'select'	{'' 'o' 'v' '*' 'square' '+' 'diamond' '^' 'pentagram' '.'}	'novice'	'Specifies the marker to use on selected data (empty = use default symbol).'
  'selectpersistent' 'Selections' 'boolean' [] 'novice' 'Keeps selection button toggled on after selection so another click starts a new selection automatically.'
  'brushwidth'	    'Selections'	'double'	'float(0:100)'	'novice'	'Specifies the width (in number of screen pixels) to use for the "Paint" selection mode.'
  'connectitems'    'Selections'  'vector' []           'intermediate' 'Indices of items to connect with sequential line in plot.'
  'connectitemsstyle' 'Selections'  'vector' []           'intermediate' 'Line/Marker style to use on connected items (see connectitems).'
  'connectitemslinewidth' 'Selections' 'double' 'float(0:100)' 'intermediate' 'Width of line to use on connected items.'
  'imageselection' 'Selections' 'select' {'overlay' 'outline'} 'novice' 'Style of selection on images. "overlay" uses a semi-transparent mask, "outline" outlines selected pixels.'

  'viewnumbers'	    'Labels'	'boolean'	[]	'intermediate'	'Governs labeling of data using the index number.'
  'viewlabels'	    'Labels'	'boolean'	[]	'intermediate'	'Governs labeling of data using the DataSet-defined text labels (if present).'
  'viewlabelset'	  'Labels'	'double'	'int(1:inf)'	'intermediate'	'Specifies the label set (by integer number) to use when labeling data.'
  'declutter'	      'Labels'	'double'	'float(0:100)'	'intermediate'	'Specifies the level of decluttering to use on labels. 0 = no declutter, 0-1 = light, 1-5 = moderate, 5+ = significant.'
  'declutter_usewaitbar'	    'Labels'	'boolean'	[]	            'intermediate'	'Use a waitbar when decluttering labels (use this option when a lot of labels are present).'
  'declutter_usepixels'	      'Labels'	'boolean'	[]	            'intermediate'	'Convert label position to pixel units to declutter (legancy code, turn this off [0] to speed things up on newer versions of Matlab 2014b+).'
  'declutter_chunksize'	      'Labels'	'double'	'int(0:inf)'	  'intermediate'	'When using a declutter waitbar, chunk up labels by this amount.'
  'labelselected'	  'Labels'	'boolean'	[]	'intermediate'	'Governs the labeling of selected points only. If "Yes" only selected points will be labeled (when ViewLabels is True). If "No" all points are labeled.'
  'viewlabelangle'	'Labels'	'double'	[]	'intermediate'	'Specifies the angle of text labels in degrees. 0 = Horizontal Right, 90 = Vertical up. Valid values include 0 through 360.'
  'viewlabelmaxy'	  'Labels'	'double'	[]	'intermediate'	'Specifies the upper limit on position of text labels (i.e. on the y-axis). Used to keep labels below the specified position.'
  'viewlabelminy'	  'Labels'	'double'	[]	'intermediate'	'Specifies the lower limit on position of text labels (i.e. on the y-axis). Used to keep labels above the specified position.'
  'textinterpreter'	'Labels'	'select'	{ 'latex' 'tex' 'none'}	'expert'	'Specifies the text interpreter to use on labels. LaTex and Tex interpret strings using special notation for various text effects.'
  'menulabelset'	  'Labels'	'double'	'int(1:inf)'	'novice'	'Specifies the label set (by integer number) to use for the labels in the y-axis menu on the Plot Controls.'
  'viewlabelprespace' 'Labels' 'double' 'int(1:inf)'  'intermediate' 'Specifies the number of padding spaces to include before point labels (allows easy offset of labels)'
  'viewaxisscale'	  'Labels'	'boolean'	[]	'intermediate'	'Governs labeling of data using the DataSet-defined axisscale (if present).'
  'viewaxisscaleset' 'Labels'	'double'	'int(1:inf)'	'intermediate'	'Specifies the axisscale set (by integer number) to use when labeling data.'
  'viewmaxlabelcount' 'Labels' 'double' []	'novice'	'Absolute max number of labels to show (declutter is done after this is applied).'
  'viewlegend3dhandlevis' 'Labels'	'boolean'	[]	'intermediate'	'Remove handle visibility on plotted 3D data. This may clean up legend.'
  'viewlegendmarkersize' 'Labels'	'double'	[]	'intermediate'	'Change the marker size displayed in a legend, defualt is current marker size in plot.'
  
  'viewclasses'	    'Classes'	'boolean'	[]	          'intermediate'	'Governs plotting of data using classes (if defined in the DataSet).'
  'viewclassset'	  'Classes'	'double'	'int(1:inf)'	'intermediate'	'Specifies the class set (by integer number) to use when viewing classes.'
  'classmodeuser'	  'Classes'	'double'	{[] 1 2 3}	'intermediate'	'Specifies the class mode (by integer number 1-3) to use when viewing classes in special mode (e.g., Summary mode). If empty then default mode is selected.'
  'classcoloruser'  'Classes' 'boolean' [] 	          'intermediate'	'Allows user to override color sets. When enabled, the classcolors>userdefined preference (plspref) is used to color markers. A context menu ("Change Class Color") is enabled on plots to change colors.'
  'viewclassesasoverlay'	'Classes'	'boolean'	[]	          'novice'	'Specifies if underlying data lines should be hidden when classes are shown (0,"no") or shown with classes overlayed (1,"yes").'
  'connectclasses'	'Classes'	'boolean'	[]	          'intermediate'	'Governs plotting of class-encirciling ellipses. When "Yes" ellipses are drawn around each displayed class.'
  'classsymbol'	    'Classes'	'select'	{'' 'o' 'v' '*' 'square' '+' 'diamond' '^' 'pentagram' '.'}	'novice'	'Symbol to use when plotting classes. If empty, the symbol editor defines the symbols and colors to use.'
  'classsymbolsize'	'Classes'	'double'	[]	          'novice'	'Specifies the symbol size to use when plotting classes. If empty, the default symbol size is used.'
  'autosizemarkers' 'Classes' 'boolean' []            'novice'  'When "Yes"(1) and no symbol syze is specified, symbol size is adjusted to axes size and smaller symbols are used when axis is small.'
  'classfacecolor'	'Classes'	'boolean'	[]	          'novice'	'Governs the use of symbol face color when viewing classes. If "No", each symbol is a single color. If "Yes", the face color of symbols will be rotated through the class colors independently from the symbol outline color.'
  'classcolormode'	'Classes'	'select'	{'' 'figure' 'jet' 'hot' 'cool' 'bone' 'gray' 'hsv'}	'novice'	'Specifies a standard colormap to use for class colors. Empty (the default) uses a standard "optimized" color map (recommended). ''figure'' uses the colormap set on the current figure. Any other setting is assumed to be a standard colormap name.'
  'connectclassmethod' 'Classes' 'select' connectclasslist   'novice'  'Specifies method used to outline classes (when connectclasses is "Yes") ''pca'' uses PCA confidence ellipses, ''outline'' draws a border around the outermost class members, ''connect'' connects all class members in series with connection back to first member (closed line), ''sequence'' connects all class members in series (open line).'
  'connectclasslimit'  'Classes' 'double' 'float(0:1)' 'intermediate' 'Specifies confidence level at which classes should be outlined when using "PCA" class connect method'
  'connectclassitems'  'Classes' 'vector' []           'intermediate' 'List of classes to apply connect method on. If empty, all classes are used.'

  'colorby'	        'ColorBy Settings'	'vector'	[]	'novice'	'Specifies an item number (from the PlotBy mode of the data), or an explicit vector of values to use in coloring the data. When not empty, the given values or index into the dataset is used to color-code the plotted data using the class color scale.'
  'colorbybins'	    'ColorBy Settings'	'double'	'int(1:inf)'	'novice'	'Specifies the number of color bins to group the colorby vector into. The more bins, the slower the plotting and more complex the legend, but the more detailed the color mapping. 30 is recommended.'
  'colorbyscale'	  'ColorBy Settings'	'select'	[{'linear' 'nonlinear'}]	'novice'	'Specifies the type of colorby bin mapping to use. "linear" maps colorby values to color maintaining the scale of the values. "nonlinear" maps values to color compressing values into sorted bins but with non-linear bins (may increase color contrast).'
  'colorbydirection' 'ColorBy Settings' 'select'  [{'lines' 'points'}] 'novice' 'If data is square, what direction should be the defualt to apply colorby ("lines" or "points"). If data not square, direction is inferred by data size.';
  'slabcolormode'     'Image Settings'  'select' {'lines' 'rgb' 'classes' 'jet' 'colormap'} 'novice' [...
       'Governs the color map used when viewing more than 3 image slabs in a false-color image. '...
       'Each pixel is assigned a single color from this colormap based on the slab with the largest value for that pixel. '...
       'This value is then scaled based on the slab color contrast setting. '...
       '''lines'' = draw from standard line color sequence; '...
       '''rgb'' = similar to lines but starts with red, green, blue; '...
       '''classes'' = draw from color scheme used for class symbols; '...
       '''jet'' = interpolate from the jet color scheme; '...
       '''colormap'' = interpolate from current figure''s color map; '];
  'slabcolorcontrast' 'Image Settings'  'double' 'float(0:1)' 'novice' 'Governs the level of intensity contrast shown for each slab when veiwing more than 3 slabs in a false-color image. The higher the value, the more the base color is scaled by the image''s value. A value of zero shows the color without scaling.'
  'viewautocontrast'	'Image Settings'	'boolean'	[]	'intermediate'	'Governs the use of auto-contrasting on images. When "Yes" image data magnitude is truncated to 3 times the standard deviation. Helps adjust the color scale of images when unusually large or small values are present.'
  'viewinterpolated'	'Image Settings'	'boolean'	[]	'novice'	'Governs the use of interpolated-color images. When "Yes" images are interpolated to higher spatial resolution. Note that not all display modes support interpolation. Other settings may disable this feature.'
  'viewpixelscale'    'Image Settings'  'boolean' []  'novice'  'Governs display of pixel axis scales on images. When "No", axis scales will be hidden unless user defines an image axisscale. When "Yes", axis scales will be shown in pixels if no user-defined image axisscale is set.'
  'imagegunorder'     'Image Settings' 'select'  {[1 2 3] [1 3 2] [2 1 3] [2 3 1] [3 1 2] [3 2 1]}, 'novice' 'Governs the order of the color guns used for false color images. 1 = red, 2 = green, 3 = blue.'
  'viewdensity'       'Image Settings' 'boolean'	[]	'novice'	'Governs use of density plots for images, trun off to force the use of a scatter plot.'
  'densitybinsmin'    'Image Settings' 'double' 'int(1:inf)' 'novice' 'Minimum number of bins to use in image density plots.'
  'densitybinsmax'    'Image Settings' 'double' 'int(1:inf)' 'novice' 'Maximum number of bins to use in image density plots.'  

  'conflimits'	'Limit Controls'	'boolean'	[]	'expert'	'Governs the display of the Confidence Limits frame on the Plot Controls figure. Simply enabling this feature does NOT automatically allow display of confidence limits. The settings will only be used when a given figure has a callback allowing the use of confidence limits.'
  'showlimits'	'Limit Controls'	'boolean'	[]	'expert'	'Governs the display of confidence limit lines on the figure.'
  'limitsvalue'	'Limit Controls'	'double'	'float(0:100)'	'expert'	'Specifies the confidence limit level to be used when plotting confidence limits.'
  
  'plotcommand'	          'Callbacks'	'char'	''	'expert'	'A standard Matlab callback used after each axes on a figure is refreshed.'
  'closeguicallback'	    'Callbacks'	'char'	''	'expert'	'A standard Matlab callback used after the user closes a PlotGUI-controlled figure.'

  'validplotby'	'GUI Controls'	'select'	{[] [0] [1] [2] [3] [0 1] [0 2] [0 3] [1 2]}	'expert'	'Specifies the mode or modes the user is permitted to select from the "Plot" menu. Empty [] = any mode in the data.'
  'vsindex'	    'GUI Controls'	'select'	{[0 0] [1 0] [0 1] [1 1] [0 0 0] [1 0 0] [0 1 0] [1 1 0] [1 0 1] [0 1 1] [1 1 1]}	'expert'	'Governs whether or not "Index" is included as an item in each of the axis menus. Specifies [X Y Z] where a value of "1" enables the listing of "Index" and/or "Axisscale" for the specified axis.'
  'axismenuenable'	'GUI Controls'	'select'	{[0 0 0] [1 0 0] [0 1 0] [1 1 0] [1 0 1] [0 1 1] [1 1 1]}	'expert'	'Governs the enabling of the [X Y Z] axis menus. If 0 (zero), the specified axis menu is not enabled and the user can not change the default selected value. See AxisMenuValues property to set the default value.'
  'axisautoinvert'  'GUI Controls'  'select' {-1 0 1} 'novice' 'When 1 (true/on) x-axis will be inverted in direction if the axisscale in the data is in decreasing order. When -1, x-axis will ALWAYS be inverted (irrespective of the data direction). When 0, axis will never invert.'
  'labelwithnumber'	'GUI Controls'	'select'	{'on' 'off' 'auto'}	'novice'	'Governs numbering of axis menu items (appended within parenthesis at the end of the label), ''auto'' adds numbering if there are duplicate.'  
  'autoduplicate'   'GUI Controls'  'boolean' []  'expert' 'When 1 (true/on) a clicked sub-plot is automatically duplicated as a single axis in a new figure.'
  'autopopulate'    'GUI Controls'  'boolean' []  'novice' 'When 1 (true/on) new sub-plots are automatically populated with results. When 0 (false/off) subplots are left empty for the user to populate manually.'
  'maximumyitems'   'GUI Controls'  'double'  'int(10:1000000)' 'novice' 'Specifies the maximum number of items allowed to be shown in the y-axis listbox menu.'
  'maximumitems'    'GUI Controls'  'double'  'int(10:1000000)' 'novice' 'Specifies the maximum number of items allowed to be shown in the x- and z-axis pull-down menus.'
  'maximumdatasummary' 'GUI Controls'  'double'  'int(10:1000000)' 'novice' 'Specifies the maximum number of items allowed to be shown in the "data" view of the "Data Summary" plot mode.'
  'maxclassview'    'GUI Controls'  'double'  'int(1:inf)'      'novice' 'Specifies the maximum number of classes to dispaly in a scatter plot.'
  'noinclude'	      'GUI Controls'	'boolean'	[]	'expert'	'Governs the ability of the user to make changes to the include field of the DataSet.'
  'noload'	        'GUI Controls'	'boolean'	[]	'expert'	'Governs the ability of the user to load new data.'
  'noselect'	      'GUI Controls'	'boolean'	[]	'expert'	'Governs the ability of the user to make or change selections.'
  'showcontrols'  	'GUI Controls'	'boolean'	[]	'expert'	'Governs the display of the Plot Controls when the target figure is active.'
  'pgtoolbar'       'GUI Controls'  'boolean' [] 'novice' 'Specifies if the toolbar controls should be added to the target figure.'
  'status'	        'GUI Controls'	'char'	''	'expert'	'Specifies the label to use for the given figure in the list of figures on the Plot Controls (top of the controls).'
  'targetaxestag'	  'GUI Controls'	'vector'	[]	'expert'	'Specifies a tag which, if non-empty, indicates the axis on which all plots should be plotted. All other plots will be ignored.'
  'axismenuvalues'	'GUI Controls'	'vector'	[]	'expert'	'A cell specifying the settings for each of the three axis menus.'
  'asimage'	        'GUI Controls'	'vector'	[]	'expert'	'Specifies if the given data should be plotted as an image, even if it is not a DataSet Type=Image object.'
};

out = makesubops(defs);

%------------------------------------------------------
function [data,datasource] = getdataset(fig,varargin);
% Extract the current data set from the given objects dataset appdata property.
%  if the dataset is identified as an object handle, then get the dataset from THAT object
% Output datasource is the id to the shared data object

%data = [];
%datasource = [];

if ~ishandle(fig)
  data = [];
  datasource = [];
  return;
end
%if ~(isempty(fig))
if ~isempty(getappdata(fig,'target'))
  %if passed a handle to the controls, redirect to current target
  fig = getappdata(fig,'target');
end
[data,datasource] = getobjdata(fig,varargin);
%end

%-------------------------------------------
function out = ispointer(in)
out = isa(in,'double') & prod(size(in))==1 & ishandle(in);


%------------------------------------------------------
function [targfig,fig] = findtarget(fig,forceredraw);      
%FINDTARGET get target figure (if any)
% figure out if the passed figure number has a valid target figure
%  The passed figure # will be checked for the following situations:
%   (A) This is a controls figure which has a "target" field pointing to a figure to plot on
%     If an invalid target is found, that target is removed from the child list and
%      a new figure is created as the target (may end up being blank!)
%   (B) This is a figure which is controlled by a different controls figure
%   (C) This is a complete figure which has its own controls
%   (D) This is a figure without its own controls and no assigned ControlBy figure
%        if so, Locate or create a ControlBy figure for it
%  If called without outputs, findtarget will try to ascertain if the
%  controls need to be updated. Add a second input of 1 to force
%  updateing the controls.

if nargin == 0; fig = gcf; end

if ~ismember(fig,allchild(0)) | ~strcmp(getappdata(fig,'figuretype'),'PlotGUI');      %plotgui figure?
  targfig = fig;      %nope, just return fig as targetfig
  return
end 

if nargin<2
  forceredraw = 0;
end

if isempty(getappdata(fig,'controlby')) & ~strcmp(get(fig,'tag'),'PlotGUI'); %isempty(guidata(fig));
  setappdata(fig,'controlby',nan);      %we have no controls but we need them
  forceredraw = 1;
end

bringtofront = forceredraw;        %default is NOT to bring figures to front (unless forceredraw is 1)

if isempty(getappdata(fig,'controlby'));               %no one else has my controls? (I am a controlling figure)
  
  targfig = getappdata(fig,'target');                  %get target figure (if any)
  if isempty(targfig)
    targfig = fig;                                      %No target? just point at myself
  elseif ~ismember(targfig,allchild(0));                %Something there? does it still exist?
    setappdata(fig,'children',setdiff(getappdata(fig,'children'),targfig));  %No, remove this as a child of that parent
    children = getappdata(fig,'children');
    children = children(ishandle(children));           %make sure all these children still exist
    if isempty(children);                              %no other children?
      targfig = newfigure;                                %then create new target
      assigndefaults(targfig);
      assigngetfocus(targfig);
    else                                               %if there ARE other children
      targfig = max(double(children));                         %then select the highest #ed fig
      assigngetfocus(targfig);
    end
    setappdata(fig,'target',[nan]);               %set new/next figure as the target
    setappdata(targfig,'controlby',double(fig));            %note me as the controlby figure
    setappdata(fig,'children',union(children,targfig));     %and set as a child of me
    bringtofront = 1;                     %flag to bring both to front when we're done
  end
  
else            %someone else has my controls
  
  targfig = fig;
  fig = [];
  if ismember(getappdata(targfig,'controlby'),double(allchild(0)));    %does it still exist?
    fig = getappdata(targfig,'controlby');                  %point at figure with actual controls
  end
  if isempty(fig);                          %If assigned control figure not available
    fig = assigncontrolby(targfig);            %find one or make one
  end
  
end

if bringtofront;
  dockcontrols(fig,targfig);
  if strcmp(get(fig,'visible'),'on'); figure(fig); end
  if strcmp(get(targfig,'visible'),'on'); figure(targfig); end          %bring both figures to the front
end

switch nargout
  case 0
    control_target = getappdata(fig,'target');
    currentaxes      = getappdata(targfig,'currentaxes');
    if forceredraw | isempty(control_target) | control_target~=targfig...
        | isempty(currentaxes) | (currentaxes~=get(targfig,'currentaxes') & ...
        (~ishandle(currentaxes) | strcmp(get(currentaxes,'tag'),getappdata(targfig,'targetaxestag'))));
      setappdata(fig,'target',targfig);
      updatecontrols(targfig);
    end
    clear targfig fig
  case 1
    clear fig  
end

%------------------------------------------------------
function [targfig,fig] = dockcontrols(fig,targfig);
% Dock controls to the indicated figure (or dock indicated controls to its target)

if nargin<2;
  [targfig,fig] = findtarget(fig);
end

%Dock control figure next to target figure
if fig ~= targfig;    %(if not the same figure!)
  if strcmp(get(findobj(fig,'tag','ViewDockControls'),'checked'),'on');     %if selected
    oldunits = {get(fig,'units') get(targfig,'units') get(0,'units')};
    set([fig targfig 0],'units','pixels');
    
    screen = getscreensize;
    ptarg = get(targfig,'position');
    pcont_old = get(fig,'position');
    pcont = pcont_old;
    
    pcont(1) = ptarg(1)-pcont(3)-1;        %  X(controls) = X(target)                - Width(controls)
    pcont(2) = ptarg(2)+ptarg(4)-pcont(4);      %  Y(controls) = Y(target)+Height(target) - Height(controls)
    
    if pcont(1)<0;                         %except that x can't be off left side of screen (put on bottom of window)
      pcont(1) = ptarg(1)+ptarg(3)+1;             %  X(controls) = X(target)+Width(target)
      if pcont(1)+pcont(3) > screen(3);        % off right side?
        pcont(1) = screen(1);                       %then put them at the bottom of window
        pcont(2) = ptarg(2)-pcont(4)-screen(4)*.05; %  Y(controls) = Y(target) - Height(controls) - 5% of screen height
      end
    end          
    
    if any(pcont_old~=pcont); 
      set(fig,'position',pcont);       %move if we have done any moving
    end
    
    set([fig targfig 0],{'units'},oldunits');
    
  end
  findtarget(targfig);
end

if ~getappdata(targfig,'showcontrols')
  set(fig,'visible','off');
%   drawnow;
else
  switch get(fig,'visible')
    case 'off'
      set(fig,'visible','on');
  end
  findcontrols(fig);  %assure controls are on-screen
end

if nargout == 0;
  clear fig targfig
elseif nargout == 1;
  clear targfig
end

%------------------------------------------------------
function [fig] = assigncontrolby(targfig);
% assigncontrolby assigns a control PlotGUI figure to an abandoned target figure

switch getappdata(targfig,'showcontrols')
  case 0
    vis = 'off';
  otherwise
    vis = 'on';
end
fig = [];
for k=-sort(-double(allchild(0)))';             %search all figures for highest #ed control figure
  if getappdata(k,'iscontrolfigure')
    %   if strcmp(get(k,'type'),'figure') & isa(getappdata(k,'figuretype'),'char') & strcmp(getappdata(k,'figuretype'),'PlotGUI') ...
    %       & (~isempty(getappdata(k,'target')) ...x
    %       | (isempty(getappdata(k,['dataset'])) & ~isempty(guidata(k))));
    %A PlotGUI figure that has a target or that doesn't have data but does have controls (with handles!!!)
    fig = k;                            %use as control figure
    set(fig,'visible',vis);
    validatefamily(fig);
    break
  end
end
if isempty(fig);                      %Still empty? no control figures
  fig = plotgui;                      %make one and use it
  set(fig,...
    'windowbuttonmotionfcn','try;plotgui(''windowbuttonmotion_Callback'');catch;end',...
    'visible',vis)
  handles = guidata(fig);
  if checkmlversion('>=','7')
    set([fig handles.statusbox handles.xaxismenu handles.yaxismenu handles.zaxismenu],'keyPressFcn',@keypress);
    set(fig,'KeyReleaseFcn',@keyrelease)  
  else
    set(fig,'keyPressFcn',@keypress);
  end
end

assigngetfocus(targfig);
setappdata(targfig,'controlby',double(fig));            %note this as the controlby figure
setappdata(fig,'children',union(getappdata(fig,'children'),targfig));  %and set this as a child of that parent

%------------------------------------------------------
function assigngetfocus(targfig,mode);
% AssignGetFocus assigns or unassigns the callback fcn to get focus for a given target
% USAGE: assigngetfocus(targfif,mode);
%  targfig is the target figure to be modified, mode is 1 to turn on GetFocus, 0 to turn off
%  Defaults are current figure and turn ON

if nargin<2; mode = 1; end
if nargin<1; targfig = gcf; end

if ishandle(targfig) & strcmp(get(targfig,'Type'),'figure');
  
  wrn = warning;
  warning off;
  
  set(targfig,'PaperPositionMode','auto');   %patch to remove resizefcn warning
  for tomodify = {'WindowButtonDownFcn', 'ResizeFcn' 'WindowButtonMotionFcn' 'WindowButtonUpFcn'}
    maketargetfcn = [';plotgui(''child_' tomodify{1} ''');'];
    fcn = get(targfig,tomodify{1});
    if mode;      %mode = 1 means add function (if not already there)
      if ~iscell(fcn) & ~strcmpi(class(fcn),'function_handle') & isempty(findstr(maketargetfcn,fcn));    %append make target string if not already there
        set(targfig,tomodify{1},[maketargetfcn fcn]);
      end
    else          %mode = 0 means remove function (if it is there)
      if ~iscell(fcn) & ~isempty(findstr(maketargetfcn,fcn));
        pos=findstr(maketargetfcn,fcn);
        fcn(pos:pos+length(maketargetfcn)-1)=[];    %remove make target command string
        set(targfig,tomodify{1},fcn);
      end
    end
  end

  if mode
    set(targfig,'keyPressFcn',@keypress,'KeyReleaseFcn',@keyrelease);
    set(targfig,'WindowScrollWheelFcn',@child_WindowScrollWheelFcn)
  else
    set(targfig,'keyPressFcn','','KeyReleaseFcn','');
    set(targfig,'WindowScrollWheelFcn','')
  end
  
  h = findobj(targfig,'tag','PlotGUITargetMenu');
  if isempty(h) & mode
    h = uimenu(targfig,'tag','PlotGUITargetMenu','Label','PlotGUI','callback','plotgui(''menuselection'');');
    uimenu(h,'Label','Duplicate Figure','tag','ViewDuplicate','callback','plotgui(''menuselection'');');
    uimenu(h,'Label','Auto-Duplicate','tag','AutoDuplicate','callback','plotgui(''menuselection'');');
    uimenu(h,'Label','Choose Toolbar Buttons','tag','PGToolbarSelect','callback','plotgui_toolbar(''settings'');');
    uimenu(h,'Label','Find Controls','tag','FindControls','callback','plotgui(''menuselection'');','separator','on');
  elseif ~mode & ~isempty(h)
    delete([h;allchild(h)]);
  end
  
  warning(wrn);
  
end

%------------------------------------------------------
function removecontrolby(targfig)
% disconnect a plotgui figure from the controls (similar to spawn, but
% without creating a new figure. Note: does NOT remove data.

[targfig,fig]=plotgui('findtarget',targfig);

delete(findobj(targfig,'tag','pgtoolbar'));

%mark figure as non-plotgui and disable special functions
% setappdata(targfig,'figuretype','')
% set(targfig,'closerequestfcn','closereq');
plotgui('assigngetfocus',targfig,0);

%remove figure from controls' child list
children = setdiff(getappdata(fig,'children'),targfig);
setappdata(fig,'children',children)

if getappdata(fig,'target')==targfig;
  %if this figure was the current target of the controls
  if ~isempty(children)
    setappdata(fig,'target',min(children))
    plotgui('updatecontrols',fig)
  else
    close(fig);  %hide them
  end
end

%------------------------------------------------------
function reattachcontrolby(targfig)
%re-attach controls to previously "detached" plotgui figure

plotgui('assigncontrolby',targfig);
dockcontrols(targfig);

%------------------------------------------------------
function [currentaxes,myaxes] = findaxes(targfig)
% locate the current (valid) axes on a given figure

myaxes = findobj(targfig,'type','axes','tag',getappdata(targfig,'targetaxestag'));      %get list of axes on figure for plotting
if ~isempty(myaxes)
  %is current axes one of the valid axes?
  currentaxes = get(targfig,'currentaxes');
  if ~any(myaxes==currentaxes);
    %locate nearest axes and use in place
    currentaxes = myaxes(1);
  end
else
  %no valid axes exist on current figure, create some
  set(0,'currentfigure',targfig);
  currentaxes = axes;
  myaxes = currentaxes;
end

%------------------------------------------------------
function updatecontrols(fig)
% Update controls on indicated figure

if nargin <1
  fig = gcf;
end

[targfig,fig] = findtarget(fig);
handles = guidata(fig);

if targfig ~= fig;
  % setappdata(targfig,'currentaxes',get(targfig,'currentaxes'))
  setappdata(targfig,'currentaxes',findaxes(targfig))
  setaxismenus(targfig);       %set axis pull-down menu options
end

%handle limits controls
if getappdata(targfig,'conflimits');
  ison = limits('on',fig,true);
  needredraw = ~ison;
else
  ison = limits('off',fig,true);
  needredraw = ison;
end
set(handles.limitsbox,'value',getappdata(targfig,'showlimits'));
limitsvalue = sprintf('%g ',getappdata(targfig,'limitsvalue'));
if ~isfinite(limitsvalue) | isempty(limitsvalue) | limitsvalue <=0 | limitsvalue >= 100;
  limitsvalue = 95;     %default if there wasn't a value stored
end
set(handles.limitsvalue,'string',limitsvalue);


%Handle status box
children = double(getappdata(fig,'children'));
children(~ishandle(children)) = [];

set(fig,'windowbuttonmotionfcn','try;plotgui(''windowbuttonmotion_Callback'');catch;end')

if checkmlversion('>=','7')
  set([fig handles.statusbox handles.xaxismenu handles.yaxismenu handles.zaxismenu],'keyPressFcn',@keypress);
  set(fig,'KeyReleaseFcn',@keyrelease)
else
  set(fig,'keyPressFcn',@keypress);
end

if isempty(children);
  set(handles.statusbox,'string',['None'],'value',1);
else
  for child = 1:length(children);
    if ~isempty(getappdata(children(child),'status'));
      list{child} = getappdata(children(child),'status');   %user string if set
    else
      if isempty(get(children(child),'name'));
        list{child} = ['Figure No. ' num2str(children(child))];
      elseif strcmp(get(children(child),'NumberTitle'),'on')
        list{child} = ['Fig ' num2str(children(child)) ': ' get(children(child),'name')];
      else
        list{child} = [get(children(child),'name')];
      end
    end
  end
  set(handles.statusbox,'string',list,'value',find(children==targfig));
end

  %handle select button enabled or not...
  if ishandle(handles.select) & ishandle(handles.selecttool)
    %Handles structure is current.
    %if strcmp(handles.select.Enable,'on') & strcmp(handles.selecttool.Enable,'on')
      if strcmp(get(handles.select,'Enable'),'off') & strcmp(get(handles.selecttool,'Enable'),'off')
%       set([handles.select handles.selecttool],'enable','off');
%     else
      set([handles.select handles.selecttool],'enable','on');
    end
  else
    %Handles not curretn, need to find.
    if getappdata(targfig,'noselect');
      set([findobj(fig,'tag','select') findobj(fig,'tag','selecttool')],'enable','off');
      set(findobj(fig,'userdata','select'),'enable','off');
    else
      set([findobj(fig,'tag','select') findobj(fig,'tag','selecttool')],'enable','on');
      set(findobj(fig,'userdata','select'),'enable','on');
    end
  end
  %handle plot type button
updateplottypebtn(targfig);
updatecolorbybtn(fig);

%handle user items (make them visible or not as appropriate)
figitems = getappdata(fig,'useritems');
targfigitems = getappdata(targfig,'useritems');
figitems(~ishandle(figitems)) = [];
targfigitems(~ishandle(targfigitems)) = [];
setappdata(fig,'useritems',figitems);
setappdata(targfig,'useritems',targfigitems);

%execute any updatecallbacks on user items
for itemind=1:length(targfigitems);
  h = targfigitems(itemind);
  updatecallback = getappdata(h,'updatecallback');
  if ~isempty(updatecallback)
    try
      eval(updatecallback);
    catch
      le = lasterror;
      le.message = ['Error in UpdateCallback on "' get(h,'tag') '"' 10 le.message];
      rethrow(le)
    end
  end
end

set(figitems,'visible','off');   %make all useritems invisible
set(targfigitems,'visible','on');    %except relevent useritems
if needredraw | ~isempty(targfigitems) | ~isempty(figitems);
  updatefigure(fig);    %force redraw to accomodate new items
end

if ~getappdata(targfig,'showcontrols')
  set(fig,'visible','off');
  drawnow;
else
  switch get(fig,'visible')
    case 'off'
      set(fig,'visible','on');
  end
  findcontrols(fig,1);  %assure controls are on-screen
end

%------------------------------------------------------
function updateplottypebtn(fig)
% update plot type button label

[targfig,fig] = findtarget(fig);
handles = guidata(fig);
plottype = getappdata(targfig,'plottype'); 
if isempty(plottype); 
  plottype = 'Plot Type...'; 
else
  plottype = [upper(plottype(1)) lower(plottype(2:end))];
  for pos=find(plottype=='_');
    if pos<length(plottype)
      plottype(pos:pos+1) = [' ' upper(plottype(pos+1))];
    end
  end
end
set(handles.plottypebtn,'string',plottype);

%-----------------------------------------------------
function updatecolorbybtn(fig)
% update colorby button status

[targfig,fig] = findtarget(fig);
handles = guidata(fig);
cb = getappdata(targfig,'colorby');
plotby = getappdata(targfig,'plotby');
if isempty(cb) | (iscell(cb) & length(cb)>=plotby & isempty(cb{plotby}))
  str = 'Color By...';
  clr = [1 1 1];
else
  str = 'Colored...';
  clr = [1 1 .3];
end
set(handles.colorbybtn,'backgroundcolor',clr,'string',str)

%------------------------------------------------------
function setaxismenus(fig)
% define axis pull-down menus based on PlotGUI settings and data

if nargin < 1
  fig = gcf;
end

[targfig,fig] = findtarget(fig);
handles       = guidata(fig);
mydataset     = getdataset(targfig);
plotby        = getappdata(targfig,'plotby');
vsindex       = getappdata(targfig,'vsindex');
labelset      = max([1 getappdata(targfig,'menulabelset')]);

if isempty(vsindex); vsindex = [1 0]; end                  %default is turn x on and y off
if length(vsindex)==1; vsindex = [vsindex 0]; end    %assume one number means only x no y
vsindex = vsindex*availableindicies(targfig);          %multiply by # of available indicies

if isempty(mydataset) | ~isa(mydataset,'dataset') | isempty(mydataset.data); 
  updatepulldown(handles.xaxismenu,[]);
  updatepulldown(handles.yaxismenu,[]);
  updatepulldown(handles.zaxismenu,[]);
  set(handles.colorbybtn,'enable','off');
  return; 
end   %don't do anything if no data

%error checking on plotby (don't allow plotting by non-existant dims)
if plotby > ndims(mydataset);
  plotby = ndims(mydataset);
  setappdata(targfig,'plotby',plotby);
end

if ndims(mydataset)<3
  set(handles.colorbybtn,'enable','on');
else
  set(handles.colorbybtn,'enable','off');
end

currentaxes = getappdata(targfig,'currentaxes');
if isempty(currentaxes);
  currentaxes = axes;
  setappdata(currentaxes,'axismenuindex',getappdata(targfig,'axismenuindex'));
  setappdata(currentaxes,'axismenuvalues',getappdata(targfig,'axismenuvalues'));
end
setappdata(targfig,'currentaxes',currentaxes)

% default = getappdata(targfig,'axismenuindex');     %will be used as default if axisvalues fails
default = getappdata(currentaxes,'axismenuindex');     %will be used as default if axisvalues fails
if isempty(default) | (iscell(default) & all(~cellne(default,cell(size(default))))); default = getappdata(targfig,'axismenuindex'); end
if isempty(default); default = {[],[],[]}; end
if ~iscell(default); default = {default, [], []}; end
while length(default) < 3; default(end+1) = {[]}; end

force = getappdata(currentaxes,'axismenuvalues');         %get forced values (if any)
if isempty(force) | (iscell(force) & all(~cellne(force,cell(size(force))))); force = getappdata(targfig,'axismenuvalues'); end
if isempty(force); force = {[],[],[]};   end
if ~iscell(force); force = {force, [], []}; end
while length(force) < 3; force(end+1) = {[]}; end

pdopts = getappdata(targfig);
pdopts.labelset = labelset;

%see if we can use the existing pulldown descriptions
validateinfo = [mydataset.moddate plotby vsindex labelset];
oldvalidate = getappdata(targfig,'axismenulabelvalid');
if ~isempty(oldvalidate) & all(validateinfo==oldvalidate)
  lbls = getappdata(targfig,'axismenulabels');
  [xstring,ystring,zstring] = deal(lbls{1:3});
  ctrvalidate = getappdata(fig,'axismenulabelvalid');
  if ~isempty(ctrvalidate) & all(validateinfo==ctrvalidate)
    selectiononly = true;  %update only selection (unless we're chnging targets)
  else
    selectiononly = false;  %controls don't have the same strings
  end
else
  %nope, regenerate
  [xstring,ystring,zstring,default,force] = createpulldowndesc(mydataset,pdopts,default,force);

  %store labels and moddate of dataset
  setappdata(targfig,'axismenulabels',{xstring ystring zstring default force});
  setappdata(targfig,'axismenulabelvalid',validateinfo)  %figure has these settings now
  selectiononly = false;
end
setappdata(fig,'axismenulabelvalid',validateinfo)  %plot controls match now too

%Don't allow multiple selection on x or z menus
if ~isstr(default{1}) & length(default{1}) > 1; default{1} = min(default{1}); end
if ~isstr(force{1})   & length(force{1})   > 1; force{1}   = min(force{1});   end
if ~isstr(default{3}) & length(default{3}) > 1; default{3} = min(default{3}); end
if ~isstr(force{3})   & length(force{3})   > 1; force{3}   = min(force{3});   end

%adjust values for vsindex
if isa(default{1},'double'); default{1} = default{1}+vsindex(1);   end
if isa(default{2},'double'); default{2} = default{2}+vsindex(2);   end
if isa(default{3},'double'); default{3} = default{3}+1;            end
if isa(force{1},'double'); force{1} = force{1}+vsindex(1);   end
if isa(force{2},'double'); force{2} = force{2}+vsindex(2);   end
if isa(force{3},'double'); force{3} = force{3}+1;            end

enabled = getappdata(targfig,'axismenuenable');
if isempty(enabled);
  enabled = [1 1 1];
end
enabled(length(enabled)+1:3) = 1;   %enable any non-specified axes

if isempty(zstring);
  zaxis('off',fig);       %turn off zaxis menu selector
else
  zaxis('on',fig);
end  

updatepulldown(handles.xaxismenu,xstring,default{1},force{1},enabled(1),selectiononly);
updatepulldown(handles.yaxismenu,ystring,default{2},force{2},enabled(2),selectiononly);
updatepulldown(handles.zaxismenu,zstring,default{3},force{3},enabled(3),selectiononly);

ind = GetMenuIndex(fig);
%Handle special cases of selected items
%Both x and y set to "vs. index"?
if plotby > 0 & (plotby + ~isempty(getappdata(targfig,'asimage')))<3 & ind{1} <= 0 & length(ind{1}) == length(ind{2}) & all(ind{1} == ind{2});
  setpd(handles.yaxismenu,'value',2); 
elseif plotby == 0 & ind{1} <= 0 & length(ind{1}) == length(ind{2}) & all(ind{1} == ind{2});
  if length(get(handles.xaxismenu,'string')) > 1; 
    setpd(handles.xaxismenu,'value',2); 
  end
end
if length(ind{2}) == 0;      %no selection = select first
  setpd(handles.yaxismenu,'value',1);
end

newvalues = GetMenuSettings(fig);
setappdata(targfig,'axismenuvalues',newvalues)
setappdata(currentaxes,'axismenuvalues',newvalues)
newvalues = GetMenuIndex(fig);
setappdata(targfig,'axismenuindex',newvalues);
setappdata(currentaxes,'axismenuindex',newvalues)

%------------------------------------------------------
function [xstring,ystring,zstring,default,force] = createpulldowndesc(mydataset,options,default,force)
%options must have:
%  plotby,asimage,labelset,vsindex

MaximumItems = options.maximumitems;       %maximum # of items allowed in a pull-down menu
MaximumYItems = options.maximumyitems;       %maximum # of items allowed in the y listbox

plotby   = options.plotby;
asimage  = options.asimage;
labelset = options.labelset;
vsindex  = options.vsindex;

xstring = cell(0); ystring = cell(0); zstring = cell(0);

if plotby > 0;
  
  plotvs = 2-plotby+1;
  if plotvs<1; plotvs = 1; end
  
  %make "vs. index" entries for beginning (we check if we need them later)
  if isempty(asimage) | ~evriio('mia')
    switch plotby
      case 1
        baseindexname = 'Variable';
      case 2
        baseindexname = 'Sample';
      otherwise
        baseindexname = 'Slab';
    end
  else
    switch plotby
      case 1
        baseindexname = 'Variable';
      otherwise
        baseindexname = 'Image';
    end
  end
  %dataset scale name if present
  indexstring{1} = baseindexname;
  for axset = size(mydataset.axisscale,2):-1:1
    if ~isempty(mydataset.axisscale{plotvs,axset})
      if ~isempty(mydataset.axisscalename{plotvs,axset});
        indexstring{end+1} = mydataset.axisscalename{plotvs,axset};
        indexstring{1} = ['Linear Index'];
      else
        if length(indexstring)>1
          indexstring{end+1} = 'Arbitrary Scale';
        else
          indexstring{2} = 'Arbitrary Scale';
          indexstring{1} = 'Linear Index';
        end
      end
      if isempty(default{1}); default{1} = indexstring{2}; end
    end
  end
  %extract labels from label property of dataset
  if size(mydataset.label,2)>=labelset & ~isempty(mydataset.label{plotby,labelset});
    labels = mydataset.label{plotby,labelset};
    missing = zeros(1,size(mydataset.data,plotby));
    if ~iscell(labels);

      slbl = sortrows(labels);
      usenum = false;%Use numbering in menu lables.
      
      switch options.labelwithnumber
        case 'on'
          usenum = true;
        case 'auto'
          %Only number if there are duplicates.
          isunique = ~any(sum(abs(diff(double(slbl))),2)==0);
          if ~isunique
            usenum = true;
          end
        case 'off'
          usenum = false;
      end
      
      %Leave example of how to insert HTML into label list. This cuases at
      %least two problems, need to cull the HTML from the list (see
      %trimparens) and from the axis labels (plotgui_plotscatter).
      %       if size(labels,1)<50
      %         htm_1 = '<HTML>';
      %         htm_2 = ' (<SPAN style="color:blue">';
      %         htm_3 = '</SPAN>)</HTML>';
      %       else
      %         htm_1 = '';
      %         htm_2 = ' (';
      %         htm_3 = ')';
      %       end
      
      temp = cell(0);
      for j = 1:size(labels,1);
        thislabel = labels(j,:);
        if ~isempty(thislabel) & any(thislabel~=' ');
          temp{j} = labels(j,:);
        else
          missing(j) = 1;
          temp{j} = '';
        end
        if usenum;
          temp{j} = [temp{j} ' (' num2str(j) ')'];
        end
      end
      labels = temp;
    end
  elseif ~isempty(mydataset.axisscale{plotby});
    %TODO: allow selection of axisscale set other than first?
    %if we've got axisscales, use those
    temp = mydataset.axisscale{plotby};
    for j = 1:length(temp);
      labels{j} = [sprintf('%g',temp(j))];
    end
    missing = zeros(1,size(mydataset.data,plotby));
  else
    missing = ones(1,size(mydataset.data,plotby));
  end
  
  if any(missing)
    %no labels? do generic ones
    if isempty(asimage)
      switch plotby
        case 1
          keyword = 'Row';
        case 2
          keyword = 'Column';
        case 3
          keyword = 'Slice';
        case 4
          keyword = 'Cube';
        otherwise
          keyword = ['Mode ' num2str(plotby) ' index'];
      end
    else
      switch plotby
        case 1
          keyword = 'Pixel';
        otherwise
          keyword = 'Slice';
      end
    end
    %replace missing cell items with generic string with number
    j = find(missing);
    if ~isempty(asimage) & plotby==1
      %image and pixel list - use x,y,z index
      nimgdim = length(asimage);
      pind = {};
      [pind{1:nimgdim}] = ind2sub(asimage,j(:));
      pindxstr = repmat('%i,',1,nimgdim);
      pindxstr = pindxstr(1:end-1);
      temp = sprintf([keyword ' %g [' pindxstr ']\n'],[j(:) pind{:}]');
    else
      %normal indexing
      temp = sprintf([keyword ' %g\n'],j);
    end
    temp = str2cell(temp,1); 
    labels(j) = temp;
  end
  
  %Add "excluded" symbols to begininning of each excluded label
  excluded_symbol = [187 32]; %183;
  isexcluded = 1:size(mydataset.data,plotby);
  isexcluded(mydataset.includ{plotby}) = [];   %make list of excluded items
  if ~isempty(isexcluded);
    for j = isexcluded;
      %       labels{j} = [labels{j} excluded_symbol];
      labels{j} = [excluded_symbol labels{j}];
    end
  end
  
  %Are we allowed to offer indices?
  if ~vsindex(1);    %don't offer if vsindex is 0
    xstring = {labels{1:min([MaximumItems length(labels)])}};
  else    
    if evriio('mia') & (strcmp(indexstring{1},'Image') | ndims(mydataset) > 2) & ~isempty(asimage)
      xstring = {'Image of' indexstring{2:end} labels{1:min([MaximumItems length(labels)])}};
    else
      xstring = {indexstring{:} labels{1:min([MaximumItems length(labels)])}};
    end
  end
  
  if ~vsindex(2);    %don't offer if vsindex is 0
    ystring = {labels{1:min([MaximumYItems length(labels)])}};
  else    
    ystring = {indexstring{:} labels{1:min([MaximumYItems length(labels)])}};
  end
  
  if plotby < 3 & (ndims(mydataset)<3 | plotby == 0) & isempty(asimage);
    zstring = {'none' labels{1:min([MaximumItems length(labels)])}};
  end
  
else     %zero-mode plotby is special mode
  
  for ind = 1:ndims(mydataset);
    %TODO: allow multiple axisscale sets AND linear index
    if ~isempty(mydataset.axisscalename{ind})
      xstring{end+1} = mydataset.axisscalename{ind};
    else
      if ndims(mydataset)<3;
        if ind == 1
          xstring{end+1} = 'Samples';
        else          
          xstring{end+1} = 'Variables';
        end
      else     %if we are going to have more than two dims, make them all "dim x" labels
        xstring{end+1} = ['Dim ' num2str(ind)];
      end
    end
  end
  
  if isempty(asimage)
    switch length(xstring);
      case 1;
        ystring = {'Data'};   %only one dim (i.e. vector) don't offer more than showing that vector.
      case 2;
        ystring = {'Data','Mean','StdDev','Mean+StdDev','Minimum','Maximum','Number Missing'};
        default{2} = 'Mean';
      otherwise
        ystring = {'Data','Mean','Minimum','Maximum'};
        default{2} = 'Mean';
    end
  else
    ystring = {'Data','Mean','StdDev','Mean+StdDev','Minimum','Maximum','Number Missing'};
    default{2} = 'Mean';
  end
end

%------------------------------------------------------
function updatepulldown(menuhandle,newstring,default,force,enabled,selectiononly)
% Update a pull-down menu with a new string. Try to match up old selected
%  item to item in new string

%get old string info (and selection)
oldstring = getpd(menuhandle,'string');
oldselected = '';
if ~isempty(oldstring);
  try
    ind = getpd(menuhandle,'value');
    if length(ind)==1;
      oldselected = trimparens(oldstring{ind});
    end
  catch
  end
end

if nargin < 6; selectiononly = true; end
if nargin < 5; enabled = 1; end
if nargin < 4; force = []; end
if nargin < 3; default = []; end

if isempty(newstring);
  setpd(menuhandle,'string',{''},'value',1);
else

  forcetrim       = trimblanks(trimparens(force));
  newstringtrim   = trimblanks(trimparens(newstring));
  oldselectedtrim = trimblanks(trimparens(oldselected));
  defaulttrim     = trimblanks(trimparens(default));
  
  newvalue = 0;
  setpd(menuhandle,'value',1);   %fake a value to show none selected
  setpd(menuhandle,'enable','on');
  if ~selectiononly & (length(oldstring) ~= length(newstring) | any(cellne(oldstring(:),newstring(:))))
    setpd(menuhandle,'string',newstring);   %store string info
  end
  
  isunique = 1;  %assume it is unique
  if ~isempty(force);    %they had a value to force equality
    switch class(force)
      case 'char';
        matches = strcmpi(forcetrim,newstringtrim);
        if sum(matches)==1;     %can we find the force item as a single matching item in the new list?
          newvalue = min(find(matches));   %yes, select it
        else
          isunique = 0;
        end
      case 'cell';
        toselect = [];
        for item = 1:length(force);
          matches = strcmpi(forcetrim{item},newstringtrim);
          if sum(matches)>1;  %more than one line matches this force item? break out and use "default" (indicies)
            toselect = 0;
            isunique = 0;
            break;
          end
          toselect = [toselect find(matches)];
        end
        newvalue = toselect;   %yes, select it
      otherwise
        cansee = (force <= length(newstring));
        if ~all(cansee)
          evritip('pgcantseeitems','Some of the selected items are outside the length limit on the list and won''t be viewable. See settings to increase the "maximumitems" or "maximumyitems" limits.',1);
        end
        if any(cansee)
          newvalue = force(cansee);
        end
    end
  else
    isunique = 0;
  end
  
  if ~isunique & ~isempty(default);
    if isa(default,'char');
      if any(strcmpi(defaulttrim,newstringtrim));     %can we find the default selected item in the new list?
        newvalue = min(find(strcmpi(defaulttrim,newstringtrim)));   %yes, select it
      end
    else
      if default <= length(newstring);
        newvalue = default;          %was default an appropriate number? assign it
      end
    end
  end
  
  if isempty(newvalue) | newvalue == 0;   %stil none selected?
    if any(strcmpi(oldselected,newstring));     %can we find the old selected item in the new list?
      newvalue = min(find(strcmpi(oldselectedtrim,newstringtrim)));   %yes, select it
    end
  end
  
  if isempty(newvalue) | newvalue == 0;   %stil none selected?
    newvalue = 1;   %nothing worked, reset selection to first item
  end
  setpd(menuhandle,'value',newvalue);
  
end

%error checking...
selected = getpd(menuhandle,'value');
if strcmp(get(menuhandle,'style'),'popupmenu');
  
  if isempty(selected); selected = 1; end;
  if selected > length(newstring); selected = length(newstring); end
  if selected == 0; selected = 1; end
  
else  %multiline box
  
  if isempty(selected); selected = 1; end;
  selected(selected > length(newstring)) = [];
  selected(selected == 0) = 1;
  
  if ~isempty(selected);
    setpd(menuhandle,'listboxtop',min(selected))
  else
    setpd(menuhandle,'listboxtop',1)
  end
end
if ~enabled; setpd(menuhandle,'enable','off'); else; setpd(menuhandle,'enable','on'); end
setpd(menuhandle,'value',selected);

%------------------------------------------------------
function setpd(handles,varargin)
%special set command for pull-down menus. Sorts out normal menus from
%eslider-controlled menus.

for handleind = 1:length(handles)
  handle = handles(handleind);
  
  esliderObj = getappdata(handle,'eslider');
  if isempty(esliderObj)
    %normal set command
    set(handle,varargin{:});
  else
    %SPECIAL handling of "set" for eslider controlled menus
    esliderObj = getappdata(esliderObj.parent,'eslider');  %get ACTUAL current eslider
    for j=1:2:length(varargin)
      switch lower(varargin{j})
        case 'value'
          %set currently selected
          esliderObj.selection = varargin{j+1};
          
        case 'string'
          %set list
          str = varargin{j+1};
          if ~iscell(str)
            str = {str};  %make sure it is a cell array
          end
          str = str(:);  %make it a column vector cell array
          setappdata(handle,'string',str);
          esliderObj.range = length(varargin{j+1});    %update eslider by updating range
          
        case 'enable'
          set(handle,'enable',varargin{j+1})
          esliderObj.enable = varargin{j+1};
          
        case 'position'
          pos = varargin{j+1};
          pos(3) = pos(3)-15;
          set(handle,'position',pos)
          epos = [pos(1)+pos(3)+2 pos(2) 13 pos(4)];
          esliderObj.position = epos;
          
        case 'listboxtop'
          esliderObj.value = varargin{j+1};
          set(handle,'listboxtop',1);
          
        otherwise
          %all others handle by simple set command
          set(handle,varargin{j:j+1});
      end
    end
  end

end 
%------------------------------------------------------
function out = getpd(handles,property)
%special get command for pull-down menus. Sorts out normal menus from
%eslider-controlled menus.


for handleind = 1:length(handles)
  handle = handles(handleind);

  esliderObj = getappdata(handle,'eslider');
  if isempty(esliderObj)
    %normal set command
    out = get(handle,property);
  else
    %SPECIAL handling of "set" for eslider controlled menus
    esliderObj = getappdata(esliderObj.parent,'eslider');  %get ACTUAL current eslider
    switch lower(property)
      case 'value'
        %get currently selected
        out = esliderObj.selection;
        
      case 'string'
        %get string list
        out = getappdata(handle,'string');
        
      otherwise
        %all others handle by simple set command
        out = get(handle,property);
    end
  end
end


%------------------------------------------------------
function strin = trimblanks(varargin)
% Trim off any "blank" characters (spaces, "excluded" or zeros)

if nargin < 1 | isempty(varargin);
  strin = '';
  return
end
strin = varargin{1};

wascell = iscell(strin);
if ~wascell;
  strin = {strin};
end

examine = ~cellfun('isempty',strin) & cellfun('isclass',strin,'char');
strin(examine) = regexprep(strin(examine),'[ \xBB\x00]','');

if ~wascell
  strin = strin{1};
end

%------------------------------------------------------
function strin = trimparens(strin)
% Trim off any ()s from a string

if nargin < 1 | isempty(strin);
  return
end

if ~iscell(strin);
  strin = {strin};
end
examine = ~cellfun('isempty',strin) & cellfun('isclass',strin,'char');
strin(examine) = regexprep(strin(examine),'[(].[^)]*[)]','')';
strin(examine) = deblank(strin(examine));

%OLD CODE: the below code is what use USED to use to get rid of
%parenthesis. The regexprep above is now used. The old code would NOT
%remove parenthesis if there were more than two sets. The new code DOES
%remove multiple sets and MAY cause a problem.

% for k = find(examine(:)');
%   popen = strin{k} == '(' ;
%   pclose = strin{k} == ')';
%   while any(popen) & any(pclose)
%     %get indices
%     popen  = find(popen);
%     pclose = find(pclose);
%     %test for unfilterable cases (use switch/case for speed)
%     switch length(popen)
%       case 1
%         %ok
%       otherwise
%         break;
%     end
%     switch length(pclose)
%       case 1
%         %ok
%       otherwise
%         break;
%     end
%     inds = popen:pclose;
%     switch length(inds)
%       case 0
%         break;
%     end
%     %drop (___)
%     strin{k}(inds)=[];
%     strin{k} = deblank(strin{k});
%     %find next set
%     popen = strin{k} == '(' ;
%     pclose = strin{k} == ')';
%   end
% end

%------------------------------------------------------
function [str,isunique] = popupstr(handle,ascell)
%Our own version of the command popupstr. This one
% handles multiple selections and can be used with
% listboxes (or illegally assigned popup menus!)
%Optional input "ascell" will return multiple selections as
% a cell of strings.

if nargin < 2;
  ascell = 0;
end

list = getpd(handle, 'String');
selection = getpd(handle, 'Value');
if isempty(selection) | selection == 0; selection = 1; end
if iscell(list)
  %remove any "excluded" markings
  temp = char(list);
  if ~isempty(temp)
    temp = (temp(:,1)'==187); %(temp(:,1)'==183);
    for k = find(temp);
      list{k}(1:min(2,end)) = [];
    end
  end
else
  if ~isempty(list)
    %remove any "excluded" markings
    for k = find(list(:,1)'==187); %find(list(:,1)'==183);
      list(k,1:min(2,end)) = ' ';
    end
  end
end
if iscell(list)
  %drop items beyond end of list (maybe all if list is empty)
  selection(selection>length(list)) = [];
  %extract string(s) of interest
  str = list(selection);
else
  %extract string(s) of interest
  str = {};
  str1 = deblank(list(selection,:));
  for j=1:size(str1,1);
    str(j) = {str1(j,:)};
  end
end

if ~ascell;
  if length(str)>1;                       %add commas between multiple strings
    str(1:2:(length(str)*2-1)) = deblank(str);
    str(2:2:end) = {', '};
  end
  str = [str{:}];                         %convert from cell to strung-out string
else
  if length(str)==1;                       %don't do cell of one item
    str = [str{:}];                         %convert from cell to strung-out string
  end
end

isunique = all(any(diff(double(sortrows(char(trimparens(list)))))'~=0)); %all(~all(diff(double(sortrows(char(list)))')==0));

%------------------------------------------------------
function axismenuvalues = GetMenuSettings(fig)
% get the axis menu settings

[targfig,fig]  = findtarget(fig);
handles        = guidata(fig);
axismenuvalues = cell(1,3);

vsindex = getappdata(targfig,'vsindex');
if isempty(vsindex);     vsindex = [1 0]; end                  %default is turn x on and y off
if length(vsindex) == 1; vsindex = [vsindex 0]; end    %assume one number means only x no y
vsindex = vsindex*availableindicies(targfig);          %multiply by # of available indicies

[axismenuvalues{1},isunique] = popupstr(handles.xaxismenu);
% if ~isunique; axismenuvalues{1} = get(handles.xaxismenu,'value')-vsindex(1); end;

[axismenuvalues{2},isunique] = popupstr(handles.yaxismenu,1);    %get strings AS CELL!!!
% if ~isunique; axismenuvalues{2} = get(handles.yaxismenu,'value')-vsindex(2); end;

[axismenuvalues{3},isunique] = popupstr(handles.zaxismenu);
% if ~isunique; axismenuvalues{3} = get(handles.zaxismenu,'value')-1; end;

%------------------------------------------------------
function [num,whichaxes] = availableindicies(targfig,plotby)
% figure out how many indicies are available (index, axisscale, etc)
%can be called with (targfig) or (mydataset,plotby)

num = 1;      %at least ONE index (vs. index itself!)
if ~isdataset(targfig)
  %passed figure handle? get data an plotby
  mydataset     = getdataset(targfig);
  plotby        = getappdata(targfig,'plotby');
else
  %passed dataset and plotby? just copy
  mydataset = targfig;
end
plotvs        = 2-plotby+1;              %what is the "other" primary dim, that is our reference for lengths, etc.
if plotvs < 1; plotvs = 1; end

whichaxes = [];  
if plotby > 0;
  if ~isempty(mydataset)
    myaxs = mydataset.axisscale;%Pull out so loop below is quicker.
    for axset = 1:size(myaxs,2)
      if ~isempty(myaxs{plotvs,axset});
        whichaxes(end+1) = axset;
        num = num + 1;
      end
    end
  end
end
whichaxes(end+1) = 0;  %last is a "fake" set (indicating vs. index)

%------------------------------------------------------
function [ind,ind2,ind3] = GetMenuIndex(fig)
% GetMenuIndex returns the currently selected menu indices (just the values corrected for vsindex)
% with a single output, the first item in each pull down menu is returned as a 3-element vector
% with three outputs, each pulldown menu's selections are returned

[targfig,fig] = findtarget(fig);
handles = guidata(fig);

vsindex = getappdata(targfig,'vsindex');
if isempty(vsindex);     vsindex = [1 0]; end                  %default is turn x on and y off
if length(vsindex) == 1; vsindex = [vsindex 0]; end    %assume one number means only x no y
vsindex = vsindex*availableindicies(targfig);          %multiply by # of available indicies

%get menu selections
switch nargout
  case 1
    ind = {getpd(handles.xaxismenu,'value')-vsindex(1) getpd(handles.yaxismenu,'value')-vsindex(2) getpd(handles.zaxismenu,'value')-1};
  case 3
    ind    = getpd(handles.xaxismenu,'value')-vsindex(1);
    ind2   = getpd(handles.yaxismenu,'value')-vsindex(2);  
    if isempty(ind2);
      ind2 = 1;
    end
    ind3   = getpd(handles.zaxismenu,'value')-1;      %subtract 1 so no selection = 0
    
  otherwise
    error('Incorrect number of outputs for GetMenuIndex')
    
end

%------------------------------------------------------
function plotds(varargin)
% Plot a datasetobject on the current PlotGUI figure
%I/O: plotds(fig,background)
%  fig specifies the figure to plot on (default is current figure)
%  background specifies (1) that the figure should NOT be given focus
%  (brought to front of other windows). Default is 0 (bring to front)

if nargin>0;
  fig = varargin{1};
else
  fig = gcf;
end

if nargin>1
  background = varargin{2};
else
  background = 0;
end

if ~ishandle(fig) | ~strcmp(getappdata(fig,'figuretype'),'PlotGUI'); return; end    %no plot if not PlotGUI figure

[targfig,fig] = findtarget(fig);
if targfig==fig;
  %NEVER EVER put axes on plot controls figure!
  bad = findobj(fig,'type','axes');
  obj = getappdata(fig,'eslider');
  if ~isempty(obj) & isa(obj,'eslider')
    %do NOT delete eslider axis
    bad = setdiff(bad,obj.axis);
  end
  delete(bad);
  return
end
[mydataset,mylink] = getdataset(targfig);
figname = mylink.properties.figurename;
if ~isempty(figname)
  set(targfig,'name',figname);
end

handles = guidata(fig);
set(handles.plotbtn,'backgroundcolor',[.8 .8 .8]);

if isempty(mydataset) | ~isa(mydataset,'dataset') | isempty(mydataset.data); return; end   %don't do anything if no data

textinterpreter = get(0,'defaulttextinterpreter');
useti = getappdata(targfig,'textinterpreter');
if ~isempty(useti)
  try
    set(0,'defaulttextinterpreter',useti);
  catch
  end
end

[currentaxes,myaxes] = findaxes(targfig);  %find valid axes
if ~isempty(myaxes)

  set(0,'currentfigure',targfig)
  if ~background
    axes(currentaxes)
  else
    set(targfig,'currentAxes',currentaxes)
  end
  
  axesaxismenuvalues=getappdata(currentaxes,'axismenuvalues');
  if ~iscell(axesaxismenuvalues) | any(cellne(axesaxismenuvalues,getappdata(targfig,'axismenuvalues')));    %change in menus?
    myaxes = currentaxes;                %ONLY do current axis
    setappdata(currentaxes,'axismenuvalues',getappdata(targfig,'axismenuvalues'));         %copy values from fig to axes
    setappdata(currentaxes,'axismenuindex',getappdata(targfig,'axismenuindex'));
  else
    %no change in axis settings? just a plot (or change in selection, labels, etc)
    myaxes(find(myaxes==currentaxes)) = [];
    use = [];
    for oneaxis = myaxes(:)';
      if ~isempty(getappdata(oneaxis,'axismenuvalues'));      %only update those which have axismenuvalues stored and have an appropriate tag
        use = [use oneaxis];
      end
    end
    myaxes = [use currentaxes];       %do current axis last
  end
else
  figure(targfig);
  myaxes = get(targfig,'currentaxes');%gca;
end

%create selectionmenu if necessary
if isempty(findobj(targfig,'tag','selectionmenu'));
  evricopyobj(findobj(fig,'tag','selectionmenu'),targfig);    %copy selectionmenu from control fig if it hasn't been already
end

%create linemenu if necessary
if isempty(findobj(targfig,'tag','linemenu'));
  evricopyobj(findobj(fig,'tag','linemenu'),targfig);    %copy linemenu from control fig if it hasn't been already
end

%make pointer be "waiting"
if strcmp(get(targfig,'type'),'figure'); setptr(targfig,'watch'); end
if strcmp(get(fig,'type'),'figure'); setptr(fig,'watch'); end

for oneaxis = myaxes(:)';
  %Change colormap here so won't affect histogram use.
  %Willem histogram fix.
  if strcmp(mydataset.type,'image')
    cm = colormap;
    cm(1,:) = cm(2,:);%Can't find original values so use neighboring values.
    cm(end,:) = cm(end-1,:);
    colormap(cm);
  end
  if ~ishandle(oneaxis) | ~strcmp(get(oneaxis,'tag'),getappdata(targfig,'targetaxestag')); %axis went away or has the wrong tag? skip it
    continue;
  end
  if length(myaxes)>1;      %if we're doing this multiple times...
    set(targfig,'currentAxes',oneaxis);
    vals = getappdata(oneaxis,'axismenuvalues');
    inds = getappdata(oneaxis,'axismenuindex');
    if (~isempty(vals) & all(cellne(vals,cell(size(vals))))) & (isempty(inds) | all(cellne(inds,cell(size(inds))))); 
      setappdata(targfig,'axismenuvalues',vals);
      setappdata(targfig,'axismenuindex',inds);
      updatecontrols(fig);  %required because the indicies might not match the values
      % The APPROPRIATE fix is to (1) store the axismenu lists (2) update those when things change which 
      % change those lists (3) validate vals against inds and the list - i.e. list(inds) should == vals but 
      % vals take presidence (unless there are duplicate labels)
    else  %copy TO axes
      setappdata(oneaxis,'axismenuvalues',getappdata(targfig,'axismenuvalues'));
      setappdata(oneaxis,'axismenuindex',getappdata(targfig,'axismenuindex'));
    end
  end

  validateaxismenus(targfig);     %make certain axis menu selections are valid    
  
  %get some current settings which we'll re-enable after plotting
  if checkmlversion('<','8.4')
    setappdata(targfig,'viewcolorbar',~isempty(findobj(targfig,'tag','TMW_COLORBAR')));
  else
    %14b has new colorbar object.
    setappdata(targfig,'viewcolorbar',~isempty(findobj(targfig,'type','colorbar')))
  end
  setappdata(targfig,'viewgrid',get(oneaxis,{'xgrid' 'ygrid' 'zgrid' 'xminorgrid' 'yminorgrid' 'zminorgrid' }));
  setappdata(targfig,'fontinfo',get(oneaxis,{'FontAngle' 'FontName' 'FontSize' 'FontUnits' 'FontWeight'}));
  %   forcelogscale = [strcmp(get(oneaxis,'xscale'),'log') strcmp(get(oneaxis,'yscale'),'log') strcmp(get(oneaxis,'zscale'),'log')];
  
  %grab viewed axis info to determine if we were (and should again) be zoomed
  if double(findobj(allchild(oneaxis),'userdata','data'));
    oldaxis   = axis(oneaxis);
    fullaxis  = getappdata(oneaxis,'unzoomedaxisscale');
    matlab_graphics_resetplotview = getappdata(oneaxis,'matlab_graphics_resetplotview');
  else
    oldaxis  = [];
    fullaxis = [];
    matlab_graphics_resetplotview = [];
  end
  zoomstate = get(zoom(targfig));
  
  axisdir   = get(oneaxis,{'xdir' 'ydir' 'zdir'});
  if getappdata(get(targfig,'CurrentAxes'),'auto_reverse_xdir')
    %if the xdir was reversed Automatically (by plotgui), do NOT
    %remember the setting (because it might change to normal this time, and
    %even if it is still reversed, the plotscatter fn will reverse it as needed)
    axisdir{1} = 'normal';
  end
  
  if strcmp(mydataset.type,'image')
    %When data is plotted as an image the axisdir is often automatically
    %reversed (by imagesc I think). Force it back to normal here. Note that
    %imagesc doesn't respect ydir so it won't mess up image plotting.
    axisdir{2} = 'normal';
  end
  
  axislog   = [strcmp(get(oneaxis,'xscale'),'log') strcmp(get(oneaxis,'yscale'),'log') strcmp(get(oneaxis,'zscale'),'log')];
  
  mylegendinfo = legendinfo(oneaxis);
  
  ispltimg=false;

  if ~strcmp(getappdata(targfig,'plottype'),'none');
    if isempty(getappdata(targfig,'asimage'))
      if ndims(mydataset) < 4 & ~strcmp(mydataset.type,'image');
        plotscatter(targfig);
      else    %3d data
        if getappdata(targfig,'plotby') > 0;
          plotimage(targfig);
          ispltimg=true;
        else
          plotscatter(targfig);
        end
      end
    else  %asimage mode
      if getappdata(targfig,'plotby') > 1;
        plotimage(targfig);
        ispltimg=true;
      else
        plotscatter(targfig);
      end
    end
  end
  %grab new axis handle
  newaxishandle = get(targfig,'currentaxes');
  
  %assign line menu to selection (if any)
  set(findobj(allchild(newaxishandle),'type','line'),'uicontextmenu',min(double(findobj(targfig,'tag','linemenu'))));  %and assign as uicontextmenu
  %assign selection menu to selection (if any)
  set(findobj(allchild(newaxishandle),'tag','selection'),'uicontextmenu',min(double(findobj(targfig,'tag','selectionmenu'))));  %and assign as uicontextmenu
  %take objects that are supposed to be "hidden" and truely hide them now
  set(findobj(allchild(newaxishandle),'type','line','handlevisibility','callback'),'handlevisibility','off')

  if strcmp(axisdir{1},'reverse')
    set(newaxishandle,'xdir',axisdir{1});
  end

  if strcmp(axisdir{2},'reverse')
    set(newaxishandle,'ydir',axisdir{2});
  end
  
  logscale = getappdata(targfig,'viewlog');
  if isempty(logscale)
    logscale = axislog;
  end
  
  %Add check for ispltimg here and don't set log scale for images. It
  %causes unexpected behavior (different for different versions of Matlab).
  %Solo user reported missing plots. 
  %TODO: Add menu item to better handle log scale for images. 
  
  if ~isempty(logscale) & any(logscale) & ~(ispltimg)
    axis auto
    for dim=find(logscale)
      switch dim
        case 1
          set(gca,'xscale','log');
        case 2
          set(gca,'yscale','log');
        case 3
          menuindex = getappdata(targfig,'axismenuindex');
          if menuindex{3}>0
            set(gca,'zscale','log');
          end
      end
    end
    
    % Check if MIA is installed
    if evriio('mia') & ispltimg
      if ~(exist('menuindex')) % Safegaurd
        menuindex = getappdata(targfig,'axismenuindex');
      end
      negs=[false,false,false];
      for i = 1:size(menuindex,2) % Check for negative values after using log().
        if (menuindex{i}>0) & (any(log(mydataset.data(:,(menuindex{i}))) < 0))
          negs(i)=true;
        end
      end
      if any(negs)
        if menuindex{3}>0 % 3D or 2D plot
          h2 = scatter(mydataset.data(:,(menuindex{1})),mydataset.data(:,(menuindex{2})),mydataset.data(:,(menuindex{3})));
        else
          h2 = scatter(mydataset.data(:,(menuindex{1})),mydataset.data(:,(menuindex{2})));
        end
      end
      if exist('h2') % Add title & labels
        axs=get(h2,'Parent');
        set(axs,'YDir','normal'); % for good measure
        ttl=get(axs,'Title');
        targttl=get(targfig,'Name');
        set(ttl,'String',targttl);
        for i=1:length(menuindex)
          if menuindex{i}>0
            switch i
              case 1
                str=get(axs,'XLabel');
              case 2
                str=get(axs,'YLabel');
              case 3
                str=get(axs,'ZLabel');
            end
          else
            continue;
          end
          set(str,'String',mydataset.label{2}(menuindex{i},:));
        end
        % Logscale axes that are flagged
        for i=1:length(menuindex)
          if ~(isempty(logscale)) & logscale(i) & menuindex{i}>0
            switch i
              case 1
                set(axs,'XScale','log');
              case 2
                set(axs,'YScale','log');
              case 3
                set(axs,'ZScale','log');
            end
          end
        end
      end
      evritip('plotimagelogscale','When plotting an image with MIA, setting an axis (of an image density plot) to log scale may not display results correctly. For good measure a scatter plot is drawn in a separate figure, as would be drawn if MIA was not installed.',1);
    end
  end
  
  if any(axislog(1:length(logscale))~=logscale)
    oldaxis = [];
    fullaxis = [];
  end
  
  %check if there are points at the edge of the axis
  if ~plotguitypes(lower(char(getappdata(targfig,'plottype'))),'is3d');
    le = lasterror;
    try
      ax = axis;
      h  = findobj(allchild(gca),'userdata','data');
      if ~isempty(h)
        h = h(1);
        dataname = {'xdata' 'ydata'};
        for axi = [1 2];
          dat = get(h,dataname{axi});
          dat = dat(isfinite(dat));
          if min(dat)==ax(axi*2-1) | max(dat)==ax(axi*2);
            %at the edge - how bad is the spread
            delta = abs(diff(sort(dat)));
            if any(delta>0)
              delta = mean(delta(delta>0));
              ax([axi*2-1 axi*2]) = ax([axi*2-1 axi*2])+[-1 1]*delta*0.25;
              axis(ax)
            end
          end
        end
        axis(ax)
      end
    catch
      lasterror(le);  %don't reflect this error in last error
    end
  end
  
  %execute user command (if any)
  if ~isempty(getappdata(targfig,'plotcommand'))    
    try
      eval(getappdata(targfig,'plotcommand'));
    catch
      le = lasterror;
      le.message = ['Error executing PlotCommand' 10  le.message];
      rethrow(le);
    end
  end
  %also do plotcommands from evriaddon
  pcmd = evriaddon('plotgui_plotcommand');
  for cbitem = 1:length(pcmd)
    feval(pcmd{cbitem},targfig);
  end
  
  %evaluate zoom state
  zoomstatemode = 'off';
  if ~isempty(zoomstate) & ~strcmpi(zoomstate.Enable,'off')
    switch zoomstate.Motion
      case 'horizontal'
        zoomstatemode = 'xon';
      case 'vertical'
        zoomstatemode = 'yon';
      otherwise
        zoomstatemode = 'on';
    end
  end
  
  %get current axis and determine if we need to zoom
  %in
  newaxis = axis(newaxishandle);
  setappdata(newaxishandle,'unzoomedaxisscale',newaxis);
  if length(oldaxis)~=length(fullaxis) | length(fullaxis)~=length(newaxis) | length(newaxis)>4
    %major change in view (E.G. 2D->3D) or newly created axes object? (Or
    %ANY 3D plot)
    rezoom = 0;
  else
    %If old unzoomed axis (fullaxis) is the same as new unzoom AND the
    %old unzoomed axis is DIFFERENT from the observed (zoomed) axis before
    %plotting, then this dim should be zoomed
    zoomx = all(fullaxis(1:2)==newaxis(1:2)) & any(oldaxis(1:2)~=fullaxis(1:2));
    zoomy = all(fullaxis(3:4)==newaxis(3:4)) & any(oldaxis(3:4)~=fullaxis(3:4));
    if ~zoomx & ~zoomy
      %neither is zoomed, don't rezoom at all
      rezoom = 0;
    else
      %one or the other (or both) are zoomed
      if ~zoomx
        oldaxis(1:2) = newaxis(1:2);
      elseif ~zoomy
        oldaxis(3:4) = newaxis(3:4);
      end
      rezoom = 1;
    end
  end
  if ~rezoom
    setappdata(gca,'matlab_graphics_resetplotview',[]);
  else
    %must rezoom
    axz = get(newaxishandle,'ZLabel');

    if zoomx & ~zoomy
      %zooming X, but y didn't match - force y-scale for SUB portion of X to be full-scale
      oldaxis = yscale(0,oldaxis(1:2),newaxishandle);
    end
    axis(oldaxis)

    %set appropriate "unzoom" information
    if isfield(matlab_graphics_resetplotview,'XLim')
      %new zoom mode looks here for unzoomed axes range
      matlab_graphics_resetplotview.XLim = newaxis(1:2);
      matlab_graphics_resetplotview.YLim = newaxis(3:4);
      setappdata(gca,'matlab_graphics_resetplotview',matlab_graphics_resetplotview);
    else
      %This is where zoom will look for the unzoomed axes range
      setappdata(axz,'ZOOMAxesData',newaxis);
    end
  end
  zoom(targfig,zoomstatemode)
    
  %check for time-based x-axis units
  timeaxis = gettimeaxis(targfig);
  stat = getappdata(targfig,'viewaxislines');
  amv  = getappdata(targfig,'axismenuvalues');
  if ischar(amv{1}) & strcmpi(amv{1},'Image of')
    stat = zeros(1,3);
  end
  setappdata(gca,'xidateticks',false)
  setappdata(gca,'yidateticks',false)
  setappdata(gca,'zidateticks',false)
  if timeaxis(1);
    idateticks('x');
    stat(1) = 0;  %turn off axis zero if time scale
  end
  if timeaxis(2);
    idateticks('y');
    stat(2) = 0;  %turn off axis zero if time scale
  end
  if timeaxis(3);
    idateticks('z');
    stat(3) = 0;  %turn off axis zero if time scale
  end
  
  legendinfo(mylegendinfo);
  
  %turn on other modes which would have been cleared when we replotted
  if getappdata(targfig,'viewcolorbar');
    colorbar
  end
  if ~isempty(getappdata(targfig,'viewgrid')) & size(getappdata(targfig,'viewgrid'))==[1 6] & any(strcmp(getappdata(targfig,'viewgrid'),'on'));
    try
      set(newaxishandle,{'xgrid' 'ygrid' 'zgrid' 'xminorgrid' 'yminorgrid' 'zminorgrid' },getappdata(targfig,'viewgrid'))
    catch
    end
  end
  if ~isempty(getappdata(targfig,'fontinfo')) & size(getappdata(targfig,'fontinfo'))==[1 5];
    try
      set(newaxishandle,{'FontAngle'   'FontName'    'FontSize'    'FontUnits'   'FontWeight'},getappdata(targfig,'fontinfo'));
      set(get(newaxishandle,'xlabel'),{'FontAngle'   'FontName'    'FontSize'    'FontUnits'   'FontWeight'},getappdata(targfig,'fontinfo'));
      set(get(newaxishandle,'ylabel'),{'FontAngle'   'FontName'    'FontSize'    'FontUnits'   'FontWeight'},getappdata(targfig,'fontinfo'));
      set(get(newaxishandle,'zlabel'),{'FontAngle'   'FontName'    'FontSize'    'FontUnits'   'FontWeight'},getappdata(targfig,'fontinfo'));
    catch
    end
  end

  %rotate labels to angle requested
  angle = getappdata(targfig,'viewlabelangle');
  if isnumeric(angle) & ~isempty(angle);
    labelsh = findobj(newaxishandle,'userdata','label');
    if angle>90 & angle<270;
      set(labelsh,'horizontalalignment','right');
      angle=angle-180;
    end
    set(labelsh,'rotation',angle);
  end
  
  %check if some labels should be hidden
  declutterlabels(newaxishandle,getappdata(targfig,'declutter'))

  % Axis lines, as requested
  if ~isempty(stat) & stat(1); 
    vh = vline('k--');
    legendname(vh,'x-axis zero');
    uistack(vh,'bottom');
    set(vh,'HandleVisibility','off');
  end
  if length(stat)>1 & stat(2);
    yzeros = getappdata(newaxishandle,'zeros');
    if isempty(yzeros)
      yzeros = 0;
    end
    hh = hline(yzeros,'k--');
    legendname(hh,'y-axis zero')
    uistack(hh,'bottom');
    set(hh,'HandleVisibility','off');
  end
  if length(stat)>2 & stat(3);
    zh = zline('k--');
    legendname(zh,'z-axis zero');
    uistack(zh,'bottom');
    set(zh,'HandleVisibility','off');
  end
  
  if getappdata(targfig,'viewaxisplanes')
    [az,el] = view;
    ax = axis;
    if any([az el]~=[0 90]) & length(ax)>4;
      if length(stat)>0 & stat(1) & ax(1)<0 & ax(2)>0
        h = patch(ax([1 2 2 1 1]).*0,ax([3 3 4 4 3]),ax([5 6 6 5 5]),0);
        set(h,'faceAlpha',.5,'facecolor',[.5 .5 .5],'edgecolor',[0 0 0],'linestyle','--','HandleVisibility','off');
        legendname(h,'x-axis zero');
        uistack(h,'bottom');
      end
      if length(stat)>1 & stat(2) & ax(3)<0 & ax(4)>0
        h = patch(ax([1 1 2 2 1]),ax([3 3 4 4 3]).*0,ax([5 6 6 5 5]),0);
        set(h,'faceAlpha',.5,'facecolor',[.5 .5 .5],'edgecolor',[0 0 0],'linestyle','--','HandleVisibility','off');
        legendname(h,'y-axis zero');
        uistack(h,'bottom');
      end
      if length(stat)>2 & stat(3) & ax(5)<0 & ax(6)>0
        h = patch(ax([1 2 2 1 1]),ax([3 3 4 4 3]),ax([5 6 6 5 5]).*0,0);
        set(h,'faceAlpha',.5,'facecolor',[.5 .5 .5],'edgecolor',[0 0 0],'linestyle','--','HandleVisibility','off');
        legendname(h,'z-axis zero');
        uistack(h,'bottom');
      end
    end
  end
  
  if getappdata(targfig,'viewdiag'); set(dp('k--'),'HandleVisibility','off'); end;
  
  peakfindgui('update',targfig);  %update peak markers 
  
  set(newaxishandle,'buttondownfcn','plotgui(''testmakeselection'',gcbf,1)');
  
end  %end of myaxes loop


if evriio('mia');
  %Adjust color axis locking.
  cslock = getappdata(targfig,'colorscalelock');
  [junk,allaxes] = findaxes(targfig);

  %find only those axes with image or density data
  use = false(1,length(allaxes));
  for j=1:length(allaxes);
    datahs = findobj(allchild(allaxes(j)),'userdata','data');
    if ~isempty(datahs) & ismember(char(getappdata(datahs(1),'plottype')),{'image' 'density'});
      use(j) = true;
    end
  end
  allaxes = allaxes(use);
  
  if ~isempty(allaxes)
    if length(cslock)==2
      %Custom clim.
      set(allaxes,'CLim',[cslock(1) cslock(2)]);
    elseif cslock==0
      %Use global max/min, set to auto then get min/max and reset.
      set(allaxes,'ClimMode','auto');
      if length(allaxes)>1;
        allclim = get(allaxes,'CLim');
        allclim = [allclim{:}];
        cmax = max(allclim);
        cmin = min(allclim);
        set(allaxes,'CLim',[cmin cmax]);
      end
    else
      set(allaxes,'CLimMode','auto')
    end
  end
end

%update toolbar
plotgui_toolbar(targfig);

%update databox if one existed for this figure
disptable(targfig);

%%update histcontrast figure, if present
if evriio('mia'); histcontrast('update',targfig); end

%Update adjust axis gui with option.
adjustaxislimitsgui(targfig,0);

%update background color, if changed
figuretheme(targfig);

%show class set name if used
classsetnotice(targfig);

%update plot type button label
updateplottypebtn(targfig);
updatecolorbybtn(targfig);

set(0,'defaulttextinterpreter',textinterpreter);
setappdata(targfig,'viewlog',[]);   %clear any forced viewlog setting (so next time we'll go on the axis current log settings)

if strcmp(get(targfig,'type'),'figure'); setptr(targfig,'arrow'); end
if strcmp(get(fig,'type'),'figure'); setptr(fig,'arrow'); end
drawnow;

%------------------------------------------------------
function   linfo = legendinfo(linfo)
% Manage legend.

if nargin==0 
  linfo = gca;
end
if ~isstruct(linfo) %grab current legend info
  axh = linfo;
  linfo = [];
  linfo.hadlegend = false;
  linfo.legendprops = [];
  linfo.axh = axh;
  thislgnd = [];
  if checkmlversion('>=','9.3')
    %in 2017b legend will create an empty legend instead of returning an
    %empty [] if no legend is on axes. Need to search.
    mylgds = findobj(ancestor(axh,'figure'),'type','legend');
    if ~isempty(mylgds)
      mylgdsidx = [mylgds.Axes]==axh;
      if any(mylgdsidx)
        thislgnd = mylgds(mylgdsidx);
      end
    end
  else
    thislgnd = legend(axh);
  end
  linfo.handle = thislgnd;
  if ~isempty(linfo.handle)
    linfo.hadlegend = ishandle(linfo.handle);
    if linfo.hadlegend
      linfo.legendprops = get(linfo.handle);
    end
  end
elseif linfo.hadlegend
  %restore legend with new content
  try
    if ishandle(linfo.handle);
      delete(linfo.handle);
    end

    %Matlab does better job of managing legend so don't need to manually
    %adjust anymore. Only thing lost is bumping up marker size on legend.
    %However, if 4 outputs are used an old version of legend is called and
    %it gets greyed out in some circumstances (class info on images scatter). 
    lh = legend(linfo.axh,'FontSize',getdefaultfontsize);

    %TODO Delete the code below.

%     %[lh,labelhandles,outH,outM] = legend(linfo.axh,'show');
%     
%     myaddwidth = 0;%Add width if needed, some versions of matlab don't resize after font change well. 
%     
%     %Don't try adjusting the font size or marker size if there are more
%     %than 200 labels. It won't work well and if there are a ton of text
%     %and line objects it will likely stall since findobj is a slow
%     %function.
%     if length(outM)<200
%       %Adjust font to default size.
%       objhl = findobj(labelhandles, 'type', 'text');
%       set(objhl,'FontSize',getdefaultfontsize);
%       set(lh,'FontSize',getdefaultfontsize);
%       
%       %Have to manually add width in some versions of Matlab.
%       myexnt = cell2mat(get(objhl,'extent'));
%       myaddwidth = (myexnt(1)+max(myexnt(:,3)))-1;%myexnt(1) is left position of all text, max(myexnt(:,3)) is widest label. Subtract one becuase normalized units.
%       myaddwidth = myaddwidth+.01;%Add some buffer.
%       if myaddwidth<=.001
%         %Don't adust if things are fitting.
%         myaddwidth = 0;
%       end
%       
%       
%       %Set legend marker size.
%       [targfig,fig] = findtarget;
%       mymarkersize = getappdata(targfig,'viewlegendmarkersize');
%       if ~isempty(mymarkersize)
%         objhl = findobj(labelhandles, 'type', 'line'); % objects of legend of type line
%         set(objhl, 'Markersize', mymarkersize);
%       end
%     end
%     lpos = get(lh,'position');
%     lpos(1) = linfo.legendprops.Position(1);
%     lpos(2) = linfo.legendprops.Position(2)+linfo.legendprops.Position(4)-lpos(4);
%     lpos(3) = lpos(3)+.06;
%     set(lh,'position',lpos);
%     set(lh,'Interpreter',linfo.legendprops.Interpreter)
    
  catch
    %do NOT allow this action to throw error
  end
end
%------------------------------------------------------
function disptable(targfig)
% get "data" from figure (targfig) and display as a data table

%not checked? Close any existing table and clear handles
h = getappdata(targfig,'databoxhandle');
if ~getappdata(targfig,'viewtable'); 
  if ishandle(h); close(h); end
  setappdata(targfig,'databoxhandle',[]);
  return; 
else
  %checked and we USED to have a valid handle but don't anymore?
  if ~isempty(h) & ~ishandle(h);
    setappdata(targfig,'databoxhandle',[]);
    setappdata(targfig,'viewtable',0);
    return
  end
end

%get data from all items and get their tags (= labels)
[dat, tags] = tabledata(targfig);
if ~isempty(dat);
  line = createtable(dat, tags);  
else  %nothing usable there? tell the user
  line = {'<can not create table from plotted data>'};
end

databox = getappdata(targfig,'databoxhandle');
if isempty(databox) | ~ishandle(databox);
  %   databox = openfig('databox','new');
  databox = infobox(line,struct(...
    'visible','off',...
    'fontname','courier',...
    'figurename','Plotted Data',...
    'openmode','new'));
  
  %move to below target figure
  infobox(databox,'docktofigure',targfig);  %make sure it is on-screen after the move
  set(databox,'visible','on');  
  
  %set as a child so it gets closed when parent plotgui figure does
  child = getappdata(targfig,'children');
  setappdata(targfig,'children',unique([databox child]));
else
  %just update existing table
  infobox(databox,'string',line);
end

%store handle so we can update this later when we re-plot (or need close it!)
setappdata(targfig,'databoxhandle',databox);
setappdata(databox,'parent',targfig);
set(databox,'KeyPressFcn','plotgui(''keypress'',getappdata(gcbf,''parent''))','KeyReleaseFcn','plotgui(''keyrelease'',getappdata(gcbf,''parent''))');

%------------------------------------------------------
function plotimage(varargin)
%Call correct image plotting function.

options = getappdata(varargin{1});

if ~exist('plotgui_plotimage')||~options.viewdensity
  plotscatter(varargin{:});
else
  plottarget('plotgui_plotimage',varargin{:});
end


%------------------------------------------------------
function plotscatter(varargin)
% Scatter Plot 

plottarget('plotgui_plotscatter',varargin{:});


%------------------------------------------------------
function plottarget(varargin)

if nargin<=1;
  fig = gcf;
else
  fig = varargin{2};
end

[targfig,fig] = findtarget(fig);
mydataset = getdataset(targfig);

%make targetfig the current figure
if targfig ~= fig; 
  set(0,'currentfigure',targfig);
end

%get data and important info
options  = getappdata(targfig);
options.selection = getselection(targfig);
[mydataset,options] = reducedscores_data(mydataset,fig,targfig,options);

feval(varargin{1},targfig,mydataset,options);

%------------------------------------------------------
function declutterlabels(ax,fact,mode)
%Declutter labels, remove and space labels according to fact, factor to
%declutter (fact):
%  0   : None
%  0-1 : Slight 
%  1-5 : Moderate
%  5+  : Strong
%  10  : Max
%
% Options:
%   declutter_usewaitbar = 1;    Show a waitbar.
%   declutter_chunksize  = 200;   Chunk size for waitbar.
%   declutter_usepixels  = 0;     Use legacy pixel position, is slower. 
%
% NOTE: See defaultoptions() for declutter_usepixels default, depends on
% version of matlab. 2014a and older = 1. 

opts = getappdata(ancestor(ax,'figure'));

if nargin<2 | isempty(fact) | fact<0;
  fact = 10;
end

%find labels
labelsh = findobj(ax,'userdata','label');

%check if there is a declutter notice
notice = findobj(allchild(gcf),'tag','declutternotice');
if fact==0 | length(labelsh)<2
  if ~isempty(notice)
    delete(notice);
  end
  return
end

mutual         = false;  %mutual exclusion - neither label is used
if nargin<3 | length(mode)<3
  mode = [false true true];
end
stringcompare  = mode(1);   %use string comparison before deleting?
shiftnonmatch  = mode(2);   %move non-matching labels to avoid each other (experimental)
shiftmatch     = mode(3);    %combine and shift matching labels as "group"

%create the map
u  = get(ax,'units');
set(ax,'units','pixels');
sz = get(ax,'position');
set(ax,'units',u);
map.size = ceil([sz(3:4)]/fact);
map.map  = zeros(map.size);

% disp(' ')
% disp('----')
% disp(['AX Pixels: ' num2str(sz(3:4))])
% disp(['Xlim: ' num2str(get(ax,'xlim'))])
% disp(['Ylim: ' num2str(get(ax,'ylim'))])
% disp('----')
% disp(' ')
use = false(size(labelsh));  %start with NONE

% u = get(labelsh,'units');
% set(labelsh,'units','pixels');
% ext_all = get(labelsh,'extent');
% str     = get(labelsh,'string');

npts = ones(1,length(labelsh));

extscale = (log10(sqrt(fact))+.5);

numchunks = 1;
if opts.declutter_chunksize>0
  numchunks = ceil(length(labelsh)/opts.declutter_chunksize);
end

myunits = {};
mystr = {};

myxlim = get(ax,'xlim');
myylim = get(ax,'ylim');

mywaitbar = [];
if opts.declutter_usewaitbar && opts.declutter_chunksize>0
  mywaitbar = waitbar(0,'Decluttering labels, please wait... (Close to Cancel)');
end

for k = 1:numchunks
  
  if ~isempty(mywaitbar)
    if ishandle(mywaitbar)
      waitbar(k/numchunks,mywaitbar);
    else
      break
    end
  end
  thisidx = [k:numchunks:length(labelsh)];
  labelsh_chunk = labelsh(thisidx);
  
  %TODO: Check to varify that labels are in data units before calling
  %convertaxisunits.
  if ~opts.declutter_usepixels
    %Faster for 2014b and newer.
    pixelconvert = 0;
    ext_all = get(labelsh_chunk,'extent');
    if ~iscell(ext_all)
      ext_all = {ext_all};
    end
    ext_all = convertaxisunits(ext_all,sz,myxlim,myylim);
  else
    %Slower for 2014b and newer.
    pixelconvert = 1;
    thisunits = get(labelsh_chunk,'units');
    if ~iscell(thisunits)
      thisunits = {thisunits};
    end
    myunits(thisidx) = thisunits;
    set(labelsh_chunk,'units','pixels');
    thisextent = get(labelsh_chunk,'extent');
    if iscell(thisextent)
      thisextent = cell2mat(thisextent);
    end
    ext_all = thisextent;
  end
  
  thisstr = get(labelsh_chunk,'string');
  if ~iscell(thisstr)
    thisstr = {thisstr};
  end
  mystr(thisidx) = thisstr;

  for j=1:length(labelsh_chunk);
    
    %Turn off labe if it's empty.
    if isempty(mystr{thisidx(j)});
      use(thisidx(j)) = 0;
      continue;
    end
    
    %calculate index ranges
    ext  = round(ext_all(j,:)/fact);
%     if j<10
%       ext
%     end
    
    if any([ext(1:2)+ext(3:4) map.size-ext(1:2)]<0) |...
      any(isnan(ext))
      %In newer Matlab label objects where units are set to 'data' will
      %show nan for position in some conditions. 
      % https://www.mathworks.com/matlabcentral/answers/478733-find-text-graphics-extent-in-axes-data-units
      continue;  %if no part is on-axis, do not show
    end
    
    xrng = round(ext(1):(ext(1)+ext(3)*extscale));
    yrng = round(ext(2):(ext(2)+ext(4)*extscale));
    
    %remove out-of-range indicies
    xrng(xrng<1 | xrng>map.size(1)) = [];
    yrng(yrng<1 | yrng>map.size(2)) = [];
    
    if isempty(xrng) | isempty(yrng);
      use(thisidx(j)) = 1;  %keep label (JUST off map)
      continue;  %but skip declutter
    end
    
    %check the nhood
    nhood = map.map(xrng,yrng);
    if ~isempty(nhood) & ~sum(sum(nhood));    %nothing there yet? do this point
      use(thisidx(j)) = 1;
      map.map(xrng,yrng) = thisidx(j);    %and mark that nhood as populated
    elseif mutual
      %had overlap, don't display ORIGINAL point either!
      if any(any(nhood>0))
        olap = unique(nhood);
        olap(olap<1) = [];
        use(olap) = 0;
        map.map(xrng,yrng) = -1;
      end
    else
      switch stringcompare
        case true
          %see if strings match (if so drop label)
          if ~ismember(mystr{thisidx(j)},mystr(nhood(nhood>0)));
            %           current = max(max(nhood));  %get index of current label in region
            %           if any(any(~ismember(nhood,[current 0]))) | ~ismember(str{j},str(nhood(nhood>0)));
            %strings do NOT match, use it
            
            switch shiftnonmatch   %try move?
              case true
                
                mwiny = length(yrng);
                mwinx = length(xrng);
                myrng{2} = yrng(1)-mwiny:yrng(1);
                myrng{1} = yrng(end):yrng(end)+mwiny;
                mxrng{1} = xrng(1)-mwinx:xrng(1);
                mxrng{2} = xrng(end):xrng(end)+mwinx;
                mxrng{1}(mxrng{1}<1 | mxrng{1}>map.size(1)) = [];
                mxrng{2}(mxrng{2}<1 | mxrng{2}>map.size(1)) = [];
                myrng{1}(myrng{1}<1 | myrng{1}>map.size(2)) = [];
                myrng{2}(myrng{2}<1 | myrng{2}>map.size(2)) = [];
                dir = [mean(any(map.map(xrng,myrng{1}),1)) mean(any(map.map(xrng,myrng{2}),1)) mean(any(map.map(mxrng{1},yrng)',1)) mean(any(map.map(mxrng{2},yrng)',1))];
                
                badcol = any(nhood,2);
                badrow = any(nhood,1);
                %               dir = [badrow(end) badrow(1) badcol(end) badcol(1)];
                
                if all(dir==1);
                  %can't move, just use where it is
                  disp('no move');
                else
                  %Try moving label
                  %(((not fully implemented)))
                  pos = get(labelsh_chunk(j),'position');
                  
                  %                 up    = (dir(1) <  dir(2)) | all(dir(1:2)==0);
                  %                 down  =  dir(1) >  dir(2);
                  %                 left  =  dir(3) <  dir(4);
                  %                 right = (dir(3) >  dir(4)) | all(dir(3:4)==0);
                  %                 pos(1) = pos(1) + ([left right]*fact*sum(badcol)*[-1 1]');
                  %                 pos(2) = pos(2) + ([down up]*fact*sum(badrow)*[-1 1]');
                  
                  dir = dir==min(dir);
                  dir(2) = dir(2) & ~all(dir(1:2));  %turn off down if both up and down triggered
                  dir(3) = dir(3) & ~all(dir(3:4));  %turn off left if both left and right triggered
                  pos(1) = pos(1) + ([dir(3) dir(4)]*(1./extscale)*fact*sum(badcol)*[-1 1]');
                  pos(2) = pos(2) + ([dir(2) dir(1)]*fact*sum(badrow)*[-1 1]');
                  
                  set(labelsh_chunk(j),'position',pos);
                  
                  %get new extent
                  ext = get(labelsh_chunk(j),'extent');
                  xrng = round(ext(1):(ext(1)+ext(3)*extscale));
                  yrng = round(ext(2):(ext(2)+ext(4)*extscale));
                  xrng(xrng<1 | xrng>map.size(1)) = [];
                  yrng(yrng<1 | yrng>map.size(2)) = [];
                  if ~isempty(xrng) & ~isempty(yrng);
                    nhood = map.map(xrng,yrng); %only for labels on the map
                  end
                  
                end
            end
            use(thisidx(j)) = 1;
            nhood(~nhood) = thisidx(j);  %replace NOT marked with our code
            if ~isempty(xrng) & ~isempty(yrng);
              map.map(xrng,yrng) = nhood;
            end
          else
            switch shiftmatch   %try move?
              case true
                current = nhood(nhood>0);
                current = min(current(ismember(mystr(current),mystr{thisidx(j)})));
                %labels match, move existing to average of positions
                pos1 = get(labelsh_chunk(current),'position');
                pos2 = get(labelsh_chunk(j),'position');
                npts(current) = npts(current)+1;
                set(labelsh_chunk(current),'position',(pos1*(npts(current)-1)+pos2)/npts(current));
                %delete(labelsh(j));
            end
          end
      end
    end
    %     drawnow; pause(.1);
    
  end
end

if any(use)
  todel = labelsh(~use);
  todel(~ishandle(todel)) = [];
  delete(todel);
  if pixelconvert
    set(labelsh(use),{'units'},myunits(use)');
  end
else
  todel = [];
end

if ~isempty(mywaitbar)
  if ishandle(mywaitbar)
    close(mywaitbar);
  end
end

if isempty(todel)
  if ~isempty(notice)
    delete(notice);
  end
elseif isempty(notice)
  noticeax = axes(...
    'visible','off',...
    'position',[0 0 .001 .001],...
    'tag','declutternotice');
  notice = text(0,0,'Decluttered');

  %create context menu (if not there)
  hct = findobj(allchild(gcf),'tag','decluttercontextmenu');
  if isempty(hct);
    hct = uicontextmenu;
    set(hct,'tag','decluttercontextmenu');
    h2 = uimenu(hct,'label','Set New Level','callback','plotgui(''menuselection'',''ViewDeclutterCustom'');');
    h2 = uimenu(hct,'label','Hide Declutter Notice','callback','delete(findobj(allchild(gcbf),''tag'',''declutternotice''))');
  end

  set(notice,...
    'horizontalalignment','left',...
    'VerticalAlignment','bottom',...
    'color',[0 0 1],...
    'fontsize',10,...
    'tag','declutternotice',...
    'uicontextmenu',hct,...
    'buttondownfcn','if strcmp(get(gcf,''selectiontype''),''normal''); plotgui(''menuselection'',''ViewDeclutterCustom''); end');
  set(noticeax,'handlevisibility','off');
  
  %create timer to automatically clear notice after some period of time
  delobj_timer('declutternoticetimer',noticeax,10);

  evritip('plotgui_declutter');

end


%------------------------------------------------------
function ext_all = convertaxisunits(ext_all,sz,myxlim,myylim)
%Manually convert extent to pixels. 
 
xratio = sz(3)/diff(myxlim);

yratio = sz(4)/diff(myylim);

myext = cell2mat(ext_all);

xoffset = myxlim(1)*xratio;
yoffset = myylim(1)*yratio;

ext_all = floor([myext(:,1)*xratio-xoffset myext(:,2)*yratio-yoffset myext(:,3)*xratio myext(:,4)*yratio]);


%------------------------------------------------------
function [prec,rng] = precision(var)
% calculate precision and range of a variable 

switch class(var)
  case 'single'; prec = 2^(8*4); rng = [-prec/2 prec/2];
  case {'int32'}; prec = 2^(8*4); rng = [-prec/2 prec/2];
  case {'uint32'}; prec = 2^(8*4); rng = [0 prec];
  case {'int16'}; prec = 2^(8*2); rng = [-prec/2 prec/2];
  case {'uint16'}; prec = 2^(8*2); rng = [0 prec];
  case {'int8'}; prec = 2^(8*1); rng = [-prec/2 prec/2];
  case {'uint8'}; prec = 2^(8*1); rng = [0 prec];
  otherwise   %probably double
    prec = 2^(8*8); rng = [-prec/2 prec/2];
end

%------------------------------------------------------
function timeaxis = gettimeaxis(targfig,newaxis);
%retrieve and validate timeaxis settings
%newaxis is a four-element vector giving the axis limits. Used (only when
%viewtimeaxisauto is true) to trigger time mode on x-axis.

timeaxis = getappdata(targfig,'viewtimeaxis');
if isempty(timeaxis);
  timeaxis = [0 0 0];
end

%check for autotimeaxis mode
if getappdata(targfig,'viewtimeaxisauto')
  if nargin<2;
    newaxis = [get(get(targfig,'currentaxes'),'xlim') get(get(targfig,'currentaxes'),'ylim')];
  end
  if newaxis(1)>datenum('1/1/1900') & newaxis(2)<datenum('1/1/2300')
    timeaxis(1) = 1;
  end
  if newaxis(3)>datenum('1/1/1900') & newaxis(4)<datenum('1/1/2300')
    timeaxis(2) = 1;
  end
end
%------------------------------------------------------
function testmakeselection(varargin)

initaxes(varargin{1},'trigger');

[targfig,fig] = findtarget(varargin{1});
handles = guidata(fig);
if isfield(handles,'select') & get(handles.select,'value') & ~getappdata(targfig,'noselect');
  makeselection(varargin{:});
end

%------------------------------------------------------
function  select_toolbar_btn(fig,enable)

tsel = findobj(fig,'tag','pgtselect');
if ishandle(tsel)
  %This code gets called on window button motion and can create error if
  %the toolbar is in the middle of updating. There can be two select
  %buttons so use the first one. The two button condition should only be
  %momentary.
  if length(tsel)>1
    tsel = tsel(1);
  end
  status = getappdata(tsel,'isdown');
  if status==enable
    return;  %already in state that we're trying to do - exit for speed
  end
  
  %get base image
  img = getappdata(tsel,'image');
  if isempty(img);
    img = get(tsel,'cdata');
    setappdata(tsel,'image',img);
  end
  
  %change image as needed (and store enable flag)
  if enable
    scl = linspace(0.9,0.6,size(img,1))'*ones(1,size(img,2));
  else
    scl = 1;
  end
  for slab = 1:3;
    img(:,:,slab) = uint8(double(img(:,:,slab)).*scl);
  end
  set(tsel,'cdata',img);
  setappdata(tsel,'isdown',enable)  %store as flag for speed later
end


%------------------------------------------------------
function makeselection(varargin)
% Allow user to select points/etc. on current figure and
%  update selection based on that.

if nargin==1; fig = varargin{1}; else; fig = gcf; end
doShapGroups = 0;
if nargin>1
  btndown = {'btndown' 'True'}; 
  if strcmpi(varargin{2},'doShapGroups')
    %called from the shapleygui.m
    doShapGroups = 1;
    btndown = {};
  end
else
  btndown = {};
end

[targfig,fig] = findtarget(fig);
handles = guidata(fig);

if ~isempty(gcbo)
  gcbtag = get(gcbo,'tag');
  if (strcmp(gcbtag,'select') & ~get(handles.select,'value')) ...
      | (strcmp(gcbtag,'pgtselect') & get(handles.select,'value')); %unclicked button?!?
    set(handles.select,'value',0);  %force selection mode OFF
    select_toolbar_btn(targfig,0)
    uiresume(targfig);      %resume figure (we'll notice the button is up)
    return
  end
end
set(handles.select,'value',1);    %force the selection button on
select_toolbar_btn(targfig,1)
    
zoom(targfig,'off')
plotby = getappdata(targfig,'plotby');
selectionmode = getappdata(targfig,'selectionmode');
mydataset = getdataset(targfig);
if isempty(mydataset) | ~isa(mydataset,'dataset') | isempty(mydataset.data); return; end   %don't do anything if no data

%initial code for selecting groups for Shapley values from the Shapley GUI 
if doShapGroups
  if strcmp(mydataset.classname{2,end},'Shapley Groups')
    currentShapGroupClass = mydataset.class{2,end};
  else
    if ~isempty(mydataset.class{2,1})
      toAdd = 1;
    else
      toAdd = 0;
    end
    mydataset.classname{2,end+toAdd} = 'Shapley Groups';
    currentShapGroupClass = mydataset.class{2,end};
  end
end

figure(targfig);

selection = gselect(selectionmode,findobj(allchild(gca),'userdata','data'),...
  struct('modal','true',btndown{:},...
  'helptextpost','Hold down [Shift] to add to or [Ctrl] to subtract from current selection.'));       %select only from displayed data

if ~get(handles.select,'value') | isempty(selection) | (iscell(selection) & isempty([selection{:}])); 
  if ~ishandle(targfig) | ~getappdata(targfig,'selectpersistent')
    set(handles.select,'value',0);    %turn off select button (we're basically done)
    select_toolbar_btn(targfig,0)
  end
  return; 
end   %button was unpressed?!? They aborted the select.. just leave

if ~getappdata(targfig,'selectpersistent')
  set(handles.select,'value',0);    %turn off select button (we're basically done)
  select_toolbar_btn(targfig,0)
end

selectcell = insertselection(selection,targfig);
setselection(selectcell,get(targfig,'selectiontype'),targfig);
%called from shapleygui.m so do necessary code here
if doShapGroups
  groupValue = inputdlg({'Enter the group value (1,2,3,etc.) for the selected variables:'},'Set Group Value',1,{''});
  groupValue = str2double(groupValue);
  if isempty(currentShapGroupClass)
    groupClass = ones(1, size(mydataset,2))*2;
  else
    groupClass = currentShapGroupClass;
  end

  if isempty(groupValue)
    setselection({[] []},get(targfig,'selectiontype'),targfig);
  elseif ~isscalar(groupValue) || isneg(groupValue)
    evrierrordlg('Invalid group value. Use whole numbers.');
    setselection({[] []},get(targfig,'selectiontype'),targfig);
    %groupValue = inputdlg({'Enter the group value (1,2,3,etc.) for the selected variables:'},'Set Group Value',1,{''});
  else
    if isempty(mydataset.class{2,end})
      createNewClassSet = 1;
    else
      createNewClassSet = 0;
    end
    groupClass(selectcell{2}) = groupValue;
    mydataset.class{2,end} = groupClass;
    
    %store the data
    if createNewClassSet
      setobjdata(targfig,mydataset, 'class_create');
    else
      setobjdata(targfig,mydataset, 'class');
    end    
    setselection({[] []},get(targfig,'selectiontype'),targfig);
    
    setappdata(targfig,'viewclasses',length(mydataset.class(2,:)));
    setappdata(targfig,'viewclassset',length(mydataset.class(2,:)));
    set(handles.ViewClasses,'checked','on');
    plotds(targfig);
  end
  
end

%------------------------------------------------------
function chooseselectionmode(fig)
%show selection tools/mode menu

h0 = selecttoolmenu(fig);
drawnow;
curpos = get(fig,'currentpoint');
set(h0,'position',curpos(1:2));
drawnow;
set(h0,'visible','on');

%------------------------------------------------------
function selectcell = insertselection(selection,fig)
% handle insertion of a selection into appropriate entry in select cell

[targfig,fig] = findtarget(fig);
handles = guidata(fig);
mydataset = getdataset(targfig);
plotby = getappdata(targfig,'plotby');

if plotby == 0;               %if special plot mode, figure out which dim we're actually selecting on
  %   plotvs = get(handles.xaxismenu,'value');
  plotvs = getappdata(targfig,'axismenuindex');
  plotvs = plotvs{1}+1;
  if ndims(mydataset)>2;
    plotby = 3;
  end
else
  plotvs = 2-plotby+1;
end
if plotvs < 1; plotvs = [1 2]; end

selectcell = cell(1,ndims(mydataset));     %create an empty cell
if iscell(selection) & length(selection)>0;       %got a valid selection, locate selected items (identified with 1's)
  if length(selection)>1;    %do we have more than one item?
    assm = selection{end};
    for k = 1:length(selection)-1;    %and are all items the same length?
      if length(selection{k}) ~= size(assm);
        assm = selection{end};        %no, just use last one
        break
      end
      assm = assm | selection{k};   %yes, use logical "or" of all items
    end
    selection = assm;
  else
    selection = selection{end};
  end
  if strcmp(getappdata(min(double(findobj(allchild(get(targfig,'currentaxes')),'userdata','data'))),'plottype'),'density');
    %deal with density plot
    if isempty(getappdata(targfig,'asimage'));
      userdata = getappdata(min(findobj(allchild(get(targfig,'currentaxes')),'userdata','data')),'size');
      if any([userdata{:}]==1);
        %density plot of vector vs. vector (i.e. this was just very long vectors, not images)
        selectcell(plotvs) = {find(selection)};   
      else      
        %density plot of image vs. image (the usual use of density plots)
        selection = reshape(selection,userdata{:});
        [selectcell{min(setdiff(1:3,plotby))} selectcell{max(setdiff(1:3,plotby))}] = find(selection);
      end
    else
      selectcell(plotvs) = {find(selection)};           %and stick selection into the correct point
    end      
  else   %other plots
    if any(size(selection)==1) | ~isempty(getappdata(targfig,'asimage'));
      selectcell(plotvs) = {find(selection)};           %and stick selection into the correct point
    else
      [selectcell{min(setdiff(1:3,plotby))} selectcell{max(setdiff(1:3,plotby))}] = find(selection);
    end
  end
end


%------------------------------------------------------
function setselection(varargin)
%SETSELECTION handles selection updating and/or linking of selections to other windows
%USAGE: setselection(selection,'addmode',fig)
%  where selection is a cell of size 1xm where m is no more than the number of dims of data
%    each element of cell contains the indices to select (see mode)
%  'addmode' is one of: 
%     'normal' or 'set' to set the selection, 
%     'add' or 'extend' to add points to any current selection, 
%     'remove' or 'alt' to subtract points from any current selection,
%     'invert' to invert the current selection (selection input is ignored)
%     (default = normal)
%  fig is the figure handle of figure to update
%  extra flags: 
%     'noplot' can be provided to keep setselection from updating the plots (needs to be done by caller)

%set defaults
addmode = 'normal';
fig = gcf;
selection = [];
noplot = 0;
othermodes = cell(0);
for k = 1:nargin;
  myclass = class(varargin{k});
  if strfind(myclass,'matlab.ui')
    varargin{k} = double(varargin{k});
  end
  
  switch class(varargin{k})
    case 'char'
      switch varargin{k}
        case 'noplot'
          noplot = 1;
        otherwise
          addmode = varargin{k};
      end
    case 'cell'
      selection = varargin{k};
    case 'double'
      if length(varargin{k}) == 1;
          fig = varargin{k};
      else
        error(['Invalid input to setselection (input ' num2str(k) ')']);
      end
    otherwise
      error(['Invalid input to setselection (input ' num2str(k) ')'])
  end
end

if ~strcmp(addmode,'invert') & isempty(selection); error('Selection cell must be provided'); end

targfig = fig;    %don't "find target" we don't want it up front. Just assume this is the target

mydataset = getdataset(targfig);

if isempty(mydataset) | ~isa(mydataset,'dataset') | isempty(mydataset.data); return; end   %no data? don't do anything!
  
if strcmp(get(fig,'type'),'figure');
  pointerinfo = getptr(fig);
  setptr(fig,'watch');      %set pointer shape to "wait"
end

oldselection = getselection(targfig);   %get current selection
if isempty(oldselection);
  oldselection = cell(1,ndims(mydataset));
end
selectcell = oldselection;                %if selection isn't enough points, keep existing selection for unspecified dims

if length(selection) > ndims(mydataset);
  error('New selection cell cannot have more elements than the number of data dimensions');
end

if strcmp(addmode,'invert')
  %invert mode = take old selection and invert all items (unless empty)
  for k=1:length(oldselection)
    if ~isempty(oldselection{k})
      selection(k) = {setdiff(1:size(mydataset,k),oldselection{k}(:))};
    else
      selection{k} = [];
    end
  end
  addmode = 'set';
end

for k = 1:length(selection);
  sz(k) = length(selection{k});
end

if sum(sz>0)==1;   %only one non-empty select item? Normal selection
  for k = 1:length(selection);
    switch addmode
      case {'extend','add'}     %add selected points to current selection
        selectcell(k) = {union(selection{k}(:),oldselection{k}(:))};
      case {'alt','remove'}        %remove selected points from current selection
        selectcell(k) = {setdiff(oldselection{k}(:),selection{k}(:))};
      otherwise         %set points to new selection
        selectcell(k) = selection(k);
    end
  end
else
  switch addmode
    case {'extend','add','alt','remove'}        %remove/add selected points from/to current selection
      %paired selection
      dimsused = setdiff(1:length(sz),find(sz==0));
      if isempty(dimsused); 
        dimsused = [1 2];
      end
      if ~isempty(selection{dimsused(1)}) & ~isempty(selection{dimsused(2)});
        indexnew = sub2ind([size(mydataset.data,dimsused(1)) size(mydataset.data,dimsused(2))],...
          selection{dimsused(1)},selection{dimsused(2)});
      else
        indexnew = [];
      end
      if ~isempty(oldselection{dimsused(1)}) & ~isempty(oldselection{dimsused(2)});
        indexold = sub2ind([size(mydataset.data,dimsused(1)) size(mydataset.data,dimsused(2))],...
          oldselection{dimsused(1)},oldselection{dimsused(2)});
      else
        indexold = [];
      end
      
      switch addmode
        case {'extend','add'}     %add selected points to current selection
          indexmix = union(indexold,indexnew);
        case {'alt','remove'}        %remove selected points from current selection
          indexmix = setdiff(indexold,indexnew);
      end
      
      [selectcell{dimsused(1)},selectcell{dimsused(2)}] = ...
        ind2sub([size(mydataset.data,dimsused(1)) size(mydataset.data,dimsused(2))],indexmix);
      
    otherwise         %set points to new selection
      selectcell = selection;
  end
  
end

myid = getlink(fig);
inprop.selection  = selectcell;
if ~noplot
  keyword = 'selection';
else
  keyword = 'quiet';
end
updatepropshareddata(myid,'update',inprop,keyword)
set(0,'currentfigure',targfig); %make sure original setselection figure is current figure
 
if strcmp(get(fig,'type'),'figure');
  set(fig,pointerinfo{:})       %restore pointer shape
end

%------------------------------------------------------
function selection = validateselection(selection,mydataset)
%VALIDATESELECTION compares current selection to dataset size

if isempty(selection);
  return        %no selection means ignore
end

if isempty(mydataset) | ~isa(mydataset,'dataset') | isempty(mydataset.data); 
  selection = {[] [] []};
  return; 
end   

if length(selection) > ndims(mydataset);
  selection = selection(1:ndims(mydataset));
end

while length(selection) < ndims(mydataset); 
  selection{end+1} = [];     
end

for k = 1:length(selection);
  if ~isempty(selection{k}) & max(selection{k}) > size(mydataset.data,k);
    selection{k} = selection{k}(selection{k}<=size(mydataset.data,k));
  end
end

%------------------------------------------------------
function [xselmat,yselmat] = selection2mat(slct,asimage,x,y)

if isempty(slct)
  xselmat = nan;
  yselmat = nan;
  return
end

[ysel,xsel] = ind2sub(asimage,slct);
if length(x)>1
  xsel = x(xsel);
  deltax = mean(abs(diff(x)));
else
  xsel = ones(size(xsel))*x;
  deltax = 1;
end
if length(y)>1
  ysel = y(ysel);
  deltay = mean(abs(diff(y)));
else
  ysel = ones(size(ysel))*y;
  deltay = 1;
end
yselmat = [0 1 1 0 0]'*deltay*ones(1,numel(ysel))+repmat(ysel(:)'-deltay/2,5,1);
xselmat = [0 0 1 1 0]'*deltax*ones(1,numel(xsel))+repmat(xsel(:)'-deltax/2,5,1);

%------------------------------------------------------
function validateaxismenus(targfig)
%VALIDATEAXISMENUS checks axis menus for valid selection

[targfig,fig] = findtarget(targfig);
handles = guidata(fig);
plotby  = getappdata(targfig,'plotby');
mydata  = getdataset(targfig);
asimage = getappdata(targfig,'asimage');

% [ind1,ind2,ind3] = GetMenuIndex(targfig);
inds = getappdata(targfig,'axismenuindex');
if isempty(inds);
  return;
end
[ind1,ind2,ind3] = deal(inds{:});

changed = 0;
if ind3 > 0 & length(ind2) > 1;   %3D plots can only have 1 y selected
  ind2 = ind2(1);
  changed = 1;
end

% NOTE: Disabled test for multi-way. If not MIA, >3 y items are OK (although confusing)
%if plotby > 0 & (ndims(mydata) > 2 | (~isempty(asimage) & plotby>1));  %special multi-way cases and "slab" as-image mode
if plotby > 0 & (~isempty(asimage) & plotby>1);  %"slab" as-image mode
  if ind1 <= 0;     %image of
    if length(ind2) > 3;    %only allow three
%       ind2 = ind2(1:3);     %%% COMMENT OUT to allow >3 slabs in image mode (special coloring mode)
%       changed = 1;
    end
  else
    if length(ind2) > 1;    %only allow one
      ind2 = ind2(1);
      changed = 1;
    end
  end
end

if plotby == 0 & length(ind2)>1;
  ind2 = ind2(1);
  changed = 1;
end

if changed
  %we had to change something about these selections
  % switch controls, and record new settings in targfig
  updatecontrols(targfig);
  setpd(handles.yaxismenu,'value',ind2);     
  setappdata(targfig,'axismenuvalues',GetMenuSettings(fig))
  setappdata(targfig,'axismenuindex',GetMenuIndex(fig))
end

%------------------------------------------------------
function validatefamily(targfig)
%VALIDATEFAMILY checks children and parents for existance

%check if this is more than one handle (e.g multiple plotGUI controls which
%is highly illegal and needs fixing - hopefully this is the first place
%we'll get to whent this happens)
if length(targfig)>1
  targfig = targfig(ishandle(targfig));  %remove non-handles
end
if length(targfig)>1
  %look for type of figure
  tags = get(targfig,'tag');
  iscontrol = find(ismember(tags,'PlotGUI'));
  iscontrol = iscontrol(:)';  %row-vectorize
  if length(iscontrol)>1
    %more than one are PlotGUI controls?
    
    %delete any without children
    for j=1:length(iscontrol); 
      nchild(j) = length(getappdata(targfig(iscontrol(j)),'children')); 
    end
    [maxchildren,tokeep] = max(nchild);   %(even if all have same # of children, this will select only ONE)
    todelete = setdiff(1:length(iscontrol),tokeep);  %keep one with max children
    delete(targfig(iscontrol(todelete)));
    iscontrol = iscontrol(tokeep);

    %and pass ONLY that one handle out
    targfig = targfig(iscontrol(1));
    
  end
  %now - whether this was multiple controls or just multiple targets, point
  %at only the first.
  targfig = targfig(1);    
end

%do some testing for valid parents and children
if ~isempty(targfig) & ishandle(targfig)
  children = getappdata(targfig,'children');
else
  children = [];
end

children(~ishandle(children)) = [];

if ~isempty(targfig) & ishandle(targfig)
  setappdata(targfig,'children',children);
end

%------------------------------------------------------
function keypress(varargin)

targfig = varargin{1};
if strcmpi(get(targfig,'type'),'figure')
  char = double(get(targfig,'currentcharacter'));
else
  char = [];
end
if isempty(char) & nargin>1
  scrollzoom('WindowKeyPressFcn',varargin{:})
  switch varargin{2}.Key
    case 'shift'
      msg = 'Use Scroll-Wheel to zoom Y-axis only, click wheel to unzoom';
    case 'control'
      msg = 'Use Scroll-Wheel to zoom X-axis only, click wheel to unzoom';
    otherwise
      msg = '';
  end
  if strcmp(get(targfig,'type'),'figure');
    setappdata(targfig,'scrollnotice',showtempnotice(targfig,msg,'scrlwheel',4));
  end
end
  
if ~isempty(char)

  [targfig,fig] = findtarget(targfig);

  switch char
    case {'shift' 'control'}
      
    case {28 29 30 31}
      inds = getappdata(targfig,'axismenuindex');
      enable = getappdata(targfig,'axismenuenable');
      switch char
        case 28
          if enable(1)
            inds{1} = [inds{1}]-1;
          end
        case 29
          if enable(1)
            inds{1} = [inds{1}]+1;
          end
        case 31
          if enable(2)
            inds{2} = [inds{2}]+1;
          end
        case 30
          if enable(2)
            inds{2} = [inds{2}]-1;
          end
      end
      update('figure',targfig,'axismenuvalues',inds,'quiet');

    case '?'
      plotgui_searchbar(targfig);
      
    case {',' '.'}
      plotby = getappdata(targfig,'plotby');
      data   = getdataset(targfig);
      validplotby = getappdata(targfig,'validplotby');
      if isempty(validplotby)
        validplotby = 0:ndims(data);
      end
      if char==','
        plotby = validplotby(max(find(validplotby==plotby)-1,1));
      else
        plotby = validplotby(min(find(validplotby==plotby)+1,length(validplotby)));
      end
      update('figure',targfig,'plotby',plotby);

    case {'x'-'`'}
      status = getappdata(targfig,'viewaxislines');
      status = ones(1,3).*~any(status);
      update('figure',targfig,'viewaxislines',status);
    
    case {'g'-'`'}
      status = getappdata(targfig,'viewaxisplanes');
      status = ~status;
      update('figure',targfig,'viewaxisplanes',status);
      
    case {'o'-'`'}
      status = getappdata(targfig,'viewdiag');
      update('figure',targfig,'viewdiag',~status);

    case {'l'-'`'}
      status = getappdata(targfig,'viewlabels');
      update('figure',targfig,'viewlabels',~status);
      
    case {'z'-'`'}
      status = getappdata(targfig,'viewclasses');
      update('figure',targfig,'viewclasses',~status);
    case {'m'-'`'}
      %Set selection to next class in table.
      cycleselectybyclass(targfig,'r')
    case {'n'-'`'}
      %Set selection to next class in table.
      cycleselectybyclass(targfig,'f')
      
    case {'u'-'`'}
      status = getappdata(targfig,'viewnumbers');
      update('figure',targfig,'viewnumbers',~status);

    case {'f'-'`'} 
      toggleautoscale(targfig);
      
    case {'e'-'`'}
      status = getappdata(targfig,'viewexcludeddata');
      update('figure',targfig,'viewexcludeddata',~status);
      
    case {'d'-'`'}
      duplicate(fig);
      
    case {'v'-'`'}
      spawn(targfig);      
      
    case {'k'-'`'}
      cycledeclutter(targfig);

    case {'a'-'`'}
      cyclelabelangle(targfig);
      
    case {'t'-'`'}
      status = getappdata(targfig,'viewtable');
      update('figure',targfig,'viewtable',~status);
      
    case {};%'s'-'`'}
      status = getappdata(targfig,'viewlog');
      switch status*[1 2 4]';
        case 0
          status = [0 1 0];
        case 1
          status = [0 0 0];
        case 2
          status = [1 1 0];
        case 3
          status = [1 0 0];
        otherwise
          status = [0 0 0];
      end
      update('figure',targfig,'viewlog',status);
      
    case {'b'-'`'}
      exportfigure(targfig);

    case {'0'}
      menuselection('ViewSubplotsCustom')
      
    case {'1' '2' '3' '4' '5' '6' '7' '8' '9'}
      menuselection(['ViewSubplots' char]);
      
    case 27  %escape
      hselect = findobj(fig,'tag','select');
      if get(hselect,'value');
        set(hselect,'value',0);    %turn off select button
        select_toolbar_btn(targfig,0)
        setptr(targfig,'arrow');
      end
      
    otherwise
      if checkmlversion('>=','7') && ~isdeployed
        commandwindow      
      end
  end

end

%------------------------------------------------------
function keyrelease(varargin)

scrollzoom('WindowKeyReleaseFcn',varargin{:})
h = getappdata(varargin{1},'scrollnotice');
if ishandle(h); delete(h); end

%---------------------------------------------------
function cycledeclutter(targfig)

status = getappdata(targfig,'declutter');
switch status
  case 0
    update('figure',targfig,'declutter',.5);
  case 0.5
    update('figure',targfig,'declutter',1);
  case 1
    update('figure',targfig,'declutter',10);
  otherwise
    update('figure',targfig,'declutter',0);
end

%---------------------------------------------------
function toggleautoscale(targfig)

menuselection('ViewAutoScaleToggle')

%---------------------------------------------------
function cyclelabelangle(targfig)

angle = getappdata(targfig,'viewlabelangle');
if isempty(angle)
  angle = 0;
end
%rotate to next direction
angle = round(angle/45)*45;
angle = angle+45;
if angle>=360; angle = angle-360; end
menuselection(sprintf('ViewLabelAngle%i',angle));

%---------------------------------------------------
function cycleselectybyclass(targfig,direction)
%Cycle current selection by included class in 'direction' f=forward,
%r=reverse.

opts = getappdata(targfig);

if opts.plotby==0
  ind = GetMenuIndex(targfig);
  plotvs = ind{1}+1;
else
  plotvs = 3-opts.plotby;
end

if ~isfield(opts,'viewclassset')
  opts.viewclassset = 1;
end
data = getdataset(targfig);
cls  = data.class{plotvs,opts.viewclassset};
if isempty(cls)
  return
end
classlookup = data.classlookup{plotvs,opts.viewclassset};
validclasses = unique(cls(data.include{plotvs}));

%Pick first class we find.
curSelection = getselection(targfig);
curClass = curSelection;
nextClass = validclasses(1);%Set default to first class.
if iscell(curClass)
  curClass = curClass{plotvs};
end
if ~isempty(curClass)
  curClass = cls(curClass(1));
else
  %No selections so make curClass end so start at first class.
  curClass = validclasses(end);
end
idx = find(validclasses==curClass);
if idx ~= length(validclasses) & strcmp(direction,'f')
  %Go to next class.
  nextClass = validclasses(idx+1);
elseif strcmp(direction,'r')
  if idx == 1
    nextClass = validclasses(end);
  else
    %Go to previous class.
    nextClass = validclasses(idx-1);
  end
end

select = find(cls==nextClass);
if ~getappdata(targfig,'viewexcludeddata');
  %not showing excluded data?
  select = intersect(select,data.include{plotvs});
end
curSelection{plotvs} = select;
setselection(curSelection,'normal',targfig);

%---------------------------------------------------
function h0 = labelmenu(targfig)

h0 = findobj(targfig,'tag','pglabelmenu');
if isempty(h0);
  h0 = uicontextmenu('tag','pglabelmenu');
  h1 = uimenu(h0,'label','Remove Label','callback','delete(gco)');
end

%---------------------------------------------------
function h0 = plottypemenu(h0,eventdata,handles,varargin)

fig = handles.PlotGUI;
[targfig,fig] = findtarget(fig);
h0 = findobj(fig,'tag','pgplottypemenu');
selmode = getappdata(targfig,'plottype');
if isempty(h0) | ~ishandle(h0)
  %create menu if it doesn't exist
  h0 = uicontextmenu('parent',fig,'tag','pgplottypemenu');
  tools = plotguitypes;
  if ~ismember(lower(char(selmode)),lower(tools))
    checked = 'on';
  else
    checked = 'off';
  end
  uimenu(h0,'tag',['mode'],'Label','Automatic','callback','plotgui(''plottypemenu_Callback'');','position',1,'checked',checked);
  for j=1:length(tools);
    if j==1 | ismember(tools{j},{'bar' 'mesh'})
      sep = 'on';
    else
      sep = 'off';
    end
    lbl = tools{j};
    lbl(1) = upper(lbl(1));
    for pos=find(lbl=='_');
      if pos<length(lbl)
        lbl(pos:pos+1) = [' ' upper(lbl(pos+1))];
      end
    end
    checked = 'off';
    uimenu(h0,'tag',['mode' lower(tools{j})],'Checked',checked,'Label',lbl,'callback','plotgui(''plottypemenu_Callback'');','position',j+1,'separator',sep);
  end
  
  set(handles.plotbtn,'uicontextmenu',h0)
  set(h0,'callback','plotgui(''plottypemenu'',gcbo,[],guidata(gcbf))');

end

%mark current method with checkmark
children = get(h0,'children');
tags = get(children,'tag');
set(children,'checked','off');
set(children(ismember(tags,['mode' selmode])),'checked','on')

drawnow;
curpos = get(fig,'currentpoint');
set(h0,'position',curpos(1:2),'visible','on');
drawnow;

%- - - - - - - - - - - - - - - - - - - - - - - - - - - - 
function plottypemenu_Callback
[targfig,fig] = findtarget(gcbf);
mode = get(gcbo,'tag');
mode = mode(5:end);
plotgui('update','figure',gcbf,'plottype',mode);

%---------------------------------------------------
function choosecolorby(fig)

[targfig,fig] = findtarget(fig);

handles = guidata(getappdata(targfig,'controlby'));

%get current value
val    = getappdata(targfig,'colorby'); 
plotby = getappdata(targfig,'plotby');
plotvs = 2-plotby+1;
actualplotby = plotby;
if plotby==0;
  [ind1,ind2,ind3] = GetMenuIndex(fig);
  plotvs = ind1+1;
  plotby = 2-plotvs+1;     %2=>1 1=>2
  if plotby < 1; plotby = 1; end
end
if iscell(val)
  %cell format? grab value from cell
  if length(val)>=plotby & ~iscell(val{plotby})
    val = val{plotby};
  else
    val = [];
  end
end

%create list
if checkmlversion('>=','7');
  prefix = '<html><b><em>';
  postfix = '</em></b></html>';
else
  prefix = '';
  postfix = '';
end
mylist = [{[prefix 'None (hide color)' postfix]}; {[prefix 'Load...' postfix]}];
fromsource = {'none' []; 'load' []};
offset = 2; %number of items at top of list...

%check for relatives
myid = getlink(targfig);
sibuse = false(1,size(myid.siblings,1));
for j=1:size(myid.siblings,1);
  sobj = myid.siblings{j,1}.object;
  if isdataset(sobj) & any(ismember(size(sobj),size(myid.object)))
    sibuse(j) = true;
  end
end

sibuse = find(sibuse);
for j=1:length(sibuse);
  sid = myid.siblings{sibuse(j)};
  if isfield(sid.properties,'itemType')
    name = sid.properties.itemType;
  else
    name = sid.object.name;
  end
  if isempty(name)
    name = ['Sibling #' num2str(j)];
  end
  mylist = [mylist;{[prefix 'Load from ' name '...' postfix]}];
  fromsource = [fromsource;{'sibling' j}];
  offset = offset + 1;
end

%add axisscales
for mode = [plotvs plotby];
  axsc = myid.object.axisscale(mode,:);
  for j=1:length(axsc)
    if ~isempty(axsc{j})
      name = myid.object.axisscalename{mode,j};
      if isempty(name)
        name = ['Axisscale Set ' num2str(j)];
      end
      if mode==plotvs;
        name = ['Points by ' name];
      else
        name = ['Lines by ' name];
      end
      
      mylist = [mylist; name];
      fromsource = [fromsource;{'axisscale' [mode,j]}];
      offset = offset + 1;
    end
  end
  %add index too...
  if mode==plotvs;
    name = 'Points by Index';
  else
    name = 'Lines by Index';
  end  
  mylist = [mylist; name];
  fromsource = [fromsource;{'index' mode}];
  offset = offset + 1;
end

%add actual items from data
if actualplotby>0
  str = getpd(handles.yaxismenu,'string');
else
  str = {};
end
mylist = [mylist;str(:)];

if numel(val)~=1 | val<1 | val+offset>=length(mylist)
  val = 1-offset; %point at "none" if we can't recognize the item
end;

%ask user for their choice
val = listdlg('ListString',mylist,'InitialValue',val+offset,'SelectionMode','Single','PromptString','Color By...','ListSize',[250 300]);
if ~isempty(val); 
  %update (if not "canceled" out of dialog)
  val = val-offset;
  if val<1
    switch (val+offset)
      case 1
        %none
        val = [];
        
      case 2
        %load...
        cbdata = lddlgpls({'double' 'dataset'},'Load Vector for ColorBy');
        if isempty(cbdata);
          return;
        end
        
        if ~isdataset(cbdata)
          cbdata = dataset(cbdata);
        end
        
        %Get target data to find correct sizes.
        dsz = size(myid.object);
        vsz = size(cbdata);
        
        %Look for size match in rows/cols.
        mydim = find(ismember(vsz(1:2),dsz));
        
        if isempty(mydim)
          %Can't find any size matches.
          evriwarndlg(['Size of selected ColorBy data incorrect. Required size of either: ' num2str(dsz(1)) ' or ' num2str(dsz(2)) ],'ColorBy Size Warning');
          return
        end
        
        %SOMETHING matches, figure out what and what to ask user
        if length(mydim)>1
          %More than one dim can be used so ask which to use.
          % Either both dims of cbdata match one of the dims of the data OR
          % BOTH match BOTH of the dims (data matches exactly)
          if vsz(1)==vsz(2)
            %vsz is square - ask which they want
            button = questdlg('Matrix is square. Select rows or columns for ColorBy source?','ColorBy Source','Rows','Columns','Cancel','Rows');
            if isempty(button) | strcmpi(button,'Cancel')
              return
            end
            if strcmpi(button,'rows')
              mydim = 2;
            else
              mydim = 1;
            end
          else
            %colorby and data are exact same size (or transpose but same)
            %ask user whether they wanted to color points (plotby) or lines
            %(plotvs)
            button = questdlg('Colorize points or lines?','ColorBy Mode','Points','Lines','Cancel','Points');
            if isempty(button) | strcmpi(button,'Cancel')
              return
            end

            if strcmpi(button,'points')
              mydim = find(vsz(1:2)==dsz(plotvs));
            else
              mydim = find(vsz(1:2)==dsz(plotby));
            end
          end
        end
        mydimvs = 2-mydim+1;  %what is the opposite mode of the colorby data
        
        if vsz(mydimvs)>1 %is colorby info a vector or a matrix?
          %Matrix - Make list of labels.
          mylist = cbdata.label{mydimvs};
          if isempty(mylist)
            %No labels for dim so make one.
            if mydimvs==1
              mylist = sprintf('Row %d\n',[1:vsz(1)]);
            else
              mylist = sprintf('Column %d\n',[1:vsz(2)]);
            end
          end
          if ~iscell(mylist)
            mylist = str2cell(mylist);
          end
          colorby_val = listdlg('ListString',mylist,'InitialValue',1,'SelectionMode','Single','PromptString','Color By...');
          if ~isempty(colorby_val) & colorby_val>0 & colorby_val<=length(mylist)
            %choose the item we need
            if mydim == 1
              val = cbdata.data(:,colorby_val);
            else
              val = cbdata.data(colorby_val,:);
            end
          else
            return;
          end
        else
          %vector already, just return that vector
          val = cbdata.data;
        end
        
        val = val(:)';
        
      otherwise
        %something else
        switch fromsource{val+offset,1}
          case 'sibling'
            %Load from Relative
            sibid = myid.siblings{sibuse(fromsource{val+offset,2}),1};
            sobj  = sibid.object;
            selmode = find(ismember(size(sobj),size(myid.object))); %identify matching sized dims
            if length(selmode)>1; selmode = selmode(1); end
            selmodevs = 2-selmode+1;
            %create list of items available to color by
            mylist = sobj.label{selmodevs};
            if isempty(mylist)
              mylist = num2str(sobj.axisscale{selmodevs,1}');
            end
            if isempty(mylist)
              mylist = num2str((1:size(sobj,selmodevs))');
            end
            val = listdlg('ListString',mylist,'InitialValue',1,'SelectionMode','Single','PromptString','Color By...');
            if ~isempty(val) & val>0 & val<=length(mylist)
              %get item from sibling
              val = nindex(sobj.data,val,selmodevs);
              %DISABLED!!
              % The following line saves the SHARED DATA handle but this
              % doesn't keep updated so it is risky.. We'll look at this in the
              % future...
              %TODO: validate using shared data as colorby
              %           val = {{sibid val selmodevs}};
            else
              return;
            end
            
          case 'axisscale'
            %load from axisscale
            indx = fromsource{val+offset,2};
            val = myid.object.axisscale{indx(1),indx(2)};
            
          case 'index'
            indx = fromsource{val+offset,2};
            val = 1:size(myid.object,indx);
            
        end
    end
  end
  %insert into cell if not plotby 0
  if actualplotby>0
    colorby = {};
    colorby{plotby} = val;
  else
    colorby = val;
  end
  %double check targfig
  if isa(targfig, 'double')
    targfig = fig;
  end
  %setfield(targfig,'Colormap',colormap(targfig)); % old safegaurd in case colormap didn't update properly for somehow, commented out because of a bug.
  plotgui('update','figure',targfig,'colorby',colorby,'viewclasses',0);
end

%---------------------------------------------------
function dynamicmenubuild(targfig,handles)
%Build calls flyout menu because can't do it dynamically in 2011a/Mac.

%2011a+ Can't do dynamic menus. Menus are updated at end of update subfunction.

%*** Force an update if you need these menus to be rebuilt.

%-- labels, classes, and numbers --
mydataset = getdataset(targfig);
currentplotby = getappdata(targfig,'plotby');
plotby = currentplotby;
if plotby == 0;               %if special plot mode, figure out which dim we're actually selecting on
  dim = get(handles.xaxismenu,'value');
  plotby = 2-dim+1;
  if plotby < 1; plotby = 1; end
end
plotvs = 2-plotby+1;
if plotvs<1; plotvs = 1; end

%set up View/Classes fly-out menu
if ~isfinite(plotby) | isempty(mydataset) | ~isa(mydataset,'dataset') ...
    | (isempty(mydataset.class{plotvs}) & isempty(mydataset.class{plotby}) & size(mydataset.class,2)==1)...
    | ndims(mydataset)>2;
  set(handles.ViewClasses,'enable','off','checked','off');
  setappdata(targfig,'viewclasses',0);
  delete(allchild(handles.ViewClasses));
else
  viewclassset = min([getappdata(targfig,'viewclassset') size(mydataset.class,2)]);
  set(handles.ViewClasses,'enable','on');
  
  if getappdata(targfig,'viewclasses');
    enb = 'on';
  else
    enb = 'off';
  end
  set(handles.ViewClasses,'checked',enb);
  
  %create sub-menu items for each set in classes
  delete(allchild(handles.ViewClasses));
  nclasses = size(mydataset.class,2);
  emptyclasses = cellfun(@isempty,mydataset.class);
  
  %if plotvs is empty, use class labels from OTHER mode
  if all(emptyclasses(plotvs,:))
    frommode = plotby;
  else
    frommode = plotvs;
  end
  
  %If in summary mode, use mode (if) specified by user.
  userclassmode = getappdata(targfig,'classmodeuser');
  if ~isempty(userclassmode) && ~all(emptyclasses(userclassmode,:)) && currentplotby==0
    frommode = userclassmode;
  end
  
  set(handles.ViewClasses,'callback','');
  for j=1:nclasses
    if emptyclasses(frommode,j)
      %no classes in this set? do not show (skip to next)
      continue;
    end
    lbl = mydataset.classname{frommode,j};
    if isempty(lbl)
      lbl = ['Set ' num2str(j)];
    end
    h1=uimenu(handles.ViewClasses,'tag',['ViewClassSet'],'userdata',j,'label',lbl,'callback','plotgui(''menuselection'',gcbo)');
    if viewclassset==j;
      set(h1,'checked',enb);
      if ismac
        %Add drawnow here of macs to see if it helps update problem.
        %Checked wasn't getting updated.
        drawnow
      end
    end
  end
  h1=uimenu(handles.ViewClasses,'tag','ViewChangeSymbols','label','Change Symbols','Separator','on','callback','plotgui(''menuselection'',gcbo)');
  
  classsymbolmenu(h1);
  classsymbolmenu(handles.LineChangeSymbol);
    
  h1=uimenu(handles.ViewClasses,'tag',['ViewConnectClasses'],'label','Outline Class Groups','Separator','off');
  h2=uimenu(h1,'tag',['ConnectClassMethodNone'],'label','None','Separator','off','callback','plotgui(''menuselection'',gcbo)');
  if ~getappdata(targfig,'connectclasses');
    set(h2,'checked',enb);
  end
  
  mlist = connectclasslist(2);

  for mi = 1:size(mlist,1);
    if mi==1;
      sep = 'on';
    else
      sep = 'off';
    end
    h2=uimenu(h1,'tag',['ConnectClassMethod' mlist{mi,1}],'label',mlist{mi,2},'Separator',sep,'callback','plotgui(''menuselection'',gcbo)');
    if getappdata(targfig,'connectclasses') & strcmpi(getappdata(targfig,'connectclassmethod'),mlist{mi,1});
      set(h2,'checked',enb);
    end
  end
  h2=uimenu(h1,'tag','ConnectClassMethodLimit','label','Set Confidence Limit...','Separator','on','callback','plotgui(''menuselection'',gcbo)');
  
  h1=uimenu(handles.ViewClasses,'tag','ViewClassesAsOverlay','label','Classes as Overlay','callback','plotgui(''menuselection'',gcbo)');
  if getappdata(targfig,'viewclassesasoverlay')
    set(h1,'checked','on');
  else
    set(h1,'checked','off');
  end
  
end

%set up View/Labels fly-out menu
if isempty(mydataset) | ~isa(mydataset,'dataset')| isempty(mydataset.label{plotvs}) ...
    | ~isempty(getappdata(targfig,'asimage')) | ndims(mydataset)>2;
  set([handles.ViewLabels],'enable','off','checked','off');
  setappdata(targfig,'viewlabels',0);
else
  viewlabelset = min([getappdata(targfig,'viewlabelset') size(mydataset.label,2)]);
  set([handles.ViewLabels],'enable','on');
  
  if getappdata(targfig,'viewlabels');
    enb = 'on';
  else
    enb = 'off';
  end
  set(handles.ViewLabels,'checked',enb);
  
  %create sub-menu items for each set in labels
  delete(allchild(handles.ViewLabels));
  nsets = size(mydataset.label,2);
  
  set(handles.ViewLabels,'callback','');
  for j=1:nsets;
    if isempty(mydataset.label{plotvs,j});
      %no labels in this set? do not show (skip to next)
      continue;
    end
    lbl = mydataset.labelname{plotvs,j};
    if isempty(lbl)
      lbl = ['Set ' num2str(j)];
    end
    h1=uimenu(handles.ViewLabels,'tag',['ViewLabelSet'],'userdata',j,'label',lbl,'callback','plotgui(''menuselection'',gcbo)');
    if viewlabelset==j;
      set(h1,'checked',enb);
    end
  end
  
end

%set up View/Axisscale fly-out menu
if isempty(mydataset) | ~isa(mydataset,'dataset')| isempty(mydataset.axisscale{plotvs}) ...
    | ~isempty(getappdata(targfig,'asimage')) | ndims(mydataset)>2;
  set([handles.ViewAxisscale],'enable','off','checked','off');
  setappdata(targfig,'viewaxisscale',0);
else
  viewaxisscaleset = min([getappdata(targfig,'viewaxisscaleset') size(mydataset.axisscale,2)]);
  set([handles.ViewAxisscale],'enable','on');
  
  if getappdata(targfig,'viewaxisscale');
    enb = 'on';
  else
    enb = 'off';
  end
  set(handles.ViewAxisscale,'checked',enb);
  
  %create sub-menu items for each set in Axisscale
  delete(allchild(handles.ViewAxisscale));
  nsets = size(mydataset.axisscale,2);
  
  set(handles.ViewAxisscale,'callback','');
  for j=1:nsets;
    if isempty(mydataset.axisscale{plotvs,j});
      %no Axisscale in this set? do not show (skip to next)
      continue;
    end
    lbl = mydataset.axisscalename{plotvs,j};
    if isempty(lbl)
      lbl = ['Set ' num2str(j)];
    end
    h1=uimenu(handles.ViewAxisscale,'tag',['ViewAxisscaleSet'],'userdata',j,'label',lbl,'callback','plotgui(''menuselection'',gcbo)');
    if viewaxisscaleset==j;
      set(h1,'checked',enb);
    end
  end
  
end
%---------------------------------------------------
function classsymbolmenu(pmenu)

delete(get(pmenu,'children'));

%create a list of markers
sets = classmarkers('options');
systemsets = fieldnames(classmarkers('factoryoptions'));
list = fieldnames(sets);
list = setdiff(list,'functionname');
list = list(:);

%sort into builtin and user-defined
systemseparator = '--- System ---';
userseparator   = '--- User-Defined ---';
builtin = ismember(list,systemsets);
list = [{systemseparator};list(builtin);{userseparator};list(~builtin)];
separator  = [1 sum(builtin)+2];  %indicate that "user defined" line is bad

desc = list;
for j=1:length(desc)
  desc{j}(desc{j}=='_') = ' ';
end
item = {'tag','ViewChangeSymbolsCustom','label','Custom...','callback','plotgui(''menuselection'',gcbo)'};
uimenu(pmenu,item{:});
sep = 'off';
for j = 1:length(desc);
  if strcmpi(list{j},'default')
    desc{j} = 'default set';
  end
  if ~ismember(j,separator)
    item = {'tag','ViewChangeSymbolsSelect','label',desc{j},'userdata',list{j},'separator',sep,'callback','plotgui(''menuselection'',gcbo)'};
    uimenu(pmenu,item{:});
    sep = 'off';
  else
    sep = 'on';
  end
end
set(pmenu,'callback','');

%---------------------------------------------------
function h0 = selecttoolmenu(fig)
%Display context menu for Selection Tool toolbar button.

[targfig,controlfig] = findtarget(fig);
h0 = findobj(fig,'tag','pgselecttoolmenu');
selmode = getappdata(targfig,'selectionmode');
mydataset = getdataset(targfig);

if isempty(h0)
  %create menu if it doesn't exist
  h0 = uicontextmenu('parent',fig,'tag','pgselecttoolmenu');
  tools = get(findobj(controlfig,'tag','EditSelectionMode'),'children');
  prevsep = 'off';
  for j=1:length(tools);
    prop = get(tools(end+1-j));
    if checkmlversion('>=','9.3')
      uimenu(h0,'tag',prop.Tag,'Label',prop.Text,'separator',prop.Separator,'callback',prop.MenuSelectedFcn,'position',j);
    else
      uimenu(h0,'tag',prop.Tag,'Label',prop.Label,'separator',prop.Separator,'callback',prop.Callback,'position',j);
    end
  end
  uimenu(h0,'tag','EditSelectClass','Label','By Class','separator','on','callback','plotgui(''menuselection'',''EditSelectClass'',gcbf)','position',length(tools)+1); 
  uimenu(h0,'tag','EditSearchBar','Label','Search Bar...','separator','on','callback','plotgui(''menuselection'',''EditSearchBar'',gcbf)','position',length(tools)+2); 
end

%mark current method with checkmark
children = get(h0,'children');
set(children,'checked','off');
for j = 1:length(children);
  if strcmpi(['selectionmode' selmode],get(children(j),'tag'))
    set(children(j),'checked','on');
  end
end
curpos = get(fig,'currentpoint');

if fig==targfig
  curpos = getcurrentpointjava(targfig);
end

%Disable plotcls menu item if no classes are available.
opts = getappdata(targfig);
if opts.plotby==0
  ind = GetMenuIndex(targfig);
  plotvs = ind{1}+1;
else
  plotvs = 3-opts.plotby;
end
pcls_h = findobj(h0,'tag','EditSelectClass');

if plotvs<1; plotvs = 1; end
if isempty(mydataset) | ~isa(mydataset,'dataset') | isempty(mydataset.class{plotvs}) | ndims(mydataset)>2;
  set([pcls_h],'enable','off');
else
  set([pcls_h],'enable','on');
end

set(h0,'position',curpos(1:2),'visible','on');

htb = getappdata(targfig,'PlotguiSearchBar');
if ~isempty(htb)
  set(findobj(h0,'tag','EditSearchBar'),'checked','on');
end

%---------------------------------------------------
function h0 = connectclassmenu(fig)
%Display context menu for Connect Class toolbar button.

[targfig,controlfig] = findtarget(fig);
h0 = findobj(fig,'tag','pgconnectclassmenu');
currentmethod = getappdata(targfig,'connectclassmethod');
connectclass = getappdata(targfig,'connectclasses');
if ~connectclass
  currentmethod = 'none';
end

if isempty(h0)
  %create menu if it doesn't exist
  h0 = uicontextmenu('parent',fig,'tag','pgconnectclassmenu');
  tools = connectclasslist(2);  %list of available connect modes
  uimenu(h0,'tag','ConnectClassMethodNone','Label','None','callback','plotgui(''menuselection'',gcbf);','position',1,'userdata','none','separator','off');
  for j=1:size(tools,1);
    if j==1
      sep = 'on';
    else
      sep = 'off';
    end
    uimenu(h0,'tag',['ConnectClassMethod' tools{j,1}],'Label',tools{j,2},'callback','plotgui(''menuselection'',gcbf);',...
      'position',j+1,'userdata',lower(tools{j,1}),'separator',sep);
  end
  uimenu(h0,'tag','ConnectClassMethodLimit','Label','Set Confidence Limit...','callback','plotgui(''menuselection'',gcbf);','position',j+2,'separator','on');

end

%mark current method with checkmark
children = get(h0,'children');
set(children,'checked','off');
for j = 1:length(children);
  if strcmpi(currentmethod,get(children(j),'userdata'))
    set(children(j),'checked','on');
  end
end
curpos = get(fig,'currentpoint');

if fig==targfig
  curpos = getcurrentpointjava(targfig);
end

set(h0,'position',curpos(1:2),'visible','on');

%---------------------------------------------------
function h0 = viewclassmenu(fig)
%Display context menu for Connect Class toolbar button.

[targfig,fig] = findtarget(fig);
h0 = findobj(targfig,'tag','pgviewclassmenu');
viewclasses = getappdata(targfig,'viewclasses');
classset = getappdata(targfig,'viewclassset');

if isempty(h0)
  %create menu if it doesn't exist
  h0 = uicontextmenu('parent',targfig,'tag','pgviewclassmenu');
end

delete(allchild(h0));

%find out what classes we should list
mydataset = getdataset(targfig);
plotby = getappdata(targfig,'plotby');
if plotby == 0;               %if special plot mode, figure out which dim we're actually selecting on
  handles = guidata(fig);
  dim = get(handles.xaxismenu,'value');
  plotby = 2-dim+1;
  if plotby < 1; plotby = 1; end
end
plotvs = 2-plotby+1;

userclassmode = getappdata(targfig,'classmodeuser');
if ~isempty(userclassmode) && getappdata(targfig,'plotby')==0
  plotvs = userclassmode;
end

if plotvs<1; plotvs = 1; end

nclasses = size(mydataset.class,2);

%if plotvs is empty, use class labels from OTHER mode
if all(cellfun('isempty',mydataset.class(plotvs,:)))
  frommode = plotby;
else
  frommode = plotvs;
end
classlist = {};
classidx = [];
for j=1:nclasses;
  if isempty(mydataset.class{frommode,j})
    continue;
  end
  lbl = mydataset.classname{frommode,j};
  if isempty(lbl)
    lbl = ['Set ' num2str(j)];
  end
  classlist(end+1,1:2) = {lbl j};
  classidx(end+1) = j;
end

if isempty(classlist)
  return
end
if size(classlist,1)==1
  %only one class set? revert to OLD behavior (just toggle viewclasses)
  setappdata(targfig,'viewclasses',~viewclasses);
  plotds(targfig);
  return
end
 
if ~viewclasses | isempty(classlist)
  chk = 'on';
else
  chk = 'off';
end
uimenu(h0,'tag','ViewClassNone','Label','None','callback','plotgui(''menuselection'',''ViewClassSet'');','position',1,...
  'userdata',0,'separator','off','checked',chk);
for j=1:size(classlist,1);
  if j==1
    sep = 'on';
  else
    sep = 'off';
  end
  if viewclasses & j==classset
    chk = 'on';
  else
    chk = 'off';
  end
  uimenu(h0,'tag',['ViewClassSet' num2str(j)],'Label',classlist{j},'callback','plotgui(''menuselection'',''ViewClassSet'');',...
    'position',j+1,'userdata',classidx(j),'separator',sep,'checked',chk);
end

curpos = getcurrentpointjava(targfig);

set(h0,'position',curpos(1:2),'visible','on');

%---------------------------------------------------
function curpos = getcurrentpointjava(targfig)
%Replace 'get currentpoint' with java based pointer position because
%current point stops updating as soon as mouse leaves main window area. It
%does not update while mouse moves over toolbar. So if user moves mouse out
%of window when it's not directly under button, then menu shows up somewhere weird. 

figpos = get(targfig,'position');
curpos = getmouseposition(targfig);

%if on target figure, make sure position is reasonably "on figure"
if curpos(1)>figpos(3)-40
  curpos(1) = 1;
end
if curpos(2)<50
  curpos(2) = figpos(4);
end

%---------------------------------------------------
function out = connectclasslist(listtype)
%list of VALID connect class modes

if nargin<1
  listtype = 1;
end

switch listtype
  case 1
    %simple list of valid types
    out = {'sequence' 'outline' 'pca' 'spider' 'means' 'delaunay' 'connect'};
  case 2
    %list of types to include in menus (along with description) and order
    %to cycle through them if automatic cycle is used
    out = {
    'Sequence'  'Points in Sequence'
    'Outline'   'Border Points'
    'PCA'       'Confidence Ellipse'
    'Spider'    'Spider'
    'Means'     'Mean at each X'
    };
end

%---------------------------------------------------
function out = setobjdata(fig,data,keyword)
%Set data object to figure. This will add or subscribe to a sharred data
%object. Output 'out' is the data that was set.

 mylink = getlink(fig);  %get any current linked data
 if isshareddata(data)
   %If shared data is not a dataset then cause error so don't load.
   if ~isdataset(data.object)
     error('Incoming data is not a DataSet Object and can''t be plotted by plogtui.')
   end
   
   %adding link to data
   if ~isshareddata(mylink) | isempty(mylink) | mylink~=data
     %adding link to a new data object
     if isshareddata(mylink) & isvalid(mylink)
       %remove link to previous object
       linkshareddata(mylink,'remove',fig);
     end
     %Adding linked data for first time, 'data' is a link to data.
     linkshareddata(data,'add',fig,'plotgui');
     setappdata(fig,'plotguilinkeddata',data);
   end
   out = data.object;
   return
end

if nargin<3
  keyword = '';
end
if isempty(mylink)
  origdata = [];
else
  origdata = mylink.object;
end
datasource = fig;
out = [];
if isempty(origdata) | ~isa(origdata,'dataset') | isempty(origdata.data) | ~isa(data,'dataset') | ((isstruct(data)||isa(data,'dataset')) && any(origdata.moddate ~= data.moddate));
  %if data is different OR there was no data, save it

  %decide how to save it
  if strcmp(getappdata(datasource,'figuretype'),'volatile')
    close(datasource);
  else
    if isempty(mylink)
      %Adding data for first time.
      %If plotgui is the parent of shareddata, it should always try to
      %adopt out its data to subscribers when closing so add property to
      %specify this.
      myprops.removeAction = 'adopt';
      myid = setshareddata(fig,data,myprops);
      linkshareddata(myid,'add',fig,'plotgui');
      out = getshareddata(myid);
      setappdata(fig,'plotguilinkeddata',myid);
    else
      %Update shared data.
      setshareddata(mylink,data,keyword);
      out = data;
    end
  end
end


%---------------------------------------------------
function [data, sourceid] = getobjdata(fig,varargin)
%Get shared data object for given figure. Input 'fig' should always be the
%figure being acted on and not a "parent" figure or some other lineage
%object.

sourceid = getlink(fig);
if isempty(sourceid)
  data = [];
  datasource = fig;
else
  data = sourceid.object;
  datasource = sourceid.source;
end

%---------------------------------------------------
function out = isloaded(fig)
%Is there data loaded in the figure.

out = isempty(getappdata(fig,'plotguilinkeddata'));

%---------------------------------------------------
function mylink = getlink(fig)
%Get the source id for given figure. Use this function to provide error
%checking and flexibility if need in future (e.g., with multiple objects per
%figure).
mylink = getappdata(fig,'plotguilinkeddata');
if length(mylink)>1
  error('Too many data objects linked to EditDS figure.');
end

%--------------------------------------------------
function out = strictedit
%returns "true" (1) if software is currently limited to strict editing mode

persistent internal_strictedit

if isempty(internal_strictedit)
  %not yet defined
  internal_strictedit = false;   %assume NOT unless...
  
  %any add-on functions want strict editing
  fns = evriaddon('strictedit');
  for j=1:length(fns)
    if feval(fns{j});
      internal_strictedit = true;
      break;
    end
  end
  
end

out = internal_strictedit;

%--------------------------------------------------
function selection = getselection(targfig)
%return the current selection on the given target figure's DSO

link = getlink(targfig);
if ~isempty(link)
  selection = validateselection(link.properties.selection,link.object);     %make certain selection is valid
else
  selection = {};
end

%---------------------------------------------------
function propupdateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object.
%The myobj variable comes in with the following structure.
%
%   sourceh     - handle to object where shared data will be stored (in appdata).
%   myobj       - shared data (object).
%   myname      - [string] name of shared object.
%   myporps     - (optional) structure of "properties" to associate with
%                 shared data.
%
%Option input varargin can be a "keyword" or other associated input.

noplot = false; %assume we're gonna have to replot

switch keyword
  case 'selection'
    %look for selection objects already on axes and do fast selection if
    %possible
    
    %first check if we are showing labels and are selection-limiting those
    axs = findobj(h,'type','axes','tag','');  %all axes we can plot on
    if getappdata(h,'labelselected') & (getappdata(h,'viewlabels') | getappdata(h,'viewnumbers') | getappdata(h,'viewaxisscale'))
      axs = [];  %do NOT use quickselect if labels shown and only selected are labeled
    end
    for j=1:length(axs)
      selh = findobj(allchild(axs(j)),'tag','selection'); %selection objects?
      
      if ~isempty(selh)
        imgsel = getappdata(selh(end),'imageselection');
        
        if isempty(imgsel)
          %Non-image (scatter/etc) plot
          realx = getappdata(selh(end),'realxdata');
          selmode = getappdata(selh(end),'selectionmode');
          if ~isempty(realx) & ~isempty(selmode);
            selind = myobj.properties.selection{selmode};
            mylegendinfo = legendinfo(axs(j));
            for k=1:length(selh)
              xdata = get(selh(k),'xdata');
              xdata = xdata.*nan;
              
              %copy over selection on plotvs mode from realx to xdata
              ind   = getappdata(selh(k),'subindex');
              selmask = getappdata(selh(k),'selectionmask');
              if ~isempty(ind)
                %this selection object only handles a subset of the items
                if ~isempty(selmask)
                  myselind = intersect(selind,selmask);
                else
                  myselind = selind;
                end
                [rselind,xselind] = intersect(ind,myselind);
              else
                %doe the object have some items "masked" (not shown)
                if ~isempty(selmask)
                  xselind = intersect(selind,selmask);
                  rselind = xselind;
                else  %this selection object handles ALL items
                  xselind = selind;
                  rselind = selind;
                end
              end
              xdata(xselind) = realx(rselind);
              
              set(selh(k),'xdata',xdata,'visible','on'); %save xdata back to object
              
              %enable/disable visibility in legend based on there being
              %some values selected
              if ~isempty(xselind)
                vis = 'on';
              else
                vis = 'off';
              end
              set(selh(k),'handlevisibility',vis);
              
              %say we don't need to plot
              noplot = true;
            end
            legendinfo(mylegendinfo);
            
          else
            %couldn't find selection object on a sub-plot - FORCE redraw of
            %figure (all axes) and leave this logic now
            noplot = false;
            break;
          end
          
        else
          %IMAGE selection
          mylegendinfo = legendinfo;
          if isdataset(myobj.object) & strcmpi(myobj.object.type,'image')
            selmode = myobj.object.imagemode;
          else
            selmode = 1;
          end
          selind = myobj.properties.selection{selmode};
          [xselmat,yselmat] = selection2mat(selind,imgsel.asimage,imgsel.x,imgsel.y);
          if ishandle(selh);
            set(selh,'xdata',xselmat,'ydata',yselmat,'visible','on');
            if isempty(selind)
              vis = 'off';
            else
              vis = 'on';
            end
            set(selh,'handlevisibility',vis);
            noplot = true;
            legendinfo(mylegendinfo);
          end
        end
      else
        %couldn't find selection object on a sub-plot - FORCE redraw of
        %figure and leave this logic now
        noplot = false;
        break;
      end
    end
    
  otherwise
    %assume we can just update the plot
end
if ~noplot
  plotds(h,1);  %update plot in background
end

%---------------------------------------------------
function updateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object.
%The myobj variable comes in with the following structure.
%
%   sourceh     - handle to object where shared data will be stored (in appdata).
%   myobj       - shared data (object).
%   myname      - [string] name of shared object.
%   myprops     - (optional) structure of "properties" to associate with shared data.
%NOTE: Any include changes will be handled here.

if nargin<3
  keyword = '';
end
if nargin<4
  userdata = [];
end
if strcmpi(keyword,'delete')
  if ishandle(h)
    close(h);
  end
  return
end
if ~isdataset(myobj.object)
  if ishandle(h);
    close(h)
  end
  return
end
update('figure',h,'background');

%---------------------------------------------------
function getselectionstats(targfig,handles)

[mydataset,datasource] = getdataset(targfig);

if isempty(handles)||nargin<2
  [targfig,fig] = findtarget(targfig);     %get target figure (if any)
  handles = guidata(fig); 
end

selection = getselection(targfig);

plotby = getappdata(targfig,'plotby');
if plotby == 0;               %if special plot mode, figure out which dim we're actually selecting on
  dim = get(handles.xaxismenu,'value');
  plotby = 2-dim+1;
  if plotby < 1; plotby = 1; end
end

datasub = mydataset;
for j=1:length(selection);
  if ~isempty(selection{j});
    datasub = nindex(datasub,selection{j},j);
    datasub.include{j} = 1:size(datasub,j);
  end
end
if  plotby==1
  datasub = permute(datasub,[2 1 3:ndims(datasub)]);
end
editds(summary(datasub));

%---------------------------------------------------
function getselectioninfo(targfig,handles,selection)


[mydataset,datasource] = getdataset(targfig);

if isempty(handles)||nargin<2
  [targfig,fig] = findtarget(targfig);     %get target figure (if any)
  handles = guidata(fig); 
end

if nargin<3 || isempty(selection)
  selection = getselection(targfig);
end

plotby = getappdata(targfig,'plotby');
if plotby == 0;               %if special plot mode, figure out which dim we're actually selecting on
  dim = get(handles.xaxismenu,'value');
  plotby = 2-dim+1;
  if plotby < 1; plotby = 1; end
end
[numsets,whichsets] = availableindicies(mydataset,plotby);
whichsets(end)=[];  %drop index set
numsets = numsets-1;

timeaxis = gettimeaxis(targfig);

infostring = cell(0);

temp1 = [];
axtemps = cell(1,numsets);
temp2 = [];
temp2b = [];  %for images only
temp3 = {};
temp4 = {};
for k = 1:length(selection);
  if ~isempty(selection{k});
    
    if length(selection{k})>1
      infostring{end+1} = sprintf('Total of %i Selected Items',length(selection{k}));
    end

    shownaxisscalename = zeros(1,numsets);
    showndim           = false;
    shownlabelname     = false;
    shownclassname     = false;
    for slcteditems = selection{k}(:)'
      selection{k} = slcteditems;
      %look for axis scale info

      for axsetind = 1:numsets
        axisscale = mydataset.axisscale{k,axsetind};
        if isempty(axisscale); continue; end
        temp1 = axtemps{axsetind};        
        if ~isempty(temp1); temp1 = [temp1 ', ']; end
        if timeaxis(1) & all(isfinite(axisscale(selection{k})))
          try
            axstr = datestr(axisscale(selection{k}));
          catch
            axstr = num2str(axisscale(selection{k}));
          end              
        else
          axstr = num2str(axisscale(selection{k}));
        end
        if ~shownaxisscalename(axsetind)
          name = mydataset.axisscalename{k,axsetind};
          if isempty(name);
            switch k
              case 1
                name = 'on Arbitrary Axis';
              case 2
                name = 'on Arbitrary Axis';
              otherwise
                name = ['on Axis ' int2str(k)];
            end
          end
          shownaxisscalename(axsetind) = true;
          temp1 = [temp1 ' ' name ':'];
        end
        temp1 = [temp1  axstr];
        axtemps{axsetind} = temp1;
        
      end

      %add index info
      if ~isempty(temp2); temp2 = [temp2 ', ']; end
      if ~isempty(temp2b); temp2b = [temp2b ', ']; end
      if ~showndim
        if k == 1;
          if isempty(getappdata(targfig,'asimage'));
            temp2 = [temp2 'Row: '];
          else
            [i,j] = ind2sub(getappdata(targfig,'asimage'),selection{1});
            temp2 = [temp2 'Image [Row Column] : '];
            temp2b = [temp2b 'Pixel: '];
          end
        elseif k == 2;
          temp2 = [temp2 'Column: '];
        else
          temp2 = [temp2 'Dim ' int2str(k) ' index: '];
        end
        showndim = true;
      end
      if k == 1;
        if isempty(getappdata(targfig,'asimage'));
          temp2 = [temp2 int2str(selection{1})];
        else
          [i,j] = ind2sub(getappdata(targfig,'asimage'),selection{1});
          temp2 = [temp2 ' [' int2str(i) ' ' int2str(j) ']'];
          temp2b = [temp2b ' ' int2str(selection{1})];
        end
      elseif k == 2;
        temp2 = [temp2 int2str(selection{2})];
      else
        temp2 = [temp2 int2str(selection{k}) ' '];
      end

      %look for labels to give info on
      nsets = size(mydataset.label,2);
      for myset = 1:nsets
        labels = mydataset.label{k,myset};
        if ~isempty(labels);
          if length(temp3)>=myset & ~isempty(temp3{myset});
            temp3{myset} = [temp3{myset} ', '];
          else
            temp3{myset} = '';
          end
          if length(shownlabelname)<myset | ~shownlabelname
            name = mydataset.labelname{k,myset};
            if ~isempty(name); temp3{myset} = [temp3{myset} name ': ']; end
            shownlabelname(myset) = true;
          end
          if ~iscell(labels);
            temp3{myset} = [temp3{myset} labels(selection{k},:)];
          else
            temp3{myset} = [temp3{myset} labels{selection{k}}];
          end
        end
      end

      %look for class to give info on
      nsets = size(mydataset.class,2);
      for classset = 1:nsets;
        classes = mydataset.class{k,classset};
        classid = mydataset.classid{k,classset};
        if ~isempty(classes);
          if length(temp4)>=classset & ~isempty(temp4{classset});
            temp4{classset} = [temp4{classset} ', '];
          else
            temp4{classset} = '';
          end
          if length(shownclassname)<classset | ~shownclassname(classset)
            name = mydataset.classname{k,classset};
            if ~isempty(name); temp4{classset} = [temp4{classset}  name ': ']; end
            shownclassname(classset) = true;
          end
          if ~isempty(classid)
            temp4{classset} = [temp4{classset} classid{selection{k}} ' (' num2str(classes(selection{k})) ')'];
          else
             temp4{classset} = [temp4{classset} ' (' num2str(classes(selection{k})) ')'];
          end
        end
      end

    end
  end
end

if ~isempty(axtemps);
  for axind = 1:length(axtemps);
    if ~isempty(axtemps{axind})
      infostring(end+1) = {['Value: ' axtemps{axind}]};
    end
  end
end
if ~isempty(temp3);
  for s = 1:length(temp3);
    if ~isempty(temp3{s})
      infostring(end+1) = {['Label: ' temp3{s}]};
    end
  end
end
if ~isempty(temp4);
  for s = 1:length(temp4);
    if ~isempty(temp4{s})
      infostring(end+1) = {['Class: ' temp4{s}]};
    end
  end
end
infostring(end+1) =   {['Index: ' temp2]};
if ~isempty(temp2b);
  infostring(end+1) = {['Index: ' temp2b]};
end

fig = infobox(infostring);
infobox(fig,'name','Information');
infobox(fig,'movetopointer');

listboxhandle = findobj(fig,'tag','listbox');

if ~isempty(datasource.properties.inforeqcallback);
  try
    eval(datasource.properties.inforeqcallback);
  catch
    disp(lasterr)
    error(['Error executing InfoReqCallback (fig ' num2str(targfig) ')']);
  end
end

%---------------------------------------------------
function viewadjustaxes_Callback
[targfig,fig] = findtarget(gcbf);
adjustaxislimitsgui(targfig);

%---------------------------------------------------

function [modl,test] = getmod(handles,recursive)

% This function returns the model from the analysis window.  Used by
% reducedscores_data.

if nargin<2
  recursive = false;
end

modl = []; test = [];
if ~isempty(handles);
  if ishandle(handles);
    %model
    myid = searchshareddata(handles,'query','model',1);
    if ~isempty(myid)
      %got shared data.
      modl = myid.object;
    elseif isempty(modl)
      %check for appdata in this figure
      modl = getappdata(handles,'modl');
      if isempty(modl)
        %or this appdata field
        modl = getappdata(handles,'model');
      end
    end
  
    %prediction
    myid = searchshareddata(handles,'query','prediction',1);
    if ~isempty(myid)
      %got shared data.
      test = myid.object;
    elseif isempty(test)
      %check for appdata in this figure
      test = getappdata(handles,'test');
    end
  elseif ismodel(handles)  %handles IS the model!
    modl = handles;
  end
end

if ~recursive & isempty(modl);
  [data,datasource] = plotgui('getdataset',handles);
  if isshareddata(datasource)
    [modl,test] = getmod(datasource.source,true);
  end
end

%---------------------------------------------------

function [data,options] = reducedscores_data(data, fig,targfig,options)
% Reduced_dataset returns a scores dataset where the Q residuals reduced and T^2
% reduced columns have been scaled appropriately for the user suppplied confidence limit.
% Returns an options structure to properly populate the legend and axes.   

fig_name = get(targfig,'Name');

if ~isempty(fig_name)
  if isempty(findstr(fig_name,'Scores'))
    return
  end
  
end

handles  = guidata(fig);
str = get(handles.yaxismenu,'string');
val = get(handles.yaxismenu,'value');
lims = getappdata(targfig,'limitsvalue');
xstr = get(handles.xaxismenu,'String');
xval = get(handles.xaxismenu,'Value');
xstr_val = xstr(xval);

% X axis has additional entries as first entries, compared with Y axis
% For example, xster always(?) has: xstr{1} = 'Linear Index'
% BUT xstr may contain additional sample-mode axisscales if there were
% any present in the analysis X-block dataset.
% The number of additional X axis leading entries must be determined.
istr1  = cellfun(@(s) ~isempty(strfind(str{1}, s)), xstr);
iextra = find(istr1)-1;

%hand = get(targfig,'userdata');
%modll = getmod(hand);
modll = getmod(targfig);

if ~isempty(modll)
  if ~isfield(modll.detail.options,{'confidencelimit'})
    return
  end
  
  if lims == round(100*modll.detail.options.confidencelimit)
    return
  end

  qadjusted  = false;    % only adjust these once
  t2adjusted = false;    
  for i = 1:length(val)
    %Check the y menu selection
    int_cellstr = str(val(i));
    if ~isempty(findstr(int_cellstr{1},'Q Residuals Reduced')) & ~qadjusted
      q_lim       = residuallimit(modll,lims/100);
      lim_model   = modll.detail.options.confidencelimit;
      q_lim_model = residuallimit(modll, lim_model);
      data.data(:,val(i)) = data.data(:,val(i)) * q_lim_model/q_lim;
      qadjusted   = true;
    end
    
    if ~isempty(findstr(int_cellstr{1},'Hotelling T^2 Reduced')) & ~t2adjusted
      lim_model   = modll.detail.options.confidencelimit;
      t_lim_model = tsqlim(modll, lim_model);
      t_lim       = tsqlim(modll,lims/100);
      data.data(:,val(i)) = data.data(:,val(i)) * t_lim_model/t_lim;
      t2adjusted  = true;
    end
  end
  
  % Check what is being plotted on X.
  if ~isempty(findstr(xstr_val{1}, 'Hotelling T^2 Reduced'))  & ~t2adjusted  
      lim_model   = modll.detail.options.confidencelimit;
      t_lim_model = tsqlim(modll, lim_model);
      t_lim       = tsqlim(modll,lims/100);
      data.data(:,xval -iextra) = data.data(:,xval-iextra) * t_lim_model/t_lim;
      t2adjusted  = true;
  end

  if ~isempty(findstr(xstr_val{1},'Q Residuals Reduced')) & ~qadjusted
      q_lim       = residuallimit(modll,lims/100);
      lim_model   = modll.detail.options.confidencelimit;
      q_lim_model = residuallimit(modll, lim_model);
      data.data(:,xval -iextra) = data.data(:,xval-iextra) * q_lim_model/q_lim;
      qadjusted   = true;
  end
end

% Modify the options structure that will be used to populate the legend and
% 
lim_str = num2str(lims);
axismenu_values = options.axismenuvalues;
for i = 1:length(axismenu_values)
  ax = axismenu_values(i);
  axis_string = ax{1};
  
  if strcmp(class(axis_string),'cell')  % When multiple things are being plotted on y,
    for j = 1:length(axis_string)
      axis_str = axis_string{j};
      if ~isempty(strfind(axis_str,'Q Residuals Reduced')) | ~isempty(strfind(axis_str,'Hotelling T^2 Reduced'))
        k = findstr(axis_str,'p=');
        if length(lim_str) > 2              % Check that this is not a decimal
          lim_str = lim_str(1:2);
        end
        if length(lim_str)==1
          lim_str = ['0' lim_str];
        end
        axis_string{j}(k+4:k+5) = lim_str;
        ax{1} = axis_string;
        axismenu_values(i) = ax;
      end
    end
  else
    if ~isempty(strfind(axis_string,'Q Residuals Reduced')) | ~isempty(strfind(axis_string,'Hotelling T^2 Reduced'))
      k = findstr(axis_string,'p=');
      if length(lim_str) > 2              % Check that this is not a decimal
        lim_str = lim_str(1:2);
      end
      if length(lim_str)==1
        lim_str = ['0' lim_str];
      end
      axis_string(k+4:k+5) = lim_str;
      ax{1} = axis_string;
      axismenu_values(i) = ax;
    end
  end
end
options.axismenuvalues = axismenu_values;
