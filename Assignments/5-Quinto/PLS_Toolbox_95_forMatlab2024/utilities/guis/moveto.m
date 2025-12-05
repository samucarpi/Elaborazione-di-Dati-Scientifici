function moveto(h,offset,postdelay);
%MOVETO moves pointer to a given GUI object
% Inputs are (h) the handle to which we should move, (offset) the
% fractional (<1) or pixel (>1) x and y offset from that object, and
% (postdelay) the amount of time to wait after moving to that object.

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%-----------
steps = 15;
tm = .5;
%-----------

%speed up or don't even move
if getappdata(0,'nomove')
  return;
end
if getappdata(0,'autodemo')>0%<.5;
  %   tm = 0.01;
  tm = tm * getappdata(0,'autodemo');
elseif getappdata(0,'autodemo')<0
  steps = 2;
  tm = 0;
end

%-------------
if nargin<2;
  offset = [];
end
if nargin<3;
  postdelay = [];
end
if length(offset)==1;
  postdelay = offset;
  offset = [];
end
if tm==0
  postdelay = 0;
end

%make it so we can see all handles
set(0,'showhiddenhandles','on');

%locate ONE valid handle
h = h(end);
if isempty(h) | ~ishandle(h);
  disp('Object not found');
  set(0,'showhiddenhandles','off');
  return;
end

%get figure number this object is on and its position
fig = h;
fig = ancestor(fig,'figure');
figure(fig);
oldunits = get(fig,'units');
set(fig,'units',get(0,'units'));
fpos     = get(fig,'position');
set(fig,'units',oldunits);

