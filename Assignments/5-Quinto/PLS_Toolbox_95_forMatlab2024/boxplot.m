function [s,options] = boxplot(ax,x,varargin)
%BOXPLOT Box plot showing various statistical properties of a data matrix.
%Box plots provide a summary of various standard statistics for the columns
%of a data matrix. The primary plotted item is a box which represents the
%"Interquartile Range" (IQR). This box shows the extent of the middle 50%
%of the data (25% of the data falls above and 25% of the data falls below
%the box). Various other statistics are superimposed over this box,
%including:
%  The top and bottom of the box are the 25th and 75th percentiles
%    (defined as Q(0.25) and Q(0.75) respectively). The size of the box is
%    called the Interquartile Range (IQR) and is defined as
%    IQR = Q(0.75)-Q(0.25). ['Tag'='Box']
%  The whiskers extend to the most extreme data points which are not
%    considered outliers (see below for definition of outliers.) These
%    extreme whiskers are called the 'Upper Adjacent Value' and 'Lower
%    Adjacent Value' ['Tag'='Upper Adjacent Value', 'Tag'='Lower Adjacent
%    Value']
%  The horizontal line inside the box (or the dot in a circle "target" -
%    see the medianstyle option) represents the median ['Tag'='Median'].
%  The dot inside the box is the mean ['Tag'='Mean'].
%  Data which falls outside the IQR box by a specific amount are considered
%    "outliers". There are two categories of outliers, Standard and
%    Extreme, which are defined by how far outside the IQR the points fall.
%    By default, these limits are 1.5 and 3.0 (see options qrtlim and
%    qrtlimx, below.) The limits are used as defined below:
%   * Standard Outliers fall between 1.5*IQR and 3.0*IQR outside of the IQR
%     and are plotted with an open circle ['Tag'='Outliers']
%   * Extreme Outliers fall greater than 3.0*IQR outside the IQR and are
%     plotted with a closed circle ['Tag'='OutliersX'].
%    For example, if the lower and upper ranges on the IQR are 4 and 6, the
%    IQR=2.0 and values between 6+(1.5*2) and 6+(3*2) ( = 9 and 12) or
%    between 4-(1.5*2) and 4-(3*2) ( = 1 and -2) are considered standard
%    outliers. Samples above 12 or below -2 are considered extreme
%    outliers.
%  When selected via the notch option, notches or markers can be viewed
%    which show the estimated 95% confidence limits for the median. If the
%    confidence limits for two medians do not overlap, they can be assumed
%    to be different at the 95% confidence limit. The notch can be viewed
%    either as a narrowing of the box at the median (where the start and
%    end of the tapered region indicate the upper and lower confidence
%    limits) or as an upper and lower triangle marker which are centered on
%    the 95% confidence limits. ['Tag'='NotchHi', 'Tag'='NotchLo']
%    The total range between the upper and lower notch bounds is calculated
%    using the formula:
%       width = IQR*1.58 / sqrt(n)
%    where n is the number of data items in the given column.
%
%  For ease of modification of graphical objects, the various objects have
%  been given tags as defined in the [ ] above.
%
%  INPUT:
%      x = MxN matrix of class 'double' or 'dataset'
%      For boxplot(x), N boxes corresponding to columns are plotted.
%
%  OPTIONAL INPUTS:
%    cls = flag / indicator variable governing how the data are grouped
%        or classed. (cls) can be numeric, cell or character array.
%        If numeric or cell, (cls) must have as many elements as (x) OR
%        contain N elements.
%        If a character array, it must have as many rows as (x) has
%        elements OR contain N rows.
%        (cls) and (options) are not input together.
%      For boxplot(x,cls), length(unique(cls)) boxes are plotted.
%        If (cls) has N elements, N boxes corresponding to columns are plotted.
%        If (cls) has as many elements as (x), then length(unique(cls)) boxes
%        are plotted.
%
%     ax = target axes handle to plot to
%      For boxplot(ax,x,cls), the plot will be a child of (ax).
%
%   For boxplot(...,param1,val1,param2,val2,...), the parameter names
%   and values must correspond to the options fields and values given
%   below.
%
%    options = standard options structure with the following fields
%      useclass: [{'yes'} | 'no'], when (x) is a DataSet object:
%                options.useclass = 'yes' will use x.label{2} as the tick label
%                when length(unique(cls))==N, otherwise if N==1 then
%                x.classid{1} will be used.
%
%        prctlo: [0.25] low  percentile {default = 0.25 for 25th percentile}
%        prcthi: [0.75] high percentile {default = 0.75 for 75th percentile}
%        qrtlim: [1.5]  limit for defining outliers
%       qrtlimx: [3]    limit for defining extreme outliers
%
%     plotstyle: [{'traditional'}| 'compact' ] 'compact' automatically
%                chooses default options to produce a plot that is easier
%                to view when there are lots of bars being displayed. See
%                below for defaults.
%      boxwidth: [0.45] box width
%      boxstyle: [{'outline'}| 'filled' ] Style of box. Note that 'filled'
%                will change the colors used for the median object(s).
%      boxcolor: ['b'] Defines the color of the IQR box. String color or
%                vector giving the fractional [red green blue] color code.
%     positions: vector of positions, which must be monotically ascending
%                and whose length must equal the number of boxes being
%                plotted, or empty will use number of unique classes.
%     groupings: {} governs major and minor grouping of data as a one- or
%                two-element cell array. First element defines major
%                grouping, second (optional) element defines minor
%                grouping. Each element contains one of the following: 
%                 * An integer value indicating a row class set to use. If
%                   requested row class set is empty then the corresponding
%                   label set is used instead, if not empty (only valid if
%                   x is a DataSet object.)
%                 * A cell array (equal in length to the number of rows)
%                   containing strings defining grouping of samples.
%                   Samples with the same string will be grouped together.
%                 * A vector of numeric values (equal in length to the
%                   number of rows) to be used to define groups of samples.
%     meancolor: ['r'] Defines the color to use for the mean marker.
%    meansymbol: ['.'] Defines symbol to use for the mean symbol.
%
%   outliersize: [6] Size of the outlier markers, in points (n/72 inch).
%        symbol: ['ob'] Marker (and optional color) of outlier markers.
%                Extreme outliers will use the filled version of the given
%                symbol.
%        jitter: [0] Governs addition of random off-axis offset to make
%                overlapping outliers visible. Indicates maximum +/- offset
%                to allow (using a uniform distribution). If zero, all
%                outliers are in-line with no offset.
%
%   medianstyle: [{'line'}| 'target'] Governs method of displaying the
%                median:
%                  'line' = Draws a line for the median.
%                  'target' = Draws a dot inside a white circle.
%         notch: [{'off'} | 'on' | 'marker'] Governs display of 5%
%                significance range for median comparisons. If the notch
%                ranges for two medians do not overlap, they are considered
%                different at the 95% confidence level.
%                 'off' = Do not show median comparison marks.
%                 'on' = Indicates intervals using notches on IQR box when
%                    plotstyle is 'traditional' or triangular markers
%                    when plotstyle is 'compact'.
%                 'marker' = Indicates intervals using triangular markers
%                    for upper and lower ranges.
%
% labelorientation: [{'horizontal'}| 'inline' ] Governs directionality of
%                labels.
%                 'inline' = Rotates the labels to be vertical. This is the
%                    default when plotstyle is 'compact'.
%                 'horizontal' = Leaves the labels horizontal. This is the
%                    default when plotstyle is 'traditional'.
%        legend: [ 'off' |{'on'}] Governs "nice legend" mode. When 'on'
%                the plot is created such that the standard legend tool
%                produces a nice looking legend (but not all graphical
%                objects can be "found" by users wanting to do
%                customization). If set to 'off', every graphical object
%                will displayed in the legend box (creating a very poor
%                looking legend). 'off' should only be used when some
%                customization is going to be done by the caller using
%                findobj graphical commands which require all graphical
%                object tags to be visible. It is recommended to use 'on'
%                unless user-customization is desired via Matlab uigraphics
%                commands.
%
%  OUTPUTS:
%          s = 7xN matrix of results. The rows of s correspond to
%              [Sl; Q(0.25); Q(0.5); Q(0.75); Sh; mean; count]
%    options = standard options structure used to create the plots.
%
%NOTES:
% (1) plotstyle = 'compact' uses the following defaults. The user can
%     override any of these by simply passing an alternative value
%     explicitly:
%              boxstyle = 'filled'
%           medianstyle = 'target'
%                symbol = 'o'
%           outliersize = 4
%                jitter = 0.5
%      labelorientation = 'inline'
% (2) This function has a known conflict with the Mathworks (MW)
%     Statistics Toolbox function of the same name. This function is
%     intended to be as compatible as practical with the MW version,
%     including many of the above options which are designed to be similar
%     to the corresponding MW version, but such compatibility is not
%     guaranteed. For more information on this issue, see this webpage:
%        http://www.eigenvector.com/faq/index.php?id=129
%
%I/O: s = boxplot(x,...);
%I/O: boxplot(x,cls,...);
%I/O: boxplot(ax,x,cls,...);
%I/O: boxplot(...,param1,val1,param2,val2,...);
%I/O: boxplot(...,options);
%
%See also: HLINE, PLOTGUI, SUMMARY

