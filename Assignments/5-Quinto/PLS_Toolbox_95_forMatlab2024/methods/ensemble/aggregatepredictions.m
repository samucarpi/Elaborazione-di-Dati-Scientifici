function pred = aggregatepredictions(preds,method)
%AGGREGATEPREDICTIONS Aggregate predictions for ensemble modeltype.
% Aggregate predictions for the ensemble modeltype. Currently supported
% methods of aggregation are 'mean', 'median', and 'jackknife'.
%
% INPUTS:
%        preds = cell array of predictions from each model,
%       method = method of aggregation. 'mean', 'median', and 'jackknife'
%                are supported.
% 
%  OUTPUT:
%         pred = column vector of aggregated predictions 
%
%I/O: pred = aggregatepredictions(preds,method)
%
%See also: ENSEMBLE CHECKTHEMODELS COMPUTEJACKKNIFE

% Copyright © Eigenvector Research, Inc. 2024
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

switch method
  case 'mean'
    pred = mean(cat(2,preds{:}),2);
  case 'median'
    pred = median(cat(2,preds{:}),2);
  case 'jackknife'
    pred = computejackknife(preds);
  otherwise
    error(['Unsupported aggregation: ' method '. Supported aggregations: ''mean'', ''median'', ''jackknife''.'])
end
end