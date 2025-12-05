function varargout = preprocess(varargin)
%PREPROCESS Selection and application of standard preprocessing methods.
% PREPROCESS is a general tool to choose preprocessing steps and to 
% perform the steps on data. It can be used as a graphical interface or
% as a command-line tool.
% To access extensive and more complete help via the wiki type
%   'preprocess help'
% The wiki provides additional and more detailed information on the use 
% of the graphical user interface, lists avaliable methods and provides
% information on user defined preprocessing. The latter shows how custom
% preprocessing can be included with the standard preprocessing and
% accessed via the PREPROCESS GUI.
%
% PREPROCESS has four basic command-line forms briefly outlined below.
%  1) SELECTION OF PREPROCESSING (or preprocessing steps).
%   a) Interactive selection of preprocessing methods:
%        s = preprocess;
%      where the output (s) is a standard preprocessing structure.
%   b) Interactive editing of the input preprocessing structure (s):
%        [s,changed] = preprocess(s);
%      the output (s) is the edited preprocessing structure. Output
%      (changed) is a flag. If == 1 then (s) has been edited else == 0 if not.
%   c) Command line selection of preprocessing methods:
%        s = preprocess('default','methodname'); 
%      This command returns the default structure for method 'methodname'.
%      For a list of valid method names, run
%        preprocess('keywords')
%     
%  2) CALIBRATE: ESTIMATE PRPROCESSING PARAMETERS. Performs preprocessing
%     on a calibration data set and returns preprocessing parameters in a
%     modified preprocessing structure (sp).
%     Inputs are (s) a preprocessing structure [see 1] and (data) the
%     calibration data.
%     Outputs are the preprocessed data (datap) and modified structure (sp).
%     Note that (sp) is used as input with the 'apply' and 'undo' commands
%     described below.
%   a)  [datap,sp] = preprocess('calibrate',s,data);
%     Short cuts for 'mean center' and 'autoscale' are:
%       [datap,sp] = preprocess('calibrate','meancenter',data);
%       [datap,sp] = preprocess('calibrate','autoscale',data);
%     Preprocessing for some multi-block methods require that the y-block
%     be passed also. The appropriate command is
%   b)  [datap,sp] = preprocess('calibrate',s,xblock,yblock);
%
%  3) APPLY: APPLY PREPROCESSING TO NEW DATA. Applies the calibrated 
%     preprocessing in (sp) to new data. Inputs are the calibrated preprocessing
%     structure (sp) [See 2] and the data to be preprocessed (data) [class
%     "double" or "dataset"]. 
%     The output is the preprocessed data (datap) [class "dataset"].
%   a)  datap = preprocess('apply',sp,data);
%
%  4) UNDO: REMOVE PREPROCESSING FROM PREPROCESSED DATA. Removes preprocessing
%     that has been applied to a data set, the 'undo' command is used.
%     Inputs are (sp) the calibrated preprocessing structure [See 2] and
%     the preprocessed data (datap) [class "double" or "dataset"].
%   a)  data = preprocess('undo',sp,datap);
%     The output (data) is (datap) with the preprocessing removed.
%     Note that some preprocessing methods can not be undone and will
%     cause an warning to occur. Warnings can be suppressed using the 
%     command 'undo_silent' instead of 'undo'.
%
%I/O: preprocess help                                      %Provides Detailed help
%I/O:          s = preprocess;                             %Modal GUI to select preprocessing
%I/O:[s,changed] = preprocess(s);                          %Modal GUI to modify preprocessing
%I/O:       list = preprocess('initcatalog');              %Gives a list of available methods
%I/O:              preprocess('keywords')                  %Lists valid method names.
%I/O:          s = preprocess('default','methodname');     %Non-GUI interactive preprocessing selection
%I/O: [datap,sp] = preprocess('calibrate',s,data);         %single-block calibration of preprocessing
%I/O: [datap,sp] = preprocess('calibrate',s,xblock,yblock);%multi-block calibration of preprocessing
%I/O:      datap = preprocess('apply',sp,data);            %apply to new data
%I/O:       data = preprocess('undo',sp,datap);            %undo preprocessing
%I/O:       data = preprocess('undo_silent',sp,datap);     %undo preprocessing (no warnings)
%I/O:  [datap,s] = preprocess(data);                       %Modal GUI to preprocess selected data
%I/O:  [datap,s] = preprocess(data,s);                     %Modal GUI to preprocess selected data
%
%See also: CROSSVAL, PCA, PCR, PLS, PREPROCESSITERATOR, PREPROCATALOG, PREPROUSER

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Include the following in ONLINE HELP:
%  The GUI selection presents a list of available preprocessing methods
%   on the left of a list of selected methods. Select an item from the
%   available methods and click "Add" to move that item to the selected
%   methods list below the currently selected item.
%  Items can be removed from the selected methods list by selecting the
%   item to remove and clicking "Remove". The order of the selected items
%   can be changed using the "Up" and "Down" buttons.
%  Click OK when the desired methods have been selected and ordered. The
%   output of the preprocess GUI is a preprocessing structure which can
%   be used in subsequent calibration and apply or undo calls to preprocess
%   data.

%** User-accessable functions:
%To perform preprocessing
%  calibrate, undo, apply
%To extract preprocessing which can be done once
%  presort
%For catalog manipulation and Stay-Resident GUI calls:
%  setup, initcatalog, addtocatalog, validate,
%To set Applied to a specific function:
%  special, meancenter, autoscale, custom, none,
%  setapplied, update, getapplied,
%To disable or enable a Stay-Resident GUI
%  disable, enable

if nargin == 0  | ~ischar(varargin{1})
  varargin = {'setup', varargin{:}};
end

switch varargin{1}
  case cat(2,evriio([],'validtopics'));
    options = [];
    options.availableview = 1;
    options.fontsize = getdefaultfontsize;
    options.hidden   = {};
    if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return;
  otherwise
    if nargout == 0;
      feval(varargin{:});
    else
      [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    end;
end

%FUNCTIONS/CALLBACKS
% --------------------------------------------------------------------
function [ppout,ppchange,catalog] = setup(varargin)
%setup preprocess
% Optional inputs include:
% (fig)     number of parent.
% (struct)  current applied preprocessing structure. If not provided,
%     preprocess will use the current settings in (fig) or nothing if no fig
%     was provided.
% (data)    dataset object or double ARRAY to which the preprocessing will
%     be applied. May be used by some preprocessing methods for size or
%     other info.
% **The following options each require one additional input value which
%     must immediately follow the property**
% 'name'      set figure name to given string
% 'listchangecallback'  set function to call when the user makes any changes
%           using the preprocess buttons. Only called for user-commanded changes
%           through the use of the GUI buttons.
% 'position'      set figure position (must be followed by a four-element
%                   position vector)
% 'catalog'       set the initial catalog to the given structure (overwrites
%                   any initial catalog)
% 'addtocatalog'  add the given items to the initial catalog (adds to initial catalog)
% 'addtoparent'   adds preprocessing figure handle to parent appdata as field 'preprocess'
% 'nomodal'       used for demo, this disables normal functionality but
%                 will return handle to the preprocessing figure.
% OUTPUT:  The figure number (fig) if a stay-resident GUI or the
%  final preprocessing structure (pp) if this was a one-time GUI
%
% I/O: newpp = setup(fig,struct,PROPERTY,VALUE,...)
% (or) newpp = setup(struct,PROPERTY,VALUE,...)
%
%  examples:
% (1) create a standard one-time preprocess with the standard options
%   pp = setup;
%  pp will be the selected preprocessing items (as a structure which can be
%   passed back to calibrate, for example)
% (2) create a preprocess to associate with your own gui:
%   fig = setup(mygui);
%  fig will be the PreProcessing GUI's handle. PREPROCESS will create an
%  appdata property named "preprocessing" in mygui which contains the most
%  up-to-date version of the preprocessing structure
% (3) create a preprocess for your gui with some additional catalog items:
%   fig = setup(mygui,'addtocatalog',myitems)
%  myitems is a structure which needs to contain at least the fields
%  "description" and "calibrate"

wbarh = waitbar(.1,'Opening Preprocess...');

fig = openfig(mfilename,'new');   %create gui
set(fig,'closerequestfcn',['try;' get(fig,'closerequestfcn') ';catch;delete(gcbf);end'])
figure(wbarh)
%Set size to default but restore x/y (screen) position becuase plots are
%turned off by default and we don't store that information after figure is
%closed.
figpos = get(fig,'position');
oldpos = positionmanager(fig,'preprocess','get');%Position gui from last known position.
if ~isempty(oldpos)
  %   newpos = [oldpos(1:2) figpos(3:4)];
  newpos = oldpos;
else
  centerfigure(fig);
  figpos = get(fig,'position');
  newpos = figpos;
  oldpos = figpos;
end

%Put upper left corner of figure in same position. Need to adjust if
%figure size was different from default when closed.
%newpos(2) = newpos(2)+(oldpos(4)-figpos(4));

set(fig,'position',newpos);
positionmanager(fig,'preprocess','onscreen')

waitbar(.2,wbarh);

figbrowser('addmenu',fig);        %add figbrowser link
handles = guihandles(fig);	      % Generate a structure of handles to pass to callbacks
guidata(fig,handles);             % and save in guidata
setappdata(fig,'custommode',1);   %turn on custom mode (default)
setappdata(fig,'viewexcludeddata',0); %default value for showing excluded data.
setappdata(fig,'viewclasses',0); %default value for showing classes
set(fig,'resize','on'); %Allow resizing.
setappdata(fig,'showppdata',0) %Initialize plotting to off.

set(handles.addbtn,'busyAction','cancel','interruptible','off')  %no interrupt of add

set(fig,'keypressfcn','preprocess(''keypressfcn'',gcbf);')

waitbar(.4,wbarh);

%set default setting for alphabetical button
options = preprocess('options');
if ~iscell(options.hidden)
  setplspref('preprocess','hidden',{});
end
alphabetical_Callback(fig,options.availableview);  %force button to update

initcatalog(fig)                  %initialize catalog
applied            = [];          %initialize currently applied items list
parenthandle       = [];          %parent handle is empty by default
nomodal            = [];          %disable modal behavior
myid               = [];          %ID to data.

returndata         = false;       %normally we return the preprocessing UNLESS the first item in is a dataset

waitbar(.6,wbarh);

k = 1;
while k <= nargin;
  if ~isstruct(varargin{k}) && prod(size(varargin{k}))==1
    if ishandle(varargin{k});
      parenthandle = varargin{k};
    elseif isempty(myid)
      %Using link ID, so set link to data.
      myid = varargin{k};
      setobj('original',handles,myid);
    else
      %y-block
      setobj('other',handles,myid);
    end
  elseif ischar(varargin{k});
    if k == nargin;
      close(wbarh)
      close(fig);
      error('Unmatched property/value pair');
    end;
    switch lower(varargin{k})
      case {'name','closerequestfcn','windowstyle'}
        set(fig,lower(varargin{k}),varargin{k+1});
      case 'nomodal'
        nomodal = varargin{k+1};
      case 'position'
        pos = get(fig,'position');
        set(fig,'position',[varargin{k+1}(1:2) pos(3:4)]);
      case 'catalog'
        clearcatalog(fig)
        addtocatalog(fig,varargin{k+1})
      case 'addtocatalog'
        addtocatalog(fig,varargin{k+1})
      case 'addtoparent'
        %Add fig handle to analysis figure so can perform catalog actions
        %with figure. Only one pp figure will be open at a given time
        %because gui behavior is modal.
        setappdata(varargin{k+1},'preprocess',fig)
    end;
    k = k+1;    %skip over value to next item
  elseif isstruct(varargin{k}) | isempty(varargin{k})
    applied = validate(varargin{k}); %pp struct was input.
  elseif prod(size(varargin{k}))>1
    %add DATASET object (must share locally first)
    mydataset = varargin{k}; %data was input.
    if ~isa(mydataset,'dataset')
      mydataset = dataset(mydataset);
    end

    %decide which block this is.
    if isempty(myid)
      item = 'original';
      if k==1
        returndata = true;
      end
    else
      %NOTE: This will only save one additional data object (e.g. a y-block).
      %If more than one "other" data object is needed then this code should
      %be refactored.
      item = 'other';
    end
    myid = setobjdata(item,handles,mydataset);
    linkshareddata(myid,'add',handles.ok);  %add self-link so we know not to delete when plotgui unlinks between plots

  else
    close(wbarh)
    close(fig);
    error('Unrecognized option for setup or invalid target handle');
  end;
  k = k+1;    %next value
end;

set(fig,'visible','on')
figure(wbarh)
waitbar(.8,wbarh);

mydataset = getobjdata('original',handles);
catalog = getappdata(handles.preprocess,'catalog');

if isempty(nomodal)
  nomodal = 0;
else
  nomodal = 1;
end

%Disable 'show' button if not data available.
if isempty(mydataset)
  if isempty(parenthandle)
    %No data passed and no parent so disable.
    set(handles.showpp,'enable','off')
  end
end

if isempty(parenthandle);
  hasparent = 0;
  parenthandle = fig;
else
  hasparent = 1;
end;

%COULD use something like: findobj(allchild(fig),'-property','fontsize')
%to find all text objects (is this backwards compatible though?)
set([handles.selected handles.available],'fontsize',options.fontsize)

try
  %Try upping font size, this could fail on older Matlab because findobj
  %didn't support -property search. 
  myobjs = findobj(allchild(fig),'-property','fontsize');
  set(myobjs,'fontsize',options.fontsize);
end

setappdata(fig,'parenthandle',parenthandle);   %store parent handle

waitbar(1,wbarh);

if isempty(applied);
  applied = getapplied(handles);         %retrieve any current preprocessing info
end
if ~isempty(applied) & (~isstruct(applied) | ~isfield(applied,'description'));
  close(wbarh)
  error('Invalid preprocessing information');
end;
setapplied(handles,applied);    %update list and buttons

close(wbarh)

set([handles.cancel handles.ok],'visible','on','enable','on');
if ~nomodal
  if hasparent
    %There is a parent present so fig is modal.
    set(fig,'WindowStyle','Modal')
  end
  uiwait(fig);

  if ishandle(handles.preprocess);
    ppout = getapplied(handles);
    ppchange = 1;
    catalog = getappdata(handles.preprocess,'catalog');
    
    if returndata & isshareddata(myid)
      mydataset = myid.object;  %grab shared data version of this data
    end
    
    positionmanager(handles.preprocess,'preprocess','set');%Save position
    delete(handles.preprocess); %Use delete here to get around 'close()' problem in ML 6.5.
  else
    ppout = applied; %figure closed? fallback on initial applied list
    ppchange = 0;
  end;
  
  if returndata
    %pass back preprocessed data as 1st output, and preprocessing as 2nd
    if isempty(ppout)
      ppchange = ppout;
      ppout = mydataset;
    else
      ppchange = ppout;
      ppout = preprocess('calibrate',ppout,mydataset);
    end
  end
  
  if nargout == 0
    clear ppout ppchange catalog  %no outputs? clear variables
  end
else
  ppout = fig;
end

% --------------------------------------------------------------------
function keylist = keywords(varargin)
% return list of valid method keywords

list = initcatalog(varargin{:});
for k = 1:length(list);
  if ~strcmp(lower(list(k).description),lower(list(k).keyword))
    keylist{k,1} = [list(k).keyword '       [' list(k).description ']'];
  else
    keylist{k,1} = [list(k).description];
  end
end
% keylist = {list.keyword}';

if nargout == 0;
  disp(keylist);
end

% --------------------------------------------------------------------
function catalog=initcatalog(fig)
% add standard items to the catalog and check to see if the
% "preprouser" function exists. If so, try to add its output to
% the catalog too.
% The "preprouser" function can be defined by the user to
%  always make certain custom preprocessing options available
% It should return an appropriate structure (see validate)

if nargin==0;     %return catalog
  fig = 0;
  setappdata(0,'catalog',[]);
else
  handles = guidata(fig);
  if ~isstruct(handles) | ~isfield(handles,'preprocess');
    error('Handle must be to a valid preprocess figure')
  end;
end

%define loop item
pp.description = '[] Loop...';
pp.calibrate = '[data,pp] = preproloop(pp,data,index);';
pp.tooltip   = 'Loop over one or more preprocessing items until results converge';
preprocess('addtocatalog', fig, pp);

%add favorites
fav = userfavorites;
for j=1:length(fav)
  addtocatalog(fig,fav(j));
end

if exist('preprocatalog','file')
  preprocatalog(fig);
end

list = evriaddon('preprocess');
for j=1:length(list);
  feval(list{j},fig);                %add user items to catalog
end

%add items in preprocatalog.mat if they exist
pcmat = evriwhich('preprocatalog.mat');
if ~isempty(pcmat);
  try
    newitems = load(pcmat);
  catch
    if isempty(getappdata(0,'preprocatalog_failure'))
      evrierrordlg(sprintf('Could not read preprocatalog.mat'),'Preprocess Catalog Problem')
    end
    setappdata(0,'preprocatalog_failure',1)
    newitems = struct([]);
  end
  for fn = fieldnames(newitems)';
    try
      preprocess('addtocatalog',fig,newitems.(fn{:}));
    catch
      if isempty(getappdata(0,'preprocatalog_failure'))
        evrierrordlg(sprintf('Could not add preprocessing item "%s" from preprocatalog.mat',fn{:}),'Preprocess Catalog Problem')
      end
      setappdata(0,'preprocatalog_failure',1)
    end
  end
end

if nargout == 1;
  catalog = getappdata(fig,'catalog');
end

% --------------------------------------------------------------------
function savecatalog(fig,catalog)

setappdata(fig,'catalog',catalog);

% %make sure parent catalog is updated
% parenthandle = getappdata(fig,'parenthandle');
% if ~isempty(parenthandle) & ishandle(parenthandle)
%   while parenthandle ~=0 & ~strcmp(get(parenthandle,'type'),'figure')
%     parenthandle = get(parenthandle,'parent');
%   end
%   mycat = getappdata(parenthandle,'preprocesscatalog');
%   if ~isempty(mycat)
%     setappdata(parenthandle,'preprocesscatalog',catalog);
%   end
% end


% --------------------------------------------------------------------
function addtocatalog(fig,varargin)
% add item(s) to catalog
%
%I/O:  addtocatalog(fig, Description, Calibrate_Cell, Apply_Cell, Undo_Cell,...
%        Out, SettingsGUI, SettingsOnAdd, UsesDataset, CalOutputs)
% (or) addtocatalog(fig, item)
%   where (item) is a structure containing the fields:
%      description, calibrate, apply, undo, out, settingsgui, ...
%        settingstoadd, usesdataset, caloutputs
% (or) addtocatalog(fig, selected)
%   to updated gui display of items and select the specified item
%   (numerical index into catalog). If selected is omitted, update of
%   screen is done only)
%
%   Calibrate, apply and undo can be cells of cells. Any single cell line will be evaled.
%    Any multiple element cells will are assumed to be the actual calibarate or apply line.

