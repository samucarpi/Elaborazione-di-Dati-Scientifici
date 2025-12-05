function [z,r,a,xsit,p,a0,t] = shiftmap(x,p,a0,options)
%SHIFTMAP Calculates Shift Invariant Tri-linear factor matrix
%  Calculates Shift Invariant Tri-linear factor matrices (xsit) and (xsist)
%  for the columns of MxN input (x).
%  SHIFTMAP also returns z = fft(x), r = |fft(x)| and phase spectra (a).
%  The FFTs are zero padded to Np = max(2^nextpow2(M),options.np).
%  
%  For K = options.ncomp (number of PCs), the outputs (xsit) and (xsist)
%  are defined as follows.
%      xsit = Shift Invariant Trilinearity based on |FFT(x)|' = T*P'
%             where T (NxK), P (NpxK), and q = sum((|FFT(x)|' - TP').^2,2).
%     xsist = Shift Invariant Soft Trilinearity based on 
%             iFFT(|FFT(x)|*diag(A))' = Tb*Pb' where
%             Tb (NxK), Pb (NpxK), and qb = sum((|FFT(x)|' - TP').^2,2).
%             The matrix A = a(I) where [~,I] = min(qb).
%  (xsit) and (xsist) are truncated to MxN matrices prior to output.
%
%  During prediction, it is expected that size(x,1) = M of the calibration
%  data. However, SHIFTMAP outputs (xsit) as long as size(x,1)<=Np and 
%  size(xsit,1) will equal size(x,1).
%
%  INPUT:
%         x = MxN [class double] operates on the columns with zero 
%             padding governed by Np = options.np.
%             If options.np is empty {default} then Np is set to 
%             Np = max(2^nextpow2(M),options.np).
%
%  OPTIONAL INPUTS:
%         p = If (p) is not input or is empty, then SHIFTMAP calibrates PCA
%             NxK loadings: p = P for SIT and p = Pb for SITS.
%             If input (p) corresponds to a loadings matrix it is 
%             used in prediction.
%
%   options = structure array with the following fields:
%          np = nonnegative scalar length of padding for FFT, Np.
%               If options.np is empty {default} then Np is set to 
%               Np = 2^nextpow2(M).
%               If not empty, then Np is set to
%               Np = max(2.^nextpow2(M),2.^options.np).
%       ncomp = 1 {default}  %Number of PCs, K, for SIT and SIST.
%   algorithm = [{'sit'} | 'sist'];
%
%  OUTPUTS:
%         z = fft(x,options.np).
%         r = |z| where z = |z|.*exp(i*a).
%         a = phase angle in radians.
%         p = NpxK loadings: p = P for SIT and p = Pb for SIST.
%        a0 = standard phase spectrum (for SIST only). 
%         t = MxK scores: t = T for SIT and t = Tb for SITS.
%      xsit = Shift Invariant Trilinearity based on |FFT(x)|' = T*P' or
%           = Shift Invariant Soft Trilinearity based on 
%               iFFT(|FFT(x)|*diag(A))' = Tb*Pb'
%    
%I/O: [z,r,a,xsit,p,a0,t] = shiftmap(x,options); % calibration step
%I/O: [z,r,a,xsit]      = shiftmap(x,p);       % prediction for SIT
%I/O: [z,r,a,xsit]      = shiftmap(x,p,a0);    % prediction for SITS
%
%See also: ALS_SIT, SHIFTMAPDEMO

%Not yet DSO enabled, nor tested
%    classset = 1 {default}, if isdataset(x), defines class set for reshape
%               , or
%             b) Mx1 [class DataSet], were M is divided into N unique
%                classes identified by the class field:
%                  x.class{1,options.classset}.
%                Note: class{1,options.classset}==0 is not used.
%                If the maximum length of the N classes is nmax, then zero 
%                padding is governed by options.np and padding given by
%                  J = max(nextpow2(nmax),options.np) yielding a JxN zero
%                padded matrix.

% Copyright © Eigenvector Research, Inc. 2022
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%% Check I/O, Options
if nargin==0; x = 'io'; end
if ischar(x)
  options       = [];
  options.name  = 'options';
  options.np    = [];        % n padding = max(2.^nextpow2(m(1)),2.^options.np)
  options.algorithm = 'sit'; % 'sist'
  options.ncomp = 1;         % Number of PCs/factors for SIT and SITS
  options.maxpc = 20;        % {not yet documented}

  if nargout==0;  evriio(mfilename,x,options); 
  else;       z = evriio(mfilename,x,options); end
  return
end

%% Check I/O, Predictmode, and set options.algorithm
predictmode     = false;
if nargin<2
  options       = shiftmap('options');
  p             = [];
  a0            = [];
  predictmode   = false;
end
if nargin==2
  if isstruct(p)
    options     = p;
    p           = [];
    a0          = [];
    predictmode = false;
  else
    options     = shiftmap('options'); %default algorithm = 'sit'
    if ~isa(p,'double')
      error('Input (p) must be a matrix of size Np x options.ncomp.')
    end
    a0          = [];
    predictmode = true;
  end
