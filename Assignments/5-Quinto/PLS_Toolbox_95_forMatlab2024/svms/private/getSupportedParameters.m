function [results] = getSupportedParameters(args)
%GETSUPPORTEDPARAMETERS Create a struct of input options which may have range values. 
% getSupportedParameters creates a new struct containing fields from input 
% struct which are SVM parameters which may have ranges (length > 1) for values.
% Support use of either the full or single-char arg names, e.g. c or cost.
%
% %I/O: out = getSupportedParameters(in); New struct of options supporting range values

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

fnames = fieldnames(args);
results = struct;
nparams = 0;
for ifld=1:length(fnames)
  switch fnames{ifld}
    case {'c', 'p','g', 'n'}
      results.(fnames{ifld}) = args.(fnames{ifld});
      nparams = nparams+1;
    case {'cost', 'epsilon','gamma', 'nu'}
      results.(fnames{ifld}) = args.(fnames{ifld});
      nparams = nparams+1;
    otherwise
      % unsupported parameter
  end
end
