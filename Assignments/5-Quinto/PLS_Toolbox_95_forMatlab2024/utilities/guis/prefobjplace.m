function varargout = prefobjplace(parentobjh, fname, preflist, options)
%PREFOBJPLACE sets up the options gui for a specific function.
%
%  Inputs:
%    parentobjh : handle of optionsgui figure.
%    fname      : name of function from which to extract preferences
%                 structure OR options structure (values will be defaults).
%                 NOTE: 'definitions' substructure must have same number of
%                 submitted fields.
%
%    preflist   : list (cell array of strings) of option names to use or a
%                 key word indicating the 'tab' or 'userlevel' (string/char
%                 array). Default is keyword 'all'.
%
%  Options:
%         startpos : vertical start position on 'parentobjh' for placing objects.
%        recursive : ['yes'|{'no'}] set parent objects appdata options
%                    storage. Used with recursive calls by cells.
%           target : handle of graphics object (figure/uipanel) that stores
%                    preferences/options structure.
%        userlevel : [{'novice'} | 'intermediate' | 'advanced']default user level.
%            fname : function name (used in drop-down menu).
%          disable : [{}] cell of stings with options names to disable in GUI.
%           remove : [{}] cell of stings with options names to remove in GUI.
%
%  Pref Structure (prefstruct):
%   name              - option name given by function.
%   tab               - catagory of preference (e.g. 'display')
%   datatype          - type a value expected, actual datatype or keyword used for type of ui control for input.
%   valid             - range of accepted values, can be cell array of
%                       strings or logic statement or vector.
%   userlevel         - complexity of option.
%   description       - short explanation of option.
%
%I/O: prefs = prefobjplace(h, 'pca', 'all', options)
%
%See also: OPTIONSGUI, PREFOBJCB

%Copyright Eigenvector Research 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 10/31/05
%rsk 05/09/06 Add cancel button to load matrix.

if nargin == 0; parentobjh = 'io'; end
varargin{1} = parentobjh;
if ischar(varargin{1});
  options = [];
  options.startpos = [];
  options.recursive = 'no';
  options.target = [];
  options.userlevel = 'novice';
  options.fname = '';
  options.disable = '';
  options.remove = '';
  options.allowsave = 'no';
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

%Check IO
% Number of Inputs >= 4
if nargin < 2
  error('Number of inputs must be 2 or more.')
end

% Valid Handle
if ~ishandle(parentobjh)
  error('Parent object handle no longer valid.')
end

if nargin < 3
  preflist = 'all';
end

%Check for options.
if nargin < 4
  options = prefobjplace('options');
else
  options = reconopts(options,'prefobjplace');
end
framepos = get(findobj(parentobjh,'tag','optionsframe'), 'Position');

%Get start position.
if isempty(options.startpos)
  startpos = framepos(2)+framepos(4)-29;
else
  startpos = options.startpos;
end

%Get target figure.
if isempty(options.target)
  target = parentobjh;
else
  if ishandle(options.target)
    target = options.target;
  else
    error('Target handle not valid for preferences GUI.')
  end
end

%Get/Set User Level
ul = getappdata(target,'userlevel');
if isempty(ul)
  setappdata(target,'userlevel',options.userlevel);
  set(findobj(target,'tag',[options.userlevel 'menu']),'Checked','On');
end

%Get/set function name.
if isempty(options.fname) & strcmp(options.recursive,'no') & ischar(fname)
  %Using function name as keyword.
  options.fname = fname;
elseif isstruct(fname)&isfield(fname,'functionname')
  %Add functionname field of input struct if there.
  options.fname = fname.functionname;
end

if strcmp(options.recursive,'no')
  %Only set function name on non recursive.
  setappdata(target,'functionname',options.fname);
end
if ~strcmpi(options.recursive,'no') | isempty(options.fname)
  %only allow saving if not recursive and a fname is defined
  options.allowsave = 'no';
end

