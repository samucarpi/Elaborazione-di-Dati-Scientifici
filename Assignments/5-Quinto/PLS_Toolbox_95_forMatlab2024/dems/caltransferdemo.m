echo on
%CALTRANSFERDEMO Demo of the CALTRANSFER function
 
echo off
%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk
 
echo on
 
%To run the demo hit a "return" after each pause
pause

%This demo conatians abriviated versions of the demos for the underlying
%methods. It is meant as a unit test for caltransfer and to demonstrate how
%to call the function. For more information about the methods see the
%spefic demo.
 
pause
 
%-------------------------------------------------
%STD
%-------------------------------------------------
 
load nir_data
 
isel = distslct(spec1.data,5); % (isel) are the sample indices
 
spec1.include{1} = isel;
spec2.include{1} = isel;
 
%DS
[dsmodel,x1,newX2] = caltransfer(spec1,spec2,'ds');
newX2_2 = caltransfer(spec2,dsmodel); %Apply.
%This apply will give the same answer as newX2 from the first call.
all(all(newX2.data==newX2_2.data))  

%PDS
opts                = caltransfer('options');
opts.pds.win        = 5; %Window.
[pdsmodel,x1,newX2] = caltransfer(spec1,spec2,'pds',opts);
newX2_2 = caltransfer(spec2,pdsmodel); %Apply.
newX2_2obj = pdsmodel.apply(spec2); %Apply via model object.
 
%DWPDS
opts.dwpds.win      = [5 3];
[dwpdsmodel,x1,newX2] = caltransfer(spec1,spec2,'dwpds',opts);
%Try apply with different include.
spec2.include{2} = isel(1:3);
newX2_2 = caltransfer(spec2,dwpdsmodel); %Apply.

%Test cell input.
load nir_data
spec1.include{1} = isel;%Reset include field.
spec2.include{1} = isel;%Reset include field.
[dwpdsmodel,x1,newX2] = caltransfer(spec1,{spec2 spec2 spec2},'dwpds',opts);
newX2_2 = caltransfer({spec2 spec2 spec2},dwpdsmodel);

%Test pp input.
load nir_data
opts                = caltransfer('options');
opts.pds.win        = 5; %Window.
opts.preprocessing  = {preprocess('default','autoscale') preprocess('default','normalize')};
[pdsmodel,x1,newX2] = caltransfer(spec1,spec2,'pds',opts);
newX2_2 = caltransfer(spec2,pdsmodel); %Apply.


pause
 
%-------------------------------------------------
%GLSW
%-------------------------------------------------
 
load nir_data
 
samps = distslct(spec1.data,6);
 
spec1.include{1} = samps;
spec2.include{1} = samps;

opts.glsw.a = .001;

[glsmodel,x1,newX2] = caltransfer(spec1, spec2,'glsw',opts);

newX2_2 = caltransfer(spec2,glsmodel,opts);

all(all(newX2.data==newX2_2.data))

%Try apply with different include.
spec2.include{1} = samps(1:3);
newX2_2 = caltransfer(spec2,glsmodel,opts);
 
pause


%-------------------------------------------------
%OSC
%-------------------------------------------------

load nir_data

[specsub,specnos] = stdsslct(spec1.data,5);

spec1.include{1} = specnos;
spec2.include{1} = specnos;
conc.include{1} = specnos;

opts.osc.ncomp = 2;
opts.osc.y = conc;
[oscmodel,newX1,newX2] = caltransfer(spec1, spec2,'osc',opts);
 
newX1_2 = caltransfer(spec1,oscmodel);
newX2_2 = caltransfer(spec2,oscmodel);

all(all(newX2.data==newX2_2.data))

 
%End of CALTRANSFERDEMO
%
%See also: ALIGNMAT, GLSW, OSCAPP, OSCCALC, STDGEN, STDIZE
 
echo off
