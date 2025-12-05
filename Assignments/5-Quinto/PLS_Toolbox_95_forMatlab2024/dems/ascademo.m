echo on
%ASCADEMO Demo of the ASCA function
 
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
% ASCA provides a multi-variate ANOVA by applying a PCA analysis to each of
% the effects modeled by an ANOVA. This is termed Simultaneous Component
% Analysis (SCA).
% For details of the ASCA method see: 
% 1. Smilde et al., "ANOVA–simultaneous component analysis (ASCA): a new tool 
% for analyzing designed metabolomics data". Bioinformatics, 2005,
% and,
% 2. Zwanenburg et al., "ANOVA-principal component analysis and
% ANOVA-simultaneous component analysis: a comparison". J. Chemometrics, 2011.
 
pause
%--------------------------------------------------- 
% The following shows how to run a simple ASCA analysis. First, load data of
% interest. In this case, we'll use the "asca_data" dataset which consists of
% 1. measured experimental data, X, (60 samples x 11 variables),
% 2. experimental design matrix, F, (60 samples x 2 factors), with integer 
% column values. F(i,j) = n means i-th sample has level n of factor j.
%
% The measured data are LC/MS-measured metabolite values from an experimental 
% design study of Cabbage plant response to administered plant hormones. 
% Type "X.description" for information on the dataset, after the data have
% been loaded.
 
load asca_data; whos

pause
%--------------------------------------------------
% 11 metabolites were measured from 60 Cabbage plants following the
% designed experiment described by F. There are two factors, "Time" and
% "Treatment", so the design matrix has two columns. Column 1 shows
% the "Time" factor level used while column 2 shows the "Treatment" factor
% level used for each sample.
% Factor "Time" has 4 values: days 1, 3, 7 and 14. 
% Factor "Treatment" has 3 values: "Control", "Root" and "Shoot". 
% F has row classes sets identifying sample factor levels, F.classid{1,1} 
% and F.classid{1,2}. These are useful when viewing scores plots.
 
