function res=cellne(one,two);
%CELLNE Compares two cells for inequality in size and/or values.
%  The two inputs are cells (c1, c2). CELLNE returns
%  a scalar one (1) if cell sizes don't match otherwise, 
%  it returns an array of same size as cells with a
%  1 everywhere the cells do not match.
%  (NOTE: 1 = cells do NOT match!)
%
%I/O: out = cellne(c1,c2)
%
%See also: COMPAREVARS


%Copyright Eigenvector Research, Inc. 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 4/2001
% JMS 12/20/01 allow for cell of cells
%  -fixed comparison of sizes
% JMS 1/2/02 updated help
%  -added additional error checking
% JMS 5/9/02 added test and comparison for multi-dimensional cell elements
%  -updated for standard I/O

if nargin == 0; one = 'io'; end
varargin{1} = one;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear res; evriio(mfilename,varargin{1},options); else; res = evriio(mfilename,varargin{1},options); end
  return; 
end
 
if ~isa(one,'cell') | ~isa(two,'cell');
  error('Both inputs must be cells');
end

if ndims(one)~=ndims(two) | any(size(one)~=size(two));
  res = 1;
  return
end;

res=zeros(size(one));
for j=1:prod(size(one));
  e1=one{j}; e2=two{j};
  if ~strcmp(class(e1),class(e2));
    res(j) = 1;
  elseif ndims(e1)~=ndims(e2) | any(size(e1)~=size(e2));
    res(j) = 1;
  elseif isa(e1,'char')
    res(j) = ~strcmp(e1,e2);
  elseif isa(e1,'cell')
    temp   = cellne(e1,e2);
    res(j) = any(temp(:));
  elseif isempty(e1)
    res(j) = 0;
  else
    try
      temp = (e1~=e2);
      res(j) = any(temp(:));
    catch
      res(j) = 1;
    end
  end
end;

res = reshape(res,size(one));
