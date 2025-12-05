function omodel = orthogonalizepls(model,x,y)
%ORTHOGONALIZEPLS Condenses y-variance into first component of a PLS model.
% Produces an orthogonal PLS model which contains all the y-variance
% capturing direction in the first weight and loading. The predictions of
% the model are identical to the non-orthogonalized model but the loadings
% and weights have been rotated.
%
% If no y-block information is passed, it is assumed that the model has
% already been orthogonalized and is being applied to the passed x-block
% data. In this case, only the new scores are calculated.
%
% INPUTS:
%    model = Standard PLS model to orthogonalize OR orthogonalized model
%             (if no y passed). Alternatively, the weights from a model can
%             be passed in instead of the entire model structure. In this
%             case, y must be passed as input and the output will be the
%             raw orthogonalized loadings, scores and weights.
%        x = Preprocessed x-block data. Preprocessed in the same way as is
%             indicated in the model.
%
% OPTIONAL INPUTS:
%        y = Preprocessed y-block data. If omitted, x is assumed to be NEW
%             data to which the model is being applied. Otherwise, x and y
%             are assumed to be the calibration data from which the model
%             was created and model will be orthogonalized.
%
% OUTPUTS:
%   omodel = Model with orthogonalized loadings and scores.
%
%I/O: omodel = orthogonalizepls(model,x,y)  %orthogonalize model
%I/O: omodel = orthogonalizepls(wts,x,y)    %orthogonalize model (from weights)
%I/O: omodel = orthogonalizepls(omodel,x)   %calculate scores for applying omodel to x
%
%See also: COV_CV, GLSW, PCR, PLS

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<2
  error('Inputs (model) and (x) are required.')
end

if nargin>2
  % Orthogonalize this model
  % Extract weights from PLS model
  if ismodel(model)
    incl    = model.detail.includ;
    weights = model.wts;
  else
    incl    = {1:size(x,1) 1:size(y,1); 1:size(x,2) 1:size(y,2)};
    weights = model;
    model   = struct('loads',[],'wts',[]);
  end
  [m,k]   = size(weights);
  
  % Create orthonormal version of them
  oweights = zeros(m,k);
  oweights(:,1) = normaliz(weights(:,1)')';
  for i = 2:k
    oweights(:,i) = (weights(:,i)' - weights(:,i)'*oweights(:,1:i)*oweights(:,1:i)');
    oweights(:,i) = normaliz(oweights(:,i)')';
  end
  
  % Calculate the scores for factor 2 to the end
  scores2 = x*oweights(:,2:end);

  %orthogonalize scores (rotate weights)
  [u,s]   = svd(scores2(incl{1},:)'*scores2(incl{1},:));
  oweights(:,2:end) = oweights(:,2:end)*u;
  scores2  = x*oweights(:,2:end);  %re-calculate scores2
  
  %calculate loadings for factor 2 to the end
  loads2  = scores2(incl{1},:)\x(incl{1},:); 
   
  % Calculate the filtered x estimate
  filteredx = x - scores2*loads2;
  scores1   = filteredx*oweights(:,1);
  loads1    = scores1(incl{1},:)\x(incl{1},:);
  
  scores    = [scores1 scores2];
  loads     = [loads1' loads2'];
  
  %correct variance captured
  yloads = (y'*normaliz(scores')'); 
  yscores = y*yloads;
  if ismodel(model)
    ssy = diag(yloads'*yloads);
    ssy = ssy./sum(ssy).*model.detail.ssq(k,5);
    ssx = diag(scores'*scores);
    ssx = ssx./sum(ssx).*model.detail.ssq(k,3);
    ssq = [(1:k)' ssx cumsum(ssx) ssy cumsum(ssy)];
  else
    ssq = [];
  end
  
  %and store back in model
  model.loads{1,1} = scores;
  model.loads{2,1} = loads;
  model.loads{1,2} = yscores;
  model.loads{2,2} = yloads;
  model.wts        = oweights;
  if ~isempty(ssq)
    model.detail.ssq = ssq;
  end
  
else
  % No Y information means we're applying this to new data
  
  %For orthogonalized model, replace first score with score
  %calculated after filtering out components 2 through nlv
  model.loads{1,1} = x*model.wts;
  model.loads{1,1}(:,1) = 0;  %zero out score 1
  %use the remaining scores to filter
  filteredxpp = x - model.loads{1,1}*model.loads{2,1}';
  %and recalculate score 1
  model.loads{1,1}(:,1) = filteredxpp*model.wts(:,1);
  
end

omodel = model;
