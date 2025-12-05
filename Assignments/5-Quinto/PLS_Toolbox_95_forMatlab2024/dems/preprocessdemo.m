echo on
% PREPROCESSDEMO Demo of the PREPROCESS function
 
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
% PREPROCESS is used to perform preprocessing operations on data. It allows
% the user to select preprocessing methods which are stored as
% instructions in a preprocessing structure.
% This demo will show its use on the demo NIR data set. The data is Near-IR
% spectral data.
 
load nir_data
 
pause
%-------------------------------------------------
% Create a preprocessing structure:
% PREPROCESS can be used as a GUI to select methods by simply calling it
% with no inputs, or by calling it with a previously created preprocessing
% structure:  s = preprocess   or   s = preprocess(s)
% It can also be used from the command line to create a preprocessing
% structure non-interactively by requesting a method by name. A list of
% available method names ("keywords") can be retrieved using the 'keywords'
% command with preprocess:
 
preprocess('keywords')
 
pause
%-------------------------------------------------
% Requesting a single preprocessing method:
% A preprocessing structure for any one of the available methods is created
% using the 'default' command and the appropriate keyword. Here the
% default Mean Center structure is returned:
  
s = preprocess('default','mean center')
 
pause
%-------------------------------------------------
% Multiple methods can be put into a preprocessing structure by adding
% additional strings in the 'default' call:
 
s = preprocess('default','normalize','mean center');
 
% The preprocessing structure now contains two records (1x2 struct) of
% which the first is the normalize method:
 
s(1).description
 
% and the second is the mean center method:
 
s(2).description
 
pause
%-------------------------------------------------
% Calibrating with a preprocessing structure:
% Many preprocessing methods require that they be first used on calibration
% data before being applied to new data. In this example, Mean Center does
% require this. To calibrate, preprocess is called with the keyword
% 'calibrate' along with the preprocessing structure and the data to
% calibrate on.  The outputs are the preprocessed data (here called
% "spec1p") and the modified preprocessing structure ("sp") which now has
% information stored in it to allow the method to be applied to new data.
 
[spec1p , sp] = preprocess('calibrate', s, spec1);
 
pause
%-------------------------------------------------
% Data is output as a DataSet object:
% Note that the input data to PREPROCESS can be either a normal array or a
% DataSet object. The output, however, is always a DataSet object. 
 
class(spec1p)
 
% (The data itself can be extracted from the DataSet object's .data
% field using something like:  mydata = spec1p.data  )
 
pause
%-------------------------------------------------
% Applying to new data:
% Once calibrated, a preprocessing method can be applied to new data using
% the 'apply' command. The inputs are the calibrated preprocessing
% structure (sp) and the new data (spec2) and only one output is returned,
% the preprocessed data:
 
spec2p = preprocess('apply', sp, spec2);
 
pause
%-------------------------------------------------
% Compare the original and preprocessed data:
 
figure
subplot(2,1,1)
plot(spec2.data')
title('Original Data')
subplot(2,1,2)
plot(spec2p.data')
title('Preprocessed Data')
 
% End of demo
 
echo off
 
 
 
