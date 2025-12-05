function a = plotloads_mcr(modl,options)
%PLOTLOADS_MCR Plotloads helper function used to extract info from model.
% Called by PLOTLOADS.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mode = options.mode;
nvars = modl.datasource{1}.size(mode);
if mode>1
  %mode 2+ are included items only
  icol = modl.detail.includ{mode,1};
else
  %mode 1 is always all items (included and excluded)
  icol = 1:nvars;
end

a           = zeros(nvars,size(modl.loads{mode,1},2));
a(icol,:)   = modl.loads{mode,1};    %insert around zeros (to match original data var #)
if strcmp(options.undopre,'yes')
  a = dataset(a);
  a.include{1} = icol;
  a = preprocess('undo_silent',modl.detail.preprocessing{1},a');
  a = a.data';
end
if ~isempty(modl.ssqresiduals{mode,1});
  if length(modl.ssqresiduals{mode,1})==length(icol);
    a(icol,end+1)     = modl.ssqresiduals{mode,1}';   %resids exist for ONLY included vars
  else
    a(:,end+1)        = modl.ssqresiduals{mode,1}';   %resids exist for ALL variables (included or not)
  end
end
if ~isempty(modl.tsqs{mode,1});
  a(icol,end+1)       = modl.tsqs{mode,1}(:);        %tsqs exist for ONLY included vars (like loads above)
end
a = dataset(a);

a = copydsfields(modl,a,{mode 1},1);   %copy mode "mode" of model to mode 1 of dataset

% a.includ{1} = icol;
if isempty(a.axisscale{1,1})
  a.axisscale{1,1} = 1:size(a.data,1);
end
if isempty(a.axisscalename{1,1})
  a.axisscalename{1,1} = 'Variable';
end

if size(modl.loads,1)>2
  a.title{1} = sprintf('Mode %i Loadings Plot',mode);
  a.name     = sprintf('Mode %i Loadings',mode);
else
  a.title{1}       = 'Variables/Loadings Plot';
  a.name           = 'Loadings';
end
if ~isempty(modl.datasource{1}.name)
  a.title{1} = [a.title{1} ' for ',modl.datasource{1}.name];
  a.name     = [a.name ' for ',modl.datasource{1}.name];
end

compname = 'Comp.';
if strcmpi(modl.modeltype,'npls')
  compname = 'LV';
end

pc                 = size(modl.loads{mode,1},2);
b                  = cell(pc,1);
for ii=1:pc
  if ~isempty(modl.detail.ssq) & isnumeric(modl.detail.ssq)
    b{ii} = sprintf('%s %i (%0.2f%%)',compname,ii,modl.detail.ssq(ii,3));
  else
    b{ii} = sprintf('%s %i',compname,ii);
  end
end

%Residuals   
if ~isempty(modl.ssqresiduals{mode,1});
  if ~isempty(modl.detail.ssq) & isnumeric(modl.detail.ssq)
    b(end+1)  = {sprintf('Q Residuals (%0.2f%%)',100-modl.detail.ssq(pc,4))};
  else
    b(end+1)  = {sprintf('Q Residuals')};
  end
end

%T^2
if ~isempty(modl.tsqs{mode,1});
  if ~isempty(modl.detail.ssq) & isnumeric(modl.detail.ssq)
    b{end+1}  = sprintf('Hotelling T^2 (%0.2f%%)',modl.detail.ssq(pc,4));
  else
    b{end+1}  = sprintf('Hotelling T^2');
  end
end

a.label{2,1}       = char(b);

