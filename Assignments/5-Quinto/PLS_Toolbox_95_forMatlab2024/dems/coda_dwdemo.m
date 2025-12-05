close all;
%Copyright (c) Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
echo on;
%CODA_DWDEMO Demo of coda_dw
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%The demo will use an LC/MS electrospray file. The spectra are stored in the 
%rows and the mass chromatograms in the columns. The data contains a 
%significant contribution of solvent peaks which hide the signal. This demo 
%will show how a series of chromatograms can be selected which contain the 
%significant chemical information, i.e., the solvent peaks are not shown.
%For more information see:     
%W. Windig
%The use of the Durbin-Watson criterion for noise and background reduction of complex
%Liquid Chromatography/Mass spectrometry data and a new algorithm to determine sample
%differences.
%submitted for publication in J. Chemom. Intell. Lab. Syst.
%For previously published methods see:
%W. Windig, J.M. Phalp, A.W. Payne,                                
%A Noise and Background Reduction Method for Component Detection in
%Liquid Chromatography/Mass Spectrometry,                          
%Anal. Chem., 68, 1996, 3602-3606.                                 
%and                                                               
%W. Windig, W.F. Smith, W.F. Nichols,                              
%Fast Interpretation of Complex LC/MS Data Using Chemometrics,     
%Anal. Chim. Act 446, 2001, 467-476.
%
%The program calculates qualitity values for the chromatograms. The technqiue
%is based on the Durbin Watson criterion. A good chromatogram has a low value for the
%Durbin-Watson criterion.
%We will load a file and run the program and show some 'typical' cases with their
%value for the Durbin-Watson criterion. To be more precise: the value of
%the Durbin-Watson criterion of the first derivative chromatogram.
pause
%-------------------------------------------------
load lcms
var_index=[137 138 23 538];%typical representatives of chromatograms
[dw_value,dw_index]=coda_dw(lcms.data(:,var_index));
 
for i=1:4;
    subplot(4,1,i);
    plot(lcms.data(:,var_index(i)));title(['Durbin Watson value: ',...
            num2str(dw_value(i))]);
    set(gca,'xticklabel',[]);
end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%It is clear that the values listed in the titles are low for high quality 
%chromatograms. Setting a level for the values (i.e., only plot chromatograms
%with a lowever value) will result in a plot of high quality chromotograms.
%We will use a level of 2.1 and let the program plot the results.
pause
%-------------------------------------------------
[dw_value,dw_index]=coda_dw(lcms.data,2.1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%It is clear that the program eliminates the low quality chromatograms. 
%The titles of both plots show the number of variables selected and the lowest
%quality value used is listed at the bottom. The output argument q_value 
%contains all the quality values. The output argument shows the indices of the
%q_values, starting with the highest value. The next two plots show how we can
%use these output arguments. The top plot show the chromatograms with a dw_value
%less than 2.25. The bottom value shows the best 10 chromatograms.
pause
%-------------------------------------------------
subplot(211);plot(lcms.data(:,dw_value<2.25));
title('chromatograms with Durbin-Watson value <2.25:lcms\_obj.data(:,dw\_value<2.25)');
subplot(212);plot(lcms.data(:,dw_index(1:10)));
title('10 ''best'' chromatograms: lcms\_obj.data(:,dw\_index(1:10))');
shg
 
 
 
 
 
