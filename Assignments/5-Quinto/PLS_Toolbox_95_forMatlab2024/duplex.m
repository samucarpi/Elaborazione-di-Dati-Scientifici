function [selCal, selTest] = duplex(x,k)
%DUPLEX Selects a subset of samples by Duplex algorithm.
% Selected samples should provide uniform coverage of the dataset and
% include samples on the boundary of the data set. Duplex starts by
% selecting the two samples furthest from each other and assigns these to
% the calibration set. Then finds the next two samples furthest from each
% other assigns these to the test set. Then iterates over the rest of the
% samples 
%
%  INPUTS:
%    x = (m,n) array, or dataset, containing data to select k samples from.
%    k = number of samples to select. 
% OUTPUTS:
%  selCal = (1,nsamples) logical vector indicating samples which are selected
%        for calibration set, true = is selected.  
%        If input x was a dataset then sel has size (1, nincluded)
%        and sel indicates which included samples are selected.
%  selTest = (1,nsamples) logical vector indicating samples which are selected
%        for test set, true = is selected.  
%        If input x was a dataset then sel has size (1, nincluded)
%        and sel indicates which included samples are selected.
%
% Based on algorithm described in:
% R.D. Snee, Validation of regression models: methods and examples, 
% Technometrics 19 (1977) 415-428
% M. Daszykowski, B. Walczak, D.L. Massart, Representative subset selection,
% Analytica Chimica Acta 468 (2002) 91-103
%
%I/O: [selCal, selTest] = duplex(x, k)
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
  if nargout==0; evriio(mfilename,varargin{1},options); else; selCal = evriio(mfilename,varargin{1},options); end
  return; 
end

if isdataset(x)
  incl = x.include{1};
  x = x.data(incl, :);
end
if ~isnumeric(x)
  error('input x must be numeric');
end

x_orig = x;
nx = size(x,1); % num samples
allInds_ref = 1:nx;
dso_info.inds = allInds_ref';
dso_info.data = x;
kforTest = nx-k;
nxa = floor(0.5*nx);
if kforTest>nxa
    k=nxa;
end
%k = min(k, floor(0.5*nx)); % k can't be greater than number of samples
selCal = false(1,nx);  % the selected cal samples
selTest = false(1,nx);
if k<1
  return;
end

% Get inter-point distance matrix
dist = tril(sqDistance(dso_info.data,dso_info.data));
[ix,iy] = find(dist==max(max(dist)));
% [dmin, imin] = max(dist(:));
% ix = mod(imin-1, nx) + 1;
% iy = floor((imin-1)/nx) + 1;
% so x(ix,:) and y(iy,:) are farthest apart. Pick both as the initial set
isamples = 1:nx;
if k==1
  selCal([ix iy]) = true;
  return;
end
selCal_inds = [ix iy];
selCal(selCal_inds)=true;
% plot(x(sel,1), x(sel,2), 'g.');hold on

% Find next two farthest apart and assign to test set
% dist([ix iy],:) = [];
% dist(:,[ix iy]) = [];
dso_info.data(selCal_inds,:) = [];
dso_info.inds(selCal_inds,:) = [];


dist = tril(sqDistance(dso_info.data,dso_info.data));
[ix,iy] = find(dist==max(max(dist)));
% [dmin, imin] = max(dist(:));
% ix = mod(imin-1, nx) + 1;
% iy = floor((imin-1)/nx) + 1;
selTest_inds = [dso_info.inds(ix) dso_info.inds(iy)];
selTest(selTest_inds) = true;

%remove cal inds and test inds
dso_info.data([ix iy],:) = [];
dso_info.inds([ix iy],:) = [];

while length(selCal_inds) < kforTest
  distToCal = sqDistance(x_orig(selCal_inds,:),dso_info.data);
  [~,w]=max(min(distToCal));
  selCal_inds=[selCal_inds dso_info.inds(w)];
  dso_info.inds(w)=[];
  dso_info.data(w,:) = [];
  distToVal = sqDistance(x_orig(selTest_inds,:),dso_info.data);
  [~,w]=max(min(distToVal));
  selTest_inds=[selTest_inds dso_info.inds(w)];
  dso_info.inds(w)=[];
  dso_info.data(w,:) = [];
end

if ~isempty(dso_info.inds)
    selCal_inds =[selCal_inds dso_info.inds'];
end

selCal(selCal_inds) = true;
selTest(selTest_inds) = true;

%--------------------------------------------------------------------------
function [D nx ny] = sqDistance(x, y)
% Dij gives distance between x(i,:) and y(j,:)
nx = size(x,1);
ny = size(y,1);
% Either following method uses same memory and processing time
D = sum(x.^2,2)*ones(1,ny) + ones(nx,1)*sum(y.^2,2)' -2*(x*y');
% D = sum(x.^2,2)*ones(1,nx) - (x*x'); D = D + D';
