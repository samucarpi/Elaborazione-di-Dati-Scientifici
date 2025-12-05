function [x0,InitString,aux,constraints]=initloads(modeltype,x0,order,Missing,nocomp,xsize,x,initialization,options);

%INITLOADS Utility for initializing loadings in PARAFAC, TUCKER etc.
%
% [x0,InitString,aux,constraints]=initloads(x0,order,Missing,nocomp,xsize,x,initialization,options);
%
%

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%rb,apr,2002, added output (parameters) from functional constraints in output aux
%rb,oct,2003, changed svd to svds to avoid memory problems for large
%rb,jun,2004, Added compressed fitting
%rb,jul,2004, Bug using many components and tld initialization
%arrays

constraints = cell(order,1);

if iscell(x0) | ismodel(x0)  % Old loadings given
  [x0,InitString,constraints]=oldloadsgiven(modeltype,x0,order,Missing,nocomp,xsize,x,initialization,options);   
   options.constraints = constraints;

else % Use defined initialization
  if initialization == 1||initialization == 0
    [x0,InitString] = rationalstart(x,nocomp,modeltype,options);
    
  elseif initialization == 2
    [x0,InitString] = semirationalstart(x,nocomp,modeltype);
      
  elseif initialization == 3
    [x0,InitString] = randomstart(x,nocomp,modeltype,options);
    
  elseif initialization == 4
    [x0,InitString] = parafaconecompstart(x,nocomp,modeltype,options);

  elseif initialization == 5
    [x0,InitString] = usecompression(x,nocomp,modeltype,options);
    
  elseif initialization > 5
    [x0,InitString,aux] = manystarts(x,nocomp,modeltype,options,initialization);
    
  end
end
if strcmpi(modeltype,'parafac2')
  % Initial guess equal to PARAFAC guess which has to be turned into the right
  % format for PARAFAC2
  if ~isstruct(x0{1})
    for k=1:xsize(end)
      l.P{k} = x0{1};
    end
    l.H = eye(nocomp);
    x0{1}=l;
  end
end
x0 = standardizeloads(x0,options.constraints,options.samplemode,modeltype,options.scaletype);

if ~(exist('aux')==1)
  aux         = cell(order,1);
end


function [x0,InitString,constraints]=oldloadsgiven(modeltype,x0,order,Missing,nocomp,xsize,x,initialization,options); 

if strcmpi(modeltype,'parafac')|strcmpi(modeltype,'parafac2')

  if strcmpi(class(x0),'cell')
    x0 = x0;
    InitString = ' Using old values for initialization';
    constraints = options.constraints;

  elseif ismodel(x0)

    if ~(strcmpi(x0.modeltype,'parafac')|strcmpi(x0.modeltype,'parafac2'))
      error([' Input x0 is model that is not a ',upper(modeltype),' model (name in model structure should be ',upper(modeltype),')'])
    else
      % Use prior model given in x0 to extract loadings
      initloads = x0.loads;
      constraints = options.constraints;
      sampmode = x0.detail.options.samplemode;
      x0 = x0.loads;
      
      %set scores to random values (the actual size may be different from the old model scores)
      x0{options.samplemode} =rand(xsize(options.samplemode),nocomp);
      if strcmp(lower(modeltype),'parafac2')
        if sampmode ~= order
          % Then it's not Dk that's to be fit and hence Pk must be fixed at earlier values
          if sampmode == 1;
            error(' Samplemode cannot be mode 1 in PARAFAC2. Please change the field options.samplemode in the calibration mode')
          end
        else
          x0{1}.P = cell(1,xsize(options.samplemode));
          for k=1:xsize(options.samplemode)
            x0{1}.P{k} = orth(rand(size(x,1),nocomp));
          end
        end
      end
      % set the norm to appr. the same as original
      norm1 = norm(x0{options.samplemode})/xsize(options.samplemode);
      norm2 = norm(initloads{options.samplemode})/size(initloads{options.samplemode},1);
      x0{options.samplemode} = (x0{options.samplemode}/norm1)*norm2;
      InitString = [' Fitting to old model (finding scores in mode ', num2str(options.samplemode),')'];
      for i=1:length(x0)
        if i~=options.samplemode
          o=regresconstr('options');
          o.fixed.weight = -1; % Skip update ('completely' fixed)          
          constraints{i} = o; 
        end
      end
      constraints{options.samplemode}.fixed.weight = 0;  % Unfix any element in sample mode as they are to be found
    end
  elseif ~strcmp(class(x0),'cell')
    error('Initial estimate x0 not a cell array')
  end

