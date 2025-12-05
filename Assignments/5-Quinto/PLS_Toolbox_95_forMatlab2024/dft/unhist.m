function d = unhist(x,y,n)
%UNHIST Create a vector whose values follow an empirical distribution.
% Given the x and y values for an empirical distribution (histogram) where
% y is the number of times each value of x is seen, this returns a vector
% as close to length n as possible whose values follow the provided
% distribtuion as close a possible.
%
% This operation is useful when attempting to derrive statistical
% information on the distribution of X values in a given x,y relationship,
% (the output can be passed into SUMMARY, for example, to get information
% on the empirical distribution in x) or when a set of values is needed
% which follow a certain empirical distribution.
%
% The d output from:
%   d = unhist(x,y,n);
% will be a vector close to length n such that the command:
%   [hy,hx] = hist(d,x);
% would give an hy where hy is an approximation of y except for scale. 
%
% The values within y are divided up into n bins and negative values in y
% are ignored. Note that the output vector may differ from length n because
% of rounding error while creating bins.
%
%INPUTS:
%  x = vector of bin centers
%  y = vector of frequency of occurence of each bin in x
%OPTIONAL INPUTS:
%  n = target length for output vector. This also defines the resolution
%      over which y is divided. Larger n leads to finer resolution of y
%      (such that the hy output from [hx,hy]=hist(d) will be a closer
%      approximation of y). Default value = 1000. Actual output length may
%      vary because of rounding on the scaled y values.
%OUTPUTS:
%  d = vector close to length n which contains y_i occurances of each
%      corresponding x_i value.
%
%I/O: d = unhist(x,y,n);
%
%See also: PLOTQQ, SUMMARY

%Copyright Eigenvector Research 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0
  x = 'io';
end
if ischar(x)
  options = [];
  if nargout==0; evriio(mfilename,x,options); else; d = evriio(mfilename,x,options); end
  return
end

if nargin<3
  n = 1000;  %n = number of points we'll have in the output vector
end

y(y<0) = 0;  %ignore negative values

%adjust scaling target to try to get as many values as we were asked for
targ  = n; 
ys = round(y/sum(y)*targ);  %set sum of all values to n (or as close as possible)
found = sum(ys); 
while found<n;
  targ = targ+1;   %increase target to attempt to get n found values
  ys = round(y/sum(y)*targ);
  found = sum(ys); 
end;

d = zeros(1,found);  %output vector
use = find(ys>0);  %pay attention to ONLY those y values which are present
int = [0 cumsum(ys(use))];  %get the intervals we'll use in the output vector
for j=1:length(int)-1; 
  d((int(j)+1):int(j+1)) = x(use(j)); %assign each x value as many times as we need it
end
if found>n
  d = d(1:n);
end
