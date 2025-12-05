function crcor = crosscor(x,y,n,period,flag,plots)
%CROSSCOR Cross-correlation function for time series data.
%  Performs the crosscorrelation function of two time series.
%  The inputs are the two time series (x), and (y) and the
%  number of sample periods (n) to consider. The sample period
%  (period) is an optional input used to scale the output plot and
%  (flag) is an optional input variable which changes the routine
%  from cross correlation to cross covariance when set to 1.
%  If optional input (plots) is set to zero no plots are constructed.
%Example:
%     crcor = crosscor(x,y,20,[],0,0);
%
%I/O: crcor = crosscor(x,y,n,period,flag,plots);
%I/O: crosscor demo
%
%See also: AUTOCOR, CORRMAP, FIR2SS, PLSPULSM, WRTPULSE

% Copyright © Eigenvector Research, Inc. 1991
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB® without
%  written permission from Eigenvector Research, Inc.
%Modified BMW 11/93, nbg 3/99
%BMW 9/2001

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; crcor = evriio(mfilename,varargin{1},options); end
  return; 
end

[mp,np]   = size(x);
[mpy,npy] = size(y);
if np > mp
  x  = x';
  mp = np;
end
if npy > mpy
  y   = y';
  mpy = npy;
end
if mpy ~= mp
  error('The x and y vectors must be the same length')
end
crcor = zeros(2*n+1,1);
if nargin < 4
  period = 1;
elseif isempty(period)
  period = 1;
end
if nargin < 5
  flag = 0;
elseif isempty(flag)
  flag = 0;
end
if nargin < 6
  plots = 1;
end
for i = 1:n
  xy = y(1:mp-n-1+i,1);
  xy(:,2) = x(n+2-i:mp,1);  
  xy(:,3) = x(1:mp-n-1+i,1);
  xy(:,4) = y(n+2-i:mp,1);
  if flag == 1
    xy = mncn(xy);
  else
    xy = auto(xy);
  end
  crcor(i,1) = xy(:,1)'*xy(:,2)/(mp-n+i-2);
  crcor(2*n+2-i,1) = xy(:,3)'*xy(:,4)/(mp-n+i-2);
end
if flag == 1
  crcor(n+1,1) = mncn(x)'*mncn(y)/(mp-1);
else
  crcor(n+1,1) = auto(x)'*auto(y)/(mp-1);
end
scl = period*(-n:1:n);
if logical(plots)
  plot(scl,crcor)
  f = axis;
  hold on
  plot([f(1) f(2)],[0 0],'--g',[0 0],[f(3) f(4)],'--g')
  if flag == 1
    title('Crosscovariance Function')
    ylabel('Covariance [CCF(Tau)]')
  else
    title('Crosscorrelation Function')
    ylabel('Correlation [CCF(Tau)]') 
  end
  xlabel('Signal Time Shift (Tau)')
  hold off
end
