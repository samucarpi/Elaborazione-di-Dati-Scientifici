echo on
%INITEVRIPCTDEMO Demo of the initevripct function
 
echo off
%Copyright Eigenvector Research, Inc. 2004 
% Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The Parallel Computing Toolbox (PCT) can be used with PLS_Toolbox code.
% However, a special parpool initialization function, INITEVRIPCT, must be
% run before the parpool is used with PLS_Toolbox. 
 
pause
%---------------------------------- 
% First, check if you have the PCT installed.
% Run the "ver" command to check. If the PCT is available then you will see
% "Parallel Computing Toolbox" listed in the response.

ver
 
pause
%---------------------------------- 
% Begin by deleting any parpool which might be running already
delete(gcp('nocreate'))
 
pause
%---------------------------------- 
% Non-PLS_Toolbox code using the PCT runs as expected, after a short delay
% while the worker pool starts. Using a parfor loop, for example, will
% automatically start the parpool

parfor ii = 1:5
  EigenValues{ii,1} = eig(magic(20)); 
end
EigenValues
 
pause
%---------------------------------- 
% Stop the parpool again

delete(gcp('nocreate'))
clear EigenValues  
 
pause
%----------------------------------  
% A parfor loop which uses PLS_Toolbox code will randomly fail if the
% parallel pool of Matlab workers is not started by calling the function
% "initevripct". This failure is associated with more than one parpool 
% Matlab instance trying to access the matlabprefs.mat file simultaneously. 
% Running initevripct starts the parpool in a controlled manner. It may 
% take 20 seconds to one minute the first time it is called but negligible 
% time if called again while the parpool is still running.

hasparpool = initevripct; 
 
pause
%---------------------------------- 
% Now PLS_Toolbox functions may be in PCT constructs such as parfor loops 
% without any problem

parfor ii = 1:5
  options{ii} = pls('options'); 
end
options
 
pause
%---------------------------------- 
% Note that PLS_Toolbox functions which use the PCT internally (for example, 
% SVM/SVMDA) already include a call to INITEVRIPCT, so you can call SVMDEMO
% in the usual way since SVM will ensure the parpool is started and 
% initialized if it is not already running.
% 
%End of INITEVRIPCTDEMO
echo off
