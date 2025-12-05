function varargout = plotgui_plotscatter(targfig,mydataset,options)
%PLOTGUI_PLOTSCATTER scatter plot of dataset object

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%BK 6/9/2016 bugfix: can now plot Mean+StdDev, even when first few samples are all NaNs.

if nargin==1 && ischar(targfig)
  options = plotgui('options');
  if nargout==0; evriio(mfilename,targfig,options); else; varargout{1} = evriio(mfilename,targfig,options); end
  return; 
end

if nargin<3;
  options = plotgui_plotscatter('options');
  options.plotby = 0;
  options.axismenuindex = {[1] [1] [0]};
  options.axismenuvalues = {[1] 'Data' []};
end

plotby   = min(ndims(mydataset),max(0,options.plotby));
plottype = options.plottype;

viewclassset = min([options.viewclassset size(mydataset.class,2)]);

selection       = options.selection;
selectioncolor  = options.selectioncolor;
selectionmarker = options.selectionmarker;

reversexaxis = false;

%assure selectioncolor is only three elements and 0-1
if length(selectioncolor)~=3; selectioncolor(3)= 0; end
selectioncolor = selectioncolor(1:3);
selectioncolor = min(max(selectioncolor,0),1);

if isempty(mydataset) | ~isa(mydataset,'dataset') | isempty(mydataset.data); return; end   %don't do anything if no data

%we could just refer to mydataset.data but we use an assignment here
% in case we decide to make some other changes such as compression
data = mydataset.data;

if isempty(selection); selection = cell(1,ndims(data)); end

for k=1:ndims(data);
  includ{k} = mydataset.includ{k};        %extract list of included elements
  exclud{k} = 1:size(mydataset.data,k);   %make list of all elements
  exclud{k}(includ{k}) = [];              %excluded = dump included elements
end

actualplotby = plotby;
if actualplotby == 0;
  %special PlotBy mode (Data, Mean, etc.)
  ind1 = 0;
  ind2 = 1;
  ind3 = 0;
  plotvs = options.axismenuindex{1}+1;
  plotby = 2-plotvs+1;     %2=>1 1=>2
  if plotby < 1; plotby = 1; end
  thisselection = selection{plotvs};

  mode = options.axismenuvalues{2};
  if isempty(mode)
    switch options.axismenuindex{2}
      case 2
        mode = 'Mean';
      case 3
        mode = 'StdDev';
      case 4
        mode = 'Mean+StdDev';
      case 5
        mode = 'Number Missing';
      case 6
        mode = 'Minimum';
      case 7
        mode = 'Maximum';
      otherwise %1 or not specified
        mode = 'Data';
    end
  end
  
  %get x-axis vector
  xdata = mydataset.axisscale{plotvs};
  if isempty(xdata);
    xdata = 1:size(data,plotvs);
  end
  xdata = shiftdim(xdata);    %make interesting dim the FIRST one
  
  if options.axisautoinvert>0
    reversexaxis = all(diff(xdata)<0);
  else
    reversexaxis = options.axisautoinvert;
  end
else
  % plotby > 0  i.e. PlotBy some actual mode

  if ~iscell(options.axismenuindex);
    error('This figure did not initialize correctly. Please close it and try again.');
  end
  [ind1,ind2,ind3] = deal(options.axismenuindex{:});

  plotvs = 2-plotby+1;              %what is the "other" primary dim, that is our reference for lengths, etc.
  if plotvs < 1; plotvs = 1; end
  thisselection = selection{plotvs};    %grab the relevent "selected" list

end

%if getappdata(targfig,'densityforce') & ind1>0
%  plotgui_plotimage(targfig,mydataset,options);
%  return;
%end

%get class vectors
classes = mydataset.class{plotvs,viewclassset};
classlookup = mydataset.classlookup{plotvs,viewclassset};
classname = mydataset.classname{plotvs,viewclassset};

if options.viewclasses && length(unique(classes))>options.maxclassview
  %Check to make sure max classes not violated.
  options.viewclasses = 0;
  evritip('plotgui_maxclassview')
end

if ~isempty(classes) & all(classes == 0); 
  classes = []; 
end

classes_plotby = mydataset.class{plotby,viewclassset};
classlookup_plotby = mydataset.classlookup{plotby,viewclassset};
classname_plotby = mydataset.classname{plotby,viewclassset};

if ~isempty(classes_plotby) & all(classes_plotby == 0); 
  classes_plotby = []; 
end

viewclasses = options.viewclasses & ~isempty(classes);
%viewplotbyclasses = options.viewclasses & isempty(classes) & ~isempty(classes_plotby);

viewplotbyclasses = 0;
if options.viewclasses & ~isempty(classes_plotby) 
  %If plot classes turned on and the plotby (other mode) class exists then
  %test for empty class or if user wants the other mode.
  userclassmode = getappdata(targfig,'classmodeuser');
  if isempty(classes) | (~isempty(userclassmode) & userclassmode==plotby) 
    viewplotbyclasses = 1;
  end
end

if viewplotbyclasses
  %if using plotby classes, remember THAT classname
  classname = classname_plotby;
end

cax = [];
colorby = false;
cblbls = '';
if ~viewclasses & isfield(options,'colorby') & ~isempty(options.colorby)
  if iscell(options.colorby)
    %extract appropriate cell based on plotby
    if actualplotby>0 & length(options.colorby)>=actualplotby
      options.colorby = options.colorby{actualplotby};
    else
      options.colorby = [];
    end
  end
  if ndims(mydataset)>2
    %do NOT try colorby with n-way
    options.colorby = [];
  end
  
  %Add check to see if colorby is a vector and if data is square. If square
  %then use perference to decide. NOTE: Original code had "points" as the
  %default but this was changed to "lines" based on Neal suggestion (from
  %helpdesk). 
  data_size = size(mydataset);
  plotbypoints = false;
  plotbylines = false;
  if any(size(options.colorby)==1)
    if ndims(mydataset)<3 && data_size(1)==data_size(2) && ~isempty(options.colorby)
      %Square data, use preference to plot. 
      if strcmpi(options.colorbydirection,'points')
        plotbypoints = true;
      else
        plotbylines = true;
      end
    else
      %Infer colorby direction from size-match to data.
      if length(options.colorby)==size(mydataset,plotvs)
        plotbypoints = true;
      elseif length(options.colorby)==size(mydataset,plotby)
        plotbylines = true;
      end
    end
  end
  
  if plotbypoints %any(size(options.colorby)==1) & length(options.colorby)==size(mydataset,plotvs);
    %colorby a vector that matches the points
    classes = options.colorby(:)';  %must be row vector
    viewclasses = true;
    colorby = true;
    cblbls = '';
  elseif plotbylines %any(size(options.colorby)==1) & length(options.colorby)==size(mydataset,plotby);
    %colorby a vector that matches the lines
    classes_plotby = options.colorby(:)';  %must be row vector
    viewplotbyclasses = true;
    colorby = true;
    cblbls = '';
    if isempty(options.classcolormode)
      options.classcolormode = 'figure';
    end
  else
    if iscell(options.colorby)
      if iscell(options.colorby{1}) & isshareddata(options.colorby{1}{1})
        % { shareddata , dim , index }
        options.colorby = options.colorby{1};
        if isvalid(options.colorby{1})
          classes = nindex(options.colorby{1}.object.data,options.colorby{2:3});
          cblbls = options.colorby{1}.object.label{options.colorby{3}};
          if ~isempty(cblbls)
            cblbls = cblbls(options.colorby{2},:);
          end
          viewclasses = true;
          colorby = true;
        else
          viewclasses = false;
        end
      else
        viewclasses = false;
      end
    elseif numel(options.colorby)==1 & options.colorby<=size(mydataset,plotby) & options.colorby>=1;
      % scalar value within limits of data in plotby dimension
      classes = nindex(mydataset.data,floor(options.colorby),plotby);
      %add one hidden object to show name of colorby
      cblbls = mydataset.label{plotby};
      if ~isempty(cblbls)
        cblbls = cblbls(floor(options.colorby),:);
      end
      classes = classes(:)';  %must be row vector
      viewclasses = true;
      colorby = true;
    else
      %ignore colorby...
      viewclasses = false;
    end
  end
  if viewclasses
    %special processing of classes for colorby
    cax = [min(classes) max(classes)];
    if any(classes<0) & ~colorby
      classes = classes-min(classes)+1;   %set lowest value to 1 for positive colors
    end
    classlookup = {};

    if isempty(options.classsymbol)
      options.classsymbol = 'o';
    end
    if isempty(options.classcolormode)
      options.classcolormode = 'figure';
    end
    options.classfacecolor = false;  %do NOT change face color separate from edge color
    classname = '';  %and do NOT use classname stored earlier
  end
end
%store classname in case we need it to find class symbols when plotting classes
options.classname = classname;

