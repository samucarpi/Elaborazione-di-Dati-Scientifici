function tbxStruct = demos
%DEMOS Demo list for the PLS_Toolbox_OPTIMIZE.

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 1/27/01

%This function follows the example in 
%toolbox-blockset integration instructions.doc
%written by J. Tung

if nargout==0, demo toolbox 'PLS_Toolbox_OPTIMIZE'; return; end

tbxStruct.Name = 'PLS_Toolbox_OPTIMIZE';
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

tbxStruct.DemoList = {'LMOPTIMIZE Levenberg-Marquardt non-linear optimization.' 'lmoptimize(''demo'')' '' ; 
  'LMOPTIMIZEBND Bounded Levenberg-Marquardt non-linear optimization.' 'lmoptimizebnd(''demo'')' '' ; };


