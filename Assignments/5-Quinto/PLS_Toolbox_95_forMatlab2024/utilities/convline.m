function [x,d] = convline(x,x2)
%CONV1 Convolves a signal or spectrum with a given line shape.
%  CONV1 is used to convolve a signal or spectrum (x) with a given line
%  shape or filter (x2). [A more general approach for two vectors is
%  given by CONV.]
%
%  INPUTS:
%     x = MxN matrix of ROW vectors to be convolved [class double or
%           DataSet].
%    x2 = 1xW line (or filter) [class double]. Typically, W<N.
%
%  OUTPUTS:
%     y = MxN matrix of ROW vectors convolved with (x2).
%         If input (x) is a DataSet object, it's include{2} field is
%         modified to exclude the ends to avoid end-effects.
%         E.g., if W is odd and p = (W-1)/2 then the output is
%           y = delsamps(y,[1:p N-p+1:N],2,1); [See help dataset/delsamps]
%     d = NxN sparse matrix [class double] that can be used to perform
%         convolution with a multiplication. E.g., if (x) is class double
%         then y = x*d;
%
%Example:
%   load data_near_IR
%   [y,d] = convline(data_near_IR,ones(1,7)/7); % y is a 7 pt boxcar average
%   figure
%   plot(normaliz([yy.data(1:2,:); y.data(1:2,:)])')
%
%I/O: [y,d] = convline(x,x2);
%
%See also: CONV, SAVGOL

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

m    = size(x,2);
n    = length(x2);

if mod(n,2)==0 
  iseven  = true;
  p  = n/2-1;
  d  = spdiags(ones(m,1)*x2(:)',p:-1:-p-1,m,m);
else
  iseven  = false;
  p  = (n-1)/2;
  d  = spdiags(ones(m,1)*x2(:)',p:-1:-p,m,m);
end

if isdataset(x)
  x.data  = x.data*d;
  if iseven
    x     = delsamps(x,[1:p m-p:m],2,1);
  else
    x     = delsamps(x,[1:p m-p+1:m],2,1);
  end
else
  x  = x*d;
end
