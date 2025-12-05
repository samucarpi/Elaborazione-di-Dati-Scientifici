function [bestuse,bestfit,bestlvs,intervals,intcv,intlv] = ipls(X,Y,int_width,maxlv,varargin);
%iPLS Interval PLS and forward/reverse MLR variable selection.
% Performs forward or reverse variable selection of variable windows based
% on the Cross-validation error (RMSECV) obtained for each individual
% window ("intervals") of variables. The interval which provides the lowest
% RMSECV is selected. Multiple windows can be selected iteratively by
% modifying the options.numintervals options. The "algorithm" option allows
% this function to behave as an iPLS or iPCR algorithm or a forward/reverse
% MLR variable selection algorithm. The default is PLS but
% options.algorithm = 'mlr' changes to MLR mode. See other options below.
%
% Inputs are (X,Y) the X and Y data, (int_width) the interval i.e. window
% width in variables and (maxlv) the maximum number of latent variables to
% use in any model (maxlv has no impact if options.algorithm = 'mlr').
% Note that excluding a variable in X will prevent it from being used in
% any model.
%
% The optional input (options) is a structure containing one or more of the
% following fields:
%
%   display       : [ 'off' | 'on' ] governs screen display
%   plots         : [ 'none' |{'final'}] governs plotting
%   mode     : [{'forward'} | 'reverse' ] Defines action to be performed
%               with each interval. 
%       'forward' mode: the RMSECV calculated for each interval represents
%           how well the y-block can be predicted using ONLY the variables
%           included in the interval.
%       'reverse' mode: the RMSECV calculated for each interval
%           represents how well the y-block can be predicted when the given
%           interval of variables are removed from the range of included X
%           variables. 
%        Note that excluding a variable in X will prevent it from being
%        used in any model.
%   algorithm : [ {'pls'} | 'pcr' | 'mlr' ] Defines regression algorithm to
%                use. Selection is done for the specific algorithm. Note
%                that when MLR is used, input (int_width) is most often = 1
%                (single variable per window). iPLSDA (discriminant
%                analysis) mode can be invoked by using algorithm='pls' and
%                passing a logical y-block (see class2logical).                
%   numintervals : {[1]} Number of intervals to select or remove. If
%               (num_intervals) is Inf, intervals are iteratively selected
%               and added/removed until no improvement in RMSECV is
%               observed. NOTE: this can also be set by passing as a scalar
%               value before, or in place of, the options structure. When
%               passed this way, any value passed in the options structure
%               will be ignored.
%   mustuse  : [] A vector of variable indices which MUST be used in all
%               models. These variables will always be included in any
%               model, whether or not they are included in the current
%               interval.
%   stepsize : [] Distance between interval centers. An empty matrix gives
%               the default spacing in which intervals do not overlap
%               (stepsize = int_width)
%   preprocessing : defines preprocessing and can be one of the following:
%        (a) One of the following strings:
%           'none'  : no preprocessing  {default}
%           'meancenter' : mean centering
%           'autoscale'  : autoscaling
%        (b) A single preprocessing structure defined using the function
%            preprocess. The same preprocessing structure will be used on both
%            the X and Y blocks.
%        (c) A cell containing two preprocessing structures {pre pre} one for
%            the X block and one for the Y block.
%   cvi : {'vet' [] 1} Three element cell indicating the cross-validation
%          leave-out settings to use {method splits iterations}. For valid
%          modes, see the "cvi" input to crossval. If splits (the second
%          element in the cell) is empty, the square root of the number of
%          samples will be used. cvi can also be a vector (non-cell) of
%          indices indicating leave-out groupings (see crossval for more
%          info).
%   plottype : [ 'bar' | {'patch'}] Governs type of plot to make. Bar plots
%          may not handle non-linear axisscales well, but allows for
%          backwards compatibility.
%
%OUTPUTS:
% When a single output is requested, the output is a structure with the
% following fields:
%  use       : the final selected indices which gave the best model, 
%  fit       : the RMSECV for the selected indicies
%  lvs       : the number of latent variables which gives the best fit
%  intervals : a matrix containing the indices used for each interval,
%  intcv     : the RMSECV in the last selection cycle for all intervals
%              (these values were used to select the last interval).
%  intlv     : the number of latent variables used in the model which gave
%               the RMSECV values returned in intcv.
%  figh      : figure handle of plot if options.plots = final. 
%
% Optionally, with multiple outputs, these variables will be returned as
% single outputs (not in structure format) in the order shown above except
% for figure handle, this is only ouput in the structure.
%
% If options.plots is 'final', a plot is given of the minimum RMSECV versus
% window center. Windows which were used are indicated in green, windows
% which were excluded are indicated in red. The number of latent variables
% (LVs) used to assess each interval (the model size that gives the
% indicated RMSECV) is shown at the bottom of each interval's bar, inside
% the axes.
% The best RMSECV that can be obtained using all intervals is shown as a
% dashed red line (all-interval RMSECV). The number of LVs used in this
% model is shown on the right of the axes. If this number of LVs
% (all-interval model) is different from the number used for the best model
% of the selected interval(s) (selected-interval model) then a dashed
% magenta line will indicate the RMSECV obtained when using all intervals
% but at the selected-interval model size. The mean sample is superimposed
% on the plot for reference. 
%
%I/O: results = ipls(X,Y,int_width,maxlv,options)
%I/O: results = ipls(X,Y,int_width,maxlv,numintervals,options)
%I/O: [use,fit,lvs,intervals,intcv,intlv] = ipls(X,Y,int_width,maxlv,numintervals,options)
%
%See also: GASELCTR, GENALG, SRATIO, VIP