% Copyright © Eigenvector Research, Inc. 2009
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%NBG 8/09

%The following input forms are accepted
% boxplot(x)
% boxplot(x,cls)
% boxplot(ax,x)
% boxplot(x,options)
% boxplot(x,cls,options)
% boxplot(ax,x,options)
% boxplot(ax,x,cls)
% boxplot(x,'property',value,'property',value) %>=3
% boxplot(ax,x,'property',value,'property',value)
% boxplot(ax,x,cls,'property',value,'property',value)

%The following input forms are NOT yet supported
% boxplot(ax,x,cls,options)
% boxplot(ax,x,cls,'property',value,'property',value)

% Doesn't handle NaN's yet.

if nargin<1; ax = 'io'; end

if ischar(ax) && any(strcmp(ax,evriio([],'validtopics')));
  options = [];
  options.name = 'options';
  options.useclass = 'yes'; %'no'
  options.qrtlim   = 1.5;
  options.qrtlimx  = 3;
  options.prctlo   = 0.25;
  options.prcthi   = 0.75;
  
  options.plotstyle  = 'traditional';  %'compact'
  options.boxwidth   = 0.45;
  options.boxstyle   = 'outline'; %'filled'
  options.boxcolor   = 'b';
  options.meancolor  = 'r';  %color for mean marker (all modes)
  options.meansymbol = '.';  %symbol for mean marker
  options.positions  = [];   %positions to plot boxes at. len = #unique classes
  options.groupings  = {};   % indices to classsets to use for major and minor grouping
  
  options.groupsortindex = []; % sort index to rearrange rows to desired grouping
  options.nminorgroups   = 0;  % number of minor groups
  
  options.outliersize = 6;       %Size of the marker used for outliers, in points (n/72 inch).
  options.symbol      = 'ob';    %symbol to use for outliers
  options.jitter	    = 0;       %maximum offset for outliers (off-axis) so replicate points are visible
  options.medianstyle = 'line';  %'line' — Draws a line for the median. 'target' — Draws a black dot inside a white circle for the median.
  options.notch = 'off'; %'off' 'on' 'marker'
  options.labelorientation = 'horizontal'; % 'inline'
  options.legend     = 'on';
  
  %   %not yet implemented
  %   options.factorseparator = [];
  %   %  Specifies which factors should have their values separated by a grid
  %   %  line. The value may be 'auto' or a vector of grouping variable
  %   %  numbers. For example, [1 2] adds a separator line when the first or
  %   %  second grouping variable changes value. 'auto' is [] for one grouping
  %   %  variable and [1] for two or more grouping variables. The default is
  %   %  [].
  %   options.factorgap = [];
  %   %   Specifies an extra gap to leave between boxes when the corresponding
  %   %   grouping factor changes value, expressed as a percentage of the width
  %   %   of the plot. For example, with [3 1], the gap is 3% of the width of
  %   %   the plot between groups with different values of the first grouping
  %   %   variable, and 1% between groups with the same value of the first
  %   %   grouping variable but different values for the second. 'auto'
  %   %   specifies that boxplot should choose a gap automatically. The default
  %   %   is [].
  
  if nargout==0; evriio(mfilename,ax,options);
  else; s = evriio(mfilename,ax,options); end
  return;
