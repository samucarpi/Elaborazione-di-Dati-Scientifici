function args = removeExtraSvmParams(args);
%REMOVEEXTRASVMPARAMS Remove parameters which are not appropriate for the svm type 
% or the kernel type
%
% %I/O: out = removeExtraSvmParams(options); Remove options inappropriate for the svm type.
%
%See also: 

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

args = removeExtraSvmtypeParams(args);
args = removeExtraKernelParams(args);

function args = removeExtraSvmtypeParams(args)
%REMOVEEXTRASVMTYPEPARAMS Remove parameters which are not appropriate for the svm type
% removeExtraSvmParams removes svm parameters which are not relevant to the
% specified svm type. Thus, for example, svm type '0' does not use 'nu' or
% 'epsilon' parameters so these would be removed from the input struct.
%
%   0 -- C-SVC           % remove nu, epsilon
%   1 -- nu-SVC          % remove cost, epsilon
%   2 -- one-class SVM   % remove cost, epsilon
%   3 -- epsilon-SVR     % remove nu
%   4 -- nu-SVR          % remove epsilon
%
% %I/O: out = removeExtraSvmtypeParams(options); Remove inappropriate options
% for the svm type.
%
%See also: 

% handle both full and single-char libsvm arg names
if isfield(args, 'svmtype')
  svmtype = lower(args.svmtype);
  switch svmtype
    case 'c-svc'
      if isfield(args, 'nu')
        args = rmfield(args,'nu');
      end
      if isfield(args, 'epsilon')
        args = rmfield(args,'epsilon');
      end
    case 'nu-svc'
      if isfield(args, 'cost')
        args = rmfield(args,'cost');
      end
      if isfield(args, 'epsilon')
        args = rmfield(args,'epsilon');
      end
    case 'one-class svm'
      if isfield(args, 'cost')
        args = rmfield(args,'cost');
      end
      if isfield(args, 'epsilon')
        args = rmfield(args,'epsilon');
      end
    case 'epsilon-svr'
      if isfield(args, 'nu')
        args = rmfield(args,'nu');
      end
    case 'nu-svr'
      if isfield(args, 'epsilon')
        args = rmfield(args,'epsilon');
      end
  end
elseif isfield(args, 's')
  svmtype = args.s;
  switch svmtype
    case 0
      if isfield(args, 'n')
        args = rmfield(args,'n');
      end
      if isfield(args, 'p')
        args = rmfield(args,'p');
      end
    case {1 2}
      if isfield(args, 'c')
        args = rmfield(args,'c');
      end
      if isfield(args, 'p')
        args = rmfield(args,'p');
      end
    case 3
      if isfield(args, 'n')
        args = rmfield(args,'n');
      end
    case 4
      if isfield(args, 'p')
        args = rmfield(args,'p');
      end
  end
end
  
function args = removeExtraKernelParams(args)
%REMOVEEXTRAKERNELPARAMS Remove parameters which are not appropriate for the kernel type
% removeExtraKernelParams removes parameters which are not relevant to the
% specified svm kernel type. 
% Kernel parameters are gamma (g), degree (d), and coef0 (r)
% Thus, for example, kernel type '0' (linear) does not use 
% 'gamma' parameters so this would be removed from the input struct.
%
%   0 -- linear                 % remove gamma, degree, and coef0 (g, d, r)
%   1 -- polynomial             % remove none
%   2 -- radial basis function  % remove degree and coef0 (d, r)
%   3 -- sigmoid                % remove degree (d)
%   4 -- precomputed kernel     % not supported
%
% %I/O: out = removeExtraSvmtypeParams(options); Remove inappropriate options
% for the svm type.
%
%See also: 

% handle both full and single-char libsvm arg names
if isfield(args, 'kerneltype')
  kerneltype = lower(args.kerneltype);
  switch kerneltype
    case 'linear'   %  0 -- linear: u'*v
      if isfield(args, 'gamma')
        args = rmfield(args,'gamma');
      end
      if isfield(args, 'degree')
        args = rmfield(args,'degree');
      end
      if isfield(args, 'coef0')
        args = rmfield(args,'coef0');
      end
    case 'polynomial'   %  1 -- polynomial: (gamma*u'*v + coef0)^degree
      % remove nothing
    case 'rbf'        %  2 -- radial basis function: exp(-gamma*|u-v|^2)
      if isfield(args, 'degree')
        args = rmfield(args,'degree');
      end
      if isfield(args, 'coef0')
        args = rmfield(args,'coef0');
      end
    case 'sigmoid'    %  3 -- sigmoid: tanh(gamma*u'*v + coef0)
      if isfield(args, 'degree')
        args = rmfield(args,'degree');
      end
  end
elseif isfield(args, 't')
  kerneltype = args.t;
  switch kerneltype
    case 0      %  0 -- linear: u'*v
      if isfield(args, 'g')
        args = rmfield(args,'g');
      end
      if isfield(args, 'd')
        args = rmfield(args,'d');
      end
      if isfield(args, 'r')
        args = rmfield(args,'r');
      end
    case 1            %  1 -- polynomial: (gamma*u'*v + coef0)^degree
      % remove nothing
    case 2            %  2 -- radial basis function: exp(-gamma*|u-v|^2)
      if isfield(args, 'd')
        args = rmfield(args,'d');
      end
      if isfield(args, 'r')
        args = rmfield(args,'r');
      end
    case 3            %  3 -- sigmoid: tanh(gamma*u'*v + coef0)
      if isfield(args, 'd')
        args = rmfield(args,'d');
      end
  end
end



