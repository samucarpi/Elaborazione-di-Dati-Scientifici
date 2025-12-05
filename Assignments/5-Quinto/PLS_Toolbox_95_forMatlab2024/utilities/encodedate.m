function out = encodedate(timestamp,format)
%ENCODEDATE Returns a timestamp in string format including miliseconds.
% Input (timestamp) is a time and date in "clock" format (6 element
% vector). Optional input (format) is a numerical format appropriate for
% calling into datestr as format.
%
%I/O: str = encodedate(timestamp)

%Copyright © Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0 || isempty(timestamp);
  timestamp = clock;
end
if nargin<2 || isempty(format)
  format = 30;
end
if format==31;
  msdelim = '.';
else
  msdelim = '';
end
out = [datestr(timestamp,format) msdelim sprintf('%0.2i',round(mod(timestamp(end),1)*100))];

