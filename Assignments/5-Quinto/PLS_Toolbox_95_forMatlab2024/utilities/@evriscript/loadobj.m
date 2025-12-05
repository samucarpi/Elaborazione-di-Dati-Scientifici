function obj = loadobj(obj)
%EVRISCRIPT/LOADOBJ Load an EVRISCRIPT object from a file.
% Called whenever an EVRISCRIPT object is loaded from a file. Handles
% upgrading of objects.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

opts = evriscript('options');
if opts.keywordonly
  obj = struct('execute','Loading EVRISCRIPT from a file is currently disabled ("keywordonly" mode enabled)');
  return
end
