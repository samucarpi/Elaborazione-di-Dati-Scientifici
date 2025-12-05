function varargout = glsw(varargin)
%GLSW Generalized least-squares weighting/preprocessing.
% Uses Generalized Least Squares to down-weight variable features
% identified from the singular value decomposition of a data matrix.  The
% input data usually represents measured populations which should otherwise
% be the same (e.g. the same samples measured on two different analyzers or
% using two different solvents) and can be input in one of several forms,
% as explained below.
%
% To calculate the deweighting matrix, the inverse of the singular values
% are used along with the singular vectors and an adjustable parameter.
% The adjustable parameter (a) is used to scale the singular values prior
% to calculating their inverse:  sinv = sqrt(1 / ( (s/a^2) + 1 ))
% As (a) gets larger, the extent of deweighting decreases (because sinv
% approaches 1). As (a) gets smaller (e.g. 0.1 to 0.001) the extent of
% deweighting increases (sinv goes to 0) and the deweighting includes increasing
% amounts of the the directions represented by smaller singular values. A
% good initial guess for (a) is 1e-2 but will vary depending on the
% covariance structure and application.
%
% This function will also perform EPO (External Parameter
% Orthogonalization) which is GLSW with a filter built from a specific
% number of singular vectors rather than the weighting scheme described
% above. To perform EPO, a negative integer is supplied in place of (a)
% where -a specifies the number of singular vectors to include in the
% filter. This is GLSW with a square-wave function for the deweighting.
% If a is passed as -inf, then all variance in the clutter is deweighted.
%
% INPUTS:
%  For calibration, inputs can be provided by one of four forms: 
%  1)  x = data or covariance matrix containing features to be downweighted
%      a = scalar parameter limiting downweighting {default = 1e-2}.
%  2) x1, x2 = two data matricies; the row-by-row differences between x1 and
%           x2 will be downweighted, and
%          a = scalar parameter limiting downweighting {default = 1e-2}.
%  3)  x = data matrix,
%      y = vector equal in length to rows of x which specifies sample
%           groups in x within which differences should be downweighted,
%           and
%      a = scalar parameter limiting downweighting {default = 1e-2}.
%  4)  x = data matrix,
%      y = column vector or matrix with rows equal to rows of x which
%           specifies the true measured value for each row of x (i.e. a
%           continuous variable rather than discrete groups) which should
%           be used to estimate the features to downweight,
%      a = scalar parameter limiting downweighting {default = 1e-2}.
%
%  In all cases, an options structure can be passed in place of (a) for any
%  call or as the third output in an apply call. This structure consists of
%  any of the fields:
%           a : [{0.02}] scalar parameter limiting downweighting {default = 1e-2},  
%  meancenter : [ 'no' | {'yes'} ] For single x-block modes only: governs
%          the calculation of a mean of each group of data before
%          calculating the covariance. If set to ''no'', the filter will
%          include the offset of each group. This is equivalent to saying
%          the offset in the data is part of  the clutter which should be
%          removed.
%   applymean : [ 'no' | {'yes'} ] governs the use of the mean difference
%           calculated between two instruments (difference between two
%           instruments mode). When appling a GLS filter to data collected
%           on the x1 instrument, the mean should NOT be applied. Data
%           collected on the SECOND instrument should have the mean
%           applied.
%   gradientthreshold : [ .25 ] "continuous variable" threshold fraction
%           above which the column gradient method will be used with a
%           continuous y. Usually, when (y) is supplied, it is assumed to
%           be the identification of discrete groups of samples. However,
%           when calibrating, the number of samples in each "group" is
%           calculated and the fraction of samples in "singleton" groups
%           (i.e. in thier own group) is determined.
%              fraction = (# Samples in Singleton Groups) / Total Samples
%           If this fraction is above the value specified by this option,
%           (y) is considered a continuous variable (such as a
%           concentration or other property to predict). In these cases,
%           the "sample similarity" (a.k.a. "column gradient") method of
%           calculating the covariance matrix will be used. Sample
%           similarity method determines the down-weighting required based 
%           mostly on samples which are the most similar (on the specified
%           y-scale). Set to >=1 to disable and to 0 (zero) to always use.
%   xgradient : [ {'no'} | 'yes' ] apply an x-block gradient filter before
%           calculating the filter. This filter performs a derivative down
%           the columns of the x-block accentuating differences between
%           adjacent samples. For example: When samples are sorted by time,
%           this creates a GLSW filter that down-weights differences in the
%           short time scale while retaining long-scale differences.
%   xgradwindow : [ 3 ] number of samples over which the xgradient should
%           be taken (see xgradient option)
%   maxpcs : [ 50 ] maximum number of components (factors) to allow in
%           the GLSW model. Typically, the number of factors in incuded in
%           a model will be the smallest of this number, the number of
%           variables or the number of samples. Having a limit set here is
%           useful when derriving a GLSW model from a large number of
%           samples and variables. Often, a GLSW model effectively uses
%           fewer than 20 components. Thus, this option can be used to keep
%           the GLSW model smaller in size. It may, however, decrease its
%           effectiveness if critical factors are not included in the
%           model.
%   classset: [ 1 ] indicates which class set in x to use when no y-block
%             is provided. 
%   maxperclass: [inf] indicates the maximum number of samples from each
%           class that should be used to calculate the filter when
%           class-based filtering is being done. When < inf, only the first
%           "maxperclass" samples from each class are used to calculate the
%           filter.
%   downweight : [ 'no' | {'yes'} ] governs whether the filter will
%           downweight identified features, or upweight them. Normally,
%           "clutter" is identified and downweighted by a GLSW filter.
%           However, GLSW filters can also be supplied with features that
%           are of interest (signal) and this flag can be reversed causing
%           GLSW to "upweight" thses signal features.
% 
%  When applying the model the inputs are:
%      newx : the x-block to be corrected,
%      modl : a GLSW model structure, and
%   options : an options structure as defined above OR 
%         a : (passed in place of options) a scalar value to use for option a
%  If options contains a value for "a", this value will be used in place of
%  the value originally passed when building the model. This allows an
%  existing GLSW model to be applied with varying levels of downweighting
%  without recalculating.
% 
%  UPDATING a IN MODEL: An existing GLSW model can be updated to a new
%  value of (a) by calling glsw with only the model and a new value for (a)
%  as input. Note also that a new value of (a) can be supplied on-the-fly
%  when applying the model to new data, but in this case, the original
%  model is not updated to reflect this new (a).
%
% OUTPUTS:
%   modl = GLSW model structure.
%     xt = the corrected x-block.
%
%I/O: modl = glsw(x,a);         %GLSW on matrix
%I/O: modl = glsw(x,options);   %GLSW on matrix
%I/O: modl = glsw(x,y,a);       %GLSW on matrix in groups based on y
%I/O: modl = glsw(x1,x2,a);     %GLSW between two matricies (e.g. instruments)
%I/O: modl = glsw(modl,a);      %Update model to use a new value for a
%I/O: xt   = glsw(newx,modl,options);   %apply correction
%I/O: xt   = glsw(newx,modl,a);         %apply correction
%I/O: glsw demo
%
%See also: CALTRANSFER, OSCCALC, PCA, PLS, PREPROCESS

%Copyright (c) Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%JMS 1/3/03 added options structure and "use gradient" option (instead of
%   triggering by logical or not!)
%JMS 2/19/04 -major improvement in speed and applicability
%   -removed use of full "w" matrix. Now stores only compacted v and d in model
%   -revised calculation to speed analysis of matricies with many variables
%JMS 5/24/04 -fixed bug in two-matrix comparison mode
%   -added applymean option 
%JMS 11/24/04 -use include on input of dataset y

if nargin==0; varargin{1} = 'io'; end
if ischar(varargin{1}) %Help, Demo, Options
  switch lower(varargin{1})
  case 'default'
    pp.description = 'GLS Weighting';
    pp.calibrate = {'if length(otherdata)<1; otherdata = {[]}; end; out{2}=glsw(data,otherdata{1},userdata);data=glsw(data,out{2});'};
    pp.apply = {'data=glsw(data,out{2});'};
    pp.undo = {};
    pp.out = {};
    pp.settingsgui = 'glswset';
    pp.settingsonadd = 1;
    pp.usesdataset = 1;
    pp.caloutputs = 2;
    pp.keyword = 'GLS Weighting';
    pp.category = 'Filtering';
    pp.tooltip = 'Generalized Least Squares Weighting - remove clutter covariance';
    pp.userdata = struct('a',[],'source','automatic','meancenter','yes');
    varargout = {pp};
  case 'clsresiduals'
    pp.description = 'GLS Weighting (CLS Residuals)';
    cal = [ ...
      'if isdataset(data); ' ...
        'ix = data.include{1}; iy = data.include{2};' ...
        'if isdataset(otherdata{1}); otherdata1 = otherdata{1}.data(ix,otherdata{1}.include{2}); end;' ...
        'if ~isdataset(otherdata{1}); otherdata1 = otherdata{1};end;' ...      
        'purespec = otherdata1\data.data(ix,iy); xhat = otherdata1*purespec;' ...
        'resids = nan(size(data));resids(ix,iy) = data.data(ix,iy) -xhat;' ...
        'resids = dataset(resids);resids.include{1} = ix; resids.include{2} = iy;' ...
      'else; purespec = otherdata{1}\data; xhat = otherdata{1}*purespec; resids = data -xhat;' ...
      'end;' ...
      'userdata.purespec = purespec;'...
      'out{2}=glsw(resids,userdata);' ...
      'out{3} = data;' ...
      'data=glsw(data,out{2});'];
    pp.calibrate = { cal };
    pp.apply = {'out{4} = data; data=glsw(data,out{2});' };
    pp.undo = {};
    pp.out = {};
    % pp{1}.out{1} = [];
    pp.settingsgui = 'glswset';
    pp.settingsonadd = 1;
    pp.usesdataset = 1;
    pp.caloutputs = 2;
    pp.keyword = 'declutter GLS Weighting';
    pp.category = 'Filtering';
    pp.tooltip = 'Generalized Least Squares Weighting using CLS Residuals - remove clutter covariance';
    pp.userdata.a = [];
    pp.userdata.source = 'cls_residuals';
    pp.userdata.meancenter = 'no';
    pp.userdata.applymean = 'no';
    pp.userdata.classset = 1;
    pp.userdata.purespec = [];
    varargout = {pp};
    otherwise
    options = [];
    options.a = 0.02;
    options.meancenter = 'yes';
    options.gradientthreshold = 0.25;
    options.xgradient    = 'no';
    options.xgradwindow  = 3;
    options.applymean    = 'yes';
    options.maxpcs       = 50;
    options.maxperclass  = inf;
    options.classset     = 1;    %class set to use (when no y provided)
    options.downweight   = 'yes';
    options.definitions  = @optiondefs;
    if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  end
  return
end

%figure out what mode they've called us in
diffmode = 0;     %difference between two matricies?
apply    = 0;     %apply mode (vs calculate mode)?
groups   = [];    %default is compare all to all (no groups)
%get sizes of all inputs
for j=1:nargin;
  if ~isa(varargin{j},'dataset');
    sz{j} = size(varargin{j});
  else
    sz{j} = size(varargin{j}.data);
  end
end
if nargin == 3;
  if ismodel(varargin{2}) & strcmpi(varargin{2}.modeltype,'glsw')
    % glsw(newx,model,options)
    diffmode = 0;
    apply    = 1;
    newx     = varargin{1};
    modl     = varargin{2};
    a        = varargin{3};
  elseif all(sz{1} == sz{2});
    % glsw(x1,x2,a)
    diffmode = 1;
    apply    = 0;
    x1       = varargin{1};
    x2       = varargin{2};
    a        = varargin{3};
  else%if all(sz{2} == [sz{1}(1) 1]);
    % glsw(x,y,a)
    diffmode = 0;
    apply    = 0;
    x1       = varargin{1};
    groups   = varargin{2};
    a        = varargin{3};
  end
elseif nargin == 2;
  if ismodel(varargin{2});
    % glsw(newx,modl)
    a        = [];  %default options
    diffmode = 0;
    apply    = 1;
    newx     = varargin{1};
    modl     = varargin{2};
  elseif isstruct(varargin{2})
    % glsw(x,options)
    diffmode = 0;
    apply    = 0;
    x1       = varargin{1};
    a        = varargin{2};
  elseif prod(sz{2}) == 1 | prod(sz{2}) == 0;
    if ~ismodel(varargin{1})
      % glsw(x,a)
      diffmode = 0;
      apply    = 0;
      x1       = varargin{1};
      a        = varargin{2};
    else
      % glsw(modl,a)    -update model alpha
      apply    = 1;
      newx     = [];
      a        = varargin{2};
      modl     = varargin{1};
    end
  elseif all(sz{1} == sz{2});
    % glsw(x1,x2)
    diffmode = 1;
    apply    = 0;
    x1       = varargin{1};
    x2       = varargin{2};
    a        = [];
  elseif sz{2}(1) == sz{1}(1);
    % glsw(x,y)
    diffmode = 0;
    apply    = 0;
    x1       = varargin{1};
    groups   = varargin{2};
    a        = [];
  else
    error('Invalid input - check sizes and types of inputs.');
  end
elseif nargin == 1;
  if ~ischar(varargin{1});
    % glsw(x)
    diffmode = 0;
    apply    = 0;
    x1       = varargin{1};
    a        = [];
  end
end

%=====================================================
if ~apply;
  %calibrate new model
  
  %reconcile input "a" as options (or alpha)
  if ~isa(a,'struct');
    options = glsw('options');
    if ~isempty(a); options.a = a; end
  else
    options = reconopts(a,'glsw',{'source'});
  end

  meancenter = strcmp(options.meancenter,'yes');
  s1 = 1;
  if diffmode;
    %doing difference between two matrices and using that difference to
    %calculate covariance
    oldmethod = false;
    
    if ndims(x1)~=ndims(x2)
      error('The number of dimensions in x1 and x2 do not match')
    end
    if isa(x1,'dataset');
      x1 = x1.data(x1.includ{1},x1.includ{2});
    end
    if isa(x2,'dataset');
      x2 = x2.data(x2.includ{1},x2.includ{2});
    end
    if size(x1,1)~=size(x2,1)
      error('The number of variables in x1 and x2 do not match')
    end
    if size(x1,2)~=size(x2,2)
      error('The number of samples in x1 and x2 do not match')
    end
    
    xdm     = mean(x1) - mean(x2);
    xd      = x1-x2+ones(size(x1,1),1)*xdm;
    groups  = [];
    [m,n] = size(xd);
    switch oldmethod
      case true
        [v,s] = svd(xd');
      otherwise
        [u,s] = svd(xd);
    end
    s     = diag(s);
    use   = 1:min(options.maxpcs,rank(diag(s)));
    s     = s(use);
    switch oldmethod
      case true
        v     = v(:,use);
      otherwise
        v     = (u(:,use)\xd)';
        v     = v*(diag(1./s));
    end
    s     = s.^2/(m-1);
  else
    %calculating covariance matrix from a single given dataset (and one of
    %a couple of algorithms decided below)
    if ~isempty(groups) & isa(groups,'dataset');
      groups = groups.data(:,groups.include{2});
    elseif size(groups,1)==1 & size(groups,2)>1
      groups = groups(:);  %make row-vector a column vector
    end
    if isa(x1,'dataset');
      %use class if no groups supplied
      if isempty(groups)
        if  (size(x1.class,2)>=options.classset & ~isempty(x1.class{1, options.classset}))
          groups = (x1.class{1, options.classset})';       
        elseif options.classset>1
          error('Attempting to use X-block class set %i, which does not exist or is empty', options.classset)
        end
      end
      
      if ~isempty(groups); groups = groups(x1.includ{1},:); end;  %remove excluded samples
      x1 = x1.data(x1.includ{1},x1.includ{2});
    end
   
    weights = ones(size(x1,1),1);
    %Calculate valid groups of data and make indicies into the unique group types
    if isempty(groups) | all(groups(:)==groups(1));
      groups     = ones(size(x1,1),1); 
      grouptypes = 1;
    else
      if size(groups,2)==1
        %single-column groups
        grouptypes = unique(groups);
        groupsizes = hist(groups,setdiff(grouptypes,0));
        pctsingle  = sum(groupsizes==1)./sum(groupsizes);
        usegradient = pctsingle>options.gradientthreshold;
      else
        %multi-column groups (e.g. y-block)?
        [tgroups,tj,ti] = unique(groups,'rows');
        grouptypes = 1:size(tgroups,1);
        groupsizes = hist(ti,grouptypes);
        pctsingle  = sum(groupsizes==1)./sum(groupsizes);
        usegradient = pctsingle>options.gradientthreshold;
        if ~usegradient
          %won't be using gradient method - translate into new classes
          groups = ti;
        else
          error('GLSW cannot operate on multivariate y-blocks with continuous variables')
        end
      end
      if usegradient
        if (max(groups)-min(groups)) > 0;
          %sort continuous groups (e.g. y-variable!)
          [groups,order] = sort(groups);
          %sort x-block in same order
          x1 = x1(order,:);
          %calculate the gradient of the SORTED x-block samples
          x1 = savgol(x1',5,1,1)';
          
          %weight each sample by distance to neighbors
          gy      = abs(savgol(groups(:)',5,1,1)');
          gy      = gy/max(gy);  %divide by largest difference
          nrm = max(0.001,std(gy));  %normalize by average difference in differences OR 0.1% of diff, whichever is larger
          weights = 2.^(-(gy./nrm));  %calculate weights
          weights = weights./max(abs(weights));  %normalize by largest weight
          for k=1:size(x1,1);
            x1(k,:) = x1(k,:)*weights(k);
          end
          
          %assign to one big group
          groups = ones(size(x1,1),1);
          grouptypes = [1];
          
        end
      end
      if length(grouptypes) > 1;
        groups = interp1(grouptypes,1:length(grouptypes),groups);       %indicize groups (1 to # of groups)
      else
        groups = ones(size(x1,1),1);
      end
    end
    
    %Center each group to mean of group
    if size(x1,1)>1 & meancenter
      [x1,xdm] = mncn(x1);  %grand mean first
    else
      %fake mean (of all zeros)
      xdm = x1(1,:).*0;
    end
    Cd = [];
    numgroupsused = 0;
    for grp = 1:length(grouptypes)
      if grouptypes(grp) ~= 0;        %don't use group "0"
        use     = (groups==grp);
        use(cumsum(use)>options.maxperclass) = 0;  %don't use more than this number per class
        if all(use)
          %everything in one group? do the memory-friendly approach
          Cd = xfilter(x1,options); 
          x1 = [];
          if meancenter
            Cd = mncn(Cd);  %use mean centered group
            ldof = 1;       %lost degrees of freedom
          else
            ldof = 0;       %lost degrees of freedom (none)
          end
          %assemble [weighted] group with others into Cd for decomposition
          div = sqrt(sum(weights(use))-ldof);
          if div>0
            Cd = Cd./div;
          end
          numgroupsused = numgroupsused+1;
        elseif sum(use)>1         %don't do this for groups of only one member
          x1g = xfilter(x1(use,:),options);
          if meancenter
            x1g = mncn(x1g);  %use mean centered group
          end
          %assemble [weighted] group with others into Cd for decomposition
          x1g = x1g./sqrt(sum(weights(use))-1);
          Cd(end+1:end+sum(use),:) = x1g;
          numgroupsused = numgroupsused+1;
        elseif sum(use)==1 & ~meancenter
          %groups of one member and we're NOT mean centering? just add
          %member (with whatever weight is selected for it)
          Cd(end+1,:) = xfilter(x1(use,:),options)./sqrt(weights(use));
          numgroupsused = numgroupsused+1;
        end
      end
    end
    if numgroupsused>0;
      %one or more groups included, do decomposition
      if size(Cd,2)<size(Cd,1)
        %more rows than columns
        tpose = true;
        Cd = Cd';
      else
        tpose = false;
      end
      %more columns than rows:
      [v,s] = svd(Cd,0);
      s   = diag(s);
      use = 1:min(options.maxpcs,rank(diag(s)));
      s   = s(use);
      if tpose
        %v is variable loadings already
        v  = v(:,use);
      else
        %v is SAMPLE loadings, project and unscale
        v  = (v(:,use)\Cd)'*(diag(1./s));        
      end
      s1 = s(1);
      s  = s/s1;  % Normaize s by first value
      s   = s.^2;
    else
      %no groups used? filter is "empty" (all passes)
      Cd = ones(1,size(x1,2));
      v  = ones(1,size(x1,2))';
      s  = 1;
    end
  end
  
  % If multiple a values then use the smallest/most-negative. This is
  % important for clutter filter using clsresiduals and EPO
  if length(options.a) > 1
    optionsa = sort(options.a);
    options.a = optionsa(1);
  end
  
  if options.a>=0
    %positive options.a = GLS weighting
    d  = s./(options.a^2);
    d(end+1:size(v,2)) = 0;  %extend to appropriate length for v
    d  = 1./sqrt(d + 1);
    d  = d-1;
  else
    % negative options.a = trim to given # of components
    a = abs(fix(options.a));
    v = v(:,1:min(end,a));
    s = -ones(size(v,2),1);
    d = s;
  end

  modl = modelstruct('glsw');
  modl.datasource = {getdatasource(varargin{1})};
  modl.date       = date;
  modl.time       = [datestr(now,15) ':' sprintf('%06.3f',mod(now*60*60*24,60))];
  modl.detail.v   = v;
  modl.detail.s   = s;
  modl.detail.xdm = xdm;
  modl.detail.a   = options.a;
  modl.detail.d   = d;
  modl.detail.groups = groups;
  modl.detail.options = options;
  modl.detail.options.s1 = s1;
  
  varargout = {modl};
  
  % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
else    %apply

  %reconcile input "a" as options (or alpha)
  newa = false;
  if ~isa(a,'struct');
    options = modl.detail.options;
    if ~isempty(a); 
      %if they supplied a, replace the one in the model
      modl.detail.a = a; 
      newa = true;
    end
  else
    %they provided an options structure
    if isfield(a,'a');
      %if they provided "a" among those options, use it
      modl.detail.a = a.a;
      newa = true;
    end
    options = reconopts(a,modl.detail.options);
  end
  options = reconopts(options,mfilename);  %make sure we have all options we need (old options or models)

  if isa(newx,'dataset');
    isdataset = 1;
    orig = newx;
    newx = newx.data(:,orig.includ{2});
  else
    isdataset = 0;
  end

  if size(newx,2)~=size(modl.detail.xdm,2)
    error('Variables in clutter and variables in data do not match. Check the data loaded for clutter definition.')
  end
  
  if strcmp(options.applymean,'yes') & ~isempty(newx)
    newx = scale(newx,modl.detail.xdm);
  end
  if isfield(modl.detail,'w');
    %old model format (pre-calculated "w")
    if isempty(newx)
      error('Unable to change alpha on this old-format GLSW model. Model must be recalculated from original data.')
    end
    weighted = newx*modl.detail.w;
  else
    if ~newa | ~isfield(modl.detail,'s')
      %no new a was supplied OR this is an old model format that doesn't
      %have "s" supplied (so we can't recalculate d)
      v = modl.detail.v;
      d = modl.detail.d;
    else
      %even newer model format (v, s, and a)
      if modl.detail.a>=0;
        v  = modl.detail.v;
        d  = modl.detail.s./(modl.detail.a^2);
        d(end+1:size(v,2)) = 0;  %extend to appropriate length for v
        d  = 1./sqrt(d + 1);
        d  = d-1;
      else
        % negative options.a = trim to given # of components
        a = abs(fix(modl.detail.a));
        if a>size(modl.detail.d,2)
          error('When using a "trim" alpha (a) the number of components included in the model can not be greater than the number originally included');
        end
        d = modl.detail.s(1:a);      %(do not do d=d-1 here - we've already done it when the model was calculated)
        v = modl.detail.v(:,1:a);
      end
    end
    
    %Apply to newx (or update model if newx was not passed)
    if ~isempty(newx)
      if (isnumeric(options.downweight) & options.downweight) | (ischar(options.downweight) & strcmpi(options.downweight,'yes'))
        %   weighted = X*v*(diag(d)*v') + X
        weighted = (newx*v)*(diag(d)*v') + newx;
      else
        weighted = (newx*v)*(diag(-d)*v') + newx;
      end
    else
      %update model details with newly calculated values
      if ~newa
        error('No new value for "a" was passed - cannot update model');
      end
      modl.detail.d = d;
      modl.detail.v = v;
      modl.detail.a = a;
      weighted = modl;
    end
  end
  
  if isdataset;
    orig.data(:,orig.includ{2}) = weighted;
    varargout = {orig};
  else
    varargout = {weighted};
  end
end
  
%------------------------------------------
function x = combinevars(x,maxvars)
%This function is not currently in use
%COMBINEVARS identifies variables which are so strongly correlated that
%combineing them when making the correlation matrix will not unduely lose
%information. This simplifies storage and speeds calculations.
% EXPERIMENTAL!!!

mode = 2;

if nargin < 2;
  maxvars = 250;
end

split = fix(size(x,2)/maxvars);
if split > 1;
  switch mode
  case 0
    xc = x;
  case 1
    ind  = [1:size(x,2)]';
    last = fix(size(x,2)/split)*split;
    xc  = zeros(size(x,1),last/split);
    for ii = 1:split;
      xc = xc + x(:,ind(ii:split:last));
    end
  case 2
    last    = fix(size(x,2)/split)*split;
    xc      = zeros(size(x,1),last/split);
    notused = logical(ones(1,size(x,2)));
    
    [what,where]   = sort(x./sqrt(diag(x)*diag(x)'));
    [what2,where2] = max(what(end-1,:));
    
    for ii = 1:last/split;
      avail          = where(notused(where(:,where2)),where2);    %get the unused list (in similarity order)
      ind            = avail(end-split+1:end);   %get the most similar to this one
      xc(:,ii)       = sum(x(:,ind),2);    %compress these into one
      notused(ind)   = 0;                  %and lock them out from use
      
      avail          = where(notused(where(:,where2)),where2);    %get the unused list (in similarity order)
      if ~isempty(avail);
        where2         = avail(1);          %find the most DIS-similar
      end
      
      %       plot(1:length(notused),notused,ind,.8,'rx')
      %       vline(ind,'r');
      %       vline(avail(1),'g');
      %       drawnow
      
      end
    case 3

      cc      = corrcoef(x);
      cc(1:size(cc,1)+1:end) = 0;
      map     = 1:size(cc,2);

      for ii = 1:size(x,2)-maxvars;  %how many to get rid of
        [whatr,wherer]  = max(cc);
        [whatc,wherec]  = max(whatr);
        ind             = map([wherec wherer(wherec)]);
        match           = ismember(map,ind); 
        cc(match,match) = 0; 
        map(match)      = ind(1); 
        x(:,match)      = sum(x(:,match),2)*ones(1,sum(match));
      end
      xc = x(:,unique(map));
      
  end    
  x = xc;
end

%--------------------------
function x1 = xfilter(x1,options)
%perform whatever x-filtering options we want. This may be repeteated for
%multiple blocks if user has also asked to use classes (e.g.)

if strcmp(options.xgradient,'yes')
  %do x-block gradient down columns
  if size(x1,1)>options.xgradwindow*2
    x1 = savgol(x1',options.xgradwindow,1,1)';
  else
    x1 = x1.*0; %too few samples to do gradient? do ZEROS (no filtering based on this info)
  end
end

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                       userlevel       description
'a'                      'Standard'      'double'        'float(0:inf)'              'novice'        'Scalar parameter (>0) limiting downweighting. The larger this number, the less downweighting. Values are typically between 0.00001 and 1000.';
'meancenter'             'Standard'      'select'        {'yes' 'no'}                'novice'        'For single x-block mode only: Governs the calculation of a mean of each group of data before calculating the covariance. If set to ''no'', the filter will include the offset of each group. This is equivalent to saying the offset in the data is part of the clutter which should be removed.';
'applymean'              'Standard'      'select'        {'yes' 'no'}                'novice'        'Governs the use of the mean difference calculated between two instruments (difference between two instruments mode). When appling a GLS filter to data collected on the x1 instrument, the mean should NOT be applied. Data collected on the SECOND instrument should have the mean applied.';
'gradientthreshold'      'Standard'      'double'        'float(0:1)'                'intermediate'  '"continuous variable" threshold fraction. If this fraction of groups specified in input "y" are singletons (one sample), the gradient method of covariance calculation will be used in which samples are sorted and compared by their similarity in y.';
'maxpcs'                 'Standard'      'double'        'int(1:inf)'                'intermediate'  'Maximum number of components (factors) to allow in any filter. Smaller numbers decrease model size but also decrease filter efficiency.';
'classset'               'Standard'      'double'        'int(1:inf)'                'novice'        'Class set to model (if no y-block passed)';
};

out = makesubops(defs);
