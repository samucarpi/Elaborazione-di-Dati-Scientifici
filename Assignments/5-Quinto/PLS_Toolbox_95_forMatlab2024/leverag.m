function lev = leverag(x,rinv)
%LEVERAG Calculate sample leverages.
%  Returns leverage (lev) for an input data matrix (x) from
%    lev(i,1) = x(i,:)*inv(x'*x)*x(i,:)'
%  This assumes that the data have been mean centered
%  and the constant contribution from the mean is not 
%  included. (This form of the leverage is directly
%  related to the Hotelling T^2 statistic.)
%
%  NOTE: If (x) is not full rank then inv(x'*x) will
%  not exist, and if (x) is nearly rank deficient the
%  estimate of inv(x'*x) may be unstable.
%  Scores from PCA can be used for (x).
%
%  If the optional input (rinv) is supplied the leverage
%  is calculated as
%    lev(i,1) = x(i,:)*rinv*x(i,:)'
%
%I/O: lev = leverag(x,rinv);
%I/O: leverag demo
%
%See also: DOPTIMAL, FIGMERIT, PCR, PLS

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; lev = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<2
  rinv   = inv(x'*x);
else
  if size(rinv,1)~=size(rinv,2)
    error('ERROR - input rinv must be square')
  end
  if size(rinv,2)~=size(x,2)
    error('ERROR - number of columns in rinv and x must be equal')
  end
end

lev = sum((x*rinv).*x,2);
