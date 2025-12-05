function prob = randomttest(err_1,err_2,iter)
%RANDOMTTEST Randomization t-test for evaluating residuals from two models.
% Pairwise comparison between two sets of model residuals using a
% randomization of the sign of the differences. Output is the probability
% that the two sets of residuals are not different.
%
% Based on the publication:
%   Hilko van der Voet "Comparing the predictive accuracy of models using a
%   simple randomization test", Chemometrics and Intelligent Laboratory
%   Systems 25 (1994) 313-323.
%
% INPUTS:
%   err_1 = Prediction errors from model #1
%   err_2 = Prediction errors from model #2
% OPTIONAL INPUTS:
%   iter  = Number of iterations to perform. Default = 199.
% OUTPUTS:
%   prob  = Probability that residuals (and thus models) are not
%           significantly different. 
%
%I/O: prob = randomttest(err_1,err_2,iter)
%
%See also: CROSSVAL, SIGNTEST, WILCOXON

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin==0
  err_1 = 'io';
end
if ischar(err_1)
  options = [];
  if nargout==0; evriio(mfilename,err_1,options); else; prob = evriio(mfilename,err_1,options); end
  return
end

if nargin<3
  iter = 199;
end

diff     = (err_1(:).^2-err_2(:).^2)';  %vectorize and get differences
meandiff = abs(mean(diff));             %get mean difference
n        = length(diff);

%randomize signs and count # abs means greater than the actual abs mean
randomsign     = 2*(rand(n,iter)>.5)-1;         %generate random signs for all iterations
meansigneddiff = abs(diff*randomsign/n);        %apply signs and get mean
prob         = (sum(meansigneddiff>=meandiff)+1)./(iter+1); %count means > original mean

%original code from paper looked basically like the code below. The new
%version, above, is MUCH faster.

% diff = err_1.^2-err_2.^2;
% meandiff = abs(mean(diff));
% n        = length(diff);
% 
% sm= 0;
% for k = 1: iter
%   randomsign = 2*round(rand(n,1))-1;
%   signeddiff = randomsign.*diff;
%   meansigneddiff = mean(signeddiff);
%   sm = sm+(abs(meansigneddiff)>=meandiff);
% end
% prob=(sm+1)/(iter+1);