end

if nargin==1 % boxplot(x)
  if length(ax)==1 & ishandle(ax)
    error('Data (x) must also be input if plotting to an axis (ax)')
  end
  options   = boxplot('options');
  if isnumeric(ax) | isdataset(ax)
    x       = ax;
    ax      = [];
    [cls,lbl, x,options] = recon_cls(x,[],options);
  else
    error('Input (x) does not appear to be a valid array.')
  end
elseif nargin==2
  % boxplot(ax,x)
  % boxplot(x,cls)
  % boxplot(x,options)
  if length(ax)==1 & ishandle(ax)  % boxplot(ax,x)
    options = boxplot('options');
    [cls,lbl, x,options] = recon_cls(x,[],options);
    if ~isnumeric(x) & ~isdataset(x)
      error('Input (x) does not appear to be a valid array.')
    end
  else
    if isstruct(x) % boxplot(x,options)
      options = myreconopts(x);
      x       = ax;
      ax      = [];
      [cls,lbl, x,options] = recon_cls(x,[],options);
      if ~isnumeric(x) & ~isdataset(x)
        error('Input (x) does not appear to be a valid array.')
      end
    else
      % boxplot(x,cls)
      options = boxplot('options');
      cls     = x;
      x       = ax;
      ax      = [];
      [cls,lbl, x,options] = recon_cls(x,cls,options);
    end
  end
elseif nargin==3
  % boxplot(ax,x,options)
  % boxplot(ax,x,cls)
  % boxplot(x,'property','value')
  if length(ax)==1 & ishandle(ax)
    if ~isnumeric(x) & ~isdataset(x)
      error('Input (x) does not appear to be a valid array.')
    end
    if isstruct(varargin{1}) % boxplot(ax,x,options)
      options = myreconopts(varargin{1});
      [cls,lbl, x,options] = recon_cls(x,[],options);
    elseif ischar(varargin{1})
      error('Property requires a value pair.')
    else                     % boxplot(ax,x,cls)
      options = boxplot('options');
      cls = varargin{1};
      [cls,lbl, x,options] = recon_cls(x,cls,options);
    end
  else
    if isstruct(varargin{1});
      % (x,cls,options)
      if ischar(x)
        %Make into cell array.
        x = str2cell(x);
      end
      options = myreconopts(varargin{1});
      cls     = x;
      x       = ax;
      ax      = [];
      [cls,lbl, x,options] = recon_cls(x,cls,options);
    elseif ischar(x)             % boxplot(x,'property','value')
      options = [{x}; varargin(:)];
      options = myreconopts(tostruct(options{:}));
      x       = ax;
      ax      = [];
      [cls,lbl, x,options] = recon_cls(x,[],options);
    else
      error('The second input was expected to be a valid property string')
    end
    if ~isnumeric(x) & ~isdataset(x)
      error('Input (x) does not appear to be a valid array.')
    end
  end
else %nargin>3
  % boxplot(ax,x,'property',value,'property',value)
  % boxplot(x,'property',value,'property',value) %>=3
  % boxplot(ax,x,cls,'property',value,'property',value)
  if length(ax)==1 & ishandle(ax)
    % boxplot(ax,x,'property',value,'property',value)
    if ~isnumeric(x) & ~isdataset(x)
      error('Input (x) does not appear to be a valid array.')
    end
    if ischar(varargin{1})
      options = varargin(:);
      options = myreconopts(tostruct(options{:}));
      [cls,lbl, x,options] = recon_cls(x,[],options);
    else
      % boxplot(ax,x,cls,'property',value,'property',value)
      cls = varargin{1};
      options = varargin(2:end);
      options = myreconopts(tostruct(options{:}));
      [cls,lbl, x,options] = recon_cls(x,cls,options);
    end
  else
    % boxplot(x,'property',value,'property',value) %>=3
    options = [{x}; varargin(:)];
    options = myreconopts(tostruct(options{:}));
    x       = ax;
    ax      = [];
    [cls,lbl, x,options] = recon_cls(x,[],options);
  end
