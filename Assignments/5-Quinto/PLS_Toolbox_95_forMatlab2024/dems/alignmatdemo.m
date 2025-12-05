echo on
%ALIGNMATDEMO Demo of the ALIGNMAT function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Create data to test the alignment algorithm:
 
w = [0:0.1:50];
s = [sin(w); cos(w)*2].^2;                        %pure analyte spectra
t = [0:40]';
c = [exp(-((t-20).^2)/40) exp(-((t-25).^2)/30)];  %elution profiles
a = c*s + randn(length(t),length(w))*.01;         %outer product of elution and spectra
 
isub = 7:37;                                      %known indices
a = a(isub,:);                                    %standard matrix
b = c*s + randn(length(t),length(w))*.01;         %matrix to be aligned
 
% Note that (a) is the standard matrix. (b) is a larger matrix
% and the objective is to find the sub-matrix of (b), (bi), that
% looks most like the matrix (a). In this case, we are aligning
% in the time mode (mode 1).
 
pause
%-------------------------------------------------
figure
subplot(3,1,1), mesh(w,t(isub),a), axis([0 40 0 50 0 4]), title('Measured LC-NIR Matrix')
subplot(3,1,2), plot(t,c),         axis([0 40 0 1]),      title('Concentration Profile')
vline([min(t(isub))-0.1, max(t(isub))+0.1])
text(min(isub),0.8,'Region of standard matrix (a)')
subplot(3,1,3), plot(w,s),         axis([0 50 0 4]),      title('Spectra')
 
% Next, construct a PCA model of the standard matrix (a).
 
pause
%-------------------------------------------------
% Turn off the display options and make a 2 factor PCA model.
 
options         = pca('options');
options.display = 'off';
options.plots   = 'none';
amodel = pca(a,2,options);
 
pause
%-------------------------------------------------
% Now call ALIGNMAT
 
[bi,itst] = alignmat(amodel,b);
 
% plot the known indices and estimated indices from (itst)
 
figure
plot(isub,itst{1},'ob','markerfacecolor',[0 0 1]), dp
xlabel('Known Indices')
ylabel('Estimated Indices from ALIGNMAT')
 
% If the appropriate sub-matrix (bi) has been extracted from (a)
% then all the circles should lie on the diagonal.
%
% Note that some deviations from the diagonal may be apparent.
% These are due to noise affecting the interpolation.
%
%End of ALIGNMATDEMO
 
echo off
