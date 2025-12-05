function y=durbin_watson(x);
%DURBIN_WATSON Criterion for measure of continuity.
% The durbin watson criteria for the columns of x are calculated as the
% ratio of the sum of the first derivative of a vector to the sum of the
% vector itself. Low values means correlation in variables, high values
% indicates randomness.
% Input (x) is a column vector or array in which each column represents a
% vector of interest. Output (y) is a scalar or vector of Durbin Watson
% measures.
%
%I/O: y = durbin_watson(x);
%
%See also: CODA_DW

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  if nargout==0; evriio(mfilename,x,options); else; y = evriio(mfilename,x,options); end
  return; 
end

d=diff(x);
a=sum(d.*d);
b=sum(x.*x);

%TAKE CARE OF DIVIDING BY 0

array    = (b==0);
b(array) = 1;

y = a./b;

y(array) = inf;
