function varargout = corrspecgui(varargin)
%CORRSPECGUI Interactive GUI to perform correlation spectroscopy.
% Can be called as stand alone or from analysis where upon data is passed
%  via shared data.
%
%I/O: corrspecgui() %Open gui.
%I/O: corrspecgui(xdata, ydata, model) %Open preloaded with data and or model.
%
%See also: CORRSPEC, EDITDS, PURITY

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%TODO: Add "update" button for apply.
%TODO: Create seperate axis colorbar then give handle to colorbar. Also,
%use 'peer',axishandle will pair to that axis.

%TODO: Move 3D plot button into toolbar.

%Programming Notes:
%Open gui from analysis with sharred data.
%Open from command line with raw data.

if nargin==0 || ~ischar(varargin{1}) % LAUNCH GUI
  try
    %Start GUI
    h=waitbar(1,['Starting ' upper(mfilename) '...']);
    drawnow
    %Open figure and initialize
    fig = openfig('corrspecgui.fig','new','invisible');
    positionmanager(fig,'corrspecgui');%Position gui from last known position.
    handles = guihandles(fig);	%structure of handles to pass to callbacks
    guidata(fig, handles);      %store it.
    set(fig,'units','pixels')
    %Get data if passed. Always load x then y.
    block = 'xblock';
    for i = 1:nargin
      myobj = varargin{i};
      if isshareddata(myobj)
        %Using shared data.
        setobjdata(myobj.properties.itemType,handles,myobj);
      elseif isa(myobj,'dataset');
        %Load stand alone dataset.
        setobjdata(block,handles,myobj);
        block = 'yblock';
      elseif isnumeric(myobj);
        %Load stand alone double array.
        setobjdata(block,handles,dataset(myobj));
        block = 'yblock';
      elseif isstruct(myobj)
        %Load model.
        setobjdata('model',handles,myobj);
      else
        %Try to load something.
        error('Input not recognized.')
      end
    end

    gui_init(fig)            %add additional fields
    figbrowser('addmenu',fig); %add figbrowser link
    set(fig,'visible','on')

    if nargout > 0
      varargout{1} = fig;
    end
    close(h);
  catch
    if ~isempty(gcbf);
      set(gcbf,'pointer','arrow');  %no "handles" exist here so try setting callback figure
    end
    if ishandle(h)
      close(h);
    end
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end
else % INVOKE NAMED SUBFUNCTION OR CALLBACK
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = [];
        options.tree_minwidth  = 220;
        options.tree_percentwidth = .1;
        options.spec_plot_size = .01; %Percentage of space used for spec plot.
        options.plot_type = 'mean';%std or data
        options.axis_type_spectra = 'continuous';%discrete or stick
        options.axis_type_contributions = 'discrete'; %discrete or stick
        options.false_color = 'off'; %on off
        options.z_origin = 'on'; %on off
        options.grid = 'off'; %on off
        options.color_map = 'hot';
        options.colorbar  = 'off';
        options.xdir = 'normal';
        options.ydir = 'normal';
        options.map3d = 'off';
        options.nlevel = 5; %Contour levels.
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
function varargout = gui_init(h)
%Initialize the the gui.

handles = guihandles(h);

opts = corrspecgui('options');
opts_corrspec = corrspec('options');

%Any time we recalc need to clear cursor.
clear_cursor_Callback(h, [], handles)

%Turn off recalc button.
setappdata(handles.corrspecgui,'recalc','off')

%Transfer corrspec options to gui.
opts.offset     = opts_corrspec.offset;
opts.inactivate = opts_corrspec.inactivate;
opts.dispersion = opts_corrspec.dispersion;
opts.max = opts_corrspec.max;

%Set presets.
setappdata(h,'gui_options',opts);

set(handles.nlevel,'String',num2str(opts.nlevel))

%Remove ticks, lines, and labels. Also for z for when/if we go 3D in future.
cleanplots(handles,[handles.xspec handles.yspec handles.corrmap]);

%Add toolbar.
[htoolbar, hbtns] = toolbar(handles.corrspecgui, 'corrspec');

add_tree(handles);

%Set callbacks.
set(h,'resizefcn','corrspecgui(''resize_callback'',gcbf,[],guidata(gcbf))')
set(h,'CloseRequestFcn','corrspecgui(''closereq_callback'',gcbf,[],guidata(gcbf))');

%Set offset values.
set(handles.xoffset,'String',num2str(opts.offset(1)))
if length(opts.offset)>1
  set(handles.yoffset,'String',num2str(opts.offset(2)))
else
  set(handles.yoffset,'String',num2str(opts.offset(1)))
end

%Get last figure position (stored previously).
positionmanager(h,'corrspecgui')

%Use try here because we want it to get to resize before it fails on a
%calculation so the gui doesn't look funny.
try
  %Not sure if data is loaded so try calculating a model.
  calculate_Callback(h,[],handles)
end

%Call resize.
resize_callback(h,[],handles)

%Add callback for mouse motion.
set(handles.corrspecgui,'WindowButtonMotionFcn',{@mousemotion_Callback,handles})

%Add callback for click on corrmap axis.
set(handles.corrmap,'ButtonDownFcn',{@corrmapclick_Callback,handles})

%Save flag for persistent varialbe in mouse motion callback. Need this for
%speed.
setappdata(handles.corrspecgui,'data_has_changed',1)

%--------------------------------------------------------------------
function add_tree(handles,resizeme)
%Add tree, use resize to issue resize command.

if nargin<2
  resizeme = false;
end

%Check for existing tree.
mytree = getappdata(handles.corrspecgui,'corrspecguitree');

if ~isempty(mytree) & mytree.isvalid
  %Make sure it's visible.
  set(mytree,'visible','on');
else
  sstree = evritree('parent_figure',handles.corrspecgui,'tag','corrspecguitree','visible','on',...
    'units','pixels','position',[1 1 1 1],'tree_data',getcontrolsnode(handles),...
    'selection_type','discontiguous','tree_clicked_callback',@tree_callback,... %'tree_nodeexpand_callback', {@tree_callback,handles},...
    'root_visible','off','root_icon','');
end

if resizeme
  resize_callback(handles.corrspecgui,[],handles)
end

%--------------------------------------------------------------------
function calculate_Callback(h,eventdata,handles,varargin)
%Calculate map.

x = getobjdata('xblock',handles);
y = getobjdata('yblock',handles);

if isempty(x) || isempty(y)
  return
end

opts = getappdata(handles.corrspecgui,'gui_options');

%Clear and indicate recalc.
cla(handles.corrmap)
th = text('parent',handles.corrmap,'units','normalized','position',[.4,.6,.5],'String','Calculating Model...','FontSize',14,'tag','recalc_warning');
drawnow
try

  %Add plot options to merged option structure.
  opts.plots_maps='off';
  opts.plots_spectra='off';

  %Offset.
  if isempty(get(handles.xoffset,'string'))
    xoff = 0;
  else
    xoff = str2num(get(handles.xoffset,'string'));
  end

  if isempty(get(handles.yoffset,'string'))
    yoff = 0;
  else
    yoff = str2num(get(handles.yoffset,'string'));
  end
  opts.offset = [xoff yoff];

  %Pure variables.
  purvars = getappdata(handles.corrspecgui,'pure_var_index');

  %Create model.
  model=corrspec(x,y,purvars,opts);
  setobjdata('model',handles,model);

  delete(th);

  %Update plots and resize.
  update_corrmap(handles)
  resize_callback(handles.corrspecgui,[],handles)

catch
  if ishandle(th)
    delete(th);
  end
  error(['Error while trying to calculate corrspec model : ' lasterr]);
end

%--------------------------------------------------------------------
function update_corrmap(handles,myax,matrix)
%Update corrmap plot. Plot changes are done here and within tree_callback
%based on options. Input 'myax' is only used when recreating plot for
%resolved plots.

if nargin<2
  myax = handles.corrmap;
end

%Need to reassign tag after plotting
mytag = get(myax,'tag');

%Clear cursor.
clear_cursor_Callback(handles.corrspecgui, [], handles)

set(handles.corrspecgui,'renderer','zbuffer');

x = getobjdata('xblock',handles);
y = getobjdata('yblock',handles);
model = getobjdata('model',handles);
if isempty(model) || isempty(x) || isempty(y)
  %Need all 3 to create a map.
  cla(myax)
  return
end

opts = getappdata(handles.corrspecgui,'gui_options');

if nargin<3
  matrix=model.detail.matrix{1};
  matrix=matrix{2};
end

%Zero origin.
if strcmp(opts.z_origin,'on');
  matrix(matrix<0)=0;
end;

nlevel = opts.nlevel;

if strcmp(opts.false_color,'on');
  %surf(myax,x.axisscale{2},y.axisscale{2},matrix);%WW
  surf(myax,x.axisscale{2}(x.include{2}),y.axisscale{2}(y.include{2}),matrix);
  shading(myax,'interp');
  hold(myax,'on');
  %contour3(myax,x.axisscale{2},y.axisscale{2},matrix,nlevel,'k');
  contour3(myax,x.axisscale{2}(x.include{2}),y.axisscale{2}(y.include{2}),matrix,nlevel,'k');
else
  %contour3(myax,x.axisscale{2},y.axisscale{2},matrix,nlevel);%whole matrix
  contour3(myax,x.axisscale{2}(x.include{2}),y.axisscale{2}(y.include{2}),matrix,nlevel);%WW
end
axis(myax,'tight')

%Grid
grid(myax,opts.grid);

%Colormap
colormap(myax,[opts.color_map '(64)']);

%Set look.
set(myax,'YAxisLocation','right','xdir',opts.xdir,'ydir',opts.ydir);

hold(myax,'off');

%axis(myax,[sort([x.axisscale{2}(1) x.axisscale{2}(end)]) sort([y.axisscale{2}(1) y.axisscale{2}(end)])]);
a=x.axisscale{2}(x.include{2});%WW
b=y.axisscale{2}(y.include{2});%WW
axis(myax,[sort([a(1) a(end)]) sort([b(1) b(end)])]);%WW

if strcmp(opts.map3d,'off')
  %Turned off.
  view(myax,2);
  rotate3d(myax,'off')
else
  %Turned on.
  view(myax,3);
  rotate3d(myax,'on')
end

set(myax,'tag',mytag);

%Update activation mask.
update_patches(handles);

%set(handles.corrmap,'ButtonDownFcn',{@corrmapclick_Callback,handles})
if strcmpi(mytag,'corrmap')
  set(allchild(handles.corrmap),'ButtonDownFcn',{@corrmapclick_Callback,handles});
