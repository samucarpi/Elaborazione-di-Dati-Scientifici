function rinv = rinverse(p,t,w,f)
%RINVERSE Calculate pseudo inverse for PLS, PCR and RR models.
%  Inverse calculated depends upon the number of inputs supplied.
%  For PLS and PCR models structures, the inputs are the model
%  (mod) and the optional number of factors (ncomp).
%
%I/O: rinv = rinverse(mod,ncomp)
%
%  For PLS models, the inputs are the loadings (p),
%  scores (t), weights (w) and number of LVs (ncomp).
%
%I/O: rinv = rinverse(p,t,w,ncomp)
%
%  For PCR models, the inputs are the loadings (p),
%  scores (t), and number of PCs (ncomp).
%
%I/O: rinv = rinverse(p,t,ncomp)
%
%  For ridge regression (RR) models, the inputs are
%  the scaled x matrix (sx) and ridge parameter (theta).
%
%I/O: rinv = rinverse(sx,theta)
%  
%See also: PCR, PLS, RIDGE, STDSSLCT

% Copyright © Eigenvector Research, Inc. 1996
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%bmw 8/02 rewritten to take PLS_Toolbox 3 models as input

if nargin == 0; p = 'io'; end
varargin{1} = p;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear rinv; evriio(mfilename,varargin{1},options); else; rinv = evriio(mfilename,varargin{1},options); end
  return; 
end

regflag = 0;
if ismodel(p)
  if strcmp(p.modeltype,'PCR')
    if nargin == 2
      w = t;
    end
    t = p.loads{1};
    p = p.loads{2};
    regflag = 1;
  elseif strcmp(p.modeltype,'PLS')
    regflag = 2;
    if nargin == 3
      f = t;
    end
    w = p.wts;
    t = p.loads{1};
    p = p.loads{2};
  else
    error(['Models of type ' p.modeltype ' not supported'])
  end
end
      
[m,n] = size(p);
if nargin == 4 | regflag == 2
  if ~exist('f')
    f = n;
  elseif f > n
    error('Number of LVs requested exceeds number given')
  end
  % The PLS pseudo inverse is defined by
  rinv = w(:,1:f)*inv(p(:,1:f)'*w(:,1:f))*inv(t(:,1:f)'*t(:,1:f))*t(:,1:f)';
elseif nargin == 3 | regflag == 1
  if ~exist('w')
    w = n;
  elseif w > n
    error('Number of PCs requested exceeds number given')
  end
  % The PCR pseudo inverse is definedy by 
  rinv = p(:,1:w)*inv(t(:,1:w)'*t(:,1:w))*t(:,1:w)';
elseif nargin == 2 & regflag == 0
  ridi = diag(diag(p'*p));
  % The RR pseudo inverse is defined by
  rinv = inv(p'*p + ridi*t)*p';
else
  error('Number of input arguments must be 2 (RR), 3 (PCR) or 4 (PLS)')
end
