function pred = computejackknife(preds)
%COMPUTEJACKKNIFE Aggregate predictions by jackknifing.
% Aggregate predictions for the ensemble modeltype by jackknifing.
% Jackknifing consists of taking the M (nsamples) by N (nmodels) prediction
% matrix and computing a new prediction matrix. It does this by looping
% over the columns in N, and column j becomes the median of the rest of the
% predictions that are not in column j. Once this new matrix is computed,
% the final M by 1 prediction matrix is a median of the previously computed
% prediction matrix.
%
% INPUTS:
%        preds = cell array of predictions from each model.
% 
%  OUTPUT:
%         pred = column vector of aggregated predictions 
%
%I/O: pred = computejackknife(preds)
%
%See also: ENSEMBLE CHECKTHEMODELS AGGREGATEPREDICTIONS

% Copyright © Eigenvector Research, Inc. 2024
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

% calculate jackknife predictions for every model
npreds = length(preds);
jackknifepreds = cell(1,npreds);
for i=1:npreds
  thesepreds = preds(setdiff(1:npreds,i));
  jackknifepreds{i} = median(cat(2,thesepreds{:}),2);
end
pred = median(cat(2,jackknifepreds{:}),2);
end

