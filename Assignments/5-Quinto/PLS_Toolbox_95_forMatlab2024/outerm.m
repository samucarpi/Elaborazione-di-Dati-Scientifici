function mwa = outerm(facts,lo,vect)
%OUTERM Computes outer product of any number of vectors.
%  The input to outerm is a 1 by N cell array (facts), where each cell
%  contains a matrix of factors for one of the modes. Each factor is
%  a column in the matrix e.g. Mode 2, Factor 3: is facts{2}(:,3).
%
%  The output (mwa) is the multiway array resulting from multiplying each
%  factor together as an outer product and summing the result. (See input
%  (vect) to get individual factors.)
%
%  Optional input (lo) is the number of a mode to leave out in the
%  formation of the outer product. Use (lo = 0) to not leave out a mode.
%
%  Optional input (vect) causes the function to not sum the factors when
%  when set to 1 {default = 0}. If (vect = 1) then the columns of (mwa)
%  correspond to the vectorized outer product of each factor. (This option
%  is used in the alternating least squares steps in PARAFAC.)
%
%  Examples:
%    If facts{1} is 1000x4, facts{2} is 100x4 and facts{3} is 10x4
%    (i.e. there are 3 modes and 4 factors)
%    mwa = outerm(facts);      gives mwa 1000x100x10.
%    mwa = outerm(facts,1);    gives mwa 100x10.
%    mwa = outerm(facts,0,1);  gives mwa 1000*100*10x4
%
%I/O: mwa = outerm(facts,lo,vect);
%
%See also: GRAM, MPCA, NPLS, PARAFAC, PARAFAC2, TLD, TUCKER, UNFOLDMW

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%bmw
%nbg 05/03 changed the help

if nargin == 0; facts = 'io'; end
varargin{1} = facts;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; mwa = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin < 2
  lo = 0;
end
if nargin < 3
  vect = 0;
end
order = length(facts);
if lo == 0
  mwasize = zeros(1,order);
else
  mwasize = zeros(1,order-1);
end
k = 0;
for i = 1:order
  if i ~= lo
    [m,n] = size(facts{i});
    k = k + 1;
    mwasize(k) = m;
    if k > 1
      if nofac ~= n
        error('All orders must have the same number of factors')
      end
    else
      nofac = n;
    end
  end
end
mwa = zeros(prod(mwasize),nofac);

for j = 1:nofac
  if lo ~= 1
    mwvect = facts{1}(:,j);
    for i = 2:order
	  if lo ~= i
        %mwvect = kron(facts{i}(:,j),mwvect);
		mwvect = mwvect*facts{i}(:,j)';
		mwvect = mwvect(:);
	  end
    end
  elseif lo == 1
    mwvect = facts{2}(:,j);
	for i = 3:order
      %mwvect = kron(facts{i}(:,j),mwvect);
	  mwvect = mwvect*facts{i}(:,j)';
	  mwvect = mwvect(:);
	end
  end
  mwa(:,j) = mwvect;
end
% If vect isn't one, sum up the results of the factors and reshape
if vect ~= 1
  mwa = sum(mwa,2);
  mwa = reshape(mwa,mwasize);
end
