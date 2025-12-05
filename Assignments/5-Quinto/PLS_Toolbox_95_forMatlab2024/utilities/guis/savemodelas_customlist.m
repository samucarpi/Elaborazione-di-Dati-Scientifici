function list = savemodelas_customlist()
%SAVEMODELAS_CUSTOMLIST List of user-defined "save as" methods for saving models.
% The list is an n x 3 cell array of stings containing a description, a
% custom "save as" function name, and a file extension.
%
% The custom save as function must take only 2 inputs, model and filename.
% The model is a standard model structure and the filename should contain a
% full path. To run the example, uncomment the last line, save this file,
% and try saving a model via "save as". You will see a custom function for
% saving as a text file.
%
%I/O: SAVEMODELAS_CUSTOMLIST
%
%See Also: SAVEMODELAS, SAVEMODELAS_EXAMPLEFUNC

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%RSK 09/13/06

list = '';

%EXAMPLE:
%        Description     Exporter M-file name       File Extension
%list = {'Text File (TXT)'   'savemodelas_examplefunc' '.txt'};
