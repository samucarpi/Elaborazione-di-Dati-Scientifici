function [results] = getSupportedParameters(args)
%GETSUPPORTEDPARAMETERS Create a struct of input options which may have range values. 
% getSupportedParameters creates a new struct containing fields from input 
% struct which are XGB parameters which may have ranges (length > 1) for values.
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
    case {'eta', 'max_depth', 'num_round'}
      results.(fnames{ifld}) = args.(fnames{ifld});
      nparams = nparams+1;
    otherwise
      % unsupported parameter
  end
end
