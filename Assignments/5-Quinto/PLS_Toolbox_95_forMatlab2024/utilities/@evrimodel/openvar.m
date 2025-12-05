function openvar(varargin)
%EVRIMODEL/OPENVAR Overload for EVRIModel object.
% Overload to work with workspace double-click-to-edit

%Copyright (c) Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

try
  msg = edit(varargin{2});
  if ~isempty(msg)
    erdlgpls(msg);
  end
catch
  le = lasterror;
  erdlgpls(le.message);
end

