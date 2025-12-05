function obj = set(obj,varargin)
%ETABLE/SET Overload of SET for etable.

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


propertyArgIn = varargin;
while length(propertyArgIn) >= 2,
  myprop = propertyArgIn{1};
  myval = propertyArgIn{2};
  propertyArgIn = propertyArgIn(3:end);
  switch myprop
    case ''
      
    otherwise
      index.type = '.';
      index.subs = myprop;
      obj = subsasgn(obj,index,myval);
  end
end
