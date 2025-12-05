echo on
%RMSEDEMO Demo of the RMSE function
 
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
% This demo will use the PLSDATA data set.
 
load plsdata
 
whos
 
pause
%-------------------------------------------------
% The objective here will be to construct several PLS
% models with Block 1 and then test with Block 2.
 
% For this demo we will extract the data from the DataSet
% objects and mean center.
 
[mcxcal,mxcal] = mncn(xblock1.data);        %mean center cal X-block 300x20
[mcycal,mycal] = mncn(yblock1.data);        %mean center cal Y-block 300x1
scxtest        = scale(xblock2.data,mxcal); %center test X-block     200x20
ytest          = yblock2.data;              %extract test Y-block    200x1
 
pause
%-------------------------------------------------
% In the first example we'll construct a 1 LV PLS model
% and call the RMSE function to get the RMSEP.
 
bpls             = simpls(mcxcal,mcycal,1);       %obtain regression vector
yppred           = rescale(scxtest*bpls',mycal);  %project and rescale predictions
rmsepp           = rmse(yppred-ytest)             %estimate prediction error
 
% In this case, RMSE calculated the Root Mean Square Error
% of the vector (yppred-ytest) passed in.
 
pause
%-------------------------------------------------
% Conversely, RMSE will accept two vectors and calculate
% the the Root Mean Square Error of the difference between
% the vectors. So, ...
 
rmsepp           = rmse(yppred,ytest)             %estimate prediction error
 
% gives the same results as the previous example.
 
pause
%-------------------------------------------------
% In the final example, several PLS models will be constructed
% and the RMSEP for all the models will be estimated.
 
% Here, we will calculate 10 PLS-1 models:
 
bpls             = simpls(mcxcal,mcycal,10);      %obtain regression vectors
yppredn          = rescale(scxtest*bpls',mycal(ones(1,10))); %project and rescale predictions
rmseppn          = rmse(yppredn,ytest)            %estimate prediction error
 
pause
%-------------------------------------------------
%  ... and we can plot the results
echo off
figure
plot(rmseppn,'-ob')
xlabel('Latent Variable'), ylabel('RMSEP')
echo on
 
%End of RMSEDEMO
 
echo off
