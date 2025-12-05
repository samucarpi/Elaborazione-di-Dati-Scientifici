function varargout = dspls(varargin);
%DSPLS Partial Least Squares computational engine using Direct Scores algorithm.
%  Performs PLS regression using Direct Scores PLS algorithm as described
%  in Andersson, "A comparison of nine PLS1 algorithms", J. Chemometrics,
%  (www.interscience.wiley.com) DOI: 10.1002/cem.1248
%
%  This modified SIMPLS algorithm provides improved numerical stability for
%  high numbers of latent variables.
%
%  INPUTS:
%        x = X-block (predictor block) class "double", and
%        y = Y-block (predicted block) class "double".
%
%  OPTIONAL INPUTS:
%    ncomp = the number of latent variables to be calculated (positive
%            integer scalar {default = rank of X-block}, and
%  options = structure array with the fields:
%      display: [ 'off' |{'on'}]  governs display to command window
%     ranktest: [ 'none' | 'data' | 'loadings' | {'auto'} ] governs type of
%               rank test to perform.
%               'data' = single test on X-block (faster with smaller data blocks
%               and more components), 'loadings' = test during regression on loadings
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
%    yscrs = Y-block scores,   (Currently returns empty)
%    basis = the basis of X-block loadings.
%
%  Note: The regression matrices are ordered in reg such that each
%  ny (number of Y-block variables) rows correspond to the regression
%  matrix for that particular number of latent variables.
%
%I/O: [reg,ssq,xlds,ylds,wts,xscrs,yscrs,basis] = dspls(x,y,ncomp,options);
%I/O: dspls demo
%
%See also: NIPPLS, PCR, PLS, PLSNIPAL, SIMPLS

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

% 10/06/08 BMW

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
end

%parse out inputs
% x,y,ncomp,options
x       = varargin{1};
y       = varargin{2};
lv      = varargin{3};
options = reconopts(varargin{4},'dspls');

[mx,nx]  = size(x); 
[my,ny]  = size(y);
if mx~=my;
  error('Number of y-block rows (samples) must match number in x-block')
elseif ny > 1
  %error('This function currently works with only 1 y-variable')
end

if isempty(lv); 
  lv = min([mx nx]); 
end

W = zeros(nx,lv);    %X-block weights    'W'
U = zeros(mx,lv);    %X-block scores     'U'
P = zeros(nx,lv);    %X-block loadings   'P'
q = zeros(ny,lv);    %Y-block loadings   'q'
R = zeros(nx,lv);    %basis vectors      'R'
b = zeros(lv*ny,nx);    %Regression vectors 'b'

ssq     = zeros(lv,2);
ssqx    = sum(sum(x.^2));
ssqy    = sum(sum(y.^2));
olv     = lv;

if ssqx==0; ssqx = inf; end  %fix zero variance error (don't divide by zero, make %captured zero)

if strcmp(options.ranktest,'auto');
  if ( nx > (3.7*lv - 2) );  %which rank-test method will be faster?
    options.ranktest = 'loadings';
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
if ny > 1
  [eve,eva] = eig(s'*s);
  [meva,ind] = max(diag(eva));
  qq = eve(:,ind);
  U(:,1) = x*s*qq;
  unorm = norm(U(:,1));
  U(:,1) = U(:,1)/unorm;
  R(:,1) = s*qq/unorm;
else
  U(:,1) = x*s;
  unorm = norm(U(:,1));
  U(:,1) = U(:,1)/unorm;
  R(:,1) = s/unorm;
end
P(:,1) = x'*U(:,1);
q(:,1) = y'*U(:,1);
b(1:ny,:) = q(:,1)*R(:,1)';
for i = 2:lv
  s = s-P(:,i-1)*q(:,i-1)';
  if ny > 1
    [eve,eva] = eig(s'*s);
    [meva,ind] = max(diag(eva));
    qq = eve(:,ind);
    R(:,i) = s*qq - R(:,1:i-1)*(P(:,1:i-1)'*s*qq);
  else
    R(:,i) = s - R(:,1:i-1)*(P(:,1:i-1)'*s);
  end

  %initial test for rank deficiency
  if all(all(abs(R(:,i)/mx)<eps));  %loadings < eps? we're rank deficient
    lv = i-1;
    
    R(:,i) = 0;
    
    switch lower(options.display)
      case {'on',1}
        disp(' ')
        disp(sprintf('Effective rank is %g, which is less than input LVs %g.',lv,olv));
        disp(sprintf('Calculating with %g LVs only. Low-variance Sum of Squares may be incorrect.',lv));
    end
    
    break           %and break out of LV calc loop
  end

  U(:,i) = x*R(:,i);
  unorm = norm(U(:,i));
  U(:,i) = U(:,i)/unorm;
  R(:,i) = R(:,i)/unorm;
  P(:,i) = x'*U(:,i);
  q(:,i) = y'*U(:,i);
  b((i-1)*ny+1:i*ny,:) = q(:,1:i)*R(:,1:i)';

  if any(~isfinite(U(:,i)));
    error('Unable to perform regression - non-finite values');
  end
  
  %Additional test for rank deficiency (if told to do this)
  if strcmp(options.ranktest,'loadings');
    rankx = rank(P'*P);
    if rankx<i  %this score matches another!! We've become rank deficient!
      
      lv = i-1;
      
      P(:,i) = 0;
      q(:,i) = 0;
      R(:,i) = 0;
      U(:,i) = 0;
      b((i-1)*ny+1:i*ny,:) = 0;
      
      switch lower(options.display)
        case {'on',1}
          disp(' ')
          disp(sprintf('Rank of X is %g, which is less than input LVs %g.',lv,olv));
          disp(sprintf('Calculating with %g LVs only.',lv));
      end
      
      break           %and break out of LV calc loop
    end
  end

end

  
ssq = [diag(P'*P)/ssqx diag(q'*q)/ssqy]*100;

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
  nrm = norm(P(:,i));
  U(:,i) = U(:,i).*nrm;
  W(:,i) = R(:,i).*nrm;
  P(:,i) = P(:,i)./nrm;
end

for i=lv+1:(size(b,1)/ny)
  %if we didn't make it out to the requested # of LVs, replicate the last
  %set of regression vectors out to the end
  b((i-1)*ny+1:i*ny,:) = b((lv-1)*ny+1:lv*ny,:);
end

varargout = {b  ssq  P  q  W U  []  R};

if strcmp(options.display,'on');
  ssqtable(ssq);
end



%varargout = {b U R P q};  
  

