function a = plotloads_anndl(modl,options)
%PLOTLOADS_ANNDL Plotloads helper function used to extract info from model.
% Called by PLOTLOADS.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2021
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% get loss
loss = modl.detail.anndl.W.loss;

% the 'lbfgs' solver in sklearn does not calculate the loss at each epoch
% let the user know and then plot nothing
useropts = modl.detail.options;
if strcmpi(useropts.algorithm,'sklearn') && strcmpi(useropts.sk.solver,'lbfgs')
  error(['The LBFGS solver does not calculate the loss at each Epoch.' newline 'The final loss was ' num2str(loss(end))],...
    'Solver Unsupported','errID','Python:Unsupported Solver')
end

% set up loss into plottable dso...
a = dataset(loss);
a.label{2,1} = 'Loss';

if isempty(a.axisscale{1,1})
  a.axisscale{1,1} = 1:size(a.data,1);
end
if isempty(a.axisscalename{1,1})
  a.axisscalename{1,1} = 'Epoch';
end

if isempty(modl.datasource{1}.name)
  a.title{1}       = 'Loss/Epochs Plot';
  a.name           = 'Epochs';
else
  a.title{1}       = ['Loss/Epochs Plot for ',modl.datasource{1}.name];
  a.name           = ['Epochs for ',modl.datasource{1}.name];
end
