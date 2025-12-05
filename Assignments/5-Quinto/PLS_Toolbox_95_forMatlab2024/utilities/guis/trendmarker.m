function varargout = trendmarker(action,varargin)
%TRENDMARKER Manages marker objects for trendtool.
% Helper function used by TRENDTOOL.
%
%I/O: trendmarker(command)
%
%See also: TRENDTOOL, TRENDAPPLY, TRENDLINK, TRENDWATERFALL

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%     'toggle', 'on', 'off', 'update'
% 'MarkerChangeFcn' : appdata which will be executed on changes to markers

if nargin==0;
  if ~isempty(gcbo)
    action = 'move';
  else
    action = 'toggle';
  end
end
action = lower(action);

switch action
  %- - - - - - - - - - - - - - - - - - - - - - - -
  case {'toggle','on','off'}
    
    if nargin<2;
      varargin = {gca};
    end
    h = varargin{1};
    
    if strcmp(get(h,'type'),'figure')
      h = get(h,'currentaxes');
    end
    fig = get(h,'parent');
    
    mycontext = get(h,'uicontextmenu');
    if isempty(mycontext) & ~strcmp(action,'off');
      
      %create context menu
      mycontext = findobj(fig,'tag','markeraxismenu');
      if isempty(mycontext);
        set(0,'currentfigure',fig);
        mycontext = uicontextmenu('tag','markeraxismenu');
      end
      set(h,'uicontextmenu',mycontext);
      delete(allchild(mycontext));  %remove previous menu entries
      uimenu(mycontext,'label','Add Marker','callback','trendmarker(''add'',gca)');
      uimenu(mycontext,'label','Delete All Markers','callback','trendmarker(''delete'',''all'')');
      
    elseif ~isempty(mycontext) & ~strcmp(action,'on');
      set(h,'uicontextmenu','');  %turn off uicontext for axes
      dat = getmarkerdata(fig);   %delete any marker lines
      if isfield(dat,'handles');
        delete(dat.handles);
      end
      putmarkerdata(fig,[]);
      
    end
    
    setpgcallback(fig,action);
    
    %- - - - - - - - - - - - - - - - - - - - - - - -
  case 'update'
    if nargin<2;
      varargin = {gca};
    end
    ax = varargin{1};

    if strcmp(get(ax,'type'),'figure')
      ax = get(ax,'currentaxes');
    end
    
    if ~strcmp(get(ax,'type'),'axes')
      error('Handle must be to a current axes object');
    end
    
    fig = get(ax,'parent');
    set(0,'currentfigure',fig);
   
    setpgcallback(fig);

    remove = [];
    dat    = getmarkerdata(fig);
    cind   = 0;
    color  = zeros(1,length(dat.handles));
    for i = 1:length(dat.handles)
      
      %Is this object linked to a missing object?
      link = dat.data(i).link;
      if any(~ishandle(link))  %is that linked object gone?
        remove = i;            %then remove this object too
        if ishandle(dat.handles(i));
          delete(dat.handles(i));
        end
        continue
      end
      
      %Determine color for object
      if ~isempty(dat.data(i).link);
        master   = min(find(dat.handles==dat.data(i).link));   %linked object = color of master
        color(i) = color(master);
      end
      if color(i)==0
        cind = cind + 1;      %otherwise, next color index
        color(i) = cind;
      end
      
      %do the actual draw of the object
      masterind = dat.handles==findmaster(dat,dat.handles(i));
      h = drawmarker(fig,dat.data(i).x,color(i),dat.data(i).mode,dat.data(masterind).normalize);
      if ishandle(dat.handles(i));
        delete(dat.handles(i));
      end
      
      %update link field of others which link to this object
      for j = findlinked(dat,dat.handles(i));
        link = dat.data(j).link;
        link(link==dat.handles(i)) = h;
        dat.data(j).link = link;
      end
      
      dat.handles(i) = h;
    end
    
    dat.handles(remove) = [];
    dat.data(remove) = [];
    
    dat.cindex = cind;
    putmarkerdata(fig,dat);
    peakfindgui('update',fig);
    
    if checkmlversion('>','7.2')
      set(zoom,'ActionPostCallback',@zoomupdate);
      set(pan,'ActionPostCallback',@zoomupdate);
    end

    
    %- - - - - - - - - - - - - - - - - - - - - - - -
  case 'add'
    
    addmarker
    trendmarker('update');
    docallback(gtf);
    
    %- - - - - - - - - - - - - - - - - - - - - - - -
  case 'autoadd'
    
    if nargin<2;
      fig = gtf;
    else
      fig = gtf(varargin{1});
    end
    dat = getmarkerdata(fig);
    set(0,'currentfigure',fig);
    ax = axis;
    startpos = mean(ax(1:2));
    newpos = startpos;
    if ~isempty(dat.data)
      limit = abs(ax(2)-ax(1))/25;
      offset = 1;
      while any(abs([dat.data.x]-newpos)<limit)
        newpos = startpos + limit*offset;
        if newpos>max(ax(1:2));
          limit = limit/2;
          offset = 1;
        end
        if any(abs([dat.data.x]-newpos)<limit)
          newpos = startpos-limit*offset;
        end
        offset = offset+1;
      end
    end
    addmarker(fig,newpos)
    trendmarker('update');
    docallback(gtf);
    
    %- - - - - - - - - - - - - - - - - - - - - - - -
  case 'edit'
    
    evritip('edittrendmarker','Right-click on any marker to edit its type or drag/drop to move a marker.',0);
    
  case 'delete'
    
    deletemarker(varargin{1})
    trendmarker('update')
    docallback(gtf);
    
    %- - - - - - - - - - - - - - - - - - - - - - - -
  case 'move'
    
    h = gcbo;
    fig = gtf;
    switch get(fig,'selectiontype')
      
      case 'alt'
        % call of uicontextmenu done by matlab
        
      otherwise
        setappdata(gcbo,'buttonmotionfcn','trendmarker(''inmotion'',h,parent,newpos);')
        moveobj
        setappdata(h,'buttonupfcn','uiresume(gcbf);')
        uiwait(fig);
        
        %update position of moved object
        dat = getmarkerdata(fig);
        mypos = find(dat.handles==h);
        if isempty(mypos);
          dat.handles = [dat.handles h];
          mypos       = length(dat.handles);
        end
        
        if ~ishandle(h); return; end
        xdata = get(h,'xdata');
        dat.data(mypos).x = xdata(1);
        
        %update marker data and the spectrum plot
        putmarkerdata(fig,dat);
        trendmarker('update')
        docallback(fig);
    end
    
  case 'inmotion'
    h = varargin{1};
    fig = varargin{2};
    newpos = varargin{3};
    dat = getmarkerdata(fig);
    mypos = find(dat.handles==h);
    
    if isempty(mypos) | ~strcmp(dat.data(mypos).mode,'h')
      return
    end
    
    %update position of moved object
    xdata = newpos([1 1]);
    cur_dso = getobjdata(fig);
    
    if ~isempty(cur_dso)
      %keep marker on-screen
      xax = cur_dso.axisscale{2};
      if isempty(xax)
        xax = 1:size(cur_dso,2);
      end
      xdata = max(min(xdata,max(xax)),min(xax));
      set(h, 'xdata', xdata);
      
      %show data of current marker position in target figure
      TrendLinkData = getappdata(fig,'TrendLinkData');
      slice = cur_dso(:,findindx(xax,xdata(1)));
      set(0,'currentfigure',TrendLinkData.target);
      switch slice.type
        case 'data'
          ax = cur_dso.axisscale{1};
          if isempty(ax)
            ax = 1:size(cur_dso,1);
          end
          h = plot(ax,slice.data);
          lineprops = getappdata(TrendLinkData.target,'lineprops');
          lineinfo  = getappdata(TrendLinkData.target,'lineinfo');
          if ~isempty(lineinfo) & ~isempty(lineprops)
            set(h,lineprops,lineinfo(1,:))
          end
          
        case 'image'
          im = slice.imagedata;
          im = im.*NaN;
          im(slice.include{1}) = slice.imagedata(slice.include{1});
          if ndims(im)>2
            im = unfoldmw(im,1);
          end
          imagesc(im);
          axis tight fill ij image off
          
      end
    end
    set(0,'currentfigure',fig);
    %- - - - - - - - - - - - - - - - - - - - - - - -
  otherwise
    
    if nargout == 0;
      feval(action,varargin{:});
    else
      [varargout{1:nargout}] = feval(action,varargin{:});
    end
    