otheraxes = {};
otheraxesnames = {};
if actualplotby == 0;
  %special PlotBy mode (Data, Mean, etc.)
  asimage = options.asimage;

  if ((ndims(data)<3) & ~options.viewexcludeddata);
    %devise substructure to pull out only the data we should be using for calcs.
    sub = cell(1,ndims(data));
    for k = 1:ndims(data);
      if (k ~= plotvs | (ndims(data)>2 & strcmp(mode,'Data')));    %unless our plotvs dim  (or multi-dim Data mode)
        sub(k) = includ(k);    %selected points only
      else
        sub(k) = {':'};        %"everything" for plotvs subscript (or when view excluded data is on)
      end
      if isempty(sub{k});       %nothing in this dim?
        sub = [];
        break                   %don't allow subsref...
      end
      if k==plotby & ~isempty(classes_plotby);  %trim classes if necessary
        classes_plotby = classes_plotby(includ{k});
      end
    end
    if ~isempty(sub);
      if ndims(data)<3 | ~strcmp(mode,'Data');
        S1 = substruct('()',sub);
        ydata = subsref(data,S1);
      else
        ydata = uint8(zeros(size(data)));
        subsasgn(ydata,substruct('()',sub),subsref(data,substruct('()',sub)));
      end
    else
      ydata = [];
    end
  else
    ydata = data;
  end

  %figure out what symbols to use
  if length(xdata) > 25 | ndims(ydata)>2;
    linestyle = '-';
  else
    if plotvs == 1;
      linestyle = '+-';
    else
      linestyle = 'o-';
    end
  end
  markerstyle = [];

  defaultlinestyle = linestyle;     %note what we WOULD have done if it weren't for the options
  if ~isempty(options.linestyle); 
    linestyle = options.linestyle;     %get linestyle if not in automatic mode
  end
  if isempty(selectionmarker); selectionmarker = 'o'; end

  mind = [];
  if ~isempty(ydata);
    switch mode
      case {'Mean','StdDev','Minimum','Maximum'}
        ydata = shiftdim(ydata,plotvs-1);
        if viewplotbyclasses
          [what,where1,where2] = unique(classes_plotby);
          tags = {};
          tempy = [];
          for j=1:length(what);
            if (isempty(classlookup_plotby))
              match = false;
            else
              match = min(find([classlookup_plotby{:,1}]==what(j)));
            end
            if any(match)
              lbl = classlookup_plotby{match,2};
            else
              lbl = sprintf('Class %i',what(j));
            end
            switch mode
              case 'Mean'
                if ndims(ydata)==2 & any(~isfinite(ydata(:)));
                  [junk,mn] = mncn(nindex(ydata,where2==j,2)',struct('matrix_threshold',1,'column_threshold',1));
                  mn = mn(:);
                else
                  mn = mean(nindex(ydata,where2==j,2),2);
                end
                tempy = cat(2,tempy,squeeze(mn));
                tags{j,1} = sprintf('%s Mean',lbl);
              case 'StdDev'
                if ndims(ydata)==2 & any(~isfinite(ydata(:)));
                  [junk,junk,sd] = auto(nindex(ydata,where2==j,2)',struct('matrix_threshold',1,'column_threshold',1));
                  sd = sd(:);
                else
                  sd = std(double(nindex(ydata,where2==j,2)),0,2);
                end
                tempy = cat(2,tempy,squeeze(sd));
                tags{j,1} = sprintf('%s Standard Deviation',lbl);
              case {'Minimum' 'Maximum'}
                mydata = ydata;
                switch mode
                  case 'Minimum'
                    mydata(~isfinite(ydata(:))) = inf;
                    mn = min(nindex(mydata,where2==j,2),[],2);
                  case 'Maximum'
                    mydata(~isfinite(ydata(:))) = -inf;
                    mn = max(nindex(mydata,where2==j,2),[],2);
                end
                tempy = cat(2,tempy,squeeze(mn));
                tags{j,1} = sprintf('%s %s',lbl,mode);
            end
          end
          ydata = tempy;
          classes_plotby = what;
        else
          switch mode
            case 'Mean'
              if ndims(ydata)==2 & any(~isfinite(ydata(:)));
                [junk,mn] = mncn(ydata',struct('matrix_threshold',1,'column_threshold',1));
                mn = mn';
              else
                mn = mean(ydata,2);
              end
              ydata = squeeze(mn);
              tags = 'Data Mean';
            case 'StdDev'
              if ndims(ydata)==2 & any(~isfinite(ydata(:)));
                [junk,junk,sd] = auto(ydata',struct('matrix_threshold',1,'column_threshold',1));
                sd = sd';
              else
                sd = std(double(ydata),0,2);
              end
              ydata = squeeze(sd);
              tags = 'Data Standard Deviation';
            case {'Minimum' 'Maximum'}
              switch mode
                case 'Minimum'
                  ydata(~isfinite(ydata(:))) = inf;
                  mn = min(ydata,[],2);
                case 'Maximum'
                  ydata(~isfinite(ydata(:))) = -inf;
                  mn = max(ydata,[],2);
              end
              ydata = squeeze(mn);
              tags = mode;
          end
        end
        
      case 'Data'
        %check for too many items to plot
        permitted = options.maximumdatasummary;
        sz        = size(ydata,plotby);
        if sz > permitted;
          items       = [1:sz];
          items       = items(fix(1:(sz/permitted):sz));
          ydata       = nindex(ydata,items,plotby);
          if ~isempty(classes_plotby);
            classes_plotby = classes_plotby(items);
          end
          noticehandle = plotgui('showtempnotice',targfig,'Some data not shown... (click to show all)','datasum');
          set(noticehandle,'buttondownfcn',@setmaxdatasummary);
        else
          items = [];
        end
        if islogical(ydata);
          ydata = double(ydata);
        end;
        ydata = shiftdim(ydata,plotvs-1);
        tags   = 'Data';
        
        lbls = mydataset.label{plotby,options.viewlabelset};
        if isempty(lbls);
          %no labels? default values here
          switch plotby
            case 1
              modelbl = 'Row';
            case 2
              modelbl = 'Column';
            case 3
              modelbl = 'Slab';
            otherwise
              modelbl = sprintf('Mode %i index',plotby);
          end
          lbls = [repmat([modelbl ' '],size(mydataset,plotby),1) num2str([1:size(mydataset,plotby)]')];
        else
          if ~strcmpi(options.labelwithnumber,'off')
            lbls = [lbls '('*ones(size(mydataset,plotby),1) num2str([1:size(mydataset,plotby)]') ')'*ones(size(mydataset,plotby),1)];
          end
        end
        if ((ndims(data)<3) && ~options.viewexcludeddata)
          lbls = lbls(mydataset.include{plotby},:);
          mind = mydataset.include{plotby};
          if ~isempty(items);
            mind = mind(items);
          end
        else
          mind = 1:size(ydata,2);
        end
        if ~isempty(items);
          lbls = lbls(items,:);
        end
        tags   = str2cell(lbls);
        actualplotby = plotby;  %fake this so we can do things like exclusions

      case 'Mean+StdDev'

        ydata = shiftdim(ydata,plotvs-1);
        if ~isempty(ydata);
          %m = mean(ydata,2);
          %s = std(double(ydata),0,2);
          [junk,m] = mncn(ydata',struct('matrix_threshold',1,'column_threshold',1));
          m=m';
          [junk,junk,s] = auto(ydata',struct('matrix_threshold',1,'column_threshold',1));
          s=s';
        else
          m = xdata*nan;
          s = xdata*nan;
        end
        if (~isempty(asimage) & plotvs==1)
          %if it is an image, only show mean and standard deviation as separate slabs
          ydata = [m s];
          classes_plotby = [2 3];
          viewplotbyclasses = 1;
          classlookup_plotby = {2 'Data Mean'; 3 '+/- Standard Deviation'};
          tags   = {'Data Mean';'Standard Deviation'};
        else
          %all other types of data, do mean and mean+/-std
          ydata = [m m+s m-s];
          classes_plotby = [2 3 3];
          viewplotbyclasses = 1;
          classlookup_plotby = {2 'Data Mean'; 3 '+/- Standard Deviation'};
          tags   = {'Data Mean';'Standard Deviation (+)';'Standard Deviation (-)'};
        end

      case 'Number Missing'
        ydata = shiftdim(ydata,plotvs-1);
        ydata = squeeze(sum(isnan(ydata),2));
        tags = 'Number of Missing Values';
        linestyle = 'o';

    end
  else
    ydata = xdata * nan;
    tags = {};
  end
  ind2        = 1:size(ydata,2);

  sz = size(ydata);
  if length(sz)>2 | (~isempty(asimage) & plotvs==1)
    if ~isempty(asimage) & exist('plotgui_plotimage') & options.viewdensity 
      %use image plotting functionality
      yimgdata = dataset(ydata);
      yimgdata.type = 'image';
      yimgdata.imagesize = asimage;
      yimgdata.imagemode = 1;
      yimgdata.imageaxisscale = mydataset.imageaxisscale;
      yimgdata = copydsfields(mydataset,yimgdata,{plotvs 1});  %copy over any image-mode information
      plotgui_plotimage(targfig,yimgdata,options)
      return
    else
      ydata = ydata(:,:);
    end
  end

else
  % plotby > 0  i.e. PlotBy some actual mode
  [numaxes,whichaxes] = plotgui('availableindicies',mydataset,plotby);
  if ind1 > 0;   %they have pointed at an actual row/column, get that data
    xdata = double(nindex(data,ind1,plotby));
    xdata = shiftdim(xdata,plotvs-1);    %make interesting dim the FIRST one
    linestyle = 'o';
    markerstyle = [];
  else     %generic sample/variable index
    xdata = [];
    axisscaleset = whichaxes(-ind1+1);  %figure out which axisscale set they want
    if ind1<=0 & ind1>=2-numaxes;
      xdata = mydataset.axisscale{plotvs,axisscaleset};
      if ~isempty(xdata) & options.axisautoinvert>0
        reversexaxis = all(diff(xdata)<0);
      else
        reversexaxis = options.axisautoinvert;
      end
      %Scott added || plotby==3 to the if below to fix issue with plotting
      %2D loadings surface with parafac reported to helpdesk. Otherwise
      %mode 2 is linear index. 
      if ndims(data)==3 || plotby==3
        for othermode = setdiff(1:ndims(data),[plotby,plotvs])
          otheraxes{end+1} = mydataset.axisscale{othermode,axisscaleset};
          otheraxesnames{end+1} = mydataset.axisscalename{othermode,axisscaleset};
          
          %Apply include to other modes.
          otheraxes{end}(exclud{othermode}) = nan;
        end
      end
    end
    if isempty(xdata);
      xdata = 1:size(data,plotvs);
    end
    xdata = shiftdim(xdata);    %make interesting dim the FIRST one
    if length(xdata) > 25;
      linestyle = '-';
      markerstyle = [];
    else
      if length(ind2) == 1 & ndims(mydataset)<3;
        linestyle = 'o-';
      else
        linestyle = '-o';
      end
      markerstyle = [];
    end
  end

  if ind3 > 0; linestyle = '.'; markerstyle = [];end    %special for 3d plots

  defaultlinestyle = linestyle;     %note what we WOULD have done if it weren't for the options
  if ~isempty(options.linestyle);     %get linestyle if not in automatic mode
    linestyle = options.linestyle;
    markerstyle = [];
  end

  if ind2 > 0;
    ydata = double(nindex(data,ind2,plotby));
    ydata = shiftdim(ydata,plotvs-1);    %make interesting dim the FIRST one
    if size(xdata,1)<numel(xdata) & length(ind2)>1   
      %was X a MATRIX? (e.g multiway) unfold both X and Y
      xdata = xdata(:);
      ydata = reshape(ydata,[size(xdata,1) numel(ydata)/size(xdata,1)]);
    end
  else
    axisscaleset = whichaxes(1-ind2);  %figure out which axisscale set they want
    if axisscaleset>0 & ind1<=0 & ind1>=2-numaxes;
      ydata = mydataset.axisscale{plotvs,axisscaleset};
    else
      ydata = [];
    end
    if isempty(ydata);
      ydata = 1:size(data,plotvs);
    end
    ydata = shiftdim(ydata);    %make interesting dim the FIRST one
  end

  tags = options.axismenuvalues;
  tags = deblank(tags{2});
  if ~iscell(tags); tags = {tags}; end

  sz = size(ydata);
  if prod(sz(2:end))>length(ind2);
    %combine tags with appropriate labels if we have more than one mode
    %being shown "folded" into the plot
    alllbls = [];
    for j=setdiff(1:ndims(data),[plotby plotvs]);
      lbls = mydataset.label{j};
      if isempty(lbls);
        %no labels? default values here
        switch j
          case 1
            modelbl = 'Row';
          case 2
            modelbl = 'Column';
          case 3
            modelbl = 'Slab';
          otherwise
            modelbl = sprintf('Mode %i index',j);
        end
        lbls = [repmat([modelbl ' '],size(mydataset,j),1) num2str([1:size(mydataset,j)]')];
      end
      if isempty(alllbls)
        alllbls = lbls;
      else
        alllbls = [repmat(alllbls,size(lbls,1),1) ' '*ones(size(alllbls,1)*size(lbls,1),1) lbls(repmat(1:size(lbls,1),size(alllbls,1),1),:)];
      end
    end
    temp = [];
    for k = 1:size(tags,1);
      temp = strvcat(temp,[repmat([tags{k} ' '],size(alllbls,1),1) alllbls]);
    end
    tags = str2cell(temp);
  end
  if length(sz)>2;
    %n-way? reshape to 2-way
    ydata = reshape(ydata,[sz(1) prod(sz(2:end))]);
  end
  xsz = size(xdata);
  if length(xsz)>2;
    %n-way? reshape to 2-way
    xdata = reshape(xdata,[xsz(1) prod(xsz(2:end))]);
  end

  mind = ind2;
end

% rng = 0; %.005;
% if rng>0
%   xdata = xdata+randn(size(xdata))*range(xdata(:))*rng;
%   ydata = ydata+randn(size(ydata))*range(ydata(:))*rng;
% end

%convert any "infs" into NaN
xdata(~isfinite(xdata)) = nan;

%interpret empty plottype
if isempty(plottype) 
  %check if we should use monotonic...
  finxdata = isfinite(xdata);
  dxdata   = diff(xdata(finxdata));  
  if any(size(xdata)==1) & options.automonotonic
    %xdata is a vector - do test
    steps    = find(dxdata<0);
    steps    = steps(:);
    sizes    = diff([steps;sum(finxdata)]);
  else
    %xdata is a matrix - do NOT test
    steps = [];
    sizes = [];
  end
  
  if ~isempty(steps) & min(sizes)>10
    % if any backwards steps AND the smallest forward going leg is >10 
    plottype = 'monotonic';
  elseif ~isempty(dxdata) & ~all(sign(dxdata)==sign(dxdata(1)))
    % if any opposite signed steps...
    plottype = 'scatter';
  else
    %look at axistype to decide plot type
    axistype = mydataset.axistype{plotvs};
    switch axistype
      %'discrete' 'stick' 'continuous' 'none'
      case 'none'
        %otherwiwse -> 'plot'  (i.e. treat as continuous)
        plottype = 'plot';
      case 'continuous'
        plottype = 'plot';
      case 'stick'
        plottype = 'stick';
      case 'discrete'
        plottype = 'scatter';
    end
  end
end

%check for new linestyle use as override for options setting
autolinestyle = linestyle; %note what we would use if the user doesn't override
linewidth = get(0,'defaultlinelinewidth');
if ~isempty(options.linewidth) & options.linewidth>0
  linewidth = options.linewidth;
end
symbolsize = get(0,'defaultlinemarkersize');
if ~isempty(options.symbolsize) & options.symbolsize>0
  symbolsize = options.symbolsize;
end
oldobjs = findobj(get(targfig,'CurrentAxes'),'userdata','data');
if ~isempty(oldobjs) & ~strcmpi(plottype,'line+points')
  ourlinestyle = getappdata(oldobjs(end),'linestyle');
  olddefault   = getappdata(oldobjs(end),'defaultlinestyle');
  oldlinewidth = getappdata(oldobjs(end),'linewidth');
  oldsymbolsize = getappdata(oldobjs(end),'symbolsize');
  if isempty(oldlinewidth); 
    oldlinewidth = linewidth; 
  else
    linewidth = oldlinewidth;  %store old linewidth as default (unless we detect a change below)
  end
  for lind = 1:length(oldobjs);
    oldobj = oldobjs(lind);
    if strcmp(get(oldobj,'type'),'line');
      usermarker      = get(oldobj,'marker');
      userlinestyle   = get(oldobj,'linestyle');
      userlinewidth   = get(oldobj,'linewidth');
      usersymbolsize  = get(oldobj,'markersize');
      preselectlw     = getappdata(oldobj,'preselectlinewidth');
      if ~isempty(preselectlw);
        userlinewidth = preselectlw;
      end
      if strcmp(userlinestyle,'none');
        userlinestyle = '';
      end
      if ~strcmp(usermarker,'none');
        userlinestyle   = [usermarker(1) userlinestyle];
      end
      if ~isempty(userlinestyle) & strcmp(defaultlinestyle,olddefault) & ~strcmp(userlinestyle,ourlinestyle)
        linestyle = userlinestyle;
      end
      if any(linestyle=='-') & strcmp(defaultlinestyle,olddefault) & (userlinewidth~=oldlinewidth)
        linewidth = userlinewidth;
      end
      if ~isempty(oldsymbolsize) & usersymbolsize~=oldsymbolsize
        symbolsize = usersymbolsize;
      end
    end
  end
end

if strcmp(plottype,'line')||strcmp(plottype,'line+points')
  linestyle = '-';
end
if ~any(linestyle=='-') %if not explitly doing a line, make width small
  linewidth = 0.5;
end

%If ydata columns do NOT equal length of otheraxes{1} (probably due to mroe
%than one y-item selected) then CLEAR otheraxes and otheraxesnames (so we
%don't use them or labels) NOTE: also see similar code in plotguitypes.
if ~isempty(otheraxes) & size(ydata,2)~=length(otheraxes{1})
  otheraxes{1} = [];
  otheraxesnames{1} = '';
end

%--- Got the data (from whatever source) do the plotting

%Handle excluded indices for x and y (z handled below)
xcomp = [];
if ~options.viewexcludeddata;
  xdata(exclud{plotvs}) = nan;    %make excluded items NAN
  ydata = nassign(ydata,nan,exclud{plotvs},1);

  % compress axis down (when exclusions exist and options set to do so)
  if ind1<=0 & options.viewcompressgaps
    if ~isempty(exclud{plotvs})
      xcomp = xdata(includ{plotvs});
      temp = nan(size(xdata));  %start with NaN's for everything
      [junk,order] = sort(xdata);
      v = 1:length(includ{plotvs});  %get index vector
      if sign(mean(diff(xdata(includ{plotvs}))))==-1 %flip vector direction if original x-axis was decreasing
        v = fliplr(v);
        xcomp = flipud(xcomp(:));
      end        
      temp(includ{plotvs}) = v;  %insert in place of included x-values
      xdata = temp;
    end
  end
end

%do data scaling if requested
setappdata(gca,'zeros',0);
if options.autoscale | options.autooffset | options.viewautocontrast

  if options.viewautocontrast
    %treat autocontrast like autoscale when here
    options.autoscale = 1;
  end
  if options.autooffset
    options.autoscaleorder = inf;
  end
  
  %correct for sub-window (if specified)
  rng = includ{plotvs};
  if ~isempty(options.autoscalewindow)
    win = [];
    if iscell(options.autoscalewindow)
      if length(options.autoscalewindow)>=plotvs
        win = options.autoscalewindow{plotvs};
      end
    else
      win = options.autoscalewindow;
    end
    if ~isempty(win);
      temp = intersect(rng,win);
      if ~isempty(temp)
        rng = temp;
      end
    end
  end
  toscale = nindex(ydata,rng,1);  %extract data to scale by

  %calculate maximum value (for scale)
  if options.autoscalebaseline | options.autooffset;
    mn = min(toscale,[],1);
  else
    mn = zeros(1,size(toscale,2));
  end
  switch options.autoscaleorder
    case inf
      mx = max(toscale,[],1);
    case 1  %1-norm
      toscale = abs(toscale);
      if any(any(isnan(toscale)))
        [junk,mx] = mncn(toscale,struct('matrix_threshold',1,'column_threshold',1));
      else
        mx = mean(toscale,1);
      end
      mx = mx*size(toscale,1);
    otherwise  %n-norm
      toscale = abs(toscale);
      toscale = toscale.^options.autoscaleorder;
      if any(any(isnan(toscale)))
        [junk,mx] = mncn(toscale,struct('maxtrix_threshold',1,'column_threshold',1));
      else
        mx = mean(toscale,1);
      end
      mx = mx*size(toscale,1);
      mx = real((mx).^(1/options.autoscaleorder));
  end
  mx((mx-mn)==0) = inf;  %fix divide by zero

  %do scaling and subtraction
  ydata = (ydata-ones(size(ydata,1),1)*mn)./(ones(size(ydata,1),1)*(mx-mn));
  
  if options.autooffset
    %doing auto-offset? offset data now

    %save zero points to show hlines at appropriate places
    mns = mn./(mx-mn);  %scaled minimum (to re-offset again)
    setappdata(gca,'zeros',(1:length(mns))-mns-1);
    
    %offset individual plots
    ydata = ydata+ones(size(ydata,1),1)*((1:size(ydata,2))-1);
  end
end

%get current view position (we'll check if 3d later)
%Also get current colormap, it will get reset to default when plot command
%is run. 
cur_cmap = [];
if ~isempty(get(targfig,'CurrentAxes'));
  [az,el] = view;
  %note whether previous view was 3D or not (critical to make sure we don't
  %auto-rotate a 3D view that the user manually rotated down to 2D)
  was3d = getappdata(gca,'was3d');
  if isempty(was3d); was3d = false; end
  setappdata(gca,'was3d',plotguitypes(plottype,'is3d'))
  
  %Get current colormap. 
  cur_cmap = colormap(get(targfig,'currentaxes'));
else  %no previous axes?
  was3d = false;
  az = 0; el = 90;    %fake a 2D position
end

if isempty(ind3) | ind3 == 0;   %2D plot?

  if (az~=0 | el ~=90); setappdata(targfig,'viewgrid',[]); end  %clear grid status if switching from 3D to 2D

  %Plot data first
  hold off
  h = plotguitypes(plotguitypes(plottype,'baseplot'),xdata,ydata,linestyle,otheraxes,options.autooffset);
  setappdata(h(1),'linestyle',autolinestyle);
  setappdata(h(1),'defaultlinestyle',defaultlinestyle);
  setappdata(h(1),'linewidth',linewidth);
  setappdata(h(1),'symbolsize',symbolsize);
  set(h,'linewidth',linewidth);
  set(h,'markersize',symbolsize);
  set(h,'userdata','data')
  
  if ~isempty(cur_cmap)
    %Restore colormap after plot command.
    colormap(get(targfig,'currentaxes'),cur_cmap)
  end
  
  hold on
  if ~iscell(tags); tags = {tags}; end
  if length(tags)~=length(h) & ~isempty(tags)
    %multiway data creates more objects than we have tags so duplicate
    %tags as necessary
    expand = ones(fix(length(h)/length(tags)),1)*[1:length(tags)];
    tags = tags(expand(:));
    if length(tags)~=length(h);
      tags(end+1:length(h)) = {' '};
    end
  end
  legendname(h,tags);
  indexinfo(h,mind,actualplotby);
  if ~ismember(plottype,{'plot' 'line' 'scatter' });
    %plottype is a special plot mode that requires an "overplot" of another
    %type (one that can't be selected against)    
    tohide = plotguitypes(plottype,'tohide');
    set(h,tohide{:},'handlevisibility','off');      %hide original data (but leave, it is our selection base)
    hvis = plotguitypes(plottype,xdata,ydata,linestyle,otheraxes,options.autooffset);
    if ~isempty(hvis) & isprop(hvis(1),'markersize'); set(hvis,'markersize',symbolsize); end
    if ~isempty(hvis) & isprop(hvis(1),'linewidth'); set(hvis,'linewidth',linewidth); end
    try
      legendname(hvis,tags);
    catch
      %couldn't tag them?
    end
  end

  if viewclasses | viewplotbyclasses
    %if need to add a colorby label object, do it now
    if viewclasses    %View Classes
      if ~viewplotbyclasses & (~options.viewclassesasoverlay | strcmp(get(h,'linestyle'),'none'))
        set(h,'linestyle','none','marker','none','handlevisibility','off');      %hide original data (but leave, it is our selection base)
      end
      ixdata = xdata;
      if options.viewexcludeddata;
        ixdata(exclud{plotvs}) = NaN;    %make excluded items NaN
      end
      h = plotclasses(targfig,ixdata,ydata,classes,classlookup,options);
      if checkmlversion('>=','7');
        tags = get(h,'DisplayName');
      else
        tags = get(h,'tag');
      end
      if ~iscell(tags); tags = {tags}; end
    end
    if viewplotbyclasses    %View Classes (other mode)
      if ~colorby
        %actual view classes?
        uniqueclasses = orderclasses(classes_plotby);
      else
        %color by? use different logic
        [classes_plotby,uniqueclasses,classlookup_plotby,options] = getcolorbybins(classes_plotby,options);
      end
      clrs = colorbycolors(uniqueclasses,targfig,options);
      myclim = [min(uniqueclasses) max(uniqueclasses)];
      if myclim(1)==myclim(2)
        delta = myclim(1)*.01;
        if delta==0
          delta = 1;
        end
        myclim = [-delta +delta]+myclim(1);
      end
      set(gca,'clim',sort(myclim))
      temp = classes_plotby(ind2);
      for j = 1:length(uniqueclasses);
        hsubset = h(temp==uniqueclasses(j));
        if ~isempty(hsubset)
          setcolor(hsubset,clrs(mod((j-1),size(clrs,1))+1,:));
          
          match = 0;
          %add appropriate legend to the FIRST line in this set
          if ~isempty(classlookup_plotby)
            %Sometimes classlookup comes back empty from getcolorbybins so
            %add check. Rasmus bug report.
            match = min(find([classlookup_plotby{:,1}]==uniqueclasses(j)));
          end
          
          if any(match)
            lbl = classlookup_plotby{match,2};
          elseif ~colorby
            lbl = sprintf('Class %i',uniqueclasses(j));
          else
            lbl = sprintf('%g',uniqueclasses(j));
          end
          if checkmlversion('<','7')
            set(hsubset,'tag',lbl);
          else
            set(hsubset,'displayname',lbl);
          end
          set(hsubset(2:end),'handlevisibility','callback');  %make all other lines "invisible" to the legend
        end
        
      end
    end
  elseif ~isempty(markerstyle);     %special markers on top of line?
    h = plotguitypes(plotguitypes(plottype,'overlayas'),xdata,ydata,markerstyle,otheraxes,options.autooffset);
    if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
    legendname(h,tags);
    indexinfo(h,mind,actualplotby);
  elseif size(ydata,2)>1 & ~all(sign(diff(xdata(isfinite(xdata))))>0) & ~all(sign(diff(xdata(isfinite(xdata))))<0);   %multiple ys and all xs are NOT increaseing or decreasing
    if options.usespecialmarkers;
      %the following code uses different symbols for individual ys (if xs are scattered)
      h=plotclasses(targfig,reshape(xdata*ones(1,size(ydata,2)),prod(size(ydata)),1),ydata(:),reshape(ones(size(ydata,1),1)*[0:size(ydata,2)-1],prod(size(ydata)),1),{},options);
      legendname(h,tags);
      indexinfo(h,mind,actualplotby);
      set(h,'markersize',4);
    end
  end

  %Plot Excluded data (if requested)
  if options.viewexcludeddata;
    for k=1:length(tags);
      excltags{k,1} = [tags{k} ' (Excluded)'];
    end

    ixdata = xdata;
    ixdata(includ{plotvs}) = NaN;    %make included items NaN
    if ~all(all(isnan(ixdata)))
      if viewclasses    %View Classes
        ixdata(thisselection)      = NaN;    %make selected items NaN
        h = plotclasses(targfig,ixdata,ydata,classes,classlookup,options);
        if options.connectclasses & size(h,2) ~= size(excltags,1)
          %plotting connect classes, need to fix excltags so the legend
          %is correct
          excltags = unique(excltags,'stable');
        end
        dimmarkers(h);
        legendname(h,excltags);
        indexinfo(h,mind,actualplotby);
      else
        h = plotguitypes(plottype,ixdata,ydata,linestyle,otheraxes,options.autooffset);
        if ~isempty(h) & isprop(h(1),'linewidth'); set(h,'linewidth',linewidth); end
        if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
        if viewplotbyclasses    %View Classes (other mode)
          uniqueclasses = orderclasses(classes_plotby);
          clrs = colorbycolors(uniqueclasses,targfig,options);
          temp = classes_plotby(ind2);
          for j = 1:length(uniqueclasses);
            setcolor(h(temp==uniqueclasses(j)),clrs(mod((j-1),size(clrs,1))+1,:));
          end
        end
        dimmarkers(h);
        legendname(h,excltags);
        indexinfo(h,mind,actualplotby);
        if ~isempty(markerstyle);     %special markers on top of line?
          h = plotguitypes(plottype,ixdata,ydata,markerstyle,otheraxes,options.autooffset);
          if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
          dimmarkers(h);
          legendname(h,excltags);
          indexinfo(h,mind,actualplotby);
        elseif size(ydata,2)>1 & ~all(sign(diff(xdata))>0) & ~all(sign(diff(xdata))<0);   %multiple ys and all xs are NOT increaseing or decreasing
          if options.usespecialmarkers;
            %the following code uses different symbols for individual ys (if xs are scattered)
            h=plotclasses(targfig,reshape(ixdata*ones(1,size(ydata,2)),prod(size(ydata)),1),ydata(:),reshape(ones(size(ydata,1),1)*[0:size(ydata,2)-1],prod(size(ydata)),1),{},options);
            if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
            dimmarkers(h);
            legendname(h,excltags);
            indexinfo(h,mind,actualplotby);
          end
        end
      end
    end

  end

  %Plot selected points
  if ~options.noselect
    ixdata = xdata * NaN;
    ixdata(thisselection) = xdata(thisselection);   %make all, but selected, = NaN
    ixdata(exclud{plotvs}) = NaN;   %make excluded items NaN
    if viewclasses %View Classes
      if ~colorby
        h = plotclasses(targfig,ixdata,ydata,classes,classlookup,options);
      else
        h = plotclasses(targfig,ixdata,ydata,classes.*0+1,classlookup,options);
      end
      setcolor(h,selectioncolor,selectioncolor*.7);   %make outline of selected objects different
    else
      if isempty(selectionmarker); selectionmarker = 'o'; end
      h = plotguitypes(plotguitypes(plottype,'overlayas'),ixdata,ydata,selectionmarker,otheraxes,options.autooffset);
      set(h,plotguitypes(plottype,'color'),selectioncolor,plotguitypes(plottype,'markerfacecolor'),selectioncolor.*.7);   %make selected objects different color
      if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
      if ~isempty(h) & isprop(h(1),'linewidth'); set(h,'linewidth',linewidth); end
    end
    setappdatas(h,'selectionmask',includ{plotvs}); %save which indicies are shown here
    set(h,'tag','selection');
    if ~isempty(h)
      setappdata(h(1),'realxdata',xdata);
      setappdata(h(1),'selectionmode',plotvs)
    end
    
    if all(isnan(ixdata))
      set(h,'handlevisibility','off');
    end

    if ~colorby
      excltags = tags;
      for k=1:length(tags);
        excltags{k,1} = [tags{k} ' (Selected)'];
      end
    else
      excltags = {'(Selected)'};
    end
    legendname(h,excltags);
    indexinfo(h,mind,actualplotby);

    %plot selected, excluded points
    if options.viewexcludeddata & ~isempty(exclud{plotvs})
      ixdata = xdata * NaN;
      ixdata(thisselection) = xdata(thisselection);   %make all, but selected, = NaN
      ixdata(includ{plotvs}) = NaN;   %make included items NaN
      
      if viewclasses    %View Classes
        h = plotclasses(targfig,ixdata,ydata,classes,classlookup,options);
        setcolor(h,selectioncolor,selectioncolor*.7);   %make outline of selected objects different
      else
        if isempty(selectionmarker); selectionmarker = 'o'; end
        h = plotguitypes(plotguitypes(plottype,'overlayas'),ixdata,ydata,selectionmarker,otheraxes,options.autooffset);
        if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
        if ~isempty(h) & isprop(h(1),'linewidth'); set(h,'linewidth',linewidth); end
        setcolor(h,selectioncolor);   %make selected objects different color
      end
      setappdatas(h,'selectionmask',exclud{plotvs}); %save which indicies are shown here
      set(h,'tag','selection');
      if all(isnan(ixdata))
        set(h,'handlevisibility','off');
      end
      dimmarkers(h);
      for k=1:length(tags);
        excltags{k,1} = [tags{k} ' (Excluded, Selected)'];
      end
      legendname(h,excltags);
      indexinfo(h,mind,actualplotby);
      
    end

  end

  %connect specified items with lines
  if ~isempty(options.connectitems)
    %if a cell (like Select) pull out appropriate cell item
    if iscell(options.connectitems)
      if length(options.connectitems)>=plotvs
        options.connectitems = options.connectitems{plotvs};
      end
    end
    
    options.connectitems = intersect(options.connectitems,1:length(xdata));
    ixdata = xdata * NaN;
    ixdata(options.connectitems) = xdata(options.connectitems);   %make all, but selected, = NaN
    if ~options.viewexcludeddata;      %no excluded data
      ixdata(exclud{plotvs}) = NaN;   %make excluded items NaN
    end

    if ~all(all(isnan(ixdata)))
      style = options.connectitemsstyle;
      if isempty(style);
        style = 'r-';
      end
      linewidth = options.connectitemslinewidth;
      if isempty(linewidth);
        linewidth = 2;
      end
      h = plotguitypes(plotguitypes(plottype,'overlayas'),ixdata(~isnan(ixdata)),ydata(~isnan(ixdata),:),style,otheraxes,options.autooffset);
      if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
      if ~isempty(h) & isprop(h(1),'linewidth'); set(h,'linewidth',linewidth); end
      set(h,'tag','connected');
      excltags = {};
      legendname(h,'connected');

      %add head to connected points
      validpts = find(isfinite(ixdata));      
      hold on; 
      h = plot(ixdata([max(validpts)]),ydata([max(validpts)],:),'ro');
      set(h,'MarkerFaceColor',[0 .56 0]); 
      hold off;
      set(h,'tag','connected');
      legendname(h,'last connected');
    end
  end
  
  %check x-scale
  ax = axis;
  if ind1 <= 0 & ~strcmp(plottype,'bar')
    %x-scale should be tight to data
    axnew = [min(xdata(:)) max(xdata(:)) ax(3:end)];
  else
    %scatter plot? use Matlab scale
    axnew = ax;
  end
  if axnew(3) == axnew(4);
    axnew(3) = axnew(3)-.5;
    axnew(4) = axnew(4)+.5;
  end
  if isnan(axnew(1)); axnew(1) = ax(1); end
  if isnan(axnew(2)); axnew(2) = ax(2); end
  if axnew(2)==axnew(1);
    axnew(1) = axnew(1)-.5;
    axnew(2) = axnew(2)+.5;
  end
  axis(axnew);
  hold off

  %restore old view (if not 2D)
  if plotguitypes(plottype,'is3d')
    if (az ~= 0 | el ~= 90)  %if was rotated, re-rotate now
      view([az,el]);
    elseif ~was3d   %if last view wasn't 3D, rotate this down (default view for 3D plots)
      view([-15 52]);
    end
%     if checkmlversion('<=','7.6')
%       set(get(targfig,'CurrentAxes'),'PlotBoxAspectRatioMode','manual','CameraViewAngleMode','manual','DataAspectRatioMode','manual')
%     end
  end

else      %3D Plot

  %Extract third dim of data
  zdata = double(nindex(data,ind3,plotby));

  %Handle excluded indices for z
  if ~options.viewexcludeddata;
    zdata(exclud{plotvs}) = nan;    %make excluded items NAN
  end

  %Do the plot

  %first plot all data (except excluded, if not requested)
  % This object will be used to select objects, if needed.
  ixdata = xdata;
  if ~options.viewexcludeddata;
    ixdata(exclud{plotvs}) = NaN;     %hide excluded data
  end

  %adjust symbol size for 3D plots
  symbolsize = symbolsize;%*3; %Scott remove *3 per request from  boss.
  
  linestyle(strfind(linestyle,'.-')) = [];
  linestyle(linestyle=='-') = [];
  linestyle(linestyle==':') = [];
  if isempty(linestyle)
    linestyle = '.'; 
  end
  h = plot3(ixdata,ydata,zdata,linestyle);
  
  if options.viewlegend3dhandlevis
    set(h,'handlevisibility','off')
  end
  
  tags = options.axismenuvalues;
  tags = deblank(tags{2});
  if ~iscell(tags); tags = {tags}; end
  set(h,{'tag'},tags);
  if checkmlversion('>=','7')
    set(h,{'displayname'},tags);
  end

  set(h,'userdata','data');
  set(h,'marker','none','linestyle','none');    %and make it invisible
  
  if ~isempty(cur_cmap)
    %Restore colormap after plot command.
    colormap(get(targfig,'currentaxes'),cur_cmap)
  end
  
  hold on

  %next, plot included, non-selected data
  ixdata = xdata;
  ixdata(exclud{plotvs}) = NaN;     %hide excluded data
  ixdata(thisselection)      = NaN;     %hide selected data
  if viewclasses    %View Classes
    plotclasses(targfig,ixdata,ydata,zdata,classes,classlookup,options);
  else    %just plot normally (but exclude nans to save memory)
    h = plot3(ixdata(find(~isnan(ixdata))),ydata(find(~isnan(ixdata))),zdata(find(~isnan(ixdata))),linestyle);
    set(h,'markersize',symbolsize);
  end

  %now, excluded data
  if options.viewexcludeddata & ~isempty(exclud{plotvs});
    ixdata = xdata;
    ixdata(includ{plotvs}) = NaN;     %hide included data
    ixdata(thisselection)      = NaN;     %hide selected data
    if viewclasses    %View Classes
      h = plotclasses(targfig,ixdata,ydata,zdata,classes,classlookup,options);
      if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
    else    %just plot normally (but exclude nans to save memory)
      h = plot3(ixdata(find(~isnan(ixdata))),ydata(find(~isnan(ixdata))),zdata(find(~isnan(ixdata))),linestyle);
      if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
      if ~isempty(h) & isprop(h(1),'linewidth'); set(h,'linewidth',linewidth); end
    end
    dimmarkers(h,2);
  end

  %now, selected data
  notselected = 1:length(xdata);  %list of all data
  notselected(thisselection) = [];    %remove selected ones from list

  ixdata = xdata;
  ixdata(notselected)      = NaN;     %hide non-selected data
  ixdata(exclud{plotvs})   = NaN;     %hide excluded data
  if isempty(selectionmarker); selectionmarker = '.'; end   %if nothing else set yet, use this marker
  if viewclasses    %View Classes
    h = plotclasses(targfig,ixdata,ydata,zdata,classes,classlookup,options);
    if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
    setcolor(h,selectioncolor,selectioncolor*.7);     %make selected objects different color
  else       %just plot normally (but exclude nans to save memory)
    h = plot3(ixdata((~isnan(ixdata))),ydata((~isnan(ixdata))),zdata((~isnan(ixdata))),selectionmarker);
    if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
    setcolor(h,selectioncolor);     %make selected objects different color
  end
  set(h,'tag','selection');
  if all(isnan(ixdata))
    set(h,'handlevisibility','off');
  end

  %and selected, excluded data
  if options.viewexcludeddata & ~isempty(exclud{plotvs})
    ixdata = xdata;
    ixdata(notselected)      = NaN;     %hide non-selected data
    ixdata(includ{plotvs})   = NaN;     %hide included data
    if isempty(selectionmarker); selectionmarker = '.'; end   %if nothing else set yet, use this marker
    if viewclasses    %View Classes
      h = plotclasses(targfig,ixdata,ydata,zdata,classes,classlookup,options);
      if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
      setcolor(h,selectioncolor,selectioncolor*.7);     %make selected objects different color
    else      %just plot normally (but exclude nans to save memory)
      h = plot3(ixdata(find(~isnan(ixdata))),ydata(find(~isnan(ixdata))),zdata(find(~isnan(ixdata))),selectionmarker);
      if ~isempty(h) & isprop(h(1),'markersize'); set(h,'markersize',symbolsize); end
      setcolor(h,selectioncolor);     %make selected objects different color
    end
    set(h,'tag','selection');
    if all(isnan(ixdata))
      set(h,'handlevisibility','off');
    end
    dimmarkers(h,2);
  end

  hold off
  axismenuvalues = options.axismenuvalues;
  zlabel(deblank(axismenuvalues{3}));

  if az ~= 0 | el ~= 90; view([az,el]); end    %restore old view (if not 2D)
  %commenting out to fix issue in 2021b
  %set(get(targfig,'CurrentAxes'),'PlotBoxAspectRatioMode','manual','CameraViewAngleMode','manual','DataAspectRatioMode','manual')
end

if reversexaxis
  xdir = 'reverse';
else
  xdir = 'normal';
end
set(get(targfig,'CurrentAxes'),'xdir',xdir)
setappdata(get(targfig,'CurrentAxes'),'auto_reverse_xdir',reversexaxis)

%label the plot (x and y axes)
axismenuvalues = options.axismenuvalues;
xlabel(deblank(axismenuvalues{1}));
tags = deblank(axismenuvalues{2});
if ~iscell(tags); tags = {tags}; end
lblname = mydataset.labelname{plotby};
if length(tags)<=3;
  if ~isempty(lblname)
    lblname = [lblname ' : '];
  end
  lblname = [lblname sprintf('%s, ',tags{1:end-1}) tags{end}];
end
if plotguitypes(plottype,'is3d')
  h = zlabel(lblname);
  if ~isempty(otheraxesnames);
    ylabel(otheraxesnames{1});
  end
else
  h = ylabel(lblname);
end
set(h,'buttondownfcn','try;axes(get(gcbo,''parent''));legend off; legend show;end');

if options.autooffset
  %hide labels if autooffset is on (they are meaningless)
  set(gca,'yticklabel','');
end

if ~isempty(xcomp)
  xticks = get(gca,'xTick');
  xticks((xticks<1) | (xticks>length(xcomp)) | (xticks~=fix(xticks))) = []; %drop invalid items
  set(gca,'xtickmode','manual','xtick',xticks,'xticklabel',num2str(xcomp(xticks)))
end

%label the points as requested
if options.viewnumbers | options.viewlabels | options.viewaxisscale
  if ind3 == 0;   %2D plot?
    zdata = [];
  end
  h = plotlabels(targfig,xdata,ydata,zdata,mydataset.label(plotvs,:),mydataset.axisscale(plotvs,:),thisselection,options);
end

if ~isempty(cax)
  if all(cax==cax(1))
    cax = cax(1)+[-.5 .5];
  end
  caxis(cax);
end

%get all axes positions
allaxh = findobj(targfig,'type','axes','tag','');
axpos = get(allaxh,'position');
if iscell(axpos)
  axpos = cat(1,axpos{:});
end
if ndims(mydataset)==2 | ~plotguitypes(plottype,'is3d')
  ttl = mydataset.title{plotvs};
else
  %n-D data with 3D visualization means no label shown - so give it in
  %title
  ttl = lblname;
end
if ~isempty(ttl);
  %look if this axes is the one "top" axes in the figure
  mypos = get(gca,'position');
  if sum(mypos(2)==axpos(:,2))==1 & mypos(2)==max(axpos(:,2));
    title(deblank(ttl));
  end
end

%look if all axes have the same x-label and HIDE all but the bottom ones
if length(allaxh)>1
  lh = get(allaxh,'xlabel');
  lh = [lh{:}];
  xlbl = get(lh,'string');
  if all(ismember(xlbl,{xlbl{end} ''}))
    vis = 'off';
  else
    vis = 'on';
  end
  set(lh(axpos(:,2)>min(axpos(:,2))),'visible',vis);
end

axm = plotguitypes(plottype,'axismodes');
if ~isempty(axm);
  axis(axm{:});
end

%------------------------------------------------------
function handles = plotclasses(targfig,xdata,ydata,zdata,class,classlookup,options)
%PLOTCLASSES plots provided data using class symbols
%NOTE: may come in as:
%    (targfig,xdata,ydata,zdata,class      ,classlookup,options)
% or (targfig,xdata,ydata,class,classlookup,options            )

if nargin==6 & isstruct(classlookup);
  %no zdata passed
  options = classlookup;
  classlookup = class;
  class = zdata;
  zdata = [];
end

%check x-data for being a ROW vector
if size(xdata,1)==1; xdata = xdata'; end  %make sure it is a column vector

if isempty(class);    %class is empty? fake it so we can show something
  class = ones(size(xdata));
  classlookup = {};
end

if ~isempty(options.colorby) & ~options.viewclasses
  %do not allow > options.colorbybins classes for colorby (which doesn't use symbols or face
  %color)
  if ~options.viewexcludeddata
    nans = isnan(xdata) | any(isnan(ydata),2);
    class(nans) = nan;
  end

  [class,classes,classlookup,options] = getcolorbybins(class,options);

else
  %non-colorby classing, use standard class assignment/ordering logic
  classes = orderclasses(class);
end

%get symbol basis
csymbol = options.classsymbol;
autosymbols = false;
setname = '';
markersize = {};
userdefinedclasscolors = [];
if any(ismember(csymbol,{'','auto'}));
  %automatic symbols using classmarker sets
  autosymbols = true;
  symbolset   = options.symbolset;
  if ischar(symbolset)
    %string - get actual class markers
    if isempty(symbolset) & isfield(options,'classname')
      symbolset = options.classname;
    end      
    setname   = symbolset;
    symbolset = classmarkers(symbolset);
  end
  markers = {symbolset.marker};
  markersize = {symbolset.size};
  if options.classcoloruser
    %User can override class colors.
    userdefinedclasscolors = getplspref('classcolors','userdefined');
  end
  
else
  if ~iscell(csymbol);
    csymbol = {csymbol};%change to cell so code works below.
  end
  markers = csymbol;
end

%get color basis
if ~autosymbols
  if any(strcmp(options.classcolormode,{'','auto'}))
    if length(classes)<64 & (length(markers)>1 & options.classfacecolor)
      colors = {[.25 .25 .25] [1 0 0] [0 .7 0] [0 0 1] [0 .9 .9] [1 1 1]};
    elseif length(classes)<=size(classcolors,1)
      colors = classcolors;
      colors = colors(1:length(classes),:);  %keep only those we need
    else
      n = length(classes);
      colors = jet(n);
      ind = []; ind(1:2:n) = 1:ceil(n/2); ind(2:2:n) = ceil(n/2)+1:n;
      colors = colors(ind,:);
    end
  else
    %not "auto" color mode?
    if strcmp(options.classcolormode,'figure')
      %"figure" color mode says take the colormap from the current figure and
      %use it (if it is sufficient)
      if checkmlversion('<','8.4')
        colors = get(targfig,'colormap');
      else
        colors = colormap(get(targfig,'currentaxes'));
      end
      
      if size(colors,1)~=length(classes);
        colors = interp1(1:size(colors,1),colors,linspace(1,size(colors,1),length(classes)));
      end
    else
      %we were given a color map name to use
      try
        colors = feval(options.classcolormode,length(classes));
      catch
        colors = [];
      end
    end
    if ~iscell(colors) & size(colors,2)~=3;
      %colors are uninterpretable as colors? use jet colorscale
      n = length(classes);
      colors = jet(n);
      ind = []; ind(1:2:n) = 1:ceil(n/2); ind(2:2:n) = ceil(n/2)+1:n;
      colors = colors(ind,:);
    end
  end
  if ~autosymbols & ~iscell(colors)
    %convert colors to cell array (for ease of indexing)
    try
      colors = mat2cell(colors,ones(1,length(classes)),3);
    catch
    end
  end
end
handles = [];

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%do plotting
if size(ydata,1) ~= length(xdata); ydata = ydata'; end
curLink = plotgui('getlink', targfig);
if strcmpi(curLink.properties.itemType, 'biplot') && ~options.connectclasses && ...
    curLink.properties.loadingsToOrigin
    % special case => biplot without connected classes
    % temporarily set connectclasses to true to enter next if block
    % and set method to "biplotVarLines"
    options.connectclasses = 1;
    options.connectclassmethod = 'biplotVarLines';
end
  for k = 1:length(classes)
    ind = find(class == classes(k)); %Create index of class member position.
    if ~isempty(ind);
      %Create unique style for each class.
      mymarker = rem(k-1,length(markers) ) + 1;
      
      if isempty(zdata);
        %---- 2D plots ----
        h = plot(xdata(ind,:),ydata(ind,:),markers{mymarker});%Handle for 2d.
        if ~any(isfinite(xdata(ind,:)))
          set(h,'handlevisibility','off'); %hide in legend if empty
        end
        setappdatas(h,'subindex',ind);  %save which indicies this class used
        if ~isempty(options.classsymbolsize)
          %specified general marker size
          set(h,'markersize',options.classsymbolsize);  
        elseif length(markersize)>=mymarker & ~isempty(markersize{mymarker})
          %optional size specified by symbolset
          set(h,'markersize',markersize{mymarker})
        elseif options.autosizemarkers
          %automatic sizing
          minsz = 4;
          maxsz = 8;
          pix2size = 55;  % number of pixels per change in unit of size
          u = get(gca,'units'); 
          set(gca,'units','pixels'); 
          p = get(gca,'position');
          set(gca,'units',u)
          s = min(max(round(min(p(3:4))/pix2size),minsz),maxsz);
          set(h,'markersize',s);
        end

        if options.connectclasses & classes(k)~=0
          for ycol = 1:size(ydata,2);
            
            use = ind(~isnan(xdata(ind)) & ~any(isnan(ydata(ind,ycol)),2));
            try
              method = options.connectclassmethod;
              if strcmpi(method,'pca') & (length(use)<=3 | rank([xdata(use,:) ydata(use,ycol)])<2)
                method = 'connect';
              end
              if strcmpi(method,'outline') & length(use)<3
                method = 'connect';
              end
              if ~isempty(use) & (isempty(options.connectclassitems) || ismember(classes(k),options.connectclassitems))
                %if all classes are being done (or this specific class is
                %listed as one to do)
                switch method
                  case 'delaunay'
                    TRI = delaunay(xdata(use),ydata(use,ycol));
                    h = [h;triplot(TRI,xdata(use),ydata(use,ycol))];
                  case 'outline'
                    outeruse=convhull(xdata(use),ydata(use,ycol));
                    h = [h;plot(xdata(use(outeruse)),ydata(use(outeruse),ycol),'-')];
                  case 'pca'
                    cl = {options.connectclasslimit};
                    h = [h;subgroupcl([xdata(use,:) ydata(use,ycol)],cl{:})];
                  case 'sequence'
                    h = [h;plot(xdata(use),ydata(use,ycol),'-')];
                  case 'biplotVarLines'
                    lu = cat(2, classlookup{:,1}) == classes(k);
                    curClass = classlookup{lu, 2};
                    if regexpi(curClass, 'loadings')
                        av = [0 0];
                        ilvx = [av(1)*ones(1, length(use));xdata(use)'];
                        ilvx = ilvx(:);
                        ilvy = [av(2)*ones(1,length(use));ydata(use, ycol)'];
                        ilvy = ilvy(:);
                        h = [h;plot(ilvx, ilvy, '-')];
                    end
                  case 'spider'
                    av = [mean(xdata(use)) mean(ydata(use,ycol))];
                    ilvx = [av(1)*ones(1,length(use));xdata(use)'];
                    ilvx = ilvx(:);
                    ilvy = [av(2)*ones(1,length(use));ydata(use,ycol)'];
                    ilvy = ilvy(:);
                    h = [h;plot(ilvx,ilvy,'-')];
                  case 'means'
                    [junk,junk,xgrp] = unique(xdata(use));
                    xgrp = xgrp(:)';
                    for gi=1:max(xgrp)
                      gruse = use(xgrp==gi);  %use for this x group
                      %                     for yi=1:size(ydata,2);
                      %get mean for each group and y value
                      ydata(gruse,ycol) = mean(ydata(gruse,ycol));
                      %                     end
                    end
                    [sxdata,order] = sort(xdata(use));
                    sydata = ydata(use(order),ycol);
                    h = [h;plot(sxdata,sydata,'-')];
                    
                  otherwise  %usually 'connect' but also the default if not recognized
                    h = [h;plot(xdata(use([1:end 1])),ydata(use([1:end 1]),ycol),'-')];
                end
                uistack(h(2:end),'bottom');
              end
            catch
            end
          end
        end
      else
        %---- 3D plots ----
        h = plot3(xdata(ind),ydata(ind),zdata(ind),markers{mymarker});%Handle for 3d
        if ~any(isfinite(xdata(ind,:)))
          set(h,'handlevisibility','off'); %hide in legend if empty
        end
        setappdatas(h,'subindex',ind);  %save which indicies this class used
        if ~isempty(options.classsymbolsize)
          %specified general marker size
          set(h,'markersize',options.classsymbolsize);  
        elseif length(markersize)>=mymarker & ~isempty(markersize{mymarker})
          %optional size specified by symbolset
          set(h,'markersize',markersize{mymarker})
        end
        if options.connectclasses & classes(k)~=0
          use = ind(~isnan(xdata(ind)) & ~any(isnan(ydata(ind,:)),2) & ~isnan(zdata(ind)));
          try
            if length(use)<=3 | rank([xdata(use,:) ydata(use,:) zdata(use,:)])<2
              method = 'connect';
            else
              method = options.connectclassmethod;
            end
            if isempty(options.connectclassitems) || ismember(classes(k),options.connectclassitems)
              %if all classes are being done (or this specific class is
              %listed as one to do)
              switch method
                case 'pca'
                  cl = {options.connectclasslimit};
                  h = [h;subgroupcl([xdata(use,:) ydata(use,:) zdata(use,:)],cl{:})];
                case 'sequence'
                  h = [h;plot3(xdata(use),ydata(use,:),zdata(use),'-')];
                case 'spider'
                  av = [mean(xdata(use)) mean(ydata(use)) mean(zdata(use))];
                  ilvx = [av(1)*ones(1,length(use));xdata(use)'];
                  ilvx = ilvx(:);
                  ilvy = [av(2)*ones(1,length(use));ydata(use)'];
                  ilvy = ilvy(:);
                  ilvz = [av(3)*ones(1,length(use));zdata(use)'];
                  ilvz = ilvz(:);
                  h = [h;plot3(ilvx,ilvy,ilvz,'-')];
                case 'biplotVarLines'
                  lu = cat(2, classlookup{:,1}) == classes(k);
                  curClass = classlookup{lu, 2};
                  if regexpi(curClass, 'loadings')
                    av = [0 0 0];
                    ilvx = [av(1)*ones(1, length(use));xdata(use)'];
                    ilvx = ilvx(:);
                    ilvy = [av(2)*ones(1,length(use));ydata(use)'];
                    ilvy = ilvy(:);
                    ilvz = [av(3)*ones(1,length(use));zdata(use)'];
                    ilvz = ilvz(:);
                    h = [h;plot3(ilvx,ilvy,ilvz,'-')];
                  end
                otherwise  %usually 'connect' but also the default if not recognized
                  h = [h;plot3(xdata(use([1:end 1])),ydata(use([1:end 1])),zdata(use([1:end 1])),'-')];
              end
              uistack(h(2:end),'bottom');
            end
          catch
          end
        end
      end
      hold on
      
      %set colors (and sizes)
      if autosymbols
        symbolindex = (rem(k-1,size(symbolset,1)  ) + 1);
        mycolor  = symbolset(symbolindex).edgecolor;
        myface   = symbolset(symbolindex).facecolor;
        try
          %Use 'try' here because this is a new feature being introduced
          %close to release. If it fails then old behavior will continue to
          %work. See classcolors.m (userdefined) for more info.
          if ~isempty(userdefinedclasscolors)
            myface = userdefinedclasscolors(symbolindex,:);
            mycolor = myface;
          end
        end
        
        if isempty(myface)
          myface = [1 1 1];
        end
        if isempty(mycolor)
          mycolor = myface;
        end
        if all(mycolor==[1 1 1]) & all(myface==[1 1 1])
          %all white? make black outline
          mycolor = [0 0 0];
        end
      elseif options.classfacecolor
        mycolor  = colors{rem(k-1,length(colors)-1) + 1};
        myface   = colors{rem(k-1,length(colors)  ) + 1};
      else
        mycolor  = colors{rem(k-1,length(colors)  ) + 1};
        myface   = mycolor;
      end
      for hind = 1:length(h);
        if isprop(h(hind),'color')
          set(h(hind),'color',mycolor,'markerfacecolor',myface);  %Set color and face for h.
        elseif isprop(h(hind),'EdgeColor')
          set(h(hind),'edgecolor',mycolor,'facecolor',myface);  %Set color and face for h.
        end
        setappdata(h(hind),'autosymbol',k);
        setappdata(h(hind),'classset',classes(k));
        setappdata(h(hind),'symbolset',setname);
        if hind>1
          set(h(hind),'handlevisibility','off'); %hide multiple lines in legend
        end
      end
      
      tag = '';
      if ~isempty(options.colorby) & isempty(classlookup)
        tag = sprintf('%g',classes(k));
      else
        if ~isempty(classlookup);
          lu = cat(2,classlookup{:,1})==classes(k);
          if any(lu)
            tag = classlookup{lu,2};
          end
        end
        if isempty(tag)
          tag = ['Class ' sprintf('%g',classes(k))];   %Set tag of line to 'Class #'
        end
      end
      if checkmlversion('<','7')
        set(h,'tag',tag);
      else
        set(h,'displayname',tag);
      end
      handles(end+1:end+length(h)) = h;%Add handle to handles variable.
    end
  end
  if strcmpi(options.connectclassmethod, 'biplotVarLines')
    options.connectclasses = 0;
    options.connectmethod = 'pca';
  end
  

if nargout == 0;
  clear handles
end

%------------------------------------------------------
function [class,classes,classlookup,options] = getcolorbybins(class,options)
%special handling of scales for when doing colorby
%Outputs are: 
%   class       : the individual class values for each sample (adjusted to
%                  match the bins output by "classes") 
%   classes     : the unique class values (bin values)
%   classlookup : the classes and human-readable names to use in a lookup
%                 table or legend
%   options     : options structure (possibly modified if options were
%                 missing)

if ~isfield(options,'colorbyscale')
  options.colorbyscale = 'linear';
end
if ~isfield(options,'colorbybins')
  options.colorbybins = 20;
end
if strcmp(options.colorbyscale,'nonlinear')
  %non-linear mapping into color space.
  [classes,i,j] = unique(class);
  %If class has NaN values (because of excluded data) then unique treats
  %NaN as unique values so we need to set to zero to get correct answer
  %from unique function. We also have to handle the "j" part of the unique
  %assignment, with modification later too.
  classes(isnan(classes)) = [];
  classnan    = isnan(class);
  j(classnan) = 1;  %temporarily set the NaN's to group 1 (so they don't throw errors beacuse there is no class to contain them)
  
  sc         = max(1,(length(classes)-1)/(options.colorbybins-1));
  ind        = round(1:sc:length(classes));
  if sc>1;
    classlookup = [mat2cell(classes(ind)',ones(length(ind),1),1) str2cell(sprintf('%g-%g\n',[classes([ind]);classes([ind(2:end)-1 end])]))];
    class       = classes(round(round((j-1)/sc)*sc+1));  %bin class into nearest group based on # in each group
    class(classnan) = nan;   %now, reset the NaN's back to NaN
    classes    = classes(ind);
  else
    classlookup = {};
  end
else
  %linear mapping
  [hy,classes] = hist(class,options.colorbybins);
  if all(isnan(classes))
    classes = 1:length(hy);
  end
  midpoints    = mean([classes(1:end-1); classes(2:end)]);
  classlookup  = [mat2cell(classes',ones(length(classes),1),1) str2cell(sprintf('%g-%g\n',[min(class) midpoints; midpoints max(class)]))];
  class        = interp1([-1e15 classes 1e15],[-1e15 classes 1e15],class,'nearest');
end

%------------------------------------------------------
function dimmarkers(handles,factor)
%DIMMARKERS dims markers to indicate that they are excluded

if nargin < 2;
  factor = 1;
end

%settings for excluded points
invmask = [0 0 0];
dimmask = [1 1 1];

for h = handles(:)';
  switch get(h,'type');
    case {'patch'};
      if isa(get(h,'facecolor'),'double');
        set(h,'facecolor',abs(invmask-get(h,'facecolor'))*dimfact+(dimmask.*(1-dimfact)));   %dim markers
      end
      set(h,'markeredgecolor','none');
    case {'hggroup'}
      try
        set(h,'edgecolor','none');
      end
      try
        set(h,'linecolor',[.8 .8 .8])
      end
      try
        set(h,'facecolor',[.8 .8 .8]);
      end
    case {'surface'}
      edgecolor = get(h,'edgecolor');
      if ischar(edgecolor);
        edgecolor = [.8 .8 .8];
      else
        edgecolor = 1-((1-edgecolor).*.5);
      end
      facecolor = get(h,'facecolor');
      if ischar(facecolor);
        facecolor = [.8 .8 .8];
      else
        facecolor = 1-((1-facecolor).*.5);
      end
      set(h,'edgecolor',edgecolor);
      set(h,'facecolor',facecolor);
    otherwise
      if isprop(h,'markerfacecolor') & isa(get(h,'markerfacecolor'),'double');
        dimfact = .4 * factor;
        set(h,'markerfacecolor',abs(invmask-get(h,'markerfacecolor'))*dimfact+(dimmask.*(1-dimfact)));   %dim markers
      else
        dimfact = .2 * factor;
      end
      if isprop(h,'color')
        set(h,'color',abs(invmask-get(h,'color'))*dimfact+(dimmask.*(1-dimfact)));   %dim markers
      end
  end
end

%------------------------------------------------------
function setcolor(handles,color,facecolor)
%SETCOLOR sets color on objects with sensitivity to what the object is

if nargin < 3;
  facecolor = 1-((1-color)*.5);
end

%settings for excluded points
for h = handles(:)';
  for p = {'color' 'edgecolor'}
    if isprop(h,p{:})
      set(h,p{:},color);
      break;
    end
  end
  if ~isempty(facecolor) 
    for p = {'markerfacecolor' 'facecolor'}
      if isprop(h,p{:}) & strcmp(class(get(h,p{:})),class(facecolor))
        set(h,p{:},facecolor)
        break;
      end
    end
  end
end

%------------------------------------------------------
function colors = colorbycolors(classes,targfig,options)

if any(strcmp(options.classcolormode,{'','auto'}))
  if length(classes)<=size(classcolors,1)
    colors = classcolors;
    colors = colors(1:length(classes),:);  %keep only those we need
  else
    n = length(classes);
    colors = jet(n);
    ind = []; ind(1:2:n) = 1:ceil(n/2); ind(2:2:n) = ceil(n/2)+1:n;
    colors = colors(ind,:);
  end
else
  %not "auto" color mode?
  if strcmp(options.classcolormode,'figure')
    %"figure" color mode says take the colormap from the current figure and
    %use it (if it is sufficient)
    if checkmlversion('>=','8.4')
      axh = get(targfig,'currentaxes');
      colors = colormap(axh);
    else
      %Prior to ML 2014b the figure colormap was updated.
      colors = get(targfig,'colormap');
    end
    if size(colors,1)~=length(classes);
      colors = interp1(1:size(colors,1),colors,linspace(1,size(colors,1),length(classes)));
    end
  else
    %we were given a color map name to use
    try
      colors = feval(options.classcolormode,length(classes));
    catch
      colors = [];
    end
  end
  if ~iscell(colors) & size(colors,2)~=3;
    %colors are uninterpretable as colors? use jet colorscale
    n = length(classes);
    colors = jet(n);
    ind = []; ind(1:2:n) = 1:ceil(n/2); ind(2:2:n) = ceil(n/2)+1:n;
    colors = colors(ind,:);
  end
end
if iscell(colors)
  %convert colors to numerical array (for ease of indexing)
  colors = cat(1,colors{:});
end


%------------------------------------------------------
function h = plotlabels(targfig,xdata,ydata,zdata,labels,axisscale,selection,options)
%PLOTLABELS puts labels (and/or numbers) at given points

viewnumbers   = options.viewnumbers;
viewlabels    = options.viewlabels;
viewaxisscale = options.viewaxisscale;
c = cell(length(xdata),1);

if viewlabels
  if length(labels)>=options.viewlabelset
    labels = labels{options.viewlabelset};
  else
    labels = '';
    viewlabels = false;
  end
end
if viewaxisscale
  if length(axisscale)>=options.viewaxisscaleset
    axisscale = axisscale{options.viewaxisscaleset};
  else
    viewaxisscale = false;
  end
end
if ~viewnumbers & ~viewaxisscale & ~viewlabels
  %nothing to view (because sets didn't exist or were empty)
  h = [];
  return;  %exit now
end

%if labelselected is 0 (false) or there no selection, label all points
%  otherwise label only selected ones
if isempty(selection) | ~options.labelselected | all(isnan(xdata(selection)))
  selection = 1:length(xdata);
end

%adjust label positions if plottype is one of the unusual types
yoffset = 0;
xoffset = 0;
if ismember(lower(char(options.plottype)),{'stick','bar','stem'})
  axh = get(targfig,'currentaxes');
  yax  = get(axh,'ylim');
  xax  = get(axh,'xlim');
  yoffset = (yax(2)-yax(1))*.02;
  xoffset = 0;  %always zero unless we decide to use this later
  if options.viewlabelangle>=180 %| options.viewlabelangle==0
    if isempty(options.viewlabelmaxy) | options.viewlabelmaxy<0
      options.viewlabelmaxy = min([options.viewlabelmaxy max(0,min(yax))]);
    end
    yoffset = -(options.viewlabelangle~=270)*yoffset;
    set(axh,'xticklabel',{' '});
  else
    if isempty(options.viewlabelminy) | options.viewlabelminy>0
      options.viewlabelminy = max([options.viewlabelminy min(0,max(yax))]);
    end      
    yoffset = (options.viewlabelangle~=90)*yoffset;
  end
  
end

%limit position based on min and max values in options
if ~isempty(options.viewlabelminy)
  ydata = max(ydata,options.viewlabelminy);
end
if ~isempty(options.viewlabelmaxy)
  ydata = min(ydata,options.viewlabelmaxy);
end
ydata = ydata+yoffset;
xdata = xdata+xoffset;

if size(xdata,1) == 1 & size(ydata,2)==size(xdata,2);    %transpose to column vectors if needed
  xdata = xdata';
  ydata = ydata';
end

use = false(1,length(xdata));
use(selection(:)') = true;
for ci = selection(:)';
  if ~isfinite(xdata(ci)) | ~any(isfinite(ydata(ci,:))) | (~isempty(zdata) & ~isfinite(zdata(ci)));
    use(ci) = 0;
  else
    thisitem = '';
    if viewnumbers
      thisitem = [thisitem sprintf('%g,',ci)];
    end
    if viewlabels & ~isempty(labels);
      thislbl = trim(labels(ci,:));
      if ~isempty(thislbl)
        thisitem = [thisitem thislbl ','];
      end
    end
    if viewaxisscale & ~isempty(axisscale)
      thisitem = [thisitem sprintf('%g,',axisscale(ci))];
    end
    if ~isempty(thisitem)
      thisitem(end) = []; %drop ending ,
      c{ci} = [ones(1,options.viewlabelprespace).*' ' thisitem];
    else
      use(ci) = 1;
    end
  end
end
labely = max(ydata,[],2); %ydata(:,1);

%drop items not marked as "use"
xdata  = xdata(use);
labely = labely(use);
c      = c(use);

%Absolute limit for number of labels displayed. 14B and newer can get
%bogged down from too many labels. Causes Matlab unreponsive.
if isempty(zdata) & ~isempty(options.viewmaxlabelcount)
  lbllgth = length(xdata);
  if lbllgth>options.viewmaxlabelcount
    lblspc = unique(round(linspace(1,lbllgth,options.viewmaxlabelcount)));
    xdata = xdata(lblspc);
    labely = labely(lblspc);
    c = c(lblspc);
  end
end

%do plot
if isempty(zdata);   %2D plot?
  h = text(xdata,labely,c);    %2D labels
  set(h,'userdata','label','uicontextmenu',plotgui('labelmenu',targfig),'fontsize',getdefaultfontsize);
else
  zdata = zdata(use);  %drop z items not "used"
  h = text(xdata,labely,zdata,c);    %3D labels
  set(h,'userdata','label','uicontextmenu',plotgui('labelmenu',targfig),'fontsize',getdefaultfontsize);
end
if (length(h) <= options.viewlabelmoveobjectthreshold)
  moveobj('on',h);
else
  evritip('plotgui_maxlabelmoveobj');
end

%----------------------------------------------------
function st = trim(st)
%EVRI version of strtrim (not available until 7.0)

notspace = find(~isspace(st));
st = st(min(notspace):max(notspace));

%----------------------------------------------------
function indexinfo(h,ind,mode)
% Store index information in appdata of objects

if length(ind)~=length(h) | mode==0
  return
end
for j=1:length(h);
  setappdata(h(j),'mode',mode)
  setappdata(h(j),'index',ind(j))
end

%---------------------------------------------------
function setmaxdatasummary(varargin)

targfig = gcbf;
delete(gcbo);
drawnow;
plotgui('update','figure',targfig,'maximumdatasummary',inf);