end
%--------------------------------------------------------------------
function update_patches(handles)
%Add patch to axes to indicate inactivation map.

%Get mask.
plist = getappdata(handles.corrspecgui,'patch_list');
delete(findobj(handles.corrspecgui,'tag','corrmap_patch'))
if isempty(plist)
  return
end

grey = .9;

for i = 1:length(plist)
  xp = [plist(i).xmin plist(i).xmax plist(i).xmax plist(i).xmin];
  yp = [plist(i).ymax plist(i).ymax plist(i).ymin plist(i).ymin];
  patch(xp,yp,[grey grey grey],'parent',handles.corrmap,'tag','corrmap_patch','EdgeColor','none');

  if strcmp(plist(i).atype,'x')
    lm = get(handles.xspec,'ylim');
    yp = [max(lm) max(lm) min(lm) min(lm)];
    patch(xp,yp,[grey grey grey],'parent',handles.xspec,'tag','corrmap_patch','EdgeColor','none');
  else
    lm = get(handles.yspec,'xlim');
    xp = [min(lm) max(lm) max(lm) min(lm)];
    patch(xp,yp,[grey grey grey],'parent',handles.yspec,'tag','corrmap_patch','EdgeColor','none');
  end
end

%--------------------------------------------------------------------
function loaddata(h,eventdata,handles,varargin)
%Load spectra data or model. varargin{1} should be item name, xblock yblock
%or model.

if nargin<4
  error('Need to provide item type to loaddata function.')
else
  if ismember(varargin{1},{'xblock' 'yblock' 'model'})
    myitem = varargin{1};
    if length(varargin)==2
      rawdata = varargin{2};
    else
      rawdata = [];
    end
  else
    return
  end
end

%Refer to data/model object by the axis tag name.
mydata = getobjdata(myitem,handles);

%Check for existing data.
if ~isempty(mydata)
  if strcmp(myitem,'model')
    button = evriquestdlg('There is an existing model. Do you wish to clear and overwrite?',...
      'Continue Load','Yes','No','Yes');
  else
    button = evriquestdlg('There is existing data. Do you wish to clear and overwrite?',...
      'Continue Load','Yes','No','Yes');
  end
  if strcmp(button,'No')
    return
  end
end

%Load data.
if isempty(rawdata)
  if strcmp(myitem,'model')
    [rawdata,name,location,rdir] = lddlgpls('struct','Select Model');
  else
    [rawdata,name,location,rdir] = lddlgpls({'double' 'dataset'},'Select Data');
  end
end

if isempty(rawdata)
  %User cancel.
  return
end

%Convert to DSO
%if ~isdataset(rawdata)
if ~isdataset(rawdata)&~strcmp(myitem,'model');
  rawdata = dataset(rawdata);
end

%Check for empty and add axis scale if needed.
if ~strcmp(myitem,'model')
  if isempty(rawdata.data)
    erdlgpls('Variable empty. Data not loaded.','Error on Load.')
    rawdata = [];
    return
  end
  if isempty(rawdata.axisscale{1})
    rawdata.axisscale{1} = [1:size(rawdata.data,1)];
  end

  if isempty(rawdata.axisscale{2})
    rawdata.axisscale{2} = [1:size(rawdata.data,2)];
  end
elseif strcmp(myitem,'model')
  %Store options.
  mopts = rawdata.detail.options;
  setappdata(handles.corrspecgui,'gui_options',mopts);
  set(handles.xoffset,'string',num2str(mopts.offset(1)));
  set(handles.yoffset,'string',num2str(mopts.offset(2)));
  setappdata(handles.corrspecgui,'pure_var_index',rawdata.detail.purvarindex)
end

%Add and update.
setobjdata(myitem,handles,rawdata,getdataprops);
update_spectra(handles)
calculate_Callback(handles.corrspecgui,[],handles)

%--------------------------------------------------------------------
function savemodel_Callback(h,eventdata,handles,varargin)
%Save model.

model = getobjdata('model',handles);
if isempty(model)
  return
end

targname = defaultmodelname(model,'variable','save');

[what,where] = svdlgpls(model,'Save Model',targname);

%--------------------------------------------------------------------
function clear_Callback(h,eventdata,handles,varargin)

if nargin<4
  error('Need to provide item type to loaddata function.')
else
  myitem = varargin{1};
end

setobjdata(myitem,handles,[]);

%Clear pure vars and deactivated areas.
setappdata(handles.corrspecgui,'pure_var_index',[]);
set(handles.purevariables,'String','');
setappdata(handles.corrspecgui,'patch_list',[]);

update_corrmap(handles)
update_spectra(handles)%Calls update patches.
calculate_Callback(handles.corrspecgui,[],handles)
%--------------------------------------------------------------------
function copyfig_Callback(h,eventdata,handles,varargin)
%Export figure to clipboard.

if ispc
  hgexport(handles.corrspecgui,'-clipboard');
else
  try
    editmenufcn(handles.corrspecgui,'EditCopyFigure');
  end
end
%[filename, pathname, filterindex] = evriuiputfile('*.bmp', 'Save File As', file);

%--------------------------------------------------------------------
function plotcontextmenu_callback(h,eventdata,handles,varargin)
%Context menu for callbacks.

%--------------------------------------------------------------------
function update(handles,key)
switch key
  case 'plots'
    update_spectra(handles)
end

%--------------------------------------------------------------------
function update_spectra(handles)
%Update plots.
opts = getappdata(handles.corrspecgui,'gui_options');
x = getobjdata('xblock',handles);
y = getobjdata('yblock',handles);

%Pull data out so mean/std won't error if x/y empty dastsets.
xdat = [];
ydat = [];

if ~isempty(x)
  xdat = x.data;
end

if ~isempty(y)
  ydat = y.data;
end

%Run plot command.
if ~isempty(x)
  %Get plottype data.
  switch opts.plot_type
    case 'mean'
      %xtype = mean(xdat);
      xtype = mean(xdat(x.include{1},x.include{2}));;%WW
    case 'std'
      xtype = std(xdat(x.include{1},x.include{2}));%WW
    case 'data'
      xtype = xdat(x.include{1},x.include{2});%WW
  end
  %plot(handles.xspec,x.axisscale{2},xtype,getaxistype(opts.axis_type_spectra));%WW
  plot(handles.xspec,x.axisscale{2}(x.include{2}),xtype,getaxistype(opts.axis_type_spectra));
  set(handles.xspec,'xdir',opts.xdir,'tag','xspec')
  axis(handles.xspec,'tight');
else
  cla(handles.xspec);
end

if ~isempty(y)
  %Get plottype data.
  switch opts.plot_type
    %     case 'mean'
    %       ytype = mean(ydat);%WW
    %     case 'std'
    %       ytype = std(ydat);
    %     case 'data'
    %       ytype = ydat;
    case 'mean'
      %xtype = mean(xdat);
      ytype = mean(ydat(y.include{1},y.include{2}));%WW
    case 'std'
      ytype = std(ydat(y.include{1},y.include{2}));%WW
    case 'data'
      ytype = ydat(y.include{1},y.include{2});%WW
  end
  plot(handles.yspec,ytype,y.axisscale{2}(y.include{2}),getaxistype(opts.axis_type_spectra));
  set(handles.yspec,'xdir','reverse','ydir',opts.ydir,'tag','yspec')
  axis(handles.yspec,'tight');
else
  cla(handles.yspec);
end

%Add patches if needed.
update_patches(handles)

%Remove ticks, lines, and labels. Also for z for when/if we go 3D in future.
cleanplots(handles,[handles.xspec handles.yspec])

%--------------------------------------------------------------------
function cleanplots(handles,hh)
%Remove all lables and ticks from plots. Input 'hh' is vector of handles.

set(hh,'XTickLabel','','YTickLabel','','ZTickLabel','','XTick',[],'YTick',[],'ZTick',[],'XColor','white','YColor','white','ZColor','white')

%--------------------------------------------------------------------
function settings_Callback(h,eventdata,handles,varargin)
%Toggle tree on and off.

mytree = getappdata(handles.corrspecgui,'corrspecguitree');
myvis = mytree.visible;

if strcmpi(myvis,'on')
  set(mytree,'visible','off');
else
  set(mytree,'visible','on');
end


%--------------------------------------------------------------------
function resize_callback(h,eventdata,handles,varargin)
%Resize based on panel visible and axes status.

%Clear cursor.
clear_cursor_Callback(handles.corrspecgui, [], handles)
drawnow

%Clear mouse motion flag so cursors will update when mouse is motion over
%plot. This is just a fail-safe for if cursor motion app data gets stuck
%for some reason.
setappdata(handles.corrspecgui,'updateing_mousemotion_plot',0)

set(handles.corrspecgui,'units','pixels');
figpos = get(handles.corrspecgui,'position');
opts = getappdata(handles.corrspecgui,'gui_options');

%Plots and controls are left aligned with tree taking remaining space to
%right.

%These controls just move up and down the same distance.
static_ctrls = {'purevariables_label' 'purevariables' 'nlevel_label' 'nlevel' 'xoffset_label' ...
  'xoffset' 'yoffset_label' 'yoffset'};

%Height of controls removed from figpos.
if ismac
  cheight = 22;
else
  cheight = 18;
end
myheight = figpos(4)-cheight;
tleft = 7;%80;
for i = 1:length(static_ctrls)
  mypos = get(handles.(static_ctrls{i}),'position');
  mypos(2) = myheight;
  mypos(1) = tleft;
  mypos(4) = cheight;
  set(handles.(static_ctrls{i}),'position',mypos)
  tleft = tleft+mypos(3)+2;
end

if ismac
  set([handles.xpos handles.ypos],'Fontsize',8);
  posht = 20;
else
  posht = 18;
end

%These position controls move to specific upper-left corner.
set(handles.position_label,'position',[11 myheight-19 53 15])
set(handles.xpos_label,'position',[7 myheight-40 12 18])
set(handles.xpos,'position',[21 myheight-38 56 posht])
set(handles.ypos_label,'position',[7 myheight-59 12 18])
set(handles.ypos,'position',[21 myheight-57 56 posht])
%set(handles.purevariables_label,'position',[7 myheight-71 50 18])
%set(handles.purevariables,'position',[59 myheight-71 24 18])

if strcmp(getappdata(handles.corrspecgui,'recalc'),'on')
  set(handles.recalc,'units','pixels','position',[7 myheight-80 70 25],'visible','on')
else
  set(handles.recalc,'units','pixels','position',[7 myheight-80 70 25],'visible','off')
end

%There is a minimum for spec plot size to accomodate the position controls.
spec_plot_min = 70; %Pixels.
main_plot_min = 70*(1-opts.spec_plot_size );
pspace = 7;%Pixel spacing between plots.
mybottom = 20;

