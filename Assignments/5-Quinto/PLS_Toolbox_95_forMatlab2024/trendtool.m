function varargout = trendtool(varargin)
%TRENDTOOL Univariate trend analysis tool.
% TRENDTOOL allows the user to graphically perform univariate analysis of
% two-way data. Inputs are (axis) which is the variable scale to plot
% against [can be omitted] and (data) the data to plot. Recall that the convention
% is that rows are samples and columns are variables. If Data is omitted, the
% user is prompted to load a dataset to analyze.
%
% Right-clicking on the trend data plot allows placement of "markers".
% Markers return either the height at a point or integrated area between
% two points. Reference markers can be added to each marker to subtract the
% height at a point or subtract a two-point baseline from the associated
% marker. Markers can be saved or loaded using toolbar buttons. A
% Waterfall plot (linked to axis range shown in data plot) can be created
% using the waterfall toolbar button.
%
% Results of the analysis are plotted in the trend results plot showing
% color-coded results of the univariate analysis. It also allows saving
% analysis results and selection of points to show in the trend data figure.
%
% Applying trend markers to new data:
% Trend markers can be saved using the save toolbar button in the GUI.
% These markers can be applied to new data by calling trendtool with the
% new data and the markers as input. In this case, no GUI is created and
% the results are simply returned to the caller as a DataSet object.
%
%I/O: trendtool(axis,data)
%I/O: trendtool(data)
%I/O: trendtool
%I/O: results = trendtool(data,markers)   %apply markers to new data
%I/O: trendtool(ttmodel)   %opens GUI to apply trendtool model to new data
%
%See also: PCA, PLOTGUI

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%INTERNAL DOCUMENTATION:
%  Various actions can be done in trendtool with the general I/O:
%    trendtool('action',figure,...)
%  Most of these are provided here for acces through the evrigui object,
%  which is the preferred route as these I/O formats may change.
%
%  Specific methods:
%          DROP: ('drop',figure,object)  auto-loads object into appropriate place
%        UPDATE: ('update',figure)       refreshes both figures
%    SIMPLESPEC: ('simplespec',figure,mode)  turns "simple spectral view"
%                  on or off (mode = true or false). Simple spectral view
%                  disables plotgui for main figure control (faster
%                  updating)
%      VIEWSPEC: ('viewspec',figure,index) views the specified indexes in
%                  the specral view. A value of zero or empty for index
%                  indicates "mean view".
% INTERPOLATION: ('interpolation',figure,n) adjusts the spatial
%                  interpolation for images.
%                ('interpolationplus',figure) INCREASE interpolation by 2x
%                ('interpolationminus',figure) DECREASE interpolation by 2x
%                NOTE: upper-limit set with maxinterpolation option
%      PLOTTYPE: ('plottype',type) accesses special plot types. 'surface'
%                  is only enabled mode now other than '' meaning standard
%                  plot.

pgsettings = {'showcontrols',1,'axismenuenable',[0 1 0],'plotby',0,'validplotby',[0 1]};  %settings specifically for plotgui
allsettings = {'name','TrendTool Data View','tag','trendtool'}; %settings used for all figures (pg and otherwise)

model = [];
if nargin == 0;
  varargin{1} = lddlgpls({'dataset'},'Select Data to analyze in TrendTool');
  if isempty(varargin{1});
    return;
  end
  toplot = varargin;  %need this in both variables
