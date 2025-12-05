function [result] = svmTrain(x, y, args)
%svmTrain Support Vector Machine for classification or regression.
%  svmTrain uses the LIBSVM package to train an SVM model
%  or return cross validation accuracy based on training data
%
%  INPUTS:
%       x   = X-block (predictor block) class "double"
%       y   = Y-block (predicted block) class "double" is avector of length m
%             indicating sample class or target value.
%    args   = Arguments to LIBSVM's svm_train method in a struct form.
%        -s svm_type : set type of SVM (default 0)
%           0 -- C-SVC
%           1 -- nu-SVC
%           2 -- one-class SVM
%           3 -- epsilon-SVR
%           4 -- nu-SVR
%        -t kernel_type : set type of kernel function (default 2)
%           0 -- linear: u'*v
%           1 -- polynomial: (gamma*u'*v + coef0)^degree
%           2 -- radial basis function: exp(-gamma*|u-v|^2)
%           3 -- sigmoid: tanh(gamma*u'*v + coef0)
%           4 -- precomputed kernel (kernel values in training_set_file)
%        -d degree : set degree in kernel function (default 3)
%        -g gamma : set gamma in kernel function (default 1/k)
%        -r coef0 : set coef0 in kernel function (default 0)
%        -c cost : set the parameter C of C-SVC, epsilon-SVR,
%             and nu-SVR (default 1)
%        -n nu : set the parameter nu of nu-SVC, one-class SVM, and nu-SVR (default 0.5)
%        -p epsilon : set the epsilon in loss function of epsilon-SVR (default 0.1)
%        -m cachesize : set cache memory size in MB (default 100)
%        -e epsilon : set tolerance of termination criterion (default 0.001)
%        -h shrinking : whether to use the shrinking heuristics, 0 or 1 (default 1)
%        -b probability_estimates : whether to train a SVC or SVR model for probability
%             estimates, 0 or 1 (default 0)
%        -wi weight : set the parameter C of class i to weight*C, for C-SVC (default 1)
%        -v n : n-fold cross validation mode
%        -q : quiet mode (no outputs)
%
%  OUTPUT:
%  LIBSVM model if not run in cross-validation mode
%  cross validation accuracy (%) (classification SVM) or RMSECV (regression
%  SVM) if run in cross-validation mode
%
% %I/O: model = svmTrain(x, y, options); Use calibration x data to build model

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


tr = libsvm.evri.SvmTrain2;

% Argument validation step (e.g. c>0)
validateArgs(args);

% Remove v argument if it is zero
if isfield(args,'v')
  if args.v==0;
    args = rmfield(args,'v');  %make SURE v is removed if not optimization call (v=0 means no optimization)
  end
end

% convert args struct to cell array suitable for libsvm
newargs = libsvmArgs(args);
try
  result = tr.apply(newargs, y, x);
catch
  s = lasterror;
  if strfind(s.message, 'SvmTimer.isTimerExpired: Time exceeds') > 0
    msg = 'ERROR: SVM time limit exceeded. Please rerun the analysis after increasing the value of option ''cvtimelimit''';
    error(msg);
  elseif strfind(s.message, 'java.lang.OutOfMemoryError:') > 0
    msg = 'ERROR: SVM memory limit exceeded. Please reduce dataset size (check http://www.eigenvector.com/faq/ for ''out of memory'')';
    if strfind(s.message, 'java.lang.OutOfMemoryError: GC overhead limit exceeded') > 0
      msg = 'ERROR: SVM memory limit exceeded (GC overhead limit exceeded). Please reduce dataset size or increase Java Heap size (See http://www.eigenvector.com/faq/index.php?id=136)';
    end
    error(msg);
  end
end

if isfield(args, 'v')   %tr.isCrossValidation
  if args.s==0 | args.s==1 % therefore is classification
    result = tr.getCvMisclassification;
  elseif args.s==2 % therefore is one-class svm
    result = tr.getCvMisclassification;
  elseif args.s==3 | args.s==4 % therefore is regression
    result = sqrt(tr.getCvMSE);   %take square root to get RMSECV
  end
end


%-----------------------------------------------------------------
function validateArgs(args)
% First check that kerneltype ('t') is not polynomial or sigmoid (1 or 3)
if isfield(args, 't')
  if args.t==1 | args.t==3
    error('Sorry, this kernel is not currently supported (t=%i)',args.t);
  end
end

% create a Java svm_parameter and initialize with args fields
svmParameter = args2svm_parameter(args);

% Argument validation step (e.g. c>0)
try
  validation_result = libsvm.evri.Helper.svm_check_parameter(svmParameter);
catch
  z = lasterror;
  z.message = [ 'svmTrain error: ' z.message];
  rethrow(z)
end
if ~isempty(validation_result)
  % throw error
  message = ['Invalid libsvm argument passed to svmTrain: ' char(validation_result)];
  error('evri:svmTrain:invalidArg', message);
end

%-----------------------------------------------------------------
function svmParameter = args2svm_parameter(args)
%%%--------------------
svmParameter = libsvm.svm_parameter;
% initialize the svm_parameter:
pnames = fieldnames(args);
for ifn=1:length(pnames);
  try
    pname = pnames{ifn};
    z = args.(pnames{ifn});
    switch pname
      case {'s'}
        newkey = 'svm_type';
      case {'t'}
        newkey = 'kernel_type';
      case {'d'}
        newkey = 'degree';
      case {'g'}
        newkey = 'gamma';
      case {'r'}
        newkey = 'coef0';
      case {'c'}
        newkey = 'C';
      case {'n'}
        newkey = 'nu';
      case {'p'}
        newkey = 'p';  % for EPSILON_SVR
      case {'m'}
        newkey = 'cache_size';
      case {'e'}
        newkey = 'eps';  % stopping criteria
      case {'h'}
        newkey = 'shrinking';
      case {'b'}
        newkey = 'probability';
      otherwise
        newkey = '';
    end
    if length(newkey)>0
      val = args.(pnames{ifn});
      if ischar(val);
        val = str2double(val);
      end
      svmParameter.(newkey) = val;
    end
    
  catch
    disp(['Skipping parameter fieldname ' z])
  end
end

