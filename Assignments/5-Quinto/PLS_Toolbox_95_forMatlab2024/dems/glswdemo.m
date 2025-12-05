echo on
%GLSWDEMO Demo of the GLSW function
 
echo off
%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%------------------------------------ 
%GLSW performs deweighting of differences between two matrices (or even
%multiple groups). Often it is used for instrument standardization or
%otherwise pre-treating data prior to building a calibration model.
%
%This function requires that you identify two or more blocks of data which
%should be identical except that some experimental parameter (e.g. two
%different instruments has induced a difference). These differences will be
%determined and "deweighted". Deweighting reduces the difference dimensions
%to some user-defined extent. The critical piece of GLSW output is a
%"deweighting matrix" containing the multivariate directions to remove.
 
pause
%-------------------------------------------------
%This demo shows how to use the GLSW function to identify and downweight
%the differences between two instruments to allow the same classical least
%squares (CLS) model to be used on both instruments. The data used to
%demonstrate this operation is the NIR data of simulated gasoline samples.
%The same 30 samples were measured on two different instruments with
%corresponding differences which need to be removed in order to use the
%same model on both instruments. These are the spec1 and spec2 datasets:
 
load nir_data
whos
 
pause
%-------------------------------------------------
%If we build a CLS model from instrument 1 and attempt to predict
%concentrations on instrument 2, the results are poor:
 
pspec = conc.data \ spec1.data;   %calculate CLS model
cest1 = spec1.data / pspec;       %estimate for instrument 1
cest2 = spec2.data / pspec;       %estimate for instrument 2
 
%Let's look at those predictions...
 
pause
%-------------------------------------------------
figure
plot(conc.data(:),cest1(:),'go',conc.data(:),cest2(:),'rx');
xlabel('Measured Concentrations'); ylabel('Estimated Concentrations');
title('CLS Results from Unstandardized Data')
legend({'Instrument 1','Instrument 2'})
dp; hline('--k'); vline('--k');
 
pause
%-------------------------------------------------
%We need to use GLS to standardize these two instruments. To perform this
%standardization, we first need to identify which samples to use. We'll
%select 6 samples from the outer edges of the data. The distslct function
%to do this:
 
samps = distslct(spec1.data,6)
 
pause
%-------------------------------------------------
%Now we'll call glsw passing the samples measured on both instruments
%and the "deweighting threshold" alpha. As alpha gets smaller, the extent
%of deweighting increases (more factors are included in the deweighting
%matrix). We'll start with a guess at alpha, but this should be optimized,
%possibly using cross-validation.
 
alpha = 0.001;
glsmodl = glsw( spec1.data(samps,:), spec2.data(samps,:), alpha);
 
pause
%-------------------------------------------------
%Now we apply that glsw model to BOTH instruments:
 
spec1gls = glsw( spec1, glsmodl);
spec2gls = glsw( spec2, glsmodl);
 
%and finally we'll recalibrate the model (using the standardized instrument
%1 data!) and apply it to both standardized data sets.
 
pspec = conc.data \ spec1gls.data;   %calculate CLS model (modified inst1)
cest1s = spec1gls.data / pspec;       %estimate for modified instrument 1
cest2s = spec2gls.data / pspec;       %estimate for modified instrument 2
 
%and now look at the results:
 
subplot(2,1,1)
plot(conc.data(:),cest1(:),'go',conc.data(:),cest2(:),'rx');
xlabel('Measured Concentrations'); ylabel('Estimated Concentrations');
title('CLS Results from Unstandardized Data')
legend({'Instrument 1','Instrument 2'})
dp; hline('--k'); vline('--k');
 
subplot(2,1,2)
plot(conc.data(:),cest1s(:),'go',conc.data(:),cest2s(:),'rx');
xlabel('Measured Concentrations'); ylabel('Estimated Concentrations');
title('CLS Results from GLSW Standardized Data')
dp; hline('--k'); vline('--k');
 
%These results are far better. We can calculate the RMSE (Root Mean Squared
%Error) for Instrument 2 for all five components in the mixtures:
echo off
disp(' ');
disp('RMSE without Standardization : ')
disp(sprintf('   % 6.2f ',rmse(conc.data,cest2)));
disp('RMSE with Standardization : ');
disp(sprintf('   % 6.2f ',rmse(conc.data,cest2s)));
echo on
 
pause
%-------------------------------------------------
%GLSW can also be used on a single dataset by passing "classes" as the
%second input. This form of input can be used if all the data is in a
%single matrix to begin with or if you are trying to reduce directions
%between samples in a matrix. This is not currently shown in this demo.
 
pause
%-------------------------------------------------
% End of GLSWDEMO
 
echo off
 
 
