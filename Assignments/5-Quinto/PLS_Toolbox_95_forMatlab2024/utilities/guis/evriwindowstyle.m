function isdocked = evriwindowstyle(fig,docked,modal)
%EVRIWINDOWSTYLE Manages window style (modal and docking) across platforms.
% Given a figure handle (fig), set the model and/or docked flags as
% indicated. If either flag is empty, the state is not changed. If an
% output is requested, the current docked state is returned.
%
% With any call (with or without multiple inputs), the dockable flag is
% always set on a figure. Thus, to assure that a figure has the docable
% controls added, simply call: evriwindowstyle(fig);
%
%I/O: evriwindowstyle(fig,docked,modal)
%I/O: evriwindowstyle(fig,[],modal)
%I/O: evriwindowstyle(fig,docked)
%I/O: isdocked = evriwindowstyle(fig);

% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

persistent prod

if nargin<1;
  fig = gcf;
end

if ~solo | checkmlversion('<','7.8')
  %non-deployed (in Matlab)
  %simple case - just use standard assignments
  if nargin>1
    %assigning
    if nargin<3
      modal = 0;
    end
    if modal
      set(fig,'windowstyle','modal')
    elseif ~isempty(docked)
      if docked
        set(fig,'windowstyle','docked')
      else
        set(fig,'windowstyle','normal')
      end
    end
  end
  
  if nargout>0
    %outputs requested? return isClientDocked
    isdocked = strcmp(get(fig,'windowstyle'),'docked');
  end
  
else
  %ONLY deployed applications get here
  
  %get java handle
  c = getfigureclient(fig);
  if isempty(c)
    %Probably uifigure, not java based, so no docking.
    isdocked = 0;
    return
  end
  
  %force on clientDocable
  c.setClientDockable(true);
  %specify product group if deployed
  if isempty(prod)
    [v,prod] = evrirelease;
  end
  setFigDockGroup(fig,prod)
  
  %See if user wanted to change any setting
  if nargin>1
    if nargin<3
      modal = [];
    end
    if isempty(modal)
      %default is to NOT be modal
      modal = 0;
    end
    if isempty(docked)
      %default is to leave docked
      docked = c.isClientDocked;
      
    end
    
    %if deployed, use client method
    if docked
      %figure MUST be visible to dock
      v = get(fig,'visible');
      set(fig,'visible','on');
      drawnow; pause(0.2);
    end
    c.setClientWindowStyle(docked,modal);
    if docked & strcmpi(v,'off');
      set(fig,'visible',v)
    end
    
  end
  
  if nargout>0
    %outputs requested? return isClientDocked
    isdocked = c.isClientDocked;
  end
end

%--------------------------------------------
function out = getfigureclient(fig)

jFrame = get(handle(fig), 'JavaFrame');
if isempty(jFrame)
  %Probably uifigure.
  out = [];
  return
end
pause(0.01);
if checkmlversion('<','7.8') %use this in R2008a and earlier
  % This works up to R2011a
  out = jFrame.fFigureClient;
elseif checkmlversion('<=','8.3')  %2008b to 14a...
  % This works from R2008b and up
  out = jFrame.fHG1Client;
else
  %14b and newer using HG2.
  out = jFrame.fHG2Client;
end

%---------------------------------------------
function out = solo

if (exist('isdeployed') & isdeployed);
  out = true;
else
  out = false;
end
