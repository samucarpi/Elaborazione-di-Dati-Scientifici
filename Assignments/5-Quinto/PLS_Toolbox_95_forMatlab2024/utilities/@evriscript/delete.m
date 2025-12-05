function  obj = delete(obj,step)
%EVRISCRIPT/DELETE Remove step from chain.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<2 | isempty(step)
  error('Delete requires the step number to delete from the chain.')
end

theSteps = obj.steps;
theSteps(step) = [];
obj.steps = theSteps;