%Copyright Eigenvector Research, Inc. 1995
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% BMW
% 5/19/05 JMS -added help and added logic to handle include for variables

if nargin == 0; X = 'io'; end
if ischar(X);
  options = [];
  options.name          = 'options';
  options.display       = 'on';
  options.plots         = 'final';
  options.mode          = 'forward';
  options.algorithm     = 'pls';
  options.numintervals  = 1;
  options.stepsize      = [];
  options.preprocessing = 'none';
  options.cvi           = {'vet' [] 1};
  options.mustuse       = [];
  options.plottype      = 'patch';

  if nargout==0; evriio(mfilename,X,options); else; bestuse = evriio(mfilename,X,options); end
  return;
end

if nargin<5;
  options = [];
elseif nargin>5 & ischar(varargin{1})
  % (...,'property',value,...)
  options = struct(varargin{:});
elseif isnumeric(varargin{1})
  % (...,numintervals)
  % (...,numintervals,options)
  if nargin==6;
    options = varargin{2};
  else
    options = [];
  end
  options.numintervals = varargin{1};
else
  % (...,options)
  options = varargin{1};
end
options = reconopts(options,'ipls');

if isempty(options.numintervals)
  options.numintervals = inf;
end

%get X ready
if ~isa(X,'dataset')
  X = dataset(X);
end
if isempty(X.axisscale{2})
  X.axisscale{2} = 1:size(X,2);
end

%get Y ready
if ~isa(Y,'dataset');
  Y = dataset(Y);
end

%Check INCLUD fields of X and Y
i = intersect(X.include{1},Y.include{1});
if ( length(i)~=length(X.include{1,1}) | ...
    length(i)~=length(Y.include{1,1}) )
  if strcmp(options.display,'on');
    disp('Warning: Number of included samples in X and Y not the same - using intersection.')
  end
  X.include{1,1} = i;
  Y.include{1,1} = i;
end
[m,n]    = size(X);

%check int_width value
if int_width>n/2
  error('Interval width must be equal to half the the number of variables or smaller')
end

%calculate splits
if iscell(options.cvi) & (length(options.cvi)<2 | isempty(options.cvi{2}))
  options.cvi{2} = min(10,floor(sqrt(length(X.include{1}))));
end

%handle preprocessing
prepro = options.preprocessing;
if isempty(prepro);
  prepro = {[] []};
end
switch class(prepro)
  case 'char'
    prepro = preprocess(prepro);
    prepro = {prepro prepro};
  case 'struct'
    prepro = {prepro prepro};
  case 'cell'
    %nothing need be done
  otherwise
   error('input (prepro) not recognized') 
end
options.preprocessing = prepro;

%handle stepsize
if isempty(options.stepsize)
  options.stepsize = int_width;
end

