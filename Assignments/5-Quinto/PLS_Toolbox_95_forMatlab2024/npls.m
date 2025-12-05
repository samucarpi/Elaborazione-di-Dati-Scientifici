function model = npls(x,y,maxlv,model,options);
%NPLS Multilinear-PLS (N-PLS) for true multi-way regression.
%  Fits a multilinear PLS1 or PLS2 regression model to (x) and (y)
%  [R. Bro, J. Chemom., 1996, 10(1), 47-62]. The NPLS function also
%  can be used for calibration and prediction.
%
%  INPUTS:
%        x = X-block,
%        y = Y-block, and
%    ncomp = the number of factors to compute, or
%    model = in prediction mode, this is a structure containing
%            a NPLS model.
%
%  OPTIONAL INPUT:
%  options = options structure containing the field:
%    outputregrescoef: if this is set to 0 no regressions coefficients working
%                      on X directly are calculated (relevant for large arrays)
%
%  OUTPUT:
%    model = standard model structure (see MODELSTRUCT)
%
%I/O: model   = npls(x,y,ncomp,options);       %identifies model (calibration step)
%I/O: pred    = npls(x,y,ncomp,model,options); %predict with prior model (prediction step)
%I/O: npls demo                                %runs a demo of the NPLS function.
%I/O: options = npls('options');               %provides default options for NPLS.
%
%See also: CONLOAD, CROSSVAL, DATAHAT, EXPLODE, GRAM, MODLRDER, MPCA, OUTERM, PARAFAC, TLD, UNFOLDM

%Copyright Eigenvector Research, Inc. 1999
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0  %
  analysis('npls');
  return
  
elseif ischar(x) %Help, Demo, Options
  options = [];
  options.name             = 'options';
  options.display          = 'on';     %Displays output to the command window
  options.plots            = 'final';  %Governs plots to make
  options.outputregrescoef = 'on';        %Specifies that regression coefficients working directly on X will be output (uses memory)
  options.blockdetails     = 'standard';     % Whether to exclude X residuals
  options.preprocessing = {[],[]};
  options.definitions   = @optiondefs;
  if nargout==0;
    evriio(mfilename,x,options);
  else
    model = evriio(mfilename,x,options);
  end
  return;
end

%Sort out inputs
switch nargin
  case 2
    %npls(x,model)
    if ismodel(y) % prediction mode
      model   = y;
      maxlv   = [];
      y       = [];
      options = [];
    else
      error(['Input to ' upper(mfilename) ' not recognized.'])
    end
  case 3
    %npls(x,y,maxlv);
    %npls(X,maxlv,model);
    %npls(X,model,options);
    %npls(X,y,model);
    [x, y, maxlv, model, options] = resolve3params(x, y, maxlv);
    
  case 4
    % Real io : npls(x,y,maxlv,model);
    %
    %npls(X,    y,maxlv,  model);
    %npls(X,   [],maxlv,  model);
    %npls(x,    y,maxlv,options);
    %npls(X,    y,model,options)
    %npls(X,maxlv,model,options)
    if ismodel(model)
      %npls(X, y,maxlv,model);
      %npls(X,[],maxlv,model);
      options = [];
    elseif isstruct(model)
      %npls(x,    y,maxlv,options)
      %npls(X,    y,model,options)
      %npls(X,maxlv,model,options)
      options = model;
      
      [x, y, maxlv, model] = resolve3params(x, y, maxlv);
    else
      error(' The fourth input must be either a prior model (prediction) or algorithmic options (calibration)')
    end
    
  case 5
    % Real io : npls(x, y, maxlv, model, options)
    % npls(x,y,maxlv,model,options);  % Do nothing
    
end

%reconcile X and Y into DSOs and store as needed
if ~isa(x,'dataset');
  x = dataset(x);
  if isa(y,'dataset');
    x.include{1,1}=y.include{1,1};
  end
end
if ~isa(y,'dataset')
  y = dataset(y);
  if ~isempty(y) & size(y,1)~=size(x,1)
    error('Number of samples in X and Y must match')
  end
  if isa(x,'dataset') & ~isempty(y);
    y.include{1,1}=x.include{1,1};
  end
end

if ~isempty(y) & islogical(y.data)
  %convert logical y-block to double (to allow regression and preprocessing
  %to work correctly)
  y.data = double(y.data);
end
xorig = x;   %save otherwise un-modified SDOs
yorig = y;

%both are DSOs? merge include field on first mode (if needed)
if ~isempty(y)
  i = intersect(x.include{1},y.include{1});
  if ( length(i)~=length(x.include{1,1}) | length(i)~=length(y.include{1,1}) )
    x.include{1,1} = i;
    y.include{1,1} = i;
  end
end
%store reconciled X as DSO and extract data
Xsdo  = x;
inc  = x.include;
x    = x.data(inc{:});

%store reconciled Y as DSO and extract data
Ysdo = y;
haveyblock = ~isempty(y);
if haveyblock;
  yname = inputname(2);
  inc   = y.include;
  y     = y.data(inc{:});
else
  yname = 'Not Given';
end

% reconcile options
options = reconopts(options,'npls');
if strcmpi(options.display,'on')
  show = 1;
else
  show = 0;
end

PredictMode = ~isempty(model);

