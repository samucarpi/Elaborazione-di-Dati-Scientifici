function x = nassign(x,xnew,indices,modes)
%NASSIGN Generic subscript assignment indexing for n-way arrays.
% NASSIGN allows index assignments into an n-way array without concern to
% the actual number of modes in the array. Requires n-way array (x), a
% matrix to be inserted (xnew), a cell of requested indices (indices) (e.g.
% {[1:5] [10:20]} ) and the modes to which those indicies should be applied
% (modes). Any additional modes not specified in (indices) will be returned
% as if reffered to as ':' and returned in full. If (modes) omitted, it is
% assumed that indices should refer to the first modes of (x) up to the
% length of (indices).
% The size of (xnew) must match the size indicated by (indices) as well as
% those indices not specified.
%
% EXAMPLES:
%   x = nassign(x,xnew,{1:5});      %insert xnew as rows 1:5 of a n-way array x
%   x = nassign(x,xnew,{1:5},3);    %insert xnew as indices 1:5 from mode 3 of a n-way array x
%   x = nassign(x,xnew,{1:10 1:5},[5 8]);  %insert xnew as 1:10 from mode 5 and 1:5 from mode 8
% Note, the use cell notation can be omitted on indices if only one mode is
% being indexed:   x = nassign(x,xnew,5:10,3);  %is valid
%
%I/O: x = nassign(x,xnew,indices,modes)
%
%See also: NINDEX

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 8/19/03

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear x; evriio(mfilename,varargin{1},options); else; x = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<3;
  error('insufficient inputs');
end

nd = ndims(x);

%extract from cell if we have only one dim
if ~isa(indices,'cell')
  indices = {indices};
end

%assume indices refers to first length(indices) modes if modes not specified
if nargin<4
  modes = 1:length(indices);
end

if length(modes)~=length(indices);
  error('Number of indexing items and number of modes do not match');
end

subs = cell(1,nd);
[subs{1:nd}] = deal(':');   % gives  {':' ':' ':' ...}
[subs{modes}]  = deal(indices{:});        % insert indices into appropriate dim

%drop any extra modes they tried indexing into
if length(subs)>nd;
  subs = subs(1:nd);
end  

S      = [];
S.subs = subs;
S.type = '()';

x = subsasgn(x,S,xnew);
