function [x,psf] = line_filter(x,win,options)
%LINE_FILTER spectral filtering via convolution, and deconvolution.
%  INPUTS:
%      x = MxN matrix of data of class 'double' or 'dataset'.
%          If 'dataset' it must x.type=='data'.
%          Each of the M rows are convolved with the linear filter
%          given in (options.lineshape).
%    win = filter window - can be input in two ways:
%       1) A scalar parameter corresponding to the analogous window width 
%          of the filter.
%          options.psf = 
%            'gaussian', (win) corresponds to the std in the Gaussian distribution.
%            'box', (win) is the half-width in number of channels.
%            'triangular', (win) is the half-width in channels.
%            'manual', win is a 1xN vector.
%       2) If (win) is 1xN vector, then it is used as the PSF and
%          (options.psf) is ignored. The FFT of the PSF is calculated
%          and used in the convolution or deconvolution algorithm. In this case,
%          if y is a vector with the psf centered at (N+2)/2 for N even,
%          or (N+3)/2 for N odd, then psf = fftshift(fft(win,[],2),2);
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%     psf: [ {'gaussian'} | 'box' | 'triangular' | 'welch' | 'hann' |
%            'centraldifference' ]
%          Line shape or point source function (PSF) for filtering.
%    conv: [ {'convolve'} | 'deconvolve' ] Governs the algorithm and
%          tells it to convolve with the point source function given
%          in (options.psf) or deconvolve. If 'deconvolve', then
%          (options.reg) is used.
%          psf = 'box' is not recommended for deconvolution.
%     reg: {1e-16} regularization parameter. psf frequencies with power
%          < reg*max(power) are ignored (this avoids small signals
%          corrupting the estimate.
%
%  OUTPUTS:
%     xf = Filtered data of class 'dataset'.
%
%  EXAMPLE:
%    load nir_data
%    x2 = spec1.data(1,:);
%    [d1,d] = savgol(x2,11,2,2);    %where x2 is 1x401 double
%    d   = fftshift(full(d(:,202))',2);
%    xf  = line_filter(spec1(1,:),d);
%    xfu = line_filter(xf,d,struct('conv','deconvolve'));
%    figure, plot(1:401,x2,'b',1:401,xfu.data,'r')
%    figure, plot(1:401,x2,'b',1:401,wlsbaseline(xfu.data,0),'r')
%
%I/O: xf = line_filter(x,win,options);
%
%See also: FFT, FFTSHIFT, LINE_FILTERB, SAVGOL

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%NBG 1/09 modified spatial_filter to perform filtering w/ convolution

%add io xf = line_filter(x,psf); where psf is a 1xN vector of the line
%    shape
%should add support for ND arrays

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  options.name    = 'options';
  options.psf     = 'gaussian';
  options.conv    = 'convolve'; %'deconvolve'
  options.reg     = 1e-16;  
  if nargout==0;
    evriio(mfilename,x,options);
    clear x;
  else
    x     = evriio(mfilename,x,options);
  end
  return;
end

if nargin<3               %set default options
  options = line_filter('options');
else
  options = reconopts(options,line_filter('options'));
end

if nargin<2
  error('LINE_FILTER requires at least 2 inputs.')
end

if ~isa(x,'dataset')
  x   = dataset(x);
end
m     = size(x);
if mod(m(2),2)==0
  psfct = (m(2)+2)/2;
else
  psfct = (m(2)+3)/2;
end
if size(win,2)==m(2)
  options.psf = 'manual';
end

%Check Inputs
if isempty(win)
  error('Input (win) must not be empty.')
end
switch lower(options.psf)
case {'gaussian', 'gauss','normal'}
  psf = normdf('density',1:m(2),psfct,win);
  psf = fftshift(psf,2);
case {'box', 'square'}
  psf = zeros(1,m(2));
  psf(ceil(psfct-win):floor(psfct+win))  = 1;
  psf = fftshift(normaliz(psf,[],1),2);
case {'triangular', 'triangle','bartlett'}
  psf = zeros(1,m(2));
  aa  = 0:length(ceil(psfct-win):psfct)-1;
  psf(ceil(psfct-win):psfct)  = aa;
  psf(psfct:floor(psfct+win)) = fliplr(aa);
  psf = fftshift(normaliz(psf,[],1),2);
case {'welch','polynomial2'}
  psf = zeros(1,m(2));
  aa  = length(ceil(psfct-win):psfct)-1:-1:0;
  aa  = 1-(aa/max(aa)).^2;
  psf(ceil(psfct-win):psfct)  = aa;
  psf(psfct:floor(psfct+win)) = fliplr(aa);
  psf = fftshift(normaliz(psf,[],1),2);
case {'hann'}
  psf = zeros(1,m(2));
  aa  = length(ceil(psfct-win):psfct)-1:-1:0;
  aa  = (1+cos(pi*aa/max(aa)))/2;
  psf(ceil(psfct-win):psfct)  = aa;
  psf(psfct:floor(psfct+win)) = fliplr(aa);
  psf = fftshift(normaliz(psf,[],1),2);  
case {'centraldifference', 'central'}
  psf = zeros(1,m(2));
  psf(psfct+1) =  0.5;
  psf(psfct-1) = -0.5;
  psf = fftshift(psf,2);
case 'manual'
  psf = win;
otherwise
  error(['OPTIONS.PSF not recognized: ',options.psf])
end
% switch lower(options.psf)
% case {'gauss','gaussian','box','square','triangular'}
%   psf(ceil(m2):end) = fliplr(psf(1:floor(m2)));
% end
psf   = fft(psf,[],2); %fft(normaliz(psf,[],1));

switch lower(options.conv)
case {'convolve','conv'} %might add padding as an optionhere
  x.data  = fft(x.data,[],2);
  if m(2)>m(1)
    x.data  = real(ifft(x.data.*(ones(m(1),1)*psf),[],2));
  else
    x.data  = real(ifft(x.data*diag(psf),[],2));
  end
case {'deconvolve','deconv'}
  x.data  = fft(x.data,[],2);  %might add padding here
  aa      = conj(psf).*psf;
  iaf     = find(aa>options.reg*max(aa));
  x.data  = x.data*diag(conj(psf));
  x.data(:,setdiff(1:m(2),iaf)) = 0;
  x.data(:,iaf) = x.data(:,iaf)*diag(1./aa(:,iaf));
  x.data  = real(ifft(x.data,[],2));
end
if nargout>1
  psf = ifftshift(ifft(psf));
end
