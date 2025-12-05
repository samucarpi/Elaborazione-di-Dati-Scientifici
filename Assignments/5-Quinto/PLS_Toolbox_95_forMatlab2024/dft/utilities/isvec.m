function tf = isvec(x,p)
%ISVEC verifies that (x) is a vector.
%  Returns a 1 if true and a 0 otherwise.
%
%  Optional input (p) is the number of elements
%  that the vector must have.
%  ISVEC Returns a 1 if (x) is a vector with (p)
%  elements and a 0 otherwise.
%
%I/O: tf = isvec(x,p);
%
%See also: ISINT, ISNEG, ISNONNEG, ISPOS, ISPROB, ISSCALAR

% Copyright © Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
% NBG 04/03, added number of elements

if nargin<2
  p   = 0;
elseif p<2
  error('Input p must be >1.')
end

[m,n] = size(x) ;

if (m~=1 & n~=1) | (m*n==1)
  tf = 0 ;
else
  if p==0
    tf = 1 ;
  else
    if p==length(x)
      tf = 1;
    else
      tf = 0;
    end
  end
end
