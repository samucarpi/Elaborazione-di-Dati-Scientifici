function [result, cmap] = xgbTrain(x, y, args)
%xgbTrain XGBoost for classification or regression.
%  xgbTrain uses the XGBoost package to train an XGB model
%  or return cross validation accuracy based on training data
%
%  INPUTS:
%       x   = X-block (predictor block) class "double"
%       y   = Y-block (predicted block) class "double" is avector of length m
%             indicating sample class or target value.
%    args   = Parameters to xgboost's train method in a struct form.
%
%  OUTPUT:
%  result: xgboost model if not run in cross-validation mode
%  cross validation accuracy (%) (classification XGB) or RMSECV (regression
%  XGB) if run in cross-validation mode
%  cmap  : vector of unique class numbers, sorted ascending.
%
% %I/O: model = xgbTrain(x, y, options); Use calibration x data to build model

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

cmap = [];

% Argument validation step (e.g. c>0)
validateArgs(args, y);

num_round = args.num_round;

% Remove empty args (e.g. 'weights') as they break tr.train
[args] = removebadopts(args);

if strcmp(args.xgbtype,'xgbc')
  [y, cmap] = binaryclass(args, y); % Keep map to actual classes (cmap)
  num_class = length(cmap);
  args.num_class = num_class;       % Set XGBoost num_class param value
else
  args = rmfield(args, 'scale_pos_weight');  % Do NOT include for regression case!
end

% set random seed
if isfieldcheck('.random_state', args)
  rng(args.random_state,'twister');
  javaState = java.util.Random();
  javaState.setSeed(args.random_state);
end

try
    tr = evriPyClient(args);
    result = tr.calibrate(x,x,y);
catch
    s = lasterror;
    error(encode(s));
end

%-----------------------------------------------------------------
function [ic, C] = binaryclass(args, y)
% ic =1,2,...,nclass.  C(ic) is the corresponding actual class
% For binary class case subtract 1 from ic since xgboost requires y [0,1]
if isfield(args, 'objective')
    [C,ia,ic] = unique(y);
    if strcmp(args.objective, 'binary:logistic')
        if ~(length(C)==2)
            error('XGBoost objective = binary:logistic requires y has two classes; );  %is valued 0 or 1');
        end
    end
    ic = ic-1;% values must be 0, ...nclass-1 when setting labels for xgboost. 
end

%-----------------------------------------------------------------
function validateArgs(args, y)
% %objective  = 'binary:logistic';  % def = reg:linear.
if isfield(args, 'objective')
    if strcmp(args.objective, 'binary:logistic')
        uniquey = unique(y);
        if ~(length(uniquey)==2)   % & uniquey(1)==0 & uniquey(2)==1)
            error('XGBoost objective = binary:logistic requires y has two classes; );  %is valued 0 or 1');
        end
    end
end

%-----------------------------------------------------------------
function [args] = removebadopts(args)
fnames = fieldnames(args);
badkeys = {};
for ifld=1:length(fnames)
    if isempty(args.(fnames{ifld}))
        badkeys{end+1} = fnames{ifld};
    end
    if strcmp('q', fnames{ifld}) | strcmp('v', fnames{ifld}) | strcmp('b', fnames{ifld}) 
        badkeys{end+1} = fnames{ifld};
    end
end
for ii=1:length(badkeys)
    args = rmfield(args, badkeys{ii});
end
        
