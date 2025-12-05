function varargout = equalitygui(varargin)
%EQUALITYGUI Equality constraint gui for alsoptions.
%
%
%
%I/O: alsoptions = equalitygui(data,ncomp,alsoptions)
%
%See also: ALS

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0 || ~ischar(varargin{1}) % LAUNCH GUI
  try
    if nargin<3
      error('Requires 3 inputs.')
    end
    if isempty(varargin{1})
      if nargout>0; varargout = {[]}; end
      return;
    end

    %Start GUI
    h=waitbar(1,['Starting Equality GUI...']);
    drawnow
    %Open figure and initialize   
    fig = figure('Tag','equalitygui',...
      'NumberTitle', 'off', ...
      'HandleVisibility','callback',...
      'Integerhandle','off',...
      'Name', 'Equality Constraints Settings',...
      'WindowStyle','modal',...
      'Renderer','OpenGL',...
      'MenuBar','none',...
      'ResizeFcn','equalitygui(''resize_callback'',gcbo,[],guihandles(gcbf))',...
      'CloseRequestFcn','try;equalitygui(''closereq_callback'',gcbo,[],guihandles(gcbf),0);catch;delete(gcbf);end',...
      'visible','off',...
      'Units','pixels');
    
    %Get datasize, ncomp, and spec/conc options.
    dsize = size(varargin{1});
    setappdata(fig,'data_size',dsize)
    setappdata(fig,'data_size_include',cellfun(@(i) length(i),varargin{1}.include));
    setappdata(fig,'data_include',varargin{1}.include);
    setappdata(fig,'ncomp',varargin{2})
    alsoptions = varargin{3};
    varargout{1} = alsoptions;
    
    %Parce concentration.
    mycc = alsoptions.cc;
    if any(size(mycc)~=[dsize(1) varargin{2}])
      %Pre allocate nan matrix for cc.
      mycc = nan(dsize(1),varargin{2});
    end
    setappdata(fig,'cc',mycc)
    
    %Parse spectra.
    mysc = alsoptions.sc;
    if any(size(mysc)~=[varargin{2} dsize(2)])
      %Pre allocate nan matrix for sc.
      mysc = nan(varargin{2},dsize(2));
    end
    setappdata(fig,'sc',mysc)
    
    %Preallocate weights.
    ccwts = alsoptions.ccwts;
    if length(ccwts)~=varargin{2}
      ccwts = inf(1,varargin{2});
    end
    setappdata(fig,'ccwts',ccwts)
    
    scwts = alsoptions.scwts;
    if length(scwts)~=varargin{2}
      scwts = inf(1,varargin{2});
    end
    setappdata(fig,'scwts',scwts)
    
    %Set up gui controls.
    gui_enable(fig)
    
    figbrowser('addmenu',fig); %add figbrowser link
    
    %Position gui from last known position.
    positionmanager(fig,'equalitygui');
    
    handles = guihandles(fig);
    fpos = get(handles.equalitygui,'position');
    
    pause(.1);drawnow
    set(fig,'visible','on');
    
    resize_callback(fig,[],handles);
    if ishandle(h)
      close(h);
    end
    
    % Wait for callbacks to run and window to be dismissed:
    uiwait(fig);
    
    if isempty(getappdata(handles.equalitygui,'cancel_push'))
      %Get options. Check for default values and switch back to scalar
      %input so mcr won't error if data size changes and user has not set
      %any options. If user has set options and changes size of data they
      %will see an error and need to reopen equality gui.
      mycc = getappdata(fig,'cc');
      if all(all(isnan(mycc)))
        mycc = [];
      end
      alsoptions.cc    = mycc;
      
      mysc = getappdata(fig,'sc');
      if all(all(isnan(mysc)))
        mysc = [];
      end
      alsoptions.sc    = mysc;
      
      myccwts = getappdata(fig,'ccwts');
      if all(isinf(myccwts))
        myccwts = inf;
      end
      alsoptions.ccwts = myccwts;
      
      myscwts = getappdata(fig,'scwts');
      if all(isinf(myscwts))
        myscwts = inf;
      end
      alsoptions.scwts = myscwts;
      
      varargout{1} = alsoptions;
    end
    
    if ishandle(fig);  %still exists?
      positionmanager(fig,'equalitygui','set')
      delete(fig);
    end
    
  catch
    if ishandle(fig); delete(fig); end
    if ishandle(h); close(h);end
    erdlgpls({'Unable to start the Equality GUI' lasterr},[upper(mfilename) ' Error']);
  end
  
