function out = trendlink(fig,mode,varargin)
%TRENDLINK Uses marker objects to extract trend information.
% Helper function used by TRENDTOOL.
%
%I/O: trendlink on  %turn on trend-linking for current figure
%I/O: trendlink off   
%
%See also: TRENDTOOL, TRENDMARKER, TRENDAPPLY, TRENDWATERFALL

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

switch nargin
  case 0
    fig = gcf;
    mode = 'on';
  case 1
    if isstr(fig);
      mode = fig;
      fig = gcf;
    else
      mode = 'update';
    end
end

if nargin>2 & ischar(fig)
  %special GUI-style calls - just pass all inputs to trendtool
  %inputs are probably: (mode,fig,eventdata,handles,otherdata)
  [mode,fig] = deal(fig,mode);  %swap fig and mode variables
  args = {mode,getappdata(fig,'TrendLinkParent'),varargin{:}};
  if nargout>0
    out = trendtool(args{:});
  else
    trendtool(args{:});
  end
  return
end

if checkmlversion('<','7')
  displayname = 'tag';
else
  displayname = 'displayname';
end

switch mode
  case 'on';
    trendmarker('on',fig);
    setappdata(fig,'MarkerChangeFcn','trendlink(gcf);')
    trendlink(fig);
    set(0,'currentfigure',fig);
    return
    
  case 'off'
    tlparent = getappdata(fig,'TrendLinkParent');
    if ~isempty(tlparent) & ishandle(tlparent);  %did we find a valid parent figure?
      %Get data from that parent
      tldata = getappdata(tlparent,'TrendLinkData'); 
      if tldata.target==fig;   %if it thinks it is OUR parent then...
        figure(tlparent);
        trendmarker('off')      %turn off markers
        setappdata(tlparent,'MarkerChangeFcn','')
        figure(tlparent);   %make it active
      end
    end
    delete(fig);   %delete TrendLink figure
    return
    
  case {'saveas' 'spawnplot' 'retrieve'}
    fig = getappdata(gcf,'TrendLinkParent');
    
  case {'closetrend' 'detach'}
    if isempty(fig);
      fig = gcf;
    end
    if ~ishandle(fig);
      return;
    end
    data = getappdata(fig,'Trendwaterfall');
    if ishandle(data)
      delete(data);
    end
    data = getappdata(fig,'TrendLinkData');
    if isfield(data,'target');
      if ishandle(data.target)
        delete(data.target)
      end
    end
    
    switch mode 
      case 'detach'
        setappdata(fig,'plotcommand','')
        setappdata(fig,'markerdata',[]);
        delete(findobj(fig,'tag','trendtool_toolbar'));
        plotgui('update','figure',fig);
        
      otherwise
        plotgui('closegui',fig);

    end
    return
    
  case 'select'
    tlparent = getappdata(fig,'TrendLinkParent');
    mydata = trendmarker('getobjdata',tlparent);
    plotby = getappdata(tlparent,'plotby');
    if plotby>0 | ~strcmpi(getappdata(fig,'figuretype'),'plotgui')
      opts = struct('helptextpost','Hold down [Shift] to add to current selection.');
    else
      opts = struct('helptextpost','');
    end
    figure(fig);
    if strcmp(mydata.type,'image')
      isel = gselect('rbbox',opts);
    else
      isel = gselect('xs',opts);
    end
    if isempty(isel);
      return;
    end
    seltype = get(fig,'selectiontype');
    
    if strcmp(mydata.type,'image')
      %handle correction for interpolation
      interpfactor = getappdata(fig,'interpolation');
      if ~isempty(interpfactor) & interpfactor>1
        if any(find(isel{1}))
          isel{1}   = coadd_img(isel{1},interpfactor,struct('mode','sum'))>0;
        else
          isel{end} = coadd_img(isel{end},interpfactor,struct('mode','sum'))>0;
        end
      end
    end
    
    myisel = find(isel{1});
    if isempty(myisel)
      myisel = find(isel{end});
    end
    isel = myisel;
    if ~isempty(isel);
      if plotby>0;
        vals = getappdata(tlparent,'axismenuindex');
        switch seltype
          case 'extend'
            isel = union(vals{2},isel);
        end
      end
      trendtool('viewspec',tlparent,isel);
    end
    return
    
  case 'autocontrast'
    fig = getappdata(fig,'TrendLinkParent');
    
  case 'update'
    %no action necessary

  case 'surface'
    mode = getappdata(fig,'plottype');
    if ~strcmpi(mode,'surface')
      setappdata(fig,'plottype','surface');
    else
      setappdata(fig,'plottype','image');
    end
    trendlink(getappdata(fig,'TrendLinkParent'),'on')
    return;
    
  otherwise
    error('Unrecognized mode "%s" for trendlink',mode)
