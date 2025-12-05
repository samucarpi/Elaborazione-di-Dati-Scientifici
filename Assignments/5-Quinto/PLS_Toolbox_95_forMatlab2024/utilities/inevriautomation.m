function out = inevriautomation
%INEVRIAUTOMATION Evaluate if currently in an EVRI Automation call

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

myfield = 'file';
if checkmlversion('>','6.5')
  stack = dbstack('-completenames');
else
  stack = dbstack;
  myfield = 'name';
end
out = false;
for j=length(stack):-1:1
  if ~isempty(findstr(stack(j).(myfield),'@evrigui'))
    out = true;
    return
  end
end
