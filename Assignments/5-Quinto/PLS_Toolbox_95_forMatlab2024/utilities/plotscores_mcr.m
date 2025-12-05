function a = plotscores_mcr(modl,test,options)
%PLOTSCORES_MCR Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 03/01/04 -initial coding from plotscores_pca.m
%jms 05/04 -allow for missing T^2


if isfield(modl.options,'samplemode')
  %PARAFAC2 has samples in mode 3.
  mymode = modl.options.samplemode;
else
  mymode = 1;
end

if isempty(test) | options.sct==1
  
  %Fill Model info
  a = dataset([modl.loads{mymode,1}, modl.ssqresiduals{mymode,1}, modl.tsqs{mymode,1}]);
  a = copydsfields(modl,a,{mymode 1},1);
  a.name   = modl.datasource{1}.name;
  
  if isempty(a.name)
    a.title{1}     = 'Samples/Scores Plot';
  else
    a.title{1}     = ['Samples/Scores Plot of ',a.name];
  end
  pc               = size(modl.loads{mymode,1},ndims(modl.loads{mymode,1}));
  
  for ii=1:pc
    if ~isempty(modl.detail.ssq)
      alabel{ii}   = sprintf('Scores on Comp %i (%0.2f%%)',ii,modl.detail.ssq(ii,3));
    else
      alabel{ii}   = sprintf('Scores on Comp %i',ii);
    end
  end
  
  if ~isempty(modl.ssqresiduals{mymode,1})
    if ~isempty(modl.detail.ssq)
      alabel{end+1}  = sprintf('Q Residuals (%0.2f%%)',100-modl.detail.ssq(pc,4));
    else
      alabel{end+1}  = sprintf('Q Residuals');
    end
  end
  
  if ~isempty(modl.tsqs{mymode,1})
    if ~isempty(modl.detail.ssq)
      alabel{end+1}  = sprintf('Hotelling T^2 (%0.2f%%)',modl.detail.ssq(pc,4));
    else
      alabel{end+1}  = sprintf('Hotelling T^2');
    end
  end
  
  %add score distance
  if options.knnscoredistance>0 && ~strcmpi(modl.modeltype,'parafac2') ...
                                && ~strcmpi(modl.modeltype,'als_sit')
    a = [a modl.knnscoredistance(options.knnscoredistance)];
    alabel{end+1} = sprintf('KNN Score Distance (k=%i)',options.knnscoredistance);
  end

  a.label{2,1}   = char(alabel);
  
else
  a                = [];
end

%Test Mode
if ~isempty(test) %X-block must be present
  if ~isempty(test.tsqs{mymode,1})
    b = dataset([test.loads{mymode,1}, test.ssqresiduals{mymode,1}, test.tsqs{mymode,1}]);
  else
    b = dataset([test.loads{mymode,1}, test.ssqresiduals{mymode,1}]);
  end
  b = copydsfields(test,b,{mymode 1},1);
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
  
  for ii=1:pc
    if ~isempty(modl.detail.ssq)
      blabel{ii}   = sprintf('Scores on Comp %i (%0.2f%%)',ii,modl.detail.ssq(ii,3));
    else
      blabel{ii}   = sprintf('Scores on Comp %i',ii);
    end
  end
  if ~isempty(modl.detail.ssq)
    blabel{pc+1}  = sprintf('Q Residuals (%0.2f%%)',100-modl.detail.ssq(pc,4));
  else
    blabel{pc+1}  = sprintf('Q Residuals');
  end
  if ~isempty(test.tsqs{1,1})
    if ~isempty(modl.detail.ssq)
      blabel{pc+2}    = sprintf('Hotelling T^2 (%0.2f%%)',modl.detail.ssq(pc,4));
    else
      blabel{pc+2}    = sprintf('Hotelling T^2');
    end
  end

  %add score distance
  if options.knnscoredistance>0 && ~strcmpi(modl.modeltype,'parafac2') && ...
                                   ~strcmpi(modl.modeltype,'als_sit')
    b = [b test.knnscoredistance(modl,options.knnscoredistance)];
    blabel{end+1} = sprintf('KNN Score Distance (k=%i)',options.knnscoredistance);
  end
  
  if ~options.sct %then add labels
    b.label{2,1}   = char(blabel);    
  end
  
  if isempty(a)
    a              = b;     clear b
  else
    cls = [zeros(1,size(a,1)) ones(1,size(b,1))];
    a              = [a;b]; clear b

    %search for empty cell to store cal/test classes
    j = 1;
    while j<=size(a.class,2)
      if isempty(a.class{1,j})
        break;
      end
      j = j+1;
    end
    a.class{1,j} = cls;  %store classes there
    a.classlookup{1,j} = {0 'Calibration';1 'Test'};
    a.classname{1,j} = 'Cal/Test Samples';

  end
end
