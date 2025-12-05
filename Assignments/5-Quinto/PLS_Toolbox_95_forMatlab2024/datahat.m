function varargout = datahat(varargin)
%DATAHAT Calculates the model estimate and residuals of the data.
%  Input (model) is a standard model structure and the
%  output (xhat) is a model estimate of the data.
%  For example, if the model is from PCA such that
%    Xcal = TP'+E  then  xhat = TP'.
%
%  The input is (model) a standard model structure.
%  Optional input (data) (class "double" or "dataset") is data
%  with size compatible with (model). If (data) is not input
%  then (model) can be a cell array of loadings (from model.loads).
%
%  When just (model) is input, the output (xhat) is an estimate of
%  the calibration data (e.g. xhat = TP').
%  When (model) and (data) are input, the output (xhat) is a
%  model estimate of the new data (e.g. xhat = XnewPP') and the
%  corresponding residuals (resids) [e.g. resids = Xnew(I-PP')].
%  Note that Xnew must have size(Xnew,2)==size(P,2).
%  With two inputs, (model) can also be a set of ortho-normal loadings such
%  as output by pcaengine. In this case, (data) is projected onto the
%  loadings to get (xhat) and (resids).
%
%  Note that preprocessing of (data) is performed by DATAHAT
%  using preprocessing in (model).
%
%  Modeltypes supported are 'PCA', 'PCR', 'PLS', 'PAR'.
%
%I/O: xhat = datahat(model);                %estimates model fit of data
%I/O: [xhat,resids] = datahat(model,data);  %estimates model fit of new data
%I/O: [xhat,resids] = datahat(loadings,data); %estimate loadings fit of new data
%I/O: datahat demo
%
%See also: ANALYSIS, NPLS, PARAFAC, PARAFAC2, QCONCALC, RESIDUALLIMIT, TCONCALC, TSQMTX, TSQQMTX, TUCKER, VARCAP, VARCAPY

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%03/18/02 nbg
%03/20/02 jms revised for 'PLS' instead of 'nip' or 'sim'
%03/22/02 jms fixed calls to pls, pcr, and pca
%08/19/02 rb addded tucker and npls and changed case 2 to use case 1
%instead of individual algorithms in case of cell input
%05/21/03 jms corrected updatemod3 reference 
%04/03 jms -added generic apply model call for unrecognized model types
%12/04 jms -added support for loadings-only input without model structure
%7/05 rb -fixed error for several single-component dimensions in Tucker/npls

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

% Check if model is given as cell array of loads only
if nargin==0
  error('DATAHAT expects 1 or 2 inputs.')
else
  if iscell(varargin{1})
    if min(size(varargin{1}))>1  % Two blocks of data, pick the first set corresponding to X
      temp = varargin{1}(:,1);
    else
      temp = varargin{1};
    end
    cellinput=1;

    % Determine modeltype
    if iscell(temp) & isstruct(temp{1})
      varargin{1} = modelstruct('parafac2');
      varargin{1}.loads = temp;
    else
      if length(size(temp{end}))>2
        varargin{1} = modelstruct('tucker');
        varargin{1}.loads = temp;
      else
        f = size(temp{1},2);
        pfok = 1;
        for i=2:length(temp)
          if size(temp{i},2)~=f
            pfok = 0; % Likely tucker instead but where the last mode (core) is e.g. two-way 
          end
        end
        if pfok
          varargin{1} = modelstruct('parafac');
          varargin{1}.loads = temp;
        else
          varargin{1} = modelstruct('tucker');
          varargin{1}.loads = temp;
        end
      end
    end
  else
    cellinput=0;
    
    %check for input of just loadings - make it be an "unknown" model
    %I/O: [xhat,res] = datahat(loadings,data);
    if isnumeric(varargin{1})
      loads = varargin{1};
      varargin{1} = modelstruct('pca');
      varargin{1}.loads{2} = loads;
    end
  end
end


switch nargin
  
  case 1 %assumes I/O: xhat = datahat(model);
    
    if ~ismodel(varargin{1}) & ~cellinput
      error('Input to DATAHAT is not a standard model structure.')
    end
    
    switch lower(varargin{1}.modeltype)
      case {'pca','pcr','pls','frpcr','mcr','lwr','plsda'}
        varargout{1} = varargin{1}.loads{1,1}*varargin{1}.loads{2,1}';
      
      case {'par', 'parafac'}
        varargout{1} = nmodel(varargin{1}.loads);
      
      case {'tuc','tucker','npls','tucker - rotated'}
        if strcmpi(varargin{1}.modeltype,'npls')
          % Move last core to loads and remove y loads
          varargin{1}.loads = varargin{1}.loads(:,1);
          varargin{1}.loads{end+1,1} = varargin{1}.core{end};
        end
        varargout{1} = varargin{1}.loads{end};
        order = length(varargin{1}.loads)-1;
        for i=1:order 
          coresize = size(varargout{1});
          if length(coresize)<order
            coresize = [coresize ones(1,order-length(coresize))];
          end
          varargout{1} = varargin{1}.loads{i}*reshape(permute(varargout{1},[i 1:i-1 i+1:order]),coresize(i),prod(coresize([1:i-1 i+1:order])));
          varargout{1} = reshape(varargout{1},[size(varargin{1}.loads{i},1) coresize([1:i-1 i+1:order])]);
          varargout{1} = ipermute(varargout{1},[i 1:i-1 i+1:order]);
        end
        
      case {'pa2', 'parafac2'}
        loads = varargin{1}.loads;
        P = loads{1}.P;
        H = loads{1}.H;
        m = outerm(loads(1:end-1),1,1);
        xsize(1) = size(P{1},1);
        for k=2:length(loads)
          xsize(k) = size(loads{k},1);
        end
        for k = 1:xsize(k);
          mm(k,:,:) = (P{k}*H)*diag(loads{end}(k,:))*m';
        end
        mm = permute(mm,[2:length(loads) 1]);
        varargout{1} = reshape(mm,xsize);
        
      case 'loads_only'
        error('Data must be supplied when loadings are input as model.');
        
      otherwise
        error('Data estimate cannot be calculated for this modeltype without original X data.')
        
    end

  case 2 %assumes I/O: [xhat,resids] = datahat(model,data);
    if ~ismodel(varargin{1}) & ~cellinput
      error('First input to DATAHAT must be a standard model structure.')
    end
    
    if isa(varargin{2},'double')
      varargin{2} = dataset(varargin{2});
    elseif ~isa(varargin{2},'dataset')
      error('Input DATA must be class "double" or "dataset".')
    end
    
    if cellinput
      varargout{1} = datahat(varargin{1});
      inc = varargin{2}.includ;
      temp = varargin{2}.data(inc{:});  
      try
        if ndims(temp)==ndims(varargout{1}) & all(size(temp)==size(varargout{1}))
          varargout{2} = temp-varargout{1};
        else
          inc = varargin{2}.includ;
          inc{1}=[1:size(varargin{2}.data,1)]';
          varargout{2} = varargin{2}.data(inc{:})-varargout{1};
        end
      catch
        error(' When only a cell of loadings are input, the size of the data should correspond to the size of the model represented by the loadings')
      end
    else
      switch lower(varargin{1}.modeltype)    %project data onto model
        case 'pca'
          if isempty(varargin{1}.loads{1})
            %loads only mode!!
            inc = varargin{2}.includ;
            inc{1}=[1:size(varargin{2}.data,1)]';
            varargin{2} = varargin{2}.data(inc{:});
            
            [mx,nx]  = size(varargin{2});
            [mp,np]  = size(varargin{1}.loads{2});
            if mp ~= nx
              error('Size of data and loadings not compatible')
            end
            scores              = varargin{2}*varargin{1}.loads{2};
            model.pred{1}       = scores*varargin{1}.loads{2}';
            model.detail.res{1} = varargin{2} - model.pred{1};
            
          else
            %normal PCA model
            opts  = pca('options');
            opts.plots   = 'none';
            opts.display = 'off';
            opts.blockdetails = 'all';
            model = pca(varargin{2},varargin{1},opts);
          end
        
        case 'pcr'
          opts  = pcr('options');
          opts.plots   = 'none';
          opts.display = 'off';
          opts.blockdetails = 'all';
          model = pcr(varargin{2},varargin{1},opts);
        
        case 'pls'
          opts  = pls('options');
          opts.plots   = 'none';
          opts.display = 'off';
          opts.blockdetails = 'all';
          model = pls(varargin{2},varargin{1},opts);
        
        case 'cls'
          opts  = cls('options');
          opts.plots   = 'none';
          opts.display = 'off';
          opts.blockdetails = 'all';
          opts.algorithm = varargin{1}.detail.options.algorithm;
          model = cls(varargin{2},varargin{1},opts);
          
        case {'par','parafac'}
          opts  = parafac('options');
          opts.plots   = 'none';
          opts.display = 'off';
          opts.blockdetails = 'all';
          sampmode = varargin{1}.detail.options.samplemode;
          varargin{2}.includ{sampmode} = 1:size(varargin{2}.data,sampmode);
          model = parafac(varargin{2},[],varargin{1},opts);
        
        case {'tuc','tucker','tucker - rotated'}
          opts  = tucker('options');
          opts.plots   = 'none';
          opts.display = 'off';
          opts.blockdetails = 'all';
          sampmode = varargin{1}.detail.options.samplemode;
          varargin{2}.includ{sampmode} = 1:size(varargin{2}.data,sampmode);
          model = tucker(varargin{2},[],varargin{1},opts);
        
        case {'pf2','parafac2'}
          opts  = parafac2('options');
          opts.plots   = 'none';
          opts.display = 'off';
          opts.blockdetails = 'all';
          model = parafac2(varargin{2},[],varargin{1},opts);      
        
        otherwise
          
          %is regmode a valid m-file?
          if ~exist(lower(varargin{1}.modeltype),'file');
            error('Modeltype not supported by DATAHAT.')
          end
          
          opts               = feval(lower(varargin{1}.modeltype),'options');
          opts.display       = 'off';
          opts.plots         = 'none';
          opts.blockdetails  = 'all';
          model = feval(lower(varargin{1}.modeltype),varargin{2},varargin{1},opts);
          
      end
      varargout{1} = model.pred{1};
      varargout{2} = model.detail.res{1};
    end
  otherwise
    error('DATAHAT expects 1 or 2 inputs.')
end


function [Xm]=nmodel(Factors,G,Om);

%NMODEL make model of data from loadings
%
% function [Xm]=nmodel(Factors,G,Om);
%
% This algorithm requires access to:
% 'neye.m'
%
%
% [Xm]=nmodel(Factors,G,Om);
%
% Factors  : The factors in a cell array. Use any factors from 
%            any model. 
% G        : The core array. If 'G' is not defined it is assumed
%            that a PARAFAC model is being established.
%            Use G = [] in the PARAFAC case.
% Om       : Oblique mode.
%            'Om'=[] or 'Om'=0, means that orthogonal
%                   projections are requsted. (default)
%            'Om'=1 means that the factors are oblique.  
%            'Om'=2 means that the ortho/oblique is solved automatically.  
%                   This takes a little additional time.
% Xm       : The model of X.
%
% Using the factors as they are (and the core, if defined) the general N-way model
% is calculated. 


for i = 1:length(Factors);
   DimX(i)=size(Factors{i},1);
end
i = find(DimX==0);
for j = 1:length(i)
   DimX(i(j)) = size(G,i(j));
end



if nargin<2, %Must be PARAFAC
   Fac=size(Factors{1},2);
   G=[];
else
   for f = 1:length(Factors)
      if isempty(Factors{f})
         Fac(f) = -1;
      else
         Fac(f) = size(Factors{f},2);
      end;
   end
end

if ~exist('Om')
    Om=[];
end;

if isempty(Om)
    Om=0;
end;

if size(Fac,2)==1,
    Fac=Fac(1)*ones(1,size(DimX,2));
end;
N=size(Fac,2);

if size(DimX,2)>size(Fac,2),
    Fac=Fac*ones(1,size(DimX,2));
end;  
N=size(Fac,2);

Fac_orig=Fac;
i=find(Fac==-1);
if ~isempty(i)
    Fac(i)=zeros(1,length(i));
    Fac_ones(i)=ones(1,length(i));
end;
DimG=Fac;
i=find(DimG==0);
DimG(i)=DimX(i);

if isempty(G),
   G=neye(DimG);
end;   
G = reshape(G,size(G,1),prod(size(G))/size(G,1));

% reshape factors to old format
ff = [];
for f=1:length(Factors)
 ff=[ff;Factors{f}(:)];
end
Factors = ff;


if DimG(1)~=size(G,1) | prod(DimG(2:N))~=size(G,2),

    help nmodel

    fprintf('nmodel.m   : ERROR IN INPUT ARGUMENTS.\n');
    fprintf('             Dimension mismatch between ''Fac'' and ''G''.\n\n');
    fprintf('Check this : The dimensions of ''G'' must correspond to the dimensions of ''Fac''.\n');
    fprintf('             If a PARAFAC model is established, use ''[]'' for G.\n\n');
    fprintf('             Try to reproduce the error and request help at rb@kvl.dk\n');
    return;
end;

if sum(DimX.*Fac) ~= length(Factors),
    help nmodel
    fprintf('nmodel.m   : ERROR IN INPUT ARGUMENTS.\n');
    fprintf('             Dimension mismatch between the number of elements in ''Factors'' and ''DimX'' and ''Fac''.\n\n');
    fprintf('Check this : The dimensions of ''Factors'' must correspond to the dimensions of ''DimX'' and ''Fac''.\n');
    fprintf('             You may be using results from different models, or\n');
    fprintf('             You may have changed one or more elements in ''Fac'' or ''DimX'' after ''Factors'' have been calculated.\n\n');
    fprintf('             Read the information above for information on arguments.\n');
    return;
end;

FIdx0=cumsum([1 DimX(1:N-1).*Fac(1:N-1)]);
FIdx1=cumsum([DimX.*Fac]);

if Om==0,
    Orthomode=1;
end;

if Om==1,
    Orthomode=0;
end;

if Om==2,
    Orthomode=1;
    for c=1:N,
        if Fac_orig(c)~=-1,
            A=reshape(Factors(FIdx0(c):FIdx1(c)),DimX(c),Fac(c));
            AA=A'*A;
            ssAA=sum(sum(AA.^2));
            ssdiagAA=sum(sum(diag(AA).^2));
            if abs(ssAA-ssdiagAA) > 100*eps;
                Orthomode=0;
            end;
        end;
    end;
end;

if Orthomode==0,
    Zmi=prod(abs(Fac_orig(2:N)));
    Zmj=prod(DimX(2:N));
    Zm=zeros(Zmi,Zmj);
    DimXprodc0 = 1;
    Facprodc0 = 1;
    Zm(1:Facprodc0,1:DimXprodc0)=ones(Facprodc0,DimXprodc0);
    for c=2:N,
        if Fac_orig(c)~=-1,
            A=reshape(Factors(FIdx0(c):FIdx1(c)),DimX(c),Fac(c));
            DimXprodc1 = DimXprodc0*DimX(c);
            Facprodc1 = Facprodc0*Fac(c);
            Zm(1:Facprodc1,1:DimXprodc1)=ckron(A',Zm(1:Facprodc0,1:DimXprodc0));
            DimXprodc0 = DimXprodc1;
            Facprodc0 = Facprodc1;
        end;
    end;
    if Fac_orig(1)~=-1,
        A=reshape(Factors(FIdx0(1):FIdx1(1)),DimX(1),Fac(1));
        Xm=A*G*Zm;
    else 
        Xm=G*Zm;
    end;
elseif Orthomode==1,
    CurDimX=DimG;
    Xm=G;
    newi=CurDimX(2);
    newj=prod(CurDimX)/CurDimX(2);
    Xm=reshape(Xm',newi,newj);
    for c=2:N,
        if Fac_orig(c)~=-1,
            A=reshape(Factors(FIdx0(c):FIdx1(c)),DimX(c),Fac(c));
            Xm=A*Xm;
            CurDimX(c)=DimX(c);
        else
            CurDimX(c)=DimX(c);
        end;
        if c~=N,
            newi=CurDimX(c+1);
            newj=prod(CurDimX)/CurDimX(c+1);
        else
				newi=CurDimX(1);
            newj=prod(CurDimX)/CurDimX(1);
        end;
        Xm=reshape(Xm',newi,newj);
    end;
    if Fac_orig(1)~=-1,
        A=reshape(Factors(FIdx0(1):FIdx1(1)),DimX(1),Fac(1));
        Xm=A*Xm;
    end;
end;    

Xm = reshape(Xm,DimX);

function G=neye(Fac)
% NEYE  Produces a super-diagonal array
%
%function G=neye(Fac);
%
% This algorithm requires access to:
% 'getindxn'
%             Produces a super-diagonal array
% G=neye(Fac);
% Fac      : A row-vector describing the number of factors
%            in each of the N modes. Fac must be a 1-by-N vector. 
%            Ex. [3 3 3] or [2 2 2 2]

N=size(Fac,2);
if N==1,
   fprintf('Specify ''Fac'' as e vector to define the order of the core, e.g.,.\n')
   fprintf('G=eyecore([2 2 2 2])\n')
end;

G=zeros(Fac(1),prod(Fac(2:N)));

for i=1:Fac(1),
   [gi,gj]=getindxn(Fac,ones(1,N)*i);
   G(gi,gj)=1;
end;

G = reshape(G,Fac);

function [i,j]=getindxn(R,Idx)
%GETINDXN
%
%[i,j]=GetIndxn(R,Idx)

l=size(Idx,2);

i=Idx(1);
j=Idx(2);

if l==3,
  j = j + R(2)*(Idx(3)-1);
 else
  for q = 3:l,
    j = j + prod(R(2:(q-1)))*(Idx(q)-1);
  end;
end;

function C=ckron(A,B)
%CKRON
% C=ckron(A,B)
%

[mA,nA] = size(A);
[mB,nB] = size(B);

C = zeros(mA*mB,nA*nB);
if mA*nA <= mB*nB
  for i = 1:mA
  iC = 1+(i-1)*mB:i*mB;
    for j = 1:nA
      jC = 1+(j-1)*nB:j*nB;
      C(iC,jC) = A(i,j)*B;
    end
  end
else
  for i = 1:mB
    iC = i:mB:(mA-1)*mB+i;
    for j = 1:nB
      jC = j:nB:(nA-1)*nB+j;
      C(iC,jC) = B(i,j)*A;
    end
  end
end
