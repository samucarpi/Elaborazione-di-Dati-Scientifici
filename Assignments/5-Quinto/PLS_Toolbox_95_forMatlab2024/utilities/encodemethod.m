function cvi = encodemethod(items,method,n,blocksize)
%ENCODEMETHOD Create a cross-validation index vector for a given method.
%  Inputs are (items) the number of items to sort into sets [e.g.,
%  size(x,1) for x a data array], (method) a string defining the cross-
%  validation method defined below, (n) the number of subsets to
%  split the data into, and (blocksize) is the number of items to include
%  in each block (NOTE: blocksize for 'vet' method only)
%  Method can be any of the following:
%   'vet'   : Venetian blinds. Every n-th item is grouped together.
%             Optionally allows grouping of more than one sample together
%             using "blocksize" input. 
%   'con'   : Contiguous blocks. Consecutive items are put into n groups.
%   'loo'   : Leave one out. Each item is in an individual group, input
%              (n) can be omitted.
%   'rnd'   : Random. items are randomly split into n equal sized groups.
%
%  Output (cvi) is a vector containing the group number of each item.
%
%I/O: cvi = encodemethod(items,method,n,blocksize)
%
%See also: CROSSVAL, SHUFFLE

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%1/05 JMS adapted from crossval
%7/05 JMS modified error and help to generalize away from "samples"

if nargin == 0; items = 'io'; end
if ischar(items);
  options = [];
  if nargout==0; evriio(mfilename,items,options); else; cvi = evriio(mfilename,items,options); end
  return;
end

if nargin<3;
  n = 0;  %force error below if n not provided explictly or in cell input
end
if nargin<4
  blocksize = [];
end
if isa(method,'cell');
  if isempty(method);
    error('Method must be supplied');
  end
  if length(method)>1;
    n = method{2};
  end
  if strcmpi(method{1},'vet') & length(method)>2
    blocksize = method{3};
  end
  method = method{1};
end
if isempty(method);
  error('Method must be supplied');
end
if isnumeric(method)
  %this IS a CVI! Check length and return if OK
  cvi = method(:);
  if length(cvi)~=items
    error('Custom cross-validation must equal length of number of samples')
  end
  return
end

if isempty(blocksize)
  blocksize = 1;
end

if ~strcmpi(method,'loo') & ~strcmpi(method,'custom') 
  if n<2
    error('Number of splits must be >1');
  elseif n>items
    n = items;
  end
end

switch lower(method)
  case 'vet'   %determine classes for venetian blind leave-out    
    cvi = mod(floor(([1:items]-1)/blocksize),n)+1;
  case 'con'   %determine classes for block leave-out
    cvi = floor(([1:items]-1)/(items/n))+1;
  case 'loo'   %determine classes for leave one out
    cvi = 1:items;
  case 'rnd'   %classes for random leave out
    cvi = mod([1:items]-1,n)+1;
    cvi = shuffle(cvi');
  case 'custom'
    cvi = n;
  case 'none'
    cvi = [];
  otherwise
    error('CV method not defined.')
end
cvi   = cvi(:);

