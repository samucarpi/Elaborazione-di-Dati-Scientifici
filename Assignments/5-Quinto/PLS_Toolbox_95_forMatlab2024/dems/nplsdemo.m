echo on
%NPLS DEMO Demonstrates NPLS regression
%
%  This demonstration illustrates the use of the multilinear 
%  partial least squared regression (NPLS) in the PLS_Toolbox.
 
echo off
%Copyright Eigenvector Research, Inc. 1992
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified 11/99 RB
 
echo on
 
% The data we are going to work with is a fluorescence data set
% 268 samples of refined sugar was sampled directly from a sugar 
% plant and excitation-emission landscapes were measured of the
% sample dissolved in water. Also available is the lab quality
% measure color, which is a measure of the amount of impurities.
% We will develop a model that relates the fluorescence data to
% the physical property color. Such a model can be used to replace
% the tediuos, time-consuming, infrequent, expensive and chemical-consuming
% lab-measurement with an on-line method.
% 
% Lets start by loading and plotting the data. Hit a key when
% you are ready.
 
pause
%-------------------------------------------------
echo off
load sugar
subplot(2,1,1)
mesh(sugar.axisscale{3},sugar.axisscale{2},squeeze(sugar.data(1,:,:)));
title('X-block data for the first sample (Predictor Variables) for NPLS Demo');
xlabel('Emission');
ylabel('Excitation');
zlabel('Intensity')
subplot(2,1,2)
plot(sugar.userdata)
title('Y-block data (Predicted Variable/color) for NPLS Demo');
xlabel('Sample Number');
ylabel('Level');
 
echo on
 
% We will start by dividing the data into a test set and a
% calibration set. We'll take every 12'th sample in the 
% calibration set, hence there are only 23 samples in the
% calibration set.
% 
% Scaling is not relevant for these spectral data, but the
% data are mean-centered to remove possible offsets
 
