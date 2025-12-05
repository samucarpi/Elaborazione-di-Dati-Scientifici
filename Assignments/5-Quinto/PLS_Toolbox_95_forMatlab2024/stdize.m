function stdspec = stdize(nspec,stdmat,stdvect);
%STDIZE Applies transform from STDGEN to new spectra.
%  Inputs are the new spectra to be standardized (nspec), and
%  the standardization matrix (stdmat).
%  Optional input (stdvect) is the additive background correction.
%  [Note: if (stdvect) was calculated using STDGEN then it should
%  be used when applying the transform here in STDIZE.]
%
%  The output is the standardized spectra (stdspec).
%  The standardization matrix and background correction can be
%  obtained using the function STDGEN.
%
%I/O: stdspec = stdize(nspec,stdmat,stdvect);
%I/O: stdize demo
%
%See also: CALTRANSFER, STDGEN, STDSSLCT

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%bmw 5/30/97, nbg 2/23/98,12/98

if nargin == 0; nspec = 'io'; end
varargin{1} = nspec;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear stdspec; evriio(mfilename,varargin{1},options); else; stdspec = evriio(mfilename,varargin{1},options); end
  return; 
end

if (isa(nspec,'dataset'))
  % if it's a dataset
  i = nspec.include;
  nspec = nspec.data(i{:});
end

if nargin<3
  [ms,ns] = size(nspec);
  [mm,nm] = size(stdmat);
  if ns~=mm
    error('Spectrum and transfer matrix sizes not compatible')
  end
  stdspec = nspec*stdmat;
else
  [ms,ns] = size(nspec);
  [mm,nm] = size(stdmat);
  [mv,nv] = size(stdvect);
  if (ns~=mm | nm~=nv)
    error('Spectrum, transfer matrix and background vector sizes not compatible')
  end
  if issparse(stdmat)
    stdmat=full(stdmat);
  end
  stdspec = nspec*stdmat + ones(ms,1)*stdvect;
end
