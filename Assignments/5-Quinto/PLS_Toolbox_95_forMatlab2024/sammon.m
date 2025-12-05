function p = sammon(x, p, options)
%SAMMON Computes Sammon projection for data or map.
% The algorithm maps points from a higher dimensional space to a lower
% dimensional space in such a way as to preserve the relative interpoint 
% distances.
%
%INPUTS:
%  x             = (matrix or dataset) data to be projected
%  ncolout OR p  = (ncolout: scalar) number of output dimensions in the
%                   Sammon projections, or (p: matrix) the initial
%                   projection matrix, size nrow by ncolout.
%OPTIONAL INPUTS:
%  options = options structure with one or more of the following fields:
%  niterations: number of iterations performed.
%   maxseconds: Maximum number of seconds allowed. Overrides niterations.
%        alpha: [0.2] Sammon's "magic factor"
%            D: (matrix) Intersample Euclidean distance, size nrow x nrow.
%        plots: [ 'none' | {'final'} ]  governs level of plotting.
%      display: [ 'on' | {'off'} ]      governs level of display to command window.
%  maxsamples : [ 2000 ] Maximum number of samples for which Sammon
%                projection will be calculated for. If an array or dataset
%                has more than this number of samples, the Sammon 
%                projections will be returned as all NaN's. This is because 
%                the algorithm can be quite slow with many samples.
%
%
%OUTPUTS:
%  p        (matrix or dataset) projected coordinates of each data point.
%            Dimension >= 2
%
%Note that in the original paper, the term "y" is used for the projections.
%In this function, the projections are referred to as "p" to avoid
%confusion with regression functions.
%
% Based on algorithm described in:
% Sammon JW (1969): A nonlinear mapping for data structure analysis,
% IEEE Transactions on Computers 18: 401–409.
%
% EXAMPLES
% p = sammon(x,2)
%  projects the vectors in x (n-dim) to 2-dimensional space.
%
%I/O: p = sammon(x, ncolout, options)
%I/O: p = sammon(x, p, options)
%
% See also: PCA

%Copyright Eigenvector Research 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  options.niterations   = 100;
  options.maxseconds    = 60;
  options.alpha         = 0.2;
  options.D             = [];
  options.display       = 'off';     %Displays output to the command window
  options.plots         = 'none';  %Governs plots to make
  options.maxsamples    = 2000;
  if nargout==0; evriio(mfilename,varargin{1},options); else; p = evriio(mfilename,varargin{1},options); end
  return;
end

if nargin<3;
  options = [];
end
options = reconopts(options,mfilename);

class1 = [];
isdso = false;
if numel(p)==1,
  ncolout = p;
else
  ncolout = size(p,2);
end
if isdataset(x)
  isdso = true;
  pout = nan(size(x,1), ncolout);  % prepare data array for output dso
  dsoout = dataset(pout);
  dsoout = copydsfields(x, dsoout, 1);
  ylabels = str2cell(sprintf('Sammon proj. %i\n',1:ncolout),1)';
  dsoout.label{2} = ylabels;
  incl   = x.include{1};
  if ~isempty(x.class{1})
    class1 = x.class{1};
    class1 = class1(incl);
  end
  x      = x.data(incl, :);
end
if ~isnumeric(x)
  error('input x must be numeric');
end
if mdcheck(x)
  error('Input data has missing values. Cannot perform Sammon mapping')
end

% compute data dimensions
[nrow, ncol] = size(x);

if nrow>options.maxsamples
  %if more than this number of samples, do NOT do distance, return NaN's
  %for all
  if isdso
    p = dsoout;
  else
    p = nan(nrow, ncolout);
  end
  return
end

if ncolout>ncol
  ncolout = ncol;
  if isdso
    dsoout = dsoout(:,1:ncolout);
  end
end

% output dimension / initial projection matrix
if numel(p)==1,
  p = randn(nrow,ncolout);
