function [distance,nearest] = knnscoredistance(model,pred,k,options)
%KNNSCOREDISTANCE Calculate the average distance to the k-Nearest Neighbors in score space.
% Given a factor-based model (PCA, PLS, PCR, MCR, etc), this function
% returns the average distance to the k nearest neighbors (in score space)
% for each sample. This value is an indication of how well sampled the
% given region of the scores space is.
%
% If only a model and number of neighbors is given, the KNN Distance for
% the calibration set is calculated (this can be used as a reference for
% what is acceptable for a test sample). If both a model and a prediction
% structure are input along with the number of neighbors, the KNN Distance
% is calculated for the prediction samples.
%
%INPUTS:
%   model = Standard model structure of a factor-based model or raw data
%           matrix or DataSet object.
%OPTIONAL INPUTS:
%        k = Number of neighbors to average the distance to. If omitted or
%            empty [], k=3 is used.
%     pred = Standard prediction structure from applying the input model
%            (model) to test data.
%  options = Options structure containing one or more of the fields:
%
%       maxsamples : [ 2000 ] Maximum number of samples for which score
%                     distance will be calculated for. If a dataset (model
%                     or prediction) has more than this number of samples,
%                     the score distance will be returned as all NaN's.
%                     This is because the algorithm can be quite slow with
%                     many samples.
%OUTPUTS:
%   distance = average distance to the k nearest neighbors for each sample.
%    nearest = sample index of the one closest sample for each sample.
%
%I/O: distance = knnscoredistance(model,k,options)
%I/O: distance = knnscoredistance(model,pred,k,options)
%
%See also: CLUSTER, KNN, PCA, PLOTSCORES, PLS, REDUCENNSAMPLES

%Copyright Eigenvector Research 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0; model = 'io'; end
if ischar(model)
  options = [];
  options.maxsamples = 2000;
  if nargout==0; evriio(mfilename,model,options); else; distance = evriio(mfilename,model,options); end
  return
end

%- - - - - - - - - - - - - - - - - - - - - - - - - 
%parse inputs
switch nargin
  case 1
    % (model)
    k       = [];
    pred    = [];
    options = [];
  case 2
    % (model,k)
    % (model,pred)
    if isnumeric(pred) & numel(pred)==1
      k    = pred;
      pred = [];
    else
      k = [];
    end
    options = [];
  case 3
    % (model,k,pred)
    % (model,k,options)
    % (model,pred,k)
    if isnumeric(pred) & numel(pred)==1
      if ismodel(k)
        % (model,k,pred)
        temp = pred;
        pred = k;
        k    = temp;
        options = [];
      else
        % (model,k,options)
        options = k;
        k       = pred;
        pred    = [];
      end
    else
      options = [];
    end
  case 4
    % (model,pred,k,options)
    % (model,k,pred,options)
    if isnumeric(pred) & numel(pred)==1
      % (model,k,pred,options)
      temp = pred;
      pred = k;
      k = temp;
    end
  otherwise
    error('Incorrect usage')
end

options = reconopts(options,mfilename);

if isempty(k)
  k = 3;
end

%- - - - - - - - - - - - - - - - - - - - - - - - - 
%get model information we need
if ~ismodel(model);
  %scores only
  if isdataset(model)
    incl = model.include;
    sc   = model.data(:,incl{2:end});
    incl = incl{1};
  else  %non-dataset
    sc = model;
    incl = 1:size(sc,1);
  end
else
  %model structure
  sc   = model.loads{1};
  incl = model.detail.includ{1,1};
end

%get scores we're PREDICTING for
if isempty(pred)
  pred = sc;
  noself = true;
else
  if ismodel(pred)
    pred = pred.loads{1};
  elseif isdataset(pred)
    pincl = pred.include;
    pred = pred.data(:,pincl{2:end});
  end
  noself = false;
end

distance = zeros(size(pred,1),1)*nan;
nearest  = distance;

if size(pred,1)>options.maxsamples
  %if more than this number of samples, do NOT do distance, return NaN's
  %for all
  return
end

%----
% Theoretically, we could do the following to get the score distance:
%
% for j=1:size(pred,1); 
%   dist = sum((scale(sc(incl,:),pred(j,:))).^2,2);
%   what = sort(dist); 
%   kuse = (1:k) + noself*ismember(j,incl);   %get maximum index we'll need
%   distance(j,1) = mean(what(kuse)); 
% end
%
% However, in practice this is VERY slow (scale and sort take a long time),
% instead we'll use the more convoluted but MUCH faster algorithm below.

pc = size(sc,2);
scc = sc(incl,:);   %will hold centered scores
sqreig = sqrt(sum(scc.^2)./(length(incl)-1)).*pc;  %corrects for eigenvalues AND number of LVs
nearest = zeros(size(pred,1),1)*nan;
nsamps = size(pred,1);
wb = [];
starttime = now;
for j=1:nsamps; 
  %using this method of centering because it is faster than "scale"
  for pci=1:pc;
    %center each column to the item in question
    scc(:,pci) = (sc(incl,pci)-pred(j,pci))./sqreig(pci);
  end
  dist = sqrt(sum(scc.^2,2));   %calculate sum-squared-values (=distance)
  
  % Instead of simple "sort" which can be slow, use the following:
  %   dist = mmin(dist,k);    %apply "thinning" algorithm defined below
  kuse = (1:k) + noself*ismember(j,incl);   %get maximum index we'll need
  for ind = 1:max(kuse);
    [what(ind),where] = min(dist);   %get the nearest point
    dist(where) = inf;   %mark it as "inf" so we don't find it again next cycle
    if ind==kuse(1)
      nearest(j) = where;
    end
  end   %repeat until we have as many points as we need for selection below

  %now, select the k nearest points (either 1:k or 2:k+1 depending on if
  %point in question is in sc)
  distance(j,1) = mean(what(kuse));   
  
  if mod(j,10)==0
    %handle waitbar
    est = (now-starttime)/j*(nsamps-j)*60*60*24;
    if (~isempty(wb) | est>15)
      if isempty(wb)
        wb = waitbar(j/nsamps,'Analyzing distances');
      end
      disp('');
      if ~ishandle(wb)
        error('Aborted by user')
      end
      waitbar(j/nsamps,wb);
      set(wb,'name',['Est. Time ' besttime(est)]);
    end
  end
  
end
if ishandle(wb)
  close(wb);
end
nearest = incl(nearest);

%===========================================
% "thin out" dist by dropping points which are < the second point in the
% vector (arbitrarily chosen, as good as any other when you have a random
% vector.) By simple random chance, this should reduce the number of points 
% in dist by a factor of 2 which will make the next step that much faster
% The trick is keeping the just-previous vector around (as dist) and
% noticing if our new vector (ndist) has dropped to or below the number of
% points we are going to be looking for. In practice for a random set of
% data, we saw reductions on the order of 500 fold with an average of 7-8
% iterations

function dist = mmin(dist,k)

ndist = dist; 
while length(ndist)>k;   %as long as our new vector has more than k samples
  dist = ndist;          %note the most recent "new" vector
  ndist = dist(dist<dist(2)/2);    %and see if we can drop some large-distance samples and still be >k in length
end
