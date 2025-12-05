echo on
%BATCHALIGNDEMO Demo of the BATCHALIGN function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
%
% Batch datasets consist of multivariate data sampled at regular timepoints
% during the evolution of a system, for example, a chemical reaction or
% patients' response to a drug. Each repetition of the cycle is considered
% to be a separate batch and batch dataset may contain many batches.
% A single batch will have n timepoints by m variables
%
% We assume batches will always have the same m variables but it is common
% for different batches to have different number of timepoints (samples).
% It is desirable to modify batches to be the same length (same number of
% timepoints). A batch can be modified to have a standard length, m, by
% three different methods:
% 1) Truncate/pad with NaN:
% 2) Linear stretch/compress:
% 3) Using Correlation Optimized Warping (COW)
%
% BATCHALIGN performs this function. It takes these three inputs:
% a) a batch data set is to be aligned with a
% reference target profile. The input data set has size (nd, nvar), where
% nd is the number of timepoints measured during the batch and nvar is the
% number of variables measured.
% b) It is also given a "target" profile as an
% example of the desired profile over the duration of a batch. This has
% size (nt,1), where nt may not equal nd. BATCHALIGN will return a
% transformed version of the input batch data set which has the same length
% as the target profile.
% c) ref_column: one column of the batch data is also identified by its 
% index, ref_column. The alignment is based on comparing the target profile
% with this column profile.
%

pause
%-------------------------------------------------

% We will apply BATCHALIGN to a single batch dataset and a target profile
% compare the resulting batches.
%
% We will use the first batch from Dupont_BSPC demo dataset, which contains
% 10 process variables (pressure, flow, temperature from several sensors)
% and multiple batches.

load Dupont_BSPC

nrow       = 80;
xd         = 1:nrow;
ntarget    = 100;
xt         = 1:ntarget;
ref_column = 5;                    % data column to be matched to target
batch = dupont_cal.data(xd, 1:6);  % First 80 timepoints and 6 variables

pause
%-------------------------------------------------
% Use a modification of the column 5 variable to construct a target profile.
% Apply a cosine-like shift to the profile, zero at start and end, max at
% mid-profile, to represent a shifted target profile, xtarget. Extend it to
% have 100 points in total by adding a 20 point linear segment to its end.
% Thus target has size (100,1).

reference = batch(:,ref_column);
xinterp = nan(size(xd))';
echo off
for iz=1:nrow
  xinterp(iz) = iz + (5*sin((iz-1)*pi/(nrow-1)));
end
target = interp1(xd, reference, xinterp);
echo on
ndel = ntarget - nrow;
ext = target(end)*(1-0.9*(1:ndel)/ndel)';
target = [target; ext]; % Add linear extension to give target 100 timepoints

pause
%-------------------------------------------------
% Plot batch, show reference column in red, and show target
figure;
subplot(211);plot(xd, batch, 'k', xd, batch(:,ref_column), 'r');
grid; xlim([xd(1) xd(end)]);
title('Original data. Reference column profile shown as red');
subplot(212); plot(xt, target); grid; xlim([xt(1) xt(end)]);
title('Target profile');

% The reference column profile has length = 80 with a minimum at time = 43
% and a secondary minimum at time = 63.
% The target profile shows how these minima have been shifted to time = 38
% (5 timepoints earlier) and time = 59 (4 timepoints earlier). The target 
% profile from time = 81 to 100 shows the linear extension.


pause
%-------------------------------------------------
% Set options
options = batchalign('options');
options.cow.plots    = 1;
options.savgolderiv  = 1;  %Savgol can enhance profile features prior to cow
options.cow.segments = 10; % 'cow' segment length
options.cow.slack    = 5;  % Must be <= segments - 4)

% Next we use BATCHALIGN to align the batch with the target profile,
% comparing the three alignment methods, 'padwithnan', 'linear', and 'cow'.
%
% First use the 'padwithnan' method. This uses the target profile only to
% determine the desired number of timepoints in the aligned result, or how
% many timepoints to add or truncate.

pause
%-------------------------------------------------
options.method = 'padwithnan';
aligned = batchalign(batch,ref_column, target, options);
figure; subplot(211);plot(xd, batch);
hold on;plot(xd, target(xd), 'b', 'LineWidth',2);
grid; xlim([xd(1) xd(end)]);
title('Data before alignment. Reference is purple, target is heavy blue line');

