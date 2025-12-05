function isIndexValidForCellArray(index, cellArray)
%ISINDEXVALIDFORCELLARRAY throws error if index is not in [1:length(cellArray)]

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~isnumeric(index)
  error('Insertion index must be greater than numeric');
end
if index<1
  error('Insertion index (%i) must be greater than 0.', index);
elseif index>length(cellArray)
  error('Insertion index (%i) must be less than or equal to the length of chain (%i).', ...
    index, length(cellArray));
end
