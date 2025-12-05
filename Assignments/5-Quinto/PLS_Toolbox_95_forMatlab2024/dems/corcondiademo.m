echo on
%CORCONDIADEMO Demo of the CORCONDIA function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rb
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load fluorescence data set:
 
load sugar
 
% Fit a three-component PARAFAC model (reasonable
% number of components). First turn of plotting of
% the model.
pause
%-------------------------------------------------
myopts = parafac('options');
myopts.plots = 'off';
model3 = parafac(sugar,3,myopts);
 
% Check the adequacy of this model by calculating
% the core consistency
 
corco3 = corcondia(sugar,model3)
pause
%-------------------------------------------------
% As can be seen, the core consistency is high. The
% plot should ideally have all the red points at one
% and the green ones at zero. The closer the core
% consistency is to 100 (%), the better. Values
% far below appr. 60 % are indicative of an 
% invalid model
pause
%-------------------------------------------------
 
% Next, fit a five component model (too many components)
model5 = parafac(sugar ,5,myopts);
pause
%-------------------------------------------------
% Now look at the core consistency to see if this 
% model is reasonable
 
corco5 = corcondia(sugar,model5)
pause
%-------------------------------------------------
% As can be seen, the core consistency is wildly off
% and the model clearly not useful.
%
% In practice, the core consistency should be checked 
% sequentially from one to F components. The point where
% it breaks off and becomes too low, indicates that too many
% components have been used.
pause
%-------------------------------------------------
 
% See "help corcondia" or "corcondia help".
%
%End of CORCONDIADEMO
 
echo off