end
%At this point, ax, x, cls and options should all be assigned

if ~ismember(lower(options.boxstyle),{'outline','filled'})
  error('Input boxstyle as "%s" not valid. Must be "outline" or "filled".',options.boxstyle)
end

m   = size(x);
if any(m==1) %isvector(x)
  if isdataset(x) & m(1)==1
    x = x';
  else
    x = x(:);
  end
end
if ~isdataset(x)
  x = dataset(x);
end

%Old code that groups by column
% s   = [min(x.data); percentile(x.data,[0.25 0.5 0.75]); max(x.data)];
% iqr = s(4,:)-s(2,:);
% for i1=1:m(2)
%   s(5,i1) = max(x.data(x.data(:,i1)<(s(4,i1)+options.qrtlim*iqr(i1)),i1));
%   s(1,i1) = min(x.data(x.data(:,i1)>(s(2,i1)-options.qrtlim*iqr(i1)),i1));
% end
%Utilizes class variable
srt = options.groupsortindex;
clsorig = cls;
if ~isempty(srt)
  cls = cls(srt);
  [uniqcls,clsi] = unique(cls);       % uniqcls are sorted
  uniqcls = cls(sort(clsi));        % uniqcls are in order of appearance
  cls = clsorig; % restore...
else
  [junk,clsi] = unique(cls);
  uniqcls = cls(sort(clsi));
end
if isempty(options.positions)
  xbx  = 1:length(uniqcls);   % xbx is index to unique cls...
else
  if length(uniqcls)~=length(options.positions)
    error('POSITIONS option must equal the number of boxes being plotted')
  end
  xbx = options.positions;
end
s    = zeros(6,length(uniqcls));
iqr  = zeros(1,length(uniqcls))*nan;
for i1=1:length(xbx)
  %grab finite data which matches this class
  xdatasub = x.data(clsorig==uniqcls(i1));
  xdatasub = xdatasub(isfinite(xdatasub));
  if length(xdatasub)<3
    s(1:5,i1) = nan;  %no data or all missing, skip to next
    s(6,i1)   = mean(xdatasub); % but can calculate mean
    continue;
  end
  %calculate what stats we can
  s(2:4,i1) = percentile(xdatasub,[options.prctlo 0.5 options.prcthi]);
  iqr     = s(4,:)-s(2,:);
  mn = min(xdatasub(xdatasub>=(s(2,i1)-options.qrtlim*iqr(i1))));
  if isempty(mn); mn = nan; end
  s(1,i1) = mn;
  mx = max(xdatasub(xdatasub<=(s(4,i1)+options.qrtlim*iqr(i1))));
  if isempty(mx); mx = nan; end
  s(5,i1) = mx;
  s(6,i1) = mean(xdatasub);
  s(7,i1) = length(xdatasub);  %number of values
end

if isempty(ax)
  figure, ax = axes;
else
  axes(ax);
end
ybx = [(xbx-options.boxwidth/2); (xbx+options.boxwidth/2)];
zbx = [(xbx-options.boxwidth/4); (xbx+options.boxwidth/4)];

