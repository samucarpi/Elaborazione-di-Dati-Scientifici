function [name] = getSvmTypeName(args)
%GETSVMTYPENAME Returns svm type name associated with libsvm '-s' parameter
% getSvmTypeName converts the svm type from the libsvm single char form
% to a descriptive string format. For example, '0' becomes 'C-SVC'.
%
%I/O: name = getSvmTypeName(args);

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

name = 'unknown SVM type';

% ensure
args = convertToLibsvmArgNames(args);
args = convertToLibsvmArgValues(args);
if isfield(args, 's')
  switch args.s
    case 0
      name = 'C-SVC';
    case 1
      name = 'nu-SVC';
    case 2
      name = 'one-class SVM';
    case 3
      name = 'epsilon-SVR';
    case 4
      name = 'nu-SVR';
    otherwise
      %unsupported svm type;
  end
end
