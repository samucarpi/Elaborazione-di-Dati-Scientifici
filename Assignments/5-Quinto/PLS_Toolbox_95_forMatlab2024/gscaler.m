function [gys] = gscaler(xin,numblocks,mxs,stdxs,undo)
%GSCALER Applies group/block scaling to submatrices of a single matrix.
%  GSCALER group/block scale submatrices of a single data matrix as in MPCA.
%
%  Inputs are a matrix (xin) (class "double"), the number of sub-matrices/
%  blocks (numblocks), an offset vector (mxs), and a scale vector (stdxs).
%  See GSCALE for descriptions of (mxs) and (stdxs).
%  Note that size(xin,2)/numblocks must be a whole number.
%  When numblocks = 1, all variables are scaled as a single block.
%  When numblocks = 0, each variable is handled on its own and gscaler is
%    equivalent to the SCALE function.
%  When numblocks < 0, stdxs is assumed to be scaling for each variable
%  based on blocks (used with the equivalent input for gscale where groups
%  are determined by classes in the calibration data).
%
%  If the optional input (undo) is included with a value of 1 (one), then
%  the input is assumed to be (gys) and is unscaled and uncentered to give
%  the original (xin) matrix.
%
%  In a standard call, the output is the scaled matrix (gys). When undo is
%  provided, the output is the unscaled original matrix (xin).
%
%Example: xin = [A1,A2,..., Anumblocks].
%  Each of the Ai is m by nt where m is the number of samples and nt
%  (for example) is the number of time steps in a batch operation and
%  size(xin,2) = nt*numblocks.
%  Each submatrix Ai is centered to the offsets given in (mxs)  and
%  scaled by the factors given in (stdxs).
%
%I/O: gys = gscaler(xin,numblocks,mxs,stdxs); %apply block scaling to new data
%I/O: xin = gscaler(gys,numblocks,mxs,stdxs,undo); %undo block scaling
%I/O: gscaler demo
%
%See also: AUTO, GSCALE, MNCN, MPCA, SCALE, UNFOLDM

%Copyright Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%1/01 nbg changed 'See Also' to 'see also'
%8/02 nbg rewrote the help, combined with dogsclr

if nargin == 0; xin = 'io'; end
varargin{1} = xin;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; gys = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin==3 %this block of code makes it backward compatible with Ver 2 I/O
  stdxs     = mxs;
  mxs       = numblocks;
  numblocks = 1;
end
if nargin<5;
  undo = 0;
end

if isa(xin,'dataset');
  yorig = xin;
  inclcols = xin.include{2};
  xin = xin.data;
else
  inclcols = 1:size(xin,2);
  yorig = [];
end

[m,nt]   = size(xin);
gys      = zeros(m,nt);
if numblocks==0
  %each column on its own.
  numblocks = nt;
elseif length(numblocks)>1 | numblocks<0 % Used classes to group
  %this means that standard deviations stored for each column are actually
  %BLOCK standard deviations and should be used on a column-wise basis
  numblocks = nt;
else
  %just a number of blocks
end
nt        = nt/numblocks;

for i = 1:numblocks
  j = [(i-1)*nt+1:i*nt];
  j = intersect(inclcols,j);
  [gys(:,j)] = gscaler1(xin(:,j),mxs(1,j),stdxs(1,j),undo);
end

if isa(yorig,'dataset');
  yorig.data = gys;
  gys = yorig;
end

%-------------------------------------------------------
function [gx] = gscaler1(newdata,mx,stdx,undo)
%GSCALER1 group scales a new matrix.
%  GSCALER1 scales a matrix (newdata) using a vector
%  of means (mx) and a vector of standard deviations
%  (stdx), and returns the resulting matrix (gx).
%  (mx) is subtracted from each row of newdata the result
%  is divided by sqrt(sum(stdx.^2)). GSCALER is typically
%  used to scale new MPCA data to the mean and variance
%  of previously analyzed MPCA data.
%
%  Additional REQUIRED input flag "undo" specifies if this is a scale or
%  REscale process (undo = 1 means REscale)
%
%I/O: [gx] = gscaler(newdata,mx,stdx,undo);

%Copyright Eigenvector Research, Inc. 1996-2002

[m,n] = size(newdata);
stdt  = stdx.^2;
stdt  = sqrt(sum(stdt));
if stdt==0;
  stdt = 1;
end

if ~undo
  gx    = (newdata-mx(ones(m,1),:))/stdt;
else
  gx    = (newdata*stdt)+mx(ones(m,1),:);
end