end

%-----------------------------------------------
function dat = getmarkerdata(fig)

dat = getappdata(fig,'markerdata');
if ~isfield(dat,'handles');
  dat.handles = [];
  dat.data = [];
end
if ~isfield(dat,'cindex') | isempty(dat.cindex)
  dat.cindex = 0;
end

%-----------------------------------------------
function putmarkerdata(fig,dat)

if ~isempty(dat);
  for j=1:length(dat.handles);
    if isempty(dat.data(j).mode)
      dat.data(j).mode = 'h';
    end
  end
end
setappdata(fig,'markerdata',dat);


%-----------------------------------------------
%locate indicies into handles which are linked to this object
function hlinks = findlinked(dat,h)

hlinks = [];
for ind = 1:length(dat.handles);
  if ismember(h,dat.data(ind).link)
    hlinks = [hlinks ind];
  end
end


%-----------------------------------------------
%locate indicies into handles which are reference objects to this object
function hlinks = findref(dat,h)

hlinks = findlinked(dat,findmaster(dat,h));
modes  = [dat.data(hlinks).mode];
hlinks = hlinks(modes=='b' | modes=='o');


%-----------------------------------------------
%locate HANDLE of master to this object (might be object itself)
function master = findmaster(dat,h)

ind = find(dat.handles==h);
if ~isempty(ind);
  if ~isempty(dat.data(ind).link);
    master = dat.data(ind).link;      %look at master object for reference links
  else
    master = h;
  end
