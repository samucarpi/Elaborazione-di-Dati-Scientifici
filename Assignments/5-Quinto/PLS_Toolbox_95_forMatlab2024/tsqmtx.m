function [tsqmat,tsqs] = tsqmtx(varargin)
%TSQMTX Calculates matrix for T^2 contributions for PCA.
%  Inputs are a data matrix (x) and a PCA model (model) in a
%  standard model struture. (x) can be class "double" or "dataset".
%  TSQMTX extracts the loads (p), (ssq) and preprocessing from (model).
%
%  Inputs are a data matrix (x), PCA loadings (p), and variance table
%  (ssq). Note: For this I/O the data matrix (x) must be scaled
%  in a similar manner to the data used to determine the loadings (p).
%
%  TSQMTX calculates Hotelling's T^2 (tsqs) and the matrix for individual
%  variable contributions to Hotelling's T^2 (tsqmat).
%
%Algorithm: If (s) is the covariance matrix and (x) is scaled then
%     tsqmat = x*p*sqrt(inv(s))*p';
%
%I/O: [tsqmat,tsqs] = tsqmtx(x,model);
%I/O: [tsqmat,tsqs] = tsqmtx(x,p,ssq);
%I/O: tsqmtx demo
%
%See also: DATAHAT, PCA, PCR, PLS, TSQQMTX

%Copyright Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified: NBG 10/96,7/97
%nbg 8/02 modified to use 3.0 model structures and DataSet
%nbg 7/06 modified to set flag='no' if p not a model structure
%nbg 1/08 modified to allow MPCA models (other minor code changes)

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  if nargout==0; clear tsqmat; evriio(mfilename,varargin{1},options); else tsqmat = evriio(mfilename,varargin{1},options); end
  return;
end

[tsqmat,tsqs] = tconcalc(varargin{:});
