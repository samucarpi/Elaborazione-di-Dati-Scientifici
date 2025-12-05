echo on

%Demo of the PEAKFUNCTION, PEAKSTRUCT and PEAKIDTEXT functions
 
echo off
%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
 
%Make known Gaussian peaks
 
ax      = 0:0.1:100;
y       = peakgaussian([2 51 4],ax) + peakgaussian([4 39 5],ax);
 
%Then define a first estimate and peak type.
%An empty 2 record standard peak structure is created
%using the PEAKSTRUCT function.
 
peakdef = peakstruct('',2);
 
pause
 
%Each record is an empty structure for a Gaussian peak with
%vectors for parameters, bounds, and penalties all set to
%appropriate sizes.
 
disp(peakdef(1))
 
pause
  
%Each record of (peakdef) corresponds to an individual peak.
%The initial parameters for each peak can be modified maually:
  
peakdef(1).id    = 'Peak 1';
peakdef(1).param = [ 1.5 55   4  ]; %Coef, Position, Spread
peakdef(1).lb    = [ 0   48   0.1]; %lower bounds on param
peakdef(1).ub    = [10   70  10  ]; %upper bounds on params
peakdef(2).id    = 'Peak 2';
peakdef(2).param = [ 3   35   3  ]; %Coef, Position, Spread
peakdef(2).lb    = [ 0   32   0.1]; %lower bounds on param
peakdef(2).ub    = [10   47  10  ]; %upper bounds on params
 
pause
 
%The initial guess for the peak fit is given by:
 
yint    = peakfunction(peakdef,ax);
 
%and the estimated best-fit peak structure and fit are given by:
 
[peakdefo,fval,exitflag,out,yfit] = fitpeaks(peakdef,y,ax);
%Note that yfit = peakfunction(peakdefo,ax);
 
pause
 
%Next plot the results and put labels on the peaks
figure
plot(ax,yint,'m',ax,y,'b',ax,yfit,'r--')
legend('Initial','Actual','Fit')
title('Two Gaussian Peaks')
axis([0 100 0 4.5])
peakidtext(peakdefo)
 
%End of PEAKFUNCTIONDEMO
 
%See also: FITPEAKS, and PEAKFUNCTION
 
echo off