%Find min dimension for plots, can only plot with equal ratio.
min_dim = min([figpos(3) myheight]) - ((2*pspace)+mybottom);% 2 spacers plus bottom gutter.

spec_plot_sz = max([(opts.spec_plot_size * min_dim) spec_plot_min]);

main_plot_sz = max([(min_dim - spec_plot_sz) main_plot_min]);

myleft = (pspace+spec_plot_sz+pspace);

set(handles.yspec,'position',[pspace mybottom spec_plot_sz main_plot_sz]);
set(handles.xspec,'position',[myleft (main_plot_sz+pspace+mybottom) main_plot_sz spec_plot_sz]);

cmap_pos = [myleft mybottom main_plot_sz main_plot_sz];
set(handles.corrmap,'position',cmap_pos);

myleft = myleft+main_plot_sz+30;

%Color bar.
delete(findobj(handles.corrspecgui,'tag','Colorbar'))

if strcmp(opts.colorbar,'on')
  %Use default tag name for colorbar "Colorbar" becuase colormap resets tag
  %name when it runs.
  cbpos = [myleft mybottom 30 main_plot_sz];
  %set(ch,'units','pixels','position',[myleft mybottom 30 main_plot_sz],'tag','Colorbar','YAxisLocation','right')
  myleft = myleft + 60;
  %I think using the peer command causes colorbar to resize corrmap axis so
  %reposition it again.
  set(handles.corrmap,'position',cmap_pos);
  
  ch = colorbar('peer',handles.corrmap);
  %Use default tag name for colorbar "Colorbar" becuase colormap resets tag
  %name when it runs.
  set(ch,'units','pixels','tag','Colorbar','YAxisLocation','right')
  if checkmlversion('<','8.4')
    %Positioning done different in 2014b so only reposition colobar in older version.
    set(ch,'position',cbpos)
    %I think using the peer command causes colorbar to resize corrmap axis so
    %reposition it again.
    set(handles.corrmap,'position',cmap_pos);
  end
end

%Depending on how a particular system renders the controls and on size of
%plot, max left may change.
myleft = max(myleft,tleft)+10;

%Sizing should be relative. Width of cache viewer should expand at options
%settings for left over space.
cvh = getappdata(handles.corrspecgui,'treeparent');
treecontainer = getappdata(handles.corrspecgui,'treecontainer');
mytree = getappdata(handles.corrspecgui,'corrspecguitree');

if mytree.isvalid & strcmpi(mytree.visible,'on')
  %set(cvh,'Units','Pixels');
  tree_pos = get(mytree,'position');

  %Tree should get tree_percentwidth of leftover from figwidth - .tree_minwidth.
  %fig_leftoverwidth = figpos(3)-opts.tree_minwidth;
  %tree_spacew = floor(opts.tree_percentwidth*fig_leftoverwidth);

  %Not using minheight
  tree_spaceh = myheight;

  %Left
  mvpos(1) = myleft;
  %Bottom
  mvpos(2) = 2;
  %Width.
  mvpos(3) = max(opts.tree_minwidth, figpos(3)-myleft);
  %Height
  mvpos(4) = figpos(4)-4;
  %Set the position.
  set(mytree,'position',mvpos);
else
  %Tree not displaying, error out.
  mvpos = [0 0 0 0];
end

update_spectra(handles)

%--------------------------------------------------------------------
function closereq_callback(h,eventdata,handles,varargin)
%Save figure position.
positionmanager(handles.corrspecgui,'corrspecgui','set')
if ishandle(handles.corrspecgui)
  delete(handles.corrspecgui)
end

% --------------------------------------------------------------------
function [myid,myitem] = loaditem(myobj)
% %Load shareddata object based on name property.
% data = myobj.object;
% %%%%%%%%% STOPPED HERE
% if ~isa(data,'dataset')
%   error('Unable to edit supplied object');
% end
% linkshareddata(myid,'add',fig,'editds');
% myname = myid.properties.name;
% setdataset(fig,myid);
% --------------------------------------------------------------------
function [myid,myitem] = getobj(item,handles)
%Get current item, 'myid' is sourceID.

myitem = item;%Legacy code from Analysis, just return item.

if ~isstruct(handles)
  handles = guidata(handles);
end

%Get a list of objects for given item type.
myitems = getappdata(handles.corrspecgui,'linkeddata');
myid = [];
for i = 1:length(myitems)
  if strcmpi(myitems(i).properties.itemType,myitem)
    myid = myitems(i);
  end
end

if length(myid)>1
  error(['There appears to be more than one current ' myitem ' registered to the GUI.']);
elseif isempty(myid)
  myid = [];
elseif length(myid)>1
  myid = myid{1};
end

% --------------------------------------------------------------------
function out = isloaded(item,handles)
%Determine if item is currently loaded.

if ~isstruct(handles)
  handles = guidata(handles);
end

out = ~isempty(getobjdata(item,handles));

% --------------------------------------------------------------------
function out = getobjdata(item,handles)
%Get a data object.
%  Inputs:
%    item       - is the type of object (e.g., "xspec" or "yspec").
%    handles    - handles structure or figure handle.

if ~isstruct(handles)
  handles = guidata(handles);
end

myid = getobj(item,handles);

out = getshareddata(myid);

% --------------------------------------------------------------------
function myid = setobjdata(item,handles,obj,myprops,userdata)
%Update or add a data object to the figure.
%  Inputs:
%    item    - is the type of object (e.g., "xblock" or "yblock").
%    handles - handles structure.
%    obj     - data object (e.g., DSO, model, or prediction) OR linkID
%  OPTIONAL INPUTS:
%    myprops  - properties to set with the object
%    userdata - userdata to set with the link in analysis

%If adding for first time (i.e., there's no data for current "item" then
%set the currentitem flag for that item). NOTE: this functionality is not
%currently in use but should allow for multiple versions of the same "item"
%to be loaded at one time.
%
% Use the following properties to define behavior.
%   itemType      - How the item is assigned in the gui (e.g., "xblock" or
%                   "model", etc).
%   itemIsCurrent - (boolean) if there are multiple items of the same type loaded,
%                   which item is currently being used (has focus).
%   itemReadOnly  - (boolean) can the current item be modified.

if ~isstruct(handles)
  handles = guidata(handles);
end

[myid myitem] = getobj(item,handles);

if nargin<4
  myprops = [];
end
if nargin<5;
  userdata = [];
end

%Check for axisscale.
if (strcmpi(item,'xblock')||strcmpi(item,'yblock')) && ~isempty(obj)
  if ~isdataset(obj)
    obj = dataset(obj);
  end
  if isempty(obj.axisscale{2,1})
    obj.axisscale{2,1} = [1:size(obj,2)];
  end

end

if isempty(myid)
  if~isempty(obj) && ~isshareddata(obj)
    %Adding for the first time.
    myprops.itemType = myitem;
    myprops.itemIsCurrent = 1;
    myprops.itemReadOnly = 0;
    myid = setshareddata(handles.corrspecgui,obj,myprops);
    linkshareddata(myid,'add',handles.corrspecgui,'corrspecgui');
  elseif isshareddata(obj)
    %Link to shareddata first time.
    linkshareddata(obj,'add',handles.corrspecgui,'corrspecgui');
  else
    %Don't add an empty data object.
  end
else
  if ~isempty(obj)
    %Update shareddata.
    if ~isempty(myprops)
      %update properties (quietly - without propogating callbacks)
      updatepropshareddata(myid,'update',myprops,'quiet')
    end
    setshareddata(myid,obj);
  else
    %Set to empty = clear shareddata.
    removeshareddata(myid,'standard');
  end
end

% --------------------------------------------------------------------
function dataprops = getdataprops
%define data callback properties

dataprops = [];
dataprops.datachangecallback = 'datachangecallback(myobj.id)';
dataprops.includechangecallback = 'dataincludechange(myobj.id)';

%-----------------------------------------------
function updateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object.
%The myobj variable comes in with the following structure.
%
%   id           - unique id of object.
%   object       - shared data (object).
%   properties   - structure of "properties" to associate with shared data.

if isempty(keyword); keyword = 'Modify'; end

if isshareddata(h)

  %connection link
  if strcmp(keyword,'delete') & isfield(userdata,'isdependent') & userdata.isdependent
    removeshareddata(h);
  end

elseif ishandle(h)

  %subscriber link
  cb = '';
  switch char(keyword)

    case {'class' 'include' 'axisscale'}

      if isempty(cb) & isfield(myobj.properties,'datachangecallback')
        cb = myobj.properties.datachangecallback;
      end

    case 'delete'

    otherwise
      if isfield(myobj.properties,'datachangecallback')
        cb = myobj.properties.datachangecallback;
      end

  end
  if ~isempty(cb)
    try
      eval(cb);
    catch
      disp(encode(lasterror))
      uiwait(errordlg(sprintf('Error executing callback for keyword ''%s'' on object ''%s''',keyword,myobj.properties.itemType),'Callback Error'));
    end
  end

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

if nargin<4;
  userdata = [];
end

id = myobj.id;
if ~isempty(keyword)
  switch keyword
    case {'selection'}
      %Selection updated

      myobj.properties.selection = plotgui('validateselection',myobj.properties.selection,myobj.object);

      if ishandle(h)  %'subscriber'
        %call related to analysis' link to this object (subscriber)

        %In the future, we may put "callback" actions here

      else  %'connection'
        %call related to linking to another object (connection)
        try
          last_timestamp = searchshareddata(h,'getval','timestamp');
        catch
          %any error in finding object, just skip it
          return
        end
        timestamp      = myobj.properties.timestamp;
        if last_timestamp~=timestamp
          %figure out what kind of selection mapping we need
          if ~isfield(userdata,'linkmap')
            if ~isstruct(userdata)
              userdata = [];
            end
            userdata.linkmap = ':';
          end
          newselection = myobj.properties.selection;
          if ~isnumeric(userdata.linkmap)
            %not numeric? pass entire selection as is
            myselection = newselection;
          else
            %matrix mapping mode to mode, pass only those modes
            myselection = h.properties.selection;
            oldselection = myselection;
            myselection(1,userdata.linkmap(:,1)) = newselection(userdata.linkmap(:,2));
            if comparevars(oldselection,myselection)
              %no change actually made? skip!
              return
            end
          end

          %create properties structure and update connection
          props = [];
          props.selection = myselection;
          props.timestamp = timestamp;
          updatepropshareddata(h,'update',props,'selection')
        end
      end
  end
end




