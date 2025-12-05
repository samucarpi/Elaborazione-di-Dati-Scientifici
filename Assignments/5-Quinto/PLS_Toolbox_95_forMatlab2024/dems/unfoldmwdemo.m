echo on
% UNFOLDMWDEMO Demo of the UNFOLDMW function
 
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
% The UNFOLDMW function is used to unfold multi-way arrays to 2-way
% arrays. These are used in the alternating least squares of PARAFAC
% and in MPCA. UNFOLDMW works on multi-way arrays and on Dataset
% Objects. 
 
% Lets start by creating a simple 3-way array where the entries
% are integers
 
mwa = reshape(1:24,4,3,2)
 
pause
%-------------------------------------------------
% We can now unold the array. We'll start by unfolding along the third mode
% which has dimension 2. This will create an array that is 2 by 12 (3*4).
% All the entries in each of the slabs will be strung out on a row of the
% resulting matrix:
%
mwauf3 = unfoldmw(mwa,3)
 
pause
%-------------------------------------------------
% The array could also be unfolded along each of the other two dimensions:
%
mwauf2 = unfoldmw(mwa,2)
 
mwauf1 = unfoldmw(mwa,1)
 
pause
%-------------------------------------------------
% Now lets create a dataset object so that we can see how UNFOLDMW works
% with them. We'll add some include fields to demonstrate how the includes
% propagate when the unfolding occurs.
%
mwa = dataset(mwa);
mwa.includ{1} = [1 2 4];
mwa.includ{2} = [1 3];
mwa.labelname{1} = 'Time';
mwa.labelname{2} = 'Position';
mwa.labelname{3} = 'Batch';
mwa.label{1} = ['T1';'T2';'T3';'T4'];
mwa.label{2} = ['P1';'P2';'P3'];
mwa.label{3} = ['Batch 1';'Batch 2']
 
pause
%-------------------------------------------------
% Now we can unfold this along the third mode:
 
mwauf3 = unfoldmw(mwa,3)
 
pause
%-------------------------------------------------
% Note how the unfolded Dataset now says "Time and Postion" in the 
% Mode 2 label field. These two modes have been convolved. A set of
% labels has been created for this mode that indicates this:
 
mwauf3.label{2}
 
pause
%-------------------------------------------------
% Finally, we can look at the include field to see which of the 
% convolved variables are included:
 
mwauf3.includ{2}
 
% In our original dataset, variable 3 in the first mode had not been
% included, and variable 2 in the second mode was not included.
 
echo off
  
   
