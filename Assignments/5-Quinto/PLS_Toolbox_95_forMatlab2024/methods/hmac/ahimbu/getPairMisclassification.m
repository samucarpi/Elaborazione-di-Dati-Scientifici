function [ncomp, res] = getPairMisclassification(X,y,opts)
%GETPAIRMISCLASSIFICATION Report optimal number of LVs from crossvalidation.
% Reports crossvalidation results on a pair of classes and optimal number
% of components to use.
%
% INPUTS:
%           X = X-block (predictor block) class "double" or "dataset",
%           y = Y-block (OPTIONAL) if (x) is a dataset containing classes for
%                sample mode (mode 1) otherwise, (y) is a vector of sample
%                classes for each sample in x.
%      maxlvs = Maximal number of latent variables to consider.
%        opts = Model options and Cross Validation options.
%
%  OUTPUT:
%       ncomp = optimal number of LVs to use.
%         res = crossval.m results.
%
%I/O: [ncomp, res] = getPairMisclassification(X,y,maxlv,opts)
%
%See also: HMAC, MERGELEASTSEPARABLE, GETMISCLASSIFICATION, AUTOCLASSIFIER, MODELSELECTOR, CROSSVAL, PLSDA

% Copyright © Eigenvector Research, Inc. 2022
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
o = plsda('options');
o.preprocessing = opts.cvopts.preprocessing;
o.display = 'off';
o.plots = 'none';

if isdataset(X)
  rankX = rank(X.data);
else
  rankX = rank(X);
end
% run with plenty of LVs, more of a chance that choosecomp will return a
% nonempty number of LVs to use
% use the maximumfactors preference, if defined
prefs = getplspref;
if isfieldcheck(prefs,'.analysis.maximumfactors')
  maxlvpref = prefs.analysis.maximumfactors;
else
  maxlvpref = 20;
end
% truncate this down to minimum between itself and rank of X
maxlvpref = min(maxlvpref,rankX);

% if ran from gui, options will have a prog field, which is the
% uiprogressdlg fig
% check if ran from gui, allowing execution to be cancelable
if isfield(opts,'prog')
  if ~opts.prog.CancelRequested
    % build model with maxlvpref
    m = plsda(X, y, maxlvpref, o);
    % crossvalidate with maxlvpref
    res = crossval(X,y,m,opts.cvi,maxlvpref,opts.cvopts);
    % choose number of components by finding knee in rmsecv curve
    ncomp = choosecomp(res);
    % ncomp can still be empty if maxlv was more than 7 or it wanted > than
    % half of the rank of the data
    % if this happens, then set to min of maxlvpref or user-specified lvs
    if all(ncomp > opts.maxlvs) || isempty(ncomp)
      ncomp = min(maxlvpref,opts.maxlvs);
    end
  else
    % user requested cancellation, abort
    return
  end
else
  % perform as usual
  % build model with maxlvpref
  m = plsda(X, y, maxlvpref, o);
  % crossvalidate with maxlvpref
  res = crossval(X,y,m,opts.cvi,maxlvpref,opts.cvopts);
  % choose number of components by finding knee in rmsecv curve
  ncomp = choosecomp(res);
  % ncomp can still be empty if maxlv was more than 7 or it wanted > than
  % half of the rank of the data
  % if this happens, then set to min of maxlvpref or user-specified lvs
  if all(ncomp > opts.maxlvs) || isempty(ncomp)
    ncomp = min(maxlvpref,opts.maxlvs);
  end
end