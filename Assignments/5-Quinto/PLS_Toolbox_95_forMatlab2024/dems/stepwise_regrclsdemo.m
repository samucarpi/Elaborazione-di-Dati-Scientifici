echo on
%STEPWISE_REGRCLSDEMO Demo of the STEPWISE_REGRCLS function

echo off
%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg

echo on

%To run the demo hit a "return" after each pause
pause
 
% Use NIR data for the example. Load the data and get estimates
% of the pure component spectra using CLS.
 
load nir_data
 
targspec      = conc.data(1:20,:)\spec1.data(1:20,:);
 
plot(spec1.axisscale{2},targspec)
title('Candidate Spectra')
 
pause
 
% For each measured spectrum, the step-wise algorithm will 
% add a spectrum from the candidate list of spectra to a
% basis (that is initially empty). This is done for all the
% candidate spectra not already in the basis, and the fit
% errors are calculated for each added spectrum.
 
% If the fit error decreases significantly, the candidate
% that reduced the error the most is kept in the basis.
% The process is repeated until the user stops it or all
% the candidate spectra are included in the basis.
% [When options.automate=='yes', the process is based on
% an F-test only with no user input allowed.]
 
pause
 
% Now run step-wise regression to see which of the target
% spectra are in the subsequent sample from (spec1).
 
% The user is expected to answer yes, 'y', keep the new spectrum
% or no, 'n', don't keep the new spectrum (e.g. the fit doesn't
% significantly improve) at the command line.
 
% To help make your decision look at
% 1) the comparison of the new fit spectrum and the old fit spectrum,
% 2) the new fit residuals and the old fit residuals, and
% 3) the estimated F-statistic based on keeping the new spectrum.
 
pause
 
options = stepwise_regrcls('options');
options.scls = spec1.axisscale{2};
options.automate = 'no';
 
[c,ikeep,res] = stepwise_regrcls(spec1.data(21:22,:),targspec,options);
 
% For sample 21, you kept targets
disp(ikeep{1})
% ans for sample 22, you kept targets
disp(ikeep{2})
 
% with estimated concentrations for both samples
disp(c)
 
pause

% The actual concentrations of the known targets are
disp(conc.data(21:22,:))
 
%End of STEPWISE_REGRCLSDEMO
%
%See also: 
 
echo off
