function out = create(obj,parent,varargin)
%CREATE Creates a new instance of the Analysis GUI
%I/O: .create
%I/O: .create('methodname')
%I/O: .create('-reuse')

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isvalid(parent)
  error('Cannot create new instance when already associated with one.')
end

%create new instance of Browse
out = browse(varargin{:});
