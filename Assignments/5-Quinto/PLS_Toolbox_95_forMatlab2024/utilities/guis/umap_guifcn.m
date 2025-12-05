function varargout = umap_guifcn(varargin)
%CLUSTER_GUIFCN CLUSTER Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%rsk 08/11/04 Change help line and add ssqupdate to keep error from appearing.
%rsk 01/16/06 Fix bug for cancel number cluster dialog.

try
  switch lower(varargin{1})
    case evriio([],'validtopics')
      options = analysis('options');
      %add guifcn specific options here
      if nargout==0
        evriio(mfilename,varargin{1},options)
      else
        varargout{1} = evriio(mfilename,varargin{1},options);
      end
      return;
    otherwise
      if nargout == 0;
        feval(varargin{:}); % FEVAL switchyard
      else
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
      end
  end

catch
  erdlgpls(lasterr,[upper(mfilename) ' Error']);
end
%----------------------------------------------------
function gui_init(h,eventdata,handles,varargin);
%create toolbar
[atb abtns] = toolbar(handles.analysis, 'umap','');
handles  = guidata(handles.analysis);
analysis('toolbarupdate',handles);

%turn off valid crossvalidation
setappdata(handles.analysis,'enable_crossvalgui','off');
crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'Nodes L1')

%{
%change pc edit label.
set(handles.pcseditlabel,'string','Neighbors (k):')
%change ssq table labels
set(handles.pcsedit,'Enable','on')
set(handles.pcsedit,'string','3');
setappdata(handles.pcsedit,'default',3);
%}

%turn on valid crossvalidation
%setappdata(handles.analysis,'enable_crossvalgui','on');
%crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'Neighbors')


%general updating
%set(handles.tableheader,'string', {'Enter (k) above and click the calculate button (gears) to perform analysis' },'horizontalalignment','center')
%No ssq table, disable.
set(handles.ssqtable,'visible','off')
set([handles.pcseditlabel handles.pcsedit],'visible','on')

%Add panel.
panelinfo.name = ['UMAP Settings'];
panelinfo.file = 'umapgui';
panelmanager('add',panelinfo,handles.ssqframe)


%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
closefigures(handles);
set([handles.tableheader handles.pcseditlabel handles.ssqtable handles.pcsedit],'visible','on')
set(handles.tableheader,'string', { '' },'horizontalalignment','left')

setappdata(handles.analysis,'enable_crossvalgui','on');

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)

choosegrps = findobj(handles.analysis,'tag','choosegrps');

%see if we can use choose groups
statmodl = getappdata(handles.analysis,'statmodl');
if ~strcmp(statmodl,'loaded') && analysis('isloaded','xblock',handles) && isempty(analysis('getobjdata','yblock',handles))
  en = 'on';
else
  en = 'off';
end
set(choosegrps,'enable',en);

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)
%two-way x
% out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%discrim: two-way x with classes
out = xprofile.data & xprofile.class & xprofile.ndims==2;

%two-way x and y
% out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;


%--------------------------------------------------------------------
function out = isyused(handles)

out = true;

%----------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin);

statmodl = getappdata(handles.analysis,'statmodl');