else
  if size(p,1) ~= nrow
    error('Initial projection row size does not match input data');
  end
  inds = find(isnan(p));
  if ~isempty(inds)
    p(inds) = rand(size(inds));
  end
end

if ncol < 2 | nrow<2
  error('Sammon requires at least two variables to operate');
end
if nrow<2
  error('Sammon requires at least two samples to operate');
end


% Initialize
maxseconds = options.maxseconds;
niterations = options.niterations;
alpha   = options.alpha;
D   = options.D;
nrow_x_1  = ones(nrow, 1);
ncolout_x_1 = ones(1,ncolout);

% compute mutual distances between vectors
if isempty(D) | isnan(D)
  D = euclideandist(x,x);
else
  if size(D) ~= [nrow nrow],
    error('Interrow difference matrix size does not match input dimension');
  end
end

% Sammon iteration
i         = 0;
ready     = 0;
ytmp      = zeros(nrow, ncolout);
starttime = tic;
while ~ready
  dp = euclideandist(p,p); % interrowdiffs(p);
  dpm3 = dp.^(-3);
  for j = 1:nrow,
    xd      = -p + p(j*nrow_x_1,:); % repmat(p(j,:), nrow, 1);  is SLOWER
    dq      = D(:,j) - dp(:,j);
    dr      = D(:,j) .* dp(:,j);
    ind     = find(dr ~= 0);
    term    = dq(ind) ./ dr(ind);
    e1     = term' * xd(ind,:);
    e2      = sum(term)*ncolout_x_1 - dpm3(ind,j)'*(xd(ind,:).^2);
    ytmp(j,:) = p(j,:) + alpha * e1 ./ abs(e2);
  end
  % mean center
  c = sum(ytmp) / nrow;
  p = ytmp - c(nrow_x_1, :);
  
  if mod(i,10)==0 & strcmp(options.display,'on')
    % Mapping error
    E = maperror(p, D);
    disp(sprintf('Mapping error, E(%d) = %d, alpha = %4.4g', i, E, alpha))
  end
  
  i = i + 1;
  if i >= niterations
    ready = 1;
  end;
  
  %time limit
  elapsedtime = toc(starttime);
  if elapsedtime > maxseconds
    if strcmp(options.display,'on')
      disp(sprintf('Terminating after elapsed time exceeds maxseconds limit'))
    end
    ready = 1;
  end;
end

if strcmp(options.plots,'final')
  plot(p, class1, i);
end

if isdso
  dsoout.data(incl,:) = p;
  p = dsoout;
end

%--------------------------------------------------------------------------
function E = maperror(p, D)
% Get mapping error
nrow = size(p,1);
Dinv  = 1./D;
d     = euclideandist(p,p) + eye(nrow);
delta = D - d;
delta(isinf(delta))=0;
Dinv(isinf(Dinv))=0;
E     = 0.5*sum(sum((delta.^2).*Dinv));

%--------------------------------------------------------------------------
function plot(p, class1, i)
% View Sammon's projection plotted (in 2-D and 3-D case)
cmap  = colormap;
trimc = round(0.1*size(cmap,1));
colormap(cmap(trimc:(end-trimc),:));
targfig = gcf;
figure(targfig);
clf
if size(p,2) == 2,
  %       plot(p(:,1), p(:,2), 'o');
  % nclass = unique(class1);
  if ~isempty(class1)
    col = class1(:);
  else
    col = ones(size(p,1),1);
  end
  colormap(cmap(trimc:(end-trimc),:));
  scatter(p(:,1), p(:,2),30, col,'filled')
else
  plot3(p(:,1), p(:,2), p(:,3), 'o')
end
title(sprintf('Sammon Mapping. Iteration %d',i))
drawnow

%--------------------------------------------------------------------------
% Strange that simplifying this for x=p does not give any speedup
function d = euclideandist(x,p)
d = sqrt(abs(sum(x.^2,2)*ones(1,size(p,1))+ones(size(x,1),1)*sum(p.^2,2)'-2*(x*p')));