%get current object position (in normalized units)
switch get(h,'type')
  case 'uimenu'  %is it a menu?
    menuindex = movetomenu(h,postdelay);        %try moving to the menu item (create fake menus for "show"
    if menuindex==0;
      set(0,'showhiddenhandles','off');
      return;
    end      %Was it successfully handled by movetomenu? just exit now.

    tbinfo = gettbinfo(fig);
    offset = [calcmenuoffset(fig,menuindex) tbinfo.size(2)];    %Nope. It's a top level menu. Move to the object (or our best guess to where it is)
    opos   = [.00 1.04 0 0];
    normpos = true;

  case 'uicontextmenu'
    set(0,'showhiddenhandles','off');
    return
  
  case 'uipushtool'
    padding = 2;
    sepsize = 6;
    tbinfo = gettbinfo(fig);
    ind = find(tbinfo.children==h);
    if isempty(ind)
      set(0,'showhiddenhandles','off');
      return
    end
    offset = round([tbinfo.size(1)*(ind-.5)+padding*(ind-1)+sum(tbinfo.separator(1:ind))*sepsize tbinfo.size(2)/2]);
    opos   = [0 1.02 0 0];
    normpos = true;
  
  case 'figure'
    opos = [0 0 1 1];
    normpos = true;
    if isempty(offset);
      offset = [.5 1.14];  %no offset given w/figure object? go to title bar
    end
    if strcmp(offset,'close');
      offset = [.98 1.14];
    end

  otherwise
    while h~=0 & ~ismember(get(h,'type'),{'uicontrol','axes','figure','uimenu'});
      h = get(h,'parent');
    end
    if h==0;
      set(0,'showhiddenhandles','off');
      return;
    end
    oldunits = get(h,'units');
    set(h,'units','pixels');
    opos = get(h,'position');
    set(h,'units',oldunits);
    normpos = false;

end

if isempty(offset);
  offset = [0 0];
end

%calculate where we want to move to
if any(offset~=fix(offset));
  center = opos(3:4).*offset;
else
  center = opos(3:4)/2;
end
opos = opos(1:2)+center;
if normpos;
  opos = fpos(3:4).*opos;
end
opos = opos + fpos(1:2);
if all(offset==fix(offset));
  opos = opos + offset;
end

%do the move
cpos = get(0,'pointerlocation');
if ~all(cpos==opos);
  for j=1:2;
    step(j) = (opos(j)-cpos(j))/(steps-1);
  end
  if all(abs(step)<5);
    steps = 5;  %short distance... do quickly 
    for j=1:2;
      step(j) = (opos(j)-cpos(j))/(steps-1);
    end
  end
  for j = 1:2;
    if abs(step(j)) < 1e-2;
      vect(1:steps,j) = ones(steps,1)*cpos(j);
    else
      vect(1:steps,j) = [cpos(j):step(j):opos(j)]';
    end
  end
  for j=1:size(vect,1);
    set(0,'pointerlocation',vect(j,:));
    drawnow;
    pause(tm/steps);
  end
end

if isempty(postdelay);
  postdelay = 1;.05;.5;
end

%do special object modifications
undo = {};
switch get(h,'type')
  case 'uicontrol'  %is it a control object?
    switch get(h,'style')
      case 'pushbutton'
        undo = {'value',get(h,'value')};
        set(h,'value',1);
    end
end

pause(postdelay);
set(0,'showhiddenhandles','off');

if ~isempty(undo);
  set(h,undo{:});
end

%-----------------------------------------------------------------------
function status = movetomenu(h,postdelay)

[tree,branch,fig] = gettree(h);

if nargin<2;
  postdelay = [];
end
if isempty(postdelay);
  postdelay = .5;2;
end

%determine how to handle this menu (is it top level?)
if length(branch)==2; 
  status = get(branch(2),'position');
  return; 
end
status = 0;  %not a top-level menu, we'll handle it here

if strcmp(get(branch(2),'type'),'uimenu')
  moveto(branch(2),0,0); %recursive call to moveto - top level menu
  moveto(branch(2),0,0); %recursive call to moveto - top level menu
end

%figure out starting position for fake menu
units = get(fig,'units');
set(fig,'units','pixels');
figpos = get(fig,'position');
origfigpos = figpos;

if ~strcmp(get(branch(2),'type'),'uimenu')
  units = get(0,'units');
  set(0,'units','pixels');
  cursorpos = get(0,'PointerLocation');
  set(0,'units',units);

  pos = [cursorpos(1)-figpos(1) figpos(4)];  %below cursor on figure
  pos(2) = [cursorpos(2)-figpos(2)];
else
  pos = [calcmenuoffset(fig,get(branch(2),'position'),0) figpos(4)];
end

%-----------------
height = 15;
spacer = 2;
sepheight = -1;

charspacing = 5;
fontname = 'Tahoma';%'arial';
fontsize = 9;

checkwidth = 15;
expandwidth = 15;

disabledcolor = [.6 .55 .47];
enabledcolor  = [0 0 0];
sepcolor      = [.5 .45 .37];
sepcolor2     = min(get(0,'defaultfigurecolor')*1.2,[1 1 1]); %[.5 .45 .37];

%-----------------
pos(2) = pos(2)-height-spacer*2;
startpos = pos;
childpos = pos;

oldbranchhandle = [];
tb = [];
for treeind = 1:length(tree);
  subtree = tree{treeind};
  
  menuframe = uicontrol(fig,...
    'style','frame',...
    'units','pixels',...
    'position',[pos(1)-spacer pos(2) spacer*2 spacer*2]);
  tb(end+1) = menuframe;
  set(menuframe,'foregroundcolor',min(get(menuframe,'backgroundcolor')*1.2,[1 1 1]));  %set edge color

  %get all labels (and set width of strings to match)
  label = [];
  for ind = 1:length(subtree);
    mh = subtree(ind);
    temp = get(mh,'label');
    temp(temp=='&') = [];   %drop &s
    label = strvcat(label,['      ' temp '     ']);
  end
  width = size(label,2)*charspacing;

  %create objects for each menu item
  for ind = 1:length(subtree);
    mh = subtree(ind);
    
    thislabel = label(ind,:);
    %     thislabel = [thislabel blanks(length(findstr(blanks(18),thislabel)))]; %double empty spaces
    %     thislabel = [thislabel blanks(length(findstr('  ',thislabel)))]; %double empty spaces
    %     if ~isempty(get(mh,'children'))
    %       thislabel(end-2) = '»';
    %     end
    %
    %     if strcmp(get(mh,'checked'),'on')
    %       thislabel(1) = '×'; %'¤';
    %       thislabel(2) = [];
    %     end
    
    %Strip HTML from label
    if ~isempty(findstr(lower(thislabel),'<html>'))
      thislabel = regexprep(thislabel,'<(.|\n)*?>','');
    end

    if strcmp(get(mh,'enable'),'on');
      color = enabledcolor;
    else
      color = disabledcolor;
    end
    
    if strcmp(get(mh,'separator'),'on');
      tb(end+1) = uicontrol(fig,...
        'style','frame',...
        'units','pixels',...
        'ForegroundColor',sepcolor,...
        'backgroundcolor',sepcolor,...
        'position',[pos(1)+width*.025 pos(2)+height-sepheight width*.95 sepheight+spacer]);
      tb(end+1) = uicontrol(fig,...
        'style','frame',...
        'units','pixels',...
        'ForegroundColor',sepcolor2,...
        'backgroundcolor',sepcolor2,...
        'position',[pos(1)+width*.025 pos(2)+height-sepheight-1 width*.95 sepheight+spacer]);
      pos(2) = pos(2)-sepheight-spacer*3;
    end
    tb(end+1) = uicontrol(fig,...
      'style','text',...
      'units','pixels',...
      'fontname',fontname,...
      'fontsize',fontsize,...
      'position',[pos width height+spacer],...
      'string',thislabel,...
      'HorizontalAlignment','left',...
      'foregroundcolor',color);
    if ismember(mh,branch);
      branchhandle = tb(end);      %mark this as the branch point for next menu
    end

    myhandle = tb(end);
    extent = get(myhandle,'extent');
    mypos = get(myhandle,'position');
    if strcmp(get(mh,'checked'),'on')
      width = max(width,extent(3)+expandwidth);
    else
      width = max(width,extent(3));
    end
    mypos(3) = width;
    set(myhandle,'position',mypos);

    if ~isempty(get(mh,'children'))
      tb(end+1) = uicontrol(fig,...
        'style','text',...
        'units','pixels',...
        'fontname','marlett',...
        'fontsize',10,...
        'position',[pos+[width-expandwidth 0] expandwidth height+spacer],...
        'string',char(52),...
        'HorizontalAlignment','left',...
        'foregroundcolor',color);
      setappdata(myhandle,'expand',tb(end));
    end

    if strcmp(get(mh,'checked'),'on')
      tb(end+1) = uicontrol(fig,...
        'style','text',...
        'units','pixels',...
        'fontname','marlett',...
        'fontsize',12,...
        'position',[pos checkwidth height+spacer],...
        'string',char(97),...
        'HorizontalAlignment','left',...
        'foregroundcolor',color);
      setappdata(myhandle,'check',tb(end));
    end
    
    pos(2) = pos(2)-height-spacer;

  end
  framepos = [pos(1)-spacer pos(2)+height width+spacer*2 childpos(2)-pos(2)+spacer*2];
  set(menuframe,'position',framepos);

  %is this "in window"?
  toedge = figpos(3)-(framepos(1)+framepos(3));
  if toedge<0;  %off right edge?
    if figpos(3)<framepos(3); %too wide to fit window? resize window to fit
      figpos(3) = framepos(3)+spacer;
      set(fig,'position',figpos);
      toedge = figpos(3)-(framepos(1)+framepos(3));
    end
    for ind=1:length(tb);
      temp = get(tb(ind),'position');
      temp(1) = temp(1)+toedge-spacer;
      set(tb(ind),'position',temp);
    end
  end

  if framepos(2)<0;
    figpos(4) = figpos(4)-framepos(2);
    figpos(2) = figpos(2)+framepos(2);
    set(fig,'position',figpos);
    for ind=1:length(tb);
      temp = get(tb(ind),'position');
      temp(2) = temp(2)-framepos(2)+spacer;
      set(tb(ind),'position',temp);
    end
  end    
  
  %add shadow for frame
  tb(end+1) = uicontrol(fig,...
    'style','frame',...
    'units','pixels',...
    'ForegroundColor',sepcolor,...
    'backgroundcolor',sepcolor,...
    'position',[framepos(1)+framepos(3) framepos(2) 1 framepos(4)]);
  tb(end+1) = uicontrol(fig,...
    'style','frame',...
    'units','pixels',...
    'ForegroundColor',sepcolor,...
    'backgroundcolor',sepcolor,...
    'position',[framepos(1) framepos(2) framepos(3) 1]);
  
  if ishandle(oldbranchhandle)
    set(branchhandle,'backgroundcolor',get(branchhandle,'backgroundcolor'),'foregroundcolor',get(branchhandle,'foregroundcolor'));
  end    
  pause(postdelay);
  moveto(branchhandle,0);
  set([branchhandle getappdata(branchhandle,'check') getappdata(branchhandle,'expand')],'backgroundcolor',[0 0 .3],'foregroundcolor',[1 1 1]);
  oldbranchhandle = branchhandle;
  
  childpos = get(branchhandle,'position');
  pos(1) = childpos(1) + width;% - spacer;  %overlap next layer SLIGHTLY
  pos(2) = childpos(2);
  
end

pause(postdelay);

for j=1:2;
  set([branchhandle getappdata(branchhandle,'check') getappdata(branchhandle,'expand')],'backgroundcolor',get(menuframe,'backgroundcolor'),'foregroundcolor',enabledcolor);
  pause(.05);
  set([branchhandle getappdata(branchhandle,'check') getappdata(branchhandle,'expand')],'backgroundcolor',[0 0 .3],'foregroundcolor',[1 1 1]);
  pause(.05);
end

delete(tb);
set(fig,'position',origfigpos);
set(fig,'units',units);


%-----------------------------------------------------------------------
% Locate tree of handles, along with branches and parent figure
function [tree,branch,fig] = gettree(h);

branch = h;
tree = cell(0);
while ~strcmp(get(h,'type'),'figure')
  
  h = get(h,'parent');
  branch = [h branch];
  
  if ~strcmp(get(h,'type'),'figure'); 
    callback = get(h,'callback');
    items = get(h,'children');
    items = items(ismember(get(items,'visible'),{'on'}));
    pos   = get(items,'position');
    if iscell(pos); pos = [pos{:}]; end
    [what,where] = sort(pos);
    items = items(where);
    tree = [{items} tree];
  else
    fig = h;
  end
  
end


%================================================
function info = gettbinfo(h);

info.children = [];
info.size = [0 0];

tb = findobj(h,'type','uitoolbar');
if isempty(tb); return; end

children = get(tb,'children');
if iscell(children); children = cat(1,children{:}); end
children = fliplr(children');

maxsz = [0 0 0];
for j=1:length(children)
  maxsz = max(maxsz,size(get(children(j),'cdata')));
  sep(j) = strcmp(get(children(j),'separator'),'on');
end

info.children = children;
info.size = maxsz(1:2);
info.separator = sep;

%======================================================
function offset = calcmenuoffset(fig,menuindex,center)

if nargin<3;
  center = true;
end
charwidth = 4;
spacing = 15;

offset = 0;

topmenus = fliplr(findobj(allchild(fig),'type','uimenu','parent',fig)');
for j=1:menuindex-1;
  offset = offset + length(get(topmenus(j),'label'))*charwidth + spacing;
end

if center
  offset = offset + (length(get(topmenus(menuindex),'label'))*charwidth)/2;
end

  