if strcmp(statmodl,'none')

  x = analysis('getobjdata','xblock',handles);

  if isempty(x.includ{1});
    erdlgpls('All samples excluded. Can not calibrate','Calibrate Error');
    return
  end
  if isempty(x.includ{2});
    erdlgpls('All x-block variables excluded. Can not calibrate','Calibrate Error');
    return
  end
  %{
  if ~analysis('isdatavalid',handles);
    erdlgpls('Classes must be supplied in the X-block samples mode, or a y-block designating class membership must be loaded. Can not calibrate','Calibrate Error');
    return
  end
  %}
  if mdcheck(x);
    ans = evriquestdlg({'Missing Data Found - Replacing with "best guess"','Results may be affected by this action.'},'Warning: Replacing Missing Data','OK','Cancel','OK');
    if ~strcmp(ans,'OK'); return; end
    drawnow;
    try
      if strcmpi(getfield(modelcache('options'),'cache'),'on')
        modelcache([],x);
        evritip('missingdatacache','Original data (with missing values) has been stored in the model cache.',1)
      end
    catch
    end
    [flag,missmap,x] = mdcheck(x,struct('toomuch','ask'));
    analysis('setobjdata','xblock',handles,x);
  end
  %{
  y = analysis('getobjdata','yblock',handles);
  if ~isempty(y)
    %check for missing data in y-block
    nans = any(isnan(y.data(y.include{1},y.include{2})),2);
    if all(nans)
      erdlgpls('All y-block rows contained missing data. Can not calibrate','Calibrate Error');
      return;
    end
    if any(nans);
      evrimsgbox({'Missing Data Found in Y-block - Excluding all samples with missing y-block values.'},'Warning: Excluding Missing Data Samples','warn','modal');
      y.include{1} = intersect(y.include{1},y.include{1}(find(~nans)));
      analysis('setobjdata','yblock',handles,y);    %and save back to object
    end
    if isempty(y.includ{1});
      erdlgpls('All y-block rows excluded. Can not calibrate','Calibrate Error');
      return
    end
    if isempty(y.includ{2});
      erdlgpls('All y-block columns excluded. Can not calibrate','Calibrate Error');
      return
    end
    
    isect = intersect(y.include{1},x.include{1}); %intersect samples includ from x- and y-blocks
    if length(x.include{1})~=length(isect) | length(y.include{1})~=length(isect);  %did either change?
      y.include{1} = isect;
      analysis('setobjdata','yblock',handles,y);   %and save back to object
      x.include{1} = isect;
      analysis('setobjdata','xblock',handles,x);    %and save back to object
    end
  end
  %}
  preprocessing = {getappdata(handles.preprocessmain,'preprocessing')};

  options = umap_guifcn('options');
  %maxk   = min([length(x.includ{1}) options.maximumfactors]);
  %mink   = getappdata(handles.pcsedit,'default');
  %if isempty(mink); mink = 3; end;                    %default model
  %if mink>maxk;     mink = 1; end;                    %don't allow > # of evs (in fact, consider this a reset of default)

  try
    opts = getoptions(handles);
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.preprocessing = preprocessing;
    %{
    %can be supervised or unsupervised, condition on y was found
    if ~isempty(y)
      %supervised
      if islogical(y.data)
        % y created from x block as logical, convert to a flattened array
        [~, classes_flattened] = max(y.data,[],2);
        y = classes_flattened;
      end  
      modl      = umap(x,y,opts);
    else
      %unsupervised
      modl      = umap(x,opts);
    end
    %}
    modl      = umap(x,opts);

  catch
    erdlgpls({'Error using UMAP method',lasterr},'Calibrate Error');
    return
  end

  %   %Do cross-validation
  %modl = crossvalidate(handles.analysis,modl);

  %UPDATE GUI STATUS
  setappdata(handles.analysis,'statmodl','calold');
  analysis('setobjdata','model',handles,modl);
end

if analysis('isloaded','validation_xblock',handles)
  %apply model to new data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
  if isempty(x); return; end  %some cancel action

  opts = getoptions(handles);
  opts.display  = 'off';
  opts.plots    = 'none';

  try
    %test = umap(x,y,modl);
    test = umap(x,modl);
  catch
    erdlgpls({'Error applying model to validation data.',lasterr,'Model not applied.'},'Apply Model Error');
    test = [];
  end

  analysis('setobjdata','prediction',handles,test);

else
  %no test data? clear prediction
  analysis('setobjdata','prediction',handles,[]);
end
opts = getoptions(handles);
opts.classset = 1;
setappdata(handles.analysis,'analysisoptions', opts);
handles = guidata(handles.analysis);
analysis('updatestatusboxes',handles);
analysis('toolbarupdate',handles)
guidata(handles.analysis,handles)

