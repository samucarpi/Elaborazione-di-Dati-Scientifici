function out = isvalid(in)
%SHAREDDATA/ISVALID

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isempty(in) | ~isshareddata(in)
  out = false;
else
  out = logical([]);
  for j=1:length(in)
    out(j) = ~isempty(getshareddata(in(j),'all'));
  end
end
