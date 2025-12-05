function out = isa(obj,type)
%EVRIMODEL/ISA Overload for object.

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


out = false;
if strcmp(type,'evrimodel')
  out = true;
end

if strcmpi(type,'struct');
  if stricttesting
    recordevent('** Call to isa(___,''struct'') on model object')
  end
  out = true;
end

  