if fig ~= 0;
  if ishandle(fig);
    handles = guidata(fig);
  else
    handles = [];
  end
  if ~isstruct(handles) | ~isfield(handles,'preprocess');
    error('Handle must be to a valid preprocess figure')
  end;
end

catalog = getappdata(fig,'catalog');    %retrieve current catalog

selected = 1;  %item we'll have selected when done
if length(varargin)==1 & isnumeric(varargin{1})
  %user passed # to select as second input...
  selected = varargin{1};
elseif ~isempty(varargin)
  if length(varargin) > 1;
    item.description   = varargin{1};
    item.calibrate     = varargin{2};
    if length(varargin)>2; item.apply         = varargin{3}; end;
    if length(varargin)>3; item.undo          = varargin{4}; end;
    if length(varargin)>4; item.out           = varargin{5}; end;
    if length(varargin)>5; item.settingsgui   = varargin{6}; end;
    if length(varargin)>6; item.settingsonadd = varargin{7}; end;
    if length(varargin)>7; item.usesdataset   = varargin{8}; end;
    if length(varargin)>8; item.caloutputs    = varargin{9}; end;
    if length(varargin)>9; item.keyword       = varargin{10}; end
    if length(varargin)>10; item.userdata      = varargin{11}; end

  else
    if ~isstruct(varargin{1});
      error('Must provide at least a description string and a calibrate cell')
    else
      item = varargin{1};
    end;
  end;

  %error if these items are supplied
  if ~isfield(item,'description');
    error(['Field "description" required for preprocessing catalog entry (unknown entry not added)']);
  end;
  if ~isfield(item,'calibrate');
    error(['Field "calibrate" required for preprocessing catalog entry (item ' item.description ' not added)']);
  end;

  %now add it
  if isempty(catalog);
    catalog = validate(item);           %validate will assure all the required fields are set one way or another
  else
    catalog(end+1:end+length(item)) = validate(item);
  end;

  if fig~=0;
    setappdata(handles.available,'category','');
  end
end

%sort list as needed
[list,order] = sort(lower({catalog.description}));
catalog = catalog(order);

savecatalog(fig,catalog);
if fig~=0;
  %hide items the user has asked to hide
  hidden = getfield(preprocess('options'),'hidden');
  if ~isempty(hidden)
    hide = find(ismember({catalog.keyword},hidden));
    for j=hide
      catalog(j).category = 'Hidden';
    end
  end

  %get current view settings
  mode = getappdata(handles.alphabetical,'mode');
  switch mode
    case {1 2}
      %create appropriately-ordered list of categories. Otherwise-defined categories will always go at end
      catlist = {'Favorites' 'Transformations' 'Filtering' 'Normalization' 'Scaling and Centering'};
      categories = {catalog.category};
      catlist = [catlist setdiff(unique(categories),[catlist 'Hidden'])];
      if ~isempty(hidden)
        %make sure 'Hidden' is at end
        catlist = [catlist 'Hidden'];
      end

      %get current selected category (if any)
      selectedcategory = getappdata(handles.available,'category');

      %run through all categories and insert items from that category into
      %description cell for use in listbox (including a map back to the catalog
      %of available items)
      desc = {};
      listmap = [];
      for cind = 1:length(catlist)
        incat = find(ismember(categories,catlist(cind)));
        if isempty(incat); continue; end

        catdesc = ['--- ' catlist{cind} ' ---'];

        if mode==1  %SHOW ALL
          if ~isempty(desc)
            desc = [desc {' '}];
            listmap = [listmap 0];
          end
          desc = [desc {catdesc}];
          listmap = [listmap 0];
          if ~isempty(strfind(lower(catdesc),'hidden')) & ~strcmpi(catdesc,selectedcategory)
            %if this is the hidden group, don't even show it when we're
            %showing all
            listmap(end) = -1;  %indicate this can be expanded by clicking
            continue
          elseif ~isempty(strfind(lower(catdesc),'hidden')) & strcmpi(catdesc,selectedcategory) & selected==1
            %showing hidden but first item is selected? force first hidden
            %item to be selected (so we scroll down to hidden category when
            %it is opened)
            selected = length(listmap)+1;
          end
          desc = [desc {catalog(incat).description}];
          listmap = [listmap incat];

        else %SHOW ONE

          %decide if we should show this category
          showcategory = strcmp(catdesc,selectedcategory);

          desc = [desc {catdesc}];
          listmap = [listmap -1];
          if showcategory
            %show it - include all items from category
            desc = [desc {' '}];
            listmap = [listmap 0];

            desc = [desc {catalog(incat).description}];
            if selected==1;
              selected = length(listmap)+1;  %make fist item in category selected
            end
            listmap = [listmap incat];

            if cind<length(catlist);
              desc = [desc {' '}];
              listmap = [listmap 0];
            end
          end

        end
      end
    otherwise
      %standard alphabetical list
      
      hiddenselected = ~isempty(strfind(getappdata(handles.available,'category'),'Hidden'));

      ishidden = ismember({catalog.category},'Hidden');
      show = 1:length(catalog);
      if ~hiddenselected
        show(ishidden) = [];       %without hidden ones
      end
      
      desc = {catalog(show).description};
      listmap = show;
      
      if ~hiddenselected  & any(ishidden)
        desc = [desc {' ' '--- Show Hidden ---'}];
        listmap(end+[1:2]) = [0 -1];
      end

      
  end

  %update listbox with new list
  selected = max(1,min(length(desc),selected));
  set(handles.available,'string',desc,'enable','on','value',selected);
  setappdata(handles.available,'listmap',listmap);
  set(handles.addbtn,'enable','on');
  available_Callback(handles.available, [], handles);
end

%---------------------------------------------------------------------
function alphabetical_Callback(fig,mode)

%get button setting
handles   = guidata(fig);

if nargin<2
  %no mode passed by caller? use button appdata
  mode = getappdata(handles.alphabetical,'mode');
  if isempty(mode)
    mode = 0;
  end

  %one input? cycle through modes
  mode = mode+1;
  if mode==3;
    mode = 0;
  end
end

%update button and gui
setappdata(handles.alphabetical,'mode',mode);
switch mode
  case 0
    %alphabetical
    set(handles.alphabetical,'string','A-Z');
  case 1
    %categorical All
    set(handles.alphabetical,'string','All');
  case 2
    %categorical ONE
    set(handles.alphabetical,'string','One');
