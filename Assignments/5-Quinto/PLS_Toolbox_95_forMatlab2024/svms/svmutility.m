function varargout = svmutility(varargin)
%SVMUTILITY Utility function for SVM models.
% Provides access to various SVM utilties:
%
%I/O: out = svmUtility('getSupportVectors',model); 
% 'getSvmTypeName' Returns svm type name associated with libsvm '-s'
% parameter 
%
%I/O: name = svmUtility('getSvmKernelName',args);
% 'getSvmKernelName' Returns svm kernel name associated with libsvm '-t'
% parameter 
%
%I/O: options = svmUtility('convertToSvmStringNames',options);
% 'convertToSvmStringNames' convert arguments to svm expected form (e.g.
% c -> cost)
%
%See also: SVMENGINE, SVM

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  error('Utility name must be supplied')
end
if nargout==0
  varargout{1} = feval(varargin{:});
else
  [varargout{1:nargout}] = feval(varargin{:});
end

function dummyfunction
%Dummy function which is never called but is necessary to get compiler to
% pick up these function files from the smvs/private folder
getSupportVectors;
getSvmKernelName;
convertToSvmStringNames;
