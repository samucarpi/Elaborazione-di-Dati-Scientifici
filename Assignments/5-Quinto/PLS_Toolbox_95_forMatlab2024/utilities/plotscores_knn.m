function a = plotscores_knn(modl,test,options)
%PLOTSCORES_KNN Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 06/18/04 Change display for T and Q to show classes.

if isempty(test) %| options.sct==1
  a = makescores(modl);
else
  if options.sct
    a = makescores(modl); 
    b = makescores(test,modl);
    cls = [zeros(1,size(a,1)) ones(1,size(b,1))];
    a              = [a;b]; clear b
    %search for empty cell to store cal/test classes
    j = 1;
    while j<=size(a.class,2);
      if isempty(a.class{1,j});
        break;
      end
      j = j+1;
    end
    a.class{1,j} = cls;  %store classes there
    a.classlookup{1,j} = {0 'Calibration';1 'Test'};
    a.classname{1,j} = 'Cal/Test Samples';

  else
    a = makescores(test,modl);
  end
end

%get rid of all-NAN columns
allnan = all(isnan(a.data),1);
if any(allnan)
  a = a(:,~allnan);
end


%---------------------------------------------------------------------
function b = makescores(test,modl)

b = [];
lbl = {};

%look for "actual" classes
classset = test.detail.options.classset;
if classset>0 & size(test.detail.class,3)>=classset
  actual = test.detail.class{1,1,classset};
else
  actual = [];
end
if isempty(actual)
  %none? use all zeros (=unknown)
  actual = zeros(1,test.datasource{1}.size(1)).*nan;
end
actual = actual(:);

[data,labels] = plotscores_addclassification(test,actual);


if isfield(test.detail,'cvpred') & ~isempty(test.detail.cvpred)
  if nargin==1
    data = [data squeeze(test.detail.cvpred(:,:,test.lvs))];
  else
    data = [data nan(size(data,1),1)];
  end
  labels{end+1} = 'Class CV Predicted';  
  
  if ~isempty(actual) & nargin==1
    data = [data squeeze(test.detail.cvpred(:,:,test.lvs))-actual(:)];
  elseif nargin>1
    data = [data nan(size(data,1),1)];
  end
  labels{end+1} = 'Class CV Residuals';  

end

b = [b data];
lbl = [lbl labels];

%create dataset
b          = dataset(b);
b          = copydsfields(test,b,1);
b.label{2} = lbl;
if isempty(actual);
  b.class{1} = test.nclass;
end

b.title{1}   = 'Samples/Scores Plot of Test';

