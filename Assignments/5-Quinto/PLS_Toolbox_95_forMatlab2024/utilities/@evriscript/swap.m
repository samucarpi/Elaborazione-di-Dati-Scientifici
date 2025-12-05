function       obj = swap(obj,index1,index2)
%EVRISCRIPT/SWAP Swap positions of two steps in a evriscript.
%I/O: obj = swap(obj,index1,index2)

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<3
  error('Swap requires two inputs indicating the steps of the chain to swap')
end

theSteps = obj.steps;
isIndexValidForCellArray(index1, theSteps);
isIndexValidForCellArray(index2, theSteps);
theSteps([index1 index2]) = theSteps([index2 index1]);
obj.steps = theSteps;