end
if nargin==3
  if isstruct(a0)
    options     = a0;
    a0          = [];
    options.algorithm = 'sit';
  else
    if ~isa(a0,'double')
      error('Input (a0) must be a matrix of size Np x 1.')
    end
    options.algorithm = 'sist';
  end
  if ~isa(p,'double')
    error('Input (p) must be a matrix of size Np x options.ncomp.')
  end
  predictmode   = true;
end
if nargin>1
  options       = reconopts(options,'shiftmap');
end

%% Initialize and FFT

% options.classset    = 1;  %if isdataset(x), defines class set for reshape
% if isdataset(x)
%   if size(x,2)>1
%     error('input (x) DataSet Obect cannnot have more than 1 column.')
%   end
%   n       = setdiff(unique(x.class{1,options.classset}),0);
%   nlength = length(n);
%   nl      = zeros(1,nlength);
%   nk      = cell(1,nlength);
%   for i1=1:nlength
%     nk{i1}      = find(x.class{1,options.classset}==n(i1));
%     nl(i1)      = length(nk{i1});
%   end
%   y       = zeros(max(nl),nlength);
%   for i1=1:nlength
%     y(nk{i1},i1)   = x.data(nk{i1},1);
%   end
%   m       = size(y);
%   t       = 2.^nextpow2(m(1));
%   if isempty(options.np)||options.np<t
%     options.np  = t;
%   end
% 
%   [z,r,a] = phasemap(y,options.np); %fft(x), |fft(x)|, angle
% else            % MxN class double
  if ~predictmode % calibrate mode
    m           = size(x);
    t           = 2.^nextpow2(m(1));
    if isempty(options.np)||options.np<t
      options.np  = t;
    end
    [z,r,a]     = phasemap(x,options.np);
  else          % predict mode
    if size(x,1)>size(p,1)
      error('Size of input (x) must be <= Np.')
    end
    [z,r,a]     = phasemap(x,size(p,1));
  end
% end

%% Shift Invariant Trilinearity
if nargout>3
  if ~predictmode % calibrate mode
    switch lower(options.algorithm)
    case 'sit' % SIT
      if options.ncomp<1
        [ssq,~,p,t] = pcaengine(r',options.maxpc,struct('display','off'));
        k           = find((ssq(:,4)/100)>=options.ncomp);
        p           = p(:,1:k(1));
        t           = t(:,1:k(1));
      else
        [~,~,p,t]   = pcaengine(r',options.ncomp,struct('display','off'));
      end   
      xsit          = real( ifft((p*t').*(cos(a) + 1i*sin(a))) );
      a0            = [];
    case {'sist','sits'} % SIST
      if options.ncomp<1
        [ssq,~,p,t]     = pcaengine(r',options.maxpc,struct('display','off'));
        k           = find((ssq(:,4)/100)>=options.ncomp);
        p           = p(:,1:k(1));
        t           = t(:,1:k(1));
      else
        [~,~,p,t]   = pcaengine(r',options.ncomp,struct('display','off'));
      end
      [~,i1]        = min(sum((r-p*t').^2)); %residuals
      a0            = a(:,i1);
      xsit          = real( ifft(spdiag(cos(a0) + 1i*sin(a0))*r) );
      if options.ncomp<1
        [ssq,~,p,t] = pcaengine(xsit',options.maxpc,struct('display','off'));
        k           = find((ssq(:,4)/100)>=options.ncomp);
        p           = p(:,1:k(1));
        t           = t(:,1:k(1));
      else
        [~,~,p,t]   = pcaengine(xsit',options.ncomp,struct('display','off'));
      end
      ts            = abs(fft(p*t',options.np));
      xsit          = real( ifft(ts.*(cos(a) + 1i*sin(a))) );
    end
    xsit            = xsit(1:m(1),:); % xsit(xsits<0) = 0;
    %   if isdataset(x)
    %     xsit  = copydsfields(x,dataset(xsit));
    %   end

  else  % predict mode
    switch lower(options.algorithm)
    case 'sit'
      xsit          = real( ifft((p*(p'*r)).*(cos(a) + 1i*sin(a))) );
    case {'sist','sits'}
      xsit          = real( ifft(spdiag(cos(a0) + 1i*sin(a0))*r) );
      t             = abs(fft(p*(p'*xsit)));
      xsit          = real( ifft(t.*(cos(a) + 1i*sin(a))) );
    end
    xsit            = xsit(1:size(x,1),:);
%     if isdataset(x)
%       xsit  = copydsfields(x,dataset(xsit));
%     end
  end
end

end %SHIFTMAP

function [z,r,a] = phasemap(x,np)
  z       = fft(x,np);
  r       = abs(z);
  a       = angle(z);
end %PHASEMAP