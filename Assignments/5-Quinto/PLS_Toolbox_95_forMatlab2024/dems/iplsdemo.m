echo on
%IPLSDEMO Demo of the IPLS function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%--------------------------------------------------- 
% IPLS performs exhaustive search variable selection in an attempt to
% improve the fit of a PLS model. The following shows how to run a simple
% IPLS analysis. First, load data of interest.
 
load plsdata
whos
 
pause
%--------------------------------------------------- 
% IPLS can be run in "forward" (addition) mode or in "reverse" (exclusion)
% mode. In either case, IPLS breaks the x-block variables up into separate
% intervals and selects the interval or intervals which provide the best
% prediction (root mean squared error of cross-validation, RMSECV) for the
% y-block in cross-validation. In forward mode, IPLS starts with no
% variables selected and each separate interval is tested for its ability
% to predict the y-block. In the end, the interval which provides the best
% prediction is selected. In reverse mode, IPLS starts with all intervals
% selected and the effect on y-block prediction of discarding each separate
% interval is tested. That is, reverse mode discards the least useful
% interval. This demo will demonstrate both approaches.
 
pause
%--------------------------------------------------- 
% To get accurate results, the data should be preprocessed as it would be
% for a final model. In some cases, preprocessing can be done before IPLS.
% However, because IPLS uses cross-validation to determine the fit of each
% model, it is sometimes better to have IPLS do the preprocessing
% on-the-fly (as it tests different models). Note that this slows the
% analysis but gives better results. (USEFUL HINT: Even if you are not
% going to use autoscaling in your final model, using it before a GA run
% sometimes makes bad variables look REALLY bad and makes the algorithm
% more likely to discard these bad variables!)
 
pause
%--------------------------------------------------- 
% The default options for IPLS can be obtained by requesting them from
% the IPLS function and we'll add "autoscale" to these options as the
% preprocessing:
 
options = ipls('options')
options.preprocessing = {'autoscale' 'autoscale'};
 
pause
%--------------------------------------------------- 
% First, lets call IPLS and request that it tell us which one interval
% gives the best RMSECV. In this case, we're going to have one variable per
% interval (i.e. we're selecting variables one at a time).
 
pause
%--------------------------------------------------- 
 
int_width = 1;  %one variable per interval
maxlv = 5; %up to 5 latent variables allowed
sel   = ipls(xblock1,yblock1,int_width,maxlv,options)
 
% The final figure shows the fit as a function of variable number. Each
% interval has its own bar indicating the RMSECV if that interval is used.
% The selected interval is shown in green. It turns out that variable 18 is
% selected and this is consistent with the data. 
 
pause
%--------------------------------------------------- 
% We can also do "sequential" addition of multiple intervals by modifying
% the "numintervals" option. This will ask ipls to select the best
% interval, then select a second interval which best improves the fit
% when used together with the first interval.
 
pause
%--------------------------------------------------- 
 
options.numintervals = 2;  
sel = ipls(xblock1,yblock1,int_width,maxlv,options);
 
% And we see that variable 8 is selected to use along with 18. It turns out
% that variables 1-10 and 11-20 are essentially replicate measurements (two
% different sets of thermocouples) so the fact that both 8 and 18 are
% "useful" in predicting y isn't too surprising. These two variables, it
% turns out, also have the highest weights in a PLS model including all the
% variables.
 
pause
%--------------------------------------------------- 
% In "reverse" mode, we can ask IPLS to tell us the best interval(s) to
% discard. Here we'll ask IPLS to split the data into 2 variables in each
% interval, then tell us which two of those intervals are the best to
% discard...
 
pause
%--------------------------------------------------- 
  
options.mode = 'reverse';  %discard intervals
options.numintervals = 2;  %drop worst 2
int_width    = 2;  %2 variables per interval
sel = ipls(xblock1,yblock1,int_width,maxlv,options);
 
% The discarded itervals are shown in red, the retained ones in green. We
% see that IPLS discarded variables 13,14, 15 and 16. Removing these
% variables most improved the fit. Note again that it makes sense from what
% we know of the data. These variables are not very useful for prediction
% of this y-block. 
 
pause
%--------------------------------------------------- 
 
%End of IPLSDEMO
 
echo off
