function varargout = demodlg(string,delay,posflag);
%DEMODLG Provides a dialog box for use with GUI demos
% A timed or "space-to-continue" dialog box with a message of variable
% length. Often used for GUI demos, DEMODLG allows narration of actions as
% they occur.
%
% INPUTS:
%   string : String or cell of one or more strings to display in the dialog
%            box. Strings are automatically wrapped to appropriate length.
%            ** SPECIAL: the keyword 'close', when passed as string, will
%            close any currently open demo dialog box.
%    delay : Length of time to wait for a keypress or click from user
%            before automatically continuing without response. A value of
%            "inf" will wait until the user responds. Any other value
%            represents the number of seconds to wait. A value of zero
%            updates the window message but skips any pause and immediately
%            returns.
%  posflag : [ {0} | 1 | -1 ] Governs positioning of GUI. 0 = automatic
%            positioning (recall last position but adjust to keep dialog
%            on-screen), 1 = force to center of screen, -1 = force to top
%            right corner of screen.
%
% The behavior of demodlg can be further modified using the appdata(0)
% properties 'autodemo' and 'nodemodlg' :
% setappdata(0,'autodemo',delay)
%   Where delay is: 
%     0 (zero) : turn off auto-demo (normal, interactive demo mode)
%     any other positive number: turns on "automatic progression" mode for
%         all demo dialog messages. The value of n indicates the length of
%         delay (where 1 = normal delay, 2 = twice as slow, 0.1 = 10x as
%         fast, etc). Demo Dialog messages which normally have a delay of
%         "inf" (infinate pause) will pause only the default amount of
%         time.
% setappdata(0,'nodemodlg',flag)
%   Where flag is:
%    1 (one) : hides the demo dialog alltogether. Note that demodlg will
%               still pause the requested amount of time before returning.
%               Thus, 'nodemodlg' is usually used along with a particular
%               time setting for 'autodemo'
%    0 (zero) : shows the dialog as usual (normal operation).
%     
%I/O: demodlg(string,delay,posflag)
%I/O: demodlg('close')

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1;
  demodlg({'During this demonstration, this dialog box will provide information on what is going on. When paused you will be asked to press the space-bar on your keyboard to continue (do so now).'},inf,1);
  demodlg({'If the pause message says "Continue ( )", then the dialog box is temporarily paused and will continue automatically (when the timer reaches zero). Press the space-bar to continue without waiting.'},15,1);
  demodlg({'When the demo narration window is paused, you can stop the demo by pressing the "Escape" (Esc) key.',...
      ' ','This window will be kept in the upper right corner of the screen to stay out of your way while the demo is running. You may move it to a different location if you wish.'},inf,1);
  demodlg('close');
  return
end

if strcmp(string,'close');
  fig = findobj(allchild(0),'tag','DemoDLG');
  if ishandle(fig);
    delete(fig);
  end
  return
end

if nargin<2 | isempty(delay);
  if getappdata(0,'autodemo');
    if iscell(string); 
      temp = char(string);
    else
      temp = string;
    end
    delay = (4 + length(temp(:))*.04);
  else
    delay = inf;
  end
end
if getappdata(0,'autodemo')
  if isinf(delay); 
    delay = 5; 
  end
  delay = delay*getappdata(0,'autodemo');
end
if getappdata(0,'nodemodlg');
  pause(delay);
  return
end

if nargin<3;
  posflag = 0;
end

if ~isinf(delay)
  flashrate   = .4;
  flashperiod = .4;
else
  flashrate   = .4;
  flashperiod = .4;
end  
flashmask   = [0 1 1];
flashdepth  = .1;

flashperiod = 0;
flashdepth = 0;

%create / find figure
% set(0,'showhiddenhandles','on');
fig = findobj(allchild(0),'tag','DemoDLG');
if isempty(fig);
  fig = dialog('visible','off','tag','DemoDLG');
  oldpos = [];
else
  oldpos = get(fig,'position');
end
if length(fig)>1; delete(fig(2:end)); end

%make duplicate of current figure to "overlay" while we work on the real
%one behind the scenes
set(fig,'handlevisibility','on');
dup = evricopyobj(fig,0);
set(dup,'visible','on','tag','');
set(allchild(dup),'tag','');
drawnow
set(fig,'visible','off');
drawnow

%adjust figure properties
origbaseunits = get(0,'units'); set(0,'units','pixels');
figpos = get(0,'defaultfigureposition');
set(fig,'HandleVisibility','off',...
  'units','pixels',...
  'WindowStyle','normal',...
  'position',figpos,...
  'visible','off',...
  'Name','Demo Narration',...
  'renderer','painters')

if strcmp(string,'close');
  close(fig);
  return
end

%add textbox to that figure (with appropriate sizing)
texth = findobj(fig,'tag','demomessage');
if isempty(texth);
  texth = uicontrol(fig,'Style','Text','tag','demomessage');
