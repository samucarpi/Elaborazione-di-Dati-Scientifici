function a = plotscores_als_sit(modl,test,options)
%PLOTSCORES_ALS_SIT Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% modl.detail.ssq = [];
% if ~isempty(test)
%   test.detail.ssq = [];
% end

% need to extract scores from cell arrays
% model.sitmodel.t and
% test.sitmodel.t
% each factor can have more than one column, so need to add labels
%  and classes (?)

ncomp = size(modl.sitmodel.t,2);
npcs  = ones(1,ncomp);
for i1=1:ncomp
  npcs(i1)  = size(modl.sitmodel.t{i1},2);
end

a     = zeros(length(modl.sitmodel.t{1}),sum(npcs)+1);
lbl   = cell(sum(npcs)+1,1);
lbl{end}    = 'Q';
i0    = 0;
for i1=1:ncomp
  for i2=1:npcs(i1)
    i0      = i0+1;
    lbl{i0} = sprintf('Factor %d, PC %d',i1,i2);
    a(:,i0) = modl.sitmodel.t{i1}(:,i2);
  end
end
z     = reshape(modl.ssqresiduals{1}(:),length(modl.sitmodel.include{1}),size(a,1));
a(:,end)    = sum(z,1)';
a           = dataset(a);
a.include{1}  = modl.sitmodel.include{3};
a.label{2}  = lbl; % a = plotscores_mcr(modl,test,options);

if ~isempty(test)
  a.class{1}  = zeros(1,size(a,1));
  a.classlookup{1} = {0 'Calibration'};
  a.classname{1}   = 'Cal/Test Samples';

  t   = zeros(length(test.sitmodel.t{1}),sum(npcs)+1);
  i0  = 0;
  for i1=1:ncomp
    for i2=1:npcs(i1)
      i0      = i0+1;
      t(:,i0) = test.sitmodel.t{i1}(:,i2);
    end
  end
  z   = test.ssqresiduals{1}(test.detail.include{1});
  z   = reshape(z(:),length(test.sitmodel.include{1}),size(t,1));
  t(:,end)    = sum(z,1)';
  t   = dataset(t);
  t.label{2}  = lbl;
  t.class{1}  = ones(1,size(t,1));
  t.classlookup{1}  = {1 'Test'};
  t.classname{1}    = 'Cal/Test Samples';
  a    = [a;t];
end
