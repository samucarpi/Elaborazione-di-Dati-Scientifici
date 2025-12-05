function varargout = bspcgui(varargin)
%BSPCGUI Batch Processor GUI.
% Generic code for setting up a Figure from mcode only. Use the following
% keys to search and replace.
%   tag/function = "bspcgui"
%   title/name   = "Batch Processor"
%
%  OPTIONS: 
%    batch_plot_style : [{'linear'} | 'stack'] Style of batch plot.
%
%
%I/O: h = bspcgui() %Open gui and return gui handle.
%I/O: bspcgui(data) %Open preloaded.
%
%See also: ANALYSIS, PLOTGUI

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%TODO: Add way to load reference trace into warping tab so it can be used on "test" sets.
%TODO: Search for places to use get_bach_class_info.
%TODO: Use custom magnify so can multiselect non-consecutive batches.
%TODO: Add marker automatically takes user back to ref batch (instead of disable).
% if nargin>0
%   disp(varargin{1})
% end 

if nargin==0 || ~ischar(varargin{1}) % LAUNCH GUI
  try
    
    %Can only use in 2007b or newer because panels can't have tabs as
    %parents.
    if checkmlversion('<','7.5')
      evriwarndlg('Batch Processor GUI is not available for 2007a or older.','Unsupported Matlab Version')
      return
    end
    
    %Start GUI
    h=waitbar(1,['Starting Batch Processor...']);
    drawnow
    %Open figure and initialize
    %fig = openfig('bspcgui.fig','new','invisible');
    
    fig = figure('Tag','bspcgui',...
      'NumberTitle', 'off', ...
      'HandleVisibility','callback',...
      'Integerhandle','off',...
      'Name', 'Batch Processor',...
      'Renderer','OpenGL',...
      'MenuBar','none',...
      'ResizeFcn','bspcgui(''resize_callback'',gcbo,[],guihandles(gcbf))',...
      'CloseRequestFcn','try;bspcgui(''closereq_callback'',gcbo,[],guihandles(gcbf),0);catch;delete(gcbf);end',...
      'visible','off',...
      'Units','pixels');
    
    %Set up gui controls.
    gui_enable(fig)
    
    figbrowser('addmenu',fig); %add figbrowser link
    
    %Position gui from last known position.
    positionmanager(fig,'bspcgui');
    
    handles = guihandles(fig);
    fpos = get(handles.bspcgui,'position');
    
    pause(.1);drawnow
    set(fig,'visible','on');
    
    resize_callback(fig,[],handles);
    
    %Get data if passed.
    if nargin>0 && ~isempty(varargin{1})
      loaddata(fig,[],handles,'auto',varargin{1});
    end
  catch
    if ishandle(fig); delete(fig); end
    if ishandle(h); close(h);end
    erdlgpls({'Unable to start the Batch Processor' lasterr},[upper(mfilename) ' Error']);
  end
  
  if ishandle(h)
    close(h);
  end
  
  if nargout>0
    varargout{1} = fig;
  end
  
else % INVOKE NAMED SUBFUNCTION OR CALLBACK
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = [];
        options.renderer            = 'opengl';%Opengl can be slow on Mac but it's the only renderer that displays alpha.
        options.fontsize            = '';%If empty then use defualt 10/12 pc/mac.
        options.analysis_types      = {'spca' 'Summary PCA'; 'batchmaturity' 'Batch Maturity'; 'mpca' 'MPCA';...
          'parafac' 'PARAFAC';'sparafac' 'Summary PARAFAC'; 'parafac2' 'PARAFAC2'; 'other' 'Other 2-Way Methods (MCR, PCA, ...)'};
        options.batch_plot_style    = 'stack'; % 'stack'
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
function help_callback(hObject, eventdata, handles)
%Open help page.
evrihelp('bspcgui')

%--------------------------------------------------------------------
function closereq_callback(h,eventdata,handles,varargin)
%Close gui.

if isempty(handles)
  handles = guihandles(h);
end

gopts = getappdata(handles.bspcgui,'gui_options');
setplspref('bspcgui',gopts)

%Save figure position.
positionmanager(handles.bspcgui,'bspcgui','set')

if ishandle(handles.bspcgui)
  delete(handles.bspcgui)
end

%--------------------------------------------------------------------
function batch_select_callback(h,eventdata,handles,varargin)
%Selection of batch to plot. Update magnify object position. This will
%"snap" the magnify area to the nearest batch.

%update_plots(handles)
if check_tab(handles,'align',0)
  update_top_plot(handles)
else
  %If we're in marker mode (choosing steps) then run update of markers if
  %needed.
  stepmode = getappdata(handles.bspcgui,'step_selection');
  if stepmode
    rinfo = getappdata(handles.bspcgui,'step_selection_info');
    oldval = rinfo.old_list_val;
    newval = get(handles.batch_list,'value');
    rinfo.old_list_val = newval;
    setappdata(handles.bspcgui,'step_selection_info',rinfo)
    %If oldval is the ref and new val is not then refresh list.
    if oldval==rinfo.refbatch_list_val & newval~=rinfo.refbatch_list_val
      update_marker_class(handles,0);
    end
  end
end
update_bottom_plot(handles)

%--------------------------------------------------------------------
function batch_patch_buttonup_fcn(varargin)
%Post drag of batch patch on variabl plot. Update xdata of patch and text
%object if present.

handles = guihandles(varargin{2});
mypatch = varargin{3};
if ~ishandle(mypatch)
  return
end

mydata = getappdata(handles.bspcgui,'classed_data');

p = get(mypatch,'xdata');
%Locate patch position in data.
mypos = max(1,round(min(p)+(max(p)-min(p))/2));
mypos = min(size(mydata,1),mypos);

mybatch  = get(handles.batch_list,'value');%Selected batch/es.
mystring = get(handles.batch_list,'string');
mybidx   = get(handles.batch_list,'userdata');%Batch class index.

if isempty(mybidx)% | ~get(handles.step_use,'value')
  return
end

%Get batch class info.
thisbatchlu = mydata.classlookup{1,mybidx};
bclass      = mydata.class{1,mybidx};
thisbatchlu = get_lookup(thisbatchlu,bclass);
newclass    = bclass(mypos);
listpos = [];

if isempty(thisbatchlu)
  return;
end

listpos = find([thisbatchlu{:,1}]==newclass);

%Update line data.
myvar = get(handles.variable_list,'value');
ln = getappdata(mypatch,'line_obj');

if isempty(ln) | ~ishandle(ln)
  return
end

txtobj = [];%Text label list.

oldclass = get(ln(1),'UserData');
thisbatchdata = mydata(bclass==newclass,myvar);
for i = 1:length(ln)
  set(ln(i),'ydata',thisbatchdata(:,i).data,'UserData',newclass);
  txtobj = [txtobj getappdata(ln(i),'text_obj')];
end
%set(ln,'ydata',thisbatchdata.data,'UserData',newclass);

%Snap patch to batch.
myxlim(1) = min(find(bclass==bclass(mypos)));
myxlim(2) = max(find(bclass==bclass(mypos)));
set(mypatch,'xdata',[myxlim(1) myxlim(1) myxlim(2) myxlim(2) myxlim(1)]);

%Update batch list.
blistval = get(handles.batch_list,'value');
blistval(blistval==find([thisbatchlu{:,1}]==oldclass)) = [];
blistval = union(blistval,listpos);
set(handles.batch_list,'value',blistval);

%Update text object.
txtobj = txtobj(ishandle(txtobj));%Make sure handle is still good.
if ~isempty(txtobj)
  set(txtobj,'String',thisbatchlu{listpos,2});
end

%--------------------------------------------------------------------
function mtool_buttonup_fcn(h,eventdata,handles,varargin)
%Locate what batch class is in middle of patch and update the batch list
%selection. Maybe call batch_select_callback to "snap" patch to position.

myfcn = varargin{1};

%mydata = getappdata(handles.bspcgui,'data');
mydata = getappdata(handles.bspcgui,'classed_data');
mobj = getappdata(handles.bspcgui,'mtool');
if isempty(mobj) | ~mobj.isvalid
  return
end

p = get(mobj.patch_handle,'xdata');
mypos = max(1,round(min(p)+(max(p)-min(p))/2));
mypos = min(size(mydata,1),mypos);

mybatch = get(handles.batch_list,'value');%Selected batch.
mystring = get(handles.batch_list,'string');
mybidx  = get(handles.batch_list,'userdata');%Batch class index.

base_selection = 1:length(mybatch);

if isempty(mybidx)% | ~get(handles.step_use,'value')
  return
end
%Get batch class info.
thisbatchlu = mydata.classlookup{1,mybidx};
bclass = mydata.class{1,mybidx};
thisbatchlu = get_lookup(thisbatchlu,bclass);

%Get position in batch list.
if isempty(thisbatchlu)
  listpos = [];
else
  listpos = find([thisbatchlu{:,1}]==bclass(mypos));
end

mid_selection = round(mean(base_selection));
if listpos<=mid_selection
  newval = base_selection;
elseif listpos+base_selection>size(mystring,1)
  newval = base_selection+(size(mystring,1)-mid_selection);
else
  newval = (base_selection+listpos)-round(mean(base_selection));
end

%Correct for index out of range because of rounding.
if any(newval<0)
  newval = newval+abs(newval);
elseif any(newval>size(mystring,1))
  newval = newval-(max(newval)-size(mystring,1));
end

set(handles.batch_list,'value',newval);

if strcmp(myfcn,'buttonup')
  batch_select_callback(h,eventdata,handles,varargin)
end
%bclass = ismember(bclass,myclass);

%--------------------------------------------------------------------
function marker_callback(handles,btn)
%Run callbacks for step toolbar.

mydata = getappdata(handles.bspcgui,'classed_data');
rinfo  = getappdata(handles.bspcgui,'step_selection_info');%Reference and point info.

switch btn
  case 'cancel'
    %setappdata(handles.bspcgui,'step_selection_info',[])
    select_custom_callback(handles.bspcgui,[],handles)
    return
  case 'ok'
    update_marker_class(handles,0);
    rinfo  = getappdata(handles.bspcgui,'step_selection_info');
    mydata = getappdata(handles.bspcgui,'classed_data');
    if ~isempty(rinfo) & ~isempty(rinfo.temporary_class)
      load_custom_callback(handles.bspcgui,[],handles,'step',rinfo.temporary_class)
    end
    %setappdata(handles.bspcgui,'step_selection_info',[])
    select_custom_callback(handles.bspcgui,[],handles)
    return
  case 'add'
    mylims      = axis(handles.magnify_display);
    xpos = round(mylims(1)+(mylims(2)-mylims(1))/2);%Middle of region for a starting location.
    
    %Plot line.
%     hold(handles.magnify_display,'on')
%     myid = now;
%     myline = plot(handles.magnify_display,[xpos xpos],mylims(3:4),'-g','LineWidth',1.5,'tag','step_marker','userdata',myid);
%     hold(handles.magnify_display,'off')
%     set(handles.magnify_display,'tag','magnify_display')
%     moveobj('x',myline);
%     setappdata(myline,'buttonupfcn',{@marker_buttonup})
    
    %Save line to struct.
    rinfo.step_loc_index(end+1).id = now;
    rinfo.step_loc_index(end).pos = xpos;
    setappdata(handles.bspcgui,'step_selection_info',rinfo)
    update_marker_class(handles,1)
    
  case 'clear'
    if ~isempty(rinfo.step_loc_index)
      rinfo.step_loc_index = [];
    end
    setappdata(handles.bspcgui,'step_selection_info',rinfo)
    update_marker_class(handles,0)
  case 'remove'
    if ~isempty(rinfo.step_loc_index)
      rinfo.step_loc_index(end) = [];
    end
    setappdata(handles.bspcgui,'step_selection_info',rinfo)
    update_marker_class(handles,0)
  case 'options'
    baopts = getappdata(handles.bspcgui,'marker_batchalign_options');
    if isempty(baopts)
      baopts = batchalign('options');
    end
    baopts = optionsgui(baopts);
    if ~isempty(baopts)
      setappdata(handles.bspcgui,'marker_batchalign_options',baopts);
    end
end

%update_marker_class(handles)
resize_callback(handles.bspcgui,[],handles)
batch_select_callback(handles.bspcgui,[],handles)

%--------------------------------------------------------------------
function update_marker_class(handles,skipalign)
%Update temporary class based step markers.

mydata = getappdata(handles.bspcgui,'classed_data');
rinfo  = getappdata(handles.bspcgui,'step_selection_info');

%If step location index is empty then make sure everything is clear and
%return.
if isempty(rinfo.step_loc_index)
  rinfo.temporary_class=[];
  return
end

%DSO of ref var/batch.
[batchclass, batchlu, batchname] = get_bach_class_info(handles,mydata);
batch_idx = find(batchclass==rinfo.refbatch_class);

refData = mydata.data((batchclass==rinfo.refbatch_class),rinfo.refvariable);
if isempty(refData)
  return
end

%Make temp class.
temprefclass = zeros(1,size(refData,1));
refclass_nums = [rinfo.step_loc_index.pos];
refclass_nums = sort(refclass_nums);%Diff code below only works with class in order.
loc_1 = 1;
for i = 1:length(refclass_nums)
  loc_2 = find(diff(batch_idx>refclass_nums(i)));
  if isempty(loc_2)
    %End of class might be at edge of batch so make all of the remaining
    %members the last class.
    loc_2 = length(batch_idx);
  end
  temprefclass(loc_1:loc_2) = i;
  loc_1 = loc_2;
end
temprefclass(loc_1:end)=i+1;%Fill class out to end.
refData = dataset(refData);
refData.class{1} = temprefclass;

temptargetclass = zeros(1,size(mydata,1));%Generic class vector.

%Bet batch align options for manual step assignment.
baopts = getappdata(handles.bspcgui,'marker_batchalign_options');
if isempty(baopts)
  baopts = batchalign('options');
  setappdata(handles.bspcgui,'marker_batchalign_options',baopts);
end

if ~skipalign
  wb = waitbar(0,'Aligning Steps...');
end

%Calculate the prposed alignment batches.
bsize = size(batchlu,1);
for i = 1:bsize
  thisclass = batchlu{i,1};
  if thisclass==rinfo.refbatch_class
    %Use reference class.
    temptargetclass(batchclass==rinfo.refbatch_class) = temprefclass;
  else
    if skipalign
      %If placing markers on ref batch, skip alignment step and leave as
      %zeros.
      continue
    end
    %Batch align to refrerence.
    %targetDSO  = mydata((batchclass==thisclass),rinfo.refvariable);
    targetData = mydata.data((batchclass==thisclass),rinfo.refvariable);
    if isempty(targetData)
      %Might be no members in class.
      continue
    end
    try
      mytarget_aligned = batchalign(refData,1,targetData,baopts);
      temptargetclass(batchclass==thisclass)=mytarget_aligned.class{1};
    catch
      myerr = lasterr;
      warndlg(['Unable to align data with current settings: ' myerr],'Batch Align Error')
      if ishandle(wb)
        delete(wb)
      end
      break
    end
  end
  if ~skipalign
    waitbar(i/bsize,wb)
  end
end
if ~skipalign & ishandle(wb)
  delete(wb)
end
rinfo.temporary_class = temptargetclass;
setappdata(handles.bspcgui,'step_selection_info',rinfo)

%--------------------------------------------------------------------
function [batchclass, batchlu, batchname] = get_bach_class_info(handles,mydata)
%Get batch class vector, lookup table, and name. Only if batch class is
%present.

if nargin<2
  mydata = getappdata(handles.bspcgui,'data');
end

batchclass = [];
batchlu    = [];
batchname  = [];

btn = get(handles.batch_source_buttongroup,'selectedobject');
if strcmp(get(btn,'userdata'),'class')
  mybidx  = get(handles.batch_source_list,'value');%Batch class index.
else
  %Assume "classed" data has been passed in and look for default name.
  mybidx = findset(mydata,'class',1,'BSPC Batch');
end

if isempty(mybidx)% | ~get(handles.step_use,'value')
  return
end

batchclass = mydata.class{1,mybidx};
batchlu    = mydata.classlookup{1,mybidx};
batchname  = mydata.classname{1,mybidx};

%--------------------------------------------------------------------
function marker_buttonup(varargin)
%Set new position for marker after move.
handles = guihandles(varargin{2});
mydata = getappdata(handles.bspcgui,'data');
rinfo = getappdata(handles.bspcgui,'step_selection_info');

%Make sure marker not dropped outside of batch.
newpos = get(varargin{3},'xdata');
newpos = round(newpos(1));

cdata = getappdata(handles.bspcgui,'classed_data');
if isempty(cdata)
  cdata = update_data(handles,'classed');
end

[batch_cls, batchlu, batchname] = get_bach_class_info(handles,cdata);

% batch_idx = get(handles.batch_source_list,'value');
% batch_cls = mydata.class{1,batch_idx};

refclass_idx = find(batch_cls==rinfo.refbatch_class);

%Move marker back into batch if needed.
if newpos>max(refclass_idx)
  newpos = max(refclass_idx);
  set(varargin{3},'xdata',[newpos newpos]);
elseif newpos<min(refclass_idx)
  newpos = min(refclass_idx);
  set(varargin{3},'xdata',[newpos newpos]);
end

%Update marker position in saved struct.
myid = get(varargin{3},'userdata');
myloc = [rinfo.step_loc_index.id]==myid;
rinfo.step_loc_index([rinfo.step_loc_index.id]==myid).pos = newpos;

