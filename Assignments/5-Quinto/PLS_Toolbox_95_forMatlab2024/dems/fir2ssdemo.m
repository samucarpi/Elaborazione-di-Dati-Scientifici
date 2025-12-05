echo on
% FIR2SSDEMO Demo of the FIR2SS function
 
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
% The FIR2SS function is used to convert finite impulse
% response (FIR) models into the PHI, GAMMA, C and D
% matrices of the state-space formalism.
 
pause
%-------------------------------------------------
% Given a set of FIR coefficents such as
 
b = [1 5 10 6 3 2 1];
 
pause
%-------------------------------------------------
% FIR2SS will create the state-space model as follows:
 
[phi,gam,c,d] = fir2ss(b)
 
pause
%-------------------------------------------------
% The state space model can then be used with other control
% tools to test the frequency response of the model, etc.
 
echo off
  
   
