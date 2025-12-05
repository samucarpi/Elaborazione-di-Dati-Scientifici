echo on
% CLUSTERDEMO Demo of the CLUSTER function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%bmw
%CEM revised 11/8/07 to include new clustering options
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The CLUSTER function is used to determine "natural" groupings of objects
% (samples or variables) in a data matrix.  This function produces a
% "dendrogram" plot, where the most similar objects are placed next to each
% other.
%-------------------------------------------------
% First, we'll use cluster to determine "natural" groupings of samples in
% a subset of the ARCH data set.....
%
pause
%-------------------------------------------------
%
%
load arch
arch.includ{1} = find(arch.class{1}~=4 & arch.class{1}~=0);
 
options = [];
options.preprocessing = {'autoscale'};
cluster(arch,options)
%
% Note that the lines on the dendrogram are color-coded according to the
% pre-assigned class 1 variable, which in this case is the quarry location.
% Note also that the samples "naturally" cluster according to their quarry
% location, which indicates that the variables in the dataset are useful
% for distinguishing between quarry location
%
pause
% ------------------------------------------------
% This example uses the default clustering algorithm of K-Nearest-Neighbor
% (or "KNN").  However, there are six other clustering algorithm options
% that are available, which could be more effective for some applications.
% 
% Next, we'll try the "Furthest Neighbor" clustering algorithm on the same
% data......
%
pause
%-------------------------------------------------
options.algorithm = 'fn';
cluster(arch,options)
%
% First of all, note that the same groups of samples tend to cluster
% together- even though the "finer structure" of the dendrogram is somewhat
% different, due to the different clustering criterion used
%
% However, also note that the use of this (furthest neighbor) clustering
% algorithm appears to reveal two "subgroups" of the "BL" quarry samples:
% one containing "BLAV1", "BLAV7" and "BL8", and the other
% containing the rest
%
pause
%-------------------------------------------------
% Finally, we'll try another popular clustering algorithm, called "Ward's
% Method".  This method is unique from all others in that it explicitly
% considers the "within-cluster" variance during the clustering process...
%
pause
%-------------------------------------------------
options.algorithm = 'ward';
cluster(arch,options)
%
% Note that the Distance scale (X-axis)is quite different for this method,
% as the distance measure considers the variance WITHIN clusters as well as
% separation BETWEEN clusters.
%
% Also, note that the separation of the "BL" samples into two groups, which
% was first-discovered using the Furthest Neighbor method, is
% even better-defined when using this method!
%
pause
%-------------------------------------------------
% END OF CLUSTER DEMO
echo off
