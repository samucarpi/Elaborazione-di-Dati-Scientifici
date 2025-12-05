function out = setCrossvalidation(obj,parent,varargin)
%SETCROSSVALIDATION Load Analysis Cross-Validation settings.
%I/O: .setCrossvalidation(cv,lv,split,iter,cvi)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 7, nargin))

defaults = {'none' 20 5 1 []};%cv,lv,split,iter,cvi
[varargin{end+1:5}] = deal(defaults{length(varargin)+1:end});

handles = guidata(parent.handle);
cvigui  = getappdata(handles.analysis,'crossvalgui');
crossvalgui('forcesettings',cvigui,varargin{:})
clearModel(obj,parent);  %clear out model (required for crossval change)
analysis('updatestatusimage',handles);  %update status boxes
out = true;
