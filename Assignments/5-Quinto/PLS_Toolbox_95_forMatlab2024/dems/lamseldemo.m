echo on
% LAMSELDEMO Demo of the LAMSEL function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%bmw
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The LAMSEL function is used to "look-up" the indicies which correspond to
% a given wavelength range in a wavelength axis vector (lamda). For
% example, this function can be used to refer to wavelengths instead of
% indicies when extracting data from a matrix.
 
pause
%-------------------------------------------------
% Start by obtaining a vector which represents the measured wavelengths
 
lamda = [400:5:2000];
 
pause
%-------------------------------------------------
% The LAMSEL function can now be used to identify, for example, what
% indicies are included in the the wavelength ranges of 840 to 860 and 1380
% to 1400.
 
inds  = lamsel(lamda,[840 860; 1380 1400]);
 
pause
%-------------------------------------------------
% We can now look at those channels as indicies, which could be used
% to extract data from another matrix.
 
inds
 
pause
%-------------------------------------------------
% For example, those indicies can be used to extract the selected
% wavelenths from lamda:
 
lamda(inds)
 
% End of LAMSELDEMO
 
echo off
