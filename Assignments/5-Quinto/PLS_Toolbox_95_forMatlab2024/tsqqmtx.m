function [tsqqmat,tsqqs] = tsqqmtx(x,model,wt)
%TSQQMTX Calculates matrix for T^2+Q contributions for PCA and MPCA.
%  INPUTS:
%        x = data matrix [class double or dataset]
%    model = PCA or MPCA model standard model struture (see PCA).
%
%  OPTIONAL INPUT:
%       wt = {sqrt((M-K-1)/(M-1))}, 0<=wt<=1 scalar weighting for contributions
%            0<wt<1 gives combined T^2 and Q statistics where M is the
%            number of calibration samples and K is the number of PCs.
%            wt = 1 gives T^2 and T^2 contributions
%            wt = 0 gives standarized Q residuals
%
%  OUTPUTS:
%    tsqqs = combined Hotelling's T^2 + Q residual
%  tsqqmat = matrix of individual variable contributions such that
%             tsqqs(i) = tsqqmat(i,:)*tsqqmat(i,:)';
% 
%I/O: [tsqqmat,tsqqs] = tsqqmtx(x,model,wt);
%I/O: tsqqmtx demo
% 
%See also: DATAHAT, PCA, PCR, PLS, TCONCALC, TSQMTX

%Copyright Eigenvector Research, Inc. 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 2/01 (original paper sent to EvRI folks), modified significantly 3/08
%presented at AEC/APC in Westminster 2006
%nbg 8/08 modified calc and help

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  if nargout==0; clear tsqqmat; evriio(mfilename,x,options); else tsqqmat = evriio(mfilename,x,options); end
  return;
elseif nargin<2
  error('TSQQMTX requires 2 inputs.')
end

[mx,nx] = size(x);
[mp,np] = size(model.loads{2,1});
if nargin<3 || isempty(wt)
  wt  = 0.5;
elseif numel(wt)>1
  error('Input (wt) must be a scalar.')
elseif wt<0 | wt>1
    error('Input (wt) must be 0<=wt<=1.')
end

if ~ismodel(model)
  %input must include a standard model structure
  error('Input (model) not a valid model structure.')
end

pred = feval(lower(model.modeltype),x,model,struct('display','off','plots','off','blockdetails','all'));
tcon = tconcalc(pred,model);
mx   = model.loads{2,1};
residstd = 1./(sqrt(model.ssqresiduals{2}/(length(model.detail.includ{1})-1)));  %1./std of residuals
tsqqmat  = (1-wt)*pred.detail.res{1}*diag(residstd)*(speye(mp)-mx*mx') + wt*tcon;

tsqqs = sum((tsqqmat.^2),2);
