function [cmodel,msg] = compressmodel(model,include)
%COMPRESSMODEL Remove references to unused variables from a model.
% COMPRESSMODEL will remove any references in a model to excluded
% variables. This permits the application of the model to new data in which
% unused variables have been hard-excluded. 
% INPUT:
%     model = model to compress
% OPTIONAL INPUT:
%   include = Index range of variables to include. If not provided,
%             compressmodel will keep only those variables which are
%             explictly marked as included in the original data.
% OUTPUTS:
%   cmodel = the compressed model
%      msg = any warning messages reported during compression.
%
% Although compression will work on most models, some preprocessing methods
% and some model types may not compress correctly. In these cases, a
% warning will be given and reported in the output (msg).
%
%I/O: [cmodel,msg] = compressmodel(model,include)
%
%See also: PCA, PCR, PLS, PLSDA

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms

if nargin == 0; model = 'io'; end
if ischar(model);
  options = [];
  if nargout==0; evriio(mfilename,model,options); else; cmodel = evriio(mfilename,model,options); end
  return; 
end

msg = [];
if ~ismember(lower(model.modeltype),{ 'pls' 'pcr' 'pca' 'plsda' });
  msg = strvcat(msg,'Attempting to reduce unrecognized model - this may not be valid');
end

%make a copy
cmodel=model;

if nargin<2;
  %grab the include field
  include = cmodel.detail.includ{2};
else
  if ~isempty(setdiff(cmodel.detail.includ{2},include))
    error('All variables required by model must be included')
  end
end

%grab the original number of variables
norigvars = cmodel.datasource{1}.size(2);

%adjust known fields
cmodel.datasource{1}.size(2) = length(include);

if ~isempty(cmodel.detail.axisscale{2})
  cmodel.detail.axisscale{2} = cmodel.detail.axisscale{2}(include);
end
if ~isempty(cmodel.detail.label{2})
  cmodel.detail.label{2}     = cmodel.detail.label{2}(include,:);
end
if ~isempty(cmodel.detail.class{2})
  cmodel.detail.class{2}     = cmodel.detail.class{2}(include);
end
if length(cmodel.ssqresiduals{2})>length(include);
  cmodel.ssqresiduals{2}     = cmodel.ssqresiduals{2}(include);
end
cmodel.detail.includ{2}      = 1:length(include);

if length(cmodel.detail.means{1})==norigvars;
  cmodel.detail.means{1} = cmodel.detail.means{1}(include);
end
if length(cmodel.detail.stds{1})==norigvars;
  cmodel.detail.stds{1} = cmodel.detail.stds{1}(include);
end

%check preprocessing for "bad" items
if ~isempty(cmodel.detail.preprocessing{1})
  pp = {cmodel.detail.preprocessing{1}.description};
  ok = {'Absolute Value'
    'Autoscale'
    'Center'
    'Detrend'
    'GLS Weighting'
    'Group Scale'
    'Log10'
    'Mean Center'
    'Median Center'
    'MSC (mean)'
    'Normalize'
    'OSC (Orthogonal Signal Correction)'
    'Scale'
    'SNV'
    'Sqrt Mean Scale'};

  %These items are explictly left out.
  % The following use references which will probably NOT have been
  % forshortened by the include field. Thus they will probably NOT work.
  %     'Baseline (Weighted Least Squares)'
  %     'EMSC (Extended Scatter Correction)'
  % These two often use the excluded variables to do the smoothing or
  % derivatizing even though they are ignored later. The result doing the
  % derivative/smooth without the excluded variables can be significantly
  % different from the same process WITH the excluded variables (depending
  % on slope)
  %     'Derivative (SavGol)'
  %     'Smoothing (SavGol)'

  questionable = setdiff(pp,ok);
  if ~isempty(questionable);
    msg = strvcat(msg,'The following preprocessing steps may or may not work correctly.');
    msg = strvcat(msg,sprintf('  %s\n',questionable{:}));
  end
end

%give warnings (if any)
if ~isempty(msg);
  disp('EVRI:Compressmodel','Model may not have compressed correctly:')
  disp(msg);
  disp('The output model should be tested on known validation data.');
end
