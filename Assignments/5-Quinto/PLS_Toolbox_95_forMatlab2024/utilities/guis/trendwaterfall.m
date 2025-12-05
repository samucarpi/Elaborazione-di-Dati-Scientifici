function varargout = trendwaterfall(varargin)
%TRENDWATERFALL waterfall for trendtool
%  Helper function used by TRENDTOOL.
%  Inputs are (sourcehandle) the figure number of the plotgui figure from
%  which the waterfall plot should be linked and (mode) the action which
%  should be performed. Valid modes are 'on', 'off', and 'update' [default
%  'update'].
%
%  Other options which can be set using SETPLSPREF
%     eraseexcluded : [0] boolean flag, 1 = erase regions which are
%        "excluded", 0 = connect included regions with lines.
%     maxsize : [60 250] maximum size of plotted waterfall points as
%        [samples variables]. Data will be co-added to condense to this
%        number of points.
%     figureposition : position of figure [left bottom width height]
%    
%I/O: trendwaterfall(sourcehandle,mode)
%
%See also: TRENDTOOL, TRENDMARKER, TRENDAPPLY, TRENDLINK

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.



if nargin > 0 & ischar(varargin{1});
  options = [];
  options.eraseexcluded = 0;    %should we use NaN's to "erase" excluded variables? (otherwise: line connect)
  options.maxsize = [60 250];   %maximum # of samples and variables for display (coadd to bring down to this #)

  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

options = reconopts([],'trendwaterfall');  %reconcile options with setplspref options

switch nargin
  case 0
    handle = gcf;
    mode = 'on';
  case 1
    handle = varargin{1};
    mode = 'update';
  case 2
    handle = varargin{1};
    mode = varargin{2};
end      

switch mode
  
  case {'on','off'}    %============================================================
    
    if isempty(handle) | ~ishandle(handle);
      error('Not a valid figure handle');
    end
    mycb = 'trendwaterfall(gcf);';
    cb = getappdata(handle,'plotcommand');
    pos = strfind(cb,mycb);
    if strcmp(mode,'on') & isempty(pos);
      cb = [cb mycb];
      setappdata(handle,'plotcommand',cb);
    elseif strcmp(mode,'off') & ~isempty(pos);
      cb(pos:(pos+length(mycb)-1)) = [];
      setappdata(handle,'plotcommand',cb);
    end

    if strcmp(mode,'on');
      fignow = getappdata(handle,'Trendwaterfall');
      if isempty(fignow) | ~ishandle(fignow);
        setappdata(handle,'Trendwaterfall',createwffigure);
      else
        figure(fignow);
      end
      trendwaterfall(handle);
    end
    
  otherwise        %============================================================
    
    xrng = [];  %default x-axis is everything
    vi = [];   %default is reset view

    if isempty(handle) | ~ishandle(handle);
      error('Handle must be a valid PlotGUI figure handle');
    end

    data = plotgui('getdataset',handle);
    if ~isa(data,'dataset') | isempty(data.data)
      return
    end
    
    pgoptions = getappdata(handle);
    
    if pgoptions.plotby == 2;
      data = data';
    end
    
    %Get samples to plot
    ind = pgoptions.axismenuindex;
    if length(ind{2})>1;
      if pgoptions.viewexcludeddata;
        data.include{1} = ind{2};   %show all selected samples
      else
        data.include{1} = intersect(data.include{1},ind{2});  %show only included, selected samples
      end
    else
      if pgoptions.viewexcludeddata;
        data.include{1} = 1:size(data.data,1);  %show all samples
      else
        %do nothing, we'll show the included samples only
      end
    end
    
    %Get variable range to view (based on xlimits on plotgui window)
    xrng = get(get(handle,'currentaxes'),'xlim');
    xdir = get(get(handle,'currentaxes'),'xdir');
    xaxis = data.axisscale{2};
    if isempty(xaxis);
      xaxis = 1:size(data.data,2);
    end
    use = findindx(xaxis,xrng);  %lookup displayed range
    if pgoptions.viewexcludeddata;
      data.include{2} = min(use):max(use);
    else
      data.include{2} = intersect(data.include{2},min(use):max(use));
    end
    
    %get figure to plot on
    fig  = getappdata(handle,'Trendwaterfall');
    if isempty(fig) | ~ishandle(fig);
      trendwaterfall(handle,'off')
      return
    else
      figure(fig);
      [az,el] = view;
      vi = [az el];
      if all(vi==[0    90]);
        vi = [];
      end
    end
    
    %get info from dataset
    incl  = data.include;
    if ~isempty(data.axisscale{2});
      if options.eraseexcluded
        xaxis = data.axisscale{2};
      else
       xaxis = data.axisscale{2}(incl{2});
     end
    else
      if options.eraseexcluded
        xaxis = 1:size(data.data,2);
      else
        xaxis = incl{2};
      end
    end
    if ~isempty(data.axisscale{1});
      yaxis = data.axisscale{1}(incl{1});
    else
      yaxis = incl{1};
    end
    if options.eraseexcluded
      temp  = data.data(incl{1},:);
      temp(:,setdiff(1:size(temp,2),incl{2})) = nan;
    else
      temp  = data.data(incl{1},incl{2});
    end
    
    %compact sample dim
    scl = round(size(temp,1)./options.maxsize(1));
    if scl > 1;
      temp = coadd(temp,scl,struct('dim',1));
      yaxis = coadd(yaxis,scl,struct('dim',2));
    end
    
    %compact variable dim
    scl = round(size(temp,2)./options.maxsize(2));
    if scl > 1;
      temp = coadd(temp,scl,struct('dim',2));
      xaxis = coadd(xaxis,scl,struct('dim',2));
    end
    
    %do plot
    waterfall(xaxis,yaxis,temp)
    
    %set x-dir options
    set(gca,'xdir',xdir);

    %set 3-D options
    rotate3d on
    if ~isempty(vi);  %restore view if we had it previously
      view(vi);
    end

    %remember current figure position (as long as it is on-screen)
    set(fig,'units',get(0,'units'))
    ss  = getscreensize;
    pos = get(fig,'position');
    if pos(1)>ss(3) | pos(2)>ss(4) | (pos(1)+pos(3))<ss(1) | (pos(2)+pos(4))<ss(2);
      pos = get(0,'defaultfigureposition');  %figure off-screen? reset to default position
      set(fig,'position',pos);
    end
    setplspref('trendwaterfall','figureposition',pos);
    
end    %============================================================


%------------------------------------------
function fig = createwffigure

fig = figure('name','Waterfall View','visible','off');
% colormenu

%set figure position
opts = getplspref('trendwaterfall');
if ~isfield(opts,'figureposition') | isempty(opts.figureposition);
  pos = get(fig,'position').*[1.15 .85 1 1];
  setplspref('trendwaterfall','figureposition',pos);
else
  pos = opts.figureposition;
end
set(fig,'position',pos);

set(fig,'visible','on');
 
