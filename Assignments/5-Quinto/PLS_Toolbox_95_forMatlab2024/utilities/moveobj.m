function moveobj(action,h,varargin)
%MOVEOBJ Interactively reposition graphics objects.
% Allows point-and-click moving and resizing of graphics object. Moving is
%  performed by clicking and dragging inside the object, resizing by
%  clicking and dragging near an edge or corner of the object.
%
% Input (action) is one of the following keywords:
%    'on'       : turn on movement for object
%    'off'      : turn off movement for object
%    'toggle'   : turn on/off movement  {default: 'toggle'}
%    'x','y'    : turn on movement for x or y direction ONLY
%    'noresize' : turn off ability to resize object
%    'resize'   : turn on ability to resize object
%    'link'     : link to move a different object when given object is
%                  clicked
%
% Several callbacks can also be assigned to the object being moved. These
% are assigned manually using the setappdata command:
%   'buttondownfcn'    : called when the mouse button is depressed
%   'buttonupfcn'      : called when the mouse button is released
%   'buttonmotionfcn'  : called each time the object is moved any distance
%   'doubleclickfcn'   : called when the object is double-clicked
%                        (also short-circuts normal button-down operation)
%   'rightclickfcn'    : called when right click on object.
% For example: setappdata(handle,'buttonupfcn',get(gco,'xdata'))
% Note that gcbo does not operate as usual when being called from these
% callbacks, however gco should return the handle of the object being moved.
% Function handles can also be used and will receive function handle
% arguments plus parent handle and object handle:
%
%    feval(callback{1},callback{:},parent,h);
%
% Input (handle) is the handle of the object to move. Default is current
%  object or axis.
% By default, objects can be resized unless the 'noresize' action is used
%  on an object.
%
%I/O: moveobj(action,handle)
%I/O: moveobj(handle)

%Undocumented actions:
%  'down' : triggers motion ONCE for current object (drag until clicked)
%  'move' : used in callback only (during drag)
%  'up'   : used in callback only (on button release)
%  'parent' : same as down except move PARENT of callback object. This allows
%     assignment of buttondownfcn:  moveobj('parent',gcbo) for a "handle"
%     which is then used to move the parent object.

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 2/03
% JMS 5/03 -added movement of objects on axes
% JMS 6/03 -added link method
%jms 8/11/03 -added hidden buttonupfcn option (appdata on object)
%  -turn on visibility when moving
%jms 2/4/04 -revised double-click logic (use test for "open" selectiontype)

if nargin==0;
  action = 'down';    %no inputs? we're probably in a callback, assume a move
end

if nargin<2;
  if ~isstr(action) & ishandle(action);
    h      = action;       %handle given as only input? toggle move of that object
    action = 'toggle';
  else
    h = gcbo;       %in a callback? then move current object
    if isempty(h);  %if not in a callback, we're doing an on/off/toggle, not move
      if nargin==0; action = 'toggle'; end
      h = gco;
      if isempty(h);
        h = gca;
      end
      if isempty(h)
        error('No moveable object could be located')
      end    
    end
  end
end

%Special modes - action 'parent' allows movement of PARENT of indicated object
if strcmp(action,'parent');
  h = get(h,'parent');
  action = 'down';
end