% --------------------------------------------------------------------
function varargout = dataincludechange(id)
%Input h is the handle of the figure.
%Need to clear transferred data if orginal data is changed.
handles = guidata(id.source);


% --------------------------------------------------------------------
function varargout = datachangecallback(id)
%Input h is the handle of the figure.
%Need to clear transferred data if orginal data is changed.
handles = guidata(id.source);
setappdata(handles.corrspecgui,'data_has changed',1)
disp('data change')

%--------------------------------------------------------------------
function map3d_Callback(hObject, eventdata, handles)
%Turn 3d on/off.
opts = getappdata(handles.corrspecgui,'gui_options');

if strcmp(opts.map3d,'on')
  %Turn off.
  view(handles.corrmap,2);
  opts.map3d = 'off';
  rotate3d(handles.corrmap,'off')
else
  %Turn on.
  view(handles.corrmap,3);
  opts.map3d = 'on';
  rotate3d(handles.corrmap,'on')
end
setappdata(handles.corrspecgui,'gui_options',opts)

%--------------------------------------------------------------------
function plotcursor_Callback(hObject, eventdata, handles)
%Plot at cursor.
opts = getappdata(handles.corrspecgui,'gui_options');
xdata = getobjdata('xblock',handles);
ydata = getobjdata('yblock',handles);

cidx = getappdata(handles.corrspecgui,'cursor_pos');

if isempty(cidx)
  %error('Need to set cursor position.')
  return
end

%get common include for rows
[x_include1_common,y_include1_common] = corrspecutilities('get_include_common',xdata,ydata);

xidx = cidx(1);
xvar2plot = xdata.data(x_include1_common,xidx);%WW

yidx = cidx(2);
yvar2plot = ydata.data(y_include1_common,yidx);%WW

f = figure('Name','Cursor Variable Plot');
tg = uitabgroup_o('v0','parent',f);

t1 = uitab_o('v0', tg, 'title', 'Cursor Variable Plots');
subplot(2,2,1,'parent',t1);
plot(xdata.axisscale{1}(x_include1_common),xvar2plot,'*');%WW
axis tight
hline('k');
%title(['X Variable: ' num2str(xdata.axisscale{2}(cidx(1)))])%WW
a=xdata.axisscale{2}(xdata.include{2});
title(['X Variable: ' num2str(a(cidx(1)))])
axis tight

subplot(2,2,2,'parent',t1);
plot(ydata.axisscale{1}(y_include1_common),yvar2plot,'*');
axis tight
hline('k');
b=ydata.axisscale{2}(ydata.include{2});
title(['Y Variable: ' num2str(b(cidx(2)))])
axis tight

subplot(2,2,3,'parent',t1);
plot(xvar2plot,yvar2plot,'*');
title('X-Variable versus Y-Variable');
c=corrcoef(xvar2plot,yvar2plot);
xlabel(['corr: ',num2str(c(2),2)]);
axis square
axis tight

model = getobjdata('model',handles);

if isempty(model)
  return
end

matrix = model.detail.matrix{1};
matrix2plot = matrix{2};

t2 = uitab_o('v0', tg, 'title', 'Cursor Spectrum Plots');

ax = subplot(2,1,1,'parent',t2);
plot(ax,xdata.axisscale{2}(xdata.include{2}),matrix2plot(yidx,:));%WW
hline('k');
hold on;
a=xdata.axisscale{2}(xdata.include{2});
plot(ax,a(xidx),matrix2plot(yidx,xidx),'r*');
hold off;
set(ax,'xdir',opts.xdir);
title('X Spectrum @ Cursor')

ax = subplot(2,1,2,'parent',t2);
plot(ax,ydata.axisscale{2}(ydata.include{2}),matrix2plot(:,xidx));
hline('k');
hold on;
b=ydata.axisscale{2}(ydata.include{2});
plot(ax,b(yidx),matrix2plot(yidx,xidx),'r*');
hold off;
set(ax,'xdir',opts.ydir);
title('Y Spectrum @ Cursor')

%--------------------------------------------------------------------
function cursor_Callback(hObject, eventdata, handles)
%Allow user to place cursor.
%TEST FOR CHANGING CURSOR POSITION

x = getobjdata('xblock',handles);
y = getobjdata('yblock',handles);
model = getobjdata('model',handles);

if isempty(model)
  return
end

matrix = model.detail.matrix{1};
matrix2plot = matrix{2};
matrix_max = matrix{3};

axes(handles.corrmap);
%Add drawnow before and after because crosshairs were not showing up in
%some situations.
% drawnow
% [x_pos,y_pos]=ginput(1);
%drawnow

%Cursor disappears when callinig ginput. Now double click sets a cursor.
C = get (gca, 'CurrentPoint');
x_pos=C(1);
y_pos=C(3);

%CHANGE TO NEW CURSOR POSITION
%x_pos=findindx(x.axisscale{2},x_pos);%WW
%y_pos=findindx(y.axisscale{2},y_pos);%WW
x_pos=findindx(x.axisscale{2}(x.include{2}),x_pos);
y_pos=findindx(y.axisscale{2}(y.include{2}),y_pos);

%set_cursor_corrmap(handles.corrspecgui,[x_pos,y_pos],matrix2plot,x.axisscale{2},y.axisscale{2});%WW
set_cursor_corrmap(handles.corrspecgui,[x_pos,y_pos],matrix2plot,...
  x.axisscale{2}(x.include{2}),y.axisscale{2}(y.include{2}));%WW

%--------------------------------------------------------------------
function max_Callback(hObject, eventdata, handles)
%Put a cursor on the max, click on - click off functionality.

x = getobjdata('xblock',handles);
y = getobjdata('yblock',handles);
model = getobjdata('model',handles);

if isempty(model)
  return
end

matrix = model.detail.matrix{1};
matrix2plot = matrix{2};
matrix_max = matrix{3};
%SET AXES TO CORRMAP

imap = get_imap(handles);
imap(imap==1)=-inf;
imap(imap==0)=1;
matrix_max=matrix_max.*imap;
%Take care of any negative values that became inf.
matrix_max(isinf(matrix_max))=-inf;

m = max(max(matrix_max));
[r,c] = find(matrix_max==m);
purvar_index2 = [c(1) r(1)];

set_cursor_corrmap(handles.corrspecgui,purvar_index2,matrix2plot,...
  x.axisscale{2}(x.include{2}),y.axisscale{2}(y.include{2}));%WW

%--------------------------------------------------------------------
function imap = get_imap(handles)
%Get inactivate map.

%Get existing patches.
plist = getappdata(handles.corrspecgui,'patch_list');

x = getobjdata('xblock',handles);
y = getobjdata('yblock',handles);

%ax = x.axisscale{2};
%ay = y.axisscale{2};
ax = x.axisscale{2}(x.include{2});
ay = y.axisscale{2}(y.include{2});

imap = zeros(length(ay),length(ax));

if isempty(plist)
  return
end

%Map patch verticies to a logical array.
for i = 1:length(plist)
  if strcmp(plist(i).atype,'x')
    x1 = findindx(ax,plist(i).xmax);
    x2 = findindx(ax,plist(i).xmin);
    if x1>x2
      imap(:,x2:x1)=1;
    else
      imap(:,x1:x2)=1;
    end
  else
    y1 = findindx(ay,plist(i).ymax);
    y2 = findindx(ay,plist(i).ymin);
    if y1>y2
      imap(y2:y1,:)=1;
    else
      imap(y1:y2,:)=1;
    end
  end
end

%--------------------------------------------------------------------
function set_cursor_corrmap(fh,index_cursor,matrix2plot,x_axisscale2,y_axisscale2)

%SET AXES TO CORRMAP
%Refresh handles.
handles = guihandles(fh);

%GET RID OF OLD CURSOR
clear_cursor_Callback(fh, [], handles)

%MAKE CROSSHAIR CURSOR WITH HLINE VLINE
index_cursor=round(index_cursor);

set(handles.xpos,'string',sprintf('%0.2f',x_axisscale2(index_cursor(1))));
set(handles.ypos,'string',sprintf('%0.2f',y_axisscale2(index_cursor(2))));
%Save position to appdata.
setappdata(handles.corrspecgui,'cursor_pos',index_cursor);

%SET CURSOR IN CORRMAP
axes(handles.corrmap);
pause(.1)
h = vline(x_axisscale2(index_cursor(1)),'k');
set(h,'zdata',repmat(matrix2plot(index_cursor(2),index_cursor(1)),1,2));
set(h,'EraseMode','xor','tag','vline_corrmap');

h = hline(y_axisscale2(index_cursor(2)),'k');
pause(.1)
set(h,'zdata',repmat(matrix2plot(index_cursor(2),index_cursor(1)),1,2));
set(h,'EraseMode','xor','tag','hline_corrmap');

%SET CURSOR IN SPEC
axes(handles.xspec);
h = vline(x_axisscale2(index_cursor(1)),'k');
set(h,'EraseMode','xor','tag','line_xspec');

axes(handles.yspec);
h = hline(y_axisscale2(index_cursor(2)),'k');
set(h,'EraseMode','xor','tag','line_yspec');

set(handles.corrmap,'ButtonDownFcn',{@corrmapclick_Callback,handles})
set(allchild(handles.corrmap),'ButtonDownFcn',{@corrmapclick_Callback,handles});

%--------------------------------------------------------------------
function clear_cursor_Callback(hObject, eventdata, handles)
%Remove lines and clear appdata.

%GET RID OF OLD CURSOR
mylines = {'line_yspec' 'line_xspec' 'vline_corrmap' 'hline_corrmap'};
for i = 1:length(mylines)
  h = findobj(handles.corrspecgui,'tag',mylines{i});
  if ~isempty(h)
    delete(h)
  end
end

set(handles.xpos,'string','')
set(handles.ypos,'string','')

setappdata(handles.corrspecgui,'cursor_pos',[]);

%--------------------------------------------------------------------
function setone_Callback(hObject, eventdata, handles)
%Set a pure variable. Take the cursor_pos appdata and call corrspec with
%it.

%Get existing index.
vidx = getappdata(handles.corrspecgui,'pure_var_index');

cpos = getappdata(handles.corrspecgui,'cursor_pos');
if isempty(cpos)
  return;
end

%Add current position.
vidx = [vidx; cpos];
%Store it.
setappdata(handles.corrspecgui,'pure_var_index',vidx);
%Update pure var number.
set(handles.purevariables,'String',num2str(size(vidx,1)));
%Recalc model and plot.
calculate_Callback(handles.corrspecgui,[],handles)
%Find new max.
max_Callback(handles.corrspecgui,[],handles)

