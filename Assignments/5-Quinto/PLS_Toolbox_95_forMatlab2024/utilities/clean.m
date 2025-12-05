%CLEAN clears and closes everything.
%
%I/O: clean
%
%See also: KEEP

%Copyright Eigenvector Research 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

close all force;
drawnow
%Shut down derby before clearing appdata.
cdb = evricachedb;
if ~isempty(cdb)
  cdb.clear;
end

%remove appdata on base object
doNotDelete = {'Graph2dSeriesListeners'};
base_appdata = getappdata(0);
base_names = fieldnames(base_appdata);
matlab_fieldsidx = xor(~cellfun('isempty',strfind(base_names,'MATLAB')),~cellfun('isempty',strfind(base_names,'MLSERVER')));
matlab_fields = base_names(matlab_fieldsidx);
for j = setdiff(fieldnames(getappdata(0)),[doNotDelete; matlab_fields])'; 
  rmappdata(0,j{:});
end
clear all force;
clear global;
clear functions;
clear classes;
clc;
