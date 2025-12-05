echo on
%MLSCADEMO Demo of the MLSCA function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%--------------------------------------------------- 
% MLSCA analyzes variability in datasets from designed experiments having 
% nested factors. It separates variability into that associated with each 
% factor and the residuals, estimating the contribution of each factor to 
% total sum of squares. A PCA model is built for each factor showing the 
% scores and loadings for these effects. 
% MLSCA also builds a PCA model on the residuals, or “within” variability. 
% The “Within” variability is often the focus of the analysis.
%
% For details of the MLSCA method see: 
% 1. de Noord and Theobald, "Multilevel component analysis and multilevel 
% PLS of chemical process data", J. Chemometrics 2005.
% 2. Timmerman, "Multilevel Component Analysis", Brit. J. Mathemat. 
% Statist. Psychol. 2006.
 
pause
%--------------------------------------------------- 
% The following shows how to run a simple MLSCA analysis. 
% First, load the nested DOE dataset which consists of
% 1. measured experimental data, X, (8560 samples x 12 variables), 
% 2. experimental design matrix, F, (8560 samples x 2 factors), with integer 
% column values. F(i,j) = n means i-th sample has level n of factor j. 
% 
% The measured data consist of the engineering variables from a LAM 9600 
% Metal Etcher over the course of etching 107 wafers taken during 3 
% experiments run several weeks apart. Type "x.description" for information
% on the dataset, after the data have been loaded.
% Note, the dataset "x" is a modified version of the "EtchCal" dataset in
% the "etchdata" demo data.
 
load mlsca_data; whos
pause
%--------------------------------------------------
% The experimental design has two factors, "Expt" and "Wafer", so the design 
% matrix, F,  has two columns. Column 1 shows
% the "Expt" factor level used while column 2 shows the "Wafer" factor
% level used for each sample. The Wafer levels are all distinct as the 
% Wafter factor is nested within the Expt levels.
% Factor "Expt" has 3 values: experiment 1, 2 and 3. 
% Factor "Wafer" has 107 values identifying the distinct wafers used. 
% F has row classes sets identifying sample factor levels, F.classid{1,1} 
% and F.classid{1,2}. These are useful when viewing scores plots.
 
pause
%--------------------------------------------------
% Before using MLSCA to show the "between" and "within" variability we
% apply standard PCA to the full data. This will help highlight the
% advantages of MLSCA showing the inherent variability of the nested
% samples.
% Build a PCA model on the x (response) data:
 
pcaopts          = pca('options');
pcaopts.display  = 'off';
pcaopts.plots    = 'none';
pcaopts.preprocessing = preprocess('default', 'autoscale');
ncomppca = Inf;
pcamodel = pca(x, ncomppca, pcaopts);

pcascores = pcamodel.loads{1};
pcascores = dataset(pcascores);
pcascores = copydsfields(F,pcascores,1,[], true); % Copy row classes from x to scores
timescale = x.axisscale{1};
pcascores.axisscale{1} = timescale; pcascores.axisscalename{1} = 'Time Steps';
for ic=1:size(pcascores.data,2)
  pclabel{ic} = sprintf('Scores on PC %d', ic);
end
pcascores.label{2} = cell2str(pclabel');

pause
%--------------------------------------------------
% Now view scores plot of the first two principal components
plotgui('new',pcascores,'plotby',2,'axismenuvalues',{[1] [2]},'viewclasses',1,'classsymbolsize', 2, 'connectclasses', 0,'NoSelect',1)
title('PCA Scores');legend('show','Location','NorthWest')

% (*** Click in Command Window and hit a "return" to resume)

pause
%--------------------------------------------------
% Next, view the dynamic evolution of the process by plotting the first PC
% against time step. 
% Both these plots show there is a large offset between the scores of the
% third experiment and the first two. This confuses interpretation of the
% process dynamics.
plotgui('new',pcascores,'plotby',2,'axismenuvalues',{[0] [1]},'viewclasses',1,'classsymbolsize', 2, 'connectclasses', 1, 'connectclassmethod', 'means','NoSelect',1)
title('PCA Scores');legend('show','Location','NorthWest')

% (*** Click in Command Window and hit a "return" to resume)

pause
%--------------------------------------------------
% Next use MLSCA to view the inherent variability of the etching process
% after the effects of the "Expt" and "Wafer" factors are removed.
%
% The Effects table shows most of the variability is in the "Within"
% ("Residuals") component but the "Expt" factor also contains 25% of the
% total variability.
 
opts = mlsca('options');
opts.preprocessing = preprocess('default', 'autoscale');

ncomp = [ 2 2 4];      % max number of PCs to use in submodels.
[model, res] = mlsca(x, F, ncomp, opts);
mlscascores = plotscores_mlsca(model,[], opts);
 
pause
%--------------------------------------------------
% View scores plot of the first two principal components of the MLSCA
% "Within" term. This is the inherent variability. 
% This shows the Within variability is very similar for the three
% experiments (and wafers) after those factors offsets were removed.
 
ncol = sum(ncomp(1:2))+1;
plotgui('new',mlscascores,'plotby',2,'axismenuvalues',{[ncol] [ncol+1]},'viewclasses',1,'classsymbolsize', 2,'NoSelect',1);
title('MLSCA: ''Within'' Scores');legend('show','Locationclear','NorthWest')

% (*** Click in Command Window and hit a "return" to resume)
 
pause
%--------------------------------------------------
% Finally, view the dynamic evolution of the process by plotting the first 
% PC of the "Within" variability against time step.
% This shows a more detailed view of the etching process evolution than is
% attained using PCA on the whole data where much of the first PCs pattern
% is influenced by the inter-experiment differences.
  
plotgui('new',mlscascores,'plotby',2,'axismenuvalues',{[0] [ncol]},'viewclasses',1,'connectclasses',0,'classsymbolsize', 2, 'connectclasses', 1, 'connectclassmethod', 'means','NoSelect',1)
title('MLSCA: ''Within'' Scores');legend('show','Location','NorthWest')

  
%--------------------------------------------------
% The MLSCA scores plots of the "Within" term are more efficient in showing
% the dynamics of the etching process because inter-experiment and
% inter-wafer differences have been removed.
 
% This demo shows the command line usage of mlsca. It is usually simpler,
% however, to, use MLSCA from the Analysis window as this simplifies the 
% viewing of "between" and "within" variability.
 
%End of MLSCA demo
echo off
