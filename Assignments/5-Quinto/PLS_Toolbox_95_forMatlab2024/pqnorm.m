function [sx,beta,xref] = pqnorm(x,xref,options)
%PQNORM Probabilistic Quotient Normalization for rows of a matrix.
% A robust normalization method similar to Multiplicative Scatter
% Correction but using the median as the target and a robust fitting of
% each row to the target.
%
% PQN is equivalent to performing a 1-norm on the rows of X, followed by a
% robust MSC (algorithm = median, see MSCORR).
%
% INPUTS:
%    x  = matrix of data to normalize (double)
%
% OPTIONAL INPUTS:
%    xref = reference spectrum to normalize to (used for applying
%           previously calculated normalization target to new data)
%
% OUTPUTS:
%      sx = corrected spectra
%    beta = the multiplicative scatter factor/slope
%    xref = the reference spectrum used
%
%I/O: [sx,beta,xref] = pqnorm(x)
%I/O: [sx,beta,xref] = pqnorm(x,xref)
%
%See also: MSCORR, NORMALIZ, SNV

%Copyright Eigenvector Research, Inc. 2015
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  if nargout==0; evriio(mfilename,x,options); else sx = evriio(mfilename,x,options); end
  return;
end

if nargin<2
  xref = [];
end
if nargin<3
  options = [];
end
%TODO: enable next line if options support is needed later
%options = reconopts(options,mfilename);

[sx,norms] = normaliz(x,0,1);
[sx,alpha,beta,xref] = mscorr(sx,xref,0,[],struct('algorithm','median'));
beta = beta.*norms;
