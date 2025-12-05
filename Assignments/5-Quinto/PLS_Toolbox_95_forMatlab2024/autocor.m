function acor = autocor(x,n,period,plots)
%AUTOCOR Auto-correlation function for time series data.
%  Performs the autocorrelation function of a time series.
%  Inuputs are the time series vector (x), and the number
%  of sample periods to consider (n).
%  The optional variable of the sample time (period)
%  which is used to scale the output plot.
%  If optional input (plots) is set to zero no
%  plots are constructed.
%  The output is the autocorrelation function (acor).
%
%Example:
%     acor = autocor(x,20,[],0);
%
%I/O: acor = autocor(x,n,period,plots);
%I/O: autocor demo
%
%See also: CORRMAP, CROSSCOR, FIR2SS, PLSPULSM, WRTPULSE

% Copyright © Eigenvector Research, Inc. 1992
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB® without
%  written permission from Eigenvector Research, Inc.
%Modified BMW 11/93, nbg 3/99

if nargin==0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; acor = evriio(mfilename,varargin{1},options); end
  return; 
end

[mp,np] = size(x);
if nargin<3
  period = 1;
elseif isempty(period)
  period = 1;
end
if nargin<4
  plots  = 1;
end
if np > mp
  x   = x';
  mp  = np;
end
acor  = zeros(2*n+1,1);
ax    = auto(x);
for i = 1:n
  ax1 = ax(1:mp-n-1+i,1);
  ax2 = ax(n+2-i:mp,1);
  acor(i,1) = ax1'*ax2/(mp-n+i-2);
end
acor(n+1,1) = ax'*ax/(mp-1);
for i = 1:n
  acor(n+i+1) = acor(n+1-i);
end
scl = period*(-n:1:n);
if logical(plots)
  plot(scl,acor)
  title('Autocorrelation Function')
  xlabel('Signal Time Shift (Tau)')
  ylabel('Correlation [ACF(Tau)]') 
  hold on
  plot(scl,zeros(size(scl)),'--g',[0 0],[-1 1],'--g')
  axis([scl(1,1) -scl(1,1) -1 1])
  hold off
end
