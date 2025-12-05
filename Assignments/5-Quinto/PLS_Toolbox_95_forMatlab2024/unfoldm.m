function [xmpca] = unfoldm(xaug,nsamp);
%UNFOLDM Rearranges (unfolds) an augmented matrix to row vectors.
%  UNFOLDM unfolds the input matrix (xaug) to create a
%  matrix of unfolded row vectors (xmpca) for MPCA. This operation is
%  typically used when several individual batch matrices have been
%  collected, each of which being arranged as time by variable, and
%  augmented into a single matrix as blocks of rows giving an arrangement
%  of time and batch by variable. This function rearranges to give an
%  matrix of batch by time and variable.
%
%  Input (nsamp) is the number of MxN matrices that are vertically
%  concatenated in (xaug). Output is the unfolded matrix (xmpca).
%
%  (xaug) contains (nsamp) matrices Aj augmented such that
%  [xaug] = [A1;A2;...;Ansamp]. For (xaug) of size
%  (M*Nsamp by N) each matrix Aj, j=1,...,Nsamp is size M by N.
%  For Aj each Mx1 column ai is transposed and augmented such that
%  [bj] = [a1',a2',...,aN'] and [xmpca] = [b1;b2;...;bnsamp].
%  Note: the Aj should all be the same size M by N.
%  
%  xaug = [A1(:)'; A2(:)'; ... ; Ansamp(:)']
%
%I/O: xmpca = unfoldm(xaug,nsamp);
%I/O: unfoldm demo
%
%See also: GSCALE, GSCALER, MPCA, NPLS, PARAFAC, PARAFAC2, PCA, TUCKER, UNFOLDMW

%Copyright Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified 10/96 NBG
%1/01 nbg changed 'See Also' to 'See also'

if nargin == 0; xaug = 'io'; end
varargin{1} = xaug;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear xmpca; evriio(mfilename,varargin{1},options); else; xmpca = evriio(mfilename,varargin{1},options); end
  return; 
end

[m,n]   = size(xaug);
mm       = m/nsamp;
if (mm-round(mm))~=0
  error('number of rows of xaug not evenly divisible by number of samples')
else
  xmpca = zeros(nsamp,mm*n);
  for ii=1:mm
    xmpca(:,ii:mm:mm*n) = xaug(ii:mm:m,:);
  end
end

