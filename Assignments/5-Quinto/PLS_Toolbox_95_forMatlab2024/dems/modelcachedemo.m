echo on
% MODELCACHEDEMO Demo of the model cache function and object
  
echo off
% Copyright © Eigenvector Research, Inc. 2024 Licensee shall not
%  re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%jms 
 
clear ans
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The MODELCACHE is function that uses the evricachedb object to store and
% retrieve models (and infomation) built during the modeling process. This
% is a simple call to the modelcache function to test the cache. 
%
% NOTE: For large caches this may take some time to complete.
 
pause
 
%-------------------------------------------------
 
modelcache list
 
%End of MODELCACHEDEMO
 
echo off