function varargout = idateticks(ax,options)
%IDATETICKS convert axis labels into intelligent date ticks
% Converts the ticks on the current axes into date or time ticks. Similar
% to the DATETICK function, IDATETICKS also assures that a date will appear
% on any axes, even when zoomed into a single day's scale.
% Inputs are both optional and include (ax) a string identifying the axis
% to convert to date as 'x', 'y', or 'z' and (dateform) a numerical or
% string code defining the type of string representation to use for date
% identification (default = 2). See DATETICK for more information on valid
% dateform values.
%
% Options include either a numerical value for "dateform" or a structure
% with one or more of the following fields:
%    dateform: [2] numerical date form (see DATETICK)
%    minticks: [4] minimum number of ticks to allow on the axis
%    maxticks: [8] maximum number of ticks to allow on the axis
%
%I/O: idateticks(ax,options)
%
%See also: DATETICK, PLOTGUI

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin>0 & ischar(ax) & ismember(ax,evriio([],'validtopics'));
  options = [];
  options.dateform = 2;
  options.minticks = 4;
  options.maxticks = 8;
  if nargout==0; clear varargout; evriio(mfilename,ax,options); else; varargout{1} = evriio(mfilename,ax,options); end
  return;
end

switch nargin
  case 0
    ax = '';
    options = [];
  case 1
    if isstruct(ax);
      options = ax;
      ax = '';
    elseif isnumeric(ax);
      options = [];
      options.dateform = ax;
      ax = '';
    else
      options = [];
    end
  case 2
    if ~isstruct(options);
      temp = options;
      options = [];
      options.dateform = temp;
    end
end
if isempty(ax)
  ax = 'x';
end
options = reconopts(options,'idateticks');

%---------------------------------------

units = [1/365 1/30 1 24/12 24/6 24/3 24/2 24 (24*2) (24*3) (24*4) (24*12) (24*30) (24*60) (24*60*60) (24*60*60*1000)];

axrng = axis;
nt = floor(abs(axrng(2)-axrng(1)).*units);

nt(nt<options.minticks) = inf;  %don't consider units which will give < n ticks in window
if all(~isfinite(nt));
  return;
end

[mwhat,mwhere] = min(nt);
units = units(mwhere);
if units<=1;
  unitstr = options.dateform;
elseif units<24*60*60;
  unitstr = 15;
elseif units<24*60*60*1000
  unitstr = 13;
else
  unitstr = 'HH:MM:SS.FFF';
  options.maxticks = ceil(options.maxticks*.6);
end
step = 1/units;
if mwhat>options.maxticks; %too many tics
  step = step*ceil(mwhat/options.maxticks);
end
%create vector of tics
t = ceil(axrng(1).*units)/units:step:floor(axrng(2).*units)/units;
set(gca,[ax 'tick'],t);
set(gca,[ax 'TickLabel'],datestr(t,unitstr));


day   = (t==fix(t))*2;

if ~any(day);
  day(1) = 1;
end

ticks = str2cell(get(gca,[ax 'TickLabel']));
for j=find(day);
  if day(j)==1;
    ticks{j} = [datestr(t(j),options.dateform) '...'];
  else
    ticks{j} = datestr(t(j),options.dateform);
  end
end
set(gca,[ax 'TickLabel'],ticks)
setappdata(gca,[ax 'idateticks'],true)

if strcmp(getappdata(gcf,'figuretype'),'PlotGUI')
  set(get(gca,'xlabel'),'buttonDownFcn','plotgui(''update'',''figure'',gcbf)')
  if checkmlversion('>','7.2')
    set(zoom,'ActionPostCallback',@zoomupdate);
    set(pan,'ActionPostCallback',@zoomupdate);
  end
end

%-----------------------------------------------
%automatically update axis if zoomed or panned
function zoomupdate(varargin)

ax = varargin{2}.Axes;

%create timer to perform this action IF no additional zooms are done in the
%specified startdelay time period
t = timerfind('tag','zoomupdate');
if ~isempty(t);
  stop(t);
  delete(t);
end
t = timer('tag','zoomupdate');
t.ExecutionMode = 'singleShot';
t.StartDelay = .2;
t.TimerFcn = @zoomupdate_callback;
t.userdata = ax;
start(t);

%------------------------------------------------
%actual callback to update ticks (called with delay timer)
function zoomupdate_callback(varargin)

ax = varargin{1}.userdata;
if ishandle(ax)
  set(get(0,'currentfigure'),'currentaxes',ax);
  for s = 'xyz';
    if getappdata(ax,[ s 'idateticks']);
      idateticks(s);
    end
  end
end
