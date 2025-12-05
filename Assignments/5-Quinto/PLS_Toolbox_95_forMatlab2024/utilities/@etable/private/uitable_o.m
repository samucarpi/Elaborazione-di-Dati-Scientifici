function [t,c] = uitable_o(varargin)
%ETABLE/uitable_o Overload of Matlab uitable function to be backward compatible.

% Copyright © Eigenvector Research, Inc. 2010
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

%2008a has new uitable which is way way better at handling large arrays so
%try to use that when possible.
if checkmlversion('<','7.6')
  if ~isfield(prop_struct,'columnnames')
    [t,c] = uitable('parent',prop_struct.parent,'data',prop_struct.data);
  else
    [t,c] = uitable('parent',prop_struct.parent,'data',prop_struct.data,'ColumnNames',prop_struct.columnnames);
  end
% CELLEDITCALLBACK not used, should be done in other function/object.
%   if isfield(prop_struct,'celleditcallback')
%     set(t,'DataChangedCallback',prop_struct.celleditcallback)
%   end
else
  [t,c] = uitable('v0',varargin{:});
end
