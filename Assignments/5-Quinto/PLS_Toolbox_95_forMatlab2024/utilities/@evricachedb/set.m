function obj = set(obj,varargin)
%EVRICACHEDB/SET Set cache property.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Passing value pairs.
property_argin = varargin;
%Try to assign value pairs.
while length(property_argin) >= 2
  prop = property_argin{1};
  val = property_argin{2};
  property_argin = property_argin(3:end);
  switch prop
    case 'dbobject'
      obj.dbobject = val;
    case 'version'
      return
    otherwise
      error(['EVRICACHDB: Can''t assign [' prop '] property.'])
  end
end