end
if length(texth)>1;
  delete(texth(2:end));
end
pos = [10 10 400 10];
set(texth,'fontsize',10,'HorizontalAlignment','Left','fontweight','demi','ForegroundColor',[0 0 0],'units','pixels','Position',pos);
if ~iscell(string); string = {string}; end
[string,newpos] = textwrap(texth,string);
pos(4) = newpos(4);
pos(3) = pos(3)+10;
set(texth,'String',string,'Position',pos+[0 30 0 0])

%resize figure to match new textbox
figpos = get(fig,'position');
figpos = [figpos(1)+figpos(3)/2-pos(3)/2-5 figpos(2)+figpos(3)/2-pos(4)/2-20 pos(3)+10 pos(4)+50];
set(fig,'position',figpos);

%Create OK button
h2 = findobj(fig,'tag','OKButton');
if isempty(h2);
  h2 = uicontrol(fig,'style','text');
end
set(h2,'string','',...
  'fontsize',10,...
  'foregroundcolor',[.8 0 0],...
  'units','pixels',...
  'position',[figpos(3)/2-125 8 250 25],...
  'callback','if ishandle(gcbf); close(gcbf);end');

set(0,'showhiddenhandles','off');

%move figure
pos       = get(fig,'position');
scrnsize  = getscreensize;
pointer   = get(0,'pointerlocation');

if posflag==1; 
  startpos = pos;
  endpos = pos;
else
  if posflag==-1 | isempty(oldpos);  %default position
    endpos    = [scrnsize(3)-pos(3)-2 scrnsize(4)-pos(4)-2-25 pos(3:4)];
  else
    %determine which corner we're closest to and resize relative to that
    endpos = pos;
    if oldpos(1)<(scrnsize(3)-(oldpos(1)+oldpos(3)))
      %closer to left edge
      endpos(1) = oldpos(1); 
    else
      %closer to right edge
      endpos(1) = (oldpos(1)+oldpos(3))-pos(3);
    end
    if oldpos(2)<(scrnsize(4)-(oldpos(2)+oldpos(4)))
      %closer to bottom
      endpos(2) = oldpos(2);
    else
      %closer to top
      endpos(2) = (oldpos(2)+oldpos(4))-pos(4);
    end
  end      
  startpos = endpos;
end
set(fig,'position',startpos);
set(0,'units',origbaseunits);

%set callback of button
cb = get(h2,'callback');
if isinf(delay)
  btn = 'Click Here or Press Space To Continue';
elseif delay>0
  btn = ['Continue (' num2str(fix(delay)) ')'];
else
  btn = ' ';
end
newcb = 'if get(gcbf,''userdata''); close(gcbf); else; set(gcbf,''userdata'',1); end';
set(h2,'style','pushbutton','string',btn,'callback',newcb,'buttondownfcn',newcb)
newcb = 'if get(gcbf,''userdata''); close(gcbf); else; set(gcbf,''userdata'',2); end';
set(fig,'KeyPressFcn',newcb,'buttondownfcn',newcb,'userdata',0)

set(fig,'visible','on');
drawnow;
set(dup,'visible','off');
% figure(fig);
drawnow;
delete(dup);
figure(fig);

%Do timing/waiting loop
c  = get(fig,'color');
tm = now;
elap = (now-tm)*24*60*60;
while ishandle(fig) & (elap<delay) & ~get(fig,'userdata'); 
  if ~isinf(delay)
    btn = ['Continue (' num2str(fix(delay-elap)+1) ')'];
  end
  if ishandle(fig)
    if elap<flashperiod;
      newc = c.*([1 1 1]-flashmask.*(mod(elap,flashrate)*flashdepth/flashrate));
      set(fig,'color',newc); 
      set(texth,'backgroundcolor',newc);
      set(h2,'backgroundcolor',newc);
      set(h2,'string',btn);
    else
      set(fig,'color',c);
      set(texth,'backgroundcolor',c);
      set(h2,'string',btn);
      set(h2,'backgroundcolor',c);
    end
  end
  drawnow; 
  elap = (now-tm)*24*60*60;
end

%done, reset figure and objects
if ishandle(fig); 
  set(fig,'color',c);%,...
%     'position',endpos); 
  key = get(fig,'CurrentCharacter');
  if key<32 & key~=13 & get(fig,'userdata')==2;
    delete(fig)
    erdlgpls('Demo aborted by user.','Demo Aborted')
    error('Demo Aborted')
  end
end
if ishandle(h2); 
  set(h2,'callback',cb,'visible','off'); 
  set(h2,'backgroundcolor',c);
end
if ishandle(texth);
  set(texth,'backgroundcolor',c);
end

figure(fig);drawnow;

if nargout ==1;
  varargout = {fig};
end
