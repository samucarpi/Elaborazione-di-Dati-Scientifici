echo on
% RINVERSEDEMO Demo of the RINVERSE function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%bmw
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The RINVERSE function is used to calculate the model pseudo-inverse for
% a variety of inverse least squares models. This includes PLS, PCR, and
% ridge regression models. The model pseudo-inverse of the predictor matrix
% X, often designated X+, can be used to obtain the regression vector b,
% i.e.   b = X+y
%
% We'll demonstrate the RINVERSE function by loading up some data and
% creating a PLS model. We'll pull the data out of the dataset objects
% and scale explicitly just so it will be clearer what we are doing.
%
load plsdata
[ax,mx,stdx] = auto(xblock1.data);
[ay,my,stdy] = auto(yblock1.data);
options = pls('options');
options.display = 'off';
options.plots = 'none';
mod = pls(ax,ay,3,options);
 
pause
%-------------------------------------------------
% Now we've got a PLS model with 3 LVs based on autoscaled data.
% We can calculate the PLS model pseudo-inverse with RINVERSE with:
%
rinv = rinverse(mod);
 
% We could have also specified a smaller number of LVs than 3 with a
% second input. This pseudo-inverse can be used to obtain the regression
% vector directly:
%
b = rinv*ay;
 
pause
%-------------------------------------------------
% This can be compared with the regression vector from the model
%
plot(1:20,b,'-+b',1:20,mod.reg,'-og')
legend('From RINVERSE','From Model'), hline
 
pause
%-------------------------------------------------
% As you can see, there isn't any difference. This vector can be used
% to make prediction on the second xblock, which can be rescaled and
% compared with the corresponding yblock.
%
sx = scale(xblock2.data,mx,stdx);
ypred = sx*b;
sypred = rescale(ypred,my,stdy);
plot(yblock2.data,sypred,'+b'), dp
xlabel('Actual Value');
ylabel('Predicted Value');
title('Predicted versus Actual Value for RINVERSE Demo')
pause
%-------------------------------------------------
% RINVERSE can be used in other instances such as when the leverage of
% samples on the model are required, as in STDSSLCT.
 
echo off   
