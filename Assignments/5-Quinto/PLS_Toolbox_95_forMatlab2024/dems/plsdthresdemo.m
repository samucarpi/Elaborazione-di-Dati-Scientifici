echo on
%PLSDTHRESDEMO Demo of the PLSDTHRES function
 
echo off
%Copyright Eigenvector Research, Inc. 2003 Licensee shall not recompile,
%translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
%PLSDTHRES is used in PLS Discriminate Analysis (PLS-DA) to identify
%thresholds for separating samples which are members of a class and those
%which are not. It also calculates the probability that a given y-value
%would be observed for a sample if it were and were not a member of the
%class being identified.
 
pause
%---------------------------------- 
% Here the use of plsdthres will be demonstrated on the archeological
% dataset "arch"...
 
load arch
 
% The arch data consists of x-ray fluorescence measurements of ten
% elements. The samples are from four different quarries assigned to four
% different classes, plus a set of "unknowns". This demo will use only the
% known samples. In addition, will split the data into a calibration and a
% validation set.
 
arch = arch(find(arch.class{1}>0),:);    %use only "known" samples
valset = arch(4:6:60,:);
calset = arch(setdiff(1:size(arch,1),4:6:60),:);
 
pause
%-------------------------------------------------
% Here is a plot of the intensity observed for one of the measured elements
% (Iron, Fe) for all the calibration samples. Each quarry is assigned a
% different symbol.
 
figure
plotgui(calset,'viewclasses',1)
 
pause
%----------------------------------
% To perform PLS-DA, first a y-block must be created which uses a type
% "logical" vector to identify which samples are members of the "class of
% interest" and which are not. This can be done automatically using the
% PLSDA function, but here we will demonstrate how to do it from the
% command line.
%
% Each sample in the class is assigned a value of 1 and each not in the
% class, a value of 0.  This is often done with "logical comparisions"
% (such as: >, <, ~=, or ==) or by simply entering a vector of zeros and
% ones and using the "logical" command. This demo will attempt to create a
% single model which can differentiate quarries 1 and 3 from quarries 2 and
% 4.
 
y = (calset.class{1}==2 | calset.class{1}==4)';  %identify samples in quarries 2 and 4
 
% and do a plot of these values (using the same symbols as before).
 
y = dataset(y);                   %put the y-values into a dataset object
y.class{1} = calset.class{1};       %add class info (for plotting only)
y.label{2} = {'Measured Y'};      %add a label
plotgui(y);
 
pause
%-------------------------------------------------
close
%----------------------------------
% Next, a PLS model is built from the calibration samples. Here we build a
% simple 3-component model. (See plsdemo for more information on the PLS
% function).
 
opts               = pls('options');
opts.preprocessing = {preprocess('default','autoscale') preprocess('default','meancenter')};
opts.plots         = 'none';
opts.display       = 'off';
model = pls(calset,y,3,opts);
 
pause
%---------------------------------- 
% The "predicted y-values" of the PLS model are actually values around and
% between zero and one and are stored in the ".pred" field of the model.
% Here they are plotted using the same class symbols as before.
 
ypred = dataset(model.pred{2});    %get the predicted values (in a dataset)
ypred.class{1} = calset.class{1};    %add class info (for plotting only)
ypred.label{2} = {'Estimated Y'};  %add a label
plotgui(ypred,'viewclasses',1)
 
pause
%---------------------------------- 
% Ideally, each sample which is a member of the class would predict as a
% value of 1 (one) and each sample not a member would predict as 0 (zero)
% and the discrimination between the two would be simple. As this is often
% not the case, a level of "predicted y" must be determined above which a
% sample is considered to be a member of the class. PLSDTHRES does this
% determination when given the original y values and the predicted y
% values. 
 
threshold = plsdthres(y.data,model.pred{2})
 
pause
%-------------------------------------------------
% and we can add that threshold to our plot. Any predicted value above that
% line is considered a member of the class.
 
hline(threshold,'r--');
 
pause
%-------------------------------------------------
close
%----------------------------------
% The threshold is calculated using the observered distribution of
% predicted values and Bayesian statistics. These statisics can also tell
% us what the probability is of observing a specific predicted y value if
% we have a sample which is (or is not) a member of the class. To get this
% information, plsdthres is called with three outputs. In this case it is
% also called with the plot flag turned on to show us a graph of the
% observed distribution (top plot) and the fraction of misclassed
% calibration samples (bottom plot).
 
[threshold, misclassed, prob] = plsdthres(y.data,model.pred{2},[],[],1);
 
pause
%---------------------------------
% The histograms in the top plot show the observed y-predicted values. The
% smooth curves show the corresponding probibilty curves (note that the
% scale of the probability curves is not shown but is always zero to one).
% The accuracy of the probability curve will improve as the number of
% samples improves.
 
pause
%---------------------------------
% The probability curves are derived from the variable PROB which is a
% "lookup table" output by plsdthres. This can be used to calculate the
% probability that a given sample is a member of the class by using the
% predicted value from the PLSD model. For example, if we do a prediction
% of our validation samples:
 
valset_pred = modlpred(valset,model,0);
 
pause
%---------------------------------
% Then we use those predicted y-values and the lookup table, prob, in the
% Matlab interp1 function to determine probability of each sample being a
% member of the class (i.e. either quarry 2 or 4). 
 
valset_prob = interp1(prob(:,1),prob(:,2:3),valset_pred);
 
% The output of this command is two columns. The first column is the
% probability that the given sample is NOT a member of the class (i.e.
% probability the sample is from quarries 1 or 3 = P(1,3)) and the second
% column is the probability that the given sample IS a member of the class
% (i.e. probability the sample is from quarries 2 or 4 = P(2,4)). Looking
% at these along with the actual quarry assignments, all samples are
% classified correctly although two are slightly less than certain (last
% sample from quarry 1 and last sample from quarry 3):
 
disp(' ');  disp(['    Quarry    P(1,3)    P(2,4)']);  disp([valset.class{1}' valset_prob])
 
pause
%-------------------------------------------------
% Notes:
%  A probability of "NaN" results whenever the predicted y-value for a
%  sample is outside the range of y-values observed in the calibration set
%  and indicates that the class probability for that sample could not be
%  determined.
%
%  Remember that these probability values are only predictions from the
%  model and, as such, must be considered along with other model statistics
%  such as Q and Hotelling T^2 (found the model or prediction structures in
%  the fields ".ssqresiduals" and ".tsqs", respectively). If these other
%  statistics show the sample to be outside of the subspace of the
%  calibration samples, the predictions should not be considered reliable.
 
%End of PLSDTHRES demo
echo off
close
 
