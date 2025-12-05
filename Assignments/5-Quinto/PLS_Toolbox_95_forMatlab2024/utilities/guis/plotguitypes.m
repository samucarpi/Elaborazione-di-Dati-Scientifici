function h = plotguitypes(plottype,xdata,ydata,linestyle,otheraxes,offset,varargin)
%PLOTGUITYPES Helper function for plotgui scatter plots.
%I/O: h = plotguitypes(plottype,ixdata,ydata,linestyle,otheraxes,offset);

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 5/24/03 
%jms 5/4/04 -fix to bar mode with single group of bars
%jms 7/15/04 -fix to R14/linestyle problem with bar plot type

validtypes = {'scatter','line','line+points','monotonic','bar','stem','stick','mesh','surface','enhanced_surface','contour','errorbar'};
%(Also note that 'plot' is always considered a validtype although it is not
%listed here)
if nargin<1;
  h = validtypes;
  return
end

%if only two inputs, then define and return properties of this plot type
% E.G.   plotguitypes('stick','markerfacecolor')
% These properties can be used by callers to modify the produced plot
% without knowing much about the plot type created. They include:
%   .baseplot          %validtype from list above for basic plot
%   .overlayas         %validtype from list above to show overlays (selections, classes)
%   .color             %name of edge-color property of object (created by "overlayas")
%   .markerfacecolor   %name of face-color property of object
%   .tohide            %property,value pairs to use to hide the object
%   .is3d              %created object is a 3D object (1) (like surfaces or mesh plots) or not (0)
%   .vectorallowed     %object can be created with only a vector (1) or
%                        must default to plottype="plot" if vector supplied (0)
%   .axismodes         %cell array of commands to pass to "axis" call when
%                        plot is done such as {'ij' 'tight'}
if nargin==2;
  %default properties (for all plottypes not listed in the switch below)
  properties = [];
  properties.baseplot  = 'plot';
  properties.overlayas = 'plot';
  properties.color     = 'color';
  properties.markerfacecolor = 'markerfacecolor';
  properties.tohide    = {'linestyle','none','marker','none'};
  properties.is3d      = 0;
  properties.vectorallowed = 1;
  properties.axismodes = {};
  
  %specialized properties for certain modes
  switch plottype
    case 'scatter'
      properties.baseplot  = 'scatter';
      properties.overlayas = 'scatter';
      properties.color     = 'color';
      properties.markerfacecolor = 'markerfacecolor';
      properties.tohide    = {'linestyle','none','marker','none'};
      properties.is3d      = 0;
      properties.vectorallowed = 1;
      
    case {'surface' 'enhanced_surface'}
      properties.baseplot  = 'hiddengrid';
      properties.overlayas = plottype;
      properties.color     = 'edgecolor';
      properties.markerfacecolor = 'markerfacecolor';
      properties.tohide    = {'linestyle','none'};
      properties.is3d      = 1;
      properties.vectorallowed = 0;
      properties.axismodes = {'tight'};
      
    case 'mesh'
      properties.baseplot  = 'hiddengrid';
      properties.overlayas = 'mesh';
      properties.color     = 'edgecolor';
      properties.markerfacecolor = 'markerfacecolor';
      properties.tohide    = {'linestyle','none'};
      properties.is3d      = 1;
      properties.vectorallowed = 0;
      properties.axismodes = {'tight'};

    case 'waterfall'
      properties.baseplot  = 'hiddengrid';
      properties.overlayas = 'waterfall';
      properties.tohide    = {'linestyle','none'};
      properties.is3d      = 1;
      properties.vectorallowed = 1;
      
    case 'contour'
      properties.baseplot  = 'hiddengrid';
      properties.overlayas = 'contour';
      properties.markerfacecolor = 'color';
      properties.tohide    = {'linestyle','none'};
      properties.vectorallowed = 0;
      properties.axismodes = {'tight'};
      
  end

  h = properties.(xdata);
  return
end

if min(size(ydata))<2 & ~plotguitypes(plottype,'vectorallowed');
  %3D plot type without 3D data? duplicate as needed
  if size(ydata,2)>1
    %mode 1 needs extension
    xdata = [xdata(1)-.5;xdata(1)+.5];
    ydata = repmat(ydata,2,1);
  else
    %mode 2 needs extension
    ydata = repmat(ydata(:),1,2);
  end
  if length(xdata)~=size(ydata,1)
    xdata = (1:size(ydata,1))';
  end
end
if nargin<5
  otheraxes = {};
end
%check size of otheraxes (note: also done in plotgui_plotscatter, but
%duplicated here just for safety)
if ~isempty(otheraxes) & iscell(otheraxes) & ~isempty(otheraxes{1})
  %provided other axes, use it
  otheraxes = otheraxes{1};
  %and replicate length if needed to match length of ydata
  if size(ydata,2)~=length(otheraxes)
    otheraxes = [];
  end
