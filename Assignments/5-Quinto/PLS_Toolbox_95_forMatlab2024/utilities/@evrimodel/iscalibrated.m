function out = iscalibrated(obj)
%EVRIMODEL/ISCALIBRATED Indicates if model has been calibrated or is empty.
%I/O: out = obj.iscalibrated

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = iscalibrated_private(obj);
