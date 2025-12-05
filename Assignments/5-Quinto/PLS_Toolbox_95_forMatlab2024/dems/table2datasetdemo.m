echo on
% TABLE2DATASETDEMO Demo of the TABLE2DATASET function
 
echo off
%Copyright Eigenvector Research, Inc. 2018
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Create table data based on Matlab documentation.
 
load patients
patients_table = table(LastName,categorical(Gender),Age,Height,Weight,Smoker,Systolic,Diastolic);
 
%Name the categorical variable.
patients_table.Properties.VariableNames{2} = 'Gender';
 
patients_table
 
% Note there are labels for rows and columns as well as a categorical and
% logical variables.
 
pause
%-------------------------------------------------
% Use TABLE2DATASET to convert the table to a DSO.
 
patients_dso = table2dataset(patients_table);
 
%The labels and data have been parsed:
 
patients_dso.table
 
pause
%-------------------------------------------------
% Check for a class based on Gender.
 
patients_dso.classid{1,1}'
 
% Note that logical table columns will be put into the .data field of the
% dataset object. These columns can be moved to a class as needed.
%
%End of TABLE2DATASETDEMO
 
echo off

