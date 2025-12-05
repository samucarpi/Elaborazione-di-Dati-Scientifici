function order = corrmap(data,labels,reord,options)
%CORRMAP Correlation map with variable grouping.
%  CORRMAP produces a pseudocolor map which shows the
%  correlation of between variables (columns) in a data
%  set. The function will reorder the variables by KNN
%  clustering if desired.
%  The input is the data (data) class "double" or "dataset". 
%  Optional input (labels) contains the variable labels
%  when the data is class "double".
%  Optional input (reord) specifies the type of variable reordering to
%  perform. Options include:
%       0 or 'none' = no variable reordering (keep original order)
%       1 or 'std'  = standard sign-sensitive variable reordering {DEFAULT}
%       2 or 'abs'  = absolute value variable reordering (positive or
%                      negative correlated variables are grouped together)
%  The output (order) is a vector of indices with the variable
%  ordering.
%
%I/O: order = corrmap(data,labels,reord); % For data of class "double"
%I/O: order = corrmap(data,reord);        % For data of class "dataset"
%I/O: corrmap demo
%
%See also: AUTOCOR, CLUSTER, CROSSCOR, GCLUSTER, PCA, PCOLORMAP, RWB

% Copyright © Eigenvector Research, Inc. 1997
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%bmw 12-28-99
%bmw 8/02 made dataset compatible
%bmw 5/03 made a pcolor workaround, fixed DSO label problem
%jms 6/03 revised code to improve speed
%jms 6/03 removed test for "double" (defined instead 'dataset' or not)

if nargin == 0; data = 'io'; end
varargin{1} = data;
if ischar(varargin{1});
  options = [];
  options.fontsize = [];%Empty means font size dynamically adjusted (default). 
  if nargout==0; evriio(mfilename,varargin{1},options); else; order = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<4
  options = corrmap('options');
else
  options = reconopts(options,mfilename);
end

