function desgn = ccdface(k)
%CCDFACE Create a Face-Centered Central Composite Design of Experiments.
% Input (k) is the number of factors to include in the model. Output is a
% coded face-centered central composite design (CCD) in which all factors
% will have three levels.
%
%I/O: desgn = ccdface(k)
%
%See also: BOXBEHNKEN, CCDSPHERE, DOEGEN, DOESCALE, FACTDES, FFACDES1

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; k = 'io'; end
if ischar(k);
  options = [];
  if nargout==0; evriio(mfilename,k,options); else; desgn = evriio(mfilename,k,options); end
  return; 
end

%get a 3-level k-factor full factorial
d = factdes(k,3);

if k>2
  %with more than two factors, drop any points with only one factor at zero
  nzeros = sum(d==0,2);
  use = nzeros==0 | nzeros>k-2;
else
  %with two or one factor, use ALL points
  use = true(size(d,1),1);
end
desgn = d(use,:);
