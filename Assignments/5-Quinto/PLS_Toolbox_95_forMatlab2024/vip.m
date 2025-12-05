function vip_scores = vip(model,varargin)
%VIP Calculate Variable Importance in Projection from regression model.
% Variable Importance in Projection (VIP) scores estimate the importance of
% each variable in the projection used in a PLS model and is often used for
% variable selection. A variable with a VIP Score close to or greater than
% 1 (one) can be considered important in given model. Variables with VIP
% scores significantly less than 1 (one) are less important and might be
% good candidates for exclusion from the model.
%
% INPUTS:
%  Standard input is:
%   model = a PLS model structure from a PLS model 
% 
%  Alternative input format is the outputs of the SIMPLS or NIPPLS:
%   xscrs = X-block scores
%    xlds = X-block loadings
%     wts = X-block weights
%     reg = regression vectors for each column of y and each number of
%           latent variables (reg) 
%
% OUTPUTS: 
%  vip_scores = a set of column vectors equal in length to the number of
%  variables included in the model. It contains one column of VIP scores
%  for each predicted y-block column.
%
% See Chong & Jun, Chemo. Intell. Lab. Sys. 78 (2005) 103–112.
%
%I/O: vip_scores = vip(model)
%I/O: vip_scores = vip(xscrs,xlds,wts,reg)
%
%See also: GENALG, IPLS, PLOTLOADS, PLS, PLSDA, SRATIO

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS initial coding 7/5/05

if nargin == 0; model = 'io'; end
if ischar(model);
  options = [];
  if nargout==0; clear vip_scores; evriio(mfilename,model,options); else; vip_scores = evriio(mfilename,model,options); end
  return; 
end

if ~ismodel(model)
  %simple inputs
  % (xscrs,xlds,wts,reg)  => (T,P,w,reg)
  if nargin<4
    error('This input format requires four inputs (xscrs, xlds, wts, reg)')
  end
  T = model;
  [P,w,reg] = deal(varargin{1:3});
  incl = {1:size(T,1); 1:size(P,1)};
  nvars = size(w,1);
  if size(reg,2)==nvars & size(reg,1)~=nvars
    %ROW oriented? Probably the "simple regression vector" style from
    %SIMPLS
    reg = reg';    %transpose if ROW-oriented    
    nlvs = size(T,2);
    if size(reg,2)>=nlvs & mod(size(reg,2),nlvs)==0
      %looks like reg is the nlvs*ny format (1:nlvs are included in matrix)
      ny = size(reg,2)/nlvs;
      reg = reg(:,end-ny+1:end);  %choose ONLY the regression vector(s) for the max # of LVs
    end
  end
  
else
  %model object input
  if ~isfield(model.detail.options,'algorithm') || ~ismember(lower(model.detail.options.algorithm),{'sim' 'dspls' 'nip' 'robustpls'})
    error('The algorithm used for this model does not support VIP calulation')
  end
  
  %gather information from model
  incl = model.detail.includ;
  T    = model.loads{1,1}(incl{1,1},:);
  P    = model.loads{2,1};
  w    = model.wts;
  reg  = model.reg;

end

%do some calculations and 
wpw  = (w/(P'*w));
nx   = length(incl{2,1});
ny   = size(reg,2);

%pre-calculate some misc. things
TT = sum(T.^2,1);
w_norm = (w*diag(1./sqrt(sum(w.^2,1))));  %normalized weights

for i = 1:ny;
  %calculate regression in terms of scores (T*b = y_hat)
  b  = wpw\reg(:,i);

  %calculate weighted T^2
  SS = b.^2.*TT';

  %VIP scores for this y
  vip_scores(:,i) = sqrt(nx*w_norm.^2*SS./sum(SS));
end