elseif ischar(varargin{1});
  switch varargin{1}
    case 'drop'
      if ismodel(varargin{5})
        peakfindgui('fpcancel',varargin{2});
        trendmarker('loadmarkers',varargin{2},varargin{5});
      elseif isdataset(varargin{5}) | isa(varargin{5},'double')
      if strcmpi(getappdata(varargin{2},'figuretype'),'plotgui')        
        myid = plotgui('getlink',varargin{2});
      else
        myid = getshareddata(varargin{2});
        myid = myid{1};
      end
        myid.object = varargin{5};  %will force update of figures
      else
        error('Cannot use this object with TrendTool')
      end
      
    case {'update','updateshareddata','propupdateshareddata'}
      if strcmpi(getappdata(varargin{2},'figuretype'),'plotgui')
        plotgui('update','figure',varargin{2},'background');
      else
        doplot(varargin{2});
      end
      trendlink(varargin{2},'on');
    
    case 'trendprepro'
      fig = varargin{2};
      [xpp,ppStruct] = trendprepro(fig);
      if ~isempty(xpp)
        plotgui('update', 'figure',fig,xpp);
        setappdata(fig, 'curpp', ppStruct);
      end
      
    case 'simplespec'
      fig = varargin{2};
      if varargin{3}
        %switch TO simple mode
        if strcmpi(getappdata(fig,'figuretype'),'plotgui')
          %convert to simple plot from plotgui controlled one
          myid = plotgui('getlink',fig);
          plotgui('removecontrolby',fig);
          delete(findobj(fig,'tag','pgtoolbar'));
          setappdata(fig,'figuretype','');
          
          %link to data & redraw
          linkshareddata(myid,'add',fig,'trendtool')
          doplot(varargin{2});
          
          %dump trend view info and redraw
          tldata = getappdata(fig,'TrendLinkData');
          delete(findobj(tldata.target,'tag','trendlink_toolbar'));
          trendlink(varargin{2},'on');
          set(fig,'closerequestFcn','trendlink(gcbf,''closetrend'')')

        end
      else
        %switch TO plotgui mode
        if ~strcmpi(getappdata(fig,'figuretype'),'plotgui')
          myid = getshareddata(varargin{2});
          plotgui('update','figure',fig,myid{1},pgsettings{:});
          tldata = getappdata(fig,'TrendLinkData');
          close(tldata.target);
          trendlink(varargin{2},'on');
          trendmarker('update',fig);
        end
      end

    case {'interpolationplus' 'interpolationminus'}
      fig     = varargin{2};
      options = trendtool('options');
      tldata  = getappdata(fig,'TrendLinkData');
      n       = getappdata(tldata.target,'interpolation');
      if isempty(n)
        n = 1;
      end
      if strcmpi(varargin{1},'interpolationplus')
        n = n*2;
      else
        n = n/2;
      end
      n = round(n);
      if n<1; n = 1; end
      if n>options.maxinterpolation; n=options.maxinterpolation; end
      setappdata(tldata.target,'interpolation',n);
      trendlink(fig,'on');
      
    case 'interpolation'
      fig = varargin{2};
      n   = varargin{3};
      options = trendtool('options');
      tldata = getappdata(fig,'TrendLinkData');
      if ~isnumeric(n) | length(n)~=1
        error('Interpolation level must be numeric value.')
      end
      if n<1
        n = 1;
      end
      if n>options.maxinterpolation
        n = options.maxinterpolation;
      end
      setappdata(tldata.target,'interpolation',n);
      trendlink(fig,'on');

    case 'plottype'
      fig  = varargin{2};
      mode = varargin{3};
      tldata = getappdata(fig,'TrendLinkData');
      setappdata(tldata.target,'plottype',mode);
      trendlink(fig,'on');
      
    case 'viewspec'
      fig = varargin{2};
      spec = varargin{3};
      if strcmpi(getappdata(fig,'figuretype'),'plotgui')
        %PlotGUI controlled figure
        plotby = getappdata(fig,'plotby');
        plotgui('findtarget',fig);
        myid = getshareddata(fig);
        myid = myid{1};
        if spec>0;
          %select specific item
          if spec>size(myid.object,1)
            spec = size(myid.object,1);
          end
          if plotby==0;
            ind = plotgui('GetMenuIndex',fig);
            plotby = 2-ind{1};
            vals = {0 spec []};
          else
            vals = getappdata(fig,'axismenuvalues');
            vals{2} = spec;
          end
          plotgui('update','figure',fig,'plotby',plotby,'axismenuvalues',vals);
          trendmarker('update',fig);
        else
          %reset to mean
          plotgui('update','figure',fig,'plotby',0,'axismenuvalues',{2-plotby 2 []});
          trendmarker('update',fig);
        end
      else
        %Simple plot
        setappdata(fig,'specindex',spec)
        doplot(fig);
      end
    case 'demo'
      options = trendtool('options');
      varargout{1} = evriio(mfilename,varargin{1},options);
      return;
      
    otherwise
      %standard EVRIIO call
      options = [];
      options.specmode = 'plotgui';
      options.figure   = [];
      options.maxinterpolation = 16;
      if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  end
  return;
