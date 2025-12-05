function [gxs,mxs,stdxs] = gscale(xin,numblocks,center)
%GSCALE Group/block scaling for a single or multiple blocks.
%GSCALE group/block scale submatrices of a single data matrix as in MPCA.
% Scales an input matrix xin such that the columns have mean zero, and
% variance in each block/sub-matrix relative to the total variance in xin
% equal to one. The purpose is to provide equal sum-of-squares weighting to
% each block in xin.
%
% INPUT:
%  xin = a matrix (class "double" or DataSet Object) to process
% OPTIONAL INPUT:
%  numblocks = Defines how the data should be split into blocks. Three
%       different uses exist:
%       >0   if (numblocks) is > 0, the number of sub-matrices/blocks in
%            the data. Note that size(xin,2)/numblocks must be a whole
%            number. If (numblocks) is not included it is assumed to be 1
%            (one) and the entire (xin) matrix is treated as a single
%            block.
%
%       =0   If (numblocks) is 0 (zero) then automatic blocking is done
%            based on the dimensions of the (xin) matrix. If (xin) is a
%            three-way array, it is unfolded (combining the first two modes
%            as variables) and the size of the original second mode
%            (size(xin,2)) is used as (numblocks). The output is re-folded
%            back into the original three-way array. Note that the unfold
%            operation is:  xin = unfoldmw(xin,3); If (xin) is a two-way
%            array, each variable is treated on its own and GSCALE is
%            equivalent to autoscale (see the AUTO function).
%
%       <0   If (numblocks) is a negative integer, then class information
%            in the indicated set on mode 2 (the variable mode) is used to
%            divide the blocks. E.g. if numblocks is -3, then the third
%            class set is used to define blocks. This feature is only
%            defined for two-way arrays.
%
%   [vector] If numblocks is a vector equal in length to the number of
%            columns in xin, it is used as the block assignments for each
%            column as if the vector was stored in the class sets
%            (described above)
% center   = A true/false flag indicating whether the xin block should be
%            centered. A value of true or 1 (default) will both center and
%            scale each block. A value of false or 0 will only scale each
%            block without centering it. 
%
% OUTPUTS:
%  gxs   = the scaled matrix
%  mxs   = a rowvector of means
%  stdxs = a row vector of "block standard deviations"
%
%Example: xin = [A1,A2,..., Anumblocks].
%  Each of the Ai is m by nt where m is the number of samples and nt (for
%  example) is the number of time steps in a batch operation and
%  size(xin,2) = nt*numblocks.
%  Each submatrix Ai is group scaled to zero mean and total variance 1.
%
%I/O: [gxs,mxs,stdxs] = gscale(xin,numblocks,center); %block scaling
%
%See also: AUTO, GSCALER, MNCN, POLYTRANSFORM, SCALE, UNFOLDM

%Copyright Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%1/01 nbg changed 'See Also' to 'see also'
%8/02 nbg rewrote the help, combined with dogscl
%8/07 rb added functionality to group based on class variable

if nargin == 0; xin = 'io'; end
varargin{1} = xin;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; gxs = evriio(mfilename,varargin{1},options); end
  return;
end

if nargin<3
  center = true;
end

xorig = xin;
if ndims(xin)==3;
  %if a 3-way, unfold it now then refold later
  origsize = size(xin);
  xin = unfoldmw(xin,3);
else
  origsize = [];
end

if isa(xin,'dataset');
  inclrows = xin.include{1};
  inclcols = xin.include{2};
  xin = xin.data;
else
  xorig = [];
  inclrows = 1:size(xin,1);
  inclcols = 1:size(xin,2);
end

useclass = 0;
[m,n]    = size(xin);

if nargin<2 | (numel(numblocks)==1 & numblocks==0)
  if ~isempty(origsize)
    numblocks = origsize(2);
  else
    numblocks = n;
  end
elseif length(numblocks)>1
  if (isempty(origsize) & length(numblocks)~=n) | (~isempty(origsize) & length(numblocks)~=origsize(2))
    error('Vector input for numblocks must be equal in length to the number of variables')
  end
  class = numblocks;
  blocks = unique(class);
  numblocks = length(blocks);
  useclass = 1;
elseif numblocks<0 % Use the variable class '-numblock' to group
  try
    class = xorig.class{2,-numblocks};
  catch
    if ~isa(xorig,'dataset')
      error('When the input numblocks is negative, class information is used to form the bloks, but this requires that the input data is a data set object')
    else
      error(['Not possible to find class ',num2str(-numblocks),' in the data'])
    end
  end
  blocks = unique(class);
  numblocks = length(blocks);
  useclass = 1;
end

gxs      = zeros(m,n);
mxs      = zeros(1,n);
stdxs    = mxs;
n        = n/numblocks;
if useclass==0 & (n-round(n))~=0
  error('Cannot divide data evenly into requested number of equally-sized blocks.')
end

for i=1:numblocks
  if useclass
    j = find(class==blocks(i));
  else
    j = [(i-1)*n+1:i*n];
  end
  j = intersect(inclcols,j);
  [gxs(:,j),mxs(1,j),stdxs(1,j),stdt(1,i)] = gscale1(xin(:,j),inclrows,center);
  if useclass
    %if using classes, store BLOCK standard deviations for each column in
    %this block (will be used on a column-by-column basis when applying to
    %new data)
    stdxs(1,j) = stdt(1,i);
  end
end

if ~isempty(origsize);  %was a 3-way array...
  gxs = reshape(gxs,origsize(3),origsize(1),origsize(2));
  gxs = permute(gxs,[2 3 1]);
end

if isa(xorig,'dataset');
  xorig.data = gxs;
  gxs = xorig;
end

%-------------------------------------------------------------
function [gx,mx,stdx,stdt] = gscale1(x,inclrows,center)
%GSCALE1 group/block scales a single matrix.
%  GSCALE1 scales an input matrix (x) such that the columns have
%  mean zero and variance relative to the total variance in (x).
%
%  The output is the matrix (gx), a vector of means (mx), and a
%  vector of standard deviations (stdx) used in the scaling.
%
%I/O: [gx,mx,stdx] = gscale(x);

xall  = x;
if nargin>1 & ~isempty(inclrows);
  x = x(inclrows,:);
end
[m,n] = size(xall);
if center
  if checkmlversion('>=','8.5')%2015a or newer
    mx  = mean(x,'omitnan');
  else
    mx    = mean(x);
  end
else
  mx = zeros(1,n);
end

if checkmlversion('>=','8.5')%2015a or newer
  stdx  = std(x,0,1,'omitnan');
else
  stdx  = std(x);
end

stdt  = sqrt(sum(stdx.^2));
if stdt==0;
  stdt = 1;
end
gx    = (xall-mx(ones(m,1),:))/stdt;