else
  otheraxes = [];
end
if length(otheraxes)~=size(ydata,2)
  %no other axes, use linear spacing
  otheraxes = 1:size(ydata,2);
end
if nargin<6 | isempty(offset)
  offset = false;
end

if isprop(gca,'ColorOrderIndex'); set(gca,'ColorOrderIndex',1); end
try
switch plottype
  case {'plot','scatter','line','line+points'}
    h = plot(xdata,ydata,linestyle);

    if strcmp(plottype,'scatter');
      %turn off any line and make sure there is SOME kind of marker
      set(h,'linestyle','none');
    end
    if strcmp(plottype,'scatter') | strcmp(plottype,'line+points');
      linestyle = get(h,'marker');
      if strcmp(linestyle,'none')
        linestyle = 'o';
        set(h,'marker',linestyle);
      end
    end

    if ismember(linestyle,{'o'});
      c = get(h,'Color');
      if ~iscell(c); c = {c}; end
      for j=1:length(c); c{j} = 1-((1-c{j})*.5); end
      set(h,{'markerFaceColor'},c);
      ms = get(h,'markersize');
      if iscell(ms);
        ms = min([ms{:}]);
      end
      if ispc
        set(h,'markersize',ceil(ms/1.4));
      end
    end
    
  case 'monotonic' 
    h = plotmonotonic(xdata,ydata);
    
  case 'errorbar'
    if size(ydata,2)>3
      m = mean(ydata,2);
      s = std(ydata,[],2);
      ydata = [m m+s m-s];
    elseif size(ydata,2)==2;
      m = mean(ydata,2);
      s = (ydata(:,1)-ydata(:,2))/2;
      ydata = [m m+s m-s];
    end
    if size(ydata,2)==3
      h = errorbar(xdata,ydata(:,1),ydata(:,1)-ydata(:,2),linestyle);
    else
      h = plot(xdata,ydata,linestyle);
    end
    legendname(h,'mean and standard deviation');
    
  case 'surface'
    h = surf(xdata(:)',otheraxes,ydata');
    shading flat

  case 'enhanced_surface'
    h = surf(xdata(:)',otheraxes,ydata');
    shading flat
    add3dlight;
    
  case 'mesh'
    h = mesh(xdata(:)',otheraxes,ydata');

  case 'contour'
    [C,h] = contour(xdata(:)',otheraxes,ydata',20);

  case 'hiddengrid'
    %NOTE: not a valid plottype, used only by above method(s) to create 2D
    %grid for selections
    h = plot(xdata(:)',repmat(otheraxes,numel(xdata),1));
    set(h,'linewidth',3);

  case 'bar'
      if size(xdata,1)==1 & size(ydata,2)>1;
        %if only one row (but multiple y-columns), add dummy row to fix bug
        %in "bar"
        xdata = [xdata; xdata*0];
        ydata = [ydata; ydata*0];
      end
      if length(unique(xdata))==length(xdata) & ~offset
        addcmd = {};
        %         if offset; addcmd = {'stack'}; end
        %note: bar plots use stacked, not real offset because Matlab doesn't
        %support multiple baselines for a single axes bar plot.
        %NEW NOTE: offset is now being handled by stick mode...
        h = bar(xdata,ydata,addcmd{:});
        if isprop(h(1),'linestyle')
          set(h,'linestyle','none');
        end
      else
        %if xdata contains any duplicates, switch to stick mode.
        h = plotguitypes('stick',xdata,ydata,linestyle,otheraxes,offset,varargin{:});
      end
    
  case 'stem'
    if ~offset
      h = stem(xdata,ydata,linestyle);
      %DISCONTINUED use of stem when offset is on (because we can't control
      %individual line baselines without splitting them off into multiple
      %objects)
    else
      %doing offset? need to create stem plot manually
      h = plotguitypes('stick',xdata,ydata,linestyle,otheraxes,offset,varargin{:});
      hm = line(xdata,ydata,'linestyle','none','marker','o');
      set(hm,{'HandleVisibility'},{'off'});
    end
    
  case 'stick'
    h = stick(xdata,ydata);
    if offset; dooffset(h); end

  case 'waterfall'
    h = waterfall(xdata(:)',otheraxes,ydata');
        
end
catch
  if ~strcmp(plottype,'plot')
    try
      h = plotguitypes('plot',xdata,ydata,linestyle,otheraxes,varargin{:});
    catch
      h = [];
    end
  else 
    h = [];
  end
end

if nargout == 0; 
  clear h
end


%----------------------------------------------
function dooffset(h)

for j=2:length(h);
  yd = get(h(j),'ydata');
  yd(yd==0) = j-1;
  set(h(j),'ydata',yd);
end
