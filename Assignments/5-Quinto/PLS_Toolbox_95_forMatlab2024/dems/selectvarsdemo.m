echo on
% SELECTVARSDEMO Demo of the SELECTVARS function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
clear ans
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load data:
% The data consists of four dataset objects, two x-blocks
% and two y-blocks.  
load beer
whos

% For the purpose of this demo beer (UVVis/NIR spectra of beer) and extract
% (quality parameter) will be used.
pause
%-------------------------------------------------
% The SELECTVARS function can be used to create the selectvars options
% structure. To do this, run:

options = selectvars('options');
 
pause
%-------------------------------------------------
% SELECTVARS can use either VIP or SRATIO in the variable selection
% process. The method chosen can be set via the .method field. In addition
% to selecting method, the threshold for leaving out must also be selected.
% This is done as a fraction. So if set to .1, then ten percent of the 
% variables in each iteration as long as the error improves. The variables 
% with the lowest VIP or SRATIO are removed. 
% Note that AUTO is the default method which will test both VIP and SRATIO 
% and several thresholds.

options.method = 'vip';

% Remove the 20% lowest scoring variables in each run
options.fractiontoremove=.2
 
pause
%-------------------------------------------------
% Now call the SELECTVARS function and specificy 8 as the maximum
% number LVs for the internal PLS models.

results=selectvars(beer,extract,8,options);

% The results will be stored as a structure in the results variable
% and will appear in a figure for review.

%End of SELECTVARSDEMO
 
echo off