end

if isempty(fig) | ~ishandle(fig) | strcmpi(get(fig,'tag'),'plotgui')
  fig = gcbf;
  if isempty(fig) | ~ishandle(fig)
    fig = gcf;
  end
end

%get dataset which we'll use to extract data from
mydata = trendmarker('getobjdata',fig);

%Get / setup trend-link data
tldata = getappdata(fig,'TrendLinkData');
if isempty(tldata) | ~isstruct(tldata);
  tldata.target = [];
end
if isempty(tldata.target) | ~ishandle(tldata.target) | ~strcmp(get(tldata.target,'tag'),'trendlink');
  tldata.target = figure('Name','Trend View','tag','trendlink','visible','off');  
  figuretheme(tldata.target);

  %move figure position
  opts = getplspref('trendlink');
  if ~isfield(opts,'figureposition') | isempty(opts.figureposition);
    pos = get(tldata.target,'position').*[1.1 .9 1 1];
    setplspref('trendlink','figureposition',pos);
  else
    pos = opts.figureposition;
  end
  set(tldata.target,'position',pos);
  set(tldata.target,'visible','on');
  
  %add menus
  h1 = uimenu(tldata.target,'label','TrendTool','tag','TrendLinkMenu');
  h2 = uimenu(h1,'label','Save Results As...','callback','trendlink(''saveas'');');
  h2 = uimenu(h1,'label','Spawn Results Plot','callback','trendlink(''spawnplot'');');
  h2 = uimenu(h1,'label','Quit TrendTool','separator','on','callback','trendlink(''off'')');
  
  setappdata(tldata.target,'TrendLinkParent',fig);

end

updatetoolbar(mydata,tldata.target,fig);

setappdata(fig,'TrendLinkData',tldata);
set(0,'currentfigure',tldata.target);

%Get markerdata
dat = getappdata(fig,'markerdata');
if isempty(dat);
  dat.handles = [];
  dat.data = [];
end

%get options determined by data figure
if strcmpi(getappdata(fig,'plottype'),'plotgui')
  pgoptions = getappdata(fig);
else
  %not a plotgui figure - assume defaults
  pgoptions = [];
end
defaults = [];
defaults.plotby = 1;
defaults.viewexcludeddata = 0;
pgoptions = reconopts(pgoptions,defaults);

%plotby info
if pgoptions.plotby == 2;
  mydata = mydata';
end

