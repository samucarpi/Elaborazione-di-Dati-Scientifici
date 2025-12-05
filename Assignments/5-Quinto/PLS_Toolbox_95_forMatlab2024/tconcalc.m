function [tcon,tsqs] = tconcalc(newx,model,ssq)
%TCONCALC Calculates Hotellings T2 contributions.
%  If the input (model) is a PCA model structure then p = model.loads{2} and
%  the output contributions (tcon) ant T^2 (tsqs) are calculated for a row
%  vector x [e.g., a row of input (newx)] as
%    tcon = x*p*sqrt(inv(s))*p';
%    tsqs = tcon*tcon';
%  Supported model types: PCA, MPCA, PCA_PRED, MPCA_PRED, PLS, PLS_PRED
%
%  INPUTS:
%   [tcon,tsqs] = tconcalc(newx,model);
%      newx = new data, and 
%     model = the 2-way PCA or regression model for which T2 contributions
%             are to be calculated.
%
%   [tcon,tsqs] = tconcalc(pred,model);
%      pred = the prediction structure calculated for the new data.
%
%   [tcon,tsqs] = tconcalc(model);
%             Passing the model only calculates contributions for
%             the calibration data.
%
%   [tcon,tsqs] = tconcalc(newx,p,ssq);
%         p = PCA loadings, and
%       ssq = variance table (ssq). See PCA for more information.
%             Note: For this I/O the data matrix (newx) must be scaled in a
%             similar manner to the data used to determine the loadings (p)
%             and the I/O is only strictly used for PCA models.
%
%  OUTPUTS
%    tcon = T^2 contributions and
%    tsqs = Hotelling's T^2.
%
%I/O: [tcon,tsqs] = tconcalc(newx,model);
%I/O: [tcon,tsqs] = tconcalc(pred,model);
%I/O: [tcon,tsqs] = tconcalc(model);
%I/O: [tcon,tsqs] = tconcalc(newx,p,ssq);
%
%See also: DATAHAT, PCA, PCR, PLS, QCONCALC

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% JMS 5/15/04 -use lowercase modeltype when doing feval for prediction.
% JMS 11/30/05 -allow passing of just a model (tcon for modeled data)
 
if nargin == 0; newx = 'io'; end
if ischar(newx);
  options = [];
  if nargout==0; clear tcon; evriio(mfilename,newx,options); else; tcon = evriio(mfilename,newx,options); end
  return; 
end

if nargin==1;    %model only passed, get tcon for modeled samples
  model   = newx;
  pred    = newx;
  newx    = [];
elseif nargin==2 %prediction or newx passed
  if ismodel(newx);
    pred  = newx;
    newx  = [];
  else
    pred  = feval(lower(model.modeltype),newx,model,struct('display','off','plots','off'));
  end
else
  %User passed raw info (x,p,ssq), fake PCA model structure and apply model
  %(assume we can just project onto the loadings)
  x       = newx;
  p       = model;
  if isdataset(x)
    x     = x.data(x.includ{1,1},:);
  end
 
  model   = modelstruct('pca');
  model.loads{2,1} = p;
  model.detail.ssq = ssq;
  model.detail.includ{1,1} = 1;
  pred    = model;
  pred.loads{1,1} = x*p;
  newx    = [];
end

if ~ismodel(model)
  error('Input model must be a standard model structure or model object with scores and loadings.');
end
if ~isfield(model,'loads');
  error('This model type does not support T Contributions (no scores)')
end

switch lower(model.modeltype)
case {'pca' 'mpca' 'pca_pred' 'mpca_pred'}  %assumes orthogonal loadings and scores
  mp      = spdiag(1./sqrt(model.detail.ssq(1:size(model.loads{2,1},2),2)));
  tcon    = pred.loads{1,1}*mp*pred.loads{2,1}';
case {'pcr' 'pcr_pred'}                     %assumes orthogonal loadings and scores
  mp      = spdiag(1./sqrt(model.detail.pcassq(1:size(model.loads{2,1},2),2)));
  tcon    = pred.loads{1,1}*mp*pred.loads{2,1}';
case {'pls' 'pls_pred' 'plsda' 'plsda_pred'}                                %assumes orthogonal scores only
  if isfield(model.detail,'eig') & ~isempty(model.detail.eig) %use eig field if there
    mp    = spdiag(sqrt(1./model.detail.eig));
  else                                                        %otherwise, calculate it
    mp    = spdiag(sqrt(1./(diag(model.loads{1,1}(model.detail.includ{1,1},:)'* ...
                                 model.loads{1,1}(model.detail.includ{1,1},:))/ ...
                                (length(model.detail.includ{1,1})-1))) );
  end
  [up,sp] = svd(pred.loads{2,1}'*pred.loads{2,1});
  sp      = diag(1./diag(sqrt(sp)));
  tcon    = pred.loads{1,1}*mp*up*sp*up'*pred.loads{2,1}';
%   case {'mcr', 'cls' }                      %assumes oblique scores and loadings
otherwise
  error('This model type is not supported')
end

% if ismember(lower(model.modeltype),{'pca' 'mpca' 'pca_pred' 'mpca_pred'})
%   np = size(model.loads{2,1},2);
%   mp = 1./sqrt(model.detail.ssq(1:np,2));
% elseif ismember(lower(model.modeltype),{'pcr' 'pcr_pred'})
%   np = size(model.loads{2,1},2);
%   mp = 1./sqrt(model.detail.pcassq(1:np,2));
% else
%   if isfield(model.detail,'eig') & ~isempty(model.detail.eig)
%     %use eig field if there
%     mp = sqrt(1./model.detail.eig);
%   else
%     %otherwise, calculate it
%     mp = sqrt(1./(diag(model.loads{1,1}(model.detail.includ{1,1},:)'* ...
%       model.loads{1,1}(model.detail.includ{1,1},:))/ ...
%       (length(model.detail.includ{1,1})-1)));
%   end
% end
% tcon = pred.loads{1,1}*diag(mp)*pred.loads{2,1}';
tsqs = sum(tcon.^2,2);


