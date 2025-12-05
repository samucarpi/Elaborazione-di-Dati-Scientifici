echo on;
% RPLSDEMO Demo for the RPLS function

echo off;
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%

echo on;

%To run the demo hit a "return" after each pause
pause

%--------------------------------------------------- 
% RPLS performs variable selection in an attempt to impprove the fit of
% a PLS model using the iterative model LRVs. The following shows how to
% run a simple RPLS analysis. First, load the data.

useplsdata = 0;  % Choose to use plsdata (1), or nir_data (0)
if (useplsdata == 1)
  load plsdata
  x = xblock1;
  y = yblock1;
  % Specify preprocessing on X
  s = preprocess('default','mean center');
else
  load nir_data
  x = spec1;
  y = conc(:,3);
  x.include{2} = 3:401;
  % Specify preprocessing on X
  s = preprocess('default','SNV', 'mean center');
end

[x , sp] = preprocess('calibrate', s, x);

pause;

%--------------------------------------------------- 
% Default settings for RPLS can be obtained by requesting it from the function:

rplsopts = rpls('options')

pause;

%--------------------------------------------------- 
% rPLS can use either 'PLS' or 'PCR' as the algorithm of choice in the
% in the variable selection process. To change the algorithm, change the
% the settings in the options structure directly. Note that PLS is the
% default algorithm.

rplsopts.algorithm = 'pls';

pause;

%--------------------------------------------------- 
% Calibration data should be pre-processed, if desired, before being passed
% to RPLS for variable selection. RPLS uses mean center preprocessing
% internally.

pause;

%--------------------------------------------------- 
% RPLS can be used in three mode: 'specified', 'suggested', & 'surveyed'
%
% Speficied will run RPLS only on the speficied number of latent variable
% and is the fastest mode available.

rplsopts.mode = 'specified';
rplsopts.stopcrt = eps;

%---------------------------------------------------  
% 'suggested' mode analyses the entire dataset using PLS/PCR, and cross-
% validation to determine the most appropriate number of latent variables 
% and proceeds with analyzing the dataset via RPLS.
%
% rplsopts.mode = 'suggested';
% 
% 'surveyed' mode runs RPLS on the dataset from 1 to the specified
% number of latent variables. This mode is the slowest but it would ensure
% the best model is selected.
%
% rplsopts.mode = 'surveyed';

pause;

%--------------------------------------------------- 
% To Run RPLS, input the x-block, y-block (single column only), the
% number of components and the options structure (optional).
% results=rpls(x,y, 5,rplsopts);
%
% When selecting the number of latent variables, it serves more or less as
% a guide to how may variables to keep, though more may be kept depending
% on the RMSECV results.
%
% Note that if the number of latent variables is specified in suggested
% and surveyed modes, the max number of latent variables will be
% changed (rplsopts.maxlv).
%
% Running RPLS can take up to a few minutes to complete... Hit "return" to begin.

pause;

%--------------------------------------------------- 
results=rpls(x,y, 5,rplsopts);

%--------------------------------------------------- 
% Once RPLS is complete, you should have two figures displayed and a
% results structure in your workspace.
%
% The figures are two images. The first displays the natural log of variable 
% weights at each RPLS iteration. The second image is similar to the first 
% only it highlights the selected variables at each RPLS iteration along
% with their respective RMSECV values. Each figure comes with a mean
% data/spectrum overlay. 
% 
% The returned 'results' structure contains information about the number of
% LVs used, the RMSECV results, sets of indexes corresponding to the
% variables selected, the Regression Vectors (both for each iteration, and
% the cumulative Regression vectors), and the calculated differences
% between regression vectors. The '.selected' field indicates the set of
% variable indexes that produced the lowest RMSECV value, and therefore is
% the recommended set of variables to use in analysis.

% This concludes the RPLS demo.
