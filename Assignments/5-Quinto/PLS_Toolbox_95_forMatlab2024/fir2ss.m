function [phi,gam,c,d] = fir2ss(b)
%FIR2SS Transform FIR model into equivalent state space model.
%  The input is the vector of FIR coefficients (b). The
%  outputs are the phi, gamma, c and d matrices from
%  discrete state-space models.
%
%I/O: [phi,gamma,c,d] = fir2ss(b);
%I/O: fir2ss demo
%
%See also: AUTOCOR, CROSSCOR, PLSPULSM, WRTPULSE

% Copyright © Eigenvector Research, Inc. 1991
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Modified BMW 11/93

if nargin == 0; b = 'io'; end
if ischar(b);
  options = [];
  if nargout==0; evriio(mfilename,b,options); else; phi = evriio(mfilename,b,options); end
  return; 
end

[m,n] = size(b);
c = b;
phi = zeros(n);
phi(2:n,1:n-1) = eye(n-1);
gam = [1 zeros(1,n-1)]';
d = 0;
