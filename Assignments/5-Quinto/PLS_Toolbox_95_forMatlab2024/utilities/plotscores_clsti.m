function a = plotscores_clsti(modl,test,options)
%PLOTSCORES_CLSTI Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

a = dataset([test.ssqresiduals{1,1}, test.tsqs{1,1}]);
a =  copydsfields(test,a,1);
a.name   = test.datasource{1}.name;

blabel         = {};                           %Scores, Q, and T^2
blabel{end+1}  = sprintf('Q Residuals');
blabel{end+1}    = sprintf('Hotelling T^2');
a.label{2,1}   = char(blabel);

c = test.pred{2};
alabel = {};
for ii=1:size(c,2)
  alabel{end+1} = ['Predicted ' modl.detail.clsti.componentNames{ii}];
end

c            = dataset(c);
c.label{2,1} = char(alabel);

a = [a, c];

d = test.detail.esterror;
alabel = {};
for ii=1:size(d,2)
  alabel{end+1} = ['Estimation error for ' modl.detail.clsti.componentNames{ii}];
end

d            = dataset(d);
d.label{2,1} = char(alabel);

a = [a, d];