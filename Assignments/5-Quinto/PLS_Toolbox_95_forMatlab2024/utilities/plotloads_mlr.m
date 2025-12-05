function a = plotloads_mlr(modl,options)
%PLOTLOADS_MLR Plotloads helper function used to extract info from model.
% Called by PLOTLOADS.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

icol        = modl.detail.includ{2,1};
nvars       = modl.datasource{1}.size(2);

pc               = size(modl.reg,2);
c                = zeros(nvars,size(modl.reg,2)) * nan;
c(modl.detail.includ{2,1},:) = modl.reg;    %insert around nan's (to match original data var #)
c                = dataset(c);
c.includ{1}      = modl.detail.includ{2,1};
b                = cell(pc,1);
if isempty(modl.detail.data{2}) | isempty(modl.detail.data{2}.label{2,1});
  for ii=1:pc
    b{ii} = sprintf('Reg Vector for Y %i',modl.detail.includ{2,2}(ii));
  end
else
  for ii=1:pc
    b{ii} = sprintf(['Reg Vector for Y %i ',deblank(modl.detail.data{2}.label{2,1}(modl.detail.includ{2,2}(ii),:))], ...
      modl.detail.includ{2,2}(ii));
  end
end
c.label{2,1}     = char(b); clear b
a                = c;

%SELRATIO
if isfield(modl.detail,'selratio') & ~isempty(modl.detail.selratio)
  nvec = size(modl.reg,2);
  c    = zeros(nvars,nvec) * nan;
  c(modl.detail.includ{2,1},:) = modl.detail.selratio';    %insert around nan's (to match original data var #)
  c           = dataset(c);
  c.includ{1} = modl.detail.includ{2,1};
  b           = cell(nvec,1);
  for ii=1:nvec
    if isempty(modl.detail.data{2}) | isempty(modl.detail.data{2}.label{2,1});
      b{ii} = sprintf('Selectivity Ratio for Y %i',modl.detail.includ{2,2}(ii));
    else
      b{ii} = sprintf(['Selectivity Ratio for Y %i ',deblank(modl.detail.data{2}.label{2,1}(modl.detail.includ{2,2}(ii),:))], ...
        modl.detail.includ{2,2}(ii));
    end
  end
  c.label{2,1}     = char(b); clear b
  a                = [a, c]; clear c
end


a = copydsfields(modl,a,{2 1},1);   %copy mode 2 of model to mode 1 of dataset
a.includ{1} = icol;
if isempty(a.axisscale{1,1})
  a.axisscale{1,1} = 1:size(a.data,1);
end
if isempty(a.axisscalename{1,1})
  a.axisscalename{1,1} = 'Variable';
end

if isempty(modl.datasource{1}.name)
  a.title{1}       = 'Variables/Loadings Plot';
  a.name           = 'Loadings';
else
  a.title{1}       = ['Variables/Loadings Plot for ',modl.datasource{1}.name];
  a.name           = ['Loadings for ',modl.datasource{1}.name];
end

