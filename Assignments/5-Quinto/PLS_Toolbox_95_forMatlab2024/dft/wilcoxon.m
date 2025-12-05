function prob = wilcoxon(err_1,err_2)
%WILCOXON Pairwise Wilcoxon signed rank test for evaluating residuals from two models.
% Pairwise comparison between two sets of model residuals using the sign
% and magnitude of residuals from two models. Output is the probability
% that model 2 (the model producing the second set of residuals) is better
% than model 1 (the model that produces the first set of residuals).
%
% INPUTS:
%   err_1 = Prediction errors from model #1
%   err_2 = Prediction errors from model #2
%
% OUTPUTS:
%   prob  = Prob{# of times model#2 wins <=k} Probability that model#2 is
%           better than model#1.
%
% Adapted from: Edward V. Thomas, "Non-parametric statistical methods for
% multivariate calibration model selection and comparison", J. Chemometrics
% 2003; 17: 653–659. Published online in Wiley InterScience
% (www.interscience.wiley.com). DOI: 10.1002/cem.833
%
%I/O: prob = wilcoxon(err_1,err_2)
%
%See also: CROSSVAL, RANDOMTTEST, SIGNTEST

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%
% Note that original code is available in the public domain at:
% J. Chemometrics 2003; 17: 653–659. DOI: 10.1002/cem.833

if nargin==0
  err_1 = 'io';
end
if ischar(err_1)
  options = [];
  if nargout==0; evriio(mfilename,err_1,options); else; prob = evriio(mfilename,err_1,options); end
  return
end

[n,dum] = size(err_1);
del     = abs(err_1)-abs(err_2);
sdel    = sign(del);
adel    = abs(del);

%sort absolute deviations to get sorted signed ranks
[a,s]   = sort(adel);
d       = (1:n)*sdel(s);

t  = n*(n+1)/2;
v  = (t-d)/2;
ev = t/2;
sv = sqrt(n*(n+1)*(2*n+1)/24);
z  = (v-ev)/sv;

prob = 1-normdf('c',z);

