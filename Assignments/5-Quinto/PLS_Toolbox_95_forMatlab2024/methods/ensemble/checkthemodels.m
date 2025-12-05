function checkthemodels(models,algorithm)
%CHECKTHEMODELS Inspect models for ensemble modeltype.
% Inspect incoming child models for ensemble modeltype. Rules apply to
% these models depending on the algorithm used for the ensemble. Function
% will error if one of these rules are violated.
%
% INPUTS:
%        models = cell array of models for ensemble,
%     algorithm = ensemble algorithm.
%
%I/O: checkthemodels(models,algorithm)
%
%See also: ENSEMBLE AGGREGATEPREDICTIONS COMPUTEJACKKNIFE

% Copyright © Eigenvector Research, Inc. 2024
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

switch algorithm
  case 'fusion'
    % model fusion assumes that the models were all trained on the same data
    % check the x
    % Rules:
    %   1) all models must be trained on the same X block
    %   2) all models must be trained on the same samples in X
    
    % 1.
    xids = cellfun(@(x) x.datasource{1}.uniqueid,models,'UniformOutput',false);
    if ~isempty(xids)
      % even if variables are excluded, they get the same uniqueid
      if length(unique(xids)) > 1
        error('At least 1 model was calibrated with a different X Block. Cannot create ensemble.')
      end
      % 2.
      % check if the number of included samples are consistent
      if length(unique(cellfun(@(x) x.datasource{1}.include_size(1),models))) > 1
        error('Models are calibrated with different number of included samples, cannot create ensemble.')
      end
      xincludedsamples = cellfun(@(x) sort(x.detail.includ{1,1}),models,'UniformOutput',false);
      if length(unique(cat(1,xincludedsamples{:}))) ~= unique(cellfun(@(x) x.datasource{1}.include_size(1),models))
        error('Not all models were calibrated on the same included samples, cannot create ensemble.')
      end
    else
      error('No X data information stored in model, cannot create ensemble.')
    end
    % check the y
    % Rules:
    %   1) all models must be trained on the same Y block
    %   2) all models must be trained on the same samples in Y
    %   3) all models must be trained on the same columns in Y
    %   4) all models must be trained on 1 column in Y
    
    % 1.
    yids = cellfun(@(x) x.datasource{2}.uniqueid,models,'UniformOutput',false);
    if ~isempty(yids)
      % even if variables are excluded, they get the same uniqueid
      if length(unique(yids)) > 1
        error('At least 1 model was calibrated with a different Y Block. Cannot create ensemble.')
      end
      % 2.
      % check if the number of included samples are consistent
      if length(unique(cellfun(@(x) x.datasource{2}.include_size(1),models))) > 1
        error('Models are calibrated with different number of included samples, cannot create ensemble.')
      end
      yincludedsamples = cellfun(@(x) sort(x.detail.includ{1,1}),models,'UniformOutput',false);
      if length(unique(cat(1,yincludedsamples{:}))) ~= unique(cellfun(@(x) x.datasource{2}.include_size(1),models))
        error('Not all models were calibrated on the same included samples, cannot create ensemble.')
      end
      % 3.
      yincludedcolumns = cellfun(@(x) sort(x.detail.includ{2,2}),models,'UniformOutput',false);
      if length(unique(cellfun(@length, yincludedcolumns))) > 1
        error('Not all models were calibrated on the same number of included Y column(s), cannot create ensemble.')
      end
      if length(unique(cat(2,yincludedcolumns{:}))) ~= unique(cellfun(@(x) x.datasource{2}.include_size(2),models))
        error('Not all models were calibrated on the same included Y column(s), cannot create ensemble.')
      end
      % 4.
      if any(cellfun(@length, yincludedcolumns) > 1)
        error('ENSEMBLE only supports univariate regression at this time.')
      end
    else
      error('No Y data information stored in model, cannot create ensemble.')
    end
  otherwise
    error(['Unsupported algorithm: ' algorithm '. Supported algorithms: ''fusion''.'])
end
end