setappdata(handles.bspcgui,'step_selection_info',rinfo)

update_marker_class(handles,1)

%--------------------------------------------------------------------
function variable_select_callback(h,eventdata,handles,varargin)
%Selection of variables to plot.

update_plots(handles)

%--------------------------------------------------------------------
function loadmodel(h,eventdata,handles,varargin)
%Load model.
gopts = bspcgui('options');
mymodel = getappdata(handles.bspcgui,'model');
mydata = getappdata(handles.bspcgui,'data');

%Check for overwrite of model.
if ~isempty(mymodel);
  clearans=evriquestdlg('Clear existing model?', ...
    'Clear Model','Clear','Cancel','Clear');
  switch clearans
    case {'Cancel'}
      return
  end
end

if length(varargin)==0;
  [mymodel,name,location] = lddlgpls('struct','Select Model');
else
  mymodel = varargin{1};
end

if isempty(mymodel)
  return
end

%Parse options.
myopts= mymodel.detail.options;

%Set analysis type.
set(handles.analysis_panel,'SelectedObject',handles.(['analysis_' lower(mymodel.fold_method)]))
select_analysis_callback(handles.(['analysis_' lower(mymodel.fold_method)]),[],handles,varargin)

%Set sources.
bsrc = myopts.batch_source;
set(handles.batch_source_buttongroup,'selectedobject',handles.(['batch_source_' myopts.batch_source]));
set(handles.step_source_buttongroup,'selectedobject',handles.(['step_source_' myopts.step_source]));

%Get batch locate setting.
%TODO: Test this.
if strcmpi(myopts.batch_locate,'index')
  set(handles.batch_source_gapchk,'value',0)
else
  set(handles.batch_source_gapchk,'value',1)
end

%Try to set alignment settings.
aopts = myopts.batch_align_options;
set(handles.(['align_source_' lower(aopts.method)]),'value',1);

%Get length of string for batch and variable. If they're longer than values
%in model then set the value.

%See if we can find alignment batch class value in lookup table. If so, try
%to set the dropdown value.
if ismember(mymodel.fold_method,{'mpca' 'parafac'}) & ~strcmpi(aopts.method,'none')
  cdata = update_data(handles,'classed');
  if ~isempty(cdata)
    [batchclass, batchlu, batchname] = get_bach_class_info(handles,cdata);
    myval = myopts.alignment_batch_class==[batchlu{:,1}];
    if any(myval)
      myval = find(myval);
      if batchlu{1,1}==0
        %Class 0 is removed so subtract one.
        myval = myval-1;
      end
      bval = get(handles.align_selectbatch_txt,'string');
      %Double check that string of batch dropdown is long enough.
      if size(bval,1)>myval
        set(handles.align_selectbatch_txt,'value',myval);
      end
    end
  end
  
  %Set variable dropdown.
  bval = get(handles.align_selectvariable_txt,'string');
  if size(bval,1)>myopts.alignment_variable_index
    set(handles.align_selectvariable_txt,'value',myopts.alignment_variable_index);
  end
  
  if strcmpi(aopts.method,'cow')
    set(handles.align_derivorder_txt,'value',aopts.savgolderiv);
    set(handles.align_segments_txt,'string',num2str(aopts.cow.segments));
    set(handles.align_slack_txt,'string',num2str(aopts.cow.slack));
  end
end

%Set summary methods.
if ismember(mymodel.fold_method,{'spca' 'sparafac'})
  %Add summary methods.
  set(findobj(handles.summarize_button_panel,'type','uicontrol'),'value',0);
  mymethods = mymodel.detail.options.summary;
  for i = mymethods
    set(handles.(['summarize_source_' i{:}]),'value',1)
  end
end

if ~isempty(mydata)
  %Update gui then try to select the correct set.
  update_callback(handles,'simple');
end

%--------------------------------------------------------------------
function drop(h,eventdata,handles,varargin)
loaddata(h,[],handles,'auto',varargin{:})

%---------------------------------------------------------------------
function dropCallbackFcn(obj,ev,varargin)
%Parse dnd object then call drop.

handles = guihandles(varargin{1});

dropdata = drop_parse(obj,ev,'',struct('getcacheitem','on'));
if isempty(dropdata{1})
  %Probably error.
  return
end

%If dropdata is more than one then try to automatically concat.
if size(dropdata,1)>1
  %If current batch source is not "class" then need to make it class then
  %cat.
  current_data = getappdata(handles.bspcgui,'data');
  if isempty(current_data)
    loaddata(handles.bspcgui,[],handles,'auto',dropdata{1,2});
    dropdata = dropdata(2:end,:);
  end
  for i = 1:size(dropdata,1)
    augment_data(handles,dropdata{i,2},1);
  end
else
  %Call load data.
  loaddata(handles.bspcgui,[],handles,'auto',dropdata{:,2})
end

%--------------------------------------------------------------------
function loaddata(h,eventdata,handles,varargin)
%Load data.

%TODO: Add warning for more than 3D data.
opts   = getappdata(handles.bspcgui, 'gui_options');

mode = varargin{1};%Type of load dialog to run.
name = '';
switch mode
  case 'import'
    %Import data.
    aopts.importmethod = 'editds_defaultimportmethods';
    mydata = autoimport([],[],aopts);
  case 'load'
    %Load data.
    [mydata,name,location] = lddlgpls({'double' 'dataset' 'cell' 'uint8'},['Select Data']);
  case 'auto'
    %Data provided in varargin.
    mydata = varargin{2};
  otherwise
    return
end

if isempty(mydata);  %canceled out of import?
  return;
end
current_data = getappdata(handles.bspcgui,'data');
if ~isempty(current_data)
  method = evriquestdlg('Overwrite existing data?', ...
    'Overwrite Existing Data?', ...
    'Overwrite','Augment','Cancel','Overwrite');
  if strcmpi(method,'overwrite')
    %Clear data.
    clear_callback(h,eventdata,handles,'data');
  elseif strcmpi(method,'augment')
    mydata = augment_data(handles,mydata);
  else
    return
  end
end


if isshareddata(mydata)
  temp_data = mydat.object;
else
  temp_data = mydata;
end

if ~isdataset(temp_data)
  %Assume data is numeric (double uint8).
  temp_data             = dataset(temp_data);
  if ~isempty(name)
    if iscell(name)
      temp_data.name        = name{1};
    else
      temp_data.name        = name;
    end
  else
    temp_data.name        = datestr(now,'yyyymmddTHHMMSSFFF');
  end
elseif strcmp(temp_data.type,'batch')
  %Unfold batch.
  temp_data = unfold_batch(handles,temp_data);
end

setappdata(handles.bspcgui,'data',temp_data)

%Reset list values so they don't get stuck with index values outside of the string.
resize_callback(handles.bspcgui,[],handles);
update_callback(handles,'full');
update_status_callback(handles);
update_top_plot(handles)

%Check to see if batch is Class 0 and move to second value so looks better
%when you load new data.
batchval = get(handles.batch_list,'value');
batchlst = get(handles.batch_list,'string');

%--------------------------------------------------------------------
function clear_callback(h,eventdata,handles,varargin)
%Clear one or more items in gui.

item = varargin{1};

switch item
  case 'data'
    setappdata(handles.bspcgui,'data',[]);
  case 'all'
    setappdata(handles.bspcgui,'data',[]);
end

%Reset lists.
set([handles.batch_source_list handles.step_source_list handles.step_list],'value',1,'String','')

%Clear counts.
setappdata(handles.bspcgui,'batch_count',[]);
setappdata(handles.bspcgui,'step_count',[]);

resize_callback(h,eventdata,handles)
update_callback(handles,'full')

%--------------------------------------------------------------------
function edit_callback(h,eventdata,handles,varargin)
%Clear one or more items in gui.

if nargin<4 | isempty(varargin{1})
  varargin{1} = 'editds';
end

%FIXME: Work out exact use of shareddata below.

switch varargin{1}
  case 'plotgui'
    %Set/update data.
    set_SDO(handles);
    
    %Get SDO.
    myobj = getshareddata(handles.bspcgui);
    if ~isempty(myobj)
      myobj = myobj{1};
    else
      return
    end
    plotgui('new',myobj);
  case 'editds'
    %Set/update data.
    set_SDO(handles);
    
    %Get SDO.
    myobj = getshareddata(handles.bspcgui);
    if ~isempty(myobj)
      myobj = myobj{1};
    else
      return
    end
    editds(myobj);
  case 'editbatch'
    fdata = get_folded_dataset(handles);
    if ~isempty(fdata)
      editds(fdata);
    end
end

%--------------------------------------------------------------------
function save_callback(h,eventdata,handles,varargin)
%Save table or image to file/workspace.

obj = [];
nm = '';
switch varargin{1}
  case 'data'
    obj = get_folded_dataset(handles);
    nm = 'batch_data';
  case 'model'
    [fdata,obj] = get_folded_dataset(handles);
    nm = 'batchfold_model';
end

if ~isempty(obj)
  svdlgpls(obj,['Save ' nm],nm)
end

%--------------------------------------------------------------------
function apply_callback(h,eventdata,handles,varargin)
%Apply current model to new data.

[fdata,mymodel] = get_folded_dataset(handles);
if isempty(fdata)
  return;
end
[mydata,name,location] = lddlgpls({'double' 'dataset' 'cell' 'uint8'},['Select Data']);
if isempty(mydata)
  return
end

newfdata = batchfold(mydata,mymodel);

if ~isempty(newfdata)
  svdlgpls(newfdata,['Save Folded Data'],'batch_data')
end

%--------------------------------------------------------------------
function [outdata,nextset] = makeclass(indata,fieldname,fieldmode,fieldset,newclassname,newval)
%Make a class from another field in a dataset. Based on editds code.
%Overwrite existing 'BSCPC Batch/Step' class if present.

outdata = indata;
if nargin<6
  newval = [];
end

%Get location of existing BSPC class.
%Make class.
mynames = indata.classname(1,:);
thisloc = strfind(mynames,newclassname);

thisloc = ~cellfun('isempty',thisloc);
if any(thisloc)
  nextset = find(thisloc);
  nextset = nextset(1);%Limit to first one.
else
  nextset = length(thisloc)+1;
end

if ismember(fieldname,{'class' 'label' 'axisscale'})
  %in Labels screen - converting labels to field...
  try
    %Get data to move into class.
    if isempty(newval)
      val = get(indata,fieldname,fieldmode,fieldset);
    else
      val = newval;
    end
    
    %Add new class.
    indata.class{fieldmode,nextset} = val;
    indata.classname{fieldmode,nextset} = newclassname;
    
  catch
    erdlgpls({['Unable to create ' fieldname];lasterr},['Create ' fieldname],'modal');
    return
  end
else %Probably 'variable' or 'data'
  %Extract data for class then delete field.
  try
    %where should we put this data?
    fieldmode = 2;%Hack for selecting variable, need to switch mode to 2 so code (from editds) below works.
    onmode = setdiff(1:ndims(indata),fieldmode);  %figure out which mode this is going to be used for (the other viewed mode)
    
    index         = cell(1,ndims(indata));
    [index{:}]    = deal(':');
    index{fieldmode}   = fieldset;
    
    indata.class{onmode,nextset} = indata.data(index{:});
    if isempty(newclassname) & ~isempty(indata.label{fieldmode});
      %Use labelname if no class name provided.
      indata.classname{onmode,nextset} = deblank(indata.label{fieldmode}(fieldset,:));
    else
      indata.classname{onmode,nextset} = newclassname;
    end
    
    %Not sure if/why we need to hard delete so exclude instead so it allows
    %test data to be checked for needed column when applying processor
    %model to new data.
    myincld = indata.include{fieldmode};
    myincld = myincld(myincld~=fieldset);
    indata.include{fieldmode} = myincld;
    %indata = delsamps(indata,fieldset,fieldmode,2);
    
  catch
    erdlgpls({['Unable to create ' fieldname];lasterr},['Create ' fieldname],'modal');
    return
  end
end

outdata = rename_lookup_class(indata,fieldmode,nextset,newclassname);

%--------------------------------------------------------------------
function mydata = rename_lookup_class(mydata,fieldmode,nextset,newclassname)
%Replace "Class" with "Batch" or "Step" in lookup table.

luname = 'Class';

%Update lookup table.
if strcmp(newclassname,'BSPC Batch')
  luname = 'Batch';
end

if strcmp(newclassname,'BSPC Step')
  luname = 'Step';
end

lu = mydata.classlookup{fieldmode,nextset};
%FIXME: This doesn't work.
for i = 1:size(lu,1)
  lu{i,2} = strrep(lu{i,2},'Class',luname);
end

mydata.classlookup{fieldmode,nextset} = lu;

%--------------------------------------------------------------------
function mydata = augment_data(handles,newdata,silent)
%Augment new data to existing data. If silent==1 then don't ask any
%questions, just augment on rows and create a batch class if necessary. 

if nargin<3
  silent = 0;
end

mydata = getappdata(handles.bspcgui,'data');

if nargin<2 | isempty(newdata)
  %Load data to augment.
  [newdata,name,location] = lddlgpls({'double' 'dataset' 'cell' 'uint8'},['Select Data']);
  
  if isempty(newdata)
    %User cancel.
    return
  end
  
  if ~isdataset(newdata)
    %Assume data is numeric (double uint8).
    newdata             = dataset(newdata);
    if ~isempty(name)
      if iscell(name)
        newdata.name        = name{1};
      else
        newdata.name        = name;
      end
    else
      newdata.name        = datestr(now,'yyyymmddTHHMMSSFFF');
    end
  end
end

if ~isdataset(newdata)
  %If data came from loaddata callback as dropped data it may not be a DSO
  %yet so double check here otherwise code below won't work.
  newdata = dataset(newdata);
end

%Sizing code check from editds.
szA = size(mydata); %size(data.data);
szA(end+1) = 1;              %allow for
szB = size(newdata);
szB(end+1:length(szA)) = 1;  %fill in remaining lengths
szA(end+1:length(szB)) = 1;  %fill in remaining lengths
match = szB.*0;     %flag indicating if a given dim can be concated.
for j=1:length(szA);
  dims = setdiff(1:length(szB),j);  %dims which must match
  %enough dims?
  if max(dims)<=length(szA)
    match(j) = all(szA(dims)==szB(dims));
  end
end

%Should only be 2D.
match = match(1:2);

if ~any(match)
  evrierrordlg('New data does not match existing data size. Resize new data and try again.','Data Size Error');
  return
end

method = '';
if ~silent & all(match)
  %Rows or Columns?
  method = evriquestdlg('New data matches modes 1 and 2 of existing data. How you want to augment the existing data?', ...
    'Augment to Existing Data?', ...
    'Rows','Columns','Cancel','Rows');
  if strcmpi(method,'cancel')
    return
  end
else
  method = 'Rows';
end

if strcmpi(method,'rows') | all(match==[1 0])
  %If there's an existing batch in 'class' or 'label' then allow to augment as new batch.
  bobj = get(handles.batch_source_buttongroup,'SelectedObject');
  makebatch = 'yes';
  if ~silent & ~isempty(bobj) & ismember(get(bobj,'userdata'),{'class' 'label'})
    if strcmpi(get(bobj,'userdata'),'class') & ismember('BSPC Batch',newdata.classname(1,:))
      %If existing data has batch class and new data has batch class then
      %don't augment new batch, just augment normally and let cat method
      %merge tables.
      makebatch = 'no';
    else
      %Ask if want to make new batch.
      makebatch = evriquestdlg('Augment as new batch?', ...
        'Augment to Existing Data?', ...
        'Yes','No','Cancel','Yes');
      if strcmpi(makebatch,'cancel')
        return
      end
    end
  end
  
  if strcmpi(makebatch,'yes')
    idx = get(handles.batch_source_list,'Value');
    if strcmp(get(bobj,'userdata'),'class')
      %Find class and add class so cat will work.
      oldlookup = mydata.classlookup{1,idx};
      if isempty(oldlookup)
        %Need to make a class.
        mydata.class{1,idx} = ones(size(mydata,1),1);
        mydata = rename_lookup_class(mydata,1,idx,'BSPC Batch');
        oldlookup = mydata.classlookup{1,idx};
      end
      maxcls = max([oldlookup{:,1}]);
      newdata.class{1,idx} = (maxcls+1)*ones(size(newdata,1),1);
      newdata = rename_lookup_class(newdata,1,idx,'BSPC Batch');
      newdata.classname{1,idx} = 'BSPC Batch';
      
    elseif strcmp(get(bobj,'userdata'),'label')
      %Must be label.
      oldlabels = mydata.label{1,idx};
      maxlbs = length(unique(oldlabels,'rows'));
      newdata.label{1,idx} = repmat(['Batch ' num2str(maxlbs+1)],size(newdata,1),1);
    else
      %Can't augment batch indicator in other sources so make a class first
      %then augment. If nothing is specified for source then make one.
      
      if ~silent
        %Warn user a class is being created.
        makebatch = evriquestdlg('Batch source (in class or label field) can''t be located. Add new class?', ...
          'Create Batch Class?', ...
          'Yes','No','Cancel','Yes');
        if ~strcmpi(makebatch,'yes')
          return
        end
      end
      %Make classes in existing data.
      myfield = get(bobj,'userdata');
      if isempty(myfield)
        %User hasn't made any selection in batch source so we need to
        %create first class.
        
        %Using 6th input will assign to next empty set.
        [mydata,myclassidx] = makeclass(mydata,'class',1,1,'BSPC Batch',ones(1,size(mydata,1)));
        
      else
        %User has selected something other than class/label to be batch
        %source.
        myclassidx = get(handles.batch_source_list,'value');%Selected batch.
        [mydata,myclassidx] = makeclass(mydata,myfield,1,myclassidx,'BSPC Batch');
      end
      
      
      %Add class to new data.
      oldlookup = mydata.classlookup{1,myclassidx};
      maxcls = max([oldlookup{:,1}]);
      newdata.class{1,myclassidx} = (maxcls+1)*ones(size(newdata,1),1);
      newdata = rename_lookup_class(newdata,1,myclassidx,'BSPC Batch');
    end
  end
  mydata = cat(1,mydata,newdata);
