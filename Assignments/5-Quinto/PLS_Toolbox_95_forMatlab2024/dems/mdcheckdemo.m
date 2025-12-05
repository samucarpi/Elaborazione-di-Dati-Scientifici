echo on
% MDCHECKDEMO Demo of the MDCHECK function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rb
%
%
clear ans
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% MDCHECK is a routine that can be used for imputing missing values or
% simply for reporting the presence and location of missing values.
%
% Make a data set that follows a bilinear model:
%
%
 
t = [1 2 3 4 5]';
p = [2 3 2 3 2]';
X = t*p';
 
% Add a little noise
X = X+randn(size(X))*.001;
 
pause
%-------------------------------------------------
% Let some elements be missing
%
%
 
Xmiss = X;
Xmiss(1,1)=NaN;
Xmiss(3,1)=NaN;
Xmiss(4,5)=NaN;
 
X,Xmiss
 
 
pause
%-------------------------------------------------
% To see if there are missing data in Xmiss simply type
%
%
 
fraction = mdcheck(Xmiss)
 
 
% which provides the fraction of missing data. 
%
%
pause
%-------------------------------------------------
 
% Possibly add the output, missmap, to get the location of these 
% missing values
%
%
 
[fraction,missmap] = mdcheck(Xmiss)
 
pause
%-------------------------------------------------
% Finally, you may add a third output to make MDCHECK provide
% an estimate of the missing values. The third output, infilled,
% is a datamatrix identical to X except that missing values are
% replaced with their imputed values
%
%
 
[fraction,missmap,infilled] = mdcheck(Xmiss);
 
pause
%-------------------------------------------------
% Compare the original data with the imputed dataset
%
%
X,infilled
 
pause
%-------------------------------------------------
% As can be seen, most of the three values are reasonable but 
% the first element is a bit off. MDCHECK works by iteratively
% fitting a PCA model to the data and replacing the missing 
% values with their model estimates. As a default, the data are
% initially centered. While this is fine for large data sets with
% a little missing data, it can disturb the analysis with small
% data sets because the means are misleading.
%
%
pause
%-------------------------------------------------
% Remove meancentering from the MDCHECK routine and redo the analysis
%
%
 
 
myopt=mdcheck('options')
myopt.meancenter = 'no';
myopt.toomuch = 'ignore';  %do NOT discard rows/columns with too much missing data
[fraction,missmap,infilled] = mdcheck(Xmiss,myopt);
%
%
 
pause
%-------------------------------------------------
% Compare the original data with the imputed dataset
%
%
X,infilled
 
pause
%-------------------------------------------------
 
 
%End of MDCHECKDEMO
 
echo off
