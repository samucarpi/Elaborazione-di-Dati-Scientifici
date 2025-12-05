function isel = distslct(x,nosamps,flag);
%DISTSLCT Selects samples on outside of data space.
%  Inputs are the M by N data matrix (x) (class "double") and the
%  number of samples to select (nosamps).
%  If nosamps<N then DISTSLCT selects all N samples.
%  Optional input (flag) indicates how many samples STDSSLCT
%  should select (when nosamps>=N):
%    flag = 1: DISTSLCT selects N-1
%    flag = 2: DISTSLCT selects N  {default}
%
%  Output (isel) is a vector of row indices for the selected samples.
%
%  Samples are selected based on Euclidian distance. It is an alternative to
%  DOPTIMAL that does not require an inverse or estimate of the determinant.
%
%I/O: isel = distslct(x,nosamps,flag);
%I/O: distslct demo
%
%See also: DOPTIMAL, FACTDES, FFACDES1, REDUCENNSAMPLES, STDGEN, STDSSLCT

%Copyright Eigenvector Research, Inc. 1999
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%nbg 8/29/00 changed "and inverse" to "an inverse"
%nbg 2/08/01 changed dist(isel(ii)) = 0; to dist(isel(1:ii)) = zeros(ii,1);
%nbg 10/30/03 line 55 commented out ==> reset distance to 0!
%nbg 9/05 included an if nosamps>n statement

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; isel = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<3  %flag determines how many samples STDSSLCT should get
  flag        = 2;
elseif isempty(flag)
  flag        = 2;
end

[m,n]         = size(x);
x             = mncn(x);
isel          = zeros(1,nosamps);

switch flag
case 1   %stdslct gets n-1 samples
	if nosamps<n
    [md,isel]   = stdsslct(x,nosamps);
	else
    [md,isel(1:n-1)] = stdsslct(x,n-1);
    dist        = sqrt(sum(x.^2,2));
    %dist        = zeros(m,1);
    for ii=1:n-1
      xsel      = x(isel(ii),:);
      dist      = dist+sqrt(sum((x-xsel(ones(m,1),:)).^2,2));
      dist(isel(1:ii),:) = zeros(ii,1);
    end
    [md,isel(n)]  = max(dist);          %first sample is furthest from the mean
    xsel        = x(isel(n),:);
    dist(isel(n)) = 0;
    for ii=n+1:nosamps
      dist           = dist+sqrt(sum((x-xsel(ones(m,1),:)).^2,2));
      [md,isel(ii)]  = max(dist);
      xsel           = x(isel(ii),:);
      dist(isel(1:ii)) = zeros(ii,1);
    end
	end
	isel          = sort(isel(:))';
case 2   %stdslct gets n samples
	if nosamps<n
    [md,isel]   = stdsslct(x,nosamps);
	else
    [md,isel(1:n)] = stdsslct(x,n);
    dist        = sqrt(sum(x.^2,2));
    dist        = zeros(m,1);
    for ii=1:n
      xsel      = x(isel(ii),:);
      dist      = dist+sqrt(sum((x-xsel(ones(m,1),:)).^2,2));
      dist(isel(1:ii),:) = zeros(ii,1);
    end
    if nosamps>n %9/05
      [md,isel(n+1)]  = max(dist);          %first sample is furthest from the mean
      xsel        = x(isel(n+1),:);
      dist(isel(n+1)) = 0;
      for ii=n+2:nosamps
        dist           = dist+sqrt(sum((x-xsel(ones(m,1),:)).^2,2));
        [md,isel(ii)]  = max(dist);
        xsel           = x(isel(ii),:);
        dist(isel(1:ii)) = zeros(ii,1);
      end
    end %9/05
	end
% 	isel          = sort(isel(:))';
end