else
  %No options, just tack it onto mode 2.
  mydata = cat(2,mydata,newdata);
end

setappdata(handles.bspcgui,'data',mydata)

resize_callback(handles.bspcgui,[],handles);
update_callback(handles,'simple');
update_status_callback(handles);

%--------------------------------------------------------------------
function mydata = unfold_batch(handles,data)
%Unfold a batch dso (taken from batchdigester).
%  Make labels and classes from batch labels and claess.
%  Add a class 'BSPC Unfold Batch' to identify batches.

%batch DSO? convert to vertical standard DSO with appropriate labels
bdata = data.data;
%look for labels in that DSO which we can use to describe each batch
% bset = [];
all_lbls = data.label(1,:);

%create unfolded DSO
newdso = dataset(cat(1,bdata{:}));
newdso = copydsfields(data,newdso,[2 2]);

%Now, expand labels out into a cell array appropriate for the concatenated
%batches
for set=1:length(all_lbls);
  if isempty(all_lbls{set}); break; end
  lbls = {};
  for j=1:length(bdata);
    %first do necessary batch labels
    lbls = [lbls;repmat({all_lbls{set}(j,:)},size(bdata{j},1),1)];
  end
  newdso.label{1,set} = lbls;
end

%expand classes out into a cell array appropriate for the concatenated
%batches
all_classes = data.class(1,:);
for set=1:length(all_classes);
  if isempty(all_classes{set}); break; end
  cls = [];
  for j=1:length(bdata);
    %first do necessary batch labels
    cls = [cls all_classes{set}(j)*ones(1,size(bdata{j},1))];
  end
  newdso.classlookup{1,set} = data.classlookup{1,set};
  newdso.class{1,set} = cls;
end

%Create batch class for this unfold operation.
newcls = [];
newclstbl = [];
for j=1:length(bdata);
  %first do necessary batch labels
  newcls = [newcls;repmat(j,size(bdata{j},1),1)];
  newclstbl = [newclstbl; {j ['Batch ' num2str(j)]}];
end

newdso.class{1,end+1}=newcls;
newdso.classname{1,end}='BSPC Batch';
newdso.classlookup{1,end}=newclstbl;

mydata = newdso;

%--------------------------------------------------------------------
function send2analysis_callback(h,eventdata,handles,varargin)
%Make data ready for analysis. Send data to batchfold function with proper
%classes identified.

mytag = get(get(handles.analysis_panel,'SelectedObject'),'tag');

aval = '';
switch mytag
  case 'analysis_spca'
    %Summary PCA
    aval = 'pca';
  case 'analysis_batchmaturity'
    %Batch Maturity
    aval = 'batchmaturity';
  case 'analysis_mpca'
    %MPCA
    aval = 'mpca';
  case {'analysis_parafac' 'analysis_sparafac'}
    %Parafac
    aval = 'parafac';
  case 'analysis_parafac2'
    %Parafac2 can only be done from command line.
    aval = '';
  case 'analysis_other'
    aval = 'other';
  otherwise
    %Next/Previous button.
end

if ~isempty(aval)
  fdata = get_folded_dataset(handles);
  if isempty(fdata)
    return
  end

  %create/connect to analysis window and set it up
  ha = getappdata(handles.bspcgui,'analysis_interface');
  if isempty(ha) | ~isa(ha,'evrigui') | ~ha.isvalid
    ha = evrigui('analysis','-reuse');
  end
  
  if ~strcmp(aval,'other') & ~strcmpi(ha.getMethod,aval)
    %change analysis method if not what we currently have selected
    ha.setMethod(aval);
  end
  if ~isempty(ha.getXblock) | ~isempty(ha.getModel)
    %if data or model exist, ask how to load this data
    resp = evriquestdlg('Load as Calibration or Validation data?','Load as...','Calibration','Validation','Cancel','Validation');
    if isempty(resp) | isnumeric(resp)
      return;
    end
    switch resp
      case 'Cancel'
        return;
      case 'Calibration'
        ha.setXblock(fdata);
      case 'Validation'
        ha.setXblockVal(fdata);
    end
  else
    %nothing in calibration x-block or model? load as calibration data
    ha.setXblock(fdata);
  end
  figure(ha.handle);
  
  %store evrigui object for later use
  setappdata(handles.bspcgui,'analysis_interface',ha)
  
  mytag = get(get(handles.analysis_panel,'SelectedObject'),'tag');
else
  thisval = upper(strrep(mytag,'analysis_',''));
  evriwarndlg(['Batch analysis method (' thisval ') not implemented in Analysis yet. Save data and try manual command call.'],'Under Construction')
end
%--------------------------------------------------------------------
function select_analysis_callback(h,eventdata,handles,varargin)
%Update enabled tabs based on select analysis.

%No access to java component so return for now.
%return

%Get Java object so we can disable un-needed tabs. Can't use visible
%property on tabs.
jtg = getappdata(handle(handles.batchtabgroup),'JTabbedPane');
tbs = get(handles.batchtabgroup,'Children');

%Tab number:
% 2 'batch_locate' 'Batches'
% 3 'step_locate'  'Steps'
% 4 'batch_align'  'Align'
% 5 'summarize'    'Summarize'

mytag = get(get(handles.analysis_panel,'SelectedObject'),'tag');

tab_enable = [];
switch mytag
  case 'analysis_spca'
    %Summary PCA
    tab_enable = [2 3 5];%{'batch_locate' 'step_locate' 'summarize'};
  case 'analysis_batchmaturity'
    %Batch Maturity
    tab_enable = [2 3 4];%{'batch_locate' 'step_locate' 'batch_align'};
  case 'analysis_mpca'
    %MPCA
    tab_enable = [2 3 4];%{'batch_locate' 'step_locate' 'batch_align'};
  case 'analysis_parafac'
    %Parafac
    tab_enable = [2 3 4];%{'batch_locate' 'step_locate' 'batch_align'};
  case 'analysis_sparafac'
    %Summary Parafac
    tab_enable = [2 3 5];%{'batch_locate' 'step_locate' 'summarize'};
  case 'analysis_parafac2'
    %Parafac2
    tab_enable = [2 4];%{'batch_locate'};
  case 'analysis_other'
    %MCR or PCA, same as BM.
    tab_enable = [2 3 4];
  otherwise
    %Next/Previous button.
end

setappdata(handles.bspcgui,'enabled_tabs',tab_enable);

%Set the tab to first enabled.
%set(handles.batchtabgroup,'SelectedIndex',tab_enable(1));
%Disable specific tabs.
if ~ismember(get(h,'tag'),{'previoustab' 'nexttab'});
  %No access to java tab object in 14b.
  if checkmlversion('<','8.4')
    for i = [2:5]
      if any(i==tab_enable)
        jtg.setEnabledAt(i-1,true);
      else
        jtg.setEnabledAt(i-1,false);
      end
    end
  else
    %14b fix.
    
    %Step panel.
    step_group = allchild(handles.step_source_buttongroup);
    step_group = [step_group; handles.step_list];
    if any(3==tab_enable)
      myenable = 'on';
    else
      myenable = 'off';
    end
    set(step_group,'enable',myenable);
    
    %Align panel.
    align_group = allchild(handles.align_buttongroup);
    align_group = [align_group; allchild(handles.align_batchselect_panel)];
    align_group = [align_group; allchild(handles.align_settings_panel)];
    if any(4==tab_enable)
      myenable = 'on';
    else
      myenable = 'off';
    end
    set(align_group ,'enable',myenable);
    
    %Summary panel.
    if any(5==tab_enable)
      set(allchild(handles.summarize_button_panel) ,'enable','on');
    else
      set(allchild(handles.summarize_button_panel) ,'enable','off');
    end
  end
  
else
  %Next/Previous callback
  idx = gettabgroupindex(handles);
  if strcmpi(get(h,'tag'),'nexttab')
    newidx = tab_enable(tab_enable>idx);
    newidx = [newidx 6];
    settabgroupindex(handles, newidx(1))
  else
    newidx = tab_enable(tab_enable<idx);
    newidx = [1 newidx];
    settabgroupindex(handles, newidx(end))
  end
end

%Change default alignment for the method. If BM or Other then set to
%none otherwise linear.
set(handles.align_buttongroup,'selectedobject',handles.align_source_none);%Set to none.
if ismember(mytag,{'analysis_mpca' 'analysis_parafac'})
  set(handles.align_buttongroup,'selectedobject',handles.align_source_linear)
end

update_alignment(h,[],handles,[])
update_status_callback(handles)

%--------------------------------------------------------------------
function settabgroupindex(handles, newidx)
%Set tab group current tab by index value.

if checkmlversion('<','8.4')
  set(handles.batchtabgroup,'SelectedIndex',newidx);
else
  %2014b fix. This relies on children being in same order as added to tab
  %group. 
  mychildren = get(handles.batchtabgroup,'Children');
  set(handles.batchtabgroup,'SelectedTab',mychildren(newidx));
end

%--------------------------------------------------------------------
function current_idx = gettabgroupindex(handles)
%Set tab group current tab by index value.

if checkmlversion('<','8.4')
  current_idx = get(handles.batchtabgroup,'SelectedIndex');
else
  mytab = get(handles.batchtabgroup,'SelectedTab');
  current_idx = getappdata(mytab,'tindex');
end

%--------------------------------------------------------------------
function editoptions(h, eventdata, handles, varargin)
%Edit options using optionsGUI for current analysis.

switch varargin{1}
  case 'gui'
    opts = getappdata(handles.bspcgui,'gui_options');
    outopts = optionsgui(opts);
    if ~isempty(outopts)
      setappdata(handles.bspcgui,'gui_options',outopts);
      if ~strcmp(opts.renderer,outopts.renderer)
        %Change renderer.
        set(handles.bspcgui,'renderer',outopts.renderer);
      end
    end
    
  case 'function'
    %NOT USED - Gui is basically how options are set.
    
%     opts = getappdata(handles.bspcgui,'fcn_options');
%     outopts = optionsgui(opts);
%     if ~isempty(outopts)
%       setappdata(handles.bspcgui,'fcn_options',outopts);
%     end
end

%--------------------------------------------------------------------
function use_callback(h, eventdata, handles, varargin)
%Checkbox click for using batch/step.

state = get(h,'value');
myparent = get(h,'parent');

if state==0
  myenable = 'off';
else
  myenable = 'on';
end

if strfind(get(myparent,'tag'),'batch')
  set(allchild(handles.batch_source_buttongroup),'enable',myenable);
else
  set([allchild(handles.step_source_buttongroup); allchild(handles.table_panel)],'enable',myenable);
end

update_status_callback(handles)
mtool_buttonup_fcn(h,eventdata,handles,'buttonup')

%--------------------------------------------------------------------
function update_attribute_list(h, eventdata, handles, varargin)
%Changing source of batch or step. Updates field list box.

mydata = getappdata(handles.bspcgui,'data');
if isempty(mydata)
  set(handles.batch_source_list,'String','')
  set(handles.step_source_list,'String','')
  return
end

src = get(h,'userdata');

mkclass = 'on';%Enable make classs button.
mylbs = [];
mysvals = [];

switch src
  case 'axisscale'
    mylbs = mydata.axisscalename(1,:);
    mysvals = mydata.axisscale(1,:);
  case 'class'
    mylbs = mydata.classname(1,:);
    mysvals = mydata.class(1,:);
    mkclass = 'off';
  case 'label'
    mylbs = mydata.labelname(1,:);
    mysvals = mydata.label(1,:);
  case 'variable'
    mylbs = str2cell(mydata.label{2,1});
    if isempty(mylbs) | isempty(mylbs{1})
      mylbs = str2cell(sprintf('Variable %d\n',[1:size(mydata,2)]));
    end
  otherwise
    %Shouldn't get here but don't make fatal error.
    mylbs = [];
    mkclass = 'off';
end

%Filter unnamed labels.
for i = 1:length(mylbs)
  if isempty(mylbs{i})
    if isempty(mysvals{i})
      mylbs{i} = 'Empty';
    else
      mylbs{i} = 'Unnamed';
    end
  end
end

switch varargin{1}
  case 'batch'
    myval = get(handles.batch_source_list,'value');
    if isempty(myval) | myval>length(mylbs)
      %Existing value isn't valid, set to 1.
      myval = 1;
    end
    set(handles.batch_source_list,'Value',myval,'String',mylbs)
    %set(handles.batch_source_makeclassbtn,'enable',mkclass)
  case 'step'
    myval = get(handles.step_source_list,'value');
    if isempty(myval) | myval>length(mylbs)
      %Existing value isn't valid, set to 1.
      myval = 1;
    end
    set(handles.step_source_list,'Value',myval,'String',mylbs)
    %set(handles.step_source_makeclassbtn,'enable',mkclass)
end

update_batchcount(h, eventdata, handles, varargin)

%--------------------------------------------------------------------
function update_batchcount(h, eventdata, handles, varargin)
%Update counts of batches and steps, update "Step Selection" listbox
%for selected field, and update alignment batch dropdown.

mydata = getappdata(handles.bspcgui,'data');

if strfind(get(h,'tag'),'batch')
  btn = get(handles.batch_source_buttongroup,'selectedobject');
  type = 'batch';
  myval = get(handles.batch_source_list,'value');
else
  btn = get(handles.step_source_buttongroup,'selectedobject');
  type = 'step';
  myval = get(handles.step_source_list,'value');
end

if isempty(mydata) | isempty(btn) | isempty(myval)
  return
end

src = get(btn,'userdata');

switch src
  case 'axisscale'
    thisbatch = mydata.axisscale{1,myval};
  case 'class'
    thisbatch = mydata.class{1,myval}';
  case 'label'
    thisbatch = mydata.label{1,myval};
  case 'variable'
    thisbatch = mydata.data(:,myval);
  otherwise
    %Should never get here because custom select and load should always
    %create a class.
    thisbatch = [];
end

%Get unique values so we can count and show batches/steps.
if isnumeric(thisbatch)
  my_items = unique(thisbatch);
  my_items = num2str(my_items);
else
  my_items = unique(thisbatch,'rows');
end

setappdata(handles.bspcgui,[type '_count'],size(my_items,1));%Set count.
setappdata(handles.bspcgui,[type '_list'],my_items);%Set list of items.

if strcmpi(src,'class')
  my_items = mydata.classlookup{1,myval};
  if ~isempty(my_items)
    myclass = mydata.class{1,myval};
    my_items = get_lookup(my_items,myclass);%Remove class 0 if needed.
    my_items = my_items(:,2);
  end
end

if strcmp(type,'step')
  %Update step selection list.
  
  %Flush list box first to avoid warning when we assign long lists (when
  %user selects a variable with a lot of unique values for example). Can get
  %"Warning: This uicontrol's ListboxTop value..." warnings.
  set(handles.step_list,'string','','value',[])
  set(handles.step_list,'string',my_items,'value',[1:size(my_items,1)])
  
else
  if isempty(my_items)
    my_items = ' ';
  end
  %Update batch selection list.
  set(handles.align_selectbatch_txt,'string',my_items,'value',1)
  if strcmpi(src,'axisscale') | strcmpi(src,'variable')
    %Enable gap checkbox.
    set(handles.batch_source_gapchk,'enable','on')
  else
    set(handles.batch_source_gapchk,'enable','off')
  end
end

update_status_callback(handles)

%--------------------------------------------------------------------
function clear_alignvec_callback(h,eventdata,handles,varargin)
%Clear manual loaded target alignment.

setappdata(handles.bspcgui,'targetdata',[]);
set(handles.align_showtarget_txt,'String','');
update_alignment(h,eventdata,handles,varargin);%Clears data.

%--------------------------------------------------------------------
function load_alignvec_callback(h,eventdata,handles,varargin)
%Load alignment target vector.

if isempty(varargin)
  [myvar,name,location] = lddlgpls({'double' 'dataset'},['Select Custom Batch/Step Variable']);
else
  myvar = varargin{1};
end

if isempty(myvar)
  return
end

if ~isvec(myvar)
  errordlg('Variable must be vector.','Vector Only')
  return
end

setappdata(handles.bspcgui,'targetdata',myvar);
set(handles.align_showtarget_txt,'String',['Vector [' num2str(length(myvar)) 'x1]']);

update_alignment(h,eventdata,handles,varargin);%Clears data.

%--------------------------------------------------------------------
function load_custom_callback(h,eventdata,handles,varargin)
%Load a cutom step or batch variable. Check for existing BSPC Step/Batch
%class and overwrite if there.

mydata = getappdata(handles.bspcgui,'data');
btype = varargin{1};%'batch' or 'step'

if isempty(mydata)
  return
end

if length(varargin)==1
  [myvar,name,location] = lddlgpls({'double' 'dataset' 'cell' 'char'},['Select Custom Batch/Step Variable']);
else
  myvar = varargin{2};
end

if isdataset(myvar)
  %Pull data out if DSO.
  myvar = myvar.data;
