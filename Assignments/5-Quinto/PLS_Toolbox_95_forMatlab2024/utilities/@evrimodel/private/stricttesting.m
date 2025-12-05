function out = stricttesting
%STRICTTESTING Returns cached value of stricttesting option for evrimodel
% This method is used to make reference to this option much faster.

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

 
persistent val
if isempty(val);
  val = getfield(evrimodel('options'),'stricttesting');
end
out = val;