%set cross-validation options
cvopts = crossval('options');
cvopts.display = 'off';
cvopts.plots = 'none';
cvopts.cvi   = options.cvi;
cvopts.rm    = options.algorithm;
cvopts.norecon  = 'true';
cvopts.waitbartrigger = inf;
cvopts.preprocessing = options.preprocessing;

if strcmpi(options.algorithm,'mlr')
  maxlv = 1;  %fix maxlv to be 1 when using MLR mode
  description = ['MLR'];  %name to use in display boxes
elseif strcmpi(options.algorithm,'svmda')
  maxlv = 1;   %fix maxlv to be 1 when using MLR mode
  description = ['iSVMDA'];
  %cvopts.rmoptions = svmda('options');
else 
  maxlv = min([maxlv length(X.include{1}) length(X.include{2})]);
  description = ['i' upper(options.algorithm)];  %name to use in display boxes
end
description = [lower(options.mode) ' ' description];
description(1) = upper(description(1));

%prepare intial "use" vector for each mode
switch options.mode
  case 'forward'
    use = options.mustuse;
    modesign = '+';
  case 'reverse'
    use = X.include{2};
    modesign = '-';
  otherwise
    error(['Unknown option: mode "' options.mode '"'])
end

%prepare waitbar information
waitbarinfo.handle = waitbar(0,['Performing ' description  ' (Close to cancel)'],'tag','iplswaitbar', 'windowstyle', 'modal');
try
  waitbarinfo.start  = 0;
  waitbarinfo.starttime = now;
  if isfinite(options.numintervals);
    waitbarinfo.numreps = options.numintervals;
  else
    waitbarinfo.numreps = floor(n/options.stepsize);
  end
  
  %loop for forward and reverse ipls
  bestfit    = inf;
  bestrmsecv = inf;
  bestuse    = use;
  windowuse  = use;
  bestlvs    = [];
  lastselected = [];
  lvs        = nan; %first time through - "always use" points marked with NaN
  fit        = nan; % same for fit
  iplsopts   = options;  %initialize what we'll pass to ipls_one
  for winloop = 1:min(size(X,2),options.numintervals)
    
    tempX = X;
    switch options.mode
      case 'forward'
        %nothing special done on X
      case 'reverse'
        tempX.include{2} = use;
    end
    [icenters,rmsecv,rmsec,intervals,waitbarinfo] = ipls_one(tempX,Y,int_width,maxlv,iplsopts,cvopts,waitbarinfo);
    
    if isempty(icenters)
      bestuse = [];
      return
    end
    
    [intcv,intlv]    = min(rmsecv,[],1);
    intlv(isnan(intcv)) = lvs;  %"always use" points get marked with # of lvs from last cycle (or NaN on first cycle)
    intcv(isnan(intcv)) = fit;
    [bestint,where]  = min(rmsecv,[],2);
    [fit,lvs]        = min(bestint,[],1);
    
    if isinf(options.numintervals)
      switch options.mode
        case 'forward'
          %add if it improves fit
          if fit>=bestfit
            break;
          end
        case 'reverse'
          %remove if it doesn't degrade fit (same fit or better fit = OK to remove)
          if fit>bestfit
            break;
          end
      end
      if all(isnan(rmsecv))
        break;
      end
    end
    
    if strcmp(options.display,'on') & options.numintervals>1
      if ~strcmpi(options.algorithm,'mlr')
        disp(sprintf('Interval %i (%s#%i)   %i LVs  Fit: %g',winloop,modesign,where(lvs),lvs,fit));
      else
        disp(sprintf('Interval %i (%s#%i)  Fit: %g',winloop,modesign,where(lvs),fit));
      end
    end
    
    lastselected     = where(lvs);
    iuse             = intersect(intervals(lastselected,:),X.include{2});
    switch options.mode
      case 'forward'
        if winloop == 1;
          windowuse = union(find(all(isnan(rmsecv),1)),lastselected);
        else
          windowuse = union(windowuse,lastselected);
        end
        use              = union(use,iuse);
        iplsopts.mustuse = use;
      case 'reverse'
        if winloop == 1;
          windowuse = setdiff(find(~all(isnan(rmsecv),1)),lastselected);
        else
          windowuse = setdiff(windowuse,lastselected);
        end
        use          = setdiff(use,iuse);
    end
    
    bestfit = fit;
    bestlvs = lvs;
    bestuse = use;
    bestrmsecv = rmsecv;
    if ~ishandle(waitbarinfo.handle)
      %User closed waitbar so clear and return.
      bestuse = [];
      return
    end
  end
  
  %Intialize figure handle so passed out as empty if plots off.
  fh = [];
  
  %do plots (if desired)
  if strcmp(options.plots,'final');
    
    %do initial "all variables" assessment (for reference line)
    res = crossval(X,Y,cvopts.rm,cvopts.cvi,maxlv,cvopts);
    if islogical(Y.data) & ~isempty(res.classerrcv)
      yunitslabel = 'Missclassification rate';
      fullrmsecv = res.classerrcv;
    else
      yunitslabel = 'RMSECV';
      fullrmsecv = res.rmsecv;
    end
    if length(Y.include{2})>1;
      fullrmsecv = rmse(fullrmsecv);
    end
    [bestfullrmsecv,bestfullnlvs] = min(fullrmsecv);
    
    %replace "infs" with best values for each # of lvs (for display later)
    intmustuse = all(isnan(bestrmsecv),1) & any(ismember(intervals,X.include{2}),2)';
    if any(intmustuse)
      bestrmsecv(1:maxlv,intmustuse) = repmat(bestint,1,sum(intmustuse));
    end
    
    %create a map of all intervals and drop any excluded items
    %this map indicates which points and intervals as ACTUALLY being used
    usedintervals = find(any(ismember(intervals,X.include{2}),2))';
    
    %get by-interval info for plot
    temp    = intcv'*nan;
    temp(usedintervals) = intcv(usedintervals);
    %get included intervals
    tempuse = temp*nan;
    tempuse(windowuse) = temp(windowuse,:);
    %get not included
    tempdnuse = temp;
    tempdnuse(windowuse) = nan;
    
    %display RMSECV bars
    fh = figure;
    
    switch options.plottype
      case 'bar'
        h = bar(icenters,[tempdnuse tempuse],int_width./options.stepsize,'stacked');
        colormap([.7 0 0;0 1 0]);
        set(h,'edgecolor','flat');
        
      otherwise
        xax = X.axisscale{2};
        iv  = interp1((1:size(X,2))',xax',[intervals(:,1)-.5 intervals(:,end)+.5]);
        iv(1,1)     = 1.5*xax(intervals(1,1))-0.5*xax(intervals(1,1)+1);
        iv(end,end) = 1.5*xax(intervals(end,end))-0.5*xax(intervals(end,end)-1);
        xbar = (diag(tempdnuse*0+1)*iv(:,[1 1 end end]))';
        ybar = [tempdnuse.*0 repmat(tempdnuse,1,size(xbar,1)-2) tempdnuse.*0]';
        h    = patch(xbar,ybar,[.7 0 0]);
        set(h(1),'EdgeColor',get(h(1),'FaceColor'))
        xbar = (diag(tempuse*0+1)*iv(:,[1 1:end end]))';
        ybar = [tempuse.*0 repmat(tempuse,1,size(iv,2)) tempuse.*0]';
        h(2) = patch(xbar,ybar,[0 1 0]);
        set(h(2),'EdgeColor',get(h(2),'FaceColor'))
        
    end
    
    switch options.mode
      case 'forward'
        legendname(h(2),'Used intervals');
        legendname(h(1),'Discarded intervals');
      case 'reverse'
        legendname(h(2),'Retained intervals');
        legendname(h(1),'Discarded intervals');
    end
    
    %Overlay mean sample line
    ax = axis;
    
    %Make sure nan doesn't cause error.
    myaxisscale = X.axisscale{2};
    myaxisscale = myaxisscale(~isnan(myaxisscale));
    
    half = mean(abs(diff(myaxisscale)))/2;
    
    if half==0; half = .5; end;
    axis([min(X.axisscale{2})-half max(X.axisscale{2})+half ax(3:4)]);
    xm=mean(X.data,1);
    hold on
    if(min(xm)<0)
      %h = plot(X.axisscale{2},(ax(4)*.9)*((mean(X.data)/(max(mean(X.data))-min(mean(X.data))))-min(mean(X.data))*0.8),'-k','linewidth',2);
      h = plot(X.axisscale{2},(ax(4)*.9)*((xm-min(xm))/(max(xm)-min(xm))),'-k','linewidth',2);
      %ylim([min(xm) max(xm)]); %
    else
    h = plot(X.axisscale{2},(ax(4)*.9)*mean(X.data)/(max(mean(X.data))),'-k','linewidth',2);
    end;
    legendname(h,'Mean sample');
    hold off
    
    %add number of LVs used for "all intervals" rmsecv
    ax = axis;
    if ~strcmpi(options.algorithm,'mlr')
      h = text(ax(2),bestfullrmsecv,[' ('  num2str(bestfullnlvs) ' LVs)']);
      set(h,'fontangle','italic','horizontalalignment','left');
      if bestfullnlvs ~= bestlvs
        h = text(ax(2),fullrmsecv(bestlvs),[' ('  num2str(bestlvs) ' LVs)']);
        set(h,'fontangle','italic','horizontalalignment','left');
      end
    end
    
    %display number of LVs per window
    if length(icenters)<40 & ~strcmpi(options.algorithm,'mlr');
      strlvs = num2str(intlv(:));
      strlvs(isnan(intlv),:) = ' ';  %blank out NaN's
      h = text(icenters,ones(1,length(icenters))*ax(3)+ax(4)*.05,strlvs);
      set(h,'HorizontalAlignment','center','erasemode','xor','fontangle','italic')
      h = text(ax(2),ax(3)+ax(4)*.05,' (# LVs)');
      set(h,'fontangle','italic','horizontalalignment','left');
    end
    
    %Overlay "all intervals" line
    h = hline(bestfullrmsecv,'r--');
    set(h,'linewidth',2);
    if ~strcmpi(options.algorithm,'mlr')
      lvinfo = [' (' num2str(bestfullnlvs) ' LVs)'];
    else
      lvinfo = '';
    end
    legendname(h,['All Interval ' yunitslabel lvinfo]);
    if bestfullnlvs ~= bestlvs
      %Overlay "all interval" line at number of lvs used for best subset
      %model
      h = hline(fullrmsecv(bestlvs),'m--');
      set(h,'linewidth',2);
      if ~strcmpi(options.algorithm,'mlr')
        lvinfo = [' (' num2str(bestlvs) ' LVs)'];
      else
        lvinfo = '';
      end
      legendname(h,['All Interval ' yunitslabel lvinfo]);
    end
    
    
    xlbl = X.axisscalename{2};
    if isempty(xlbl) & isempty(X.axisscale{2});
      xlbl = 'Variable number';
    end
    xlabel(xlbl)
    
    switch options.mode
      case 'forward'
        ylabel([yunitslabel ' with interval added']);
        ttl = ([description ' Results']);
      case 'reverse'
        ylabel([yunitslabel ' with interval removed']);
        ttl = ([description ' Results']);
    end
    
    title(ttl)
    
  end
  
