function cvmaxPC = getMaxCVallowedPCs(x, cvi)
%getMaxCVallowedPCs Get the maximum allowed factors based on crossval subset
% getMaxCVallowedPCs is a utility funciton that will return the maximum
% allowed factors based on crossval method (cvi) and the size of the
% included samples in the data (x).
% NOTE: This assumes x is full-rank. The maximum allowed PCs could be
% smaller if the dataset is not full-rank.
%
%  INPUT:
%        x  = DataSet Object or matrix),
%      cvi  = cross-validation specification, example = {'vet', 10, 1}
%
%  OUTPUT:
%   cvmaxPC = maximum allowed factors
%
%I/O:cvmaxPC = getMaxCVallowedPCs(x,cvi);

%Copyright Eigenvector Research, Inc. 2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isdataset(x)
  nsamp = length(x.include{1});
elseif isnumeric(x)
  nsamp = size(x,1);
else
  error('Input x must be a dataset or matrix')
end

cvienc = encodemethod(nsamp, cvi{1}, cvi{2},1);
Nhist = hist(cvienc, cvi{2});
cvmaxPC = nsamp-max(Nhist);