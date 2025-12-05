function tbxStruct = demos
%DEMOS Demo list for the PLS_Toolbox_DFT.

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 1/27/01

%This function follows the example in 
%toolbox-blockset integration instructions.doc
%written by J. Tung

if nargout==0, demo toolbox 'PLS_Toolbox_DFT'; return; end

tbxStruct.Name = 'PLS_Toolbox_DFT';
tbxStruct.Type = 'Toolbox';

tbxStruct.Help = cell(2,1);
tbxStruct.Help = {
  ' PLS_Toolbox contains the foremost collection ',
  ' of tools for chemometrics and multivariate analysis. ',
  ' Included are algorithms for single and multi-block ',
  ' analysis, GUI, and command line functions for Principal ',
  ' Components Analysis, linear and non-linear regression, ',
  ' multi-way routines, multivariate image analysis, ',
  ' classification, and more.',
  ' ',
  [' "<functionname> demo" shows a short demo of each function.', 10],
  [' "<functionname> io" to get a list of the function I/O.<br>', 10],
  [' "<functionname> help" to get online help on each function.<br>', 10],
  ' "help <functionname>" to get help as usual.' };

tbxStruct.DemoList = { 'BETADF Beta distribution function.' 'betadf(''demo'')' '' ; 
'CHITEST Uses chi-squared test tests if sample has a specific distribution.' 'chitest(''demo'')' '' ; 
'DISTFIT  Chitest for all distributions' 'distfit(''demo'')' '' ; 
'KDENSITY Calculates the kernel density estimate.' 'kdensity(''demo'')' '' ; 
'KSTEST Kolmogorov-Smirnov test that a sample has a specified distribution.' 'kstest(''demo'')' '' ; 
'MEANS calculates the algebraic, harmonic, and geometric mean of a vector.' 'means(''demo'')' '' ; 
'PARAMMLE  Maximum likelihood parameter estimates for DF_Toolbox.' 'parammle(''demo'')' '' ; 
'PCTILE1 Returns the Pth percentile of a data vector.' 'pctile1(''demo'')' '' ; 
'PCTILE2 Returns the Pth percentile of a data vector.' 'pctile2(''demo'')' '' ; 
'SUMMARY calculates summary statistics for a vector.' 'summary(''demo'')' '' ; 
'TTEST1  One sample t-test' 'ttest1(''demo'')' '' ; 
'TTEST2E Two sample t-test (assuming equal variance).' 'ttest2e(''demo'')' '' ; 
'TTEST2P  Two sample paired t-test' 'ttest2p(''demo'')' '' ; 
'TTEST2U Two sample t-test (assuming unequal variance).' 'ttest2u(''demo'')' '' };
