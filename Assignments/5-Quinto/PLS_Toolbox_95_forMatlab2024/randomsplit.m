function sel = randomsplit(x,k)
%RANDOMSPLIT Randomly selects a subset of samples.
% Selected samples will be randomly selected.
%
%  INPUTS:
%    x = (m,n) array, or dataset, containing data to select k samples from.
%    k = number of samples to select. 
% OUTPUTS:
%  sel = (1,nsamples) logical vector indicating samples which are selected
%        for calibration set, true = is selected.  
%        If input x was a dataset then sel has size (1, nincluded)
%        and sel indicates which included samples are selected.
%
%I/O: selCal = randomsplit(x, k)
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

% Calculate the number of 0s based on the desired percentage
numZeros = nx - k;

% Generate the random vector with the desired percentage of 1s
randomVector = [ones(1, k), zeros(1, numZeros)];

% Shuffle the vector to randomize the order
sel = shuffle(randomVector')';
sel = logical(sel);
