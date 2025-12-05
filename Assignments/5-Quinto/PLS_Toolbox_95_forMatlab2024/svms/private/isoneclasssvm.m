function [result] = isoneclasssvm(args)
%ISONECLASSSVM Test if args indicate this is one-class svm.
% isclassification returns true if SVM type is one-class svm, false otherwise.
%I/O: out = isclassification(args_struct);

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

result = false;

if isfield(args, 's')
  switch args.s
    case {2}
      result = true;
    case {0, 1, 3, 4}
      result = false;
    otherwise
      %unsupported svm type;
  end
elseif isfield(args, 'svm_type')
  switch args.svmtype
    case {2}
      result = true;
    case {0, 1, 3, 4}
      result = false;
    otherwise
      %unsupported svm type;
  end
elseif isfield(args, 'svmtype')
  switch lower(args.svmtype)
    case {'one-class svm'}
      result = true;
    case {'c-svc', 'nu-svc', 'epsilon-svr', 'nu-svr'}
      result = false;
    otherwise
      %unsupported svm type;
  end
end
