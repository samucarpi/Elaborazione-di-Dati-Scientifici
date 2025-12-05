function disp(obj)
%EVRISCRIPT/DISP Overload for display function.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

disp(' evriscript object');
disp(['    label: ' obj.label]);
if obj.lock
  lockstr = 'LOCKED (1)';
else
  lockstr = 'Unlocked (0)';
end
disp(['     lock: ' lockstr]);
disp(' + steps: ');

steps = obj.steps;
keywords = {};
if isempty(steps)
  disp('     (none)')
else  
  for j=1:length(steps)
    keywords(1:3,j) = {j obj.steps{j}.step_keyword obj.steps{j}.step_mode}';
  end
  disp([sprintf('     (%i) = %s "%s"\n',keywords{:})]);
  if length(steps)==1
    disp(steps{1});
  end
end
