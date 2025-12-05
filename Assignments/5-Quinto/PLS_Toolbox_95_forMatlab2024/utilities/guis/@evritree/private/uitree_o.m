function [t,c] = uitree_o(varargin)
%EVRITREE/UITREE_O Overload of Matlab uitree function to be backward compatible.

% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


property_argin = varargin;
prop_struct = [];
%Try to assign value pairs.
while length(property_argin) >= 2
  prop_struct.(lower(property_argin{1})) = property_argin{2};
  property_argin = property_argin(3:end);
end


if checkmlversion('>=','7.6')
  [t, c] = uitree('v0',prop_struct.parent,'Root', prop_struct.root,'parent', prop_struct.parent,'ExpandFcn',prop_struct.expandfcn);
else
  [t, c] = uitree(prop_struct.parent,'Root', prop_struct.root,'parent', prop_struct.parent,'ExpandFcn',prop_struct.expandfcn);
end

