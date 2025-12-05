function varargout = modelselectorgui(model,varargin)
%MODELSELECTORGUI Graphical Interface to build ModelSelector models
%I/O: modelselectorgui

%Copyright Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0 | (nargin==1 & ~ischar(model))
  %- - - - - - - - - - - - - - - - - - - -
  fig = findall(0,'tag','modelselectorgui');
  if ~isempty(fig)
    figure(fig);
    if nargout>0
      varargout = {fig};
    end
    if exist('model')
      if ismodel(model) & ~isempty(model)
        if strcmpi(model.modeltype,'modelselector')
          % load model into canvas if canvas is open
          loadmodel(fig,model);
        end
      end
    end
    return;
  end
  
  wb = waitbar(0.5,'Starting Hierarchical Model Builder...');
  
  try
  fig = figure('color',[1 1 1],'toolbar','none',...
    'visible','off',...
    'menubar','none',...
    'tag','modelselectorgui',...
    'name','Hierarchical Model Builder',...
    'numbertitle','off',...
    'integerhandle','off',...
    'resizefcn',@resize,...
    'units','pixels',...
    'windowbuttondownfcn',@highlight,...
    'closerequestfcn',@exitgui,...
    'PaperPositionMode','auto',...`
    'windowkeypressfcn',@keypress);
  
  positionmanager(fig,mfilename,'move');
  guiinit(fig)
  set(fig,'visible','on');
  
  %- - - - - - - - - - - - - - - - - - - -
  
  %build tree
  builtmodel = [];
  if nargin<1 | isempty(model)
    model = node;
    autohighlight = true;
  elseif ismodel(model) & strcmpi(model.modeltype,'modelselector')
    builtmodel = model;
    model = decodemodel(model);
    autohighlight = false;
  end
  assigninmodel(fig,[],model)
  setappdata(fig,'builtmodel',builtmodel);
  setappdata(fig,'modelsaved',~isempty(builtmodel));
  draw(fig);
  
  hlookup = getappdata(fig,'hlookup');
  if autohighlight;
    highlight(hlookup{1}(1),1);
  end
  
  catch
    le = lasterror;
    if ishandle(wb)
      delete(wb)
    end
    rethrow(le)
  end
  if ishandle(wb)
    delete(wb)
  end

  if nargout>0
    varargout = {fig};
  end
  
elseif ismember(model,{'options','io'})

  %evriio call
  options = [];
  options.reducedstats = 'on';
  options.plsdaqlimit = 3;
  options.plsdat2limit = 3;
  options.multiple      = 'otherwise'; 
  options.definitions   = @optiondefs;
  
  if nargout==0; evriio(mfilename,model,options); else; varargout{1} = evriio(mfilename,model,options); end
  return;
  
else
  
  %switchyard
  if nargout>0
    [varargout{1:nargout}] = feval(model,varargin{:});
  else
    feval(model,varargin{:});
  end
end

%---------------------------------------------------
function guiinit(fig)

btnlist = {
  'evri' 'evri'         'browse'    'enable' 'View Workspace Browser'    'off' 'push'
  'analysis' 'findanalysistb'  @findanalysis  'enable' 'Locate Analysis Window'  'on' 'push'
  'options' 'editprefstb'  @editpref  'enable' 'Edit Preferences'  'on' 'push'
  'open' 'loadmodeltb'  @loadmodel  'enable' 'Load Hierarchical Model Tree'  'on' 'push'
  'save' 'savemodeltb'  @savemodel  'disable' 'Save Hierarchical Model Object'  'off' 'push'
  'clipboard' 'copyfiguretb'  @copyfigure  'enable' 'Copy Model Image to Clipboard'  'off' 'push'
  'calc' 'buildmodeltb' @buildmodel 'disable' 'Build Hierarchical Model' 'on'  'push'
  'image_tree'    'automatetb'      @classify   'enable' 'Automate Classification' 'on'  'push'
  'rotate_ccw' 'undotb' @doundo     'disable' 'Undo Last Action' 'on' 'push'
  'rotate_cw'  'redotb' @doredo     'disable' 'Redo Next Action' 'off' 'push'
  'help' 'help' @showhelp           'enable'  'Get Interface Help' 'on' 'push'
  };  
tbh = toolbar(fig,[],btnlist,'modelseltoolbar');

set(0,'currentfigure',fig);
%add Target object menu
h = uicontextmenu('parent',fig,'tag','targetmenu');

uimenu(h,'label','Choose Model Outputs...','tag','chooseoutputs','callback',@chooseoutputs);
uimenu(h,'label','Convert to Decision Rule','tag','makenode','callback',@makenode);
uimenu(h,'label','Convert to End-Point','tag','makeendpoint','callback',@makeendpoint);

h2 = uimenu(h,'label','End Point','tag','datatype');
uimenu(h2,'label','Model...','tag','model','callback',@settarget_model);
uimenu(h2,'label','Value...','tag','value','callback',@settarget_valuenumeric);
uimenu(h2,'label','String...','tag','string','callback',@settarget_valuestring);
uimenu(h2,'label','Error...','tag','error','callback',@settarget_error);

h2 = uimenu(h,'label','Decision Rule','tag','trigger');
uimenu(h2,'label','Model-Based Rule...','callback',@settarget_trigger);
uimenu(h2,'label','Variable Test Rule...','callback',@settarget_vartrigger);

uimenu(h,'label','Delete','tag','delete','separator','on','callback',@deleteitem);

%normal menus
h = uimenu(fig,'label','File');
uimenu(h,'label','Load Hierarchical Model','callback',@loadmodel)
uimenu(h,'label','Save Hierarchical Model','callback',@savemodel)
uimenu(h,'label','Clear Canvas','callback',@clearcanvas)
uimenu(h,'label','Close','callback',@exitgui,'separator','on')


h = uimenu(fig,'label','Edit','callback',@editmenu);
uimenu(h,'label','Undo Last Action  (Ctrl-Z)','callback',@doundo,'userdata',-1,'tag','editundo')
uimenu(h,'label','Redo Next Action  (Ctrl-Y)','callback',@doredo,'userdata',+1,'tag','editredo')
uimenu(h,'label','Preferences...','callback',@editpref,'tag','editpref','separator','on')

h = uimenu(fig,'label','Help');
uimenu(h,'label','Hierarchical Model Builder Help','callback',@showhelp)


%add drop handlers
if ~exist('DropTargetList','class'); evrijavasetup; end
analysisdnd = evrijavaobjectedt(DropTargetList);%EVRI Custom drop target class.
analysisdnd = handle(analysisdnd,'CallbackProperties');
jFrame = get(handle(fig),'JavaFrame');
jAxis  = jFrame.getAxisComponent;
jAxis.setDropTarget(analysisdnd);
set(analysisdnd,'DropCallback',{@dropCallbackFcn,fig});

%add evritree
%Set a custom structure for modelcache.
copts.parent_function = 'modelselectorgui';%Function with tree_callback sub.
copts.showhide        = 'off';%Show the hide cache leaf.
copts.showview        = 'on';
copts.showdemo        = 'on';
copts.showsettings    = 'off';
copts.showclear       = 'off';
copts.showhelp        = 'off';
copts.demo_gui        = ''; %Show all demo data.
mycache = cachestruct('type',copts);
setappdata(fig,'treestructure',mycache);
setappdata(fig,'treestructure_options',copts);

%Create model cache tree.
defaultcacheview = 'date';
etopts = evritreefcn('options');
etopts.closebtn = 'off';
etopts.parent_function = 'modelselectorgui';
etopts.parent_callback = 'tree_callback';
setappdata(fig,'force_tree_callback','modelselectorgui') 
[mctree, mccontainer] = evritreefcn(fig,'show',defaultcacheview,etopts);

%---------------------------------------------------
function keypress(fig,varargin)

c = char(get(fig,'currentcharacter'));
switch c
  case char(27)  %esc
    if ~checkmlversion('==','8.4')
      highlight(fig);
    end
    
  case char(26)  %ctrl-z
    doundo(fig);
    
  case char(25)  %ctrl-y
    doredo(fig);
    
  case char(18)  %ctrl-r   %Redraw
    draw(fig);
    
  case char(9)   %tab
    highlightnext(fig);
    
  case char(13)  %enter
    co = gco;
    if isempty(getappdata(fig,'selecteditem'))
      %open item for editing
      obj = getappdata(fig,'highlighteditem');
      if ~isempty(obj)
        highlight(obj,1);
      end
    elseif strcmp(get(co,'type'),'uicontrol') & strcmp(get(co,'style'),'edit'); 
      %already editing, save and exit
      uicontrol(co);
      [content,S,index,obj] = getselobject(fig);
      if ~checkmlversion('==','8.4')
        highlight(fig);
        highlight(obj,0);
      end
    else
      %skip to next item
      highlightnext(fig);
    end
    
  case {' ' char(8) char(127)}  %space, delete, or backspace
    if strcmp(get(gco,'type'),'uicontrol') & strcmp(get(gco,'style'),'edit'); return; end
    obj = getappdata(fig,'selecteditem');
    if isempty(obj)
      obj = getappdata(fig,'highlighteditem');
    end
    if ~isempty(obj)
      highlight(obj,2);
    end

  case {'v' 's' 'm' 't' 'e'}
    if strcmp(get(gco,'type'),'uicontrol') & strcmp(get(gco,'style'),'edit'); return; end
    obj = getappdata(fig,'selecteditem');
    if isempty(obj)
      obj = getappdata(fig,'highlighteditem');
    end
    if ~isempty(obj)
      highlight(obj,0.5);
      settargetas(fig,c);
    end
    
  otherwise
%     double(c)
end

%--------------------------------------------------
function exitgui(fig,varargin)

fig = findparentfig(fig);
model = getappdata(fig,'model');
modelsaved = getappdata(fig,'modelsaved');

if ~isemptynode(model) & ~modelsaved
  resp = evriquestdlg('Current model has not been saved. What do you want to do?','Model Not Saved','Close Without Saving','Save & Close','Cancel','Close Without Saving');
  switch resp
    case {'Cancel'}
      return
    case {'Save & Close'}
      if ~savemodel(fig);
        return
      end
  end
end
% if Hmac Gui is still open, kill it
h = findall(groot,'Type','Figure','Name','Automatic Classifier Settings');
if ~isempty(h)
  delete(h);
end
% if Hmac CV Gui is still open, kill it
h = findall(groot,'Type','Figure','Name','Cross-Validation Settings');
if ~isempty(h)
  delete(h);
end

% if preprocessing window is still open, kill it
h = findall(groot,'Type','Figure','Name','Preprocessing');
if ~isempty(h)
  delete(h);
end

delete(fig);

%---------------------------------------------------
function showhelp(varargin)

evrihelp('Hierarchical_Model_Builder',1)

%---------------------------------------------------
function out = optiondefs()
defs = {
  'reducedstats'    'General Settings'    'select'   {'on' 'off'}    'novice'    'When ''on'' Q and T^2 condition tests use reduced statistics. When ''off'', raw, unnormalized statistics are used in condition tests.';
  'multiple'        'General Settings'    'select'   {'otherwise' 'mostprobable' 'fail'}    'novice'    'Governs behavior when more than one class of a classification model is assigned. ''fail'' will throw an error. ''mostprobable'' will choose the target that corresponds to the most probable class. ''otherwise'' will use the last target (otherwise.)';
  'plsdaqlimit'     'PLSDA Nodes' 'double'   'float(0:inf)'  'novice'    'Governs trigging of PLSDA "Otherwise" branch. When Q is above this limit, the otherwise branch is selected.'
  'plsdat2limit'    'PLSDA Nodes' 'double'   'float(0:inf)'  'novice'    'Governs trigging of PLSDA "Otherwise" branch. When T2 is above this limit, the otherwise branch is selected.'
};
out = makesubops(defs);

%---------------------------------------------------
function editpref(varargin)

fig = findparentfig(varargin{1});
opts = modelselectorgui('options');
opts = reconopts(getappdata(fig,'preferences'),opts);
out = optionsgui(opts);
if isempty(out) %cancel
  return;
end
setappdata(fig,'preferences',out);
setappdata(fig,'builtmodel',[]);
setappdata(fig,'modelsaved',false);
updatetoolbar(fig);

%---------------------------------------------------
function dropCallbackFcn(obj,ev,varargin)
%Parse dnd object then call drop.

fig = findparentfig(varargin{1});

dropdata = drop_parse(obj,ev,'',struct('concatenate','on'));
if isempty(dropdata{1})
  %Probably error.
  %TODO: Process workspace vars.
  return
end

if strcmp(dropdata{1},'treenode')
  %Droping single cache item or multiple items from workspace.
  dropnode = dropdata{end,2};
  myval = evrijavamethodedt('getValue',dropnode);
  if strfind(myval,'cachestruct|')
    %Dropping cache item.
    %Need to save location of drop because some systems don't update mouse
    %location until after a drop and another click.
    if ispc
      %Use this position for hi res windows. 
      pos = round(get(get(fig,'currentaxes'),'currentpoint'));
      pos = pos(1,1:2);
    else
      %Mac doesn't update mouse position with currentpoint so use java
      %event data. Note this doesn't work on hi res windows because
      %resolution is different between event data (higher res) and
      %'currentpoint' which is lower. 
      pos = [ev.getLocation.getX ev.getLocation.getY];
    end
    %Location from the event data does not work on high res windows
    %setappdata(fig,'LastDropLocation',[ev.getLocation.getX ev.getLocation.getY])
    setappdata(fig,'LastDropLocation',pos)
    loadcacheitem(fig)
  elseif strfind(myval,'demo/')
    %Dropping demo node
    [mydemodata, loadas, idx] = getdemodata(regexprep(myval,'demo\/',''));
    if ~isempty(mydemodata) & ~isempty(mydemodata{1})
      dropitem([],fig,mydemodata{1});
    end
    return
  else
    %Drop workspace node.
    myud = get(dropnode,'UserData');
    if ~isempty(myud) && isstruct(myud) && isfield(myud,'location') && strcmp(myud.location,'workspace')
      %Check for multiple items.
      myvars = browse('get_multiple_tree_selections',findobj(allchild(0),'tag','eigenworkspace'));
      myitems = {};
      for i = 1:length(myvars)
        myitems{i} = evalin('base',myvars(i).name);
      end
      if isempty(myitems)
        return;
      end
      dropitem([],fig,myitems{:});
    end
  end
else
  %Probably dropping a file.
  dropitem([],fig, dropdata{:,2})
end

% --------------------------------------------------------------------
function loadcacheitem(fig, varargin)
%Load item from menu in cache viewer.

t = getappdata(fig,'treeparent');
fcn = get(t,'GetSelectedCacheItem');

myitem = fcn(fig);
if ~iscell(myitem)
  myitem = {myitem};
end
if length(myitem)>1
  myitem = myitem(1);
end
if ~isempty(myitem{:})
  dropitem([],fig,myitem{:})
end

%---------------------------------------------------
function findanalysis(varargin)

eg = evrigui('analysis','-reuse');
figure(eg.handle);


%---------------------------------------------------
function tree_callback(fh,keyword,mystruct,jleaf)
%Left click on tree callback switch yard.
  
highlight(fh);

setview = '';%Should we save cache view.
switch keyword
  case {'viewbylineage' 'lineage'}
    setview = 'lineage';
  case {'viewbydate' 'date'}
    setview = 'date';
  case {'viewbytype' 'type'}
    setview = 'type';
end

if ~isempty(setview)
  setappdata(fh,'cachetreetype',setview)
  evritreefcn(fh,'update');
  %Save cache view as default.
end


%---------------------------------------------------
%functions to help examine modelselector models (aka "nodes")

function out = node(trigger,targets,outputfilters,tags)
%creates a "node" faux model. not really a model but a template for the
%inputs for a modelselector call

if nargin<1
  trigger = [];
end

%check trigger for valid content and determine what the default targets
%should be
iscls = false;
if ~isempty(trigger)
  if ismodel(trigger)
    %CASE: (model,...)  -> ({model},...)
    trigger    = {trigger};
  end
  if iscell(trigger)
    if ~isempty(trigger) & ismodel(trigger{1})
      if isclassification(trigger{1})
        %CASE: ({classification},...)
        deftargets = cell(1,length(trigger{1}.classification.classids)+1);
        iscls = true;
      else
        %CASE: ({model,...},...)
        deftargets = cell(1,length(trigger)-1);
        md = trigger{1};
      end
    elseif ~isempty(trigger)
      %CASE: ({'vartest',...})
      if ~isempty(trigger{1})
        %CASE: ({'vartest','vartest',...},...)
        trigger = [{[]} trigger];   %add [] at beginning -> {[],'vartest','vartest',...}
      end
      deftargets = cell(1,length(trigger)-1);
    end
  else
    %CASE: unrecognized trigger passed...
    trigger = {[]};
    deftargets = {};
  end
else
  %empty trigger = empty targets
  trigger = {};
  deftargets = {};
end

if nargin<2
  targets = deftargets;
elseif iscls
  if length(deftargets)>length(targets)
    targets(end+1:length(deftargets)) = deftargets(length(targets)+1:end);
  elseif length(deftargets)<length(targets)
    targets = targets(1:length(deftargets));
  end
end

if nargin<3
  [outputfilters{1:length(targets)}] = deal('');
else
  [outputfilters{end+1:length(targets)}] = deal('');
  outputfilters = outputfilters(1:length(targets));
end

if nargin<4
  tags = cell(1,length(targets));
else
  [tags{end+1:length(targets)}] = deal('');
  tags = tags(1:length(targets));
end

out = struct('type',{'node'},...
  'trigger',{trigger},...
  'targets',{targets},...
  'outputfilters',{outputfilters},...
  'tags',{tags});

%- - - - - - - - - - - - - - - - - - - - - 
function out = isnode(model)
%returns TRUE if object is a decision node (modelselector object)

out = ~ismodel(model) && isfield(model,'type') && strcmpi(model.type,'node');

%- - - - - - - - - - - - - - - - - - - - - 
function out = isclassificationtrigger(model)

out = ~isempty(model.trigger) && ismodel(model.trigger{1}) && model.trigger{1}.isclassification;

%- - - - - - - - - - - - - - - - - - - - - 
function out = ismodelconditiontrigger(model)

out = ~isempty(model.trigger) && ismodel(model.trigger{1}) && ~model.trigger{1}.isclassification;

%- - - - - - - - - - - - - - - - - - - - - 
function out = isvarconditiontrigger(model)

out = ~isclassificationtrigger(model) && ~ismodelconditiontrigger(model);

%- - - - - - - - - - - - - - - - - - - - - 
function out = isemptynode(model)
%returns TRUE if all targets of a node are empty

if ~isnode(model)
  out = true;
else
  out = all(cellfun('isempty',model.targets));
end

%- - - - - - - - - - - - - - - - - - - - - 
function out = numtargets(model)
%returns number of targets

if ~isnode(model)
  out = 0;
else
  out = length(model.targets);
end

%- - - - - - - - - - - - - - - - - - - - - 
function count = countchildren(node,count)
%calculate number of all tree branches
if nargin<2
  count = 0;
end
count = count+length(node)/2;
for j=1:length(node.targets);
  if isnode(node.targets{j})
    count = count - 1;
    count = countchildren(node.targets{j},count);
  end
end


%---------------------------------------------------
function out = decodemodel(model)
%decodes a modelselector model into a structure for use in this GUI

out = node;
if ~ismodel(model) | ~strcmpi(model.modeltype,'modelselector')
  return
end

%extract trigger
triggermodel = model.content.trigger;
if isempty(triggermodel)  %NOTHING? then return empty node!
  return
end
classificationmodel = false;
switch triggermodel.modeltype
  case 'TRIGGERSTRING'
    out.trigger = triggermodel.triggers;
    if iscell(out.trigger) & ~isempty(out.trigger) & ~ismodel(out.trigger{1})
      %convert variable-based test to correct form by adding empty cell element
      %at start of cell (looks more like model based tests except model is
      %empty)
      out.trigger = [{[]} out.trigger];
    end
  otherwise
    %simple classification-based test, just create cell with model
    out.trigger = {triggermodel};
    classificationmodel = true;
end

%copy targets
out.targets = model.targets;
for j=1:length(out.targets)
  %convert any model-selector models into nodes as we go
  if ismodel(out.targets{j}) & strcmpi(out.targets{j}.modeltype,'modelselector')
    out.targets{j} = decodemodel(out.targets{j});
  end
end
if ~classificationmodel & length(out.trigger)-1<length(out.targets)
  %add empty string if this model has an otherwise segment
  out.trigger{end+1} = '';
end

%copy outputfilters
out.outputfilters = model.outputfilters;
if isempty(out.outputfilters)
  [out.outputfilters{1:length(out.targets)}] = deal('');
end

%---------------------------------------------------
function [out,err,errindex] = encodemodel(model,guiopts,index)
%creates a modelselector model from a structure created in this GUI

if nargin<3 | isempty(index)
  index = [];
  guiopts = reconopts(guiopts,'modelselectorgui');
end
err = '';
errindex = [];
  
if isempty(model.targets)
  err = 'No target end-points have been defined.';
  if isempty(index);
    errindex = 0;
  else
    errindex = index;
  end
  out = [];
  return;
end

for j=1:length(model.targets)
  %convert any nodes into model-selector models as we go
  if isnode(model.targets{j})
    [model.targets{j},err,errindex] = encodemodel(model.targets{j},guiopts,[index j]);
    if ~isempty(err)
      out = [];
      return;
    end
  end
end

%convert trigger into correct form
trigger = model.trigger;
if isclassificationtrigger(model)
  %classification models take care of themselves
  trigger = trigger{1};
else
  %either variable trigger or regression/projection model trigger
  
  % GOOD trigger examples:
  %  { model 'cond' ''        }    = good trigger
  %  { model 'cond' 'cond' '' }    = BAD trigger
  % BAD trigger examples:
  %  { model ''              }     = BAD trigger
  %  { model 'cond'          }     = BAD trigger
  %  { model 'cond' 'cond'   }     = BAD trigger
  %  { model 'cond' ''  ''   }     = BAD trigger
  
  %check for empty trigger strings
  emptytrigger = cellfun('isempty',trigger) & cellfun('isclass',trigger,'char');

  %  { model ''        }     = BAD model trigger
  if (length(trigger)==2 & emptytrigger(2))
    err = 'Condition must be defined for first node.';
    errindex = 1;
    if ~isempty(index);
      errindex = [index errindex];
    end
    out = [];
    return;
  end

  %  { model 'cond'  ''  ''  }     = BAD too many otherwise
  if (length(trigger)>2 & sum(emptytrigger(2:end))>1)
    err = 'Empty Condition string not permitted (except as last end-node "Otherwise" case)';
    errindex = min(find(emptytrigger(2:end)));
    if ~isempty(index);
      errindex = [index errindex];
    end
    out = [];
    return;
  end
  
  %  { model 'cond'          }     = BAD missing otherwise
  %  { model 'cond' 'cond'   }     = BAD missing otherwise
  if length(trigger)<3 | (~any(emptytrigger(2:end)))
    %missing an otherwise
    err = 'End point is missing an "Otherwise" end-node. The model needs an output if none of the conditions on this rule are met.';
    if isempty(index);
      errindex = length(trigger);
    else
      errindex = [index length(trigger)];
    end
    out = [];
    return;
  end

  %  { model 'cond'  ''  ''  }     = BAD too many otherwise
  if any(emptytrigger(2:end-1))
    err = 'Empty Condition string not permitted (except as last end-node "Otherwise" case)';
    errindex = min(find(emptytrigger(2:end-1)));
    if ~isempty(index);
      errindex = [index errindex];
    end
    out = [];
    return;
  end

  if isempty(trigger{1})
    %variable trigger
    trigger = trigger(2:end);
  end
  trigger(end) = [];  %drop empty tests at end (this is the "otherwise" statement)

end

%check for missing targets
if isempty(model.targets)
  err = 'No targets defined for Rule';
  errindex = index;
  out = [];
  return;
end

%set up options (including output filters)
msopts = struct('plots','none','display','off');
filters = model.outputfilters;
msopts.qtestlimit = guiopts.plsdaqlimit;
msopts.t2testlimit = guiopts.plsdat2limit;
msopts.multiple = guiopts.multiple;

%if all output filters have only one selected item, do NOT include labels
uselabels = false;
for j=1:length(filters)
  if iscell(filters{j}) & length(filters{j})>1
    uselabels = true;
    break;
  end
end
if ~uselabels
  for j=1:length(filters)
    if iscell(filters{j})
      for k=1:length(filters{j})
        if iscell(filters{j}{k}) & length(filters{j}{k})==2;
          filters{j}{k} = filters{j}{k}{2};
        end
      end
    end
  end
end
msopts.outputfilters = filters;

%build actual model, but trap errors and return (so we can give "nice"
%error and highlight the bad node in the GUI)
try
  out = modelselector(trigger,model.targets{:},msopts);
  out.reducedstats = guiopts.reducedstats;
catch
  err = lasterr;
  errindex = index;
  out = [];
  return;
end

%---------------------------------------------------
function varargout = buildmodel(fig,varargin)
%build model and store in GUI

fig = findparentfig(fig);

emodel = getappdata(fig,'builtmodel');
if ~isempty(emodel)
  if nargout>0
    %asking for output? check if model is already there
      varargout = {emodel};
  else
    helpdlg('Model has already been built. To apply model, drag data to model canvas.','Model Build Unneeded')
  end
  return
end

%erase old model
setappdata(fig,'builtmodel',[]);
updatetoolbar(fig);

%try building model
model = getappdata(fig,'model');
[emodel,err,errindex] = encodemodel(model,getappdata(fig,'preferences'));
if ~isempty(err)
  %highlight faulty node
  highlightindex(fig,errindex,1)
  %returned errors? display them
  erdlgpls(err,'Model Building Error');
  if nargout>0
    varargout = {[]};
  end
  return
end

setappdata(fig,'builtmodel',emodel);
modelcache(emodel);
evritreefcn(fig,'update');
updatetoolbar(fig);

if nargout==0
  helpdlg('Model built without error','Model Build Complete')
else
  varargout = {emodel};
end

%---------------------------------------------------
function varargout = classify(fig,varargin)
%automate classification model and populate canvas

% supported in R2018b and up
if checkmlversion('<','9.5')
  evrierrordlg('Feature supported only for MATLAB R2018b and newer versions.')
  return
end


% check if gui is already floating around
h = findall(groot,'Type','Figure','Name','Automatic Classifier Settings');
if ~isempty(h)
  if length(h)==1
    set(h,'Visible','on');
    figure(h);
  else
    %Hmm, kill all and recall classify?
    delete(h);
    varargout = classify(fig,varargin);
  end
else
  hmacgui = hmacGui();
end

%---------------------------------------------------
function applymodel(fig,data,varargin)
%apply current model to data

model = buildmodel(fig);
if isempty(model)
  %probably had an error
  return;
end

set(0,'currentfigure',fig);
shg;

try
  [res,smindex] = modelselector(data,model,struct('plots','none','display','off','waitbar','on','errors','struct'));
catch
  evrierrordlg(lasterr,'Error on Apply');
  return;
end
if ~isempty(smindex)
  highlightindex(fig,smindex(end,:),0.5)  %highlight last one
end

if isdataset(res) | isnumeric(res)
  editds(res);
else
  if iscell(res) & ~all(cellfun('isclass',res,'char'))
    %NOT all characters
    res = encode(res);
  elseif ~iscell(res) & ~ischar(res)
    res = encode(res);
  end
  infobox(res,struct('figurename','Hierarchical Model Results'));
end


%---------------------------------------------------
function saved = savemodel(fig,varargin)
%save built model

fig = findparentfig(fig);
model = buildmodel(fig);

saved = false;
if ~isempty(model) & ismodel(model) & strcmpi(model.modeltype,'modelselector')
  varname = defaultmodelname(model,'variable','save');
  name    = svdlgpls(model,'Save ModelSelector Model...',varname);
  if ~isempty(name)
    setappdata(fig,'modelsaved',true);
    saved = true;
  end
end

%---------------------------------------------------
function saved = copyfigure(fig,varargin)
%Copy image of figure.

%Reduce size of cache first so it doesn't show up in image then put back to
%original position.
fig = findparentfig(fig);
handles = guihandles(fig);
xdatoriginal = get(handles.resizeframe,'xdata');
map = getappdata(fig,'hitmap');
sliderh = findobj(fig,'tag','xslider');
sliderhy = findobj(fig,'tag','yslider');
fpos = get(handles.modelselectorgui,'position');
% cachesize(fig,max(mincachesize,fpos(3)-xd(3)));

%get some info
tbxttl = findobj(fig,'tag','toolboxtitle');
tbitems = [findobj(fig,'userdata','toolbox');findobj(fig,'tag','toolboxpatch');sliderh;sliderhy];
str = get(tbxttl,'string');

try
  %hide cache
  set(handles.resizeframe,'xdata',[fpos(3) fpos(3) fpos(3) fpos(3)])
  resizecache([],fig,handles.resizeframe)%Calls resize.
  
  %hide toolbox
  set(tbitems,'visible','off')
  set(tbxttl,'string','');
  
  if isempty(getappdata(fig,'selecteditem'))
    delete(findobj(allchild(fig),'userdata','objcontrol'));
  end
  
  %Get
  axh= get(fig,'currentaxes');
  ax_pos = get(axh,'position');
  
  slider_stepsh = ceil(size(map,2)/ax_pos(3));%Total width of image divided by with of axis rounded up.
  slider_stepsv = ceil(size(map,1)/ax_pos(4));%Total height of image divided by with of axis rounded up.
  %get image
  drawnow;pause(.2)%Need good pause so screen gets updated.
  figure(fig)
  
  %Need to stitch image together.
  myimg = [];%Aggregate image.
  startposv = get(sliderhy,'max');%Start in upper left corner.
  for j = 1:slider_stepsv
    
    if startposv<get(sliderhy,'min')
      set(sliderhy,'value',get(sliderhy,'min'))
    else
      set(sliderhy,'value',startposv)
    end
    resize(fig)
    drawnow;pause(.2)
    startposh = 1;
    myimg_row = [];%Rows of aggregate image (to concat).
    for i = 1:slider_stepsh
      if startposh>get(sliderh,'max')
        set(sliderh,'value',get(sliderh,'max'))
      else
        set(sliderh,'value',startposh)
      end
      resize(fig)
      %Need to make sure everything renders, this takes time and is on
      %seperate thread so pause is needed.
      figure(fig)
      drawnow;
      pause(.2)
      %Make sure figure is on top since we have time lage.
      figure(fig)
      thisimg = grabscreenshot(fig);%Get image.
      if startposh>get(sliderh,'max')
        %At right side end of image so cut in proper place.
        cutath = round(startposh-get(sliderh,'max'));
        thisimg = thisimg(:,cutath:end,:);
      end
      
      if startposv<get(sliderhy,'min')
        cutatv = round(startposv-get(sliderh,'min'));
        thisimg = thisimg(abs(cutatv):end,:,:);
      end
        
        
      %Add to main image.
      myimg_row = [myimg_row thisimg(2:end,1:end-2,:)];%Cut last 2 pixels of, seem to be overlap.
      startposh = startposh+round(ax_pos(3)-2);%Next position in pixels.
    end
    myimg = [myimg; myimg_row];
    startposv = startposv-round(ax_pos(4))+1;%Next position in pixels. Seems to be edge affect so add one.
  end
  
  %If clipboard_image doesn't work try a new figure and exportfigure.
  clipboard_image('copy',myimg,struct('usescale','no'));
  
  %f = figure;
  %imagesc(myimg);
  %exportfigure('clipboard',f);
  
catch
  evriwarndlg('Unable to copy image of Model Selector to clipboard.','Unable to Copy')
end

set(tbitems,'visible','on')
set(tbxttl,'string',str);
set(handles.resizeframe,'xdata',xdatoriginal)
resizecache([],fig,handles.resizeframe)%Calls resize.
drawnow

%---------------------------------------------------
function imgData= grabscreenshot(fig)
%Get a raw screen shot of figure.
%Use code from Yair tool.

img_area = get(fig,'position');
scrnsz = get(0,'screensize');
%Java is upper left indexed so change img_area(2).
img_area(2) = scrnsz(4)-(img_area(2)+img_area(4));

if isempty(img_area) | all(img_area==0) | img_area(3)<=0 | img_area(4)<=0  %#ok ML6
  imgData = [];
else
  % Use java.awt.Robot to take a screen-capture of the specified screen area
  rect = java.awt.Rectangle(img_area(1), img_area(2), img_area(3), img_area(4));
  robot = java.awt.Robot;
  jImage = robot.createScreenCapture(rect);
  
  % Convert the resulting Java image to a Matlab image
  % Adapted for a much-improved performance from:
  % http://www.mathworks.com/support/solutions/data/1-2WPAYR.html
  h = jImage.getHeight;
  w = jImage.getWidth;
  
  % Performance even further improved based on feedback from Jan Simon:
  pixelsData = reshape(typecast(jImage.getData.getDataStorage, 'uint8'), 4, w, h);
  imgData = cat(3, ...
    transpose(reshape(pixelsData(3, :, :), w, h)), ...
    transpose(reshape(pixelsData(2, :, :), w, h)), ...
    transpose(reshape(pixelsData(1, :, :), w, h)));
end

%---------------------------------------------------
function loadmodel(fig,varargin)
%load model
% I/O: loadmodel(fig)  %prompt user
% I/O: loadmodel(fig,model)  %load specified model

fig = findparentfig(fig);
if nargin<2 | isempty(varargin{1}) | ~ismodel(varargin{1})
  model = lddlgpls('model','Load ModelSelector Model...');
  if isempty(model)
    return;
  end
else
  model = varargin{1};
end

if ~ismodel(model) | ~strcmpi(model.modeltype,'modelselector')
  erdlgpls('Specified model is not a ModelSelector model','Invalid Model')
  return;
end
modelobj = model;
model = decodemodel(model);

%update preferences from model settings
pref = getappdata(fig,'preferences');
pref.reducedstats = modelobj.reducedstats;
pref.plsdaqlimit = modelobj.detail.options.qtestlimit;
pref.plsdat2limit = modelobj.detail.options.t2testlimit;
pref.multiple = modelobj.detail.options.multiple;

setappdata(fig,'preferences',pref);

%check if current node is empty and give warning if not
hlookup = getappdata(fig,'hlookup');
current = getselobject(fig,hlookup{1}(1));
msaved = getappdata(fig,'modelsaved');
if ~msaved & isnode(current) & ~isemptynode(current)
  conf = questdlg('Overwrite this entire tree and all children?','Overwrite Tree?','Overwrite','Cancel','Overwrite');
  if strcmpi(conf,'cancel'); return; end
end
assigninmodel(fig,[],model)

%save loaded model as "builtmodel" so that we don't rebuild from what we
%just decoded (it would match exactly and get cached again)
setappdata(fig,'builtmodel',modelobj);
setappdata(fig,'modelsaved',true);

draw(fig);
%delete edit controls and check for redraw requirement
objcontrol = findobj(fig,'userdata','objcontrol');
if ~isempty(objcontrol)
  objcontrol = objcontrol(ishandle(objcontrol));
  delete(objcontrol); %delete edit controls for this object
  if getappdata(fig,'forceredraw')
    draw(fig);
    return;
  end
end

%-----------------------------------------------------
function type = objtype(obj)

if isnode(obj)
  if isclassificationtrigger(obj)
    type = 'triggercls';
  elseif ismodelconditiontrigger(obj)
    if iscell(obj.trigger) & ~isempty(obj.trigger) & ismodel(obj.trigger{1}) & length(obj.trigger{1}.datasource)>1
      type = 'triggerreg';
    else
      type = 'triggerpro';
    end
  elseif iscell(obj.trigger) & length(obj.trigger)>1 & isempty(obj.trigger{1})
    type = 'triggervar';
  else
    type = 'trigger';
  end
elseif ischar(obj)
  type = 'string';
elseif isempty(obj)
  type = [];
elseif ismodel(obj) & ~obj.isprediction
  type = 'model';
elseif isstruct(obj) & isfield(obj,'error')
  type = 'error';
elseif isnumeric(obj)
  type = 'value';
else
  type = [];
end

%-----------------------------------------------------
function val = settargetas(fig,type)

if nargin==1
  type = fig;
  fig = [];
end
if isnode(type)
  val = type;
else
  switch type
    case {'v' 'value' 'numeric'}
      val = 0;
    case {'s' 'string'}
      val = '';
    case {'m' 'model'}
      val = lddlgpls('model');
      if isempty(val) | ~ismodel(val)
        return;
      end
    case {'t' 'trigger' 'node'}
      val = node;
    case {'e' 'error'}
      val = struct('error','unspecified error');
    case {'d' 'delete'}
      val = [];
    otherwise
      error('unrecognized type')
  end
end

if nargout==0 & ~isempty(fig)
  settarget(fig,val)
  clear val  %clear so it isn't returned
end

%---------------------------------------------------
%settarget_____ helper functions (shortcut functions to set a particular
%type; actual work is done in settargetas() function)
function settarget_valuenumeric(varargin)
settargetas(varargin{1},'v');

%- - - - - - - - - - - - - - 
function settarget_valuestring(varargin)
settargetas(varargin{1},'s');

%- - - - - - - - - - - - - - 
function settarget_model(varargin)
settargetas(varargin{1},'m');

%- - - - - - - - - - - - - - 
function settarget_trigger(varargin)
wh = evriquestdlg('Load model from File or from Model Cache?','Load Model From...','File','Model Cache','Cancel','File');

if strcmpi(wh,'cancel')
  return;
end
if strcmpi(wh,'Model Cache')
  evrihelpdlg('To load model from Model Cache, drag from frame on the right.','Model Cache Help');
  return;
end
model = lddlgpls('model');
if isempty(model); return; end
if ~ismodel(model) | model.isprediction
  erdlgpls('Object is not a valid Model object','Invalid Model')
  return
end
if strcmpi(model.modeltype,'modelselector')
  %decode modelselector as node (i.e. they said they wanted a model-based
  %node but the loaded a modelselector itself!!)
  model = decodemodel(model);
else
  %otherwise, embed in node
  model = node(model);
end
settargetas(varargin{1},model);

%- - - - - - - - - - - - - - 
function settarget_vartrigger(varargin)
settargetas(varargin{1},node({'"var"<1'},{}))

%- - - - - - - - - - - - - - 
function settarget_error(varargin)
settargetas(varargin{1},'e');

%- - - - - - - - - - - - - - 
function deleteitem(varargin)
settargetas(varargin{1},'d');

%---------------------------------------------------
function makenode(varargin)
%convert a target model to a trigger model

fig = varargin{1};
fig = findparentfig(fig);
obj = getselobject(fig);
if ismodel(obj)
  content = node(obj);
  if isempty(content);
    return;
  end
  settarget(fig,content);
end

%---------------------------------------------------
function makeendpoint(varargin)
%convert a trigger model to a target model

fig = varargin{1};
fig = findparentfig(fig);
obj = getselobject(fig);
if isnode(obj) 
  content = obj.trigger;
  if ~ismodel(content)
    %if not a model itself
    if iscell(content) & ~isempty(content) & ismodel(content{1})      
      content = content{1};
    else
      %data-based test OR otherwise invalid model
      content = [];
    end
  end
  if ~isempty(content)
    settarget(fig,content,[],false);  %drop but do NOT merge
  end
end

%---------------------------------------------------
function chooseoutputs(obj,varargin)

ref = getappdata(obj,'refhandle');
if ~isempty(ref)
  %for button callbacks
  info = getappdata(ref);
  if ~isfield(info,'value') | ~ismodel(info.value)
    return;
  end
  model = info.value;
else
  %for context menu callbacks
  [content,S,index,ref] = getselobject(gcbf);
  model = content;
  if ~ismodel(model)
    return;
  end
end

list = getmodeloutputs(model,-1);

if isempty(list)
  %Error message displayed in getmodeloutputs.m.
  return;
end

%find CURRENTLY selected items in list
fig = findparentfig(ref);
[content,S,index,mobj] = getselobject(fig);
parent = getselobject(fig,getappdata(mobj,'parent'));
inds = [];  %default is none selected
if length(parent.outputfilters)>=index(end)
  %if we have an entry for this item
  filters = parent.outputfilters{index(end)};
  for j=1:length(filters)
    if iscell(filters{j})
      %if it is a multi-column cell {desc substruct} then use last column
      filters{j} = filters{j}{end};
    end
    filters{j} = encodexml(filters{j},'item');
  end
  inds = strlookup(filters,list(:,3));
end
selitems = list(inds,1);

%ask user for which they want to use
[selitems, btnpushed] = listchoosegui(list(:,1),selitems);
if ~strcmpi(btnpushed,'ok')
  return;
end

%get index of selected items and grab the first and second columns to store
inds = strlookup(selitems,list(:,1));
item = {};
for j=1:length(inds);
  item{j} = list(inds(j),1:2);
end
setfilter(fig,item);
draw(fig);
highlightindex(fig,index,1);

%---------------------------------------------------
function out = decodesubstruct(st)
%convert substruct into a human-friendly form

out = '';
for j=1:length(st)
  t = st(j).type;
  s = st(j).subs;
  switch t
    case '.'
      out = [out '.' st(j).subs];
    case {'()' '{}' '[]'}
      for j=1:length(s)
        if ~ischar(s{j}); s{j} = num2str(s{j}); end
      end
      indx = sprintf('%s,',s{:});
      indx = indx(1:end-1);
      out = [out t(1) indx t(2)];
  end
end

%---------------------------------------------------
function inds = strlookup(strcell,lookup)

[junk,ii,jj] = intersect(lookup,strcell);
rev = nan(1,max(jj));
rev(jj) = 1:length(jj);
rev(isnan(rev)) = [];
inds = ii(rev);

%---------------------------------------------------
function setfilter(fig,content,index)
%lower-level function to assign new filter content into specified item's parent.
fig = findparentfig(fig);
if nargin>2
  obj = getobjbyindex(fig,index);
else
  obj = [];
end
[current,S,index,obj] = getselobject(fig,obj);

[parent,parentS] = getselobject(fig,getappdata(obj,'parent'));
saveparent = false;
if ~isempty(parent)
  if length(parent.outputfilters)<index(end)
    %make sure we have enough filter strings to start
    [parent.outputfilters{end+1:index(end)}] = deal('');
    saveparent = true;
  end
  if ~comparevars(parent.outputfilters{index(end)},content)
    %assign new value to filter cell (if different from whats there)
    parent.outputfilters{index(end)} = content;
    saveparent = true;
  end
  
  if saveparent
    assigninmodel(fig,parentS,parent);
  end
end

%---------------------------------------------------
function settriggerstring(fig,trigger,index)
%lower-level function to assign new trigger string into specified item's parent.
fig = findparentfig(fig);
if nargin>2
  obj = getobjbyindex(fig,index);
else
  obj = [];
end
[current,S,index,obj] = getselobject(fig,obj);

[parent,parentS] = getselobject(fig,getappdata(obj,'parent'));
saveparent = false;
if ~isempty(parent)
  if ~isclassificationtrigger(parent)
    
    %wrong type of initial value in trigger list? Fix it now
    if isempty(parent.trigger) | isempty(parent.trigger{1}) & ischar(parent.trigger{1})
      parent.trigger{1} = [];
      saveparent = true;
    end
    
    if length(parent.trigger)<index(end)+1
      %make sure we have enough trigger strings to start
      [parent.trigger{end+1:index(end)+1}] = deal('');
      saveparent = true;
    end
    if ~comparevars(parent.trigger{index(end)+1},trigger)
      %assign new value to trigger cell (if different from whats there)
      parent.trigger{index(end)+1} = trigger;
      saveparent = true;
    end
    
    if saveparent
      assigninmodel(fig,parentS,parent);
    end
  end
end

%---------------------------------------------------
function settarget(fig,content,index,merge)
%lower-level function to assign new content (target)
% Optional "index" input assigns input to specified index, otherwise
% currently selected item is assigned value
% optional input "merge" is boolean flag saying whether or not to merge the
% new content in with the old or to overwrite (ignoring previous content).
% Generally merging is preferred (exception: REPLACING model-based node
% with model end-point) 

fig = findparentfig(fig);
if nargin>2 & ~isempty(index)
  obj = getobjbyindex(fig,index);
else
  obj = [];
end
[current,S,index,obj] = getselobject(fig,obj);

if nargin<4
  merge = true;
end

if isempty(S) & ~isnode(content) & ~ismodel(content)
  %don't allow dropping of non-model or non-node on root item (and don't
  %bother asking user if its OK)
  return;
end

%check if we're about to overwrite a node
needconfirm = false;
if ~ismodel(content) & isnode(current) & ~isemptynode(current)
  needconfirm = isempty(getappdata(fig,'builtmodel'));  %if model has changed since we last built it, we need to confirm this action
  if ~ischar(content) & isempty(content)
    msg = 'Delete';
  else
    msg = 'Overwrite';
  end
end

saveobj = true;
if isempty(S) %root node
  %check if content is a modelselector model and convert as needed
  if ismodel(content) & strcmpi(content.modeltype,'modelselector')
    %modelselector on top node? LOAD model using standard load
    loadmodel(fig,content)
    return;
  end
  if ~isnode(content) & (~ismodel(content) | content.isprediction)
    return;
  end
else  %other than root-node
  %check if content is a modelselector model and convert as needed
  if ismodel(content) & strcmpi(content.modeltype,'modelselector')
    content = decodemodel(content);
  end
  %check if parent is a condition-based node
  parentobj = getappdata(obj,'parent');
  [parent,parentS] = getselobject(fig,parentobj);
  if ~isempty(parent)
    saveparent = false;
    if ~isclassificationtrigger(parent)
      %node which needs conditions...
      if isempty(parent.trigger) | isempty(parent.trigger{1}) & ischar(parent.trigger{1})
        parent.trigger{1} = [];
        saveparent = true;
      end
      
      if ~isempty(content) | ischar(content)
        %adding non-empty item
        if length(parent.trigger)<index(end)+1
          [parent.trigger{end+1:index(end)+1}] = deal('');
          saveparent = true;
        end
      else
        %deleting item
        if length(parent.trigger)>=index(end)+1
          parent.trigger(index(end)+1) = [];
        end
        if length(parent.targets)>=index(end)
          parent.targets(index(end)) = [];
        end
        if length(parent.trigger)==1 & length(parent.targets)==1
          %otherwise case needs empty string added
          parent.trigger{end+1} = '';
        end
        saveparent = true;
        saveobj = false;  %we just DELETED the target content - do NOT save it later
      end
      
    end
    
    if saveobj & length(parent.outputfilters)>=index(end) & ~isempty(parent.outputfilters{index(end)})
      %saving object? clear out any outputfilter (if present and non-empty)
      parent.outputfilters{index(end)} = [];
      saveparent = true;
    end

    if saveparent
      if needconfirm & ~confirmoverwrite(msg)
        return;
      end
      needconfirm = false;
      %save parent (but do NOT cache this event if we're also going to save
      %the object itself below)
      assigninmodel(fig,parentS,parent,saveobj);
    end

  end
end

if saveobj;
  if needconfirm & ~confirmoverwrite(msg)
    return;
  end
  assigninmodel(fig,S,content,false,merge);  %noundo = false, merge = ??maybe
end
draw(fig);
highlightindex(fig,index,1)

%---------------------------------------------------
function out = confirmoverwrite(msg)

if nargin<1 | isempty(msg)
  msg = 'Overwrite';
end
conf = questdlg([msg ' this decision rule and its children?'],[msg ' Rule?'],msg,'Cancel',msg);
out = ~strcmpi(conf,'cancel');


%---------------------------------------------------
function clearcanvas(varargin)

if nargin<1
  varargin{1} = gcbf;
end
fig = findparentfig(varargin{1});
settarget(fig,node,0);

%---------------------------------------------------
function [content,S,index,obj] = getselobject(fig,obj)
%get the currently selected object
%returns;
%  content = actual content of object
%  S       = subscripting into model to reach object
%  index   = raw indexing for object
%  obj     = graphical object corresponding to selected item

fig = findparentfig(fig);
model = getappdata(fig,'model');
if nargin<2
  obj = [];
end
[S,index,obj] = getobjindex(fig,obj);
if isempty(S)
  content = model;
else
  le = lasterror;
  try
    content = subsref(model,S);
  catch
    lasterror(le)
    content = [];
  end
end

%--------------------------------------------------
function assigninmodel(fig,S,content,noundo,merge)
%assign an object to the model WITHOUT display update

if nargin<4;
  noundo = false;
end
if nargin<5
  merge = true;
end
fig = findparentfig(fig);
model = getappdata(fig,'model');
if isempty(S)
  %root node
  if ~isnode(content)
    if ismodel(content)
      content = node(content);
      if isempty(content)
        return;
      end
    else
      %only replace top-level node with a new node (NOTHING ELSE!)
      return
    end
  end
  oldcontent = model;  
else
  %sub-objects
  %examine what WAS there and see if we can translate it over
  try
    oldcontent = subsref(model,S);
  catch
    oldcontent = [];
  end
end

if merge & ~isempty(oldcontent) & ~isempty(content)
  newtype = objtype(content);
  oldtype = objtype(oldcontent);
  switch newtype
    case 'error'  % -> error
      switch oldtype
        case 'string'   % string -> error
          content.error = oldcontent;
      end
      
    case 'string'  % -> string
      switch oldtype
        case 'error'   % error -> string
          if ~strcmpi(oldcontent.error,'unspecified error')
            content = oldcontent.error;
          end
      end
      
    case 'model'
      switch oldtype
        case {'triggerreg' 'triggerpro' 'triggervar'}
          %insert model INTO trigger
          oldcontent.trigger{1} = content;
          content = oldcontent;
        case {'triggercls'}
          if isclassificationtrigger(oldcontent) & isclassification(content)
            content = node(content,oldcontent.targets,oldcontent.outputfilters,oldcontent.tags);
          else
            content = node(content);
          end
      end
      
  end
end

%store new content
if isempty(S)
  model = content;
else
  model = subsasgn(model,S,content);
end

if ~noundo
  undo(fig,model);  %store for undo history
end
setappdata(fig,'builtmodel',[]);
setappdata(fig,'model',model);
setappdata(fig,'modelsaved',false);

%---------------------------------------------------
function editmenu(h,varargin)
fig = findparentfig(h);
[undos,redos] = undo(fig);
if undos
  uen = 'on';
else
  uen = 'off';
end
if redos
  ren = 'on';
else
  ren = 'off';
end
set(findobj(h,'tag','editundo'),'enable',uen);
set(findobj(h,'tag','editredo'),'enable',ren);

%---------------------------------------------------
function doundo(varargin)
fig = findparentfig(varargin{1});
undos = undo(fig);
if undos>0
  model = undo(fig,-1);
  setappdata(fig,'builtmodel',[]);
  setappdata(fig,'model',model);
  setappdata(fig,'modelsaved',false);
  draw(fig);
  highlight(fig);
end
%---------------------------------------------------
function doredo(varargin)
fig = findparentfig(varargin{1});
[undos,redos] = undo(fig);
if redos>0
  model = undo(fig,+1);
  setappdata(fig,'builtmodel',[]);
  setappdata(fig,'model',model);
  setappdata(fig,'modelsaved',false);
  draw(fig);
  highlight(fig);
end

%---------------------------------------------------
function varargout = undo(fig,item)
%UNDO - manage undo list
%I/O:   undo(fig,item)    %store item in undo list
%I/O:   [undos,redos] = undo(fig);     %return current number of items in list in front and behind current one
%I/O:   out = undo(fig,-1);  %"undo" (grab last item from list and move pointer back)
%I/O:   out = undo(fig,1);  %"redo" (grab next item from list and move pointer FORWARD)

maxundo = 15;

%get items
list = getappdata(fig,'undo');
p = getappdata(fig,'undopointer');
if isempty(p)
  list = {};
  p = 0;
end

if nargout==2 | nargin<2
  %return number of items
  varargout = {max([0 p-1]) length(list)-p};
  return
  
elseif nargout==1
  %do undo/redo
  % item is flag for "redo"
  if item<0
    %undo
    if p>1
      %move pointer and return undo item
      p = p-1;
      varargout = {list{p}};
    else
      %no items to undo
      varargout = {[]};
    end
  else
    %redo
    if p<length(list);
      p = p+1;
      varargout = {list{p}};
    else
      varargout = {[]};
    end
  end
  
elseif ischar(item) & strcmpi(item,'clear')
  %CLEAR undo history
  list = {};
  p = 0;
  
else
  %store item in list
  p = p+1;
  list{p} = item;
  if length(list)>p
    %remove old "redo" history
    list = list(1:p);
  end
  if length(list)>maxundo & p == length(list);
    %truncate if we extended the list and it exceeds allowed length
    list = list(end-maxundo+1:end);
    p = length(list);  %point at item in end location
  end
end

setappdata(fig,'undo',list);
setappdata(fig,'undopointer',p);

%---------------------------------------------------
function obj = getobjbyindex(fig,index)
%returns object referenced by a given index

hlookup = getappdata(fig,'hlookup');
if isempty(index)
  ind = 1;
else
  ncols = size(hlookup{2},2);
  if length(index)<ncols
    index(ncols) = 0;
  end
  ind = find(all(scale(hlookup{2},index)==0,2));
end
if ~isempty(ind)
  obj = hlookup{1}(ind(1));
else
  obj = [];
end

%---------------------------------------------------
function [S,index,obj] = getobjindex(fig,obj)
%returns index into model cell of selected item

if nargin<2 | isempty(obj)
  obj = getappdata(fig,'selecteditem');
end
if isempty(obj) | ~ishandle(obj)
  S = [];
  index = [];
  obj = [];
  return;
end
index = getappdata(obj,'index');
if index(1)==0;
  S = []; 
  index = [];
  obj = [];
  return
end
S = substruct('.','targets','{}',{index(1)});
for i=2:length(index); 
  S = [S substruct('.','targets','{}',{index(i)})]; 
end

%---------------------------------------------------
function resize(fig,varargin)
%resize figure

fig = findparentfig(fig);
set(fig,'units','pixels');
fpos = get(fig,'position');
axh= get(fig,'currentaxes');
if isempty(axh); return; end
ymax = getappdata(axh,'ymax');

padding = 20;

%do not allow figure to be shorter than tree (for now - later we may add
%scrolling logic)
% if fpos(4)<ymax
%   fpos(2) = fpos(2)-(ymax-fpos(4)+padding);
%   fpos(4) = ymax+padding;
%   set(fig,'position',fpos)
% end

%don't allow width to be narrower than toolbox
ph = findobj(fig,'tag','toolboxpatch');
minwidth = getappdata(ph,'minwidth');
needed = minwidth-(fpos(3)-cachesize(fig))+10;
if needed>0
  csize = cachesize(fig);
  if csize>mincachesize
    %shrink cachesize first if we can
    csize = max(mincachesize,csize-needed);
    cachesize(fig,csize);
    needed = max(0,minwidth-(fpos(3)-cachesize(fig))+10);
  end
  fpos(3) = fpos(3)+needed/(1-cachesize);  %and then make figure wider if still needed
  set(fig,'position',fpos)
end

%adjust axes to fit figure
left = getslidershift(fig);
map = getappdata(fig,'hitmap');
set(axh,'units','pixels');
axsize = [fpos(3)-cachesize(fig) fpos(4)];
set(axh,'position',[1 1 axsize]);

%add slider for horizontal
sl = findobj(fig,'tag','xslider');
right = axsize(1);
neededwidth = size(map,2)+padding+100;%Add 100 for any text on right of last item.
if neededwidth>right
  if isempty(sl)
    sl = uicontrol(fig,'style','slider','tag','xslider','units','pixels',...
      'min',0,'max',1,'callback',@resize);
  end
  slidermax = neededwidth-right+1;
  set(sl,'position',[0 0 axsize(1)-28 padding-2],'min',1,'max',slidermax,...
    'sliderstep',[.1 .9],'value',max(1,min(slidermax,left)));
else
  if ~isempty(sl)
    delete(sl);
  end
  left = 1;
end

%add slider for vertical
sl = findobj(fig,'tag','yslider');
bottompos = getslidershift_y(fig);
mytop = axsize(2);
neededheight = size(map,1)+padding;
slidermax = max(1,neededheight-mytop+1);
if neededheight>mytop
  if isempty(sl)
    sl = uicontrol(fig,'style','slider','tag','yslider','units','pixels',...
      'min',0,'max',1,'callback',@resize);
  end
  set(sl,'position',[right-22 2 padding-2 axsize(2)-38 ],'min',-40,'max',slidermax,...
    'sliderstep',[.1 .9],'value',min(slidermax,bottompos));
else
  if ~isempty(sl)
    delete(sl);
  end
  mytop = 1;
end

%give 1:1 pixel size on axes
xlim = [1 axsize(1)]-1+left;
ylim = [1 axsize(2)]-1+(slidermax-bottompos);
set(axh,'xlim',xlim,'ylim',ylim);  %set axis limits to fit figure

%Adjust toolbar frame and contents
set(ph,'xdata',[0 0 axsize([1 1])+left-8 0],'ydata',[ylim(1) tbwidth+ylim(1) tbwidth+ylim(1) ylim(1) ylim(1)]-1);
tih = findobj(fig,'tag','toolboxtitle');
set(tih,'position',[13+left-1 ylim(1)+18 0])
tbh = findobj(fig,'userdata','toolbox');
if ~isempty(tbh)
  for j=1:length(tbh);
    xd = getappdata(tbh(j),'xdata');
    xd = xd+left;
    set(tbh(j),'xdata',xd);
    setappdata(tbh(j),'originalx',xd);
    set(tbh(j),'ydata',[ylim(1)+4 ylim(1)+34])
  end
end

%adjust object controls
hs = findobj(fig,'userdata','objcontrol');
if ~isempty(hs)
  for j=1:length(hs)
    pos = getappdata(hs(j),'position');
    newpos = [pos(1)-left fpos(4)-pos(2) pos(3:4)];
    set(hs(j),'position',newpos)
    offscreen(j) = newpos(1)>axsize(1);
  end
  if all(offscreen)
    vis = 'off';
  else
    vis = 'on';
  end
  set(hs,'visible',vis);
end

%adjust Cache tree container
treecontainer = getappdata(fig,'treecontainer');
set(treecontainer,'Units','pixels','Position',[axsize(1)+1 0 cachesize(fig) axsize(2)])

%adjust Cache resize marker
h = findobj(fig,'tag','resizeframe');
xd = get(h,'xdata');
yd = get(h,'ydata');
xd = xd-xd(1);
xd = xd+xlim(2)-xd(3);
yd(2:3) = max(ylim);
set(h,'xdata',xd,'ydata',yd)

hideaxistext(axh);
%Hide additional text objects in toolbar area.
texth = findobj(axh,'type','text');
textloc = cell2mat(get(texth,'position'));
set(texth(textloc(:,2)<(tbwidth+ylim(1))),'visible','off')
set(tih,'visible','on')
updatetoolbar(fig);
positionmanager(fig,mfilename,'set');

%--------------------------------------------
function resizecache(cb,fig,h)

xd  = get(h,'xdata');
fig = findparentfig(h);
fpos = get(fig,'position');
cachesize(fig,max(mincachesize,fpos(3)-xd(3)));
resize(fig);

%--------------------------------------------
function out = cachesize(fig,in)

persistent sz

if nargin>0
  relative = true;
  fpos = get(fig,'position');
else
  relative = false;
  fpos = [0 0 1 1];
end
if isempty(sz)
  %default
  sz = getplspref('modelselectorgui','cachesize');
  if isempty(sz)
    sz = .25;
  end
end

if nargin>1
  %assign value 
  in = max(mincachesize,in);
  sz = in/fpos(3);
  setplspref('modelselectorgui','cachesize',sz)
end

if nargout>0
  out = fpos(3)*sz;
  if relative & out<mincachesize
    out = mincachesize;
  end
end

%--------------------------------------------
function out = mincachesize

%Can't be less than one.
out = .1;


%--------------------------------------------
function left = getslidershift(fig)

sl = findobj(fig,'tag','xslider');
if ~isempty(sl)
  left = get(sl,'value');
else
  left = 1;
end

%--------------------------------------------
function mypos = getslidershift_y(fig)

sl = findobj(fig,'tag','yslider');
if ~isempty(sl)
  mypos = get(sl,'value');
else
  mypos = 1;
end

%--------------------------------------------
function updatetoolbar(fig)
%manage toolbar buttons

%if something exists in trigger & target of top-level, allow build & save
model = getappdata(fig,'model');
if ~isempty(model) & ~isempty(model.trigger) & ~isempty(model.targets)
  enb = 'on';
else
  enb = 'off';
end
set([findobj(fig,'tag','buildmodeltb') findobj(fig,'tag','savemodeltb')],'enable',enb);

[nundo,nredo] = undo(fig);
if nundo>0
  uen = 'on';
else
  uen = 'off';
end
if nredo>0
  ren = 'on';
else
  ren = 'off';
end
set(findobj(fig,'tag','undotb'),'enable',uen);
set(findobj(fig,'tag','redotb'),'enable',ren);


%--------------------------------------------
function movemouse(fig,varargin)
%detect when mouse is over a control and highlight it

hmode = getappdata(fig,'mousehighlight');
if ~isempty(hmode) & hmode==0; return; end

pos = round(get(get(fig,'currentaxes'),'currentpoint'));
pos = pos(1,1:2);
map = getappdata(fig,'hitmap');
if pos(1)>0 & pos(1)<=size(map,2) & pos(2)>0 & pos(2)<=size(map,1)
  %inside axis limits
  obj = map(pos(2),pos(1));
  if obj>0
    hobj = getappdata(fig,'highlighteditem');
    if isempty(hobj) | obj~=hobj
      highlight(obj,0,1);
    end
  else
    %no item under mouse
    highlight(fig,0,1);
  end
else
  %outside of axis limits
  highlight(fig,0,1);
end


%--------------------------------------------
function dropitem(fn,fig,draggedobj,varargin)
%handle dropping of a toolbox item

temppos = [];
if ishandle(draggedobj)
  %toolbox item dragged
  %move object we dragged back to toolbox
  set(draggedobj,'xdata',getappdata(draggedobj,'originalx'));
  set(draggedobj,'ydata',getappdata(draggedobj,'originaly'));
  setobjbgcolor(draggedobj,ones(1,3)*.95*255)
  
  %get dragged object's type (so we know what to replace the target with)
  newtype = getappdata(draggedobj,'type');
  newtype = settargetas(fig,newtype(1));
  toolboxitem = true;
else
  %actual object
  newtype = draggedobj;
  toolboxitem = false;
  
  %Need to use saved location of drop because some systems don't update mouse
  %location until after a drop so 'currentpoint' give location of last
  %click, not current mouse location. 
  temppos = getappdata(fig,'LastDropLocation');
end

%determine what we dropped ONTO
drawnow;
if isempty(temppos)
  pos = round(get(get(fig,'currentaxes'),'currentpoint'));
  pos = pos(1,1:2);
else
  pos = temppos;
  setappdata(fig,'LastDropLocation',[]);
end

map = getappdata(fig,'hitmap');
if pos(1)>0 & pos(1)<=size(map,2) & pos(2)>0 & pos(2)<=size(map,1)
  obj = map(pos(2),pos(1));
  if obj<1 | ~ishandle(obj) | isempty(getappdata(obj,'index'))
    obj = [];
  end
else
  obj = [];
end

if ~isempty(obj)
  %got a valid target object, highlight it and replace it
  highlight(obj,1)
  if isempty(objtype(newtype));
    erdlgpls('Unrecognized Object - cannot be used','Unrecognized Object');
    return;
  else
    settarget(fig,newtype)
  end
else
  %not dropped on any valid object
  if ~toolboxitem & (isdataset(newtype) | isnumeric(newtype))
    %try applying model to this data
    applymodel(fig,newtype)
  elseif ismodel(newtype) & strcmpi(newtype.modeltype,'modelselector')
    %modelselector dropped on main content? write in root node
    highlightindex(fig,0,0.5)
    settarget(fig,newtype)
    setappdata(fig,'builtmodel',newtype);
    setappdata(fig,'modelsaved',true);
    highlight(fig)
  end
end

%--------------------------------------------
function out = tbwidth

out = 38;

%--------------------------------------------
function draw(fig)
%draws or redraws tree

set(0,'currentfigure',fig);
set(fig,'windowbuttonmotionfcn',''); %disable mouse motion until done

delete(findobj('tag','treeaxes'));
axh = axes('units','normalized','position',[0 0 1 1],'tag','treeaxes');
axis ij off

le = [];
try
  drawnode(fig);
catch
  le = lasterror;
end

%draw toolbox
bgcolor = [.95 .95 .95];
ax = get(axh,'xlim');
ph = patch(ax([1 1 2 2 1]),[0 tbwidth tbwidth 0 0],bgcolor);
set(ph,'tag','toolboxpatch');
types = {'trigger' 'model' 'value' 'string' 'error'};
set(text(13,18,'Tools:'),'tag','toolboxtitle','fontweight','bold')
for j=1:length(types)
  for k=1:2;
    h = drawobj(fig,[],types{j},.9+j*.5,1.2,bgcolor*255);
    set(h,'buttondownfcn','','userdata','toolbox');
    xd = get(h,'xdata');
    setappdata(h,'xdata',xd)
    if k==2;
      moveobj(h);
      setappdata(h,'buttondownfcn',{@clicktbitem});
      setappdata(h,'buttonupfcn',{@dropitem})
      setappdata(h,'originalx',get(h,'xdata'));
      setappdata(h,'originaly',get(h,'ydata'));
    end
  end
end
minwidth = xd(2);
setappdata(ph,'minwidth',minwidth);

%draw resize "bar"
hw = 4;
delete(findobj('tag','resizeframe'))
ay = get(axh,'ylim');
rsf = patch([0 0 hw hw 0],[0 ay(2) ay(2) 0 0],[.90 .90 1]);
set(rsf,'EdgeColor',[.3 .3 1])
set(rsf,'tag','resizeframe');
setappdata(rsf,'buttonupfcn',{@resizecache})
moveobj('x',rsf);

resize(fig);

%set mouse motion action (now that tree is built)
set(fig,'windowbuttonmotionfcn',@movemouse)

if ~isempty(le)
  rethrow(le)
end

%--------------------------------------------
function clicktbitem(varargin)
setobjbgcolor(varargin{3},[255 255 255])

%--------------------------------------------
function y = drawnode(fig,node,x,y,index,parentobj)
%draw a trigger model and its targets

if nargin<2
  %top-level node
  setappdata(fig,'hitmap',0);
  node = getappdata(fig,'model');
  x = 1;
  y = 0;
  h = drawobj(fig,node,objtype(node),x,y);
  setappdata(h,'index',0);
  setappdata(fig,'hlookup',{h 0})
  index = [];
  parentobj = h;
end
if ~isnode(node)
  return;
end
nchild = numtargets(node);  %number of sub-nodes

%determine y reference and starting point
yref = y;

%create descriptions and calculate extent needed
conditionstrings = false;
includeadd = false;

if isvarconditiontrigger(node)
  %variable trigger
  description = node.trigger(2:end);
  conditionstrings = true;
  includeadd = true;
  if isempty(description) & nchild>0
    %WHAAA?? fill in strings for no children
    [description{1:nchild}] = deal('');
  end
  if ~isempty(description)
    if isempty(description{end}) 
      if length(description)>1
        description{end} = 'Otherwise';
      else
        %first and only item is empty - can't add yet
        includeadd = false;
      end
    else
      description{end+1} = 'Otherwise';
    end
  end
elseif ismodelconditiontrigger(node)
  %regression model trigger
  conditionstrings = true;
  includeadd = true;
  description = node.trigger(2:end);
  if ~isempty(description)
    if isempty(description{end})
      if length(description)>1
        description{end} = 'Otherwise';
      else
        %first and only item is empty - can't add yet
        includeadd = false;
      end
    else
      description{end+1} = 'Otherwise';
    end
  end
elseif isclassificationtrigger(node)
  %classification model trigger
  description = [node.trigger{1}.classification.classids {'Otherwise'}];
elseif ~isempty(node.trigger)
  description = {};
else
  %empty? Don't know what to do, assume var conditions
  description = {};
  conditionstrings = true;
  includeadd = true;
end
maxlen  = max(cellfun('size',description,2));
xindent = 1+min([max([0 (maxlen-8)]) 20])*.044; %determine what the indent length needs to be based on length of descriptions

%cycle through children drawing each as indicated by type
for j=1:nchild
  if j>1
    y = y-1;
  end
  
  h = drawobj(fig,node.targets{j},objtype(node.targets{j}),x+xindent,y,x,yref,description{j});
  
  %store handle in lookup table (to map from index to object)
  hlookup = getappdata(fig,'hlookup');
  hlookup{1}(end+1) = h;
  hlookup{2}(end+1,1:length(index)+1) = [index j];
  setappdata(fig,'hlookup',hlookup);
  setappdata(h,'index',[index j]);
  setappdata(h,'parent',parentobj);
  setappdata(h,'description',description{j});
  if conditionstrings
    %add "condition" string (triggers ability to edit this from controls)
    setappdata(h,'condition',description{j});
    if strcmpi(description{j},'otherwise')
      %already have an "otherwise" don't give "add" ability (TODO: needs
      %refinement)
      includeadd = false;
    end
  end
  
  if isnode(node.targets{j})
    y = drawnode(fig,node.targets{j},x+xindent,y,[index j],h);
  end
  
end

if includeadd
  %add an "Add" item at the end if appropriate
  if nchild>0
    y = y-1;
  end
  j = nchild+1;
  
  adddescription = '';
  if conditionstrings & length(description)>=j
    adddescription = description{j};
  end
  
  h = drawobj(fig,[],'add',x+xindent,y,x,yref,adddescription);
  setappdata(h,'index',[index j]);
  setappdata(h,'parent',parentobj);
  if conditionstrings
    %add "condition" string (triggers ability to edit this from controls)
    setappdata(h,'condition',adddescription);
  end
  
  %store handle in lookup table (to map from index to object)
  hlookup = getappdata(fig,'hlookup');
  hlookup{1}(end+1) = h;
  hlookup{2}(end+1,1:length(index)+1) = [index j];
  setappdata(fig,'hlookup',hlookup);
end  

%---------------------------------------------------
function h = drawobj(fig,content,type,x,y,xref,yref,description)

background = [];
if nargin<7
  if nargin==6
    background = xref;
  end
  xref = [];
  yref = [];
  description = '';
end
width = 130;
height = 30+4;

axh = get(fig,'currentaxes');
set(0,'currentfigure',fig);
hold on
yoffset = 45;
xoffset = 10;
halfOffset = 8;

%determine what kind of object to draw
if isempty(type)
  type = 'missing';
end

%create image and put into correct place
im = getimage(type);
h = image(im);
setobjbgcolor(h,background);
xd = get(h,'xdata');
yd = get(h,'ydata');
xorigin = min(xd);
yorigin = min(yd);

xd = xd-xorigin+(x-1)*width+xoffset;
yd = yd-yorigin-y*height+yoffset;
set(h,'xdata',xd,'ydata',yd);
set(h,'buttondownfcn',@highlight)
setappdata(h,'type',type);
setappdata(h,'value',content);

if ~isempty(xref)
  %draw line from reference to this object
  xstart = (xref-1)*width+xoffset+56+xorigin;
  xend   = (x-1)*width+xoffset+xorigin+(56/2);
  xhalf  = xstart + halfOffset;
  ystart = (-yref*height+yoffset)+17-yorigin;
  yend   = (-y*height+yoffset)+17-yorigin;
  lh = line([xstart xhalf xhalf xend],[ystart ystart yend yend],'color','k','linewidth',2);
  set(lh,'zdata',[-1 -1 -1 -1])
  
  %add description as text on that branch
  maxdesclen = 25;
  if length(description)>maxdesclen
    description = [description(1:maxdesclen) '...'];
  end
  th = text(xhalf+4,yend-8,description);
  set(th,'buttondownfcn',@highlight)

  [desc,offset] = encodecontent(type,content);
  if ~isempty(desc)
    dh = text(max(xd)+offset,yend,desc);
    setappdata(dh,'offset',offset);
  else
    dh = [];
  end  
  setappdata(th,'refhandle',h);
  setappdata(h,'texthandle',th);
  setappdata(h,'deschandle',dh);
  
  xd(1) = xstart;  %makes mouse-over region stretch to the left
  
end

%store handle in map for mouse-over actions
map = getappdata(fig,'hitmap');
map(round(max([1 yd(1)]):yd(2)),round(max([1 xd(1)]):xd(2))) = h;
setappdata(fig,'hitmap',map);

ymax = getappdata(axh,'ymax');
setappdata(axh,'ymax',max([ymax yd]))

%---------------------------------------------------
function setobjbgcolor(h,color)

im = get(h,'cdata');

%find edges and middle
nonwhite = getappdata(h,'nonwhitemap');
if isempty(nonwhite)
  mcdata = mean(im,3);
  edge = mcdata<255;
  edge = ([diff(edge')'~=0 zeros(size(edge,1),1)] + [diff(edge)~=0; zeros(1,size(edge,2))]>0);
  if ~any(edge(:));
    sz = size(edge);
    edge = [ones(sz(1),2) [ones(2,sz(2)-4); zeros(sz(1)-4,sz(2)-4); ones(2,sz(2)-4)] ones(sz(1),2)];
  else
    edge = mcdata<200;
  end
  nonwhite = mcdata<255;
  
  setappdata(h,'nonwhitemap',nonwhite);  %used for transparency and highlighting
  setappdata(h,'edgemap',edge);  %used for highlighting
end

%replace white with background color (if specified)
if ~isempty(color);
  if ~any(isnan(color))
    for j=1:3
      im1 = im(:,:,j);
      im1(~nonwhite) = color(j);
      im(:,:,j) = im1;
    end
    set(h,'cdata',im);
  else
    set(h,'alphadata',double(nonwhite))
  end
else
%   set(h,'alphadata',ones(size(nonwhite)))
end

%---------------------------------------------------
function im = getimage(name)
%returns image from MAT file of images

persistent images
if isempty(images)
  images = load('modelselectorgui_images');
end

%not in images? show as missing data icon
if ~isfield(images,['im' name])
  name = 'missing';
end

%get image
name = ['im' name];
im = images.(name);

%--------------------------------------------
function fig = findparentfig(fig)
%locate the parent fig of any object

if isempty(fig)
  fig = 0;
else
  fig = ancestor(fig,'figure');
end

%--------------------------------------------
function highlightindex(fig,index,seltype,varargin)
%highlight/select an object based on INDEX 

obj = getobjbyindex(fig,index);
if ~isempty(obj)
  highlight(obj,seltype)
end

%--------------------------------------------
function highlightnext(fig)

obj = getappdata(fig,'highlighteditem');
hlookup = getappdata(fig,'hlookup');
nitems = length(hlookup{1});
if isempty(obj)
  obj = getappdata(fig,'lasttab');
end
if isempty(obj) | ~ishandle(obj)
  ind = 1;
else
  ind = find(hlookup{1}==obj);
end
if ~isempty(ind)
  ind = ind+1;
  if ind>nitems
    ind = 1;
  end
  item = hlookup{1}(ind);
  setappdata(fig,'lasttab',item);
  highlight(fig,1);
  highlight(item,0);
end

%--------------------------------------------
function highlight(obj,seltype,mousehighlight)
%highlight or select an object

if nargin<1
  obj = gco;
end

if ~ishandle(obj)
  return;
end

%locate parental figure
fig = findparentfig(obj);

clicktype = get(fig,'selectiontype');

%default for seltype
mousemenupos = false;
if nargin<2 | isempty(seltype)
  if strcmp(clicktype,'alt')
    seltype = 2;  %select and open menu
    mousemenupos = true;
  else
    seltype = 1;  %select only
  end
end
if ~isnumeric(seltype) 
  %R2014b and later return a different type here
  if isprop(seltype,'EventName')
    switch seltype.EventName
      case {'WindowMousePress' 'Hit'}
        if isprop(seltype,'Button')
          switch seltype.Button
            case 3
              seltype = 2;
              mousemenupos = true;
            otherwise
              seltype = 1;
          end
        else
          seltype = 1;
        end
      otherwise
        seltype = 1;
    end
  else
    seltype = 0;
  end
end

%determine if this is a mouse-highlight and flag (meaning allow change via
%mouse motion)
if nargin<3
  mousehighlight = (obj==fig);
end
setappdata(fig,'mousehighlight',mousehighlight);
%get currently selected item
sel = getappdata(fig,'selecteditem');
if seltype==0 & ~isempty(sel) & ishandle(sel)
  %if we're only supposed to highlight but something was SELECTED, exit now
  return;
end

%DISABLE any selected item
hsel = getappdata(fig,'highlighteditem');
if ~isempty(hsel) & ishandle(hsel) & hsel~=fig
  set(hsel,'CData',getappdata(hsel,'originalimage'));  %reset image
  textobj = getappdata(hsel,'texthandle');
  if ~isempty(textobj)  %reset text
    set(textobj,'color',[0 0 0],'fontweight','normal')
  end
end
if ~isempty(hsel) & ~isempty(obj) & hsel==fig & obj==fig
   return; 
end

setappdata(fig,'selecteditem',[]);
setappdata(fig,'highlighteditem',[]);

%delete edit controls and check for redraw requirement
objcontrol = findobj(fig,'userdata','objcontrol');
if ~isempty(objcontrol)
  objcontrol = objcontrol(ishandle(objcontrol));
  delete(objcontrol); %delete edit controls for this object
  if getappdata(fig,'forceredraw')
    draw(fig);
    return;
  end
end
if obj==fig;
  %give generic message on canvas
  showcontrols([],fig,0);
  setappdata(fig,'highlighteditem',fig);
  setappdata(fig,'mousehighlight',1);  %reset to base figure always allows mouse-over again
  return
end

%map from text object to image handle (and back)
if strcmp(get(obj,'type'),'text')
  obj = getappdata(obj,'refhandle');
end
textobj = getappdata(obj,'texthandle');
type = getappdata(obj,'type');

%store handle as appropriate
setappdata(fig,'highlighteditem',obj);
if seltype>0
  setappdata(fig,'selecteditem',obj);
end

%locate regions on image we want to change (edges and non-white)
cdata = get(obj,'CData');
setappdata(obj,'originalimage',cdata)
nonwhite = getappdata(obj,'nonwhitemap');
edge     = getappdata(obj,'edgemap');

%cororize highlighted/selected item
if seltype==0
  scl = [.7 .7 1];
else
  scl = [1 .5 .5];
end
scl = 1-scl;
for slab = 1:3;
  cdata(:,:,slab) = cdata(:,:,slab)-uint8(double(cdata(:,:,slab)).*(edge/2+nonwhite/2).*scl(slab));
end
set(obj,'cdata',cdata);

%highlight corresponding text (if present)
if ~isempty(textobj)
  if seltype==0 
    clr = [0 0 .9];
  else
    clr = [.9 0 0];
  end
  set(textobj,'color',clr,'fontweight','bold')
end

if seltype==0 | seltype==1
  %bring up controls for this object
  showcontrols(obj,fig,seltype==1)
end

if seltype==1
  %special left=click actions
  if strcmpi(clicktype,'open')
    if ismember(type,{'model' 'triggerpro' 'triggerreg' 'triggercls'})
      switch type
        case 'model'
          model = getselobject(fig,obj);
        otherwise
          mynode = getselobject(fig,obj);
          model = mynode.trigger{1};
          if isempty(model)
            return;
          end
      end
      ev = evrigui('analysis','-reuse');
      figure(ev.handle);
      ev.setMethod(model.modeltype);
      ev.setModel(model);
    end
  end
end

%bring up trigger menu for object if "selected"
if seltype==2
  
  h = findobj(fig,'tag','targetmenu');
  if mousemenupos
    %position relative to mouse
    pos = get(fig,'currentpoint');
  else
    %position relative to object
    axpos = get(get(fig,'currentaxes'),'position');
    pos = [get(obj,'xdata') get(obj,'ydata')];
    pos = [pos(1) axpos(4)-pos(4)];
  end
  
  if ~isempty(h)
    %enable checkmarks
    index = getappdata(obj,'index');
    if isempty(index); return; end
    rootnode = (index(1)==0);
    set(findobj(h,'checked','on'),'checked','off');
    set(findobj(h,'tag',type),'checked','on');
    
    sep = 'off';  %flag for data type separator
    if strcmpi(type,'model')
      enb = 'on';
      sep = 'on';
    else
      enb = 'off';
    end
    set([findobj(h,'tag','chooseoutputs') findobj(h,'tag','makenode')],'visible',enb)
%     set(findobj(h,'tag','chooseoutputs'),'visible','off')  %Hard-Code DISABLE choose outputs for now
    
    if strcmpi(type(1:min(end,7)),'trigger') & ~rootnode & ~isvarconditiontrigger(getselobject(fig,obj))
      enb = 'on';
      sep = 'on';
    else
      enb = 'off';
    end
    set(findobj(h,'tag','makeendpoint'),'visible',enb)
    set(findobj(h,'tag','datatype'),'separator',sep);
    
    if rootnode
      enb = 'off';
    else
      enb = 'on';
    end
    set([findobj(h,'tag','delete') findobj(h,'tag','datatype')],'visible',enb)
    
    %position and show
    set(h,'position',pos(1,1:2),'visible','on')
  end
end

%---------------------------------------------------
function   showcontrols(obj,fig,editmode)
%show edit controls for a given object

if ~isempty(obj)
  if isempty(getappdata(obj,'index')); return; end
  type = getappdata(obj,'type');
  value = getappdata(obj,'value');
  parent = getappdata(obj,'parent');
  if ~isempty(parent)
    parenttype = getappdata(parent,'type');
  else
    parenttype = '';
  end
  index = getappdata(obj,'index');
  rootnode = all(index==0);
  outputfilters = {};
  if ~isempty(parent)
    parentnode = getappdata(parent,'value');
    if length(parentnode.outputfilters)>=index(end)
      outputfilters = parentnode.outputfilters{index(end)};
      for j=1:length(outputfilters)
        if iscell(outputfilters{j})
          outputfilters{j} = outputfilters{j}{1};
        else
          outputfilters{j} = decodesubstruct(outputfilters{j});
        end
      end
    end
  else
    parentnode = [];
  end
else
  %empty object? just working with base figure
  obj = fig;
  rootnode = false;
  if ~isempty(getappdata(fig,'builtmodel'))
    type = 'applymodel';
  else
    type = 'buildmodel';
  end
end

% Define Controls
%  { 'uistyle'  'label'  'appproperty'  callbackfn  'default_string' 'tooltip' }
% NOTE: for uistyle='text', "callbackfn" indicates (boolean) if text is to
% be shown in hover-mode. Empty or one indicates it is shown. Zero hides
% it.

separator = {'separator' '' '' [] [] ''};
separatorhidden = separator; 
separatorhidden{1,4} = 0;
switch type
  case 'applymodel'
    controls = {
      'text' 'Drag data to canvas to apply model.'   {} [] [] ''
      };
    
  case 'buildmodel'
    controls = {
      'text' 'Use "Build" toolbar button to build model.'   {} [] [] ''
      };
    
  case 'add'
    controls = {
      'text' 'Add New End-Point' {'fontweight','bold'} [] [] ''
      'text' 'Drag item here (or right-click) to add new test condition...'      '' [] [] ''
      };
    
  case 'missing'
    controls = {};
    
  case 'string'
    controls = {
      'text' 'Return string as output.' {'fontweight','bold'} [] [] ''
      'edit' 'Output:'  'value' @storestring value 'String value to return'
      };
    
  case 'error'
    controls = {
      'text' 'Throw error as output.' {'fontweight','bold'} [] [] ''
      'edit' 'Message:' 'error' @storeerror value.error 'Error message to throw'
      };
    
  case 'value'
    controls = {
      'text' 'Return numeric value(s) as output.' {'fontweight','bold'} [] [] ''
      'text' ' Separate multiple values with commas.' {'foregroundcolor',[.3 .3 .3]} 0 [] ''
      'edit' 'Output:'   'value' @storevalue nicenum2str(value) 'Numerical value(s) to return'
      };
    
  case 'model'
    controls = {
      'text' ['Apply Model: ' value.modeltype] {'fontweight','bold'} [] [] ''
      };
    if ~isempty(outputfilters)
      if editmode
        toadd = {'text' '(Custom Outputs Selected)' '' [] [] '' };
      else
        toadd = {};
        for j=1:length(outputfilters)
          toadd(j,1:6) = {'text' ['Output ' num2str(j) ': ' outputfilters{j}] '' [] [] '' };
        end
      end
      controls = [controls; toadd];
    end
    controls = [controls; {
      'pushbutton' 'Choose Outputs' '' @chooseoutputs [] 'Select model contents to return'
      'pushbutton' 'Get Info' '' @giveinfobox [] 'View model details'
      'pushbutton' 'Convert To Decision Rule' '' @makenode [] ''
      'text' 'Double-click to open in Analysis' '' 0 [] ''
      }];
    
  case 'triggervar'
    controls = {
      'text' 'Variable Test-based Rule' {'fontweight','bold'} [] [] ''
      'text' 'End-node "Conditions" test value of a variable' '' [] [] ''
      'text' ' Specify variables by "label" or [axisscale].' {'foregroundcolor',[.3 .3 .3]} [] [] ''
      'text' ' Tests performed sequentially (top test first).' {'foregroundcolor',[.3 .3 .3]} [] [] ''
      };
    
  case 'triggerreg'
    controls = {
      'text' 'Regression Model-based Rule' {'fontweight','bold'} [] [] ''
      'text' ['Model Type: ' value.trigger{1}.modeltype] {'fontweight','bold'} [] [] ''
      'text' 'End-node "Conditions" test output of predicted y value.' {} [] [] ''
      'text' ' Specify condition as [y_column] + comparison operator + value' {'foregroundcolor',[.3 .3 .3]} [] [] ''
      'pushbutton' 'Get Info' '' @giveinfobox [] ''
      };
    if ~rootnode
      controls = [controls; {
        'pushbutton' 'Convert To End-Point' '' @makeendpoint [] ''
        }];
    end
    controls = [controls; {
      'text' 'Double-click to open in Analysis' '' [] [] ''
      }];

  case 'triggerpro'
    controls = {
      'text' 'Projection Model-based Rule' {'fontweight','bold'} [] [] ''
      'text' ['Model Type: ' value.trigger{1}.modeltype] {'fontweight','bold'} [] [] ''
      };
    if ismember(lower(value.trigger{1}.modeltype),getfield(modelselector('options'),'addtrigmodels'))
      %models that output datasets (or other ununusal "allowed" types)
      controls = [controls; {
        'text' 'End-node "Conditions" test data output from prediction.' {'foregroundcolor',[.3 .3 .3]} [] [] ''
        'text' ' Specify condition as variable + comparison operator + value' {'foregroundcolor',[.3 .3 .3]} [] [] ''
        'text' ' Specify variables by "label" or [index].' {'foregroundcolor',[.3 .3 .3]} [] [] ''
        }];
    else
      %other projection models
      controls = [controls; {
        'text' 'End-node "Conditions" test output of predicted scores.' {'foregroundcolor',[.3 .3 .3]} [] [] ''
        'text' ' Specify condition as [pc#] + comparison operator + value' {'foregroundcolor',[.3 .3 .3]} [] [] ''
        }];
    end
    controls = [controls; {
      'pushbutton' 'Get Info' '' @giveinfobox [] ''
      }];
    if ~rootnode
      controls = [controls; {
        'pushbutton' 'Convert To End-Point' '' @makeendpoint [] ''
        }];
    end
    controls = [controls; {
      'text' 'Double-click to open in Analysis' '' [] [] ''
      }];
    
  case 'triggercls'
    controls = {
      'text' 'Classification Model-based Rule' {'fontweight','bold'} [] [] ''
      'text' ['Model Type: ' value.trigger{1}.modeltype] {'fontweight','bold'} [] [] ''
      'text' 'Classes defined by model. "Otherwise" used' {'foregroundcolor',[.3 .3 .3]} [] [] ''
      'text' 'if no class fits or statistics are out-of-limit.' {'foregroundcolor',[.3 .3 .3]} [] [] ''
      'pushbutton' 'Get Info' '' @giveinfobox [] ''
      };
    if ~rootnode
      controls = [controls; {
        'pushbutton' 'Convert To End-Point' '' @makeendpoint [] ''
        }];
    end
    controls = [controls; {
      'text' 'Double-click to open in Analysis' '' [] [] ''
      }];
        
  case 'trigger'
    %empty root node
    controls = {
      'text' 'Define Decision Rule' {'fontweight','bold'} [] [] ''
      'text' 'Drag a model from cache to here to use a model-based rule.'  '' [] [] ''
      'text' 'or assign end-points [+] now to use as variable-based rule.'  '' [] [] ''
      separatorhidden{:}
      'text' 'Or use controls below to choose rule type:'  '' 0 [] ''
      'radio' 'Variable-Based - Choose end-point by value of variable' '' @radiotargetvartrigger [] ''
      'radio' 'Model-Based - Choose end-point by output of model' '' @radiotargettrigger [] ''
      };
    if rootnode
      controls{1,2} = 'Define Initial Decision Rule';
    end
    
  otherwise
    controls = {};
end

%look for "condition" property (indicates a branch of a regression or
%numeric comparison node) and add controls for that too
if isappdata(obj,'condition')
  cond = getappdata(obj,'condition');  
  if isempty(cond)
    cond = '<UNDEFINED>';
  end
  toadd = {
    'edit' 'Do If Test Condition:' 'condition' @storecondition cond 'Logical statement when this node should be selected';
    };
  if ~strcmpi(parenttype,'triggervar')
    toadd = [toadd; {
            'text' 'Specify condition as [index] + comparison operator + value ' {'foregroundcolor',[.3 .3 .3]} 0 [] ''
            'text' ' Example: [1]>=5  tests output #1 > 5' {'foregroundcolor',[.3 .3 .3]} 0 [] ''
            }];
  else
    toadd = [toadd; {
            'text' 'Specify as: "variable" + comparison operator + value' {'foregroundcolor',[.3 .3 .3]} 0 [] ''
            'text' ' "variable" is "label" or [axisscale] (e.g. "var">=5 )' {'foregroundcolor',[.3 .3 .3]} 0 [] ''
            }];

  end
  
  if ~strcmpi(parenttype,'triggercls') & length(parentnode.targets)>1
    %add order change controls
    toadd = [toadd;
      {
      'movectrl' '' '' 0 [] ''
      }];
  end
  
  if ~isempty(controls)
    toadd = [toadd;separator];
  end
  controls = [toadd;controls];
    
else
  desc = getappdata(obj,'description');
  if length(desc)>40
    desc = [desc(1:min(end,40)) '...'];
  end
  if ~isempty(desc)
    toadd = [{ 'text' ['Test Condition: ' desc] '' [] [] ''} ];
    if ~isempty(controls)
      toadd = [toadd;separator];
    end
    controls = [toadd;controls];
  end
end

if isempty(controls)
  return;
end

set(0,'currentfigure',fig);
axh = get(fig,'currentaxes');

fpos = get(fig,'position');
axpos = get(axh,'position');
axlim = get(axh,'xlim');
aylim = get(axh,'ylim');

%find longest string
mxsz = max(cellfun('size',controls(:,2),2));

%-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
%display settings
controlWidth = 190;
labelWidth = min([controlWidth max([100 mxsz*5])]);
frameVOffset  = 5;       %vertical offset from object
frameHOffset  = -15;     %horizontal offset from object
fontsize = getdefaultfontsize;
fontname = 'Arial';
height   = getdefaultfontsize+10;   %per line height
framePadding = 4;        %padding between frame and controls
controlPadding = 2;      %padding between separate controls
controlLinePadding = 2;  %padding between label and control (on edit lines)
separatorPadding = 3;    %padding for separator line
shadowOffset  = 4;       %offset of shadow
shadowclr   = [.93 .93 .93];
outlineclr  = [.7 .7 .7];
selectedclr = [1 1 1];
hoverclr    = [1 1 1];


if editmode
  clr = selectedclr;
  shadowclr = outlineclr;
  backgroundclr = clr;
  fw = 'normal';
  editstyle = 'edit';
  editclr = [1 1 1];
  edittxtclr = [0 0 0];
  editfw = 'normal';
  radiostyle = 'radio';
else
  clr = hoverclr;
  backgroundclr = clr;
  fw = 'normal';
  editstyle = 'text';
  editclr = clr;
  edittxtclr = [0 0 0];
  editfw = 'bold';
  radiostyle = 'text';
end

%-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  

%add controls
width = labelWidth+controlWidth+controlLinePadding;

if obj~=fig
  opos = [get(obj,'xdata') get(obj,'ydata')];
else
  opos = [axlim aylim];
end

%get origin for all objects
left = (opos(1)-axlim(1))./(axlim(2)-axlim(1))*axpos(3);
objbottom = (1-(opos(4)./(aylim(2)-aylim(1)))).*axpos(4);
if left+width>fpos(3)
  left = fpos(3)-width;
end

%create frame for all controls
ncontrols = size(controls,1);

left = left + frameHOffset;
left = max(left,6);
objbottom = objbottom - frameVOffset;

fheight = height*ncontrols+controlPadding*(ncontrols-1)+framePadding*2;
if obj==fig
  %if box is for FIGURE rather than a given control, do NOT allow it to be
  %below bottom of figure
  objbottom = max(objbottom,fheight+shadowOffset)+20;
else
  if objbottom<height*ncontrols
    %Move to top.
    objbottom = objbottom+height*ncontrols-40;
  end
end
shadow = uicontrol('style','frame',...
  'position',[left-framePadding+shadowOffset objbottom-fheight-shadowOffset width+framePadding*2+controlLinePadding fheight],...
  'userdata','objcontrol','backgroundcolor',shadowclr,'foregroundcolor',shadowclr);
ph = uicontrol('style','frame',...
  'foregroundcolor',outlineclr,...
  'backgroundcolor',backgroundclr,...
  'position',[left-framePadding objbottom-fheight width+framePadding*2+controlLinePadding fheight],...
  'userdata','objcontrol');

%and add controls
inneroffset = 0;
focuson = [];
for cind = 1:ncontrols;
  bottom = objbottom - framePadding - height*cind - controlPadding*(cind-1) - inneroffset;
  
  switch controls{cind,1}
    case 'edit'
      uicontrol('style','text','string',controls{cind,2},'position',[left bottom labelWidth height],...
        'horizontalalign','right','fontsize',fontsize,'fontname',fontname,'fontweight',fw,...
        'backgroundcolor',clr,...
        'userdata','objcontrol');
      coffset = labelWidth+controlLinePadding;
      eh = uicontrol('style',editstyle,'position',[left+coffset bottom controlWidth height],...
        'backgroundcolor',editclr,'foregroundcolor',edittxtclr,...
        'horizontalalign','left','fontsize',fontsize,'fontname',fontname,'fontweight',editfw,...
        'tooltip',controls{cind,6},...
        'userdata','objcontrol','callback',controls{cind,4});
      setappdata(eh,'refhandle',obj);
      setappdata(eh,'property',controls{cind,3});
      default = getappdata(obj,controls{cind,3});
      if isempty(default)
        default = controls{cind,5};
      end
      if ~ischar(default);
        default = nicenum2str(default);
      end
      set(eh,'string',default);
      if isempty(focuson); focuson = eh; end
      
    case 'pushbutton'
      if editmode
        enb = 'on';
        btnwidth = width*.3 + width.*(max(0,length(controls{cind,2})-10)*.02);
        leftover = max(0,width-btnwidth);
        eh = uicontrol('style','pushbutton','string',controls{cind,2},'position',[left+leftover/2 bottom btnwidth height+3],...
          'horizontalalign','left','fontsize',fontsize,'fontname',fontname,'fontweight',fw,...
          'enable',enb,...
          'tooltip',controls{cind,6},...
          'userdata','objcontrol','callback',controls{cind,4});
        setappdata(eh,'refhandle',obj);
        setappdata(eh,'property',controls{cind,3});
        inneroffset = inneroffset + 6;
        fheight = fheight + 6;
      else
        inneroffset = inneroffset - height - separatorPadding;  %reduce separation to next
        fheight = fheight - height - separatorPadding;
      end
      

    case 'radio'
      if editmode
        eh = uicontrol('style',radiostyle,'string',controls{cind,2},'position',[left+framePadding*2 bottom width-+framePadding*2 height],...
          'horizontalalign','left','fontsize',fontsize,'fontname',fontname,'fontweight',fw,...
          'backgroundcolor',clr,...
          'tooltip',controls{cind,6},...
          'userdata','objcontrol','callback',controls{cind,4});
        setappdata(eh,'refhandle',obj);
        setappdata(eh,'property',controls{cind,3});
      else
        inneroffset = inneroffset - height - separatorPadding;  %reduce separation to next
        fheight = fheight - height - separatorPadding;
      end
      
    case 'text'
      if ~isempty(controls{cind,3})
        myitems = controls{cind,3};
      else
        myitems = {};
      end
      if editmode | isempty(controls{cind,4}) | controls{cind,4}
        uch = uicontrol('style','text','string',controls{cind,2},'position',[left bottom+1 width height-2],...
          'horizontalalign','center','fontsize',fontsize,'fontname',fontname,'fontweight',fw,...
          'backgroundcolor',clr,...
          'tooltip',controls{cind,6},...
          myitems{:},...
          'userdata','objcontrol');
        
        %check for truncated text
        ucext = get(uch,'extent');
        ucpos = get(uch,'position');
        if ucext(3)>ucpos(3)
          delta = ucext(3)+3 - ucpos(3);
          ucpos(3) = ucpos(3)+delta;
          set(uch,'position',ucpos);
          width = width+delta;  %make controls wider too
        end
        
      else
        inneroffset = inneroffset - height - separatorPadding;  %reduce separation to next
        fheight = fheight - height - separatorPadding;
      end
      
    case 'separator'
      if editmode | isempty(controls{cind,4}) | controls{cind,4}
        uicontrol('style','frame','position',[left+width*.02 bottom+height-separatorPadding/2 width*.96 1],...
          'backgroundcolor',clr,...
          'userdata','objcontrol','foregroundcolor',outlineclr);
        
        inneroffset = inneroffset - height + separatorPadding;  %reduce separation to next
        fheight = fheight - height + separatorPadding;
      else
        inneroffset = inneroffset - height - separatorPadding+1;  %reduce separation to next
        fheight = fheight - height - separatorPadding+1;
      end
      
    case 'movectrl'
      if editmode
        btnwidth = (width*.4)/2-controlLinePadding*2;
        enb = 'on';
        uicontrol('style','text','string','Move Condition:','position',[left bottom width*.4 height],...
          'horizontalalign','right','fontsize',fontsize,'fontname',fontname,'fontweight',fw,...
          'backgroundcolor',clr,...
          'userdata','objcontrol');        
        eh = uicontrol('style','pushbutton','string','Up','position',[left+width*.45-controlLinePadding/2 bottom btnwidth height+3],...
          'horizontalalign','left','fontsize',fontsize,'fontname',fontname,'fontweight',fw,...
          'enable',enb,...
          'tooltip','Move Condition Up',...
          'userdata','objcontrol','callback',@movecondup);
        setappdata(eh,'refhandle',obj);
        setappdata(eh,'property',controls{cind,3});

        eh = uicontrol('style','pushbutton','string','Down','position',[left+width*.45+controlLinePadding+btnwidth bottom btnwidth height+3],...
          'horizontalalign','left','fontsize',fontsize,'fontname',fontname,'fontweight',fw,...
          'enable',enb,...
          'tooltip','Move Condition Down',...
          'userdata','objcontrol','callback',@moveconddown);
        setappdata(eh,'refhandle',obj);
        setappdata(eh,'property',controls{cind,3});

        inneroffset = inneroffset + 6;
        fheight = fheight + 6;
      else
        inneroffset = inneroffset - height - separatorPadding;  %reduce separation to next
        fheight = fheight - height - separatorPadding;
      end
      

    otherwise
      %display NOTHING  
      inneroffset = inneroffset - height - separatorPadding;  %reduce separation to next
      fheight = fheight - height - separatorPadding;
    
  end
end

%re-assign frame size (in case objects needed to change it) Equation is
%same as above
set(ph,'position',[left-framePadding objbottom-fheight width+framePadding*2 fheight]);
set(shadow,'position',[left-framePadding+shadowOffset objbottom-fheight-shadowOffset width+framePadding*2 fheight]);
setappdata(fig,'forceredraw',false);  %flag indicating that we must redraw tree when closing dialog

%store current positions so we can shift with slider
hs = findobj(fig,'userdata','objcontrol');
poses = get(hs,'position');
for j=1:length(hs)
  poses{j}(1) = poses{j}(1)+getslidershift(fig);
  poses{j}(2) = fpos(4)-poses{j}(2);
  setappdata(hs(j),'position',poses{j})
end

if editmode & ~isempty(focuson)
  uicontrol(focuson);
end

%--------------------------------------------------
function storevalue(obj,varargin)

v = get(obj,'string');
p = getappdata(obj,'property');
rh = getappdata(obj,'refhandle');
v = str2num(v);
v = v(:)';
set(obj,'string',nicenum2str(v));

setappdata(rh,p,v);

%store in object
mobj = getappdata(obj,'refhandle');
fig = findparentfig(mobj);
[current,S] = getselobject(fig,mobj);
assigninmodel(fig,S,v);

%update canvas display
set(getappdata(rh,'deschandle'),'string',encodecontent('value',v));

%- - - - - - - - - - - - - - - - -
function str = nicenum2str(v)

if ~isempty(v)
  str = sprintf(',%g',v(:));
else
  str = '';
end
str = str(2:end);

%--------------------------------------------------
function storestring(obj,varargin)

v = get(obj,'string');
p = getappdata(obj,'property');
rh = getappdata(obj,'refhandle');
setappdata(rh,p,v);

%store in object
mobj = getappdata(obj,'refhandle');
fig = findparentfig(mobj);
[current,S] = getselobject(fig,mobj);
assigninmodel(fig,S,v);

%update canvas display
set(getappdata(rh,'deschandle'),'string',encodecontent('string',v));

%--------------------------------------------------
function storeerror(obj,varargin)

v = get(obj,'string');
p = getappdata(obj,'property');
rh = getappdata(obj,'refhandle');
setappdata(rh,p,v);

%store in object
mobj = getappdata(obj,'refhandle');
fig = findparentfig(mobj);
[current,S] = getselobject(fig,mobj);
errv = struct('error',{v});
assigninmodel(fig,S,errv);

%update canvas display
set(getappdata(rh,'deschandle'),'string',encodecontent('error',errv));

%--------------------------------------------------
function radiotargetvartrigger(obj,varargin)

settarget_vartrigger(gcbf);
if ishandle(obj)
  set(obj,'value',0)
end

%--------------------------------------------------
function radiotargettrigger(obj,varargin)

settarget_trigger(gcbf);
if ishandle(obj)
  set(obj,'value',0)
end

%--------------------------------------------------
function storecondition(obj,varargin)

%get information on figure and parent
v = strtrim(get(obj,'string'));
p = getappdata(obj,'property');
rh = getappdata(obj,'refhandle');
mobj = getappdata(obj,'refhandle');
fig = findparentfig(mobj);
index = getappdata(mobj,'index');
parentobj = getappdata(mobj,'parent');
[parent,S] = getselobject(findparentfig(obj),parentobj);

badvalue = false;
if strcmpi(v,'otherwise')
  v = '';
end
if ~isempty(v)
  %not empty, check for valid notation  
  valid = {'>=' '<=' '==' '~=' '<>' '!=' '=>' '=<' '>' '<' '='};
  goodcomp = [];  %which comparison operator did we use
  for j=1:length(valid)
    pos = strfind(v,valid{j});
    if pos>0
      v(pos:pos+length(valid{j})-1) = '';
      if isempty(goodcomp)
        %first one found use this (don't expect others!)
        goodcomp = valid{j};
        switch goodcomp
          case '=>' 
            goodcomp = '>=';
          case '=<'
            goodcomp = '<=';
          case '='
            goodcomp = '==';  %convert = to ==
          case {'<>' '!='}
            goodcomp = '~=';
        end
        comploc  = pos;
      else
        %found ANOTHER one? error!
        goodcomp = [];
        break;
      end
    end
  end
  if isempty(goodcomp)
    %none or more than one found or in wrong position
    v = '';
    badvalue = true;
  else
    v = [v(1:comploc-1) goodcomp v(comploc:end)];
    pos = comploc+length(goodcomp);
    if isempty(str2num(v(pos:end)))
      %test value after comparison operator, if remainder does NOT look
      %like a number, its bad
      v = '';
      badvalue = true;
    else
      %good value
      %check for valid label or axisscale (or index)
      var = strtrim(v(1:comploc-1));  %pre comparison string
      v   = v(comploc:end);           %remove that string
      var(var=='"') = '';             %remove all quotes
      if ~isempty(var) & var(1)=='['
        %numeric locator...
        var(var=='[' | var==']') = '';  %remove [ ]
        valvar = str2double(var); %check for valid number
        if ~isempty(valvar) & isfinite(valvar) %Good value, add [ ]
          var = ['[' num2str(valvar) ']'];
        else
          badvalue = true;
        end
      end
      if ~badvalue
        if isempty(var)
          %no axisscale/label?
          if isvarconditiontrigger(parent)
            %var condition, add label
            var = 'Var';
          else
            %otherwise, add default index of 1
            var = '[1]';
          end
        end
        if var(1)~='['
          %label index? Add quotes
          var = ['"' var '"'];
        end
        v = [var v];
      end
    end
  end  
else
  %empty string? see if we're allowed that
  emptytriggers = find(cellfun('isempty',parent.trigger) & cellfun('isclass',parent.trigger,'char'));
  if length(parent.trigger)>2 & (isempty(emptytriggers) | ismember(index(end)+1,emptytriggers))
    %no other empties OR this one is empty, assign as-is
    badvalue = false;
  else
    badvalue = true;
  end
end

if badvalue
  %bad test, reset to original
  v = getappdata(rh,p);
  set(obj,'string',v);
  erdlgpls('Invalid condition string','Invalid Condition');
else
  %got a good one - store in parent
  settriggerstring(fig,v,index)

  %see if we have a label to assign
  texth = getappdata(mobj,'texthandle');
  if ~isempty(texth) & ishandle(texth)
    set(texth,'string',v);
  end
  
  setappdata(fig,'forceredraw',true);  %force tree to be redrawn on close of dialog
  set(obj,'string',v);
end

%update appdata in object
setappdata(rh,p,v);

%-----------------------------------------------------
function giveinfobox(obj,varargin)

rh = getappdata(obj,'refhandle');
model = getappdata(rh,'value');

if ~ismodel(model) & isfield(model,'trigger') & ~isempty(model.trigger) & iscell(model.trigger) & ismodel(model.trigger{1})
  model = model.trigger{1};
end  
try
  info = modlrder(model)';
catch
  return
end
infofig = infobox(info);
infobox(infofig,'font','courier',10);

%--------------------------------------------------------
function movecondup(bobj,varargin)

movecond(bobj,'up');

%--------------------------------------------------------
function moveconddown(bobj,varargin)

movecond(bobj,'down')

%--------------------------------------------------------
function movecond(bobj,direction)

obj = getappdata(bobj,'refhandle');
fig = findparentfig(obj);
[current,S,index,obj] = getselobject(fig,obj);
[parent,parentS] = getselobject(fig,getappdata(obj,'parent'));

endindex = index(end);
newindex = index;
nitems = length(parent.targets);
switch direction
  case 'up'
    reorder = [1:endindex-2 endindex endindex-1 endindex+1:nitems];
    canmove = endindex>1;
    newindex(end) = newindex(end)-1;
  case 'down'
    reorder = [1:endindex-1 endindex+1 endindex endindex+2:nitems];
    canmove = endindex<nitems && endindex<length(parent.trigger);
    newindex(end) = newindex(end)+1;
end

%special indexing for target reordering
triggerreorder = [1 reorder+1];
triggerreorder(triggerreorder>length(parent.trigger)) = [];

if canmove
  parent.targets = parent.targets(reorder);
  if length(parent.outputfilters)==nitems
    parent.outputfilters = parent.outputfilters(reorder);
  end
  parent.trigger = parent.trigger(triggerreorder);

  highlight(fig);
  assigninmodel(fig,parentS,parent);
  draw(fig);
  highlightindex(fig,newindex,1);
end

%------------------------------------------
function [desc,offset] = encodecontent(type,content)

desc = '';   %default is give no description
offset = 5;  %default is indent 5 pixels
switch type
  case 'string'
    desc = sprintf('= "%s"',content);
  case 'error'
    desc = sprintf('= "%s"',content.error);
    offset = -13;
  case 'value'
    if isnumeric(content)
      if length(content)==1
        desc = ['= ' sprintf('%g',content)];
      elseif isempty(content)
        desc = '[empty]';
      elseif any(size(content)==1)
        desc = '(Vector)';
      else
        desc = '(Array)';
      end
    else
      desc = '(Complex Object)';
    end
    
  case 'model'
    desc = content.modeltype;
    
end

