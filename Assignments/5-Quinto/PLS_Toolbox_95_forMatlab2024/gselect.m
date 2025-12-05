function [selected,y] = gselect(mode,command,options);
%GSELECT Selects objects in a figure (various selection styles).
%  INPUTS (all are optional):
%    mode  = a string governing how GSELECT operates:
%          'x' : select single x-axis position (snaps-to line x-data)
%          'y' : select single y-axis position (snaps-to line y-data)
%         'xs' : select range of x-axis positions (snaps-to line x-data)
%         'ys' : select range of y-axis positions (snaps-to line y-data)
%      'rbbox' : select points inside standard rubber-band box
%    'polygon' : select points inside polygon
%     'circle' : select points inside a circle
%    'ellipse' : select points inside an ellipse
%      'lasso' : select points inside a free-form shape
%      'paint' : drag a broad line across points for selection
%    'nearest' : select single nearest point
%   'nearests' : select multiple single (nearest) points
%        'all' : selects all points (no user interaction required)
%       'none' : selects no points (no user interaction required)
%    (with one output, 'rbbox' is default mode. With two outputs, 'polygon')
%    TargetHandle = specifies object to use to determine points and inclusion
%                   {default is all lines, patches, surfaces, and images}.
%                   If (TargetHandle) is empty, then selected will be the raw
%                   shape information of the selected item (e.g. the polygon or
%                   rbbox verticies or x/y positions).
%         options = optional options structure containing one or more of
%                    the following fields:
%
%                modal : [{'False'} | 'True' ] Governs window's "modal"
%                         nature. Note that some systems will not allow
%                         modal windows.
%              btndown : [{'False'} | 'True' ] Should button be considered
%                         "down" at start? 
%                 demo : [{'False'} | 'True' ] Is this a demo call to
%                         gselect? (do not wait to exit) 
%             poslabel : [ 'none' | 'insidexy' | {'xy'}] Governs what kind
%                         of axis position labels will be shown. 'none'
%                         shows no labels; 'xy' shows xy labels outside of
%                         axes; 'insidexy' shows labels inside axes.
%              helpbox : [ 'off' | {'on'} ]; Governs display of the helpbox
%          helptextpre : [''] Specifies text to prepend to helpbox message
%         helptextpost : [''] Specifies text to append to end of helpbox message
%             helptext : [''] Specifies alternate text to replace default
%                         helpbox message.
%
%    modalwindow  = optional flag which can be passed in place of "options"
%                   input. Controls window modal setting during the
%                   selection process (Keeps other windows from
%                   interrupting process) A value of 1 sets options.modal
%                   to 'true'.
%
%  OUTPUT:
%    selected = cell array which contains a cell for each target object on
%               the current axes. Each cell contains a logical map of all
%               included points, thus find(selected{x}) returns the indicies
%               which are selected for line object #x.
%         x,y = if two outputs are requested, the selected verticies will be
%               returned instead of the cell of maps.
%
% I/O: selected = gselect(mode,TargetHandle,options);
% I/O: [x,y]    = gselect(mode,TargetHandle,options);
% I/O: gselect demo
%
%See also: PLOTGUI

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

gsd = [];

if nargout < 2;
  verticies = 0;    %default, return selected points, not verticies
else
  verticies = 1;    %two outputs = return verticies
end;

if nargin<1 | isempty(mode);
  mode = 'rbbox';
end

mode = lower(mode);
if ismember(mode, evriio([],'validtopics'))
  options = [];
  options.modal   = 'False';    %should window be modal?
  options.btndown = 'False';  %should button be "down" to start?
  options.demo    = 'False';  %is this a demo call to gselect?
  options.poslabel  = 'xy';     %what kind of labels to show [ 'none' | 'insidexy' | {'xy'}]
  options.helpbox  = 'on';     %turn helpbox on or off
  options.helptext = '';       %text to REPLACE default text in helpbox
  options.helptextpre = '';       %text to prepend to helpbox
  options.helptextpost = '';       %text to append to helpbox
  if nargout==0; evriio(mfilename,mode,options); else; selected = evriio(mfilename,mode,options); end
  return;
  %error('Unrecognized selection mode')
end

if strcmp(mode,'testforfocus')
  %callback from timer to test if the expected figure still has focus
  testforfocus;
  return
end

fig = get(0,'currentfigure');
if isempty(fig);    %No current figure
  selected = cell(0);
  y        = cell(0);
  return            %return with nothing
end

brushwidth = getappdata(fig,'brushwidth');
if isempty(brushwidth);
  brushwidth = 8;   %default brush width
end;

if nargin>1;  %figure out what the extra inputs are
  if isempty(command);
    verticies = 1;                %return verticies, not selected
    command = '';
  else
    if ~isa(command,'char');      %non-char as command is a target handle
      if isa(command,'struct')
        options = command;
        command = '';
      elseif prod(size(command)) == 1 & command == 1;
        command = '';
        options = 1;
      elseif ~ishandle(command);
        error('Target Handle must be a valid handle or handles');
      else
        gsd.targethandle = command;
        command = '';
      end
    end
  end
else
  command = '';
end


