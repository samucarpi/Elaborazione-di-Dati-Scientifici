function s1 = convertToSvmStringNames(s)
%CONVERTTOSVMSTRINGNAMES convert arguments to svm expected form (e.g. c -> cost)
% Users may use abbreviated argument name or the full name, case insensitively.
% For example, 'c', 'C' are mapped to 'cost'.
%
% The following are the equivalencies:
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
% %I/O: options = convertToSvmStringNames(options); Convert argumnent names

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

s1 = struct;
ckeys = fieldnames(s);
for i = 1:size(ckeys,1)
  ckey0 = char(ckeys(i,:));
  ckey = lower(ckey0);
  switch ckey
    case {'s', 'svmtype'}
      newkey = 'svmtype';
    case {'t', 'kerneltype'}
      newkey = 'kerneltype';
    case {'d', 'degree'}
      newkey = 'degree';
    case {'g', 'gamma'}
      newkey = 'gamma';
    case {'r', 'coef0'}
      newkey = 'coef0';
    case {'c', 'cost'}
      newkey = 'cost';
    case {'n', 'nu'}
      newkey = 'nu';
    case {'p', 'epsilon'}
      newkey = 'epsilon';
    case {'m', 'cachesize'}
      newkey = 'cachesize';
    case {'e', 'terminationepsilon'}
      newkey = 'terminationepsilon';
    case {'h', 'shrinking'}
      newkey = 'shrinking';
    case {'b', 'probabilityestimates'}
      newkey = 'probabilityestimates';
    case {'w', 'weight'}
      newkey = 'weight';
    case {'v', 'splits'}      % Do n-fold CV
      newkey = 'splits';
    case {'q', 'quiet', 'display'}
      newkey = 'display';
    case {'x', 'cvtimelimit'}       % Limit for libsvm run when in CV (sec)
      newkey = 'cvtimelimit';
    otherwise
      newkey = ckey;  % is an unmodified key
  end
  s1.(newkey) = s.(ckey0);
end
