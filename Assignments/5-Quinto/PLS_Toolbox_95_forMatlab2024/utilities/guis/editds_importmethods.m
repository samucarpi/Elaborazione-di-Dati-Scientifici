function list = editds_importmethods
%EDITDS_IMPORTMETHODS List of user-defined import methods for DataSet Editor
% This is a user-modifiable file which contains a list of user-defined
% methods for use by the DataSet Editor importer. The output of this
% function is a list consisting of two columns describing user-defined
% import methods. Column 1 contains the description of the import method as
% it should appear in the menu and import from dialog. Column 2 contains
% the name of the importer. Column 3 contains a cell of the filetypes for
% which this importer should be used as the default reader. The import
% method must follow the format shown in editds_userimport.m.
%
%I/O: list = editds_importmethods

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%EXAMPLE:
%        Description     Importer M-file name   Cell of filetypes  Valid filetypes
% list = {'ZZZ File'      'editds_userimport'    {'zzz'}           {'zzz' 'yyy'}}
%
% The cell of filetypes should list which file types this importer should
% be used as the DEFAULT importer for. Valid filetypes should be a cell of
% file types this importer is CAPEABLE of reading (even if it isn't the
% default). If an importer has no valid filetypes, it will not appear in
% the load dialogs and only in the import dialogs.

list = {};