else % INVOKE NAMED SUBFUNCTION OR CALLBACK
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = [];
        options.renderer            = 'opengl';%Opengl can be slow on Mac but it's the only renderer that displays alpha.
        options.definitions         = @optiondefs;
        
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
      otherwise
        if nargout == 0;
          %normal calls with a function
          feval(varargin{:}); % FEVAL switchyard
        else
          [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
        end
    end
  catch
    if ~isempty(gcbf);
      set(gcbf,'pointer','arrow');  %no "handles" exist here so try setting callback figure
    end
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end
  
end

%--------------------------------------------------------------------
function varargout = gui_enable(fig,ncomp)
%Initialize the the gui.

%Get handles and save options.
handles = guihandles(fig);
gopts = equalitygui('options');

%Set persistent options.
setappdata(fig,'gui_options',gopts);
%setappdata(fig,'fcn_options',fopts);

ncomp = getappdata(fig,'ncomp');

%Get position.
figpos = get(fig,'position');
figcolor = [.95 .95 .95];
set(fig,'Color',figcolor,'Renderer',gopts.renderer);
myfontsize = getdefaultfontsize;

%Set extra fig properties.
set(fig,'Toolbar','none')

%Add menu items.
hmenu = uimenu(fig,'Label','&File','tag','menu_file');

uimenu(hmenu,'tag','closemenu','Separator','on','label','&Close','callback','equalitygui(''closereq_callback'',gcbo,[],guidata(gcbf),''import'')');

cpanel = uipanel(fig,'tag','concentrations_panel',...
  'units','pixels',...
  'BackgroundColor',figcolor,...
  'title','Concentrations',...
  'position',[6 100 220 100],...
  'fontsize',myfontsize+4);


spanel = uipanel(fig,'tag','spectra_panel',...
  'units','pixels',...
  'BackgroundColor',figcolor,...
  'title','Spectra',...
  'position',[240 100 220 100],...
  'fontsize',myfontsize+4);

ht = 24;
%Create controls for ncomp:
for i = 1:ncomp
  cstr = num2str(i);
  
  h1 = uicontrol('parent', cpanel,...
    'tag', ['pclabel_' cstr],...
    'style', 'text', ...
    'string', cstr, ...
    'units','pixel',...
    'position',[4 20 30 20],...
    'fontsize',myfontsize,...
    'background',figcolor,...
    'userdata',[i 1]);
  h2 = evricopyobj(h1,spanel);
  
  h3 = uicontrol('parent', cpanel,...
    'tag', ['cload_' cstr],...
    'style', 'pushbutton', ...
    'string', 'Load', ...
    'units','pixel',...
    'position',[28 20 45 ht],...
    'background','white',...
    'userdata',[i 2]);
  h4 = evricopyobj(h3,spanel);
  set(h4,'tag',['sload_' cstr]);
  
  h9 = uicontrol('parent', cpanel,...
    'tag', ['cclear_' cstr],...
    'style', 'pushbutton', ...
    'string', 'X', ...
    'units','pixel',...
    'position',[28 20 20 ht],...
    'enable','off',...
    'userdata',[i 3]);
  h10 = evricopyobj(h9,spanel);
  set(h10,'tag',['sclear_' cstr]);
  
  h5 = uicontrol('parent', cpanel,...
    'tag', ['cconstraintslider_' cstr],...
    'style', 'slider', ...
    'min', 0, ...
    'max', 10, ...
    'SliderStep',[.01 .2],...
    'units','pixel',...
    'position',[75 20 100 ht],...
    'background','white',...
    'value',10,...
    'userdata',[i 4]);
  h6 = evricopyobj(h5,spanel);
  set(h6,'tag',['sconstraintslider_' cstr]);
  
  h7 = uicontrol('parent', cpanel,...
    'tag', ['cconstraintval_' cstr],...
    'style', 'edit', ...
    'string', '10', ...
    'fontsize', myfontsize,...
    'units','pixel',...
    'position',[180 20 50 ht],...
    'background','white',...
    'userdata',[i 5]);
  h8 = evricopyobj(h7,spanel);
  set(h8,'tag',['sconstraintval_' cstr]);
  
  h11 = uicontrol('parent', cpanel,...
    'tag', ['div_' cstr],...
    'style', 'frame', ...
    'string', '10', ...
    'units','pixel',...
    'position',[4 20 100 2],...
    'background','white',...
    'userdata',[i 6]);
  h12 = evricopyobj(h11,spanel);
  
  set([h3 h4 h5 h6 h7 h8 h9 h10],...
    'fontsize',myfontsize,...
    'callback','equalitygui(''control_callback'',gcbo,[],guidata(gcbf))')
end


%Apply new.
uicontrol('parent', fig,...
  'tag', 'okbtn',...
  'style', 'pushbutton', ...
  'string', 'OK', ...
  'units', 'pixels', ...
  'position',[100 4 110 30],...
  'fontsize',myfontsize,...
  'callback','equalitygui(''control_callback'',gcbo,[],guidata(gcbf))');

%Cancel
uicontrol('parent', fig,...
  'tag', 'cancelbtn',...
  'style', 'pushbutton', ...
  'string', 'Cancel', ...
  'units', 'pixels', ...
  'position',[206 4 110 30],...
  'fontsize',myfontsize,...
  'tooltipstring','Cance and close window.',...
  'callback','equalitygui(''control_callback'',gcbo,[],guidata(gcbf))');


handles = guihandles(fig);
guidata(fig,handles);

set(fig,'visible','on')

update_callaback(handles)

%--------------------------------------------------------------
function resize_callback(h,eventdata,handles,varargin)
%Resize callback.

ncomp = getappdata(handles.equalitygui,'ncomp');

%Sometimes handles aren't updated so get them manually.
handles = guihandles(h);

if isempty(handles)
  %On some platforms resize is called by openfig before all of controls are
  %created in gui init so just return until handles are available.
  return
end

opts = getappdata(handles.equalitygui, 'gui_options');
set(handles.equalitygui,'units','pixels');

%Get initial positions.
figpos = get(handles.equalitygui,'position');
panelw = max(1,figpos(3)/2-10);
panelh = max(1,figpos(4)-40);

%Panel position.
set(handles.concentrations_panel,'position',[4 38 panelw panelh]);
set(handles.spectra_panel,'position',[panelw+8 38 panelw panelh]);

%All panel controls.
myctrls = [allchild(handles.concentrations_panel); allchild(handles.spectra_panel)];
mygrid  = get(myctrls,'userdata');

%Buttons.
set(handles.okbtn,'position',[figpos(3)-118 4 110 30])
set(handles.cancelbtn,'position',[figpos(3)-232 4 110 30])

%Widths
mywidths  = [30 45 20 60 45 panelw-14];
myheights = [20 20 20 20 22 1];

%Get slider width.
mywidths(4) = max(panelw-(sum(mywidths([1 2 3 5]))+28),mywidths(3));

panelh = panelh-20;

if isempty(mygrid)
  return
end

%Get list and grid.
keepr = ~cellfun('isempty',mygrid);
myctrls = myctrls(keepr);
mygrid  = mygrid(keepr);
mygrid  = cell2mat(mygrid);

for i = 1:length(myctrls)
  thiscomp = myctrls(i);
  thisgrid = mygrid(i,:);
  thispos  = get(thiscomp,'position');
  
  thispos(1) = (4*thisgrid(2));%4*column+sum of column widths.
  if thisgrid(2)>1
    thispos(1) = thispos(1)+sum(mywidths(1:thisgrid(2)-1));
  end
  
  if ismember(thisgrid(2),[2 3])
    thispos(2) = panelh-(thisgrid(1)*34)+3;%Vertical ncomp row.
  elseif thisgrid(2)==5
    thispos(2) = panelh-(thisgrid(1)*34)+2;
  elseif thisgrid(2)==6
    thispos(1) = 4;
    thispos(2) = panelh-(thisgrid(1)*34)-4;
  else
    thispos(2) = panelh-(thisgrid(1)*34);%Vertical ncomp row.
  end
  thispos(3) = mywidths(thisgrid(2));
  thispos(4) = myheights(thisgrid(2));
  set(thiscomp,'position',thispos);
end

%--------------------------------------------------------------------
function control_callback(hObject, eventdata, handles,varargin)
%Update GUI.

ncomp  = getappdata(handles.equalitygui,'ncomp');
mytag  = get(hObject,'tag');
myname = strtok(mytag,'_');
mygrid = get(hObject,'userdata');
parent = get(hObject,'parent');

switch myname
  case 'cancelbtn'
    setappdata(handles.equalitygui,'cancel_push',1)
    uiresume(gcbf)
  case 'okbtn'
    uiresume(gcbf)
  case {'cconstraintslider' 'sconstraintslider'}
    %Update slider val.
    myval = round(100*get(hObject,'value'))/100;
    set(hObject,'value',myval)
    valstr = strrep(myname,'slider','val');
    set(findobj(parent,'tag',[valstr '_' num2str(mygrid(1))]),'String',wtstr(myval))   
    %Ten equals hard constraint (inf).
    if myval==10
      myval = inf;
    end
    if strcmp(get(parent,'tag'),'spectra_panel')
      scwts = getappdata(handles.equalitygui,'scwts');
      scwts(mygrid(1)) = myval;
      setappdata(handles.equalitygui,'scwts',scwts)
    else
      ccwts = getappdata(handles.equalitygui,'ccwts');
      ccwts(mygrid(1)) = myval;
      setappdata(handles.equalitygui,'ccwts',ccwts)
    end
  case {'cconstraintval' 'sconstraintval'}
    %Update slider val.
    mystr = get(hObject,'String');
    if strcmpi(mystr,'Hard')
      mystr = '10';
    end
    if strcmpi(mystr,'None')
      mystr = '0';
    end
    myval = round(100*str2num(mystr))/100;
    myval = max(0,myval);
    myval = min(10,myval);
    sldstr = strrep(myname,'val','slider');
    set(findobj(parent,'tag',[sldstr '_' num2str(mygrid(1))]),'Value',myval)
    set(hObject,'String',wtstr(myval));
    
  case {'sload' 'cload'}
    load_contraints(hObject, eventdata, handles,varargin);
  case 'sclear'
    mysc = getappdata(handles.equalitygui,'sc');
    mysc(mygrid(1),:)=nan(1,size(mysc,2));
    setappdata(handles.equalitygui,'sc',mysc);
    update_callaback(handles)
  case 'cclear'
    mycc = getappdata(handles.equalitygui,'cc');
    mycc(:,mygrid(1))=nan(size(mycc,1),1);
    setappdata(handles.equalitygui,'cc',mycc);
    update_callaback(handles)
end

%--------------------------------------------------------------------
function load_contraints(hObject, eventdata, handles,varargin)
%Load constraings.
% Check data for size, loadings/spectra == var size, scores/concentrations == sample size.
% Check for matrix and try to load from ncomp onward.
% Disable load and enable clear to show data loaded.

ncomp  = getappdata(handles.equalitygui,'ncomp');
mygrid = get(hObject,'userdata');
parent = get(hObject,'parent');
remaining_comps = ncomp-mygrid(1)+1;
isspectra = strcmp(get(parent,'tag'),'spectra_panel');

[rawdata,name,location,rdir] = lddlgpls({'double' 'dataset' 'evrimodel'},'Select Data or Model for Equality Constraint');
if ~isempty(rawdata)
  if ismodel(rawdata)
    if isspectra
      rawdata = rawdata.loadings;
    else
      rawdata = rawdata.scores;
    end
  end    
  dsize = getappdata(handles.equalitygui,'data_size');
  isize = getappdata(handles.equalitygui,'data_size_include');
  include = getappdata(handles.equalitygui,'data_include');

  rsize = size(rawdata);
  if isspectra
    if rsize(2)==dsize(2)
      %Correct size.
    elseif rsize(1)==dsize(2)
      %Transpose to var direction.
      rawdata = rawdata';
    elseif rsize(2)==isize(2) | rsize(1)==isize(2)
      %transposed correct size for INCLUDED
      if rsize(1)==isize(2)
        rawdata = rawdata';
      end
      %correct size for INCLUDED - insert into NaN matrix
      temp = nan(size(rawdata,1),dsize(2));
      temp(:,include{2}) = rawdata;
      rawdata = temp;
    else
      error('Size of contraint data does not match size of spectra.')
    end
    %Check to see if more than one comp can be loaded.
    mysc = getappdata(handles.equalitygui,'sc');
    if size(rawdata,1)>remaining_comps
      error('Too many rows being loaded.')
    end
    mysc(mygrid(1):mygrid(1)+size(rawdata,1)-1,:)=rawdata;
    setappdata(handles.equalitygui,'sc',mysc)
  else
    %Same size as samples.
    if rsize(2)==dsize(1)
      %Transpose to sample direction.
      rawdata = rawdata';
    elseif rsize(1)==dsize(1)
      %Correct size.
    elseif rsize(1)==isize(1) | rsize(1)==isize(2)
      if rsize(1)==isize(2);
        %transposed correct size for INCLUDED
        rawdata = rawdata';
      end
      %correct size for INCLUDED
      temp = nan(dsize(1),size(rawdata,2));
      temp(include{1},:) = rawdata;
      rawdata = temp;
    else
      error('Size of contraint data does not match size of concentration.')
    end
    %Check to see if more than one comp can be loaded.
    mycc = getappdata(handles.equalitygui,'cc');
    if size(rawdata,2)>remaining_comps
      error('Too many columns being loaded.')
    end
    mycc(:,mygrid(1):mygrid(1)+size(rawdata,2)-1)=rawdata;
    setappdata(handles.equalitygui,'cc',mycc);
  end
end
update_callaback(handles)

%--------------------------------------------------------------------
function openhelp_ctrl_Callback(hObject, eventdata, handles)
%Open help page.
evrihelp('equalitygui')

%--------------------------------------------------------------------
function closereq_callback(hObject, eventdata, handles, varargin)
%Open help page.
uiresume(gcf)
delete(gcf)

%--------------------------------------------------------------------
function editoptions(h, eventdata, handles, varargin)
%Edit options using optionsGUI for current analysis.

switch varargin{1}
  case 'gui'
    opts = getappdata(handles.equalitygui,'gui_options');
    outopts = optionsgui(opts);
    if ~isempty(outopts)
      setappdata(handles.equalitygui,'gui_options',outopts);
    end
    
    if ~strcmp(opts.renderer,outopts.renderer)
      %Change renderer.
      set(handles.equalitygui,'renderer',outopts.renderer);
    end
    
  case 'function'
    opts = getappdata(handles.equalitygui,'fcn_options');
    outopts = optionsgui(opts);
    if ~isempty(outopts)
      setappdata(handles.equalitygui,'fcn_options',outopts);
    end
end

%--------------------------------------------------------------------
function update_callaback(handles)
%Update GUI.

ncomp  = getappdata(handles.equalitygui,'ncomp');

mycc = getappdata(handles.equalitygui,'cc');
mysc = getappdata(handles.equalitygui,'sc');

ccwts = getappdata(handles.equalitygui,'ccwts');
ccwts(ccwts==inf)=10;

scwts = getappdata(handles.equalitygui,'scwts');
scwts(scwts==inf)=10;

onclr = [1 1 1];
offclr = [.82 .82 .82];

for i = 1:ncomp
  cstr = num2str(i);
  %Disable/enable buttons for loaded data.
  if all(isnan(mycc(:,i)))
    %Enalbe load.
    set(handles.(['cload_' cstr]),'enable','on','background',onclr)
    set(handles.(['cclear_' cstr]),'enable','off','background',offclr)
  else
    %Enable clear.
    set(handles.(['cload_' cstr]),'enable','off','background',offclr)
    set(handles.(['cclear_' cstr]),'enable','on','background',onclr)
  end
  
  if all(isnan(mysc(i,:)))
    %Enable load.
    set(handles.(['sload_' cstr]),'enable','on','background',onclr)
    set(handles.(['sclear_' cstr]),'enable','off','background',offclr)
  else
    %Enable clear.
    set(handles.(['sload_' cstr]),'enable','off','background',offclr)
    set(handles.(['sclear_' cstr]),'enable','on','background',onclr)
  end
  
  set(handles.(['cconstraintslider_' cstr]),'value',ccwts(i));
  set(handles.(['cconstraintval_' cstr]),'String',wtstr(ccwts(i)));
  
  set(handles.(['sconstraintslider_' cstr]),'value',scwts(i));
  set(handles.(['sconstraintval_' cstr]),'String',wtstr(scwts(i)));
  
end

%-----------------------------------------------------------------
function out = wtstr(val)

if val<=0
  out = 'None';
elseif val<10
  out = num2str(val);
else
  out = 'Hard';
end

%-----------------------------------------------------------------
function out = optiondefs()
defs = {
  %name                    tab              datatype        valid                            userlevel       description
  'renderer'               'Image'          'select'        {'opengl' 'zbuffer' 'painters'}  'novice'        'Figure renderer (selection will affect alpha and performance).';
  
  };
out = makesubops(defs);
