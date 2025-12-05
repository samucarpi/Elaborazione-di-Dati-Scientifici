function pp = autochromprob(X,model,modelF_1)
% The algorithm determines the propability of a PARAFAC2 
% model being overfitted
%
% X       : Data in format RetTime x Spectra x Samples
% model   : PARAFAC2 model on X
% modelF_1: PARAFAC2 model with one component less than current (the above)

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

x = permute(X,[2 1 3]); % old format from article
x = x.data;
% X     : Data in format spectra x rt x samples
A = model.loads{2};
C = model.loads{3};
P = model.loads{1}.P;
H = model.loads{1}.H;
F = size(A,2);

AF = modelF_1.loads{2};
CF = modelF_1.loads{3};
PF = modelF_1.loads{1}.P;
HF = modelF_1.loads{1}.H;


% core consistency
cc = coreC(x,A,H,C,P,F);
 
%signflip
[A C H P] = sf(x,A,C,H,P,F);
 
predprob   = 0;
     
% Correlation between data and model, durbin
% watson, and fit
[TicCorr, DW, fit] = residuals(x,A,C,H,P);

% Negative area in elution profile
negArea = NegativeArea(C,H,P);

% Correlation between spectra
[posCorr,negCorr] = corrSpectra(A,F);

iterations = model.detail.critfinal(3);
logIt = log(iterations);
        
[TicCorrF_1, DWF_1, fitF_1] = residuals(x,AF,CF,HF,PF);
diffRC  = (TicCorr-TicCorrF_1)/TicCorr;
diffRDW = (DW-DWF_1)/DW;
        
        
% Diff negative area in elution profile
negAreaF_1 = NegativeArea(CF,HF,PF);
diffNegArea = negArea-negAreaF_1;
        
% Correlation between spectra + Diff Negative correlation
[posCorrF_1, negCorrF_1]  = corrSpectra(AF, F-1);
diffNegCorr = negCorr-negCorrF_1;
        
% dataset for prediction of probability of 
% the model being overfitted
parameters = [logIt posCorr cc diffNegArea ...
diffNegCorr, diffRC, diffRDW];
            
% PLSDA:
op         = plsda('options');
op.plots   = 'none';
op.display = 'off';
load PLSDA_final
model      = plsda(parameters, plsdamodel, op);
pp         = model.detail.predprobability(2);
        

%% Signflip
function [A, C, H, P] = sf(x, A, C, H, P, F, i)
model.loads{2}   = A;
model.loads{3}   = C;
model.loads{1}.H = H;
model.loads{1}.P = P;
model.modeltype  = 'parafac2';

x = permute(x, [2 1 3]);
% signflip
[sgns,Fmodel] = sign_flip(model,x);

A = Fmodel.loads{2};
C = Fmodel.loads{3};
H = Fmodel.loads{1}.H;
P = Fmodel.loads{1}.P;

%% Core consistency
function cc = coreC(x, a, h, c, p, F)
Y = zeros(size(x,1), F, size(p,2));
for i2 = 1:size(x,3)
    Y(:,:,i2) = x(:,:,i2)*p{i2};
end
cc = corcondia(Y,{a,h,c},[],0);

