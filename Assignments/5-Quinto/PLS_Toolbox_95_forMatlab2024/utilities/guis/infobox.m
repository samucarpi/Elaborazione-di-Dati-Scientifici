function varargout = infobox(fig,mode,varargin)
%INFOBOX Display a text message in an information box.
% When called with a string input (string), infobox creates a figure with a
%  scrollable listbox. The contents of the listbox can be copied to the
%  system clipboard for pasting into other programs.
%   Optional structure input (options) can contain any of the fields:
%      figurename: [{'Information'}] default name of infobox figure
%         maxsize: [width height] maximum default size of window in
%                  characters. Size will be this value or 2/3 of the
%                  current screen size, whichever is smaller. Default for
%                  maxsize option is [inf inf] so boxes are only limited by
%                  screen size.
%        fontname: [{''}| fontname ] default font for listbox (empty =
%                  use system default)
%        fontsize: [{[]}| fontsize ] default font size for listbox (empty =
%                  use system default)
%         visible: [{'on'}| 'off'] visibility of new infobox figures
%        openmode: [{'reuse'}| 'new' ] reuse existing infobox figure or create
%                  a new figure?
%        helplink: [''] Help page location to associated with help menu, if
%                  any. Expected to be either complete HTTP URL or the name
%                  of a help page in the Eigenvector Documetnation wiki
%                  (local version will be displayed if present, otherwise,
%                  web version will be displayed.)
% The output of infobox is (fig) the handle of the newly created figure.
% A previously created infobox figure can be changed using the following
%  keywords and inputs:
%    'string' and (string) a string to display in the listbox
%    'font'   and (fontname) and/or (fontsize) to update the font used
%    'name'   and (figurename) to set the figure's name
%
%I/O: fig = infobox(string,options)
%I/O: infobox(fig,'string',string)
%I/O: infobox(fig,'font',fontname,fontsize)
%I/O: infobox(fig,'name',figurename)

%Internal call info
%  Mode can be one of:
%    new - {default} create a new info box FIG is string
%    font - set font of given figure to fontname and fontsize supplied
%    name - set name of window to given string
%    string - set infobox string
%    selectall - select all lines in the info box
%    copy - copy selected lines (or all lines if none are selected)
%    movetopointer - move box to pointer location
%    keeponscreen - move box to keep on-screen

%Copyright Eigenvector Research 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%JMS 1/16/04 -added select all mode
% -mods to copy and initialize modes
%rsk - JMS Add comment.
%jms 6/04 -increased max autosize (options.maxsize)

if nargin == 0; fig = 'io'; end
if ischar(fig) & ismember(fig,evriio([],'validtopics'));
  options = [];
  options.figurename = 'Information';
  options.maxsize = [inf inf];
  options.fontname  = '';
  options.fontsize  = [];
  options.visible   = 'on';
  options.openmode  = 'reuse';
  options.helplink  = '';
  if nargout==0; evriio(mfilename,fig,options); else; varargout{1} = evriio(mfilename,fig,options); end
  return; 
end

