function sel = kennardstone(x,k)
%KENNARDSTONE Selects a subset of samples by Kennard-Stone algorithm.
% Selected samples should provide uniform coverage of the dataset and
% include samples on the boundary of the data set.
%
%  INPUTS:
%    x = (m,n) array, or dataset, containing data to select k samples from.
%    k = number of samples to select
% OUTPUTS:
%  sel = (1,nsamples) logical vector indicating samples which are selected,
%        true = is selected.  
%        If input x was a dataset then sel has size (1, nincluded)
%        and sel indicates which included samples are selected.
%
% Based on algorithm described in:
% R. W. Kennard & L. A. Stone (1969): Computer Aided Design of Experiments,
% Technometrics, 11:1, 137-148
%
%I/O: sel = kennardstone(x, k)
%
%See also: DISTSLCT, REDUCENNSAMPLES, DOPTIMAL, STDSSLCT

%Copyright Eigenvector Research 2008
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

if isdataset(x)
  incl = x.include{1};
  x = x.data(incl, :);
end
if ~isnumeric(x)
  error('input x must be numeric');
end

nx = size(x,1); % num samples
k = min(k, nx); % k can't be greater than number of samples
sel = false(1,nx);  % the selected samples
if k<1
  return;
end

% Get inter-point distance matrix
dist = sqDistance(x,x);
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
% plot(x(sel,1), x(sel,2), 'g.');hold on

% Find the remaining k-2 selected samples
for ii=1:(k-2)
  % Get min distances from non-selected samples to selected samples
  mindist = min(dist(~sel, sel), [], 2); 
  [xmax, ixmax] = max(mindist);
  tmp = isamples(~sel);
  inewsel = tmp(ixmax);
  sel(inewsel) = true;
  % plot(x(inewsel,1), x(inewsel,2), 'r.');hold on
end

%--------------------------------------------------------------------------
function [D nx ny] = sqDistance(x, y)
% Dij gives distance between x(i,:) and y(j,:)
nx = size(x,1);
ny = size(y,1);
% Either following method uses same memory and processing time
D = sum(x.^2,2)*ones(1,ny) + ones(nx,1)*sum(y.^2,2)' -2*(x*y');
% D = sum(x.^2,2)*ones(1,nx) - (x*x'); D = D + D';
