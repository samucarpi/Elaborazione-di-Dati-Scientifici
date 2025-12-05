function a = plotscores_pca(modl,test,options)
%PLOTSCORES_PCA Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
% Additional options fields used by PLOTSCORES_PCA:
%   reducedstats: [ {'none'} | 'only' | 'both' ] governs reporting of
%                  statistics as "reduced" (normalized to confidence limit)
%                  when possible. 'both' returns both reduced and regular
%                  stats. 'only' returns only reduced stats. 'none' returns
%                  only regular stats.
%            cmi: [ {'off'} | 'on' ] include combined statistics when
%                  possible. Note that reducedstats must be "on" to view
%                  CMI.
%       cmiorder: [ 1 ] order of combined statistics
%
%I/O: a = plotscores_pca(modl,test,options)
%
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 8/25/03 -fixed bug associted with non-model input to plotscores (get
%    number of PCs from LAST MODE of scores instead of loads)

if ischar(modl);
  options = [];
  options.reducedstats = 'none';
  options.sammon       = 0;
  options.cmi          = 'off';
  options.cmiorder     = 1;
  options.addcalfields    = '';
  options.autoclass    = false;
  if nargout==0; clear a; evriio(mfilename,modl,options); else;  a = evriio(mfilename,modl,options); end
  return; 
end
if nargin<3; options = []; end
options = reconopts(options,mfilename,0);

%convert addcalfields into cell if not already.
if ~iscell(options.addcalfields)
  options.addcalfields = {options.addcalfields};
end

%figure out what stats we should include
%first entry in each flag below is for "regular" stats, second is for
%"reduced" stats and is equal to the reduced confidence level
regularstats = ~strcmp(options.reducedstats,'only');
showQ   = [regularstats 0];
showT2  = [regularstats 0];
showCMI = [(exist('cmicalc','file') & strcmp(options.cmi,'on')) 0];
if ~strcmp(options.reducedstats,'none')
  if isfieldcheck('model.detail.reslim',modl) && iscell(modl.detail.reslim) && ~isempty(modl.detail.reslim)
    showQ(2) = modl.detail.options.confidencelimit;
  end
  if isfieldcheck('model.detail.tsqlim',modl) && iscell(modl.detail.tsqlim) && ~isempty(modl.detail.tsqlim)
    showT2(2) = modl.detail.options.confidencelimit;
  end
  if showCMI(1)
    showCMI(2) = modl.detail.options.confidencelimit;
  end
end

if isempty(test) | options.sct==1
  %Fill Model info
  a = modl.loads{1,1};
  if showQ(1)
    if ~isempty(modl.ssqresiduals{1,1})
      a = [a modl.ssqresiduals{1,1}];
    else
      showQ(1:2) = 0;
    end
  end
  if showT2(1)
    if ~isempty(modl.tsqs{1,1})
      a = [a modl.tsqs{1,1}];
    else
      showT2(1:2) = 0;
    end
  end
  if showQ(2)
    a = [a modl.ssqresiduals{1,1}./modl.detail.reslim{1}];
  end
  if showT2(2)
    a = [a modl.tsqs{1,1}./modl.detail.tsqlim{1}];
  end
  if showCMI(2)
    [cmival,cmilim] = cmicalc(modl,showCMI(2),options.cmiorder);
    a = [a cmival];
  end
  if options.knnscoredistance>0
    a = [a modl.knnscoredistance(options.knnscoredistance)];
  end
  if options.sammon>0
    if modl.ncomp>1
      options.sammon = min(modl.ncomp-1,options.sammon);
      sm = sammon(modl.scores,modl.scores(:,1:options.sammon));
      options.sammon = size(sm,2);      
      a = [a sm];
    else
      options.sammon = 0;
    end
  end

  a = dataset(a);
  a = copydsfields(modl,a,1,1);
  a.name   = modl.datasource{1}.name;
  
  if isfield(modl.detail,'originalinclude') & ~isempty(modl.detail.originalinclude) & ~isempty(modl.detail.originalinclude{1})
    a.include{1} = modl.detail.originalinclude{1};
  end
  
  if isempty(a.name)
    a.title{1}     = 'Samples/Scores Plot';
  else
    a.title{1}     = ['Samples/Scores Plot of ',a.name];
  end
  pc               = size(modl.loads{1,1},ndims(modl.loads{1,1}));
  
  alabel = {};
  for ii=1:pc
    if ~isempty(modl.detail.ssq);
      alabel{ii}   = sprintf('Scores on PC %i (%0.2f%%)',ii,modl.detail.ssq(ii,3));
    else
      alabel{ii}   = sprintf('Scores on PC %i',ii);
    end
  end
  
  if ~isempty(modl.detail.ssq);
    Qvarcap  = sprintf(' (%0.2f%%)',100-modl.detail.ssq(pc,4));
    T2varcap = sprintf(' (%0.2f%%)',modl.detail.ssq(pc,4));
  else
    Qvarcap = '';
    T2varcap = '';
  end

  if showQ(1)
    alabel{end+1}  = sprintf('Q Residuals%s',Qvarcap);
  end
  if showT2(1)
    alabel{end+1}  = sprintf('Hotelling T^2%s',T2varcap);
  end
  if showQ(2)
    alabel{end+1}  = sprintf('Q Residuals Reduced (p=%0.3f)%s',showQ(2),Qvarcap);
  end
  if showT2(2)
    alabel{end+1}  = sprintf('Hotelling T^2 Reduced (p=%0.3f)%s',showT2(2),T2varcap);
  end
  
  if showCMI(2)
    alabel{end+1}  = sprintf('CMI (reduced to %0.3f, p=%0.3f)',cmilim,showCMI(2));
  end
  
  %add score distance
  if options.knnscoredistance>0
    alabel{end+1} = sprintf('KNN Score Distance (k=%i)',options.knnscoredistance);
  end
  if options.sammon>0
    for ii=1:options.sammon
      alabel{end+1} = sprintf('Sammon Proj. %i',ii);
    end
  end
  
  
  a.label{2,1}   = char(alabel);
  
  %--- add fields specified by options.addfield ---
  for j=1:length(options.addcalfields);
    if isfieldcheck(['modl.detail.' options.addcalfields{j}],modl);
      a = [a modl.detail.(options.addcalfields{j})];
    end
  end
  