updatefigures(handles.analysis);     %update any open figures
figure(handles.analysis)


%----------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)

%----------------------------------------------------
function pcsedit_Callback(h, eventdata, handles, varargin)
val = get(handles.pcsedit,'string');
val = str2double(val);
default = getappdata(handles.pcsedit,'default');
if ~isfinite(val) || val<1  %not valid? reset
  set(handles.pcsedit,'string',default);
  return
end
if val==default;
  return
end
val = round(val);

setappdata(handles.pcsedit,'default',val);
analysis('clearmodel',handles.analysis,[],handles);

% --------------------------------------------------------------------
function [modl,success] = crossvalidate(h,modl,perm)
handles  = guidata(h);
success = 0;

if nargin<3
  perm = 0;
end

[cv,lv,split,iter,cvi] = crossvalgui('getsettings',getappdata(h,'crossvalgui'));
if strcmp(cv,'none')
  return;
end

x        = analysis('getobjdata','xblock',handles);
y        = modl.detail.class{1,1,modl.detail.options.classset}';
mc       = modl.detail.preprocessing;

opts = [];
opts.preprocessing = mc;
opts.display = 'off';
opts.plots   = 'none';
opts.discrim = 'yes';  %force discriminant ananlysis cross-val mode

if perm>0
  opts.permutation = 'yes';
  opts.npermutation = perm;
  lv = modl.k;
end

try
  modl = crossval(x,y,modl,cvi,lv,opts);
catch
  erdlgpls({'Unable to perform cross-valiation - Aborted';lasterr},'Cross-Validation Error');
  return
end

if perm>0
  success = lv;
else
  success = 1;
end

%--------------------------------------------------------------------
function updatefigures(h)

handles = guidata(h);
if ~strcmp(getappdata(handles.analysis,'statmodl'),'none');
  if ~isempty(analysis('findpg','scores',handles,'*'))
    plotscores_Callback(handles.plotscores, [], handles);
  end
end

%----------------------------------------
function closefigures(handles)
%close the analysis specific figures

pca_guifcn('closefigures',handles);


%-------------------------------------------------
function updatessqtable(handles,pc)

%-------------------------------------------------
function storedopts = getoptions(handles)
%Returns options strucutre for umap

storedopts  = getappdata(handles.analysis,'analysisoptions');
curanalysis = getappdata(handles.analysis,'curanal');

if isempty(storedopts) | ~strcmp(storedopts.functionname, curanalysis)
  storedopts = umap('options');
end

storedopts.display       = 'off';
storedopts.plots         = 'none';

% --------------------------------------------------------------------
function ploteigen_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ploteigen.

plot_connectivity_graph(handles);

%-------------------------------------------------
function plotscores_Callback(h,eventdata,handles,varargin)

pca_guifcn('plotscores_Callback',h,eventdata,handles,varargin{:});

%----------------------------------------------------
function  optionschange(h)
handles = guidata(h);
panelmanager('update',handles.ssqframe)
%-------------------------------------------------
function plot_connectivity_graph(handles)
% function to take graph object from evrimodel and make a weighted graph
% plot.

%get included x and class information
x = analysis('getobjdata','model',handles);
x = x.detail.data;
x = x(x.include{1},x.include{2});
incld_x = x(x.include{1},:);

%get classes
classes = incld_x.class{1}'; %numbers
classesid = incld_x.classid{1}';  %text (labels)


%map classes to markers and node colors
%first get preferences
if isempty(getplspref('classcolors'))
  pref_colors = classcolors;
else
  prf = getplspref('classcolors');
  pref_colors = prf.userdefined;
end
if isempty(getplspref('classmarkers'))
  pref_markers = classmarkers;
else
  prf = getplspref('classmarkers');
  pref_markers = prf.default;
end