outlierhv = 'on';
extoutlierhv = 'on';
for i1=1:length(xbx)
  %draw box, whiskers, and internal obejects
  
  if strcmpi(options.legend,'on')
    if i1==1;
      hv = 'on';    %first time through, most have visibility
    else
      hv = 'off';   %second time through, no visibility
    end
    hve = 'off';   %extra items have this visibility
  else
    %not legend-friendly mode? leave all handles ON
    hv = 'on';
    hve = 'on';
  end
  
  %calculate box shape first
  notchw = iqr(i1)*1.58/sqrt(s(7,i1))/2;  %calcluate 1/2 height of notch
  switch options.notch
    case 'on'
      %add points for narrowing
      py = [s(2,i1) max(s(2,i1),min(s(4,i1),s(3,i1)+[-notchw 0 notchw]))  s(4,i1) s(4,i1) max(s(2,i1),min(s(4,i1),s(3,i1)+[notchw 0 -notchw])) s(2,i1)]';
      notchnarrow = abs(ybx(1,i1)-ybx(2,i1))*.25;  %and width at median
      px = [ybx(1,i1)+[0 0 notchnarrow 0 0] ybx(2,i1)-[0 0 notchnarrow 0 0]]';
      medianx = ybx(:,i1)+[notchnarrow -notchnarrow]';
    otherwise  %standard simple box  (notch = 'off' or 'marker')
      px = [ybx(1,i1);ybx(1,i1);ybx(2,i1);ybx(2,i1)];
      py = s([2 4 4 2],i1);
      medianx = ybx(:,i1);
  end
  
  switch lower(options.boxstyle)
    %-----------------------------------------------------
    case 'outline'      
      fillcolors = classcolors;
      fillcolors = fillcolors(2:end,:);
      if ~isempty(options.nminorgroups) & options.nminorgroups>0
        ncolors = options.nminorgroups;
        myboxcolor = fillcolors(1+mod((i1-1),ncolors),:);
        wiskercolor = myboxcolor;
        outliercolor = myboxcolor;
      else
        myboxcolor = options.boxcolor;
        wiskercolor = 'k';
        outliercolor = 'b';
      end
      meancolor = options.meancolor;
      h = plot([xbx(i1); xbx(i1)],s([1 5],i1),'--','tag','Whisker','color',wiskercolor,'handlevisibility',hv);
      legendname(h,'Data Range (Robust)');
      hold on
      h = patch(px,py,'w','tag','Box','edgecolor',myboxcolor,'handlevisibility',hv);
      legendname(h,'Interquartile Range');
      
      switch options.notch
        case 'marker'
          notchface = options.meancolor;
          notchcolor = options.meancolor;
      end
      
      switch options.medianstyle
        case 'line'
          h = plot(medianx,s([3 3],i1),'-','tag','Median','color',myboxcolor,'handlevisibility',hv);
          legendname(h,'Median');
        otherwise
          h = plot(mean(ybx(:,i1)),s(3,i1),'o','tag','MedianOuter','markersize',6,'markerfacecolor','w','handlevisibility',hv);
          legendname(h,'Median');
          h = plot(mean(ybx(:,i1)),s(3,i1),'.','tag','MedianInner','markersize',6,'markerfacecolor',myboxcolor,'handlevisibility',hve);
          legendname(h,'Median (Outer)')
      end
      if ~isempty(options.meansymbol);
        h = plot(xbx(i1),  s(6,i1),options.meansymbol,'tag','Mean','color',meancolor,'handlevisibility',hv);
        legendname(h,'Mean')
      end
      h = plot(zbx(:,i1),s([1 1],i1),'-','tag','Lower Adjacent Value','color',wiskercolor,'handlevisibility',hve);
      h = plot(zbx(:,i1),s([5 5],i1),'-','tag','Upper Adjacent Value','color',wiskercolor,'handlevisibility',hve);
      
      %-----------------------------------------------------
    case 'filled'
      fillcolors = classcolors;
      fillcolors = fillcolors(2:end,:);
      if ~isempty(options.nminorgroups) & options.nminorgroups>0
        ncolors = options.nminorgroups;
        options.meancolor = 'w';
        myboxcolor = fillcolors(1+mod((i1-1),ncolors),:);
        wiskercolor = myboxcolor;
        outliercolor = myboxcolor;
      else
        myboxcolor = options.boxcolor;
        wiskercolor = myboxcolor;
        outliercolor = myboxcolor;
      end
      %when filled, internal objects need to be colored differently
      mark_color = 'w';
      options.boxwidth = options.boxwidth/2;
      
      %do box and addons
      h = plot([xbx(i1); xbx(i1)],s([1 5],i1),'-','tag','Whisker','color',wiskercolor,'handlevisibility',hv);
      legendname(h,'Data Range (Robust)')
      hold on
      h = patch(px,py,'k','tag','Box','facecolor',myboxcolor,'edgecolor',myboxcolor,'handlevisibility',hv);
      legendname(h,'Interquartile Range')
      
      switch options.notch
        case {'marker'}
          options.notch = 'marker';  %make sure BOTH of these modes show markers (when in "filled" mode)
          notchface = mark_color;
          notchcolor = options.boxcolor;
      end
      
      switch options.medianstyle
        case 'line'
          h = plot(ybx(:,i1),s([3 3],i1),['-'],'tag','Median','color',mark_color,'handlevisibility',hv);
          legendname(h,'Median')
        otherwise
          h = plot(mean(ybx(:,i1)),s(3,i1),'o','tag','MedianOuter','markersize',6,'markerfacecolor','w','color',outliercolor,'handlevisibility',hv);
          legendname(h,'Median');
          h = plot(mean(ybx(:,i1)),s(3,i1),'.','tag','MedianInner','markersize',6,'markerfacecolor',outliercolor,'color',outliercolor,'handlevisibility',hve);
          legendname(h,'Median (Outer)')
      end
      if ~isempty(options.meansymbol)
        h = plot(xbx(i1),  s(6,i1),options.meansymbol,'tag','Mean','color',options.meancolor,'handlevisibility',hv);
        legendname(h,'Mean')
      end
  end
  
  %show notch markers if selected
  switch options.notch
    case {'marker'}
      h = plot(mean(ybx(:,i1)),s(3,i1)+notchw,'V','markerfacecolor',notchface,'color',notchcolor,'tag','NotchHi','handlevisibility',hv);
      legendname(h,'Median Upper 95%')
      h = plot(mean(ybx(:,i1)),s(3,i1)-notchw,'^','markerfacecolor',notchface,'color',notchcolor,'tag','NotchLo','handlevisibility',hv);
      legendname(h,'Median Lower 95%')
  end
  
  %show outliers (if any)
  i3 = find(cls==uniqcls(i1));
  i2 = find((x.data(i3)>s(4,i1)+options.qrtlim*iqr(i1))&(x.data(i3)<=s(4,i1)+options.qrtlimx*iqr(i1)));
  if ~isempty(i2)
    h = plot(xbx(i1)*ones(length(i2),1)+rand(length(i2),1)*(options.jitter)-(options.jitter/2),x.data(i3(i2)),options.symbol...
      ,'tag','Outliers','markersize',options.outliersize,'handlevisibility',outlierhv,'color',outliercolor);
    legendname(h,'Outliers')
    if strcmpi(options.legend,'on')
      outlierhv = 'off';  %do NOT show legend entries again for this type
    end
  end
  
  i4 = find(x.data(i3)>s(4,i1)+options.qrtlimx*iqr(i1));
  if ~isempty(i4)
    h = plot(xbx(i1)*ones(length(i4),1)+rand(length(i4),1)*(options.jitter)-(options.jitter/2),x.data(i3(i4)),options.symbol, ...
      'tag','OutliersX','markersize',options.outliersize,'handlevisibility',extoutlierhv,'color',outliercolor);
    set(h,'markerfacecolor',get(h,'color'));
    legendname(h,'Extreme Outliers')
    if strcmpi(options.legend,'on')
      extoutlierhv = 'off';  %do NOT show if we find them on the other side
    end
  end
  
  i2 = find((x.data(i3)<s(2,i1)-options.qrtlim*iqr(i1))&(x.data(i3)>=s(2,i1)-options.qrtlimx*iqr(i1)));
  if ~isempty(i2)
    h = plot(xbx(i1)*ones(length(i2),1)+rand(length(i2),1)*(options.jitter)-(options.jitter/2),x.data(i3(i2)),options.symbol,...
      'tag','Outliers','markersize',options.outliersize,'handlevisibility',outlierhv,'color',outliercolor);
    legendname(h,'Outliers')
    if strcmpi(options.legend,'on')
      outlierhv = 'off';  %do NOT show legend entries again for this type
    end
  end
  i4 = find(x.data(i3)<s(2,i1)-options.qrtlimx*iqr(i1));
  if ~isempty(i4)
    h = plot(xbx(i1)*ones(length(i4),1)+rand(length(i4),1)*(options.jitter)-(options.jitter/2),x.data(i3(i4)),options.symbol, ...
      'tag','OutliersX','markersize',options.outliersize,'handlevisibility',extoutlierhv,'color',outliercolor);
    set(h,'markerfacecolor',get(h,'color'));
    legendname(h,'Extreme Outliers')
    if strcmpi(options.legend,'on')
      extoutlierhv = 'off';  %do NOT show if we find them on the other side
    end
  end
  