end

if nargin==1 & ismodel(varargin{1})
  %Load markers from passed model and load user-specified data in GUI
  model = varargin{1};
  data = lddlgpls({'dataset'},'Select Data to analyze in TrendTool');
  if isempty(data);
    return;
  end
  varargin{1} = data;
  varargin{2} = model;
end

if nargin>=2 & ismodel(varargin{2})
  %apply markers to new data (no GUI)
  
  [data,model] = deal(varargin{1:2});
  if ~strcmpi(model.modeltype,'trendtool');
    error('Not a valid trendtool model type');
  end
  
  try
    [results,tags,normto] = trendapply(data,model);
  catch
    le = lasterror;
    le.message = ['Unable to apply markers to new data.' 10 le.message];
    rethrow(le)
  end
  
  %drop any normalize-to columns
  results(:,normto) = [];
  tags(normto) = [];
  
  %create dataset object of results and return that to user
  results = dataset(results);
  if ~isempty(results)
    if isdataset(data)
      results = copydsfields(data,results,1);
      if exist('inheritimage','file')
        results = inheritimage(results,data);
      end
    end
    results.label{2} = tags;
  end
  
  varargout = {results};
  
  return
end

showclosebtn = false;
options = [];
switch nargin
  case 1
    % (data)
    % (options)
    if isstruct(varargin{1})
      % (options)
      options = varargin{1};
      toplot = [];
    else
      % (data)
      toplot = varargin(1);
      if isshareddata(toplot{1}) 
        if strcmpi(getappdata(toplot{1}.source,'figuretype'),'PlotGUI')
          validplotby = getappdata(toplot{1}.source,'validplotby');
          if isempty(validplotby) | all(ismember([0 1],validplotby))
            %Got shared data in a plotgui figure already - attach to that
            %PG figure (instead of creating a new one)
            fig = toplot{1}.source;
            plotby = getappdata(fig,'plotby');
            if plotby <= 1
              options.figure = fig;
              pgsettings = {'showcontrols',1};
              allsettings = {};
              toplot = {};
              showclosebtn = true;
              if plotby==0
                [ind,ind2,ind3] = plotgui('GetMenuIndex',fig);
                if ind~=1;
                  pgsettings = [pgsettings {'axismenuvalues',{1 ind2}}];
                end
              end
            end
          end
        end
        if ~isempty(toplot) & isshareddata(toplot{1})
          %didn't get cleared or reset above? extract object
          toplot = {toplot{1}.object};
        end
      end
    end
  case 2
    % (data,options)
    % (x,y)
    if isstruct(varargin{2})
      options = varargin{2};
      toplot = varargin(1);
    else
      toplot = varargin(1:2);
    end
  case 3
    % (data,[],options)
    % (x,y,options)
    options = varargin{3};
    if isempty(varargin{2});
      toplot = varargin(1);
    else
      toplot = varargin(1:2);
    end
end

% if length(size(toplot{1}))>2
%   % Multiway data?
%   beep;
%   h = msgbox('Trendtool is not compatible with multi-way data', 'Warning');
%   %h=errordlg('Trendtool is not compatible with multiway data.');
%   %return;
% end

options = reconopts(options,mfilename);

