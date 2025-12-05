function evripause(secs)
%EVRIPAUSE Pause in seconds that is not affected by Matlab pause function.
%
%I/O: evripause(secs)
%
%See also: PAUSE

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

start = now;
while 1
  if (now-start)*60*60*24>secs
    break
  end
end
