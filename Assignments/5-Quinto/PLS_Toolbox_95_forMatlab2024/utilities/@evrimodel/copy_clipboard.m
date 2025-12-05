function varargout = copy_clipboard(obj)
%EVRIMODEL/COPY_CLIPBOARD Copy model information to system clipboard.
%
%I/O: copy_clipboard(obj)

% Copyright © Eigenvector Research, Inc. 2013
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

myinfo  = modlrder(obj)';
myinfo = cell2str(myinfo,char(9),1)';
myinfo = [myinfo(:)]';
clipboard('copy',myinfo);
