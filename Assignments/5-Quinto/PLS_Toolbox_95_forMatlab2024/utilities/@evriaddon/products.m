function list = products(obj)
%EVRIADDON/PRODUCTS Returns list of add-on products currently available.
% This method returns a cell array of strings listing the products
% currently available through evriaddon connections. These products'
% evriaddon_connection objects can be accessed by requesting the specified
% product in an evriaddon object:    evriaddon('this_product')
%
%I/O: evriaddon('products')

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin==0;
  obj = evriaddon;
end

%get list of all current object methods
list = methods(obj);

list = list(strmatch('addon',list))';
for j=1:length(list)
  list{j} = list{j}(7:end);
end
