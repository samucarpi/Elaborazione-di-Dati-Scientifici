function [name] = getSvmKernelName(args)
%GETSVMKERNELNAME Returns svm kernel name associated with libsvm '-t' parameter
% getSvmKernelName converts the svm kernel type from the libsvm single char form
% to a descriptive string format. For example, '0' becomes 'linear'.
%
%I/O: out = getSvmKernelName(args); %get the kernel type as a string

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

name = 'unknown SVM kernel type';
% -t kernel_type : set type of kernel function (default 2)
% 	0 -- linear: u'*v
% 	1 -- polynomial: (gamma*u'*v + coef0)^degree
% 	2 -- radial basis function: exp(-gamma*|u-v|^2)
%   3 -- sigmoid: tanh(gamma*u'*v + coef0)


args = convertToLibsvmArgNames(args);
args = convertToLibsvmArgValues(args);
if isfield(args, 't')
  switch args.t
    case 0
      name = 'linear';
%     case 1
%       name = 'polynomial';
    case 2
      name = 'radial basis function';
%     case 3
%       name = 'sigmoid';
    otherwise
      %unsupported svm type;
  end
end