%--------------------------------------------------------------------
function reset_Callback(hObject, eventdata, handles)
%Pull off one pure variable from the index.

%Get existing index.
vidx = getappdata(handles.corrspecgui,'pure_var_index');
if isempty(vidx)
  return
end

%Remove last element.
vidx(end,:)=[];
%Store it.
setappdata(handles.corrspecgui,'pure_var_index',vidx);
%Update pure var number.
set(handles.purevariables,'String',num2str(size(vidx,1)));
%Recalc model and plot.
calculate_Callback(handles.corrspecgui,[],handles)
%Find old max.
max_Callback(handles.corrspecgui,[],handles)

%--------------------------------------------------------------------
function inactivatex_Callback(hObject, eventdata, handles, mypts)
%Inactivate x values. Input mypts are x and y verticies.

if nargin<4||isempty(mypts)
  %Get verticies.
  opts.helpbox = 'off';
  [xpts,ypts] = gselect('xs',handles.xspec,opts);
else
  xpts = mypts;
end

%Get limits.
ylm = get(handles.corrmap,'ylim');

%Get existing patches.
plist = getappdata(handles.corrspecgui,'patch_list');

%Add new record.
plist(end+1).atype = 'x';
plist(end).xmin    = min(xpts);
plist(end).xmax    = max(xpts);
plist(end).ymin    = min(ylm);
plist(end).ymax    = max(ylm);

%Save it.
setappdata(handles.corrspecgui,'patch_list',plist);

%Plot it.
update_patches(handles)

%--------------------------------------------------------------------
function inactivatey_Callback(hObject, eventdata, handles, mypts)
%Inactivate y values.

if nargin<4||isempty(mypts)
  %Get verticies.
  opts.helpbox = 'off';
  [xpts, ypts] = gselect('ys',handles.xspec,opts);
else
  ypts = mypts;
end

%Get limits.
xlm = get(handles.corrmap,'xlim');

%Get existing patches.
plist = getappdata(handles.corrspecgui,'patch_list');

%Add new record.
plist(end+1).atype = 'y';
plist(end).xmin    = min(xlm);
plist(end).xmax    = max(xlm);
plist(end).ymin    = min(ypts);
plist(end).ymax    = max(ypts);

%Save it.
setappdata(handles.corrspecgui,'patch_list',plist);

%Plot it.
update_patches(handles)

%--------------------------------------------------------------------
function inactivatexy_Callback(hObject, eventdata, handles)
%Inactivate xy values.
opts.helpbox = 'off';
[xpts,ypts] = gselect('rbbox',handles.xspec,opts);

inactivatex_Callback(hObject, eventdata, handles, xpts)
inactivatey_Callback(hObject, eventdata, handles, ypts)

%--------------------------------------------------------------------
function reactivate_Callback(hObject, eventdata, handles, mypts)
%Clear patches.

plist = getappdata(handles.corrspecgui,'patch_list');
plist = plist(1:end-1);
setappdata(handles.corrspecgui,'patch_list',plist);

%Plot it.
update_patches(handles)

%--------------------------------------------------------------------
function resolve_Callback(hObject, eventdata, handles)
%Click resolve button.

opts = getappdata(handles.corrspecgui,'gui_options');
x = getobjdata('xblock',handles);
y = getobjdata('yblock',handles);
model = getobjdata('model',handles);

numvars = size(model.detail.purvarindex,1);

if isempty(x) || isempty(y) || isempty(model) || numvars==0
  return
end

%calculate common axisscale1 for x and y;WW
[x_include1_common,y_include1_common] = corrspecutilities('get_include_common',x,y);

m = ceil(sqrt(numvars));
n = ceil(sqrt(numvars));

f = figure('Name','Resolved Plots');
tg = uitabgroup_o('v0','parent',f);%,'tag','resolve_tg');
set(tg,'tag','resolve_tg');
t2 = uitab_o('v0', tg, 'title', 'X Spec');

for i=1:numvars;
  ax = subplot(m,n,i,'tag',['xspec_var_' num2str(i)],'parent',t2);
  %plot(ax,x.axisscale{2},model.loads{2,1}(i,:));
  plot(ax,x.axisscale{2}(x.include{2}),model.loads{2,1}(i,:));%WW
  axis tight
  hline('k')
  title(['Resolved X # ',num2str(i)]);
  %axis tight
  set(ax,'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));','xdir',opts.xdir)
end

t3 = uitab_o('v0', tg, 'title', 'X Con');

for i=1:numvars;
  ax = subplot(m,n,i,'tag',['xspec_var_' num2str(i)],'parent',t3);
  %plot(ax,x.axisscale{1},model.loads{1,1}(:,i),'*');
  plot(ax,x.axisscale{1}(x_include1_common),model.loads{1,1}(:,i),'*');
 axis tight;axis(axis+[-eps +eps -eps +eps]*10);
  hline('k')
  title(['Resolved X # ',num2str(i)]);
  %axis tight
  set(ax,'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));')
end

t4 = uitab_o('v0', tg, 'title', 'Y Spec');

for i=1:numvars;
  ax = subplot(m,n,i,'tag',['xspec_var_' num2str(i)],'parent',t4);
  %plot(ax,y.axisscale{2},model.loads{2,2}(i,:));
  plot(ax,y.axisscale{2}(y.include{2}),model.loads{2,2}(i,:));%WW
  axis tight
  hline('k')
  title(['Resolved Y # ',num2str(i)]);
  %axis tight
  set(ax,'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));','xdir',opts.ydir)
end

t5 = uitab_o('v0', tg, 'title', 'Y Con');

for i=1:numvars;
  ax = subplot(m,n,i,'tag',['xspec_var_' num2str(i)],'parent',t5);
  %plot(ax,y.axisscale{1},model.loads{1,2}(:,i),'*');
  plot(ax,y.axisscale{1}(y_include1_common),model.loads{1,2}(:,i),'*');%WW

  axis tight;axis(axis+[-eps +eps -eps +eps]*10);
  hline('k')
  title(['Resolved Y # ',num2str(i)]);
  %axis tight
  set(ax,'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));')
end

t6 = uitab_o('v0', tg, 'title', 'X vs Y Con');

for i=1:numvars;
  ax = subplot(m,n,i,'tag',['xspec_var_' num2str(i)],'parent',t6);
  plot(ax,model.loads{1,1}(:,i),model.loads{1,2}(:,i),'*');
  axis(ax,'square','tight');
  axis(axis+[-eps +eps -eps +eps]*10);
  xlabel(['Resolved X # ',num2str(i)]);
  ylabel(['Resolved Y # ',num2str(i)]);
  c=corrcoef(model.loads{1,1}(:,i),model.loads{1,2}(:,i));
  title(['corr.: ',num2str(c(2),2)]);


  set(ax,'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));')
end

t7 = uitab_o('v0', tg, 'title', 'Maps');
for i=1:numvars;
  ax = subplot(m,n,i,'tag',['xspec_var_' num2str(i)],'parent',t7);
  update_corrmap(handles,ax,model.detail.maps{i});
  %contour(ax,model.detail.maps{i});
  hline('k')
  axis(ax,'square')
  set(ax,'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));');
  set(get(ax,'children'),'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));');
  title(['Resolved map # ',num2str(i)]);
end

%Diagnostics plots.
t8 = uitab_o('v0', tg, 'title', 'Diagnostics');

for i = 1:3
  switch i
    case 1
      mydat = model.detail.dispmat;
      mytitle = 'Dispersion Matrix';
      mytag = 'dispmat';
    case 2
      mydat = model.detail.dispmat_reconstructed;
      mytitle = 'Reconstructed Dispersion Matrix';
      mytag = 'recondispmat';
    case 3
      mydat = model.detail.sum_matrix;
      mytitle = 'Sum Resolved Matrices';
      mytag = 'sumresolvemat';
  end

  %Zero origin.
  if strcmp(opts.z_origin,'on');
    mydat(mydat<0)=0;
  end;

  ax = subplot(2,2,i,'tag',[mytag '_var_' num2str(i)],'parent',t8);
  %contour(ax,model.detail.axisscale{2,1},model.detail.axisscale{2,2},mydat,opts.nlevel);%WW
  contour(ax,model.detail.axisscale{2,1}(x.include{2}),model.detail.axisscale{2,2}(y.include{2}),mydat,opts.nlevel);
  colormap(ax,[opts.color_map '(64)']);
  axis(ax, 'square')
  title(mytitle);
  set(ax,'YAxisLocation','right','xdir',opts.xdir,'ydir',opts.ydir);
  set(ax,'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));')
  if i == 2
    xlabel(['rrssq: ',num2str(rrssq(model.detail.dispmat,model.detail.dispmat_reconstructed))]);
  end
end

clrs = get(gca,'colororder');
ax = subplot(2,2,4,'parent',t8);
hold on;
for i=1:numvars;
  mydat = model.detail.maps{i};
  %Zero origin.
  if strcmp(opts.z_origin,'on');
    mydat(mydat<0)=0;
  end
  % [a,b]=contour(ax,model.detail.axisscale{2,1},model.detail.axisscale{2,2},mydat,3);%WW
  [a,b]=contour(ax,model.detail.axisscale{2,1}(x.include{2}),model.detail.axisscale{2,2}(y.include{2}),mydat,3);
  set(b,'edgecolor',clrs(repeat(i,7),:));
end;
axis(ax, 'square')
hold off;
title('Overlay Resolved Maps');
set(ax,'YAxisLocation','right','xdir',opts.xdir,'ydir',opts.ydir);
set(ax,'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));')

%Apply model to excluded samples.WW
nrowsx=size(x,1);
nrowsy=size(y,1);
x_exclude1=setdiff([1:nrowsx],x_include1_common);
y_exclude1=setdiff([1:nrowsy],y_include1_common);
[purintx,purinty,purspecx,purspecy,maps] = corrspec(x.data(x_exclude1,x.include{2}),...
  y.data(y_exclude1,y.include{2}),model);%WW

%WW try add new plot

numvars_excl_x=length(x_exclude1);
mx=ceil(sqrt(numvars_excl_x));
nx=mx;

numvars_excl_y=length(y_exclude1);
my=ceil(sqrt(numvars_excl_y));
ny=my;

t9 = uitab_o('v0', tg, 'title', 'X Spec_excl');

for i=1:numvars_excl_y;
  ax = subplot(mx,nx,i,'tag',['xspec_var_' num2str(i)],'parent',t9);
  %plot(ax,x.axisscale{2},model.loads{2,1}(i,:));
  plot(ax,x.axisscale{2}(x.include{2}),purspecx(i,:));%WW
  axis tight
  hline('k')
  title(['Resolved X Excl # ',num2str(i)]);
  %axis tight
  set(ax,'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));','xdir',opts.xdir)