if ~isempty(mydata);
  %Determine indicies closest to marked points
  xind   = 1:size(mydata,2);
  xaxis  = mydata.axisscale{2};
  if isempty(xaxis);  %working in unitless "index"
    xaxis = xind;
  end
  if ~isempty(dat.data)
    if length(xind)>1
      x = min(max([dat.data.x],min(xaxis(xind))),max(xaxis(xind)));
      ind   = interp1(xaxis,xind,x,'nearest');
    else
      ind = 1;
    end
    %get x-values from those indicies (except "bad" points which should = NaN
    bad   = isnan(ind);
    ind(bad) = 1;
    xind  = xaxis(ind);
    xind(bad) = nan;
    ind(bad) = nan;
  end
  
  results = [];
  tags = cell(0);
  
  %- - - - - - - - - - -
  %do calculations
  [results,tags,normto] = trendapply(mydata,dat,pgoptions);

else
  %no data to analyze
  results = [];
  tags = {};
  normto = [];
end

%- - - - - - - - - - -
%Do plot or other action with those results

switch mode
  case {'saveas' 'spawnplot' 'retrieve'}
    if ~isempty(results);
      results = copydsfields(mydata,dataset(results),1);
      results.label{2} = tags;
      if strcmp(mydata.type,'image') & mydata.imagemode==1
        results.type = 'image';
        results.imagemode = 1;
        imsz = mydata.imagesize;
        results.imagesize = imsz;
        results.imageaxisscale = mydata.imageaxisscale;
      end
      
      switch mode
        case 'saveas'
          svdlgpls(results,'Save trends as...','trends');
        case 'spawnplot'
          plotgui(results,'new','imagegunorder',[3 2 1]);
        case 'retrieve'
          out = results;
      end          
    end
    
  otherwise
    if ~isempty(results);
      %create dataset from compiled results (incl. labels, etc)
      results = copydsfields(mydata,dataset(results),1);
      
      if pgoptions.viewexcludeddata
        results.include{1} = 1:size(results,1);
      end
      
      if strcmp(mydata.type,'image') & mydata.imagemode==1
        results.type = 'image';
        results.imagemode = 1;
        imsz = mydata.imagesize;
        if length(imsz)>2
          imsz = [imsz(1) prod(imsz(2:end))];
        end
        results.imagesize = imsz;
        excl = setdiff(1:size(results,1),results.include{1});
        results.data(excl,:) = nan;

        autocontrast = strcmp(get(findobj(tldata.target,'tag','autocontrastbtn'),'state'),'on');
        
        nslabs = size(results,2);
        switch 'simple'
          case 'simple'
            toselect = 1:nslabs;  %ALWAYS do only first three
            im = results.imagedata(:,:,toselect);
            if nslabs>1;
              if nslabs<3
                % 2 slabs? add one or more blank slabs
                im = cat(3,zeros(results.imagesize(1),results.imagesize(2),1),im(:,:,[2 1]));
              elseif nslabs>3
                % >3? condense
                sz = size(im);
                cm = get(gca,'colororder');
                cm = cm(mod((1:sz(3))-1,size(cm,1))+1,:);
                im = reshape(im,[sz(1)*sz(2) sz(3)]);
                im = im*cm;
                im = reshape(im,[sz(1:2) 3]);
              else
                %invert order to be [red green blue]
                im = im(:,:,[3 2 1]);
              end
              im(isnan(im)) = 0;
              %normalize and baseline slabs
              if autocontrast
                im = reshape(autocon(unfoldmw(im,3)',2.5),[results.imagesize 3]);
              end
              for j=1:3;
                slab = im(:,:,j);
                mn = min(min(slab));
                slab = slab-mn;
                mx = max(max(slab));
                if mx>0
                  slab = slab./mx;
                end
                im(:,:,j) = slab;
              end
            else
              %only one slab? autocon and display using colormap
              if autocontrast
                im(isnan(im)) = 0;
                im = reshape(autocon(im(:)),results.imagesize);
              end
            end

            %grab image axisscale if present
            imax = mydata.imageaxisscale;
           
            %Interpolate if requested
            interpfactor = getappdata(tldata.target,'interpolation');
            if ~isempty(interpfactor) & interpfactor>1
              %interpolate image
              sz = size(im);
              [xi,yi] = meshgrid(linspace(0,100,sz(2)*interpfactor),linspace(0,100,sz(1)*interpfactor));
              [x,y]   = meshgrid(linspace(0,100,sz(2)),linspace(0,100,sz(1)));
              imi     = zeros(size(xi));
              im(isnan(im)) = 0;   %do NOT allow NaN's here
              im(setdiff(1:size(results,1),results.include{1})) = 0;
              for j=1:size(im,3);
                temp = interp2(x,y,im(:,:,j),xi,yi,'spline');
                temp(temp<0) = 0;
                imi(:,:,j) = temp./max(max(max(temp)),1);
              end
              
              im = imi;
              %and interpolate axes too (if present)
              for j = 1:2;
                if ~isempty(imax{j})
                  imax{j} = interp1(1:length(imax{j}),imax{j},linspace(1,length(imax{j}),length(imax{j})*interpfactor));
                end
              end
            end
              
            figuretheme
            
            mode = char(getappdata(tldata.target,'plottype'));
            if isempty(mode)
              mode = 'image';
            end
            switch mode
              case 'surface'
                [az,el] = view;
                im = mean(im,3);
                if any(cellfun('isempty',imax))
                  p = surf(im);
                else
                  p = surf(imax{2},imax{1},im);
                end
                if az~=0
                  view([az,el]);
                end
                axis tight ij
                shading interp
                add3dlight;

                if all(cellfun('isempty',imax))
                  axis off
                end

              otherwise
                %standard image
                if any(cellfun('isempty',imax))
                  %show image WITHOUT axisscale
                  imagesc(im);
                  axis off % hide axis
                else
                  %show image WITH axisscale
                  imagesc(imax{2},imax{1},im);
                end
                
                %add patch for excluded variables
                coptions = [0 0 0; 1 1 1;  .2 .2 .3; .5 .5 .5];
                excludecolor = coptions(end,:);  %default if not found below
                cm = colormap;
                for exci = 1:size(coptions,1);
                  if ~any(all(abs(scale(cm,coptions(exci,:)))<.1,2))
                    %color was NOT found, use this one
                    excludecolor = coptions(exci,:);
                    break
                  end
                end
                
                excludmask = setdiff(1:size(results,1),results.include{1});
                facealpha = 1;  %NON transparent
                [yexcl,xexcl] = ind2sub(results.imagesize,excludmask);
                xexclmat = [0 1 1 0 0]'*ones(1,length(xexcl))+repmat(xexcl(:)'-.5,5,1);
                yexclmat = [0 0 1 1 0]'*ones(1,length(yexcl))+repmat(yexcl(:)'-.5,5,1);
                interpfactor = getappdata(tldata.target,'interpolation');
                if ~isempty(interpfactor) & interpfactor>1
                  %interpolate mask if needed
                  xexclmat = (xexclmat-.5)*interpfactor+.5;
                  yexclmat = (yexclmat-.5)*interpfactor+.5;
                end
                exclpatch = patch(xexclmat,yexclmat,excludecolor);
                set(exclpatch,'facealpha',facealpha,'linestyle','none');
                
                axis ij fill tight image
                
            end
            
          case 'plotgui'
            %WARNING: this command, while completely functional, will cause
            %very strange behavior if the spectral window takes a long time
            %to update the controls figure (e.g. many pixels in the image)
            toselect = 1:nslabs;  %ALWAYS do only first three
            plotgui('update','figure',tldata.target,results,'plotby',2,'viewautocontrast',autocontrast,'axismenuvalues',{0 toselect []},'imagegunorder',[3 2 1]);
        end
        return
      end
      
      %plot in trend figure
      taxis = mydata.axisscale{1};
      if isempty(taxis);
        taxis = 1:size(mydata.data,1);
      end
      
      figure(tldata.target);

      %list of properties to keep the same when we replot
      lineprops = {'EraseMode','LineStyle','LineWidth','Marker','MarkerSize','MarkerEdgeColor','MarkerFaceColor'};  
      setappdata(tldata.target,'lineprops',lineprops)
      
      %Copy those properties from all current trend lines
      currentlines = findobj(tldata.target,'type','line','userdata','trendline');
      lineinfo = get(currentlines,lineprops);
      if isempty(lineinfo); lineinfo = cell(0); end
      lineinfo = flipud(lineinfo);
      if ~isempty(lineinfo); setappdata(tldata.target,'lineinfo',lineinfo); end
      
      %get current axes (if # of new results = # of old plotted results)
      if size(results,2)==size(lineinfo,1);
        rezoom    = 1;  %try to rezoom
        %grab viewed axis info to determine if we were (and should again) be zoomed
        oldaxis   = axis(get(tldata.target,'currentaxes'));
        fullaxis  = getappdata(get(tldata.target,'currentaxes'),'unzoomedaxisscale');
      else
        rezoom    = 0;  %don't try to rezoom
      end
      zoomstate = getappdata(tldata.target,'ZoomOnState');
      zoommode  = getappdata(tldata.target,'ZOOMFigureMode');

      %check for legend
      hadlegend = ~isempty(findobj(tldata.target,'tag','legend','type','axes'));
      
      colors = get(0,'defaultaxescolororder');
      
      results.data(:,normto) = nan;
      
      mylines = [];
      hasnan = any(isnan(results.data));
      for j=1:size(results,2);
        h = dsoplot(taxis,results(:,j));
        set(h,displayname,tags{j},'color',colors(mod(j-1,size(colors,1))+1,:));
        set(h,'userdata','trendline')
        taxisd = sign(diff(taxis));
        if isempty(taxisd)
          set(h,'marker','o','linestyle','none');
        elseif ~all(taxisd==taxisd(1));
          set(h,'marker','.','linestyle','none');
        elseif hasnan
          set(h,'marker','.');
        end
        mylines(j) = h;
        
        %reset previously set properties 
        % (if user changes properties, we should keep those the same)
        if size(lineinfo,1)>=j;
          set(h,lineprops,lineinfo(j,:))
        end
        
        hold on
      end
      hold off
      
      %evaluate Zoom state and if we should re-zoom
      ax      = gca;
      newaxis = axis(ax);
      if rezoom
        if length(oldaxis)==length(fullaxis) & ~all(oldaxis==fullaxis)  %was there a difference between the displayed axes and the zoomed-out axes? then rezoom
          zoom on
          axz = get(ax,'ZLabel');
          setappdata(axz,'ZOOMAxesData',newaxis);    %This is where zoom will look for the unzoomed axes range
          axis(oldaxis)
        end
      end
      setappdata(gca,'unzoomedaxisscale',newaxis)
      if isempty(zoomstate); 
        zoom off; 
      else
        zoom on
        setappdata(tldata.target,'ZOOMFigureMode',zoommode);
      end

      %add legend again if we had one
      if hadlegend
        legend(get(mylines,displayname),0)
      end
      
      %remember current figure position (as long as it is on-screen)
      set(tldata.target,'units',get(0,'units'))
      ss  = getscreensize;
      pos = get(tldata.target,'position');
      if pos(1)>ss(3) | pos(2)>ss(4) | (pos(1)+pos(3))<ss(1) | (pos(2)+pos(4))<ss(2);
        pos = get(0,'defaultfigureposition');  %figure off-screen? reset to default position
        set(tldata.target,'position',pos);
      end
      setplspref('trendlink','figureposition',pos);
      
    elseif isempty(mydata)
      cla
      text(0.5,0.5,{'No Data Loaded','Use Plot Controls File/Load to load data'},'fontsize',12,'horizontalalignment','center','fontweight','bold');
      set(gca,'visible','off');
    else
      cla
      text(0.5,0.5,{'No Trend Markers Set','Right-Click in main window to set markers'},'fontsize',12,'horizontalalignment','center','fontweight','bold');
      set(gca,'visible','off');
    end
    figure(fig);
    
    
end

%-----------------------------------------------------------
function varargout = dsoplot(varargin)
%PLOT - overloaded plot function for DataSets

%Copyright Eigenvector Research, Inc. 2003
%jms 4/24/03 -renamed "includ" to "include"

if nargin == 0;
  error('Not enough input arguments');
end

if nargin==1;
  temp = varargin{1};
  incl = temp.include(:,1)';
  axisscale = temp.axisscale{1,1};
  if isempty(axisscale);
    varargin = {temp.data(incl{:})};
  else
    varargin = {axisscale(incl{1}) temp.data(incl{:})};
    if ~all(diff(varargin{1})>0) & ~all(diff(varargin{1})<0)
      varargin{end+1} = '.';
    end
  end
else
  use = 1:length(varargin{1});
  for j=1:nargin;
    if isa(varargin{j},'dataset')
      incl = varargin{j}.include';
      use = intersect(use,incl{1});
      varargin{j} = varargin{j}.data;
    else
      if size(varargin{j},1)==1;
        varargin{j} = varargin{j}';
      end
      use = intersect(use,1:length(varargin{j}));
    end
  end
  %now, shrink all data down 
  for j=1:nargin;
    varargin{j} = varargin{j}(use,:);
  end
end

try
  if nargout==0
    plot(varargin{:});
  else
    [varargout{1:nargout}] = plot(varargin{:});
  end
catch
  error(lasterr)
end

%--------------------------------------------------
function updatetoolbar(mydata,target,parent)

if ~isempty(findobj(target,'tag','trendlink_toolbar')) & strcmp(getappdata(target,'datatype'),mydata.type)
  return; %no update needed
end
setappdata(target,'datatype',mydata.type);

%update toolbar
btnlist = {
  'save'      'savemarkers' 'trendlink(''saveas'');'  'enable' 'Save trend results'   'off' 'push'
  'plot'      'spawnplot' 'trendlink(''spawnplot'');' 'enable' 'Spawn results plot'   'off' 'push'
  };
if ~strcmp(mydata.type,'image')
  %non-image data, add standard buttons
  btnlist = [btnlist
    {'xselect'   'select'  'trendlink(gcbf,''select'')'  'enable' 'Select range'         'on' 'push'}
    ];
else
  %image data, add special buttons
  btnlist = [btnlist
    {
    'Select'   'select'  'trendlink(gcbf,''select'')'  'enable' 'Select pixels'      'on' 'push'
    'autoscale' 'autocontrastbtn' 'trendlink(gcbf,''autocontrast'')'  'enable' 'Autocontrast image'   'on' 'toggle'
    'waterfall' 'surfview' 'trendlink(gcbf,''surface'')'  'enable' 'Plot as Surface On/Off'   'on' 'toggle'
    'minus'     'interpminus' 'trendtool(''interpolationminus'',getappdata(gcbf,''TrendLinkParent''))' 'enable' 'Decrease Interpolation' 'on' 'push'
    'plus'      'interpplus' 'trendtool(''interpolationplus'',getappdata(gcbf,''TrendLinkParent''))' 'enable' 'Increase Interpolation' 'off' 'push'
    }
    ];
  if length(mydata.imagesize)>2 & evriio('mia')
    %3D (or higher order) image? add yet more buttons
    btnlist = [btnlist
      {
      'map3d'     'surfaceviewer'    'surfaceviewer(trendlink(''retrieve''));'      'enable' 'View 3D Surface Image'        'on' 'push'
      }
      ];
  end
end
toolbar(target,'',btnlist,'trendlink_toolbar');