elseif strcmpi(modeltype,'tucker')
  if strcmp(class(x0),'cell')
    x0 = x0;
    InitString = ' Using old values for initialization';
    constraints = options.constraints;
  elseif ismodel(x0)
    if ~(strcmpi(x0.modeltype,'tucker')|strcmpi(x0.modeltype,'tucker - rotated'))
      error([' Input x0 is model that is not a ',upper(modeltype),' model (name in model structure should be ',upper(modeltype),')'])
    else
      % Use prior model given in x0 to extract loadings
      initloads = x0.loads;
      constraints = options.constraints;
      x0 = x0.loads;
      %set scores to random values (the actual size may be different from the old model scores)
      x0{options.samplemode} =rand(xsize(options.samplemode),nocomp(options.samplemode));
      % set the norm to appr. the same as original
      norm1 = norm(x0{options.samplemode})/xsize(options.samplemode);
      norm2 = norm(initloads{options.samplemode})/size(initloads{options.samplemode},1);
      x0{options.samplemode} = (x0{options.samplemode}/norm1)*norm2;
      InitString = [' Fitting to old model (finding scores in mode ', num2str(options.samplemode),')'];
      for i=1:length(x0)
        if i~=options.samplemode
          o=regresconstr('options');
          o.fixed.weight = -1; % Skip update ('completely' fixed)
          constraints{i} = o; 
        else
          o=regresconstr('options');
          constraints{i} = o; 
        end
      end
      constraints{options.samplemode}.fixed.weight = 0;  % Unfix any element in sample mode as they are to be found
    end
  elseif ~iscell(x0)
    error('Initial estimate x0 not a cell array')
  end
  
  
else
  error('Modeltype not known in INITLOADS')
  
end
% Check that sizes are ok
for i = 1:order
  if strcmpi(modeltype,'parafac2')&&i==1
  else
    if (size(x0{i},1)~=size(x,i))&&(size(x,i)~=1)
      error('Initial loadings given are not compatible with the size of the array')
    end
  end
end

function varargout = manystarts(x,nocomp,modeltype,options,initialization)

aux =1;
if strcmpi(modeltype,'parafac')|strcmpi(modeltype,'parafac2')
  
  interimopt             = options;
  interimopt.stopcrit(3) = 80;
  interimopt.plots       = 'off';
  interimopt.display     = 'off';
  interimopt.waitbar     = 'off';
  
  interimopt.init   = 1;
  interimopt2 = interimopt;
  interimopt2.stopcrit(3) = 30; % To avoid that it gets too good a start!
  try
      eval(['bestmodel = ',lower(modeltype),'(x,nocomp,0,interimopt2);']);
  catch
      interimopt.init   = 3;
      eval(['bestmodel = ',lower(modeltype),'(x,nocomp,0,interimopt2);']);
  end
  allssq = bestmodel.detail.ssq.residual;
  aux = bestmodel.detail.options.constraints; %save these because they containt the current parameters in case of functional constraints
  for ccount = 2:initialization(1)
    if ccount<4
      interimopt.init = ccount;
    else
      interimopt.init = 3;
    end
    eval(['currentmodel = ',lower(modeltype),'(x,nocomp,interimopt);']);
    allssq = [ allssq currentmodel.detail.ssq.residual];
    if currentmodel.detail.ssq.residual<bestmodel.detail.ssq.residual
      bestmodel = currentmodel;
      aux = bestmodel.detail.options.constraints;
    end
  end
  x0 = bestmodel.loads;
  InitString =  [' Using best of ',num2str(initialization(1)),' small runs' sprintf('\n')];
  for i = 1:initialization(1),
    InitString =  [InitString '    fit model ',num2str(i),': ',num2str(allssq(i)),' ' sprintf('\n')];
  end
  varargout{1} = x0;
  varargout{2} = InitString;
  
