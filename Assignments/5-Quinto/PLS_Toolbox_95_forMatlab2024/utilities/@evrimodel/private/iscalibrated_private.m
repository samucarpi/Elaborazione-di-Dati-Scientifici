function out = iscalibrated(obj)
%EVRIMODEL/ISCALIBRATED Indicates if model has been calibrated or is empty.
%I/O: out = obj.iscalibrated

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isfield(obj.content,'datasource') & ~isempty(obj.content.datasource) & isempty(obj.content.datasource{1}.size)
  %calibrate method exists and datasource is empty, not calibrated yet
  out = false;
else
  %best we can assume is that we're calibrated
  out = true;
end
