function [predictions] = xgbPredict(x, y, booster, args)
%XGBPREDICT: Apply XGBoost model to supplied test data.
%
%  This function applies a xgboost model to supplied test data in either
%  a classification or regression mode.
%  Returns predictions of the input samples' class membership (classification)
%  or y value predictions (regression)
%
%  INPUTS:
%  x: 	values. m by n array, m samples, n variables
%  y: 	labels. vector of length m indicating sample class (XGB
%     classification) or y value (XGB regression).
%  args:	Arguments. LIBXGB arguments in a struct form.
%
%  OUTPUT:
%  predictions of the input samples' class membership (classification)
%  or y value predictions (regression)
%
% %I/O: out = xgbPredict(x, y, model, options); Use x and model for prediction

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% showwaitbar = strcmpi(args.waitbar,'on');

% test.setLabel(y);   % y should not be needed for pred

try    
    booster = booster.apply(x);
    predictions = booster.validation_pred;
catch
    z = lasterror;
    z.message = ['xgbPredict error: ' z.message];
    rethrow(z)
end