options = [];
if isa(fig,'char') | isa(fig,'cell');  
  %"create new" call: (string)  or (string,options)
  
  if nargin==2 & isa(mode,'struct');
    options = mode;
  end
  
  options = reconopts(options,'infobox');
  
  if ~isa(fig,'cell') & ~isa(fig,'char')
    error('Input (content) must be a cell or character array');
  end
  infostring = fig;  %input was content string
  
  %create figure and do initialization
  if isempty(options.openmode) | ~strcmpi(options.openmode,'new')
    oldfig = findobj(allchild(0),'name',options.figurename);
    if ~isempty(oldfig)
      fig = oldfig(1);
      figure(fig);  %bring to front
    else
      fig = openfig('infobox','new');
    end
  else
    %user specifically requested 'new'
    fig = openfig('infobox',options.openmode);
  end
  
  set(fig,'name',options.figurename)
  handles = guihandles(fig);  % Generate a structure of handles to pass to callbacks, and store it. 
  guidata(fig, handles);
  setappdata(fig,'figuretype','infobox')

  if ~iscell(infostring)
    infostring = {infostring};
  end

  if isempty(options.helplink)
    %remove any help menu
    delete([findobj(fig,'tag','helpmenu') findobj(fig,'tag','helpsubmenu')]);
  else
    %create menus (if needed)
    if isempty(findobj(fig,'tag','helpmenu'));
      hh = uimenu(fig,'label','Help','tag','helpmenu');
      uimenu(hh,'label','Help on Window Contents','callback','infobox(gcbf,''showhelp'')');
    end
    
    %show help notice
    note = 'See Help menu for content information';
    if checkmlversion('>=','7.1')
      note = ['<html><font color="#000099">' note];
    end
    infostring = [infostring;{' ';note}];    
    
  end
  setappdata(fig,'helplink',options.helplink)
  
  %Make print menu invisible. 
  %FIXME: Add print functionality.
  if isfield(handles,'fileprint')
    set(handles.fileprint,'visible','off')
  end
  
  %assign string and selection
  set(handles.listbox,...
    'string',infostring,...
    'units','pixels',...
    'keypressfcn','infobox(gcbf,''keypress'')',...
    'value',[]);
  
  %set default font
  setfont(fig,options.fontname,options.fontsize);    
  
  %resize to fit size of infostring
  scrnsz = getscreensize;
  options.maxsize = min(options.maxsize,scrnsz(3:4)/3*2);
  set(fig,'units','pixels');
  pos = get(fig,'position');
  ext = get(handles.listbox,'extent');
  pos(3:4) = [max(pos(3),min(ext(3)+20,options.maxsize(1))) max(pos(4),min(ext(4)+15,options.maxsize(2)))];
  set(fig,'position',pos);
  set(fig,'resizefcn','infobox(gcbf,''resize'')');
  keeponscreen(fig);
  
  set(fig,'keypressfcn','infobox(gcbf,''keypress'')');
  
  % Correction for >2K screens
  if ((scrnsz(3) > 2048) || (scrnsz(4) > 1080))
    scrn=scrnsz*0.4;
    % Clamp gui within screen resolution
    if (pos(1) + pos(3) > scrn(1) + scrn(3))
      pos(1) = scrn(3) - pos(3); % - 1;
    end
    if (pos(2) + pos(4) > scrn(2) + scrn(4))
      pos(2) = scrn(4) - pos(4); % - 1;
    end
    if (pos(1) < scrn(1))
      pos(1) = scrn(1); % + 1;
    end
    if (pos(2) < scrn(2))
      pos(2) = scrn(2); % + 1;
    end
    %Minor adjustment for infobox.
    pos(2) = pos(2) - scrn(4)*0.07;
    set(fig,'position',pos);
  end
  
  set(fig,'visible',options.visible);
  
  if nargout > 0
    varargout = {fig};
  end
  
else    %update of existing figure
  
  %verify figure handle
  if isa(fig,'double') & (~ishandle(fig) | ~strcmp(getappdata(fig,'figuretype'),'infobox'))
    error('Input (fig) must be a valid figure handle')
  end
  figbrowser('on',fig);
  
  %check for options and parse out
  for j=1:length(varargin);
    if isa(varargin{j},'struct')
      options = varargin{j};
      break
    end
  end
  options = reconopts(options,'infobox');
  
  %choose action based on mode
  switch mode      
    case 'string'
      h = findobj(fig,'tag','listbox');
      set(h,'string',varargin{1},'value',[]);
      
    case 'selectall'
      h = findobj(fig,'tag','listbox');
      st = get(h,'string');
      val = 1:size(st,1);
      set(h,'value',val);
      
    case 'keypress'
      c = double(get(fig,'CurrentCharacter'));
      if isempty(c);
        return;
      end
      switch c
        case 1   %ctrl-a
          infobox(fig,'selectall');
          
        case 3   %ctrl-c
          infobox(fig,'copy');
          
        case 19   %ctrl-s
          infobox(fig,'save');
          
        case 23  %ctrl-w
          close(fig);
          
        case 2   %ctrl-b
          exportfigure('',fig);
          
      end
      
    case 'copy'
      h = findobj(fig,'tag','listbox');
      st = get(h,'string');
      val = get(h,'value');
      if isempty(st) | max(val)>size(st,1) | min(val)<1;
        return
      end
      if isempty(val)
        val = 1:size(st,1);  %nothing selected? consider this "copy all"
      end
      %convert to cell if it isn't already
      if ~isa(st,'cell'); 
        st = mat2cell(st,ones(size(st,1),1),size(st,2));
      end;   
      
      tocopy = sprintf(['%s' 10],st{val});
      clipboard('copy',tocopy);
      
    case 'font'
      setfont(fig,varargin{:});
      
    case 'name'
      set(fig,'name',varargin{1});
      
    case 'keeponscreen'
      keeponscreen(fig);

    case 'docktofigure'
      docktofigure(fig,varargin{1});
      
    case 'movetopointer'    
      set(fig,'units',get(0,'units'))
      pos = get(fig,'position');
      set(fig,'position',[get(0,'PointerLocation')-[0 pos(4)] pos(3:4)],'visible','on')
      keeponscreen(fig);

    case 'viewfont'
      h = findobj(fig,'tag','listbox');
      newfontinfo = uisetfont(h);
      if isa(newfontinfo,'struct');
        for j=fieldnames(newfontinfo)';
          set(h,j{:},getfield(newfontinfo,j{:}));
        end
        if isfield(newfontinfo,'FontName')
          setplspref('infobox','fontname',newfontinfo.FontName);
        end
        if isfield(newfontinfo,'FontSize')
          setplspref('infobox','fontsize',newfontinfo.FontSize);
        end
      end
      
    case 'resize'
      h = findobj(fig,'tag','listbox');
      pos = get(h,'position');
      figpos = get(fig,'position');
      pos(3:4) = max([3 3],figpos(3:4)-pos(1:2)*2+[1 1]);
      set(h,'position',pos);
    
    case 'print'
      
    case 'save'
      h = findobj(fig,'tag','listbox');
      st = get(h,'string');
      if ~isa(st,'cell'); 
        st = mat2cell(st,ones(size(st,1),1),size(st,2));
      end;
      
      if ~isempty(st)
        [filename, pathname, filterindex] = evriuiputfile({'*.txt','Text File (*.txt)';'*.*',  'All Files (*.*)' },'Save','infobox_save.txt');
        if ~filename
          %User cancel.
          return
        end
        
        %Check for file extension (user may have manually added it), add if not there.
        [junk, junk, ext] = fileparts(filename);
        if isempty(ext)
          filename = fullfile(pathname,filename,'.txt');
        else
          filename = fullfile(pathname,filename);
        end
        fid = fopen(filename,'w');
        fprintf(fid,['%s' 10],st{:});
        fclose(fid);
      end
      
    case 'showhelp'
      link = getappdata(fig,'helplink');
      plotgui('showhelp',char(link))
  end
