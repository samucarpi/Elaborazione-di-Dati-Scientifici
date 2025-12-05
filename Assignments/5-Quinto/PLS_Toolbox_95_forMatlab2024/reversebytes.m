function res = reversebytes(y,totalbytes,base)
%REVERSEBYTES Flips order of bytes in a word.
%  Generalized reversal of bytes. Inputs are (y) the value(s) to operate
%  on, the total number of bytes to swap {default = 2} in each word, and
%  the number base to work in (base) {default = 2^8 = 256 = 1 hex byte}.
%  Note that the default is to swap 2 hex bytes in a 16 bit number.
%
%  EXAMPLES:
%   to swap 4 BYTES in a 32 bit number:
%     reversebytes(y,4)
%   to swap 2 WORDS in a 32 bit number:
%     reversebytes(y,2,2^16)
%
%I/O: res = reversebytes(y,totalbytes,base)

% Copyright © Eigenvector Research, Inc. 2003
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
if nargin == 0; y = 'io'; end
varargin{1} = y;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; res = evriio(mfilename,varargin{1},options); end
  return; 
end
if nargin<3;
  base = 2^8;
end
if nargin<2;
  totalbytes = 2;
end

res = 0; 
for k = 1:totalbytes; 
  res = res + fix((y-fix(y/base^k)*base^k)/base^(k-1))*base^(totalbytes-k); 
end; 

if any(any(y>base^(totalbytes)));
  warning('EVRI:ReversebytesTruncate','Some elements truncated (total bytes > number swapped)');
end
