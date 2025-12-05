function Core = corecalc(X,loads,orth,Weights,OldCore);
%CORECALC Calculate the Tucker3 core given the data array and loadings.
%  INPUTS:
%        X = multi-way data array and
%    loads = the loadings in which is a cell array (the i'th cell
%            holds the loading matrix of the i'th mode).
%
%  OPTIONAL INPUTS:
%     orth = if orth = 0, it is assumed that the loadings are NOT orthogonal. 
%            Otherwise, orthogonal loadings are assumed.
%  Weights = Optional weights for updating the core in a weighted 
%            least squares sense
%  OldCore = Initial value of the core
%
%  OUTPUT:
%     Core = Tucker3 core.
% 
%I/O: Core = corecalc(X,loads,orth,Weights,OldCore);
%I/O: corecalc demo
%
%See also: CORCONDIA, COREANAL, PARAFAC, TUCKER

%Copyright Eigenvector Research 1999
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified RB 10/02

% TO DO Allow for Tucker2/Tucker1 core

show = 0;

if nargin == 0; X = 'io'; end
varargin{1} = X;
if ischar(varargin{1});
  options = [];
  if nargout==0; 
    evriio(mfilename,varargin{1},options); 
  else; 
    Core = evriio(mfilename,varargin{1},options); 
  end
  return; 
end

if isa(X,'dataset')% Then it's a SDO
  Xsdo = X;
  inc=X.includ;            
  X = X.data(inc{:});
end


% INITIALIZATION
xsize = size(X);
if ismodel(loads)
  loads = loads.loads;
end

if ~strcmp(class(loads),'cell')
  error(' Input loads must be a cell array holding the i-mode loading matrix in its i''th element')
end
Ord = length(loads);

if nargin<3
  orth = 0;
end

DoWeight = 0;
if nargin==4
  if length(size(Weights))==length(size(X))
    if all(size(Weights)==size(X))
      DoWeight = 1;
    end
  end
end

% Check if OldCore fits the sizes of loadings
OldCoreOK = 0;	
if nargin>4
  OldCoreOK = 1;
  if length(size(OldCore))~=length(loads)
    OldCoreOK = 0;
  else
    for i = 1:length(loads)
      if size(loads{i},2)~=size(OldCore)
        OldCoreOK = 0;
      end
    end
  end
end

% Check for missing and replace those with model estimates initially
DoMiss = 0;
if any(isnan(X(:)))
  % Weights for missing elements zero
  WeightMiss = ones(size(X));
  WeightMiss(isnan(X))=0;
  
  % Replace the missing elements with model estimates initiallyf
  % That way they won't bias the estimation procedure too much
  if ~OldCoreOK  % No initial value of core given, hence a PARAFAC model is assumed
    try
      model = outerm(loads);
    catch % Then it was a tucker model after all!
      DimG =[];
      for i=1:Ord
        DimG(i) = size(loads{i},2);
      end
      OldCore = rand(DimG);
      ll = loads;
      ll{end+1}=OldCore;
      model = datahat(ll);
    end
  else
      ll = loads;
      ll{end+1}=OldCore;
      model = datahat(ll);
  end
  X(isnan(X))=model(isnan(X));
  
  % If additional weights given, let those corresponding to missing elements be zero
  if DoWeight
    Weights = Weights.*WeightMiss;
  else
    Weights = WeightMiss;
  end
  clear model WeightMiss
  DoWeight = 1;
end

if DoWeight
  WMax     = max(abs(Weights(:)));
  W2       = Weights.*Weights;
end

% CALCULATE PSEUDOINVERSES INITIALLY
if ~orth
  for i=1:Ord;
    % Z{i} pseudoinverse of loading matrix of mode i
    L = loads{i};
    Z{i} = pinv(L'*L)*L';
    %      Z{i} = pinv(L);
  end   
else
  for i=1:Ord;
    % Z{i} pseudoinverse of loading matrix of mode i
    L = loads{i};
    Z{i} = L';
  end
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
    Core = fixcore(X,Core);
    model = Core;
    for i = 1:Ord
      DimCore = size(model);
      model = loads{i}*reshape(model,DimCore(1),prod(DimCore(2:end)));
      model = reshape(model,[size(loads{i},1) DimCore(2:end)]);
      model = shiftdim(model,1);
    end
    
    % calculate fit
    Esq = ((squeeze(XtoFit)-squeeze(model)).*squeeze(Weights)).^2;
    Fit = sum(Esq(:));
    if abs(Fit-FitOld)/FitOld<ConvCrit & iter>50
      NotConv = 0;
    end
    if show
      if iter == 1
        disp(' ')
        disp('     Calculating Core')
        disp('     Iter  Fit')
      end
      format = '   %3.0f     %6.2f';
      tab = sprintf(format,[iter Fit]); 
      disp(tab)
    end
    
  end
end

Core = fixcore(X,Core);

function CoreFixed = fixcore(X,Core);

% Fix problems if dimension of X is 1 in some modes (in which case the number 
% of modes is incorrectly reduced in the core, because these modes are singleton modes)
if any(size(X)==1) & (length(size(Core))~=length(size(X)))
  j = find(size(X)==1);
  cosi = size(Core);
  cosi_correct = [cosi(1:j(1)-1) 1 cosi(j(1):length(cosi))];
  Core = reshape(Core,cosi_correct);
  for i=2:length(j);
    cosi = size(Core);
    cosi_correct = [cosi(1:j(i)-1) 1 cosi(j(i):length(cosi))];
    Core = reshape(Core,cosi_correct);
  end
end
CoreFixed = Core;
