function out = extensions_release(name)
%EXTENSIONS_RELEASE Release number for extension.
%
% Functions using an extension should check and save (as preference in
% options struct) the current version. If a new version of extension needs
% to be indicated, it should be done here. Using functions can then check
% saved/current version versus version indicated by extensions_release and
% take appropriate action (if needed) if newer version is available.
%
% HJYREADR is a good example of when a new ActiveX component may need to be
% installed. Incrementing here will cause a new installation.

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

switch name
  case 'hjy'
    out = 2.0;
  case 'javatools'
    out = 1.0;
end
