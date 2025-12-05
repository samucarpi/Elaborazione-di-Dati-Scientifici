function a = plotscores_lwr(modl,test,options)
%PLOTSCORES_LWR Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms

a = plotscores_pls(modl,test,options);

% Add the extrap variable to the Scores Plot dataset
datacase = a.userdata.datacase; % does a have cal, test, or both
ecal = [];
etst = [];
if ~isempty(modl) & strcmpi(modl.modeltype, 'lwr')
  if isfield(modl.detail,'extrap') & ~isempty(modl.detail.extrap);
    ecal = modl.detail.extrap;
  end
end
if ~isempty(test) & strcmpi(test.modeltype, 'lwr_pred')
  if isfield(test.detail,'extrap') & ~isempty(test.detail.extrap);
    etst = test.detail.extrap;
  end
end

if strcmp('caltest', datacase)
  e      = dataset([ecal;etst]);
elseif strcmp('cal', datacase)
  e      = dataset(ecal);
elseif strcmp('test', datacase)
  e      = dataset(etst);
end
e.label{2,1} = 'Extrapolated Y';
a        = [a, e]; clear e1 e2
