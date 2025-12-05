echo on
%AREADRDEMO Demo of the AREADR function
 
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
% This demo will demonstrate how the AREADR function can be used
% to import data from a formated ascii text file. It is used to
% skip header information and just read the data table.
%
% There is a data file in the \dems folder called 'areadrdemtext.txt'
% that has the following ascii contents:
% 		
% 		example text file used by AREADRDEMO
% 		this is header line 2
% 		this is header line 3
% 		so, in the example the number of header lines to skip is 4
%              1     2     3     4     5     6     7
%             11    12    13    14    15    16    17
%             21    22    23    24    25    26    27
%             31    32    33    34    35    36    37
%
% You can edit this file to examine it's contents. (Don't modify it
% or the demo won't work.)
 
pause
%-------------------------------------------------
% AREADR can be called to read this file in 4 different ways
% depending on what the user knows about the structure of the
% ascii files. These calls are:
%
% 1) skip the first 4 lines and read a table of 4 rows
% 	out = areadr('dems\areadrdemtext.txt',4,4,1);
%
% 2) skip the first 4 lines and read a table of 7 columns
% 	out = areadr('dems\areadrdemtext.txt',4,7,2);
%
% 3) find the string "skip is 4" and read the following table of 4 rows
% 	out = areadr('dems\areadrdemtext.txt','skip is 4',4,1);
%
% 4) find the string "skip is 4" and read the following table of 7 columns
% 	out = areadr('dems\areadrdemtext.txt','skip is 4',7,2);
%
% Two of these options will be shown.
 
pause
%-------------------------------------------------
% 1) skip the first 4 lines and read a table of 4 rows
out = areadr(['dems' filesep 'areadrdemtext.txt'],4,4,1)
 
pause
%-------------------------------------------------
% 4) find the string "skip is 4" and read the following table of 7 columns
out = areadr(['dems' filesep 'areadrdemtext.txt'],'skip is 4',7,2)
 
%End of AREADRDEMO
 
echo off
