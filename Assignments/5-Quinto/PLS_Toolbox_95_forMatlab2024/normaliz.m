function [dat,norms] = normaliz(dat,out,normtype,window)
%NORMALIZ Normalize rows of matrix.
%  This function can be used for pattern normalization, which is useful for
%  preprocessing in some pattern recognition applications and also for
%  correction of pathlength effects for some quantification applications.
%
% INPUTS:
%         dat = the data matrix or a DataSet object
% OPTIONAL INPUTS:
%         out = a flag which suppress warnings when set to 0 {default = 0}
%    normtype = the type of norm to use {default = 2}. The following are
%               typical values of normtype:
%                normtype       description              norm
%                  1       normalize to unit area       sum(abs(dat))
%                  2       normalize to unit LENGTH     sqrt(sum(dat^2))
%                  inf     normalize to maximum value   max(dat)
%               Generically, for row i of dat:
%                 norms(i) = sum(abs(dat(i,:)).^normtype)^(1/normtype)
%               If (normtype) is specified then (out) must be included,
%               although it can be empty [].
%      window = indicies which should be used to calculate the norm.
% ALTERNATIVE INPUT:
%     options = An options structure can be passed as third input along
%               with (dat) and (normtype). This input takes the place 
%               of the remaining inputs and should contain one or more of
%               the following fields: 
%          display : [ 'off' |{'on'}] controls display (replacement for
%                     (out) input above)
%          window  : [] replacement for standard (window) input above.
% OUTPUTS: 
%    ndat = the matrix of normalized data where the rows have been
%            normalized. If input (dat) was a DataSet object, then ndat
%            will also be a DataSet object.
%   norms = the vector of norms used for normalization of each row.
%
% Unless out = 0, warnings are given when any vectors have zero norm.
%
%Example: [ndat,norms] = normaliz(x,[],1);
%
%I/O:  [ndat,norms] = normaliz(dat);
%I/O:  [ndat,norms] = normaliz(dat,out,normtype,window);
%I/O:  [ndat,norms] = normaliz(dat,normtype,options);
%
%See also: AUTO, BASELINE, MNCN, MSCORR, POLYTRANSFORM, SNV

% Copyright © Eigenvector Research, Inc. 1997
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%bmw May 30, 1997
%nbg 1/11/00 added out
%jms 8/2/01 added precalc of norm to speed up loop
%    8/3/01 added option for other types of norm (1 norm, inf norms, etc.)
%    3/7/01 modified error checking on inputs
%jms 3/21/03 -added speed improvement to final normalization (use loop if > n samples)
%jms 6/23/03 changed warning message when >1 sample have zero norm
%jms 1/28/04 -fixed inf-norm problem.

if nargin == 0; dat = 'io'; end
if ischar(dat);
  options = [];
  options.display = 'on';
  options.window  = [];
  if nargout==0; evriio(mfilename,dat,options); clear dat; else; dat = evriio(mfilename,dat,options); end
  return; 
end

if nargin<2 | isempty(out)
  out = 0;
end
if nargin==2 & isstruct(out)
  %I/O:   (data,options)
  options  = reconopts(out,mfilename);
  out      = strcmp(options.display,'on');
  window   = options.window;
  normtype = [];
elseif nargin==3 & isstruct(normtype)
  %I/O:   (data,normtype,options)
  options = reconopts(normtype,mfilename);
  normtype = out;
  out      = strcmp(options.display,'on');
  window   = options.window;
else
  %other I/O:
  if nargin == 2 & out > 1;
    error('Unrecognized input option for ''out''');
  end
  if nargin<3
    normtype = [];
  end
  if nargin<4
    window = [];
  end
end

%default values for missing inputs
if isempty(normtype)
  normtype = 2;
end
origsize = size(dat);
if isempty(window)
  window = 1:prod(origsize(2:end));
end

%if it is a dataset, extract data
wasdataset = isdataset(dat);
if wasdataset
  originaldata = dat;
  incl = dat.include;
  if ndims(dat)==2;
    %2-way
    window       = intersect(window,dat.include{2});
  elseif any(cellfun(@(i) length(i),incl(2:end))<origsize(2:end));
    %nway with any exclusions on variables
    window = reshape(window,origsize(2:end));
    window = nindex(window,incl(2:end),1:length(incl)-1);
    window = window(:)';
  end
  dat          = dat.data;
end

if length(origsize)>2
  dat = dat(:,:);
end

%make sure window is valid
window = intersect(window,1:prod(origsize(2:end))); 
if isempty(window);
  error('All normalization window points are excluded')
end

%calculate norms (but use loop to avoid memory hogging)
sampwinsize = 100;
norms = zeros(size(dat,1),1);
for j=1:sampwinsize:size(dat,1);
  sampwin = j:min(size(dat,1),j+sampwinsize-1);
  fdat = dat(sampwin,window);
  switch normtype
    case 1
      fdat(~isfinite(fdat)) = 0;  %missing data can be replaced with zero
      norms(sampwin,1) = sum(abs(fdat),2);
    case inf
      norms(sampwin,1) = max(abs(fdat),[],2);
    otherwise
      fdat(~isfinite(fdat)) = 0;  %missing data can be replaced with zero
      norms(sampwin,1) = sum(abs(fdat).^normtype,2).^(1/normtype);
  end
end


%locate any zero norms
ii    = find(norms==0);
if ~isempty(ii) & out
  if length(ii)==1
    disp(sprintf('The norm of sample %g is zero; sample not normalized',ii))
  else
    disp(sprintf('%g samples have a norm of zero and were not normalized',length(ii)))
  end
end
ii    = find(norms~=0);

%normalize data
if length(ii)<50;  %fewer than n samples? use matrix
  dat(ii,:) = dat(ii,:)./norms(ii,ones(1,size(dat,2)));
else   %otherwise use loop
  for ij = ii(:)';
    dat(ij,:) = dat(ij,:)./norms(ij,1);
  end
end

if length(origsize)>2
  dat = reshape(dat,origsize);
end

if wasdataset
  %re-insert back into dataset (if it was to begin with)
  originaldata.data = dat;
  dat = originaldata;
end
