function a = plotloads_clsti(modl,options)
%PLOTLOADS_CLSTI Plotloads helper function used to extract info from model.
% Called by PLOTLOADS.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

block = options.block;

icol   = modl.detail.includ{2,block};
nvars = modl.datasource{block}.size(2);

%how many components
numOfPureComps = length(modl.detail.clsti.refData);

a_zeros = zeros(nvars,numOfPureComps);

%cell array of loads for each test sample/test temp
myLoads = modl.loads{2};
myTestTemps = modl.detail.data{2}.data;
[uniqueTestTemps,ia] = unique(myTestTemps);
myLoads = myLoads(:,ia);
a = [];
for i = 1:length(uniqueTestTemps)
  thisLoads = myLoads{i};
  a_fixed = a_zeros;
  a_fixed(icol,:) = thisLoads;
  a_fixedDSO = dataset(a_fixed);
  fixedLabels = cell(numOfPureComps,1);
  for j = 1:length(fixedLabels)
    thisLabel = ['Interp. ' modl.detail.clsti.componentNames{j} ' at temp. ' num2str(uniqueTestTemps(i))];
    fixedLabels{j} = thisLabel;
  end
  a_fixedDSO.label{2} = fixedLabels;
  a = [a a_fixedDSO];
end

a.include{1} = modl.detail.include{2};