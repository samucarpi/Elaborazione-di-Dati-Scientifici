echo on
%MATCHVARSDEMO Demo of the MATCHVARS function
 
echo off
%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
echo on
 
%To run the demo hit a "return" after each pause
 
pause
%--------------------------------------------------------------------------
% All PLS_Toolbox models assume that when new data comes in along with a
% model, the variables (columns) in that data are already in the same order
% as the variables in the calibration data. It is not uncommon that extra
% data is passed or that variables get shuffled around. In the case of
% spectra, the exact wavelength or wavenumber sampling may be off from that
% expected by the model.
%
% MATCHVARS is used to prepare data for a prediction using a standard
% PLS_Toolbox model. MATCHVARS re-arranges variables so they are in the
% order expected by the model. It also discards unneeded variables and
% inserts missing variables, as necessary.
% We'll demonstrate this using a PCA model but the same procedure would be
% used for other model types, including regression models.
 
pause
%--------------------------------------------------------------------------
% First we'll load the arch data and note the column order (here indicated
% by labels for each of the elements)
 
load arch
 
arch.label{2}
 
pause
%--------------------------------------------------------------------------
% Next, we'll create a PCA model from this data...
% We turn off the plotting and display in the PCA routine, set the
% preprocessing to autoscale and use 4 PCs to model the data.
 
options       = pca('options');     %get the default options structure
options.plots = 'none';             %change the plotting options
options.display = 'off';
options.preprocessing = {preprocess('default','autoscale')};
model         = pca(arch,4,options);  %construct the PCA model
 
pause
%--------------------------------------------------------------------------
% Now that we have that model, we'll take a few of the samples from arch,
% delete the "Ba" variable and add some "unneeded" variables.
 
newdata = arch(72:end,:);  %grab last samples
 
newdata = newdata(:,[1:2 4:10]);  %drop BA (variable 3) from newdata
 
junk = dataset(rand(4,3));
junk.label{2} = {'junk 1' 'junk 2' 'junk 3'};
newdata = [newdata junk];  %add unneeded columns
 
pause
%--------------------------------------------------------------------------
% Lets look at the current variables by looking at the column labels:
 
newdata.label{2}
 
% Note that Ba is missing and that we have our three new variables.
 
pause
%--------------------------------------------------------------------------
% Next, we rearrange all the columns to some random order
 
neworder = shuffle([1:12]')';
newdata = newdata(:,neworder);
 
pause
%--------------------------------------------------------------------------
% Lets look at the current order of the columns by looking at the column
% labels:
 
newdata.label{2}
 
% Clearly this data isn't in the correct order! If we tried to call PCA
% with this data, we would get an error.
 
pause
%--------------------------------------------------------------------------
% Now, we'll ask MATCHVARS to re-arrange this new data so that it matches
% the variables expected by PCA.
 
matched_newdata = matchvars(model,newdata);
 
% and we look at the column order one more time:
 
matched_newdata.label{2}
 
% This order matches the original data order and could be used with the PCA
% model to make a prediction. Our three unneeded variables are gone and
% a "filler" column has been put into place for the missing "Ba" variable.
 
pause
%--------------------------------------------------------------------------
% We can see the values for "Ba" in column 3:
 
matched_newdata.data(:,1:4)
 
% have been replaced with NaN's. PCA will replace these with a "best
% guess" based on the PCA model. See the REPLACE function for more
% information on this behavior.
 
pause
%--------------------------------------------------------------------------
%End of MATCHVARSDEMO
 
echo off
