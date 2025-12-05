function varargout = dendrogram(fig,clusterdata,denoptions)
%DENDROGRAM Display a dendrogram based on Cluster output
% A utility function called by the CLUSTER routine. This is generally not
% a user-accessible function.
%
% Input (clusterdata) is a structure with the following fields:
%   order, options, classes, ins, labels, m, n, desc, dist, cls
% all of which are defined within the code of CLUSTER.
%
% The following options are internal to the function but can be set using
% setplspref:
%      linewidth: [2] defines the width of the lines in the dendrogram.
%      maxlabels: [200] defines the maximum number of labels which will be
%                   shown on the dendrogram. If more than this number of
%                   samples exist, no labels will be shown.
%    clickassign: [ 'off' |{'on'}] governs clicking to assign classes. If
%                   'on', user can click on dendrogram to assign classes to
%                   samples based on splitting the dendrogram at the
%                   indicated distance.
%    clickmarker: [ 'off' |{'on'}] governs showing of marker line
%                   where dendrogram would be split (used with
%                   clickassign).
%   optthreshold: [ inf ] governs optimization of colors. Above this
%                    number of samples, the color pallet is optimized to
%                    improve contrast in the dendrogram. However, optimized
%                    colors will not match color order in other interfaces.
%                    Typical value is 10 to 20. inf = no optimization is
%                    ever done.
%  
%  Note: When running "Cluster" in Analysis window, the threshold value 
%        selected by the user in the dendrogram plot is stored in the
%        "x.userdata" field after the user clicks on the "Keep..."
%        button. If x.userdata is a structure then the value is in 
%        "x.userdata.threshold". If x.userdata is a cell array then the
%        threshold value will be put at the end of "x.userdata".
%        When running "cluster" from the command line, for example:
%        [results,fig,distances] = cluster(arch,options);
%        the threshold selected by the user in the dendrogram plot is
%        stored in appdata and can be retrieved as:
%        cd = getappdata(fig,'clusterdata');cd.threshold
%        Important: The figure must remain open to obtain clusterdata.
%
%I/O: dendrogram(fig,clusterdata,options)
%I/O: dendrogram(clusterdata,options)
%I/O: dendrogram(fig,action)
%
%See also: CLUSTER

%Copyright © Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 1/2007 split out from CLUSTER
%BK 6/1/2016 added threshold to clusterdata struct.
%BK 6/2/2016 added maxlabels to options.

%initialize to avoid compilation and function-name lookup errors
[order options classes classlookup ins labels m n desc dist cls xincl] = deal([]);
% if exists(denoptions)
%   orig_denopts = denoptions;
% else
%   orig_denopts = clusterdata.options;
% end

