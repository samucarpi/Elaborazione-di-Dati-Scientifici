echo on
 
% MAXAUTOFACTORSDEMO Demo of the MAXAUTOFACTORS function
 
echo off
% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
 
% The maxautofactors function is used to create models based on
% maximum autocorrelation factors (MAF), and
% maximum difference factors (MDF).
 
% The MAXAUTOFACTORS function can be applied to time-series data where the
% time-series is collected into the ordered rows of a data set (x).
% Additionally, the MAXAUTOFACTORS function can be applied to the spatial
% modes of a multivariate image.
 
% The first example show the application to time-series using the slurry
% fed ceramic melter (SCFM) data in plsdata.mat. The data are first loaded
% and four outliers are removed from the variable xblock1. This is the data
% used to calibrate the MAF and MDF models.
% The xblocks correspond to 20 temperatures measured in a SFCM over time.
 
pause
 
load plsdata

xblock1         = delsamps(xblock1,[72:74 167 278 279],1,1); %remove outliers
xblock1         = delsamps(xblock1,[1 2 11 12],2,1); %e.g., exclude variables
 
% Next, the MAXAUTOFACTORS options and number of factors will be set
ncomp           = 8;                            %number of MAF and MDF factors
options         = maxautofactors('options');    %create a default options structure
options.confidencelimit = 0.99;                 %change default CL for T, T2 and Q
options.preprocessing   = {preprocess('default','mean center')}; %set preprocessing
options.plots   = 'none';         %turn off plots and create them manually later
 
% Calibrate a MAF model (MAF is the default algorithm)
 
modela          = maxautofactors(xblock1,ncomp,options); %calibrate the MAF model
plotloads(modela)                               %make a loadings plot for MAF
 
% Apply the model to test set xblock2
 
options.plots   = 'final';        %turn on plots to get a scores plot automatically
preda           = maxautofactors(xblock2,modela);
 
% Use the plot controls to explore the loadings and scores plots (turn on the legend).
% The scores on Factor 1 correspond to a factor that has higher autocorrelation
% than for the corresponding PCA scores on PC 1.
 
% Next, the algorthm will be changed to MDF to find factors corresponding
% to high frequency change in time.
 
pause
 
options.algorithm = 'mdf';                      %change the algorithm
options.plots   = 'none';         %turn off plots and create them manually later
modelb          = maxautofactors(xblock1,ncomp,options); %calibrate the MDF model
plotloads(modelb)                               %make a loadings plot for MDF
options.plots   = 'final';        %turn on plots to get a scores plot automatically
predb           = maxautofactors(xblock2,modelb);
 
% Use the plot controls to explore the loadings and scores plots (turn on the legend).
% The scores on Factor 1 correspond to a factor that has higher
% 'differences' in the time-series than for the corresponding PCA scores on PC 1.
% Create line+points plots and contrast the scores plots between MDF and MAF.
 
% A second example uses LCMS data. In this case, it will be important to
% lower the parameter 'condmax' otherwise the MAF results get really odd
% due to ill-conditioning in the 'clutter' matrix (in MAF the first
% derivative of the time-series is considered 'clutter').
 
pause
 
load lcms
options         = maxautofactors('options');    %create a default options structure
options.confidencelimit = 0.99;                 %change default CL for T, T2 and Q
ncomp           = 8;                            %number of MAF and MDF factors
sp              = preprocess('default','sqmnsc');
sp.description  = 'Poisson (Sqrt Mean) Scaling (scale offset = 33.00%)';
sp.userdata.offset = 3;
sp(2)           = preprocess('default','mean center');   
options.condmax   = 1e2;                        %lower from default
options.preprocessing   = {sp};                 %set preprocessing
modelc          = maxautofactors(lcms,ncomp,options);  %calibrate the MAF model
 
% Use the plot controls to explore the loadings and scores plots.
% The scores on Factor 1 correspond to a factor that has higher autocorrelation
% than for the corresponding PCA scores on PC 1.
 
% Change the algorithm and try MDF.
 
pause
 
options.algorithm = 'mdf';                      %change the algorithm
modeld          = maxautofactors(lcms,ncomp,options);  %calibrate the MDF model

echo off
if evriio('mia')
  echo on
 
  % The image example uses an NMR image of a human brain kindly provided by
  % Dr. J.P. Hornak, RIT, Rochester NY and discussed in W. Windig, J.P. Hornak,  
  % B. Antalek, "Multivariate Image Analysis of Magnetic Resonance Images with
  % the Direct Exponential Curve Resolution Algorithm (DECRA)," Part 1:
  % Algortihm and Model Study, JMR, 132 (1998) 298-306.                                                             
 
  pause
  
  % The data are loaded and the MAF model is constructed using
  % mean-centering.
 
  load braint2
  %     data      65536x14            7872228  dataset
 
  ncomp   = 4;
  options = maxautofactors('options');
  options.preprocessing = preprocess('default','mean center');
  model   = maxautofactors(data,ncomp,options);

  % Note that scores and loadings plots are constructed because
  %  options.plots = 'final' is the default
  %  use autocontrast and explore the  scores and loadings plots
  %  also note that edges are excluded from the original image for this
  %  example
 
  % Next make an MDF model
 
  pause
 
  % The MDF shows changes in the image
  options.algorithm = 'mdf';
  model2   = maxautofactors(data,ncomp,options);
  % Note again that scores and loadsing plots are constructed
  % the default plot for MDF is the mean scores, tsq and q
  % this gives a "3D" look to the image but taking the mean of the scores
  % can "wash out" some nuances.
 
  % next show how to get MDF for down the columns and across the rows.
 
  pause
 
  model2.userdata.options.mdfdir = 'c'; %set plot dir 'c' for down the columns
  ac        = plotscores(model2);       % DataSet object with d/dx scores
  model2.userdata.options.mdfdir = 'h'; %set plot dir 'h' for across the rows
  ar        = plotscores(model2);       % DataSet object with d/dy scores
  figure, plotgui([ac,ar]);             %augment and plot together

  % Explore the scores on each PC both down the columns (first set of scores
  % and across the rows (second set of scores).
end
 
%End of maxautofactors Demo
 
echo off