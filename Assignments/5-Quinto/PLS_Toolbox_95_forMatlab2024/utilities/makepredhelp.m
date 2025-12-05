function out = makepredhelp(in)
%MAKEPREDHELP Converts cell format prediction help into structure
% Input is a cell array containing two columns indicating the name of a
% predicted property and the model field to interrogate for that value.
%I/O: out = makepredhelp(in);

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = in;
if ~iscell(in) || size(in,2)~=3
  error('Unable to convert prediction help content');
end

out = struct('label',in(:,1)','field',in(:,2)','dimension',in(:,3)');
