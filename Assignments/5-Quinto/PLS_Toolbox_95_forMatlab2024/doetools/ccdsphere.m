function desgn = ccdsphere(k)
%CCDSPHERE Create a Spherical Central Composite Design of Experiments.
% Input (k) is the number of factors to include in the model. Output is a
% coded spherical central composite design in which all factors will have
% five levels.
%
%I/O: desgn = ccdsphere(k)
%
%See also: BOXBEHNKEN, CCDFACE, DOEGEN, DOESCALE, FACTDES, FFACDES1

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

%get a face-centered cubic design
d = ccdface(k);

%correct all points for leverage
desgn = normaliz(d,0,2); 