end

%store as default value
setplspref('preprocess','availableview',mode);

catalog = getappdata(fig,'catalog');    %retreive current catalog
if ~isempty(catalog);
  %refresh list
  addtocatalog(fig);  %without item to add, acts as "refresh"
end

% --------------------------------------------------------------------
function clearcatalog(fig,varargin)
% clear entire catalog.. (fig) is the preprocess figure
% I/O:  clearcatalog(fig)

handles = guidata(fig);
if ~isstruct(handles) | ~isfield(handles,'preprocess');
  error('Handle must be to a valid preprocess figure')
end;

catalog = [];     %catalog? what catalog? We don't need no stinking catalog!

savecatalog(fig,catalog);
set(handles.available,'string',cell(0),'enable','off','value',1,'tooltip','');
set(handles.addbtn,'enable','on');


% --------------------------------------------------------------------
function shell = default(varargin)
% Returns default preprocessing structure
%  with optional input (keyword) those preprocessing types are
%  returned. E.G. out = default('mean center','normalize');
% I/O:  shell = default(keyword)

if nargout == 1;
  if nargin >0;
    if length(varargin)==1 & iscell(varargin{1});
      varargin = varargin{1};     %cell list to expand
    end
      type = locateinlist(initcatalog,varargin{:});
  else
    type = validate;
  end
  shell = validate(type);
end

% --------------------------------------------------------------------
function type = locateinlist(catalog,varargin)
% Locates and extracts preprocessing structures from catalog by keyword
% string(s)
%I/O: pp = locateinlist(catalog,'method_1','method_2',...)

