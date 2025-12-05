function [ output_args ] = data_changed_callback(varargin)
%ETABLE/DATA_CHANGED_CALLBACK Data changed callbck.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

fh = varargin{3};
mytag = varargin{4};

%Get copy of object.
obj = gettobj(fh,mytag);

%Table not available.
if isempty(obj)
  return
end

myfcn = obj.data_changed_callback;

if isempty(myfcn)
  return
end

%Run additional callbacks if needed.
myvars = getmyvars(myfcn);
if iscell(myfcn)
    myfcn = myfcn{1};
end

%Put table and change event objects on end of call.
feval(myfcn,myvars{:},varargin{:});

%---------------------------
function myvars = getmyvars(myfcn)
%Get function from object.

myvars = {};
if length(myfcn)>1
  myvars = myfcn(2:end);
  myfcn = myfcn{1};
end
