function [cumpress] = savgolcv(x,y,lv,width,order,deriv,ind,rm,cvi,pre)
%SAVGOLCV Cross-validation for Savitzky-Golay smoothing and differentiation.
%  SAVGOLCV performs cross-validation of Savitzky-Golay parameters
%  filter width, polynomial order, and derviative order.
%  INPUT:
%    x     = (m by n) matrix of predictor variables with ROW 
%            vectors to be smoothed (e.g. spectra).
%    y     = (m by p) matrix of predicted variables.
%    ind   = indices of columns of x to use for calibration
%            {default = [1:n] i.e. all x columns}. In some cases
%            fewer channels are used for calibration. These channels
%            are given in the vector (ind). SAVGOLCV uses all channels
%            for smoothing/derivitizing but only the (ind) channels in
%            the cross-validation/prediction.
%
%  SAVITZKY-GOLAY PARAMETERS (calls SAVGOL)
%    The following variables are cross-validated by entering 
%    a vector instead of a scalar.
%    width = number of points in filter {default = [11 17 23]}.
%    order = polynomial order {default = [2 3]}.
%    deriv = derivative order {default = [0 1 2]}.
%
%  CROSS-VALIDATION METHOD (calls CROSSVAL)
%    lv    = number of latent variables {default = min(size(x))}.
%    rm    = regression method (class "char"). Options are:
%      'nip'  = PLS via NIPALS algorithm,
%      'sim'  = PLS via SIMPLS algorithm {default}, and
%      'pcr'  = PCR.
%    cvi   = cross validation method (class "cell"). Options are:
%      {'loo'}          = leave-one-out,
%      {'vet', splits}  = venetian blinds {default},
%      {'con', splits}  = contiguous blocks, and
%      {'rnd', splits, its}  = repeated random test sets.
%      (splits) = number of subsets to split the data into {default = 5}
%                 (needed for cvm = 'vet', 'con', and 'rnd').
%      (iter)   = number of iterations {default = 5} (needed for cvm = 'rnd').
%      (cvi) can be a vector with the same number of elements as x has rows
%         see CROSSVAL
%    pre   = {xp yp}; cell array containing preprocessing structures for
%            both the xblock (xp) and yblock (xp).
%
%  OUTPUT:
%    cumpress(i,:,:,:) = deriv;
%    cumpress(:,j,:,:) = lv;
%    cumpress(:,:,k,:) = width;
%    cumpress(:,:,:,l) = order;
%
%I/O: cumpress = savgolcv(x,y,lv,width,order,deriv,ind,rm,cvi,pre); %for x class "double"
%I/O: cumpress = savgolcv(x,y,lv,width,order,deriv,[],rm,cvi,pre);  %for x class "dataset"
%I/O: savgolcv demo
% 
%See also: BASELINE, CROSSVAL, LAMSEL, MSCORR, SAVGOL, SPECEDIT, STDFIR

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 3/24/99
%jms changed the crossval call
%nbg 4/08 added a line on help for cvi

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear cumpress; evriio(mfilename,varargin{1},options); else; cumpress = evriio(mfilename,varargin{1},options); end
  return; 
end

h      = waitbar(0,'Setting up.');
if isempty(x)|isempty(y)
  error('Input (x) or (y) is empty, both are required.')
end
if isa(x,'dataset')&isa(y,'dataset')
  y    = y.data(x.includ{1},y.includ{2});
  ind  = x.includ{2};
  x    = x.data(x.includ{1},:);
elseif isa(x,'double')&isa(y,'double')
  % do nothing
else
  error('(x) and (y) both need to be class "double" or "data".')
end

if exist('lv')~=1
  lv   = min(size(x));
elseif isempty(lv)
  lv   = min(size(x));
end
if lv>min(size(x))
  lv   = min(size(x));
end
if exist('width')~=1
  width = [11 17 23];
elseif isempty(width)
  width = [11 17 23];
end
if exist('order')~=1
  order = [2 3];
elseif isempty(order)
  order = [2 3];
end
if exist('deriv')~=1
  deriv = [0 1 2];
elseif isempty(deriv)
  deriv = [0 1 2];
end
if exist('rm')~=1
  rm    = 'sim';
elseif isempty(rm)
  rm    = 'sim';
end
if exist('cvi')~=1
  cvi   = {'vet' 5 5};
elseif isempty(cvi)
  cvi   = {'vet' 5 5};
end
if exist('pre')~=1
  pre   = 1;
elseif isempty(pre)
  pre   = 1;
end

cumpress = zeros(length(deriv),lv,length(width),length(order), size(y,2));

waitbar(0,h,'Starting Cross-Validation.')

for i1=1:length(deriv)
  for i2 = 1:length(width);
    for i3 = 1:length(order);
      for iy = 1:size(y,2)
        xh = savgol(x,width(i2),order(i3),deriv(i1));
        [ps,cumpress(i1,[1:lv],i2,i3, iy)] = crossval(xh(:,ind),y(:,iy),rm,cvi,lv,0,pre);
      
      end
    end
  end
  waitbar(i1/length(deriv),h,'Cross-Validating')
end
close(h)
