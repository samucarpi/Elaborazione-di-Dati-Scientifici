function out = ismodel(obj)
%ISMODEL Returns boolean TRUE if input object is a standard model structure.
% Input (obj) is any object or variable. If (obj) is determined to be a
% standard PLS_Toolbox model structure, output (out) will be true.
% Otherwise output will be false.
%
%I/O: out = ismodel(obj)

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = isa(obj,'evrimodel');

if ~out & isfield(obj,'modeltype')
  %SPECIAL! Even old models which have the "modeltype" field set will be
  %detected as models. This allows for transparent loading and working with
  %old models - HOWEVER, old models should be updated with:
  %  model = evrimodel(model)
  out = true;
end
  
