echo on
%COREANALDEMO Demo of the COREANAL function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rb
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load amino acid data set:
 
load aminoacids
 
% Fit a 3x3x3 - component Tucker3 model (reasonable
% number of components). 
pause
%-------------------------------------------------
model = tucker(X,[3 3 3]);
 
% The core is held in model.loads{end} and gives
% a description of the interactions between different
% components in different modes. 
% 
% Extract the core for more easy access
pause
%-------------------------------------------------
 
core = model.loads{end};
pause
%-------------------------------------------------
% In order to have an overview of the elements
% use COREANAL to plot the core. 
pause
%-------------------------------------------------
close
coreanal(core,'plot');
 
 
% As can be seen, the element (1,1,1) is especially
% large indicating that the combination of the first
% component in all three modes explains the most 
% variation. In order to get a more quantitative 
% view on that, a list can be produced of the
% importance of each combination
pause
%-------------------------------------------------
close
coreanal(core,'list');
 
% The first four combinations seem to be the most 
% important ones, explaining 91% of the variance 
pause
%-------------------------------------------------
% It is possible to rotate the core to see if 
% a more suitable rotation exists. Suitable in
% this case, means explaining as much variance 
% with as few elements as possible. Usually,
% for unconstrained Tucker models, the improvements
% are only small though
 
pause
%-------------------------------------------------
rotcore = coreanal(core,'maxvar');
coreanal(rotcore.core,'list');
 
% As can be seen, no strong improvements appear
% in the first most important combinations.
 
 
% See "help coreanal" or "coreanal help".
%
%End of COREANALDEMO
 
echo off