elseif strcmp(lower(modeltype),'tucker')
  
  interimopt             = options;
  interimopt.stopcrit(3) = 50;
  interimopt.plots       = 'off';
  interimopt.display     = 'off';
  interimopt.waitbar     = 'off';
  interimopt.init   = 1;
  bestmodel = tucker(x,nocomp,0,interimopt);
  allssq = bestmodel.detail.ssq.residual;
  aux = bestmodel.detail.options.constraints; %save these because they containt the current parameters in case of functional constraints
  for ccount = 2:initialization(1)
    interimopt.init = 3;
    currentmodel = tucker(x,nocomp,0,interimopt);
    allssq = [ allssq currentmodel.detail.ssq.residual];
    if currentmodel.detail.ssq.residual<bestmodel.detail.ssq.residual
      bestmodel = currentmodel;
      aux = bestmodel.detail.options.constraints; %save these because they containt the current parameters in case of functional constraints  
    end
  end
  x0 = bestmodel.loads;
  InitString =  [' Using best of ',num2str(initialization(1)),' small runs' sprintf('\n')];
  for i = 1:initialization(1),
    InitString =  [InitString '    fit model ',num2str(i),': ',num2str(allssq(i)),' ' sprintf('\n')];
  end
  varargout{1} = x0;
  varargout{2} = InitString;
  
else
  error('Modeltype not known in INITLOADS')
end
varargout{3} = aux;

function varargout=rationalstart(x,nocomp,modeltype,options);

if strcmp(lower(modeltype),'parafac')|strcmp(lower(modeltype),'parafac2')
  xsize = size(x);
  if all(xsize>nocomp)&~any(isnan(x(:)))&~any(isinf(x(:))) % Use atld
    x0=atld(x,nocomp,0);
    InitString = ' Using fast approximation for initialization (ATLD)';
  elseif length(size(x)) == 3& ~any(isnan(x(:)))&~any(isinf(x(:))) &~all(xsize<nocomp)
    % Initialize with TLD estimates
    
    m = tld(x,nocomp,0,0);
    x0 = m.loads;
    InitString = ' Using direct trilinear decomposition for initialization';
  else
    [x0,InitString]=semirationalstart(x,nocomp,modeltype);
  end
  varargout{1}=x0;
  varargout{2}=InitString;
  
elseif strcmp(lower(modeltype),'tucker')
  % Use svd if all constraints orthogonal, else random
  allorth = 1;
  for i=1:length(nocomp) % order
    if options.constraints{i}.orthogonal ~= 1;
      allorth=0;
    end
  end
  if allorth
      [varargout{1},varargout{2}] = semirationalstart(x,nocomp,modeltype);
  else
    [varargout{1},varargout{2}] = randomstart(x,nocomp,modeltype,options);
  end
  
else
  error('Modeltype not known in INITLOADS')
end

function varargout=parafaconecompstart(x,nocomp,modeltype,options)

if strcmp(lower(modeltype),'parafac')|strcmp(lower(modeltype),'tucker')|strcmp(lower(modeltype),'parafac2')
  
  interimopt             = options;
  interimopt.stopcrit(3) = 250;
  interimopt.plots       = 'off';
  interimopt.display     = 'off';
  interimopt.waitbar     = 'off';
  interimopt.init   = 1;
  if strcmpi(modeltype,'tucker')
    % Remove constraints for core
    interimopt.constraints = interimopt.constraints(1:length(size(x)));
  end
  model = parafac(x,1,interimopt);
  x0 = model.loads;
  for i=2:max(nocomp) % in case of tucker, take as many components as the highest and reduce accordingly afterwards
    x = x-datahat(model);
    model = parafac(x,1,interimopt);
    for j=1:length(size(x))
      x0{j} = [x0{j} model.loads{j}];
    end
  end  
  if strcmp(lower(modeltype),'tucker') % Normalize loads
    for i=1:length(x0)
      for j=1:max(nocomp)
        x0{i}(:,j) = x0{i}(:,j)/norm(x0{i}(:,j));
      end
      x0{i} = x0{i}(:,1:nocomp(i));
    end
  end
  if strcmp(lower(modeltype),'tucker')
    x0{length(x0)+1} = rand(nocomp);
  end
else
  error('Modeltype not known in INITLOADS')
end
varargout{1}=x0;
varargout{2}=' Using PARAFAC-like approximation for initialization';


function varargout=semirationalstart(x,nocomp,modeltype)

