function sel = spxy(x,y,k)
%SPXY Selects a subset of samples by SPXY algorithm.
% Selected samples should provide uniform coverage of the dataset, which 
% takes into account X and Y data, and include samples on the boundary of 
% the data set. Algorithm is similar to the algorithm in the reference
% below. The distance calculation differs from the reference to remain 
% consistent with how Eigenvector calculates distances in the kennardstone 
% and duplex functions. 
%
%  INPUTS:
%    x = (m,n) array, or dataset, containing data to select k samples from.
%    y = (m,1) array, or dataset, containing data to select k samples from.
%    k = number of samples to select
% OUTPUTS:
%  sel = (1,nsamples) logical vector indicating samples which are selected,
%        true = is selected.  
%        If input x was a dataset then sel has size (1, nincluded)
%        and sel indicates which included samples are selected.
%
% Based on algorithm described in:
% R.K.H Galvao, M.C.U. Araujo, G.E. Jose, M.J.C. Pontes, E.C. Silva, 
% T.C.B. Saldanha (2005): A method for calibration and validation subset 
% partitioning, Talanta 67, 736-740
%
%I/O: sel = spxy(x,y,k)
%
%See also: DISTSLCT, REDUCENNSAMPLES, DOPTIMAL, STDSSLCT, KENNARDSTONE

%Copyright Eigenvector Research 2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; sel = evriio(mfilename,varargin{1},options); end
  return; 
end

if ~isequal(size(x,1), size(y,1))
  evrierrordlg('Unequal number of samples');
  sel = [];
  return
end

if isdataset(x)
  inclx1 = x.include{1};
  inclx2 = x.include{2};
else
  inclx1 = 1:size(x, 1);
  inclx2 = 1:size(x, 2);
end
if isdataset(y)
  incly1 = y.include{1};
  incly2 = y.include{2};
else
  incly1 = 1:size(y, 1);
  incly2 = 1:size(y, 2);
end

incl = intersect(inclx1, incly1);

x = x(incl, inclx2);
y = y(incl, incly2);

if isdataset(x)
  x = x.data;
end

if isdataset(y)
  y = y.data;
end

if ~isnumeric(x)
  error('input x must be numeric');
end

if ~isnumeric(y)
  error('input x must be numeric');
end

nx = size(x,1); % num samples
k = min(k, nx); % k can't be greater than number of samples
sel = false(1,nx);  % the selected samples
if k<1
  return;
end

% Get inter-point distance matrix
distx = sqDistance(x,x);
disty = sqDistance(y,y);

distx = distx./max(distx(:));
disty = disty./max(disty(:));

dist = distx + disty;

[dmin, imin] = max(dist(:));
ix = mod(imin-1, nx) + 1;
iy = floor((imin-1)/nx) + 1;
% so x(ix,:) and y(iy,:) are farthest apart. Pick both as the initial set
isamples = 1:nx;
if k==1
  sel(ix) = true;
  return;
end
sel([ix iy])=true;

% Find the remaining k-2 selected samples
for ii=1:(k-2)
  % Get min distances from non-selected samples to selected samples
  mindist = min(dist(~sel, sel), [], 2); 
  [xmax, ixmax] = max(mindist);
  tmp = isamples(~sel);
  inewsel = tmp(ixmax);
  sel(inewsel) = true;
end

%--------------------------------------------------------------------------
function [D nx ny] = sqDistance(x, y)
% Dij gives distance between x(i,:) and y(j,:)
nx = size(x,1);
ny = size(y,1);
% Either following method uses same memory and processing time
D = sum(x.^2,2)*ones(1,ny) + ones(nx,1)*sum(y.^2,2)' -2*(x*y');
% D = sum(x.^2,2)*ones(1,nx) - (x*x'); D = D + D';
