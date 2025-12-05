function a = plotscores_anndl(modl,test,options)
%PLOTSCORES_ANN Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms

nomeasured  = 0;     %default is to try to show measured and residuals (changed if we're missing required info)
nores       = 0;
nocvpred    = 0;
nocvpredres = 0;

isAnndlda = strcmpi(modl.modeltype,'anndlda') ;
a            = [];
alabel       = cell(0);

if isAnndlda 
  nclass = length(modl.classification.classids);
  ny     = nclass;
else  %ANNDL
  ny     = size(modl.pred{2},2); %number of Y variables
  nclass = ny;
end


labelsuffix = {};
for ii=1:nclass
  
  %develop suffix indicating which component this is (added to any other
  %label to indicate y-block column and other info)
  if isAnndlda
    classset = modl.detail.options.classset;
    if prod(modl.datasource{2}.size)==0 & ~isempty(modl.detail.class{1,1,classset});
      classstr = getclassstr(modl.detail.classlookup{1,1,classset}, modl.detail.includ{2,2}(ii));
      labelsuffix{ii} = sprintf('%i (%s)',modl.detail.svm.model.label(ii),classstr);
    else
      classstr = getclassstr(modl.detail.classlookup{1,1,classset}, modl.detail.includ{2,2}(ii));
      labelsuffix{ii} = sprintf('%i (%s)', ii, classstr);
    end
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
    if ~isAnndlda
    for ii=1:ny;
        alabel{end+1} = ['Y Measured ' labelsuffix{ii}];
        a = [a, meas(:,ii)];
    end
    end
  else
    nomeasured = 1;
    meas = [];
  end
  
  if isAnndlda
    if isfield(modl,'classification');
      %add classification information
      [dc,classlbl] = plotscores_addclassification(modl,meas);
      a = [a, dc];
      alabel = [alabel classlbl];
    end
  else   
    if ~isempty(modl.pred{2})
      for ii=1:ny;
        a = [a, modl.pred{2}(:,1)]; %%ii)];
        alabel{end+1} = ['Y Predicted ' labelsuffix{ii}];
      end
    end
    
    if ~nores & (isAnndlda | (length(modl.detail.res)>1 & ~isempty(modl.detail.res{2})));
      for ii=1:ny;
        res  = modl.detail.res{2}(:,ii);
        a = [a, res];
        alabel{end+1} = ['Y Residual ' labelsuffix{ii}];
      end
    else
      nores = 1;
    end
  end 

  
  
  nhid1 = getanndlnhidone(modl);   
  if ~nocvpred & isfield(modl.detail,'cvpred') & ~isempty(modl.detail.cvpred);
    for ii=1:ny;
      if isAnndlda
        a = [a, modl.detail.cvpred(:,ii)];
      else
        a = [a, modl.detail.cvpred(:,ii,nhid1)];
      end
      alabel{end+1} = ['Y CV Predicted ' labelsuffix{ii}];
    end
  else
    nocvpred = 1;
  end
 
  if ~nocvpred & ~nomeasured & ~nores
    for ii=1:ny;
      if isAnndlda
        a = [a, modl.detail.cvpred(:,ii)-modl.detail.data{2}.data(:,modl.detail.includ{2,2}(ii))]; 
      else
        a = [a, modl.detail.cvpred(:,ii,nhid1)-modl.detail.data{2}.data(:,modl.detail.includ{2,2}(ii))];  % make same as class
      end
      alabel{end+1} = ['Y CV Residual'];
    end
  else
    nocvpredres = 1;
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
  
  if isAnndlda & isfield(modl.detail,'originalinclude') & ~isempty(modl.detail.originalinclude) & ~isempty(modl.detail.originalinclude{1})
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
    if ~isempty(ytest) & ~isAnndlda
      for ii=1:ny
        b = [b, ytest(:,ii)];
        blabel{end+1} = ['Y Measured ' labelsuffix{ii}];
      end
    end
  end

  if isAnndlda
    if isfield(test,'classification');
      %add classification information
      [dc,classlbl] = plotscores_addclassification(test,ytest);
      b = [b, dc];
      blabel = [blabel classlbl];
    end
  else  
    if ~isempty(test.pred{2})
      for ii=1:ny
        b = [b, test.pred{2}(:,ii)];
        blabel{end+1} = ['Y Predicted ' labelsuffix{ii}];
      end
    end
    
    if ~nores
      if length(test.detail.res)>1 & ~isempty(test.detail.res{2});
        yres = test.detail.res{2};
      elseif options.sct
        yres = test.pred{2}*nan;
      else
        yres = [];  %no cal, no val y-block, skip resids by using empty
      end
      if ~isempty(yres)
        for ii=1:ny
          b = [b, yres(:,ii)];
          blabel{end+1} = ['Y Residual ' labelsuffix{ii}];
        end
      end
    end
  end
  
  if ~nocvpred & options.sct
    b = [b, zeros(size(b,1),ny)*nan];
  end
  
  if ~nocvpredres & options.sct
    b = [b, zeros(size(b,1),ny)*nan];
  end
  
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
