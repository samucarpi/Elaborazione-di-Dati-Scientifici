function [rescl,s] = residuallimit(residuals,cl,options)
%RESIDUALLIMIT Estimates confidence limits for sum squared residuals.
%  INPUTS:
%    residuals = 1) E a full-matrix of residuals. For example, for a PCA
%                  model X = TP' + E, the residuals is the matrix E which
%                  can be calculated using the DATAHAT function.
%                Note that the biggest error is to input sum(E.^2,2) not E
%                [see output (s) for more information].
%             or 2) a standard model structure (model).
%
%           cl = the frational confidence limit {default = 0.95}
%             or 2) sum-of-squares residual(s) when using inverse algorithm.
%
%  OPTIONAL INPUT:
%      options = structure array with the following fields:
%    algorithm : [ {'jm'} | 'chi2' | 'auto' ] governs algorithm choice:
%          'jm' uses Jackson-Mudholkar method (slower, more robust)
%       'invjm' uses Jackson-Mudholkar method (slower, more robust) to
%                calculate a confidence limit from a given sum square
%                residual. Output is a confidence limit.
%        'chi2' uses chi^2 moment method (faster, less robust with outliers)
%     'invchi2' uses chi^2 moment method to calculate a confidence limit
%                from a given sum square residual. Output is a confidence
%                limit.
%        'auto' automatically selects based on data size (<300 rows or
%                columns, use 'jm', otherwise, use 'chi2').
%
%  OUTPUT:
%        rescl = the confidence limit.
%            s = residual eigenvalues when using the Jackson-Mudholkar
%                'jm' algorithm. To improve speed, (s) can be used in place
%                of (residuals) in subsequent calls to residuallimit for
%                the same data.
%
%I/O: [rescl,s] = residuallimit(residuals,cl,options);
%I/O: [rescl,s] = residuallimit(model,cl,options);
%I/O: rescl     = residuallimit(s,cl,options);  %fast new limits
%I/O: cl        = residuallimit(model,q,options);
%
%Example: rescl = residuallimit(resids,0.95);
%
%See also: ANALYSIS, CHILIMIT, DATAHAT, JMLIMIT, PCA

% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%bmw 9/2002
%jms 9/2002
%rb 10/2002 changed mdcheck options
%jms 11/29/05 added option to pass model itself (we extract info for user)

if nargin == 0; residuals = 'io'; end
varargin{1} = residuals;
if ischar(varargin{1});
  options.algorithm = 'jm';
  if nargout==0; clear rescl; evriio(mfilename,varargin{1},options); else; rescl = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin < 3
  options = [];
end
options = reconopts(options,'residuallimit',{'plots','preprocessing'});
if nargin < 2 | isempty(cl)
  cl = .95;
end

if ~(strcmpi(options.algorithm,'invjm') | strcmpi(options.algorithm,'invchi2')) & any(cl>=1|cl<=0)
  error('confidence limit must be 0<cl<1')
end

if ismodel(residuals);
  %got a model, see what we can extract from it
  model = residuals;
  if strcmpi(model.modeltype, 'pca_pred')
    residuals = model.ssqresiduals;
  elseif (strcmpi(options.algorithm,'jm') | strcmpi(options.algorithm,'invjm')) ...
      & isfield(model.detail,'reseig') & ~isempty(model.detail.reseig)
    %we've got residual eigenvectors! (but only for "jm" limit mode)
    residuals = model.detail.reseig;
  elseif isfield(model.detail,'res') & ~isempty(model.detail.res) ...
      & iscell(model.detail.res) & ~isempty(model.detail.res{1})
    %we've got raw residuals...
    residuals = model.detail.res{1}(model.detail.includ{1,1},:);
  elseif isfield(model,'ssqresiduals')
    %we've got ssq residuals...
    residuals = model.ssqresiduals{1}(model.detail.includ{1,1});
  else
    error('Cannot locate relavent residual information in this model')
  end
end
    
sr = size(residuals);
org_opts = options;

if length(sr) > 2  %N-way array
  for i = 1:length(sr)
    resuf = unfoldmw(residuals,i);
    rescl(i) = residuallimit(resuf,cl,options);
  end
else
  m = sr(1); n = sr(2);
  if strcmp(lower(org_opts.algorithm),'auto')
    if min([m,n]) < 300
      options.algorithm = 'jm';
    else
      options.algorithm = 'chi2';
    end
  end
  switch lower(options.algorithm)
  case {'chi2' 'invchi2'}
    if min(m,n)>1;  %actual residuals, calculate sum squared resids
      q = sum(residuals.^2,2);
    else   %sum squared residuals passed, use those to calculate limit
      q = residuals;
    end
    if strcmpi(options.algorithm, 'chi2')
      rescl = chilimit(q,cl);
    else
      rescl = chilimit(q, cl, [], 2);
    end
    s     = residuals;
  case {'jm' 'invjm'}
    if min(m,n)>1;  %actual residuals, calculate eigenvalues
      % Remove completely missing rows and columns
      residuals(:,sum(~isfinite(residuals))==size(residuals,1))=[];
      residuals = residuals(:,find(sum(~isfinite(residuals))~=size(residuals,1)));
      residuals(sum(~isfinite(residuals'))==size(residuals,2),:)=[];
      try % Try to replace missing elements
        mdop                = mdcheck('options');
        mdop.max_missing    = 0.9999;
        mdop.max_pcs        = 1;
        mdop.meancenter     = 'no';
        mdop.tolerance      = [1e-4 10];
        mdop.algorithm      = 'nipals';
        [out,out,residuals] = mdcheck(residuals,mdop);
      catch % Otherwise set them to zero
        residuals(find(~isfinite(residuals))) = 0;
      end
      if m > n
        s = svd(residuals);
      else
        s = svd(residuals');
      end
      s = s.^2/(m-1);
    else    %eigenvalues passed, use those to calculate limit
      s = residuals;
    end
    if strcmpi(options.algorithm, 'jm')
      rescl = jmlimit(0,s,cl);
    else
      rescl = jmlimit(0,s,cl, 2);
    end
  otherwise
    error('Unknown method for residuals limits')   
  end
end
