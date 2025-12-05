function a = plotscores_svmoc(modl,test,options)
%PLOTSCORES_SVMOC Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms

a            = [];
alabel       = cell(0);

if isempty(test) | options.sct==1
  %Fill Model info
  
  a = [a, modl.pred{2}(:,1)<=0];
  alabel{end+1} = ['Outlier'];
  a = [a, (1-modl.pred{2}(:,1))/2];
  alabel{end+1} = ['Raw Outlier Prediction'];
  
  a = dataset(a);
  a = copydsfields(modl,a,1,1);
  a.name   = modl.datasource{1}.name;
  
  if isempty(a.name)
    a.title{1}     = 'Samples/Scores Plot';
  else
    a.title{1}     = ['Samples/Scores Plot of ',a.name];
  end
  
  a.label{2,1} = char(alabel);
  
end

%Test Mode
if ~isempty(test) %X-block must be present
  
  b      = [];
  blabel = {};
  
  b = [b, test.pred{2}(:,1)<=0];
  blabel{end+1} = ['Outlier'];
  b = [b, (1-test.pred{2}(:,1))/2];
  blabel{end+1} = ['Raw Outlier Prediction'];
  
  %create DSO
  b = dataset(b);
  b = copydsfields(test,b,1,1);
  b.name   = test.datasource{1}.name;
  if options.sct
    if isempty(a.name)&isempty(b.name)
      a.title{1}   = 'Samples/Scores Plot of Cal & Test';
    elseif isempty(a.name)&~isempty(b.name)
      a.title{1}   = ['Samples/Scores Plot of Cal &',b.name];
    elseif ~isempty(a.name)&isempty(b.name)
      a.title{1}   = ['Samples/Scores Plot of ',a.name,' & Test'];
    else
      a.title{1}   = ['Samples/Scores Plot of ',a.name,' & ',b.name];
    end
  else
    if isempty(b.name)
      b.title{1}   = 'Samples/Scores Plot of Test';
    else
      b.title{1}   = ['Samples/Scores Plot of ',b.name];
    end
    %add add column labels
    b.label{2,1} = blabel;
  end
  
  if isempty(a)
    %no cal data? just use test
    a = b;
  else
    %combine cal and test
    cls = [zeros(1,size(a,1)) ones(1,size(b,1))];
    a = [a;b];
    
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
  end
  
end

a.axistype{1} = 'discrete';
