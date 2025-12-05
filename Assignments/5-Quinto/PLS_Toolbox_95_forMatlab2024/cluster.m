function [results,fig,distances] = cluster(dat,labels,options)
%CLUSTER Agglomerative and K-means cluster analysis with dendrograms.
%  This function performs a cluster analysis using either one of six
%  different agglomerative methods (including K-Nearest-Neighbor (KNN),
%  furthest neighbor, and Ward's method) or K-means clustering algorithm
%  and plots a dendrogram.
%  The input is (data) (class double or dataset).
%  Optional inputs are a character or cell matrix of sample labels (labels)
%  {default: if labels is empty, [], then sample numbers are used on the plots},
%  and options a structure array with the following fields:
%            plots: [ 'none' | {'final'} ] Governs plotting. When set to
%                    'none', the distance/cluster matrix is returned.
%        algorithm: Clustering algorithm, can have one of seven values:
%                   'knn': K-Nearest Neighbor
%                   'fn' : Furthest Neighbor
%                   'avgpair' : Average Paired Distance
%                   'med' : Median
%                   'cnt' : Centroid
%                   'ward' : Ward's Method  {DEFAULT}
%                   'kmeans' : K-means
%    preprocessing: {[]}  Preprocessing structure or keyword (see PREPROCESS)
%              pca: [ {'off'} | 'on' ]  on = Perform PCA on input
%                   data and perform cluster analysis on results.
%            ncomp: Number of PCA components to use. [] (empty) = manual
%                   selection from SSQ table. Default = []
%      mahalanobis: [ {'off'} | 'on' ]  on = Use Mahalanobis distance
%                   on the PCA scores.
%            slack: [0] integer number indicating how many samples can be
%                   "overridden" when two class branches merge. If the
%                   smaller of the two classes has no more than this number
%                   of samples, the branch will be absorbed into the larger
%                   class. This feature is only valid when classes are
%                   supplied in the input data. A value of 0 (zero)
%                   disables this feature.
%         maxlabels:[ 200 ] defines the maximum number of labels which will
%                    be shown on the dendrogram. If more than this number 
%                     of samples exist, no labels will be shown.
%         distance: [{'euclidean'} | 'manhattan' ] a string to choose the
%                   type of distance to use.
%
%  If options.plots is 'final' (the default) the output is a dendrogram
%  plot showing sample distances.
%  The outputs are (results) a structure containing results of the
%  clustering (defined below), the handle (fig) to any plot created, and
%  (distances) the raw sample-to-sample distance matrix (output distances
%  is not available when algorithm = 'kmeans'.)
%
%  The results structure will contain the following fields:
%
%    dist  : the distance threshold at which each cluster forms
%    class : the classes of each sample (columns of class) for each
%             distance (rows of class).
%    order : the order of the samples which locates similar samples nearest to
%             each other (this is the order used for the plots)
%    linkage : a table of linkages where each row indicates a linkage of
%              one group to another. Each row in the matrix represents one
%              group. The first two columns indicate the sample or group
%              numbers which were linked to form the group. The final
%              column indicates the distance between linked items. Group
%              numbers start at m+1 (where m is the number of samples in
%              the input dat matrix) thus, row j of this matrix is group
%              number m+j. This matrix can be used with the statistics
%              toolbox dendrogram function.
%
%  The (results.class) matrix can be used with the (results.dist) matrix to
%  determine clusters of samples for any distance using:
%   results   = cluster(data);   %do cluster
%   ind       = max(find(results.dist<threshold));  %user-desired threshold
%   thisclass = results.class(ind,:);   %grab arbitrary classes
%
%I/O: [results,fig,distances] = cluster(data,labels,options);
%I/O: [results,fig,distances] = cluster(data,options);
%I/O: cluster demo
%
%See also: ANALYSIS, CORRMAP, DBSCAN, DENDROGRAM, GCLUSTER, KNN, KNNSCOREDISTANCE, SIMCA

%Copyright © Eigenvector Research, Inc. 1993
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified BMW 5/94,2/95, NBG 10/96,4/99
%NBG 2/02 removed screen output
%JMS 8/02 v3 format inputs
%JMS 10/04 fixed output of figure # if no output requested
%JMS 3/1/05 added output of classes
%JMS 5/28/05 added output of order, use results structure, modified help
%CEM 11/6/07 added option for 6 different agglomerative methods(incl Ward's
%method)
%BK 6/2/2016 added options.maxlabels to change the max amount of labels

if nargin == 0;
  analysis cluster
  return
end

varargin{1} = dat;
if ischar(varargin{1});
  options = [];
  options.name          = 'options';
  options.plots         = 'final';
  options.algorithm     = 'ward';
  options.preprocessing = {[]};
  options.pca           = 'off';
  options.ncomp         = [];
  options.mahalanobis   = 'off';
  options.slack         = 0;
  options.maxlabels     = 200;
  options.distance      = 'euclidean';

  if nargout==0; evriio(mfilename,varargin{1},options); else; results = evriio(mfilename,varargin{1},options); end
  return;
end

switch nargin
  case 1
    % (data)
    labels = [];
    options = [];
  case 2
    if isstruct(labels);  %this is options, not labels!
      % (data,labels)
      options = labels;
      labels  = [];
    else
      % (data,options)
      options = [];
    end
  case 3
    % (data,labels,options)
end


options = reconopts(options,mfilename);
options.pca         = lower(options.pca);
options.mahalanobis = lower(options.mahalanobis);
options.distance = lower(options.distance);

% if pca is enabled, disable Manhattan distance.
if strcmp(options.pca,'on') & strcmp(options.distance,'manhattan')
  warning('Use PCA enbled. Euclidean distance used.');
  options.distance = 'euclidean';
end

%convert dat to dataset if it isn't
if ~isdataset(dat);
  dat = dataset(dat);
end

if mdcheck(dat)
  [flag,missmap,dat] = mdcheck(dat);
  dat.data(isnan(dat.data)) = 0;  %any samples with unreplacible data get assigned zero
end

%Handle Preprocessing
if isempty(options.preprocessing);
  options.preprocessing = {[]};  %reinterpet as empty cell
end
if ~isa(options.preprocessing,'cell');
  options.preprocessing = {options.preprocessing};  %insert into cell
end

%preprocess
if ~isempty(options.preprocessing{1})
  [dat,pp] = preprocess('calibrate',options.preprocessing{1},dat);
  %get preprocessing description
  names = {pp.description};
  desc = sprintf('%s + ',names{1:end-1});
  desc = [desc names{end}];
else
  desc = [];
end

% extract classes etc.
inds   = dat.includ;
if isempty(labels);
  if ~isempty(dat.label{1});
    labels = dat.label{1}(inds{1},:);
  end
end
classes = dat.class{1};
if ~isempty(classes);
  classes = classes(inds{1});  %index with include field
end
classlookup = dat.classlookup{1};
dat = dat.data(inds{:});                % dat is now not a dataset


if prod(size(dat)) == 1 || min(size(dat,1)) == 1;
  error('Data must be a matrix')
end

if strcmp(options.pca,'on');
  opts         = [];
  opts.display = 'off';

  if isempty(options.ncomp) | options.ncomp == 0;
    options.ncomp = choosencomp(pcaengine(dat,opts));
    if isempty(options.ncomp)
      %User cancel.
      results = [];
      distances = [];
      fig = [];
      return;
    end
  end
  [ssq,datarank,loads,scores] = pcaengine(dat,options.ncomp,opts);

  if strcmp(options.mahalanobis,'on')
    dat = auto(scores);
  else
    dat = scores;
  end
end

%-------------------
%
% initialize clustering arrays
%
[m,n] = size(dat);
%
% if K-means clustering, use existing clustering loop.  Otherwise, use new
% AGCLUSTER function
%
try
  
  if strcmp(options.algorithm,'kmeans')
    adat  = [(1:m)' zeros(m,m) dat];
    ins   = zeros((m-1)*2,m+2);
    for k = 1:m-1
      drawnow
      %K-Means
      dist = ones(m-k,m-k)*inf;
      for i = 2:m-k+1
        for j = 1:i-1
          dist(i-1,j) = sqrt(sum((adat(i,m+2:m+n+1) - adat(j,m+2:m+n+1)).^2));
        end
      end
      [mind,yind] = min(dist);
      [mind,xind] = min(mind);
      yind = yind(xind);
      ins(k*2-1:k*2,1:m) = adat([xind yind+1]',1:m);
      ins(k*2-1:k*2,m+1) = [1 1]'*mind;
      nsamp = zeros(1,m+n+1);
      sampvect = [adat(xind,1:m) adat(yind+1,1:m)];
      samplocs = find(sampvect);
      sampnos = sampvect(samplocs);
      [d,ns] = size(sampnos);
      nsamp(1,m+2:m+n+1) = sum(dat(sampnos',:))/ns;
      nsamp(1,1:ns) = sampnos;
      nsamp(1,m+1) = mind;
      ins(k*2-1,m) = adat(xind,m+1);
      ins(k*2,m) = adat(yind+1,m+1);
      adat = delsamps(adat,[xind yind+1]);
      adat = [adat; nsamp];
    end
    
  else
    %K-NN, AND OTHER AGGLOMERATIVE CLUSTERING METHODS
    % Calculate distance
    switch (options.distance)
      case 'euclidean'
        dist = euclideandist(dat,struct('diag',inf));
      case 'manhattan'
        dist = manhattandist(dat,struct('diag',inf));
      otherwise
        dist = euclideandist(dat,struct('diag',inf));
    end
    
    %
    % At this point, have the inter-point distance matrix (dist), call the
    % agglomerative clustering function "AGCLUSTER" to do clustering
    %
    [orderag,ins] = agcluster(dist,options.algorithm);
    %
    %
    %
  
  end
  distances = dist;
  
catch
  if ~isempty(findstr(lasterr,'Out of memory'))
    error('Too many samples to analyze (Out of memory). Reduce number of samples and retry.')
  else
    rethrow(lasterror);
  end
end


waitbarhandle = waitbar(.5,'Finalizing Clustering');
drawnow;

if strcmp(options.algorithm,'kmeans')
  order = adat(1,1:m);
else
  order = orderag;
end
lookup(order)=1:length(order);  %create order lookup table (based on index)
for i = 1:2*(m-1)
  ni = full(sum(ins(i,1:m-1)>0));  %Determine the number of non-zero elements
  if ni == 1                 %   If the number = 0
    ins(i,m+2) = lookup(ins(i,1));   %set yval equal to its order
  else                       % Otherwise
    subords = lookup(ins(i,1:ni));
    ins(i,m+2) = (min(subords)+max(subords))/2;
  end
end
%make sure labels are in order (and exist as needed)
if ~isempty(labels)
  if iscell(labels);
    if size(labels,1)==1;
      labels = labels';
    end
    labels=char(labels);
  end
else
  labels = num2str([1:m]');
end
labels = labels(order,:);

%calculate class assignment tree and extract distance info
isz = size(ins);
cls = repmat([1:m+1]-1,isz(1)/2,1);
for j=1:isz(1)/2;
  incls = ins(2*j-1:2*j,1:end-3)+1;
  cls(j:end,incls(:)') = cls(j,incls(1));
end
cls = cls(:,2:end);
dist = ins(1:2:end,isz(2)-1);

%create ML Toolbox-style linkage tree
gmap = 1:m;
links = [];
for j=1:isz(1)/2;
  g = gmap(ins(j*2-1:j*2,1)');     %grab the groups we're merging
  links(j,1:3) = [g ins(j*2,end-1)]; %note the grouping
  gmap(ismember(gmap,g)) = j+m;      %and assign all those group's members to the new group
end

fig = [];
threshold=[];

if strcmp(options.plots,'final');
  if isfield(options,'targetfigure') && ~isempty(options.targetfigure)
    fig = figure(options.targetfigure);
  else
    fig = figure;
  end

  clusterdata = struct(...
    'order',order,...
    'options',options,...
    'classes',classes,...
    'classlookup',{classlookup},...
    'ins',ins,...
    'labels',labels,...
    'm',m,...
    'n',n,...
    'desc',desc,...
    'dist',dist,...
    'cls',cls,...
    'xincl', inds{1}...
    );

  dendrogram(fig,clusterdata);
end

if ishandle(waitbarhandle)
  delete(waitbarhandle);
end

if nargout>0;
  
  results.dist  = dist;
  results.class = cls;
  results.order = order;
  results.linkage = links;
  
  if ~isempty(fig) & ishandle(fig)
    try
      threshold = getappdata(fig,'clusterdata');
      if ~isempty(threshold) & isfield(threshold,'threshold')
        threshold = threshold.threshold;
      end
    end
  end
  results.threshold = threshold;
end

%------------------------------------------------------------
function [order,indices] = agcluster(dist,cmethod,cwaitbar)
%AGCLUSTER Performs Agglomerative Cluster Analysis.
%  This function performs agglomerative cluster analysis using one of six
%  different methods, using the Lance-Williams Updating Formula. It is
%  generally called through CLUSTER.
%
%  INPUTS:
%      dist = m by m (m = # of objects)distance matrix containing the
%              distances between all possible combinations of objects
%   cmethod = a string indicating the clustering method to be performed
%            'knn' = nearest neighbor
%            'fn' = farthest neighbor
%            'avgpair' = average paired distance
%            'cnt' = centroid
%            'med' = median
%            'ward' = Ward's Method (minimum variance)
%  cwaitbar = [ 'off' | {'auto'}] governs display of waitbar. 'auto'
%                 shows waitbar when analysis will take longer than a
%                 preset amount of time. 'off' disables the waitbar
%                 entirely.
%
%  OUTPUTS:
%   order = a 1 by m array containing the indeces of the original m
%   objects, in the order that they are to be listed on the y-axis of the
%   dendrogram
%
%   indices = (m-1)+3 by (m-1)*2 matrix, where
%       - each PAIR of rows corresponds to two clusters to be joined
%       - the 1st m-1 columns contain object indices denoting object
%          membership to clusters to be joined
%       - column m contains the maximum of the inter-sample distances
%          within a multi-sample cluster (0 if a single-sample cluster)
%       - column m+1 contains the distance between clusters, according to
%          the clustering method selected, and
%       - column m+2 contains the y-axis values on the dendogram where the
%          cluster is to be plotted
%
%I/O: [order, indices] = agcluster(dist,cmethod,options);
%
%See also: CLUSTER, GCLUSTER

%Copyright © Eigenvector Research, Inc. 1993-2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
% Acknowledgement to Prof. Steven D. Brown, University of Delaware, for
% providing example code
%
% CEM 11/6/07

if nargin<3;
  cwaitbar = 'auto';
end

cmethod = lower(cmethod);

%
%
% The Lance-Williams method requires the definition of four parameters.
% For three of the cluster methods, these parameters are fixed throughout
% the clustering process (the other three depend on the numbers of objects
% in existing clusters, which is updated after each clustering cycle)
%
%
[m,dum] = size(dist);
[adat,amindis,indices] = allocate_matrices(m);

LWparm = zeros(1,4);

switch cmethod
  case 'knn'
    LWparm = [0.5 0.5 0 -0.5];
  case 'fn'
    LWparm = [0.5 0.5 0 0.5];
  case 'med'
    LWparm = [0.5 0.5 -0.25 0];
  case 'ward'
    nh = ones(m,1);
end;

%
%initialize calcs for waitbar
%
waitbarhandle = [];
startat = now;
lastreport = now;
if strcmp(cwaitbar,'auto')
  trigger = 15;   %>this number of seconds estimated and we'll give a waitbar
else
  trigger = inf;
end
comb_total = ((m*(m+1))/2)-1;

%
% MAIN CLUSTERING LOOP BEGINS HERE
%
k=1;
while k<m;

  %
  % search for minium value in entire dist matrix. get row and column index
  % of that value (note, order of these instructions assures only an
  % upper-triangular point even though dist is symmetric).
  %
  if k==1;
    [colmin,colmin_where] = min(dist,[],1);
  end
  [minimald,where2]     = min(colmin,[],2);
  ilow = where2;
  jlow = colmin_where(where2);

  %
  % need to account for the (unlikely) case where more than one cluster
  % pair have the same separation distance- keep track of these pairs
  % also...
  %  
  if sum(colmin==minimald)>2 | sum(dist(:,ilow)==minimald)>1
    %
    % if more than two pairs of clusters have equal distances, then need a
    % "tie-breaker" to determine which pair to join together.  In this case,
    % the two clusters of most equal sizes are linked in preference to those
    % of different sizes CONTINUE HERE!!!!!
    %
    [ipair,jpair] = find(dist==minimald);
    use    = jpair>ipair;  %only use upper diagonal items (faster than triu)
    ipair  = ipair(use);
    jpair  = jpair(use);
    nminim = length(ipair);  %determine how many we had
    
    [i1,i2] = size(find(adat(ilow+1,:)));
    [i3,i4] = size(find(adat(jlow,:)));
    memb=i2+i4;
    for ij=1:nminim-1
      itest=ipair(ij);
      jtest=jpair(ij);
      [i1,i2] = size(find(adat(itest+1,:)));
      [i3,i4] = size(find(adat(jtest,:)));
      test=i2+i4;
      if(test <= memb)
        xind=jtest; %link clusters of nearest size
        yind=itest; %otherwise link last set of equally-sized clusters
      else
        xind=ilow;
        yind=jlow;
      end;
    end;
  else
    %no tie to break, just use single found item
    xind = ilow;
    yind = jlow;
  end;
  %
  %
  %
  [i1,i2] = size(find(adat(yind,:)));
  [i3,i4] = size(find(adat(xind,:)));
  indices(k*2-1:k*2,1:m) = adat([xind yind]',:);
  indices(k*2-1:k*2,m+1) = [1 1]'*minimald;
  nsamp    = zeros(1,m);
  sampvect = [adat(xind,:) adat(yind,:)];
  sampnos  = sampvect(sampvect>0);
  ns       = length(sampnos);
  %
  % Now the Lance-Williams parameters for the other 3 options can be
  % determined
  %
  switch cmethod
    case 'avgpair'
      ni = i2;
      nj = i4;
      nk = i2+i4;
      LWparm = [ni/nk,nj/nk,0,0];
    case 'cnt'
      ni = i2;
      nj = i4;
      nk = i2+i4;
      LWparm = [ni/nk,nj/nk,-ni*nj/(nk^2),0];
    case 'ward'
      ni = i2;
      nj = i4;
      nk = i2+i4;
      
      %for ward ONLY, LWparm is matrix (vector for all others)
      LWparm = [(nh+ni)./(nh+nk),(nh+nj)./(nh+nk),-nh./(nh+nk),nh.*0];
  end;
  %
  % determine new inter-cluster distances, using LW updating formula
  %

  %vectorized application of LWparm
  ndist =  LWparm(:,1).*dist(:,xind) + LWparm(:,2).*dist(:,yind) + LWparm(:,3).*dist(xind,yind) + LWparm(:,4).*abs(dist(:,xind)-dist(:,yind));
  ndist = single(ndist);

  nsamp(1,1:ns)    = sampnos;
  indices(k*2-1,m) = amindis(xind);
  indices(k*2,m)   = amindis(yind);

  %
  % remove old distances
  %
  dist(:,xind)    = ndist;  %replace xind with new group
  dist(xind,:)    = ndist';
  dist(xind,xind) = inf; % (note diag as infinite)
  adat(xind,:)    = nsamp;
  amindis(xind)   = minimald;
  nh(xind)        = ns;     %update nh (for ward's distance only)

  dist(yind,:) = inf;     %remove yind altogether
  dist(:,yind) = inf;
  adat(yind,:) = inf;
  nh(yind)     = inf;
  
  %
  %update colmin values based on replaced values
  % (we do this instead of recalculating the grand minimum using min(dist)
  %   because this approach is MUCH faster)
  %

  %is new row lower than previous minimum? use it
  islow = (ndist'<colmin);  
  colmin(islow)       = ndist(islow);
  colmin_where(islow) = xind;
  
  %was dropped row or modified row the minimum on any column? recalculate that column
  islow = (colmin_where==yind | colmin_where==xind);
  islow(xind) = true;  %also recalculate for new column
  [colmin(islow),colmin_where(islow)] = min(dist(:,islow),[],1);
  
  %inf out column and row we've dropped
  colmin(yind) = inf;
  colmin_where(yind) = 1;

  %
  %move to next cluster
  %

  k=k+1;

  %
  %show waitbar if it will take us a long time to finish
  %
  if (now-startat)*24*60*60>3 & (now-lastreport>10/24/24/60 | mod(k,min(100,fix(m/20)))==0)
    lastreport = now;
    pct = 1-((((m-k+1)*((m-k+1)+1)/2)-1)./comb_total);
    est = ((now-startat)*24*60*60)/pct;
    if ~isempty(waitbarhandle)
      if ishandle(waitbarhandle)
        waitbar(pct);
      else
        error('User canceled clustering');
      end
    elseif est > trigger
      waitbarhandle = waitbar(pct,'Clustering (Close to cancel)');
    end
    if ~issparse(indices)
      name = ['Est. Time Remaining: ' besttime((1-pct)*est)];
    else
      name = [num2str(fix(pct*100)) '% complete'];
    end
    set(waitbarhandle,'name',name); drawnow
  end

end;
%
% end of main clustering loop
%
%
if ishandle(waitbarhandle)
  delete(waitbarhandle)
  drawnow;
end

%figure out which to use
row = min(find(isfinite(adat(:,1))));
order = adat(row,1:m);

%---------------------------------------------------------------
function [adat,amindis,indices] = allocate_matrices(m)

try
  %first try with single precision adat and normal indices
  adat = [(1:m)' repmat(single(0),m,m-1)];
  amindis = zeros(m,1);
  indices = zeros((m-1)*2,m+2);
catch
  if ~isempty(findstr(lasterr,'Out of memory'))
    try
      %try with indices being sparse only
      adat = [(1:m)' repmat(single(0),m,m-1)];
      amindis = zeros(m,1);
      indices = sparse((m-1)*2,m+2);
    catch
      if ~isempty(findstr(lasterr,'Out of memory'))
        %couldn't do it with "full" matrices, try all sparse (will be much
        %slower, but may actually work, at least!)
        adat = sparse(m,m);
        adat(:,1) = 1:m;
        amindis = zeros(m,1);
        indices = sparse((m-1)*2,m+2);
      else
        rethrow(lasterror);
      end
    end
  else
    rethrow(lasterror);
  end
end
