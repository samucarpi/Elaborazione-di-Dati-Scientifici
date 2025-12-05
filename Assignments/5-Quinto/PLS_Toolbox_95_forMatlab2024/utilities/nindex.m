function x = nindex(x,indices,modes)
%NINDEX Generic subscript indexing for n-way arrays.
% NINDEX allows indexing into an n-way array without concern to the actual
% number of modes in the array. Requires n-way array (x) a cell of
% requested indices (indices) (e.g. {[1:5] [10:20]} ) and the modes to which
% those indicies should be applied (modes). Any additional modes not
% specified in (indices) will be returned as if reffered to as ':' and
% returned in full. If (modes) omitted, it is assumed that indices should
% refer to the first modes of (x) up to the length of (indices).
%
% EXAMPLES:
%   x = nindex(x,{1:5});      %extract indices 1:5 from mode 1 (rows) of any n-way array
%   x = nindex(x,{1:5},3);    %extract indices 1:5 from mode 3 of any n-way array 
%   x = nindex(x,{1:10 1:5},[5 8]);  %extract 1:10 from mode 5 and 1:5 from mode 8
%   x = nindex(x,{1:10 1:5});  %extract 1:10 from mode 1 and 1:5 of mode 2
%     The last example is equivalent to performing:
%         x = x(1:10,1:5);          %for a 2-way array or
%         x = x(1:10,1:5,:,:,:);    %for a 5-way array
% Note, the use cell notation can be omitted on indices if only one mode is
% being indexed:   x = nindex(x,5:10,3);  %is valid
%
%I/O: x = nindex(x,indices,modes)
%
%See also: NASSIGN

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 8/13/03

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear x; evriio(mfilename,varargin{1},options); else; x = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<2;
  error('insufficient inputs');
end

nd = ndims(x);

%extract from cell if we have only one dim
if ~isa(indices,'cell')
  indices = {indices};
end

%assume indices refers to first length(indices) modes if modes not specified
if nargin<3  
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
x = subsref(x,S);
