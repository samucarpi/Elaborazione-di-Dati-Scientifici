function obj = reference(obj,stepfrom,namefrom,stepto,nameto)
%EVRISCRIPT/REFERENCE References an input of one step to an output of another

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<5
  error('Insufficient number of inputs')
end

if ~isnumeric(stepto) | stepto>length(obj.steps) | stepto<1
  error('StepTo must refer to a current step in the chain')
end
if ~isnumeric(stepfrom) | stepfrom>length(obj.steps) | stepfrom<1
  error('StepFrom must refer to a current step in the chain')
end
if stepto<stepfrom
  error('Step being referenced must be < step using reference')
end

if ~ismember(namefrom,obj.steps{stepfrom}.step_inputs) & ~ismember(namefrom,obj.steps{stepfrom}.step_outputs)
  error('Property "%s" could not be found in step %i',namefrom,stepfrom)
end
if ~ismember(nameto,obj.steps{stepto}.step_inputs)
  error('Property "%s" could not be found as an input to step %i',nameto,stepto)
end

%make reference object and store in appropriate location
obj.steps{stepto}.(nameto) = evriscript_reference(namefrom,obj.steps{stepfrom});
