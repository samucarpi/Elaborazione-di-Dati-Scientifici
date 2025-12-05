function a = plotscores_cls(modl,test,options)
%PLOTSCORES_CLS Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms

nomeasured = 0;     %default is to try to show measured and residuals (changed if we're missing required info)
nores      = 0;
nostdres   = 0;
nocvpred   = 0;
nocvpredres = 0;

if isempty(test) | options.sct==1
  %Fill Model info
  a = dataset([modl.ssqresiduals{1,1}, modl.tsqs{1,1}]);
  a = copydsfields(modl,a,1,1);
  a.name = modl.datasource{1}.name;

  if isfield(modl.detail,'originalinclude') & ~isempty(modl.detail.originalinclude) & ~isempty(modl.detail.originalinclude{1})
    a.include{1} = modl.detail.originalinclude{1};
  end

  if isempty(a.name)
    a.title{1}     = 'Samples/Scores Plot';
  else
    a.title{1}     = ['Samples/Scores Plot of ',a.name];
  end
  pc               = size(modl.loads{2,1},2);

  alabel = {};
  if ~isempty(modl.ssqresiduals{1,1});
    alabel{end+1}  = sprintf('Q Residuals');
  end

  if ~isempty(modl.tsqs{1,1});
    alabel{end+1}    = sprintf('Hotelling T^2');
  end

  %add score distance
  if options.knnscoredistance>0
    a = [a modl.knnscoredistance(options.knnscoredistance)];
    alabel{end+1} = sprintf('KNN Score Distance (k=%i)',options.knnscoredistance);
  end

  a.label{2,1}   = char(alabel);
  %   if isempty(test)  %i.e. not test
  %     if ~isempty(modl.detail.leverage);
  %       e            = dataset(modl.detail.leverage);
  %       e.label{2,1} = 'Leverage';
  %       a            = [a, e]; clear e
  %     end
  %   end

  ny     = size(modl.pred{2},2); %number of Y variables
  c      = [];
  alabel = cell(0);

  if ~isempty(test) & isempty(test.detail.data{2})          %no test ydata present
%     nomeasured = 1;
%     nores      = 1;
  end

  labelsuffix = {};
  for ii=1:ny
    %develop suffix indicating which component this is (added to any other
    %label to indicate y-block column and other info)
    if isempty(modl.detail.data{2}) | isempty(modl.detail.data{2}.label{2,1})
      labelsuffix{ii} = sprintf('%i',modl.detail.includ{2,2}(ii));
    else
      labelsuffix{ii} = sprintf('%i %s',modl.detail.includ{2,2}(ii),deblank(modl.detail.data{2}.label{2,1}(modl.detail.includ{2,2}(ii),:)));
    end
  end

  if ~nomeasured & length(modl.detail.data)>1 & ~isempty(modl.detail.data{2});
    for ii=1:ny
      c = [c, modl.detail.data{2}.data(:,modl.detail.includ{2,2}(ii))];
      alabel{end+1} = ['Y Measured ' labelsuffix{ii}];
    end
  else
    nomeasured = 1;
  end

  for ii=1:ny
    c = [c, modl.pred{2}(:,ii)];
    alabel{end+1} = ['Y Predicted ' labelsuffix{ii}];
  end

  if ~nores & length(modl.detail.res)>1 & ~isempty(modl.detail.res{2});
    for ii=1:ny
      c = [c, modl.detail.res{2}(:,ii)];
      alabel{end+1} = ['Y Residual ' labelsuffix{ii}];
    end
    %         if ~isempty(modl.detail.leverage);
    %           for ii=1:ny
    %             m     = size(modl.detail.res{2},1);
    %             mincl = length(modl.detail.includ{1,1});
    %             p     = ones(m,1)*nan;
    %             p(modl.detail.includ{1,1}) = 1-modl.detail.leverage(modl.detail.includ{1,1});
    %             ps    = sqrt(diag(modl.detail.res{2}(modl.detail.includ{1,1},ii)'*(modl.detail.res{2}(modl.detail.includ{1,1},ii)./(p(modl.detail.includ{1,1}).^2)))/(mincl-1))';
    %             syres = modl.detail.res{2}(:,ii)./(ps(ones(m,1),:).*sqrt(p));
    %
    %             c = [c, syres];
    %             alabel{end+1} = ['Y Stdnt Residual ' labelsuffix{ii}];
    %           end
    %         else
    nostdres = 1;
    %         end

  else
    nores = 1;
    nostdres = 1;
  end

  %cross-validation results
  if ~nocvpred & isfield(modl.detail,'cvpred') & ~isempty(modl.detail.cvpred);
    for ii=1:ny;
      c = [c, modl.detail.cvpred(:,ii)];
      alabel{end+1} = ['Y CV Predicted ' labelsuffix{ii}];
    end
  else
    nocvpred = 1;
  end

  if ~nocvpred & ~nomeasured;
    for ii=1:ny;
      c = [c, modl.detail.cvpred(:,ii)-modl.detail.data{2}.data(:,modl.detail.includ{2,2}(ii))];
      alabel{end+1} = ['Y CV Residual ' labelsuffix{ii}];
    end
  else
    nocvpredres = 1;
  end

  c            = dataset(c);
  c.label{2,1} = char(alabel);

  a              = [a, c]; clear alabel c

else
  a                = [];
end

%Test Mode
if ~isempty(test) %X-block must be present
  b = dataset([test.ssqresiduals{1,1}, test.tsqs{1,1}]);
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
  end
  pc               = size(modl.loads{2,1},2);

  blabel         = {};                           %Scores, Q, and T^2
  blabel{end+1}  = sprintf('Q Residuals');
  blabel{end+1}    = sprintf('Hotelling T^2');
    
  %add score distance
  if options.knnscoredistance>0
    b = [b test.knnscoredistance(modl,options.knnscoredistance)];
    blabel{end+1} = sprintf('KNN Score Distance (k=%i)',options.knnscoredistance);
  end

  if ~options.sct %then add labels
    b.label{2,1}   = char(blabel);
  end

  [my,ny]        = size(test.pred{2}); %number of Y variables
  d              = [];
  blabel         = cell(0);

  labelsuffix = {};
  for ii=1:ny
    %develop suffix indicating which component this is (added to any other
    %label to indicate y-block column and other info)
    if isempty(modl.detail.data{2}) | isempty(modl.detail.data{2}.label{2,1})
      labelsuffix{ii} = sprintf('%i',modl.detail.includ{2,2}(ii));
    else
      labelsuffix{ii} = sprintf('%i %s',modl.detail.includ{2,2}(ii),deblank(modl.detail.data{2}.label{2,1}(modl.detail.includ{2,2}(ii),:)));
    end
  end

  if ~nomeasured
    if length(test.detail.data)>1 & ~isempty(test.detail.data{2});
      ytest = test.detail.data{2}.data(:,test.detail.includ{2,2});
    elseif options.sct
      ytest = test.pred{2}*nan;
    else
      ytest = [];  %no cal data and no y-block use empty (to skip loop below)
    end
    if ~isempty(ytest)
      for ii=1:ny
        d = [d, ytest(:,ii)];
        if ~options.sct;
          blabel{end+1} = ['Y Measured ' labelsuffix{ii}];
        end
      end
    end
  end

  for ii=1:ny
    d = [d, test.pred{2}(:,ii)];
    if ~options.sct;
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
        d = [d, yres(:,ii)];
        if ~options.sct;
          blabel{end+1} = ['Y Residual ' labelsuffix{ii}];
        end
      end
    end
  end

  if ~nores & ~nostdres & options.sct;
    d = [d, test.pred{2}*nan];   %studentized y-residuals not implemented for test set
  end

  if ~nocvpred & options.sct;
    d = [d, test.pred{2}*nan];   %cvpred is not valid for test set, add NaN if used in cal
  end

  if ~nocvpredres & options.sct;
    d = [d, test.pred{2}*nan];   %cvpred residuals is not valid for test set, add NaN if used in cal
  end

  %create DSO
  d    = dataset(d);
  if ~options.sct;
    d.label{2,1} = blabel;
  end
  b  = [b, d]; clear blabel d

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

%%%NOTE: move T2 and Q columns to end
a = a(:,[4:end 1:3]);
