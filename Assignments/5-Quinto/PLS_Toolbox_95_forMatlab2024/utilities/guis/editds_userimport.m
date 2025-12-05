function [data,name,source] = editds_userimport(varargin)
%MYREADR Example user-defined importer for editds
% This file is an example of a user=defined importer. To create a
% user-defined import method, copy this file with a unique m-file name and
% edit the code to read the desired file. The method may be added to the
% import from list by editing the editds_importmethods list (see the
% editds_importmethods file)
%
%I/O: [data,name,source] = editds_userimport(varargin)

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

name = '';
source = '';

%==========================================
% User-defined import code goes here. The variable "data" is expected to
% be a standard matlab array, a DataSet object, or empty at the end of
% this code. If empty, no importing will be done.
% The optional variable (name) can contain the filename read.
% The optional variable (source), if set to non-empty, indicates that the
% read file should be considered "not saved" if loaded into the dataset
% Editor.

%this code will ask the user to locate a file:
[file,pathname] = evriuigetfile({'*.zzz','Description of ZZZ file (*.zzz)';'*.*','All Files (*.*)'});
if file == 0
  data = [];  %exit without data
else
  filename = [pathname,file];
  %read file here...

  %(instead of reading a file, this example will just create a 10x5 matrix)
  data = rand(10,5);

end

% end of user-defined code
%==========================================
