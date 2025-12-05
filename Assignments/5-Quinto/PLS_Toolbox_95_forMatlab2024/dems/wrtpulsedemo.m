echo on
% WRTPULSEDEMO Demo of the WRTPULSE function
 
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
% The WRTPULSE function is used to write shifted matrices
% for use in the identification of finite impulse response (FIR)
% and auto-recursive extensive variable (ARX) models. To demonstrate
% it, we'll create a small Dataset object with 3 input variables and
% another with the output variable.
 
pause
%-------------------------------------------------
echo off
 
ud = [[1:25]' [101:125]' [201:225]'];
yd = [301:325]';
ud = dataset(ud);
yd = dataset(yd);
ud.label{2} = ['temp ';'flow ';'power'];
ud.name = 'Temp and Flow Demo Data';
ud.labelname{1} = 'Time';
ud.labelname{2} = 'Variables';
ud.author = 'WRTPULSE DEMO';
 
echo on
ud, yd
 
pause
%-------------------------------------------------
% Lets take a look at the data fields of these datasets. The last
% column is the output
 
disp([ud.data yd.data])
 
% You can see that we used an integer series in order to make things
% simple.
 
pause
%-------------------------------------------------
% We can now create a new dataset where the input variables are lagged
% back by 5, 3 and 2 points, and there is a delay of 1, 1, and 3 points
% between the inputs and the output:
 
[newu,newy] = wrtpulse(ud,yd,[5 3 2],[1 1 3])
 
pause
%-------------------------------------------------
% Now lets look at the contents of newu and newy. The last column will be
% the output data. Note how the contents of the input file are lagged, and
% how the delay has been added.
 
disp([newu.data newy.data])
 
pause
%-------------------------------------------------
% WRTPULSE also created a new set of variable labels for newu to indicate
% how many time units each original variable is lagged with respect to the
% ouput:
 
newu.label{2}
 
pause
%-------------------------------------------------
% These dataset objects would now be ready to input into PLS or PCR for
% development of a dynamic model.
%
% WRTPULSE will also work when variables are excluded, but not when samples
% are excluded. The number of included variables must match the number of 
% lags n and delays given. WRTPULSE also works on doubles and produces outputs
% of doubles.
 
echo off
  
   
