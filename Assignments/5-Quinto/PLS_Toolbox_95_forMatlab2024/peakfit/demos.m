function tbxStruct = demos
%DEMOS Demo list for the PLS_Toolbox_PEAKFIT.

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 1/27/01

%This function follows the example in 
%toolbox-blockset integration instructions.doc
%written by J. Tung

if nargout==0, demo toolbox 'PLS_Toolbox_PEAKFIT'; return; end

tbxStruct.Name = 'PLS_Toolbox_PEAKFIT';
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

tbxStruct.DemoList = { 'FITPEAKS Peak fitting routine' 'fitpeaks(''demo'')' '' ; 
  'Makes plots of different peak shapes.' 'peakcomdemo' '' ; 
  'PEAKFIND Automated identification of peaks.' 'peakfind(''demo'')' '' ; 
  'PEAKFUNCTION Outputs the estimated peaks from parameters in PEAKDEF' 'peakfunction(''demo'')' '' ; 
  'PEAKGAUSSIAN Outputs a Gaussian Function' 'peakgaussian(''demo'')' '' ; 
  'PEAKIDTEXT Writes peak ID information on present graph.' 'peakidtext(''demo'')' '' ; 
  'PEAKLORENTZIAN Outputs a Lorentzian Function' 'peaklorentzian(''demo'')' '' ; 
  'PEAKPVOIGT1 Pseudo-Voigt 1 (Gaussian with Lorentzian)' 'peakpvoigt1(''demo'')' '' ; 
  'PEAKPVOIGT2 Pseudo-Voigt 2 (Gaussian with Lorentzian)' 'peakpvoigt2(''demo'')' '' ; 
  'Demo of the PEAKFUNCTION, PEAKSTRUCT and PEAKIDTEXT functions.' 'peaksddemo' '' ; 
  'PEAKSTRUCT Makes an empty peak definition structure.' 'peakstruct(''demo'')' ''};
