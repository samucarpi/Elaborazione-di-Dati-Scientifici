function a = plotscores_lda(modl,test,options)
%PLOTSCORES_LDA Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES
% (Based on plotscores_lregda.m)

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms

nomeasured  = 0;     %default is to try to show measured and residuals (changed if we're missing required info)
nocvpred    = 0;
nocvpredres = 0;

isLda = strcmpi(modl.modeltype,'lda') ;
a            = [];
alabel       = cell(0);

if isLda 
  ny = length(modl.classification.classids);
end


labelsuffix = {};
for ii=1:ny  
  %develop suffix indicating which component this is (added to any other
  %label to indicate y-block column and other info)
  if isLda
    classset = modl.detail.options.classset;
    classstr = getclassstr(modl.detail.classlookup{2,2},modl.detail.class{2,2}(modl.detail.includ{2,2}(ii)));
    labelsuffix{ii} = sprintf('%i (%s)', ii, classstr);
  else
    if ~isempty(modl.detail.data{2}) & ~isempty(modl.detail.data{2}.label{2,1})
      labelsuffix{ii} = sprintf('%i %s',modl.detail.includ{2,2}(ii),deblank(modl.detail.data{2}.label{2,1}(modl.detail.includ{2,2}(ii),:)));
    else
      labelsuffix{ii} = sprintf('%i',modl.detail.includ{2,2}(ii));
    end
  end
end

if isempty(test) | options.sct==1
  %Fill Model info
  
  if ~nomeasured & length(modl.detail.data)>1 & ~isempty(modl.detail.data{2})
    meas = modl.detail.data{2}.data(:,modl.detail.includ{2,2});
    for ii=1:ny;
        alabel{end+1} = ['Y Measured ' labelsuffix{ii}];
        a = [a, meas(:,ii)];
    end
  else
    nomeasured = 1;
    meas = [];
  end

  % Scores
  for ii=1:size(modl.loads{1},2)
    a = [a, modl.loads{1}(:,ii)];
    if ~isempty(modl.ssq)
      alabel{end+1} = sprintf('Scores on LV %i (%0.2f%%)',ii,modl.ssq(ii,3));
    else
      alabel{end+1} = ['Scores on LV ' num2str(ii)];
    end
  end
  
  if isLda
    if isfield(modl,'classification');
      %add classification information
      [dc,classlbl] = plotscores_addclassification(modl,meas);
      a = [a, dc];
      alabel = [alabel classlbl];
    end  
  end 

  nhid1 = modl.detail.options.lambda;   
  if ~nocvpred & isfield(modl.detail,'cvpred') & ~isempty(modl.detail.cvpred);
    for ii=1:ny;
      if isLda
        a = [a, modl.detail.cvpred(:,ii)];
      end
      alabel{end+1} = ['Class CV Probability ' labelsuffix{ii}];
    end
  else
    nocvpred = 1;
  end
  
  a = dataset(a);
  a = copydsfields(modl,a,1,1);
  a.name   = modl.datasource{1}.name;
  
  if isempty(a.name)
    a.title{1}     = 'Samples/Scores Plot';
  else
    a.title{1}     = ['Samples/Scores Plot of ',a.name];
  end
  
  a.label{2,1} = char(alabel);
  
  if isLda & isfield(modl.detail,'originalinclude') & ~isempty(modl.detail.originalinclude) & ~isempty(modl.detail.originalinclude{1})
    a.include{1} = modl.detail.originalinclude{1};
  end
    
end

%Test Mode
if ~isempty(test) %X-block must be present
  
  b      = [];
  blabel = {};
  
  ytest = [];
  if ~nomeasured
    if length(test.detail.data)>1 & ~isempty(test.detail.data{2});
      ytest = test.detail.data{2}.data(:,test.detail.includ{2,2});
    elseif options.sct
      ytest = ones(test.datasource{1}.size(1), ny)*nan; % ANN only support one y var
    else
      ytest = [];  %no cal data and no y-block use empty (to skip loop below)
    end
    %if ~isempty(ytest) & ~isLda
    if ~isempty(ytest)
      for ii=1:ny
        b = [b, ytest(:,ii)];
        blabel{end+1} = ['Y Measured ' labelsuffix{ii}];
      end
    end
  end

  % Scores
  for ii=1:size(test.loads{1},2)
    b = [b, test.loads{1}(:,ii)];
    blabel{end+1} = ['Scores on LV ' num2str(ii)];
  end

  if isfield(test,'classification');
    %add classification information
    [dc,classlbl] = plotscores_addclassification(test,ytest);
    b = [b, dc];
    blabel = [blabel classlbl];
  end

  if ~nocvpred & options.sct
    b = [b, zeros(size(b,1),size(modl.detail.cvpred,2))*nan];
  end
  
  %Don't need this for this LDA models
%   if ~nocvpredres & options.sct
%     b = [b, zeros(size(b,1),size(modl.detail.cvpred,2))*nan];
%     %b = [b, zeros(size(b,1),1)*nan];
%   end
  
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

%---------------------------------------------------------
function   classstr = getclassstr(classlookup,classnum)

classstr = classlookup(ismember([classlookup{:,1}],classnum),2);
classstr = sprintf('%s,',classstr{:});
classstr = classstr(1:end-1); %drop ending comma