if strcmpi(modeltype,'parafac')|strcmpi(modeltype,'parafac2')
  order = length(size(x));
  xsize = size(x);
  if ~any(isnan(x(:)))&~any(isinf(x(:)))
    for j = 1:length(size(x))
      [u,s,v] = svds(reshape( permute(x,[j 1:j-1 j+1:order]),xsize(j),prod(xsize([1:j-1 j+1:order]))));
      x0{1,j} = u(:,1:min(nocomp,size(u,2)));
      if size(x0{1,j},2)<nocomp   % add extra columns because orthogonalization has removed some
        x0{1,j} = [x0{1,j} rand(xsize(j),nocomp-size(x0{1,j},2))];
      end
    end
  else % When missing data
    for j = 1:length(size(x))
      [t,p,Mean,Fit,RelFit] = pcanipals(reshape( permute(x,[j 1:j-1 j+1:order]),xsize(j),prod(xsize([1:j-1 j+1:order]))),nocomp,0);
      x0{1,j} = t;
      if size(x0{1,j},2)<nocomp   % add extra columns because orthogonalization has removed some
        x0{1,j} = [x0{1,j} rand(xsize(j),nocomp-size(x0{1,j},2))];
      end
    end
  end    
  InitString = ' Using singular values for initialization';
  varargout{1}=x0;
  varargout{2}=InitString;
  
elseif strcmp(lower(modeltype),'tucker')
  order = length(size(x));
  xsize = size(x);
  if ~any(isnan(x(:)))&~any(isinf(x(:)))
    for j = 1:length(size(x))
      [u,out,out] = svds(reshape( permute(x,[j 1:j-1 j+1:order]),xsize(j),prod(xsize([1:j-1 j+1:order]))),nocomp(j));
      % Below flaws for e.g. [u,s,v]=svd(rand(5,12000),0);
      %[u,s,v] = svd(reshape( permute(x,[j 1:j-1 j+1:order]),xsize(j),prod(xsize([1:j-1 j+1:order]))),0);
      x0{1,j} = u(:,1:min(nocomp(j),size(u,2)));
      if size(x0{1,j},2)<nocomp(j)   % add extra columns because orthogonalization has removed some
        x0{1,j} = [x0{1,j} rand(xsize(j),nocomp(j)-size(x0{1,j},2))];
      end
    end
  else % When missing data
    for j = 1:length(size(x))
      [t,p] = pcanipals(reshape( permute(x,[j 1:j-1 j+1:order]),xsize(j),prod(xsize([1:j-1 j+1:order]))),nocomp(j),0);
      x0{1,j} = t;
      if size(x0{1,j},2)<nocomp(j)   % add extra columns because orthogonalization has removed some
        x0{1,j} = [x0{1,j} rand(xsize(j),nocomp(j)-size(x0{1,j},2))];
      end
    end
  end    
  InitString = ' Using singular values for initialization';
  x0{length(x0)+1} = rand(nocomp);
  varargout{1}=x0; % Add core
  varargout{2}=InitString;
  
else
  error('Modeltype not known in INITLOADS')
  
end


function varargout=randomstart(x,nocomp,modeltype,options)

if strcmpi(modeltype,'parafac')|strcmpi(modeltype,'parafac2')
  xsize = size(x);
  for j = 1:length(size(x))
    x0{1,j} = rand(xsize(j),nocomp);
    x0{1,j} = orth(x0{1,j});
    if size(x0{1,j},2)<nocomp   % add extra columns because orthogonalization has removed some
      x0{1,j} = [x0{1,j} rand(xsize(j),nocomp-size(x0{1,j},2))];
    end
  end
  InitString = ' Using orthogonalized random values for initialization';
  varargout{1}=x0;
  varargout{2}=InitString;
  
elseif strcmpi(modeltype,'tucker')
  % Use orthogonalization if all constraints orthogonal, else random
  allorth = 1;
  for i=1:length(nocomp) % order
    if options.constraints{i}.orthogonal ~= 1;
      allorth=0;
    end
  end
  xsize = size(x);
  for j = 1:length(size(x))
    x0{1,j} = rand(xsize(j),nocomp(j));
    if allorth
      x0{1,j} = orth(x0{1,j});
      if size(x0{1,j},2)<nocomp(j)   % add extra columns because orthogonalization has removed some
        x0{1,j} = [x0{1,j} rand(xsize(j),nocomp(j)-size(x0{1,j},2))];
      end
    end
  end
  if allorth
    InitString = ' Using orthogonalized random values for initialization';
  else
    InitString = ' Using random values for initialization';
  end
  x0{length(x0)+1} = rand(nocomp);  % Add core
  varargout{1}=x0;
  varargout{2}=InitString;
  
else
  error('Modeltype not known in INITLOADS')
end

function varargout=usecompression(x,nocomp,modeltype,options);

