echo on
% TEXTREADRDEMO Demo of the TEXTREADR function
 
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
% The TEXTREADR function is used to read data matrices exported from
% an Excel spreadsheet into a Dataset Object, which may then be
% used with other PLS_Toolbox functions and interfaces. TEXTREADR
% imports the labels for samples and variables.
pause
%-------------------------------------------------
% To use TEXTREADR to import data, the original data table must be stored in
% a spreadsheet where the first column (starting from the second row)
% contains the sample labels, the first row (starting from the second
% column) contains the variable labels, and the data occuppies the
% space between. The first cell can contain some descriptive
% information about the data set. This spreadsheet should then be
% saved as a tab (default), comma, or space delimited text file.
pause
%-------------------------------------------------
% The contents of a sample example data file, textreadrdata.txt, follows:
%
%Test file for TEXTREADR	Temperature	Pressure	Flow
%Yesterday	5	6	9
%Today	3	4	8
%Tomorrow	2	6	10
%
% The file alignment may not look correct because tabs are used to
% separate the fields.
pause
%-------------------------------------------------
% This text file may be read into a Dataset object as follows:
 
mydata = textreadr('textreadrdata.txt')
 
pause
%-------------------------------------------------
% If you perform this at the command line, it will create a Dataset object
% with the contents of the file textreadrdata.txt. Note that TEXTREADR will
% turn empty cells into NaNs, which other PLS_Toolbox functions interpret
% as missing data. 
%
% TEXTREADR may also be called without inputs, which will bring up a
% dialog box that allows the user to browse for files. Other file
% delimiters can be specified as a second input.
 
echo off
