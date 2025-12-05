function [diffval, diffvalstr] = calcdifference(x1,x2)
%CALCDIFFERENCE Calculate difference between two datasets.
%  Calculate aggregate difference in mode 1 of 2 datasets.
% INPUTS
%   x1 = first dataset.
%   x2 = second dataset.
%
%
%I/O: [diffval, diffvalstr] = calcdifference(x1,x2)           
%
%See also: CALTRANSFER, CALTRANSFERGUI

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


if (~isempty(x1) && ~isempty(x2)) && all(size(x1)==size(x2))
  x1incl = x1.include;
  x2incl = x2.include;
  for m = 1:length(x1incl);
    incl{m} = intersect(x1incl{m},x2incl{m});
  end
  x1i = x1.data(incl{:});
  x2i = x2.data(incl{:});
  diffval = norm(x1i( : )-x2i( : ))./norm(x1i( : ));
  %diffval = min(diffval,1);
  %diffval = max(diffval,0);
  diffvalstr = sprintf('%.3g',diffval);
elseif ~isempty(x1) && ~isempty(x2)
  %There's data but the sizes don't match.
  diffval = 0;
  diffvalstr = 'N/A Data Size Mismatch';
end
