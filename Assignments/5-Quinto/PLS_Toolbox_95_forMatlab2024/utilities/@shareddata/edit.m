function out = edit(obj,varargin);
%SHAREDDATA/EDIT Overload of Edit function for shared data objects.

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

id = getshareddata(obj,'all');
switch class(id.object);
  case 'dataset'
    if nargout>0
      out = editds(obj);
    else
      editds(obj);
    end
  otherwise
    error('No Edit method is known for this type of shared data')
end