pause
%--------------------------------------------------
% Specify options for: 
% X preprocessing method, 
% The number of random permutations of a factor's levels to use when 
%   estimating significance a factor's effect,
% Identify level of interactions to include in the analysis (2 = include
%   2-way interactions meaning the ANOVA model will be: 
%       X = Mean + XA + XB + XAB + E 
% The maximum number of principal components to use in the ASCA submodels
%   (if ncomp is omitted, the maximum number of factors for each model will
%   be calculated - generally this is the number of levels in a given
%   factor minus one)
opts               = asca('options');
% opts.display       = 'off';
pp                 = preprocess('default', 'mean center');
opts.preprocessing = pp;
opts.npermutations = 1000;
opts.interactions  = 2;
ncomp              = 20;

pause
%--------------------------------------------------

% Run ASCA.

model = asca(X, F, ncomp, opts);
%
% ASCA applies PCA to each ANOVA decomposition matrix, size 60x11. This is 
% the dimension reduction part of ASCA. There is a PCA sub-model for each 
% factor and interaction term so the scores for each PCA model are scores 
% for factor-level averages. 
%
% Description of model.
% The PCA sub-models are contained in the field model.submodel.
% The scores and loadings from the sub-models are extracted and stored
% together in model.combinedscores and model.combinedloads. 
% model.combinedscores.data is the matrix of scores (60x11). The sub-model
% and PC associated with each column of the matrix are given by
% model.combinedscores.class{2,j}, j=1 is sub-model, j=2 is PC number.
% Similarly for the sub-model loadings. 
% The ANOVA residuals matrix, E, is also projected onto each sub-model and
% these scores are saved in model.combinedprojected.
%
% Viewing the scores of factor-level averages is not very meaningful
% without a measure of within-level variability. This can be obtained if
% there are replicates for each factor combination. Thus, for each factor,
% model.combinedprojected shows the scatter of the scores of the ANOVA model 
% residuals around the scores of the factor level means. This gives a
% visual indication of whether the factor has a significant experimental
% effect.
 
pause
%--------------------------------------------------
 
% Interpreting ASCA results.
% The model.detail.effects field shows the percentage contribution of each 
% effect (Global average, factors, interactions, and residuals) to the 
% overall sum-of-squares of the data matrix, X. The corresponding names are
% in model.detail.effectnames.
 
effects = [model.detail.effectnames num2cell(model.detail.effects')]'
 
% This shows that the Treatment effect is the most important contributor to
% the overall sum-of-squares, contributing 44 percent. Note the "Mean" 
% contribution is zero since mean center preprocessing was applied to X.
 
pause
%--------------------------------------------------
% The P-values for significance of the factor or interaction's effect are 
% obtained by using a permutation test (see second reference paper above 
%for details):
 
pValues = [model.detail.effectnames(2:end-1) num2cell(model.detail.pvalues')]'
 
% This shows that both the Time and Treatment factors' effects are
% significant but the Time:Treatment interaction effect is not significant
% at a 5% level. 
 
pause
%--------------------------------------------------
% Plotting results.
% Use the helper function plotscores_asca to extract the relevant details
% for plotting the results for the Treatment factor (asca_submodel = 2).
% Sub-model 1 is for factor 1, "Time", 
% sub-model 2 is for factor 2, "Treatment"
% sub-model 3 is for interaction "Time:Treatment"
 
options.asca_submodel = 2;   % Treatment
effectsdso = plotscores_asca(model,[],options);
 
% Plot the PC 1 versus PC 2scores for the Treatment factor:
plotgui('new',effectsdso,'plotby',2,'axismenuvalues',{[1] [2]},'viewclasses',1,'connectclasses',1,'connectclassmethod','spider')
legend('show','Location','NorthEast')
 
% This shows the Treatment level means are significantly different relative
% to the individual plant variability not represented by the experimental
% factors.

pause
%--------------------------------------------------

% ASCA assumes the data represent a balanced design, with equal number of
% samples in each level of a Factor. This ideal situation is often not 
% possible, however.
%
% A final example demonstrates the ASCA+ extension of ASCA to handle an
% un-balanced design dataset, as introduced by Thiel, Feraud, and Govaerts 
% (2017). This approach uses a general linear model to estimate the ANOVA
% model parameters by regression rather than by using differences between 
% level means as in conventional ANOVA. With un-balanced designs the 
% conventional ANOVA estimation of factor effects become biased but are 
% correctly estimated using ASCA+.
%
% This is demonstrated here by using the small example from section 2.1.3
% of the Thiel et al. paper. The example has two factors.
% Factor 1 has 2 levels and factor 2 has 3 levels, with no interaction 
% effects present. These are replicated twice. 
% The model parameters used are:
% mu = 10; alpha = [2, -2]; beta  = [1, 0.5, -1.5];

% The full, balanced dataset has 12 samples:
X2 = [13, 12.5, 10.5, 9, 8.5, 6.5, 13, 12.5, 10.5, 9, 8.5, 6.5]';
X2 = dataset(X2);

% and design matrix:
F2 = [ 1 1; 1 2; 1 3; 2 1; 2 2; 2 3; 1 1; 1 2; 1 3; 2 1; 2 2; 2 3];
F2 = dataset(F2);

% First, ASCA applied to the full, balanced dataset:
pause
%--------------------------------------------------

opts.preprocessing = {[] []};
model2 = asca(X2, F2, ncomp, opts);

% Examine the ANOVA model parameters (factor effects):

pause
%--------------------------------------------------

% The full, balanced dataset shows the correct ANOVA model parameters, or 
% global mean, and level means for each factor and interaction:
% (10.0) for global mean, (2.0) for factor 1, and (1.0, 0.5) for factor 2,
% and zero for the factor1 x factor 2 interaction levels.
% Note that level mean for the last level of each factor is not included 
% since it is constrained to equal minus the sum of the Factor's other 
% level means.

model2.detail.decomp.regparams'

% These match the parameters mu, alpha1, and beta1, beta2 values used in
% the paper.

pause
%--------------------------------------------------

% Next, delete 2 samples to make the dataset become an unbalanced design 
% and apply ASCA again. Delete samples 11 and 12:

X2 = X2(1:10,:);
F2 = F2(1:10,:);

% Apply ASCA:

pause
%--------------------------------------------------

model2 = asca(X2, F2, ncomp, opts);

model2.detail.decomp.regparams'

% This shows the calculated ANOVA model parameters match those calculated
% from the full, balanced dataset, meaning the factor effects are still
% estimated correctly despite using the incomplete, un-balanced dataset.
% Traditional ANOVA (or ASCA), where the factor parameters are estimated
% from the level means, would produce biased results in the un-balanced
% case.

%End of ASCA demo
echo off
