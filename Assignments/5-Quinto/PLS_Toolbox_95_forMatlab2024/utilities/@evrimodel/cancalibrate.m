function out = cancalibrate(obj)
%EVRIMODEL/CANCALIBRATE Indicates if model has a calibrator script and can be calibrated.
%I/O: out = obj.cancalibrate

%Copyright (c) Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


if ~iscalibrated(obj) & ~isempty(obj.calibrate);
  %calibrate method exists and is not calibrated yet
  out = true;
else
  out = false;
end
