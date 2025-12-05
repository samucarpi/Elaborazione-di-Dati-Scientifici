function a = plotloads_lda(modl,options)
%PLOTLOADS_LDA Plotloads helper function used to extract info from model.
% Called by PLOTLOADS.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2021
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% set up weights into plottable dso...
a = dataset(modl.detail.lda.w);
nwts = size(a,2);
wtlbls = cell(nwts,1);
for i=1:nwts
  wtlbls{i} = ['Weights_' num2str(i)];
end
a.label{2,1} = cell2str(wtlbls);

if isempty(a.axisscale{1,1})
  a.axisscale{1,1} = 1:size(a.data,1);
end
if isempty(a.axisscalename{1,1})
  a.axisscalename{1,1} = 'Variable Index';
end

if isempty(modl.datasource{1}.name)
  a.title{1}       = 'Weights Plot';
  a.name           = 'Variables';
else
  a.title{1}       = ['Weights Plot for ',modl.datasource{1}.name];
  a.name           = ['Variables for ',modl.datasource{1}.name];
end
