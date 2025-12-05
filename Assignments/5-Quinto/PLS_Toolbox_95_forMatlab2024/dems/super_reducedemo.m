echo on;
%SUPER_REDUCEDEMO Demo of super_reduce
 
echo off
% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
%This example will use lcms data that have been reduced using the function
%CODA_DW.CODA_DW results in the chemically significant chromatograms of a 
%complex data set and leaves out noisy chromagrams. However, there are often
%highly correlated chromatograms in the reduced data.
%SUPER_REDUCE aims to leave only one chromatogram at a certain retention time by
%eliminating highly correlated chromatograms, but leaving the one with the
%highest intensity, see:                                               
%W. Windig, W.F. Smith, W.F. Nichols,                              
%Fast Interpretation of Complex LC/MS Data Using Chemometrics,     
%Anal. Chim. Act 446, 2001, 467-476.
%
%We will first determine the 50 most significant chromatograms of a file.
pause
%-------------------------------------------------
load lcms
[dw_value,dw_index]=coda_dw(lcms.data,50);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%The top plot show aall the original chromatograms. The bottom plot shows
%the reduced data.
%We see quite a few highly correlated chromatograms. With SUPER_REDUCE we will 
%eliminate of these 60 chromatograms the ones with a correlation larger then .65,
%but leave the most intense of the correlated chromatograms.
pause
%-------------------------------------------------
data_reduced=lcms.data(:,dw_index(1:50));
corr_values=super_reduce(data_reduced,.65);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%The top plot shows the reduced data. The bottom plot shows the super-reduced
%data. We see that we indeed have one chromatogram per component now. If we want
%see if we can use a lower correlation value, e.g. 0.3 we do not need to
%run the program again, but we can use the calculated values. The top plot
%will show the results for a correlation level of 0.65 and the bottom plot
%the results for a correlation level of 0.3:
pause
%-------------------------------------------------
subplot(211);plot(data_reduced(:,corr_values<.65));
title('correlation level: 0.65');
subplot(212);plot(data_reduced(:,corr_values<.3));
title('correlation level: 0.3');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%We see that more chromatograms were deleted here.
pause
