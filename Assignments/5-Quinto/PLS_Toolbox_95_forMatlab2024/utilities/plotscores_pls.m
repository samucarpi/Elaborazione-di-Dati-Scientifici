function a = plotscores_pls(modl,test,options)
%PLOTSCORES_PLS Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
%
% Additional options fields used by PLOTSCORES_PLS:
%            msr: [ {'off'} | 'on' ] include MSR statistic (based on Q
%            residuals)
%
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
%3/31/04 jms -added support for plsda
%6/20/04 jms -cleaned up labeling code, added support to show PLSDA class
%               associated with each y-column
%9/1/04 jms -test if classes exist before trying to make PLSDA-style labels

if ischar(modl);
  options = [];
  options.msr = 'off';
  if nargout==0; clear a; evriio(mfilename,modl,options); else;  a = evriio(mfilename,modl,options); end
  return;
end
if nargin<3; options = []; end
options = reconopts(options,mfilename,0);

nomeasured  = 0;     %default is to try to show measured and residuals (changed if we're missing required info)
nores       = 0;
nostdres    = 0;
nocvpred    = 0;
nocvpredres = 0;
noleverage  = 0;   %default is NOT to include leverage
noerrest    = 0;

if isempty(test) | options.sct==1
  %Fill Model info
  if any(strcmpi(modl.modeltype, {'pls' 'plsda' 'npls'}))
    a = dataset([modl.loads{1,1} modl.loads{1,2}]);
  else
    a = dataset(modl.loads{1,1});
  end
  
  a = copydsfields(modl,a,1,1);
  a.name   = modl.datasource{1}.name;
  
  if isfield(modl.detail,'ssq') & ~isempty(modl.detail.ssq);
    ssq = modl.detail.ssq;
  else
    ssq = [];
  end
  
  if isfield(modl.detail,'originalinclude') & ~isempty(modl.detail.originalinclude) & ~isempty(modl.detail.originalinclude{1})
    a.include{1} = modl.detail.originalinclude{1};
  end
  
  if isempty(a.name)
    a.title{1}     = 'Samples/Scores Plot';
  else
    a.title{1}     = ['Samples/Scores Plot of ',a.name];
  end
  pc               = size(modl.loads{2,1},2);
  
  switch lower(modl.modeltype)
    case {'pcr' 'lwr'}
      for ii=1:pc
        if ~isempty(ssq);
          alabel{ii} = sprintf('Scores on PC %i (%0.2f%%)',ii,ssq(ii,2));
        else
          alabel{ii} = sprintf('Scores on PC %i',ii);
        end
      end
    case {'pls' 'plsda' 'npls'}
      for ii=1:pc
        if ~isempty(ssq);
          alabel{ii} = sprintf('Scores on LV %i (%0.2f%%)',ii,ssq(ii,2));
          alabel{ii+pc} = sprintf('Y Scores on LV %i (%0.2f%%)',ii,ssq(ii,4));
        else
          alabel{ii} = sprintf('Scores on LV %i',ii);
          alabel{ii+pc} = sprintf('Y Scores on LV %i',ii);
        end
      end
    otherwise
      for ii=1:pc
        if ~isempty(ssq);
          alabel{ii} = sprintf('Scores on Comp. %i (%0.2f%%)',ii,ssq(ii,2));
        else
          alabel{ii} = sprintf('Scores on Comp. %i',ii);
        end
      end
  end
  
  if ~isempty(modl.ssqresiduals{1,1});
    a = [a modl.ssqresiduals{1,1}];
    if ~isempty(ssq);
      alabel{end+1}  = sprintf('Q Residuals (%0.2f%%)',100-ssq(pc,3));
    else
      alabel{end+1}  = sprintf('Q Residuals');
    end
    
    %if special "MSR" stat is requested, add it now
    if strcmp(options.msr,'on')
      a = [a sqrt(modl.ssqresiduals{1,1})];
      if ~isempty(ssq);
        alabel{end+1}  = sprintf('MSR (%0.2f%%)',100-ssq(pc,3));
      else
        alabel{end+1}  = sprintf('MSR');
      end
    end
  end
  
  if ~isempty(modl.tsqs{1,1});
    a = [a modl.tsqs{1,1}];
    if ~isempty(ssq);
      alabel{end+1}    = sprintf('Hotelling T^2 (%0.2f%%)',modl.detail.ssq(pc,3));
    else
      alabel{end+1}    = sprintf('Hotelling T^2');
    end
  end
  
  a.label{2,1}   = char(alabel);
  if isfield(modl.detail,'leverage') & ~isempty(modl.detail.leverage);
    e            = dataset(modl.detail.leverage);
    e.label{2,1} = 'Leverage';
    a            = [a, e]; clear e
    noleverage   = 0;
  end
  
  ny             = size(modl.pred{2},2); %number of Y variables
  c              = [];
  alabel       = cell(0);
  
  if ~isempty(test) & isempty(test.detail.data{2})          %no test ydata present
    %     nomeasured = 1;
    %     nores      = 1;
  end
  
  if options.knnscoredistance>0
    c = [c modl.knnscoredistance(options.knnscoredistance)];
    alabel{end+1} = sprintf('KNN Score Distance (k=%i)',options.knnscoredistance);
  end
  
  labelsuffix = {};
  for ii=1:ny
    
    %develop suffix indicating which component this is (added to any other
    %label to indicate y-block column and other info)
    if isempty(modl.detail.data{2}) | isempty(modl.detail.data{2}.label{2,1})
      if strcmp(lower(modl.modeltype),'plsda') & ~isempty(modl.detail.class{2,2});
        classstr = getclassstr(modl.detail.classlookup{2,2},modl.detail.class{2,2}(modl.detail.includ{2,2}(ii)));
        labelsuffix{ii} = sprintf('%i (%s)',modl.detail.includ{2,2}(ii),classstr);
      else
        labelsuffix{ii} = sprintf('%i',modl.detail.includ{2,2}(ii));
      end
    else
      labelsuffix{ii} = sprintf('%i %s',modl.detail.includ{2,2}(ii),deblank(modl.detail.data{2}.label{2,1}(modl.detail.includ{2,2}(ii),:)));
    end
  end

  %pre-calculate measured (so we've got it to calculate misclassification
  %if this is plsda)
  if ~nomeasured & length(modl.detail.data)>1 & ~isempty(modl.detail.data{2});
    meas = modl.detail.data{2}.data(:,modl.detail.includ{2,2});
  else
    nomeasured = 1;
    meas = [];
  end

  if isfield(modl,'classification');
    %add classification information
    [dc,classlbl] = plotscores_addclassification(modl,meas);
    c = [c, dc];
    alabel = [alabel classlbl];
  end
  
  if ~nomeasured
    for ii=1:ny;
      c = [c, meas(:,ii)];
      alabel{end+1} = ['Y Measured ' labelsuffix{ii}];
    end
  end
  
  for ii=1:ny;
    c = [c, modl.pred{2}(:,ii)];
    alabel{end+1} = ['Y Predicted ' labelsuffix{ii}];
  end
  
  if ~nores & length(modl.detail.res)>1 & ~isempty(modl.detail.res{2});
    for ii=1:ny;
      c = [c, modl.detail.res{2}(:,ii)];
      alabel{end+1} = ['Y Residual ' labelsuffix{ii}];
    end
    if isfield(modl.detail,'leverage') & ~isempty(modl.detail.leverage);
      
      for ii=1:ny;
        
        m     = size(modl.detail.res{2},1);
        mincl = length(modl.detail.includ{1,1});
        p     = ones(m,1);
        p(modl.detail.includ{1,1},1) = 1-modl.detail.leverage(modl.detail.includ{1,1},1);             
        ps    = sqrt(diag(modl.detail.res{2}(modl.detail.includ{1,1},ii)'* ...
          (modl.detail.res{2}(modl.detail.includ{1,1},ii)))/(mincl-pc))';
        syres = modl.detail.res{2}(:,ii)./(ps(ones(m,1),:).*sqrt(p));
        
        %The following code does the same as the above (for a single
        %y-column and no excluded samples), but is MUCH easier to read and
        %may be useful for documentation:
        %
        % res   = modl.detail.res{2};
        % L     = modl.detail.leverage;
        % m     = length(modl.detail.includ{1});
        % MSE   = sum((res).^2)./(m-ncomp);
        % syres = res./sqrt(MSE.*(1-L));
        
        c = [c, syres];
        alabel{end+1} = ['Y Stdnt Residual ' labelsuffix{ii}];
      end
    else
      nostdres = 1;
    end
  else
    nores = 1;
    nostdres = 1;
  end
  
  if ismember(lower(modl.modeltype), {'pls', 'pcr'})
    qdd = cooksd(modl);
    if ~isempty(qdd) & size(qdd,1)==size(c,1)
      c = [c, qdd];
      for ii=1:ny
        alabel{end+1} = ['Cooks Distance ' labelsuffix{ii}];
      end
    end
  end
  
  if isfieldcheck(modl,'modl.detail.esterror.pred');
    try
      err = modl.detail.esterror.pred;
      if isempty(err)
        err = ils_esterror(modl);
        modl.detail.esterror.pred = err;
      end
    catch
      err = [];
      noerrest = 1;
    end
  else
    err = [];
    noerrest = 1;
  end
  if isempty(err)
    noerrest = 1;
  end
  if ~noerrest
    for ii=1:ny;
      c = [c, err(:,ii)];
      alabel{end+1} = ['Y Error Est. ' labelsuffix{ii}];
    end
  end
  
  if ~nocvpred & isfield(modl.detail,'cvpred') & ~isempty(modl.detail.cvpred);
    for ii=1:ny;
      c = [c, modl.detail.cvpred(:,ii,min(end,pc))];
      alabel{end+1} = ['Y CV Predicted ' labelsuffix{ii}];
    end
  else
    nocvpred = 1;
  end
  
  if ~nocvpred & ~nomeasured;
    for ii=1:ny;
      c = [c, modl.detail.cvpred(:,ii,min(end,pc))-modl.detail.data{2}.data(:,modl.detail.includ{2,2}(ii))];
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
  if any(strcmpi(test.modeltype, {'pls_pred' 'plsda_pred' 'npls_pred'}))
    if isempty(test.loads{1,2})
      dummyYBlockScores = nan(size(test.loads{1,1}));
      b = dataset([test.loads{1,1} dummyYBlockScores]);
    else
      b = dataset([test.loads{1,1} test.loads{1,2}]);
    end

  else
    b = dataset(test.loads{1,1});
  end
  %b = dataset([test.loads{1,1}]);
  
  if ~isempty(test.ssqresiduals{1,1})
    b = [b test.ssqresiduals{1,1}];
    if strcmp(options.msr,'on')
      b = [b sqrt(test.ssqresiduals{1,1})];
    end
  end
  
  if ~isempty(test.tsqs{1,1})
    b = [b test.tsqs{1,1}];
  end
  
  
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
  
  if isfield(modl.detail,'ssq') & ~isempty(modl.detail.ssq);
    ssq = modl.detail.ssq;
  else
    ssq = [];
  end
  
  if ~options.sct %then add labels
    blabel           = cell(pc,1);                           %Scores, Q, and T^2
    switch lower(modl.modeltype)
      case {'pcr' 'lwr'}
        for ii=1:pc
          if ~isempty(ssq)
            blabel{ii} = sprintf('Scores on PC %i (%0.2f%%)',ii,ssq(ii,2));
          else
            blabel{ii} = sprintf('Scores on PC %i',ii);
          end
        end
      case {'pls' 'plsda' 'npls'}
        for ii=1:pc
          if ~isempty(ssq)
            blabel{ii} = sprintf('Scores on LV %i (%0.2f%%)',ii,ssq(ii,2));
            blabel{ii+pc} = sprintf('Y Scores on LV %i (%0.2f%%)',ii,ssq(ii,4));
          else
            blabel{ii} = sprintf('Scores on LV %i',ii);
            alabel{ii+pc} = sprintf('Y Scores on LV %i',ii);
          end
        end
      otherwise
        for ii=1:pc
          if ~isempty(ssq)
            blabel{ii} = sprintf('Scores on Comp. %i (%0.2f%%)',ii,ssq(ii,2));
          else
            blabel{ii} = sprintf('Scores on Comp. %i',ii);
          end
        end
    end
    
    if ~isempty(test.ssqresiduals{1,1});
      if ~isempty(ssq)
        blabel{end+1}  = sprintf('Q Residuals (%0.2f%%)',100-ssq(pc,3));
      else
        blabel{end+1}  = sprintf('Q Residuals');
      end
      if strcmp(options.msr,'on')
        if ~isempty(ssq)
          blabel{end+1}  = sprintf('MSR (%0.2f%%)',100-ssq(pc,3));
        else
          blabel{end+1}  = sprintf('MSR');
        end
      end
    end
    
    if ~isempty(test.tsqs{1,1});
      if ~isempty(ssq)
        blabel{end+1}    = sprintf('Hotelling T^2 (%0.2f%%)',ssq(pc,3));
      else
        blabel{end+1}    = sprintf('Hotelling T^2');
      end
    end
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
      if strcmp(lower(modl.modeltype),'plsda') & ~isempty(modl.detail.class{2,2})
        classstr = getclassstr(modl.detail.classlookup{2,2},modl.detail.class{2,2}(modl.detail.includ{2,2}(ii)));
        labelsuffix{ii} = sprintf('%i (%s)',modl.detail.includ{2,2}(ii),classstr);
      else
        labelsuffix{ii} = sprintf('%i',modl.detail.includ{2,2}(ii));
      end
    else
      labelsuffix{ii} = sprintf('%i %s',modl.detail.includ{2,2}(ii),deblank(modl.detail.data{2}.label{2,1}(modl.detail.includ{2,2}(ii),:)));
    end
  end
  
  if ~noleverage & options.sct
    if isfield(modl.detail,'leverage') & ~isempty(modl.detail.leverage); % ~strcmp(lower(modl.modeltype),'lwr')
    lev = test.detail.leverage;
    m = test.datasource{1}.size(1);
    if length(lev)<m;
      lev = nan(m,1);
    end
    d = [d, lev];
    end
  end
  
  if options.knnscoredistance>0 & ~isempty(modl.loads{1})
    d = [d test.knnscoredistance(modl,options.knnscoredistance)];
    if ~options.sct;
      blabel{end+1} = sprintf('KNN Score Distance (k=%i)',options.knnscoredistance);
    end
  end

  %pre-calculate ytest in case we need it for misclassifications
  if ~nomeasured
    if length(test.detail.data)>1 & ~isempty(test.detail.data{2});
      ytest = test.detail.data{2}.data(:,test.detail.includ{2,2});
    elseif options.sct
      ytest = ones(test.datasource{1}.size(1),ny)*nan;
    else
      ytest = [];  %no cal data and no y-block use empty (to skip loop below)
    end
  else
    ytest = [];
  end

  if isfield(test,'classification');
    %add classification information
    [dc,classlbl] = plotscores_addclassification(test,ytest);
    d = [d, dc];
    blabel = [blabel classlbl];
  end
  
  if ~nomeasured
    if ~isempty(ytest)
      for ii=1:ny
        d = [d, ytest(:,ii)];
        blabel{end+1} = ['Y Measured ' labelsuffix{ii}];
      end
    end
  end
  
  for ii=1:ny
    d = [d, test.pred{2}(:,ii)];
    blabel{end+1} = ['Y Predicted ' labelsuffix{ii}];
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
        blabel{end+1} = ['Y Residual ' labelsuffix{ii}];
      end
    end
    
    %add studenized residuals for predictions
    if isfield(modl.detail,'leverage') & ~isempty(modl.detail.leverage) & ~isempty(yres) & ~nostdres
      for ii=1:ny;
        
        if ~isempty(test.detail.res{2})
          pres  = test.detail.res{2}(:,ii);
        else
          pres  = nan(size(test.pred{2},1),1);
        end
        m     = size(pres,1);
        mincl = length(modl.detail.includ{1,1});
        ps    = sqrt(diag(modl.detail.res{2}(modl.detail.includ{1,1},ii)'* ...
          (modl.detail.res{2}(modl.detail.includ{1,1},ii)))/(mincl-pc))';
        syres = pres./ps(ones(m,1),:);  % actually semi-studentized residuals
        
        %The following code does the same as the above (for a single
        %y-column and no excluded samples), but is MUCH easier to read and
        %may be useful for documentation:
        %
        % res   = modl.detail.res{2};
        % pres  = test.detail.res{2};
        % m     = length(modl.detail.includ{1});
        % MSE   = sum((res).^2)./(m-ncomp);
        % syres = pres./sqrt(MSE);
        
        d = [d, syres];
        blabel{end+1} = ['Y Stdnt Residual ' labelsuffix{ii}];
      end
    end
  end
  
  if ismember(lower(modl.modeltype), {'pls', 'pcr'})
    qdd = [];
    if  length(test.detail.res)>1 & ~isempty(test.detail.res{2})
      qdd = cooksd(test);
    end
    if ~isempty(qdd) & size(qdd,1)==size(d,1)
      d = [d, qdd];
      for ii=1:ny
        blabel{end+1} = ['Cooks Distance ' labelsuffix{ii}];
      end
    elseif options.sct;
      d = [d, test.pred{2}*nan];   %cooksd is not valid for test set, add NaN if used in cal
    end
  end
  
  if ~noerrest
    if isfieldcheck(test,'test.detail.esterror.pred');
      try
        err = test.detail.esterror.pred;
        if isempty(err)
          err = ils_esterror(modl,test);
          test.detail.esterror.pred = err;
        end
      catch
        err = [];
      end
    else
      if options.sct;
        err = test.pred{2}*nan;
      else
        err = [];
      end
    end
    if ~isempty(err)
      for ii=1:ny;
        d = [d, err(:,ii)];
        blabel{end+1} = ['Y Error Est. ' labelsuffix{ii}];
      end
    end
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
  
  if isempty(a) & isfield(test.detail,'leverage') & ~isempty(test.detail.leverage)
    e            = dataset(test.detail.leverage);
    e.label{2,1} = 'Leverage';
    noleverage   = 0;
    if (size(e,1)==size(b,1))
      b  = [b,e,d]; clear blabel d e
    else
      try
        %There seem to be several unknown sources of trouble that cause
        %sizes to not match up so just catch into no leverage scenario.
        sub_e=e(test.detail.includ{1,1});
        b  = [b,sub_e,d]; clear blabel d sub_e
      catch
        b  = [b, d]; clear blabel d
      end
    end
  else
    b  = [b, d]; clear blabel d
  end
  
  if isempty(a)
    %no cal data? just use test
    a = b;
    a.userdata.datacase = 'test';
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
    a.userdata.datacase = 'caltest';
  end
  
else
    a.userdata.datacase = 'cal';
end

%---------------------------------------------------------
function   classstr = getclassstr(classlookup,classnum)

classstr = classlookup(ismember([classlookup{:,1}],classnum),2);
classstr = sprintf('%s,',classstr{:});
classstr = classstr(1:end-1); %drop ending comma