if any(size(data)~=1) || ~ishandle(data)
  if isa(data,'dataset')
    if nargin < 2
      reord = 1;
    else
      reord = labels;
    end
    %Mark any rows with NaN as excluded.
    if any(isnan(data.data(:)))
      rincld = data.include{1};
      allNanVars = sum(isnan(data.data), 1)==size(data.data,1);
      mynan = any(isnan(data.data(:, ~allNanVars)'));
      %           mynan  = any(isnan(data.data'));
      rincld = rincld(~ismember(rincld,find(mynan)));
      data.include{1} = rincld;
    end
    inds = data.includ;
    
    if isempty(data.label{2})
      if isempty(data.axisscale{2})
        labels = num2str(inds{2}');
      else
        labels = num2str(data.axisscale{2}(inds{2})');
      end
    else
      labels = data.label{2}(inds{2},:);
    end
    data = data.data(inds{:});
  else
    if nargin < 3
      reord = 1;
    end
    if nargin < 2
      labels = [];
    else
      if ~isempty(labels) & (isnumeric(labels) || size(labels,1)==1)
        reord = labels;
        labels = [];
      end
    end
  end

  %handle translation of reord from string to #
  if isempty(reord)
    reord = 1;
  end
  if ischar(reord)
    switch reord
      case 'none'
        reord = 0;
      case 'abs'
        reord = 2;
      otherwise
        reord = 1;
    end
  end

  %do reording of variables (if requested)
  [m,n] = size(data);
  if reord
    dist = -corrcoef(data);
    dist(isnan(dist)) = 0;  %re-assign NaNs as no correlation
    if reord==2
      dist = - (dist .* dist);
    end
    for i = 1:n
      dist(i,i) = inf;
    end
    startat = now;
    h = [];
    groups = [];
    for k = 1:n-1
      ett = (now-startat)/k*(n-1)*60*60*24;  %estimated total time
      if ~isempty(h) | ett > 30; %total time likely to be > 30 seconds?
        if isempty(h);
          h = waitbar(0,'Calculating correlation map');
        end
        if ishandle(h);
          waitbar(k/(n-1));
          set(h,'name',['Approx. ' num2str(round(ett*(1-(k/(n-1))))) ' Seconds Remaining'])
        end
      end
      [min1,ind1] = min(dist);
      [min2,ind2] = min(min1);
      r = ind1(ind2);
      c = ind2;
      % Segment to order samples here
      if k == 1
        groups = zeros(round(n/2),n);
        groups(1,1:2) = [c r]; gi = 1;
      else
        % does r belong to an existing group?
        [zr1,zr2] = find(groups==r);
        % does c belong to an existing group?
        [zc1,zc2] = find(groups==c);
        % If neither c nor r belong to a group they form their own
        if isempty(zr1)   %r doesn't belong to a group
          if isempty(zc1) %c doesn't belong to a group
            gi = gi+1;
            groups(gi,1:2) = [c r];
          else   % r doesn't belong but c does, add r to group c
            sgc = size(find(groups(zc1(1),:)));   %how big is group c
            % Figure out what side to add to
            cgc = groups(zc1(1),1:sgc(2));
            [mindg,inddg] = min([dist(cgc(1),r) dist(cgc(sgc(2)),r)]);
            if inddg == 2
              groups(zc1(1),sgc(2)+1) = r;
            else
              groups(zc1(1),1:sgc(2)+1) = [r groups(zc1(1),1:sgc(2))];
            end
          end
        else   %r does belong to a group
          if isempty(zc1) %c doesn't belong to a group, add c to group r
            sgr = size(find(groups(zr1(1),:)));   %how big is group r
            % Figure out what side to add to
            cgr = groups(zr1(1),1:sgr(2));
            [mindg,inddg] = min([dist(cgr(1),c) dist(cgr(sgr(2)),c)]);
            if inddg == 2
              groups(zr1(1),sgr(2)+1) = c;
            else
              groups(zr1(1),1:sgr(2)+1) = [c groups(zr1(1),1:sgr(2))];
            end
          else  %both c and r belong to groups, add group c to group r
            sgr = size(find(groups(zr1(1),:)));  %size of group r
            sgc = size(find(groups(zc1(1),:)));  %size of group c
            % Figure out what side to add to
            cgc = groups(zc1(1),1:sgc(2));  % current group c
            cgr = groups(zr1(1),1:sgr(2));  % current group r
            [mindg,inddg] = min([dist(cgc(1),cgr(1)) dist(cgc(1),cgr(sgr(2))) ...
              dist(cgc(sgc(2)),cgr(1)) dist(cgc(sgc(2)),cgr(sgr(2)))]);
            if inddg == 1
              % flop group c and add to the left of r
              groups(zr1(1),1:sgr(2)+sgc(2)) = [cgc(sgc(2):-1:1) cgr];
            elseif inddg == 2
              % add group c to the right of group r
              groups(zr1(1),sgr(2)+1:sgr(2)+sgc(2)) = cgc;
            elseif inddg == 3
              % add group c to the left of group r
              groups(zr1(1),1:sgr(2)+sgc(2)) = [cgc cgr];
            else
              % flop group c and add to the right of group r
              groups(zr1(1),1:sgr(2)+sgc(2)) = [cgr cgc(sgc(2):-1:1)];
            end
            groups(zc1,:) = zeros(1,n);
          end
        end
      end
      dist(r,c) = inf;
      dist(c,r) = inf;

      z   = isinf(dist(r,:)) | isinf(dist(c,:));
      dist(z,z) = inf;

    end
    if ishandle(h); close(h); end
  end
  if reord ~= 0
    if isempty(groups)
      order = 1;
    else
      order = groups(find(groups(:,1)),:);
    end
  else
    order = 1:n;
  end

  if ~isempty(labels) %nargin > 1
    [ml,nl] = size(labels);
    if ml == n
      lflag = 1;
    else
      lflag = 0;
      nl = 2;
    end
  else
    lflag = 0;
    nl = 2;
  end
  if ~lflag
    labels = num2str([1:n]');
  end

  %calculate correlation matrix
  sim = corrcoef(data(:,order));
  sim(isnan(sim)) = 0;  %re-assign NaNs as no correlation
  
  %create figure and store information on this corr matrix
  fig = figure;
  set(fig,'color',[1 1 1],...
    'toolbar','none')
  toolbar(fig,'',{'Zoom','zoom','corrmap(gcbf,''zoom'');','enable','Zoom Map','off','push';
    'Unzoom','unzoom','corrmap(gcbf,''unzoom'');','enable','UnZoom Map','off','push';
    'clipboard','showcmenu','corrmap(gcbf,''showcmenu'');','enable','Show Copy Menu','off','push';
    'save','savedataset','corrmap(gcbf,''savedataset'');','enable','Save Dataset','off','push'});

%   drawnow;
  set(fig,'resizefcn','corrmap(gcbf,''update'');')%,'windowbuttondownfcn','corrmap(gcbf,''zoom'');')

  cmenu = uicontextmenu('parent',fig,'tag','corrmap_context');
  
  uimenu(cmenu,'tag','copytable','label','Copy Table Data To Clipboard','callback',{@menu_callback,fig,'copytable'});
  uimenu(cmenu,'tag','copyorder','label','Copy Order Data To Clipboard','callback',{@menu_callback,fig,'copyorder'});
  
  setappdata(fig,'sim',sim);
  setappdata(fig,'labels',labels);
  setappdata(fig,'order',order);
  setappdata(fig,'reord',reord);
  setappdata(fig,'cmenu',cmenu);

  rows = 1:n;
  cols = rows;

else
  %got a figure handle, use to update zoom
  fig = data;

  if nargin==1;
    mode = 'zoom';
  else
    mode = lower(labels);
  end
  
  if ismac
    set(0,'CurrentFigure',fig);
  else
    figure(fig);
  end
  
  sim    = getappdata(fig,'sim');
  labels = getappdata(fig,'labels');
  order  = getappdata(fig,'order');
  reord  = getappdata(fig,'reord');
  cols   = getappdata(fig,'cols');
  rows   = getappdata(fig,'rows');
  cmenu  = getappdata(fig,'cmenu');

  n      = size(sim,1);

  if strcmp(get(gcbf,'selectiontype'),'open')
    mode = 'unzoom';
  end
  switch mode
    case 'zoom'
      sel = gselect('rbbox',[],struct('poslabel','none','helptextpost','Unzoom using toolbar button or by double-clicking.'));
      if isempty(sel)
        clear order;
        return;
      end
      sel = [min(round(sel)) max(round(sel))];
      sel = max(sel,1);
      lr = length(rows);
      lc = length(cols);
      sel = min(sel,[lc lr lc lr]);
      cols = cols(sel(1):sel(3));
      rows = rows(sel(2):sel(4));
      sim = sim(rows,cols);
    case 'unzoom'
      %unzoom command
      rows = 1:n;
      cols = rows;
    case 'update'
      %redraw only (no change in zoom)
    case 'showcmenu'
      %Show context menu.
      figpos = get(fig,'position');
      set(cmenu,'visible','on')
      set(cmenu,'position',[60 figpos(4)])
      return
    case 'savedataset'
      myds = dataset(sim);
      if reord
        labels = labels(order,:);
      end
      myds.label{1} = labels;
      myds.label{2} = labels;
      svdlgpls(myds,'Save CORRMAP Data','corrmap_data')
      return
  end
  
end

%store current cols and rows selection (might be full range, might not)
setappdata(fig,'cols',cols);
setappdata(fig,'rows',rows);

%draw appropriate image
[sm,sn] = size(sim);
[ml,nl] = size(labels(order([rows cols]),:));
n = max(sm,sn);
if n > 18
  h = imagesc(1:sn,1:sm,sim); colormap('rwb')
else
  sim = [sim zeros(sm,1); [zeros(1,sn) -1]];
  h = pcolor(0.5:1:sn+0.5,0.5:1:sm+0.5,sim); colormap('rwb')
end
set(gca,'Ydir','reverse')
set(gca,'YTickLabel',[],'YTick',[])
set(gca,'XTickLabel',[],'XTick',[])
set(h,'uicontextmenu',cmenu);
if abs(sm-sn)<(sm*.05)   %if the matrix appears to be square to within 95%
%   axis('square')
end
figuretheme(fig);

%draw box around axis
ax = axis;
line(ax([1 2 2 1 1]),ax([3 3 4 4 3]),'color',[0 0 0]);

%add labels
if n > 50 | nl>20
  fs = 7;
elseif n > 20  | nl>10
  fs = 9;
else
  fs = 12;
end

if ~isempty(options.fontsize)
  fs = options.fontsize;
end

labels = deblank(str2cell(labels));

%add horizontal labels
hlh = text(-0.01*(ax(2)-ax(1))*ones(sm,1),1:sm,labels(order(rows)));
set(hlh,'FontSize',fs,'HorizontalAlignment','right','interpreter','none')
%add vertical labels
vlh = text(1:sn,zeros(1,sn),labels(order(cols)));
set(vlh,'Rotation',90,'FontSize',fs,'interpreter','none')

%adjust axes until labels are on-screen
ext1 = get(hlh,'extent');
if iscell(ext1);
  ext1 = cat(1,ext1{:});
end
ext2 = get(vlh,'extent');
if iscell(ext2);
  ext2 = cat(1,ext2{:});
end
%identify most critical labels
[what_xmin,where_xmin] = min(ext1(:,1));
[what_ymin,where_ymin] = min(ext2(:,2)-ext2(:,4));
where_xmin = where_xmin(1);  %use only one of the handles
where_ymin = where_ymin(1);  % (makes iterative resize faster)

for j=1:3;
  %repeat 3 times (to iteratively put labels on screen)
  ext1 = get(hlh(where_xmin),'extent');
  ext2 = get(vlh(where_ymin),'extent');

  %adjust axes to keep labels on-figure
  newax = [ext1(1) ax(2) (ext2(2)-ext2(4)) ax(4)];
  axis(newax);
end

axis off

caxis([-1 1]);
colorbar
if reord ~= 0
  title('Correlation Map, Variables Regrouped by Similarity')
else
  title('Correlation Map, Variables in Original Order')
end
xlabel('Scale Gives Value of R for Each Variable Pair') 

set(gca,'buttondownfcn','corrmap(gcbf,''zoom'');');

if nargout == 0
  clear order
else
  disp('order not cleared')
end

%------------------------------------------
function menu_callback(varargin)
%Callback for menu selections.

mylbl = str2cell(getappdata(varargin{end-1},'labels'));

switch varargin{end}
  case 'copytable'
    %Copy table data to clipboard.
    mytbl    = num2cell(getappdata(varargin{end-1},'sim'));
    mytbl    = [mylbl mytbl];
    mytbl    = [[{' '} mylbl';mytbl]];
  case 'copyorder'
    %Copy order to clipboard.
    order    = getappdata(varargin{end-1},'order');
    olbl     = mylbl(order)';
    order    = num2cell(order);
    mytbl    = [olbl; order];  
end

mytbl = cell2str(mytbl,char(9),1)';
mytbl = [mytbl(:)]';
clipboard('copy',mytbl);




