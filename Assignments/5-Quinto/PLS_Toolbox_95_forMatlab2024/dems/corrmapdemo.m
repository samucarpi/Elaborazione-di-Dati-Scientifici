echo on
% CORRMAPDEMO Demo of the CORRMAP function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%bmw
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The CORRMAP function is used to generate a pseudocolor map showing
% what variables are most closely correlated with each other in a
% given data matrix. Variables can be reordered on the map so that
% the most highly correlated variables are next to each other.
 
% As an example, consider the ARCH data set, which consists of the
% elemental analysis of 75 obsidian samples. We'll load up the arch.mat
% data file and look at the Dataset now
 
load arch
arch
 
pause
%-------------------------------------------------
% We can now call the CORRMAP function to create a map showing how
% the variables are correlated with each other as follows:
 
inds = corrmap(arch);
 
pause
%-------------------------------------------------
% The new ordering of the variables is output in the variable "inds". 
% Note how variables which are very highly correlated, like K and Rb,
% are grouped together in the plot.
 
% We can also do a map where the varables are not reordered by adding
% a flag of 0 to the input.
 
inds = corrmap(arch,0);
 
% Notice how disordered this plot looks compared to the first plot.
 
pause
%-------------------------------------------------
% CORRMAP also accepts single matrices as inputs, along with separate
% labels. See help for more info.
 
echo off
  
   