%empty command = initialize
if isempty(command);
  
  if nargin<3 & ~exist('options','var');  %not passed OR set above?
    options = [];
  else
    if ~isa(options,'struct');
      if options
        options = [];
        options.modal = 'True';
      else
        options = [];
        options.modal = 'False';
      end
    end
  end

  options = reconopts(options,'gselect'); %NOTE: the only time we need to do this is here (options not used outside this IF)

  if ~ismember(mode,{'none','all'});      %jms change from strcmp to ismember

    zoom('off')                        %fix for R12.1
    rotate3d('off')                    %fix for R12.1
    plotedit(fig,'off')
    if checkmlversion('>','6.5');
      pan('off')                         %turn off pan
      datacursormode('off')              %turn off datacursor
    end
    
    oldgsd = getappdata(fig,'gselectdata');
    if ~isempty(oldgsd);
      %this function has an active gselect process on it
      %get old figure settings and delete any gselect objects
      gsd.fcns        = oldgsd.fcns;
      gsd.oldpntr     = oldgsd.oldpntr;
      gsd.windowstyle = oldgsd.windowstyle;
      gsd.axismode    = oldgsd.axismode;
      doresume(fig);
      delete(oldgsd.handle(ishandle(oldgsd.handle)));
    else
      %normal figure
      gsd.fcns = storefcns(fig);      %store old button functions
      gsd.oldpntr     = get(fig,'pointer');
      gsd.windowstyle = get(fig,'windowstyle');
      
      %Axis mode is getting lost and causing problems on plotgui axes
      %because of gca not being the correct axes so try using target here.
      %Not sure if targethandle will always be an axes so adding checks.
      if isfield(gsd,'targethandle') & ~isempty(gsd.targethandle) & length(gsd.targethandle)==1 & strcmp(get(gsd.targethandle,'type'),'axes')
        myax = gsd.targethandle;
      else
        myax = gca;
      end
      gsd.axismode    = get(myax,{'xlimmode','ylimmode','zlimmode'});
    end

    %add help frame
    gsd.helpwindow = cratehelpframe(fig,mode,options);drawnow;

    %set button/motion actions
    set(fig,'windowbuttondownfcn',['gselect(''' mode ''',''down'');']);  %and set our own
    set(fig,'windowbuttonmotionfcn',['gselect(''' mode ''',''motion'');']);
    set(fig,'windowbuttonupfcn',['gselect(''' mode ''',''up'');']);
    set(fig,'keypressfcn',['gselect(''' mode ''',''keypress'');']);

    if strcmpi(options.modal,'true');
      if checkmlversion('~=','7.0')
        %do NOT use modal windows on 14 - menus disappear
        %         set(fig,'windowstyle','modal');
      end
    end

    switch mode
      case 'paint';
        set(fig,'pointer','circle');
      case 'polygon'
        set(fig,'pointer','crosshair');
      case 'lasso'
        lasso_pointer(fig);
      otherwise
        set(fig,'pointer','crosshair');
    end;

    gsd.axis = get(fig,'currentaxes');
    gsd.posx = [];
    gsd.posy = [];
    gsd.handle = [];
    
    if isempty(findobj(gsd.axis,'type','image'))
      gsd.erasemode = 'xor';
      gsd.linewidth = 1;
    else
      gsd.erasemode = 'normal';
      gsd.linewidth = 2;
    end

    axis manual    %force axes to be fixed in scale

    setappdata(fig,'gselectdata',gsd);      %save now (may be used if we call "down" in a moment)

    if strcmpi(options.btndown,'true') | (~isempty(gcbf) & (gcbf == gcbo));          %calling from a figure's callback?
      gselect(mode,'down');     %then call button down immediately
    else
      gsd.handle = [];          %No? don't make marker object yet
      setappdata(fig,'gselectdata',gsd);
    end

    if strcmpi(options.demo,'true'); return; end

    %store options in figure
    setappdata(fig,'poslabel',options.poslabel);

    try
      %create test for "not current figure"
      create_focus_timer(fig);

      uiwait(fig);  %wait for "done" response
      
      %try stopping timer (not fatal error if we don't/can't)
      kill_focus_timer
      
    catch
      err = lasterr;
      cleanup(fig);
      error(err);
    end

    if ~ishandle(fig);      %figure gone?!?
      selected = cell(0);
      y        = cell(0);
      return            %return with nothing
    end

    gsd = getappdata(fig,'gselectdata');    %retrieve pos results
    cleanup(fig);

  else   %all or none initialize

    if ~isfield(gsd,'targethandle') | isempty(gsd.targethandle);
      gsd.targethandle = getvalidhandles;
    end;

  end

  if ~isfield(gsd,'targethandle')
    %error?!? probably called (and exited) another gselect while waiting
    selected = cell(0);
    y        = cell(0);
    return            %return with nothing
  end
  
  if isempty(gsd.targethandle);
    verticies = 1;                %return verticies, not selected
  end;

  %after initilize and uiresume, we fall through and do the "otherwise" mode for
  %whatever selection mode we've got...

end

try
  if ~isempty(command);  %command other than "initialize" (blank command)?

    gsd = getappdata(fig,'gselectdata');    %load appdata

    if strcmp(command,'down') & (~isfield(gsd,'axis') | isempty(gsd.axis));
      gsd.axis = gca;
      setappdata(fig,'gselectdata',gsd);    %save appdata
    else
      if isfield(gsd,'axis') & ~isempty(gsd.axis);
        set(fig,'currentaxes',gsd.axis);
        %axes(gsd.axis)      %reactivate correct axis
      end;
    end;

    if ~isfield(gsd,'targethandle') | isempty(gsd.targethandle);
      gsd.targethandle = getvalidhandles;
      if isempty(gsd.targethandle);
        gsd.targethandle = inf;
      end
      setappdata(fig,'gselectdata',gsd);    %save appdata
    end;

    if ~isfield(gsd,'handle');
      gsd.handle = [];
    end
    if ~isempty(gsd.handle) & ~ishandle(gsd.handle)
      gsd.handle = [];
    end

    if ~isfield(gsd,'fcns')
      cleanup(fig);
      return
    end

    %check if helpframe should be hidden
    
    if isfield(gsd,'helpwindow') && ~isempty(gsd.helpwindow)
      helpframe = gsd.helpwindow(1);
      if ishandle(helpframe)
        set(helpframe,'units','pixels');
        framepos = get(helpframe,'position');
        set(helpframe,'units','normalized');
        currentpoint = get(fig,'currentpoint');
        ctxmenu = get(helpframe,'uicontextmenu');
        if currentpoint(2)>framepos(2);          
          set(ctxmenu,'position',[currentpoint(1) framepos(2)+framepos(4)]);
          set(ctxmenu,'visible','on');
          starttime = getappdata(helpframe,'starttime');
          if isempty(starttime);
            setappdata(helpframe,'starttime',now);
          elseif (now-starttime)*60*60*24>1 | ~isempty(gsd.handle)
            try
              delete(getappdata(helpframe,'handles'));
            catch
            end
          end
        else
          set(ctxmenu,'visible','off');
          setappdata(helpframe,'starttime',now);
        end
      end
    end

  end
  %Change to current axis on first button down click. Selection hasn't been
  %started if (gsd.handle is empty).
  if strcmp(command,'down') && isempty(gsd.handle)
    
    allaxs = findobj(fig,'type','axes'); %All axes.
    auns = get(gca,'units'); %Use gca as orginal units.
    set(allaxs,'units','pixels');
    allpos = get(allaxs,'position'); %Get axes positions
    set(allaxs,'units',auns);%Set axes back to orginal units.
    
    if iscell(allpos)
      %Change cell to matrix
      allpos = cat(1,allpos{:});
    end 
    
    currentpoint = get(fig,'currentpoint');
    newaxs = allaxs(currentpoint(1)>=allpos(:,1) & currentpoint(1)<=allpos(:,1)+allpos(:,3) & currentpoint(2)>=allpos(:,2) & currentpoint(2)<=allpos(:,2)+allpos(:,4));
    if length(newaxs)==1 & newaxs ~=gsd.axis
      %IF there is one obvious axis they are on AND it is different from
      %what we FIRST thought...
      set(fig,'currentaxes',newaxs);  %force this to be the current axes
      gsd.axis = newaxs;      

      %dump targethandles not on this axes
      if ~any(isinf(double(gsd.targethandle)))
        userdata = get(gsd.targethandle,'userdata');
        parents = get(gsd.targethandle,'parent');
        if iscell(parents); parents = cat(1,parents{:}); end
        gsd.targethandle(parents~=newaxs) = [];

        %look for objects on new axes which match the userdata on the old axes
        if ~iscell(userdata); userdata = {userdata}; end
        newtargets  = allchild(gsd.axis);
        newuserdata = get(newtargets,'userdata');
        if ~iscell(newuserdata); newuserdata = {newuserdata}; end
        use = cellfun('isclass',newuserdata,'char');
        newtargets = newtargets(use);
        newuserdata = newuserdata(use);
        userdata = userdata(cellfun('isclass',userdata,'char'));
        gsd.targethandle = unique([gsd.targethandle(:);newtargets(ismember(newuserdata,userdata))]);
      end
      
      %if a plotgui figure, make sure controls reflect new axes
      if strcmpi(getappdata(fig,'figuretype'),'plotgui')
        plotgui('updatecontrols')
      end
      
    end
  end
  
  switch mode
    %- - - - - - - - - - - - - - - - - - -
    case 'none'  %do nothing, of course!
      if ~verticies;      %determine selected points
        selected = cell(0);
        gsd.targethandle(~ishandle(gsd.targethandle)) = [];   %delete placeholder for "no valid items"
        for h = gsd.targethandle(:)';
          switch get(h,'type')
            case 'image'
              selected{end+1} = uint8(zeros(size(sum(double(get(h,'cdata')),3))));
            case 'surface'
              selected{end+1} = uint8(zeros(size(sum(double(get(h,'zdata')),3))));
            otherwise
              selected{end+1} = uint8(zeros(size(get(h,'xdata'))));
          end
        end
      else
        selected = [];
        if nargout == 2;
          y = [];
        end;
      end;

      %- - - - - - - - - - - - - - - - - - -
    case {'all'}
      switch command
        case {'down','motion','up','keypress'}
          doresume(fig);
        otherwise
          if ~verticies;      %determine selected points
            %determine selected points
            selected = cell(0);
            gsd.targethandle(~ishandle(gsd.targethandle)) = [];   %delete placeholder for "no valid items"
            for h = gsd.targethandle(:)';
              switch get(h,'type')
                case 'image'
                  selected{end+1} = uint8(~isnan(sum(double(get(h,'cdata')),3)));
                case 'surface'
                  selected{end+1} = uint8(~isnan(sum(double(get(h,'zdata')),3)));
                otherwise
                  selected{end+1} = uint8(~isnan(get(h,'xdata')));
              end
            end

          else      %pass vertices only
            selected = [];
            if nargout == 2;
              y = [];
            end;
          end

      end

      %- - - - - - - - - - - - - - - - - - -
    case {'nearest','nearests'}
      switch command
        case 'down';
          pos = getcurrentpoint;
          [pos3d,snappos] = snaptoline(pos,mode,gsd.targethandle);
          gsd.posx(1) = snappos(1,1);
          gsd.posy(1) = snappos(1,2);

          if ishandle(gsd.handle);  %if line already exists, just change x and y data
            set(gsd.handle,'xdata',pos3d(:,1),'ydata',pos3d(:,2),'zdata',pos3d(:,3));
          else  %otherwise create a new object
            gsd.handle = line(pos3d(:,1),pos3d(:,2),pos3d(:,3));
          end
          set(gsd.handle,'linestyle','none',...
            'marker','o',...
            'EraseMode',gsd.erasemode,...
            'Markersize',10,...
            'color',[.8 0 0],...
            'markerfacecolor',[.8 .5 .5],...
            'tag','selectionmarker');
          setappdata(fig,'gselectdata',gsd);
        case 'motion';
          if ~isempty(gsd.handle);
            pos = getcurrentpoint;
            [pos3d,snappos] = snaptoline(pos,mode,gsd.targethandle);
            gsd.posx(1) = snappos(1,1);
            gsd.posy(1) = snappos(1,2);
            pos3d = trans3d({gsd.posx gsd.posy});  %dont use snaptoline output because we need ALL selected points' 3D positions
            set(gsd.handle,'xdata',pos3d(:,1),'ydata',pos3d(:,2),'zdata',pos3d(:,3));
            setappdata(fig,'gselectdata',gsd);
          end
          placelabels(fig,gsd,mode);

        case 'up';
          if strcmp(mode,'nearest');
            doresume(fig);
          else
            gsd.posx = [gsd.posx(1) gsd.posx];
            gsd.posy = [gsd.posy(1) gsd.posy];
            setappdata(fig,'gselectdata',gsd);
          end
        case 'keypress';
          if ~isempty(get(fig,'currentcharacter'));
            if get(fig,'currentcharacter') == 27;       %ESC
              delete(gsd.handle);                       % = delete line and return to main loop (abort)
              gsd.handle = [];
              setappdata(fig,'gselectdata',gsd);
            elseif strcmp(mode,'nearests');
              gsd.posx(1) = [];  %drop last point (point where person hit return) if multi-point mode
              gsd.posy(1) = [];
              setappdata(fig,'gselectdata',gsd);
            end
            doresume(fig);
          end

        otherwise

          if ~verticies;      %determine selected points
            selected = cell(0);
            if isfield(gsd,'handle') & ~isempty(gsd.handle);
              gsd.targethandle(~ishandle(gsd.targethandle)) = [];   %delete placeholder for "no valid items"
              for h = gsd.targethandle(:)';
                xdata = get(h,'xdata');
                ydata = get(h,'ydata');
                notnanmap = 1;
                switch get(h,'type')
                  case 'image'
                    if length(xdata)==2; xdata = xdata(1):xdata(2); end
                    if length(ydata)==2; ydata = ydata(1):ydata(2); end
                    [xdata,ydata] = meshgrid(xdata,ydata);
                    zdata = ydata*0;
                    notnanmap = uint8(~isnan(sum(double(get(h,'cdata')),3)));
                  case 'surface'
                    [xdata,ydata] = meshgrid(xdata,ydata);
                    zdata = ydata*0;
                    notnanmap = uint8(~isnan(sum(double(get(h,'zdata')),3)));
                  otherwise
                    zdata  = get(h,'zdata');
                end
                temptr = project2d({xdata ydata zdata});
                xdata = reshape(temptr(:,1),size(xdata));
                ydata = reshape(temptr(:,2),size(ydata));
                selectedmap = 0;
                for pnt = 1:length(gsd.posx);
                  posx = gsd.posx(pnt); posy = gsd.posy(pnt);
                  selectedmap = logical(uint8(round(myinpolygon(xdata,ydata,[posx posx posx posx posx],[posy posy posy posy posy])))) & notnanmap | selectedmap;
                end
                selected{end+1} = selectedmap;
                %selected{end+1} = logical(uint8(round(myinpolygon(xdata,ydata,[gsd.posx gsd.posx gsd.posx gsd.posx gsd.posx],[gsd.posy gsd.posy gsd.posy gsd.posy gsd.posy])))) & notnanmap;
              end
            else                %no line = aborted
              selected = cell(1,length(gsd.targethandle));    %indicate no selected entries for any line object
            end
          else      %pass vertices only
            if isfield(gsd,'handle') & ~isempty(gsd.handle);
              selected = trans3d({gsd.posx gsd.posy});
              if nargout == 2;
                y = selected(:,2);
                selected = selected(:,1);
              end;
            else
              selected = [];
              if nargout == 2;
                y = [];
              end
            end
          end

      end

      %- - - - - - - - - - - - - - - - - - -
    case {'x', 'y'}
      switch command
        case {'down' 'motion'};
          if strcmp(command,'down') | ~isempty(gsd.handle);
            pos = getcurrentpoint;
            [pos3d,pos] = snaptoline(pos,mode,gsd.targethandle);
            scale = trans3d([1 1]);
            ax = axis;
            if strcmp(mode,'x');
              gsd.posx = pos(1,1)*[1 1 1 1 1];
              gsd.posy = [0 1 1 0 0];
              if length(ax)>4;
                pos3d = pos3d([1 1 1 1 1],:);
                pos3d(:,2:3) = [ax([3 4 4 3 3])' ax([5 5 6 6 5])'];
              else
                pos3d = pos3d([1 1],:);
                pos3d(:,2) = ax(3:4)';
              end
            else %mode is 'y'
              gsd.posx = [0 1 1 0 0];
              gsd.posy = pos(1,2)*[1 1 1 1 1];
              if length(ax)>4;
                pos3d = pos3d([1 1 1 1 1],:);
                pos3d(:,[1 3]) = [ax([1 2 2 1 1])' ax([5 5 6 6 5])'];
              else
                pos3d = pos3d([1 1],:);
                pos3d(:,1) = ax(1:2)';
              end
            end
            if ~isempty(gsd.handle);
              set(gsd.handle,'xdata',pos3d(:,1),'ydata',pos3d(:,2),'zdata',pos3d(:,3));
            else
              if scale(3)>0;
                gsd.handle = patch(pos3d(:,1),pos3d(:,2),pos3d(:,3),'r');
                set(gsd.handle,'linestyle',':',...
                  'EraseMode',gsd.erasemode,...
                  'linewidth',gsd.linewidth,...
                  'tag','selectionmarker',...
                  'facecolor',[1 .8 .8],...
                  'edgecolor',[.8 0 0]);
              else
                gsd.handle = line(pos3d(:,1),pos3d(:,2),pos3d(:,3));
                set(gsd.handle,'linestyle',':',...
                  'EraseMode',gsd.erasemode,...
                  'linewidth',gsd.linewidth,...
                  'color',[.8 0 0],...
                  'tag','selectionmarker');
              end
            end
            setappdata(fig,'gselectdata',gsd);
          end
          placelabels(fig,gsd,mode);

        case 'up';
          doresume(fig);
        case 'keypress';
          if ~isempty(get(fig,'currentcharacter'));
            if get(fig,'currentcharacter') == 27;       %ESC
              delete(gsd.handle);                       % = delete line and return to main loop (abort)
              gsd.handle = [];
              setappdata(fig,'gselectdata',gsd);
            end
            doresume(fig);
          end

        otherwise

          if ~verticies;      %determine selected points
            selected = cell(0);
            if ~isempty(gsd.handle);
              gsd.targethandle(~ishandle(gsd.targethandle)) = [];   %delete placeholder for "no valid items"
              for h = gsd.targethandle(:)';
                xdata = get(h,'xdata');
                ydata = get(h,'ydata');
                notnanmap = 1;
                switch get(h,'type')
                  case 'image'
                    if length(xdata)==2; xdata = xdata(1):xdata(2); end
                    if length(ydata)==2; ydata = ydata(1):ydata(2); end
                    [xdata,ydata] = meshgrid(xdata,ydata);
                    zdata = ydata*0;
                    notnanmap = uint8(~isnan(sum(double(get(h,'cdata')),3)));
                  case 'surface'
                    [xdata,ydata] = meshgrid(xdata,ydata);
                    zdata = ydata*0;
                    notnanmap = uint8(~isnan(sum(double(get(h,'zdata')),3)));
                  otherwise
                    zdata  = get(h,'zdata');
                end
                temptr = project2d({xdata ydata zdata});
                xdata = reshape(temptr(:,1),size(xdata));
                ydata = reshape(temptr(:,2),size(ydata));
                selected{end+1} = logical(uint8(round(myinpolygon(xdata,ydata,gsd.posx,gsd.posy)))) & notnanmap;
              end
            else                %no line = aborted
              selected = cell(1,length(gsd.targethandle));    %indicate no selected entries for any line object
            end
          else      %pass vertices only
            if isfield(gsd,'handle') & ~isempty(gsd.handle);
              pos3d = trans3d({gsd.posx gsd.posy});
              switch mode
                case 'x'
                  selected = pos3d(1);
                  if nargout == 2;
                    y = [];
                  end;
                case 'y'
                  selected = pos3d(1,2);
                  if nargout == 2;
                    y = selected;
                    selected = [];
                  end;
              end
            else
              selected = [];
              if nargout == 2;
                y = [];
              end
            end

          end

      end


      %- - - - - - - - - - - - - - - - - - -
    case {'rbbox', 'xs', 'ys' 'zs'}  %ZS NOT FULLY SUPPORTED
      switch command
        case 'down';
          if isempty(gsd.handle);
            pos = getcurrentpoint;
            ax = axis;
            if length(ax) == 4; ax=[ax 0 0]; end     %flat for 2D plots
            gsd.posx = [pos(1) pos(1) pos(1) pos(1) pos(1)];
            gsd.posy = [pos(2) pos(2) pos(2) pos(2) pos(2)];
            pos3d = trans3d({gsd.posx gsd.posy});
            switch mode
              case 'xs'
                pos3d(:,2) = ax([3 3 4 4 3])';
                pos3d(:,3) = ax([5 5 5 5 5])';
              case 'ys';
                pos3d(:,1) = ax([1 1 2 2 1])';
                pos3d(:,3) = ax([5 5 5 5 5])';
              case 'zs'
                pos3d(:,1) = ax([1 1 2 2 1])';
                pos3d(:,2) = ax([3 3 4 4 3])';
            end
            switch mode
              case {'xs','ys','zs'}
                gsd.handle = patch(pos3d(:,1),pos3d(:,2),pos3d(:,3),'r');
                set(gsd.handle,'linestyle',':',...
                  'EraseMode',gsd.erasemode,...
                  'linewidth',gsd.linewidth,...
                  'tag','selectionmarker',...
                  'facecolor',[1 .8 .8],...
                  'edgecolor',[.8 0 0]);
                uistack(gsd.handle,'bottom');  %use uistack because of facecolor setting
              case 'rbbox';
                gsd.handle = line(pos3d(:,1),pos3d(:,2),pos3d(:,3));
                set(gsd.handle,'linestyle',':',...
                  'linewidth',gsd.linewidth,...
                  'EraseMode',gsd.erasemode,...
                  'tag','selectionmarker',...
                  'color',[.8 0 0]);
            end
            gsd.valid = 0;   %not yet valid
            setappdata(fig,'gselectdata',gsd);
          end
        case 'motion';
          if ~isempty(gsd.handle);
            pos = getcurrentpoint;
            ax = axis;
            if length(ax) == 4; ax=[ax 0 0]; end     %flat for 2D plots
            switch mode
              case 'xs'
                gsd.posx = [gsd.posx(1) pos(1) pos(1) gsd.posx(1) gsd.posx(1)];
                gsd.posy = [gsd.posy(1) pos(2) pos(2) gsd.posy(1) gsd.posy(1)];
                pos3d = trans3d({gsd.posx gsd.posy});
                pos3d(:,2) = ax([3 3 4 4 3])';
                pos3d(:,3) = ax(5)*[1 1 1 1 1]';
              case 'ys';
                gsd.posy = [gsd.posy(1) pos(2) pos(2) gsd.posy(1) gsd.posy(1)];
                gsd.posx = [gsd.posx(1) pos(1) pos(1) gsd.posx(1) gsd.posx(1)];
                pos3d = trans3d({gsd.posx gsd.posy});
                pos3d(:,1) = ax([1 1 2 2 1])';
                pos3d(:,3) = ax(5)*[1 1 1 1 1]';
              case 'zs'; %ZS NOT FULLY SUPPORTED
                gsd.posy = [gsd.posy(1) pos(2) pos(2) gsd.posy(1) gsd.posy(1)];
                gsd.posx = [gsd.posx(1) pos(1) pos(1) gsd.posx(1) gsd.posx(1)];
                pos3d = trans3d({gsd.posx gsd.posy});
                pos3d(:,1) = ax([1 1 2 2 1])';
                pos3d(:,2) = ax(4)*[1 1 1 1 1]';
              case 'rbbox';
                gsd.posx = [gsd.posx(1) gsd.posx(1) pos(1) pos(1) gsd.posx(1)];
                gsd.posy = [gsd.posy(1) pos(2) pos(2) gsd.posy(1) gsd.posy(1)];
                pos3d = trans3d({gsd.posx gsd.posy});
            end
            gsd.valid = 1;  %NOW we're valid
            set(gsd.handle,'xdata',pos3d(:,1)','ydata',pos3d(:,2)','zdata',pos3d(:,3)');
            setappdata(fig,'gselectdata',gsd);
          end
          switch mode
            case {'xs' 'ys' 'zs'}
              placelabels(fig,gsd,mode(1));
            otherwise
              placelabels(fig,gsd);
          end

        case 'up';
          doresume(fig);

        case 'keypress';
          if ~isempty(get(fig,'currentcharacter'));      %something other than a special key?
            if get(fig,'currentcharacter') == 27;       %ESC?
              delete(gsd.handle);                       % = delete line and return to main loop (abort)
              gsd.handle = [];
              setappdata(fig,'gselectdata',gsd);
            end
            doresume(fig);                                   %otherwise, just say we're done
          end

        otherwise
          if ~verticies;      %determine selected points
            %determine selected points
            selected = cell(0);
            if isfield(gsd,'handle') & ~isempty(gsd.handle) & gsd.valid;
              gsd.targethandle(~ishandle(gsd.targethandle)) = [];   %delete placeholder for "no valid items"
              for h = gsd.targethandle(:)';
                xdata = get(h,'xdata');
                ydata = get(h,'ydata');
                notnanmap = 1;
                switch get(h,'type')
                  case 'image'
                    if length(xdata)==2; xdata = xdata(1):xdata(2); end
                    if length(ydata)==2; ydata = ydata(1):ydata(2); end
                    [xdata,ydata] = meshgrid(xdata,ydata);
                    zdata = ydata*0;
                    notnanmap = uint8(~isnan(sum(double(get(h,'cdata')),3)));
                  case 'surface'
                    [xdata,ydata] = meshgrid(xdata,ydata);
                    zdata = ydata*0;
                    notnanmap = uint8(~isnan(sum(double(get(h,'zdata')),3)));
                  otherwise
                    zdata  = get(h,'zdata');
                end
                switch mode
                  case 'xs'
                    pos3d = trans3d({gsd.posx gsd.posy});
                    selected{end+1} = logical(uint8(round(myinpolygon(xdata,ydata*0,pos3d(:,1),pos3d(:,2)*0)))) & notnanmap;
                  case 'ys'
                    pos3d = trans3d({gsd.posx gsd.posy});
                    selected{end+1} = logical(uint8(round(myinpolygon(xdata*0,ydata,pos3d(:,1)*0,pos3d(:,2))))) & notnanmap;
                  case 'zs'
                    pos3d = trans3d({gsd.posx gsd.posy});
                    selected{end+1} = logical(uint8(round(myinpolygon(xdata*0,zdata,pos3d(:,1)*0,pos3d(:,3))))) & notnanmap;
                  otherwise
                    temptr = project2d({xdata ydata zdata});
                    xdata = reshape(temptr(:,1),size(xdata));
                    ydata = reshape(temptr(:,2),size(ydata));
                    selected{end+1} = logical(uint8(round(myinpolygon(xdata,ydata,gsd.posx,gsd.posy)))) & notnanmap;
                end
              end
            else                %no line = aborted
              selected = cell(1,length(gsd.targethandle));    %indicate no selected entries for any line object
            end
          else      %pass vertices only
            if isfield(gsd,'handle') & ~isempty(gsd.handle) & gsd.valid;
              pos3d = trans3d({gsd.posx gsd.posy});
              selected = pos3d(:,1:2);  %no 3rd dim unless zs mode
              if strcmp(mode,'zs')
                selected = pos3d(:,3);
              end
              if nargout == 2;
                y = selected(:,2);
                selected = selected(:,1);
              end;
            else
              selected = [];
              if nargout == 2;
                y = [];
              end
            end
          end

      end

      %- - - - - - - - - - - - - - - - - - -
    case {'circle' 'ellipse'}
      switch command
        case 'down';
          
          pos = getcurrentpoint;
          gsd.posx(end+1) = pos(1);
          gsd.posy(end+1) = pos(2);

          setappdata(fig,'gselectdata',gsd);

        case 'motion';
          if ~isempty(gsd.posx);
            pos = getcurrentpoint;
            ax = axis;
            if ishandle(gsd.handle); delete(gsd.handle); end

            gsd.handle = drawellipse(ax,gsd,pos);
            
            set(gsd.handle,'linestyle','--',...
              'EraseMode','normal',...
              'linewidth',gsd.linewidth,...
              'tag','selectionmarker',...
              'color',[.8 0 0]);
            setappdata(fig,'gselectdata',gsd);
            placelabels(fig,gsd);
          end

        case 'up';
          switch mode
            case 'circle'
              if length(gsd.posx)==2; doresume(fig); end
            case 'ellipse'
              if length(gsd.posx)==3; doresume(fig); end
          end

        case 'keypress';
          if ~isempty(get(fig,'currentcharacter'));      %something other than a special key?
            if get(fig,'currentcharacter') == 27;       %ESC?
              delete(gsd.handle);                       % = delete line and return to main loop (abort)
              gsd.handle = [];
              setappdata(fig,'gselectdata',gsd);
            end
            doresume(fig);                                   %otherwise, just say we're done
          end

        otherwise

          %draw ellipse (to get x and y of circle)
          if isfield(gsd,'handle') & ~isempty(gsd.handle);
            %(Note: have to redraw ellipse because main code deletes
            %drawing object on uiresume (before we get here))
            gsd.handle = drawellipse(axis,gsd);
            posx = get(gsd.handle,'xdata');
            posy = get(gsd.handle,'ydata');
            posz = get(gsd.handle,'zdata');
            delete(gsd.handle);  %delete object
          end
          
          if ~verticies;      %determine selected points
            %determine selected points
            selected = cell(0);
            if isfield(gsd,'handle') & ~isempty(gsd.handle);
              gsd.targethandle(~ishandle(gsd.targethandle)) = [];   %delete placeholder for "no valid items"
              for h = gsd.targethandle(:)';
                xdata = get(h,'xdata');
                ydata = get(h,'ydata');
                notnanmap = 1;
                switch get(h,'type')
                  case 'image'
                    if length(xdata)==2; xdata = xdata(1):xdata(2); end
                    if length(ydata)==2; ydata = ydata(1):ydata(2); end
                    [xdata,ydata] = meshgrid(xdata,ydata);
                    zdata = ydata*0;
                    notnanmap = uint8(~isnan(sum(double(get(h,'cdata')),3)));
                  case 'surface'
                    [xdata,ydata] = meshgrid(xdata,ydata);
                    zdata = ydata*0;
                    notnanmap = uint8(~isnan(sum(double(get(h,'zdata')),3)));
                  otherwise
                    zdata  = get(h,'zdata');
                end
                temptr = project2d({xdata ydata zdata});
                xdata = reshape(temptr(:,1),size(xdata));
                ydata = reshape(temptr(:,2),size(ydata));
                elltr  = project2d({posx posy posz});
                selected{end+1} = logical(uint8(round(myinpolygon(xdata,ydata,elltr(:,1)',elltr(:,2)')))) & notnanmap;
              end
            else                %no line = aborted
              selected = cell(1,length(gsd.targethandle));    %indicate no selected entries for any line object
            end
          else      %pass vertices only
            if isfield(gsd,'handle') & ~isempty(gsd.handle);
              selected = [posx(:) posy(:) posz(:)];
              if nargout == 2;
                y = selected(:,2);
                selected = selected(:,1);
              end;
            else
              selected = [];
              if nargout == 2;
                y = [];
              end
            end
          end

      end


      %- - - - - - - - - - - - - - - - - - -
    case {'polygon','paint','lasso'}
      switch command
        case 'down';
          pos = getcurrentpoint;
          if ~isfield(gsd,'posx');  gsd.posx = []; gsd.posy = []; end
          gsd.posx(end+1) = pos(1);
          gsd.posy(end+1) = pos(2);
          pos3d = trans3d({gsd.posx gsd.posy});
          if ~isfield(gsd,'handle') | isempty(gsd.handle);
            gsd.handle = line(pos3d(:,1),pos3d(:,2),pos3d(:,3));
            switch mode
              case 'polygon';
                set(gsd.handle,'linestyle','-',...
                  'linewidth',2,...
                  'marker','o',...
                  'markersize',2,...
                  'EraseMode',gsd.erasemode,...
                  'tag','selectionmarker',...
                  'color',[.8 0 0]);
              case 'paint'
                set(gsd.handle,'linestyle','-',...
                  'linewidth',brushwidth,...
                  'EraseMode',gsd.erasemode,...
                  'tag','selectionmarker',...
                  'color',[.8 0 0]);
              case 'lasso'
                set(gsd.handle,'linestyle','-',...
                  'EraseMode',gsd.erasemode,...
                  'linewidth',gsd.linewidth,...
                  'tag','selectionmarker',...
                  'color',[.8 0 0]);
            end
          else
            set(gsd.handle,'xdata',pos3d(:,1),'ydata',pos3d(:,2),'zdata',pos3d(:,3));
            if strcmp(mode,'paint');
              doresume(fig);
            end
          end
          setappdata(fig,'gselectdata',gsd);
        case 'motion';
          switch mode
            case 'lasso'
              if ~isempty(gsd.handle);
                pos = getcurrentpoint;
                gsd.posx = [gsd.posx pos(1)];
                gsd.posy = [gsd.posy pos(2)];
                pos3d = trans3d({gsd.posx gsd.posy});
                set(gsd.handle,'xdata',pos3d(:,1),'ydata',pos3d(:,2),'zdata',pos3d(:,3));
                setappdata(fig,'gselectdata',gsd);
              end
            otherwise
              if ~isempty(gsd.handle);
                pos = getcurrentpoint;
                posx = [gsd.posx pos(1)];
                posy = [gsd.posy pos(2)];
                pos3d = trans3d({posx posy});
                set(gsd.handle,'xdata',pos3d(:,1),'ydata',pos3d(:,2),'zdata',pos3d(:,3));
              end
          end
          placelabels(fig,gsd);

        case 'up';
          if length(gsd.posx)>1;
            if strcmp(mode,'lasso') | (abs(gsd.posx(end)-gsd.posx(1))<.01 ...
                & abs(gsd.posy(end)-gsd.posy(1))<.01);        %<1% difference between first and last point?
              gsd.posx(end) = gsd.posx(1);
              gsd.posy(end) = gsd.posy(1);
              setappdata(fig,'gselectdata',gsd);
              doresume(fig);
            end
          elseif length(gsd.posx)==1;   %only one point but dragged in paint mode?
            if strcmp(mode,'paint');
              pos = getcurrentpoint;
              if pos(1) ~= gsd.posx(1) | (length(gsd.posx)>1 & pos(2) ~= gsd.posx(2));
                gsd.posx(end+1) = pos(1);
                gsd.posy(end+1) = pos(2);
                setappdata(fig,'gselectdata',gsd);
                doresume(fig);
              end
            end
          end
        case 'keypress';
          if ~isempty(get(fig,'currentcharacter'));
            if get(fig,'currentcharacter') == 27 | ~isfield(gsd,'posx') | length(gsd.posx) < 3;       %ESC
              if isfield(gsd,'handle') & ishandle(gsd.handle);
                delete(gsd.handle);                       % = delete line and return to main loop (abort)
              end
              gsd.handle = [];
              setappdata(fig,'gselectdata',gsd);
            else
              gselect(mode,'down');     %act like this was a button press
              posx = [gsd.posx gsd.posx(1)];      %and flash up the closed polygon
              posy = [gsd.posy gsd.posy(1)];
              set(gsd.handle,'xdata',posx,'ydata',posy);
              pause(.1);          %just long enough to show it
            end
            doresume(fig);
          end

        otherwise

          if ~verticies;      %determine selected points
            selected = cell(0);
            if ~isempty(gsd.handle);

              if strcmp(mode,'paint');
                x1 = gsd.posx(1);
                y1 = gsd.posy(1);
                x2 = gsd.posx(2);
                y2 = gsd.posy(2);

                Dx = (x2 - x1);
                Dy = (y2 - y1);

                units = get(gca,'units');
                set(gca,'units','pixels');
                axpos = get(gca,'position');    %get axis size in pixels
                set(gca,'units',units);

                adj = .7;
                xscaling = brushwidth / axpos(3) * adj;
                yscaling = brushwidth / axpos(4) * adj;

                gx = Dx / sqrt(Dx^2 + Dy^2) * yscaling;
                gy = Dy / sqrt(Dx^2 + Dy^2) * xscaling;

                gsd.posx = [x1-gy x1+gy x2+gy x2-gy x1-gy];
                gsd.posy = [y1+gx y1-gx y2-gx y2+gx y1+gx];
              elseif strcmp(mode,'lasso');

                %locate and remove nearly duplicate points
                use = 1:length(gsd.posx);
                dat = [gsd.posx(:) gsd.posy(:)];

                what = 0;
                where = [];

                %drop points which are too close together to be
                %significantly different (x% of full scale)
                while what<.02;  % = percent of full scale threshold
                  use(where) = [];
                  grad = diff(diff([dat(use,1) dat(use,2)]));
                  [what,where] = min(sum(abs(grad),2));
                  where = where+1;
                end

                %Identify straight-line segments
                ddat  = diff(dat(use,:));
                anglediff = acos(ddat(1:end-1,1)./(sqrt(sum(ddat(1:end-1,:).^2,2))+eps)) - acos(ddat(2:end,1)./(sqrt(sum(ddat(2:end,:).^2,2))+eps));
                where = find(abs(anglediff)<.1)+1;
                where(where==1) = [];
                where(where==length(use)) = [];
                use(where)=[];

                gsd.posx = gsd.posx(use);
                gsd.posy = gsd.posy(use);

              end;

              gsd.targethandle(~ishandle(gsd.targethandle)) = [];   %delete placeholder for "no valid items"
              for h = gsd.targethandle(:)';
                xdata = get(h,'xdata');
                ydata = get(h,'ydata');
                notnanmap = 1;
                switch get(h,'type')
                  case 'image'
                    if length(xdata)==2; xdata = xdata(1):xdata(2); end
                    if length(ydata)==2; ydata = ydata(1):ydata(2); end
                    [xdata,ydata] = meshgrid(xdata,ydata);
                    zdata = ydata*0;
                    notnanmap = uint8(~isnan(sum(double(get(h,'cdata')),3)));
                  case 'surface'
                    [xdata,ydata] = meshgrid(xdata,ydata);
                    zdata = ydata*0;
                    notnanmap = uint8(~isnan(sum(double(get(h,'zdata')),3)));
                  otherwise
                    zdata  = get(h,'zdata');
                end
                temptr = project2d({xdata ydata zdata});
                xdata = reshape(temptr(:,1),size(xdata));
                ydata = reshape(temptr(:,2),size(ydata));
                selected{end+1} = logical(uint8(round(myinpolygon(xdata,ydata,gsd.posx,gsd.posy)))) & notnanmap;
              end
            else                %no line = aborted
              selected = cell(1,length(gsd.targethandle));    %indicate no selected entries for any line object
            end
          else      %pass vertices only
            if isfield(gsd,'handle') & ~isempty(gsd.handle);
              selected = trans3d({gsd.posx gsd.posy});
              if nargout == 2;
                y = selected(:,2);
                selected = selected(:,1);
              end;
            else
              selected = [];
              if nargout == 2;
                y = [];
              end
            end
          end

      end

      %- - - - - - - - - - - - - - - - - - -
    otherwise
      error(['selection mode ''' mode ''' undefined']);
  end

catch

  err = lasterror;
  cleanup(fig);
  rethrow(err)

end


%--------------------------------
function fcns = storefcns(fig);

fcns.bd = get(fig,'windowbuttondownfcn');
fcns.bm = get(fig,'windowbuttonmotionfcn');
fcns.bu = get(fig,'windowbuttonupfcn');
fcns.kp = get(fig,'keypressfcn');

a = findall(gcf);
fcns.obj.handles       = findall(gcf);

for cycle=1:2
  try
    hasprop = isprop(fcns.obj.handles,'uicontextmenu');
    fcns.obj.uicontextmenu = repmat({[]},1,length(hasprop));
    fcns.obj.uicontextmenu(hasprop) = get(fcns.obj.handles(hasprop),'uicontextmenu');
    break;  %don't try a second time if this worked
  catch
    %There seems to be latency in handles being destoyed on Mac 2014b but it
    %can't be caught using ishandle so use try catch and try to recover.
    %THIS CODE DID NOT WORK:
    % a = findall(gcf);
    % b = double(a);
    % c = ishandle(a);
    % if any(~c)
    %   %'c' never shows bad handle.
    %   d = get(b(~c));
    % end
    
    pause(.1);
    fcns.obj.handles = findall(gcf);
  end
end

hasprop = isprop(fcns.obj.handles,'buttondownfcn');
fcns.obj.buttondownfcn = repmat({[]},1,length(hasprop));
fcns.obj.buttondownfcn(hasprop) = get(fcns.obj.handles(hasprop),'buttondownfcn');

discard = cellfun('isempty',fcns.obj.uicontextmenu) & cellfun('isempty',fcns.obj.buttondownfcn);
fcns.obj.uicontextmenu(discard) = [];
fcns.obj.buttondownfcn(discard) = [];
fcns.obj.handles(discard) = [];

%disable everything we just saved
set(fig,'windowbuttondownfcn','')
set(fig,'windowbuttonmotionfcn','');
set(fig,'windowbuttonupfcn','');
set(fig,'keypressfcn','');
set(fcns.obj.handles,'uicontextmenu','')
set(fcns.obj.handles,'buttondownfcn','')

%--------------------------------
function restorefcns(fig,fcns);

set(fig,'windowbuttondownfcn',fcns.bd);
set(fig,'windowbuttonmotionfcn',fcns.bm);
set(fig,'windowbuttonupfcn',fcns.bu);
set(fig,'keypressfcn',fcns.kp);
try
  valid = ishandle(fcns.obj.handles);
  valid(valid) = isprop(fcns.obj.handles(valid),'uicontextmenu');
  set(fcns.obj.handles(valid),{'uicontextmenu'},fcns.obj.uicontextmenu(valid)')
catch
  disp('GSELECT: Error restoring uicontextmenu, skipping')  
end
try
  valid = ishandle(fcns.obj.handles);
  valid(valid) = isprop(fcns.obj.handles(valid),'buttondownfcn');
  set(fcns.obj.handles(valid),{'buttondownfcn'},fcns.obj.buttondownfcn(valid)')
catch
  disp('GSELECT: Error restoring buttondownfcn, skipping')  
end

%--------------------------------
function pos = putinrange(pos);
%PUTINRANGE - makes certain pos is inside axes limits

ax = axis;
is3d = length(ax) == 6;

pos(pos(:,1) < ax(1),1) = ax(1);
pos(pos(:,1) > ax(2),1) = ax(2);
pos(pos(:,2) < ax(3),2) = ax(3);
pos(pos(:,2) > ax(4),2) = ax(4);
if is3d;
  %3D plot
  pos(pos(:,3) < ax(5),3) = ax(5);
  pos(pos(:,3) > ax(6),3) = ax(6);
end     

%--------------------------------
function selectin = selectinaxes(pos);
%SELECTINAXES - determine which axes we are looking at

ax = axis;
if length(ax) == 4; ax=[ax 0 0]; end     %flat for 2D plots

selectin = ones(1,3);
[what,where] = max(std(pos./[ax(2:2:end)-ax(1:2:end);ax(2:2:end)-ax(1:2:end)]));
selectin(where) = 0;
%don't select about axis which has the biggest difference in front and back plane position
if sum(selectin)<2; selectin = [1 1 0]; end


%--------------------------------
function [npos,npostr] = snaptoline(pos,xory,handle)
%SNAPTOLINE locates the x or y axis point with actual data closest to the input position
%  USAGE: [npos,npostr] = snaptoline(position,'x or y',handle)
%    position is the axis position to snap to the current line objects
%    'x or y' is a character indicating which axis to look at, 'x' or 'y'
%    handle is the handle or handles of the line objects to snap to (default: all on axis)
%    NPOS is the new snapped-to value in original x,y,z units and NPOSTR is
%    the value in transformed 2D units (view_x,view_y).

if nargin < 3;
  handle = [findobj(gca,'type','line')' findobj(gca,'type','surface')' ...
    findobj(gca,'type','patch')' findobj(gca,'type','image')'];
end

handle = setdiff(handle,findobj(gca,'tag','selectionmarker'));   %don't use selection marker
handle(~isfinite(double(handle))) = [];  %drop Inf and NaN

if isempty(handle); npos = pos; npostr = pos; return ; end          %no lines? return original value

data = [];
for h = handle(:)';
  tempx = get(h,'xdata');
  tempy = get(h,'ydata');
  switch get(h,'type')
    case 'image'
      if length(tempx)==2; tempx = tempx(1):tempx(2); end
      if length(tempy)==2; tempy = tempy(1):tempy(2); end
      [tempx,tempy] = meshgrid(tempx,tempy);
      notnanmap = (~isnan(sum(double(get(h,'cdata')),3)));
      thisdata = [tempx(:)./(notnanmap(:)+eps) tempy(:)./(notnanmap(:)+eps)]*(1+eps);
      thisdata(:,3) = 0;
    case 'surface'
      [tempx,tempy] = meshgrid(tempx,tempy);
      notnanmap = (~isnan(sum(double(get(h,'zdata')),3)));
      thisdata = [tempx(:)./(notnanmap(:)+eps) tempy(:)./(notnanmap(:)+eps)]*(1+eps);
      thisdata(:,3) = 0;
    otherwise
      tempz = get(h,'zdata');
      if isempty(tempz)
        tempz = tempy*0;
      end
      thisdata = [tempx(:) tempy(:) tempz(:)];
  end
  data = [data;thisdata];
end

trdata = project2d(data);
switch xory
  case {'nearest' 'nearests'};
    dist = sqrt((trdata(:,1)-pos(1)).^2 + (trdata(:,2)-pos(2)).^2);
  case 'x'
    dist = abs(trdata(:,1)-pos(1));
  case 'y'
    dist = abs(trdata(:,2)-pos(2));
  case 'z'
    pos3d = trans3d(pos(1:2));
    dist = abs(data(:,3)-pos3d(3));
end
where = find(dist == min(dist));
npos   = data(where,:);
npostr = trdata(where,:);

%-----------------------------------------------------
function result = myinpolygon(xdata,ydata,polyx,polyy);
% pre-limited inpolygon wrapper function
% (drops obviously excluded points before calling inpolygon

p = getptr(gcf);
setptr(gcf,'watch');      %set pointer shape to "wait"

result = zeros(size(xdata));    %create holding variable for results

whichx = find(xdata>=min(polyx) & xdata<=max(polyx));
xdata = xdata(whichx);
ydata = ydata(whichx);      %extract only x points of interest

whichy = find(ydata>=min(polyy) & ydata<=max(polyy));
xdata = xdata(whichy);
ydata = ydata(whichy);      %extract only y points of interest

if all(polyx==polyx(1)) & all(polyy==polyy(1))
  %if polygon is a single point, do this as a special test (because
  %inpolygon will give warning in this scenario)
  subresult = (xdata==polyx(1) & ydata==polyy(1));
elseif all(polyy==polyy(1))
  subresult = (xdata>=min(polyx) & xdata<=max(polyx));
elseif all(polyx==polyx(1))
  subresult = (ydata>=min(polyy) & ydata<=max(polyy));  
else
  subresult = inpolygon(xdata,ydata,polyx,polyy);     %do search
end

result(whichx(whichy)) = subresult;       %reinsert subresults

set(gcf,p{:})       %restore pointer shape


%-----------------------------------------------------
function targethandle = getvalidhandles
%locate valid target handles on current axes

targethandle = [findobj(gca,'type','line')' findobj(gca,'type','surface')' ...
  findobj(gca,'type','patch')' findobj(gca,'type','image')'];

if ~isempty(targethandle);
  targethandle(find(~(strcmp('line',get(targethandle,'type')) ...
    | strcmp('patch',get(targethandle,'type')) ...
    | strcmp('surface',get(targethandle,'type')) ...
    | strcmp('image',get(targethandle,'type'))))) = [];      %remove non-valid types
end

%-----------------------------------------------------
function pout = project2d(p)
%wrapper function for trans3d
pout = trans3d(p,1);

function pout = trans3d(p,project)
%calculate and apply transformation matrix to give 2D projection position
%(or 3D estimated position) from the current axes azimuth and elevation
% input "project" indicates:
%    1 : convert 3D -> 2D
%    0 : convert 2D -> 3D

if nargin<2;
  project = 0;  %default is 2D -> 3D (back-map to 3D)
end

if iscell(p)
  %cell input? vectorize and concatenate as columns
  for j=1:length(p);
    temp = p{j}(:);
    if isempty(temp);
      temp = [];
    end
    p{j} = temp;
  end
  p = cat(2,p{:});
end

%check if we're in 2D plot
ax = axis;
is2d = (length(ax)==4);
if is2d; ax = [ax 0 1]; end

%apply transform matrix in expected direction (forward or inverse)
if project;
  %project: [x y z] becomes [xv yv]
  if size(p,2)<3;
    %make sure there are three indices (all zero for 3rd if not there)
    p(:,3) = 0;
  end
  p = (p-ones(size(p,1),1)*ax(1:2:6))./(ones(size(p,1),1)*(ax(2:2:6)-ax(1:2:6)));
  pout = p*xmtx;
else
  %back-map: [xv yv] becomes [x y z]
  pout = p*xmtx';
  
  %check for out-of-limits projection (everything here is normalized axis units)
  omtx = oxmtx;
  for bad = find(any(pout>1,2)')
    [what,where] = max(pout(bad,:));
    if ~is2d & omtx(where)~=0
      pout(bad,:) = pout(bad,:)+((1-what)./omtx(where))*omtx';
    else
      pout(bad,where) = 1;
    end
  end
  for bad = find(any(pout<0,2)')
    [what,where] = max(-pout(bad,:));
    if ~is2d & omtx(where)~=0
      pout(bad,:) = pout(bad,:)+(what./omtx(where))*omtx';
    else
      pout(bad,where) = 0;
    end
  end
  pout = pout.*(ones(size(p,1),1)*(ax(2:2:6)-ax(1:2:6)))+ones(size(p,1),1)*ax(1:2:6);
  pout = putinrange(pout);

end

if size(pout,2)==3
  %If we have a "z" coordinate and we're looking down on in z direction
  %then place the at max so it can be seen. Otherwise selection is drawn
  %underneath rendered surfaces. If you're looking at plot from different
  %angle then all bets are off.
  [AZ,EL] = view;
  if EL==90;
    %Out includes z value.
    myz = zlim;
    pout(:,3) = max(zlim);
  end
  
end
  
%-----------------------------------------------------
function out = xmtx;
%formulate transform matrix based on view

[az,el] = view;
out = [
  cos(az*pi/180)                    sin(az*pi/180)                0;
  -1*sin(el*pi/180)*sin(az*pi/180)  sin(el*pi/180)*cos(az*pi/180) cos(el*pi/180)
  ]';

%-----------------------------------------------------
function out = oxmtx
%formulate orthogonal transform matrix (direction you can move WITHOUT
%changing projection

t = xmtx;
out = eye(3)-t*t';
[u,s] = svd(out);
out = u(:,1);

%-----------------------------------------------------
function pos = getcurrentpoint

pos = get(gca,'currentpoint');
pos = pos(1,:);
% pos = putinrange(pos);
pos = project2d(pos);
pos(:,3) = 0;

%-----------------------------------------------------
function cleanup(fig);
% TRY to clean up figure functions and pointers when done
%  (is also called after errors so this is really secure!)

kill_focus_timer  %contains try/catch to avoid errors

try
  if ishandle(fig);
    if isappdata(fig,'gselectdata');
      gsd = getappdata(fig,'gselectdata');
      rmappdata(fig,'gselectdata');
      if isfield(gsd,'handle') & ishandle(gsd.handle);
        delete(gsd.handle);
      end
      if isfield(gsd,'oldpntr');
        set(fig,'pointer',gsd.oldpntr);
      else
        set(fig,'pointer','arrow');
      end
      if isfield(gsd,'fcns');
        restorefcns(fig,gsd.fcns);
      else
        set(fig,'windowbuttondownfcn','')
        set(fig,'windowbuttonmotionfcn','');
        set(fig,'windowbuttonupfcn','');
        set(fig,'keypressfcn','');
      end
      if isfield(gsd,'windowstyle');
        set(fig,'windowstyle',gsd.windowstyle);
        drawnow;
      else
        set(fig,'windowstyle','normal');
        drawnow;
      end
      if isfield(gsd,'helpwindow');
        delete(gsd.helpwindow(ishandle(gsd.helpwindow)));
      end
      if isfield(gsd,'axismode');
        set(gca,{'xlimmode','ylimmode','zlimmode'},gsd.axismode);
      end    
    end

    %remove axismarkers
    hs = getappdata(fig,'axismarkers');
    hs(~ishandle(hs)) = [];
    if ~isempty(hs);
      delete(hs);
    end
    setappdata(fig,'axismarkers',[]);
    
  end

catch
  disp(encode(lasterror));
  disp('GSELECT - could not clean up figure. Error details above. Please send to helpdesk@eigenvector.com');
  if ishandle(fig);
    if isappdata(fig,'gselectdata');
      rmappdata(fig,'gselectdata');
    end
    set(fig,'windowstyle','normal');
    set(fig,'pointer','arrow');
    set(fig,'windowbuttondownfcn','')
    set(fig,'windowbuttonmotionfcn','');
    set(fig,'windowbuttonupfcn','');
    set(fig,'keypressfcn','');
    axis auto
  end
end


%-----------------------------------------------------
function doresume(fig);
% attempt to do a uiresume but first test if we've already done one and it
% failed... in which case, clean up first (we are probably no longer being
% watched)

gsd = getappdata(fig,'gselectdata');
if isfield(gsd,'uiresuming');
  cleanup(fig);
else
  gsd.uiresuming = 1;
  setappdata(fig,'gselectdata',gsd);
end
uiresume;
kill_focus_timer

%-------------------------------------------
function lasso_pointer(fig)

cdat = [ NaN NaN NaN NaN NaN NaN  2   2   2   2   2   2   2 NaN NaN NaN;
  NaN NaN NaN NaN  2   2   1   1   1   1   1   1   1   2   2 NaN;
  NaN NaN NaN  2   1   1   1   2   2   2   2   2   1   1   1   2;
  NaN NaN  2   1   1   2   2 NaN NaN NaN NaN NaN   2   2   1   2;
  NaN NaN  2   1   2 NaN NaN NaN NaN NaN NaN NaN NaN   2   1   2;
  NaN NaN  2   1   2 NaN NaN NaN NaN NaN NaN NaN NaN   2   1   2;
  NaN NaN  2   1   2 NaN NaN NaN NaN NaN NaN NaN NaN   2   1   2;
  NaN NaN  2   1   2 NaN NaN NaN   2 NaN NaN NaN   2   1   1   2;
  NaN NaN  2   1   1   2 NaN   2   1   2 NaN NaN   2   1   1   2;
  NaN NaN  2   1   1   2 NaN   2   1   2   2   2   2   1   2 NaN;
  NaN NaN NaN  2   1   1   2   2   2   1   2   1   1   1   2 NaN;
  NaN NaN NaN NaN  2   1   1   2   1   1   1   1   2   2 NaN NaN;
  NaN NaN NaN  2   2   2   1   1   1   2   1   2 NaN NaN NaN NaN;
  NaN  2   2   1   1   1   1   1   2   2   1   2 NaN NaN NaN NaN;
  2    1   1   1   2   2   2   2   1   1   2 NaN NaN NaN NaN NaN;
  NaN  2   2   2 NaN NaN NaN NaN   2   2 NaN NaN NaN NaN NaN NaN ];

set(fig,'pointer','custom','pointershapeCdata',cdat,'pointershapehotSpot',[16 1])

%---------------------------------------
function h = drawellipse(ax,gsd,pos)

if nargin>2;
  gsd.posx = [gsd.posx pos(1)];
  gsd.posy = [gsd.posy pos(2)];
end

x = gsd.posx;
y = gsd.posy;

%get axes size in pixels
units = get(gsd.axis,'units');
set(gsd.axis,'units','pixels');
pos = get(gsd.axis,'position');
set(gsd.axis,'units',units);

if length(pos)==4;
  r = pos([4 3]);
  r = (r./max(r));
else
  r = [ 1 1 ];
end

cnt = [x(1) y(1)];
ax = axis;
switch length(x)
  case 1
      d = [0.,0.];
      ang = 0;
  case 2
    %circle
    d = r*sqrt(sum(((cnt-[x(2) y(2)])./r).^2));
    ang = 0;

  otherwise
    %ellipse
    ang = atan(((y(3)-cnt(2)))/(eps+(x(3)-cnt(1))));
    adj = cos(ang)*(r(2)-r(1));
    d = [sqrt(sum(((cnt-[x(3) y(3)])./r).^2))*(r(2)-adj) sqrt(sum(((cnt-[x(2) y(2)])./r).^2))*(r(1)+adj)];
    
    
end

h = ellps(cnt,d,'r:',ang);
axis(ax)

%translate ellipse into 3D
pos3d = trans3d({get(h,'xdata') get(h,'ydata')});
set(h,'xdata',pos3d(:,1),'ydata',pos3d(:,2),'zdata',pos3d(:,3)); 

%------------------------------------------
function placelabels(fig,gsd,mode)

poslabel = getappdata(fig,'poslabel');

if strcmp(poslabel,'none')
  return
end

if nargin<2;
  gsd = [];
end
if nargin<3;
  mode = 'nearest';
end

if isfield(gsd,'axis') & ~isempty(gsd.axis);
  axh = gsd.axis;
  set(fig,'currentaxes',axh);
else
  axh = get(fig,'currentaxes');
end

hs = getappdata(fig,'axismarkers');

%if they switched axes on us, delete the old markers
if ~isempty(hs) && ishandle(hs(1)) && get(hs(1),'parent')~=axh;
  delete(hs);
  hs = [];
end

%get current axes
ax = axis;
mpos = get(axh,'currentpoint');
x = mpos(1,1);
y = mpos(1,2);

bgc = min(get(fig,'color')+0.1,1);

%if we've got GSD, snap to data
% if ~isempty(gsd) & ~isempty(gsd.handle);
%   temp = snaptoline(getcurrentpoint,mode,gsd.targethandle);
%   x = temp(1,1);
%   y = temp(1,2);
% end

x = max(ax(1),min(ax(2),x));
y = max(ax(3),min(ax(4),y));

%X-axis label
pos = [x ax(3) 0];
if isempty(hs) | ~ishandle(hs(1));
  h   = text(pos(1),pos(2),num2str(x));
  if checkmlversion('>','6.1'); set(h,'backgroundColor',bgc); end
else
  h = hs(1);
end
ext = get(h,'extent');
if strcmp(poslabel,'insidexy')
  if abs(y-ax(3))<abs(ax(4)-y)
    %if closer to bottom, put label on top (but inside)
    pos(2) = ax(4);
  else
    %bump label up a bit to be inside
    pos = pos + [0 ext(4) 0];
  end
end
pos = pos + [-ext(3)/2 -ext(4)/2 0];
set(h,'string',num2str(x),'position',pos)
hs(1) = h;

%Y-axis label
pos = [ax(1) y 0];
if length(hs)<2 | ~ishandle(hs(2));
  h = text(pos(1),pos(2),num2str(y));
  set(h,'horizontalalignment','right')
  if checkmlversion('>','6.1'); set(h,'backgroundColor',bgc); end
else
  h = hs(2);
end
if strcmp(poslabel,'insidexy')
  if abs(x-ax(1))<abs(ax(2)-x)
    %if closer to left side, put label on right
    pos(1) = ax(2);
  else
    pos = pos + [ext(3)*1.25 0 0];
  end
end
pos = pos + [0 0 0];
set(h,'string',num2str(y),'position',pos);
hs(2) = h;

setappdata(fig,'axismarkers',hs)

%-----------------------------------------------------------
function handles = cratehelpframe(fig,mode,options);

h = [findobj(fig,'tag','gselecthelpframe') findobj(fig,'tag','gselecthelpframetext')];
delete(h);

if strcmp(options.helpbox,'on');
  %create help frame and put appropriate text into box
  
  ctxmenu = findobj(fig,'tag','gselecthelpcontext');
  if ~isempty(ctxmenu)
    delete(ctxmenu);
  end
  ctxmenu = uicontextmenu('tag','gselecthelpcontext');
  uimenu(ctxmenu,'label','Hide Selection Help','callback','try;delete(getappdata(findobj(gcbf,''uicontextmenu'',get(gcbo,''parent'')),''handles''));catch; end;');
  uimenu(ctxmenu,'label','Never Show Selection Help','separator','on','callback','setplspref(''gselect'',''helpbox'',''off'');try;delete(getappdata(findobj(gcbf,''uicontextmenu'',get(gcbo,''parent'')),''handles''));catch; end;');
  
  pos = get(fig,'position');
  if checkmlversion('>=','7.7') & strcmp(get(fig,'toolbar'),'auto')
    %Matlab 2008b hides figure toolbar when adding uicontrol to figure where toolbar is auto
    set(fig,'toolbar','figure');
  end
  h = uicontrol(fig,'tag','gselecthelpframe','visible','off','style','frame','units','pixels',...
    'position',[1 pos(4)-1 pos(3)-1 1],'backgroundcolor',[1 1 1],'uicontextmenu',ctxmenu);
  ht = uicontrol(fig,'visible','off','style','text','units','pixels','position',[4 pos(4)-4 pos(3)-8 2],'backgroundcolor',[1 1 1],...
    'fontsize',10,'horizontalalignment','left','tag','gselecthelpframetext');
  set(ht,'string',helpstring(mode,options)); drawnow;
  fpos = get(h,'position');
  tpos = get(ht,'position');
  text = get(ht,'extent');
  fheight = (ceil(text(3)/tpos(3))*text(4))+4;
  theight = (ceil(text(3)/tpos(3))*text(4));
  set(h,'position', [fpos(1) pos(4)-1-fheight fpos(3) fheight])
  set(ht,'position',[tpos(1) pos(4)-3-theight tpos(3) theight])
  set([h ht],'units','normalized','visible','on')
  handles = [h ht ctxmenu];
  setappdata(h,'handles',handles);
  setappdata(ht,'handles',handles);
else
  %no help frame
  handles = [];
end

%-----------------------------------------------------------
function str = helpstring(mode,options)

if ~isempty(options.helptext);
  str = options.helptext;
else
  switch mode
    case 'rbbox' 
      str = 'Click and drag to draw selection box. Abort by pressing [Esc].';
    case 'xs'
      str = 'Click and drag to select x-range. Abort by pressing [Esc].';
    case 'ys'
      str = 'Click and drag to select y-range. Abort by pressing [Esc].';
    case 'x'
      str = 'Click to select a single x-axis point. Abort by pressing [Esc].';
    case 'y'
      str = 'Click to select a single y-axis point. Abort by pressing [Esc].';
    case 'nearest'
      str = 'Click to select a single point. Abort by pressing [Esc].';
    case 'nearests'
      str = 'Click on each point to select. Finish by pressing [Enter]. Abort by pressing [Esc].';
    case 'lasso'
      str = 'Click and drag to draw selection lasso. Abort by pressing [Esc].';
    case 'polygon'
      str = 'Click to mark corners of a selection polygon. Finish by re-selecting the first point or by pressing [Enter]. Abort by pressing [Esc].';
    case 'paint'
      str = 'Click and drag to "paint" selection. Abort by pressing [Esc].';
    case 'ellipse'
      str = 'Click to mark selection ellipse center, again to mark minor axes, then again to mark major axes. Abort by pressing [Esc].';
    case 'circle'
      str = 'Click to mark selection circle center then click again to mark outer edge. Abort by pressing [Esc].';
    otherwise
      str = 'Click to make selection. Abort by pressing [Esc].';
  end
end
if ~isempty(options.helptextpre) && options.helptextpre(end)~=' ';
  options.helptextpre = [options.helptextpre ' '];
end
str = [options.helptextpre str ' ' options.helptextpost];

%-------------------------------------------------------------
function t = create_focus_timer(fig)
%create timer to watch for change of focus

t = timerfind('tag','gselect_timer');
if isempty(t);
  t = timer;
end
t.TimerFcn = 'gselect(''testforfocus'')';
t.ExecutionMode = 'fixedSpacing';
t.Period = .2;
t.userdata = fig;
t.tag = 'gselect_timer';
start(t);

function testforfocus
%callback from timer to test if the expected figure still has focus

fig = get(0,'currentfigure');
t   = timerfind('tag','gselect_timer');
if ~isempty(t) & t.userdata~=fig
  %gselect figure is no longer current figure? - stop gselect as if we escaped
  if ishandle(t.userdata)
    uiresume(t.userdata);
  end
  stop(t);
end

function kill_focus_timer
%delete existing focus timer
try
  t = timerfind('tag','gselect_timer');
  if ~isempty(t)
    stop(t)
    delete(t)
  end
catch
end