else
  master = h;
end

%-----------------------------------------------
%locate the partner of this object (area or baseline objects)
function hlinks = findmate(dat,h)

ind = find(dat.handles==h);

master = findmaster(dat,h);  %start at master
hlinks = [find(dat.handles==master) findlinked(dat,master)];       %find all linked to it
modes  = [dat.data(hlinks).mode];               %look at the modes of those objects
hlinks = hlinks(modes==dat.data(ind).mode);    %find others like me
hlinks = setdiff(hlinks,ind);                  %but don't count me


%-----------------------------------------------
function addmarker(fig,poses,mode,link)

if nargin<1 | isempty(fig); 
  fig = gtf;   
else
  fig = gtf(fig);
end
if nargin<2 | isempty(poses);
  pos = get(get(fig,'CurrentAxes'),'CurrentPoint');
  poses = pos(1);
end
if nargin<3 | isempty(mode);  mode = 'h'; end
if nargin<4 | isempty(link);  link = [];  end

mydata = getobjdata(fig);
if isempty(mydata);
  evrierrordlg('Data must be loaded before markers can be set');
  return;
end

dat = getmarkerdata(fig);
for pos = poses;
  mypos = length(dat.handles)+1;
  
  dat.data(mypos).x    = pos;
  dat.data(mypos).mode = mode;
  dat.data(mypos).link = link;
  dat.data(mypos).normalize = 0;
  
  if isempty(link);
    dat.cindex = dat.cindex+1;
  end
  h = nan;
  dat.handles(mypos)   = h;
end

putmarkerdata(fig,dat);

%-----------------------------------------------
function deletemarker(h,fig)

if nargin<2;
  fig = gtf;
else
  fig = gtf(fig);
end

dat = getmarkerdata(fig);

if strcmp(h,'all');
  h = dat.handles;
  if isempty(h); return; end
  ok = evriquestdlg('Erase all markers?','Erase Markers','Erase','Cancel','Erase');
  if ~strcmpi(ok,'Erase'); return; end
end

todelete = [];
for ind = 1:length(h);
  
  todelete = dat.handles(findlinked(dat,h(ind)));  %note to remove objects which link to this object
  
  dat = getmarkerdata(fig);
  mypos = find(dat.handles==h(ind));
  if ~isempty(mypos);
    if ~isempty(dat.data(mypos).link);      %this is a slave...
      mate = findmate(dat,h(ind));
      if ~isempty(mate);                             % does it's mate still exist?
        todelete = [todelete dat.handles(mate)];     %   delete it too
      end
    end
    dat.handles(mypos) = [];
    dat.data(mypos)    = [];
  end
  if ishandle(h(ind));
    delete(h(ind));
  end
  putmarkerdata(fig,dat);
  
end

if ~isempty(todelete);
  deletemarker(todelete,fig);
end

%-----------------------------------------------
function h = drawmarker(fig,pos,ind,mode,normalize)

if nargin<5 | isempty(normalize)
  normalize = 0;
end

colors = get(0,'defaultaxescolororder');

if isempty(mode);
  mode = 'h';
end