% options.display = 'off';
% options.plot    = 'off';
if strcmpi(modeltype,'parafac')|strcmpi(modeltype,'parafac2')  
  data = x;
  xsize=size(data);
  
  % Compress successively
  for i=1:length(xsize)
    if strcmp(lower(modeltype),'parafac2')&i==1
      disp([' Mode 1 not compressed in PARAFAC2'])
      comp{i}.data=data;
    else
      disp([' Compressing data mode ',num2str(i)])
      comp{i}=compress(data,i,min(size(data,i),(nocomp + max(nocomp,4)))); % generally take nocomp*2 but take nocomp+4 for low number of components
      data = comp{i}.data;
    end
  end
  
  op = options;
  op.plots = 'off';
  op.display = 'off';
  op.stopcrit(1)=op.stopcrit(1)/100;
 
  disp([' Decompressing mode ',num2str(length(xsize))])
  [x0,InitString] = rationalstart(comp{length(xsize)}.data,nocomp,modeltype,op);
  x0{length(xsize)} = comp{length(xsize)}.load*x0{length(xsize)};
  for i= length(xsize)-1:-1:1
    disp([' Decompressing mode ',num2str(i)])
    if strcmp(lower(modeltype),'parafac2')&i==1;
      3;
    else
      if strcmp(lower(modeltype),'parafac');
        m = parafac(comp{i}.data,x0,op);
      else strcmp(lower(modeltype),'parafac2');
        m = parafac2(comp{i}.data,x0,op);
      end
      x0 = m.loads;
      x0{i} = comp{i}.load*x0{i};
    end
  end
  
  InitString = ' Using fitting to compressed data for initialization';
  varargout{1}=x0;
  varargout{2}=InitString;
  
elseif strcmpi(modeltype,'tucker')
  data = x;
  xsize=size(data);
  
  % Compress successively
  for i=1:length(xsize)
    disp([' Compressing data mode ',num2str(i)])
    comp{i}=compress(data,i,min(size(data,i),nocomp(i)*3));
    data = comp{i}.data;
  end
  
  op = options;
  op.plots = 'off';
  op.display = 'off';
  op.stopcrit(1)=op.stopcrit(1)/100;
 
  disp([' Decompressing mode ',num2str(length(xsize))])
  [x0,InitString] = rationalstart(comp{length(xsize)}.data,nocomp,modeltype,op);
  x0{length(xsize)} = comp{length(xsize)}.load*x0{length(xsize)};
  for i= length(xsize)-1:-1:1
    disp([' Decompressing mode ',num2str(i)])
    m = tucker(comp{i}.data,x0,op);
    x0 = m.loads;
    x0{i} = comp{i}.load*x0{i};
  end
  
  InitString = ' Using fitting to compressed data for initialization';
  varargout{1}=x0;
  varargout{2}=InitString;
  
else
  error('Modeltype not known in INITLOADS')
end



function loads=atld(X,F,Show);
if nargin<3
  Show = 0;
end

xsize = size(X);
order = ndims(X);
RealData = all(isreal(X(:)));

% Initialize with random numbers
for i = 1:order;
  if xsize(i)>=F
    loads{i} = orth(rand(xsize(i),F));
  else
    loads{i} = rand(xsize(i),F);
  end
  invloads{i} = pinv(loads{i});
end

model = outerm(loads);
fit=sum(abs((X(:)-model(:)).^2));
oldfit=2*fit;
maxit=3;
crit=1e-6;
it=0;

while abs(fit-oldfit)/oldfit>crit&it<maxit
  it=it+1;
  oldfit=fit;
  
  % Normalize loadings   
  for mode = 2:order
    scale = sqrt(abs(sum(loads{mode}.^2)));
    loads{1}    = loads{1}*diag(scale);
    loads{mode} = loads{mode}*diag((scale+eps).^-1);
    % Scale occasionally to mainly positiviy
    if RealData & (it==1|it==2|rem(it,1)==0)
      scale = sign(sum(loads{mode}));
      loads{1}    = loads{1}*diag(scale);
      loads{mode} = loads{mode}*diag(scale);
      invloads{mode} = pinv(loads{mode});
    end
  end
  
  if it == 1
    delta = linspace(1,F^(order-1),F);
  end
  
  % Compute new loadings for all modes
  for mode = 1:order;
    
    xprod = X;
    % Multiply pseudo-inverse loadings in all but the mode being estimated
    if mode == 1
      for mulmode = 2:order
        xprod = ntimes(xprod,invloads{mulmode},2,2);
      end
    else
      for j = 1:mode-1
        xprod = ntimes(xprod,invloads{j},1,2);
      end
      for j = mode+1:order
        xprod = ntimes(xprod,invloads{j},2,2);
      end
    end
    
    % Extract first mode loadings from product
    loads{mode} = xprod(:,delta);
    invloads{mode} = pinv(loads{mode});
  end
  
  
  model = outerm(loads);
  fit=sum((X(:)-model(:)).^2);
