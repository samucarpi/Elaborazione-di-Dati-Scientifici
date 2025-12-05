function ypred = lwrxy(xnew,xold,yold,lvs,npts,alpha,iter,out)
%LWRXY Predictions based on lwr models with y-distance weighting.
%
% WARNING: This function is depreciated and may be removed in future
% versions of PLS_Toolbox. Y-distance weighting should be accessed via the
% 'alpha' option of LWRPRED.
%
%  This function makes new sample predictions (ypred) for a new
%  matrix of independent variables (xnew) based on an existing 
%  data set of independent (xold) variables and vector of dependent
%  (yold) variables. Predictions are made using a locally weighted
%  regression model defined by the number principal components
%  used to model the independent variables (lvs), the number of
%  points defined as local (npts), the weighting given to the
%  distance in y (alpha), and the number of iterations to use (iter).
%  Optional input (out) suppresses printing of the results when
%  set to 0 {default = 1}.
%
%Note:  Be sure to use the same scaling on new and old samples!
%
%I/O:  ypred = lwrxy(xnew,xold,yold,lvs,npts,alpha,iter,out);
%
%See also: LWRPRED, PLS, POLYPLS

% Copyright © Eigenvector Research, Inc. 1994
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%bmw
%nbg 11/00 added out
%bmw 8/02 allowed for Dataset object input, waitbar

if nargin == 0; xnew = 'io'; end
varargin{1} = xnew;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; ypred = evriio(mfilename,varargin{1},options); end
  return; 
end

warning('EVRI:Depreciated','LWRXY is depreciated. Y-distance weighting should be accessed via the .alpha option of LWRPRED.')

opts = [];
opts.alpha = alpha;
opts.iter = iter;
if nargin<8  %nbg 11/00
  out = 1;
end
if out
  opts.display = 'on';
else
  opts.display = 'off';
end
opts.preprocessing = {1 2};  %default to match ver3.5.0
ypred = lwrpred(xnew,xold,yold,lvs,npts,opts);

return

%======================================
%old code below

if isa(xnew,'dataset')
  inds = xnew.includ;
  xnew = xnew.data(inds{:});
end
if isa(xold,'dataset')
  inds = xold.includ;
  xold = xold.data(inds{:});
end
if isa(yold,'dataset')
  inds = yold.includ;
  yold = yold.data(inds{:});
end

if nargin<8  %nbg 11/00
  out = 1;
end
if lvs > npts
  error('npts must >= lvs')
end
[m,n] = size(xnew);
[mold,nold] = size(xold);
if n ~= nold
  disp('xnew and xold must have the same number of columns')
  error('if xnew and/or xold is Dataset Object, check includ')
end
[my,ny] = size(yold);
if my ~= mold
  disp('xold and yold must have the same number of rows')
  error('if xold and/or yold is Dataset Object, check includ')
end 

[axold,mxold] = mncn(xold);
[ayold,myold,stdyold] = auto(yold);
if n < m
  cov = (axold'*axold)/(mold-1);
  [u,s,v] = svd(cov,0);
else
  cov = (axold*axold')/(mold-1);
  [u,s,v] = svd(cov,0);
  v = axold'*v;
  for i = 1:m
    v(:,i) = v(:,i)/norm(v(:,i));
  end
end
u = axold*v(:,1:lvs);
[au,umx,ustd] = auto(u(:,1:lvs));
sxnew = scale(xnew,mxold);
newu = scale(sxnew*v(:,1:lvs),umx,ustd);
ureg = zeros(npts,lvs);
yreg = zeros(npts,1);
weights = zeros(npts,1);
r = u(:,1:lvs)\ayold;
bpcr = (v(:,1:lvs)*r)';
ypred = sxnew*bpcr';
%clc     nbg 11/00
hh = waitbar(0,'Please wait while LWRXY completes predictions');
for i = 1:m;
  waitbar(i/m,hh)
  for k = 1:iter
    xdist = sum(((au-ones(mold,lvs)*diag(newu(i,:))).^2)',1)';
    ydist = (ayold-ones(mold,1)*ypred(i,1)).^2;
	  dists = (1-alpha)*xdist + alpha*ydist;
    [a,b] = sort(dists);
    for j = 1:npts
      ureg(j,:) = au(b(j,1),:);
      yreg(j,:) = ayold(b(j,1),1);
      scldist = a(j,1)/a(npts,1);
      weights(j,:) = (1 - scldist^3)^3;
    end
    h = diag(weights.^2);
    ureg1 = [ureg ones(npts,1)];
    breg = inv(ureg1'*h*ureg1)*ureg1'*h*yreg;
    ypred(i,1) = [newu(i,:) 1]*breg;
  end
end
close(hh)
ypred = rescale(ypred,myold,stdyold);