%all other calls - create GUI
btnlist = {
  'open'      'loadmarkers' 'trendmarker(''loadmarkers'',gcbf)'     'enable' 'Load markers'            'off' 'push'
  'save'      'savemarkers' 'trendmarker(''savemarkers'',gcbf)'     'enable' 'Save markers'            'off' 'push'
  'SetPureVarOne' 'addmarker' 'trendmarker(''autoadd'',gcbf)'       'enable' 'Add marker'              'on' 'push'
  'findpeaks' 'findpeaks' 'peakfindgui(''setup'',gcbf)'             'enable' 'Find peaks'              'off' 'push'
  'deleteallmarkers' 'delmarkers' 'trendmarker(''delete'',''all'')' 'enable' 'Delete all markers'      'off' 'push'
  'editmarkers' 'editmarkers' 'trendmarker(''edit'',gcbf)'          'enable' 'Edit markers'            'off' 'push'
  'revdir'    'xdir_rev'  'revdir(gcbf)'                            'enable' 'Flip X-axis Direction'   'on' 'push'
  };

otherbtn =       {
  'update_trend' 'trend'     'trendlink(gcbf,''on'')'      'enable' 'Update trend plot'               'off' 'push'
  'waterfall'    'waterfall' 'trendwaterfall(gcbf,''on'')' 'enable' 'Display / Update waterfall plot' 'off' 'push'
  'coffee'       'doprepro'  'trendtool(''trendprepro'',gcbf)'         'enable' 'Choose and apply preprocessing'  'off' 'push'
  };

closebtn = {
  'close'    'trendclose'  'trendlink(gcbf,''detach'')'  'enable' 'Close TrendTool'   'on' 'push'
  };

if isdataset(varargin{1}) & strcmp(varargin{1}.type,'image')
  %image data, add special update trend button
  otherbtn = {
    'update_trend' 'trend'     'trendlink(gcbf,''on'')'      'enable' 'Update image plot'               'off' 'push'
    };
end

btnlist = [btnlist; otherbtn];

if showclosebtn
  btnlist = [btnlist; closebtn];
end

%get figure sizes we want to use
posa = get(0,'defaultfigureposition');
posb = posa;
% posa = get(th,'position');
% posb = get(target,'position');
scrn = getscreensize;
% fix for high resolution screens
if (scrn(3)>= 2048 || scrn(4) > 1080)
  scrn(3:4) = scrn(3:4)*.4;
  posa(2)=posa(2)-scrn(4)*0.05;
  posb(2)=posa(2);
end
cnt = round(scrn(3)/2);
if posa(3)+posb(3)<=scrn(3)
  %two windows fit side-by-side OK
  posa(1) = cnt-posa(3);
  posb(1) = cnt+1;
else
  %shrink windows to fit centered
  posa(1) = 1;
  posa(3) = cnt;
  posb(1) = cnt+1;
  posb(3) = cnt-1;
end
posa([2 4]) = posb([2 4]);
setplspref('trendlink','figureposition',posb);

% Clamp windows with 25 pixel buffer on top.
if(posa(1) < 1) || (posb(1) < 1 + posa(3)) 
  posa(1) = 1;
  posb(1) = posa(1) + posa(3);
end
if (posa(1) > scrn(3) - posb(3)) || (posb(1) > scrn(3))
  posa(1) = scrn(3) - posb(3) - posa(3);
  posb(1) = scrn(1) - posb(3);
end
if (posa(2) + posa(4) > scrn(4) - 25)
  posa(2) = scrn(4) - posa(4) - 25;
  posab(2) = posa(2);
end
if(posa(2) < 1) || (posb(2) < 1) 
  posa(1) = 1;
  posb(1) = posa(1);
end

%create main figre
wbh = waitbar(0.3,'Initializing TrendTool');