catch
  le = lasterror;
  if ishandle(waitbarinfo.handle)
    delete(waitbarinfo.handle)
  end
  rethrow(le)
end

if ishandle(waitbarinfo.handle)
  delete(waitbarinfo.handle)
end

if nargout<=1
  bestuse = struct('use',bestuse,'fit',bestfit,'lvs',bestlvs,'intervals',intervals,'intcv',intcv,'intlv',intlv,'figh',fh);
end  

%-----------------------------------------------------
function [icenters,rmsecv_all,rmsec_all,intervals,waitbarinfo] = ipls_one(X,Y,int_width,maxlv,options,cvopts,waitbarinfo)
%make sure mustuse is valid
origincl = X.include{2};
options.mustuse = intersect(options.mustuse,origincl);

if isfinite(options.numintervals)
  timelabel = 'Est. Time Remaining: ';
else
  timelabel = 'Max. Time Remaining: ';
end  

%setup and do sub-models
sz = size(X);
m = sz(1);
n = sz(2);
no_ints = floor(n/options.stepsize);
rmsecv_all = zeros(maxlv,no_ints)*nan;
rmsec_all = zeros(maxlv,no_ints)*nan;
icenters = zeros(1,no_ints);

lastupdate = now;
for j = 1:no_ints
  intervals(j,:) = (j-1)*options.stepsize + [1:int_width];
  intervals(j,:) = max(min(intervals(j,:),n),1);
  switch options.mode
    case 'forward'
      newincl = intervals(j,:);
      newincl = setdiff(newincl,options.mustuse);  %don't consider "mustuse" regions when we check for newincl being empty
      newincl = intersect(newincl,origincl);  %remove "never use" (i.e. excluded) regions
    case 'reverse'
      if any(ismember(intervals(j,:),origincl))
        newincl = setdiff(origincl,intervals(j,:));  %remove indentified region from original include
        newincl = union(newincl,options.mustuse);  %add "must use" regions (so it is OK to analyze if SOMETHING is there)
      else
        newincl = [];  %already excluded, skip
      end
  end

  if ~isempty(newincl);
    switch options.mode
      case 'forward'
        newincl = union(newincl,options.mustuse);
    end
    %assgin include field in copy of data
    Xone = X;
    Xone.include{2} = newincl;  
    if mdcheck(Xone);
      %and replace missing data (or exclude too-much-missing columns)
      [flag,missmap,Xone] = mdcheck(Xone);
    end
  end
  if ~isempty(newincl) & ~isempty(Xone.include{2})
    %if we had any columns (and still have them after possible exclusion in
    %mdcheck)...
    if strcmpi(cvopts.rm,'svmda');
        res = crossval(Xone,Y,cvopts.rm,cvopts.cvi,min(length(newincl),maxlv));
    else
        res = crossval(Xone,Y,cvopts.rm,cvopts.cvi,min(length(newincl),maxlv),cvopts);
    end
    if islogical(Y.data) & ~isempty(res.classerrcv)
      %logical y-block with classifcation error results, use those.
      classerrcv = res.classerrcv;   
      addrmsecv  = res.rmsecv;
      classerrc  = res.classerrc;
      addrmsec   = res.rmsec;
      if length(Y.include{2})>1
        classerrcv = rmse(classerrcv);
        addrmsecv  = rmse(addrmsecv);
        classerrc  = rmse(classerrc);
        addrmsec   = rmse(addrmsec);
      end
      rmsecv = classerrcv + addrmsecv*eps*max(classerrcv(:))*10;
      rmsec  = classerrc  + addrmsec*eps*max(classerrc(:))*10;
    else
      %normal cross-validation, just use rmsecv/c
      rmsecv = res.rmsecv;
      rmsec  = res.rmsec;
      if length(Y.include{2})>1
        rmsecv    = rmse(rmsecv);
        rmsec     = rmse(rmsec);
      end
    end
    rmsecv(:,end+1:maxlv) = nan;  
    rmsec(:,end+1:maxlv)  = nan;
    
  else
    rmsecv = nan;
    rmsec = nan;
  end
  rmsecv_all(:,j) = rmsecv';
  rmsec_all(:,j) = rmsec';
  icenters(1,j) = mean(X.axisscale{2}(intervals(j,:)));
  
  %handle waitbar (if necessary)
  if (now-lastupdate)*24*60*60>0.5
    lastupdate = now;
    if ishandle(waitbarinfo.handle)
      progress = waitbarinfo.start+(j/no_ints)/waitbarinfo.numreps;
      elaptm = now-waitbarinfo.starttime;
      esttm  = (elaptm/progress)*(1-progress)*60*60*24;
      if ~ishandle(waitbarinfo.handle)
        warning('EVRI:IplsUserAbort','User aborted analysis');
        icenters = [];
        return
      end
      waitbar(progress,waitbarinfo.handle);
      if ishandle(waitbarinfo.handle)
        %Make sure thre's a handle, seemed to get here even with check
        %above.
        set(waitbarinfo.handle,'name',[timelabel besttime(ceil(esttm))])
      end
    end
  end
  
  if ~ishandle(waitbarinfo.handle)
    %User closed waitbar so break out here. Clear result so doesn't give
    %partial, that should be avoided.
    icenters = [];
    break
  end
  
end

if ishandle(waitbarinfo.handle)
  waitbarinfo.start = waitbarinfo.start+1/waitbarinfo.numreps;
end
