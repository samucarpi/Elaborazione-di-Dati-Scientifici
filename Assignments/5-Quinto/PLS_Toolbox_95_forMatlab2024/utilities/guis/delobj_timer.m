function out = delobj_timer(tag,handle,delay,varargin)
%DELOBJ_TIMER Automatically delete a given object after a period of time
% Create (or execute) a timer which will automatically delete an object
% after a given period of time.
% INPUTS:
%    tag    = string identifier for the timer object
%    handle = handle of object to delete after set time
%    delay  = length of time to wait (in seconds) before deleting object
%
% Can optionally include additional timer properties and value pairs at end
% of required inputs.
%
%I/O: delobj_timer(tag,handle,delay)
%I/O: delobj_timer(tag,handle,delay,'property',value)

%Copyright © Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

if isempty(handle) | ~ishandle(handle)
  %invalid handle? just exit
  return
end

%create (or re-create) timer with given tag for given handle deletion
% ('tag',handle,delay)
t = timerfind('tag',tag);
if ~isempty(t)
  stop(t);
  delobj_timer_callback(t);
  delete(t);
end
t = timer('tag',tag);

callbacktarget = @delobj_timer_callback;

blinks = 0;
clr    = [];
bg     = [];
if length(delay)==1 | strcmp(get(handle,'type'),'figure')
  %no blinking requested
  t.StartDelay = delay;
  if ~strcmp(get(handle,'type'),'figure') & isprop(handle,'color')
    %not a figure and something with a "color" property? add quick delay
    %to end (will be encoded as fade below)
    delay = [delay 0.5 delay-.2];
  end
end
if length(delay)>1
  %call included request to blink or fade object
  blinks = delay(2);
  if length(delay)>2
    %includes delay before blink/fade
    startdelay = delay(3);
    delay  = round((delay(1)-startdelay)./blinks./20*1000)/1000;
  else
    %immediate start of blink/fade
    delay  = round(delay(1)./blinks./20*1000)/1000;
    startdelay = delay ;
  end
  clr    = get(handle,'color');  %get base color of object
  %see if we can get a background color to fade TO
  if isprop(handle,'backgroundcolor') & ~ischar(get(handle,'backgroundcolor'))
    %explict background color of object itself
    bg = get(handle,'backgroundcolor');
  elseif isprop(handle,'parent') & ishandle(get(handle,'parent')) & ismember(get(get(handle,'parent'),'type'),{'figure' 'axes'})
    %parent is figure or axes, use parent color
    bg = get(get(handle,'parent'),'color');
  else
    bg     = [1 1 1];  %default of white
  end
  t.ExecutionMode = 'fixedDelay';
  t.Period = delay;
  t.StartDelay = max(0,startdelay);
  t.TasksToExecute = 150;  %maximum number of tasks to execute
end

%create userinfo for timer
t.userdata = struct('handle',handle,'blinks',blinks,'color',clr,'backgroundcolor',bg);
t.TimerFcn = callbacktarget;
t.Name     = tag;

%add other properties
if nargin>3;
  for j=1:2:length(varargin)
    if length(varargin)<j+1;
      error('Unmatched property/value pair')
    end
    if ~ischar(varargin{j})
      error('Invalid property name (input #%i)',j+2)
    end
    try
      t.(varargin{j}) = varargin{j+1};
    catch
      error('Invalid value or property name ("%s")', varargin{j});
    end
  end
end
start(t);  %start timer

if nargout>0
  out = t;
end

%--------------------------------------------------------
function delobj_timer_callback(obj,event,varargin)
%actual callback, try deleting object specified in userdata

le=lasterror;
try
  userdata = obj.userdata;
  h = userdata.handle;
  if ~isempty(h) & ishandle(h);
    %check if we're blinking still
    if userdata.blinks>0 & obj.TasksExecuted<100  %note: timer will automatically stop based on TasksToExecute, but we need to stop blinking BEFORE that!
      %just blink first...
      if ~strcmp(get(h,'type'),'figure')
        %blink object - don't delete
        userdata.blinks = userdata.blinks-.05;
        obj.userdata = userdata;
        fract = abs(.5-mod(userdata.blinks-.5,1))*2;  %get fractional oscillator
        set(h,'color',userdata.color*fract+userdata.backgroundcolor*(1-fract));
      end
    else
      %ready to delete
      if strcmp(get(h,'type'),'figure')
        close(h);
      else
        delete(h);
      end
      stop(obj)
    end
  else
    %object gone already? stop timer
    stop(obj);
  end
catch
  %error during deletion, stop timer and show error
  if ~isempty(obj) & isobject(obj) & isvalid(obj) & isa(obj,'timer')
    stop(obj);
  end
  lasterror(le);  %restore previous error state
end
