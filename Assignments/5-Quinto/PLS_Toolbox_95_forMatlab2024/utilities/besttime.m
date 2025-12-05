function out = besttime(time)
%BESTTIME Returns a string describing the time interval provided (in seconds).
%  Input (time) is the time interval in seconds to be described and
%  (string) is a character string with the time (in appropriate units).
%
%Examples:
%  out = besttime(95);       gives  out = '1.6 minutes'
%  out = besttime(195);      gives out = '3.3 minutes'
%  out = besttime(60);       gives out =  '1 minutes'
%  out = besttime(60*60);    gives out ='60 minutes'
%  out = besttime(60*60*24); gives out = '24 hours'
%
%I/O: string = besttime(time)

%Copyright Eigenvector Research 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS, NBG 9/08 modified the help

units = 'seconds';

if all(abs(time/60)<1);
  units='seconds';
elseif all(abs(time/60/60)<1.5);
  units='minutes';
  time=time/60;
elseif all(abs(time/60/60/24)<1.5);
  units='hours';
  time=time/60/60;
elseif all(abs(time/60/60/24/365)<1);
  units='days';
  time=time/60/60/24;
else
  units='years';
  time=time/60/60/24/365;
end

out=[num2str(round(time*10)/10) ' ' units];
