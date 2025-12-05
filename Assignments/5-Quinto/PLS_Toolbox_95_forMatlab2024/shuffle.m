function varargout = shuffle(varargin)
%SHUFFLE Randomly re-orders matrix and multiple blocks rows.
%  This funtion shuffles samples (rows) in a matrix (e.g. so that they can
%  be used randomly for cross-validations.) If more than one input is
%  provided, all inputs are shuffled to the same random order. All inputs
%  must have the same number of rows. 
%  If the final input is the string 'groups' then the first input is sorted
%  into groups of matching rows and the order of the groups is randomly
%  shuffled, keeping group members together. This is useful for random
%  reordering of measurement replicates. If all the rows of  the first
%  input are unique, 'groups' will have no effect on the behavior of
%  shuffle.
%
%I/O: xr = shuffle(x);
%I/O: [xr,x2r,x3r,...] = shuffle(x,x2,x3,...);
%I/O: [xr,x2r,x3r,...] = shuffle(x,x2,x3,...,'groups');
%I/O: shuffle demo
%
%See also: DELSAMPS, MATCHROWS

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified 11/93
%jms 5/22
%jms 11/03 - added ability to shuffle keeping group members together

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

if ischar(varargin{end}) & strcmp(varargin{end},'groups')
  bygroup = 1;
  varargin = varargin(1:end-1);
else
  bygroup = 0;
end

[m,n] = size(varargin{1});
for j = 2:length(varargin);
  if size(varargin{j},1) ~= m
    error('All inputs must have the same number of rows');
  end
end

if ~bygroup
  ind   = rand(m,1);
  [a,b] = sort(ind);
else
  %reorder but group matching rows together
  temp = varargin{1};
  if isa(temp,'dataset'); temp = temp.data; end
  [grps,gi,gj] = unique(temp,'rows');  %find the groups and where they are in the original data
  reorder = shuffle([1:size(grps,1)]');       %randomly reorder the group order
  [a,b]   = sort(reorder(gj));                %use map to locate new order of original group members
end

for j = 1:length(varargin);
  varargout{j} = varargin{j}(b,:);
end

