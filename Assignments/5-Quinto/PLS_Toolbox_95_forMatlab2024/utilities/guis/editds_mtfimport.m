function [data,name,source] = editds_mtfimport(varargin)
%EDITDS_MTFIMPORT DSO Import function for EditDS
% Importer for interfacing mtfreadr with editds
%
%I/O: [data,name,source] = editds_mtfimport(varargin)

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

data = mtfreadr(varargin{:});

% end of user-defined code
%==========================================

