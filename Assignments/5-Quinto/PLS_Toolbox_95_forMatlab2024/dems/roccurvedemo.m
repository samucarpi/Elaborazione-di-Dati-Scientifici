%C:\Code\evri\plstb\app\trunk\dems\roccurvedemo.m

echo on
%ROCCURVEDEMO Demo of the ROCCURVE function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% ROCCURVE Calculates and displays ROC curve(s) for yknown and ypred.
% ROC curves can be used to assess the specificity and sensitivity of a 
% classifier for different predicted y-value thresholds, for input y known 
% and predicted.

% We will show examples of the two ways ROCCURVE may be called. 
%
% The first way, where the input yknown is a logical column vector, size 
% (n,1), and the ypred is a double (n,m) array. These are the true and 
% predicted state of the tested sample. "n" is the number of samples for
% which predictions were made. The "m" columns of ypred represent m
% different predictors. This produces m ROC plots and m Threshold plots for
% yknown versus each of the m ypred predictors in turn.
%
% The second way that ROCCURVE is called is where the input yknown is a 
% logical array, (n,m), and the input ypred is a double (n,m) array. 
% This also produces m ROC plots and m Threshold plots but in this case the
% j-th plot is showing yknown column j versus ypred column j.
%
% First way:
% The simplest ROCCURVE example is where yknown is an (n,1) logical and 
% ypred is an (n,1) double. For any particular ypred "threshold" value, y0, 
% we say samples with y>y0 are positives, else negatives. Comparing 
% predictions for number of positives/negatives with the known number of 
% positives/negatives lets us calculate the specificity and sensitivity for 
% that threshold value. Repeating this using each ypred as a threshold lets 
% us create a plot of sensitivity versus specificity, an ROC plot. A 
% Threshold plot plots both sensitivity and specificity against ypred, 
% sorted ascending.
%

pause
%---------------------------------------------------
% Create simple yknown (n,1) and ypred (n,1):

n2 = 50;
n = 2*n2;
yknown = (1:n)';
yknown=yknown>n2;

ypred = (1:n)';
noisefactor = 0.5*max(abs(ypred));
ypred = ypred + noisefactor * rand(size(ypred));


pause
%---------------------------------------------------
% Calculate ROC:

roc = roccurve(yknown,ypred);

% roc is a dataset object with size (n,2). 
% Column 1 is specificity
% Column 2 is sensitivity
% with a row for each value of ypred, in order sorted ascending, used as 
% the test threshold

% ROCCURVE can produce "ROC" plots and/or "Threshold" plots. 
% The plots produced are determined by the "plotstyle" option field. The
% default is to produce both types of plots.
% Plots can be suppressed by setting the options field 'plots' = 'none'
%   opts = roccurve('options');
%   opts.plots = 'none';
%   roc = roccurve(yknown, ypred, opts);

% 
pause
%---------------------------------------------------
% Calculate ROC again with two column ypred:
ypred2 = [ypred (ypred + noisefactor * rand(size(ypred)))];
% ypred2 = [ypred (ypred.*rand(size(ypred)))*0.01];
roc2 = roccurve(yknown,ypred2);

% Notice that two ROC plots are generated, one for each column of ypred, 
% and two "threshold" plots.
% The returned "roc2" dataset object has size (n1, 4). This shows the 
% specificity and sensitivity at the "n1" unique ypred values (union over  
% all ypred values in both columns), sorted in order of increasing ypred.  
% The column-pairs contain the specificity and sensitivity for ypred column
% 1, then ypred column 2.
%
% In general, if yknown is nx1 logical vector and ypred is nxm, then m roc 
% curves are produced, one for each column of ypred. The returned roc 
% dataset has size (n1,2*m), where n1 is less than or equal to n*m.
% containing column-pairs of Specificity and Sensitivity for each yknown 
% vs. ypred pairing.

% 
pause
%---------------------------------------------------
% Second way:
% The second way that ROCCURVE can be called is where yknown is a logical
% (n,m) and ypred is double (n,m), so both are multicolumn, with the same 
% number of columns. This produces m ROC curves, one for each pair of 
% yknown and its corresponding ypred column.  The returned value is a  
% dataset with size (n1, 2*m), where n1 is less than or equal to n*m.
%
% Create yknown and ypred, each with size (n,3):

n = 20;
yknown = [repmat(1, n,1); repmat(2, n,1); repmat(3, n,1)];
yknown = class2logical(yknown);
yknown = ~yknown.data;

ypred = (1:3*n)';
noisefactor = 0.01*max(abs(ypred));
ypred = repmat(ypred, 1,3);
ypred = ypred + noisefactor * rand(size(ypred));
 
pause
%---------------------------------------------------
% Calling ROCCURVE produces 3 ROC plots and 3 threshold plots:

roc3 = roccurve(yknown,ypred);

pause
%---------------------------------------------------
% Finally, the last example of the second way is shown using PLSDA model 
% predictions for ypred on the arch demo dataset. 
% Here, yknown is (63,4) and ypred is (63,4)

load arch;
arch = arch(1:63,:);    % only use the calibration samples
% Add noise to make predictions less perfect and plots more interesting
arch.data = arch.data + 500*rand(size(arch.data));
yknown = arch.class{1};

optsplsda               = plsda('options');
optsplsda.preprocessing = {preprocess('default','autoscale') preprocess('default','meancenter')};
optsplsda.plots         = 'none';
model = plsda(arch,yknown,3,optsplsda);

ypred = model.pred{2};
threshold = model.detail.threshold;
yknown = arch.class{1};
%
% This is a double (1,63) with values 1 to 4. It is converted into a
% logical (63,4) by CLASS2LOGICAL:
yknown = class2logical(yknown); yknown = yknown.data;  % logical yknown

pause
%---------------------------------------------------
% Calling ROCCURVE procuces 4 ROC plots and 4 threshold plots
% First plot compares first column of yknown against first column of ypred,
% and so on for plots 2, 3, and 4.

opts         = roccurve('options');
opts.showauc = 'off';   % plot without showing AUC value
roc4 = roccurve(yknown, ypred, opts);

echo off  
