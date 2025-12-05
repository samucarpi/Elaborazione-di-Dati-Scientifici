function out = validmethods(obj,varargin)
%EVRIGUI_fcn/validmethods

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

persistent list

if ~iscell(list)
  list = setdiff([{'close'}; methods(obj)],{class(obj) [class(obj) 'version'] 'expectedtag' 'disp' 'display' 'subsref' 'encodexml'});
end

out = list;
