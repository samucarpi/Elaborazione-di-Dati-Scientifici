function lrspec = deresolv(hrspec,a)
%DERESOLV Changes high resolution spectra to low resolution.
%  Uses a FFT to convolve spectra with a resolution function to 
%  make it appear as if it had been taken on a lower resolution instrument.
%  Inputs are the high resolution spectra to be de-resolved (hrspec)
%  and the number of channels to convolve them over (a). The output
%  is the estimate of the lower resolution spectra (lrspec).
%
%I/O: lrspec = deresolv(hrspec,a);
%I/O: deresolv demo
%
%See also: BASELINE, COADD, REGISTERSPEC, SAVGOL, STDFIR, STDGEN

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified BMW  April 97
%4/03 Modified help

if nargin == 0; hrspec = 'io'; end
varargin{1} = hrspec;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; lrspec = evriio(mfilename,varargin{1},options); end
  return; 
end

[m,n] = size(hrspec);
lrspec = zeros(m,n);
tlrspec = lrspec;
dif = -1;
i = 0;
while dif < 0 
  i = i+1;
  fftl = 2^i;
  dif = fftl - n;
end
conf = zeros(1,fftl);


for k = 1:a
  conf = zeros(1,fftl);
  if k == 1
    conf(1) = .5;
    conf(fftl) = .5;
  else
    conf(1:k+1) = 1:(-1/(k)):0;
    conf(fftl-(k):fftl) = 0:(1/(k)):1;
    conf = conf/(sum(conf));
  end
  conffft = fft(conf);
  for i = 1:m
    padspec = [hrspec(i,:) zeros(1,fftl-n)];
    specfft = fft(padspec);
    convspec = ifft(specfft.*conffft);
    tlrspec(i,:) = real(convspec(1:n));
  end  
  lrspec(:,k:n-k+1) = tlrspec(:,k:n-k+1);
end
