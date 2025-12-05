echo on
%MCRDEMO Demo of the MCR function.
 
echo off
%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
 
pause
%-------------------------------------------------
% This demo uses the OSEDATA data set. The data set is Optical Emission
% Spectra from a semiconductor etch process. The data set contains 3
% "batches" of data with 770 channels collected over time (roughly 45
% seconds). For this demonstration we'll just use one wafer's worth of data
% (the first batch).
%
% The goal is to watch concentrations of Aluminum and Titanium to see when
% the etch process is complete. The demo will make initial guesses for the
% concentration and add constraints for the Al and Ti components for
% selected time periods.
 
pause
%-------------------------------------------------
% Load the oesdata data set.
 
load oesdata
disp(oes1.description)
 
pause
%-------------------------------------------------
% This data is for metal etch on semi-conductor wafers.
% Let's plot the data.
 
figure; plot(oes1.data), xlabel('Time'), ylabel('OES Intensity')
 
% It is clear that some of the channels in the OES data
% show the 3 different regions of the etch: TiN, Al, Overetch. 
 
pause
%-------------------------------------------------
% Extract the first batch of oesdata into the variable "data".
 
data = oes1.data;
 
pause
%------------------------------------------------- 
% The first step in the MCR decomposition is to generate an initial
% estimate of the contribution profiles, c0 (or spectra). In this case
% there is reason to believe that the BCl3/Cl2 etch gas is present for the
% entire run. Al, however, is only present at the beginning, TiN should
% only be present in the middle, and based on our knowledge of this data set
% an unknown component is present around sample 12. Thus, an initial
% estimate is constructed using the expected range of existence of the
% analytes as follows:
 
c0(:,1) = ones(46,1); %BC13/C12
c0(1:12,2) = ones(12,1); %AL
c0(15:25,3) = ones(11,1); %TiN
c0(10:12,4) = ones(3,1); % Unknown
 
pause
%-------------------------------------------------
% Contribution constraints can be used to eliminate non-zero estimates for
% the TiN and AL where it is expected to have zero contributions. Constraint
% matrices are constructed using desired numerical values where constraints
% are to be applied, and NaNs in locations where there are no constraints.
% This is done as follows:
 
ccon = repmat(NaN,46,4);
ccon(14:end,2) = 0; %AL
ccon(1:7,3) = 0; %TiN
 
pause
%-------------------------------------------------
% Now let's obtain the optional inputs for MCR and add our contribution
% constraints.
 
mcr_ops = mcr('options');
mcr_ops.alsoptions.cc = ccon;
 
pause
%-------------------------------------------------
% We can now build a MCR model with the following command:
 
mcrmodel = mcr(data, c0, mcr_ops);
 
pause
%-------------------------------------------------
% We can apply this model to the data without negativity constraints on
% concentration to get the true concentration estimates:
 
opts = mcr('options');
opts.alsoptions.ccon = 'none';
opts.alsoptions.ccon = 'none';  %turn off non-negativity
pred = mcr(data,mcrmodel,opts);
cls_conc_est = pred.loads{1};
 
pause
%-------------------------------------------------
% Now we can plot a CLS estimate of the concentration profile based on the
% MCR estimate of the spectra with concentration constraints:
 
figure;plot(1:46, cls_conc_est)
legend({'BCl_3', 'Aluminum', 'Titanium', 'unknown factor'})

%End of MCRDEMO
 
echo off
