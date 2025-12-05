function [result] = isclassification(args)
%ISCLASSIFICATION Test if args invoke classification type SVM analysis.
% isclassification returns true if SVM type is classification, false otherwise.
% Returns true if svm type = 'c-svc' or 'nu-svc' 
% Returns false otherwise (e.g. 'epsilon-svr', 'nu-svr' or 'one-class svm')
%I/O: out = isclassification(args_struct);

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

result = false;

if isfield(args, 's')
  switch args.s
    case {0, 1}
      result = true;
    case {3, 4}
      result = false;
    otherwise
      %unsupported svm type;
  end
elseif isfield(args, 'svm_type')
  switch args.svmtype
    case {0, 1}
      result = true;
    case {3, 4}
      result = false;
    otherwise
      %unsupported svm type;
  end
elseif isfield(args, 'svmtype')
  switch lower(args.svmtype)
    case {'c-svc', 'nu-svc'}
      result = true;
    case {'epsilon-svr', 'nu-svr'}
      result = false;
    otherwise
      %unsupported svm type;
  end
end