switch mode
  case 'o'
    linestyle = ':';
  case 'b'
    linestyle = '--';
  otherwise
    if ~normalize
      linestyle = 'v-';
    else
      linestyle = 's-';
    end
end

h   = vline(pos,linestyle);
set(h,'buttondownfcn','trendmarker',...
  'linewidth',2,...
  'color',colors(mod(ind-1,size(colors,1))+1,:))
setappdata(h,'MOVEOBJ_mode','x');

%create context menu
mycontext = findobj(fig,'tag','markermenu');
if isempty(mycontext);
  mycontext = uicontextmenu('tag','markermenu','callback','trendmarker(''markermenu'',gco);');
  delete(allchild(mycontext));  %remove previous menu entries
  uimenu(mycontext,'label','Height','tag','styleheight','callback','trendmarker(''markermenu'',gco);');
  uimenu(mycontext,'label','Area','tag','stylearea','callback','trendmarker(''markermenu'',gco);');
  uimenu(mycontext,'label','Position','tag','styleposition','callback','trendmarker(''markermenu'',gco);');
  uimenu(mycontext,'label','Width','tag','stylewidth','callback','trendmarker(''markermenu'',gco);');
  uimenu(mycontext,'label','Maximum','tag','stylemax','callback','trendmarker(''markermenu'',gco);');
  uimenu(mycontext,'label','Baseline','tag','stylebaseline','callback','trendmarker(''markermenu'',gco);');
  uimenu(mycontext,'label','Normalize to Region','tag','normalize','callback','trendmarker(''markermenu'',gco);');
  uimenu(mycontext,'label','Add Reference','tag','addreference','callback','trendmarker(''markermenu'',gco);');
  uimenu(mycontext,'label','Delete Region','tag','deletemarker','callback','trendmarker(''markermenu'',gco);');
end

set(h,'uicontextmenu',mycontext);

%----------------------------------------------
function markermenu(varargin)

action = get(gcbo,'tag');
fig = gtf;
handles = guihandles(fig);
h = double(get(fig,'currentobject'));

dat = getmarkerdata(fig);
ind = find(dat.handles==h);
if isempty(ind); return; end