type = [];
list = lower({catalog.keyword});
for ind = 1:length(varargin);
  varargin{ind} = lower(varargin{ind});
  temp = find(strcmp(varargin{ind},list));
  if isempty(temp);
    %couldn't find match in standard keywords, look in description
    temp = find(strcmp(varargin{ind},lower({catalog.description})));
  end
  if isempty(temp);
    %couldn't find match in description, look in de-spaced keywords
    for k=1:length(list);
      list{k}(list{k}==' ') = [];
    end
    temp = find(strcmp(varargin{ind},list));
  end
  if isempty(temp);
    %couldn't find match in de-spaced keywords, look in de-spaced description
    list = lower({catalog.description});
    for k=1:length(list);
      list{k}(list{k}==' ') = [];
    end
    temp = find(strcmp(varargin{ind},list));
  end
  if isempty(temp)
    error(['Unrecognized preprocessing keyword ''' lower(varargin{ind}) '''']);
  else
    toadd = catalog(temp(1));
    if strcmpi(toadd.category,'favorites') & isfield(toadd.userdata,'keyword')
      %if this is a favorite, extract the ACTUAL preprocessing from the
      %userdata (if that appears to be a preprocessing - it should always
      %be, but adding the isfield test to just be SURE to avoid error
      %messages)
      toadd = toadd.userdata;
    end
    if isempty(type)
      type = toadd;
    else
      type(end+(1:length(toadd))) = toadd;
    end
  end
end

% --------------------------------------------------------------------
function list = validate(list)
% validate a preprocessing item list (check fields)
% checks structure fields for:
%  (1) existance
%  (2) appropriate info (when possible)
%  (3) order of appearance in structure (so that we can copy a single item from one struct. to another)
%
% I/O:  list = validate(list)

if nargin == 0;
  list.description = '';
  list.calibrate   = [];
else
  if isempty(list);
    return
  end
end

if iscell(list) | ischar(list)
  %if character or cell array, use default to create structures
  list = default(list);
end

%empty structure for reordered fields
reorder = struct('description',[],'calibrate',[],'apply',[],'undo',[],...
  'out',[],'settingsgui',[],'settingsonadd',[],'usesdataset',[],'caloutputs',[],'keyword',[],'tooltip',[],'category',[],'userdata',[]);

if length(list)>1 & size(list,1)>1
  %multi-row? (array or column vector)
  list = list(:)';
end

for ind = 1:length(list);

  %assign defaults for unsupplied items
  if ~isfield(list(ind),'description');
    list(ind).description   = '(unknown)';
  end;

  if ~isfield(list(ind),'calibrate') & nargin > 0;
    error(['Invalid preprocessing structure (no calibrate field found)']);
  end

  if ~isfield(list(ind),'calibrate') | isempty(list(ind).calibrate)
    list(ind).calibrate     = cell(0);
    list(ind).apply         = cell(0);
    list(ind).undo          = cell(0);
    list(ind).description   = '';
  end;
  if ~isa(list(ind).calibrate,'cell');
    list(ind).calibrate     = {list(ind).calibrate};
  end

  if ~isfield(list(ind),'apply') | isempty(list(ind).apply);
    list(ind).apply         = list(ind).calibrate;
  end;
  if ~isa(list(ind).apply,'cell');
    list(ind).apply         = {list(ind).apply};
  end

  if ~isfield(list(ind),'undo') | isempty(list(ind).undo);
    list(ind).undo          = cell(0);
  end;
  if ~isa(list(ind).undo,'cell');
    list(ind).undo          = {list(ind).undo};
  end

  if ~isfield(list(ind),'out') | isempty(list(ind).out);
    list(ind).out           = cell(0);
  end;
  if ~isa(list(ind).calibrate,'cell');
    list(ind).out           = {list(ind).out};
  end
  if length(list(ind).out) == 1 & isempty(list(ind).out{1});
    list(ind).out           = cell(0);
  end;

  if ~isfield(list(ind),'settingsgui') | isempty(list(ind).settingsgui) | ~isa(list(ind).settingsgui,'char');
    list(ind).settingsgui   = '';
  end;
  if ~isempty(list(ind).settingsgui) & ~exist(list(ind).settingsgui,'file');
    warning('EVRI:badppsetgui',['SettingsGUI ' list(ind).settingsgui ' not found'])
    list(ind).settingsgui   = '';
  end;

  if ~isfield(list(ind),'settingsonadd') | isempty(list(ind).settingsonadd) ...
      | ~isa(list(ind).settingsonadd,'double') | prod(size(list(ind).settingsonadd))~= 1 ...
      | ~ismember(list(ind).settingsonadd,[1 0]);
    list(ind).settingsonadd = 0;
  end;

  if ~isfield(list(ind),'usesdataset') | isempty(list(ind).usesdataset) ...
      | ~isa(list(ind).usesdataset,'double') | prod(size(list(ind).usesdataset))~= 1 ...
      | ~ismember(list(ind).usesdataset,[1 0]);
    list(ind).usesdataset   = 0;
  end;

  if ~isfield(list(ind),'caloutputs');
    list(ind).caloutputs    = 0;     %default is zero
  end
  if ~isempty(list(ind).caloutputs) & (~isa(list(ind).caloutputs,'double') ...
      | prod(size(list(ind).caloutputs))~= 1) | list(ind).caloutputs<0 ...
      | ~isfinite(list(ind).caloutputs);
    list(ind).caloutputs    = [];     %default is to determine from apply
  end;

  if ~isfield(list(ind),'keyword');
    list(ind).keyword       = list(ind).description;     %default is to determine from discription
  end
  if isempty(list(ind).keyword) | ~isa(list(ind).keyword,'char');
    list(ind).keyword       = list(ind).description;     %default is to determine from apply
  end;

  if ~isfield(list(ind),'tooltip');
    list(ind).tooltip     = list(ind).description;
  end

  if ~isfield(list(ind),'category') || isempty(list(ind).category)
    list(ind).category = 'Other';
  end

  if ~isfield(list(ind),'userdata');
    list(ind).userdata    = [];     %default is empty
  end

  %compare field orders, reorder if not valid
  listfields    = fieldnames(list);
  reorderfields = fieldnames(reorder);
  if ~strcmp([listfields{:}],[reorderfields{:}]);
    reorder(ind) = reorder(1);      %make a fake entry
    %And then copy fields into the entry (which is in the CORRECT order)
    for feyld = reorderfields';
      reorder(ind) = setfield(reorder(ind),feyld{:},getfield(list(ind),feyld{:}));
    end
  else
    reorder = list;
  end

end

list = reorder;

% --------------------------------------------------------------------
function varargout = special(mode,fig,varargin)
% add / create special item to applied
% If called with no figure # (fig), this will just return the appropriate
%  structure; with a figure #, it will set the applied field of
%  that preprocess to the given mode (mode) as per:
% Modes include: 'none', 'meancenter', 'autoscale', 'custom'
%  The first three store the current list of applied variables
%   and then set the applied to the given mode (creates a structure
%   with all the appropriate fields for the given mode).
%  The "custom" mode restores the list of applied variables
%   which was stored when one of the other three modes was called.
%   This allows the user to call one of the special modes, then return
%   the gui to it's original state before the call.
%  (s) is the one optional output. It will contain the structure
%   appropriate for the called mode.
%
% I/O:  s = special(mode,fig)

if nargin>1 & ishandle(fig);
  handles = guidata(fig);
  if ~isstruct(handles) | ~isfield(handles,'preprocess');
    error('Handle must be to a valid preprocess figure')
  end;
else
  fig = [];
end

switch mode
  case 'none'
    applied = [];

  case 'meancenter'
    clear applied
    applied     = mncnset('default');

  case 'autoscale'
    clear applied
    applied     = autoset('default');

  case 'custom'
    if ishandle(fig);
      if ~getappdata(fig,'custommode');
        setappdata(fig,'custommode',1);
        applied = getappdata(fig,'customapplied');    %retrieve any stored custom info
      else
        %already in custom mode, don't do anything
        setappdata(fig,'custommode',1);
        return;
      end;
    else
      aplied = [];
    end

  otherwise
    error(['Unrecognized special preprocessing mode ' mode ])
end

applied = validate(applied);

if ishandle(fig);
  if ~strcmp(mode,'custom');                    %something other than cusom?
    if getappdata(fig,'custommode');              %doing custom applied right now?
      setappdata(fig,'customapplied',getapplied(handles));    %store custom applied info for restore later
      setappdata(fig,'custommode',0);             %turn off custom mode
    end
  end

  setapplied(handles,applied);
end

if nargout == 1;
  varargout = {applied};
end

% --------------------------------------------------------------------
function varargout = meancenter(varargin)
applied = special('meancenter',varargin{:});
if nargout == 1;
  varargout = {applied};
end

function varargout = autoscale(varargin)
applied = special('autoscale',varargin{:});
if nargout == 1;
  varargout = {applied};
end

function varargout = custom(varargin)
applied = special('custom',varargin{:});
if nargout == 1;
  varargout = {applied};
end

function varargout = none(varargin)
applied = special('none',varargin{:});
if nargout == 1;
  varargout = {applied};
end

% --------------------------------------------------------------------
function loadapplied(fig)
% load preprocessing structure from workspace or file

new = lddlgpls('struct','Load Preprocessing Structure...');
if isempty(new)   %cancel or load of empty... don't do anything
  return
end
if ~isstruct(new) | any(~ismember({'description','calibrate','apply'},fieldnames(new)));
  erdlgpls('Not a recognized PreProcessing Structure','Unable to load','modal');
  return
end
setapplied(fig,new, 0)

% --------------------------------------------------------------------
function saveapplied(fig)
% save preprocessing structure to workspace or file

applied = getapplied(fig);
svdlgpls(applied,'Save Preprocessing Structure...','applied');

% --------------------------------------------------------------------
function disable(fig)
% disable all objects on a given preprocess figure

if ~isempty(fig) & ishandle(fig);% & (isempty(getappdata(fig,'isdisabled')) | ~getappdata(fig,'isdisabled'));
  set(allchild(fig),'enable','off');
  setappdata(fig,'isdisabled',1);
end

% --------------------------------------------------------------------
function enable(fig)
% reenable all [appropriate] objects on a given preprocess figure

if ~isempty(fig) & ishandle(fig) & getappdata(fig,'isdisabled');
  set(allchild(fig),'enable','on');
  setappdata(fig,'isdisabled',0);
  update(fig);   %update selection buttons/etc.
end

% --------------------------------------------------------------------
function setapplied(handles,applied,selected)
% set the preprocessing info associated with prepro figure

if nargin < 3;
  selected = length(applied)-1;
end

if selected > length(applied)+1
  selected = length(applied)+1;
end

if selected < 1
  selected = 1;
end

if ~isstruct(handles) & ishandle(handles);
  handles = guidata(handles);
end

if ~isstruct(handles) | ~isfield(handles,'preprocess');
  error('Handle must be to a valid preprocess figure')
end;

setappdata(getappdata(handles.preprocess,'parenthandle'),'preprocessing',validate(applied)); %store back in parent.

if isempty(applied);
  set(handles.selected, ...
    'string','<none>', ...
    'value',1, ...
    'enable','inactive');
else

  strng = {applied.description '<end>'};

  %handle loop indenting
  desc = char(strng');
  indent = cumsum((desc(:,1)=='[') - (desc(:,1)==']')) - (desc(:,1)=='[');
  for j=1:length(strng);
    strng{j} = [blanks(indent(j)*3) strng{j}];
  end

  set(handles.selected, ...
    'string',strng, ...
    'value',selected, ...
    'enable','on');
end;

setappdata(handles.selected,'moddate',now);  %note when we changed this

selected_Callback(handles.selected, [], handles);   %update selection buttons/etc.

axismenu_Callback(handles.selected, [], handles), [];  %update plots (if shown)


% --------------------------------------------------------------------
function update(h)
% update selected list if someone has changed it externally

handles = guidata(h);
if ~isstruct(handles) | ~isfield(handles,'preprocess');
  error('Handle must be to a valid preprocess figure')
end;
applied = getapplied(handles);

if isempty(applied);
  set(handles.selected, ...
    'string','<none>', ...
    'value',1, ...
    'enable','inactive');
else
  set(handles.selected, ...
    'string',{applied.description '<end>'}, ...
    'value',1, ...
    'enable','on');
end;

selected_Callback(handles.selected, [], handles);   %update selection buttons/etc.

if getappdata(handles.preprocess,'isdisabled');
  disable(handles.preprocess);
end

% --------------------------------------------------------------------
function applied = getapplied(handles)
% get the preprocessing info associated with prepro figure

if ~isstruct(handles);
  if ishandle(handles);
    handles = guidata(handles);
  else
    error('Must pass valid handle or handles structure to getapplied');
  end;
end;

applied = getappdata(getappdata(handles.preprocess,'parenthandle'),'preprocessing');

% --------------------------------------------------------------------
function [mydataset,supportingds,myid] = getdataset(parenthandle,handles)
% EXTERNAL callers use this to get the current dataset (if any) associated
% with prepro figure. It is NOT (and should not be) used by any internal
% functions. They should all use getobj and/or getobjdata with a specific
% keyword.

mydataset = [];
supportingds = {};  %other datasets to pass back with the requested object (pass y back with x, for eg)

if nargin == 0 | isempty(parenthandle) | ~ishandle(parenthandle)
  fig = gcbf;
else
  fig = parenthandle;
end

if isempty(fig);
  return
end
if nargin < 2
  handles = guidata(fig);
end

if ~isfield(handles,'preprocess');
  %not a preprocessing figure?
  return
end

%See if original data was saved in setup function.
[mydataset,myid] = getobjdata('original',handles);
if ~isempty(mydataset)
  %if we found something, grab any supporting data too
  supportingds = getobjdata('other',handles);
  if ~iscell(supportingds); supportingds = {supportingds}; end  %just to be sure
end

% --------------------------------------------------------------------
function available_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.available.

if strcmp(get(handles.preprocess,'selectiontype'),'open')
  set(handles.preprocess,'selectiontype','normal');
  add_Callback(handles.addbtn, [], handles);
  return
end

%update tooltip to match currently selected item
catalog = getappdata(handles.preprocess,'catalog');    %retrieve current catalog
listmap = getappdata(handles.available,'listmap');
value   = get(handles.available,'value');
toadd   = listmap(value);
selcategory = getappdata(handles.available,'category');

if toadd==0 & value>1;
  %check if we're on a separator (forward to real item)
  lastvalue = getappdata(handles.available,'lastvalue');
  while listmap(value)==0
    if lastvalue>value & value>2
      value = value-1;
    else
      value = value+1;
      if value>length(listmap); value=length(listmap); break; end
    end
  end
  toadd = listmap(value);
  set(handles.available,'value',value);
end
setappdata(handles.available,'lastvalue',value);

if toadd==-1 && length(listmap)>1
  str = get(handles.available,'string');
  if ~strcmp(str{value},selcategory);
    %haven't yet selected this category header?
    setappdata(handles.available,'category',str{value});
    addtocatalog(handles.preprocess);  %force update for new category
    return
  end
end

if toadd>0
  set(handles.available,'tooltip','');  %NOTE: Disabeled. This was confusing becuase the selected item might not be visible. Plus we're using the tooltip below.
  set(handles.methodinfo,'string',catalog(toadd).tooltip,'backgroundcolor',[1 1 .7],'userdata',catalog(toadd));
  set(handles.addbtn,'enable','on');
  set(handles.hidebtn,'enable','on');
  hidden = getfield(preprocess('options'),'hidden');
  if isempty(hidden) | ~ismember(catalog(toadd).keyword,hidden)
    if ~strcmpi(catalog(toadd).category,'favorites')
      %standard item (not favorite or hidden)
      set(handles.hidebtn,'string','Hide');
    else
      %in the favorites group
      set(handles.hidebtn,'string','Delete');
    end
  else
    %in the hidden group
    set(handles.hidebtn,'string','Unhide');
  end

else
  set(handles.addbtn,'enable','off');
end

% --------------------------------------------------------------------
function hide_Callback(h, varargin)

handles = guidata(h);
catalog = getappdata(handles.preprocess,'catalog');    %retrieve current catalog
listmap = getappdata(handles.available,'listmap');
value   = get(handles.available,'value');
toadd   = listmap(value);

if isempty(toadd) | toadd==0; return; end
item = catalog(toadd);
hidden = getfield(preprocess('options'),'hidden');
if ~isempty(hidden) & ismember(item.keyword,hidden)
  %remove from hidden category
  setplspref('preprocess','hidden',setdiff(hidden,item.keyword));
elseif ~strcmpi(item.category,'Favorites')
  %regular item - hide it
  setplspref('preprocess','hidden',union(hidden,item.keyword));
else
  %favorite - delete it
  
  isok = evriquestdlg('Delete this "Favorite Preprocessing Combination" item, or Hide it?','Delete Favorite','Delete','Hide','Cancel','Delete');
  if isempty(isok) | strcmpi(isok,'Cancel')
    return
  end
  if strcmpi(isok,'Delete')
    %delete item
    fav = userfavorites;
    %locate method and delete it
    match = find(ismember(lower(item.keyword),lower({fav.keyword})));
    if ~isempty(match)
      match = match(1);
      fav(match) = [];
      userfavorites(fav)  %save favorites
    end
    %drop the match from the gui catalog
    catalog(toadd) = [];
    savecatalog(handles.preprocess,catalog);
  else
    %HIDE item
    setplspref('preprocess','hidden',union(hidden,item.keyword));
  end
end  

addtocatalog(handles.preprocess,value);  %force update



% --------------------------------------------------------------------
function selected_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.selected.

if strcmp(get(handles.preprocess,'selectiontype'),'open')
  set(handles.preprocess,'selectiontype','normal');
  settings_Callback(handles.settings, [], handles);
  return
end

applied = getapplied(handles);
selected = get(h,'value');

if isempty(applied);
  set(handles.settings,'enable','off');
  set(handles.removebtn,'enable','off');
  set(handles.favorite,'enable','off');
else
  set(handles.favorite,'enable','on');
  if selected > length(applied);
    set(handles.removebtn,'enable','off');
  else
    set(handles.removebtn,'enable','on');
  end;

  if selected > length(applied) | isempty(applied(selected).settingsgui);
    set(handles.settings,'enable','off');
  else
    set(handles.settings,'enable','on');
  end;
  
  if handles.available~=gcbo & handles.addbtn~=gcbo
    if selected <=length(applied)
      tt = applied(selected).tooltip;
      if ~isempty(applied(selected).settingsgui)
        tt = [tt ' (double-click list item to change settings)'];
      end
      set(handles.methodinfo,'string',tt,'backgroundcolor',[.7 1 .7],'userdata',applied(selected));
    else
      set(handles.methodinfo,'string','(End of Preprocessing)','backgroundcolor',[.7 .7 1],'userdata',[]);
    end
  end

end;

%calculate indent info
if ~isempty(applied);
  desc = char({applied.description}');
  indent = cumsum((desc(:,1)=='[') - (desc(:,1)==']')) - (desc(:,1)=='[');
else
  indent = [];
end

%determine up and down button status
if selected >= length(applied)...
    | ((applied(selected).description(1)==']' | applied(selected).description(1)=='[') ...
    & (applied(selected+1).description(1)==']' | applied(selected+1).description(1)=='['));
  set(handles.down,'enable','off');
else
  set(handles.down,'enable','on');
end

if selected == 1 | selected > length(applied)...
    | ((applied(selected).description(1)==']' | applied(selected).description(1)=='[') ...
    & (applied(selected-1).description(1)==']' | applied(selected-1).description(1)=='['));
  set(handles.up,'enable','off');
else
  set(handles.up,'enable','on');
end

% --------------------------------------------------------------------
function remove_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.removebtn.

selected = get(handles.selected,'value');
applied = getapplied(handles);  %retrieve currently applied items

if applied(selected).description(1)=='[';
  %remove a starting loop item
  desc = char({applied.description}');
  indent = cumsum((desc(:,1)=='[') - (desc(:,1)==']')) - (desc(:,1)=='[');
  toremove = [selected min(find(indent==indent(selected) & [1:length(indent)]'>selected))];
elseif applied(selected).description(1)==']';
  %remove an ending loop item
  desc = char({applied.description}');
  indent = cumsum((desc(:,1)=='[') - (desc(:,1)==']')) - (desc(:,1)=='[');
  toremove = [selected max(find(indent==indent(selected) & [1:length(indent)]'<selected))];
else
  toremove = selected;
end
applied = applied(setdiff(1:length(applied),toremove));

setappdata(handles.preprocess,'custommode',1);

setapplied(handles,applied,selected);

% --------------------------------------------------------------------
function add_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.addbtn.

listmap = getappdata(handles.available,'listmap');
value   = get(handles.available,'value');
toadd   = listmap(value);
if isempty(toadd) | toadd<=0; return; end  %non-real entry, just exit

catalog = getappdata(handles.preprocess,'catalog');    %retrieve current catalog
selected = get(handles.selected,'value');
applied = getapplied(handles);  %retrieve currently applied items

item = catalog(toadd);
%check for special loop item
if strcmp(lower(item.description),'[] loop...');
  item = default;
  item(1).description = '[ Repeat the following...';
  item(1).calibrate   = '[loopstart';
  item(1).usesdataset = 1;

  item(2) = default;
  item(2).description = '] Until Converged';
  item(2).calibrate   = ']loopend';
  item(2).settingsgui = 'preproloop';
  item(2).settingsonadd = 1;
end

%get settings from user if required
keep = true(1,length(item));
for j=1:length(item);
  if item(j).settingsonadd
    temp = settings_Callback(handles.selected,[],handles,item(j));
    if ~isempty(temp)
      item(j) = temp;
    else
      keep(j) = false;
    end
  end
end
item = item(keep);  %throw away items that had SettingsOnAdd errors
if isempty(item)
  return;
end

for j=length(item):-1:1;
  if strcmpi(item(j).category,'favorites')
    %item is a "favorite"? extract userdata which contains actual content
    extracted = item(j).userdata;
    if iscell(extracted) | ischar(item)
      item = preprocess('default',item);
    end
    item = [item(1:j-1) extracted item(j+1:end)];
  end
end

if isempty(applied);    %nothing added yet, this is the first
  applied = item;
else
  if selected > length(applied);
    applied(end+1:end+length(item)) = item;
  else
    applied = applied([1:selected-1 selected*ones(1,length(item)) selected:end]);  %make a spot in list
    applied(selected:(selected+(length(item)-1))) = item;     %insert new item(s)
  end
end

setappdata(handles.preprocess,'custommode',1);

setapplied(handles,applied,selected+1);

% --------------------------------------------------------------------
function varargout = settings_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.settings.

if nargin<4
  selected = get(handles.selected,'value');
  applied = getapplied(handles);  %retrieve currently applied items
  passed  = false;
else
  %they passed a prepro item to work with (rather than use currently
  %selected in GUI)
  selected = 1;
  applied = varargin{1};
  passed  = true;
end

if selected>length(applied) | isempty(applied(selected).settingsgui)
  return
end

failed = false;
try
  newapplied = feval(applied(selected).settingsgui, applied(selected));
  if ~isempty(newapplied)
    applied(selected) = validate(newapplied);
  else
    failed = true;
  end
catch
  erdlgpls(lasterr,'Settings');
  failed = true;
end;

setappdata(handles.preprocess,'custommode',1);

if ~passed
  %store back into selected methods 
  setapplied(handles,applied,selected);
else
  %return (unles we failed)
  if failed
    applied = [];
  end
  varargout = {applied};
end

% -----------------------------------------------------------
function savefavorite(h,applied)

handles = guidata(h);
if nargin<2
  applied = getapplied(handles);  %retrieve currently applied items
end

if isempty(applied)
  return;
end

%get current list
catalog = getappdata(handles.preprocess,'catalog');    %retrieve current catalog
fav = catalog([ismember(lower({catalog.category}),'favorites')]);
descriptions = lower({fav.description});
keywords     = lower({fav.keyword});

%ask for new item name
repeat = true;
info = {applied(1).description applied(1).tooltip};
if length(applied)>1
  info{1} = [ applied(1).keyword sprintf(' + %s',applied(2:end).keyword) ];
  info{2} = [ applied(1).description sprintf(' + %s',applied(2:end).description) ];
end
while repeat
  info = inputdlg({'Favorite Description:','Tooltip:'},'Favorite As...',1,info);
  if isempty(info)
    return;
  end
  if isempty(info{1})
    evrierrordlg('Non-empty "description" must be entered','Save As Favorite');
    continue;
  end
  info{3} = regexprep(info{1},' ','');
  if ismember(lower(info{1}),descriptions) | ismember(lower(info{3}),keywords)
    ovr = evriquestdlg('A method with this description and/or keyword already exists. Overwrite existing method?','Method Exists','Overwrite','Rename','Cancel','Overwrite');
    if isempty(ovr) | strcmpi(ovr,'cancel')
      return;
    end
    if strcmpi(ovr,'Rename')
      continue
    else
      repeat = false;
    end
  else
    repeat = false;
  end
end

%create method
p=default;
p.description = info{1};
p.calibrate = {'[data,out{1}] = preprocess(''calibrate'',userdata,data);'};
p.apply = {'data = preprocess(''apply'',out{1},data);'};
p.undo = {'data = preprocess(''undo'',out{1},data);'};
p.out = {};
p.settingsgui = 'preprocess';
p.settingsonadd = 0;
p.usesdataset = 1;
p.caloutputs = 1;
p.keyword = info{3};
p.tooltip = info{2};
p.category = 'Favorites';
p.userdata = applied;
newfav = p;

%figure out where to put it in current catalog
match = find(ismember(lower(info{1}),descriptions) | ismember(lower(info{2}),keywords));
if ~isempty(match)
  %drop the match
  catalog(match) = [];
  savecatalog(handles.preprocess,catalog);
end
%add the new one...
addtocatalog(handles.preprocess,newfav);

%save to preprofavorites file
fav = userfavorites;
%add new method or overwrite existing method in favorites file
match = find(ismember(lower(info{1}),lower({fav.description})) | ismember(lower(info{2}),lower({fav.keyword})));
if ~isempty(match)
  %replace existing
  match = match(1);
else
  %add on end
  match = length(fav)+1;
end
fav(match) = newfav;
userfavorites(fav)  %save favorites


% -----------------------------------------------------------
function [favorites,f] = userfavorites(favorites)
%load or save file of favorites (returns empty if no file found when
%loading - creates file in preferences folder if none found when saving)
%I/O: favorites = userfavorites;   %load current favorites
%I/O: userfavorites(favorites);    %save new favorites

favs_prefdir_file = fullfile(prefdir,'preprofavorites.mat');
f = fullfile(evridir,'preprofavorites.mat');

if exist(favs_prefdir_file,'file')
  %Move preprofavorites.mat file to evri home directory
  movefile(favs_prefdir_file,f)
end
if nargin==0
  %LOAD favorites
  if exist(f,'file')
    favorites = load(f);
    if isfield(favorites,'favorites')
      %extract from variable
      favorites = favorites.favorites;
    else
      %no "favorites" variable in file? do new list
      favorites = default;
      favorites = favorites([]);
    end
  else
    %no file, do new list
    favorites = default;
    favorites = favorites([]);
  end
else
  %SAVE favorites
  save(f,'favorites')
  clear favorites
end

% -----------------------------------------------------------
function keypressfcn(h)

handles = guidata(h);
c = double(get(h,'currentcharacter'));
if length(c)~=1 | ~ischar(c); return; end

switch c
  case 27  %esc
    cancel_Callback(h, [], handles)
end

% --------------------------------------------------------------------
function down_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.down.

selected = get(handles.selected,'value');
applied = getapplied(handles);  %retrieve currently applied items

applied = applied([1:selected-1 selected+1 selected selected+2:end]);

setappdata(handles.preprocess,'custommode',1);

setapplied(handles,applied,selected+1);

% --------------------------------------------------------------------
function up_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.up.

selected = get(handles.selected,'value');
applied = getapplied(handles);  %retrieve currently applied items

applied = applied([1:selected-2 selected selected-1 selected+1:end]);

setappdata(handles.preprocess,'custommode',1);

setapplied(handles,applied,selected-1);

% --------------------------------------------------------------------
function ok_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.ok.

%unlink from all data we might have linked to
linkshareddata(handles.preprocess,'removeall');
uiresume(handles.preprocess)

% --------------------------------------------------------------------
function cancel_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.cancel.

linkshareddata(handles.preprocess,'removeall');
positionmanager(handles.preprocess,'preprocess','set');%Save position
delete(handles.preprocess)

% --------------------------------------------------------------------
function varargout = calibrate(varargin)
% calibrate (first-time run of preprocessing)

if nargin == 0; evrihelp(mfilename); return; end

mydataset = [];
otherdata = {};
applied = [];

if nargin >= 1;
  if (isa(varargin{1},'struct') | isempty(varargin{1}));
    applied      = varargin{1};
  elseif isa(varargin{1},'char');
    applied = locateinlist(initcatalog,varargin{1});
  elseif isa(varargin{1},'cell') & isa(varargin{1}{1},'char')
    applied = locateinlist(initcatalog,varargin{1}{:});   %list of preprocessing strings
  else
    error('Unrecognized preprocessing structure or keyword');
  end
end
if nargin >= 2
  mydataset = varargin{2};
  if ~isa(mydataset,'dataset');
    mydataset    = dataset(mydataset);
  end
end
if nargin >= 3;
  otherdata = varargin(3:end);
end

if isempty(mydataset) | isempty(mydataset.include{1});
  error('Must supply data to calibrate')
end;

if isempty(mydataset.include{1});
  error('All dataset samples excluded; preprocessing cannot be performed')
end

if isempty(mydataset.include{2});
  error('All dataset variables excluded; preprocessing cannot be performed')
end

if isempty(applied);      %nothing to do?!? just return dataset
  varargout{1} = mydataset;
  varargout{2} = applied;
  return
end;

originaldata = mydataset;

applied = validate(applied);      %make sure all required fields are there

datasize  = size(mydataset.data);
include    = mydataset.include;
data      = mydataset;
useinclud = 0;

preproitem = 1;
while preproitem <=length(applied);

  userdata = applied(preproitem).userdata;
  if ~applied(preproitem).usesdataset
    if isa(data,'dataset')    %do we have a dataset right now? then convert it
      mydataset = data;
      %do we have a subset of include?
      useinclud = (sum(datasize) ~= length([include{:}]));  % = 1 if include isn't all of data
      data = mydataset.data;      %get all of data to pass to preprocessing
      if useinclud
        data = subsref(data,substruct('()',include));   %pass only the important subset
      end
    end
  else
    if ~isa(data,'dataset')
      if ~useinclud
        mydataset.data = data;      %save back to mydataset
      else
        mydataset.data(:) = nan;
        mydataset.data(include{:}) = data;
        myinc          = mydataset.include;
        for dims = 1:length(datasize);
          if length(myinc{dims})~=length(include{dims}) | sum(myinc{dims})~=sum(include{dims}) | prod(myinc{dims})~=prod(include{dims});
            mydataset.include{dims} = include{dims};      %reassign include
          end
        end;
      end;
      data = mydataset;     %this item can handle a data set, pass the whole thing
    end;

    useinclud = 0;        %and note that we didn't have to use include (it handles it for us)
  end;

  if applied(preproitem).description(1)=='['  %start of loop item
    %extract items inside loop
    desc      = char({applied.description}');
    indent    = cumsum((desc(:,1)=='[') - (desc(:,1)==']')) - (desc(:,1)=='[');
    endmark   = min(find(indent==indent(preproitem) & [1:length(indent)]'>preproitem));
    if isempty(endmark)
      error('Missing end of loop');
    end
    loopitems = applied(preproitem+1:endmark-1);

    %extract convergence criteria, call preprocess, store results in end of loop item
    [data,applied(endmark).out{1}] = loop(loopitems,data,applied(endmark).userdata);

    %skip to endmark
    preproitem = endmark;

  else
    %normal preprocessing item...

    % determine how many outputs we need to ask for
    if isempty(applied(preproitem).caloutputs);
      for apply = [applied(preproitem).apply applied(preproitem).undo];
        if ~isempty(apply) & iscell(apply{1});          %locate actual function call if multiple-command apply cell
          for ind = 1:length(apply);
            if iscell(apply{ind}) & length(apply{ind}) > 1;
              apply = apply{ind};
              break;
            end;
          end;
        end;
        maxout = 0;
        for ind = 1:length(apply);
          if isstr(apply{ind}) & length(apply{ind})>4;
            switch apply{ind}(1:4);
              case '*out'       %search for out strings and then grab "n" from '*out{n}' in string
                maxout = max([maxout str2num(apply{ind}(6:end-1))]);
            end;
          end;
        end;
      end
    else
      maxout = applied(preproitem).caloutputs;
    end

    calibrate = applied(preproitem).calibrate; %pull out cell (we don't want to modify calibrate directly
    % because we're going to save everything back with "out" modified in a moment and calibrate shouldn't change)

    if ~isempty(calibrate);   %break out into next preproitem if this one was empty
      if ~iscell(calibrate{1}); calibrate = {calibrate}; end;

      for calibrateitem = 1:length(calibrate);
        if ~iscell(calibrate{calibrateitem}) | length(calibrate{calibrateitem}) == 1;
          if iscell(calibrate{calibrateitem}); calibrate{calibrateitem}=calibrate{calibrateitem}{:}; end;
          %execute single-item lines as written
          out = applied(preproitem).out;
          try
            [data,out,userdata,include,otherdata] = safe_eval(calibrate{calibrateitem},data,out,userdata,include,otherdata);
          catch
            lerr = lasterror;
            lerr.message = ['Error Performing Preprocessing' 10 'Method: ' applied(preproitem).description 10 lerr.message];
            rethrow(lerr)
          end
          applied(preproitem).out = out;
        else
          %old unsupported cell-type call
          error(['Error Performing Preprocessing' 10 'Method: ' applied(preproitem).description 10 'Multi-cell format no longer supported'])
        end
      end

      applied(preproitem).userdata = userdata;
    end
    clear out userdata
  end
  preproitem = preproitem + 1;  %move to next preproitem
end

%expand loops into explict instructions
if ~isempty(applied);
  desc = char({applied.description}');
  while any(desc(:,1)=='[');
    indent  = cumsum((desc(:,1)=='[') - (desc(:,1)==']')) - (desc(:,1)=='[');
    loopstart = min(find(desc(:,1)=='['));
    loopend   = min(find(indent==indent(loopstart) & [1:length(indent)]'>loopstart));
    expanded  = applied(loopend).out{1};
    applied   = [applied(1:loopstart-1) expanded applied(loopend+1:end)];  %replace with expanded items
    desc      = char({applied.description}');  %get new description string
  end
end

%reinsert data into dataset (if last method left it out of a DSO) and call
%"apply" to apply to excluded samples (only)
if ~isa(data,'dataset')
  if useinclud
    mydataset.data(:) = nan;
    mydataset.data(include{:}) = data;
  else
    mydataset.data = data;     % save back to mydataset
  end
else
  mydataset = data;     %return dataset (from prepro routine which works on datasets)
end
clear data
if length(include{1})<datasize(1)  %excluded samples?
  excluded       = setdiff(1:datasize(1),include{1});
  predset        = nindex(originaldata,excluded);
  predset.include{1} = 1:size(predset,1);
  predset        = preprocess('apply', applied, predset);
  mydataset.data = nassign(mydataset.data,predset.data,excluded);
end

if nargout > 1;
  %save for output to caller
  varargout{2} = applied;
end;

if nargout > 0;
  varargout{1} = mydataset;
end

% --------------------------------------------------------------------
function mydataset = undo(varargin)
% undo (previous application of preprocessing)

if nargin == 0; evrihelp(mfilename); return; end

if nargout == 0;
  error('preprocess undo requires an output');
end

mydataset = apply(varargin{:},'undo');   %call apply with "undo" flag on end!

% --------------------------------------------------------------------
function mydataset = undo_silent(varargin)
% undo (previous application of preprocessing)

if nargin == 0; evrihelp(mfilename); return; end

if nargout == 0;
  error('preprocess undo requires an output');
end

mydataset = apply(varargin{:},'undo_silent');   %call apply with "undo" flag on end!

% --------------------------------------------------------------------
function [mydataset,applied] = apply(varargin)
% apply (subsequent applications of preprocessing)
%I/O: result = apply(preprostructure,data)

mydataset    = [];
applied      = [];
undo         = 0;

if nargin == 0; evrihelp(mfilename); return; end

if nargin >= 1;
  if (isa(varargin{1},'struct') | isempty(varargin{1}));
    applied      = varargin{1};
  else
    error('Unrecognized preprocessing structure');
  end
end
if nargin >= 2
  mydataset = varargin{2};
  if ~isa(mydataset,'dataset');
    mydataset    = dataset(mydataset);
  end
end
if nargin >= 3
  if isa(varargin{3},'char') & (strcmpi(varargin{3},'undo') | strcmpi(varargin{3},'undo_silent'))
    undo = 1;
    silent_undo = strcmpi(varargin{3},'undo_silent');      
  else
    error('Too many inputs for Apply / Undo');
  end
end

if nargout == 0;
  error('preprocess apply requires an output');
end

if isempty(mydataset);
  error('Must supply data to apply or undo')
end;

if isempty(mydataset.include{2});
  error('All dataset variables excluded; preprocessing cannot be performed')
end

if isempty(applied);      %nothing to do?!? just return dataset
  return
end;

%verify we've got all the out info we need (i.e. was calibrate done?)
%(do this before we bother to get any subset of data)
for preproitem = 1:length(applied);
  if isempty(applied(preproitem).caloutputs);
    for apply = [applied(preproitem).apply applied(preproitem).undo];
      if ~isempty(apply) & iscell(apply{1});          %locate actual function call if multiple-command apply cell
        for ind = 1:length(apply);
          if iscell(apply{ind}) & length(apply{ind}) > 1;
            apply = apply{ind};
            break;
          end;
        end;
      end;
      for ind = 1:length(apply);
        if isstr(apply{ind}) & strncmp('*out',apply{ind},4);    %if it makes use of "out"
          if isempty(applied(preproitem).out);                  % and we don't have any out info,
            error('Preprocessing must be calibrated before applying or undoing');      %give error
          end;
        end;
      end;
    end
  else
    if applied(preproitem).caloutputs > length(applied(preproitem).out);    %if it makes use of more "out" than we have
      error('Preprocessing must be calibrated before applying or undoing');      %give error
    end
  end
end

if ~undo;
  itemorder = 1:length(applied);
else
  itemorder = length(applied):-1:1;     %do the preprocessing items in reverse order if undoing
end

%copy out include field
include   = mydataset.include;
datasize = size(mydataset.data);

data = mydataset;
useinclud = 0;
for preproitem = itemorder;
  if ~applied(preproitem).usesdataset
    if isa(data,'dataset'); %is it a dataset now? convert it
      mydataset = data;
      %do we have a subset of include?
      useinclud = (sum(datasize(2:end)) ~= length([include{2:end}]));  % = 1 if include isn't all of data
      data = mydataset.data;      %get all of data to pass to preprocessing
      if useinclud
        data = subsref(data,substruct('()',{':' include{2:end}}));   %pass only the important subset
      end
    end
  else  %need a dataset...
    if ~isa(data,'dataset');  %don't have a dataset?
      if ~useinclud
        mydataset.data = data;      %save back to mydataset
      else
        mydataset.data(:) = nan;
        mydataset.data(:,include{2:end}) = data;
      end;
      for dims = 1:length(datasize);
        myinc = mydataset.include;
        if length(myinc{dims})~=length(include{dims}) | prod(myinc{dims})~=prod(include{dims}) | sum(myinc{dims})~=sum(include{dims});
          mydataset.include{dims} = include{dims};      %reassign include
        end
        data = mydataset;     %this item can handle datasets, just pass the whole thing
      end;

      useinclud = 0;        %and note that we didn't have to use include (it handles it for us)
    end
  end;

  if ~undo;
    apply = applied(preproitem).apply;
  else
    apply = applied(preproitem).undo;
    if ~silent_undo & isempty(applied(preproitem).undo) & ~isempty(applied(preproitem).apply);
      warning('EVRI:badppundo',[ applied(preproitem).description ' could not be undone'])
    end
  end

  if ~isempty(apply);   %break out into next preproitem if this one was empty
    if ~iscell(apply{1}); apply = {apply}; end;

    for applyitem = 1:length(apply);
      userdata = applied(preproitem).userdata;
      if ~iscell(apply{applyitem}) | length(apply{applyitem}) == 1;

        if iscell(apply{applyitem}); apply{applyitem}=apply{applyitem}{:}; end;

        %execute single-item lines as written
        out = applied(preproitem).out;
        try
          [data,out,userdata,include] = safe_eval(apply{applyitem},data,out,userdata,include);
        catch
          if ~undo
            lerr = lasterror;
            lerr.message = ['Error Performing Preprocessing' 10 'Method: ' applied(preproitem).description 10 lerr.message];
            rethrow(lerr)
          elseif ~silent_undo
            warning('EVRI:badppundo',[ applied(preproitem).description ' could not be undone'])
          end
        end
        applied(preproitem).out = out;

        %items which matter: applied, mydataset, preproitem, apply, itemorder, undo, applyitem, parenthandle, useinclud
        %   user can modify: data, out, userdata

      else
        %old unsupported cell-type call
        error(['Error Performing Preprocessing' 10 'Method: ' applied(preproitem).description 10 'Multi-cell format no longer supported'])
      end
    end    
  end

end

if ~isa(data,'dataset');  %last item didn't use a dataset? we need to convert back...
  if ~useinclud
    mydataset.data = data;      %save back to mydataset
  else
    mydataset.data(:) = nan;
    mydataset.data(:,include{2:end}) = data;
 end
  myinc = mydataset.include;
  for dims = 1:ndims(mydataset.data);
    if length(myinc{dims})~=length(include{dims}) | sum(myinc{dims})~=sum(include{dims}) | prod(myinc{dims})~=prod(include{dims});
      mydataset.include{dims} = include{dims};      %reassign include
    end
  end
else
  mydataset = data;      %save back to mydataset
end

%------------------------------------------------------------
function [data,pp_all] = loop(pp,data,convsettings)
% perform loop of preprocessing items until convergence of "data"
% inputs are: pp (preprocessing do be looped over (pp), data to preprocess
% (data), and convsettings is set by the preproloop GUI (convsettings)
%   convsettings(1) is the relative change below which the loop should end
%   convsettings(2) is the absolute change below which the loop should end
%   convsettings(3) is the max number of iterations to perform

%setup loop
converged = 0;
iter      = 0;
pp_all    = [];
delta     = inf;
incl      = data.include;
temp      = data.data(incl{:});
n         = sum(temp(:).^2);     %used to calculate relative change
lastdata  = data;

%do loop
while ~converged
  iter = iter+1;
  if iter>convsettings(3);    %reached max iterations
    break
  end

  [data,pp_one] = calibrate(pp,data);
  delta = (lastdata.data(incl{:}) - data.data(incl{:})).^2;
  delta = sum(delta(:));

  if (delta/n)<convsettings(1) | delta<convsettings(2);
    %no significant change in that last step
    data      = lastdata;  %reset back to last step's result
    break
  end

  %store the preprocessing from this last step
  pp_all   = [pp_all pp_one];
  lastdata = data;

end


%------------------------------------------------------------
function [data,out,userdata,include,otherdata] = safe_eval(apply,data,out,userdata,include,otherdata)
%limits scope to keep application functions from accidentally modifying
%other variables they aren't allowed to work with.

check_safety(apply);
eval(apply);

%------------------------------------------------------------
function check_safety(apply)
%function to test a given apply/calibrate/undo command for safety. Various
%functions which are NOT permitted in callbacks are caught here
%Note that this function does NOT distinguish between text inside strings,
%variable name, and function calls since the user could use a combination
%of these in a malicious way

%the following keywords and commands are considered unsafe and we will NOT
%execute them in any case. Note that any commend which CONTAINS these
%keywords will also not function (e.g. "csvwrite")
badcommands = {...
  'pearl' 'system' 'unix' 'winopen' 'dos' 'fopen' 'open' ...
  'eval' 'feval' 'delete' 'rmdir' 'mkdir' 'save' 'saveas' ...
  'write' 'keyboard' 'input' '!'...
  };

apply = lower(apply);  %base test on lower case only
%use of regexprep and lower is ~25% faster than regexpi so we use the fast
%method to check for offense, then the slow method if we found an offense
if ~strcmp(regexprep(apply,badcommands,''),apply)
  %identify which command was in offense and grab text context
  starts   = regexpi(apply,badcommands);
  offense  = min(find(~cellfun('isempty',starts)));
  mybad    = badcommands{offense};
  position = min(starts{offense});
  context  = apply(max(1,position-25):min(end,position+25));
  
  %throw diagnostic error
  error('Illegal use of keyword "%s" (context: "...%s...")',mybad,context)
end

%------------------------------------------------------------
function [pre,post] = presort(pp)
% identifies preprocessing items which are independent of the rows being
% analyzed and can be applied once in advance of other iterative steps
% (e.g. cross-validation)

pre = [];
post = pp;
if isempty(pp); return; end

caloutputs = {pp.caloutputs};
%Convert "unknown number of outputs" to "1" (assume it is NOT pre-processable)
% (This also handles loops which have empty caloutput fields and should NOT be preprocessed)
for j=1:length(caloutputs)
  if isempty(caloutputs{j})
    caloutputs{j} = 1;
  end
end
caloutputs = [caloutputs{:}];  %convert to array

firstpost = min(find(caloutputs));
if ~isempty(firstpost) & firstpost>1;
  pre = pp(1:firstpost-1);
  post = pp(firstpost:end);
end

%------------------------------------------------------------
function show_Callback(h, eventdata, handles, varargin)
% Show button callback. Expands window and plots data and pp data or shrinks
% window (turns off plotting of pp data).

%Find/save status of show (is show turned on or off).
showpp = getappdata(handles.preprocess,'showppdata');
parenthandle = getappdata(handles.preprocess,'parenthandle');
figpos = get(handles.preprocess,'position');

%Toggle showpp for button push.
if isempty(showpp) | showpp == 0
  %Turning on pp plots.
  setappdata(handles.preprocess,'showppdata',1);
  showpp = 1;
  %Upsize figure if it is smaller than minimum so user will see affects of
  %button push.
  if figpos(3)<443
    figpos(3)=443;
  end
  if figpos(4)<532
    yshift = 532-figpos(4);
    figpos(2) = figpos(2)-yshift;
    figpos(4)=532;
  end
  set(handles.preprocess,'position',figpos); %Calls resize.
  %Move onto screen in case upsizing pushed off.
  positionmanager(handles.preprocess,'onscreen')

elseif showpp == 1
  %Turning off pp plots.
  setappdata(handles.preprocess,'showppdata',0);
  showpp = 0;

  %Retract figure (bring buttom up to default position).
  newbottom = getpos(handles.frame5,'bottom');
  figpos(4) = figpos(4) - newbottom;
  figpos(2) = figpos(2) + newbottom;
  set(handles.preprocess,'position',figpos); %Calls resize.
end

if showpp
  ds = getobjdata('original',handles);

  %populate dropdown menus, if more than 2 them switch to multiway.
  dsdim = ndims(ds);
  if dsdim<3
    %2D
    xlist = {'Samples' 'Variables'};
    ylist = {'Data' 'Mean' 'StdDev' 'Mean+StdDev'};
    defaultx = 2;
    if strcmpi(ds.type,'image')
      xlist{1} = 'Image';
    end
  else
    %Greater than 2d
    xlist = '';
    for i = 1:dsdim
      xlist = [xlist {['Dim ' num2str(i)]}];
    end
    ylist = {'Data' 'Mean'};
    defaultx = 2;
  end
  if defaultx~=2 | size(ds,1)<1000
    defaulty = 1;  %Dat is standard default
  else
    defaulty = 2;  %too many items? view the MEAN instead of the data
  end
  set(handles.showxaxis,'String',xlist,'Value',min(defaultx,length(xlist)));
  set(handles.showyaxis,'String',ylist,'Value',min(defaulty,length(ylist)));
  %call plotgui with axes
  handles = guihandles(handles.preprocess); %Refresh handles.
end
axismenu_Callback(handles.preprocess, [], handles, 1)


%------------------------------------------------------------
function axismenu_Callback(h, eventdata, handles, varargin)
%All plotgui calls are from here.
%varargin{1} is boolean for whether or not to replot first (original data)
%axes. Default is to not replot original data.

if nargin == 4 & varargin{1}
  plotoriginal = 1;
else
  plotoriginal = 0;
end

viewexcld = getappdata(handles.preprocess,'viewexcludeddata');
viewcls   = getappdata(handles.preprocess,'viewclasses');

if getappdata(handles.preprocess,'showppdata')
  try
  xval = get(handles.showxaxis, 'Value') - 1;%X is zero indexed with 0 = index.
  yval = get(handles.showyaxis, 'Value');%Y is one indexed.
  parenthandle = getappdata(handles.preprocess,'parenthandle');

  ds           = getobjdata('original',handles);
  supportingds = getobjdata('other',handles);
  if ~iscell(supportingds)
    supportingds = {supportingds};
  end
  ds_id = getobj('original',handles);

  if strcmp(ds_id.object.type,'image') & evriio('mia') & xval==0
    isimage = true;
    pg_method = @plotgui_plotimage;
  else
    isimage = false;
    pg_method = @plotgui_plotscatter;
  end

  ax1 = findobj(handles.preprocess,'tag','rawaxes');
  ax2 = findobj(handles.preprocess,'tag','ppaxes');

  if isempty(ax1) || isempty(ax2)
    resize(handles)
    ax1 = findobj(handles.preprocess,'tag','rawaxes');
    ax2 = findobj(handles.preprocess,'tag','ppaxes');
  end

  if plotoriginal
    axes(ax1); cla;
    try
      opts = plotgui('options');
      opts.plotby = 0;
      opts.viewclasses = viewcls;
      opts.viewexcludeddata = viewexcld;
      opts.axismenuindex = {xval yval []};
      opts.axismenuvalues = {ds_id.object.axisscalename{1+xval} '' ''};
      if isimage; opts.asimage = ds_id.object.imagesize; end
      pg_method(handles.preprocess,ds_id.object,opts)
    catch
    end
    set(handles.preprocess,'CloseRequestFcn','closereq')
    set(ax1,'tag','rawaxes')
  end
  %Apply pp to data and plot on second axis.
  axes(ax2); cla;
  pp =  getappdata(parenthandle,'preprocessing');

  %check if we NEED to recalculate
  moddate  = getappdata(handles.selected,'moddate');  %note when we last changed selected
  lastcalc = getappdata(handles.preprocess,'lastppds');
  [ppds ppds_id] = getobjdata('ppds',handles);

  osc_true = osc_show(pp);
  
  if isempty(ppds) | isempty(lastcalc) | isempty(moddate) | moddate>lastcalc
    %yes, recalculate
    try
      ppwb = waitbar(.5,'Applying Preprocessing...');
      if ~osc_true
          ppds = preprocess('calibrate',pp,ds,supportingds{:});
      else
          analysis_handle = ancestor(parenthandle, 'figure')
          yds = analysis('getobjdata','yblock',analysis_handle)
          ppds = preprocess('calibrate',pp,ds,yds);
      end
        
        waitbar(1,ppwb)
      close(ppwb)
    catch
      erdlgpls(lasterr,[upper(mfilename) ' Error'])
      ppds = dataset([]);
      close(ppwb)
    end
    %store info as to when we last calculated this data
    setappdata(handles.preprocess,'lastppds',now);
    %setappdata(handles.preprocess,'ppds',ppds);
    ppds_id = setobjdata('ppds',handles,ppds);
  end
  drawnow
  try
    opts = plotgui('options');
    opts.viewexcludeddata = viewexcld;
    opts.viewclasses = viewcls;
    opts.plotby = 0;
    opts.axismenuindex = {xval yval []};
    opts.axismenuvalues = {ppds_id.object.axisscalename{1+xval} '' ''};
    if isimage; opts.asimage = ppds_id.object.imagesize; end
    pg_method(handles.preprocess,ppds_id.object,opts)
  catch
  end
  setappdata(ax2,'matlab_graphics_resetplotview',[]);  %clear any zoom setting
  set(handles.preprocess,'CloseRequestFcn','closereq')
  set(ax2,'tag','ppaxes')

  %Clear axis labels
  for i = {ax1 ax2}
    set(get(i{:},'XLabel'),'String','')
    set(get(i{:},'YLabel'),'String','')
  end
  %Need to get title handle first to fix R13 bug.
  x1title = get(ax1,'Title');
  set(x1title,'String','Raw Data','fontsize',getdefaultfontsize,'fontweight','bold','tag','rawdatatitle');
  x2title = get(ax2,'Title');
  set(x2title,'String','Preprocessed Data','fontsize',getdefaultfontsize,'fontweight','bold','tag','ppdatatitle');
  
  if checkmlversion('>=','7')
    if ~isimage
      linkaxes([ax1 ax2],'x');
    else
      linkaxes([ax1 ax2],'xy');
      axis(ax1,'image');
      axis(ax2,'image');
    end
  end
  
  catch
  end
end
%------------------------------------------------------------c
function showexcluded_Callback(h, eventdata, handles, varargin)
showincld = getappdata(handles.preprocess,'viewexcludeddata');
if isempty(getappdata(handles.showexcluded,'color'))
  setappdata(handles.showexcluded,'color',get(handles.showexcluded,'backgroundcolor'))
end
if showincld
  setappdata(handles.preprocess,'viewexcludeddata',0);
  set(handles.showexcluded,'backgroundcolor',getappdata(handles.showexcluded,'color'))
else
  setappdata(handles.preprocess,'viewexcludeddata',1);
  set(handles.showexcluded,'backgroundcolor',getappdata(handles.showexcluded,'color')*.8)
end
axismenu_Callback(handles.preprocess, [], handles, 1)

%------------------------------------------------------------c
function showclasses_Callback(h, eventdata, handles, varargin)
showclas = getappdata(handles.preprocess,'viewclasses');
if isempty(getappdata(handles.showclasses,'color'))
  setappdata(handles.showclasses,'color',get(handles.showclasses,'backgroundcolor'))
end
if showclas
  setappdata(handles.preprocess,'viewclasses',0);
  set(handles.showclasses,'backgroundcolor',getappdata(handles.showclasses,'color'))
else
  setappdata(handles.preprocess,'viewclasses',1);
  set(handles.showclasses,'backgroundcolor',getappdata(handles.showclasses,'color')*.8)
end
axismenu_Callback(handles.preprocess, [], handles, 1)

%--------------------------------------------------------------
function resize_callback(h,eventdata,handles,varargin)

if nargin<4
  %Have varargin{1} as flag for retract figure when closing showpp.
  varargin{1} = 0;
end
%Mac resize problem workaround.
handles = guihandles(h);
if ~ispc & checkmlversion('<','7.10')
  %Seems to be fixed in newer versions Matlab so don't run through this
  %code for 2010a and newer. This code causes problems in 2011b on Mac.
  count = 1;
  while 1
    figsize1 = get(handles.preprocess,'Position');
    pause(1);
    figsize2 = get(handles.preprocess,'Position');
    if figsize1 == figsize2
      break
    elseif count == 100
      break
    end
    count = count + 1;
  end
end

resize(handles,varargin{1})

%------------------------------------------------------------
function resize(handles,retract)
%If showpp = off then expand top controls as expected.
%If showpp = on, retract top to default height/y position and realocate all
%remaining space to bottom plots.
%
%NOTE: The order in which controls are moved and sized can make a
%differnece in how they get spaced. When making changes to this code be
%aware of this.

%Find/save status of show (is show turned on or off).
showpp = getappdata(handles.preprocess,'showppdata');

if isempty(showpp)
  showpp = 0;
end

%get current figure size/position
set(handles.preprocess,'units','pixels');
figpos = get(handles.preprocess,'position');%[left, bottom, width, height]
ofigpos = figpos;%Keep original figure pos.

%Handle heights and y postions first then adjust widths/x.

%Spoof minimum height.
defaultfigheight = 268;
defaultfigheightpp = 264;


if figpos(4)<=defaultfigheight
  %Less than default height so render controls off screen.
  heightadjust = figpos(4)-defaultfigheight; %Will be negative.
  figpos(4) = defaultfigheight;
elseif showpp
  %Showing pp plots (and figure is larger than default) so controls should
  %be default height/y position (i.e., moved up on figure).
  heightadjust = figpos(4)-(defaultfigheight); %Will be positive.
  figpos(4) = defaultfigheight+defaultfigheightpp;
else
  %Not showing pp plots so all space is used for controls.
  heightadjust = 0;
end

%These controls (y postion) are always fixed to top.
setpos(handles.text2,'bottom',ofigpos(4)-27);
setpos(handles.text3,'bottom',ofigpos(4)-27);
setpos(handles.alphabetical,'bottom',ofigpos(4)-27);
setpos(handles.loadbutton,'bottom',ofigpos(4)-27);
setpos(handles.savebutton,'bottom',ofigpos(4)-27);
setpos(handles.favorite,'bottom',ofigpos(4)-27);
setpos(handles.frame4,'top',ofigpos(4)-4);
setpos(handles.frame2,'top',ofigpos(4)-4);
setpos(handles.available,'top',ofigpos(4)-29);
setpos(handles.selected,'top',ofigpos(4)-29);

%Adjust heights of lists and frames.
setpos(handles.frame4,'bottom',63+34+heightadjust,1);
setpos(handles.frame2,'bottom',63+34+heightadjust,1);
setpos(handles.available,'bottom',91+34+heightadjust,1);
setpos(handles.selected,'bottom',91+34+heightadjust,1);

%Adjust bottoms of remaining controls (except shopp axes).
setpos(handles.up,'bottom',66+34+heightadjust);
setpos(handles.down,'bottom',66+34+heightadjust);
setpos(handles.removebtn,'bottom',66+34+heightadjust);
setpos(handles.addbtn,'bottom',66+34+heightadjust);
setpos(handles.hidebtn,'bottom',66+34+heightadjust);
setpos(handles.settings,'bottom',66+34+heightadjust);

setpos(handles.helpframe,'bottom',62+heightadjust);
hlpfb = getpos(handles.helpframe,'bottom');
setpos(handles.helpbtn,'bottom',hlpfb+2);
setpos(handles.methodinfo,'bottom',hlpfb+2);

setpos(handles.showpp,'bottom',34+heightadjust);
setpos(handles.ok,'bottom',34+heightadjust);
setpos(handles.cancel,'bottom',34+heightadjust);

setpos(handles.text4,'bottom',9+heightadjust);
setpos(handles.text5,'bottom',9+heightadjust);

setpos(handles.showxaxis,'bottom',6+heightadjust);
setpos(handles.showyaxis,'bottom',6+heightadjust);

setpos(handles.showexcluded,'bottom',4+heightadjust);
setpos(handles.showclasses,'bottom',4+heightadjust);

setpos(handles.frame6,'bottom',32+heightadjust);
setpos(handles.frame5,'bottom',2+heightadjust);


%Adjust widths and x position.

%Spoof minimum width.
if figpos(3)<443
  figpos(3) = 443;
end

%Position list panels, 3 pixels from edges (top and sides = 9pxls) with min width of
%217 pixels (frame4 is left, frame2 is right).
frmwidth = max([floor((figpos(3)-9)/2) 217]);
listwidth = frmwidth - 6;
setpos(handles.frame4,'width',frmwidth);
setpos(handles.frame2,'width',frmwidth);
setpos(handles.available,'width',listwidth);
setpos(handles.selected,'width',listwidth);

setpos(handles.frame6,'width',figpos(3)-6);
setpos(handles.frame5,'width',figpos(3)-6);

%Adjust remaining controls left/right.
setpos(handles.frame2,'left',frmwidth+6);
setpos(handles.selected,'left',frmwidth+9);
setpos(handles.text3,'left',frmwidth+9);

rfrmedge_r = getpos(handles.frame2,'right');
setpos(handles.savebutton,'right',rfrmedge_r-3);
setpos(handles.loadbutton,'right',rfrmedge_r-46);
setpos(handles.favorite,'right',rfrmedge_r-89);

setpos(handles.helpframe,'width',figpos(3)-6);
setpos(handles.helpbtn,'right',rfrmedge_r-3);
hlpbr = getpos(handles.helpbtn,'left');
setpos(handles.methodinfo,'width',hlpbr-6);

rfrmedge_l = getpos(handles.frame2,'left');
setpos(handles.removebtn,'left',rfrmedge_l+3);
setpos(handles.settings,'right',rfrmedge_r-3);

%Move based on middle point of right frame.
rfrm_middle = rfrmedge_l+(floor((rfrmedge_r-rfrmedge_l)/2));
setpos(handles.up,'right',rfrm_middle-1);
setpos(handles.down,'left',rfrm_middle+1);

setpos(handles.addbtn,'right',rfrmedge_l-6);
setpos(handles.alphabetical,'right',rfrmedge_l-6);

setpos(handles.ok,'right',figpos(3)-111);
setpos(handles.cancel,'right',figpos(3)-19);
setpos(handles.showexcluded,'right',figpos(3)-6);
setpos(handles.showclasses,'right',getpos(handles.showexcluded,'left')-2);

%X and Y dropdown box widths.
%Run code here, after exclude button moved so can base position off of it.
xlbledge_r = getpos(handles.text4,'right');%Right edge of remaining area.
excldbtnedge_l = getpos(handles.showclasses,'left');%Left edge of remaining area.
rmlstarea = excldbtnedge_l-xlbledge_r;%Remaining area.
rmlstarea = rmlstarea - (14+12);%Remove spacing and y label width.
drpdwnsize = floor(rmlstarea/2);%Dropdown width.

setpos(handles.showxaxis,'width',drpdwnsize);
setpos(handles.showyaxis,'width',drpdwnsize);

setpos(handles.showyaxis,'right',excldbtnedge_l-4);
setpos(handles.text5,'right',excldbtnedge_l-(4+drpdwnsize+2));


%Size pp plots.

ax1 = findobj(handles.preprocess,'tag','rawaxes');
ax2 = findobj(handles.preprocess,'tag','ppaxes');
createaxis = isempty(ax1) | isempty(ax2);

if showpp
  %Set minimum to 264.
  ctrlbottom = getpos(handles.frame5,'bottom');

  if ctrlbottom < 264
    remainingplotheight = 264;
    axbottom = ctrlbottom - 264;%Will be negative.
  else
    remainingplotheight = ctrlbottom;
    axbottom = 0;
  end

  %Adjust axes bottom up 32 pixels for 16p buffer and 16p text line for
  %zoom instructions.
  axbottom = axbottom + 32;

  %For height, 26 from bottom and 32 at top (for label area).
  axheight = (remainingplotheight)-(64);

  %Spoofed width.
  remainingplotwidth = figpos(3);

  %For width, 16 pxl buffer on edges.
  axwidth = (remainingplotwidth/2) - 32;

  %Right axis position.
  raxpos = 16+axwidth+22;


  if createaxis
    %Haven't created axes yet.
    delete(findobj(handles.preprocess,'type','axes'));  %delete all existing axes

    axsz = [16 axbottom axwidth axheight];
    ax1 = axes('Parent',handles.preprocess,'Units','Pixels','tag','rawaxes',...
      'Position',axsz,'Visible','On','FontSize',6); %Add userdata to know it should not be moved in resize.
    axsz(1) = axsz(1)+ raxpos;
    ax2 = axes('Parent',handles.preprocess,'Units','Pixels','tag','ppaxes',...
      'Position',axsz,'Visible','On','FontSize',6); %Add userdata to know it should not be moved in resize.

    set(handles.showxaxis,'enable','on')
    set(handles.showyaxis,'enable','on')
    set([handles.showclasses handles.showexcluded],'enable','on')
  else
    %Resize axes.
    axsz = [16 axbottom axwidth axheight];
    set(ax1,'Visible','On','Position',axsz)
    axsz(1) = axsz(1)+ raxpos;
    set(ax2,'Visible','On','Position',axsz)
    set(handles.showxaxis,'enable','on')
    set(handles.showyaxis,'enable','on')
    set([handles.showclasses handles.showexcluded],'enable','on')
  end

  %Add zoom.
  if checkmlversion('>=','7')
    linkaxes([ax1 ax2],'x');
  end
  zoom(handles.preprocess,'on');

  %Add zoom label. axbottom-32
  zmlabel = findobj(handles.preprocess,'tag','zoomlabel');
  if isempty(zmlabel)
    zcolor = get(handles.preprocess,'color');
    ztxt = '[Click and drag to zoom. Double-click to reset.]';
    zpos = [(figpos(3)/2 - 150) axbottom-28 300 15];
    uicontrol(handles.preprocess,'style','text','tag','zoomlabel','BackgroundColor',zcolor,...
      'position',zpos,'fontsize',getdefaultfontsize,'string',ztxt,'HorizontalAlignment','center');
  else
    zmlabel = findobj(handles.preprocess,'tag','zoomlabel');
    zpos = [(figpos(3)/2 - 150) axbottom-28 300 15];
    set(zmlabel,'visible', 'on','position',zpos)
  end

else
  if ~isempty(ax1)
    axes(ax1);
    delete(ax1);
  end
  if ~isempty(ax2)
    axes(ax2);
    delete(ax2);
  end
  set(handles.showxaxis,'enable','off')
  set(handles.showyaxis,'enable','off')
  set([handles.showclasses handles.showexcluded],'enable','off')
  zmlabel = findobj(handles.preprocess,'tag','zoomlabel');
  set(zmlabel,'visible', 'off')
end

%------------------------------------------------------------
function setpos(h,dim,sz,stretch)

if nargin<4;
  stretch = 0;
end
set(h,'units','pixels');
uipos = get(h,'position');
switch dim
  case 'bottom'
    %uipos(2) = sz;
    if stretch
      uipos(4) = uipos(4)+uipos(2)-sz;
    end
    uipos(2) = sz;
  case 'top'
    if ~stretch
      uipos(2) = sz-uipos(4);
    else
      uipos(4) = sz-uipos(2);
    end
  case 'left'
    uipos(1) = sz;
    if stretch
      uipos(3) = uipos(3)+sz;
    end
  case 'right'
    if ~stretch
      uipos(1) = sz-uipos(3);
    else
      uipos(3) = sz-uipos(1);
    end

  case 'width'
    if ~stretch
      uipos(3) = sz;
    else
      uipos(1) = uipos(1)-sz;
    end
  case 'height'
    if ~stretch
      uipos(4) = sz;
    else
      uipos(2) = uipos(2)-sz;
    end
end
limit = (3:4);
uipos(limit(uipos(limit)<1)) = 1;
set(h,'position',uipos);

%------------------------------------------------------------
function sz = getpos(h,dim)
set(h,'units','pixels');
uipos = get(h,'position');
switch dim
  case 'bottom'
    sz = uipos(2);
  case 'top'
    sz = uipos(2)+uipos(4);
  case 'left'
    sz = uipos(1);
  case 'right'
    sz = uipos(1)+uipos(3);
  case 'width'
    sz = uipos(3);
  case 'height'
    sz = uipos(4);
end

% --------------------------------------------------------------------
function out = setobjdata(item,handles,obj)
%Update or add a data object to the figure.
%  Inputs:
%    item    - is the type of object (e.g., "original" or "ppds" see
%               targfield sub-function)
%    handles - handles structure.
%    obj     - data object

myid = getobj(item,handles);

if isempty(myid)
  %Adding for the first time. Store object in OK button
  myid = shareddata(handles.ok,obj,struct('removeAction','adopt'));
  setobj(item,handles,myid);
else
  %Update
  myid.object = obj;
end
out = myid;

% --------------------------------------------------------------------
function [out,myid]= getobjdata(item,handles)
%Get a data object.
%  Inputs:
%    item       - is the type of object (e.g., "original" or "other").
%    handles    - handles structure or figure handle.

if ~isstruct(handles)
  handles = guidata(handles);
end

myid = getobj(item,handles);
out  = getshareddata(myid);

% --------------------------------------------------------------------
function myid = getobj(item,handles)
%Get current id of an item, 'out' is sourceID.
%  item - can be 'original' or 'other'
%NOTE: instead of searching links (which gets confusing with plotgui adding
%its own links) we are storing the key item links in appdata fields and
%accessing those directly. This works because preprocess is ONLY a modal
%window.

if ~isstruct(handles)
  handles = guidata(handles);
end

myid = getappdata(handles.preprocess,targfield(item));

%---------------------------------------------------
function setobj(item,handles,value)
%assign value for a given item

if ~isstruct(handles)
  handles = guidata(handles);
end

setappdata(handles.preprocess,targfield(item),value)

%---------------------------------------------------
function targ = targfield(item)
%convert from item name to appdata field

targ = 'preprodata';
switch item
  case 'original'
    targ = [targ];
  case 'other'
    targ = [targ '_other'];
  otherwise
    targ = [targ '_' item];
end

%---------------------------------------------------
function helpbtn_Callback(h, eventdata, handles, varargin)

info = get(handles.methodinfo,'userdata');

lookup = {
  '[] Loop...'      ''
  'Abs'             'Advanced_Preprocessing:_Simple_Mathematical_Operations'
  'log10'           'Advanced_Preprocessing:_Simple_Mathematical_Operations'
  'trans2abs'       'Advanced_Preprocessing:_Simple_Mathematical_Operations'
  'simple baseline' 'Advanced_Preprocessing:_Noise,_Offset,_and_Baseline_Filtering'
  'baseline'        'Advanced_Preprocessing:_Noise,_Offset,_and_Baseline_Filtering'
  'derivative'      'Advanced_Preprocessing:_Noise,_Offset,_and_Baseline_Filtering'
  'Detrend'         'Advanced_Preprocessing:_Noise,_Offset,_and_Baseline_Filtering'
  'smooth'          'Advanced_Preprocessing:_Noise,_Offset,_and_Baseline_Filtering'
  'EPO'             'Advanced_Preprocessing:_Multivariate_Filtering'
  'GLS Weighting'   'Advanced_Preprocessing:_Multivariate_Filtering'
  'osc'             'Advanced_Preprocessing:_Multivariate_Filtering'
  'msc'             'Advanced_Preprocessing:_Sample_Normalization'
  'Normalize'       'Advanced_Preprocessing:_Sample_Normalization'
  'SNV'             'Advanced_Preprocessing:_Sample_Normalization'
  'holoreact'       'Hrmethodreadr'
  'classcenter'     'Advanced_Preprocessing:_Variable_Centering'
  'Mean Center'     'Advanced_Preprocessing:_Variable_Centering'
  'Median Center'   'Advanced_Preprocessing:_Variable_Centering'
  'Autoscale'       'Advanced_Preprocessing:_Variable_Scaling'
  'gscale'          'Advanced_Preprocessing:_Variable_Scaling'
  'logdecay'        'Advanced_Preprocessing:_Variable_Scaling'
  'pareto'          'Advanced_Preprocessing:_Variable_Scaling'
  'sqmnsc'          'Advanced_Preprocessing:_Variable_Scaling'
  'autoscalenomean' 'Advanced_Preprocessing:_Variable_Scaling'
  'specalign'       'Advanced_Preprocessing:_Variable_Alignment'
  'Centering'       'Advanced_Preprocessing:_Multiway_Centering_and_Scaling'
  'Scaling'         'Advanced_Preprocessing:_Multiway_Centering_and_Scaling'
  };

%look up current preprocessing in lookup table
target = [];
if ~isempty(info);
  match = strmatch(lower(info.keyword),lower(lookup(:,1)),'exact');
  if ~isempty(match)
    %found keyword, get referenced page
    target = lookup{match(1),2};
  else
    %could not find keyword in list? try search on website:
    target = ['Special%3ASearch&search=' info.keyword '&go=Go'];
  end
end
if isempty(target)
  target = 'Model_Building:_Preprocessing_Methods';
end

%get actual page
local = regexprep(target,':','_');
local = which(local);    %look for local copy
if ~isempty(local)
  %found local - show it
  web(local);
else
  %no local copy? get web version
  web(['http://wiki.eigenvector.com/index.php?title=' target]);
end

%---------------------------------------------------
function propupdateshareddata(h,myobj,varargin)
%Input 'h' is the  handle of the subscriber object.
%The myobj variable comes in with the following structure.
%
%   sourceh     - handle to object where shared data will be stored (in appdata).
%   myobj       - shared data (object).
%   myname      - [string] name of shared object.
%   myporps     - (optional) structure of "properties" to associate with
%                 shared data.
%
%Option input varargin can be a "keyword" or other associated input.


%---------------------------------------------------
function updateshareddata(h,myobj,varargin)
%Input 'h' is the  handle of the subscriber object.
%The myobj variable comes in with the following structure.
%
%   sourceh     - handle to object where shared data will be stored (in appdata).
%   myobj       - shared data (object).
%   myname      - [string] name of shared object.
%   myporps     - (optional) structure of "properties" to associate with
%   shared data.

function osc_true = osc_show(pp)    % Determine if a preprocessing array has OSC
osc_true = 0;
for i = 1:length(pp)
  if strcmp(pp(i).keyword,'osc')
    osc_true =1;
    return
  end
end