end

%TODO: Check this.
%Check to make sure data is correct length.
if length(myvar)~=size(mydata,1)&min(size(myvar))==1
  evrierrordlg(['Size mismatch, expecting (mode 1) length: ' num2str(size(mydata,1)) ' Check size of data being loaded and try again.'],'Sizing Error');
  return
end

%Make class.
myidx = [];
mynames = mydata.classname(1,:);
if strcmp(btype,'batch')
  thisloc = strfind(mynames,'BSPC Batch');
else
  thisloc = strfind(mynames,'BSPC Step');
end

thisloc = ~cellfun('isempty',thisloc);
if any(thisloc)
  myidx = find(thisloc);
  myidx = myidx(1);%Limit to first one.
else
  myidx = length(thisloc)+1;
end

%Clear the lookup table.
mydata.classlookup{1,myidx} = [];

if strcmp(btype,'batch')
  mydata.class{1,myidx} = myvar;
  mydata.classname{1,myidx} = 'BSPC Batch';
  mydata = rename_lookup_class(mydata,1,myidx,'BSPC Batch');
  
  set(handles.batch_source_buttongroup,'selectedobject',handles.batch_source_class)
else
  mydata.class{1,myidx} = myvar;
  mydata.classname{1,myidx} = 'BSPC Step';
  mydata = rename_lookup_class(mydata,1,myidx,'BSPC Step');
  
  set(handles.step_source_buttongroup,'selectedobject',handles.step_source_class)
end

setappdata(handles.bspcgui,'data',mydata);

%Set selected

%Refresh count and update status.
update_callback(handles,'full')

%--------------------------------------------------------------------
function select_custom_callback(h,eventdata,handles,varargin)
%Turn step selection mode on or off.

mydata = getappdata(handles.bspcgui,'classed_data');
currentmode = getappdata(handles.bspcgui,'step_selection');

if isempty(mydata)
  return
end

if isempty(currentmode)
  currentmode = 0;
end

if strcmp(get(h,'tag'),'step_source_selectbtn')
  %Turn on step selection.
  newmode = 1;
else
  %Turn off step selection.
  newmode = 0;
end

%Add initial reference var/batch
curval_var = get(handles.variable_list,'value');

curval_batch = get(handles.batch_list,'value');
curval_batch = curval_batch(1);%Make sure only one value.

[batchclass, batchlu, batchname] = get_bach_class_info(handles,mydata);
if isempty(batchlu)
  evriwarndlg('Can''t locate Batch class. Make sure Batch Source is "class".','No Batch Class');
  return
end

%Get existing step info.
refinfo = getappdata(handles.bspcgui,'step_selection_info');
if ~isempty(refinfo) & newmode
  %If there's existing step selection info and var/step has changed then
  %ask if should clear.
  if refinfo.refvariable ~= curval_var(1) | refinfo.refbatch_list_val ~= curval_batch
    qans = evriquestdlg('Variable or Batch has changed from last selection. Clear selections or use last?','Clear Selection','Use','Clear','Cancel','Use');
    if strcmpi(qans,'cancel')
      return
    end
    if strcmpi(qans,'use')
      set(handles.variable_list,'value',refinfo.refvariable);
      set(handles.batch_list,'value',refinfo.refbatch_list_val);
      %Reset values so things work below.
      curval_var = get(handles.variable_list,'value');
      curval_batch = get(handles.batch_list,'value');
      curval_batch = curval_batch(1);%Make sure only one value.
      [batchclass, batchlu, batchname] = get_bach_class_info(handles,mydata);
    else
      refinfo = [];
    end
  end
end

%Get selected batch (class number).
myclass = get_selected_batches(handles);