end

t10 = uitab_o('v0', tg, 'title', 'Y Spec_excl');

for i=1:numvars_excl_x;
  ax = subplot(my,ny,i,'tag',['xspec_var_' num2str(i)],'parent',t10);
  %plot(ax,x.axisscale{2},model.loads{2,1}(i,:));
  plot(ax,y.axisscale{2}(y.include{2}),purspecy(i,:));%WW
  axis tight
  hline('k')
  title(['Resolved Y Excl # ',num2str(i)]);
  %axis tight
  set(ax,'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));','xdir',opts.xdir)
end

t11 = uitab_o('v0', tg, 'title', 'X Con_excl');

for i=1:numvars_excl_y;
  ax = subplot(m,n,i,'tag',['xspec_var_' num2str(i)],'parent',t11);
  %plot(ax,x.axisscale{1},model.loads{1,1}(:,i),'*');
  plot(ax,y.axisscale{1}(y_exclude1),purintx(:,i),'*');
  axis tight;axis(axis+[-eps +eps -eps +eps]*10);
  hline('k')
  title(['Resolved X Excl # ',num2str(i)]);
  %axis tight
  set(ax,'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));')
end

t12 = uitab_o('v0', tg, 'title', 'Y Con_excl');

for i=1:numvars_excl_x;
  ax = subplot(m,n,i,'tag',['xspec_var_' num2str(i)],'parent',t12);
  %plot(ax,x.axisscale{1},model.loads{1,1}(:,i),'*');
  plot(ax,x.axisscale{1}(x_exclude1),purinty(:,i),'*');
  axis tight;axis(axis+[-eps +eps -eps +eps]*10);
  hline('k')
  title(['Resolved X Excl # ',num2str(i)]);
  %axis tight
  set(ax,'ButtonDownFcn','corrspecgui(''resolve_click_Callback'',gca,[],guihandles(gcf));')
end

%ax = subplot(2,1,2,'tag',['xspec_var_' num2str(i)],'parent',t11);
%plot(ax,y.axisscale{1}(y.include{1},purinty);

%Current plot.
t1 = uitab_o('v0', tg, 'title', 'Current Plot','tag','current_plot_tab');
axes('parent',t1,'tag','current_plot');
axis tight

%--------------------------------------------------------------------
function h = uitabgroup_o(varargin)

%Overload so can provide v0 flag.
if checkmlversion('<','7.6') || checkmlversion('>','7.10')
  h = uitabgroup(varargin{2:end});
else
  h = uitabgroup(varargin{:});
end

%--------------------------------------------------------------------
function h = uitab_o(varargin)
%Overload so can provide v0 flag.
if checkmlversion('<','7.6') || checkmlversion('>','7.10')
  h = uitab(varargin{2:end});
else
  h = uitab(varargin{:});
end
%--------------------------------------------------------------------
function y=repeat(x,n)
%REPEAT cycles through sequence [1:n] as function of x;
%Y=REPEAT(X,N);
%input:
%   x is input number to be expressed in cycle [1:n];
%output:
%   y is output in cycle [1:n]
%example:
%   y=repeat([1 2 3 4 5 6 7 8],3])
%   results in y values [1 2 3 1 2 3 1 2];


y=rem(x,n);
if (y==0)&(x~=0);y=n;end;

%--------------------------------------------------------------------
function y = rrssq(a,b)
%Helper for resolve_Callback.
dif=a-b;ssqdif = sum (sum (dif.*dif));
ssqrel = sum (sum (a.*a));
[y] = sqrt (ssqdif ./ ssqrel);


%--------------------------------------------------------------------
function resolve_click_Callback(hObject, eventdata, handles)

oldplot = findobj(handles.current_plot_tab,'tag','current_plot');
if ~isempty(oldplot)
  delete(oldplot);
end

h = evricopyobj(hObject,handles.current_plot_tab);
set(h,'tag','current_plot','position',[.1 .1 .8 .8],'ButtonDownFcn','');

if checkmlversion('>','7.10')
  %Use new syntax.
  set(handles.resolve_tg,'SelectedTab',findobj(handles.resolve_tg,'tag','current_plot_tab'));
else
  set(handles.resolve_tg,'SelectedIndex',8);
end

%--------------------------------------------------------------------
function xpos_Callback(hObject, eventdata, handles)


%--------------------------------------------------------------------
function ypos_Callback(hObject, eventdata, handles)


%--------------------------------------------------------------------
function plotdata_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------
function nlevel_Callback(hObject, eventdata, handles)

opts = getappdata(handles.corrspecgui,'gui_options');
opts.nlevel = str2num(get(handles.nlevel,'String'));
setappdata(handles.corrspecgui,'gui_options',opts);
calculate_Callback(handles.corrspecgui,[],handles)

%--------------------------------------------------------------------
function xoffset_Callback(hObject, eventdata, handles)
%Recalc model and plot.
calculate_Callback(handles.corrspecgui,[],handles)

%--------------------------------------------------------------------
function yoffset_Callback(hObject, eventdata, handles)
%Recalc model and plot.
calculate_Callback(handles.corrspecgui,[],handles)

%--------------------------------------------------------------------
function file_menu_Callback(hObject, eventdata, handles)


%--------------------------------------------------------------------
function out = mycolormap

out = {'autumn'
  'bone'
  'colorcube'
  'cool'
  'copper'
  'flag'
  'gray'
  'hot'
  'hsv'
  'jet'
  'lines'
  'pink'
  'prism'
  'rwb'
  'spring'
  'summer'
  'white'
  'winter'};


%--------------------------------------------------------------------
function out = getaxistype(type)
%Get axis info from gui.

switch type
  case 'continuous'
    out = '-';
  case 'discrete'
    out = '*';
  otherwise
    out = '-';
end

%--------------------------------------------------------------------
function axisinfo = setaxistype(handles,opts)
%Update axis types based on options.

axisname = {'spectra' 'contributions'};

for i = 1:length(axisname)
  switch lower(opts.(['axistype_' axisname{i}]))
    case 'continuous'
      myval = 1;
    case 'discrete'
      myval = 2;
    case 'bar'
      myval = 3;
  end
  set(handles.(['axistype_' axisname{i}]),'value',myval)
end

%--------------------------------------------------------------------
function tree_callback(varargin)%fh,keyword,mystruct,jleaf,varargin)
%Left click on tree callback switch yard.
jtree    = varargin{1};
mouse_ev = varargin{2};
etreeobj = varargin{3};
myrow    = varargin{4};
jleaf    = varargin{5};
keyword  = varargin{6};
mypath   = varargin{7};
mystruct = getstruct(etreeobj,mypath);
fh       = etreeobj.parent_figure;
handles = guihandles(fh);

opts = getappdata(fh,'gui_options');

%Need to examin leaf and parent values.
drawnow
[mynode, rem] = strtok(fliplr(jleaf.getValue),'/');
[parent, rem] = strtok(rem,'/');

mynode = fliplr(mynode);
parent = fliplr(parent);
keyword = mynode;

%Check for loading demo data.
if strcmp(parent,'demodata')
  ddata = load(keyword);
  vname = fieldnames(ddata);
  ddata = ddata.(vname{1});
  switch keyword
    case 'data_near_IR'
      loaddata(fh,[],handles,'yblock',ddata)
    case 'data_mid_IR'
      loaddata(fh,[],handles,'xblock',ddata)
  end
  return
end

if isfield(opts,parent)||(isfield(opts,mynode)&&jleaf.isLeaf)
  %Set option of parent node.
  upspec      = false;%Update spectra.
  upmap       = false;%Update map.
  resizeme    = false;
  recalc      = false;

  switch keyword
    case {'std' 'mean' 'data'}
      opts.plot_type = keyword;
      upspec = true;
    case {'continuous' 'discrete' 'bar'}
      opts.(parent) = keyword;
      upspec = true;
    case {'1' '2' '3' '4' '5' '6'}
      opts.(parent) = str2num(keyword);
      recalc = true;
    case {'on' 'off'}
      %On off for false_color, grid, z_origin
      opts.(parent) = keyword;
      switch parent
        case 'grid'
          grid(handles.corrmap,keyword)
        case 'colorbar'
          resizeme = true;
        case 'z_origin'
          upmap = true;
        case 'false_color'
          resizeme = true;
          recalc = true;
          upmap = true;
      end
    case mycolormap
      opts.(parent) = keyword;
      colormap(handles.corrmap,[opts.color_map '(64)']);
    case {'normal' 'reverse'}
      opts.(parent) = keyword;
      upspec = true;
      upmap  = true;
  end

  setappdata(fh,'gui_options',opts);

  if recalc
    calculate_Callback(handles.corrspecgui,[],handles)
  end
  if upspec
    update_spectra(handles)
  end
  if upmap
    update_corrmap(handles)
  end
  if resizeme
    resize_callback(handles.corrspecgui,[],handles)
  end
else
  %Need to update icon.
  if ismember(mynode,{'plot_type' 'max' 'dispersion' 'axis_type_contributions' ...
      'false_color' 'axis_type_spectra' 'z_origin' 'grid' 'xdir' 'ydir' 'colorbar' 'color_map'})
    nodepath  = evrijavamethodedt('getClosestPathForLocation',jtree,mouse_ev.getX,mouse_ev.getY);
    mydepds = jtree.getExpandedDescendants(nodepath);%Is empty if children are not expanded.
    if ~isempty(mydepds)
      %For some reason the collection is empty, maybe because of lazy expand. 
      %The following code doesn't work.
      %thiselement = mydepds.nextElement;
      
      %Get info about current option and then loop through child leafs
      %until we find the correct one and update its icon.
      thisoption = num2str(opts.(mynode));%Dispersion algo is a numeric id so have to use num2str.
      thischildpath = [mypath '/' thisoption];
      thisschildtruct = getstruct(etreeobj,thischildpath);
      for i = 1:jleaf.getChildCount
        thischildleaf = jleaf.getChildAt(i-1);
        [thischildval, junk] = strtok(fliplr(thischildleaf.getValue),'/');
        thischildval = fliplr(thischildval);
        if strcmpi(thischildval,thisoption)
          %Update icon.
          updateicon(etreeobj,thisschildtruct, thischildleaf)
          break
        end
      end
    end
  end
end

%--------------------------------------------------------------------
function tree_close_callback(hObject, eventdata, handles)
%Closing tree.
evritree(handles.corrspecgui,'hide');
resize_callback(handles.corrspecgui,eventdata,handles)

%--------------------------------------------------------------------
function cacheview_closeFcn(fh)

