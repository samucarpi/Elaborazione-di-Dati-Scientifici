function [ratio_min,ratio_mean,withindist,betweendist_mean,betweendist_min] = calculate_distanceratio(x,classset)
%CALCULATE_DISTANCERATIO Calculates ratio between mean intraclass distances and
% the minimum interclass centerpoint distance.
%   This an in-house quality metric that will give a ratio based on the
%   intraclass distances and interclass distances. The variable
%   'x' is the first argument and this is where we want to get the data
%   from. The 'classset' variable is a vector of classes that correspond
%   with the data. For each each unique class, the centerpoint is calculated first.
%   Then the mean distance (euclidean) between each data point and it's class center point
%   is calculated. These mean values for each class is later averaged into one mean intraclass distance. 
%   Then, the mean distance between each class's centerpoint is
%   calculated. The ratio then is this mean of the intraclass distances
%   divided by the minimum of the interclass distance between each class's
%   centerpoint.
%
% INPUTS:
%    x       = vector of data. (Class "double")
%  classset  = vector of classes that correspond with data in model object
%
%  OUTPUT:
%     ratio = Division of mean intraclass distances and minimum interclass
%             centerpoint distance.
%
%I/O: [ratio] = calculate_distanceratio(model,classset);
%
%See also: calcystats

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Clean x
if any(isnan(x(:)))
  [flag,missmap,x] = mdcheck(x);
end

[m,n] = size(x);
%Total number of clases
unique_classes = unique(classset);
%Not calculating for class 0
unique_classes = unique_classes(unique_classes~=0);
ncls = length(unique_classes);
withindist  = nan(1,ncls);
nsamp       = nan(1,ncls);
centerpoint = nan(ncls, n);
if ncls>1 && ~(isempty(classset))
  for ii=1:ncls  %unique_classes
    % Get data for each class
    indClass = find(classset==unique_classes(ii));
    Xoutclass = x(indClass,:);
    % Get centerpoint per class
    centerpoint(ii,:) = mean(Xoutclass, 1);
    inclassdist = euclideandist(Xoutclass,centerpoint(ii,:));
    % Mean intraclass distance
    withindist(ii) = mean(inclassdist);   % mean within dist for each class
    nsamp(ii)      = length(indClass);
  end
  
  withindist  = mean(withindist);
  % Interclass centerpoint distances
  betweendist = euclideandist(centerpoint);
  
  ncls = size(betweendist,1);
  idiag = 1:(ncls+1):ncls*ncls;
  iencl = setdiff(1:ncls*ncls, idiag);      % off-diag elements
  bdist = betweendist(:);
  betweendist_mean = sum(bdist)/(ncls*(ncls-1)); % div by #off-diag elems
  betweendist_min  = min(bdist(iencl));     % excl diagonal zeros
  
  ratio_mean = withindist/betweendist_mean; % ratio of mean distances
  ratio_min  = withindist/betweendist_min;  % ratio of within / min between
else
  ratio_mean = [];
  ratio_min  = [];
  withindist = [];
  betweendist_mean = [];
  betweendist_min = [];
end
end

