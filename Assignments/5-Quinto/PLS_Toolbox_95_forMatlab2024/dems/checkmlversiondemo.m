echo on
%CHECKMLVERSIONDEMO Demo of the CHECKMLVERSION function
 
echo off
%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%This demo checks the version comparison operatorations of CHECKMLVERSION.
%If TMW changes the structure of its version functions then this demo may
%catch any problems.

if checkmlversion('<','1.99') || checkmlversion('<=','1.99')  || checkmlversion('==','1.99')
  error('CHECKMLVERSION Demo error')
end

if checkmlversion('>','99.01') || checkmlversion('>=','99.01') || checkmlversion('==','99.01')
  error('CHECKMLVERSION Demo error')
end


if ~checkmlversion('~=','1.99')
  error('CHECKMLVERSION Demo error')
end

if checkmlversion('<','1') || checkmlversion('<=','1.99.12')  || checkmlversion('==','1')
  error('CHECKMLVERSION Demo error')
end

if checkmlversion('<','7.01') || checkmlversion('<=','7.01')  || checkmlversion('==','7.01')
  error('CHECKMLVERSION Demo error')
end

if checkmlversion('==','7.99')
  error('CHECKMLVERSION Demo error')
end

%End of CHECKMLVERSIONDEMO
 
echo off
