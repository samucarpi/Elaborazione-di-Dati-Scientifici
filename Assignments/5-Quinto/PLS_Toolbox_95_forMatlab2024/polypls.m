function [p,q,w,t,u,b,ssq] = polypls(x,y,lv,n,options)
%POLYPLS PLS regression with polynomial inner-relation.
% Calculates a polynomal PLS model which uses a polynomial as an
% inner-relation between the scores of the X and Y blocks. This is used for
% loosely non-linear models. See POLYPRED to make predictions with new
% data.
%
% INPUTS:
%      x = matrix of predictor variables
%      y = vector or matrix of the predicted variable
%     lv = maximum number of latent variables to consider
%      n = order of polynomial to use for the inner-relation
%  
% OPTIONAL INPUTS:
%  options = an options structure with one or more of the following fields:
%        display: [ 'off' | {'on'} ] governs display of SSQ table
%
% OUTPUTS:
%      p = x-block loadings 
%      q = y-block loadings 
%      w = x-block weights
%      t = x-block scores 
%      u = y-block scores 
%      b = matrix of inner-relation coefficients 
%    ssq = table of variance explained per component. 
%
%I/O: [p,q,w,t,u,b,ssq] = polypls(x,y,lv,n,options);
%
%See also: LWR, LWRPRED, LWRXY, PLS, POLYPRED

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified BMW 11/93
%Checked on MATLAB 5 by BMW

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  options.display = 'on';
  if nargout==0; clear p; evriio(mfilename,varargin{1},options); else; p = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<5
  options = [];
end
options = reconopts(options,mfilename);

[mx,nx] = size(x);
[my,ny] = size(y);
p = zeros(nx,lv);
q = zeros(ny,lv);
w = zeros(nx,lv);
t = zeros(mx,lv);
u = zeros(my,lv);
b = zeros(n+1,lv);
ssq = zeros(lv,2);
ssqx = sum(sum(x.^2)');
ssqy = sum(sum(y.^2)');
for i = 1:lv
  [pp,qq,ww,tt,uu] = plsnipal(x,y);
  b(:,i) = (polyfit(tt,uu,n))';
  x = x - tt*pp';
  y = y - (polyval(b(:,i),tt))*qq';
  ssq(i,1) = (sum(sum(x.^2)'))*100/ssqx;
  ssq(i,2) = (sum(sum(y.^2)'))*100/ssqy;
  t(:,i) = tt(:,1);
  u(:,i) = uu(:,1);
  p(:,i) = pp(:,1);
  w(:,i) = ww(:,1);
  q(:,i) = qq(:,1);
end
ssqdif = zeros(lv,2);
ssqdif(1,1) = 100 - ssq(1,1);
ssqdif(1,2) = 100 - ssq(1,2);
for i = 2:lv
  for j = 1:2
    ssqdif(i,j) = -ssq(i,j) + ssq(i-1,j);
  end
end

ssq = [(1:lv)' ssqdif(:,1) cumsum(ssqdif(:,1)) ssqdif(:,2) cumsum(ssqdif(:,2))];
if strcmpi(options.display,'on');
  disp('  ')
  disp('     Percent Variance Captured by PolyPLS Model   ')
  disp('  ')
  disp('           -----X-Block-----    -----Y-Block-----')
  disp('   LV #    This LV    Total     This LV    Total ')
  disp('   ----    -------   -------    -------   -------')
  format = '   %3.0f     %6.2f    %6.2f     %6.2f    %6.2f';
  for i = 1:lv
    tab = sprintf(format,ssq(i,:)); disp(tab)
  end
  disp('  ')
end
