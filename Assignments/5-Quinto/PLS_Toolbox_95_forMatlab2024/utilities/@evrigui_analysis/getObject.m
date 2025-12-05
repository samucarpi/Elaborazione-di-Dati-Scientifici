function out = getObject(obj,parent,varargin)
%GETOBJECT Returns specified object from GUI.
% With optional second input (1), the shared data object is returned.
%I/O: .getObject('objectname'
%I/O: .getObject('objectname',1)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 4, nargin))

if nargin>3 & varargin{2}
  field = 'getobj';
else
  field = 'getobjdata';
end
handles = guidata(parent.handle);
out = analysis(field,varargin{1}, handles);
