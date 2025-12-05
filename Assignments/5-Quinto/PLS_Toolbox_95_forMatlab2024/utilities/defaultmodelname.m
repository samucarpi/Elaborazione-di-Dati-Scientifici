function name = defaultmodelname(modl,object,method)
%DEFAULTMODELNAME Generate default model name for save of model
%
%I/O: name = defaultmodelname(model,object,method)
% 
%See Also: ANALYSIS, SAVEMODELAS

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<3 || ~ischar(method)
  method = 'save';
end
if nargin<2 || ~ischar(object)
  object = 'variable';
end

name = lower([modl.modeltype 'model' datestr(modl.time,30)]);

