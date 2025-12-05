function [isel,loads] = exteriorpts(x,ncomp,options)
%EXTERIORPTS Identifies points on the exterior of a normalized data space.
%  Given a two-way or higher-order data set (X), the most exterior samples
%  or variables are identified and their indices returned. When the loads
%  output is requested, the data (X) are assumed to be modelable as:
%      X = CS' + E. 
%  If the non-negative least  squares option is used, C and S are also
%  assumed to be all positive.
%
%  The approach is discussed in:
%  Gallagher NB, Sheen DM, Shaver, JM, Wise, BM, Schultz, JF, "Estimation of
%    Trace Vapor Concentration-Pathlength in Plumes for Remote Sensing Applications
%    from Hyperspectral Images," SPIE Proceedings, 5093, 184-194 (2003).
%  Gallagher, NB, Shaver, JM, Martin, EB, Morris, J, Wise, BM, Windig, W, "Curve
%    resolution for images with applications to TOF-SIMS and Raman," Chemo. and
%    Intell. Lab. Sys., 2003, 77(1), 105-117.
%
%  INPUTS:
%         x = MxN matrix or DataSet object.
%     ncomp = number of points to extract.
%
%  OPTIONAL INPUT:
%   options = structure with the following fields:
%    selectdim: [1] mode of the data from which items should be selected
%                   (i.e. 1=rows, 2=columns, ...) If empty [], all modes
%                   are analyzed and the mode with the largest sum-squared
%                   captured value is used.
%      waitbar: [ 'off' | 'on' | {'auto'} ] governs of waitbar while
%                    processing. 'auto' uses waitbar only if multiple modes
%                    are being analyzed with nway data.
%      minnorm: [ 0.03 ] approximate noise level, points with unit area 
%                         smaller than this (as a fraction of the maximum
%                         value in x) are ignored during selection.
%       usepca: [{'no'}| 'yes' ] governs use of PCA as a pre-filtering step
%                         on the data prior to selection.
%      usennls: [{'no'}| 'yes' ] governs use of non-negative least squares
%                         when calculating loadings for other-than-sample
%                         modes. Only used when (loads) output is
%                         requested.
%  distmeasure: [ {'Euclidian'} | 'Mahalanobis' ] Governs the type of
%                         distance measurement to use. Mahalanobis requires
%                         the usepca option to be 'yes'. 
%   samplemode: [ 1 ] mode that contains variance (factors for other modes
%                     are normalized to unit 2-norm). Only used when loads
%                     output is requested.
%
%  OUTPUTS:
%      isel = if selectdim option was non-empty, isel is a vector of the
%             selected indices. Otherwise, isel is a cell array with the
%             indices selected on each mode of the data.
%     loads = cell array with extracted pts/factors. Non-selectdim modes
%             are determined via projection.
%
%I/O: [isel,loads] = exteriorpts(x,ncomp,options);
%
%See also: ALS, MCR, PARAFAC, PURITY, PURITYENGINE

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 5/03
%nbg 10/03 modified to use auto
%nbg 1/05 added help
%nbg 2/08 recoded to allow multiway

%TODO: for multiway, it is possible to have more factors than samples and we need to account for that

if nargin == 0; x = 'io'; end
if ischar(x) %Help, Demo, Options
  options = [];
  options.selectdim     = 1;
  options.waitbar       = 'auto';   %| 'off'   %Displays output to the command window
  options.minnorm       = 0.03;
  options.usepca        = 'no';  
  options.usennls       = 'no';  
  options.distmeasure   = 'Euclidian'; %| Mahalanobis
  options.samplemode    = 1;

  if nargout==0
    evriio(mfilename,x,options);
  else
    isel = evriio(mfilename,x,options);
  end
  return
end

%Check Inputs
if nargin<2
  error([ upper(mfilename) ' requires 2 inputs.'])
end

if isnumeric(x)
  x       = double(x);
  include = {};  %no include
elseif isdataset(x)
  include = x.include;
  x       = double(x.data.include);  %extract included from dataset
else
  error('Input (x) must be numeric or dataset')
end

if nargin<3
  options = [];
end
try
  options = reconopts(options,mfilename);
catch
  error('Input OPTIONS not recognized.')
end

%initialize a few things
m        = size(x);   %size of each mode
p        = length(m); %number of modes
loads    = cell(1,p);
isel     = loads;
ssq      = zeros(1,p);

if isempty(options.selectdim)
  %if user asked us to decide which dim to select from... select on ALL
  %modes (can be slow!)
  selectOnModes = 1:p;
else
  %2-way and user had a particular mode to select from (typical case)
  selectOnModes = options.selectdim;
end

