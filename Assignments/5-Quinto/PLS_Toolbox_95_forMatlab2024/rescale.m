function rx = rescale(x,means,stds,options)
%RESCALE Scales data back to original scaling.
%  Rescales a matrix (x) using the means (means) and standard deviation
%  (stds) vectors specified.  An optional input (options) is an options
%  structure with the field:
%     stdthreshold: [0] scalar value or vector of standard deviation
%                   threshold values. If a standard deviation is below its
%                   corresponding threshold value, the threshold value will
%                   be used in lieu of the actual value. A scalar value is
%                   used as a threshold for all variables.
%
%I/O: rx = rescale(x,means,stds,options);
%
%  If only two input arguments are supplied the function corrects the means
%  only.
%  If means is empty, a vector of all zeros will be used (no subtraction)
%
%I/O: rx = rescale(x,means);
%I/O: rescale demo
%
%See also: AUTO, CLASSCENTER, MEDCN, MNCN, NPREPROCESS, POLYTRANSFORM, PREPROCESS, SCALE

% Copyright © Eigenvector Research, Inc. 1991
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Modified 11/93
%Checked on MATLAB 5 by BMW  1/4/97
%JMS 2/5/04 -added option to do by loop if > critical # of samples
%  -added support for non-doubles

switch nargin
  case 0
    x = 'io';
end

%default options
defoptions = [];
defoptions.stdthreshold = 0;

if ischar(x);
  if nargout==0; clear rx; evriio(mfilename,x,defoptions); else; rx = evriio(mfilename,x,defoptions); end
  return;
end

%make sure we've got row vectors
means = means(:)';
if nargin>2;
  stds = stds(:)';
end
if nargin<4;
  options = [];
end

%NOTE: manuallly reconcilling to improve speed
% options = reconopts(options,mfilename,{'badreplacement','offset'});
if ~isfield(options,'stdthreshold')
  options.stdthreshold = defoptions.stdthreshold;
end

%check for DataSet object
originaldso = [];
switch class(x)
  case 'dataset'
    originaldso = x;
    incl = x.include;
    if length(options.stdthreshold)==size(x,2);
      %apply include field to stdthreshold (if applicable)
      options.stdthreshold = options.stdthreshold(incl{2});
    end
    %extract data from x (all samples)
    x = originaldso.data(:,incl{2:end});
end

[m,n] = size(x);
if isempty(means)
  means = zeros(1,n);
end

if nargin < 3
  %mean centering done (only)
  
  if isa(x,'double')
    if m*n<50000;  %< critical # of points (<0.5Mb) ? use matrix
      rx = x+means(ones(m,1),:);
    else   %otherwise use loop
      rx = zeros(size(x));
      for row = 1:m;
        rx(row,:) = x(row,:)+means;
      end
    end
  else   %do non-double by rows
    rx = zeros(size(x));
    for row = 1:m;
      rx(row,:) = feval(class(x),(double(x(row,:)))+means);
    end
  end
  
else
  %standard deviations passed
  
  %test against the std threshold
  if ~isempty(options.stdthreshold) & (length(options.stdthreshold)>1 | options.stdthreshold>0)
    if length(options.stdthreshold)>1 & length(options.stdthreshold)~=n
      error('Standard Deviation Threshold does not match number of included variables')
    end
    %expand to vector
    options.stdthreshold = ones(1,n).*options.stdthreshold;
    %apply to stds
    stds = max(stds,options.stdthreshold);
  end
  
  stds(~isfinite(stds)) = 0;  %replace inf with 0
  
  if isa(x,'double')
    if m*n<50000;  %< critical # of points (<0.5Mb) ? use matrix
      rx = (x.*stds(ones(m,1),:))+means(ones(m,1),:);
    else   %otherwise use loop
      rx = zeros(size(x));
      for row = 1:m;
        rx(row,:) = (x(row,:).*stds)+means;
      end
    end
  else   %do non-double by rows
    rx = zeros(size(x));
    for row = 1:m;
      rx(row,:) = feval(class(x),(double(x(row,:)).*stds)+means);
    end
  end
  
end

switch class(originaldso)
  case 'dataset'
    %if we started with a DSO, re-insert back into DSO
    scaleddata = originaldso.data.*nan;  %block out all columns
    scaleddata(:,incl{2:end}) = rx;  %insert scaled data (included columns only)
    originaldso.data = scaleddata;
    rx = originaldso;
end

