function varargout = nippls(varargin)
%NIPPLS NIPALS Partial Least Squares computational engine.
%  Performs PLS regression using NIPALS algorithm.
%  INPUTS:
%       x = X-block (M by Nx).
%       y = Y-block (M by Ny).
%
%  OPTIONAL INPUTS:
%    nocomp = number of components {default = rank of x-block}.
%   options = options structure containing the field:
%     display: [ 'off' |{'on'}]  governs display to command window.
%
%  OUTPUTS:
%      reg = matrix of regression vectors, where each row corresponds to a
%            regression vector for a given number of latent variables.
%            If the Y-block contains multiple columns, the rows of reg will
%            be in groups of latent variables (so that the regression vectors
%            for all columns of Y at 1 latent variable will come first,
%            followed by the regression vectors for all columns of Y at
%            2 latent variables, etc.).
%      ssq = the sum of squares captured (ncomp by 5), with the columns defined
%            as follows:
%            Column 1 = Number of latent variables (LVs),
%            Column 2 = Variance captured (%) in the X-block by this LV,
%            Column 3 = Total variance captured (%) by all LVs up to this row,
%            Column 4 = Variance captured (%) in the X-block by this LV,
%            Column 5 = Total variance captured (%) by all LVs up to this row
%     xlds = X-block loadings (Nx by ncomp).
%     ylds = Y-block loadings (Ny by ncomp).
%      wts = X-block weights  (Nx by ncomp).
%    xscrs = X-block scores   (M  by ncomp).
%    yscrs = Y-block scores   (M  by ncomp).
%      bin = the inner relation coefficients (1 by ncomp).
%   nipwts = X-block weights in the original deflated X format.
%
%I/O: [reg,ssq,xlds,ylds,wts,xscrs,yscrs,bin,nipwts] = nippls(x,y,ncomp,options);
%I/O: nippls demo
%
%See also: ANALYSIS, DSPLS, PLS, PLSNIPAL, SIMPLS

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  options.name    = 'options';
  options.display = 'on';
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

switch nargin
  case 1
    error('Insufficient inputs')
  case 2
    % (x,y)
    varargin{3} = [];
    varargin{4} = [];
  case 3
    % (x,y,ncomp)
    % (x,y,options)
    if isa(varargin{3},'double');
      varargin{4} = [];
    else
      varargin{4} = varargin{3};
      varargin{3} = [];
    end
  case 4
    % (x,y,ncomp,options)
end

%parse out inputs
% x,y,ncomp,options
x       = varargin{1};
y       = varargin{2};
lv      = varargin{3};
options = reconopts(varargin{4},'nippls',0);

if isempty(lv); lv = min(size(x)); end

[m,nx]  = size(x);  %= y.includ{1}
ny      = size(y,2);
if size(y,1)~=m;
  error('Number of y-block rows (samples) must match number in x-block')
end

loads{1,1} = zeros(m,lv);  %X-block scores   't'
loads{1,2} = zeros(m,lv);  %Y-block scores   'u'
loads{2,1} = zeros(nx,lv); %X-block loadings 'p'
loads{2,2} = zeros(ny,lv); %Y-block loadings 'q'
wts        = zeros(nx,lv); %X-block weights  'w'
bin        = zeros(1,lv);  %inner-relation coefficients

ssq     = zeros(lv,2);
ssqx    = sum(sum(x.^2));
ssqy    = sum(sum(y.^2));
olv     = lv;

