function summarize(obj, idetail)
%EVRISCRIPT/SUMMARIZE print details of steps in the chain at increasing levels of detail (idetail= 0,1,2)

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isempty(obj)
  disp(sprintf('evriscript is empty object'));
  return
elseif isempty(obj.steps)
  disp(sprintf('evriscript has no steps'));
  return
else
  if nargin < 2
    idetail = 0;
  end
  nsteps = length(obj.steps);
  theSteps = obj.steps;
  disp(sprintf('\n\n===================================='));
  disp(sprintf('evriscript: ''%s'' summary', obj.label));
  disp(sprintf('===================================='));
  for i=1:nsteps
    step = theSteps{i};
    disp(sprintf('Step[%i]: ----------------------------', i));
    if idetail > 0
      disp(step, idetail);
    else
      disp(sprintf('  keyword = %s', step.step_keyword));
      disp(sprintf('  label = %s', step.step_label));
      disp(sprintf('  id = %15.12f', step.step_id));
    end
  end
  %   disp(sprintf('------------------------------------'));
  disp(sprintf('===================================='));
end
