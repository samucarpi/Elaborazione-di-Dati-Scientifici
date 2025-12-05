function evritraperror(guimode)
%EVRITRAPERROR Utility to retrieve error information for debugging purposes.
% This script can be used to help identify errors to send to the Eigenvector
% Research staff. Instructions:
% 1) Run this function once to enable error catching
% 2) Perform whatever steps are necessary to cause the error
% 3) Run this function again to prepare error information
%
%I/O: evritraperror

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isempty(dbstatus)
  dbstop if all error

  disp(' ');
  disp('-------------------------------------------------');
  disp(' Please reproduce the steps which cause the error.')
  disp(' When the error occurs, it will open the Matlab editor.')
  disp(' At that point, return to this window and again type the command:')
  disp(['   <a href="matlab:' mfilename '">' mfilename '</a>'])
  disp('-------------------------------------------------');
  disp(' ');
  
else
  %have breakpoints, error has occurred
  evrireporterror  
  dbclear all
  if checkmlversion('>=','7')
    dbquit('all')
  else
    dbquit
  end
end