end
hold off

set(ax,'xtick',xbx(1,:))
axl = axis;
axl(1:2) = [min(xbx(1,:))-1 max(xbx(1,:))+1];
axis(axl);

if ~isempty(lbl)
  if ~iscell(lbl)
    lbl = strtrim(str2cell(lbl));
  end
  lbl = lbl(uniqcls);  % labels for the plotted groups
  switch options.labelorientation
    case 'inline'
      minext = 0;
      for j=1:length(lbl);
        th = text(xbx(1,j),axl(3)-abs(axl(4)-axl(3))*.02,lbl{j});
        set(th,'horizontalAlignment','right','rotation',90,'FontSize',9)
        %get how far off the figure these labels are
        set(th,'units','pixels');
        ext = get(th,'extent');
        set(th,'units','data');
        minext = min(minext,ext(2));
      end
      set(ax,'xticklabel','')
      if minext<0
        %if any label is off the figure, adjust the axes down so the labels
        %fits
        minext = minext*.8;  %give a 20% buffer for window size
        set(ax,'units','pixels')
        pos = get(ax,'position');
        pos = pos-[0 minext 0 -minext];
        set(ax,'position',pos);
        set(ax,'units','normalized')
        drawnow
      end
    otherwise
      set(ax,'xticklabel',lbl)
  end
end

disp('')
if nargout<1
  clear s options
end

function []=boxplotDatatipCallback()
disp('boxplotDatatipCallback')

function []=boxplotUpdateDataCursorCallback()
disp('boxplotUpdateDataCursorCallback')

function []=boxplotMoveDataCursorCallback()
disp('')

%--------------------------------------------------------------
function [cls,lbl, x,options] = recon_cls(x,cls,options)
%RECON_CLS Reconciles the input (cls) with input (x)
%
%INPUTS:
%    x = dataset object containing data to be plotted
%  cls = specifies how data are grouped
%        a) scalar, uses dataset class field x.class{1,cls}.
%        b) 1x2 vector, uses dataset class field x.class{cls(1),cls(2)}.
%        c)(cls) must have one row per element of (x) or per column of (x)
%
%OUTPUTS:
%  cls = a vector with the same number of elements as elements of (x)
%  lbl = cell array of string labels, one for each unique cls, in order of
%  unique(cls)
%  x   = input dataset where soft excluded rows/cols are hard deleted
%
%I/O: [cls,lbl, x,options] = recon_cls(x,cls,options);

% Do hard exclude
xinclude1 = [];
xinclude2 = [];
if isdataset(x)
  morig = size(x,1);
  norig = size(x,2);
  xinclude1 = x.include{1};
  xinclude2 = x.include{2};
  x = x(x.include{1}, x.include{2});
end

% groupings
% Combine two classsets or use one classset plus input cell array of classids
if isempty(cls)
  groupings = options.groupings;
  if ~isempty(groupings)
    if isnumeric(groupings)
      %convert [ 1 2 ] -> {1 2}
      groupings = num2cell(groupings);
    end
    if isempty(groupings{1})
      gsuper = [];
    elseif ~iscell(groupings{1})
      if numel(groupings{1})>1
        gsuper = str2cell(sprintf('%g\n',groupings{1}));
      elseif isdataset(x)
        gsuper = getclassidorlabel(x, groupings{1});
      else
        gsuper = [];
      end
    else
      gsuper = groupings{1};
      gsuper = gsuper(xinclude1);
    end
    if length(groupings)<2 | isempty(groupings{2})
      gsub = [];
    elseif ~iscell(groupings{2})
      if numel(groupings{2})>1
        gsub = str2cell(sprintf('%g\n',groupings{2}));
      elseif isdataset(x)
        gsub   = getclassidorlabel(x, groupings{2});
      else
        gsub = [];
      end
    else
      gsub   = groupings{2};
      gsub   = gsub(xinclude1);
    end
    [classid, class, sortindex, nminor, xpos] = getclass(gsuper, gsub);
    if isdataset(x)    
      x.classlookup{1} = [];
      x.class{1} = [];
      x.classid{1} = classid;
    end
    options.groupsortindex = sortindex;
    options.nminorgroups   = nminor;
    options.positions = xpos;
  end