if isempty(refinfo)
  refinfo.refvariable = curval_var(1);
  refinfo.refbatch_class = myclass(1);%Reference class number.
  refinfo.refbatch_list_val = curval_batch;%List value for ref (so don't have to reverse lookup from class).
  refinfo.old_list_val = curval_batch;%Last list box value so we know when to recalculate batches.

  refinfo.step_loc_index = [];%Index of new steps.
  refinfo.temporary_class = zeros(size(mydata,1),1);%Initial new class field.
end

if newmode
  if length(curval_var)>1
    curval_var = curval_var(1);
  end
  %In step selection mode, disable multi select in batch list.
  set(handles.variable_list,'min',0,'max',1,'value',curval_var);
  set(handles.batch_list,'min',0,'max',1,'value',curval_batch);
  
  %Get variable and batch list and add "*" next to reference.
  vlist = str2cell(get(handles.variable_list,'string'));
  if ~isempty(vlist)
    vlist{curval_var(1)} = [vlist{curval_var(1)} '*'];
    set(handles.variable_list,'string',cell2str(vlist))
    
    vlist = str2cell(get(handles.batch_list,'string'));
    vlist{curval_batch(1)} = [vlist{curval_batch(1)} '*'];
    set(handles.batch_list,'string',cell2str(vlist))
  end
  
  setappdata(handles.bspcgui,'step_selection_info',refinfo);
else
  %Normal mode, allow multi selections get rid of ref info.
  set(handles.variable_list,'min',0,'max',2,'value',curval_var)
  set(handles.batch_list,'min',0,'max',2,'value',curval_batch)
  %setappdata(handles.bspcgui,'step_selection_info',[]);
end
setappdata(handles.bspcgui,'step_selection',newmode)
%if newmode
  %A new BSPC Step class should be available so call in 'full' mode so it's
  %automatically selected.
  update_callback(handles,'full')
%end
batch_select_callback(h,eventdata,handles,varargin)
resize_callback(handles.bspcgui,[],handles);

%--------------------------------------------------------------------
function step_select_callback(h,eventdata,handles,varargin)
%Step selection.

setappdata(handles.bspcgui,'step_count',length(get(h,'value')));
update_status_callback(handles)
update_bottom_plot(handles)

%--------------------------------------------------------------------
function update_alignment(h,eventdata,handles,varargin)
%Enalbe alignment settings.

src = get(handles.align_buttongroup,'SelectedObject');
src = get(src,'userdata');

set(findobj(handles.align_settings_panel,'type','uicontrol'),'enable','off');
set(findobj(handles.align_batchselect_panel,'type','uicontrol'),'enable','on');

if strcmp(src,'cow')
  set(findobj(handles.align_settings_panel,'type','uicontrol'),'enable','on');
elseif strcmp(src,'none')
  set(findobj(handles.align_batchselect_panel,'type','uicontrol'),'enable','off');
end

%Clear aligned data, user will need to push update button.
setappdata(handles.bspcgui,'aligned_data',[])

%Disable alignment batch selection if using custom vector to align to. Note
%that variable (column) to align to must still be available.
tdata = getappdata(handles.bspcgui,'targetdata');
if ~isempty(tdata)
  set([handles.align_selectbatch_txt],'enable','off');
else
  set([handles.align_selectbatch_txt],'enable','on');
end

%Becuase the information needed to update batch selection and variables is
%avaialble in other update functions the updating is done there:
%  Update batch selection dropdown done in update_batchcount()
%  Update available variables update_callback()

update_status_callback(handles)
update_plots(handles)

%--------------------------------------------------------------------
function update_alignment_data_callback(handles,varargin)
%Update alignment data and callbacks.

update_data(handles,'aligned');
update_plots(handles)

%--------------------------------------------------------------------
function setbatch_callback(handles,update_type)
%Save source of batch so can be used to populate model later.

mysource = [];

%--------------------------------------------------------------------
function update_batchsource_callback(handles,update_type)
%Update batch source.

%Send data to batchfold so classes can get updated. Parsed classes are then
%used to populate batch info in listbox and plot data.
update_callback(handles,update_type)


%--------------------------------------------------------------------
function update_callback(handles,update_type)
%Update GUI. Updates batch and step info. If 'update_type' is "simple' then
%just refreshes already selected items. Otherwise, code will search for
%'step' and 'batch' in attribute names make "default" selections based on
%the info.

mydata = getappdata(handles.bspcgui,'data');

%update_alignment(handles.bspcgui,[],handles);%Update controls.

if isempty(mydata)
  %Can't do a full update if no data.
  update_type = 'simple';
else
  %Refresh alignmnet variable list, variables should only change if data
  %changes. Always use first set for now.
  myvars = mydata.label{2,1};
  if isempty(myvars)
    myvars = str2cell(sprintf('Variable %d\n',[1:size(mydata,2)]));
  end
  %Check to make sure value doesn't get out of scale.
  myval = get(handles.align_selectvariable_txt,'value');
  if myval>size(myvars,1)
    myval = 1;
  end
  set(handles.align_selectvariable_txt,'string',myvars,'value',myval)
end

%TODO: Check to see what attributes are available and disable controls that have
%not data present for the list.

if strcmp(update_type,'simple')
  %Refresh lists based on current selections.
  thisobj = get(handles.batch_source_buttongroup,'selectedobject');
  if ~isempty(thisobj)
    update_attribute_list(thisobj, [], handles,'batch');
    update_batchcount(thisobj, [], handles);
  end
  thisobj  = get(handles.step_source_buttongroup,'selectedobject');
  if ~isempty(thisobj)
    update_attribute_list(thisobj, [], handles,'step');
    update_batchcount(thisobj, [], handles);
  end
else
  %Search data for keyword then set selected button to the key.
  tabs = {'batch' 'step'};
  for j = 1:2
    [myfield,myidx] = findbatchindex(handles,tabs{j});
    
    if ~isempty(myfield)
      %Set selected field and index of field.
      mychild = get(handles.([tabs{j} '_source_buttongroup']),'children');
      for i = 1:length(mychild)
        if strcmp(get(mychild(i),'userdata'),myfield)
          %Select field and call callback.
          set(handles.([tabs{j} '_source_buttongroup']),'SelectedObject',mychild(i));
          update_attribute_list(mychild(i), [], handles,tabs{j});
          %Make selection and call callback.
          set(handles.([tabs{j} '_source_list']),'value',myidx)
          update_batchcount(mychild(i), [], handles);%
        end
      end
    else
      %Deselect step use.
      %set(handles.step_use,'value',0);
      %use_callback(handles.step_use,[],handles);
    end
  end
end

%Update data plot controls.
myval = get(handles.variable_list,'value');
if ~getappdata(handles.bspcgui,'step_selection')
  %Update plot variable list only if not in step selection mode (list will already be updated).
  if ~isempty(mydata)
    mylbls = mydata.label{2,1};%
    if isempty(mylbls)
      mylbls = str2cell(sprintf('Variable %d\n',[1:size(mydata,2)]));
    end
    if myval>size(mydata,2)
      myval = 1;
    end
    set(handles.variable_list,'value',myval,'string',mylbls)
  else
    set(handles.variable_list,'value',1,'string','');
  end
end

%Update batch list next to lower plot.
obj = get(handles.batch_source_buttongroup,'selectedobject');%Button handle.
if ~isempty(obj) & ~isempty(mydata)
  src = get(obj,'userdata');%Batch key word.
  if strcmp(src,'class')
    myclassidx = get(handles.batch_source_list,'value');%Selected batch.
    thisbatch = mydata.classlookup{1,myclassidx};
  else
    %Not using class so run data through batchfold to create lookup table.
    cdata = update_data(handles,'classed');
    myclassidx = findset(cdata,'class',1,'BSPC Batch');
    if ~isempty(myclassidx)
      thisbatch = cdata.classlookup{1,myclassidx};
    else
      thisbatch = [];
    end
  end
  
  if ~isempty(thisbatch)
    %Remove class 0.
    if thisbatch{1} == 0
      thisbatch = thisbatch(2:end,:);
    end
    thisbatch = thisbatch(:,2);
  end
else
  thisbatch = [];
end

if ~isempty(thisbatch)
  myval = get(handles.batch_list,'value');
  if myval>length(thisbatch)
    myval = 1;
  end
  
  if ~getappdata(handles.bspcgui,'step_selection')
    set(handles.batch_list,'value',myval,'string',thisbatch,'userdata',myclassidx)
  end
else
  set(handles.batch_list,'value',1,'string','','userdata',[]);
end

%TODO: Only update if align.
%update_top_plot(handles)

update_alignment(handles.bspcgui,[],handles);%Update controls, will update plots as well.

%--------------------------------------------------------------------
function [myfield,myidx] = findbatchindex(handles,mykey)
%Search dataset for index key words "batch" or "index".
% mykey = 'batch' or 'step'

mydata = getappdata(handles.bspcgui,'data');

%Look for default step indicator.
myfield = '';
myidx = [];
for i = {'class' 'label' 'axisscale'}
  mynames = mydata.([i{:} 'name'])(1,:);
  %Make sure empties are empty strings so strfind works below.
  emptynames = cellfun('isempty',mynames);
  if any(emptynames)
    mynames(emptynames) = repmat({''},1,length(find(emptynames)));
  end
  thisloc = strfind(lower(mynames),mykey);
  thisloc = ~cellfun('isempty',thisloc);
  if any(thisloc)
    myfield = i{:};
    myidx = find(thisloc);
    myidx = myidx(1);%Limit to first one.
    break
  end
end

%Check variable if needed.
if isempty(myfield)
  mynames = str2cell(mydata.label{2,1});
  thisloc = strfind(lower(mynames),mykey);
  thisloc = ~cellfun('isempty',thisloc);
  if any(thisloc)
    myfield = 'variable';
    myidx = find(thisloc);
    myidx = myidx(1);%Limit to first one.
  end
end

if ~get(handles.([mykey '_use']),'value')
  myfield = [];
end

%--------------------------------------------------------------------
function update_status_callback(handles)
%Update status info.

mydata = getappdata(handles.bspcgui,'data');
mytabs = getappdata(handles.bspcgui,'enabled_tabs');

%Update data status.
mystr = {'No Data Loaded'};
if ~isempty(mydata)
  %Update data info.
  mystr = {['Name: ' mydata.name]; ['Size: ' mydata.sizestr]};
end
set(handles.data_status,'string',mystr)

%Update status panel.
mystatus = {};
if isempty(mydata)
  mystatus = [mystatus; {'Data:' 'None'}];
else
  mystatus = [mystatus; {'Data:' [mydata.name ' (' mydata.sizestr ')']}];
end

%Analysis type.
aobj = get(handles.analysis_panel,'SelectedObject');
mystatus = [mystatus; {'Analysis:' upper(get(aobj,'UserData'))}];

mystatus = [mystatus; {'-------------' '-------'}];

%Batch type.
if any(mytabs==2)
  bobj = get(handles.batch_source_buttongroup,'SelectedObject');
  if isempty(bobj) | ~get(handles.batch_use,'value')
    mystatus = [mystatus; {'Batch:' 'None'}];
    mystatus = [mystatus; {'Count:' '0'}];
  else
    bcount = getappdata(handles.bspcgui,'batch_count');
    if isempty(bcount)
      bcount = 0;
    end
    
    mybfield = get(bobj,'userdata');
    mybname = '';
    %Get selected source list name.
    if ismember(mybfield,{'class' 'label' 'variable' 'axisscale'})
      fstr = get(handles.batch_source_list,'String');
      fval = get(handles.batch_source_list,'Value');
      mystr = '';
      if ~isempty(fstr)
        mystr = strtrim(fstr{fval});
      end
      mybname = [' (' mystr ')'];
    end
    
    mystatus = [mystatus; {'Batch:' [upper(mybfield) mybname]}];
    mystatus = [mystatus; {'Count:' num2str(bcount)}];
  end
else
  mystatus = [mystatus; {'Batch:' 'N/A'}];
end

mystatus = [mystatus; {'-------------' '-------'}];

%Step type.
if any(mytabs==3)
  sobj = get(handles.step_source_buttongroup,'SelectedObject');
  if isempty(sobj) | ~get(handles.step_use,'value')
    mystatus = [mystatus; {'Step:' 'None'}];
    mystatus = [mystatus; {'Count:' '0'}];
  else
    scount = getappdata(handles.bspcgui,'step_count');
    if isempty(scount)
      scount = 0;
    end
    
    mysfield = get(sobj,'userdata');
    mysname = '';
    %Get selected source list name.
    if ismember(mysfield,{'class' 'label' 'variable' 'axisscale'})
      sstr = get(handles.step_source_list,'String');
      sval = get(handles.step_source_list,'Value');
      mystr = '';
      if ~isempty(sstr)
        mystr = strtrim(sstr{sval});
      end
      mysname = [' (' mystr ')'];
    end
    
    mystatus = [mystatus; {'Step:' [upper(mysfield) mysname]}];
    mystatus = [mystatus; {'Count:' num2str(scount)}];
  end
else
  mystatus = [mystatus; {'Step:' 'N/A'}];
end

mystatus = [mystatus; {'-------------' '-------'}];

%Align type.
if any(mytabs==4)
  aobj = get(handles.align_buttongroup,'SelectedObject');
  if isempty(aobj)
    mystatus = [mystatus; {'Alignment:' 'None'}];
    %mystatus = [mystatus; {'Count:' '0'}];
  else
    mystatus = [mystatus; {'Alignment:' upper(get(aobj,'userdata'))}];
    %mystatus = [mystatus; {'Count:' num2str(scount)}];
  end
  %Get alignment batch/var.
  mybat = get(handles.align_selectbatch_txt,'string');
  if iscell(mybat)
    mybat = cell2str(mybat);
  end
  mybat = mybat(get(handles.align_selectbatch_txt,'value'),:);
  tdata = getappdata(handles.bspcgui,'targetdata');
  if ~isempty(tdata)
    mybat = 'Manually Loaded';
  end
  mystatus = [mystatus; {'Batch:' mybat}];
  myvar = get(handles.align_selectvariable_txt,'string');
  myvar = myvar(get(handles.align_selectvariable_txt,'value'),:);
  if iscell(myvar)
    myvar = myvar{:};
  end
  mystatus = [mystatus; {'Variable:' myvar}];
else
  mystatus = [mystatus; {'Alignment:' 'N/A'}];
end

mystatus = [mystatus; {'-------------' '-------'}];
%Summary type.
if any(mytabs==5)
  myobjs = findobj(handles.summarize_button_panel,'value',1);
  if isempty(myobjs)
    mystatus = [mystatus; {'Summarize:' 'None'}];
    %mystatus = [mystatus; {'Count:' '0'}];
  else
    mystatus = [mystatus; {'Summarize:' upper(get(myobjs(1),'userdata'))}];
    for i = 2:length(myobjs)
      mystatus = [mystatus; {' ' upper(get(myobjs(i),'userdata'))}];
    end
    %mystatus = [mystatus; {'Summarize:' upper(get(smobj,'userdata'))}];
    %mystatus = [mystatus; {'Count:' num2str(scount)}];
  end
else
  mystatus = [mystatus; {'Summarize:' 'N/A'}];
end

parsed = cell2str(mystatus,' ');
for i = 1:size(parsed,1);
  %Make dashed line contiguous because it prettier.
  parsed(i,:) = strrep(parsed(i,:), '- -', '---');
end
set(handles.status,'String',parsed,'value',[]);

%--------------------------------------------------------------------
function thisdata = update_data(handles,type)
%Set/Get classed or aligned dataset.

thisdata = [];
mydata = getappdata(handles.bspcgui,'data');
myanalysis = get(get(handles.analysis_panel,'SelectedObject'),'userdata');

bfopts = get_batchfold_options(handles);
if isempty(bfopts)
  return
end

switch type
  case 'aligned'
    bfopts.data_only = 2;
    bfopts.align_waitbar = 'on';
    try
      thisdata = batchfold(myanalysis,mydata,bfopts);
    catch
      myerr = lasterr;
      warndlg([{'Unable to align data with given settings, try changing Alignment Batch/Variable and or other settings.'} myerr],'Alignment Error')
    end
    setappdata(handles.bspcgui,'aligned_data',thisdata);
  case 'classed'
    bfopts.data_only = 1;
    %If a variable with lots of unique values is used as a source for batch
    %or step it can take a long time to construct a lookup table so change
    %cursor here so user has some indication.
    set(handles.bspcgui,'Pointer','watch');
    drawnow
    try
      thisdata = batchfold(myanalysis,mydata,bfopts);
    catch
      myerr = lasterr;
      warndlg([{'Unable to align data with given settings, try changing Batch/Variable and or other settings.'} myerr],'Alignment Error')
    end
    set(handles.bspcgui,'Pointer','arrow');
    setappdata(handles.bspcgui,'classed_data',thisdata);
end

%--------------------------------------------------------------------
function cdata = set_classed_dataset(handles)
%Set/Get classed data.

cdata = [];
mydata = getappdata(handles.bspcgui,'data');
myanalysis = get(get(handles.analysis_panel,'SelectedObject'),'userdata');

bfopts = get_batchfold_options(handles);
if isempty(bfopts)
  return
end


%--------------------------------------------------------------------
function adata = set_aligned_dataset(handles)
%Set/Get aligned data.

adata = [];
mydata = getappdata(handles.bspcgui,'data');
myanalysis = get(get(handles.analysis_panel,'SelectedObject'),'userdata');

bfopts = get_batchfold_options(handles);
if isempty(bfopts)
  return
end
bfopts.data_only = 1;
bfopts.align_waitbar = 'on';
try
  adata = batchfold(myanalysis,mydata,bfopts);
catch
  myerr = lasterr;
  warndlg([{'Unable to align data with given settings, try changing Alignment Batch/Variable and or other settings.'} myerr],'Alignment Error')
end

setappdata(handles.bspcgui,'aligned_data',adata);

%--------------------------------------------------------------------
function [fdata, mod] = get_folded_dataset(handles)
%Get DataSet with batch/step information parsed from GUI. New classes for
%Batch and Step are created even if using existing class.
fdata = [];
mod   = [];
mydata = getappdata(handles.bspcgui,'data');
if isempty(mydata)
  return
end
myanalysis = get(get(handles.analysis_panel,'SelectedObject'),'userdata');

bfopts = get_batchfold_options(handles);

[fdata, mod] = batchfold(myanalysis,mydata,bfopts);

%--------------------------------------------------------------------
function [cls_num, cls_nam] = get_selected_batches(handles)
%Get selected batches from Batch Selection list.

cls_num = [];
cls_nam = []; 
cls_lu_idx = [];

cdata = update_data(handles,'classed');

mybatch = get(handles.batch_list,'value');%Selected batches.
mystring = get(handles.batch_list,'string');%Batch string (cell array).
if ~iscell(mystring)
  mystring = str2cell(mystring);
end
mybidx  = get(handles.batch_list,'userdata');%Batch class set index.
if isempty(mybidx) | isempty(cdata) | isempty(cdata.classlookup{1,mybidx})% | ~get(handles.step_use,'value')
  return
end

thisbatchlu = cdata.classlookup{1,mybidx};
thisclass   = cdata.class{1,mybidx};
thisbatchlu = get_lookup(thisbatchlu,thisclass);

cls_num = [thisbatchlu{mybatch,1}];%Look up batch number.
cls_nam = thisbatchlu(mybatch,2);

%--------------------------------------------------------------------
function mylu = get_lookup(mylu,myclass)
%If there is a Class 0 and there aren't any members assigned to it then
%remove it from the table so list boxes don't look funny. Need to make sure
%list boxes account for missing value when selections are made.

if ~isempty(mylu)
  myz = [mylu{:,1}]==0;
  if any(myz) & ~any(myclass==0)
    mylu = mylu(~myz,:);
  end
end

%--------------------------------------------------------------------
function bfopts = get_batchfold_options(handles)
%Get options for batchfold.

%TODO: Rewrite this code to call batchfold and save alternative data for
%use elsewhere.

mydata = getappdata(handles.bspcgui,'data');
bfopts = [];
if isempty(mydata)
  return
end

myanalysis = get(get(handles.analysis_panel,'SelectedObject'),'userdata');

bfopts = batchfold('options');
batchclassset = [];

%Create batch/step class sets.
types = {'Batch' 'Step'};
for i = 1:2
  
  if ~get(handles.([lower(types{i}) '_use']),'value')
    %Not using so indicate with empty.
    bfopts.([lower(types{i}) '_source']) = '';
    bfopts.([lower(types{i}) '_set'])    = [];
    continue
  end
  
  obj = get(handles.([lower(types{i}) '_source_buttongroup']),'selectedobject');%Button handle.
  if isempty(obj)
    %If there's no attribute selected then don't try to make a class
    %otherwise it will error.
    continue
  end
  src = get(obj,'userdata');%Batch key word.
  myclassidx = get(handles.([lower(types{i}) '_source_list']),'value');%Selected batch.
  
  bfopts.([lower(types{i}) '_source']) = src;
  bfopts.([lower(types{i}) '_set'])    = myclassidx;
  
  %Get batch locate setting.
  if strcmpi(types{i},'batch')
    blocate = 'index';
    if (strcmpi(src,'axisscale') | strcmpi(src,'variable')) & get(handles.batch_source_gapchk,'value')
      blocate = 'gap';%Note: gap and backstep use same code so doesn't matter.
    end
    bfopts.batch_locate = blocate;
  end
  
  if strcmpi(types{i},'step')
    stepclassset = myclassidx;%Save set location for later use.
    
    if get(handles.step_use,'value')
      
      %Get step selection.
      stepselected = get(handles.step_list,'value');
      stepvals = get(handles.step_list,'string');
      %       if isempty(stepvals)
      %         errordlg('Unable to locate Step Indicator. Check step selection.','Step Error')
      %         return
      %       end
      if strcmp(src,'class') & ~isempty(stepvals)
        %If source is class then lookup the numeric class values.
        if ~iscell(stepvals)
          stepvals = str2cell(stepvals);
        end
        myvals = stepvals(stepselected)';
        stepLU = mydata.classlookup{1,stepclassset};
        stepselectidx = [];
        
        for j = myvals
          stepselectidx = [stepselectidx stepLU{ismember(stepLU(:,2),j{:}),1}];
        end
      else
        %No class to get class info from so index will be created in
        %batchfold and should be linear starting at 1.
        stepselectidx = stepselected;
      end
      
      if isempty(stepselectidx)
        %evrierrordlg('No Steps selected, make selection from Step Selection pain in Step tab.','No Steps Found');
      end
    else
      stepselectidx = [];
    end
    bfopts.step_selection_classes = stepselectidx;
  else
    batchclassset = myclassidx;%Save set location for later use.
  end
  
end

bfopts = get_batchalign_settings(handles,mydata,batchclassset,bfopts);

%Get summary settings.
myobjs = findobj(handles.summarize_button_panel,'value',1);
mysum = {};
for i = 1:length(myobjs)
  mysum = [mysum {get(myobjs(i),'userdata')}];
end
bfopts.summary = mysum;

%--------------------------------------------------------------------
function baopts = get_batchalign_settings(handles,mydata,batchclassset,baopts)
%Get settings for batch align from GUI.

%TODO: Check for tab enabled.
etabs = getappdata(handles.bspcgui,'enabled_tabs');
if ~any(etabs==4);
  return
end

%Get alignment settings.
obj = get(handles.align_buttongroup,'SelectedObject');

%Get alignemnt batch and variable.
mytarget = getappdata(handles.bspcgui,'targetdata');
if isempty(mytarget)
  myabat = get(handles.align_selectbatch_txt,'value');%Alignment batch.
  mystr  = get(handles.align_selectbatch_txt,'string');
  mystr  = str2cell(mystr);
  myvarbatch = mystr{myabat};
  if ~isempty(myabat) & ~isempty(batchclassset)
    if isempty(mydata.classlookup{1,batchclassset})
      %No class for batches yet (not using class as batch source) so since
      %class will be made from same source as align_selectbatch_txt, use
      %the value.
      baopts.alignment_batch_class = myabat;
    else
      %Get numeric class for index.
      batchLU = mydata.classlookup{1,batchclassset};
      mybatidx = ismember(batchLU(:,2),myvarbatch);
      if any(mybatidx)
        myabat = batchLU{mybatidx,1};
        baopts.alignment_batch_class = myabat;
      else
        baopts.alignment_batch_class = [];
      end
    end
  else
    %No batches yet.
    baopts.alignment_batch_class = [];
  end
else
  baopts.alignment_batch_target = mytarget;
end

myavar = get(handles.align_selectvariable_txt,'value');%Alignment variable.
if ~isempty(myavar)
  baopts.alignment_variable_index = myavar;
end

%Get alignment method settings.
if strcmp(get(obj,'userdata'),'nan')
  %If nan, no other settings  needed.
  baopts.batch_align_options.method = 'padwithnan';
elseif strcmp(get(obj,'userdata'),'none')
  baopts.batch_align_options.method = 'none';
else
  baopts.batch_align_options.savgolderiv = get(handles.align_derivorder_txt,'value');%Cow takes deriv order.
  if strcmp(get(obj,'userdata'),'cow')
    baopts.batch_align_options.method = 'cow';
    baopts.batch_align_options.cow.segments = str2num(get(handles.align_segments_txt,'string'));
    baopts.batch_align_options.cow.slack = str2num(get(handles.align_slack_txt,'string'));
  else
    baopts.batch_align_options.method = 'linear';
  end
end

%--------------------------------------------------------------------
function update_plots(handles)
%Update both plots.
update_top_plot(handles)
update_bottom_plot(handles)

%--------------------------------------------------------------------
function update_top_plot(handles)
%Update variable data plot.

%Get data.
mydata = getappdata(handles.bspcgui,'data');

%Update data plot.
if isempty(mydata)
  cla(handles.data_axes)
  cla(handles.magnify_display)
  set(handles.magnify_display,'tag','magnify_display')
else
  myval = get(handles.variable_list,'value');
  %Not sure what impact excluding data will have on plotting step location
  %so just mark as NaN for now.
  thisdata = nan(size(mydata.data));
  thisdata(mydata.include{1},mydata.include{2}) = mydata.data(mydata.include{1},mydata.include{2});
  
  if check_tab(handles,'align',0)
    %Display selected batches on top of each other.
    [batchclass, batchlu, batchname] = get_bach_class_info(handles,mydata);
    myclass = get_selected_batches(handles);
    if isempty(myclass)
      return
    end
    cla(handles.data_axes);
    hold(handles.data_axes,'on')
    for i = 1:length(myclass)
      %myclass(i)
      plot(thisdata(batchclass==myclass(i),myval),'parent',handles.data_axes);
    end
    hold(handles.data_axes,'off')
    axis(handles.data_axes,'tight')
  else
    %Plot all data.
    plot(thisdata(:,myval),'parent',handles.data_axes);
    axis(handles.data_axes,'tight')
  end
  %Tag can get lost so reassign.
  set(handles.data_axes,'tag','data_axes')
end

%--------------------------------------------------------------------
function update_bottom_plot(handles)
%Update batch data plot.

gopts = getappdata(handles.bspcgui,'gui_options');

%Get align setting.
isalign = check_tab(handles,'align',0);
if isalign
  ptype = 'align';
else
  if getappdata(handles.bspcgui,'step_selection')
    ptype = 'linear';
  else
    ptype = gopts.batch_plot_style;
  end
end

ctype = getappdata(handles.bspcgui,'current_batch_plot_style');

if isempty(ctype) | ~strcmp(ctype,ptype) | strcmp(ptype,'stack') | isalign
  %Clear the axis.
  cla(handles.magnify_display)
end

if strcmp(ptype,'align')
  mydata = getappdata(handles.bspcgui,'aligned_data');
else
  %mydata = getappdata(handles.bspcgui,'data');
  mydata = update_data(handles,'classed');%Get classed data.
end

%Apply include.
if isempty(mydata)
  thisdata = [];
else
  thisdata = nan(size(mydata.data));
  thisdata(mydata.include{1},mydata.include{2}) = mydata.data(mydata.include{1},mydata.include{2});
end

if isempty(mydata)
  return
else
  myval = get(handles.variable_list,'value');%Get column index.
end

%Get selected batches.
mybidx  = get(handles.batch_list,'userdata');%Batch class set index.

myclass = get_selected_batches(handles);
if isempty(myclass)
  return
end

if strcmp(ptype,'linear')
  %Make sure list selection is from min to max, must select contiguous.
  mybatch = get(handles.batch_list,'value');
  cntinslct = min(mybatch):max(mybatch);
  if length(cntinslct)>length(mybatch)
    set(handles.batch_list,'value',cntinslct);
  end
end

bclass = mydata.class{1,mybidx};%Selected batch boolean vector.
bclass = ismember(bclass,myclass);
if ~any(bclass)
  bdata = [];
else
  bdata = mydata(bclass,myval);%Single batch of data.
end

bclassidx = find(bclass);%Index of batch.
%Add one unit buffer on either side so you can see markers on the edge.
xmin = min(bclassidx)-1;
xmax = max(bclassidx)+1;

if isempty(bdata)
  cla(handles.magnify_display)
end
%Tag can get lost so reassign.
set(handles.magnify_display,'tag','magnify_display')

%Delete old batch patches here so they don't show up if changing to linear
%from stacked.
delete(findobj(handles.data_axes,'tag','batch_patch'));

%Add moveable patch on data plot for given batch.
mobj = getappdata(handles.bspcgui,'mtool');

%Add/update/remove magnify tool.
if ismember(ptype,{'align' 'stack'})
  %Remove magnify tool if viewing aligned data.
  if ~isempty(mobj)
    delete(mobj)
  end
else
  if isempty(mobj)
    mobj = magnifytool;
    mobj.display_delete = 0;
    mobj.show_menu = 0;
    mobj.position_checking = 0;
    mobj.show_resize = 0;
    mobj.patch_color = [.7 .7 .7];
    mobj.patch_alpha = .5;
    mobj.moveobj_constraint = 'x';
    mobj.target_axis = handles.data_axes;
    mobj.parent_figure = handles.bspcgui;
    mobj.display_axis = handles.magnify_display;
    mobj.buttonmotion_fcn = {@mtool_buttonup_fcn,handles.bspcgui,[],handles,'buttonmotion'};
    setappdata(handles.bspcgui,'mtool',mobj)
  end
  mobj.patch_color = [.6 .6 .6];
  mobj.patch_alpha = .6;
  %Get y lims and add to mobj.
  mylims      = get(handles.data_axes,'ylim');
  mobj.patch_ydata = [mylims(1) mylims(2) mylims(2) mylims(1) mylims(1)]';
  mobj.patch_xdata = [xmin xmin xmax xmax xmin]';
  %Update the magnify patch.
  mobj = updatepatch(mobj);
  
  if ~isempty(mobj.patch_handle) & ishandle(mobj.patch_handle)
    %Only set button up fcn if patch has been created.
    setappdata(mobj.patch_handle,'buttonupfcn','bspcgui(''mtool_buttonup_fcn'',gcbo,[],guidata(gcbf),''buttonup'')')
  else
    return
  end
  setappdata(handles.bspcgui,'mtool',mobj);
end

%Add step markers.
btn = get(handles.step_source_buttongroup,'selectedobject');
if ~isempty(btn)
  src = get(btn,'userdata');%Source of class (class, label, ...).
else
  src = [];
end
mystepval = get(handles.step_source_list,'value');

%Get batch class info.
[batchclass, batchlu, batchname] = get_bach_class_info(handles,mydata);

%If not class, then clear markers and return.
if ismember(ptype,{'align' 'stack'});
  mylims      = get(handles.data_axes,'ylim');%Get ylim for variable patch plot. 
  
  %Plot selected variable and batches on top of each other.
  hold(handles.magnify_display,'on')
  [alnbatchclass, junk, junk] = get_bach_class_info(handles,mydata);
  for i = 1:length(myclass)
    thisbatchdata = thisdata(alnbatchclass==myclass(i),myval);
    if ~isempty(thisbatchdata)
      h = plot(thisbatchdata,'parent',handles.magnify_display);
      %Set appdata so can display class via context menu.
      set(h,'UIContextMenu',getappdata(handles.bspcgui,'cmenu_batchplot'),'userdata',myclass(i));
      if ~isalign
        %Add patch indicators for batches in upper plot.
        myxlim(1) = min(find(alnbatchclass==myclass(i)));
        myxlim(2) = max(find(alnbatchclass==myclass(i)));
        mypatch = patch([myxlim(1) myxlim(1) myxlim(2) myxlim(2) myxlim(1)],[mylims(1) mylims(2) mylims(2) mylims(1) mylims(1)]',[.6 .6 .6],...
          'Parent',handles.data_axes,'tag','batch_patch');
        alpha(mypatch,.6);
        setappdata(mypatch,'buttonupfcn',{@batch_patch_buttonup_fcn})
        setappdata(mypatch,'line_obj',h);
        moveobj('x',mypatch)
      end
    end
  end
  hold(handles.magnify_display,'off')
  axis(handles.magnify_display,'tight')
  set(handles.magnify_display,'tag','magnify_display')
  
  %Get y lims and add to mobj.
  mylims      = get(handles.data_axes,'ylim');
  mobj.patch_ydata = [mylims(1) mylims(2) mylims(2) mylims(1) mylims(1)]';
  mobj.patch_xdata = [xmin xmin xmax xmax xmin]';
  
elseif isempty(mydata) | (isempty(btn) & ~getappdata(handles.bspcgui,'step_selection')) | isempty(mystepval)
  %Clear any step indicators.
  delete(findobj(handles.magnify_display,'tag','step_marker'));
else
  if ~get(handles.step_use,'value') & ~getappdata(handles.bspcgui,'step_selection')
    delete(findobj(handles.magnify_display,'tag','step_marker'));
    return
  end
  %Add horizonal line a the end of each step class for this batch.
  mylims      = axis(handles.magnify_display);
  
  if getappdata(handles.bspcgui,'step_selection')
    %In step selection mode so use temp structure.
    rinfo = getappdata(handles.bspcgui,'step_selection_info');
    
    %If this isn't current batch, disable 'add' button.
    if rinfo.refbatch_class~=myclass
      set(handles.addmarker,'enable','off');
    else
      set(handles.addmarker,'enable','on');
    end
    
    %Get ref batch index.
    batch_idx = find(batchclass==rinfo.refbatch_class);
    
    stepclass = rinfo.temporary_class;
    %Spoof step lookup table.
    stepclasslu = [num2cell(unique(rinfo.temporary_class)') str2cell(sprintf('Step %d\n',unique(rinfo.temporary_class)))];
    selected_steps = [];
  else
    batch_idx = [];
    stepclass   = mydata.class{1,mystepval};
    stepclasslu = mydata.classlookup{1,mystepval};
    stepclasslu = get_lookup(stepclasslu,stepclass);%Remove class 0 if we need to. 
    
    selected_steps = get(handles.step_list,'value');
  end
  
  if ~isempty(stepclass)
    hold(handles.magnify_display,'on')
    
    for i = 1:size(stepclasslu,1)
      if i == size(stepclasslu,1)
        %Change linespec of last position so can see end/begin of step
        %series.
        linespec = '-k';
        linesize = 1.5;
      elseif any(i==selected_steps)
        linespec = '-g';%Line format for step indicator.
        linesize = 1;
      else
        linespec = '-.r';%Line format for step indicator.
        linesize = 1;
      end
      
      thisclass = stepclasslu{i,1};
      lastpos   = find(diff(stepclass==thisclass));%Last positions of continuous class blocks.
      %Diff returns elements comapred to the right so beginning elements are
      %one off. Since we want only one location per step, just drop the wrong
      %index positions.
      lastpos   = lastpos(stepclass(lastpos)==thisclass)+1;%Add offset of 1.
      if ~isempty(lastpos)
        for j = 1:length(lastpos);
          if any(batch_idx(2:end)==lastpos(j))%Use 2:end so we don't get begin marker that's included with lastpos diff result.
            if ~isempty(rinfo.step_loc_index)
              mypos = [rinfo.step_loc_index.pos];
              mypos_j = mypos==lastpos(j);
              if any(mypos_j)
                myid  = rinfo.step_loc_index(mypos==lastpos(j)).id;
                lh = plot(handles.magnify_display,[lastpos(j) lastpos(j)],mylims(3:4),'-g','LineWidth',1.5,'tag','step_marker','userdata',myid);
                set(handles.magnify_display,'tag','magnify_display')
                moveobj('x',lh);
                setappdata(lh,'buttonupfcn',{@marker_buttonup})
              else
                %The step position is not being found for some reason. Don't
                %make this a fatal error when we're plotting but give
                %warning.
                evriwarndlg('Step position not located. Undo (remove) last step and try again.','Step Not Located')
              end
            end
          else
            lh  = plot(handles.magnify_display,[lastpos(j) lastpos(j)],mylims(3:end),linespec,'LineWidth',linesize,'tag','step_marker');
          end
          
        end
      end
    end
    hold(handles.magnify_display,'off')
  end
end

setappdata(handles.bspcgui,'current_batch_plot_style',ptype)

%-----------------------------------------------
function varargout = cmenu_batch_callback(h, eventdata, handles, varargin)
%Main context menu callback.

  % NOT USED

%-----------------------------------------------
function varargout = showinfo_callback(h, eventdata, handles, varargin)
%Display info about batch line.

myln = gco;%Get line being clicked on.

thisclass = get(myln,'UserData');

%Get correct data for plot.
isalign = check_tab(handles,'align',0);
if isalign
  mydata = getappdata(handles.bspcgui,'aligned_data');
else
  mydata = getappdata(handles.bspcgui,'classed_data');
end

%Batch info.
[batchclass, batchlu, batchname] = get_bach_class_info(handles,mydata);

bname = batchlu([batchlu{:,1}]==thisclass,2);

pos = get(gca,'currentPoint');
str = [bname{:}];% ' (' num2str(thisclass) ')'];
h = text(pos(1,1),pos(1,2),str);
setappdata(myln,'text_obj',h);
moveobj(h);

%--------------------------------------------------------------------
function plot_style_callback(h, eventdata, handles, varargin)
%Check for tab and update as needed.

gopts = getappdata(handles.bspcgui,'gui_options');
isalign = check_tab(handles,'align',0);

if isalign
  ptype = 'stack';
else
  ptype = gopts.batch_plot_style;
end

switch varargin{1}
  case 'main'
    %Check type.
    if strcmp(ptype,'linear')
      set(handles.batchplotlinear,'checked','on');
      set(handles.batchplotstack,'checked','off');
    else
      set(handles.batchplotlinear,'checked','off');
      set(handles.batchplotstack,'checked','on');
    end
    return
  case 'linear'
    gopts.batch_plot_style = 'linear';
  case 'stack'
    gopts.batch_plot_style = 'stack';
end

setappdata(handles.bspcgui,'gui_options',gopts)
update_bottom_plot(handles)

%-----------------------------------------------
function mycheck = check_tab(handles,tabname,idxpos)
%Check current tab. If idxpos=1 then return index of tab.

mycheck = false;

current_idx = gettabgroupindex(handles);

if isempty(tabname)
  tabname = '';
end

switch tabname
  case {'tab_start' 'start'}
    tab_idx = 1;
  case {'batch_locate' 'batch'}
    tab_idx = 2;
  case {'step_locate' 'step'}
    tab_idx = 3;
  case {'batch_align' 'align'}
    tab_idx = 4;
  case {'summarize' 'summary'}
    tab_idx = 5;
  case {'tab_finish' 'finish'}
    tab_idx = 6;
  otherwise
    tab_idx = [];
end

if idxpos
  mycheck = tab_idx;
elseif current_idx==tab_idx
  mycheck = true;
end

%--------------------------------------------------------------------
function tab_change_callback(varargin)
%Check for tab and update as needed.

handles = guihandles(varargin{3});

if ishandle(varargin{2}.OldValue)
  oldidx = check_tab(handles,get(varargin{2}.OldValue,'Tag'),1);
else
  oldidx = [];
end

if ishandle(varargin{2}.NewValue)
  newidx = check_tab(handles,get(varargin{2}.NewValue,'Tag'),1);
else
  newidx = [];
end

if isempty(oldidx) | isempty(newidx)
  return
end

%Have to manually set SelectedIndex here becuase this callback is called
%before property is updated.
if checkmlversion('<','8.4')
  set(handles.batchtabgroup,'SelectedIndex',newidx);
else
  %2014b fix. This relies on children being in same order as added to tab
  %group. 
  mychildren = get(handles.batchtabgroup,'Children');
  set(handles.batchtabgroup,'SelectedTab',mychildren(newidx));
end

if newidx~=oldidx & newidx==4 |oldidx==4
  %Move into or out of align tab so need to update plots.
  update_plots(handles)
end

%-----------------------------------------------
function propupdateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object.
%The myobj variable comes in with the following structure.
%
%   id       - unique id of object.
%   myobj    - shared data (object).
%   keyword  - keyword for what was updated (may be empty if nothing specified
%   userdata - additional data associated with the link by user

%-----------------------------------------------
function updateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object.
%The myobj variable comes in with the following structure.
%
%   id           - unique id of object.
%   object       - shared data (object).
%   properties   - structure of "properties" to associate with shared data.

if isempty(keyword); keyword = 'Modify'; end
handles = guihandles(h);

%Update everything
newdata = myobj.object;
setappdata(handles.bspcgui,'data',newdata);
update_callback(handles,'simple')

%--------------------------------------------------------------------
function set_SDO(handles)
%Set dataset.

%Set shareddata.
myobj = getshareddata(handles.bspcgui);
if ~isempty(myobj)
  %If somehow more than one object make sure use first.
  myobj = myobj{1};
end

mydata = getappdata(handles.bspcgui,'data');

if isempty(myobj)
  if~isempty(mydata)
    %Adding for the first time.
    myprops.itemType = 'bspcgui_data';
    myprops.itemIsCurrent = 1;
    myprops.itemReadOnly = 0;
    myid = setshareddata(handles.bspcgui,mydata,myprops);
    linkshareddata(myid,'add',handles.bspcgui,'bspcgui');
  else
    %Don't add an empty data object.
  end
else
  if ~isempty(mydata)
    %Update shareddata.
    setshareddata(myobj,mydata,'update');
  else
    %Set to empty = clear shareddata.
    removeshareddata(myobj,'standard');
  end
end

%--------------------------------------------------------------------
function varargout = gui_enable(fig)
%Initialize the the gui.

%Get handles and save options.
handles = guihandles(fig);
gopts = bspcgui('options');

%Set persistent options.
%fopts = analyzeparticles('options');
%fopts.display = 'off';
%Save options.
setappdata(fig,'gui_options',gopts);
setappdata(handles.bspcgui,'step_selection',0)
%setappdata(fig,'fcn_options',fopts);

%Get position.
figpos = get(fig,'position');
figcolor = [.92 .92 .92];
set(fig,'Color',figcolor,'Renderer',gopts.renderer);

%Add drag drop handler.
figdnd = evrijavaobjectedt(DropTargetList);%EVRI Custom drop target class.
figdnd = handle(figdnd,'CallbackProperties');
jFrame = get(handle(handles.bspcgui),'JavaFrame');
%Don't think we need to run on EDT but if the need arises be sure to
%accommodate 7.0.4.
jAxis  = jFrame.getAxisComponent;
jAxis.setDropTarget(figdnd);
set(figdnd,'DropCallback',{@dropCallbackFcn,handles.bspcgui});

myfontsize = gopts.fontsize;
if isempty(myfontsize)
  if ispc
    myfontsize = 10;
  else
    myfontsize = 12;
  end
end

%Set extra fig properties.
set(fig,'Toolbar','none')

%Add menu items.
hmenu = uimenu(fig,'Label','&File','tag','menu_file');

uimenu(hmenu,'tag','loaddatamenu','label','&Load Workspace Data','callback','bspcgui(''loaddata'',gcbo,[],guidata(gcbf),''load'')');
uimenu(hmenu,'tag','importdatamenu','label','&Import Data','callback','bspcgui(''loaddata'',gcbo,[],guidata(gcbf),''import'')');
uimenu(hmenu,'tag','loadmodelmenu','Separator','on','label','&Load Model','callback','bspcgui(''loadmodel'',gcbo,[],guidata(gcbf))');
uimenu(hmenu,'tag','savedatamenu','Separator','on','label','&Save Data','callback','bspcgui(''save_callback'',gcbo,[],guidata(gcbf),''data'')');
uimenu(hmenu,'tag','savemodelmenu','label','Save &Model','callback','bspcgui(''save_callback'',gcbo,[],guidata(gcbf),''model'')');

cmenu = uimenu(hmenu,'tag','clearmenu','Separator','on','label','&Clear');
uimenu(cmenu,'tag','cleardatamenu', 'label','&Data'         ,'callback','bspcgui(''clear_callback'',gcbo,[],guidata(gcbf),''data'')');
uimenu(cmenu,'tag','clearmodelmenu','label','&Model'        ,'callback','bspcgui(''clear_callback'',gcbo,[],guidata(gcbf),''model'')');
uimenu(cmenu,'tag','clearallmenu',  'label','&All'          ,'callback','bspcgui(''clear_callback'',gcbo,[],guidata(gcbf),''all'')','Separator','on');

uimenu(hmenu,'tag','closemenu','Separator','on','label','&Close','callback','bspcgui(''loaddata'',gcbo,[],guidata(gcbf),''import'')');

hmenu = uimenu(fig,'Label','&Edit','tag','menu_edit');
psmenu = uimenu(hmenu,'tag','batchplotstylemenu','label','&Batch Plot Style','callback','bspcgui(''plot_style_callback'',gcbo,[],guidata(gcbf),''main'')');
uimenu(psmenu,'tag','batchplotlinear','label','&Linear','callback','bspcgui(''plot_style_callback'',gcbo,[],guidata(gcbf),''linear'')');
uimenu(psmenu,'tag','batchplotstack','label','&Stacked','callback','bspcgui(''plot_style_callback'',gcbo,[],guidata(gcbf),''stack'')');

uimenu(hmenu,'tag','guioptionsmenu','label','&Interface Options','callback','bspcgui(''editoptions'',gcbo,[],guidata(gcbf),''gui'')');
%uimenu(hmenu,'tag','functionoptionsmenu','label','&Function Options','callback','bspcgui(''editoptions'',gcbo,[],guidata(gcbf),''function'')');

hmenu = uimenu(fig,'Label','&Help','tag','menu_help');
uimenu(hmenu,'tag','openhelpmenu','label','&Batch Processor Analysis Help','callback','bspcgui(''help_callback'',gcbo,[],guidata(gcbf))');

uimenu(hmenu,'tag','plshelp','label','&General Help','callback','helppls');

%Create context menu for batch plot line objects.
cm = uicontextmenu('parent',fig,'tag','cmenu_batchplot','callback','bspcgui(''cmenu_batch_callback'',gcbo,[],guidata(gcbf))');
showcm = uimenu(cm, 'Label', 'Show Info', 'Callback', 'bspcgui(''showinfo_callback'',gcbo,[],guidata(gcbf))');

setappdata(handles.bspcgui,'cmenu_batchplot',cm);

% %Set up resize bar with moveobj.
% panel_resizeh = uicontrol('parent', fig, ...
%   'style', 'pushbutton', ...
%   'units','pixels',...
%   'position', [100 200 4 4], ...
%   'cdata',zeros(5,5,3),...
%   'backgroundcolor',[1 1 1],...
%   'enable','inactive',...
%   'tag', 'panel_resize_button');
%
% setappdata(panel_resizeh,'minsize',[20 4]);
% moveobj('x',panel_resizeh);

%============== Data Vis Area ====================
dpanel = uipanel(fig,'tag','plot_panel',...
  'units','pixels',...
  'BackgroundColor',figcolor,...
  'title','',...
  'position',[220 100 220 100],...
  'fontsize',myfontsize);
%Variable label
uicontrol('parent', dpanel,...
  'tag', 'variable_lbl',...
  'style', 'text', ...
  'string', 'Variables:', ...
  'units','pixels',...
  'position',[4 200 100 20],...
  'fontsize',myfontsize,...
  'horizontalalignment','left',...
  'backgroundcolor',get(fig,'color'),...
  'tooltipstring','Current variables.');
%Variable select.
uicontrol('parent', dpanel,...
  'tag', 'variable_list',...
  'style', 'listbox', ...
  'string', '', ...
  'units', 'pixels', ...
  'position',[4 120 100 100],...
  'min',0,...
  'max',2,...
  'fontsize',myfontsize,...
  'horizontalalignment','left',...
  'backgroundcolor','white',...
  'tooltipstring','Select variable to plot.',...
  'callback','bspcgui(''variable_select_callback'',gcbo,[],guidata(gcbf))');
%Batch label
uicontrol('parent', dpanel,...
  'tag', 'batches_lbl',...
  'style', 'text', ...
  'string', 'Batches:', ...
  'units','pixels',...
  'position',[4 4 100 20],...
  'fontsize',myfontsize,...
  'horizontalalignment','left',...
  'backgroundcolor',get(fig,'color'),...
  'tooltipstring','Current batches.');
%Batch select.
uicontrol('parent', dpanel,...
  'tag', 'batch_list',...
  'style', 'listbox', ...
  'string', '', ...
  'units', 'pixels', ...
  'position',[4 4 100 100],...
  'min',0,...
  'max',2,...
  'fontsize',myfontsize,...
  'horizontalalignment','left',...
  'backgroundcolor','white',...
  'tooltipstring','Select batch to plot.',...
  'callback','bspcgui(''batch_select_callback'',gcbo,[],guidata(gcbf))');
%Data axes.
ax = axes('parent',dpanel,...
  'tag','data_axes',...
  'units','pixels',...
  'position',[120 110 200 100]);

%Batch axes.
ax = axes('parent',dpanel,...
  'tag','magnify_display',...
  'units','pixels',...
  'position',[120 4 200 100]);

%============== Tab Group ====================
tpanel = uipanel(fig,'tag','tab_panel',...
  'units','pixels',...
  'BackgroundColor',figcolor,...
  'title','',...
  'position',[220 100 220 100],...
  'fontsize',myfontsize);

mytg = uitabgroup('Parent',tpanel,...
  'tag','batchtabgroup',...
  'units','normalized',...
  'position',[0 0 1 1]);
if checkmlversion('<','8.4')
  set(mytg,'BackgroundColor',figcolor);
end

if checkmlversion('<','7.11') 
  set(mytg,'SelectionChangeFcn',{@tab_change_callback,handles.bspcgui});
elseif checkmlversion('>=','8.4')
  set(mytg,'SelectionChangedFcn',{@tab_change_callback,handles.bspcgui})
else
  set(mytg,'SelectionChangeCallback',{@tab_change_callback,handles.bspcgui});
end

%=========== Start Tab ===========
mytab = uitab('parent',mytg,...
  'title','Start',...
  'tag','tab_start');
setappdata(mytab,'tindex',1)

firstbtn = make_buttongroup(handles,'','',myfontsize,'Start',mytab);
%Data Panel
dpanel = uipanel(mytab,'tag','data_panel','units','pixels','BackgroundColor',figcolor,...
  'title','Data','position',[4 100 220 100],'fontsize',myfontsize);

%Data info, this must be a list box and not edit box or drag/drop will not work.
dsh = uicontrol('parent', dpanel,...
  'tag', 'data_status',...
  'style', 'list', ...
  'string', 'No Data Loaded', ...
  'units','normalized',...
  'position',[.01 .26 .98 .73],...
  'min',0,...
  'max',2,...
  'enable','inactive',...
  'value',[],...
  'fontsize',myfontsize,...
  'horizontalalignment','left',...
  'backgroundcolor','white',...
  'tooltipstring','Data information.');
%jAxis.setDropTarget(figdnd);

%Load
uicontrol('parent', dpanel,...
  'tag', 'data_load',...
  'style', 'pushbutton', ...
  'string', 'Load', ...
  'units','normalized',...
  'position',[.01 .01 .23 .24],...
  'fontsize',myfontsize,...
  'tooltipstring','Load data.',...
  'callback','bspcgui(''loaddata'',gcbo,[],guidata(gcbf),''load'')');
%Append
uicontrol('parent', dpanel,...
  'tag', 'data_append',...
  'style', 'pushbutton', ...
  'string', 'Append', ...
  'units','normalized',...
  'position',[.26 .01 .23 .24],...
  'fontsize',myfontsize,...
  'tooltipstring','Append data.',...
  'callback','bspcgui(''augment_data'',guidata(gcbf))');
%Edit
uicontrol('parent', dpanel,...
  'tag', 'data_edit',...
  'style', 'pushbutton', ...
  'string', 'Edit', ...
  'units','normalized',...
  'position',[.51 .01 .23 .24],...
  'fontsize',myfontsize,...
  'tooltipstring','Open data in DataSet Editor.',...
  'callback', 'bspcgui(''edit_callback'',gcbo,[],guidata(gcbf),''editds'')');
%Clear
uicontrol('parent', dpanel,...
  'tag', 'data_clear',...
  'style', 'pushbutton', ...
  'string', 'Clear', ...
  'units','normalized',...
  'position',[.76 .01 .23 .24],...
  'fontsize',myfontsize,...
  'tooltipstring','Clear data.',...
  'callback','bspcgui(''clear_callback'',gcbo,[],guidata(gcbf),''data'')');

%Analysis Panel
%Add button group.
bg = uibuttongroup('parent',mytab,...
  'tag','analysis_panel',...
  'Title','Analysis Type',...
  'BackgroundColor',get(fig,'color'),...
  'units','pixels',...
  'position',[4 200 220 152],...
  'fontsize',myfontsize,...
  'SelectionChangeFcn','bspcgui(''select_analysis_callback'',gcbo,[],guidata(gcbf))');
atypes = gopts.analysis_types;%Analysis types stored in options.
bt = 4;
for i = size(atypes,1):-1:1
  bh = uicontrol('style','radio',...
    'tag',['analysis_' atypes{i,1}],...
    'string',atypes{i,2},...
    'parent',bg,...
    'BackgroundColor',get(fig,'color'),...
    'fontsize',myfontsize,...
    'units','pixels',...
    'position',[4 bt 240 20],...
    'userdata',atypes{i,1});
  if i == 1
    firstbtn = bh;
  end
  bt = bt+22;
end

%Set default to first button (summary pca).
set(bg,'SelectedObject',firstbtn)

%=== Batch Tab ===
mytab = uitab('parent',mytg,...
  'title','Batches',...
  'tag','batch_locate');

setappdata(mytab,'tindex',2)

uicontrol('parent', mytab,...
  'tag', 'batch_use',...
  'style', 'checkbox', ...
  'value',1,...
  'string', 'Use Batches', ...
  'units', 'pixels', ...
  'position',[4 100 100 20],...
  'fontsize',myfontsize,...
  'tooltipstring','Indicate and identify batches in data.',...
  'callback','bspcgui(''use_callback'',gcbo,[],guidata(gcbf),''batch'')');

%Batch source.
bg = uibuttongroup('parent',mytab,...
  'tag','batch_source_buttongroup',...
  'Title','Batch Source',...
  'BackgroundColor',get(fig,'color'),...
  'units','pixels',...
  'position',[4 200 160 110],...
  'fontsize',myfontsize,...
  'SelectionChangeFcn','bspcgui(''update_batchsource_callback'',guidata(gcbf),''simple'')');
firstbtn = make_buttongroup(handles,{'class' 'Class'; 'label' 'Label' ;'variable' 'Variable';'axisscale' 'Axisscale'},bg,myfontsize,'Batch',mytab);
set(bg,'SelectedObject',[])

%=== Step Tab ===
mytab = uitab('parent',mytg,...
  'title','Steps',...
  'tag','step_locate');

setappdata(mytab,'tindex',3)

uicontrol('parent', mytab,...
  'tag', 'step_use',...
  'style', 'checkbox', ...
  'value',1,...
  'string', 'Use Steps', ...
  'units', 'pixels', ...
  'position',[4 100 100 20],...
  'fontsize',myfontsize,...
  'tooltipstring','Indicate and identify steps in data.',...
  'callback','bspcgui(''use_callback'',gcbo,[],guidata(gcbf),''step'')');

tpanel = uipanel(mytab,'tag','table_panel',...
  'units','pixels',...
  'BackgroundColor',get(handles.bspcgui,'color'),...
  'title','Step Selection ',...
  'position',[4 100 280 95],...
  'fontsize',myfontsize);

%Step selection listbox.

uicontrol('parent', tpanel,...
  'tag', 'step_list',...
  'style', 'listbox', ...
  'string', '', ...
  'units', 'normalized', ...
  'position',[.01 .01 .98 .98],...
  'min',0,...
  'max',2,...
  'fontsize',myfontsize,...
  'horizontalalignment','left',...
  'backgroundcolor','white',...
  'tooltipstring','Data information.',...
  'callback','bspcgui(''step_select_callback'',gcbo,[],guidata(gcbf))');

%Step source.
bg = uibuttongroup('parent',mytab,...
  'tag','step_source_buttongroup',...
  'Title','Step Source',...
  'BackgroundColor',get(fig,'color'),...
  'units','pixels',...
  'position',[4 200 160 110],...
  'fontsize',myfontsize,...
  'SelectionChangeFcn','bspcgui(''update_callback'',guidata(gcbf),''simple'')');
firstbtn = make_buttongroup(handles,{'class' 'Class'; 'label' 'Label' ;'variable' 'Variable';'axisscale' 'Axisscale'},bg,myfontsize,'Step',mytab);
set(bg,'SelectedObject',[]);

%=== Align Tab ===
mytab = uitab('parent',mytg,...
  'title','Align',...
  'tag','batch_align');

setappdata(mytab,'tindex',4)

%Align group.
bg = uibuttongroup('parent',mytab,...
  'tag','align_buttongroup',...
  'Title','Alignment Method',...
  'BackgroundColor',get(fig,'color'),...
  'units','pixels',...
  'position',[4 200 160 110],...
  'fontsize',myfontsize,...
  'SelectionChangeFcn','bspcgui(''update_alignment'',gcbo,[],guidata(gcbf))');
firstbtn = make_buttongroup(handles,{'none' 'None';'linear' 'Linear';'cow' 'COW'; 'nan' 'Pad With NaN'},bg,myfontsize,'Align',mytab);
uicontrol('parent', bg,...
  'tag', 'align_update',...
  'style', 'pushbutton', ...
  'string', 'Update Plot', ...
  'units', 'pixels', ...
  'position',[140 4 130 26],...
  'fontsize',myfontsize,...
  'tooltipstring','Update aligned data and plots.',...
  'callback','bspcgui(''update_alignment_data_callback'',guidata(gcbf))');

set(bg,'SelectedObject',firstbtn)

%Align batch/var selection.
apanel = uipanel(mytab,'tag','align_batchselect_panel',...
  'units','pixels',...
  'BackgroundColor',get(handles.bspcgui,'color'),...
  'title','Select Alignment Batch',...
  'position',[4 100 280 70],...
  'fontsize',myfontsize);
uicontrol('parent', apanel,...
  'tag', 'align_loadtarget_btn',...
  'style', 'pushbutton', ...
  'string', 'Load', ...
  'units', 'pixels', ...
  'position',[4 58 60 18],...
  'fontsize',myfontsize,...
  'BackgroundColor',get(fig,'color'),...
  'callback','bspcgui(''load_alignvec_callback'',gcbo,[],guidata(gcbf))',...
  'tooltipstring','Load target vector for alignment.');
uicontrol('parent', apanel,...
  'tag', 'align_cleartarget_btn',...
  'style', 'pushbutton', ...
  'string', 'Clear', ...
  'units', 'pixels', ...
  'position',[70 58 60 18],...
  'fontsize',myfontsize,...
  'BackgroundColor',get(fig,'color'),...
  'callback','bspcgui(''clear_alignvec_callback'',gcbo,[],guidata(gcbf))',...
  'tooltipstring','Clear target.');
uicontrol('parent', apanel,...
  'tag', 'align_showtarget_txt',...
  'style', 'edit', ...
  'string', '', ...
  'units', 'pixels', ...
  'position',[140 55 130 24],...
  'fontsize',myfontsize,...
  'BackgroundColor','white',...
  'tooltipstring','Currently loaded target vector.');
uicontrol('parent', apanel,...
  'tag', 'align_selectbatch_lbl',...
  'style', 'text', ...
  'string', 'Alignment Batch:', ...
  'units', 'pixels', ...
  'position',[4 28 130 24],...
  'fontsize',myfontsize,...
  'horizontalalignment','left',...
  'BackgroundColor',get(fig,'color'),...
  'tooltipstring','Select the batch to align other bathes to.');
uicontrol('parent', apanel,...
  'tag', 'align_selectbatch_txt',...
  'style', 'popup', ...
  'string', {''}, ...
  'units', 'pixels', ...
  'position',[140 28 130 24],...
  'enable','on',...
  'fontsize',myfontsize,...
  'backgroundcolor','white',...
  'tooltipstring','Select the batch to align other bathes to.',...
  'callback','bspcgui(''update_alignment'',gcbo,[],guidata(gcbf))');

uicontrol('parent', apanel,...
  'tag', 'align_selectvariable_lbl',...
  'style', 'text', ...
  'string', 'Alignment Variable:', ...
  'units', 'pixels', ...
  'position',[4 4 130 24],...
  'fontsize',myfontsize,...
  'horizontalalignment','left',...
  'BackgroundColor',get(fig,'color'),...
  'tooltipstring','Select the variable to align.');
uicontrol('parent', apanel,...
  'tag', 'align_selectvariable_txt',...
  'style', 'popup', ...
  'string', {''}, ...
  'units', 'pixels', ...
  'position',[140 4 130 24],...
  'enable','on',...
  'fontsize',myfontsize,...
  'backgroundcolor','white',...
  'tooltipstring','Select the variable to align.',...
  'callback','bspcgui(''update_alignment'',gcbo,[],guidata(gcbf))');

%Align settings.
spanel = uipanel(mytab,'tag','align_settings_panel',...
  'units','pixels',...
  'BackgroundColor',get(handles.bspcgui,'color'),...
  'title','Alignment Settings',...
  'position',[4 100 280 95],...
  'fontsize',myfontsize);
uicontrol('parent', spanel,...
  'tag', 'align_derivorder_lbl',...
  'style', 'text', ...
  'string', 'Derivative Order:', ...
  'units', 'pixels', ...
  'position',[4 52 130 24],...
  'fontsize',myfontsize,...
  'horizontalalignment','left',...
  'BackgroundColor',get(fig,'color'),...
  'tooltipstring','Order of derivative to take of target and ref_column before doing alignment (default = 0).',...
  'callback','bspcgui(''update_alignment'',gcbo,[],guidata(gcbf))');
uicontrol('parent', spanel,...
  'tag', 'align_derivorder_txt',...
  'style', 'popup', ...
  'string', {'None' '1st Order' '2nd Order' '3rd Order' '4th Order' '5th Order'}, ...
  'units', 'pixels', ...
  'position',[140 52 130 24],...
  'enable','off',...
  'fontsize',myfontsize,...
  'backgroundcolor','white',...
  'tooltipstring','Order of derivative to take of target and ref_column before doing alignment (default = 0).',...
  'callback','bspcgui(''update_alignment'',gcbo,[],guidata(gcbf))');
%Segments
uicontrol('parent', spanel,...
  'tag', 'align_segmets_lbl',...
  'style', 'text', ...
  'string', 'Segment Length:', ...
  'units', 'pixels', ...
  'position',[4 28 130 24],...
  'fontsize',myfontsize,...
  'horizontalalignment','left',...
  'BackgroundColor',get(fig,'color'),...
  'tooltipstring','Number of segments.',...
  'callback','bspcgui(''update_alignment'',gcbo,[],guidata(gcbf))');
uicontrol('parent', spanel,...
  'tag', 'align_segments_txt',...
  'style', 'edit', ...
  'string', '6', ...
  'units', 'pixels', ...
  'position',[140 28 130 24],...
  'enable','off',...
  'fontsize',myfontsize,...
  'backgroundcolor','white',...
  'tooltipstring','Number of segments.',...
  'callback','bspcgui(''update_alignment'',gcbo,[],guidata(gcbf))');
%Slack
uicontrol('parent', spanel,...
  'tag', 'align_slack_lbl',...
  'style', 'text', ...
  'string', 'Slack:', ...
  'units', 'pixels', ...
  'position',[4 4 130 24],...
  'fontsize',myfontsize,...
  'horizontalalignment','left',...
  'BackgroundColor',get(fig,'color'),...
  'tooltipstring','Maximum range or degree of warping in segment length.',...
  'callback','bspcgui(''update_alignment'',gcbo,[],guidata(gcbf))');
uicontrol('parent', spanel,...
  'tag', 'align_slack_txt',...
  'style', 'edit', ...
  'string', '2', ...
  'units', 'pixels', ...
  'position',[140 4 130 24],...
  'enable','off',...
  'fontsize',myfontsize,...
  'backgroundcolor','white',...
  'tooltipstring','Maximum range or degree of warping in segment length .',...
  'callback','bspcgui(''update_alignment'',gcbo,[],guidata(gcbf))');


%=== Summary Tab ===
mytab = uitab('parent',mytg,'title','Summarize','tag','summarize');

setappdata(mytab,'tindex',5)

%Step source.
bg = uipanel('parent',mytab,...
  'tag','summarize_button_panel',...
  'Title','Summary Statistics',...
  'BackgroundColor',get(fig,'color'),...
  'units','pixels',...
  'position',[4 200 160 110],...
  'fontsize',myfontsize);
statlist = {'mean' 'Mean';'std' 'Standard Deviation';'min' 'Minimum';...
  'max' 'Maximum';'range' 'Range';'slope' 'Slope';'skew' 'Skewness';...
  'kurtosis' 'Kurtosis'; 'length' 'Length (of step)';'percentile' 'Five-Number Summary'};

firstbtn = make_buttongroup(handles,statlist,bg,myfontsize,'Summarize',mytab);

%=========== Finish Tab ===========
mytab = uitab('parent',mytg,...
  'title','Finish',...
  'tag','tab_finish');

setappdata(mytab,'tindex',6)

firstbtn = make_buttongroup(handles,'','',myfontsize,'Finish',mytab);

%============== OK/Cancel Buttons ====================
%Send to analysis/cancel buttons.

%Send to analysis.
uicontrol('parent', mytab,...
  'tag', 'sentto_analysis',...
  'style', 'pushbutton', ...
  'string', 'Send to Analysis', ...
  'units', 'pixels', ...
  'position',[100 4 110 30],...
  'fontsize',myfontsize,...
  'tooltipstring','Export data to analysis interface.',...
  'callback','bspcgui(''send2analysis_callback'',gcbo,[],guidata(gcbf),''load'')');

%Save Dataset.
uicontrol('parent', mytab,...
  'tag', 'save_batch',...
  'style', 'pushbutton', ...
  'string', 'Save DataSet', ...
  'units', 'pixels', ...
  'position',[100 4 110 30],...
  'fontsize',myfontsize,...
  'tooltipstring','Export data to analysis interface.',...
  'callback','bspcgui(''save_callback'',gcbo,[],guidata(gcbf),''data'')');

%Save model.
uicontrol('parent', mytab,...
  'tag', 'save_model',...
  'style', 'pushbutton', ...
  'string', 'Save Model', ...
  'units', 'pixels', ...
  'position',[100 4 110 30],...
  'fontsize',myfontsize,...
  'tooltipstring','Save model file.',...
  'callback','bspcgui(''save_callback'',gcbo,[],guidata(gcbf),''model'')');

%Apply new.
uicontrol('parent', mytab,...
  'tag', 'apply_new',...
  'style', 'pushbutton', ...
  'string', 'Apply New Data', ...
  'units', 'pixels', ...
  'position',[100 4 110 30],...
  'fontsize',myfontsize,...
  'tooltipstring','Apply current model to new data.',...
  'callback','bspcgui(''apply_callback'',gcbo,[],guidata(gcbf),''model'')');

%Cancel
uicontrol('parent', mytab,...
  'tag', 'cancel',...
  'style', 'pushbutton', ...
  'string', 'Cancel', ...
  'units', 'pixels', ...
  'position',[206 4 110 30],...
  'fontsize',myfontsize,...
  'tooltipstring','Cance and close window.',...
  'callback','bspcgui(''closereq_callback'',gcbo,[],guidata(gcbf))');

%Add toolbar.
%TODO: Update toolbar button set.

btnlist = {
  'ok'            'savemarkers'   'bspcgui(''marker_callback'',guidata(gcbf),''ok'')'      'enable' 'Save step markers.'      'off' 'push'
  'close'         'cancelmarkers' 'bspcgui(''marker_callback'',guidata(gcbf),''cancel'')'  'enable' 'Cancel changes.'      'off' 'push'
  'options'       'markeroptions' 'bspcgui(''marker_callback'',guidata(gcbf),''options'')' 'enable' 'Changes options used to location markers.'       'on'  'push'
  'SetPureVarOne' 'addmarker'     'bspcgui(''marker_callback'',guidata(gcbf),''add'')'     'enable' 'Add step marker.'       'on'  'push'
  'ResetLastVar'  'removemarker'  'bspcgui(''marker_callback'',guidata(gcbf),''remove'')'  'enable' 'Remove last marker.'    'off' 'push'
  'trash'         'clearallmarkers' 'bspcgui(''marker_callback'',guidata(gcbf),''clear'')' 'enable' 'Remove all markers.'    'off' 'push'
  };


[htoolbar, hbtns] = toolbar(fig,'',btnlist,'bspc_step_toolbar');

set(htoolbar,'visible','off')

handles = guihandles(fig);
guidata(fig,handles);
resize_callback(fig);
select_analysis_callback(handles.analysis_spca,[],handles)

%--------------------------------------------------------------
function divider_callback(h,eventdata,handles,varargin)
%Add flag for divider drag. Flag is cleared in resize.

resize_callback(h,eventdata,handles,1)

%--------------------------------------------------------------
function firstbtn = make_buttongroup(handles,blist,myparent,myfontsize,myprefix,mytab)
%Make step/batch source controls.

myname = myprefix;%Title string.
myprefix = [lower(myname) '_source_'];%String to build tag.
firstbtn = [];

%Add div and next/prev buttons.
uicontrol('parent', mytab,...%Div line.
  'tag', 'divline',...
  'style', 'frame', ...
  'units', 'pixels', ...
  'position',[4 200 160 110]);

if ~strcmpi(myname,'finish')
  %Add next.
  uicontrol('parent', mytab,...
    'tag', 'nexttab',...
    'style', 'pushbutton', ...
    'string', 'Next >', ...
    'units', 'pixels', ...
    'position',[210 200 2 2],...
    'fontsize',myfontsize,...
    'ForegroundColor','blue',...
    'tooltipstring','Next tab.',...
    'callback','bspcgui(''select_analysis_callback'',gcbo,[],guidata(gcbf),''next'')');
end

if ~strcmpi(myname,'start')
  %Add prev.
  uicontrol('parent', mytab,...
    'tag', 'previoustab',...
    'style', 'pushbutton', ...
    'string', '< Previous', ...
    'units', 'pixels', ...
    'position',[210 200 2 2],...
    'fontsize',myfontsize,...
    'ForegroundColor','blue',...
    'tooltipstring','Previous tab.',...
    'callback','bspcgui(''select_analysis_callback'',gcbo,[],guidata(gcbf),''previous'')')
end

statuspanel = uipanel(mytab,'tag','status_panel',...
  'units','pixels',...
  'BackgroundColor',get(handles.bspcgui,'color'),...
  'title',['Status'],...
  'position',[4 100 220 100],...
  'fontsize',myfontsize);

uicontrol('parent', statuspanel,...
  'tag', 'status',...
  'style', 'list', ...
  'string', 'Data: No Data Loaded', ...
  'min',0,...
  'max',2,...
  'enable','inactive',...
  'units', 'normalized', ...
  'position',[.01 .01 .98 .98],...
  'fontsize',myfontsize,...
  'fontname','courier',...
  'horizontalalignment','left',...
  'backgroundcolor','white',...%get(handles.bspcgui,'color'),...
  'tooltipstring','Data information.');

bt = 4;%Bottom start position for check boxes/buttons

%Source panel for batch and step.
if ~ismember(lower(myname),{'align' 'summarize' 'start' 'finish'})
  %Seperator.
  uicontrol('parent', myparent,...
    'tag', [myprefix 'frameseparator'],...
    'style', 'frame', ...
    'units', 'pixels', ...
    'position',[4 35 272 1]);
  %Load btn.
  uicontrol('parent', myparent,...
    'tag', [myprefix 'loadbtn'],...
    'string','Load',...
    'style', 'pushbutton', ...
    'units', 'pixels', ...
    'position',[190 6 80 20],...
    'fontsize',myfontsize,...
    'tooltipstring','Select item.',...
    'callback',['bspcgui(''load_custom_callback'',gcbo,[],guidata(gcbf),''' lower(myname) ''')']);
  
  if strcmpi(myname,'Batch')
    %Select btn.
    uicontrol('parent', myparent,...
      'tag', [myprefix 'gapchk'],...
      'string','Use Gap/Backstep',...
      'style', 'checkbox', ...
      'units', 'pixels', ...
      'position',[44 6 150 20],...
      'fontsize',myfontsize,...
      'Enable','off',...
      'tooltipstring','How to use variable to define batches.',...
      'callback','bspcgui(''update_callback'',guidata(gcbf),''simple'')');
    
  else
    %Select btn.
    uicontrol('parent', myparent,...
      'tag', [myprefix 'selectbtn'],...
      'string','Select',...
      'style', 'pushbutton', ...
      'units', 'pixels', ...
      'position',[104 6 80 20],...
      'fontsize',myfontsize,...
      'tooltipstring','Graphically select step.',...
      'callback',['bspcgui(''select_custom_callback'',gcbo,[],guidata(gcbf),''' lower(myname) ''')']);
    
  end
  %Left column.
%**  %Disable make button for now because switched to using level 2 model that doesn't force the creation of class.
%  %Make class button.
%  uicontrol('parent', myparent,...
%     'tag', [myprefix 'makeclassbtn'],...
%     'string','Make Class',...
%     'style', 'pushbutton', ...
%     'enable','off',...
%     'units', 'pixels', ...
%     'position',[130 120 140 20],...
%     'fontsize',myfontsize,...
%     'tooltipstring','Make BSPC class from selected source.',...
%     'callback',['bspcgui(''makeclass_callback'',gcbo,[],guidata(gcbf),''' lower(myname) ''')']);
  %List.
  uicontrol('parent', myparent,...
    'tag', [myprefix 'list'],...
    'style', 'listbox', ...
    'units', 'pixels', ...
    'position',[130 48 140 94],...
    'fontsize',myfontsize,...
    'backgroundcolor','white',...
    'tooltipstring','Select specific item.',...
    'callback','bspcgui(''update_callback'',guidata(gcbf),''simple'')');
  bt = 50;
end

if isempty(blist)
  return
end

boxtype = 'radiobutton';
mycallback = '';
if strcmpi(myname,'summarize')
  boxtype = 'checkbox';
  mycallback = 'bspcgui(''update_status_callback'',guidata(gcbf))';
  bt = bt+30;%Put extra space at bottom of panel instead of top because it looks better. 
end

for i = size(blist,1):-1:1
  bh = uicontrol('style',boxtype,...
    'tag',[myprefix blist{i,1}],...
    'string',blist{i,2},...
    'parent',myparent,...
    'BackgroundColor',get(handles.bspcgui,'color'),...
    'fontsize',myfontsize,...
    'units','pixels',...
    'position',[4 bt 120 20],...%Make sure doesn't overlap onto list box.
    'Callback',mycallback,...
    'userdata',blist{i,1});
  if i == 1
    firstbtn = bh;
  end
  
  if ismember(blist{i,1},{'mean' 'std' 'slope'})
    %Set defaults for summary.
    set(bh,'value',1);
  end
  
  bt = bt+24;
end

%--------------------------------------------------------------
function resize_callback(h,eventdata,handles,varargin)
%Resize callback.

%Add drag divider line and resize behavior.

%Sometimes handles aren't updated so get them manually.
handles = guihandles(h);
set(handles.bspcgui,'units','pixels');%Make sure we're in pixels.

%Get initial positions.
figpos = get(handles.bspcgui,'position');
figpos(3) = max(figpos(3),520);%Make min width be 400.

% %Get divider position.
% rpos = get(handles.panel_resize_button,'position');
% if rpos(2)<10
%   %Don't let panel be less than 10 px from bottom.
%   rpos(2) = 10;
%   set(handles.panel_resize_button,'position',rpos)
% end
%
% %Set resizebars.
% rpos(1) = 1;
% rpos(3) = max(1,figpos(3)-2);
% set(handles.panel_resize_button,'position',rpos);

%Tab parent panel.
if checkmlversion('>=','8.4')
  tab_ht = 410;
else
  tab_ht = 390;  
end

main_wt = max(figpos(3)-8,600);
ppanel_ht  = max(200,figpos(4)-(tab_ht+10));%Remaining height for data plots with min of 200 px.
ppanel_btm = min(4,(figpos(4)-(tab_ht+4)-ppanel_ht-4));

curselmode = getappdata(handles.bspcgui,'step_selection');

if curselmode
  ppanel_btm = 4;%Bottom of plot panel should be at bottom of window.
  set(handles.tab_panel,'visible','off')
  set(handles.bspc_step_toolbar,'visible','on')
  ppanel_ht  = max(200,figpos(4)-10);%Remaining height for data plots with min of 200 px.
else
  set(handles.tab_panel,'visible','on')
  set(handles.bspc_step_toolbar,'visible','off')
  ppanel_ht  = max(200,figpos(4)-(tab_ht+10));%Remaining height for data plots with min of 200 px.
end

%Main panels.
set(handles.tab_panel,'position',[4 figpos(4)-(tab_ht+4) main_wt tab_ht])%Main tab group panel.
set(handles.plot_panel,'position',[4 ppanel_btm main_wt ppanel_ht]);%Data plot panel.

tgpos = get(handles.tab_panel,'position');%Get new tab_panel posisiton for use below.

if checkmlversion('>=','8.4')
  tgpos(4) = tgpos(4)-15;
end

%Start tab.
dpos = get(handles.data_panel,'position');
set(handles.data_panel,'position',[8 tgpos(4)-182 280 112]);%Data panel.
apos = get(handles.analysis_panel,'position');
set(handles.analysis_panel,'position',[8 tgpos(4)-360 280 174]);%Analysis type panel.

%Set tab control positions. Tabgroup is normalized inside tab panel so get
%panel pixel position, should be fine in relative distances.
set([handles.batch_use handles.step_use],'position',[88 tgpos(4)-60 100 20]);%Use checkbox.
set(findobj(handles.tab_panel,'tag','previoustab'),'position',[4 tgpos(4)-60 70 20]);%Previous tab.
set(findobj(handles.tab_panel,'tag','nexttab'),'position',[tgpos(3)-97 tgpos(4)-60 70 20]);%Next tab.
set(findobj(handles.tab_panel,'tag','divline'),'position',[4 tgpos(4)-66 tgpos(3)-18 1]);%Div line.

set(handles.status_panel,'position',[292 tgpos(4)-360 280 290]);

%set([handles.batch_source_status_panel handles.step_source_status_panel],'position',[8 tgpos(4)-170 280 100])%Batch/step status.
set([handles.batch_source_buttongroup handles.step_source_buttongroup],'position',[8 tgpos(4)-235 280 165])%Button group.

set(handles.table_panel,'position',[8 tgpos(4)-360 280 125]);%Step selection list.
% setcolumnwidth(mytbl,1,10)
% setcolumnwidth(mytbl,1,100)
%set([handles.batch_source_loadbtn handles.step_source_loadbtn],'position',[200 tgpos(4)-315 80 20]);%Load
%set([handles.batch_source_selectbtn handles.step_source_selectbtn],'position',[200 tgpos(4)-337 80 20]);%Select

%Make manual select batch button not visible since we don't do it.
%set(handles.batch_source_selectbtn,'visible','off')


%Align/summary control panels.
set([handles.align_buttongroup],'position',[8 tgpos(4)-160 280 90]);%Align group.
set([handles.align_batchselect_panel],'position',[8 tgpos(4)-260 280 95]);%Align group.
set([handles.align_settings_panel],'position',[8 tgpos(4)-360 280 95]);%Align settings.
set([handles.summarize_button_panel],'position',[8 tgpos(4)-360 280 290]);%Summary panel.

%Move alignment none to other side of button box.
set(handles.align_source_none,'position',[140 50 120 20])


%Up the width of buttons for longer names.
btns = findobj(handles.summarize_button_panel,'type','uicontrol');
for i = 1:length(btns)
  mypos = get(btns(i),'position');
  mypos(3) = 150;
  set(btns(i),'position',mypos);
end

%Finish page.
finish_status_panel = findobj(allchild(handles.tab_finish),'tag','status_panel');
fspos = get(finish_status_panel,'position');
fspos(1)=8;
button_bt = 390;%Button bottome.
set(finish_status_panel,'position',fspos);%Move status to left.
set(handles.sentto_analysis,'position',[8 tgpos(4)-button_bt 120 30]);%Send to analysis.
set(handles.save_batch,'position',[130 tgpos(4)-button_bt 120 30]);%Save.
set(handles.save_model,'position',[252 tgpos(4)-button_bt 120 30]);%Save model.
set(handles.apply_new,'position',[374 tgpos(4)-button_bt 120 30]);%Save model.
set(handles.cancel,'position',[496 tgpos(4)-button_bt 120 30]);%Cancel.

%Data plots/controls.
ppos = get(handles.plot_panel,'position');
ppos(4) = ppos(4);
bt = ppos(4)-30;%Floating bottom.
listw = 120;%List width.
dataw = ppos(3)-listw-60;%Data plot width.
listh = round(ppos(4)/2-46);%List height
set(handles.variable_lbl,'position',[4 bt listw 22])
bt = bt-listh;
set(handles.variable_list,'position',[4 bt listw listh])
set(handles.data_axes,'position',[listw+40 bt dataw listh]);
bt = bt-30;
set(handles.batches_lbl,'position',[4 bt listw 22])
bt = bt-listh;
set(handles.batch_list,'position',[4 bt listw listh])
set(handles.magnify_display,'position',[listw+40 bt dataw listh]);

%-----------------------------------------------------------------
function out = optiondefs()
defs = {
  %name                    tab              datatype        valid                            userlevel       description
  'renderer'               'Settings'      'select'        {'opengl' 'zbuffer' 'painters'}  'novice'        'Figure renderer (selection will affect alpha and performance).';
  
  };
out = makesubops(defs);

%-----------------------------------------------------------------
function out = maketestdso
%Make a dso for testing load logic.
load arch
%Make class the batch indicator.
arch.classname{1,3}='sdfds'
arch.classname{1,1}='BSPC Batch'

%Make a label the step indicator.
mynames = str2cell(arch.label{2,1});
mynames{2,1} = 'step';
arch.label{2,1} = mynames;