for i=1:lv
  [pp,qq,ww,tt,uu]                = plsnipal(x,y);
  bin(1,i)           = uu'*tt/(tt'*tt);
  if any(~isfinite(tt(:,1)));
    error('Unable to perform regression - non-finite values');
  end
  rankx = rank([loads{1,1}(:,1:i) tt(:,1)]);
  if rankx<i;
    lv    = rankx;
    switch lower(options.display)
      case {'on',1}
        disp(' ')
        disp(sprintf('Rank of X is %g, which is less than input LVs %g.',lv,olv));
        disp(sprintf('Calculating with %g LVs only.',lv));
    end
    break
  end
  x = x - tt*pp';
  y = y - bin(1,i)*tt*qq';
  ssq(i,1) = (sum(sum(x.^2)))*100/ssqx;
  ssq(i,2) = (sum(sum(y.^2)))*100/ssqy;
  loads{1,1}(:,i)           = tt(:,1); %X-block scores   't'
  loads{1,2}(:,i)           = uu(:,1); %Y-block scores   'u'
  loads{2,1}(:,i)           = pp(:,1); %X-block loadings 'p'
  loads{2,2}(:,i)           = qq(:,1); %Y-block loadings 'q'
  wts(:,i)                  = ww(:,1); %X-block weights  'w'
end
% Calculate weights for use on non-deflated X-block
nipwts = wts;  %save old NIPALS weights
wts = wts*pinv(loads{2,1}'*wts);

ssqdif            = zeros(olv,2);
ssqdif(1,1)       = 100 - ssq(1,1);
ssqdif(1,2)       = 100 - ssq(1,2);
for i=2:lv
  for j=1:2
    ssqdif(i,j)   = -ssq(i,j) + ssq(i-1,j);
  end
end
ssq  = [(1:olv)' ssqdif(:,1) cumsum(ssqdif(:,1))  ssqdif(:,2) cumsum(ssqdif(:,2))];

reg    = zeros(olv*ny,nx);
reg(1:lv*ny,:) = conpred(bin,wts,loads{2,1},loads{2,2},lv);
if ny>1
  for i=2:olv
    j        = (i-1)*ny+1;
    i0       = j-ny;
    reg(j:i*ny,:) = reg(j:i*ny,:) + reg(i0:(i-1)*ny,:);
  end
else
  reg  = cumsum(reg,1);
end

%varargout = {model};
varargout = {reg  ssq  loads{2,1}  loads{2,2}  wts  loads{1,1}  loads{1,2}  bin  nipwts};

if strcmp(options.display,'on');
  ssqtable(ssq);
end

%------------------------------------------------------------
function m = conpred(b,w,p,q,lv)
%CONPRED Converts PLS models to regression vectors
%  Inputs:
%    b  =  the inner-relation coefficients,
%    w  =  the x-block weights,
%    p  =  the x-block loadings,
%    q  =  the y-block loadings, and
%    lv =  the number of latent variables.
%  Output:
%    m  =  a matrix of the contribution of each latent variable
%          to the final regression vector.
%  CONPRED works with either single or multiple variable y-block 
%  PLS models. If there is only 1 y-block variable each row of the
%  output matrix corresponds to the contribution from each lv to the
%  y-block prediction. If there are N y-block variables each block
%  of N rows corresponds to the contribution from each lv to the
%  prediction. See CONPRED1 for obtaining final models.
%
%  The I/O format: m = conpred(b,w,p,q,lv);
%
%  See also: CONPRED1, PLS, PLSPRED

%  Copyright Eigenvector Research 1993-2002
%  Modified BMW 5/94

[mq,nq] = size(q);
[mw,nw] = size(w);
if nw ~= lv
  if lv > nw
    s = sprintf('Original model has a maximum of %g LVs',nw);
    disp('  '), disp(s)
	  s = sprintf('Calculating vectors for %g LVs only',nw);
  	disp(s), disp('  ')
  	lv = nw;
  else
    w = w(:,1:lv);
	  q = q(:,1:lv);
	  p = p(:,1:lv);
	  b = b(:,1:lv);
  end
end
m = zeros(mq*lv,mw);
if mq == 1
  m = (w*inv(p'*w)*diag(b))';
else
  mp = (w*inv(p'*w)*diag(b))';
  for i = 1:lv
    mpp = mp(i,:);
    m((i-1)*mq+1:i*mq,:) = diag(q(:,i))*mpp(ones(mq,1),:);
  end
end
