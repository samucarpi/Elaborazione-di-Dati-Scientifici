function isel = doptimal(x,nosamps,iint,tol)
%DOPTIMAL Selects samples based on D-Optimal criteria.
%  DOPTIMAL selects samples from a candidate matrix that maximizes
%    det(x(isel,:)'*x(isel,:)) where (x) is the matrix of all candidate
%  samples, (nosamps) is the number of samples to select, and (isel) is
%  a vector of the selected samples where length(isel) = nosamps.
%
%  Optional input (iint) is a vector of samples used to initialize the
%  optimization [nosamps = length(iint)]. If (iint) is not supplied the
%  algorithm is initialized with samples on the exterior of the data
%  space using the DISTSLCT function (in contrast to a random set).
%  (tol) is an optional input setting the tolerance for minimum increase
%  in the determinant {default = 1e-4}.
%
%  Notes:
%  1) (nosamps) must be >= rank(x) (it is necessary but not sufficient
%     that (nosamps)>=size(x,2)) for a good solution to be obtained.
%  2) Input (x) can be a set of scores from PCA or PLS.
%     This helps when the number of columns in (x) is greater than (nosamps).
%  3) The solution can depend on the intial guess (i.e. is not necessarily
%     a global optimum). See the above reference.
%
%  The routine is based on Fedorov's algorithm discussed in
%    de Aguiar, P.F., Bourguignon, B., Khots, M.S., Massart, D.L., and
%    Phan-Than-Luu, R., "D-optimal designs", Chemo. Intell. Lab. Sys.,
%    30, 199-210, 1995.
%
%I/O: isel = doptimal(x,nosamps,iint,tol);
%I/O: doptimal demo
%
%See also: DISTSLCT, FACTDES, FFACDES1, LEVERAG, STDSSLCT

% Copyright © Eigenvector Research, Inc. 1998
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 1998, 11/99
%nbg 8/25/00 changed to use DISTSLCT instead of internal DISTSLC1
%            and added to the help.
%nbg 2/08/01 added sort(isel) to end
%nbg 2/28/09 added a line to break ties

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; isel = evriio(mfilename,varargin{1},options); end
  return; 
end

%initialize selected matrix
if nargin<3
  iint = [];
elseif ~exist('iint','var')
  iint = [];
end
m      = size(x,1);
if isempty(iint)
  isel = distslct(x,nosamps);
else
  if length(iint)~=nosamps
    nosamps = length(iint);
  end
  isel = iint(:);
end

%initialize memory
inot     = delsamps([1:m]',isel);
del      = zeros(length(inot),length(isel));
if nargin<4
  tol    = 1e-4;
end
e        = 1;

while e>tol
  invx   = inv(x(isel,:)'*x(isel,:));  %inv(x'x)
  lev    = leverag(x,invx);            %d(xi), d(xj)
  xiinvx = x(inot,:)*invx;
  for ii=1:nosamps
    del(:,ii) = xiinvx*x(isel(ii),:)'; %d(xij)
  end
  for ii = 1:nosamps
    del(:,ii) = lev(inot)-lev(inot)*lev(isel(ii))+ ...
      del(:,ii).^2-lev(isel(ii));
  end
  [imx,jmx] = find(del>=max(max(del)')');
  imx    = imx(1); jmx  = jmx(1); %just in case of a tie
  e      = del(imx,jmx);
  if e>tol
    isel(jmx) = inot(imx);
    isel = sort(isel);
    inot = delsamps([1:m]',isel);
  end
end
isel     = sort(isel);