end
% Normalize loadings   
for mode = 2:order
  scale = sqrt(sum(loads{mode}.^2));
  loads{1}    = loads{1}*diag(scale);
  loads{mode} = loads{mode}*diag(scale.^-1);
end

if Show
  disp(' ')
  disp('    Iteration    sum-sq residuals')
  disp(' ')
  fprintf(' %9.0f       %12.10f    \n',it,fit);
end


function product = ntimes(X,Y,modeX,modeY);


%NTIMES Array multiplication
% X*Y is the array/matrix product of X and Y. These are multiplied across the 
% modeX mode/dimension of X and modeY mode/dimension of Y. The number of levels of X in modeX
% must equal the number of levels in modeY of Y.
%
% The product will be an array of order two less than the sum of the orders of A and B
% and thus works as a straightforward extension of the matrix product. The order
% of the modes in the product are such that the X-modes come first and then the
% Y modes. 
%
% E.g. if X is IxJ and Y is KxL and I equals L, then 
% ntimes(X,Y,1,2) will yield a JxK matrix equivalent to the matrix product
% X'*Y'. If X is IxJxK and Y is LxMxNxO with J = N then 
% ntimes(X,Y,2,3) yields a product of size IxKxLxMxO
% 
%I/O: product = NTIMES(X,Y,modeX,modeY) 
% 
%See also TIMES,MTIMES.

%Copyright Eigenvector Research Inc./Rasmus Bro, 2000
%Rasmus Bro, August 20, 2000

orderX = ndims(X);
orderY = ndims(Y);
xsize  = size(X);
ysize  = size(Y);

X = permute(X,[modeX 1:modeX-1 modeX+1:orderX]);
Y = permute(Y,[modeY 1:modeY-1 modeY+1:orderY]);
xsize2  = size(X);
ysize2  = size(Y);

if size(X,1)~=size(Y,1)
  error(' The number of levels must be the same in the mode across which multiplications is performed')
end

%multiply the matricized arrays
product = reshape(X,xsize2(1),prod(xsize2(2:end)))'*reshape(Y,ysize2(1),prod(ysize2(2:end)));
%reshape to three-way structure
product = reshape(product,[xsize2(2:end) ysize2(2:end)]);


function output=compress(x,mode,lv);

xsize = size(x);
ord = length(xsize);

% Unfold 
x = permute(x,[mode 1:mode-1 mode+1:ord]);
x = reshape(x,xsize(mode),prod(xsize)/xsize(mode));

