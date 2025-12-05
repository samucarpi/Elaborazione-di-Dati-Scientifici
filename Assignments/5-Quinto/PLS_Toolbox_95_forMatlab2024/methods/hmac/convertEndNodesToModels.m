function [mod] = convertEndNodesToModels(hmacmodel)
  %CONVERTENDNODESTOMODELS Converts Hmac model output from string to model.
  % Converts the output nodes of a model produced by HMAC from strings to 
  % models. This allows for the user to apply data to the HMAC model and
  % see the results in a dataset object rather than the strings in a text
  % window.
  %
  % INPUTS:
  %         hmacmodel = model produced by HMAC.
  %
  %  OUTPUT:
  %              mod  = model produced by HMAC with models as the output
  %                     nodes.
  %
  %I/O: [mod]         = convertEndNodesToModels(hmacmodel);
  %
  %See also: HMAC HMACGUI

  % Copyright © Eigenvector Research, Inc. 2023
  % Licensee shall not re-compile, translate or convert "M-files" contained
  %  in PLS_Toolbox for use with any software other than MATLAB®, without
  %  written permission from Eigenvector Research, Inc.

mod = hmacmodel;
targs = hmacmodel.targets;

stringinds = zeros(1,length(targs));
for i=1:length(targs)
  if ~ismodel(targs{i}) && ischar(targs{i}) && ~isequal(targs{i},'Class 0')
    % string output
    targs{i} = hmacmodel.trigger;
    stringinds(i) = 1;
  elseif ismodel(targs{i})
    targs{i} = convertEndNodesToModels(targs{i});
  else
    continue;
  end
end
mod.targets = targs;
if ~strcmpi(mod.targets{1}.modeltype,'modelselector')
  outputs = getmodeloutputs(mod.targets{1},-1); % default outputs
  items = cell(1,size(outputs,1));
  for j=1:size(outputs,1)
    items{j} = outputs(j,[1,2]);
  end
  mod.outputfilters = cell(1,length(targs));
  [mod.outputfilters(find(stringinds))] = {items};
end
end