%--------------------------------------------------------------------
function nodes = getcontrolsnode(handles)
%Create node structure with contorls for gui. Set all icons to unchecked
%then, update to checked icons afterwards based on options (see tree_callback).

%***NOTE: the naming scheme for this structure is important and must match
%the options structure field names.

opts = corrspecgui('options');

checkimg = which('evri_check.gif');
uncheckimg = which('evri_uncheck.gif');

%Demo data.
nodes(1).val = 'demodata';
nodes(end).nam = 'demodata';
nodes(end).str = 'Load Demo Data';
nodes(end).icn = '';
nodes(end).isl = false;
nodes(end).clb = 'corrspecgui';

nodes = createdemonodes(nodes, handles);

%Plot Type

nodes(end+1).val = ['plot_type'];
nodes(end).nam = 'plot_type';
nodes(end).str = 'Plot Type';
nodes(end).icn = '';
nodes(end).isl = false;
nodes(end).clb = 'corrspecgui';
%TODO: Switch order same as plotgui.

nodes(end).chd(1).val = ['plot_type' '/' 'mean'];
nodes(end).chd(end).nam = 'mean';
nodes(end).chd(end).str = 'Mean';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

nodes(end).chd(end+1).val = ['plot_type' '/' 'std'];
nodes(end).chd(end).nam = 'std';
nodes(end).chd(end).str = 'Standard Deviation';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

nodes(end).chd(end+1).val = ['plot_type' '/' 'data'];
nodes(end).chd(end).nam = 'data';
nodes(end).chd(end).str = 'Data';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

%Max algorithm.
%                 1: synchronous correlation
%                 2: asynchronous correlation
%                 3: synchronous covariance
%                 4: asynchronous covariance
%                 5: purity about origin
%                 6: purity about mean
nodes(end+1).val = ['max'];
nodes(end).nam = 'max';
nodes(end).str = 'Max Algorithm';
nodes(end).icn = '';
nodes(end).isl = false;
nodes(end).clb = 'corrspecgui';

nodes(end).chd(1).val = ['max' '/' '1'];
nodes(end).chd(end).nam = '1';
nodes(end).chd(end).str = 'Synchronous Correlation';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

nodes(end).chd(end+1).val = ['max' '/' '2'];
nodes(end).chd(end).nam = '2';
nodes(end).chd(end).str = 'Asynchronous Correlation';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

nodes(end).chd(end+1).val = ['max' '/' '3'];
nodes(end).chd(end).nam = '3';
nodes(end).chd(end).str = 'Synchronous Covariance';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

nodes(end).chd(end+1).val = ['max' '/' '4'];
nodes(end).chd(end).nam = '4';
nodes(end).chd(end).str = 'Asynchronous Covariance';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

nodes(end).chd(end+1).val = ['max' '/' '5'];
nodes(end).chd(end).nam = '5';
nodes(end).chd(end).str = 'Purity About Origin';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

nodes(end).chd(end+1).val = ['max' '/' '6'];
nodes(end).chd(end).nam = '6';
nodes(end).chd(end).str = 'Purity About Mean';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

%Dispersion algorithm
nodes(end+1).val = ['dispersion'];
nodes(end).nam = 'dispersion';
nodes(end).str = 'Dispersion Algorithm';
nodes(end).icn = '';
nodes(end).isl = false;
nodes(end).clb = 'corrspecgui';

nodes(end).chd(1).val = ['dispersion' '/' '1'];
nodes(end).chd(end).nam = '1';
nodes(end).chd(end).str = 'Synchronous Correlation';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

nodes(end).chd(end+1).val = ['dispersion' '/' '2'];
nodes(end).chd(end).nam = '2';
nodes(end).chd(end).str = 'Asynchronous Correlation';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

nodes(end).chd(end+1).val = ['dispersion' '/' '3'];
nodes(end).chd(end).nam = '3';
nodes(end).chd(end).str = 'Synchronous Covariance';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

nodes(end).chd(end+1).val = ['dispersion' '/' '4'];
nodes(end).chd(end).nam = '4';
nodes(end).chd(end).str = 'Asynchronous Covariance';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

nodes(end).chd(end+1).val = ['dispersion' '/' '5'];
nodes(end).chd(end).nam = '5';
nodes(end).chd(end).str = 'Purity About Origin';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

