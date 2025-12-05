echo on
%PCAENGINEDEMO Demo of the PCAENGINE function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load data: This data consists of two parts. A model will be built on part
% 1 and applied to part 2.
 
load pcadata
 
whos
 
pause
%-------------------------------------------------
% PCAENGINE is a lower level routine to perform a PCA decomposition. It
% takes only regular Matlab arrays and it does no plots but can optionally
% display the sum-of-squares table. The outputs are the basic results of
% the decomposition. For comparison, see the function PCA which outputs an
% organized model structure.
% 
 
pause
%-------------------------------------------------
% The data must first be preprocessed before calling PCAENGINE. In this
% case, the data will be autoscaled.
%
 
[part1.data,mn,sd] = auto(part1.data);         %auto scale based on part 1
 
pause
%-------------------------------------------------
% To perform a PCA decomposition, the PCAENGINE function is called with the
% data (in this case, extracted from the part1 DataSet) and the number of
% requested components. Although the PCAENGINE has various options, a call
% without the third input (options) will use the default options.
% Here is the call to return three principal components from the part1 data:
%
 
[ssq,datarank,loads,scores,msg] = pcaengine(part1.data,3);
 
pause
%-------------------------------------------------
% The outputs from PCAENGINE include the sum-of-squares table (ssq), the
% mathematical rank of the data (datarank) and the loads and scores from
% the decomposition (loads, scores).
%
 
whos
 
pause
%-------------------------------------------------
% The loads are orthonormal and can be used to predict scores from "new"
% data, done here for the part2 data.
% 
% First, the autoscaling is applied to the part2 data, then the new data is
% projected into the model.
 
part2.data  = scale(part2.data,mn,sd);  %apply scaling to part 2
newscores   = part2.data * loads;
 
%End of PCAENGINEDEMO
 
echo off