end

if isempty(cls) & strcmpi(options.useclass,'yes') & isdataset(x)
  %find first non-empty class preferring mode 2 over mode 1
  notemptycls = ~cellfun('isempty',x.class);  %which are not empty
  notemptycls = flipud(notemptycls);  %flip so we prefer mode 2
  [i,j] = find(notemptycls);
  if ~isempty(i);
    cls = [3-i(1) j(1)];  %3-i swaps 2<->1 (because of flipud)
  end
end

if length(cls)==1
  cls = [1 cls];
end
if all(size(cls)==[1 2])
  if ~isdataset(x)
    error('When input cls is a two-element vector, x must be a dataset')
  end
  b   = unique(x.class{cls(1),cls(2)});
  if ~isempty(x.classid{cls(1),cls(2)})
    lbl = x.classid{cls(1),cls(2)};
  else
    lbl = cell(0);
  end
  
  if cls(1)==1
    %mode 1 class
    cls = x.class{cls(1),cls(2)}(:);
    [lblx,i,j] = unique(cls);
    cls = j*ones(1, size(x,2));  % cls is index, 1,...,nuniquecls. use with lbl
    lbl = lbl(i);
  elseif cls(1) == 2
    %mode 2 class
    cls = x.class{cls(1),cls(2)}(:);
    [lblx,i,j] = unique(cls);
    cls = ones(size(x,1),1)*j'; % cls is index, 1,...,nuniquecls. use with lbl
    lbl = lbl(i);
  else
    error('class must be mode 1 or 2');
  end
elseif ~isempty(cls)
  m   = size(x);
  % Adjust cls if dso to use includes
  if isdataset(x)
    if ischar(cls)            % char
      if size(cls,1)==morig*norig
        % Get unfolded index of included
        mask=zeros(morig,norig);
        mask(xinclude1, xinclude2)=1;
        iunfold = mask(:);
        cls = cls(iunfold>0,:);
      elseif size(cls,1)==norig
        mask=zeros(1,norig);
        mask(xinclude2)=1;
        iunfold = mask(:);
        cls     = cls(iunfold>0,:);
      end
    elseif iscell(cls)         % cell
      if numel(cls)==morig*norig
        % Get unfolded index of included
        mask=zeros(morig,norig);
        mask(xinclude1, xinclude2)=1;
        iunfold = mask(:);
        cls = {cls{iunfold>0}}';
      elseif numel(cls)==norig
        mask=zeros(1,norig);
        mask(xinclude2)=1;
        iunfold = mask(:);
        cls     = {cls{iunfold>0}}';
      end
    elseif isnumeric(cls)     % numeric
      if numel(cls)==morig*norig
        cls = cls(xinclude1, xinclude2);
      elseif numel(cls)==norig
        cls     = cls(xinclude2);
      end
    end
  end
  if isdataset(x)
    numelx = numel(x.data);
  else
    numelx = numel(x);
  end
  
  % Set lbl, a cell array. cls values are index into lbl.
  % Boxplot columns are in order of unique(cls)
  if ischar(cls)
    if size(cls,1)==numelx
      [lbl,i,j] = unique(str2cell(cls));
      cls     = j(:);
    elseif size(cls,1)==m(2)
      [lbl,i,j] = unique(str2cell(cls));
      cls     = ones(m(1),1)*j';
    else
      error('Character array input (cls) must have the same number of rows as elements of (x) or columns of (x).')
    end
  elseif iscell(cls)
    [lbl,i,j] = unique(cls);    % NOTE:so lbl are sorted unique cls
    if numel(cls)==numelx
      lbl     = lbl(:);
      cls     = j(:);
    elseif numel(cls)==m(2)
      lbl     = lbl(:);
      cls     = ones(m(1),1)*j(:)'; %col values is index into lbl for that col
    else
      error('Cell array input (cls) must have the same number of elements as elements of (x) or columns of (x).')
    end
  elseif isnumeric(cls)
    if numel(cls)==numelx
      [b,i,j] = unique(cls);
      cls     = j;
      lbl = cell(0);
      if m(2)==1 & strcmpi(options.useclass,'yes')
        if isdataset(x) & ~isempty(x.classid{1})
          lbl = x.classid{1}(i);
        else
          lbl = cell(0);
        end
      end
    elseif numel(cls)==m(2)
      [b,i,j] = unique(cls);
      cls     = j;
      if isdataset(x) & strcmpi(options.useclass,'yes')
        if ~isempty(x.label{2}) & length(b)==m(2)
          lbl   = x.label{2};
        else
          lbl = num2cell(b);
        end
      else
        lbl     = num2cell(b);
      end
      cls     = ones(m(1),1)*cls(:)';
    else
      error('Input (cls) must equal the number of columns of the input x');
    end
    
  else
    error('Input (cls) must be numeric, cell or character array')
  end