try
  
  if strcmp(options.specmode,'simple')
    %non PlotGUI figure for main figure
    if isempty(options.figure)
      th = figure('position',posa,allsettings{:});
    else
      th = options.figure;
    end
    if length(toplot)==2
      if ~isdataset(toplot{2});
        data = dataset(toplot{2});
      else
        data = toplot{2};
      end
      if length(toplot{1})~=size(data,2);
        data = data'; %transpose if axisscale doesn't match columns
      end
      data.axisscale{2} = toplot{1};
    else
      if ~isdataset(toplot{1});
        data = dataset(toplot{1});
      else
        data = toplot{1};
      end
    end
    myid = setshareddata(th,data);
    linkshareddata(myid,'add',th,'trendtool');
    doplot(th);
  else
    if isempty(options.figure)
      th = plotgui('new',toplot{:},'position',posa,pgsettings{:},allsettings{:});
    else
      th = options.figure;
      plotgui('update','figure',th,pgsettings{:},allsettings{:})
    end
  end
  tbh = toolbar(th,'',btnlist);
  set(tbh,'tag','trendtool_toolbar');
  set(th,'closerequestFcn','trendlink(gcbf,''closetrend'')')
  setappdata(th,'TrendToolPosition',[posa;posb]);
  setappdata(th,'OriginalData',toplot{:});
  
  if ~isempty(model)
    trendmarker('loadmarkers',th, model);
  elseif ~isempty(varargin{1})
    peakfindgui('setup',th);
  end
  
  if ishandle(wbh); waitbar(0.6,wbh); end
  trendlink(th,'on');
  
  %adjust positions of the two windows
  tldata = getappdata(th,'TrendLinkData');
  target = tldata.target;
  set(target,'position',posb);
  
catch
  le = lasterror;
  if ishandle(wbh); close(wbh); end
  rethrow(le)
end

%and dump waitbar
if ishandle(wbh); close(wbh); end

if nargout>0
  varargout = {th};
end

%----------------------------------------------------------
function doplot(fig)

set(0,'currentfigure',fig);
myid = getshareddata(fig);
data = myid{1}.object;
ax = data.axisscale{2};
if isempty(ax)
  ax = data.include{2};
else
  ax = ax(data.include{2});
end

spec = getappdata(fig,'specindex');
if isempty(spec) | spec==0 | spec>size(data,1)
%   [junk,toplot] = mncn(data.data.include{2});  % Is memory hog
  % meanomitnans reduces peak memory usage by approx 50% vs. mncn.
  toplot = meanomitnans(data);
else
  toplot = data.data(spec,data.include{2});
end
plot(ax,toplot);
xlabel(data.axisscalename{2});
trendmarker('update',fig);

%----------------------------------------------------------
function toplot = meanomitnans(x)
% Get column means of dataset's included columns, omitting NaN values from
% the means. Means for columns which contain only NaNs are interpolated
% from neighboring column means.
if isempty(x)
  toplot = [];
else
  [toplot] = mean(x.data.include{2},1);
  if isnan(toplot)
    error(['Too much missing data to analyze'])
  else
    incl2 = x.include{2};
    nancolinds = find(isnan(toplot));
    nancolmean = nan(1,length(nancolinds));
    if any(nancolinds)
      % Handle NaN-containing columns individually. Get mean, omitting NaNs.
      for ii=1:length(nancolinds)
        nancol = x.data(:, incl2(nancolinds(ii)));
        nancolmean(ii) = mean(nancol(~isnan(nancol)));
      end
      toplot(nancolinds) = nancolmean;
    end
    if all(isnan(toplot))
      error(['Too much missing data to analyze'])
    elseif any(isnan(toplot))
      notnanind=find(~isnan(toplot));
      toplot = interp1(notnanind,toplot(notnanind),1:length(toplot));
    end
  end
end

%----------------------------------------------------------
function [xpp,ppStruct] = trendprepro(fig)
data = getappdata(fig, 'OriginalData');
xpp = [];
preproCat = preprocess('initcatalog'); 

keysToUse = {'Abs'
  'arithmetic'
  'baseline'
  'whittaker'
  'simple baseline'
  'derivative'
  'Detrend'
  'gapsegment'
  'glog'
  'log10'
  'Normalize'
  'pareto'
  'sqmnsc'
  'PQN'
  'referencecorrection'
  'smooth'
  'SNV'
  'trans2abs'};

touse = ismember({preproCat.keyword},keysToUse);
newcatalog = preproCat(touse);
curpp = getappdata(fig, 'curpp');
[ppStruct,ppChange] = preprocess('setup',fig,'catalog', newcatalog, curpp, data); 
if ppChange
  [xpp,ppStruct] = preprocess('calibrate',ppStruct, data);
end


