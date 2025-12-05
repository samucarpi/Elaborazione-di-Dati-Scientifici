function vloads = varimax(loads,options)
%VARIMAX Orthogonal rotation of loadings.
%  Input (loads) is a NxK matrix with orthogonal columns (or a standard
%  model structure as described below) and the output (vloads) is a NxK
%  matrix with orthogonal columns rotated to maximize the "raw varimax
%  criterion". Under varimax the total simplicity S is maximized where:
%    S  = sum(Sk), k = 1:K
%  and the simplicty for each factor (column) is:
%    Sk = mean( (a - ones(n,1)*mean(a)).^2 ) with
%    a  = vloads(:,k)
%
%  If (loads) is a model structure, then the model's loadings are rotated
%  according to the varimax algorithm, then the scores and eigenvalues are
%  updated to correspond with the new loadings. The output (vloads) is the
%  model structure updated for the new basis.
%
%  Optional input (options) is a structure with the following fields:
%   stopcrit:   [ 1e-6 10000 ]    stopping criteria
%     stopcrit(1) is a relative tolerance { 1e-6 }
%     stopcrit(2) is the maximum number of iterations { 10000 }
%
%  Based on Kaiser's VARIMAX Method (J.R. Magnus and H. Neudecker,
%  Matrix Differential Calculus with Applications in Statistics and
%  Econometrics, Revised Ed., pp 373-376, 1999.)
%
%I/O: vloads = varimax(loads,options);
%
%See also: ANALYSIS, MANROTATE, PCA

%Copyright Eigenvector Research, Inc. 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg

if nargin == 0; loads = 'io'; end
varargin{1} = loads;
if ischar(varargin{1});
  options = [];
  options.name        = 'options';
  options.stopcrit    = [1e-6 10000]; %[(reltol) (iter)];

  if nargout==0; clear vloads; evriio(mfilename,varargin{1},options); else; vloads = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<2                      %assume input is a loadings matrix
  options  = varimax('options');
else
  options = reconopts(options,varimax('options'));
end

if ismodel(loads)
  %Model input? do rotation and insert results back into model
  vloads = varimaxmodel(loads,options);
  return;
end

n      = size(loads,1);
vb     = loads;      %initial guess for B = B(0)
its    = 0;
relres = inf;
while (its<options.stopcrit(2)) & (relres>options.stopcrit(1))
  %1) Estimate Q(i)
  tmp    = vb.^2;
  vb2m   = mean(tmp);
  vq     = vb.*(tmp - vb2m(ones(n,1),:));
  %2) Estimate B(i)
  tmp    = loads'*vq;
  [vb2m,s,vq] = svd(tmp'*tmp);
  s      = diag(1./sqrt(diag(s)));
  vb2m   = vb2m*s*vq';
  vbn    = loads*tmp*vb2m;
  %  vbn    = normaliz((loads*tmp*vb2m)')';
  relres = sum(sum((vbn - vb).^2,2));
  %if (its/50 - floor(its/50))==0
  %disp(relres)
  %end
  its    = its+1;
  vb     = vbn;
end
vloads = vbn;

%-----------------------------------------------
function mod = varimaxmodel(mod,options)
%operate on a model

if ~isfield(mod,'loads') | ndims(mod.loads{2,1})~=2;
  error('VARIMAX cannot operate on this model type (%s)',mod.modeltype);
end

lds = mod.loads;
vloads = varimax(lds{2},options);

ncomp = size(vloads,2);        %number of components
incl  = mod.detail.includ{1};  %included samples

%calculate corresponding scores and eigenvalues
vscores   = lds{1}*(lds{2}'*vloads);
veig      = sum(vscores(incl,:).^2/(length(incl)-1));
vssq      = mod.detail.ssq(1:ncomp,:);
switch lower(mod.modeltype)
  case 'pca'
    vssq(:,2) = veig;
    vssq(:,3) = veig./sum(veig).*vssq(end,4);
    vssq(:,4) = cumsum(vssq(:,3));
  case {'pcr','pls','plsda'}
    vssq(:,2) = veig./sum(veig).*vssq(end,3);
    vssq(:,3) = cumsum(vssq(:,2));
  otherwise
    error('VARIMAX cannot operate on this model type (%s)',mod.modeltype);
end

%update model with this information
mod.loads = {vscores; vloads};
mod.detail.ssq(1:ncomp,:) = vssq;

%clear out invalid settings (cross-val, etc)
mod.detail.rmsec  = [];
mod.detail.rmsecv = [];
mod.detail.eigsnr = [];
mod.detail.cv     = '';
mod.detail.split  = [];
mod.detail.iter   = [];
mod.info = sprintf('VARIMAX rotated %s model',mod.modeltype);

