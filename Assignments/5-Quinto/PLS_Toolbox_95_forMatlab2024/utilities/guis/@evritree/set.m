function obj = set(obj,varargin)
%EVRITREE/SET Overload of SET for evritree.

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


if nargin > 0 & ~isa(obj,'evritree');
  %If not evritree the send to Matlab SET.
  builtin('set',varargin{:});
  return
end

propertyArgIn = varargin;
while length(propertyArgIn) >= 2,
  myprop = propertyArgIn{1};
  myval = propertyArgIn{2};
  propertyArgIn = propertyArgIn(3:end);
  switch myprop
    case ''
      %No special cases yet.
    otherwise
      index.type = '.';
      index.subs = myprop;
      obj = subsasgn(obj,index,myval);
  end
end
set_evritree_obj(obj)%Save object to figure.
