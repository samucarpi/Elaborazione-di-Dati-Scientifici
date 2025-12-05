echo on
%DISCRIMPROBDEMO Demo of the DISCRIMPROB function
 
echo off
%Copyright Eigenvector Research, Inc. 2003 Licensee shall not recompile,
%translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%------------------------------------ 
% DISCRIMPROB calculates Bayesian probabilities for predictions from
% discriminate analysis models (PLS-DA or PCR-DA). For an introduction to
% creating discriminate models, see the PLSDTHRES demo.
%
% The probabilities output by DISCRIMPROB can be used to convert the
% continuous (i.e. non-integer) outputs of standard PLS and PCR models to
% the probability that this prediction would be observed for a sample in
% the class for which the model was built.
 
pause
%------------------------------------ 
% For example, Consider the archeological dataset "arch"... The arch data
% consists of x-ray fluorescence measurements of ten elements. The samples
% are from four different quarries assigned to four different classes, plus
% a set of "unknowns". This demo will use only the known samples.
 
load arch
arch = arch(find(arch.class{1}>0),:);    %use only "known" samples
size(arch)
 
pause
%------------------------------------ 
% First, we will build a very good PLS model which separates quarries 1 and
% 2 from the other quarries.
 
y = (arch.class{1}<=2)';  %identify samples in quarries 1 and 2
 
% Define modeling options
opts               = pls('options');
opts.preprocessing = {preprocess('default','autoscale') preprocess('default','meancenter')};
opts.plots         = 'none';
opts.display       = 'off';
 
model = pls(arch,y,3,opts);  %calculate PLS model
 
pause
%------------------------------------ 
% DISCRIMPROB uses the predicted y-values (in model.pred{2}) and the known
% class assignment (in y) to determine probabilities:
 
prob = discrimprob(y,model.pred{2});
 
pause
%------------------------------------ 
% The first column of the output (prob) is an evenly-spaced vector covering
% the range of observed predicted y-values. The subsequent columns contain
% the probability of observing the corresponding y-value for each class
% identified in y (typically just two classes, 0 and 1). If the two classes
% are well separated by the model, then the probability curves will be
% sharp.
 
figure
plot(prob(:,1),prob(:,2:3));
ylabel('Probability (lines)')
xlabel('Predicted y-value')
 
pause
%-------------------------------------------------
clf
%------------------------------------ 
% In this figure, the bars indicate the observed distribution of predicted
% y-values for "not-in-class" (y=0) samples (blue bars) and "in-class"
% (y=1) samples (green bars). The lines are the output of DISCRIMPROB and
% show the probabilities of observing that predicted y-value for a sample
% that is "not-in-class" (blue line) and a sample that is "in-class" (green
% line).  Note that the probability of observing a predicted y-value above
% 0.45 for a sample that is "not-in-class" is essentially zero and that the
% probability of observing a y-value below 0.45 for a sample "in-class" is
% also essentially zero.
 
n0 = hist(model.pred{2}(y==0),prob(:,1));  %calculate histograms
n1 = hist(model.pred{2}(y==1),prob(:,1));  % for in-and not-in-class
bar(prob(:,1),n0,'b'); hold on
bar(prob(:,1),n1,'g');
 
[ax,h1,h2] = plotyy([0],[0],prob(:,1),prob(:,2:3)); %plot prob
 
set(h2,'linewidth',2);  %do some labels
axes(ax(1)); ylabel('Frequency of Observation (bars)')
axes(ax(2)); ylabel('Probability (lines)')
xlabel('Predicted y-value')
hold off
 
pause
%-------------------------------------------------
clf
%------------------------------------ 
% Given a model that does not separate the two classes well gives different
% results. Here is a PCR model using just one PC which does a poor job of
% separating the classes.
 
opts               = pcr('options');
opts.preprocessing = {preprocess('default','autoscale') preprocess('default','meancenter')};
opts.plots         = 'none';
opts.display       = 'off';
 
model = pcr(arch,y,1,opts);  %calculate overly simple PCR model
prob  = discrimprob(y,model.pred{2});  %and probabilities
 
n0 = hist(model.pred{2}(y==0),prob(:,1));  %calculate histograms
n1 = hist(model.pred{2}(y==1),prob(:,1));  % for in-and not-in-class
bar(prob(:,1),n0,'b'); hold on
bar(prob(:,1),n1,'g');
 
[ax,h1,h2] = plotyy([0],[0],prob(:,1),prob(:,2:3)); %plot prob
 
set(h2,'linewidth',2);  %do some labels
axes(ax(1)); ylabel('Frequency of Observation (bars)')
axes(ax(2)); ylabel('Probability (lines)')
xlabel('Predicted y-value')
 
pause
%------------------------------------ 
% Here we observe that a predicted y-value of 0.2, for example, has about
% an 80% probability of being a "not-in-class" sample. 
%
% Overall, the poor separation of samples in quarries 1 and 2 ("in-class")
% from the other samples ("not-in-class") leads to non-zero probabilities
% of observing almost all values for either an "in-class" or a
% "not-in-class" sample. In this manner, the probability curves can be used
% to assess the quality of a discriminate model.
 
pause
%------------------------------------ 
% Note that the accuracy of the probabilities is highly dependent on the
% number of calibration samples and the distribution of predicted y-values.
% In this example, the distribution is probably not sufficient to lend much
% creedence to the absolute magnitude of the probabilities.
 
% End of DISCRIMPROB demo 
 
echo off
close
 
