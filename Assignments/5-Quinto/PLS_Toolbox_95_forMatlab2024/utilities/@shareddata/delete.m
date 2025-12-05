function delete(id)
%SHAREDDATA/DELETE Remove shared data completely

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

for j=1:length(id);
  removeshareddata(id(j));
end