if ~PredictMode
  
  if length(size(y))>2
    error(' This N-PLS routine only handles uni- & multivariate y')
  end
  
  % check preprocessing
  [x,Xsdo,y,Ysdo,prepro] = preprocesscheck(x,Xsdo,y,Ysdo,options,PredictMode,model);
  
  % INITIALIZATION
  maxit=20;
  DimX=size(x);
  order = length(DimX);
  [I,Jy]=size(y);
  mdop=mdcheck('options');
  mdop.max_missing = 0.9999;
  mdop.tolerance = [1e-4 10];
  [flag,missX] = mdcheck(x,mdop);
  if flag
    MissingX = 1;
    presentX = find(~missX);
  else
    MissingX = 0;presentX = 0;missX    = 0;
  end
  [flag,missY] = mdcheck(y,mdop);
  if flag
    MissingY = 1;
    presentY = find(~missY);
  else
    MissingY = 0;presentY = 0;missY    = 0;
  end
  
  if length(Xsdo.includ{1})~=size(Xsdo.data,1)
    % See if there are missing data in possibly non-included samples
    incallsamps = Xsdo.includ;
    incallsamps{1} = [1:size(Xsdo.data,1)]';
    xnoninclud = Xsdo.data(incallsamps{:});
    sx = size(xnoninclud);
    xnoninclud(inc{1},:) = [];
    sx(1) = size(xnoninclud,1);
    xnoninclud = reshape(xnoninclud,sx);
    [flag,missXnoninclud] = mdcheck(xnoninclud,mdop);
    if flag
      MissingXnoninclud = 1;
    else
      MissingXnoninclud = 0;missXnoninclud    = 0;
    end
    incallsamps = Ysdo.includ;
    incallsamps{1} = [1:size(Ysdo.data,1)]';
    ynoninclud = Ysdo.data(incallsamps{:});
    sy = size(ynoninclud);
    ynoninclud(inc{1},:) = [];
    sy(1) = size(ynoninclud,1);
    ynoninclud = reshape(ynoninclud,sy);
    [flag,missYnoninclud] = mdcheck(ynoninclud,mdop);
    if flag
      MissingYnoninclud = 1;
    else
      MissingYnoninclud = 0;missYnoninclud    = 0;
    end
  end
  
  
  order=length(DimX);
  crit=1e-8;
  
  if show
    disp(' ')
    disp(' Fitting N-PLS ...')
    txt=[];
    for i=1:order-1
      txt=[txt num2str(DimX(i)) ' x '];
    end
    txt=[txt num2str(DimX(order))];
    disp([' Input X: ',num2str(order),'-way ',txt, ' array'])
    disp([' Input Y: ',num2str(size(y,1)),' x ',num2str(size(y,2)), ' matrix'])
    disp([' A ',num2str(maxlv),'-component model will be fitted'])
    
    if MissingX
      disp([' ', num2str(100*(length(find(missX))/prod(DimX))),'% missing values in X']);
    else
      disp(' No missing values in X')
    end
    if MissingY
      disp([' ', num2str(100*(length(find(missY))/prod(size(y)))),'% missing values in Y']);
    else
      disp(' No missing values in Y')
    end
  end
  
  B=zeros(maxlv,maxlv);
  T=zeros(size(x,1),maxlv);
  U=zeros(size(y,1),maxlv);
  W = cell(1,order-1);
  Q = zeros(size(y,2),maxlv);
  G = cell(1,maxlv);
  
  if MissingX
    ex2=x(presentX).^2;
    SSX=sum(ex2);
  else
    SSX=sum(x(:).^2);
  end
  if MissingY
    SSy=sum(sum(y(presentY).^2));
  else
    SSy=sum(sum(y.^2));
  end
  
  ssx=[];
  ssy=[];
  Xres=x;
  yres=y;
  if length(Xsdo.includ{1})~=size(Xsdo.data,1)
    yresnoninclud = ynoninclud;
  end
  xmodel=zeros(size(x,1),numel(x)/size(x,1));
  
  % ITERATION
  for num_lv=1:maxlv
    
    %init
    %     [out,maxy]=max(sum(yres.^2));
    %     u = yres(:,maxy);   OLD VERSION
    if size(yres,2)==1
      u = yres;
    else
      [u] = pcanipals(yres,1,0);
    end
    
    
    t=rand(DimX(1),1);
    tgl=t+2;it=0;
    while (norm(t-tgl)/norm(t))>crit&it<maxit
      tgl=t;
      it=it+1;
      % w=X'u
      Z = innerprod(x,u,MissingX,missX);
      LoadW = RankOne(Z);
      for i=1:length(LoadW)
        lwn = norm(LoadW{i});
        if lwn==0; lwn=1; end
        LoadW{i} = LoadW{i}/lwn;
      end
      % t=Xw
      [t,unfoldw] = project(x,LoadW,MissingX,missX);
      % q=y't
      Z = innerprod(yres,t,MissingY,missY);
      if norm(Z)>0
        LoadQ{1} = Z/norm(Z);
      else
        LoadQ{1}=ones(size(Z));
      end
      % u=yq
      u = project(yres,LoadQ,MissingY,missY);
      
    end
    
    if length(Xsdo.includ{1})~=size(Xsdo.data,1)
      % Calculate extra u- and t-scores if there are non-included samples
      unoninclud = project(yresnoninclud,LoadQ,MissingYnoninclud,missYnoninclud);
      tnoninclud = project(xnoninclud,LoadW,MissingXnoninclud,missXnoninclud);
    end
    
    
    % Assign parameters
    T(:,num_lv)=t;
    for f = 2:order;
      w = [W{f-1} LoadW{f-1}];
      W{f-1} = w;
    end
    U(:,num_lv)=u;
    Q(:,num_lv) = LoadQ{1};
    if length(Xsdo.includ{1})~=size(Xsdo.data,1)
      Tnoninclud(:,num_lv) = tnoninclud;
      Unoninclud(:,num_lv) = unoninclud;
    end
    
    
    % Find core for LS modeling of X
    TempLoads{1}=T(:,1:num_lv);
    for i=2:order
      TempLoads{i} = W{i-1};
    end
    g = corecalc(x,TempLoads);
    G{num_lv} = g;
    
    % REGRESSION PART (INNER RELATION)
    B(1:num_lv,num_lv)=pinv(T(:,1:num_lv))*U(:,num_lv);
    ypred=T(:,1:num_lv)*B(1:num_lv,1:num_lv)*Q(:,1:num_lv)';
    
    % RESIDUALS
    xmodel=xmodel+T(:,num_lv)*unfoldw';
    model = t3model(g,TempLoads);
    Xres = x - model;
    yres=y-ypred;
    if length(Xsdo.includ{1})~=size(Xsdo.data,1)
      yresnoninclud = ynoninclud- Tnoninclud(:,1:num_lv)*B(1:num_lv,1:num_lv)*Q(:,1:num_lv)';
    end
    
    
    % Calculate LS residuals for reporting variance
    if MissingX
      exs = Xres(presentX).^2;
      ssx = [ssx;sum(exs(:))];
    else
      ssx=[ssx;sum(Xres(:).^2)];
    end
    if MissingY
      eys = (y(presentY)-ypred(presentY)).^2;
      ssy=[ssy;sum(eys(:))];
    else
      ssy=[ssy;sum(sum((y(:)-ypred(:)).^2))];
    end
  end
  ssx= [ [SSX(1);ssx] [0;100*(1-ssx/SSX(1))]];
  ssy= [ [SSy(1);ssy] [0;100*(1-ssy/SSy(1))]];
  
  % Redo T/U to include possible non-included samples
  if length(Xsdo.includ{1})~=size(Xsdo.data,1) % Then some samples were not included
    t = zeros(size(Xsdo.data,1),maxlv);
    u = t;
    t(Xsdo.includ{1},:) = T;
    u(Ysdo.includ{1},:) = U;
    inc2 = Xsdo.includ;
    inc2 = [1:size(Xsdo.data,1)]';
    inc2 = delsamps(inc2,Xsdo.includ{1});
    t(inc2,:) = Tnoninclud;
    u(inc2,:) = Unoninclud;
    T = t;
    U = u;
  end
  % Change ypred from included to all samples
  ypred=T(:,1:num_lv)*B(1:num_lv,1:num_lv)*Q(:,1:num_lv)';
  
  % Calculate regression coefficients that apply directly to X
  if strcmpi(options.outputregrescoef,'on')|options.outputregrescoef==1
    R = outerm(W,0,1);
    for iy=1:size(y,2)
      if length(DimX) == 2
        dd = [DimX(2) 1];
      else
        dd = DimX(2:end);
      end
      bnpls{iy,1} = reshape(R(:,1)*B(1)*Q(iy,1),dd);
      for i=2:maxlv
        bnpls{iy,i} = reshape( sum( (R(:,1:i)*B(1:i,1:i)*diag(Q(iy,1:i)))' )' ,dd);
      end
    end
    
  end
  
  % SCREEN OUTPUT
  if show~=0&~isnan(show)
    disp('  ')
    disp('   Percent Variation Captured by N-PLS Model   ')
    disp('  ')
    disp('   LV      X-Block    Y-Block')
    disp('   ----    -------    -------')
    ssq = [(1:maxlv)' ssx(2:maxlv+1,2) ssy(2:maxlv+1,2)];
    format = '   %3.0f     %6.2f     %6.2f';
    for i = 1:maxlv
      tab = sprintf(format,ssq(i,:)); disp(tab)
    end
  end
  
  % Calculate residuals
  dif = reshape(Xres,DimX).^2;
  res = cell(1,order);
  for i = 1:order
    r = dif;
    r = nansum(r,i);
    r = squeeze(r);
    res{i} = repmat(NaN,size(Xsdo.data,i),1);
    res{i}(Xsdo.includ{i}) = r(:);
  end
  
  % Save the model as a structured array
  model = modelstruct('NPLS',order);
  [datasource{1:2}] = getdatasource(xorig,yorig);
  model.datasource{1}.name = inputname(1);
  model.datasource{2}.name = yname;
  model.date = date;
  model.time = clock;
  model.info = 'Scores are in row 1 of cells in the loads field. T=loads{1,1} and U=loads{2,1}.';
  if strcmpi(options.outputregrescoef,'on')|options.outputregrescoef == 1
    model.reg=bnpls;
  end
  
  model.loads{1,1} = T;
  for i=1:length(W);
    model.loads{i+1,1}=W{i};
  end
  model.loads{1,2} = U;
  model.loads{2,2}=Q;
  model.core = G;
  model.description{2} = ['Constructed on ',date,'at ',num2str(model.time(4)),':',num2str(model.time(5)),':',num2str(model.time(6))];
  if maxlv==1
    model.description{3} = [num2str(maxlv),' N-PLS component'];
  else
    model.description{3} = [num2str(maxlv),' N-PLS components'];
  end
  model.detail.bin = B;
  if strcmpi(options.blockdetails,'all')
    inc2 = Xsdo.includ;
    inc2{1}=[1:size(Xsdo.data,1)]';
    temploads = model.loads(1:end,1);
    temploads{end+1}=model.core{end};
    Xres = repmat(NaN,size(Xsdo.data));
    if length(temploads)==3 % Then its two-way
      d = temploads{1}*temploads{3}*temploads{2}';
      Xres(inc2{:}) = Xsdo.data(inc2{:})-d;
    else
      Xres(inc2{:}) = Xsdo.data(inc2{:})-datahat(temploads);
    end
    model.detail.res{1} = Xres;
    model.pred{1} = Xsdo.data - Xres;
    
    inc2 = Ysdo.includ;
    inc2{1}=[1:size(Ysdo.data,1)]';
  end
  
  % Make residual control limits
  inc=Xsdo.includ;
  if ~strcmpi(options.blockdetails,'compact')
    resopts.algorithm = 'jm';
    %reslim95 = residuallimit(Xres(inc{:}),.95,resopts);
    %reslim99 = residuallimit(Xres(inc{:}),.99,resopts);
    reslim95 = residuallimit(Xres,.95,resopts);
    reslim99 = residuallimit(Xres,.99,resopts);
    if ~isstruct(model.detail.reslim)
      model.detail.reslim=[];
    end
    model.detail.reslim.lim95 = reslim95;
    model.detail.reslim.lim99 = reslim99;
  end
  
  model.pred{1,2}   = preprocess('undo',prepro{2},ypred);
  model.pred{1,2}   = model.pred{1,2}.data;
  model.detail.data{2} = yorig;
  model = copydsfields(Xsdo,model,[],{1 1});
  model = copydsfields(Ysdo,model,[],{1 2});
  model.datasource = datasource;
  % Add preprocessing
  model.detail.preprocessing = prepro;
  model = calcystats(model,PredictMode);
  
  for i=1:order %over modes
    model.ssqresiduals(i,1) = res(i);
    inc  = model.detail.includ{i,1};
    L = model.loads{i,1};
    if i==1, % Handle that include is special for the first mode (Loadings contain scores from non-included samples which should not be included in the covariance matrix)
      f               = L*pinv(L(inc,:)'*L(inc,:))*(size(L(inc,:),1)-1);
    else
      f               = L*pinv(L'*L)*(size(L,1)-1);
    end
    model.tsqs{i,1} = repmat(NaN,size(Xsdo.data,i),1);
    model.tsqs{i,1} = sum(L.*f,2);
    if length(model.detail.includ{i,1})>maxlv,
      model.detail.tsqlim{i,1} = tsqlim(length(model.detail.includ{i,1}),maxlv,95);
    else
      model.detail.tsqlim{i,1} = NaN;
    end
  end
  model.detail.means{1,1}    = mean(Xsdo.data(Xsdo.includ{1},:)); %mean of X-block
  model.detail.stds{1,1}     = std(Xsdo.data(Xsdo.includ{1},:));  %mean of X-block
  model.detail.options       = options;
  model.detail.ssq  = [(1:maxlv)' ssx(2:end,2)-[0;ssx(2:end-1,2)] ssx(2:end,2) ssy(2:end,2)-[0;ssy(2:end-1,2)] ssy(2:end,2) ];
  if strcmpi(options.blockdetails,'all')
    model.detail.data{1} = xorig;
  end
  
  
  model = addhelpyvars(model);
  
  % PLOT MODEL
  if (strcmpi(options.plots,'on')|strcmpi(options.plots,'final')|options.plots==1)
    try
      modelviewer(model,Xsdo);
    catch
      %do NOT abort model building if we have a problem doing plots
    end
  end
  
  
elseif PredictMode
  if nargin>2
    if isstruct(maxlv)
      options = maxlv;
    end
  end
  if isempty(maxlv)
    maxlv = size(model.loads{1,1},2);
  end
  if maxlv>size(model.loads{1,1},2) % In case too high lv chosen it is automatically set to max
    maxlv = size(model.loads{1,1},2);
  end
  
  %make sure x-block variables (modes 2+) are correct size and use the
  %include field from the model (if it doesn't already match)
  sz = size(Xsdo);
  if length(sz)~=length(model.datasource{1}.size) | sz(2:end)~=model.datasource{1}.size(1,2:end)
    error('Variables included in data do not match variables expected by model');
  else
    for mode = 2:length(sz);
      if length(Xsdo.include{mode,1})~=length(model.detail.includ{mode,1}) | any(Xsdo.include{mode,1} ~= model.detail.includ{mode,1});
        missing = setdiff(model.detail.includ{mode,1},Xsdo.include{mode,1});
        Xsdo.data(:,missing) = nan;  %replace expected but missing data with NaN's to force replacement
        Xsdo.include{mode,1} = model.detail.includ{mode,1};
      end
    end
  end
  
  if haveyblock
    %check if the include field on the y-block matches what is expected by
    %the model
    if size(Ysdo.data,2)==length(model.detail.includ{2,2})
      %SPECIAL CASE - ignore the y-block column include field if the
      %y-block contains the same number of columns as the include field.
      model.detail.includ{2,2} = 1:size(Ysdo.data,2);
    else
      if size(Ysdo.data,2) < length(model.detail.includ{2,2})
        %trap this one error to give more diagnostic information than the
        %error below gives
        error('Y-block columns included in model do not match number of columns in test set.');
      end
      try
        Ysdo.include{2} = model.detail.includ{2,2};
        yorig = Ysdo;
      catch
        error('Model include field selections will not work with current Y-block.');
      end
    end
  end
  
  % check preprocessing
  [x,Xsdo,y,Ysdo,prepro] = preprocesscheck(x,Xsdo,y,Ysdo,options,PredictMode,model);
  
  %model is APPLIED to all samples
  incl = Xsdo.include;
  x    = Xsdo.data(:,incl{2:end});
  origmodel = model;
  order     = length(size(x));
  
  if haveyblock
    incl = Ysdo.include;
    y = Ysdo.data(:,incl{2:end});
  end
  
  maxit=20;
  I = size(x,1);
  mdop=mdcheck('options');
  mdop.max_missing = 0.9999;
  mdop.tolerance = [1e-4 10];
  [flag,missX] = mdcheck(x,mdop);
  if flag
    MissingX = 1;
    presentX = find(~missX);
  else
    MissingX = 0;presentX = 0;missX    = 0;
  end
  Xres = x;
  
  T    = zeros(I,maxlv);
  for i=2:size(model.loads,1)
    if size(model.loads{i,1},1)>0
      W{i-1}=model.loads{i,1};
    end
  end
  Q    = model.loads{2,2};
  G    = model.core;
  B    = model.detail.bin;
  
  for f=1:maxlv
    % Make cell with only the f'th loadings
    w{1} = W{1}(:,f);
    
    for o = 2:order-1
      w{o} = W{o}(:,f);
    end
    [t,unfoldw] = project(x,w,MissingX,missX);
    T(:,f)=t;
    AllLoad{1} = t;
    for o = 1:order-1
      AllLoad{o+1} = W{o}(:,f);
    end
    
    TempLoads{1}=T(:,1:f);
    for i=2:order
      TempLoads{i} = W{i-1}(:,1:f);
    end
    model3 = t3model(G{f},TempLoads);
    Xres = x - reshape(model3,size(x));
    
    %Xres=x-reshape(T(:,1:f)*reshape(G{f},f,f^2)*kron(W{2}(:,1:f),W{1}(:,1:f))',size(x));
    
  end
  ypred=T*B(1:maxlv,1:maxlv)*Q(:,1:maxlv)';
  dif = Xres.^2;
  res = cell(1,order);
  for i = 1:order
    x = dif;
    x = permute(x,[i 1:i-1 i+1:order]);
    for j = 1:size(x,1);
      res{i}(j) = sum(x(j,~isnan(x(j,:))));
    end
  end
  
  % Save the model as a structured array
  model = copydsfields(xorig,model,[],{1 1});
  model.datasource{1} = getdatasource(xorig);
  model.datasource{1}.name = inputname(1);
  if haveyblock
    model.datasource{2} = getdatasource(yorig);
    model.datasource{2}.name = inputname(2);
  end
  model.date = date;
  model.time = clock;
  model.info = 'Scores are in row 1 of cells in the loads field. T=loads{1,1} and U=loads{2,1}.';
  model.description{2} = ['Constructed on ',date,'at ',num2str(model.time(4)),':',num2str(model.time(5)),':',num2str(model.time(6))];
  if maxlv==1
    model.description{3} = [num2str(maxlv),' N-PLS component'];
  else
    model.description{3} = [num2str(maxlv),' N-PLS components'];
  end
  if strcmpi(options.blockdetails,'all')
    inc = Xsdo.includ;
    model.detail.data{1} = xorig;
    model.pred{1}        = Xsdo.data(:,inc{2:end})-Xres;
    model.detail.res{1}  = Xres;
  else
    model.detail.data{1} = [];
    model.pred{1}        = [];
    model.detail.res{1}  = [];
  end
  model.pred{1,2}   = preprocess('undo',prepro{2},ypred);
  model.pred{1,2}   = model.pred{1,2}.data;
  if haveyblock
    model.detail.data{2}=yorig;
  else
    model.detail.data{2} = [];
  end
  model.loads{1,2} = [];
  
  model = copydsfields(xorig,model,1,{1 1});
  model.detail.includ{1,2} = model.detail.includ{1,1};   %x-includ samples for y samples too
  [datasource{1:2}] = getdatasource(xorig,yorig);
  model.datasource = datasource;
  % Add preprocessing
  model.detail.preprocessing = prepro;
  model = calcystats(model,PredictMode);
  
  model.detail.reslim  = origmodel.detail.reslim;
  model.detail.tsqlim  = origmodel.detail.tsqlim;
  for i=1:ndims(x)
    model.ssqresiduals{i} = res{i}(:);
  end
  
  
  for i=1:1 % Only first mode
    inc = origmodel.detail.includ{i,1};
    oL = origmodel.loads{1,1};
    f = sqrt(1./(diag(oL(inc,1:maxlv)'* oL(inc,1:maxlv))/(length(inc)-1)));
    if size(T,2) > 1;
      model.tsqs{1,1}     = sum((T*diag(f)).^2,2);
    else
      model.tsqs{1,1}     = (T*diag(f)).^2;
    end
    model.loads{1,1} = T;
  end
  model.detail.means{1,1}    = mean(Xsdo.data(Xsdo.includ{1},:)); %mean of X-block
  model.detail.stds{1,1}     = std(Xsdo.data(Xsdo.includ{1},:));  %mean of X-block
  model.detail.options       = options;
  %model.detail.ssq  = [(1:maxlv)' ssx(2:end,2)-[0;ssx(2:end-1,2)] ssx(2:end,2) ssy(2:end,2)-[0;ssy(2:end-1,2)] ssy(2:end,2) ];
  
  model.detail.ssqpred.X.fitted         = sum(res{1});
  model.detail.ssqpred.X.percentage     = 100*(1-sum(res{1})/sum(x(~isnan(x(:))).^2));
  model.detail.ssqpred.X.OverModes      = res;
  
  model.modeltype = 'NPLS_PRED';
  
end

%-------------------------------------------------------------------
function NewArray = innerprod(X,y,Missing,ElemntMiss);

% Calculates the inner product of a n-way array X
% and a vector y within the first mode of X
% Handles missing elements in X by adjusting the inner product
% according to the non-missing elements


DimX = size(X);
if Missing
  X            = reshape(X,DimX(1),prod(DimX(2:end)));
  ElemntMiss   = reshape(ElemntMiss,DimX(1),prod(DimX(2:end)));
  NewArray     = zeros(1,prod(DimX(2:length(DimX))));
  id           = sum(ElemntMiss); % vector with zeros in those columns that have no missing
  MissCol      = find(id);
  NoneMiss     = find(~id(:));
  sumsqY       = sum(y.^2);
  NewArray(NoneMiss) = (y'*X(:,NoneMiss))/sumsqY; % inner product for columns of X with no missing
  for i =1:length(MissCol);
    id2 = find(~ElemntMiss(:,MissCol(i)));
    if length(id2)==0 % All elements missing
      NewArray(MissCol(i)) = NaN;
    else
      NewArray(MissCol(i)) = y(id2)'*X(id2,MissCol(i))/(y(id2)'*y(id2));
    end
  end
  NewArray = squeeze(reshape(NewArray,[DimX(2:end) 1]));
else
  out      = reshape(X,DimX(1),prod(DimX(2:length(DimX))));
  NewArray = squeeze(reshape(y'*out,[DimX(2:end) 1]));
end

%-------------------------------------------------------------------
function LoadW = RankOne(Z);

% makes a rank-one model of Z

sZ = size(Z);
if min(sZ)==1
  % Insert singleton dimensions for lower 1-dimensional modes
  for i=1:length(sZ);
    if sZ(i)==1
      if i~=length(sZ)
        LoadW{i}=1;
      end
    else
      nz = norm(Z);
      if nz==0; nz=1; end
      LoadW{i} = Z(:)/nz;
    end
  end
elseif length(sZ)==2
  if any(isnan(Z(:))) % missing elemnts
    [t,p] = pcanipals(Z,1,0);
    LoadW{1}=t;
    np = norm(p);
    if np==0; np=1; end
    LoadW{2}=p/np;
    %     o=parafac('options');o.plots='off';o.display='off';o.stopcrit(3)=3;
    %     model = parafac(Z,1,o);
    %     LoadW = model.loads;
    %     LoadW{length(sZ)} = LoadW{length(sZ)}/norm(LoadW{length(sZ)});
  else
    [u,s,v]=svd(Z,0);
    LoadW{1} = u(:,1);
    LoadW{2} = v(:,1);
  end
else
  o=parafac('options');o.plots='off';o.waitbar='off';o.display='off';o.stopcrit(3)=30;
  model = parafac(Z,1,o);
  LoadW = model.loads;
  LoadW{length(size(Z))} = LoadW{length(size(Z))}/norm(LoadW{length(size(Z))});
end

%-------------------------------------------------------------------
function [t,w] = project(X,LoadW,Missing,miss);

w = LoadW{1};
for i = 2:length(LoadW)
  w = kron(LoadW{i},w);
end
w = w(:);
if Missing
  t = zeros(size(X,1),1);
  for i = 1:size(X,1)
    id = find(~miss(i,:));
    %if w(id)'*w(id) == 0;
    %if length(id) == 0;
    if isempty(id) | w(id)'*w(id) == 0;
      t(i) = 0;
    else
      t(i) = X(i,id)*w(id)/(w(id)'*w(id));
    end
  end
else
  I = size(X,1);
  J = numel(X)/size(X,1);
  t = reshape(X,I,J)*w;
end


%-------------------------------------------------------------------
function Core = corecalc(X,loads)

%CORECALC to calculate the Tucker3 core array given the data array X
% and the loadings
%
% INPUT
% X        multi-way data array
% loads    cell array. i'th element holds the loading matrix of the i'th mode
% I/O
% Core = corecalc(X,loads);
%  See also: PARAFAC, CORCONDIA, TUCKER

%  Copyright Eigenvector Research 1993-99
%  Modified RB 12/99

% INITIALIZATION
xsize = size(X);
if ~iscell(loads)
  error(' Input loads must be a cell array holding the i-mode loading matrix in its i''th element')
end
Ord = length(loads);

if nargin<3
  orth = 0;
end

DoWeight = 0;

% Check for missing and replace those with model estimates initially
DoMiss = 0;
if any(isnan(X(:)))
  % Weights for missing elements zero
  WeightMiss = ones(size(X));
  WeightMiss(find(isnan(X)))=0;
  
  % Replace the missing elements with model estimates initially
  % That way they won't bias the estimation procedure
  model = outerm(loads);
  X(find(isnan(X)))=model(find(isnan(X)));
  
  % If additional weights given, let those corresponding to missing elements be zero
  Weights = WeightMiss;
  clear model WeightMiss
  DoWeight = 1;
end

if DoWeight
  WMax     = max(abs(Weights(:)));
  W2       = Weights.*Weights;
end

% CALCULATE PSEUDOINVERSES INITIALLY
for i=1:Ord;
  % Z{i} pseudoinverse of loading matrix of mode i
  L = loads{i};
  L(~isfinite(L)) = 0;
  Z{i} = pinv(L'*L)*L';
  Z{i} = pinv(L);
end

iter     = 0;
NotConv  = 1;
itermax = 100;
if DoWeight
  ConvCrit = 1e-8;
  Fit     = sum(X(:).^2);
  FitOld  = 2*Fit;
end

% CALCULATE CORE (ITERATIVELY IF WEIGHTED OR MISSING ELEMENTS)
while ((DoWeight & NotConv)|iter < 1) & iter < itermax
  
  iter = iter + 1;
  
  % If Weighted regression is to be used, do majorization to make
  % a transformed data array to be fitted in a least squares sense
  if DoWeight & iter > 1
    FitOld = Fit;
    XtoFit = reshape(model,xsize) + (WMax^(-2)*W2).*(X - reshape(model,xsize));
  else
    XtoFit = X;
  end
  
  % project X on pseudo-inverses
  DimCore = size(X);
  Core = XtoFit;
  for i = 1:Ord
    Core = Z{i}*reshape(Core,DimCore(1),prod(DimCore(2:end)));
    Core = reshape(Core,[size(Core,1) DimCore(2:end)]);
    Core = shiftdim(Core,1);
    DimCore = size(Core);
  end
  if DoWeight
    % calculate model
    model = t3model(Core,loads);
    
    % calculate fit
    Esq = ((XtoFit-model).*Weights).^2;
    Fit = sum(Esq(:));
    if abs(Fit-FitOld)/FitOld<ConvCrit & iter>50
      NotConv = 0;
    end
  end
end


%-------------------------------------------------------------------
function model = t3model(core,loads)

% Find a Tucker3 model from given multi-way core and loadings

if max(size(core))== 1
  model = outerm(loads)*core;
else
  
  DimCore = size(core);
  model = loads{1}*reshape(core,size(core,1),numel(core)/size(core,1));
  model = reshape(model,[size(loads{1},1) DimCore(2:end)]);
  
  for i = 2:length(loads)
    model = shiftdim(model,1);
    DimX = size(model);
    model = loads{i}*reshape(model,DimX(1),prod(DimX(2:end)));
    model = reshape(model,[size(loads{i},1) DimX(2:end)]);
  end
  model = shiftdim(model,1);
end



%-------------------------------------------------------------------
function [t,p,Mean,Fit,RelFit] = pcanipals(X,F,cent)

% NIPALS-PCA WITH MISSING ELEMENTS
% 20-6-1999
%
% Calculates a NIPALS PCA model. Missing elements
% are denoted NaN. The solution is nested
%
% Comparison for data with missing elements
% NIPALS : Nested    , not least squares, not orthogonal solutoin
% LSPCA  : Non nested, least squares    , orthogonal solution
%
% I/O
% [t,p,Mean,Fit,RelFit] = pcanipals(X,F,cent);
%
% X   : Data with missing elements set to NaN
% F   : Number of componets
% cent: One if centering is to be included, else zero
%
% Copyright
% Rasmus Bro
% KVL 1999
% rb@kvl.dk
%

[I,J]=size(X);
if any(sum(isnan(X))==I)|any(sum(isnan(X)')==J)
  % Just set to zero - the effect is the same
  id = find(sum(isnan(X))==I);
  X(:,id)=0;
  id = find(sum(isnan(X'))==J);
  X(id,:)=0;
  % error(' One column or row only contains missing')
end

Xorig      = X;
Miss       = isnan(X);
NotMiss    = ~isnan(X);

ssX    = sum(X(find(NotMiss)).^2);

Mean   = zeros(1,J);
if cent
  Mean    = nanmean(X);
end
X      = X - ones(I,1)*Mean;

t=[];
p=[];

for f=1:F
  Fit    = 3;
  OldFit = 6;
  it     = 0;
  
  T      = nanmean(X')';
  P      = nanmean(X)';
  % Adjust if T or P turns zero
  if std(T)<eps*1000;
    T = T + randn(size(T));
  end
  if std(P)<eps*1000;
    P = P + randn(size(P));
  end
  Fit    = 2;
  FitOld = 3;
  
  while abs(Fit-FitOld)/FitOld>1e-7 & it < 1000;
    FitOld  = Fit;
    it      = it +1;
    
    for j = 1:J
      id=find(NotMiss(:,j));
      P(j) = T(id)'*X(id,j)/(T(id)'*T(id));
    end
    P = P/norm(P);
    
    for i = 1:I
      id=find(NotMiss(i,:));
      T(i) = P(id)'*X(i,id)'/(P(id)'*P(id));
    end
    
    Fit = X-T*P';
    Fit = sum(Fit(find(NotMiss)).^2);
  end
  t = [t T];
  p = [p P];
  X = X - T*P';
  
end

Model   = t*p' + ones(I,1)*Mean;
Fit     = sum(sum( (Xorig(find(NotMiss)) - Model(find(NotMiss))).^2));
RelFit  = 100*(1-Fit/ssX);

%-------------------------------------------------------------------
function y = nanmean(x)
if isempty(x) % Check for empty input.
  y = NaN;
  return
end
nans = isnan(x);
i = find(nans);
x(i) = zeros(size(i));

if min(size(x))==1,
  count = length(x)-sum(nans);
else
  count = size(x,1)-sum(nans);
end
i = find(count==0);
count(i) = ones(size(i));
y = sum(x)./count;
y(i) = i + NaN;


%-------------------------------------------------------------------
function y = nansum(x,mode)
nans = isnan(x);
i = find(nans);
x(i) = zeros(size(i));
x = permute(x,[mode 1:mode-1 mode+1:length(size(x))]);
x = reshape(x,size(x,1),numel(x)/size(x,1))';
y = sum(x);


%-------------------------------------------------------------------
function [xmod,xsdo,ymod,ysdo,prepro] = preprocesscheck(x,xsdo,y,ysdo,options,predictmode,oldmodel);
xmod = x;
ymod = y;
try
  if isempty(options.preprocessing);
    options.preprocessing{1} = {[],[]};
  end
  if ~isa(options.preprocessing,'cell');
    options.preprocessing = {options.preprocessing};  %insert into cell
  end
catch
  options.preprocessing = {[],[]};  %reinterpet as empty cell
end

if ~predictmode
  %calibration mode preprocessing
  if ~isempty(options.preprocessing{1});
    try
      [xsdo,prepro{1}] = preprocess('calibrate',options.preprocessing{1},xsdo);
      incl = xsdo.include;
      xmod = xsdo.data(incl{:});
    catch
      error('Unable to preprocess X - selected preprocessing may not be valid for multi-way data');
    end
  else
    prepro{1} = [];
  end
  
  %calibration mode preprocessing
  if ~isempty(options.preprocessing{2});
    try
      [ysdo,prepro{2}] = preprocess('calibrate',options.preprocessing{2},ysdo);
      incl = ysdo.include;
      ymod = ysdo.data(incl{:});
    catch
      error('Unable to preprocess Y - selected preprocessing may not be valid');
    end
  else
    prepro{2} = [];
  end
  
else
  if ~isempty(oldmodel.detail.preprocessing);
    prepro = oldmodel.detail.preprocessing;
  else
    prepro = {[],[]};
  end
  if ~isempty(prepro{1});
    try
      xsdo = preprocess('apply',prepro{1},xsdo);
      incl = xsdo.include;
      xmod = xsdo.data(incl{:});
    catch
      error('Unable to preprocess X - selected preprocessing may not be valid for multi-way data');
    end
  end
  if ~isempty(prepro{2}) & ~isempty(ysdo)
    try
      ysdo = preprocess('apply',prepro{2},ysdo);
      incl = ysdo.include;
      ymod = ysdo.data(incl{:});
    catch
      error('Unable to preprocess Y - selected preprocessing may not be valid');
    end
  end
end

%-------------------------------------------------------------------
function [x, y, maxlv, model, options] = resolve3params(x, y, maxlv);
model   = [];
options = [];
if ismodel(maxlv)
  %npls(X,model,options);
  %npls(X,maxlv,model);
  %npls(X,y,model);
  model = maxlv;
  % now decide between npls(X,maxlv,model) and npls(X,y,model)
  if max(size(y))==1 & size(x,1)~=1 % Then y is maxlv
    %npls(X,maxlv,model);   <-- this signature was removed
    msg1 = ['Calling ' upper(mfilename) ' as npls(X, maxlv, model) is not allowed'];
    msg2 = [ 'because of possible ambiguity when resolving parameters.'];
    msg3 = [ 'Use the 5 parameter form of npls instead: npls(X, [], maxlv, model, [])'];
    msg = sprintf('%s \n %s \n %s', msg1, msg2, msg3);
    error(msg);
  else
    %npls(X,y,model);
    % npls(X,maxlv,model) and npls(X,y,model) are indestinguishable
    % when size(x,1)==1, so cannot assume...
    % Nevertheless, currently assumes is the case npls(X,y,model):
    maxlv = size(model.loads{1,1},2); % and y as is
  end
elseif isstruct(maxlv)
  %npls(X,model,options);
  options = maxlv;
  model   = y;
  y       = [];
  maxlv   = size(model.loads{1,1},2);
else
  %npls(x,y,maxlv);
end

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                            userlevel       description
'display'                'Display'        'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
'plots'                  'Display'        'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
'outputregrescoef'       'Standard'       'select'        {'on' 'off'}                     'novice'        'Specifies that regression coefficients working directly on X will be output (uses memory)';
'preprocessing'          'Standard'       'matrix'        ''                               'novice'        'Preprocessing structure.';
'blockdetails'           'Standard'       'select'        {'compact' 'standard' 'all'}     'novice'        'Extent of predictions and raw residuals included in model. ''standard'' = none, ''all'' x-block.';
};

out = makesubops(defs);