oldmode = dat.data(ind).mode;
switch action
  case {'stylearea' 'styleposition' 'stylewidth' 'stylemax'}
    switch action
      case 'stylearea'
        newmode = 'a';
      case 'styleposition'
        newmode = 'p';
      case 'stylewidth'
        newmode = 'w';
      case 'stylemax'
        newmode = 'm';
    end
    if ~strcmp(oldmode,newmode)
      switch oldmode
        case 'h';
          %from height to area
          %add mate
          pos = dat.data(ind).x;
          ax = axis;
          ax = [ax(1:2) mean(ax(1:2))];
          posmate = pos + (ax(2)-ax(1))*.05.*sign(ax(3)-pos);
          pos     = pos - (ax(2)-ax(1))*.05.*sign(ax(3)-pos);
          %now test if either pos or posmate is outside of the data range
          %and adjust both accordingly
          cur_dso = getobjdata(fig);
          if isempty(cur_dso.axisscale{2})
            x_lims = [1 size(cur_dso, 2)];
          else
            x_lims = [cur_dso.axisscale{2}(1) cur_dso.axisscale{2}(end)];
          end
          x_lims = sort(x_lims);
          x_range = x_lims(2) - x_lims(1);
          pos_vec = [pos posmate];
          
          tom = [~issorted([x_lims(1) pos_vec(1) x_lims(2)]);...
            ~issorted([x_lims(1) pos_vec(2) x_lims(2)])];
          if any(tom)
            %can't think of a way that both would be off the data scale,
            %check which one is outside of the range
            ind = find(tom);
            closest_lim = x_lims(findindx(x_lims, pos_vec(ind)));
            delta = closest_lim - pos_vec(ind) + ...
              .05*sign(closest_lim - pos_vec(ind))*x_range;
            pos = pos + delta;
            posmate = posmate + delta;
          end
          
          %change to area
          dat.data(ind).mode = newmode;
          dat.data(ind).x = pos;
          putmarkerdata(fig,dat)
          addmarker(fig,posmate,newmode,h);
        case {'p' 'w' 'a' 'm'}
          %from mode with mate already
          mate = findmate(dat,h);
          dat.data(mate).mode = newmode;
          dat.data(ind).mode = newmode;
          putmarkerdata(fig,dat)
      end
      
      trendmarker('update');
      docallback(fig);
    end
    
  case 'stylebaseline'
    if ~strcmp(oldmode,'b')
      dat.data(ind).mode = 'b';
      putmarkerdata(fig,dat)
      
      pos = dat.data(ind).x;
      ax = axis;
      ax = [ax(1:2) mean(ax(1:2))];
      pos = pos + (ax(2)-ax(1))*.05.*sign(ax(3)-pos);
      
      addmarker(fig,pos,'b',dat.data(ind).link);
      trendmarker('update');
      docallback(fig);
    end
    
  case 'styleheight'
    if strcmp(oldmode,'b')     %baseline -> height
      mate = findmate(dat,h);
      dat.data(ind).mode = 'o';
      putmarkerdata(fig,dat)
      deletemarker(dat.handles(mate),fig);
      trendmarker('update');
      docallback(fig);
    elseif ismember(oldmode,{'a' 'w' 'p' 'm'})     %area or position -> height
      master = findmaster(dat,h);
      ind    = find(dat.handles==master);
      mate   = findmate(dat,findmaster(dat,h));
      dat.data(ind).x = mean([dat.data([ind mate]).x]);
      dat.data(ind).mode = 'h';
      putmarkerdata(fig,dat)
      deletemarker(dat.handles(mate),fig);
      trendmarker('update');
      docallback(fig);
    end
    
  case 'normalize'
    masterind = dat.handles==findmaster(dat,h);
    if dat.data(masterind).normalize
      dat.data(masterind).normalize = 0;
    else
      for j=1:length(dat.data);
        dat.data(j).normalize = 0;
      end
      dat.data(masterind).normalize = 1;
    end
    putmarkerdata(fig,dat)
    trendmarker('update');
    docallback(fig);
    
  case 'deletemarker'
    deletemarker(h,fig);
    trendmarker('update');
    docallback(fig);
    
  case 'addreference'
    if isempty(findref(dat,h))
      
      pos = dat.data(ind).x;
      ax = axis;
      ax = [ax(1:2) mean(ax(1:2))];
      pos = pos + (ax(2)-ax(1))*.05.*sign(ax(3)-pos);
      
      addmarker(fig,pos,'o',findmaster(dat,h));
      trendmarker('update');
      docallback(fig);
    end
    
  case 'markermenu'
    mode = dat.data(ind).mode;
    if isempty(mode); mode = 'h'; end
    if dat.data(dat.handles==findmaster(dat,h)).normalize;
      set(handles.normalize,'checked','on');
    else
      set(handles.normalize,'checked','off');
    end
    switch mode
      case {'o','b'}
        set([handles.stylebaseline handles.styleheight],'visible','on');
        set([handles.addreference handles.stylearea handles.stylewidth handles.styleposition],'visible','off');
        set(handles.deletemarker,'separator','on');
        if strcmp(mode,'b');
          set(handles.stylebaseline,'checked','on');
          set(handles.styleheight,'checked','off');
        else
          set(handles.stylebaseline,'checked','off');
          set(handles.styleheight,'checked','on');
        end
        set(handles.deletemarker,'label','Remove Reference');
        
      case {'h','','a','p','w' 'm'}
        if isempty(findref(dat,h))
          set(handles.addreference,'visible','on','enable','on');
        else
          set(handles.addreference,'visible','on','enable','off');
        end
        set([handles.stylearea handles.styleheight handles.stylewidth handles.styleposition],'visible','on');
        set([handles.stylebaseline],'visible','off');
        set(handles.deletemarker,'separator','off');
        set(handles.addreference,'separator','on');
        set([handles.styleheight handles.stylearea handles.stylewidth handles.styleposition handles.stylemax],'checked','off');
        switch mode
          case 'a'
            set(handles.stylearea,'checked','on');
          case 'p'
            set(handles.styleposition,'checked','on');
          case 'w'
            set(handles.stylewidth,'checked','on');
          case 'm'
            set(handles.stylemax,'checked','on');
          otherwise
            set(handles.styleheight,'checked','on');
        end
%         set(handles.deletemarker,'label','Delete Marker');
    end
  otherwise
    action
    disp('action not defined')
end

%----------------------------------------------
function docallback(fig)

cb = getappdata(fig,'MarkerChangeFcn');
if ~isempty(cb)
  try
    eval(cb)
  catch
    disp(cb)
    disp(lasterr)
    error(['Error evaluating MarkerChangeFcn']);
  end