InCalSet  = [1:12:size(sugar.data,1)]';
InTestSet = delsamps([1:size(sugar.data,1)]',InCalSet);
Xcal     = delsamps(sugar,InTestSet,1,2);
Ycal     = delsamps(sugar.userdata,InTestSet);
Xtest    = delsamps(sugar,InCalSet,1,2);
Ytest    = delsamps(sugar.userdata,InCalSet);
 
 
MeanX     = [1 0 0];
ScaleX    = [0 0 0];
settingsX = [MeanX;ScaleX];
MeanY     = [1 0];
ScaleY    = [0 0];
settingsY = [MeanY;ScaleY];
 
[Xmean,preparX]=npreprocess(Xcal,settingsX);
[Ymean,preparY]=npreprocess(Ycal,settingsY);
 
 
% Now that the data are preprocessed, we can use the PLS routine
% to make a calibration. Lets start by using all the data to 
% make models and see how variance they capture.  We'll also 
% make a model using MLR and compare it to the PLS model.
pause
%-------------------------------------------------
maxlv = 5;
modelnpls = npls(Xmean,Ymean,maxlv);
echo off
disp(' '),disp(' ')
echo on
XmeanUnfold=reshape(Xmean.data,size(Xmean.data,1),prod(size(Xmean.data))/size(Xmean.data,1));
[b,ssq,p,q,w,t,u,bin] = pls(XmeanUnfold,Ymean,maxlv);
 
 
% Take a look at the outputted graphics from NPLS and notice
% how loadings are given for the excitation and the emission
% modes separately. That makes exploration and validation 
% much simpler than in the ordinary two-way pls model of the 
% same data (press a key to remove figures)
pause
%-------------------------------------------------
close all
 
% We can also see from the variance captured by the NPLS and
% PLS models that the variance fitted in both X and y is smaller
% for NPLS than for PLS. This is typical (especially on the X 
% side) for NPLS and illustrates the important fact, that NPLS
% filters away more variation because it is mathematically a
% simpler model (less free parameters). However, the interesting
% aspect is not the amount of variance fitted but the predictive
% ability. If NPLS predicts as well as, or better than, PLS, 
% then NPLS is clearly preferable due to its parsimony.
 
pause
%-------------------------------------------------
 
% Now lets use the NPLS and PLS models to calculate the fitted
% level to the training/test data and compare it to 
% the actual level.
pause
%-------------------------------------------------
[XmeanTest]=npreprocess(Xtest,settingsX,preparX);
[YmeanTest]=npreprocess(Ytest,settingsY,preparY);
XmeanTestUnfold = reshape(XmeanTest.data,size(XmeanTest.data,1),prod(size(XmeanTest.data))/size(XmeanTest.data,1));
 
echo off
Result=[];
for i = 1:maxlv
   PredNpls  = npls(XmeanTest,YmeanTest,i,modelnpls);
   YnplsPred = npreprocess(PredNpls.pred{2},settingsY,preparY,1);
   YplsPred  = XmeanTestUnfold*b(i,:)';
   YplsPred = npreprocess(YplsPred,settingsY,preparY,1);
   stdnpls = std(Ytest-YnplsPred);
   stdpls = std(Ytest-YplsPred);
   Result=[Result;[stdnpls stdpls]];
end
 
echo off
 
disp('  ')
disp('   RMSEP for Test Set  ')
disp('  ')
disp('   LV       NPLS        PLS')
disp('   ----    -------    -------')
ssq = [(1:maxlv)' Result];
format = '   %3.0f     %6.2f     %6.2f';
for i = 1:maxlv
   tab = sprintf(format,ssq(i,:)); disp(tab)
end
echo on
 
 
% As can be seen the real predictive ability of the two
% models is almost exactly the same. This is typical of
% many spectral data sets. It is therefore clear that NPLS
% is the preferable method to use because of its more
% parsimonious, interpretable and expectedly robust model
% 
% Let us see the predictions of the test set using
% four components
 
pause
%-------------------------------------------------
lv = 4;
PredNpls = npls(XmeanTest,YmeanTest,lv,modelnpls);
YnplsPred = npreprocess(PredNpls.pred{2},settingsY,preparY,1);
YplsPred  = XmeanTestUnfold*b(lv,:)';
YplsPred = npreprocess(YplsPred,settingsY,preparY,1);
 
subplot(2,1,1)
plot(Ytest,YnplsPred,'o');
rmsep = std(Ytest-YnplsPred,1);dp
title(['Pred vs. fitted by NPLS ',num2str(lv),' LV - RMSEP=',num2str(round(rmsep*100)/100)])
subplot(2,1,2)
plot(Ytest,YplsPred,'o');
rmsep = std(Ytest-YplsPred,1);dp
title(['Pred vs. fitted by unfold-PLS ',num2str(lv),' LV - RMSEP=',num2str(round(rmsep*100)/100)])
 
% The predictions are very similar as expected, so 
% quantitatively there is not much difference between
% the two competing models. However, the NPLS model is
% much easier to interpret because it has loadings
% of the same size as the variable modes:
%
%   Emission loadings of length 44 and
%   excitation loadings of length 7.
%
% UnfoldPLS on the other hand has only one set of
% loadings but these are of length 308 (44*7)!
%
%
%
% Lets finally look at the regression coefficients for 
% these two four-component models
 
pause
%-------------------------------------------------
subplot(2,1,1)
mesh(sugar.axisscale{3},sugar.axisscale{2},modelnpls.reg{lv})
title(['Regr. Coefficients from NPLS ',num2str(lv),' LV'])
axis([sugar.axisscale{3}(1) sugar.axisscale{3}(end) sugar.axisscale{2}(1) sugar.axisscale{2}(end) min(modelnpls.reg{lv}(:)) max(modelnpls.reg{lv}(:))])
subplot(2,1,2)
mesh(sugar.axisscale{3},sugar.axisscale{2},reshape(b(lv,:),size(sugar.data,2),size(sugar.data,3)))
title(['Regr. Coefficients from PLS ',num2str(lv),' LV'])
axis([sugar.axisscale{3}(1) sugar.axisscale{3}(end) sugar.axisscale{2}(1) sugar.axisscale{2}(end) min(b(lv,:)') max(b(lv,:)')])
 
% It seems that the trilinearly based regression coefficients
% are slightly less noisy which is also what is expected
% as the trilinear model has more structure imposed
 
% End of NPLS DEMO
