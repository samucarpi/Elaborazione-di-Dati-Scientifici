function list = importmodel_customlist()
%IMPORTMODEL_CUSTOMLIST List of user-defined "import" methods for models.
% The list is an n x 3 cell array of stings containing a description, a
% custom "import" function name, and a file extension.
%
% The custom import function must take 1 input, a filename which should be
% expected to contain a full path, and return one output, a standard model
% structure. To run the example, uncomment the last line, save this file,
% and try importing a model via "import". You will see a custom function for
% importing a text file.
%
%I/O: IMPORTMODEL_CUSTOMLIST
%
%See Also: ANALYSIS

%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 1/4/07

%EXAMPLE:
%        Description     Exporter M-file name       File Extension
%list = {'Text File (*.txt)'   'save'    '.txt'}

list = {};
