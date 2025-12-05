echo on
%Diviner Demo of the diviner function
 
echo off
%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load data:

load SBRdata_EU.mat

pause
% Select the first Y-column to use for modeling
Ycal_one = Ycal(:,1);

pause
% Grab the options for diviner
diviner_options = diviner('options');

pause
% Before running diviner, we need to provide preprocessing recipes to use
% during model building. These recipes are stored in the
% options.preprocessing field. We'll Create four recipes to use for the 
% x-block preprocessing and one recipe to use for the y-block
% preprocessing.

recipes = cell(4,2);
mncn_prepro = preprocess('default', 'mean center');
snv_prepro = preprocess('default','snv');
normalize_prepro = preprocess('default', 'normalize');
derivative_prepro = preprocess('default','derivative');

pause
%X-block recipe 1: Mean Center
recipes{1,1} = mncn_prepro;

pause
%X-block recipe 2: SNV + Mean Center
prepro_1 = snv_prepro;
prepro_1(2) = mncn_prepro;
recipes{2,1} = prepro_1;

pause
%X-block recipe 3: Normalize + Mean Center
prepro_2 = normalize_prepro;
prepro_2(2) = mncn_prepro;
recipes{3,1} = prepro_2;

pause
%X-block recipe 4: SavGol Derivative + Mean Center
prepro_3 = derivative_prepro;
prepro_3(2) = mncn_prepro;
recipes{4,1} = prepro_3;

pause
%Y-block recipe: Mean Center
recipes{1,2} = mncn_prepro;

pause

%Assign recipes to the preprocessing option
diviner_options.preprocessing = recipes;

%Diviner is ready to run and once doing so will cause a plot of results 
% to open. 
%Click the green check button to finish the Diviner run and have the 
% results saved to the workspace. Or, perform model refinement.

pause

%To perform model refinement,use the Make Selection button to select models
% to refine. Usually models in the lower left corner of this plot will be
% selected, as those models have low error values, RMSECV, and low over-fit
% values (RMSECV/RMSEC). 
pause

%Once models have been selected, click the green check mark to accept the
%selection.

%A dialog window will appear asking how to refine the selected models.
%For this demo check Variable Selection, as the Outlier reinclusion 
%option is not applicable for this Diviner run as outlier detection was not
%performed. Click Ok.

%After variable selection has been performed a plot of the results will
%appear for graphical review and the results will be saved to the 
%workspace.

%Diviner is ready to run:
diviner_results = diviner(Xcal,Ycal_one, diviner_options);

%End of DIVINERDEMO
 
echo off
