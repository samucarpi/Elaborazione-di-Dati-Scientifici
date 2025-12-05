function [Consistency,G,Extra] = corcondia(X,loads,Weights,plots);
%CORCONDIA Evaluates consistency of PARAFAC model.
%  The core consistency is given as the percentage of variation in a Tucker3 core
%  array consistent with the theoretical superidentity array. Max value is 100%.
%  Consistencies well below 70-90% indicates that either too many components
%  are used or the model is otherwise mis-specified.
%  Note that core consistency is an ad hoc method. It often works
%  well on real data (though less well on simulated) but it does not give
%  any proof of dimensionality; just a good indication.
%
%  INPUTS:
%        X = multi-way data array, and
%    loads = a) cell array of loads (i'th element holds the loading 
%                matrix of the i'th mode, or
%            b) a PARAFAC model structure.
% 
%  OPTIONAL INPUTS:
%  Weights = optional weights for updating the core in a weighted 
%            least squares sense, and
%    plots = if plots is not zero, a plot will be given showing
%            the individual estimated core elements.
% 
%I/O: CoreConsist = corcondia(X,loads,Weights,plots);
%I/O: corcondia demo
%
%See also: CORECALC, PARAFAC, TUCKER

%Copyright Eigenvector Research, Inc. 1999
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rb 12/99
%rb 10/01 added nargin=0 help
%rb 11/01 changed I/O and added optional model input rather than just loads
%rb, Dec, 2001, DSO-enabled
%rb, mar, 2002, fixed plots
%rb, jun, 2002, fixed one-comp solution output

varargout = [];
if nargin == 0; X = 'io'; end
varargin{1} = X;
if ischar(varargin{1});
  options = [];
  if nargout==0; 
    clear varargout; 
    evriio(mfilename,X,options); 
  else; 
    Consistency = evriio(mfilename,X,options); 
  end
  return; 
end


if nargin==0
  disp(' CORCONDIA for evaluating consistency of PARAFAC model')
  disp(' ')
  disp(' I/O: CoreConsist = corcondia(X,loads,Weights,plots);')
  disp(' ')
  disp(' Type <<help corcondia>> for extended help')
  disp(' ')
  return
end


if isa(X,'dataset')% Then it's a SDO
  Xsdo = X;
  inc=X.includ;            
  X = X.data(inc{:});
end

if nargin<3
  Weights = [];
end
if nargin<4
  plots = 1;
end
if isstruct(loads)
  if strcmp(lower(loads.modeltype),'parafac')
    loads = loads.loads;
  else
    error(' Second input to corcondia.m must be either the loadings or the model structure from PARAFAC')
  end
end

Ord = length(loads);
Fac = size(loads{1},2);


% Check if # components = 1. Then corcondia = 100% per definition
MaxNumb=0;
for i=1:Ord
  MaxNumb = max(MaxNumb,size(loads{i},2));
end
if MaxNumb == 1
  Consistency = 100;
  if nargout > 1
    G = 1;
    Extra.I        = 1;
    Extra.GG       = 1;
    Extra.bNonZero = 1;
    Extra.bZero    = [];
  end
  return
end

% Rescale loadings so variance is equally distributed in each mode
Norm = ones(1,Fac);
for i = 1:Ord
  for f = 1:Fac
    n=norm(loads{i}(:,f));
    if n==0
        n=1;
    end
    Norm(f) = Norm(f)*n;
    loads{i}(:,f) = loads{i}(:,f)/n;
  end
end
Norm = Norm.^(1/Ord);
for i = 1:Ord
  for f = 1:Fac
    loads{i}(:,f) = loads{i}(:,f)*Norm(f);
  end
end
% Ideal superdiagonal array of ones
I = zeros(Fac*ones(1,Ord));
j=length(I(:));
I(linspace(1,j,Fac))=1;

% Check if rankdeficiencies and restate problem if so
loadsreduced=[];
for i = 1:Ord
  rankZ=rank(loads{i});
  if rankZ<Fac
    [u,s,v]=svd(loads{i},0);
    q = u(:,1:rankZ)*s(1:rankZ,1:rankZ);
    r = v(:,1:rankZ)';
    I = permute(I,[i [1:i-1 i+1:Ord]]);
    DimI = size(I);
    I = r*reshape(I,DimI(1),prod(DimI(2:end)));
    DimI(1) = size(I,1);
    I = reshape(I,DimI);
    I = ipermute(I,[i [1:i-1 i+1:Ord]]);
    loadsreduced{i} = q;
  else
    loadsreduced{i} = loads{i};
  end
end   


% Calculate core
G = corecalc(X,loadsreduced,0,Weights);

% Calculate consistency
Consistency = 100*(1-sum((I(:)-G(:)).^2)/sum(I(:).^2));

% Plot results
Target=I(:);
[a,b]=sort(abs(I(:)));
b=flipud(b);
I=I(b);
GG=G(b);
bNonZero=find(I);
bZero=find(~I);

if plots
  plot([I(bNonZero);I(bZero)],'b--','LineWidth',1)
  hold on
  plot(GG(bNonZero),'ro','LineWidth',3)
  plot(length(bNonZero)+1:length(GG),GG(bZero),'gx','LineWidth',4)
  hold off
  set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
  axis tight,drawnow;grid off
  info = 'The core consistency plot shows the actual core elements (red & green) calculated from the PARAFAC loadings. Ideally, these should follow the blue line which is simply a superdiagonal core with ones on the diagonal (might change if one dimension < number of factors). The red elements are those that should ideally be non-zero and the green one those that should be zero. The core consistency is measuring the deviation from the blue target. The core consistency should not be used alone for assessing the number of components. It merely provides an indication. Especially, for simulated data (that follow the model perfectly with random iid noise) the core consistency is known to be less reliable than for real data.';
  t=title('Core Consistency','fontweight','bold');
  set(t,'ButtonDownFcn',['evrimsgbox(''',info,''',''replace'');'])
  xlabel('Core element')
  ylabel('Core value/expectation')
end

% Used for plotting
Extra.I        = I;
Extra.GG       = GG;
Extra.bNonZero = bNonZero;
Extra.bZero    = bZero;
