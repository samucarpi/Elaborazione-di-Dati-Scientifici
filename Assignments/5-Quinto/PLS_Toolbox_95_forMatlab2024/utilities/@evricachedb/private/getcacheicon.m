function iconpath = getcacheicon(type)
%Get full path to icon for given type of data (model,data,prediction).

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

type = strrep(type,'*','na');
iconpath = which([lower(type) '.gif']);
if isempty(iconpath)
  iconpath = which('other.gif');
end
