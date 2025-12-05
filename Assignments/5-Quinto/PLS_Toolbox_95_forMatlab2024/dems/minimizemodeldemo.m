echo on
% MINIMIZEMODELDEMO Demo of the MINIMIZEMODEL function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
clear ans
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The minimizemodel function reduces the size of a model by removing
% information that is not strictly necessary to apply the model to new
% data. This does disable/break some plotting options for the model, but
% may reduce the model size significantly.
%
% The following shows an example using random data and a PLS model. First
% we'll generate some random data to build a model from:
 
x = rand(1000,10);
y = rand(1000,1);
 
pause
%-------------------------------------------------
% Next, we'll build a PLS model from this data and check its size:
 
model = pls(x,y,3,struct('plots','none','display','off'));
clear x y  %clear these to make "whos" easier to read...
whos
 
% note the "bytes" column of the table and the size of "model"
 
pause
%-------------------------------------------------
% We can get details on the model fields' sizes using minimizemodel with no
% outputs. 
 
pause
 
minimizemodel(model)
 
%This shows us which model fields are the largest consumers of memory...
 
pause
%-------------------------------------------------
% Finally, we'll call minimizemodel to reduce the model size...
 
modelmin = minimizemodel(model);
 
pause
%-------------------------------------------------
% and check the new sizes. Note both the "model" and "modelmin" lines:
 
whos
 
pause
 
%End of MINIMIZEMODELDEMO
 
echo off
