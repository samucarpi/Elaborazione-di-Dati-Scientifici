function prob = signtest(err_1,err_2)
%SIGNTEST Pairwise sign test for evaluating residuals from two models.
% Pairwise comparison between two sets of model residuals using the signs
% of the residuals. Output is the probability that model 2 (the model
% producing the second set of residuals) is better than model 1 (the model
% that produces the first set of residuals).
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
%I/O: prob = signtest(err_1,err_2)
%
%See also: CROSSVAL, RANDOMTTEST, WILCOXON

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

n = numel(err_1);
delta = abs(err_1(:))-abs(err_2(:));
s = sum(sign(delta));
k = (n+s)/2;

prob = 1-binomial(.5,n,k+1);

%---------------------------------------------------------------
function [prob]=binomial(x,n,k);
%
% This function computes the exact probability that there are
% at least k Successes in n Bernoulli Trials
% Method uses incomplete Beta function
% INPUT: x=Underlying Probability of Success
% n=Number of trials
% k=Number of successes
% OUTPUT: prob=probability
%
a=k;
b=n-k+1;
if x==0;
  prob=0;
else
  if k==0;
    prob=1;
  else;
    if k==n;
      prob=x^n;
    else
      prob=betainc(x,a,b);
    end;
  end;
end;
