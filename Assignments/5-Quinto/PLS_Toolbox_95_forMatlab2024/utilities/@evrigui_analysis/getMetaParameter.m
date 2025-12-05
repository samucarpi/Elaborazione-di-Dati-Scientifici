function out = getMetaParameter(obj,parent,varargin)
%GETMETAPARAMETER Returns the currently selected Analysis method.
%I/O: .getMetaParameter(paramName)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

handles = guidata(parent.handle);
myparam = varargin{1};
out = [];

switch myparam
  case 'npts'
    canal = getappdata(handles.analysis,'curanal');
    if strcmp(canal,'lwr')
      out = str2num(get(handles.lwr_npts,'string'));
    end
end