%make empty vars
colors = zeros(size(classes,1),3);
edge_colors = zeros(size(classes,1),3);
markers = strings(size(classes,1),1);
n_classes = unique(classes);

%handle class 0 if present
zero_flag = 1;
if ismember(0,n_classes)
  this_class_color = pref_colors(1,:);
  this_class_marker = pref_markers(1);
  ind = find(classes==0);
  colors(ind,1) = this_class_color(1);
  colors(ind,2) = this_class_color(2);
  colors(ind,3) = this_class_color(3);
  markers(ind) = this_class_marker.marker;
  for i=1:length(ind)
    edge_colors(ind(i),:) = this_class_marker.edgecolor;
  end
  % remove 0 from n_classes now that it is taken care of
  n_classes = n_classes(2:end);
  pref_colors = pref_colors(2:end,:);
  pref_markers = pref_markers(2:end);
  zero_flag = 0;
end

% handles the rest of the classes
for i=1:size(n_classes,1)
  this_class_color = pref_colors(n_classes(i)+zero_flag,:);
  this_class_marker = pref_markers(n_classes(i)+zero_flag);
  ind = find(classes==n_classes(i));
  colors(ind,1) = this_class_color(1);
  colors(ind,2) = this_class_color(2);
  colors(ind,3) = this_class_color(3);
  markers(ind) = this_class_marker.marker;
  for j=1:length(ind)
    edge_colors(ind(j),:) = this_class_marker.edgecolor;
  end
end

% grab graph object and linewidths from evrimodel
modl = analysis('getobjdata','model',handles);
G = modl.detail.umap.graph;
linewidths = modl.detail.umap.linewidths;


%only generate for UMAP models with either 1, 2 or 3 components
emsize = size(modl.detail.umap.embeddings,2);
%filter out G, linewidths if too many connections, leads to locking up
%machine
%quit if no good cutoff was found
[G, linewidths, toomany] = filter_graph(G, linewidths, emsize);
if ~isempty(toomany) return; end
switch emsize
  case 1
    xx = modl.detail.umap.embeddings(x.include{1},1);
    % handle the size of the points
    if size(xx,1) <= 200
      markerSize = 7;
    elseif size(xx,1) > 200 && size(xx,1) <= 1000
      markerSize = 4;
    else
      markerSize = 2;
    end

    % use UIfigure, seems to do better with 2 dims
    myfig = uifigure;
    ax = uiaxes(myfig,'Position',[10 10 530 390]);
    p = plot(ax,G,'Linewidth',linewidths,'NodeColor','r','EdgeColor','#333333','XData',x.include{1},'YData',xx,'MarkerSize',markerSize,'NodeLabel','','EdgeAlpha',0.1);
    ax.YLabel.String = "Embeddings for Component 1";
    ax.XLabel.String = "Samples";

  case {2 3}

    % get the location of the embeddings
    xx = modl.detail.umap.embeddings(x.include{1},1);
    yy = modl.detail.umap.embeddings(x.include{1},2);

    % handle the size of the points
    if size(xx,1) <= 200
      markerSize = 7;
    elseif size(xx,1) > 200 && size(xx,1) <= 1000
      markerSize = 4;
    else
      markerSize = 2;
    end

    switch emsize
      case 2
        % use UIfigure, seems to do better with 2 dims
        myfig = uifigure;
        ax = uiaxes(myfig,'Position',[10 10 530 390]);
        p = plot(ax,G,'Linewidth',linewidths,'NodeColor','r','EdgeColor','#333333','XData',xx,'YData',yy,'MarkerSize',markerSize,'NodeLabel','','EdgeAlpha',0.1);
        ax.XLabel.String = "Embeddings for Component 1";
        ax.YLabel.String = "Embeddings for Component 2";

      case 3
        % use a regular figure, uifigure does not do well with 3 dims
        myfig = figure;
        % handle third axis
        zz = modl.detail.umap.embeddings(:,3);
        p = plot(G,'Linewidth',linewidths,'NodeColor','r','EdgeColor','#333333','XData',xx,'YData',yy,'ZData',zz,'MarkerSize',markerSize,'NodeLabel','','EdgeAlpha',0.1);
        xlabel('Embeddings for Component 1');
        ylabel('Embeddings for Component 2');
        zlabel('Embeddings for Component 3');
        xticks('auto');
        yticks('auto');
        zticks('auto');
    end
  otherwise
    error('Connectivity plot only generated for UMAP models with either 1, 2, or 3 components');
