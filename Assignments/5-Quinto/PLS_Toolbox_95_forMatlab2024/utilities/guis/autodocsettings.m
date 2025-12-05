function f = autodocsettings(fh,key);
%AUTODOCSETTINGS Simple interface for setting auto docking features of PLS_Tool box.

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  %Create figure.
  f = figure('Name','Docking Settings','Tag','autodocksettings','NumberTitle','off',...
    'Units','pixels','Visible','off','Toolbar','none','Menubar','none');
  
  %default position.
  figpos = get(f,'position');
  screensize = getscreensize;
  figpos(3) = 300;
  figpos(4) = 262;
  figpos(1) = 200;
  figpos(2) = screensize(4)-figpos(4)-50;
  set(f,'position',figpos,'visible','on');
  positionmanager(f,'autodocsettings')
  
  %Get button images.
  imgs = loadicons;
  
  
  %Add butons.
  lst = {'none' 'user' 'all' 'cancel'; ... %tag
    imgs.none imgs.user imgs.all imgs.cancel; ... %img
    '(Default) Do not dock figures. All data figures and interfaces open in separate windows.' ...
    'Data figures are automatically docked. Interfaces open in separate windows, but can be docked manually.' ...
    'All data figures and interfaces are automatically docked.' ...
    'Cancel'}; %string
  
  voffset = 2;
  for i = 1:size(lst,2)
    mypos = [2 (figpos(4) - (2+(i*64))) 64 64];%left bottom width height
    %Create button.
    bh = uicontrol('Style','togglebutton','tag',lst{1,i}, ...
      'position',mypos,'Callback',['autodocsettings(gcbf,''' lst{1,i} ''')'], ...
      'cdata',lst{2,i});
    %Create text box.
    uicontrol('Style','text','tag',[lst{1,i} '_text'],'String',lst{3,i},'Enable','Inactive', ...
      'Position',[mypos(3)+4 mypos(2)+2 230 mypos(4)-4],'BackgroundColor','white', ...
      'HorizontalAlignment','Left','Max',3,'Min',1,'ButtonDownFcn',['autodocsettings(gcbf,''' lst{1,i} ''')']);
  end

else
  %Callbacks.
  switch key
    case 'none'
      setplspref('figbrowser','autodock','off')
      setplspref('positionmanager','dockall','save')
    case 'user'
      setplspref('figbrowser','autodock','on')
      setplspref('positionmanager','dockall','save')
    case 'all'
      setplspref('figbrowser','autodock','on')
      setplspref('positionmanager','dockall','always')
    case 'cancel'
  end
  close(fh)
  
end

%-----------------------------------------------------
function autodocimages = loadicons()
%Load images and add grey to current setting.

load autodockicons
fopts = figbrowser('options');
popts = positionmanager('options');
mybutton = '';

if strcmp(fopts.autodock,'off')
  if strcmp(popts.dockall,'save')
    mybutton = 'none';
  end
else
  if strcmp(popts.dockall,'save')
    mybutton = 'user';
  elseif strcmp(popts.dockall,'always')
    mybutton = 'all';
  end
end

switch mybutton
  case 'none'
    autodocimages.none(autodocimages.none==255) = 220;
  case 'all'
    autodocimages.all(autodocimages.all==255) = 220;
  case 'user'
    autodocimages.user(autodocimages.user==255) = 220;
end




