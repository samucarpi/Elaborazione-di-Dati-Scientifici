echo on
%REPLACEVARSDEMO Demonstrates the REPLACEVARS function 
% for replacing variables in PCA and PLS models. 
 
echo off
% Copyright © Eigenvector Research, Inc. 1992
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%Modified April 1994
%Modified BMW 3/98
%bmw 8/02
echo on 
 
% To start out the demonstration we'll load some process
% data into memory.  This data set will be divided into
% a test set and a calibration set.
 
load replacedata
 
% The data set we've just loaded consists of 20 process temperatures
% and 1 level measurement.  We can plot the calibration set to
% see what it looks like.
 
pause
%-------------------------------------------------
echo off
figure
subplot(211)
plot(repcal.data(:,1:20))
title('Data for replacevars Demo')
xlabel('Sample Number (time)')
ylabel('Temperature')
subplot(212)
plot(repcal.data(:,21))
title('Data for replacevars Demo')
xlabel('Sample Number (time)')
ylabel('Tank Level')
echo on
pause
%-------------------------------------------------
% Now lets build a PCA model of this data. As usual, we'll
% scale the data first, this time using autoscaling. Then
% we'll form the PCA model with the scaled data. The PCA plots
% will be omitted this time. For this data set 7 is a pretty 
% good number, so we will set the PCA function to calculate
% 7 PCs.
 
pause
%-------------------------------------------------
options.preprocessing = preprocess('default','autoscale');
options.plots = 'none';
model = pca(repcal,7,options);
 
pause
%-------------------------------------------------
% Now lets take a look at the Q residuals of the test set
% using the model from the calibration set. We can use the
% PCA function and the model we just created and get the
% predictions. 
 
pred  = pca(reptest1,model,options);
echo off
subplot(1,1,1);
plot(pred.ssqresiduals{1}), shg
hline(pred.detail.reslim{1})
title('New Sample Residuals with 95% Limits from Original Model')
xlabel('Sample Number (time)')
ylabel('Q Residual')
echo on
pause
%-------------------------------------------------
 
% Hopefully you noticed that right near the end of the period
% the Q residual went over the 95% limit and stayed there.
% We can determine the reason by calculating and plotting the
% raw residuals.
 
pause
%-------------------------------------------------
[xhat,resmat] = datahat(model,reptest1);
echo off
plot(resmat(51:end,:)'), hline
title('Residuals for Last 4 Samples of Test Data')
xlabel('Variable Number')
ylabel('Residual')
echo on
pause
%-------------------------------------------------
 
% As you can see, the residual on the fifth variable is very
% large, which is an indication that the sensor has failed.
% The failure of this sensor has also skewed the residuals on
% many of the other sensors, particulary the ones that are
% highly correlated with it. So, now lets use the REPLACEVARS
% function and see what the residuals would look like if we
% replaced the values from the bad sensors with the value that
% is most consistant with the PCA model we have used.
 
pause
%-------------------------------------------------
repdata = replacevars(model,5,reptest1);
[xhat,resmat] = datahat(model,repdata);
echo off
plot(resmat(51:end,:)'), hline
title('Residuals after Replacement of Variable 5')
xlabel('Variable Number')
ylabel('Residual')
echo on
pause
%-------------------------------------------------
 
% As you can see, the residual on variable 5 is now zero, but
% the residuals on the other sensors have a much more normal
% looking pattern than they did before.
 
% Now lets compare this to the results we would obtain if we
% calculated a whole new model leaving the bad variable out,
% instead of just replacing the bad variable with the PCA
% based estimate. As before, we will choose 7 PCs for the
% the model.
 
pause
%-------------------------------------------------
options.preprocessing = preprocess('default','autoscale');
options.plots = 'none';
repcal.includ{2} = [1:4 6:21];
model_5 = pca(repcal,7,options);
reptest1.includ{2} = [1:4 6:21];
[xhat,nresmat] = datahat(model_5,reptest1);
 
plot(nresmat(51:end,:)','-b'), hline
xlabel('Variable Number')
ylabel('Residual')
hold on
echo on
pause
%-------------------------------------------------
 
% Except for the "missing variable 5", these residuals look
% suspiciously like the residuals from the last plot.
% So lets compare these to the residuals from the replacement
% method by plotting them over the top.
 
pause
%-------------------------------------------------
echo off
plot([resmat(51:54,1:4) resmat(51:54,6:21)]','--r')
title('Residuals on New Model and Old Model with Replacement')
hold off
echo on
pause
%-------------------------------------------------
 
% As you can see, this shows that the residuals are essentially
% the same using either method. In fact, we have determined
% that in the noise-free case where data is truly rank deficient
% the results are identical. In real world cases this is an
% approximation but a very close one.
  
% But now lets get to the real reason that you might
% want to replace the values from sensors that have been
% identified as bad. We also have some data available from
% a period when an additional sensor failed. So in this new data
% sensor 5 will continue to be bad and then another sensor will
% fail sometime during the period. So first, lets scale the
% data and calculate the residual on the original model.
 
pause
%-------------------------------------------------
pred  = pca(reptest2,model,options);
echo off
plot(pred.ssqresiduals{1}), shg
hline(pred.detail.reslim{1})
title('New Sample Residuals with Limits from Original Model')
xlabel('Sample Number (time)')
ylabel('Q Residual')
echo on
pause
%-------------------------------------------------
 
% The failure is very hard to see in this plot. Can you find it?
% It is at sample 155.  Now lets see what the residual plot looks
% like after the sensor that we already know is bad has been
% corrected for.
 
pause
%-------------------------------------------------
repdata = replacevars(model,5,reptest2);
pred  = pca(repdata,model,options);
 
echo off
plot(pred.ssqresiduals{1})
hline(pred.detail.reslim{1})
title('New Corrected Sample Residuals with Limits from Original Model')
xlabel('Sample Number (time)')
ylabel('Q Residual')
echo on
pause
%-------------------------------------------------
 
% I believe you would find this much easier to see!
 
%End of REPLACEVARSDEMO
 
echo off