% chk if any completely missing rows and remove
nanidx = find(sum(isnan(x'))==prod(xsize)/xsize(mode));
x(nanidx,:)=[];

% chk if any completely missing columns and remove
nanidx3 = find(sum(isnan(x))==xsize(mode));
x(:,nanidx3)=[];


% Do pca
[t,p] = pcanipals(x',lv,0);

% Refold to array
if length(nanidx3)>0
  T = repmat(0,prod(xsize)/xsize(mode),lv);
  nanidx4 = find(sum(isnan(x))~=xsize(mode));
  T(nanidx4,:)=t;
else
  T = t;
end

T = reshape(T',[lv xsize([1:mode-1 mode+1:ord])]);
T = ipermute(T,[mode 1:mode-1 mode+1:ord]);

% Generate output
output.data = T;
if length(nanidx)>0
  P = repmat(0,xsize(mode),lv);
  nanidx2 = find(sum(isnan(x'))~=prod(xsize)/xsize(mode));
  P(nanidx2,:)=p;
else
  P = p;
end
output.load = p;

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
if any(sum(isnan(X))==I) % Remove missing columns (since only scores are relevant here)
  X(:,find(sum(isnan(X))==I))=[];
end

[I,J]=size(X);

if any(sum(isnan(X)')==J)
  error(' One slab only contains missing')
end


if F>min(size(X));
  F = min(size(X));
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
  
  T      = rand(I,1);
  P      = rand(J,1);
  Fit    = 2;
  FitOld = 3;
  
  while abs(Fit-FitOld)/FitOld>1e-7 & it < 10;
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
if nargout>3
  Fit     = sum(sum( (Xorig(find(NotMiss)) - Model(find(NotMiss))).^2));
end
if nargout>4
  RelFit  = 100*(1-Fit/ssX);
end


function model = tld(x,ncomp,scl,plots)
%TLD Trilinear decomposition.
%  The Trilinear decomposition can be used to decompose
%  a 3-way array as the summation over the outer product
%  of triads of vectors. The inputs are the 3 way array
%  (x) and the number of components to estimate (ncomp),
%  Optional input variables include a 1 by 3 cell array 
%  containing scales for plotting the profiles in each
%  order (scl) and a flag which supresses the plots when
%  set to zero (plots). The output of TLD is a structured
%  array (model) containing all of the model elements
%  as follows:
%
%     xname: name of the original workspace input variable
%      name: type of model, always 'TLD'
%      date: model creation date stamp
%      time: model creation time stamp
%      size: size of the original input array
%    nocomp: number of components estimated
%     loads: 1 by 3 cell array of the loadings in each dimension
%       res: 1 by 3 cell array residuals summed over each dimension
%       scl: 1 by 3 cell array with scales for plotting loads
%
%  Note that the model loadings are presented as unit vectors
%  for the first two dimensions, remaining scale information is
%  incorporated into the final (third) dimension. 
%
%I/O: model = tld(x,ncomp,scl,plots);
%
%See also: GRAM, MWFIT, OUTER, OUTERM, PARAFAC

%Copyright Eigenvector Research, Inc. 1998-2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%By Barry M. Wise
%Modified April, 1998 BMW
%Modified May, 2000 BMW
%Modified Aug, 2002 RB Included missing data

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear model; evriio(mfilename,varargin{1},options); else; model = evriio(mfilename,varargin{1},options); end
  return; 
end

dx = size(x);

[min_dim,min_mode] = min(dx);
shift_mode = min_mode;
if shift_mode == 3
   shift_mode = 0;
end
x = shiftdim(x,shift_mode);
dx = size(x);

if (nargin < 3 | ~strcmp(class(scl),'cell'))
  scl = cell(1,3);
end
if nargin < 4
  plots = 1;
end
xu = reshape(x,dx(1),dx(2)*dx(3));
opt=mdcheck('options');
opt.max_pcs = ncomp;
opt.frac_ssq = 0.9999;
xu(:,sum(~isfinite(xu))==size(xu,1)) = [];  % Remove completely missing columns
[o1,o2,xu] = mdcheck(xu,opt);clear o1 o2    % Replace missing with estimates

if dx(1) > dx(2)*dx(3)
  [u,s,v] = svds(xu,ncomp);
else
  [v,s,u] = svds(xu',ncomp);
end
uu = u(:,1:ncomp);
xu = zeros(dx(2),dx(1)*dx(3));
for i = 1:dx(1)
  xu(:,(i-1)*dx(3)+1:i*dx(3)) = squeeze(x(i,:,:));
end
xu(:,sum(~isfinite(xu))==size(xu,1)) = [];
[o1,o2,xu] = mdcheck(xu,opt);clear o1 o2

if dx(2) > dx(1)*dx(3)
  [u,s,v] = svds(xu,ncomp);
else
  [v,s,u] = svds(xu',ncomp);
end
vv = u(:,1:ncomp);
xu = zeros(dx(3),dx(1)*dx(2));
for i = 1:dx(2)
  xu(:,(i-1)*dx(1)+1:i*dx(1)) = squeeze(x(:,i,:))';
end
xu(:,sum(~isfinite(xu))==size(xu,1)) = [];
[o1,o2,xu] = mdcheck(xu,opt);clear o1 o2

if dx(3) > dx(1)*dx(2)
  [u,s,v] = svds(xu);
else
  [v,s,u] = svds(xu');
end
ww = u(:,1:2);
clear u s v

g1 = zeros(ncomp,ncomp,dx(3));

uuvv = kron(vv,uu);

for i = 1:dx(3)
  xx = squeeze(x(:,:,i));
  xx = xx(:);
  notmiss = isfinite(xx);
  gg = pinv(uuvv(notmiss,:))*xx(notmiss);
  g1(:,:,i) = reshape(gg,ncomp,ncomp);
  % Old version not formissing; g1(:,:,i) = uu'*squeeze(x(:,:,i))*vv;
end
g2 = g1;
for i = 1:dx(3);
  g1(:,:,i) = g1(:,:,i)*ww(i,2);
  g2(:,:,i) = g2(:,:,i)*ww(i,1);
end
g1 = sum(g1,3);
g2 = sum(g2,3);
[aa,bb,qq,zz,ev] = qz(g1,g2);
if ~isreal(ev)
  %disp('  ')
  %disp('Imaginary solution detected')
  %disp('Rotating Eigenvectors to nearest real solution')
  ev=simtrans(aa,bb,ev);
end
ord1 = uu*(g1)*ev;
ord2 = vv*pinv(ev');
norms1 = sqrt(sum(ord1.^2));
norms2 = sqrt(sum(ord2.^2));
ord1 = ord1*inv(diag(norms1));
ord2 = ord2*inv(diag(norms2));
sf1 = sign(mean(ord1));
if any(sf1==0)
  sf1(find(sf1==0)) = 1;
end
ord1 = ord1*diag(sf1);
sf2 = sign(mean(ord2));
if any(sf2==0)
  sf2(find(sf2==0)) = 1;
end
ord2 = ord2*diag(sf2);
ord3 = zeros(dx(3),ncomp);
xu = zeros(dx(1)*dx(2),ncomp);
for i = 1:ncomp
  xy = ord1(:,i)*ord2(:,i)';
  xu(:,i) = xy(:);
end
for i = 1:dx(3)
  y = squeeze(x(:,:,i));
  y = y(:);
  notmiss = isfinite(y);
  ord3(i,:) = (xu(notmiss,:)\y(notmiss))';
end

if shift_mode
   if shift_mode==1
      ord4 = ord1;
      ord1 = ord3;
      ord3 = ord2;
      ord2 = ord4;
   else
      ord4 = ord1;
      ord1 = ord2;
      ord2 = ord3;
      ord3 = ord4;
   end
   x = shiftdim(x,3-shift_mode);
   dx = size(x);
end

loads = {ord1,ord2,ord3};
xhat = outerm(loads);
dif = (x-xhat).^2;
res = cell(1,3);
res{1} = nansum(dif,1)';
res{2} = nansum(dif,2)';
res{3} = nansum(dif,3)';

% Do additional check for imag solutions
for i=1:3
  if any(~isreal(loads{i}(:)))
    loads{i} = abs(loads{i});
  end
end

  
model = struct('xname',inputname(1),'name','TLD','date',date,'time',clock,...
  'size',dx,'nocomp',ncomp);
model.loads = loads;
model.ssqresiduals = res;
model.scale = scl;


function Vdd=simtrans(aa,bb,ev);
%SIMTRANS Similarity transform to rotate eigenvectors to real solution
Lambda = diag(aa)./diag(bb);
n=length(Lambda);
[t,o]=sort(Lambda);
Lambda(n:-1:1)=Lambda(o);
ev(:,n:-1:1)=ev(:,o);

Theta = angle(ev);
Tdd = zeros(n);
Td = zeros(n);
ii = sqrt(-1);

k=1;
while k <= n
  if k == n
    Tdd(k,k)=1;
    Td(k,k)=(exp(ii*Theta(k,k)));
    k = k+1;
  elseif abs(Lambda(k))-abs(Lambda(k+1)) > (1e-10)*abs(Lambda(k)) 
    %Not a Conjugate Pair
    Tdd(k,k)=1;
    Td(k,k)=(exp(ii*Theta(k,k)));
    k = k+1;
  else 
    %Is a Conjugate Pair
    Tdd(k:k+1,k:k+1)=[1, 1; ii, -ii];
    Td(k,k)=(exp(ii*0));  
    Td(k+1,k+1)=(exp(ii*(Theta(k,k+1)+Theta(k,k))));
    k = k+2;
  end
end
Vd = ev*pinv(Td);
Vdd = Vd*pinv(Tdd);
if imag(Vdd) < 1e-3
   Vdd = real(Vdd);
end


function y = nanmean(x)

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



function y = nansum(x,mode)
nans = isnan(x);
i = find(nans);
x(i) = zeros(size(i));
x = permute(x,[mode 1:mode-1 mode+1:length(size(x))]);
x = reshape(x,size(x,1),prod(size(x))/size(x,1))';
y = sum(x);