end

if isempty(cls)
  if strcmpi(options.useclass,'yes') & isdataset(x)
    lbl = x.label{2};
  else
    lbl = cell(0);
  end
  cls = ones(size(x,1),1)*(1:size(x,2));
end

%-------------------------------------------------------
function options = myreconopts(options,varargin)
%customized reconopts function to handle special defaults when various
%options are given

d = boxplot('options');
if isfield(options,'plotstyle') & strcmpi(options.plotstyle,'compact')
  % When the plotstyle parameter takes the value 'compact', the following
  % default values for other parameters apply. User-passed values for
  % these will still take presidence, however, setplspref cannot modify
  % these values.
  %NOTE: some of these are NOT yet supported by our boxplot, but this is
  %the entire list to match the Mathworks version of this function
  d.boxstyle         = 'filled';
  d.medianstyle      = 'target';
  d.outliersize      = 4;
  d.symbol           = 'o';
  d.labelorientation = 'inline';
  d.jitter	         = 0.5;
  %   d.factorseparator	 = 'auto';       %%%%Not Yet Supported!
  %   d.factorgap	       = 'auto';       %%%%Not Yet Supported!
  %   d.labelverbosity   = 'majorminor'; %%%%Not Yet Supported!
end

%reconcile supplied options with defaults
options = reconopts(options,d,0);

if strcmpi(options.plotstyle,'compact') & strcmpi(options.notch,'on')
  %interpret notch "on" as "marker" when in compact plotstyle mode
  options.notch = 'marker';
end

%-------------------------------------------------------
function out = tostruct(varargin)
%convert list of items to a structure (cell-safe)
% takes a list of input items assumed to be ('property',value) pairs and
% creates a structure as does struct() except that cell "value" elements
% are correctly transformed into cells (rather than creating a structure
% array)

for k=2:2:length(varargin);
  varargin{k} = varargin(k);  %convert every "value" element to a single-element cell
end
out = struct(varargin{:});

%--------------------------------------------------------------------------
function [classid, class, sortindex, nminor, xpos] = getclass(c1,c2) 
% Generate a cell array classid by combining inputs c1 and c2 where classid
% is ordered to group rows by c1's unique values, then sub-grouped by c2's
% unique values. c1 and c2 are cell arrays used to form main and
% sub-groups.
%  INPUT:
%         c1 : cell array used for major grouping
%         c2 : cell array used for minor grouping
% OUTPUT:
%    classid : classid with major/minor grouping.
%      class : class associated with classid.
%  sortindex : index to sort dataset to match classid order.
%     nminor : number of minor groups.
%       xpos : vector of integer positions to locate boxes at.

classid   = []; 
class     = []; 
sortindex = []; 
nminor    = []; 
xpos      = [];

if isempty(c1) & isempty(c2)
  return
end
if isempty(c1) | isempty(c2)
  %SINGLE CLASS case
  if isempty(c2)
    classid = c1;
  else
    classid = c2;
  end
  class = cellarray2ints(classid);
  nclass = length(unique(class));
  sortindex = 1:length(class);
  xpos = 1:nclass;
  if isempty(c2)
    nminor = 0;
  else
    nminor = nclass;
  end
  return;
end

% Number of spaces between major groups in the boxplot
np  = 1;
c1 = c1(:)';   % ensure is row
c2 = c2(:)';
len = length(c1);
[intmajor] = cellarray2ints(c1);
[intminor] = cellarray2ints(c2);
comclass = [intmajor' intminor'];

% Sort by major grouping then minor grouping
[sorted, sortindex] = sortrows(comclass, [1 2]);
nmajor = length(unique(c1(:)));
nminor = length(unique(c2(:)));

cnminor = unique(intminor);
cnmajor = unique(intmajor);

xposm    = nan(nminor,nmajor); 
xposmask = false(nminor,nmajor);
% flag those major/minor class combinations which actually occur
for i=1:len
  xposmask(intminor(i),intmajor(i)) = true;
end
% create position vector for all major/minor class combinations
for j=cnmajor
  xposm(:,j) = cnminor + (j-1)*(nminor+np);
end
xpos = xposm(:)';
% exclude positions which do not have data from xpos
xpos = xpos(xposmask(:));

% Generate combined classid
classid = cell(1,len); % classid in order of data
for i=1:len
  tmp = [c1(i) ' : ' c2(i)];
  classid{i} = [tmp{:}];
end
class = cellarray2ints(classid);

%--------------------------------------------------------------------------
function [intarray] = cellarray2ints(cellarray) 
% Replace unique entries in a cell array of strings by integers, starting
% with 1, up to number of unique values in cellarray.
[uniqcls,clsi, index1] = unique(cellarray);  % uniqcls: sorted unique classid
classiduniq = cellarray(sort(clsi));  % unique classid in order of appearance
[junk, zd2] = sort(classiduniq);
intarray = zd2(index1);

%--------------------------------------------------------------------------
function cellarr = getclassidorlabel(x, i)
% Get a cell array, 1 x m, containing classids or labels
if size(x.classid,2)>=i & ~isempty(x.classid{1,i})
  cellarr = x.classid{1,i};    % classid
elseif size(x.label,2)>=i & ~isempty(x.label{1,i})   % try label
  cellarr = x.label{1,i};
  cellarr=str2cell(cellarr);
  cellarr=cellarr(:)';
else
  cellarr = [];
end
