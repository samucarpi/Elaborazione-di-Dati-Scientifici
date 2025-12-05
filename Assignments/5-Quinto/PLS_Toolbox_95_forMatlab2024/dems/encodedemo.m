echo on
% ENCODEDEMO Demo of the ENCODE function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The ENCODE function is used to create executable Matlab code to reproduce
% a variable's content. It is particularly useful with simple structure
% such as preprocessing structures. This demo shows its use to produce code
% which reproduces a preprocessing structure. This code could then be
% inserted into an m-file.
 
pause
%-------------------------------------------------
% First, we'll create a preprocessing structure for mean-centering:
 
p = preprocess('default','meancenter')
 
pause
%-------------------------------------------------
% now, we use encode to create code to reproduce "p" from code:
 
encode(p)
 
% end of demo
 
echo off
  
   
