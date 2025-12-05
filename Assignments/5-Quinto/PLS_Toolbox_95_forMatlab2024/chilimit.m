 function varargout = chilimit(varargin)
%CHILIMIT Chi-squared confidence limits from sum-of-squares residuals.
%  INPUT:
%     ssqr = sum-of-squares residuals (a.k.a. Q).
%
%  OPTIONAL INPUT:
%       cl = confidence level (0<cl<1) {default = 0.95}.
%  
%  OUTPUTS:
%      lim = calculated limit.
%      scl = scaling determined from the residuals.
%      dof = degrees of freedom determined from the residuals.
%    Subseqent calls to calculate different limits for the same data can 
%    be performed by passing (scl), (dof) and (cl).
%
%
%  The inverse of CHILIMIT must be called with four inputs using
%      I/O: cl   = chilimit(scl,dof,ssqr,2);
%    where the inputs (scl) and (dof) are outputs described above.
%    The input (ssqr) corresponds to a sum-of-squared residual and the
%    input 2 is a flag that tells the algorithm to calculate the inverse.
%
%I/O: [lim,scl,dof] = chilimit(ssqr,cl);
%I/O: lim           = chilimit(scl,dof,cl);
%I/O: cl   = chilimit(scl,dof,ssqr,2);
%I/O: cl   = chilimit(ssqr,new_ssqr,[],2);
%
%See also: JMLIMIT, PCA, PCR, PLS, RESIDUALLIMIT, TSQLIM

% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%JMS 4/17/02 -initial coding
%jms 7/24/02 -added logic to handle all-zero residuals
%jms 3/29/06 -revised to use DF_Toolbox function

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

scl  = [];
dof  = [];
cl   = 0.95;
ssqr = [];

switch nargin
  case 1                      % [lim,scl,dof] = (ssqr)
    ssqr    = varargin{1};
  case 2
    if length(varargin{1})>1; % [lim,scl,dof] = (ssqr,cl)
      ssqr  = varargin{1};
      cl    = varargin{2};
    else                      % [lim]         = (scl,dof)
      scl   = varargin{1};
      dof   = varargin{2};
    end
  case 3                      % [lim]         = (scl,dof,cl)
    scl     = varargin{1};
    dof     = varargin{2};
    cl      = varargin{3};
  case 4                       %[cl] = (scl,dof,ssqr,flag)
    if ~isempty(varargin{3})
    %I/O: cl   = chilimit(scl,dof,ssqr,2);
    scl     = varargin{1};
    dof     = varargin{2};
    cl      = varargin{3};
    flag    = varargin{4};
    else
    %I/O: cl   = chilimit(ssqr,new_ssqr,[],2);
    ssqr    = varargin{1};
    cl      = varargin{2};
    flag    = varargin{4};
    end
end
if nargin<4
  flag    = 1;
end

if length(scl)~=1;
  if isempty(ssqr)
    error('SSQR requried to calculate scl')
  end
  if mean(ssqr)>0;
    scl   = var(ssqr)/(2*mean(ssqr));
  else
    scl   = eps;
  end
end

if length(dof)~=1;
  if isempty(ssqr)
    error('SSQR requried to calculate dof')
  end
  dof     = floor(mean(ssqr)./scl);
  if dof==0
    dof   = 1;
  end
end

if flag~=2
  if cl>=1|cl<=0
    if cl<100 & cl>0;
      cl    = cl /100;     %interpret 1-100 as percent and convert it
    else
      error('confidence limit must be 0<cl<1')
    end
  end

  lim       = chidf('quantile',cl,dof)*scl;
else
  lim       = chidf('cumulative',cl/scl,dof);
end
varargout   = {lim scl dof};
