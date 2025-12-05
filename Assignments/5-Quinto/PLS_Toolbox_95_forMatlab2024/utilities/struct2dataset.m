function [ds_out,msg] = struct2dataset(ds_struct)
%STRUCT2DATASET Convert a structure into a dataset object.
% Attempts to convert fields of a structure (in) into corresponding fields
% in a DataSet object (out). Field names and contents should be the same as
% those in a DataSet object. Some fields (such as history and moddate)
% cannot be copied over and will be ignored.
%
% One critical difference between standard DataSet object field formats and
% what is expected in the input structure is that the fields: label, class,
% axisscale, title, and include are cells with three modes (instead of the
% usual two) where the indices representing:
%    {mode, val_or_name, set}
% The first and thrid dimensions are the same as with the standard indices
% for these fields, but the second is the value "1" for the actual value
% for the field and "2" for the name (usually stored in the DataSet object
% in a field named "____name", such as "classname")
%
% INPUT:
%    in = Structure containing one or more fields appropriate for a DataSet
%         object. See the DataSet object documentation for information and
%         format of these fields
% OUTPUTS:
%   out = DataSet object created from the contents of the input structure.
%   msg = Text of any error/warning messages discovered during the
%          conversion. Returned as empty if no errors were found.
%
% If only one output is requested, any discovered errors/warnings will be
% displayed on the screen.
%
%I/O: [ds_out,msg] = struct2dataset(ds_struct)
%
%See also: DATASET, EDITDS

%Copyright © Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Moved main function to @dataset because it became necessary after
%updating to classdef. Older objects were converted to struct upon
%loading.
[ds_out,msg] = dataset.struct2dataset(ds_struct);