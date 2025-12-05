function sx = scale(x,means,stds,options)
%SCALE Scales data using specified means and std. devs.
%  Scales a matrix or multi-way array (x) using means (means) and standard
%  deviations (stds) specified. An optional input (options) is an options
%  structure with the field:
%     stdthreshold: [0] scalar value or vector of standard deviation
%                   threshold values. If a standard deviation is below its
%                   corresponding threshold value, the threshold value will
%                   be used in lieu of the actual value. A scalar value is
%                   used as a threshold for all variables.
%     samplemode: [1] mode of x which should be considered the "sample"
%                   mode. Default is 1, rows. This is the mode over which
%                   the scaling and subtracting are done.
%
%I/O: sx = scale(x,means,stds,options);
%
%  If only two input arguments are supplied or stds is empty, then the
%  function will not do variance scaling, but only vector subtraction.
%  If means is empty, a vector of all zeros will be used (no subtraction)
%
%I/O: sx = scale(x,means);
%
%
%See also: AUTO, CLASSCENTER, GSCALE, GSCALER, LOGDECAY, MEDCN, MNCN, NPREPROCESS, PREPROCESS, RESCALE

% Copyright © Eigenvector Research, Inc. 1991
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Modified 11/93 
%Checked on MATLAB 5 by BMW  1/4/97
%Added support for non-doubles (do by rows) by JMS 6/21/2001
%JMS 2/5/04 -added use of loop if > some # of samples
%  -revised non-double logic
%JMS 10/04 -added test for zero standard deviation

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  options.stdthreshold = 0;
  options.samplemode   = 1;
  if nargout==0; clear sx; evriio(mfilename,x,options); else; sx = evriio(mfilename,x,options); end
  return; 
end

%make sure we've got row vectors
means = means(:)';
if nargin < 3
  stds = [];
else
  stds = stds(:)';
end
if nargin<4;
  options = [];
end
options = reconopts(options,mfilename,{'offset' 'badreplacement'});

%check for DataSet object
originaldso = [];
if isdataset(x)
  originaldso = x;
  incl = x.include;
  if length(options.stdthreshold)==size(x,2);
    %apply include field to stdthreshold (if applicable)
    options.stdthreshold = options.stdthreshold(incl{2});
  end
  %extract data from x (all samples)
  if (size(originaldso.data(:,incl{2:end}),2) == size(means,2)) | (size(originaldso.data(:,incl{2:end}),2) == size(stds,2))
  x = originaldso.data(:,incl{2:end});
  else
    x = originaldso.data;
  end
end

if options.samplemode~=1
  %adjust for unusual sample mode (if supplied)
  neworder = [options.samplemode setdiff(1:ndims(x),options.samplemode)];
  oldorder = [];
  oldorder(neworder) = 1:ndims(x);
  x = permute(x,neworder);
end

if ndims(x)>2
  %handle multi-way matrix
  nway = true;
  sz = size(x);
  x  = reshape(x,[sz(1) prod(sz(2:end))]);
else
  nway = false;
end
[m,n] = size(x);

if isempty(means)
  means = zeros(1,n);
end
if isempty(stds)
  %mean centering done (only)

  %do the correction
  if isa(x,'double')
    if m*n<50000;  %< critical # of points (<0.5Mb) ? use matrix
      sx = (x-means(ones(m,1),:));
    else   %otherwise use loop
      sx = zeros(size(x));
      for row = 1:m;
        sx(row,:) = (x(row,:)-means);
      end
    end
  else   %do non-double by rows
    sx = zeros(size(x));
    for row = 1:m;
      sx(row,:) = feval(class(x),(double(x(row,:))-means));
    end
  end

else
  %standard deviations passed

  %test against the std threshold
  if ~isempty(options.stdthreshold) && (length(options.stdthreshold)>1 || options.stdthreshold>0)
    if length(options.stdthreshold)>1 && length(options.stdthreshold)~=n
      error('Standard Deviation Threshold does not match number of included variables')
    end
    %expand to vector
    options.stdthreshold = ones(1,n).*options.stdthreshold;
    %apply to stds
    stds = max(stds,options.stdthreshold);
  end

  stds(stds==0) = inf;  %replace 0 with inf to effectively "exclude"
  
  wrn=warning;
  warning off;

  %do the correction
  if isa(x,'double')
    if m*n<50000;  %< critical # of points (<0.5Mb) ? use matrix
      sx = (x-means(ones(m,1),:))./stds(ones(m,1),:);
    else   %otherwise use loop
      sx = zeros(size(x));
      for row = 1:m;
        sx(row,:) = (x(row,:)-means)./stds;
      end
    end
  else   %do non-double by rows
    sx = zeros(size(x));
    for row = 1:m;
      sx(row,:) = feval(class(x),(double(x(row,:))-means)./stds);
    end
  end

  warning(wrn);

end

if nway
  sx = reshape(sx,sz);
end
if options.samplemode~=1
  sx = permute(sx,oldorder);
end

if isdataset(originaldso);
  %if we started with a DSO, re-insert back into DSO
  scaleddata = originaldso.data.*nan;  %block out all columns
  if size(originaldso.include{2,1},2)~=size(sx,2)
    scaleddata = sx;
    scaleddata(:,~ismember([1:size(sx,2)],originaldso.include{2,1}))=nan;
  else
  scaleddata(:,incl{2:end}) = sx;  %insert scaled data (included columns only)
  end
  originaldso.data = scaleddata;
  sx = originaldso;
end