end

%assign colors, markers, and marker edge colors
if ~isempty(colors) && ~isempty(markers)
  for i=1:size(modl.detail.umap.embeddings(x.include{1},:),1);
    highlight(p,i,'NodeColor',colors(i,:),'Marker',markers(i));
  end
end

% make new hover labels, add class information and sample labels
p.DataTipTemplate.DataTipRows(1).Label = 'Sample Number:';
p.DataTipTemplate.DataTipRows(2).Label = 'Number of Connections:';
if ~isempty(classesid)
  p.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Class:',classesid);
end
if ~isempty(incld_x.label{1})
  p.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Label:',cellstr(incld_x.label{1}));
end

%tip on plot information
msg = sprintf('Hover each data point to find the Sample Number, Degree (Number of Connections), Class*, and Label*.\n\n*These need to be provided in the X-block in order to be visible.');
evritip('hover_tip',msg,1);


%-----------------------------------------------------
function [graph, linewidths, toomany] = filter_graph(graph, linewidths, ncomp)
orig_n_connections = length(linewidths);
toomany = [];
% any more connections than this will result in bad performance
% this is as of 11/30/2021 running r2020b.
cutoff = 3000;


%filter out number of connections to improve connectivity plot experience
if orig_n_connections > cutoff
  threshold = find_cutoff(graph.Edges.Weight, cutoff);
  if isempty(threshold) toomany='yes'; return; end
  % remove edges from graph
  graph = rmedge(graph,find(graph.Edges.Weight<threshold));
  % take linewidths
  linewidths = linewidths(find(graph.Edges.Weight>=threshold));
  % launch message box, indicating connections have been taken out
  % include directions to find full graph object
  prop = sprintf('%g',round(100*((orig_n_connections-length(linewidths))/orig_n_connections),2));
  msg = sprintf('For performance reasons, the connectivity plot was truncated by %s %%%%.\n\nOne can find the full graph object after saving the model to the workspace and executing <name_of_saved_model>.detail.umap.graph.\n\nConsider reducing the number of neighbors, which will reduce the number connections in the graph.',prop);
  evritip('graphplot_truncated', msg, 0);
end
%-------------------------------------------------
function [threshold] = find_cutoff(data, cutoff)
% we want the connections to be plotted to be no more than ~3000 (cutoff)
% so the strategy here is to find a threshold of which the connections
% will not be plotted if they are below this threshold. To find the
% threshold, let's start with the 25th percentile. Then find the number
% of remaining connections left. If below cutoff we're done. If not, we
% increase the threshold by percentile and repeat until we are under
% cutoff.

threshold = [];
percentiles_to_test = [25:10:95 96 97 98 99];
for i=percentiles_to_test
  % prctile requires Statistics and Machine Learning Toolbox.
  % might as well use numpy, right? they are already running Python, so there should be no issue here
  t = py.numpy.percentile(data,i);
  remaining = find(data >= t);
  if length(remaining)<=cutoff
    threshold = t;
    break
  elseif length(remaining) > cutoff  && i==percentiles_to_test(end)
    erdlgpls('The UMAP model has too many connections and a sucessful cutoff was not found. Plotting this graph can potentially result in locking up the computer. One can find the full graph object after saving the model to the workspace and executing <name_of_saved_model>.detail.umap.graph. Consider reducing the number of neighbors, which will reduce the number connections in the graph. Aborted.','Performance Error');
  end
end


