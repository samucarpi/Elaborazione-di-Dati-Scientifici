function [y_hat,cm] = gapsegment(y,order,gap,segment,options)
%GAPSEGMENT provides Gap-Segment derivatives.
% Calculates a derivative in which the two values being subtracted from
% each other are not single adjacent points (as in a point difference
% derivative, where, for example, Dx1=x2-x1) but a derivative where there
% are multiple points in each "segment" (i.e. window) and the segments are
% separated by some non-zero number of points.
%
% The filter is determined by the order of derivative (which defines the
% number of segments), segment size (number of variables in each window)
% and gap size (number of variables between the windows).
%
% INPUTS:
%        y = MxN matrix where rows are to be filtered.
%    order = order of derivative (1, 2, 3 or 4)
%      gap = the gap size, the number of variables between segments. Must
%            be >2 and odd.
%  segment = the segment size, the number of variables in each segment.
%            Must be >2 and odd.
%
% OPTIONAL INPUT:
%  options = structure with the following fields:
%    algorithm: [{standard} | savgol]
%
% OUTPUTS:
%    y_hat = is the filtered data.
%       cm = is the filter matrix such that
%            y_hat = y*cm;
%
% The filter (F) for each order is given as [g = gap, s = segment]
%  order = 1
%   F = [-ones(1,s) zeros(1,g)    ones(1,s)];
%  order = 2
%   F = [ ones(1,s) zeros(1,g) -2*ones(1,s) zeros(1,g)   ones(1,s)];
%  order = 3
%   F = [-ones(1,s) zeros(1,g)  3*ones(1,s) zeros(1,g) , ...
%                              -3*ones(1,s) zeros(1,g)   ones(1,s)];
%  order = 4
%   F = [ ones(1,s) zeros(1,g) -4*ones(1,s) zeros(1,g) , ...
%       6*ones(1,s) zeros(1,g) -4*ones(1,s) zeros(1,g) ones(1,s)];
%
%I/O: [y_hat,cm] = gapsegment(y,order,gap,segment,options);
%I/O: gapsegment demo
%
%See also: SAVGOL

% Copyright © Eigenvector Research, Inc. 2013
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

% Make sure gap and segment are both odd numbers & greater than 3...adjust as needed

if nargin == 0; y = 'io'; end
if ischar(y);
  options = [];
  options.algorithm = 'standard'; %[{standard} | savgol]
  
  if nargout==0; clear y_hat; evriio(mfilename,y,options);
  else; y_hat = evriio(mfilename,y,options); end
  return;
end

if nargin<5;
  options = [];
end
options = reconopts(options,mfilename);

if gap<2 || segment<2
  error('Gap and Segment values must be >2 and ODD');
end

switch order
  case {1,3}
    if mod(gap,2)==0
      gap = gap -1;  %gap is an even number....subtract 1
    end
  case {2,4}
    if mod(segment,2)==0
      segment = segment -1;  %segment is an even number....subtract 1
    end
  otherwise
    error('Input (order) must be 1, 2, 3 or 4.')
end

switch lower(options.algorithm)
  case 'standard'
    switch order
      case 1
        F = [-ones(1,segment) zeros(1,gap) ones(1,segment)];
      case 2
        F = [ones(1,segment) zeros(1,gap) -2*ones(1,segment) zeros(1,gap) ones(1,segment)];
      case 3
        F = [-ones(1,segment) zeros(1,gap) 3*ones(1,segment) zeros(1,gap) -3*ones(1,segment), ...
          zeros(1,gap) ones(1,segment)];
      case 4
        F = [ones(1,segment) zeros(1,gap) -4*ones(1,segment) zeros(1,gap) 6*ones(1,segment), ...
          zeros(1,gap) -4*ones(1,segment) zeros(1,gap) ones(1,segment)];
    end
    
    len = length(F);      % len = the number of points of the filter
    m   = (len-1)/2;
    j   = -m:m;
    F   = F/sum(j.^order*F')/prod(1:order); % the generic normalized filter
    n   = size(y,2); % Construct and populate the square matrix filter
    cm  = spdiags(ones(n,1)*F,m:-1:-m,n,n);
    
    for i=m:-1:1
      cm(:,1:i) = cm(:,1:i)*(1-1/m);
    end
    for i=n-m:n
      cm(:,i:n) = cm(:,i:n)*(1-1/m);
    end
    y_hat = y*cm;
  case 'savgol'
    switch order
      case 1
        p  = floor(gap/2);
        z  = segment + p;
        wt = sqrt(abs(-z:z)); wt(z+1) = 1;
        wt = [ones(1,segment) zeros(1,gap) ones(1,segment)]./wt;
      case 2
        q  = floor(segment/2);
        z  = segment + gap + q;
        wt = sqrt(abs(-z:z)); wt(z+1) = 1;
        wt = [ones(1,segment) zeros(1,gap) -sqrt(2)*ones(1,segment), ...
          zeros(1,gap) ones(1,segment)]./wt;
        wt = normaliz(wt,[],inf);
      case 3
        p  = floor(gap/2);
        z  = segment*2+ gap + p;
        wt = sqrt(abs(-z:z)); wt(z+1) = 1;
        wt =    [-ones(1,segment) zeros(1,gap) sqrt(3)*ones(1,segment) zeros(1,gap), ...
          -sqrt(3)*ones(1,segment) zeros(1,gap) ones(1,segment)]./wt;
        wt = normaliz(wt,[],inf);
      case 4
        p  = floor(gap/2);
        z  = segment*2+ gap*2 + p;
        wt = sqrt(abs(-z:z)); wt(z+1) = 1;
        wt =    [ones(1,segment) zeros(1,gap) -sqrt(4)*ones(1,segment) zeros(1,gap), ...
          sqrt(6)*ones(1,segment) zeros(1,gap) -sqrt(4)*ones(1,segment) zeros(1,gap) ones(1,segment)]./wt;
        wt = normaliz(wt,[],inf);
    end
    [y_hat,cm] = savgol(y,length(wt),order,order,struct('wt',wt,'tails','weighted'));
  otherwise
    error('Input (options.algorithm) not recognized.')
end


