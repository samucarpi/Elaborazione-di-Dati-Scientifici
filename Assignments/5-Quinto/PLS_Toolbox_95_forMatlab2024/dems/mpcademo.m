echo on
% MPCADEMO Demo of the MPCA function
 
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
% The MPCA function is used to develop PCA models on unfolded multi-way
% data. We'll demonstrate with some excitation emission data from a
% a sugar product process. Each of the 268 samples is a matrix of the
% emission at each of 44 wavelengths for each of 7 excitation wavelengths. 
 
% Hit a return and we'll load the data and show the contents of the dataset
% object containing the data
 
pause
%-------------------------------------------------
load sugar
 
sugar
 
pause
%-------------------------------------------------
% Now we have to set up the options structure for MPCA. A default options
% structure can be obtained from:
 
options = mpca('options')
 
pause
%-------------------------------------------------
% In this case the sample mode is the first one, so we need to change that
% in the options
 
options.samplemode = 1;
 
pause
%-------------------------------------------------
% Now we're ready to call MPCA. We'll specify a 3 PC model. Once its called, 
% it will bring up a plot window to allow plotting of the scores and loads. 
% Note that the different months (Oct, Nov, Dec, Jan) are each different 
% colored points in the scores plots. Hit a return when ready:
 
pause
%-------------------------------------------------
mod = mpca(sugar,3,options);
 
pause
%-------------------------------------------------
% As you can see if you explored the model a little bit, the loadings of
% MPCA models are quite hard to interpred. It is easier if they are folded
% back up into the original size as shown next. Of course, using PARAFAC 
% might provide a simpler solution altogether for multi-way data.
 
figure
subplot(1,2,1)
mesh(reshape(mod.loads{2}(:,1),44,7))
title('Loadings for First PC')
subplot(1,2,2)
mesh(reshape(mod.loads{2}(:,2),44,7))
title('Loadings for Second PC')
 
echo off
  
   