if nargin>1 && ischar(clusterdata);
  % (handle,action)
  %handle of figure - some figure action
  action = clusterdata;

  switch action
    case 'motion'
      vhandle = getappdata(fig,'vbarhandle');
      if isempty(vhandle) || ~ishandle(vhandle)
        vhandle = vline(0,'k:');
        set(vhandle,'handlevisibility','off');
      end
      
      thandle = getappdata(fig,'texthandle');
      if isempty(thandle) | ~ishandle(thandle)
        thandle = text(0,0,'');
        set(thandle,'handlevisibility','off');
        set(thandle,'buttondownfcn','eval(get(gca,''buttondownfcn''))');
      end
      
      axh = get(fig,'currentaxes');
      pos = get(axh,'currentpoint');
      if pos(1,1)<0 || pos(1,1)>max(get(axh,'xlim')) || pos(1,2)>max(get(axh,'ylim')) || pos(1,2)<0;
        %outside limits, hide
        set(vhandle,'visible','off');
        set(thandle,'visible','off','string','');
      else
        %inside limits
        %snap to nearest
        pos = pos(1,1:3);
        clusterdata = getappdata(fig,'clusterdata');
        pnts = clusterdata.dist;
        pnts = pnts(1:end-1)+diff(pnts)/2;  %get 1/2 way values
        dpnts = pnts-pos(1);
        if all(dpnts<0) || all(dpnts>0);
          pos(1) = nan;
        else
          [what,where] = min(abs(dpnts));
          pos(1) = pnts(where);
        end
        set(vhandle,'xdata',[pos(1) pos(1)],...
          'visible','on',...
          'buttondownfcn',get(gca,'buttondownfcn'));

        %show the class of the current marker position.
        clsname = '';
        clusterdata = getappdata(fig,'clusterdata');
        ind = round(pos(2));
        if ind>0 & ind<=length(clusterdata.order);
          samp = clusterdata.order(ind);
          clsname = [' Sample: ' clusterdata.labels(ind,:)];
          cls  = getappdata(fig,'newclasses');
          if isempty(cls)
            %no new classes set? use original classes
            cls = clusterdata.classes;
            if ~isempty(clusterdata.classlookup) & ~isempty(cls)
              %classlookup populated? use string from there
              cind = ([clusterdata.classlookup{:,1}]==cls(samp));
            else
              cind = [];
            end
            if length(cind)==1
                cls  = clusterdata.classlookup{cind,2};
            elseif length(cls)>=samp
              %use numerical value
              cls = num2str(cls(samp));
            else
              cls = '';
            end
          else
            %use numerical value
            cls = num2str(cls(samp));
          end
          if ~isempty(cls)
            clsname = [clsname ' Class: ' cls];
          end
        end
        set(thandle,'visible','on','string',clsname,'position',pos);
                
      end
      setappdata(fig,'vbarhandle',vhandle);
      setappdata(fig,'texthandle',thandle);

      return

    case 'click'
      %click on figure

      set(fig,'windowbuttonmotionfcn','');  %disable move action for now

      %extract clusterdata as regular variables for use below
      cls = [];
      clusterdata = getappdata(fig,'clusterdata');
      %explode_clusterdata(clusterdata);
      [denoptions order options classes classlookup ins labels m n desc dist cls xincl] = explode_clusterdata(clusterdata);
      options.targetfigure = fig;
      originalclasses = classes;

      if ~isempty(originalclasses)
        evritip('clusterclassreset','Classes have been set. To return to original classes, click on labels (left side of plot)',1)
      end
      %get new classes from click
      axh = get(fig,'currentaxes');
      pos = get(axh,'currentpoint');
      pos = pos(1);
      pnts = dist;
      pnts = pnts(1:end-1)+diff(pnts)/2;  %get 1/2 way values
      %       ind = interp1(pnts,1:length(pnts),pos,'nearest');
      dpnts = pnts-pos;
      if all(dpnts<0) || all(dpnts>0);
        ind = nan;
      else
        [what,ind] = min(abs(dpnts));
      end
      if isfinite(ind);
        classes = cls(ind,:);
        [junk,junk,classes] = unique(classes);  %convert to sequential integers
        setappdata(fig,'newclasses',classes);   %store for later (if we need to push back to data)
      else
        %reset newclasses to match originalclasses (whatever they are)
        setappdata(fig,'newclasses',originalclasses);   %store for later (if we need to push back to data)
      end
            
      vbarhandle = getappdata(fig,'vbarhandle');
      t_val=get(vbarhandle,'XData');
      t_val=t_val(1);
      % get the threshold value & store it for later.
      %setappdata(fig,'threshold',vbarhandle.XData(1));
      setappdata(fig,'threshold',t_val);

      h = findobj(fig,'tag','keepbtn');
      parentfig = getappdata(fig,'parent');
      %actual SETTING of classes? create button
      if (isempty(h) | ~ishandle(h)) & ~isempty(parentfig);
        h=uicontrol(fig,'style','pushbutton','string','Keep...',...
          'units','pixels','position',[10 10 60 20],...
          'tag','keepbtn',...
          'callback','dendrogram(ancestor(gcbo,''figure''),''keep'')');
      end
      
     %t_val = vbarhandle.XData(1);
     stringtext = sprintf('Threshold:\n%f',t_val); 
     h = findobj(fig,'tag','thresholdtxt');
      if isempty(h) && ~isempty(parentfig);
        h=uicontrol(fig,'style','text','string',stringtext,...
          'units','pixels','position',[10 80 60 40],...
          'tag','thresholdtxt','value', t_val);
      else
        try % works in GUI, not in console (where it's stored in fig.clusterdata) 
          %h.String=stringtext;
          set(h,'String',stringtext);
          %h.Value = t_val;
          set(h,'Value',t_val);
        end
      end
      
    case 'keep'
      %see if we can push these classes to data
      parentfig   = getappdata(fig,'parent');
      newclasses  = getappdata(fig,'newclasses');
      handles = guidata(parentfig);

      x = analysis('getobjdata','xblock',handles);
      
      cd = getappdata(fig,'clusterdata');
      %Map out with include field.
      mycls = zeros(1,size(x.data,1));
      mycls(cd.xincl) = newclasses;

      if ~isempty(x.class{1,1})
        %confirm
        %ans = evriquestdlg('Overwrite original classes in data with displayed classes?','Confirm Keep Classes','OK','Cancel','OK');
        myans=evriquestdlg('Save cluster class information?','Add Class to Dataset','Add to End','Replace Last','Ignore','Ignore');
        if strcmp(myans,'Ignore') | isempty(myans)
          return
        end
      else
        myans = 'Replace Last';
      end
      
      % Assume Replace Last was selected
      %x.classlookup{1,1} = [];
      %x.class{1,1} = mycls;
      %x.classname{1,1} = 'Cluster Classes';
      xcls = x.class(1,:);
      xclsidx = size(xcls,2);
      if (strcmp(myans,'Add to End'))
        xclsidx = xclsidx + 1;
      end
      
      x.class{1,xclsidx} = mycls;
      x.classname{1,xclsidx} = 'Cluster Classes';
      
      %also get the threshold data
      h = findobj(fig,'tag','thresholdtxt');
      thresholdValue = get(h,'Value'); %h.Value
      try
          if iscell(x.userdata)
              x.userdata(1,end+1) = {['Threshold Value: ' num2str(thresholdValue)]};
          else
              x.userdata.threshold{1,1} = thresholdValue;
          end
      catch
          %do nothing. This will not store the threshold value in the
          %userdata field b/c the userdata was not in a compatible format
      end          
      analysis('setobjdata','xblock',handles,x);
      
      msg = sprintf('Displayed classes have been stored in Analysis X-block class set %d for samples',xclsidx);
      %evrihelpdlg('Displayed classes have been stored in Analysis X-block class set 1 for samples','Classes stored');
      evrihelpdlg(msg,'Classes stored');
      delete(findobj(fig,'tag','keepbtn'));
      return

    case 'update'
      clusterdata = getappdata(fig,'clusterdata');
      %explode_clusterdata(clusterdata);
      [denoptions order options classes classlookup ins labels m n desc dist cls xincl] = explode_clusterdata(clusterdata);

  end
elseif nargin==1 | (nargin==2 & ~ishandle(fig))
  if ischar(fig);
    options = [];
    options.linewidth   = 2;
    options.maxlabels   = 200;   %maximum number of labels to show
    options.clickassign = 'on';  %allows clicking to assign classes
    options.clickmarker = 'on';
    options.optthreshold = inf;
    if nargout==0; clear varargout; evriio(mfilename,fig,options); else; varargout{1} = evriio(mfilename,fig,options); end
    return;
  end

  if nargin==2;
    % (clusterdata,options)
    denoptions = clusterdata;
  end

  if ~isstruct(fig);
    %     error('Single input must be cluster data structure');
    clusterdata = createclusterdata(fig);
    %explode_clusterdata(clusterdata);
  else
    %(clusterdata,...)
    %explode_clusterdata(fig);
    clusterdata = fig;
  end
  [denoptions order options classes classlookup ins labels m n desc dist cls xincl] = explode_clusterdata(clusterdata);
  fig = figure;

elseif nargin==2
  %(fig,clusterdata)
  %explode_clusterdata(clusterdata);
  [denoptions order options classes classlookup ins labels m n desc dist cls xincl] = explode_clusterdata(clusterdata);
  originalclasses = classes;
  denoptions = clusterdata.options;%[];
elseif nargin==3
  %(fig,clusterdata,options)
  %Nothing to do
end

denoptions = reconopts(denoptions,'dendrogram');

%Do actual dendrogram (on current figure)
if ~isempty(classes);
  iszero = classes==0;  %find any "unknown" samples
  [uclasses,uclassind,classes] = unique(classes);  %convert to sequential positive integers
  if any(iszero)
    classes(iszero)   = 0;  %and set "unknown" samples back to 0
    positive          = classes>find(uclasses==0);  %all classes > 0
    classes(positive) = classes(positive)-1;  %adjust for moving of zero to start
    zeroind = find(uclasses==0);
    uclasses = uclasses([zeroind 1:zeroind-1 zeroind+1:end]);  %and correct order of uclasses (as index)
  end

  %create ordered list of classes to determine colors
  [uorder,uindorder] = unique(classes(order));
  uindorder(uorder == 0) = [];  %drop class zero
  nclasses   = length(uindorder);
  classes    = classes+1;  %bump up classes so "unassigned" = index 1

  if all(uclasses==fix(uclasses)) & all(uclasses<10) & all(uclasses>=0)
    %if all classes are positive integers < 10...
    new_uclasses = 0:max(uclasses);
    [junk,ia,ib] = intersect(uclasses,new_uclasses);
    if junk(1)>0; ia=ia+1; end
    lookup(ia)=ib;
    classes = lookup(classes);
    uclasses = new_uclasses;
    nclasses = length(uclasses);
  end
  colororder = getcolororder(nclasses);

  if nclasses>denoptions.optthreshold;
    %optimize color contrast
    [what,where] = sort(uindorder);
    ind = [];
    ind(where)   = 1:nclasses;
    ind = [ind(1:2:end) ind(2:2:end)];
    colororder   = colororder(ind,:);
  end

else
  classes = ones(1,m)*2;
  colororder = [1 0 0];
  uclasses = [];
end
%add unassigned color at beginning and extra class to end which is used
%when classes do not match
colororder = [0 0 0;
  colororder;
  .5 .5 .5];
unmatched = size(colororder,1);  %get index into colororder which = unmatched color

%define a few keywords for easy reading
startdist = m;
enddist   = m+1;
center    = m+2;

title('Generating Dendrogram...'); drawnow;
axh = get(fig,'currentaxes');
cla
delete(allchild(axh));
for i = 1:m-1
  lastitem = 2*i-1;
  thisitem = 2*i;
  if ins(lastitem,startdist) > ins(lastitem,enddist);
    rind = find(ins(:,startdist) == ins(lastitem,enddist));
    ins(lastitem:thisitem,enddist) = max([ins(lastitem,startdist) ins(thisitem,startdist)])*[1 1]';
    if rind > 0
      ins(rind,startdist) = max([ins(lastitem,startdist) ins(thisitem,startdist)]);
    end
  elseif ins(thisitem,startdist) > ins(thisitem,enddist)
    rind = find(ins(:,startdist) == ins(thisitem,enddist));
    ins(lastitem:thisitem,enddist) = max([ins(lastitem,startdist) ins(thisitem,startdist)])*[1 1]';
    if rind > 0
      ins(rind,startdist) = max([ins(lastitem,startdist) ins(thisitem,startdist)]);
    end
  end

  %get primary connection index
  thisclass = classes(ins(thisitem,1));
  thisclassweight = sum(ins(thisitem,1:end-3)>0);
  lastclass = classes(ins(lastitem,1));
  lastclassweight = sum(ins(lastitem,1:end-3)>0);

  %draw from first group out distance
  lh = line(axh,[ins(lastitem,startdist) ins(lastitem,enddist)],ins(lastitem,center)*[1 1]);
  set(lh,'color',colororder(lastclass,:),'buttondownfcn','eval(get(gca,''buttondownfcn''));'...
    ,'handlevisibility','off','linewidth',denoptions.linewidth);
  %draw from next group out distance
  lh = line(axh,[ins(thisitem,startdist) ins(thisitem,enddist)],ins(thisitem,center)*[1 1]);
  set(lh,'color',colororder(thisclass,:),'buttondownfcn','eval(get(gca,''buttondownfcn''));'...
    ,'handlevisibility','off','linewidth',denoptions.linewidth);
  %draw link between
  lh = line(axh,ins(lastitem,enddist)*[1 1],[ins(thisitem,center) ins(lastitem,center)]);
  if thisclass~=lastclass;
    %if the classes don't match, decide how to merge them
    if thisclass==1           %this was unassigned, branch as other class
      setclass = lastclass;
    elseif lastclass==1       %last was unassigned, branch as this class
      setclass = thisclass;
    else
      %merging two classes, check slack parameter to "override" one of the
      %classes...
      if thisclassweight<options.slack && (lastclassweight>thisclassweight)
        setclass = lastclass;
      elseif lastclassweight<options.slack && (thisclassweight>lastclassweight)
        setclass = thisclass;
      else
        %neither class "wins out", branch as mixed (no class)
        setclass = unmatched;
      end
    end
    %classes do not match, set ALL subsequent connections to these items to gray
    classes(setdiff([ins(thisitem,1:m-1) ins(lastitem,1:m-1)],0)) = setclass;
  else
    setclass = thisclass;
  end
  set(lh,'color',colororder(setclass,:),'buttondownfcn','eval(get(gca,''buttondownfcn''));'...
    ,'handlevisibility','off','linewidth',denoptions.linewidth);
end
drawnow
grid off

switch options.algorithm
  case 'knn'
    xlabel('Distance to K-Nearest Neighbor')
  case 'kmeans'
    xlabel('Distance to K-Means Nearest Group')
  case 'fn'
    xlabel('Distance to Furthest Neighbor')
  case 'avgpair'
    xlabel('Average-Paired Distance')
  case 'ward'
    xlabel('Variance Weighted Distance Between Cluster Centers')
  otherwise
    xlabel('Distance Between Cluster Centers');
end


mindist = 0;
if m<=denoptions.maxlabels;
  th = [];
  for i = 1:m
    th(i) = text(axh,0,i,labels(i,:));
  end
  set(th,'horizontalalignment','right','buttondownfcn','dendrogram(ancestor(gcbo,''figure''),''click'')','interpreter','none');
  hold off

  %adjust axes to put labels insize the axes area
  for j = 1:2;
    %loop through this twice to get correct scaling
    ext = get(th,'extent');
    ext = cat(1,ext{:});
    mindist = min([mindist;ext(:,1)])*1.05;
    maxdist = max(ins(:,m+1))*1.15;
    if maxdist ~= mindist;
      axis([mindist maxdist 0 m+1]);
    end
  end
end

if strcmp(options.pca,'true')
  if strcmp(options.mahalanobis,'true')
    s = sprintf('Dendrogram Using Mahalanobis Distance on %g PCs',n);
    title(s)
  elseif ~isempty(desc)
    s = sprintf('Dendrogram Using %s and Distance on %g PCs',desc,n);
    title(s)
  else
    s = sprintf('Dendrogram Using No Scaling and Distance on %g PCs',n);
    title(s)
  end
else
  if ~isempty(desc)
    s = sprintf('Dendrogram of Data with Preprocessing: %s',desc);
    title(s)
  else
    title('Dendrogram Using Unscaled Data')
  end
end
set(gca,'YColor',get(fig,'Color'));

if ~isempty(uclasses);
  %add hidden objects for legend
  hold on
  lh = plot(axh,ones(length(uclasses)),ones(length(uclasses))*nan);
  if any(uclasses==0);
    start = 1;
  else
    start = 2;
  end
  for j=1:length(lh)
    tag = '';
    if ~isempty(classlookup)
      clind = cat(2,classlookup{:,1})==uclasses(j);
      if any(clind)
        tag = classlookup{clind,2};
      end
    end
    if isempty(tag)
      tag = ['Class ' num2str(uclasses(j))];
    end
    set(lh(j),'color',colororder(j-1+start,:),'handlevisibility','on','linewidth',denoptions.linewidth);
    legendname(lh(j),tag);
  end
  hold off
  legend off
end

threshold = getappdata(fig,'threshold');

clusterdata = struct(...
  'denoptions',denoptions,...
  'order',order,...
  'options',options,...
  'classes',originalclasses,...
  'classlookup',{classlookup},...
  'ins',ins,...
  'labels',labels,...
  'm',m,...
  'n',n,...
  'desc',desc,...
  'dist',dist,...
  'cls',cls,...
  'xincl',xincl,...
  'threshold',threshold...
  );

setappdata(fig,'clusterdata',clusterdata);
if strcmp(denoptions.clickassign,'on')
  set(axh,'buttondownfcn','dendrogram(ancestor(gcbo,''figure''),''click'')');
  if strcmp(denoptions.clickmarker,'on')
    set(fig,'windowbuttonmotionfcn','dendrogram(ancestor(gcbo,''figure''),''motion'');');
  end
end


%-----------------------------------------------------------
function clusterdata = createclusterdata(linkage,x)

m = size(linkage,1);
n = 0;
desc = [];
options = cluster('options');
options.pca = 'false';
options.slack = 2;

labels = [];
classes = [];
if nargin>1 & ~isempty(x)
  if isa(x,'dataset');
    classes = x.class{1};
    labels  = x.label{1};
    xincl   = x.include{1};
  end
end
if isempty(labels)
  labels = num2str([1:m]');
end

%create ins matrix from linkage
ins = zeros((m-1)*2,m+2);
for j=1:length(linkage);
  for linkitem = 1:2;
    g = linkage(j,linkitem);
    isgrp = find(g>m);
    while ~isempty(isgrp)
      %for any which are references to previously grouped items, look up the
      %links to the original objects
      tolookup = g(isgrp);
      g(isgrp) = [];
      for k=tolookup;
        lookup = ins(k-m,1:m);
        g = [g lookup(lookup>0)];
      end
      isgrp = find(g>m);
    end
    ins((j-1)*2+linkitem,1:length(g)) = g;
    ins((j-1)*2+linkitem,m+2) = mean(g); %store link location
  end
  ins((j-1)*2+1,m+1) = linkage(j,3); %store distance
end

%create class assignment tree from ins
isz = size(ins);
cls = repmat([1:m+1]-1,isz(1)/2,1);
for j=1:isz(1)/2;
  incls = ins(2*j-1:2*j,1:end-3)+1;
  cls(j:end,incls(:)') = cls(j,incls(1));
end
cls = cls(:,2:end);
dist = ins(1:2:end,isz(2)-1);
order = [m:-1:1];

clusterdata = struct(...
  'order',order,...
  'options',options,...
  'classes',classes,...
  'ins',ins,...
  'labels',labels,...
  'm',m,...
  'n',n,...
  'desc',desc,...
  'dist',dist,...
  'cls',cls,...
  'xincl',xincl...
  );

%-----------------------------------------------------------
function [denoptions, order, options, classes, classlookup, ins, labels, m, n, desc, dist, cls, xincl] = explode_clusterdata(clusterdata)

% for fyld = fieldnames(clusterdata)';
%   assignin('caller',fyld{:},clusterdata.(fyld{:}));
% end

if length(fieldnames(clusterdata))>=11
  if isfield(clusterdata,'denoptions')
    denoptions = clusterdata.denoptions;
  else
    denoptions = [];
  end
  order = clusterdata.order;
  options = clusterdata.options;
  classes = clusterdata.classes;
  classlookup = clusterdata.classlookup;
  ins = clusterdata.ins;
  labels = clusterdata.labels;
  m = clusterdata.m;
  n = clusterdata.n;
  desc = clusterdata.desc;
  dist = clusterdata.dist;
  cls = clusterdata.cls;
  xincl = clusterdata.xincl;
else
  error('Input structure ''clusterdata'' is missing one or more fields')
end



%-----------------------------------------------------------
function clrs = getcolororder(n);

clrs = classcolors;

%These are the EXACT colors from plotgui... now drop gray
clrs = clrs(2:end,:);

if nargin>0;
  if n>size(clrs,1);
    clrs = normaliz(jet(n),[],3);
  else
    clrs = clrs(1:n,:);
  end
end
