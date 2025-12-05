function [stdmat, stdvect] = sstcal(spec1,spec2,ncomp,options)
%SSTCAL Create and apply Spectral Subspace Transformation calibration transfer.
%
%  INPUTS:
%    spec1 = M by N1 spectra from the standard instrument, and
%    spec2 = M by N2 spectra from the instrument to be standarized.
%    ncomp = Number of PCs to use.
%
%  OPTIONS:
%  options = structure array with the following fields:
%    waitbar: ['off' | {'on'}]  governs display of waitbar.
%
%  OUTPUTS:
%    stdmat = the transform matrix, and
%   stdvect = the additive background correction.
%
%I/O: [stdmat, stdvect] = sstcal(spec1,spec2,ncomp,options);%Calibrate.
%
%See also: ALIGNMAT, CALTRANSFER, GLSW, OSCAPP, OSCCALC, STDGEN, STDIZE

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rtr

if nargin == 0
  spec1 = 'io';
end

if ischar(spec1);
  options = [];
  options.waitbar     = 'off';
  %options.definitions = @optiondefs;
  if nargout==0
    clear stdmat; 
    evriio(mfilename,spec1,options); 
  else
    stdmat = evriio(mfilename,spec1,options); 
  end
  return
end

if nargin<4
  options  = [];
end
options = reconopts(options,mfilename);

%Check for valid data.
if isa(spec1,'dataset')
  i1 = spec1.includ{1};
else
  i1 = 1:size(spec1,1);
end
if isa(spec2,'dataset')
  i2 = spec2.includ{1};
else
  i2 = 1:size(spec2,1);
end
if length(i1)~=length(i2) || length(i1)~=length(intersect(i1,i2))
  warning('EVRI:IncludeIntersect','Samples included in data sets do not match. Using intersection.')
  i1 = intersect(i1,i2);
  i2 = i1;
end
%index into spec1 and spec2 as indicated by include
spec1 = nindex(spec1,i1,1);
spec2 = nindex(spec2,i2,1);
if isa(spec1,'dataset')
  i     = spec1.include;
  spec1 = spec1.data(i{:});
end
if isa(spec2,'dataset')
  i     = spec2.include;
  spec2 = spec2.data(i{:});
end
[ms,ns]   = size(spec1);
[ms2,ns2] = size(spec2);
if ms ~= ms2
  error('Both data sets must have the same number of samples')
end
if ~isequal(ns, ns2)
  error('Both data sets must have the same number of included variables')
end

%Check 3rd input.
if nargin<3
  ncomp = 1;
elseif isempty(ncomp)
  ncomp = 1;
end

%Check ncomp
if ncomp > min(ms, ns)
  ncomp = min(ms, ns);
end

if isequal(nargout, 2)
  [mspec1, mns1] = mncn(spec1);
  [mspec2, mns2] = mncn(spec2);
else
  mspec1 = spec1;
  mspec2 = spec2;
end

clear spec1 spec2
num_vars = size(mspec1,2);

comb_data = [mspec1 mspec2];
[u,s,v] = svd(comb_data);
p1 = v(1:num_vars, 1:ncomp);
p2 = v(num_vars+1:end, 1:ncomp);

stdmat = eye(num_vars)+pinv(p2')*(p1'-p2');

if isequal(nargout, 2)
  stdvect = mns1 - mns2*stdmat;
end