end

%----------------------------------------------
function savemarkers(fig)

model = getmodel(fig);

if isempty(model.markers);
  evriwarndlg('No markers are set. Cannot Save.','Markers not set');
  return
end

svdlgpls(model,'Save trend marker model as...',defaultmodelname(model));

%----------------------------------------------
function model = getmodel(fig)

%get marker info
dat = getmarkerdata(fig);

%convert links to indices
for j=1:length(dat.data);
  dat.data(j).link = find(ismember(dat.handles,dat.data(j).link));
end

data = getobjdata(fig);
model = modelstruct('trendtool');
model.datasource{1} = getdatasource(data);
model.date = date;
model.time = clock;
model.markers = dat.data;
model = copydsfields(data,model);
model.detail.preprocessing{1} = getappdata(fig, 'curpp');

%----------------------------------------------
function loadmarkers(fig,model)

if nargin<2 | isempty(model)
  model = lddlgpls('struct','Select trend marker model...');
  if isempty(model);
    return
  end
end

if ~ismodel(model) | ~strcmpi(model.modeltype,'trendtool')
  erdlgpls('This is not a valid TrendTool model','Can not load markers');
end

%extract markers from model
markers = model.markers;
if ~isfield(markers,'mode') | ~isfield(markers,'link');
  erdlgpls('This is not a valid set of TrendTool markers','Can not load markers');
  return
end

if ~isempty(model.detail) && ~isempty(model.detail.preprocessing{1})
  mydata = getappdata(fig,'OriginalData');
  xpp = preprocess('apply',model.detail.preprocessing{1},mydata);
  setappdata(fig, 'curpp', model.detail.preprocessing{1});
  plotgui('update','figure',fig,xpp);
end

%clear existing markers
dat = getmarkerdata(fig);
if ~isempty(dat)
  delete(dat.handles);
end

dat = [];
for j=1:length(markers);
  h = line(nan,nan);
  dat.handles(j) = double(h);
  dat.data(j) = markers(j);
  dat.data(j).link = dat.handles(dat.data(j).link);  %look up link (if any) in handles list
end
dat.cindex = 0;  %unknown...
putmarkerdata(fig,dat);

trendmarker('update',fig);
docallback(fig);

%---------------------------------------------------
function [mydata,figtype] = getobjdata(fig)

if strcmpi(getappdata(fig,'figuretype'),'PlotGUI')
  mydata = plotgui('getobjdata',fig);
  figtype = 'plotgui';
else
  fig = gtf(fig);
  myid = getshareddata(fig);
  mydata = myid{1}.object;
  figtype = 'appdata';
end

%---------------------------------------------------
function setpgcallback(fig,action)

if nargin<2
  action = 'on';
end

%define plotcommand for PlotGUI callback
mypc = 'trendmarker(''update'',targfig);trendlink(targfig);';
%is it a plotgui figure?
if strcmp(getappdata(fig,'figuretype'),'PlotGUI')
  oldpc = getappdata(fig,'plotcommand');
  if strcmp(action,'on');
    %add plotcommand to update markers
    if isempty(strfind(oldpc,mypc));
      oldpc = [oldpc mypc];
      plotgui('update','figure',fig,'plotcommand',oldpc);
    end
  else
    %remove all instances of marker command from plotgui plotcommand
    pos = strfind(oldpc,mypc);
    if ~isempty(pos)
      for pos = pos;
        oldpc(pos:(pos+length(mypc)-1)) = [];
      end
      plotgui('update','figure',fig,'plotcommand',oldpc);
    end
  end
end

%--------------------------------------------------
function zoomupdate(varargin)

trendmarker('update');

%--------------------------------------------------
function fig = gtf(fig)

if nargin<1
  fig = gcbf;
  if isempty(fig)
    fig = gcf;
  end
end
fig = ancestor(fig,'figure');
trendparent = getappdata(fig,'TrendLinkParent');
if ~isempty(trendparent)
  %if this figure appears to be the trend VIEW, skip to parent
  fig = trendparent;
end

%if this figure DOESN'T have trend data...
if isempty(getappdata(fig,'TrendLinkData'))
  %search all figures for one that does
  for f = findobj(allchild(0),'type','figure');
    if ~isempty(getappdata(fig,'TrendLinkData'))
      fig = f; 
      break;
    end
  end
end
