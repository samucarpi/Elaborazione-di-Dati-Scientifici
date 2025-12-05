echo on
%ANGLEMAPPERDEMO Demo of the ANGLEMAPPER function

echo off
%Copyright Eigenvector Research, Inc. 2020
%Licensee shall not re-compile, translate or convert "M-files" 
% distributed by Eigenvector Research Inc. for use with any software other
% than MATLAB®, without written permission from Eigenvector Research, Inc.

echo on

%To run the demo hit a "return" after each pause
pause
 
%  ANGLEMAPPER can be used with two-way matrices (e.g., time-series) or
%  multivarite images from imaging spectroscopy. Samples are classed as
%  the target with the smallest angle between the sample and the target.
%  Different algorithms can be selected using (options.algorith). The
%  default is a simple angle measure (a.k.a., Spectral Angle Mapper).
 
%  For a two-way MxN matrix and a set of K target signals or spectra (targ),
%  ANGLEMAPPER calculates an angle between each target and each row of the
%  input (x). The output (x) is a MxN DataSet object with the last class
%  for Mode 1 (x.class{1,end}) corresponding to the target with the
%  smallest angle.
 
%  For an example with two-way data, the PLSdata will be used.
 
pause
 
load('plsdata','xblock1')
targ  = xblock1([100 73 278],:);
targ.label{1} = char('Sample 100','Sample 73','Sample 278');
targ.labelname{1} = 'Sample Type';
 
% xblock1 is a 300x20 time series of 20 measured temperatures.
% For this specific example, samples 100, 73 and 278 are selected as
% candidate target signals. Other targets could be used.
 
% ANGLEMAPPER will be called using the default options using the
% spectral angle mapper (SAM) algorithm.
 
pause
 
[xblock1,angl11] = anglemapper(xblock1,targ);
 
figure('Name','X Block 1 w/ SAM Classes')  % plot the results
plotgui(xblock1,'plotby',2,'axismenuvalues',{[0] [6 8]}, ...
  'viewclasses',1,'viewclassset',1)
legend, commandwindow
 
% The output (xblock1) is the same as the input (xblock1) except the
% output now has a new set of classes added to it by ANGLEMAPPER.
 
% Next, the default algorithm will be changed to spectral correlation
% mapper (SCM).
 
% To obtain the options structure, ANGLEMAPPER is called with the
% input 'options':
 
pause
 
opts  = anglemapper('options')   %opts is an options stucture
opts.algorithm   = 'scm';
[xblock1,angl12] = anglemapper(xblock1,targ,opts);
 
figure('Name','X Block 1 w/ SCM Classes')  % plot the results
plotgui(xblock1,'plotby',2,'axismenuvalues',{[0] [6 8]}, ...
  'viewclasses',1,'viewclassset',2)
legend, commandwindow
 
% The output (xblock1) now has a new set of classes added to it by 
% ANGLEMAPPER using the SCM algorithm.
 
% It is fun to now perform PCA on the new (xblock1) and see where the
% classes lie in scores space.
 
echo off
if evriio('mia')
  echo on
  
pause
 
%  For an MxN DataSet object (x) of type "image" with a total of M pixels
%  and a set of K target spectra (targ), ANGLEMAPPER calculates an angle
%  between each target and each pixel (row) the input (x). The output (x)
%  is a MxN image DataSet object with the last class for Mode 1
%  (x.class{1,end}) corresponding to the target with the smallest angle.
 
%  Note however that if no threshold is used on the magnitude of the angle,
%  all samples will be place in some class. This is probably ok if a full
%  representative set of end-members is avaiable for the target set, but
%  it is more typical that only a few targets are available. Setting a
%  threshold on the angle allows for some samples can belong to no class.
%  (see options.threshold). This is shown in the following examples.
 
%  A 128x128 EDS image of six types of wires in rows made of six different 
%  alloys in epoxy. The rows correspond to the following.                                                                      
%  Top Row 1 (100% Ni)
%  Row 2 (36% Ni, 64% Fe)
%  Row 3 (70% Cu, 30% Zn)                      
%  Row 4 (16% Cr, 84% Fe)
%  Row 5 (13% Mn, 4% Ni, 83% Cu) and                               
%  Bottom Row 6 (100% Cu).                                                            
 
load StandardWireTest
 
pause
 
%  Targets will be selected from known locations in the image. One target
%  will be associated with Ni and a second from Cu.
 
targ = data([1947 3184],:);
targ.label{1} = char('Ni','Cu');
 
%  In the first example with images, ANGLEMAPER be called with the default
%  algorithm SAM.
%  In the second example, the WTFAC agorithm will be used and a threshold
%  will be set at an angle of 40 degrees. This means that pixels with
%  an angle > 40 degress for all targets will not have a class.
 
%  A PCA model of the image will be used for visualization.
 
pause
 
[data,angl21] = anglemapper(data,targ);
pcamodel      = pca(mncn(data),1,struct('plots','none','display','off'));
figure('Name','Wires Image w/ Classes from SAM - No Threshold')
plotgui(plotscores(pcamodel),'viewclasses',1,'viewclassset',1)
legend, commandwindow
 
opts          = anglemapper('options');
opts.algorithm  = 'sam';
opts.threshold  = 40;
[data,angl22] = anglemapper(data,targ,opts);
pcamodel      = pca(mncn(data),1,struct('plots','none','display','off'));
figure('Name','Wires Image w/ Classes from SAM - with Threshold')
plotgui(plotscores(pcamodel),'viewclasses',1,'viewclassset',2)
legend, commandwindow
  
opts          = anglemapper('options');
opts.algorithm  = 'wtfac';
opts.threshold  = 40;
[data,angl23] = anglemapper(data,targ,opts);
pcamodel      = pca(mncn(data),1,struct('plots','none','display','off'));
figure('Name','Wires Image w/ Classes from WTFA - with Threshold')
plotgui(plotscores(pcamodel),'viewclasses',1,'viewclassset',3)
legend, commandwindow
 
% The two plots show a clear differences between SAM and WTFC. In the SAM
% plot where the threshold was not used, every pixel got classed as either
% Ni or Cu. It's nice to see that the top row and bottom row were correctly
% classified as Ni and Cu.
% Note that PlotGUI was called with 'viewclassset' to view the most
% recently class set added by ANGLEMAPPER. 
 
% The WTFC image used a threshold and most of the pixels were not
% classified. Tthe top row and bottom row were correctly classified as 
% Ni and Cu. Row 3 (70% Cu, 30% Zn) and Row 5 (13% Mn, 4% Ni, 83% Cu)
% were classified as Cu.
 
end
 
%End of ANGLEMAPERDEMO
%
%See also: BUILDIMAGE, EVOLVFA, EFA_DEMO, EWFA, PCA, WTFA, EWFA_IMG, WTFA_IMG
 
echo off
