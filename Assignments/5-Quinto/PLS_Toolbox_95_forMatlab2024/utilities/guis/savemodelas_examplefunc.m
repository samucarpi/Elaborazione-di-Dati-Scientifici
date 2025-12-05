function savemodelas_examplefunc(modl,filename)
%SAVEMODELAS_EXAMPLEFUNC Simple example of custom "save as" function.
% Inputs can only be model and filename. This is a simple example of
% printing the model scores to a .txt file. To integrate this function into
% the save as dialob box, add it to the SAVEMODELAS_CUSTOMLIST list.
%
%I/O: SAVEMODELAS_EXAMPLEFUN(model,'c:\temp\myModelScores.txt')
% 
%See Also: SAVEMODELAS, SAVEMODELAS_CUSTOMLIST

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%RSK 09/13/06

%Print model scores as a simple tab delimited txt file.
dlmwrite(filename,modl.loads{1},'\t');
