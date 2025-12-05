function err = rmse(y1,y2);
%RMSE Calculate Root Mean Square Difference(Error).
%  RMSE is used to calculate the root mean square difference
%  between two vectors or matrices. If the vector or matrix
%  is from a model estimation and measurements then the output
%  is the Root Mean Square Error (RMSE).
%  Output depends on the input:
%  A) (y1) is a matrix or vector
%       err = rmse(y1);
%     The output (err) is the root mean square of the elements of (y1).
%  B) (y1) is a matrix or vector, (y2) the same size as (y1)
%       err = rmse(y1,y2);
%     The output (err) is the root mean square of the difference
%     between (y1) and (y2).
%  C) (y1) is a matrix or vector, (y2) a column vector.
%       err = rmse(y1,y2);
%     The output (err) is the root mean square of the difference
%     between each column of (y1) and (y2).
%     For example, (y2) is a reference and the RMSE is calculated
%     between each column of (y1) and the vector (y2).
%
%I/O: err = rmse(y1,y2);
%I/O: rmse demo
%
%See also: CROSSVAL

% Copyright © Eigenvector Research, Inc. 1991
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
% bmw
% nbg 1/07 changed help

if nargin==0; y1 = 'io'; end
varargin{1} = y1;
if ischar(varargin{1});
  options = [];
  if nargout==0 
    evriio(mfilename,varargin{1},options);
  else 
    err = evriio(mfilename,varargin{1},options); 
  end
  return; 
end

if nargin == 2
  [m1,n1] = size(y1);
  [m2,n2] = size(y2);
  if m1 ~= m2
    error('y1 and y2 must have the same number of rows')
  end
  if n1 ~= n2 & n2 ~= 1
    error('y1 and y2 must have the same number of columns')
  end
  if n1 > 1 & n2 == 1
    y2 = y2(:,ones(1,n1));
  end
  dif = y1-y2;
else
  dif = y1;
end
err = sqrt(mean(dif.^2));
