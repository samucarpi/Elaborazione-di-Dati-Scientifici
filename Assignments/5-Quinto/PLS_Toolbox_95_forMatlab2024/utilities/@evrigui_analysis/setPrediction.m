function out = setPrediction(obj,parent,varargin)
%SETPREDICTION Loads prediction structure into Analysis GUI.
%I/O: .setPrediction(prediction)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

handles = guidata(parent.handle);
analysis('loadprediction',handles.analysis, [], handles, varargin{:})

out = true;
