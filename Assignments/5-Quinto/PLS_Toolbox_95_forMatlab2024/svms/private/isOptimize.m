function [result] = isOptimize(args)
%ISOPTIMIZE Does args have any SVM parameter with length>1
% isOptimize checks the input options to see if they indicate a scan over
% SVM parameters to find an optimal set is desired. It determines this by
% checking if one of range-supporting svm parameters' value has a range instead of a
% single value
%
% %I/O: out = isOptimize(options); Is optimization search required?
%
%See also: GETSUPPORTEDPARAMETERS, HASPARAMETERRANGES

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

result = false;

% Check for parameter ranges
checkpranges = hasParameterRanges(args);

% Is optimize if has param ranges
result = checkpranges;

function result = hasParameterRanges(args)
%HASPARAMETERRANGES Does any supported parameter have length>1?
% hasParameterRanges checks if any input struct field which is permitted to 
% have a range value (length > 1), does so.
%
% %I/O: out = hasParameterRanges(in); Do any supported options have range values?
%
%See also: GETSUPPORTEDPARAMETERS

result = false;
% get supported parameters, then check if any of these have length >1.
supParams = getSupportedParameters(args);
supFieldNames = fieldnames(supParams);
for ikey=1:length(supFieldNames)
  key = supFieldNames{ikey};
  if (isnumeric(supParams.(key)) & (numel(supParams.(key)) > 1))
    result = true;  % this parameter is specified as a range of values,
    break;          % so this is an optimize mode
  end
  % So this is just a normal cv run for specified parameters (no ranges)
end
