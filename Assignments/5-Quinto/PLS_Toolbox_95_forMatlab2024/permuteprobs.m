function table = permuteprobs(results,nlv)
%PERMUTEPROBS Display probabilities derived from permutation testing.
% Displays or returns the probability of model insignificance as determined
% from permutation testing. Inputs are the permutation testing results
% (results) and the number of latent variables (nlv) for which statistics
% should be displayed. If no outputs are given, the table is displayed at
% the command line, otherwise, the table is returned as a cell array of
% strings.
%
%I/O: table = permuteprobs(results,nlv)
%
%See also: PERMUTEPLOT, PERMUTETEST

%Copyright © Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

if nargin<2
  nlv = 1;
end
maxlv = size(results.rmsec,1);
nlv = min(maxlv,max(1,nlv));
ny = length(results.rmsy);

desc = {'Probability of Model Insignificance vs. Permuted Samples'};
if maxlv>1
  desc{end+1,1} = sprintf('For model with %i component(s)',nlv);
end
for yi = 1:ny;
  probsc = [results.cprob.wilcoxon(nlv,yi)  results.cprob.signtest(nlv,yi)  results.cprob.randomttest(nlv,yi)];
  probscv = [results.cvprob.wilcoxon(nlv,yi)  results.cvprob.signtest(nlv,yi)  results.cvprob.randomttest(nlv,yi)];
  desc = [desc;
    sprintf('_________________________________');
    sprintf('Y-column:  %i',yi);
    sprintf('                  Wilcoxon     Sign Test     Rand t-test');
    sprintf('Self-Prediction:   %0.3f        %0.3f          %0.3f',probsc);
    sprintf('Cross-Validated:   %0.3f        %0.3f          %0.3f',probscv);
    ];
end
desc{end+1,1} = ' ';
desc{end+1,1} = 'Values less than 0.05 indicate the model is';
desc{end+1,1} = 'significant at the 95% confidence level.';

if nargout==0
  disp(char(desc));
else
  table = desc;
end