% ts = now;
% disp([datestr(ts) ' ' action])
switch action
  case {'toggle','on','off','x','y','angle'}
    
    % actions 'x' or 'y' = 'on' with limits on motion to x- or y-direction only
    motionmode = '';
    if ismember(action,{'x','y','angle'})
      motionmode = action;
      action = 'on';
    end

    %if we have a "button down function" field, see if we already have
    %"moveobj" in that command, and if not, add it. If we already had it,
    %remove it.
      
    for h = h(:)';
      if ~strcmp(lower(action),'off')
        setappdata(h,'MOVEOBJ_mode',motionmode)
      end
      
      try
        bdf = get(h,'buttondownfcn');
        ind = strfind(lower(bdf),'moveobj');
        if isempty(ind) & ~strcmp(lower(action),'off')

          if ~isempty(bdf); bdf = [bdf ';']; end
          set(h,'buttondownfcn',[bdf 'moveobj']);

        elseif ~isempty(ind) & ~strcmp(lower(action),'on')

          offset = length('moveobj');
          remove = [];
          for j = 1:length(ind);
            remove(end+1:end+offset) = ind(j):(ind(j)+offset-1);
          end
          bdf(remove)=[];
          set(h,'buttondownfcn',bdf);

        end
      catch
        error('Could not make object moveable')
      end
    end
    
  case 'resize'
    
    setappdata(h,'noresize',0)

  case 'noresize'
    
    setappdata(h,'noresize',1)
    
  case 'link'
    
    if nargin<3
      error('LINK mode requires two object handles')
    end
    setappdata(h,'MOVEOBJ_link',varargin{1});
    moveobj('on',h);    
    
  %-----=================================------
  % The following actions are used internally
  case 'down'

    link = getappdata(h,'MOVEOBJ_link');
    if ~isempty(link); %is this object "linked" to another?
      h = link;
    end

    %check for recent "down" on this same object
    if strcmp(get(gcbf,'selectiontype'),'open')
      %got a double-click - special exit?
      callback = getappdata(h,'doubleclickfcn');
      if ~isempty(callback)
        if ischar(callback)
          eval(callback);
        else
          %Try function handle.
          feval(callback{1},callback{:},get(h,'parent'),h);
        end
        return
      end
    elseif strcmp(get(gcbf,'selectiontype'),'alt')
      callback = getappdata(h,'rightclickfcn');
      if ~isempty(callback)
        if ischar(callback)
          eval(callback);
        else
          %Try function handle.
          feval(callback{1},callback{:},get(h,'parent'),h);
        end
        return
      end
    end
    
    %when calling "down" we pass the object to move so get the object's parent now...
    parent = get(h,'parent');
    
    if strcmp(get(h,'type'),'figure')
      return
    end
        
    isonaxes = strcmp(get(parent,'type'),'axes') & isprop(h,'xdata');
    
    %find the FIGURE which holds this object
    myfig = parent;
    while ~strcmp(get(myfig,'type'),'figure') & parent~=0;
      myfig = get(myfig,'parent');
    end
    if ~isonaxes;   %if this isn't an axis object, myfig and parent should be the same
      parent = myfig;
    end

    if ~strcmp(get(myfig,'selectiontype'),'normal');
      return;
    end
    
    %things to restore later
    info.hdown     = get(h,'buttondownfcn');
    info.motion    = get(myfig,'windowbuttonmotionfcn');
    info.up        = get(myfig,'windowbuttonupfcn');
    info.down      = get(myfig,'windowbuttondownfcn');
    info.isvisible = get(h,'visible');
    info.isonaxes  = isonaxes;
    info.parent    = parent;
    
    if isfield(get(h),'EraseMode'); 
      info.erasemode = get(h,'EraseMode'); 
    else
      info.erasemode = 'normal'; 
    end

    set(h,'visible','on');

    %reference point for movement
    info.pos    = get(parent,'currentpoint');
    info.mode   = getappdata(h,'MOVEOBJ_mode');
    
    if ~isonaxes
      %remember original units for object
      info.hunits    = get(h,'units');
      set(h,'units',get(myfig,'units'));      %set units to match parent
      hpos = get(h,'position');
      if size(hpos,2)<4; 
        hpos(size(hpos,1),4)=0;   %object without "height" info...
        setappdata(h,'noresize',1);  %force noresize
      end;
      
      if getappdata(h,'noresize')
        info.drag = 0;
      else
        info.drag = abs([hpos(1)-info.pos(1) hpos(2)-info.pos(2) hpos(1)+hpos(3)-info.pos(1) hpos(2)+hpos(4)-info.pos(2)])<10;
      end
      
    else  %object is on an axes
      info.hunits = '';      
    end
    
    if strcmp(info.mode,'angle')
      info.correctionangle = calcangle(info.pos) - calcangle(get(h,'xdata'),get(h,'ydata'));
    end

    setappdata(h,'MOVEOBJ_data',info)
    setappdata(myfig,'MOVEOBJ_handle',h);
        
    set(myfig,'windowbuttonmotionfcn','moveobj(''move'',gcbf)',...
      'windowbuttonupfcn','moveobj(''up'',gcbf)',...
      'windowbuttondownfcn','moveobj(''up'',gcbf)');
    set(h,'buttondownfcn','');
    if isfield(get(h),'EraseMode'); set(h,'EraseMode','xor'); end
    
    %do any user-assigned buttonmotionfcn on the object
    callback = getappdata(h,'buttondownfcn');
    if ~isempty(callback)
      if ischar(callback)
        eval(callback);
      else
        %Try function handle.
        feval(callback{1},callback{:},parent,h);
      end
    end 
    
  case 'move'

    parent = h;  %h will actually be our PARENT object

    %get handle and info associated with that handle
    h = getappdata(parent,'MOVEOBJ_handle');    
    if ishandle(h);
      info = getappdata(h,'MOVEOBJ_data');
    else
      info = [];
      setappdata(parent,'MOVEOBJ_handle',[]);    
    end

    %check for missing info
    if ~isa(info,'struct') | ~isfield(info,'motion') | ~isfield(info,'up') | ~isfield(info,'pos')
      %Lost info - just quit
      set(parent,'windowbuttonmotionfcn','','windowbuttonupfcn','','windowbuttondownfcn','');
      if ishandle(h);
        set(h,'buttondownfcn',[]);
      end
      return
    end
    
    newpos = get(parent,'currentpoint');  %position of pointer
    figpos = get(parent,'position');
    
    if info.isonaxes
      %object on axes
      
      xdata = get(h,'xdata');
      ydata = get(h,'ydata');
      
      newpos = get(info.parent,'currentpoint') ;  %position relative to axes
      
      %TODO: add flag to stop reposition if object gets to edge of parent
      %axis.
      if info.isonaxes
        xlim = get(info.parent,'xlim');
        ylim = get(info.parent,'ylim');
      end

      if strcmp(info.mode,'x') | isempty(info.mode);
        xdata = xdata + newpos(1,1)-info.pos(1,1);
      end
      if strcmp(info.mode,'y') | isempty(info.mode);
        if (min(ydata)<min(get(info.parent,'ylim'))&newpos(1,2)<info.pos(1,2)) |...
          (max(ydata)>max(get(info.parent,'ylim'))&newpos(1,2)>info.pos(1,2))
          %New pos is off the top of parent. Check to see if current position if
          %off the top and adjust down.
          if max(ydata)>max(get(info.parent,'ylim'))
            ydata = ydata-(max(ydata)-max(get(info.parent,'ylim')));
          elseif min(ydata)<min(get(info.parent,'ylim'))
            ydata = ydata-(min(ydata)-min(get(info.parent,'ylim')));
          end
        else
          ydata = ydata + newpos(1,2)-info.pos(1,2);
        end
      end
      if strcmp(info.mode,'angle')
        %get angle of data and current point
        dataangle = calcangle(xdata,ydata);
        posangle = calcangle(newpos(1,1:2));
        %difference in angle triggers "rotate" of object to match current
        %point
        dangle = posangle-dataangle-info.correctionangle;
        if isfinite(dangle) & dangle~=0;
          data = [xdata(:) ydata(:)]*[cos(dangle) sin(dangle);-sin(dangle) cos(dangle)];
          ydata = data(:,2);
          xdata = data(:,1);
        end
      end
      
      set(h,'xdata',xdata,'ydata',ydata);
      
    else 
      
      set(h,'units',get(parent,'units'));      %set units to match parent
      hpos   = get(h,'position');   %position of object
      if size(hpos,2)<4; 
        hpos(size(hpos,1),4)=0; 
        hposcols = 1:3;
      else
        hposcols = 1:4;
      end;
      
      if isempty(info.mode);
        info.mode = '';
      end
      
      switch info.mode
        case 'x'
          newpos(2) = info.pos(2);
        case 'y'
          newpos(1) = info.pos(1);
      end
      
      if ~any(info.drag);
        hpos(1:2) = hpos(1:2)+(newpos-info.pos);   %move object normally
      else
        if any(info.drag(1:2))  %change bottom or left
          hpos = hpos + info.drag([1 2 1 2]).*[newpos-info.pos info.pos-newpos];
        end
        if any(info.drag(3:4))  %change top or right
          hpos = hpos + info.drag([3 4 3 4]).*[0 0 newpos-info.pos];
        end
      end
      
      %assign new position (if not out of limits in size or position)
      minsize = getappdata(h,'minsize');
      if isempty(minsize); minsize = [20 10]; end
      if hpos(3)<minsize(1); hpos(3) = minsize(1); end
      if hpos(4)<minsize(2); hpos(4) = minsize(2); end
      if all(hpos(1:2)>0) & all((hpos(1:2)+hpos(3:4))<figpos(3:4));
        set(h,'position',hpos(:,hposcols));
      end

    end
    
    info.pos = newpos;  %update position
    setappdata(h,'MOVEOBJ_data',info)
    
    %do any user-assigned buttonmotionfcn on the object
    callback = getappdata(h,'buttonmotionfcn');
    if ~isempty(callback)
      if ischar(callback)
        eval(callback);
      else
        %Try function handle.
        feval(callback{1},callback{:},parent,h);
      end
    end
    
  case 'up'
    
    parent = h;  %h will actually be our PARENT object
    h = getappdata(parent,'MOVEOBJ_handle');    
    if ishandle(h);
      info = getappdata(h,'MOVEOBJ_data');
    else
      info = [];
      setappdata(parent,'MOVEOBJ_handle',[]);    
    end
    if ~isa(info,'struct') | ~isfield(info,'motion') | ~isfield(info,'up') | ~isfield(info,'pos') | ~isfield(info,'isvisible') | ~isfield(info,'erasemode')
      %Lost info - just quit
      set(parent,'windowbuttonmotionfcn','','windowbuttonupfcn','','windowbuttondownfcn','');
      if ishandle(h);
        set(h,'buttondownfcn',[]);
        if isfield(get(h),'EraseMode'); set(h,'EraseMode','normal'); end
      end
    else
      set(h,'buttondownfcn',info.hdown);  
      set(h,'visible',info.isvisible);
      if isfield(get(h),'Units'); set(h,'units',info.hunits); end
      if isfield(get(h),'EraseMode'); set(h,'EraseMode',info.erasemode); end
      set(parent,'windowbuttonmotionfcn',info.motion,'windowbuttonupfcn',info.up,'windowbuttondownfcn',info.down);
      setappdata(parent,'MOVEOBJ_handle',[]);
      
      %fix for label shadow bug. Create context menu on the given figure
      %and promptly delete it.
      figure(parent);drawnow;
      htemp = uicontextmenu('parent',parent); 
      htemp1=uimenu(htemp,'label','test');
      set(htemp,'visible','on'); drawnow;
      delete([htemp1 htemp]);drawnow
    end
    
    %do any user-assigned buttonupfcn on the object
    callback = getappdata(h,'buttonupfcn');
    if ~isempty(callback)
      if ischar(callback)
        eval(callback);
      else
        %Try function handle.
        feval(callback{1},callback{:},parent,h);
      end
    end
    
end
    
% disp([datestr(ts) ' ' action ' done'])

%------------------------------------------------------
function  dataangle = calcangle(xdata,ydata);
  
if nargin<2
  ydata = xdata(:,2);
  xdata = xdata(:,1);
end
mdata = [mean((xdata)) mean((ydata))];
dataangle = acos(mdata(1)./sqrt(sum(mdata.^2)));
if mdata(1,2)<0; dataangle = 2*pi-dataangle; end


