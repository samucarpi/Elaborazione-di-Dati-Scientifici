function [z,d,options]= wsmooth(y,options)
%WSMOOTH Whittaker smoother.
%  For a row vector (y), W_Smooth finds (z) that is a smoothed estimate of
%  (y) by minimizing the objective function O(z)
%    O(z) = (y-z)*W0*(y-z)' + lambda*z*Ds*Ws*Ds'*z' (1).
%  The matix (Ds) is a first difference or second derivative {default}
%  operator used to penalize roughness (Ds can be modified using input
%  options.smooth).
%  W0 and Ws are NxN diagonal matrices with entries (0<=w<=1) used to weight
%  channels. For example, entries in W0 set to 0 are not used in the least-
%  squares fit, and entries in Ws set to 0 are not used to estimate the
%  roughness penalty. For more information on the Whittaker smoother see
%  P.H.C. Eilers, "A Perfect Smoother," Anal. Chem. 2003, 75, 3631-3636.
%
%  The solution to (1) is
%    z = y*d
%  where (d) is the "smoother" operator.
%
%  INPUT:
%    y = MxN matrix of ROW vectors to be smoothed.
%        Input (y) can also be a DataSet object, which allows more
%        flexibility in handling excluded columns.
%
%  OPTIONAL INPUT:
%    options = structure array with the following fields:
%      lambda: {0.1} smoothness penalty (scalar>0).
%          w0: {[]} 1xN vector with entries 0<=w0<=1 used to weight
%                   channels used to estimate (z).
%          ws: {[]} 1xN vector with entries 0<=ws<=1 used to weight
%                   channels used to estimate the roughness penalty.
%      smooth: used to govern details of developing Ds {=savgol{options)}.
%              see SAVGOL for details on options.smoothXXX.
%      smoothwidth: {3} window width for Ds.
%      smoothorder: {2} polynomial order for Ds.
%      smoothderiv: {2} derivative for Ds.
%
%  OUTPUTS:
%          z = MxN matrix of smoothed (and differentiated) ROW vectors.
%          d = NxN "smoother" such that z = y*d .
%    options = input (options) but some fields may have been modified.
%
%I/O: [z,d,options] = wsmooth(y,options);
%I/O: wsmooth demo
%
%See also: POLYINTERP, SAVGOL, STDFIR, WLSBASELINE

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%NBG

%Excluded data can easily be handled by setting corresponding terms in
%WO = 0. However, if the data have randomly missing points, then the W0 is
%expected to be different for each row of y - this is expected to be slow.
%So, maybe there's a trick (nbg)

% Would like to have options.lambda = 'auto' as an option. Not yet there.

% May want better checking to avoid ill-conditioning

if nargin == 0; y = 'io'; end
if ischar(y);
  options        = [];
  options.smooth = savgol('options');
  options.smooth.tails = 'weighted';
  options.smoothwidth = 3;
  options.smoothorder = 2;
  options.smoothderiv = 2;
  
  options.lambda = 0.1;
  options.w0     = [];
  options.ws     = [];
  options.useexcluded = false;

  if nargout==0; clear z; evriio(mfilename,y,options); else z = evriio(mfilename,y,options); end
  return;
end

if nargin<2;
  options = [];
end
options = reconopts(options,mfilename);

if options.lambda<0 | isempty(options.lambda)
  error('The penalty options.lambda must be a non-negative scalar.')
end

[m,n] = size(y);
if isempty(options.w0);
  options.w0  = ones(1,n);
end
if isempty(options.ws);
  options.ws  = ones(1,n);
end

if isdataset(y)
  wasdso = true;
else
  wasdso = false;
  y      = dataset(y);
end
if ~isa(y.data,'double')
  y.data = double(y.data);
end
if ~options.useexcluded
  options.w0(setdiff(1:n,y.include{2})) = 0;
end
options.ws(options.w0==0) = 0.01*options.ws(options.w0==0);
options.ws(options.ws==0) = 0.01*max(options.ws);

[tmp,ds] = savgol(1:n,options.smoothwidth,options.smoothorder, ...
                  options.smoothderiv,options.smooth);
d    = sparse(1:n,1:n,options.w0,n,n);
d    = d/(d + options.lambda*ds*sparse(1:n,1:n,options.ws,n,n)*ds'); %Replace w/ chol for speed

if wasdso
  z = y;
  z.data  = y.data*d;
else
  z  = y.data*d;
end