if strcmpi(options.waitbar,'on') | (strcmpi(options.waitbar,'auto') & length(selectOnModes)>1)
  hwait = waitbar(0,'Selecting Exterior Points');
else
  hwait = [];
end
for i1=selectOnModes
  if p>2
    %nway - do unfold
    unfoldedx  = unfoldmw(x,i1);
  else
    %2-way
    if i1==2
      %and selecting from COLUMNS
      unfoldedx = x';
    else
      %selecting from ROWS
      unfoldedx = x;
    end
  end
  [normx,nz] = normaliz(unfoldedx,0,1);
  goodnorm   = find(nz>options.minnorm*max(nz));
  [~,dk]     = pcaengine(mncn(normx(goodnorm,:)),1,struct('plots','none','display','off')); %3/29/24
  if dk<ncomp %account for noise-free perfect data
    normx    = mncn(normaliz(unfoldedx(goodnorm,:)+options.minnorm*max(unfoldedx(:)),0,1));
  else
    normx    = mncn(normx(goodnorm,:));
  end
  
  if strcmp(options.usepca,'yes')
    [sq,dk,~,normx] = pcaengine(normx,ncomp-1,struct('plots','none','display','off'));
    if dk<ncomp-1
      error('The rank of the input data is less than number of requested components.')
    end
    sq = sq(1:ncomp-1,2)*(m(i1)-1);
    switch lower(options.distmeasure)
      case {'m','mahal','mahalan','mahalanobis'}
        %normalize by eigenvalues if mahalanobis requested
        normx = normx*diag(1./sqrt(sq));
    end
    ssq(i1) = prod(sq);
  else
    %not doing pca? base fake "ssq" on size of dim. The ssq is used ONLY to
    %do automatic choice of dim if selectdim is empty. Without the PCA
    %information, the easiest thing is to look at the size of the dim.
    ssq(i1) = size(normx,1);
  end
  %determine selections based on distance
  isel{i1} = goodnorm(distslct(normx,ncomp));


  if nargout>1  %if loadings were requested
    %get initial guess from current unfolded data
    loads{i1}      = unfoldedx(isel{i1},:);
    if strcmp(options.usennls,'yes')
      loads{i1}(loads{i1}<0) = 0;
    end
    loads{i1} = normaliz(loads{i1})';
  end
  
  if ishandle(hwait); waitbar(i1/p,hwait); end
end
if ishandle(hwait), waitbar(1,hwait); end

if nargout>1  %if loadings were requested
  
  %identify which mode we selected from and what the OTHER dim(s) is/are
  if isempty(options.selectdim)
    [~,selectdim] = max(ssq(:));
    selectdim        = min(selectdim);  %just in case there is a "tie"
  else
    selectdim        = options.selectdim;
  end
  otherdim = setdiff(1:p,selectdim);  %everything EXCEPT the one we selected on

  if p==2
    %two-way: simply start by copying the loadings
    loads{otherdim} = loads{selectdim};
  elseif p==3
    %3-way, unfold 
    for i1=otherdim
      loads{i1}      = zeros(m(i1),ncomp);
    end
    for i1=1:ncomp
      ld = reshape(loads{selectdim}(:,i1),m(otherdim));
      loads{otherdim(1)}(:,i1) = sum(ld,2);
      loads{otherdim(2)}(:,i1) = sum(ld,1)';
    end
    loads{otherdim(1)} = normaliz(loads{otherdim(1)}')';
    loads{otherdim(2)} = normaliz(loads{otherdim(2)}')';
  else
    %not available for nway>3
  end
  if strcmp(options.usennls,'yes')
    loads{selectdim} = fastnnls(outerm(loads,selectdim,1),unfoldmw(x,selectdim)')';
  else
    loads{selectdim} = unfoldmw(x,selectdim)/outerm(loads,selectdim,1)';
  end
  
  if selectdim~=options.samplemode
    %if the dim we selected from is NOT the same as the sample dim...
    loads{selectdim} = normaliz(loads{selectdim}',0,2)';  %normalize
    %and do one iteration of least squares to get the sample mode
    if strcmp(options.usennls,'yes')
      loads{options.samplemode} = fastnnls(outerm(loads,options.samplemode,1),unfoldmw(x,options.samplemode)')';
    else
      loads{options.samplemode} = unfoldmw(x,options.samplemode)/outerm(loads,options.samplemode,1)';
    end
  end
end

if ishandle(hwait), close(hwait), end

%re-index into include field
if ~isempty(include)
  for i1=1:length(isel)
    isel{i1} = include{i1}(isel{i1});
  end
end

%if a single output was requested AND a known selection dim was used,
%return ONLY the indices on the selected dim
if ~isempty(options.selectdim)
  isel = isel{options.selectdim};
end
