function sfield = isfieldcheck(subfields, strct)
%EVRIMODEL/ISFIELDCHECK Overload for object.

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isa(subfields,'evrimodel')
  %invert order if passed in as (object,subfields)
  [strct,subfields] = deal(subfields,strct);
end
sfield = isfieldcheck(subfields, strct.content);
