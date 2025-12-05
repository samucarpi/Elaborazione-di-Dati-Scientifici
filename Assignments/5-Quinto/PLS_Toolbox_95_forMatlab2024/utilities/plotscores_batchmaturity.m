function a = plotscores_batchmaturity(modl,test,options)
%PLOTSCORES_BATCHMATURITY Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 8/25/03 -fixed bug associted with non-model input to plotscores (get
%    number of PCs from LAST MODE of scores instead of loads)

if nargin<2
  test = [];
end
if nargin<3
  options = [];
end
if isempty(test)
  %if no test was passed, fill in fake values for submodels so we can
  %simplify code below.
  test.submodelpca = [];
  test.submodelreg = [];
end
apca = plotscores_pca(modl.submodelpca,test.submodelpca,options);
apls = plotscores_pls(modl.submodelreg,test.submodelreg,options);

%change some PLS labels so we don't get (##) at the end of each item
for rev = {'Q Residuals' 'Hotelling T^2' 'KNN Score Distance'}
  ind = strmatch(rev{:},apls.label{2});
  if ~isempty(ind)
    apls.label{2}{ind} = [rev{:} ' PLS' apls.label{2}(ind,length(rev{:})+1:end)];
  end
end

a = [apca apls];