% Validate fname (if is not sturcture) and get default options. Current
% defaults will be automatically included (via reconopts) when calling to
% function.
try
  if ischar(fname)
    defaultopts = feval(fname, 'options');
  elseif isstruct(fname)
    defaultopts = fname;
  else
    warning('EVRI:PrefobjplaceInvalidFname','Not a valid input for ''fname'' to prefojplace function.')
  end

  if ~isfield(defaultopts, 'definitions')
    %************ Add code to make simple list of options when definitions not present.
    warning('EVRI:PrefobjplaceNoDefinitions',['There is no options.definitions field for ''' fname ''' function.']);
  else
    if isa(defaultopts.definitions,'function_handle')
      setappdata(target,'defhandle',defaultopts.definitions);
      defaultopts.definitions = feval(defaultopts.definitions);
    end
    pdefs = defaultopts.definitions; %preference definitions
  end

catch
  error(['Unable to set options for input to ''prefojplace'' function.']);
end

% Create preflist, check to see key word doesn't generate empty set, check
% for existance of prefs if cell array.
% Preflist should be cell array (not index) so as to avoid sorting errors.
buildlist = '';%Actual list of pref names.

%If prelist is empty or keyword = 'all' then build cell array of all names.
if isempty(preflist) | strcmp(preflist,'all')
  preflist = defval(pdefs,'name');
end

%Remove unwanted definitions.
% if ~isempty(options.remove)
[dummy ia] = setdiff(preflist, options.remove);
preflist = preflist(sort(ia));%Sort back into orginal order.
% end

if ischar(preflist)
  %If ischar then construct cell array of named preferences based on key
  %work. Key word can be tab or userlevel.

  %Create search sets for keyword out of 'tab' and 'userlevel'.
  pdefs_tabcell = defval(pdefs, 'tab');%Cell array of tabs.
  pdefs_userlevelcell = defval(pdefs, 'userlevel');%Cell array of userlevel.
  %Search for keyword.
  if any(cell2mat(strfind(pdefs_tabcell,preflist)));
    %The keyword is a tab so create list based on tab.
    for i = 1:length(pdefs)
      if strcmp(pdefs(i).tab,preflist)
        buildlist = [buildlist {pdefs(i).name}];
      end
    end
  elseif any(cell2mat(strfind(pdefs_userlevelcell,preflist)));
    %The keyword is a user level, create list based on userlevel.
    for i = 1:length(pdefs)
      if strcmp(pdefs(i).userlevel,preflist)
        buildlist = [buildlist {pdefs(i).name}];
      end
    end
  end
elseif iscell(preflist)
  %Given cell list, check for the existance of all names.
  pdefs_namecell= defval(pdefs, 'name');%Cell array of names.
  buildlist = preflist(ismember(preflist,pdefs_namecell));
  %   for i = 1:length(preflist)
  %     if any(cell2mat(strfind(pdefs_namecell, preflist{i})))
  %       buildlist = [buildlist preflist(i)];
  %     else
  %       %***** May not need to be an error.
  %       %warning(['Can''t find prefernce ''' preflist{i} ''' in definitions.'])
  %     end
  %   end
end

%Store initial data and create new options holder.
if strcmp(options.recursive,'no')
  setappdata(target,'initialopts',defaultopts);
  setappdata(target,'newopts',defaultopts);
  setappdata(target,'cellinfo','');%need to map cell names back to orginal option name.
  %Store preflist and options in case need to rebuild gui.
  setappdata(target,'inipreflist',preflist);
  setappdata(target,'inioptions',options);
end

%Create contorls.
set(parentobjh,'units','pixels');%Make sure units are pixels.

clr = [0.98 0.98 .94]*.98;
curpos = startpos; %[left bottom width height]

for i = buildlist
  try
    controltype = defval(pdefs, i{:}, 'datatype');
    if regexp(controltype,'cell(\w*)') %acceptable values 'cell(char)' 'cell(double)' 'cell(vector)' 'cell(select)'
      %Create two or more selections based on number of cells in default.
      %Uses datatype from orginal definitions to create a temporary
      %options structure for a recursive call. Not able to handle
      %differnt datatypes for each cell at this time.
      numcells = length(getsubstruct(defaultopts,(i{:})));%Number of cells to create.
      [dummy,rem] = strtok(controltype,'()');
      dtype = strtok(rem,'()'); %Cell datatype.
      row = defaultopts.definitions(find(ismember({defaultopts.definitions.name},i{:})));%Default row from definitions.
      cellinfo = getappdata(target,'cellinfo');
      tempopts = [];
      for j = 1:numcells
        %Build temporary options structure to call prefobjplace recursively.
        item = getfield(defaultopts,i{:});
        tempopts = setfield(tempopts,[i{:} '_Mode' num2str(j) '_Cell'],item{j});
        tempopts.definitions(j) = row;
        tempopts.definitions(j).name = [i{:} '_Mode' num2str(j) '_Cell'];
        tempopts.definitions(j).datatype = dtype;
        %need to map cell names back to orginal option name.
        cellinfo(end+1).orgname = i{:};
        cellinfo(end).curname = [i{:} '_Mode' num2str(j) '_Cell'];
      end
      setappdata(target,'cellinfo',cellinfo);
      usecell = 1;
      cellopts.startpos = curpos;
      cellopts.recursive = 'yes';
      cellopts.disable = options.disable;
      prefobjplace(parentobjh, tempopts, {tempopts.definitions.name}, cellopts);
      curpos = curpos-((numcells)*32);
      continue
    end

    %If using cell, change format to display better otherwise use name.
    cloc = regexp(i{:},'_Mode\d*_Cell');
    cellname = ''; %Add original name of cell (without _Mode..., so can identify later).
    if cloc
      lbl = [i{:}(1:cloc-1) ' (Cell ' i{:}(regexp(i{:},'_Mode\d*_Cell')+5:end-5) ')'];
      cellname = i{:}(1:cloc-1);
    else
      lbl = i{:};
      cellname = i{:};
    end

    %Visibility switch of controls that don't store ud variable.
    ctrl.visible = 1; %Visible switch;
    ctrl.target = target;
    ctrl.row = i;
    ctrl.help = defval(pdefs, i{:}, 'description');
    ctrl.name = i{:}; %Option name;
    ctrl.tab = defval(pdefs, i{:}, 'tab');
    ctrl.userlevel = defval(pdefs, i{:}, 'userlevel');
    ctrl.cellname = cellname;

    %Create label textbox.
    lh = uicontrol(parentobjh,...
      'tag', ['label_' i{:}],...
      'style', 'text',...
      'position',[framepos(1)+4 curpos 140 27],...
      'string', lbl,...
      'userdata','optctrl',...
      'horizontalalignment', 'left',...
      'BackgroundColor',clr);
    setappdata(lh, 'optinfo',ctrl);%Add visible switch.

    %Need options information stored with control so can access in callback later.
    ud.name = i{:};
    ud.datatype = defval(pdefs, i{:}, 'datatype');
    ud.valid = defval(pdefs, i{:}, 'valid');
    ud.help = defval(pdefs, i{:}, 'description');
    ud.tab = defval(pdefs, i{:}, 'tab');
    ud.userlevel = defval(pdefs, i{:}, 'userlevel');
    ud.target = target;
    ud.row = i;
    ud.visible = 1;
    ud.cellname = cellname;

    mlp = framepos(1)+145; %New control left position.
    %Tags are label_name, value_name, discription_name, and disp_name(for
    %type matrix).
    switch controltype
      %Controls try to store values in parrent appdata field 'newopts' imediately.
      %Option field name stored in UserData field of control (tag = val_*).
      case {'char','double'}
        ch = uicontrol(parentobjh,...
          'tag', ['val_' i{:}],...
          'style', 'edit',...
          'position',[mlp curpos 140 27],... %move over 141 pixels
          'string', getsubstruct(defaultopts,(i{:})),... %default options
          'CallBack', 'prefobjcb(''loadsingle'',gcbo,[],guidata(gcbo))',... %Callback in prefobjcb.m
          'ButtonDownFcn','prefobjcb(''updategui'',guidata(gcbo))',...
          'TooltipString', 'Enter single value.');
        setappdata(ch, 'optinfo',ud);
      case 'select'
        %Drop-down list from cell array of strings.
        str = defval(pdefs,i{:},'valid');%Get string values.
        if isnumeric(str{1})
          %Assume all values are numeric and need to be changed into strings.
          for j = 1:length(str)
            str{j} = num2str(str{j});
          end
          dfopt = num2str(getsubstruct(defaultopts,(i{:})));
        else
          dfopt = getsubstruct(defaultopts,(i{:}));
        end
        if all(cellfun('isclass',str,'char'));
          dfopt = char(dfopt);
        end
        listval = find(ismember(str,dfopt));%Find position of default option.
        if isempty(listval)
          %Ticket #910, if default value isn't valid then make selection 1.
          listval = 1;
        end

        ch = uicontrol(parentobjh,...
          'tag', ['val_' i{:}],...
          'style', 'popupmenu',...
          'position',[mlp curpos 140 27],... %move over 141 pixels
          'string', str,... %list values
          'value', listval,...%default value
          'CallBack', 'prefobjcb(''loadlist'',gcbo,[],guidata(gcbo))',...
          'TooltipString', 'Select value from drop-down menu.');
        setappdata(ch, 'optinfo',ud);

      case {'vector', 'matrix', 'dataset', 'preprocesing', 'directory'}
        
        if strcmp(controltype,'directory')
          str = 'Choose';
        else
          str = 'Load';
        end
        
        %Buttons load/edit.
        mh = uicontrol(parentobjh,...
          'tag', ['val_' i{:}],...
          'style', 'pushbutton',... %Used as search criteria in optionsgui>isvisible
          'position',[mlp curpos+14 70 13],... %move over 141 pixels
          'string', str,... %default options
          'CallBack', 'prefobjcb(''loadmatrix'',gcbo,[],guidata(gcbo))',...
          'userdata','optctrl',...
          'horizontalalignment', 'left',...
          'BackgroundColor',[1 1 1],...
          'TooltipString', 'Load data from workspace.');
        setappdata(mh, 'optinfo',ud);

        clh = uicontrol(parentobjh,...
          'tag', ['clear_' i{:}],...
          'style', 'pushbutton',... %Used as search criteria in optionsgui>isvisible
          'position',[mlp+70 curpos+14 70 13],... %move over 141 pixels
          'string', 'Clear',... %default options
          'CallBack', 'prefobjcb(''clearmatrix'',gcbo,[],guidata(gcbo))',...
          'userdata','optctrl',...
          'horizontalalignment', 'left',...
          'BackgroundColor',[1 1 1],...
          'TooltipString', 'Clear value (resets structures to default value).');
        setappdata(clh, 'optinfo',ctrl);%Add visible switch.

        %Create size string for display.
        rawdata = getsubstruct(defaultopts,(i{:}));
        sz = size(rawdata);
        if isempty(rawdata)
          sizestr = '(empty)';
        else
          sizestr = sprintf('%ix',sz);
          sizestr = [sizestr(1:end-1) ' ' class(rawdata)];
        end
        sizestr = ['Size: ' sizestr];

        sh = uicontrol(parentobjh,...
          'tag', ['disp_' i{:}],...
          'style', 'edit',...
          'position',[mlp curpos 140 13],... %move over 141 pixels
          'string', sizestr,... %size and class of default data
          'userdata','optctrl',...
          'enable', 'inactive',...%Used as search criteria in optionsgui>isvisible
          'horizontalalignment', 'left',...
          'BackgroundColor',[1 1 1],...
          'TooltipString', 'Load matrix or vector from workspace.');
        setappdata(sh, 'optinfo',ctrl);%Add visible switch.
      case {'mode' 'vector_inline'}
        %Mode data (e.g. '3 4 6').
        ch = uicontrol(parentobjh,...
          'tag', ['val_' i{:}],...
          'style', 'edit',...
          'position',[mlp curpos 140 27],... %move over 141 pixels
          'string', num2str(getsubstruct(defaultopts,(i{:}))),... %default options
          'CallBack', 'prefobjcb(''loadmode'',gcbo,[],guidata(gcbo))',... %Callback in prefobjcb.m
          'TooltipString', 'Enter each number seperated by a space (e.g. "3 4 8").');
        setappdata(ch, 'optinfo',ud);
      case 'boolean'
        str = {'0 (''No'')' '1 (''Yes'')'};%Get string values.
        listval = find(ismember([0 1],getsubstruct(defaultopts,(i{:}))));%Find position of default option.

        ch = uicontrol(parentobjh,...
          'tag', ['val_' i{:}],...
          'style', 'popupmenu',...
          'position',[mlp curpos 140 27],... %move over 141 pixels
          'string', str,... %list values
          'value', listval,...%default value
          'CallBack', 'prefobjcb(''loadboolean'',gcbo,[],guidata(gcbo))',...
          'TooltipString', 'Select boolean argument from drop-down menu.');
        setappdata(ch, 'optinfo',ud);
      case 'struct'
        %Create Button that will display a substructure when clicked.
        ch = uicontrol(parentobjh,...
          'tag', ['val_' i{:}],...
          'style', 'text',...
          'visible', 'off',...
          'position',[mlp curpos 140 27],... %move over 141 pixels
          'string', [{'Nested Structure: see'} {'Options Catagories buttons'}]',... %default options
          'CallBack', 'prefobjcb(''loadstructure'',gcbo,[],guidata(gcbo))',...
          'TooltipString', 'Display sub-structure options.' );
        setappdata(ch, 'optinfo',ud);
    end

    if exist('ch','var')
      set(ch, ...
        'userdata','optctrl',...
        'horizontalalignment', 'left',...
        'ButtonDownFcn','prefobjcb(''displayhelp'',gcbo,[],guidata(gcbo))',...
        'BackgroundColor',[1 1 1]);
    end
    %Description/help text box.
    %Create a tool tip.
    tt = defval(pdefs, i{:}, 'description');
    if iscell(tt)
      tt = [tt{1} '...'];
    end
    dh = uicontrol(parentobjh,...
      'tag', ['description_' i{:}],...
      'style', 'listbox',...
      'min',0,...
      'max',2,...
      'value',[],...
      'enable', 'inactive',...
      'position',[framepos(1)+287 curpos 290 28],... %move over 141 pixels
      'tooltip', tt,... %default options
      'userdata','optctrl',...
      'horizontalalignment', 'left',...
      'ButtonDownFcn','prefobjcb(''displayhelp'',gcbo,[],guidata(gcbo))',...
      'BackgroundColor',clr);

    setappdata(dh, 'optinfo',ctrl); %Add visible switch.

    dstr = defval(pdefs, i{:}, 'description');
    if ~iscell(dstr)
      %Help description is a single string so make sure it fits the list
      %box.
      dstr = textwrap(dh,{dstr});
      usestr = true;

      %Adjust string to indicate more help than can be listed.
      if length(dstr)>2 & length(dstr{2})>52
        dstr{2} = [dstr{2}(1:52) ' ...'];
        set(dh,'BackgroundColor',[1 0.92 .88])
      elseif length(dstr)>2
        dstr{2} = [dstr{2} ' ...'];
        set(dh,'BackgroundColor',[1 0.92 .88])
      end
    else
      %Help description is a cell array of strings so assume the author has
      %"wrapped" the text correctly.
      set(dh,'BackgroundColor',[1 0.92 .88])
    end
    set(dh,'string',dstr);

    if strcmpi(options.allowsave,'yes') & isempty(strfind(i{:},'.')) & ~strcmp(controltype,'struct')
      svh = uicontrol(parentobjh,...
        'tag', ['save_' i{:}],...
        'style', 'pushbutton',...
        'units','pixels',...
        'position',[framepos(1)+287+290 curpos 20 20],...
        'userdata','optctrl',...
        'string','',...
        'tooltip','Save as default value for this option',...
        'cdata',gettbicons('save'),...
        'callback','prefobjcb(''savepref'',gcbo,[],guidata(gcbo))');
      setappdata(svh, 'optinfo',ud);
    else
      svh = [];
    end
    
    %Disable control if on disable list.
    if ~isempty(options.disable)
      if ismember(i{:},options.disable) | ismember(cellname,options.disable)
        if ismember(controltype,{'vector', 'matrix'})
          set(mh,'enable','off'); %Disable button.
        else
          set(ch,'enable','off'); %Disable control.
        end
        if ishandle(svh);
          set(svh,'enable','off');
        end
      end
    end

    curpos = curpos - 32; %move down 32 pixels.
  catch
    %     encode(lasterror)
  end
end

if strcmp(options.recursive,'no')
  tabbuttonadd(parentobjh,pdefs(sort(ia)));%is calculated in 'Remove unwanted definitions.' near beginning of function.
  headeradd(parentobjh,pdefs,curpos,target,framepos)
  %optionsgui('slidersetup',guihandles(parentobjh),[]);
  optionsgui('menuset',[],[],guihandles(parentobjh));
  %Call resizefunction to correctly size controls. This is needed becuase
  %of the use of positionmanager.
  optionsgui('resize_callback',parentobjh,[],guihandles(parentobjh))
end

% --------------------------------------------------------------------
function bh = tabbuttonadd(parentobjh,defs)
%Add buttons for each tab.
[list,where1]=unique({defs.tab});  %get unique tabs
[junk,where2]=unique(where1);  
list = list(where2);  %but keep in original order

handles = guidata(parentobjh);

%Sort list putting nested tabs at bottom.
lst1 = '';
lst2 = '';
for i = 1:length(list)
  if strfind(list{i},'.')
    lst1 = [lst1; list(i)];
  else
    lst2 = [lst2; list(i)];
  end
end
sort(lst1);
sort(lst2);
list = [lst2;lst1];

allbtnlocation = get(handles.allbutton,'position');
c = allbtnlocation(2) - 26;

if ~isempty(list{1})
  for i = 1:length(list)
    pos = [5  c 121 20];
    cb = ['optionsgui(''togglebutton_Callback'',gcbo,[],guihandles(gcbo))'];
    bh = uicontrol(parentobjh,...
      'tag', ['tab_' list{i}],...
      'string', list{i},...
      'style', 'toggle',...
      'userdata','tabbutton',...
      'position', pos,...
      'CallBack', cb);
    c = c - 21;
  end
end

% --------------------------------------------------------------------
function headeradd(parentobjh,pdefs,curpos,target,framepos)
%Add header lines for each tab.
pcell = struct2cell(pdefs)';

%Get list of tabs, need a loop so can stay in orginal order.
clist = pcell(:,2);
tablist = unique(clist);
loc = [];
for i = tablist'
  loc = [loc min(find(strcmp(i,pcell(:,2))))];%Find first occurance.
end
loc = sort(loc); %Sort to min order.
tablist = clist(loc)';%Tab list in correct order.

%Remove spaces from name. 
tabtagname = strrep(tablist,' ','');

setappdata(target,'tablist',tablist);%Save the tablist.

for i = 1:length(tablist)
  %Visibility switch of controls that don't store ud variable.
  ctrl.visible = 1; %Visible switch;
  ctrl.target = target;
  ctrl.row = tablist(i);
  ctrl.help = ['Header for tab: ' tablist{i}];
  ctrl.name = [tablist{i} '_tabheader'];; %Option name;
  ctrl.tab = [tablist{i} '_tabheader'];
  ctrl.userlevel = 'novice';
  ctrl.cellname = '';

  %Create label textbox.
  lh = uicontrol(parentobjh,...
    'tag', ['tabheader_' tabtagname{i}],...
    'style', 'text',...
    'position',[framepos(1)+4 curpos 573 22],...
    'string', ['          ' tablist{i}],...
    'fontsize',12,...
    'userdata','optctrl',...
    'horizontalalignment', 'left',...
    'BackgroundColor',[1 1 1]);
  setappdata(lh, 'optinfo',ctrl);%Add visible switch.
  curpos = curpos - 32; %move down 32 pixels.
end


% --------------------------------------------------------------------
function val = defval(pdefs, name, column, row)
%Return value (if 'column' input give as a column name) or
%cell array (column) from definitions sturcture or
%a row if 'row' input is given and = 1 for 'name' input.
fields = {'name' 'tab' 'datatype' 'valid' 'userlevel' 'description'};
pdefs_cell = struct2cell(pdefs);

if nargin == 2 & ismember(name, fields)
  %Return cell array (column).
  switch name
    case 'name'
      val = pdefs_cell(1,:);
    case 'tab'
      val = pdefs_cell(2,:);
    case 'datatype'
      val = pdefs_cell(3,:);
    case 'valid'
      val = pdefs_cell(4,:);
    case 'userlevel'
      val = pdefs_cell(5,:);
    case 'description'
      val = pdefs_cell(6,:);
  end
elseif ~isempty(column)

  nnpos = find(ismember(pdefs_cell(1,:),name));
  ccpos = find(ismember(fields,column));
  val = pdefs_cell{ccpos,nnpos};
elseif row
  nnpos = find(ismember(pdefs_cell(1,:),name));
  val = pdefs_cell(:,nnpos)';
end
