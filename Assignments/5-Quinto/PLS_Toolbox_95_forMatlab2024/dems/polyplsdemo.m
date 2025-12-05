echo on
%POLYPLSDEMO Demo of the POLYPLS function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
load paint
 
% The data for this demo is described in D. H. Alman and C. G. Pfeifer,
% "Empirical color mixture models", Color Research and Application,
% 12, 210-222 (1987).
% 
% This is a nonlinear data set, from formulation of color paints.
% There are four inputs, the concentrations of colorants (white, 
% black, violet, magenta), and three outputs, the color values   
% (black to white, red to green , yellow to blue). The first 49  
% samples (xcal and ycal) are for training and the last 8 samples
% (xtest and ytest) are for testing. This is a quaternary quartic
% mixture design.

%  paint_cal_X    49x4 dataset  Colorant concentrations for training data        
%  paint_test_X    8x4 dataset  Colorant concentrations for test data
%  paint_cal_Y    49x3 dataset  Black/white, Red/green, Yellow/blue values
%  paint_test_Y    8x3 dataset  Black/white, Red/green, Yellow/blue values
 
pause
%-------------------------------------------------
% After the demo the user is encouraged to load paint.mat,
% plot and examine the data.
 
% It's always good to compare to other approaches. So,
% before we use POLYPLS let's try plain old vanilla PLS.
 
% For this demo we will mean center the data.
 
xcal = paint_cal_X.data;
xtest = paint_test_X.data;
y1cal = paint_cal_Y.data(:,1);
y1test = paint_test_Y.data(:,1);
[mcxcal,mxcal] = mncn(xcal);                      %mean center cal X-block
[mcycal,mycal] = mncn(y1cal);                     %mean center cal Y-block
scxtest        = scale(xtest,mxcal);              %center test X-block
 
% Now perform cross-validation (using SIMPLS, venetian blinds,
% with 6 splits, and estimate RMSECV for up to 4 LVs.
 
pause
%-------------------------------------------------
crossval(mcxcal,mcycal,'sim',{'vet',6},4);
 
% Cross-validation suggests using 2 latent variables, but the vaiance
% captured table suggests using only 1. We'll try a 2 LV PLS model
% model using the SIMPLS function. Then we'll make predictions for
% the test set and plot the results.
 
pause
%-------------------------------------------------
bpls             = simpls(mcxcal,mcycal,2);            %obtain regression vector
yppred           = rescale(scxtest*bpls(2,:)',mycal);  %project and rescale predictions
rmsepp           = rmse(yppred,y1test);                %estimate prediction error
 
echo off
hfig             = figure;
hplt(1)          = plot(y1test,yppred,'rs'); hold on
axis([0 50 0 50]), dp
xlabel('Measured'), ylabel('Predicted')
text(2,40,sprintf('PLS RMSEP =    %1.2f',rmsepp))
 
legend(hplt(1),'PLS', 'Location','NorthWest')
shg
echo on
  
% This shows how the PLS model performed. Now, let's
% try a POLY-PLS model.
 
% Here we'll try a 2 LV PLS model with a 3rd order
% polynomial inner relation.
 
pause
%-------------------------------------------------
[p,q,w,t,u,b2]   = polypls(mcxcal,mcycal,2,3);         %calibration
y2pred           = rescale(polypred(scxtest,b2,p,q,w,2),mycal);  %test
rmsep2           = rmse(y2pred,y1test);                %estimate prediction error
 
echo off
figure(hfig), legend off
hplt(2)          = plot(y1test,y2pred,'ob','markerfacecolor',[0 0 1]);
text(2,36,sprintf('POLY-PLS RMSEP = %1.2f',rmsep2))
legend(hplt,'PLS','POLY-PLS', 'Location','NorthWest')
shg
echo on
 
% This shows that the non-linear POLYPLS model performs
% better than the linear PLS model for this data.
 
%End of POLYPLSDEMO
 
echo off