%% Residuals and correlation betwwen model and raw data and durbin watson
function [TicCorr, DW, fit] = residuals(x, a, c, h, p)
e  = zeros(size(a,1), size(p{1,1},1), size(c,1));
Xmodel = e;
for i3 = 1:size(p,2)
    % Dk is a diagonal matrix that holds the k'th row of C in its
    % diagonal
    d = zeros(size(c,2));
    for i = 1:size(c,2)
        d(i,i) = c(i3,i);
    end
    Xmodel(:,:,i3) = (a*d*(p{1,i3}*h)');
    e(:,:,i3)      = x(:,:,i3) - Xmodel(:,:,i3);
end
tic   = squeeze(sum(x));
m_tic = squeeze(sum(Xmodel));
corr  = zeros(size(p,1),1);
for i1 = 1:size(p,2)
    cor = corrcoef(tic(:,i1),m_tic(:,i1));
    corr(i1) = cor(2);
end
%correlation between raw data and model
TicCorr      = mean(corr);

%durbin watson:
E_tic        = squeeze(sum(e,1));
DW           = max(durbin_watson(E_tic));
%fit
sse          = sum(sum(sum(e.^2)));
ssx          = sum(sum(sum(x.^2)));
fit          = 100*(1-(sse/ssx));

%% Negative area in elution time profile
function negArea = NegativeArea(c, h, p)
M = zeros(length(p),length(p{1}), length(h));
for i =1:length(p)
    M(i,:,:) = p{i}*h*c(i);
end
Neg = find(M<0);
SumNeg = sum(M(Neg));
Pos = 1:length(p)*length(p{1})*length(h);
Pos(Neg) = [];
SumPos = sum(M(Pos));
if SumNeg == 0
    negArea = 0;
else
    negArea = abs(SumNeg/SumPos);
end
%% correlation between spectra
function [posCorr, negCorr] = corrSpectra(a, F)
corr    = corrcoef(a);
I       = 1:F+1:(F*F);
corr(I) = NaN;
I       = find(corr<0);
if isempty(I) == 0
    negCorr = abs(min(corr(I)));
else
    negCorr = 0;
end
I = find(corr>0);
if isempty(I) == 0
    posCorr = max(corr(I));
else
    posCorr = 0;
end

function [sgns,loads,S] = sign_flip(loads,X,pfstuff)

% [sgns,newmodel] = sign_flip(model,X)
% INPUT
% model is a model structure (or cell of loadings if PCA or PARAFAC)
% X     is the data array
% 
% OUTPUT
% sgns  is a MxF matrix where sgns(m,f) is the sign of loading f in mode m
% model is a cell containing the corrected model (or cell of loadings)
%
% If using svd ([u,s,v]=svd(X)) then set 
% loads{1}=u*s; 
% and loads{2}=v;
% 
% If using an F-component PCA model ([t,p]=pca(X,F), then loads{1}=t; and
% loads{2}=p;
%
% Copyright 2007 R. Bro, E. Acar, T. Kolda - www.models.life.ku.dk

% for Tucker, PARAFAC and PCA

if isa(X,'dataset')
    inc = X.includ;
    X = X.data(inc{:});
end

if any(isnan(X(:))) % Simply replace data with model of data. That should work
    X = datahat(loads);
end

model = 'pca';
recallmodel = 0;
if isstruct(loads); % A PLS_model structure assumed
    recallmodel = 1;
    oldmodel = loads;
    if isfield(loads,'modeltype')
        if strcmpi(loads.modeltype,'pca')
            model = 'pca';
        elseif strcmpi(loads.modeltype,'parafac')
            model = 'parafac';
        elseif strcmpi(loads.modeltype,'tucker')
            model = 'tucker';
        elseif strcmpi(loads.modeltype,'parafac2')
            model = 'parafac2';
        else
            error(' Modeltype not supported')
        end
        loads = loads.loads;
    else
        error(' Only a cell of loadings or a recognized PLS_Toolbox model structure is valid as first input')
    end
end

order = length(size(X));
for i=1:order
    F(i) = size(loads{i},2);
end

if strcmpi(model,'parafac2')
  
    loads = sgnswitch_pf2(loads,X);
    sgns=0;
%     % OLD APPROACH - INCORRECT
%     % First fix the extra indeterminacy within the shift within and across mode 
%     sx = size(X);
%     x = permute(X,[order 1:order-1]);
%     K = sx(end);
%     sx = size(x);
%     
%     for k=1:K;
%         xk = reshape(x(k,:),sx(2:end)); % Extract data from sample k
%         for f=1:F(2)
%             % Find the specific loadings for this sample
%             L = loads;
%             L{1}=loads{1}.P{k}*loads{1}.H;
%             L{end}=L{end}(k,:);
%             for m=1:order,
%                 Lf{m}=L{m}(:,[1:f-1 f+1:end]);
%             end
%             %Lf{order}=abs(Lf{order});
%             Z = outerm(Lf);
%             % subtract contribution from other components
%             xkres = xk-Z;
%             a = L{1}(:,f);
%             a = a /(a'*a);
%             clear s
%             for i=1:size(xkres(:,:),2) % for each column
%                 s(i)=(a'*xkres(:,i));
%                 s(i)=sign(s(i))*power(s(i),2);
%             end
%             sgn = sign(sum(s));
%             if sgn<0
%                 loads{1}.P{k}(:,f)=-loads{1}.P{k}(:,f);
%                 loads{end}(k,f)=-loads{end}(k,f);
%             end
%         end
%     end
%     sgns = 0;

elseif strcmp(model,'tucker')
    newloads=loads;
    for m = 1:order % for each mode
        for f=1:F(m) % for each component
            s=[];
            a = loads{m}(:,f);
            a = a /(a'*a);
            x = subtract_otherfactors_tucker(X, loads, m, f);
            for i=1:size(x(:,:),2) % for each column
                s(i)=(a'*x(:,i));
                s(i)=sign(s(i))*power(s(i),2);
            end
            S(m,f) =sum(s);
        end
    end
    sgns = sign(S);
    
    core = loads{end};
    for m=1:order %each mode
        core = permute(core,[m 1:m-1 m+1:order]);
        for f=1:F(m) %each component
            newloads{m}(:,f)=sgns(m,f)*loads{m}(:,f);
            core(f,:) = sgns(m,f)*core(f,:);
        end %each component
        core = ipermute(core,[m 1:m-1 m+1:order]);
    end  %each mode
    newloads{end}=core;
    loads = newloads;
    
else % PARAFAC and PCA
    for m = 1:order % for each mode
        for f=1:F(m) % for each component
            s=[];
            a = loads{m}(:,f);
            a = a /(a'*a);
            x = subtract_otherfactors(X, loads, m, f);
            for i=1:size(x(:,:),2) % for each column
                s(i)=(a'*x(:,i));
                s(i)=sign(s(i))*power(s(i),2);
            end
            S(m,f) =sum(s);
        end
    end
    sgns = sign(S);
    
    for f=1:F(1) %each component
        for i=1:size(sgns,1) %each mode
            se = length(find(sgns(:,f)==-1));
            if (rem(se,2)==0 )
                loads{i}(:,f)=sgns(i,f)*loads{i}(:,f);
            else
                % disp('Odd number of negatives!')
                sgns(:,f) = handle_oddnumbers(S(:,f));
                se = length(find(sgns(:,f)==-1));
                if (rem(se,2)==0)
                    loads{i}(:,f)=sgns(i,f)*loads{i}(:,f);
                else
                    disp('Something Wrong!!!')
                end
            end
        end  %each mode
    end %each component
    
end

if recallmodel
    oldmodel.loads=loads;
    loads=oldmodel;
end

if any(isnan(sgns(:)))
    sgns(isnan(sgns))=1;
    j=find(prod(sgns)<0);
    for k=1:length(j)
        sgns(j(k),1)=(-1)*sgns(j(k),1);
    end
end
%----------------------------------------------------------------------
function sgns=handle_oddnumbers(Bcon)

sgns=sign(Bcon);
nb_neg=find(Bcon<0);
[min_val, index]=min(abs(Bcon));
if (Bcon(index)<0)
    sgns(index)=-sgns(index);
    % since this function is called nb_neg should be greater than 0, anyway
elseif ((Bcon(index)>0) && (nb_neg>0))
    sgns(index)=-sgns(index);
end


%------------------------------------------------------------------------
function x = subtract_otherfactors(X, loads, mode, factor)

order=length(size(X));
x = permute(X,[mode 1:mode-1 mode+1:order]);
loads = loads([mode 1:mode-1 mode+1:order]);

for m = 1: order
    loads{m}=loads{m}(:, [factor 1:factor-1 factor+1:size(loads{m},2)]);
    L{m} = loads{m}(:,2:end);
end
M = outerm(L);
x=x-M;

function x = subtract_otherfactors_tucker(X, loads, mode, factor)

order=length(size(X));
% Remove column from mode
loads{mode}=loads{mode}(:,[1:factor-1 factor+1:size(loads{mode},2)]);
% Remove correspond slab in core
core = loads{end};
core = permute(core,[mode 1:mode-1 mode+1:order]);
sc = size(core);
sc(1) = sc(1)-1;
core = core([1:factor-1 factor+1:end],:);
core = reshape(core,sc);
core = ipermute(core,[mode 1:mode-1 mode+1:order]);
loads{end}=core;
M = datahat(loads); 
X=X-M;
x = permute(X,[mode 1:mode-1 mode+1:order]);



function mwa = outerm(facts,lo,vect)

if nargin < 2
    lo = 0;
end
if nargin < 3
    vect = 0;
end
order = length(facts);
if lo == 0
    mwasize = zeros(1,order);
else
    mwasize = zeros(1,order-1);
end
k = 0;
for i = 1:order
    if i ~= lo
        [m,n] = size(facts{i});
        k = k + 1;
        mwasize(k) = m;
        if k > 1
        else
            nofac = n;
        end
    end
end
mwa = zeros(prod(mwasize),nofac);

for j = 1:nofac
    if lo ~= 1
        mwvect = facts{1}(:,j);
        for i = 2:order
            if lo ~= i
                mwvect = mwvect*facts{i}(:,j)';
                mwvect = mwvect(:);
            end
        end
    elseif lo == 1
        mwvect = facts{2}(:,j);
        for i = 3:order
            mwvect = mwvect*facts{i}(:,j)';
            mwvect = mwvect(:);
        end
    end
    mwa(:,j) = mwvect;
end
% If vect isn't one, sum up the results of the factors and reshape
if vect ~= 1
    mwa = sum(mwa,2);
    mwa = reshape(mwa,mwasize);
end



function newmod = sgnswitch_pf2(loads,X)
sx = size(X);
K = sx(end);
I = sx(1);
F = size(loads{2},2);
order = length(sx);

% Extract loadings
P=loads{1}.P;
H=loads{1}.H;
if order>3 % put all 'middle' loadings into B
    B = kr(loads{end-2},loads{end-3});
    for o=order-4:-1:2
        B = kr(B,loads{o});
    end
else
    B = loads{2};
end
C = loads{end};

%%%%%%%%% FIX Pk, Dk
% Turn it into a problem with Dk and Pk on one mode and the rest 
% in another
Z = B; % The rest
G=zeros([I*K F]); % Pk*Dk on top of each other
for k=1:K;
    G((k-1)*I+1:I*k,:) = (P{k}*H*diag(C(k,:)));
end

% Adjust X
Xnew = permute(X,[[2:order-1] 1 order]);
Xnew = reshape(Xnew,sx(2:end-1),sx(1)*sx(end));

% Now its bilinear Xnew = Z*G'; so we can fix indeterminacy between these
% two blocks and then fix it for Pk Dk afterwards

[sgns] = sign_flip({Z,G},Xnew);
% Now modify the 'left' and 'right' loadings
% For left, just pick any one of the modes in there (for higher order models,
% there can be many)
B = B*diag(sgns(1,:));
loads{2}=loads{2}*diag(sgns(1,:)); % This is for later in case of higher order data
% For right; update C;
C = C*diag(sgns(2,:));

if any(prod(sgns)<0)
    error('Something wrong here - apologies');
end

% Now we have updated versions of A (P,H), B, C (and possibly others)
% Now fix sign indeterminacy within Pk,Dk by posing the model as Xk =
% (ADk)*H'*Pk'. This model is assessed using the two-way sign fix for each
% slab and the fixed signs are imposed on Dk and Pk

Xnew = permute(X,[order 2:order-1 1]);
for k=1:K
    LeftLoad=B*diag(C(k,:));
    Xk = reshape(Xnew(k,:),[prod(sx(2:end-1)) I]);
    [sgns,LOADS] = sign_flip({LeftLoad,P{k}*H},Xk);
    if any(prod(sgns)<0)
        error('Something wrong here - apologies');
    end
    C(k,:) = C(k,:).*sgns(1,:);
    S = pinv(H')*diag(sgns(2,:))*H';
    P{k}=P{k}*S';
    % plot(Xk'/max(Xk(:)),'color',.6*[1 1 1]),hold on,plot(P{k}),hold off, shg,axis tight,pause
end

dbg=0;
if dbg==1
clf,subplot(2,2,1),plot(B),shg, subplot(2,2,2), plot(C),
subplot(2,1,2), for k=1:10,plot(P{k}*H),hold on,end,55,pause
end


% Now fix indeterminacy within Pk*H
LeftLoad =[];
RightLoad =[];
Xk = [];
S = 0;
for k=1:K % Determine sign in each mode
    L1 = B*diag(C(k,:))*H';
    L2 = P{k};
    Xk = reshape(Xnew(k,:),[prod(sx(2:end-1)) I]);
    [sgns,LOADS,ss] = sign_flip({L1,L2},Xk);
    %S = S+sgns;
    ss(isnan(ss)) = 0; 
    S = S+ss;
    % S holds the magnitude majority sign (maybe not perfect, but it'll
    % work mostly)
end
sgns = sign(S);

if any(prod(sgns)<0) % Adjust misunderstandings so that if signs are swicthed opposite pick the sign that has the highest magnitude as judged from S
    j = find(prod(sgns)<0);
    for j2=1:length(j)
        s=S(:,j(j2));
        [a,b1]=max(abs(s));
        [a,b2]=min(abs(s));
        S(b2,j(j2))=abs(S(b2,j(j2))) * sign(S(b1,j(j2)));
    end
    sgns = sign(S);
end
H = (H'*diag(sgns(1,:)))';
for k=1:K
    P{k} = P{k}*diag(sgns(2,:));
end

if dbg==1
clf,subplot(2,2,1),plot(B),shg, subplot(2,2,2), plot(C),
subplot(2,1,2), for k=1:10,plot(P{k}*H),hold on,end,5566,pause
end

% Now the internal Pk Dk signs are fixed and hence Pk is correct. We then 
% transform the model into a PARAFAC model
Y = zeros([F sx(2:end)]);
Y = permute(Y,[order 1:order-1]);
Xnew = permute(X,[order 1:order-1]);

for k=1:K
    Xk = reshape(Xnew(k,:),[sx(1) prod(sx(2:end-1))]);
    Yk = P{k}'*Xk;
    Y(k,:) = Yk(:)';
end

% Y = ipermute(Y,[order 1:order-1]);
% LOADS = cell(1,order);
% LOADS{1}=H;
% LOADS{end}=C;
% for o=2:order-1
%     LOADS{o}=loads{o};
% end

if dbg==1
clf,subplot(2,2,1),plot(B),shg, subplot(2,2,2), plot(loads{end}),
subplot(2,1,2), for k=1:10,plot(P{k}*H),hold on,end,66,pause
end

%clf,subplot(2,2,1),plot(B),shg, subplot(2,2,2), plot(C),subplot(2,1,2), for k=1:10,plot(P{k}*H),hold on,end,66,pause
%[sgns,LOADS] = sign_flip(LOADS,Y,1);
newmod=loads;
newmod{1}.P = P;
newmod{1}.H = H;
%newmod{1}.H = H*diag(sgns(1,:));
for o=2:order-1
 %newmod{o} = loads{o}*diag(sgns(o,:));
 newmod{o} = loads{o};
end
% newmod{end} = C*diag(sgns(end,:));
newmod{end} = C;

if dbg==1
clf,subplot(2,2,1),plot(newmod{2}),shg, subplot(2,2,2), plot(newmod{3}),
subplot(2,1,2), for k=1:10,plot(newmod{1}.P{k}*newmod{1}.H),hold on,end,77,pause
end

if any(prod(sgns)<0)
    error('Something wrong here - apologies');
end



function AB = kr(A,B);
%KR Khatri-Rao product
%
% The Khatri - Rao product
% For two matrices with similar column dimension the khatri-Rao product
% is kr(A,B) = [kron(A(:,1),B(:,1)) .... kron(A(:,F),B(:,F))]
% 
% I/O AB = kr(A,B);
%
% kr(A,B) equals ppp(B,A) - where ppp is the triple-P product = 
% the parallel proportional profiles product which was originally 
% suggested in Bro, Ph.D. thesis, 1998

disp('KR.M is obsolete and will be removed in future versions. ')
disp('use KRB.M instead.')


[I,F]=size(A);
[J,F1]=size(B);

if F~=F1
   error(' Error in kr.m - The matrices must have the same number of columns')
end

AB=zeros(I*J,F);
for f=1:F
   ab=B(:,f)*A(:,f).';
   AB(:,f)=ab(:);
end

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

%Copyright Eigenvector Research, Inc. 1999-2012
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

function y=durbin_watson(x);
%DURBIN_WATSON Criterion for measure of continuity.
% The durbin watson criteria for the columns of x are calculated as the
% ratio of the sum of the first derivative of a vector to the sum of the
% vector itself. Low values means correlation in variables, high values
% indicates randomness.
% Input (x) is a column vector or array in which each column represents a
% vector of interest. Output (y) is a scalar or vector of Durbin Watson
% measures.
%
%I/O: y = durbin_watson(x);
%
%See also: CODA_DW

% Copyright © Eigenvector Research, Inc. 2004-2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  if nargout==0; evriio(mfilename,x,options); else; y = evriio(mfilename,x,options); end
  return; 
end

d=diff(x);
a=sum(d.*d);
b=sum(x.*x);

%TAKE CARE OF DIVIDING BY 0

array    = (b==0);
b(array) = 1;

y = a./b;

y(array) = inf;

function [A,H,C,P,it,fit,AddiOutput]=parafac2(X,F,Constraints,Options,A,H,C,P);


%
% THE PARAFAC2 MODEL
%
% Algorithm to fit the PARAFAC2 model which is an advanced variant of the
% normal PARAFAC1 model. It handles slab-wise deviations between components
% in one mode as long as the cross-product of the components stays
% reasonably fixed. This can be utilized for modeling chromatographic
% data with retention time shifts, modeling certain batch data of
% varying length etc. See Bro, Kiers & Andersson, Journal of Chemometrics,
% 1999, 13, 295-309 for details on application and Kiers, ten Berge &
% Bro, Journal of Chemometrics, 1999, 13, 275-294, for details on the algorithm
%
%
% The PARAFAC2 model is given
%
% Xk = A*Dk*(Pk*H)' + Ek, k = 1, .., K
%
% Xk is a slab of data (I x J) in which J may actually vary with K. K
% is the number of slabs. A (I x F) are the scores or first-mode loadings. Dk
% is a diagonal matrix that holds the k'th row of C in its diagonal. C
% (K x F) is the third mode loadings, H is an F x F matrix, and Pk is a
% J x F orthogonal matrix (J may actually vary from k to k. The output here
% is given as a cell array of size J x F x K. Thus, to get e.g. the second P
% write P(:,:,2), and to get the estimate of the second mode loadings at this
% second frontal slab (k = 2), write P(:,:,2)*H. The matrix Ek holds the residuals.
%
% INPUT
%
% X
%   Holds the data.
%   If all slabs have similar size, X is an array:
%      X(:,:,1) = X1; X(:,:,2) = X2; etc.
%   If the slabs have different size X is a cell array (type <<help cell>>)
%      X{1} = X1; X{2} = X2; etc.
%   If you have your data in an 'unfolded' two-way array of size
%   I x JK (the three-way array is I x J x K), then simply type
%   X = reshape(X,[I J K]); to convert it to an array.
%
% F
%   The number of components to extract
%
% Constraints
%   Vector of length 2. The first element defines constraints
%   imposed in the first mode, the second defines contraints in
%   third mode (the second mode is not included because constraints
%   are not easily imposed in this mode)
%
%   If Constraints = [a b], the following holds. If
%   a = 0 => no constraints in the first mode
%   a = 1 => nonnegativity in the first mode
%   a = 2 => orthogonality in the first mode
%   a = 3 => unimodality (and nonnegativity) in the first mode
%   a = 4 => Fast ad hoc nonnegativity (set negative paramaters to zero)
%   same holds for b for the third mode
%
% Options
%   An optional vector of length 3
%   Options(1) Convergence criterion
%            1e-7 if not given or given as zero
%   Options(2) Maximal iterations
%            default 2000 if not given or given as zero
%   Options(3) Initialization method
%            A rather slow initialization method is used per default
%            but it pays to investigate in avoiding local minima.
%            Experience may point to faster methods (set Options(3)
%            to 1 or 2). You can also change the number of refits etc.
%            in the beginning of the m-file
%            0 => best of 10 runs of maximally 80 iterations (default)
%            1 => based on SVD
%            2 => random numbers
%   Options(4) Cross-validation
%            0 => no cross-validation
%            1 => cross-validation splitting in 7 segments
%            If cross-validation is chosen, the result is given
%            the first output (A). No more outputs are given
%   Options(5) show output
%            0 => show standard output on screen
%            1 => hide all output to screen
%
% AUXILIARY
% - Missing elements: Use NaN for missing elements
% - You can input initial values by using the input argument
%           (X,F,Constraints,Options,A,H,C,P);
%
% OUTPUT
% See right above INPUT
%
% I/O
%
% Demo
% parafac2('demo')
%
% Short
% [A,H,C,P]=parafac2(X,F);
%
% Long
% [A,H,C,P,fit]=parafac2(X,F,Constraints,Options);
%
% Copyright
% Rasmus Bro
% KVL, DK, 1998
% rb@kvl.dk
%
% Reference to algorithm
% Bro, Kiers & Andersson, PARAFAC2 - Part II. Modeling chromatographic
% data with retention time shifts, Journal of Chemometrics, 1999, 13, 295-309

% TO DO:
% Set the algorithm to handle fixed modes as in PARALIN
% Make it N-way
% Incorporate ulsr

% $ Version 1.01 $ Date 28. December 1998 $ Not compiled $ RB
% $ Version 1.02 $ Date 31. March    1999 $ Added X-validation and added function $ Not compiled $ RB
% $ Version 1.03 $ Date 20. April    1999 $ Cosmetic changes $ Not compiled $ RB
% $ Version 1.04 $ Date 25. April    1999 $ Cosmetic changes $ Not compiled $ RB
% $ Version 1.05 $ Date 18. May      1999 $ Added orthogonality constraints $ Not compiled $ RB
% $ Version 1.06 $ Date 14. September1999 $ Changed helpfile $ Not compiled $ RB
% $ Version 1.07 $ Date 20. October  1999 $ Added unimodality $ Not compiled $ RB
% $ Version 1.08 $ Date 27. March    2000 $ Optimized handling of missing dat $ Not compiled $ RB
% $ Version 1.09 $ Date 27. January  2003 $ fixed output in cross-validation and removed breaks $ Not compiled $ RB
% $ Version 1.010 $ Date 27. January  2003 $ fixed error in cross-validation - not thoroughly tested! $ Not compiled $ RB
% $ Version 1.011 $ Date 8. April     2003 $ fixed yet an error in cross-validation - not thoroughly tested! $ Not compiled $ RB
% $ Version 1.1 $ Date March 2012 $ Added approximate nonnegativity to test if it was faster than traditional nonneg $ Not compiled $ RB
%

% This M-file and the code in it belongs to the holder of the
% copyrights and is made public under the following constraints:
% It must not be changed or modified and code cannot be added.
% The file must be regarded as read-only. Furthermore, the
% code can not be made part of any toolbox or similar.
% In case of doubt, contact the holder of the copyrights.

%
% Rasmus Bro
% Chemometrics Group, Food Technology
% Department of Food and Dairy Science
% Royal Veterinary and Agricultutal University
% Rolighedsvej 30, DK-1958 Frederiksberg, Denmark
% Phone  +45 35283296
% Fax    +45 35283245
% E-mail rb@kvl.dk
%

S = warning('off', 'MATLAB:nearlySingularMatrix');

if nargin==0
    disp(' ')
    disp(' ')
    disp(' THE PARAFAC2 MODEL')
    disp(' ')
    disp(' Type <<help parafac2>> for more info')
    disp('  ')
    disp(' I/O ')
    disp(' [A,H,C,P]=parafac2(X,F);')
    disp(' ')
    disp(' Or optionally')
    disp(' ')
    disp(' [A,H,C,P,fit]=parafac2(X,F,Constraints,Options);')
    disp(' ')
    disp(' Options=[Crit MaxIt Init Xval Show]')
    disp(' ')
    disp(' ')
    return
    
elseif nargin<2&~all(X=='demo')
    
    error(' The inputs X and F must be given')
    
end


if isstr(X) & all(X=='demo')
    F=3;
    n=1:30;
    disp(' ')
    disp(' %%%%% PARAFAC2 DEMO %%%%%%')
    disp(' ')
    disp(' Generating simulated data')
    disp(' Note that the second mode loadings change from slab to slab')
    disp(' hence the ordinary PARAFAC model is not valid')
    disp(' ')
    subplot(2,2,1)
    A=[exp(-((n-15)/5).^2);exp(-((n-1)/10).^2);exp(-((n-21)/7).^2)]';
    plot(A),title(' First mode loadings')
    subplot(2,2,2)
    C=rand(4,3);
    plot(C),title(' Third mode loadings')
    H=orth(orth(rand(F))');
    P=[];X=[];
    for i=1:size(C,1),
        subplot(2,4,4+i)
        P(:,:,i)=orth(rand(7,F));
        plot(P(:,:,i)*H),eval(['title([''2. mode, k = '',num2str(i)])'])
    end,
    disp(' Press key to continue'),pause
    for i=1:size(C,1),
        X(:,:,i)=A*diag(C(i,:))*(P(:,:,i)*H)';
    end,
    
    X = X + randn(size(X))*.01;
    disp(' Adding one percent noise and fitting model')
    disp(' Several initial models will be fitted and the best used')
    [a,h,c,p]=parafac2(X,F);
    
    disp(' ')
    disp(' Results shown in plot')
    subplot(2,2,1)
    plot(A*diag(sum(A).^(-1)),'r'),
    hold on,
    plot(a*diag(sum(a).^(-1)),'g'),title(' First mode (red true,green estimated)')
    hold off
    subplot(2,2,2)
    plot(C*diag(sum(C).^(-1)),'r')
    hold on,
    plot(c*diag(sum(c).^(-1)),'g'),title(' Third mode (red true,green estimated)')
    hold off
    for i=1:size(C,1),
        subplot(2,4,4+i)
        ph=P(:,:,i)*H;
        plot(ph*diag(sum(ph).^(-1)),'r'),
        hold on
        ph=p{i}*h;
        plot(ph*diag(sum(ph).^(-1)),'g'),
        eval(['title([''2. mode, k = '',num2str(i)])'])
        hold off
    end,
    return
    
end


ShowFit  = 100; % Show fit every 'ShowFit' iteration
NumRep   = 10; %Number of repetead initial analyses
NumItInRep = 80; % Number of iterations in each initial fit
if ~(length(size(X))==3|iscell(X))
    error(' X must be a three-way array or a cell array')
end
%set random number generators
randn('state',sum(100*clock));
rand('state',sum(100*clock));

if nargin < 4
    Options = zeros(1,5);
end
if length(Options)<5
    Options = Options(:);
    Options = [Options;zeros(5-length(Options),1)];
end

% Convergence criterion
if Options(1)==0
    ConvCrit = 1e-7;
else
    ConvCrit = Options(1);
end
if Options(5)==0
    disp(' ')
    disp(' ')
    disp([' Convergence criterion        : ',num2str(ConvCrit)])
end

% Maximal number of iterations
if Options(2)==0
    MaxIt = 2000;
else
    MaxIt = Options(2);
end

% Initialization method
initi = Options(3);

if nargin<3
    Constraints = [0 0];
end
if length(Constraints)~=2
    Constraints = [0 0];
    disp(' Length of Constraints must be two. It has been set to zeros')
end
% Modify to handle GPA (Constraints = [10 10]);
if Constraints(2)==10
    Constraints(1)=0;
    ConstB = 10;
else
    ConstB = 0;
end


ConstraintOptions=[ ...
    'Fixed                     ';...
    'Unconstrained             ';...
    'Non-negativity constrained';...
    'Orthogonality constrained ';...
    'Unimodality constrained   ';...
    'Approximate nonnegativity ';...
    'Not defined               ';...
    'Not defined               ';...
    'Not defined               ';...
    'Not defined               ';...
    'Not defined               ';...
    'GPA                       '];


if Options(5)==0
    disp([' Maximal number of iterations : ',num2str(MaxIt)])
    disp([' Number of factors            : ',num2str(F)])
    disp([' Loading 1. mode, A           : ',ConstraintOptions(Constraints(1)+2,:)])
    disp([' Loading 3. mode, C           : ',ConstraintOptions(Constraints(2)+2,:)])
    disp(' ')
end


% Make X a cell array if it isn't
if ~iscell(X)
    for k = 1:size(X,3)
        x{k} = X(:,:,k);
    end
    X = x;
    clear x
end
I = size(X{1},1);
K = max(size(X));

% CROSS-VALIDATION
if Options(4)==1
    Opt = Options;
    Opt(4) = 0;
    splits = 7;
    while rem(I,splits)==0 % Change the number of segments if 7 is a divisor in prod(size(X))
        splits = splits + 2;
    end
    AddiOutput.NumberOfSegments = splits;
    if Options(5)==0
        disp(' ')
        disp([' Cross-validation will be performed using ',num2str(splits),' segments'])
        disp([' and using from 1 to ',num2str(F),' components'])
        XvalModel = [];
    end
    SS = zeros(1,F);
    for f = 1:F
        Arep = [];Hrep = [];Crep = [];clear Prep;
        for s = 1:splits
            Xmiss = X;
            for k = 1:K
                Xmiss{k}(s:splits:end)=NaN;
            end
            [a,h,c,p]=parafac2(Xmiss,f,Constraints,Opt);
            Arep(:,:,s)=a;Hrep(:,:,s)=h;Crep(:,:,s)=c;Prep(s,:)=p;
            for k = 1:K
                m    = a*diag(c(k,:))*(p{k}*h)';
                M{k} = m;
                SS(f) = SS(f) + sum(sum(((X{k}(s:splits:end)-m(s:splits:end)).^2)));
            end
            XvalModel{f} = M;
        end
        %AddiOutput.XvalModels=XvalModel;
        AddiOutput.SS = SS;
        AddiOutput.A_xval{f}=Arep;
        AddiOutput.H_xval{f}=Hrep;
        AddiOutput.C_xval{f}=Crep;
        AddiOutput.P_xval{f}=Prep;
        A = AddiOutput;
    end
    
    clf
    plot([1:F],SS),title(' Residual sum-squares - cross-validation')
    xlabel('Number of components')
    disp(' ')
    disp(' The total model has NOT been fitted.')
    disp(' You must refit the model with the number of ')
    disp(' components you judge necessary.')
    disp(' ')
    disp(' You can also check the outputted struct array')
    disp(' It contains loadings estimated from different')
    disp(' subsets and stability of subsets indicates validity.')
    disp(' (e.g. if name of struct array is Output then the file')
    disp(' AX=Output.A_xval{3}is a three-way array holding all A')
    disp(' loadings estimated with 3 components. AX(:,:,1) is the ')
    disp(' estimate of A obtained from the first subset etc.')
    
    [a,b]=min(SS);
    figure
    subplot(2,1,1)
    a=AddiOutput.A_xval{b};
    for i=2:splits
        plot(a(:,:,i),'r'),hold on
    end
    title([' A resampled during Xval for ',num2str(b),' comp.'])
    hold off
    
    subplot(2,1,2)
    c = AddiOutput.C_xval{b};
    for i=2:splits
        plot(c(:,:,i),'r'),hold on
    end
    title([' C resampled during Xval for ',num2str(b),' comp.'])
    hold off
    A = AddiOutput;
    return
end

% Find missing and replace with average
MissingElements = 0;
MissNum=0;AllNum=0;
for k = 1:K
    x=X{k};
    miss = sparse(isnan(x));
    MissingOnes{k} = miss;
    if any(miss(:))
        MissingElements = 1;
        % Replace missing with mean over slab (not optimal but what the heck)
        % Iteratively they'll be replaced with model estimates
        x(find(miss)) = mean(x(find(~miss)));
        X{k} = x;
        MissNum = MissNum + prod(size(find(miss)));
        AllNum = AllNum + prod(size(x));
    end
end
if MissingElements
    if Options(5)==0
        PercMiss = 100*MissNum/AllNum;
        RoundedOf = .1*round(PercMiss*10);
        disp([' Missing data handled by EM   : ',num2str(RoundedOf),'%'])
    end
end
clear x

% Initialize by ten small runs
if nargin<5
    if initi==0
        if Options(5)==0
            disp([' Use best of ',num2str(NumRep)])
            disp(' initially fitted models')
        end
        Opt = Options;
        Opt = Options(1)/20;
        Opt(2) = NumItInRep; % Max NumItInRep iterations
        Opt(3) = 1;  % Init with SVD
        Opt(4) = 0;
        Opt(5) = 1;
        [A,H,C,P,bestfit]=parafac2(X,F,Constraints,Opt);
        AllFit = bestfit;
        for i = 2:NumRep
            Opt(3) = 2;   % Init with random
            [a,h,c,p,fit]=parafac2(X,F,Constraints,Opt);
            AllFit = [AllFit fit];
            if fit<bestfit
                A=a;H=h;C=c;P=p;
                bestfit = fit;
            end
        end
        AddiOutput.AllFit = AllFit;
        if Options(5)==0
            for ii=1:length(AllFit)
                disp([' Initial Model Fit            : ',num2str(AllFit(ii))])
            end
        end
        % Initialize by SVD
    elseif initi==1
        if Options(5)==0
            disp(' SVD based initialization')
        end
        XtX=X{1}*X{1}';
        for k = 2:K
            XtX = XtX + X{k}*X{k}';
        end
        [A,s,v]=svd(XtX,0);
        A=A(:,1:F);
        C=ones(K,F)+randn(K,F)/10;
        H = eye(F);
    elseif initi==2
        if Options(5)==0
            disp(' Random initialization')
        end
        A = rand(I,F);
        C = rand(K,F);
        H = eye(F);
    else
        error(' Options(2) wrongly specified')
    end
end

if initi~=1
    XtX=X{1}*X{1}'; % Calculate for evaluating fit (but if initi = 1 it has been calculated)
    for k = 2:K
        XtX = XtX + X{k}*X{k}';
    end
end
fit    = sum(diag(XtX));
oldfit = fit*2;
fit0   = fit;
it     = 0;
Delta = 1;

if Options(5)==0
    disp(' ')
    disp(' Fitting model ...')
    disp(' Loss-value      Iteration     %VariationExpl')
end

% Iterative part
while abs(fit-oldfit)>oldfit*ConvCrit & it<MaxIt & fit>1000*eps
    oldfit = fit;
    it   = it + 1;
    
    % Update P
    for k = 1:K
        Qk       = X{k}'*(A*diag(C(k,:))*H');
        P{k}     = Qk*psqrt(Qk'*Qk);
        %  [u,s,v]  = svd(Qk.');P{k}  = v(:,1:F)*u(:,1:F)';
        Y(:,:,k) = X{k}*P{k};
    end
    
    % Update A,H,C using PARAFAC-ALS
    [A,H,C,ff]=parafac(reshape(Y,I,F*K),[I F K],F,1e-4,[Constraints(1) ConstB Constraints(2)],A,H,C,5);
    [fit,X] = pf2fit(X,A,H,C,P,K,MissingElements,MissingOnes);
    % Print interim result
    if rem(it,ShowFit)==0|it == 1
        if Options(5)==0
            fprintf(' %12.10f       %g        %3.4f \n',fit,it,100*(1-fit/fit0));
            subplot(2,2,1)
            plot(A),title('First mode')
            subplot(2,2,2)
            plot(C),title('Third mode')
            subplot(2,2,3)
            plot(P{1}*H),title('Second mode (only first k-slab shown)')
            drawnow
        end
    end
    
end

if rem(it,ShowFit)~=0 %Show final fit if not just shown
    if Options(5)==0
        fprintf(' %12.10f       %g        %3.4f \n',fit,it,100*(1-fit/fit0));
    end
end



function [fit,X]=pf2fit(X,A,H,C,P,K,MissingElements,MissingOnes);

% Calculate fit and impute missing elements from model

fit = 0;
for k = 1:K
    M   = A*diag(C(k,:))*(P{k}*H)';
    % if missing values replace missing elements with model estimates
    if nargout == 2
        if any(MissingOnes{k})
            x=X{k};
            x(find(MissingOnes{k})) = M(find(MissingOnes{k}));
            X{k} = x;
        end
    end
    fit = fit + sum(sum(abs (X{k} - M ).^2));
end


function X = psqrt(A,tol)

% Produces A^(-.5) even if rank-problems

[U,S,V] = svd(A,0);
if min(size(S)) == 1
    S = S(1);
else
    S = diag(S);
end
if (nargin == 1)
    tol = max(size(A)) * S(1) * eps;
end
r = sum(S > tol);
if (r == 0)
    X = zeros(size(A'));
else
    S = diag(ones(r,1)./sqrt(S(1:r)));
    X = V(:,1:r)*S*U(:,1:r)';
end


function [A,B,C,fit,it] = parafac(X,DimX,Fac,crit,Constraints,A,B,C,maxit,DoLineSearch);

% Complex PARAFAC-ALS
% Fits the PARAFAC model Xk = A*Dk*B.' + E
% where Dk is a diagonal matrix holding the k'th
% row of C.
%
% Uses on-the-fly projection-compression to speed up
% the computations. This requires that the first mode
% is the largest to be effective
%
% INPUT
% X          : Data
% DimX       : Dimension of X
% Fac        : Number of factors
% OPTIONAL INPUT
% crit       : Convergence criterion (default 1e-6)
% Constraints: [a b c], if e.g. a=0 => A unconstrained, a=1 => A nonnegative
% A,B,C      : Initial parameter values
%
% I/O
% [A,B,C,fit,it]=parafac(X,DimX,Fac,crit,A,B,C);
%
% Copyright 1998
% Rasmus Bro
% KVL, Denmark, rb@kvl.dk

% Initialization
if nargin<9
    maxit   = 2500;      % Maximal number of iterations
end
showfit = pi;         % Show fit every 'showfit'th iteration (set to pi to avoid)

if nargin<4
    crit=1e-6;
end

if crit==0
    crit=1e-6;
end

I = DimX(1);
J = DimX(2);
K = DimX(3);

InitWithRandom=0;
if nargin<8
    InitWithRandom=1;
end
if nargin>7 & size(A,1)~=I
    InitWithRandom=1;
end

if nargin<5
    ConstA = 0;ConstB = 0;ConstC = 0;
else
    ConstA = Constraints(1);ConstB = Constraints(2);ConstC = Constraints(3);
end

if InitWithRandom
    
    if I<Fac
        A = rand(I,Fac);
    else
        A = orth(rand(I,Fac));
    end
    if J<Fac
        B = rand(J,Fac);
    else
        B = orth(rand(J,Fac));
    end
    if K<Fac
        C = rand(K,Fac);
    else
        C = orth(rand(K,Fac));
    end
end

SumSqX = sum(sum(abs(X).^2));
fit    = SumSqX;
fit0   = fit;
fitold = 2*fit;
it     = 0;
Delta  = 5;

while abs((fit-fitold)/fitold)>crit&it<maxit&fit>10*eps
    it=it+1;
    fitold=fit;
    
    % Do line-search
    if rem(it+2,2)==-1
        [A,B,C,Delta]=linesrch(X,DimX,A,B,C,Ao,Bo,Co,Delta);
    end
    
    Ao=A;Bo=B;Co=C;
    % Update A
    Xbc=0;
    for k=1:K
        Xbc = Xbc + X(:,(k-1)*J+1:k*J)*conj(B*diag(C(k,:)));
    end
    if ConstA == 0 % Unconstrained
        A = Xbc*pinv((B'*B).*(C'*C)).';
    elseif ConstA == 1 % Nonnegativity, requires reals
        Aold = A;
        for i = 1:I
            ztz = (B'*B).*(C'*C);
            A(i,:) = fastnnls(ztz,Xbc(i,:)')';
        end
        if any(sum(A)<100*eps*I)
            A = .99*Aold+.01*A; % To prevent a matrix with zero columns
        end
    elseif ConstA == 2 % Orthogonality
        A = Xbc*(Xbc'*Xbc)^(-.5);
    elseif ConstA == 3 % Unimodality
        A = unimodalcrossproducts((B'*B).*(C'*C),Xbc',A);
    elseif ConstA == 4 % Unimodality
        Aold = A;
        A = Xbc*pinv((B'*B).*(C'*C)).';
        A(find(A<0))=0;
        if any(sum(A)<100*eps*I)
            A = .99*Aold+.01*A; % To prevent a matrix with zero columns
        end
        
    end
    
    % Project X down on orth(A) - saves time if first mode is large
    [Qa,Ra]=qr(A,0);
    x=Qa'*X;
    
    % Update B
    if ConstB == 10 % Procrustes
        B = eye(Fac);
    else
        Xac=0;
        for k=1:K
            Xac = Xac + x(:,(k-1)*J+1:k*J).'*conj(Ra*diag(C(k,:)));
        end
        if ConstB == 0 % Unconstrained
            B = Xac*pinv((Ra'*Ra).*(C'*C)).';
        elseif ConstB == 1 % Nonnegativity, requires reals
            Bold = B;
            for j = 1:J
                ztz = (Ra'*Ra).*(C'*C);
                B(j,:) = fastnnls(ztz,Xac(j,:)')';
            end
            if any(sum(B)<100*eps*J)
                B = .99*Bold+.01*B; % To prevent a matrix with zero columns
            end
        elseif ConstB == 4
            B = Xac*pinv((Ra'*Ra).*(C'*C)).';
            B(find(B<0))=0;
        end
    end
    
    % Update C
    if ConstC == 0 % Unconstrained
        ab=pinv((Ra'*Ra).*(B'*B));
        for k=1:K
            C(k,:) = (ab*diag(Ra'* x(:,(k-1)*J+1:k*J)*conj(B))).';
        end
    elseif ConstC == 1  % Nonnegativity, requires reals
        Cold = C;
        ztz = (Ra'*Ra).*(B'*B);
        for k = 1:K
            xab = diag(Ra'* x(:,(k-1)*J+1:k*J)*B);
            C(k,:) = fastnnls(ztz,xab)';
        end
        if any(sum(C)<100*eps*K)
            C = .99*Cold+.01*C; % To prevent a matrix with zero columns
        end
    elseif ConstC == 2 % Orthogonality
        Z=(Ra'*Ra).*(B'*B);
        Y=[];
        for k=1:K
            d=diag(Ra'*x(:,(k-1)*J+1:k*J)*B)';
            Y=[Y;d];
        end;
        [P,D,Q]=svd(Y,0);
        C=P*Q';
    elseif ConstC == 3 % Unimodality
        xab = [];
        for k = 1:K
            xab = [xab diag(Ra'* x(:,(k-1)*J+1:k*J)*B)];
        end
        C = unimodalcrossproducts((Ra'*Ra).*(B'*B),xab,C);
    elseif ConstC==4
        Cold = C;
        ab=pinv((Ra'*Ra).*(B'*B));
        for k=1:K
            C(k,:) = (ab*diag(Ra'* x(:,(k-1)*J+1:k*J)*conj(B))).';
        end
        C(find(C<0))=0;
        if any(sum(C)<100*eps*K)
            C = .99*Cold+.01*C; % To prevent a matrix with zero columns
        end
        
    elseif ConstC == 10 % GPA => Isotropic scaling factor
        ab=(Ra'*Ra).*(B'*B);
        ab = pinv(ab(:));
        C(1,:) = 1;
        for k=2:K
            yy = [];
            yyy = diag(Ra'* x(:,(k-1)*J+1:k*J)*conj(B)).';
            for f=1:Fac
                yy = [yy;yyy(:)];
            end
            C(k,:) = ab*yy;
        end
    end
    
    % Calculating fit. Using orthogonalization instead
    %fit=0;for k=1:K,residual=X(:,(k-1)*J+1:k*J)-A*diag(C(k,:))*B.';fit=fit+sum(sum((abs(residual).^2)));end
    [Qb,Rb]=qr(B,0);
    [Z,Rc]=qr(C,0);
    fit=SumSqX-sum(sum(abs(Ra*ppp(Rb,Rc).').^2));
    
    if rem(it,showfit)==0
        fprintf(' %12.10f       %g        %3.4f \n',fit,it,100*(1-fit/fit0));
    end
end

% ORDER ACCORDING TO VARIANCE
Tuck     = diag((A'*A).*(B'*B).*(C'*C));
[out,ID] = sort(Tuck);
A        = A(:,ID);
if ConstB ~= 10 % Else B is eye
    B        = B(:,ID);
end
C        = C(:,ID);
% NORMALIZE A AND C (variance in B)
if ConstB ~= 10 % Then B is eye
    for f=1:Fac,normC(f) = norm(C(:,f));end
    for f=1:Fac,normA(f) = norm(A(:,f));end
    B        = B*diag(normC)*diag(normA);
    A        = A*diag(normA.^(-1));
    C        = C*diag(normC.^(-1));
    
    % APPLY SIGN CONVENTION
    SignA = sign(sum(sign(A))+eps);
    SignC = sign(sum(sign(C))+eps);
    A = A*diag(SignA);
    C = C*diag(SignC);
    B = B*diag(SignA)*diag(SignC);
end

function [NewA,NewB,NewC,DeltaMin] = linesrch(X,DimX,A,B,C,Ao,Bo,Co,Delta);

dbg=0;

if nargin<5
    Delta=5;
else
    Delta=max(2,Delta);
end

dA=A-Ao;
dB=B-Bo;
dC=C-Co;
Fit1=sum(sum(abs(X-A*ppp(B,C).').^2));
regx=[1 0 0 Fit1];
Fit2=sum(sum(abs(X-(A+Delta*dA)*ppp((B+Delta*dB),(C+Delta*dC)).').^2));
regx=[regx;1 Delta Delta.^2 Fit2];

while Fit2>Fit1
    if dbg
        disp('while Fit2>Fit1')
    end
    Delta=Delta*.6;
    Fit2=sum(sum(abs(X-(A+Delta*dA)*ppp((B+Delta*dB),(C+Delta*dC)).').^2));
    regx=[regx;1 Delta Delta.^2 Fit2];
end

Fit3=sum(sum(abs(X-(A+2*Delta*dA)*ppp((B+2*Delta*dB),(C+2*Delta*dC)).')^2));
regx=[regx;1 2*Delta (2*Delta).^2 Fit3];

while Fit3<Fit2
    if dbg
        disp('while Fit3<Fit2')
    end
    Delta=1.8*Delta;
    Fit2=Fit3;
    Fit3=sum(sum(abs(X-(A+2*Delta*dA)*ppp((B+2*Delta*dB),(C+2*Delta*dC)).')^2));
    regx=[regx;1 2*Delta (2*Delta).^2 Fit2];
end

% Add one point between the two smallest fits
[a,b]=sort(regx(:,4));
regx=regx(b,:);
Delta4=(regx(1,2)+regx(2,2))/2;
Fit4=sum(sum(abs(X-(A+Delta4*dA)*ppp((B+Delta4*dB),(C+Delta4*dC)).').^2));
regx=[regx;1 Delta4 Delta4.^2 Fit4];

%reg=pinv([1 0 0;1 Delta Delta^2;1 2*Delta (2*Delta)^2])*[Fit1;Fit2;Fit3]
reg=pinv(regx(:,1:3))*regx(:,4);
%DeltaMin=2*reg(3);

DeltaMin=-reg(2)/(2*reg(3));

%a*x2 + bx + c = fit
%2ax + b = 0
%x=-b/2a

NewA=A+DeltaMin*dA;
NewB=B+DeltaMin*dB;
NewC=C+DeltaMin*dC;
Fit=sum(sum(abs(X-NewA*ppp(NewB,NewC).').^2));

if dbg
    regx
    plot(regx(:,2),regx(:,4),'o'),
    hold on
    x=linspace(0,max(regx(:,2))*1.2);
    plot(x',[ones(100,1) x' x'.^2]*reg),
    hold off
    drawnow
    [DeltaMin Fit],pause
end

[minfit,number]=min(regx(:,4));
if Fit>minfit
    DeltaMin=regx(number,2);
    NewA=A+DeltaMin*dA;
    NewB=B+DeltaMin*dB;
    NewC=C+DeltaMin*dC;
end

function AB=ppp(A,B);

% $ Version 1.02 $ Date 28. July 1998 $ Not compiled $
%
% Copyright, 1998 -
% This M-file and the code in it belongs to the holder of the
% copyrights and is made public under the following constraints:
% It must not be changed or modified and code cannot be added.
% The file must be regarded as read-only. Furthermore, the
% code can not be made part of anything but the 'N-way Toolbox'.
% In case of doubt, contact the holder of the copyrights.
%
% Rasmus Bro
% Chemometrics Group, Food Technology
% Department of Food and Dairy Science
% Royal Veterinary and Agricultutal University
% Rolighedsvej 30, DK-1958 Frederiksberg, Denmark
% Phone  +45 35283296
% Fax    +45 35283245
% E-mail rb@kvl.dk
%
% The parallel proportional profiles product - triple-P product
% For two matrices with similar column dimension the triple-P product
% is ppp(A,B) = [kron(B(:,1),A(:,1) .... kron(B(:,F),A(:,F)]
%
% AB = ppp(A,B);
%
% Copyright 1998
% Rasmus Bro
% KVL,DK
% rb@kvl.dk

[I,F]=size(A);
[J,F1]=size(B);

if F~=F1
    error(' Error in ppp.m - The matrices must have the same number of columns')
end

AB=zeros(I*J,F);
for f=1:F
    ab=A(:,f)*B(:,f).';
    AB(:,f)=ab(:);
end



function [x,w] = fastnnls(XtX,Xty,tol)
%NNLS	Non-negative least-squares.
%	b = fastnnls(XtX,Xty) returns the vector b that solves X*b = y
%	in a least squares sense, subject to b >= 0, given the inputs
%       XtX = X'*X and Xty = X'*y.
%
%	A default tolerance of TOL = MAX(SIZE(X)) * NORM(X,1) * EPS
%	is used for deciding when elements of b are less than zero.
%	This can be overridden with b = fastnnls(X,y,TOL).
%
%	[b,w] = fastnnls(XtX,Xty) also returns dual vector w where
%	w(i) < 0 where b(i) = 0 and w(i) = 0 where b(i) > 0.
%
%	See also LSCOV, SLASH.

%	L. Shure 5-8-87
%	Revised, 12-15-88,8-31-89 LS.
%	Copyright (c) 1984-94 by The MathWorks, Inc.

%       Revised by:
%	Copyright
%	Rasmus Bro 1995
%	Denmark
%	E-mail rb@kvl.dk
%       According to Bro & de Jong, J. Chemom, 1997

% initialize variables


if nargin < 3
    tol = 10*eps*norm(XtX,1)*max(size(XtX));
end
[m,n] = size(XtX);
P = zeros(1,n);
Z = 1:n;
x = P';
ZZ=Z;
w = Xty-XtX*x;

% set up iteration criterion
iter = 0;
itmax = 30*n;

% outer loop to put variables into set to hold positive coefficients
while any(Z) & any(w(ZZ) > tol)
    [wt,t] = max(w(ZZ));
    t = ZZ(t);
    P(1,t) = t;
    Z(t) = 0;
    PP = find(P);
    ZZ = find(Z);
    nzz = size(ZZ);
    z(PP')=(Xty(PP)'/XtX(PP,PP)');
    z(ZZ) = zeros(nzz(2),nzz(1))';
    z=z(:);
    % inner loop to remove elements from the positive set which no longer belong
    
    while any((z(PP) <= tol)) & iter < itmax
        
        iter = iter + 1;
        QQ = find((z <= tol) & P');
        alpha = min(x(QQ)./(x(QQ) - z(QQ)));
        x = x + alpha*(z - x);
        ij = find(abs(x) < tol & P' ~= 0);
        Z(ij)=ij';
        P(ij)=zeros(1,max(size(ij)));
        PP = find(P);
        ZZ = find(Z);
        nzz = size(ZZ);
        z(PP)=(Xty(PP)'/XtX(PP,PP)');
        z(ZZ) = zeros(nzz(2),nzz(1));
        z=z(:);
    end
    x = z;
    w = Xty-XtX*x;
end

x=x(:);


function B=unimodalcrossproducts(XtX,XtY,Bold)

% Solves the problem min|Y-XB'| subject to the columns of
% B are unimodal and nonnegative. The algorithm is iterative and
% only one iteration is given, hence the solution is only improving
% the current estimate
%
% I/O B=unimodalcrossproducts(XtX,XtY,Bold)
% Modified from unimodal.m to handle crossproducts in input 1999
%
% Copyright 1997
%
% Rasmus Bro
% Royal Veterinary & Agricultural University
% Denmark
% rb@kvl.dk
%
% Reference
% Bro and Sidiropoulos, "Journal of Chemometrics", 1998, 12, 223-247.


B=Bold;
F=size(B,2);
for f=1:F
    xty = XtY(f,:)-XtX(f,[1:f-1 f+1:F])*B(:,[1:f-1 f+1:F])';
    beta=pinv(XtX(f,f))*xty;
    B(:,f)=ulsr(beta',1);
end


function [b,All,MaxML]=ulsr(x,NonNeg);

% ------INPUT------
%
% x          is the vector to be approximated
% NonNeg     If NonNeg is one, nonnegativity is imposed
%
%
%
% ------OUTPUT-----
%
% b 	     is the best ULSR vector
% All 	     is containing in its i'th column the ULSRFIX solution for mode
% 	     location at the i'th element. The ULSR solution given in All
%            is found disregarding the i'th element and hence NOT optimal
% MaxML      is the optimal (leftmost) mode location (i.e. position of maximum)
%
% ___________________________________________________________
%
%
%               Copyright 1997
%
% Nikos Sidiroupolos
% University of Maryland
% Maryland, US
%
%       &
%
% Rasmus Bro
% Royal Veterinary & Agricultural University
% Denmark
%
%
% ___________________________________________________________


% This file uses MONREG.M

x=x(:);
I=length(x);
xmin=min(x);
if xmin<0
    x=x-xmin;
end


% THE SUBSEQUENT
% CALCULATES BEST BY TWO MONOTONIC REGRESSIONS

% B1(1:i,i) contains the monontonic increasing regr. on x(1:i)
[b1,out,B1]=monreg(x);

% BI is the opposite of B1. Hence BI(i:I,i) holds the monotonic
% decreasing regression on x(i:I)
[bI,out,BI]=monreg(flipud(x));
BI=flipud(fliplr(BI));

% Together B1 and BI can be concatenated to give the solution to
% problem ULSR for any modloc position AS long as we do not pay
% attention to the element of x at this position


All=zeros(I,I+2);
All(1:I,3:I+2)=B1;
All(1:I,1:I)=All(1:I,1:I)+BI;
All=All(:,2:I+1);
Allmin=All;
Allmax=All;
% All(:,i) holds the ULSR solution for modloc = i, disregarding x(i),


iii=find(x>=max(All)');
b=All(:,iii(1));
b(iii(1))=x(iii(1));
Bestfit=sum((b-x).^2);
MaxML=iii(1);
for ii=2:length(iii)
    this=All(:,iii(ii));
    this(iii(ii))=x(iii(ii));
    thisfit=sum((this-x).^2);
    if thisfit<Bestfit
        b=this;
        Bestfit=thisfit;
        MaxML=iii(ii);
    end
end

if xmin<0
    b=b+xmin;
end


% Impose nonnegativity
if NonNeg==1
    if any(b<0)
        id=find(b<0);
        % Note that changing the negative values to zero does not affect the
        % solution with respect to nonnegative parameters and position of the
        % maximum.
        b(id)=zeros(size(id))+0;
    end
end

function [b,B,AllBs]=monreg(x);

% Monotonic regression according
% to J. B. Kruskal 64
%
% b     = min|x-b| subject to monotonic increase
% B     = b, but condensed
% AllBs = All monotonic regressions, i.e. AllBs(1:i,i) is the
%         monotonic regression of x(1:i)
%
%
% Copyright 1997
%
% Rasmus Bro
% Royal Veterinary & Agricultural University
% Denmark
% rb@kvl.dk
%


I=length(x);
if size(x,2)==2
    B=x;
else
    B=[x(:) ones(I,1)];
end

AllBs=zeros(I,I);
AllBs(1,1)=x(1);
i=1;
while i<size(B,1)
    if B(i,1)>B(min(I,i+1),1)
        summ=B(i,2)+B(i+1,2);
        B=[B(1:i-1,:);[(B(i,1)*B(i,2)+B(i+1,1)*B(i+1,2))/(summ) summ];B(i+2:size(B,1),:)];
        OK=1;
        while OK
            if B(i,1)<B(max(1,i-1),1)
                summ=B(i,2)+B(i-1,2);
                B=[B(1:i-2,:);[(B(i,1)*B(i,2)+B(i-1,1)*B(i-1,2))/(summ) summ];B(i+1:size(B,1),:)];
                i=max(1,i-1);
            else
                OK=0;
            end
        end
        bInterim=[];
        for i2=1:i
            bInterim=[bInterim;zeros(B(i2,2),1)+B(i2,1)];
        end
        No=sum(B(1:i,2));
        AllBs(1:No,No)=bInterim;
    else
        i=i+1;
        bInterim=[];
        for i2=1:i
            bInterim=[bInterim;zeros(B(i2,2),1)+B(i2,1)];
        end
        No=sum(B(1:i,2));
        AllBs(1:No,No)=bInterim;
    end
end

b=[];
for i=1:size(B,1)
    b=[b;zeros(B(i,2),1)+B(i,1)];
end
