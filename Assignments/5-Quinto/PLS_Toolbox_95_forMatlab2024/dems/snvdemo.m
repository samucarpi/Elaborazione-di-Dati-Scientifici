echo on
% SNVDEMO Demo of the SNV function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The SNV function is used to remove sample-specific scaling and offset
% differences in rows of a data matrix. It is often used on spectra where
% baseline and pathlength (or collection efficiency) changes cause
% differences between otherwise identical spectra. It is a form of
% normalization weighting mid-range values more than outlying large
% intensities. 
% (Mathematically, it is identical to an autoscaling of the rows instead of
% the columns; see the function AUTO)
 
pause
%-------------------------------------------------
% For example, given the single row:
 
row = [0:4];
 
% un-interesting variations to this row can be created by multiplying it
% by a scalar and offseting by some amount:
 
x = [row; row*5+10; row*200+55] 
 
pause
%-------------------------------------------------
% Although these rows appear very different, the SNV operation removes the
% mean value in each row and scales by the rows' standard deviation, thus
% removing the uninteresting scaling and offset differences:
 
snv(x)
 
%End of SNVDEMO
 
echo off
