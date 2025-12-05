echo on
%GENALGPLOTDEMO Demo of the GENALGPLOT function
 
echo off
%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% GENALGPLOT provides a sorted graphical view of the final models selected
% by a Genetic Algorithm run (see gaselctr and genalg for more information
% on genetic algorithms). This may help elucidate trends in which variables
% are most useful. As an example, we will look at "prematurely ended" GA
% results (which contain a wide variety of varible choices). Load data of
% interest and autoscale the x-block.
 
load plsdata
whos
xblock1 = preprocess('calibrate','autoscale',xblock1);
 
pause
%-------------------------------------------------
% Get settings for the GA run: allow only three generations and set
% the population size to 128.
 
options = gaselctr('options');
options.maxgenerations = 3;
options.popsize = 128;
 
pause
%-------------------------------------------------
% Do the GA run:
 
model = gaselctr(xblock1,yblock1,options);
 
% Now, we'll plot those results using genalgplot. In the first figure, you
% will see a point for each model created. Drag a box to select which of
% the models (individual points) you want to have plotted (for best
% results in this demo, try selecting a large number of the points).
 
close
pause
%-------------------------------------------------
genalgplot(model);
 
% In this plot, each row is a model and a colored mark indicates an
% included variable. The color of the row indicates the fit (scale on the
% color bar on the right of the plot). The best fitting models are at the
% bottom of the plot.
%
% Variables which, when included, tend to help the fit will be clustered
% towards the bottom of the plot or show up throughout the models  (e.g.
% variables 7 and 8). Those which, when included, tend to degrade the
% fit, will be clustered towards the top or will show up not at all (e.g.
% variables 9 and 10).
 
%End of GENALGPLOTDEMO
 
echo off
