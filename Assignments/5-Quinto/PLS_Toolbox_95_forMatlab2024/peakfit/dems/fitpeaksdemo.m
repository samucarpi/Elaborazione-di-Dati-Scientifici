echo on
%FITPEAKSDEMO Demo of the FITPEAKS function
 
echo off
%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
% This demo calls the function TESTFITPEAKS.
% Enter an integer 1 to 9 for input (test) to run
% a desired demo.
% Enter any other number (e.g. 0) to exit.
 
echo off
 
test = 1;
while any(test==1:10)
  help testfitpeaks
  test = input('Enter 0 to exit or 1 to 10 for a demo. ');
  while isempty(test)|~isa(test,'double')
    disp('Please enter an integer 0 to 10.')
    test = input('Enter 0 to exit or 1 to 10 for a demo. ');
  end
  if ~isempty(test) & any(test==1:10)
    [peakdef,fval,exitflag,output] = testfitpeaks(test);
  end
end
 
%Edit the TESTFITPEAKS function to see how to call
%PEAKSTRUCT, FITPEAKS, and PEAKFUNCTION.
 
%End of FITPEAKSDEMO
%
%See also: PEAKSTRUCT, FITPEAKS, and PEAKFUNCTION
 
echo off
