function x = pr_entropy(x,a,sumflag)
%PR_ENTROPY pattern recognition entropy (PRE), Shannon entropy, transform.
%  For input(x) PR_ENTROPY calculates the pattern recognition entropy (PRE)
%  on the ROWS of (x). If (x) is MxN with a row given by x(i,:) i=1,...,M
%  then the output (ax) is PRE calculated as
%    ax = -p'.*log2(p); where p = normaliz(abs(x(i,:)),[],1) with 0<p<=1
%  if optional input (a) is included then
%                             p = normaliz(abs(x(i,:))+a,[],1)
%  to avoid taking log of <=0.
%  Note: PR_ENTROPY was originally intended for use with non-negative data.
%    The PR_ENTROPY function includes abs(x) to allow negative data to be used,
%    however input (a) is included to avoid problems when (x) is small.
%
%  See: TG Avval, B Moeini, V Carver, N Fairley, EF Smith, J Baltrusaitis,
%       V Fernandez, BJ Tyler, N Gallagher, MR Linford, "The Often-Overlooked
%       Power of Summary Statistics in Exploratory Data Analysis: Comparison of
%       Pattern Recognition Entropy (PRE) to Other Summary Statistics and
%       Introduction of Divided Spectrum-PRE (DS-PRE)," J. Chem. Inf. Model.,
%       2021, 61, 4173−4189. DOI: 10.1021/acs.jcim.1c00244
%
%   INPUT:
%      x = MxN matrix to transform (class double or DataSet).
%          If (x) is a DataSet object then the calculation uses
%          x(:,x.include{2}).
%
%   OPTIONAL INPUTS:
%      a = scalar offset {default: a = eps}.
%     sf = [{false} | true] sum flag 
%
%   OUTPUT:
%     ax = MxN PRE values for each row of (x).
%          Mx1 summed |PRE| values across each row of (x).
%
%I/O: ax = pr_entropy(x,a,sf);
%I/O: pr_entropy demo
%
%See also: AUTO, ASINHX, ASINSQRT

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<2 || isempty(a)
  a       = eps; 
end
if nargin<3 || isempty(sumflag)
  sumflag = false; 
end

% run test on x to ensure this works ok, try/catch to be graceful
if isdataset(x)
  wasdso  = true;
else
  x       = dataset(x);
end
if ~isa(x.data,'double')
  x.data  = double(x.data);
end

% Calculate for include{2}
m         = size(x);
[x.data(:,x.include{2}),xn]  = normaliz(abs(x.data(:,x.include{2}))+a,[],1);
x.data(:,x.include{2})    = -x.data(:,x.include{2}).*log2(x.data(:,x.include{2}));
% Calculate for ~include{2}
if length(x.include{2})~=m(2) && ~sumflag
  i2      = setdiff(1:m,x.include{2});
  x.data(:,i2)  = 0;
end

if sumflag
  x.data(:,1)   = sum(abs(x.data(:,x.include{2})),2);
  x       = x(:,1);
  x.label{2}    = 'PRE';
end