else
  a                = [];
end

%Test Mode
if ~isempty(test) %X-block must be present
  b = test.loads{1,1};
  if showQ(1)
    b = [b test.ssqresiduals{1,1}];
  end
  if showT2(1)
    b = [b test.tsqs{1,1}];
  end
  if showQ(2)
    b = [b test.ssqresiduals{1,1}/modl.detail.reslim{1}];
  end
  if showT2(2)
    b = [b test.tsqs{1,1}/modl.detail.tsqlim{1}];
  end
  if showCMI(2)
    [cmival,cmilim] = cmicalc(modl,test,showCMI(2),options.cmiorder);
    b = [b cmival];
  end
  if options.knnscoredistance>0
    b = [b test.knnscoredistance(modl,options.knnscoredistance)];
  end
  if options.sct & options.sammon>0
    b = [b nan(size(b,1),options.sammon)];
  end
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
  end
  pc               = size(modl.loads{2,1},2);
  
  if ~options.sct %then add labels
    blabel           = {};
    
    for ii=1:pc
      blabel{ii}   = sprintf('Scores on PC %i (%0.2f%%)',ii,modl.detail.ssq(ii,3));
    end

    Qvarcap = '';  %do not show captured information if not showing calibration data
    T2varcap = '';
    if showQ(1)
      blabel{end+1}  = sprintf('Q Residuals%s',Qvarcap);
    end
    if showT2(1)
      blabel{end+1}  = sprintf('Hotelling T^2%s',T2varcap);
    end
    if showQ(2)
      blabel{end+1}  = sprintf('Q Residuals Reduced (p=%0.3f)%s',showQ(2),Qvarcap);
    end
    if showT2(2)
      blabel{end+1}  = sprintf('Hotelling T^2 Reduced (p=%0.3f)%s',showT2(2),T2varcap);
    end

    if showCMI(2)
      blabel{end+1} = sprintf('CMI (reduced to %0.3f, p=%0.3f)',cmilim,showCMI(2));
    end

    %add score distance
    if options.knnscoredistance>0
      blabel{end+1} = sprintf('KNN Score Distance (k=%i)',options.knnscoredistance);
    end
    
    b.label{2,1}   = char(blabel);
    
  end
  
  if isempty(a)
    a              = b;     clear b
  else
    cls = [zeros(1,size(a,1)) ones(1,size(b,1))];

    if size(b,2)<size(a,2);
      b = [b zeros(size(b,1),size(a,2)-size(b,2))*nan]; % pad with NaN's as needed
    end
    a              = [a;b]; clear b
        
    %search for empty cell to store cal/test classes
    j = 1;
    while j<=size(a.class,2) & ~isempty(a.class{1,j});
      j = j+1;
    end
    a.class{1,j} = cls;  %store classes there
    a.classlookup{1,j} = {0 'Calibration';1 'Test'};
    a.classname{1,j} = 'Cal/Test Samples';

  end
end

%look for rows or columns which are all NaN and hard-delete them
bad = all(isnan(a.data),1);
if any(bad)
  a = a(:,~bad);  %keep non-bad columns
end

if options.autoclass
  a = doautoclass(a,modl);
end

%--------------------------------------------------
function [data,newset] = doautoclass(data,modl)

%Get subset of data to build classes on
%check for sammon projections and use those if we can...
subinds = strmatch('Sammon Proj',data.label{2});
if isempty(subinds)
  %none? just use scores
  subinds = 1:modl.ncomp;
end
toclass = data(data.include{1},subinds);  %extract data to use for classing
cls = zeros(1,size(data,1)); % placeholders for excluded samples
try
  cls(data.include{1}) = dbscan(toclass); % do classing on included
catch
  %any error? just exit without classes
  newset = [];
  return
end

%locate appropriate class set
ind = 1;
classes    = data.class(1,:);
classnames = data.classname(1,:);
while ind<=length(classes) & ~isempty(classes{ind}) & ~strcmpi(classnames{ind},'AutoClasses')
  ind=ind+1;
end
data.classlookup{1,ind} = {};
data.class{1,ind} = cls;
if any(cls==-1)
  data.classlookup{1,ind}.assignstr = {-1 'No Class'};
end
data.classname{1,ind} = 'AutoClasses';
newset = ind;