subplot(212); plot(xt, aligned)
hold on; plot(xt, target(xt), 'b', 'LineWidth',2); grid; xlim([xt(1) xt(end)]);
title(sprintf('Data after alignment. Method = %s', options.method ));
xlabel('Time points')

% 'padwithnan': The aligned data variable profiles have been extended by 20 
% timepoints but these do not show on the plot as they are NaNs.
% The reference column is shown in color purple and the target profile is
% a heavy blue line.
%
% Next use the 'linear' method. This also uses the target profile only to
% determine the desired number of timepoints in the aligned result. In this
% case the input batch is stretched or compressed using interpolation to
% have the same number of timepoints as the target profile.

pause
%-------------------------------------------------
options.method = 'linear';
aligned = batchalign(batch,ref_column, target, options);

figure; subplot(211);plot(xd, batch);
hold on;plot(xd, target(xd), 'b', 'LineWidth',2);
grid; xlim([xd(1) xd(end)]);
title('Data before alignment. Reference is purple, target is heavy blue line');

subplot(212); plot(xt, aligned)
hold on; plot(xt, target(xt), 'b', 'LineWidth',2); grid; xlim([xt(1) xt(end)]);
title(sprintf('Data after alignment. Method = %s', options.method ));
xlabel('Time points')

% 'linear': Shows the aligned data variable profiles have been stretched to
% make up the same 100 point length of the target profile. The reference
% column is shown as purple and the target profile as a heavy blue line. 
% The same transformation has been applied to every profile (column) of the 
% batch data.
%
% Deciding which of these two alignment methods is best depends on what the
% cause of the batch length difference is. If it is simply that the process
% evolves at different speeds between batches then linear stretching or
% compressing is appropriate. If the processing evolves at the same speed 
% in the batches but the the batches are terminated after differing 
% durations then truncating/padding with NaNs is more appropriate.
%
% The third alignment method, 'cow', is a variation of the linear method.
% It applies a linear stretch or compression to match the target length but
% it also uses "warping" within the batch to try to make a better alignment
% between the reference column's profile and the target profile.
% Thus, the 'cow' method is the only method which actually uses the
% reference column's profile shape when trying to align with it. 

pause
%-------------------------------------------------
options.method = 'cow';
aligned = batchalign(batch,ref_column, target, options);

if options.cow.plots
  figure; subplot(211);plot(xd, batch);
  hold on;plot(xd, target(xd), 'b', 'LineWidth',2);
  grid; xlim([xd(1) xd(end)]);
  title('Data before alignment. Reference is purple, target is heavy blue line');
  
  subplot(212); plot(xt, aligned)
  hold on; plot(xt, target(xt), 'b', 'LineWidth',2); grid; xlim([xt(1) xt(end)]);
  title(sprintf('Data after alignment. Method = %s', options.method ));
  xlabel('Time points')
end

% 'cow': produces two plots. First plot shows the target profile (blue)
% and the adjusted reference profile (green), with the differential
% warping, or displacement, of the reference profile shown by red arrows.
% The second plot is the same "before versus after" plot we saw above for
% the other methods.
%
% This shows the aligned profiles have been stretched to match the target
% profile's length but it is not a simple linear stretching which is
% applied. Comparing the reference column profile with the target profile
% shows that 'cow' perfectly aligns the reference and target profiles up to
% about timepoint 45. After that point the stretching of the reference
% profile has to be greater than in the 'linear' case to spread its
% remaining 35 timepoints out to become 55 timepoints. 
%
% The 'cow' method is a very flexible improvement to the 'linear' method
% because it tries to align prominent features in the batch reference
% profile. It is the default method for BATCHALIGN.

pause
%-------------------------------------------------
%
% Note that the 'cow' results can be very dependent on the option choices.
% In particular,
% 'cow.slack' controls how much differential shifting of the reference
% profile is allowed, by specifying the maximum number of points which part
% of the reference profile can be shifted by.
% 'cow.segments' indicates how many points each sub-segment should have.
%
% If we repeat the 'cow' case but with the cow.slack option value = 4 
% instead of 5 then the resulting alignment will not be as good. This is
% because the target profile is a deformed version of the reference profile
% with the profile minimum being shifted by 5 timepoints. 'cow' cannot then
% make the profiles align at the minimum if cow.slack = 4, so shifting is
% limited to 4 timepoints.

%End of BATCHALIGNDEMO
echo off
