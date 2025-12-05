function sout = convertToLibsvmArgNames(s)
%CONVERTTOLIBSVMARGNAMES convert arguments to libsvm expected form (e.g. Cost -> c)
% Users may use abbreviated argument name or the full name, case insensitively.
% For example, 'c', 'C', 'Cost', 'cost', 'COST' are mapped to 'c'.
%
% Arguments to LIBSVM's svm_train method in a struct form can have the
% following field names, case insensitively:
%    s svmtype
%    t kerneltype
%    d degree
%    g gamma
%    r coef0
%    c cost
%    n nu
%    p epsilon
%    m cachesize cache
%    e terminationepsilon
%    h shrinking
%    b probabilityestimates
%    w weight
%    v cv splits
%    q quiet
%
% %I/O: out = convertToLibsvmArgNames(in); Convert argumnent names

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

ckeys = fieldnames(s);
ckeyslower = lower(ckeys);
for i = 1:size(ckeys,1)
  switch ckeyslower{i}
    case {'svmtype', 'svm_type'}
      newkey = 's';
    case {'kerneltype', 'kernel_type'}
      newkey = 't';
    case {'degree'}
      newkey = 'd';
    case {'gamma'}
      newkey = 'g';
    case {'coef0'}
      newkey = 'r';
    case {'cost'}
      newkey = 'c';
    case {'nu'}
      newkey = 'n';
    case {'epsilon'}
      newkey = 'p';
    case {'cachesize'}
      newkey = 'm';
    case {'terminationepsilon'}
      newkey = 'e';
    case {'shrinking'}
      newkey = 'h';
    case {'probabilityestimates'}
      newkey = 'b';
    case {'weight'}
      newkey = 'w';
    case {'splits'}      % Do n-fold CV
      newkey = 'v';
    case {'quiet'}
      newkey = 'q';
    case {'cvtimelimit'}       % Limit for libsvm run when in CV (sec)
      newkey = 'x';
    otherwise
      newkey = ckeys{i};
  end
  sout.(newkey) = s.(ckeys{i});
end