nodes(end).chd(end+1).val = ['dispersion' '/' '6'];
nodes(end).chd(end).nam = '6';
nodes(end).chd(end).str = 'Purity About Mean';
nodes(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).isl = true;
nodes(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chk = checkimg;

%Plot settings.
nodes(end+1).val = ['plot_settings'];
nodes(end).nam = 'plot_settings';
nodes(end).str = 'Plot Settings';
nodes(end).icn = '';
nodes(end).isl = false;
nodes(end).clb = 'corrspecgui';

%Axis type.
nodes(end).chd(1).val = ['plot_settings' '/' 'axis_type'];
nodes(end).chd(end).nam = 'axis_type';
nodes(end).chd(end).str = 'Axis Type';
nodes(end).chd(end).icn = '';
nodes(end).chd(end).isl = false;
nodes(end).chd(end).clb = 'corrspecgui';

%Contributions.
nodes(end).chd(end).chd(1).val = ['plot_settings' '/' 'axis_type' '/' 'axis_type_contributions'];
nodes(end).chd(end).chd(end).nam = 'axis_type_contributions';
nodes(end).chd(end).chd(end).str = 'Contributions';
nodes(end).chd(end).chd(end).icn = '';
nodes(end).chd(end).chd(end).isl = false;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';

nodes(end).chd(end).chd(end).chd(1).val = ['plot_settings' '/' 'axis_type' '/' 'axis_type_contributions' '/' 'continuous'];
nodes(end).chd(end).chd(end).chd(end).nam = 'continuous';
nodes(end).chd(end).chd(end).chd(end).str = 'Continuous';
nodes(end).chd(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chd(end).chk = checkimg;

nodes(end).chd(end).chd(end).chd(end+1).val = ['plot_settings' '/' 'axis_type' '/' 'axis_type_contributions' '/' 'discrete'];
nodes(end).chd(end).chd(end).chd(end).nam = 'discrete';
nodes(end).chd(end).chd(end).chd(end).str = 'Discrete';
nodes(end).chd(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chd(end).chk = checkimg;

%Spectra.
nodes(end).chd(end).chd(end+1).val = ['plot_settings' '/' 'axis_type' '/' 'axis_type_spectra'];
nodes(end).chd(end).chd(end).nam = 'axis_type_spectra';
nodes(end).chd(end).chd(end).str = 'Spectra';
nodes(end).chd(end).chd(end).icn = '';
nodes(end).chd(end).chd(end).isl = false;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';

nodes(end).chd(end).chd(end).chd(1).val = ['plot_settings' '/' 'axis_type' '/' 'axis_type_spectra' '/' 'continuous'];
nodes(end).chd(end).chd(end).chd(end).nam = 'continuous';
nodes(end).chd(end).chd(end).chd(end).str = 'Continuous';
nodes(end).chd(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chd(end).chk = checkimg;

nodes(end).chd(end).chd(end).chd(end+1).val = ['plot_settings' '/' 'axis_type' '/' 'axis_type_spectra' '/' 'discrete'];
nodes(end).chd(end).chd(end).chd(end).nam = 'discrete';
nodes(end).chd(end).chd(end).chd(end).str = 'Discrete';
nodes(end).chd(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chd(end).chk = checkimg;

%False color.
nodes(end).chd(end+1).val = ['plot_settings' '/' 'false_color'];
nodes(end).chd(end).nam = 'false_color';
nodes(end).chd(end).str = 'False Color';
nodes(end).chd(end).icn = '';
nodes(end).chd(end).isl = false;
nodes(end).chd(end).clb = 'corrspecgui';

nodes(end).chd(end).chd(1).val = ['plot_settings' '/' 'false_color' '/' 'on'];
nodes(end).chd(end).chd(end).nam = 'on';
nodes(end).chd(end).chd(end).str = 'On';
nodes(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chk = checkimg;

nodes(end).chd(end).chd(end+1).val = ['plot_settings' '/' 'false_color' '/' 'off'];
nodes(end).chd(end).chd(end).nam = 'off';
nodes(end).chd(end).chd(end).str = 'Off';
nodes(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chk = checkimg;

%Z Origin.
nodes(end).chd(end+1).val = ['plot_settings' '/' 'z_origin'];
nodes(end).chd(end).nam = 'z_origin';
nodes(end).chd(end).str = 'Z Origin Equal Zero (z=0)';
nodes(end).chd(end).icn = '';
nodes(end).chd(end).isl = false;
nodes(end).chd(end).clb = 'corrspecgui';

nodes(end).chd(end).chd(1).val = ['plot_settings' '/' 'z_origin' '/' 'on'];
nodes(end).chd(end).chd(end).nam = 'on';
nodes(end).chd(end).chd(end).str = 'On';
nodes(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chk = checkimg;

nodes(end).chd(end).chd(end+1).val = ['plot_settings' '/' 'z_origin' '/' 'off'];
nodes(end).chd(end).chd(end).nam = 'off';
nodes(end).chd(end).chd(end).str = 'Off';
nodes(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chk = checkimg;

%Grid.
nodes(end).chd(end+1).val = ['plot_settings' '/' 'grid'];
nodes(end).chd(end).nam = 'grid';
nodes(end).chd(end).str = 'Grid';
nodes(end).chd(end).icn = '';
nodes(end).chd(end).isl = false;
nodes(end).chd(end).clb = 'corrspecgui';

nodes(end).chd(end).chd(1).val = ['plot_settings' '/' 'grid' '/' 'on'];
nodes(end).chd(end).chd(end).nam = 'on';
nodes(end).chd(end).chd(end).str = 'Grid On';
nodes(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chk = checkimg;

nodes(end).chd(end).chd(end+1).val = ['plot_settings' '/' 'grid' '/' 'off'];
nodes(end).chd(end).chd(end).nam = 'off';
nodes(end).chd(end).chd(end).str = 'Grid Off';
nodes(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chk = checkimg;

%xdir.
nodes(end).chd(end+1).val = ['plot_settings' '/' 'xdir'];
nodes(end).chd(end).nam = 'xdir';
nodes(end).chd(end).str = 'Set X Direction';
nodes(end).chd(end).icn = '';
nodes(end).chd(end).isl = false;
nodes(end).chd(end).clb = 'corrspecgui';

nodes(end).chd(end).chd(1).val = ['plot_settings' '/' 'xdir' '/' 'normal'];
nodes(end).chd(end).chd(end).nam = 'normal';
nodes(end).chd(end).chd(end).str = 'Normal';
nodes(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chk = checkimg;

nodes(end).chd(end).chd(end+1).val = ['plot_settings' '/' 'xdir' '/' 'reverse'];
nodes(end).chd(end).chd(end).nam = 'reverse';
nodes(end).chd(end).chd(end).str = 'Reverse';
nodes(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chk = checkimg;

%Ydir.
nodes(end).chd(end+1).val = ['plot_settings' '/' 'ydir'];
nodes(end).chd(end).nam = 'ydir';
nodes(end).chd(end).str = 'Set Y Direction';
nodes(end).chd(end).icn = '';
nodes(end).chd(end).isl = false;
nodes(end).chd(end).clb = 'corrspecgui';

nodes(end).chd(end).chd(1).val = ['plot_settings' '/' 'ydir' '/' 'normal'];
nodes(end).chd(end).chd(end).nam = 'normal';
nodes(end).chd(end).chd(end).str = 'Normal';
nodes(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chk = checkimg;

nodes(end).chd(end).chd(end+1).val = ['plot_settings' '/' 'ydir' '/' 'reverse'];
nodes(end).chd(end).chd(end).nam = 'reverse';
nodes(end).chd(end).chd(end).str = 'Reverse';
nodes(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chk = checkimg;

%Colorbar
nodes(end).chd(end+1).val = ['plot_settings' '/' 'colorbar'];
nodes(end).chd(end).nam = 'colorbar';
nodes(end).chd(end).str = 'Color Bar';
nodes(end).chd(end).icn = '';
nodes(end).chd(end).isl = false;
nodes(end).chd(end).clb = 'corrspecgui';
%TODO: Switch order same as plotgui.

nodes(end).chd(end).chd(1).val = ['plot_settings' '/' 'colorbar' '/' 'on'];
nodes(end).chd(end).chd(end).nam = 'on';
nodes(end).chd(end).chd(end).str = 'On';
nodes(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chk = checkimg;

nodes(end).chd(end).chd(end+1).val = ['plot_settings' '/' 'colorbar' '/' 'off'];
nodes(end).chd(end).chd(end).nam = 'off';
nodes(end).chd(end).chd(end).str = 'Off';
nodes(end).chd(end).chd(end).icn = uncheckimg;
nodes(end).chd(end).chd(end).isl = true;
nodes(end).chd(end).chd(end).clb = 'corrspecgui';
nodes(end).chd(end).chd(end).chk = checkimg;

%Colormap.
nodes(end).chd(end+1).val = ['plot_settings' '/' 'color_map'];
nodes(end).chd(end).nam = 'color_map';
nodes(end).chd(end).str = 'Colormap';
nodes(end).chd(end).icn = '';
nodes(end).chd(end).isl = false;
nodes(end).chd(end).clb = 'corrspecgui';

nodes = createcolormapnodes(nodes, handles);

% %Plots.
% nodes(end+1).val = ['plots'];
% nodes(end).nam = 'plots';
% nodes(end).str = 'Plots';
% nodes(end).icn = which('plot_op_conditions.gif');;
% nodes(end).isl = false;
% nodes(end).clb = 'corrspecgui';
%
% nodes(end).chd(1).val = ['plots' '/' 'data'];
% nodes(end).chd(end).nam = 'data';
% nodes(end).chd(end).str = 'Data';
% nodes(end).chd(end).icn = '';
% nodes(end).chd(end).isl = true;
% nodes(end).chd(end).clb = 'corrspecgui';
%
% nodes(end).chd(end+1).val = ['plots' '/' 'transpose'];
% nodes(end).chd(end).nam = 'transpose';
% nodes(end).chd(end).str = 'Transpose';
% nodes(end).chd(end).icn = '';
% nodes(end).chd(end).isl = true;
% nodes(end).chd(end).clb = 'corrspecgui';
%
% nodes(end).chd(end+1).val = ['plots' '/' 'cross-resolve'];
% nodes(end).chd(end).nam = 'cross-resolve';
% nodes(end).chd(end).str = 'Cross-Resolve';
% nodes(end).chd(end).icn = '';
% nodes(end).chd(end).isl = true;
% nodes(end).chd(end).clb = 'corrspecgui';

%--------------------------------------------------------------------
function nodes = createcolormapnodes(nodes, handles)
%Create structure for colormap nodes.

%Get list of shareddata for figure, use .id in tree name so can maintain
%unique items.

mymaps = mycolormap;


for i = 1:length(mymaps)
  nodes(end).chd(end).chd(end+1).val = ['plot_settings' '/' 'color_map' '/' mymaps{i}];
  nodes(end).chd(end).chd(end).nam = mymaps{i};
  nodes(end).chd(end).chd(end).str = mymaps{i};
  nodes(end).chd(end).chd(end).icn = which('evri_uncheck.gif');
  nodes(end).chd(end).chd(end).isl = true;
  nodes(end).chd(end).chd(end).clb = 'corrspecgui';
  nodes(end).chd(end).chd(end).chk = which('evri_check.gif');
end

%--------------------------------------------------------------------
function nodes = createdemonodes(nodes, handles)
%Create structure for colormap nodes.

mydata = getdemodata('','corrspecgui');
for i = 1:length(mydata)
  nodes(end).chd(i).val = ['demodata' '/' mydata(i).file];
  nodes(end).chd(end).nam = mydata(i).file;
  nodes(end).chd(end).str = mydata(i).description;
  nodes(end).chd(end).icn = which('bluebutton.gif');
  nodes(end).chd(end).isl = true;
  nodes(end).chd(end).clb = 'corrspecgui';
end

%--------------------------------------------------------------------
function mousemotion_Callback(varargin)
%Mouse motion on main plot, update position and indicate position on spec
%axes. 
persistent x_line y_line x y model
drawnow
handles = varargin{3};

%Motion commands can pile up so return if we're still plotting.
if getappdata(handles.corrspecgui,'updateing_mousemotion_plot')
  return
end

if ~isovercorrmap(handles)
  %Mouse not over corrmap, remove temp cursor lines and return.
  try
    if ~isempty(x_line) & ishandle(x_line)
      delete(x_line);
    end
    if ~isempty(y_line) & ishandle(y_line)
      delete(y_line);
    end
  end
  return
end

%Keep data persistent for speed. 
if isempty(getappdata(handles.corrspecgui,'data_has_changed')) | getappdata(handles.corrspecgui,'data_has_changed') | (isempty(model)|isempty(x)|isempty(y))
  x = getobjdata('xblock',handles);
  y = getobjdata('yblock',handles);
  model = getobjdata('model',handles);
  setappdata(handles.corrspecgui,'data_has_changed',0)
end

if isempty(model)|isempty(x)|isempty(y)
  return
end

setappdata(handles.corrspecgui,'updateing_mousemotion_plot',1)

axpnt = get(handles.corrmap,'CurrentPoint');
x_pos=axpnt(1);
y_pos=axpnt(3);

matrix = model.detail.matrix{1};
matrix2plot = matrix{2};
matrix_max = matrix{3};

%CHANGE TO NEW CURSOR POSITION
%x_pos=findindx(x.axisscale{2},x_pos);%WW
%y_pos=findindx(y.axisscale{2},y_pos);%WW
x_pos=findindx(x.axisscale{2}(x.include{2}),x_pos);
y_pos=findindx(y.axisscale{2}(y.include{2}),y_pos);
x_axisscale2 = x.axisscale{2}(x.include{2});
y_axisscale2 = y.axisscale{2}(y.include{2});
set(handles.xpos,'string',sprintf('%0.2f',x_axisscale2(x_pos)));
set(handles.ypos,'string',sprintf('%0.2f',y_axisscale2(y_pos)));

%Move cursor inidcator on spec axes. Make non fatal error so user can keep
%using if something goes wrong.

try
  axes(handles.xspec)
  v = axis(handles.xspec);
  hold on
  if isempty(x_line) | ~ishandle(x_line)
    x_line = plot([1 1]*x_axisscale2(x_pos),v(3:4),'-b');
  else
    set(x_line,'XData',[1 1]*x_axisscale2(x_pos))
  end
  hold off
  
  %This command seems to take a long time to complete. Not sure why but
  %put in the updateing_mousemotion_plot command to lagging doesn't happen
  %when plot commands pile up.
  axes(handles.yspec)
  v = axis(handles.yspec);
  hold on
  if isempty(y_line) | ~ishandle(y_line)
    y_line = plot(v(1:2),[1 1]*y_axisscale2(y_pos),'-b');
  else
    set(y_line,'YData',[1 1]*y_axisscale2(y_pos))
  end
  hold off
catch
  hold off
end

setappdata(handles.corrspecgui,'updateing_mousemotion_plot',0)
% axes(handles.xspec);
% h = vline(x_axisscale2(index_cursor(1)),'k');
% set(h,'EraseMode','xor','tag','line_xspec');
% 
% axes(handles.yspec);
% h = hline(y_axisscale2(index_cursor(2)),'k');
% set(h,'EraseMode','xor','tag','line_yspec');



%--------------------------------------------------------------------
function nodes = corrmapclick_Callback(varargin)

fig = varargin{1};
evnt = varargin{2};
handles = varargin{3};

if ~isovercorrmap(handles)
  return
end
  
click_type = get(gcf,'SelectionType');

if strcmpi(click_type,'open')
  %If this is a double click then set the cursor and .
  cursor_Callback(fig, evnt, handles)
  setone_Callback(fig, evnt, handles)
else
  cursor_Callback(fig, evnt, handles)
end

%--------------------------------------------------------------------
function out = isovercorrmap(handles)
%Is mouse over corrmap plot.

out = 0;
mypnt = get(handles.corrspecgui, 'CurrentPoint');
mypos = get(handles.corrmap,'position');

if mypnt(1)<mypos(1) | mypnt(1)>(mypos(1)+mypos(3))
  %To left or right so return.
  return
end

if mypnt(2)<mypos(2) | mypnt(2)>(mypos(2)+mypos(4))
  %Off top or bottom.
  return
end
out = 1;

%--------------------------------------------------------------------
function open_new_Callback(varargin)
%Open main map in new window. 

handles = varargin{3};

ax = handles.corrmap;
mychildren = get(ax,'Children');
if ~isempty(mychildren)
  f = figure('Name','Correlation Map','color','white');
  newax = copyobj(ax,f);
  set(newax,'units','normalized', 'box', 'on','position', [0.15    0.07    0.73   0.90])
  set(newax,'fontsize',getdefaultfontsize);
  opts = getappdata(handles.corrspecgui,'gui_options');
  colormap(newax,[opts.color_map '(64)']);
end