end

%-------------------------------------
function setfont(fig,varargin)
%Set listbox font as specified in varargin
%  (fontname,fontsize)
if ~strcmp(getappdata(fig,'figuretype'),'infobox')
  return
end

h = findobj(fig,'tag','listbox');

%parse out varargin
switch length(varargin)
  case 0
    % just a fig # ?!?
    return
  case 1
    % (fig,fontname)
    % (fig,fontsize)
    if isa(varargin{1},'char')
      fontname = varargin{1};
      fontsize = [];
    else
      fontname = '';
      fontsize = varargin{1};
    end
  otherwise
    % (fig,fontname,fontsize,...) extra are ignored
    if ~isa(varargin{1},'char') & isa(varargin{2},'char')
      varargin = varargin([2 1]);  %check for reverse order (gads we're nice!)
    end
    fontname = varargin{1};
    fontsize = varargin{2};
end

if ~isempty(fontname) & isa(fontname,'char')
  set(h,'FontName',fontname);
  setplspref('infobox','fontname',fontname);
end
if ~isempty(fontsize) & isa(fontsize,'double')
  set(h,'FontSize',fontsize);
  setplspref('infobox','fontsize',fontsize);
end

%------------------------------------------------
function keeponscreen(fig,shrinkonly);
%check if fig is off screen (order of tests is important, top left
%corner is most critical to be on-screen)

if nargin<2;
  shrinkonly = false;
end

units = get(fig,'units');
set(fig,'units','pixels');
pos        = get(fig,'position');
screensize = getscreensize;
moved  = false;

%test for off right side
shift = screensize(3)-(pos(1)+pos(3));
if shift<0  
  if ~shrinkonly;
    pos(1) = pos(1)+shift;
  else
    pos(3) = pos(3)+shift;
  end
  moved  = true;
end
%test for off bottom
shift = pos(2);
if shift<0  
  if ~shrinkonly;
    pos(2) = pos(2)-shift;
  else
    pos(2) = pos(2)-shift;
    pos(4) = pos(4)+shift;
  end    
  moved  = true;
end
%test for off left side
shift = pos(1);
if shift<0  
  if ~shrinkonly;
    pos(1) = pos(1)-shift;
  else
    pos(1) = pos(1)-shift;
    pos(3) = pos(3)+shift;
  end
  moved  = true;
end
%test for off top (w/padding for menus)
shift = screensize(4)-(pos(2)+pos(4) + 50);
if shift<0  
  if ~shrinkonly;
    pos(2) = pos(2)+shift;
  else
    pos(4) = pos(4)+shift;
  end    
  moved  = true;
end

if moved;
  %save new position
  set(fig,'position',pos);
end

%return to original units
set(fig,'units',units);

%force resize
infobox(fig,'resize')

%--------------------------------------------------------
function docktofigure(fig,targfig)

%move to below target figure
set(fig,'units',get(targfig,'units'))
pos    = get(fig,'position');
figpos = get(targfig,'position');
set(fig,'position',[figpos(1:2)-[0 pos(4)] figpos(3) pos(4)])

keeponscreen(fig,true);  %make sure it is on-screen after the move (by shrinking)

%--------------------------------------------------------
function infokeypress(varargin)

varargin{:}
