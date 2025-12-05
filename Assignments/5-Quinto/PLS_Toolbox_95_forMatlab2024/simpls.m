function varargout = simpls(varargin);
%SIMPLS Partial Least Squares computational engine using SIMPLS algorithm.
%  Performs PLS regression using SIMPLS algorithm.
%  INPUTS:
%        x = X-block (predictor block) class "double", and
%        y = Y-block (predicted block) class "double".
%
%  OPTIONAL INPUTS:
%    ncomp = the number of latent variables to be calculated (positive
%            integer scalar {default = rank of X-block}, and
%  options = structure array with the fields:
%      display: [ 'off' |{'on'}]  governs display to command window
%     ranktest: [ 'none' | 'data' | 'scores' | {'auto'} ] governs type of
%               rank test to perform.
%               'data' = single test on X-block (faster with smaller data blocks
%               and more components), 'scores' = test during regression on scores
%               matrix (faster with larger data matricies), 'auto' = auto
%               selection, or 'none' = assume sufficient rank.
%
%  OUTPUTS:
%      reg = matrix of regression vectors,
%      ssq = the sum of squares captured,
%     xlds = X-block loadings,
%     ylds = Y-block loadings,
%      wts = X-block weights,
%    xscrs = X-block scores,
%    yscrs = Y-block scores,
%    basis = the basis of X-block loadings.
%
%  Note: The regression matrices are ordered in reg such that each
%  ny (number of Y-block variables) rows correspond to the regression
%  matrix for that particular number of latent variables.
%
%  NOTE: in previous versions of SIMPLS, the X-block scores were
%  unit length and the X-block loadings contained the variance.
%  As of Version 3.0, this algorithm now uses standard convention
%  in which the X-block scores contain the variance.
%
%I/O: [reg,ssq,xlds,ylds,wts,xscrs,yscrs,basis] = simpls(x,y,ncomp,options);
%I/O: simpls demo
%
%See also: DSPLS, NIPPLS, PCR, PLS, PLSNIPAL

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% 5/20/03 JMS change of help (removed dataset references)
% 6/3/03 JMS added additional rank test on weights magnitude
% 7/1/03 JMS test for invalid SSQ table (>100%)
% 10/7/03 JMS fix all negative weights/rank test bug (anticorrelation)
% 08/18/10 BMW added reorthogonalization step

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  options.name    = 'options';
  options.display = 'on';
  options.ranktest = 'auto';
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
    % (x,y,ncomp,xtx)     v2
    % (x,y,ncomp,options)
    if ~isa(varargin{4},'struct');
      % (x,y,ncomp,xtx)     v2
      if ~isempty(varargin{4}); warning('EVRI:SimplsXTXInvalid','The use of X''X (XTX) is no longer permitted - analyzing without using supplied matrix'); end
      varargin{4} = [];
    end
  case 5
    % (x,y,maxlv,xtx,out)  v2
    if ~isempty(varargin{4}); warning('EVRI:SimplsXTXInvalid','The use of X''X (XTX) is no longer permitted - analyzing without using supplied matrix'); end
    varargin{4} = [];
    if varargin{5}
      varargin{4}.display = 'on';
    else
      varargin{4}.display = 'off';
    end
    varargin = varargin(1:4);
end

%parse out inputs
% x,y,ncomp,options
x       = varargin{1};
y       = varargin{2};
lv      = varargin{3};
options = reconopts(varargin{4},'simpls',0);

if isempty(lv); lv = min(size(x)); end

[m,nx]  = size(x);  %= y.includ{1}
ny      = size(y,2);
if size(y,1)~=m;
  error('Number of y-block rows (samples) must match number in x-block')
end

xscrs = zeros(m,lv);  %X-block scores   't'
yscrs = zeros(m,lv);  %Y-block scores   'u'
xlds = zeros(nx,lv); %X-block loadings 'p'
ylds = zeros(ny,lv); %Y-block loadings 'q'
wts  = zeros(nx,lv); %X-block weights  'w'
basis = zeros(nx,lv); %basis vectors

ssq     = zeros(lv,2);
ssqx    = sum(sum(x.^2));
ssqy    = sum(sum(y.^2));
olv     = lv;

if ssqx==0; ssqx = inf; end  %fix zero variance error (don't divide by zero, make %captured zero)

if strcmp(options.ranktest,'auto');
  if ( nx > (3.7*lv - 2) );  %which rank-test method will be faster?
    options.ranktest = 'scores';
  else
    options.ranktest = 'data';
  end
end

if strcmp(options.ranktest,'data');
  lv = min(lv,rank(x));
else
  options.inloopranktest = 0;
end

s = x'*y;

for i = 1:lv
  if ny > 1
    [eve,eva] = eig(s'*s);
    [meva,ind] = max(diag(eva));
    qq = eve(:,ind);
    rr = s*qq;
  else
    qq = 1;
    rr = s;
  end

  %initial test for rank deficiency
  if all(all(abs(rr/m)<eps));  %loadings < eps? we're rank deficient
    lv = i-1;
    
    switch lower(options.display)
      case {'on',1}
        disp(' ')
        disp(sprintf('Effective rank is %g, which is less than input LVs %g.',lv,olv));
        disp(sprintf('Calculating with %g LVs only. Low-variance Sum of Squares may be incorrect.',lv));
    end
    
    break           %and break out of LV calc loop
  end
  
  %calc loads and scores for this component
  tt = x*rr;
  % Reorthogonalization step
  if i > 1
    tt = tt - xscrs(:,1:i-1)*((tt'*xscrs(:,1:i-1))');
  end
  normtt = norm(tt);
  tt = tt/normtt;
  rr = rr/normtt;
  pp = (tt'*x)';
  
  if any(~isfinite(tt(:,1)));
    error('Unable to perform regression - non-finite values');
  end
  
  %Additional test for rank deficiency (if told to do this)
  if i>1 & strcmp(options.ranktest,'scores');
    ranktest = [xscrs(:,1:i-1) tt(:,1)];
    rankx = rank(ranktest'*ranktest);
    if rankx<i  %this score matches another!! We've become rank deficient!
      
      lv = i-1;
      
      switch lower(options.display)
        case {'on',1}
          disp(' ')
          disp(sprintf('Rank of X is %g, which is less than input LVs %g.',lv,olv));
          disp(sprintf('Calculating with %g LVs only.',lv));
      end
      
      break           %and break out of LV calc loop
    end
  end
  
  qq = y'*tt;
  uu = y*qq;
  vv = pp;
  if i > 1
    vv = vv - basis*(basis'*pp);
    uu = uu - xscrs*(uu'*xscrs)';
  end
  vv = vv/norm(vv);
  s = s - vv*(vv'*s);
  wts(:,i)   = rr;           %r  x-block weights
  xscrs(:,i) = tt;           %t  x-block scores
  xlds(:,i)  = pp;           %p  x-block loadings
  ylds(:,i)  = qq;           %q  y-block loadings
  yscrs(:,i) = uu;           %u  y-block scores
  basis(:,i) = vv;           %v  basis of x-loadings
  
end

if ny == 1
  if size(wts,2) ~= 1
    reg = cumsum((wts*diag(ylds))');
  else
    reg = (wts*ylds)';
  end
else
  reg = zeros(ny*olv,nx);
  reg(1:ny,:) = ylds(:,1)*wts(:,1)';
  for i = 2:olv
    reg((i-1)*ny+1:i*ny,:) = ylds(:,i)*wts(:,i)' + reg((i-2)*ny+1:(i-1)*ny,:);
  end
end

ssq = [diag(xlds'*xlds)/ssqx ...
    diag(ylds'*ylds)/ssqy]*100;

ssq = [(1:olv)' ssq(:,1) cumsum(ssq(:,1)) ssq(:,2) ...
    cumsum(ssq(:,2))];

%test for >100% captured components (invalidate all beyond that point)
bad = min([find(ssq(:,3)>(100+eps*200));find(ssq(:,5)>(100+eps*200))]);
if ~isempty(bad) & bad>1;
  ssq(bad:end,2) = 0;
  ssq(bad:end,3) = ssq(bad-1,3);
  ssq(bad:end,4) = 0;
  ssq(bad:end,5) = ssq(bad-1,5);
end

for i=1:lv
  nrm = norm(xlds(:,i));
  xscrs(:,i) = xscrs(:,i).*nrm;
  wts(:,i) = wts(:,i).*nrm;  % Added so wts create correct scores 8/29/09
  xlds(:,i) = xlds(:,i)./nrm;
end

varargout = {reg  ssq  xlds  ylds  wts xscrs  yscrs  basis};

if strcmp(options.display,'on');
  ssqtable(ssq);
end
