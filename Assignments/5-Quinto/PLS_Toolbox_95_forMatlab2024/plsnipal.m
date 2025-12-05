function [p,q,w,t,u] = plsnipal(x,y)
%PLSNIPAL NIPALS algorithm for one PLS latent variable.
%  This program does the nipals algorithm for PLS
%  It is generally run as a subprogram of PLS, since it
%  calculates only one latent variable.
%
%I/O: [p,q,w,t,u] = plsnipal(x,y);
%
%See also: ANALYSIS, DSPLS, NIPPLS, PLS, SIMPLS

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified BMW 11/93
%Modified RB 04/98 to handle missing
%Modified JMS 02/02 to speed missing checks

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; p = evriio(mfilename,varargin{1},options); end
  return;
end

[my,ny] = size(y);
[mx,nx] = size(x);

% Check for missing data
MissingDataX = 0;
if ~isfinite(mean(mean(x)));
  MissingDataX = 1;
  nomisX=sparse(isfinite(x));
end

MissingDataY = 0;
if ~isfinite(mean(mean(y)));
  MissingDataY = 1;
  nomisY=sparse(isfinite(y));
end

if ny > 1
  if MissingDataY
    u = missmean(y')';
  else
    ssy = sum(y.^2);
    [ymax,yi] = max(ssy);
    u = y(:,yi);
  end

else
  u = y(:,1);
end
conv = 1;
told = x(:,1);
count = 1.0;
%  Specify the conversion tolerance
while conv > 1e-10
  count = count + 1;

  % Calculate w
  if MissingDataX
    for j = 1:nx
      id = find(nomisX(:,j));
      w(j) = (u(id)'*x(id,j))'/(u(id)'*u(id));
    end
  else
    w = (u'*x)';
  end
  w = (w'/norm(w'))';
  w=w(:);

  % Calculate t
  if MissingDataX
    for i = 1:mx
      id = find(nomisX(i,:));
      t(i) = (x(i,id)*w(id))/(w(id)'*w(id));
    end
  else
    t = x*w;
  end
  t = t(:);

  if ny == 1
    q = 1;
    break
  end

  % Calculate q
  if MissingDataY
    for j = 1:ny
      id = find(nomisY(:,j));
      q(j) = (t(id)'*y(id,j))'/(t(id)'*t(id));
    end
  else
    q = (t'*y)';
  end
  q = (q'/norm(q'))';
  q = q(:);

  % Calculate u
  if MissingDataY
    for i = 1:my
      id = find(nomisY(i,:));
      u(i) = (y(i,id)*q(id))/(q(id)'*q(id));
    end
  else
    u = y*q;
  end
  u = u(:);

  conv = norm(told - t);
  told = t;
  if count >= 50.0
    disp('Algorithm Failed to Converge after 50 Iterations')
    break;
  end
end

% Calculate p
if MissingDataX
  for j = 1:nx
    id = find(nomisX(:,j));
    p(j) = (t(id)'*x(id,j))'/(t(id)'*t(id));
  end
else
  p = (t'*x/(t'*t))';
end
p = p(:);

p_norm=norm(p);
t = t*p_norm;
w = w*p_norm;
p = p/p_norm;
