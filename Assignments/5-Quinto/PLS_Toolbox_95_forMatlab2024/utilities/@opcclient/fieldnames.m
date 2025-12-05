function out = fieldnames(obj)
%OPCCLIENT/FIELDNAMES Overload for OPCCLIENT object

%Copyright Eigenvector Research, Inc. 2015
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = {'version' 'getdefaultgroup' 'connect' 'disconnect' ...
  'read' 'write' 'display' 'disp'...
  'id' 'groupname' 'jclient' };
