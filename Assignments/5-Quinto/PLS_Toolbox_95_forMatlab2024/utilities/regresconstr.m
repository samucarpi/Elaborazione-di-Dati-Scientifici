function [B,aux,flag,it] = regresconstr(X,A,Bold,options,iter,aux)

%REGRESCONSTR For constrained bilinear regression.
%  Estimates one loading matrix in a bilinear model given the
%  data and the other loading matrix. Uses least squares
%  fitting and permits a number of constraints to be
%  imposed.
%
%  Solves
%       B = argmin||X - AB'||
%  subject to specificed constraints
%
%  INPUTS:
%       X = IxJ matrix of real-valued data
%       A = (Interim) score/loading matrix and optionally a prior estimate of B (Bold)
%
%  OPTIONAL INPUTS:
%    Bold = Prior estimate of the matrix B to estimate
% options = Structure defining constraints
%
%   For e.g. three-way parafac: parafacoptions.constraints =
%   {options1,options2,options3}; where options1 are the
%   options for the first mode etc.
%
%
% I/O:       B = regresconstr(X,A,Bold,options);
% I/O: options = regresconstr('options');         % Default constraints
% I/O:    text = regresconstr('text',options)     % Description of options:
% I/O:     def = regresconstr({options1;options2})% Find which modes are constrained,
% I/O:                                              which can be scaled and
% I/O:                                              which normalized for a
% I/O:                                              cell of constraint options
%
%See also: LSCOV, MCR, PARAFAC, PARAFAC2, TUCKER

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Feb, 2003, RB, Changed nonnegativity to allow choosing which algorithm to use.
% Feb, 2003, RB, Improved speed of traditional nonnegativity .
% Feb, 2003, RB, Modified functional constraints.
% May, 2004, JMS, Revised from use of internal fastnnls to PLS_Toolbox
%   version (which is 6.1 compatible). Old code still at end of routine.
% Feb, 2005, RB, Fixed exponential constraints



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% INITIALIZE %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


warning off backtrace
maxiter = 10;
varargout = [];
flag = 0;

% Generate options when "options = regresconstr('options');"
if nargin==2 && isstr(X)&& strcmpi(X,'text');
  B = maketxt(A);
  return
end

if nargin == 0;
  X = 'io';
end
if ischar(X)
  options = setdefaults;
  if nargout==0;
    clear varargout;
    evriio(mfilename,X,options);
  else
    B = evriio(mfilename,X,options);
  end
  return;
end

% Make text describing used constraints
if nargin==2
  if isstr(X)
    if strcmpi(X,'text'); % Make a verbal description of the constraints
      B = maketxt(A);
      return
    elseif strcmpi(X,'gui');  % Set constraints with gui
      for i=1:length(size(X))
        constopt{1} = regresconstr('options');
        % NEED TO DO THE GUI
      end
    end
  end
end
% Find which modes are scaled, which can be scaled and which can be normalized
if nargin==1
  if isstruct(X)||iscell(X)
    B = optionsoverview(X);
    return
  end
end

% Explode options
[nonnegativity,nonnegativityalgorithm,unimodality,exponential,orthogonal,orthonormal,smoothness,...
  fixed,equality,ridge,leftprod,rightprod,lae,lts,iterate_to_conv,timeaxis,funcon]=getopt(options);

J = size(X,2);
F = size(A,2);

% Check if functional constraints. If so, overrule other constraints and do
% functional constraint
if size(funcon,1)==F && size(funcon,2) == 3
  % Use prior parameters if they exist (they don't the first time)
  if iscell(aux)
    if length(aux)==F
      funcon(:,2) = aux;
    end
  end


  B = Bold;
  %  for rep = 1:3
  for f=1:F
    % determine the ls problem for all except component f subtracted
    Xf = X- A(:,[1:f-1 f+1:F])*B(:,[1:f-1 f+1:F])';
    % Determine the LS solution for component f given the others ('unimodal-trick')
    bf = Xf'*pinv(A(:,f))';
    if ~isempty(funcon{f,1})
      oldparam = funcon{f,2};
      additionalparam = funcon{f,3};
      additionalparam{length(additionalparam)+1}=bf; % Add the current estimate of bf for the loss function to work
      %        [newparam]= smarquardt(funcon{f,1},additionalparam,oldparam,[.3  1e-11  1e-11  150 5]);
      newparam= fminsearch(funcon{f,1},oldparam,[],additionalparam);
      % Check if new is better than prior and update if so
      [out1,bfnew] = feval(funcon{f,1},newparam,additionalparam);
      [out2,bfold]= feval(funcon{f,1},oldparam,additionalparam);
      %[oldparam newparam]
      %[out1-out2 2222]
      if sum(out1.^2)>sum(out2.^2) % Didn't improve so go back to old
        bfnew = bfold;
        disp('going back to old')
      else
        funcon{f,2}=newparam;
      end
      % Every now and then test some completely different initial values
      % just to provide a little help if the algorithm is going in a bad direction
      if 4==5
        if rand(1)<.03 % In 3% of the runs do this
          [newparam2]= smarquardt(funcon{f,1},additionalparam,rand(1)*10*randn(size(oldparam)),[1  1e-11  1e-11  150 .1]);
          [out1,bfnew] = feval(funcon{f,1},newparam,additionalparam);
          [out2,bfrand]= feval(funcon{f,1},newparam2,additionalparam);
          if sum(out1.^2)>sum(out2.^2) % Didn't improve so change to new one with random initial values
            bfnew = bfrand;
            funcon{f,2}=newparam2;
          end
        end
      end
      %      end
      B(:,f)=bfnew(:);
    end
  end
  it=1;
  aux = funcon(:,2);

  %% IF FIXED ELEMENTS DO SPECIAL ONE. NOTE: FIX ONLY ALLOWS NONNEG AND
  %% ULSR IN ADDITION
elseif any(fixed.position(:))
  fix = fixed.value;
  fixpos = fixed.position;
  Bold(find(fixpos)) = fix(find(fixpos));
  B = Bold;
  if all(size(B)==[F 1]) % Correction needed when fixing elements in the core
    B = B';
  end
  F = size(A,2);
  % Do columnwise update
  for f = 1:F
    if length(find(~fixpos(:,f)))>0 % If whole column is fixed just skip it
      Xres = X-A(:,[1:f-1 f+1:F])*B(:,[1:f-1 f+1:F])';
      B(find(~fixpos(:,f)),f) = (inv(A(:,f)'*A(:,f))*A(:,f)'*Xres(:,find(~fixpos(:,f))))';
    end
    B(find(fixpos(:,f)),f) = fix(find(fixpos(:,f)),f);
  end
  if unimodality
    B(:,f)=ulsr(B(:,f)',nonnegativity);
  elseif nonnegativity
    id = find(~fixpos);
    id2 = find(B(id)<0);
    B(id(id2)) = 0;
  end
  aux=[];flag=[];it=[];
  return
elseif fixed.weight == -1 % Completely fixed
  B = Bold;
  aux=[];flag=[];it=[];

  %% ALL OTHER CONSTRAINTS

else

  % Initialize Bold & B
  if nargin<3|~all(size(Bold)==[J F])
    Bold = X'*pinv(A)';
  end
  B = Bold;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%% PREPROCESS (equal,fix etc) %%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  constrtext='Constraints:';
  converged = 0;it = 0;
  Jold = J;
  Fold = F;
  while ~converged
    it = it +1;
    Bold = B;

    if size(leftprod,1)==Jold&Jold>1;
      X = X*pinv(leftprod)';
      Bold = pinv(leftprod)*Bold;
      B = Bold;
      J = size(X,2);
    else
      Jold=0;
    end

    if size(rightprod,2)==Fold&Fold>1;
      A = A*rightprod';
      Bold = Bold*pinv(rightprod);
      B = Bold;
      J = size(X,2);
    else
      Jold2=0;
    end


    % Add equality
    if isstruct(equality)
      if equality.weight
        w = equality.weight;
        w1 = sum(A(:).^2);
        w2 = sum(X(:).^2)/sum(equality.H(:).^2);
        X = [X;w*w1*w2*equality.H];
        A = [A;w*w1*w2*equality.G];
      end
    end

    if isstruct(smoothness)
      if smoothness.weight
        % Fast computation of a B-spline basis,
        % of degree "deg", at positions "xx",
        % on a uniform grid with "ndx" intervals between "x0" and "x1".
        % Saver computations
        

        x0 = 1; x1 = J; deg = 3;
        % Number of splines defines smoothness (1 high - few splines, 0 low -
        % many splines)
        ndx = J - smoothness.weight*J;
        ndx  = round(ndx);ndx = min(max(ndx,2),J);
        
        Bs = bbase([1:J]', 1, J, ndx, deg);
        X = X*Bs*pinv(Bs);
        % Old version - not working properly yet. Needs better scaling to
        % avoid non-convergence
        % o=ones(J,1);P=spdiags([-o 3*o -3*o o],[-2:1],J,J);
        % P=full(P(3:J-1,:));PtP=P'*P;w = smoothness.weight;
        % w1 = sum(A(:).^2);w2 = sum(X(:).^2);X = [X;w*w1*w2*P];
        % A = [A;w*w1*w2*ones(size(P,1),size(A,2))];
      end
    end

    %     % Enforce fixed elements
    %     if isstruct(fixed)
    %       if fixed.weight>0
    %         w = fixed.weight;
    %         w1 = sqrt(sum(A(:).^2));
    %         %        w2 = sum(X(:).^2)/sum(fixed.value(:).^2);
    %         w2 = sqrt(sum(X(:).^2));
    %         w3 = sqrt(sum(fixed.value(:).^2));
    %         %w3 = sqrt(sum(Bold(:).^2));
    %         fix = fixed.value;
    %         fixpos = fixed.position;
    %         Bold(find(fixpos)) = fix(find(fixpos));
    %         %               X = [X;w*w1*w2*Bold'];
    %         %                A = [A;w*w1*w2*eye(F)];
    %         X = [max(eps*10000,(1-w))*X;(w*w2/w3)*Bold'];
    %         A = [max(eps*10000,(1-w))*A;(w*w2/w3)*eye(F)];
    %         % This algorithm could be slow because if enforces that fixed values should
    %         % be close to target but also that other elements should be close to their
    %         % prior values. However it has the advantage of being applicable even for
    %         % column-wise solved problems such as unimodality
    %         %         for ci = 1:size(fixed.position,1)
    %         %           for cj = 1:size(fixed.position,2)
    %         %             if fixed.position(ci,cj)
    %         %               X = [X;zeros(1,size(fixed.position,1))];
    %         %               X(end,ci)=w*w2/w3*(fixed.value(ci,cj));
    %         %               A = [A;zeros(1,size(fixed.position,2))];
    %         %               A(end,cj)=w*w2/w3;
    %         %             end
    %         %           end
    %         %         end
    %
    %       elseif fixed.weight<0
    %         if all(size(fixed.value)==[J F])& all(fixed.position(:)==1)
    %           B = fixed.value;
    %         else
    %           B = Bold;
    %         end
    %         converged = 1;
    %         return
    %       end
    %     end

    % Enforce ridging
    if isstruct(ridge)
      if ridge.weight
        w = ridge.weight;
        w1 = sum(A(:).^2);
        w2 = sum(X(:).^2);
        w3 = sum(Bold(:).^2);
        X = [X;0*Bold'];
        %A = [A;w*w2*eye(F)/w1];
        A = [A;w*w1*eye(F)];
        % This algorithm could be slow because if enforces that fixed values should
        % be close to target but also that other elements should be close to their
        % prior values. However it has the advantage of being applicable even for
        % column-wise solved problems such as unimodality
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%% REGRESSION PART %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if unimodality

      B=unimodal(A,X,Bold,nonnegativity);

    elseif exponential
      if nargin == 6
        [B,aux.rates]=exponential2(A,X,Bold,nonnegativity,iter,timeaxis,aux);
      else
        [B,aux.rates]=exponential2(A,X,Bold,nonnegativity,iter,timeaxis);
      end

    elseif nonnegativity
      % Use LS through row-wise nnls
      if nonnegativityalgorithm == 0
        Ax = A'*A;
        for k = 1:size(X,2)
          B(k,:) = CrossProdFastNnls(Ax,A'*X(:,k))';
          % B(k,:) = lsqnonneg(A,X(:,k),B(k,:)')';  % Alternative but actually
          % seems slower although it ought to be faster. Maybe bad initial
          % values makes it less good
        end

        % Use column-wise LS updating one column at a time
      elseif nonnegativityalgorithm == 1
        B = column_nonneg(A,X,Bold,nonnegativity,0);

        % Use non-LS setting negative numbers to zero
      elseif nonnegativityalgorithm == 2
        B = (A\X)';
        B(find(B<0)) = 0;

        % Use newer fast version of fastnnls
      elseif nonnegativityalgorithm == 3
        %         B = fastnnls2(A,X,0,Bold')';
        B = fastnnls(A,X,0,Bold')';

        % Use alternative algorithm
      elseif nonnegativityalgorithm == 4
        B = nmf(A,X,B);
 
     elseif nonnegativityalgorithm == 5
        B = column_nonneg(A,X,Bold,nonnegativity,options.nonnegativityslack);

      elseif nonnegativityalgorithm == 10 % Nonneg on some columns only
          howmanycolumns = options.howmanycolumns;
          B = column_nonneg_special(A,X,Bold,howmanycolumns);
          
      else
        error('Constraint option .nonnegativityalgorithm not set correct (0,1,2,3,4 or 5)')
      end


    elseif orthogonal
      B = orthregress(X,A);

    elseif orthonormal
      [B,flag] = orthnormregress(X,A,B);

    elseif lae
      B = plae(X,A,B',nonnegativity);
      B = B';

    elseif lts
      for ib=1:size(B,1)
        [raw,rew] = ltsregres(A,X(:,ib),'plots',0,'intercept',0);
        %if sum((X(:,ib)-A*raw.slope(:)).^2)<sum((X(:,ib)-A*B(ib,:)').^2)
        B(ib,:) = raw.slope(:)';
      end


    else
      B = (A\X)';
    end

    if nonnegativity
      if any(sum(abs(B),2)==0);
        FeasibilityProblems=1;
        B = .01*B+.99*Bold;
      else
        FeasibilityProblems=0;
      end
    end
    if any(isnan(B(:)))
      B = Bold;
    end

    % Check convergence
    if ~iterate_to_conv
      converged = 1;
    else
      if sum((B(:)-Bold(:)).^2)/sum(Bold(:).^2)>1e-6 & it<maxiter
        converged =0;
      else
        converged=1;
      end
    end

    %     if isstruct(ridge)
    %       if ridge.weight
    %         disp('RIDGE')
    %         B = nm(B);
    %       end
    %     end

  end

  if any(~isfinite(B(:)))
    %  if strcmp(lower(options.display),'on')
    warning('EVRI:RegresconstrInfParm','The algorithm encountered problems in fitting the model (infinite parameters) and some parameters have been reassigned appropriate values')
    %  end
    B(find(~isfinite(B)))=rand(size(find(~isfinite(B))));
  end

  nrmB = norm(B);
  if nrmB~=0 & any(sum(abs(B))/nrmB<eps*100)
    %  if strcmp(lower(options.display),'on')
    % warning('EVRI:RegresconstrZeroLoads','The algorithm encountered problems in fitting the model (almost zero loadings) and some parameters have been reassigned appropriate values')
    %  end
    jj=find(abs(sum(B))/norm(B)<eps*100);
    B(:,jj)=rand(size(B,1),length(jj));
  end


  %     POSTPROCESS
  if size(leftprod,1)==Jold&Jold>1;
    B = leftprod*B;
  end

  if size(rightprod,2)==Fold&Fold>1;
    B = B*rightprod;
  end



end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%  UTITLITY FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function B=unimodal(X,Y,Bold,nonnegativity)

% Solves the problem min|Y-XB'| subject to the columns of
% B are unimodal and nonnegative. The algorithm is iterative
% If an estimate of B (Bold) is given only one iteration is given, hence
% the solution is only improving not least squares
% If Bold is not given the least squares solution is estimated
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

if nargin>2
  B=Bold;
  F=size(B,2);
  for f=1:F
    y=Y-X(:,[1:f-1 f+1:F])*B(:,[1:f-1 f+1:F])';
    beta=pinv(X(:,f))*y;
    B(:,f)=ulsr(beta',nonnegativity);
  end
else
  F=size(X,2);
  maxit=10;

  B=randn(size(Y,2),F);
  Bold=2*B;
  it=0;
  while norm(Bold-B)/norm(B)>1e-5&it<maxit
    Bold=B;
    it=it+1;
    for f=1:F
      y=Y-X(:,[1:f-1 f+1:F])*B(:,[1:f-1 f+1:F])';
      beta=pinv(X(:,f))*y;
      B(:,f)=ulsr(beta',nonnegativity);
    end
  end
  %if it==maxit,disp([' UNIMODAL did not converge in ',num2str(maxit),' iterations']);end
end




function B=column_nonneg(X,Y,Bold,nonnegativity,slack)

% Solves the problem min|Y-XB'| subject to the columns of
% B are nonnegative. The algorithm is iterative
% If an estimate of B (Bold) is given only one iteration is given, hence
% the solution is only improving not least squares
% If Bold is not given the least squares solution is estimated
%

if nargin>2
  B=Bold;
  F=size(B,2);
  for f=1:F
    y=Y-X(:,[1:f-1 f+1:F])*B(:,[1:f-1 f+1:F])';
    beta=pinv(X(:,f))*y;
    beta(find(beta<slack))=slack;
    B(:,f)=beta(:);
  end
else
  F=size(X,2);
  maxit=10;

  B=randn(size(Y,2),F);
  Bold=2*B;
  it=0;
  while norm(Bold-B)/norm(B)>1e-5&it<maxit
    Bold=B;
    it=it+1;
    for f=1:F
      y=Y-X(:,[1:f-1 f+1:F])*B(:,[1:f-1 f+1:F])';
      beta=pinv(X(:,f))*y;
      beta(find(beta<slack))=slack;
      B(:,f)=beta(:);
    end
  end
  %if it==maxit,disp([' NONNEG did not converge in ',num2str(maxit),' iterations']);end
end

function B=column_nonneg_special(X,Y,Bold,howmany)

  B=Bold;
  F=size(B,2);
  for f=1:F
    y=Y-X(:,[1:f-1 f+1:F])*B(:,[1:f-1 f+1:F])';
    beta=pinv(X(:,f))*y;
    if f<=howmany % Impose nonneg for first 'howmany' columns
        beta(beta<0)=0;
    end
    B(:,f)=beta(:);
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

All=zeros(I,I+2);All(1:I,3:I+2)=B1;
All(1:I,1:I)=All(1:I,1:I)+BI;
All=All(:,2:I+1);Allmin=All;Allmax=All;
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
% Copyright 1997
%
% Rasmus Bro
% Royal Veterinary & Agricultural University
% Denmark
% rb@kvl.dk

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

function [B,rate]=exponential2(X,Y,Bold,nonnegativity,iter,timeaxis,aux)

if nargin>3
  B=Bold;
  F=size(B,2);
else
  F=size(X,2);
  B=(pinv(X'*X)*(X'*Y))';
  Bold=B;
end
if nargin>5
  if isstruct(aux)
    if isfield(aux,'rates')
      rates = aux.rates;
      %      constants = aux.constants;
    end
  end
end

if ~exist('rates')==1|isempty(aux.rates)
  if isempty(timeaxis)|length(timeaxis)~=size(B,1)
    maxtime = size(B,1);
    timeaxis = [1:maxtime];
  else
    maxtime = timeaxis(end);
  end
  rates = -rand(F,1)/maxtime;
  %  constants = rand(F,1);
end
if isempty(timeaxis)|length(timeaxis)~=size(B,1)
  maxtime = size(B,1);
  timeaxis = [1:maxtime];
end

%o=optimset('Diagnostics','off','Display','off','levenbergmarquardt','on');
o=optimset('Diagnostics','off','Display','off','FunValCheck','off');
o=optimset('TolX',1e-8);
o=optimset('tolfun',1e-8);
c = rates(:)';


%[answer,FVAL,EXITFLAG,ou]=fminsearch(inline('sum(sum((Y-X*((exp(time(:)*c(1,:))))'' ).^2))','c','Y','X','time'),c,o,Y,X,timeaxis);
b = Bold;
for f=1:F
  bold = b;
  y = Y-X(:,[1:f-1 f+1:F])*b(:,[1:f-1 f+1:F])';
  x = X(:,f);
  [answer,FVAL,EXITFLAG,ou]=fminsearch(inline('sum(sum((Y-  X*((exp(time(:)*c)))'' ).^2))','c','Y','X','time'),c(f),o,y,x,timeaxis);
  b(:,f) = exp(timeaxis(:)*answer);
  if (sum(sum((Y-X*b').^2))<sum(sum((Y-X*bold').^2)))
    rate(f) = answer;
  else
    rate(f) = c(f);
    b(:,f)=bold(:,f);
  end
end
B = exp(timeaxis(:)*rate(:)');

if (sum(sum((Y-X*B').^2))>sum(sum((Y-X*Bold').^2))) & iter >1
  B = .1*B+.9*Bold;
  %  disp('OOOPS')
  %   c = rates(:)';
  %   c = c.*(randn(size(c))+1);
  %   answer=fminsearch(inline('sum(sum((Y-  X*((exp(time(:)*c(1,:))))'' ).^2)+sum(c.^2))','c','Y','X','time'),c,o,Y,X,timeaxis);
  %   c = answer;
  %   B = exp(timeaxis(:)*c(1,:));
  %   if sum(sum((Y-X*B').^2))>sum(sum((Y-X*Bold').^2))
  %     B = Bold;
  %     disp('øv')
  %   else
  %     rate = answer(1,:);
  %     disp('jinoon')
  %   end
  % else
  %   disp('OKOKOK')
end


function [B,rate]=exponential(X,Y,Bold,nonnegativity,iter,timeaxis,aux)
% NOT USED CURRENTLY. THE ABOVE IS USED INSTEAD
% Doesn't work anymore because it uses constants and these have been
% removed now.

%EXPONENTIAL FITTING OF LOADINGS
%
%
% Solves the problem min|Y-XB'| subject to the columns of
% B are exponential. The form of each column of B (B(:,j)) is
%
% B(:,j) = exp([1:I]'*rates(j))
%
% Where rates(j) is the
% exponential time constant. Note that the 'time-scale' is always
% 1 to I where I is the dimension of the column of B.
%
%
% Copyright 2001
%
% Rasmus Bro
% Royal Veterinary & Agricultural University
% Denmark
% rb@kvl.dk
if nargin>3
  B=Bold;
  F=size(B,2);
else
  F=size(X,2);
  B=(pinv(X'*X)*(X'*Y))';
  Bold=B;
end
if nargin>5
  rates = aux;
end
if ~exist('rates')==1|isempty(rates)
  if isempty(timeaxis)
    maxtime = size(B,1);
    timeaxis = [1:maxtime];
  else
    maxtime = timeaxis(end);
  end
  rates = rand(F,1)/maxtime;
else
  rates = rand(F,1)/size(B,1);
end

maxit=25;
it=0;


while (norm(Bold-B)/norm(B)>1e-5&it<maxit)|it==0
  Bold=B;
  it=it+1;
  for f=1:F
    y=Y-X(:,[1:f-1 f+1:F])*B(:,[1:f-1 f+1:F])';
    beta=pinv(X(:,f))*y;
    [B(:,f),rate(f)]=fit_one_exp(beta(:),nonnegativity,rates(f),timeaxis);
    if iter>3&sum(sum((Y-X*B').^2)) > sum(sum((Y-X*Bold').^2)) % Old guess better hence retain
      % Check that old is actually exponential and not just better because it is an initial values that was not set to be exponential
      cc=corrcoef([[1:size(B,1)]' log(B(:,f))]);
      if abs(cc(2,1)) >  .99999
        B(:,f) = Bold(:,f);
      end
    else
      rates(f)=rate(f);
    end
  end
end

rate = rates;


function [bexp,rate] = fit_one_exp(b,nonnegativity,rate,time)

% Estimates in an LS sense bexp = c*exp(k*[1:I])
% where I is the length of b.
%
% Nonneg will make c > 0;

o=optimset('Diagnostics','off','Display','off');

bb=abs(b+eps*norm(b));
if isempty(time)
  time = [1:length(bb)]';
end
time = time(:);

answer=fminsearch(inline('sum((b-exp(c(1)*time)).^2)','c','b','time'),rate,o,bb,time);
rate  = answer(1);
bexp  = exp(rate*time);
%disp(['SSQ1 = ',num2str(sum(bb(:)-bexp(:)).^2)])
answer=fminsearch(inline('sum((b-exp(c(1)*time)).^2)','c','b','time'),rand(1),o,bb,time);
rate2  = answer(1);
bexp2  = exp(rate2*time);

if sum((bb(:)-bexp(:)).^2)>sum((bb(:)-bexp2(:)).^2)
  rate = rate2;
  bexp = bexp2;
end

function [x,w] = CrossProdFastNnls(XtX,Xty,tol)
%NNLS	Non-negative least-squares.
%	b = CrossProdFastNnls(XtX,Xty) returns the vector b that solves X*b = y
%	in a least squares sense, subject to b >= 0, given the inputs
%       XtX = X'*X and Xty = X'*y.
%
%	[b,w] = fastnnls(XtX,Xty) also returns dual vector w where
%	w(i) < 0 where b(i) = 0 and w(i) = 0 where b(i) > 0.
%	L. Shure 5-8-87 Copyright (c) 1984-94 by The MathWorks, Inc.
%
%  Revised by:
%	Copyright
%	Rasmus Bro 1995
%	Denmark
%	E-mail rb@kvl.dk
%  According to Bro & de Jong, J. Chemom, 1997, 11, 393-401

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
    P(ij)=zeros(1,length(ij));
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

function B = orthregress(X,A);

if size(X,2)<size(A,2) % Orthogonal not possible
  B = (A\X)';
else
  ZtX = A'*X;
  B=(((ZtX*ZtX')^(-.5))*ZtX)';
end

function [B,flag] = orthnormregress(X,A,B);

Bold = 2*B+1;
it = 0;
while sum(sum((Bold-B).^2))/sum(sum((Bold).^2))>1e-5 & it < 10
  it = it+1;
  Bold = B;
  Z = [];
  for fac = 1:size(A,2)
    Z = [Z kron(B(:,fac)/norm(B(:,fac)),A(:,fac))];
  end
  Scales = pinv(Z'*Z)*(Z'*X(:));
  ZtX = (A*diag(Scales))'*X;
  B=((ZtX*ZtX')^(-.5))*ZtX;
  B = B'*diag(Scales);
end
if it>9
  flag = 1;
else
  flag = 0;
end



function S = plae(X,A,Sold,nonnegativity);

% Least Absolute Error ``pseudoinverse'':
% iteratively solves the problem of min wrt S sum(sum(abs(X-A*S)))
% monotonically convergent in terms of LAE,
% but not guaranteed in general to find globally opt soln.
% ALL parameters are real-valued
% uses wmf.m
% complexity per complete iteration is order of F*N*I*logI
% where S is FxN, and A is IxF
% Assumes A is tall and full rank
% N. Sidiropoulos, April 12, 2000
% RB 2005, Added nonnegativity

[I,F]=size(A);
[I,N]=size(X);

if nargin<3
  S = pinv(A)*X; % use LS-solution as good initialization
else
  S = Sold;
end
LAE = sum(sum(abs(X-A*S)));
SMALLNUMBER = eps*10;
MAXNUMITER = 30;

%fprintf('LAE = %12.10f\n',LAE);
LAEold = 2*LAE;
LAEinit = LAE;
it     = 0;

while abs((LAE-LAEold)/LAEold) > SMALLNUMBER & it < MAXNUMITER & LAE > 10*eps
  it=it+1;
  LAEold=LAE;

  % update elements of S one by one:

  for f=1:F,
    Y = X - (A*S - A(:,f)*S(f,:));
    for n=1:N,
      S(f,n) = wmf(Y(:,n)./A(:,f),A(:,f));
    end
    if nonnegativity
      S(f,find(S(f,:)<0)) = 0;
    end
  end

  % compute new LAE:

  LAE = sum(sum(abs(X-A*S)));
  %fprintf('LAE = %12.10f\n',LAE);

end % while loop

function a = wmf(x,w);

% weighted median filter with non-negative real weights
% input (vector x) and output (scalar a) are both real-valued
% minimize sum_i abs(w(i)) * abs(x(i) - a)
% N. Sidiropoulos, April 12, 2000
% Ref: cf. e.g., Yang et al, IEEE Trans. Signal Proc. 43(3):591-592, Mar. 1995
% Complexity is NlogN, N=length(x), due to the sorting operation

[s,p] = sort(x);
absw = abs(w);
sw = absw(p);
t = 0.5*sum(absw);
N=length(x);
psum=0;
for n=N:-1:1,
  psum = psum + sw(n);
  if (psum >= t)
    a = s(n);
    break;
  end
end


function [nonnegativity,nonnegativityalgorithm,unimodality,exponential,orthogonal,orthonormal,...
  smoothness,fixed,equality,ridge,leftprod,rightprod,lae,lts,iterate_to_conv,timeaxis,funcon]=getopt(options);

if isfield(options,'nonnegativity'),           nonnegativity = options.nonnegativity;else,nonnegativity = 0;end
if isfield(options,'nonnegativityalgorithm'),  nonnegativityalgorithm = options.nonnegativityalgorithm;else,nonnegativitynonnegativityalgorithm = 0;end
if isfield(options,'nonnegativityslack'),      nonnegativityslack = options.nonnegativityslack;else,nonnegativitynonnegativityslack = 0;end
if isfield(options,'unimodality'),             unimodality = options.unimodality;      else,unimodality = 0;end
if isfield(options,'exponential'),             exponential = options.exponential;      else,exponential = 0;end
if isfield(options,'orthogonal'),              orthogonal = options.orthogonal;else,orthogonal = 0;end
if isfield(options,'orthonormal'),             orthonormal = options.orthonormal;else,orthonormal = 0;end
if isfield(options,'smoothness'),              smoothness = options.smoothness;else,smoothness = 0;end
if isfield(options,'fixed'),                   fixed = options.fixed;else,fixed = 0;end
if isfield(options,'ridge'),                   ridge = options.ridge;else,ridge = 0;end
if isfield(options,'equality'),                equality = options.equality;else,equality = 0;end
if isfield(options,'leftprod') ,               leftprod = options.leftprod;else,leftprod = 0;end
if isfield(options,'rightprod') ,              rightprod = options.rightprod;else,rightprod = 0;end
if isfield(options,'lae') ,                    lae = options.lae;else,lae = 0;end
if isfield(options,'lts') ,                    lts = options.lts;else,lts = 0;end
if isfield(options,'iterate_to_conv'),         iterate_to_conv = options.iterate_to_conv;else,iterate_to_conv = 0;end
if isfield(options,'timeaxis'),                timeaxis = options.timeaxis;else,timeaxis = [];end
if isfield(options,'funcon'),                  funcon = options.funcon;else,funcon = [];end

function options = setdefaults()

options.nonnegativity            = 0;
options.nonnegativityalgorithm   = 0;
options.nonnegativityslack       = 0;
options.unimodality              = 0;
options.exponential              = 0;
options.orthogonal               = 0;
options.orthonormal              = 0;

options.smoothness.weight        = 0;
options.smoothness.readme        = 'Set the value of weight to 1 for high smoothness. The closer to zero, the less smoothness';

options.fixed.position           = 0;
options.fixed.value              = 0;
options.fixed.weight             = 0;
options.fixed.readme             = 'Example. First mode, A, is 5x3 and you want A(1,1) to be 2 and A(5,3) to 4. Let P = zeros(5,3);P(1,1)=1;P(5,3)=1;Set fixed.position = P; Let Af = zeros(5,3);Af(1,1) = 2;A(5,3) = 4; Set fixed.value = Af; Finally set fixed.weight = 1 to enforce the constraint.';

options.ridge.weight             = 0;
options.ridge.readme             = 'Weight must be >0. The closer to 1, the higher the ridge. Ridging is useful when a problem is difficult to fit.';

options.equality.G               = 0;
options.equality.H               = 0;
options.equality.weight          = 0;
options.equality.readme          = 'Imposes that loading B satisfies equality.G*B'' = equality.H. Setting the weight to 1, the constraint is imposed exact. Between 0 and 1, the constraint is imposed softly';

options.leftprod                 = 0;
options.rightprod                = 0;

options.lae                      = 0;
options.lts                      = 0;

options.iterate_to_conv          = 0;
options.timeaxis                 = [];
options.funcon                   = [];

options.definitions              = @optiondefs;


options.description              = ...
  [' ',sprintf('\n'),...
  'POSSIBLE CONSTRAINTS',sprintf('\n'),...
  'Nonnegativity             : Set to one to impose nonnegativity of the loading matrix',sprintf('\n'),...
  'Nonnegativityalgorithm    : Set to 0 for default (LS) update of each mode, 1 for LS (column update) and 2, non-LS fast update (negative values forced to zero',sprintf('\n'),...
  'Nonnegativityslack        : Lower limit for parameters in nonnegativityalgorithm 5',sprintf('\n'),...
  'Unimodality               : Set to one to have the columns unimodal (one local maximum)',sprintf('\n'),...
  'Orthogonal                : Set to one to have the loading B satisfy B''*B diagonal',sprintf('\n'),...
  'Orthonormal               : Set to one to have the loading B satisfy B''*B identity',sprintf('\n'),...
  'Exponential               : Set to one to have columns exponential',sprintf('\n'),...
  'Smoothness                : Impose smoothness of columns using B-spline bases',sprintf('\n'),...
  'Fixed                     : Fix certain elements to specified values (e.g. spectra, concentrations etc,)',sprintf('\n'),...
  'Ridge                     : Add a ridging in the regression step to speed up convergence',sprintf('\n'),...
  'Equality                  : In finding B solving ||X-A*B''|| have B satisfy C*B = D (e.g. useful for imposing closure)',sprintf('\n'),...
  'Leftprod                  : Given matrix C, let B be of the form (C*D). Hence only D is computed',sprintf('\n'),...
  'Rightprod                 : Given matrix E, let B be of the form F*E. Hence only E is computed',sprintf('\n'),...
  'LAE                       : Robust fit using Least Absolute Deviations',sprintf('\n'),...
  'LTS                       : Robust fit using Least Trimmed Squares',sprintf('\n'),...
  'Iterate to convergence    : If set to 1, the least squares solution is found even if iterations are needed. Otherwise, the current estimate is only improved',sprintf('\n'),...
  'Timeaxis                  : Optional input for exponential constraints, to ensure that time constants are given on correct time-scale.',sprintf('\n'),...
  'funcon                    : For imposing functional constraints. Overrules all other constraints',sprintf('\n'),...
  ' '];

function optionssetting = optionsoverview(options)

constrainedmodes     = [];
freetoscalemodes     = [];
freetonormalizemodes = [];
fixedmodes           = 0;
for i=1:length(options)
  if options{i}.nonnegativity||options{i}.unimodality||options{i}.exponential||options{i}.ridge.weight||options{i}.orthogonal||options{i}.orthonormal||options{i}.smoothness.weight||any(options{i}.fixed.position(:))||options{i}.equality.weight||length(options{i}.funcon)==3
    constrainedmodes(i)=1;
  else
    constrainedmodes(i)=0;
  end

  if any(options{i}.fixed.position(:))||options{i}.fixed.weight||options{i}.equality.weight||options{i}.exponential|length(options{i}.funcon)==3
    freetoscalemodes(i)=0;
  else
    freetoscalemodes(i)=1;
  end

  % Set this whenever you don't want the components to be permuted during
  % the iterations
  if any(options{i}.fixed.position(:))|options{i}.fixed.weight|options{i}.equality.weight|length(options{i}.funcon)==3
    fixedmodes = 1;
  end

  if options{i}.orthogonal|any(options{i}.fixed.position(:))|options{i}.fixed.weight|options{i}.equality.weight|options{i}.exponential|length(options{i}.funcon)==3
    freetonormalizemodes(i)=0;
  else
    freetonormalizemodes(i)=1;
  end
end

optionssetting.constrainedmodes     = constrainedmodes;
optionssetting.freetoscalemodes     = freetoscalemodes;
optionssetting.freetonormalizemodes = freetonormalizemodes;
optionssetting.fixedmodes           = fixedmodes;

function txt = maketxt(options);

txt = ' ';
none=1;
try, if options.nonnegativity,               txt = [txt 'Nonnegativity/'];none=0;end, end
try, if options.unimodality,                 txt = [txt 'Unimodality/'];none=0;end,end
try, if options.exponential,                 txt = [txt 'Exponential/'];none=0;end,end
try, if options.orthogonal,                  txt = [txt 'Orthogonal/'];none=0;end,end
try, if options.orthonormal,                 txt = [txt 'Orthonormal/'];none=0;end,end
try, if options.smoothness.weight,           txt = [txt 'Smoothness/'];none=0;end,end
try, if options.ridge.weight,                txt = [txt 'Ridging/'];none=0;end,end
try, if any(options.fixed.position(:)),      txt = [txt 'Fixed elements/'];none=0;end,end
try, if options.fixed.weight       ,         txt = [txt 'Fixed elements/'];none=0;end,end
try, if options.equality.weight,             txt = [txt 'Equality/'];none=0;end,end
try, if max(size(options.leftprod))>1        txt = [txt 'Left product given/'];none=0;end,end
try, if options.lae                          txt = [txt 'Least Absolute fit/'];none=0;end,end
try, if options.lts                          txt = [txt 'Least Trimmed Squares/'];none=0;end,end
try, if max(size(options.rightprod))>1       txt = [txt 'Right product given/'];none=0;end,end
try, if max(size(options.timeaxis))>1        txt = [txt 'Time axis given/'];end,end
try, if size(options.funcon,2)==3            txt = [' Functional constraint imposed/'];none=0;end,end
if none
  txt = [txt 'Unconstrained/'];
end
if length(txt)>1
  txt = txt(:,1:end-1);
end


function  [X,info,perf] = smarquardt(fun,par, x0, opts, B0)
%SMarquardt  Secant version of Marquardt's method for least squares.
%  Find  xm = argmin{F(x)} , where  x = [x_1, ..., x_n]  and
%  F(x) = .5 * sum(f_i(x)^2) .
%  The functions  f_i(x) (i=1,...,m)  must be given by a MATLAB
%  function with declaration
%            function  f = fun(x, par)
%  par  can e.g. be an array with coordinates of data points,
%  or it may be dummy.
%
%  Call
%      [X, info {,perf}] = SMarquardt(fun,par, x0, opts {,B0})
%
%  Input parameters
%  fun  :  String with the name of the function.
%  par  :  Parameters of the function.  May be empty.
%  x0   :  Starting guess for  x .
%  opts :  Vector with five elements:
%          opts(1) used in starting guess for Marquardt parameter:
%              mu = opts(1) * max(A0(i,i))  with  A0 = B'*B ,
%          where  B  is the initial approximation to the Jacobian.
%          opts(2:4) used in stopping criteria
%              ||B'*f||inf <= opts(2)                   or
%              ||dx||2 <= opts(3)*(opts(3) + ||x||2)    or
%              no. of iteration steps exceeds  opts(4) .
%          opts(5) = Step used in difference approximation to the
%              Jacobian.  Not used if  B0  is present.
%  B0   :  (optional).  If given, then initial approximation to J.
%          If  B0 = [], then it is replaced by  eye(m,n) .
%
%  Output parameters
%  X    :  If  perf  is present, then array, holding the iterates
%          columnwise.  Otherwise, computed solution vector.
%  info :  Performance information, vector with 8 elements:
%          info(1:4) = final values of
%              [F(x)  ||F'||inf  ||dx||2  mu/max(A(i,i))] ,
%            where  A = B'* B .
%          info(5) = no. of iteration steps
%          info(6) = 1 :  Stopped by small gradient
%                    2 :  Stopped by small x-step
%                    3 :  Stopped by  kmax
%                    4 :  Problems, indicated by printout
%          info(7) = no. of function evaluations
%          info(8) = no. of difference approximations to the Jacobian
%  perf :  (optional). If present, then array, holding
%            perf(1,:) = values of  F(x)
%            perf(2,:) = values of  || F'(x) ||inf
%            perf(3,:) = mu-values.

%  Hans Bruun Nielsen,  IMM, DTU.  99.06.10 / 00.09.04

%  Check function call
nin = nargin;
[xb m n fb] = check(fun,par,x0,opts,nin);   fcl = 1;
%  Initialize
if  nin > 4
  reappr = 0;  sB = size(B0);
  if      sum(sB) == 0,  B = eye(m,n);
  elseif  any(sB ~= [m n])
    error('Dimension of B0 do not match  f  and  x')
  else,   B = B0; end
else
  B = Dapprox(fun,par,xb,fb,opts(5));
  reappr = 1;
  fcl = fcl + n;
end
mu = opts(1) * max(sum(B .* B));
Fb = (fb'*fb)/2;
kmax = opts(4);
Trace = nargout > 2;
if  Trace,
  X = zeros(n,kmax+1);
  perf = zeros(3,kmax+1);
end
k = 0;
nu = 2;
stop = 0;
K = max(10,n);
updB = 0;
updx = 1;  % updx changed 00.09.04

while  ~stop
  if  reappr & ((updx & nu > 16) | (updB == K))
    % Recompute difference approximation
    B = Dapprox(fun,par,xb,fb,opts(5));
    reappr = reappr + 1;   fcl = fcl + n;
    nu = 2;   updB = 0;   updx = 0;
  end
  g = B'*fb;    ng = norm(g,inf);   k = k + 1;
  if  Trace,  X(:,k) = xb;   perf(:,k) = [Fb ng mu]'; end
  if  ng <= opts(2),  stop = 1;
  else    %  Compute Marquardt step
    h = (B'*B + mu*eye(n))\(-g);
    nh = norm(h);   nx = opts(3) + norm(xb);
    if      nh <= opts(3)*nx,  stop = 2;
    elseif  nh >= nx/eps
      stop = 4;
      disp('Marquardt matrix is (almost) singular')
    end
  end
  if  ~stop
    xnew = xb + h;    h = xnew - xb;
    fn = feval(fun, xnew,par);   fcl = fcl + 1;
    Fn = (fn'*fn)/2;
    if  updx | (Fn < Fb)    % Update  B
      B = B + ((fn - fb - B*h)/(h'*h)) * h';
      updB = updB + 1;
    end
    %  Update  x  and  mu
    if  Fn < Fb
      dL = .5*(h'*(mu*h - g));   rho = max(0, (Fb - Fn)/dL);
      mu = mu * max(1/3, (1 - (2*rho - 1)^7));   nu = 2;
      xb = xnew;   Fb = Fn;   fb = fn;   updx = 1;
    else
      mu = mu*nu;  nu = 2*nu;
    end
    if  k > kmax,  stop = 3; end
  end
end
%  Set return values
if  Trace
  X = X(:,1:k);   perf = perf(:,1:k);
else,  X = xb;  end
try % Rasmus Bro added try because an error sometimes  occur because nh is not known
  info = [Fb  ng  nh  mu/max(sum(B .* B))  k-1  stop  fcl  reappr];
end
% ==========  auxiliary functions  =================================




function  [x,m,n, f] = check(fun,par,x0,opts,nin)
%  Check function call
sx = size(x0);   n = max(sx);
if  (min(sx) > 1)
  error('x0  should be a vector'), end
x = x0(:);   f = feval(fun,x,par);
sf = size(f);
if  sf(2) ~= 1
  error('f  must be a column vector'), end
m = sf(1);
%  Thresholds
if  nin > 4,  nopts = 4;  else,  nopts = 5; end
if  length(opts) < nopts
  tx = sprintf('opts  must have %g elements',nopts);
  error(tx), end
if  length(find(opts(1:nopts) <= 0))
  error('The elements in  opts  must be strictly positive'), end

function  B = Dapprox(fun,par,x,f,delta)
%  Difference approximation to Jacobian
n = length(x);   B = zeros(length(f),n);
for  j = 1 : n
  z = x;  z(j) = x(j) + delta;   d = z(j) - x(j);
  B(:,j) = (feval(fun,z,par) - f)/d;
end


% function [b,xi] = fastnnls2(x,y,tol,b,xi)
% %FASTNNLS Fast non-negative least squares
% %NOTE: this routine is NOT called internally anymore. It remains here for
% %diagnostic purposes ONLY and is now OUT OF DATE.
%
% if nargin == 0; x = 'io'; end
% varargin{1} = x;
% if ischar(varargin{1});
%   options = [];
%   if nargout==0; evriio(mfilename,varargin{1},options); else; b = evriio(mfilename,varargin{1},options); end
%   return;
% end
%
% [m,n] = size(x);
% if (nargin < 3 | tol == 0)
%   tol = max(size(x))*norm(x,1)*eps;
% end
% if nargin < 4
%   b = zeros(n,size(y,2));
% end
% if size(b,2)==1 & size(y,2)>1;  %is b a column vector by y a matrix?
%   b(:,2:size(y,2)) = b(:,1);    %copy to every column to match y.
% end
%
% if nargin<5;
%   %initialize inverse cache
%   xi = struct([]);
% end
%
% %loop across y columns
% y_all = y;
% b_all = b;
% for col = 1:size(y,2);
%
%   y = y_all(:,col);
%   b = b_all(:,col);
%
%   p    = (b>0)';
%   r    = ~p;
%   b(r) = 0;
%
%   [sp,xi] = proj(x,xi,p,y);
%   b(p) = sp;
%   while min(sp) < 0
%     b(b<0) = 0;
%     p = (b>0)';
%     r = ~p;
%     [sp,xi] = proj(x,xi,p,y);
%     b(p) = sp;
%   end
%
%   w = x'*(y-x*b);
%   [wmax,ind] = max(w);
%   flag = 0;
%   inloop = 0;
%   while (wmax > tol & any(r))
%     p(ind) = 1;
%     r(ind) = 0;
%     [sp,xi] = proj(x,xi,p,y);
%     while (min(sp) < 0) & any(p)
%       tsp    = zeros(n,1);
%       tsp(p) = sp;
%       fb     = (b~=0);
%       nrm    = (b(fb)-tsp(fb));
%       nrm(nrm==0) = inf;
%       rat    = b(fb)./nrm;
%       alpha  = min(rat(rat>0));
%       alpha  = min([alpha 1]);      %limit to 1
%       b = b + alpha*(tsp-b);
%       p = (b > tol)';
%       r = ~p;
%       [sp,xi] = proj(x,xi,p,y);
%     end
%     b(p) = sp;
%     w = x'*(y-x*b);
%     [wmax,ind] = max(w);
%     if p(ind)
%       wmax = 0;
%     end
%   end
%
%   b_all(:,col) = b;  %store this column's result
%
%   %  drawnow;
%
% end
%
% b = b_all;
%
% %----------------------------
% function [sp,xi] = proj(x,xi,p,y);
%
% sp = x(:,p)\y;



function B = nmf(A,X,Bold);
% Nonnegative matrix factorization

X(find(X(:))<0)=0;

AtX = A'*X;
AtABt = A'*A*Bold';
B = Bold;

B=B.*(AtX'./(AtABt'+eps));


function B = bbase(x, xmin, xmax, nseg, deg)
% Compute a B-spline basis using differences of truncated power functions
% Input
% x: evaluation points;
% xmin: left boundary
% xmax: right boudary
% nseg: number of inter-knot segments between xmin and xmax
% deg: degree of B-splines
% From paper of Eilers in Journal of Chemometrics, 2005

dx = (xmax - xmin) / nseg;
knots = (xmin - deg * dx):dx:(xmax + deg * dx);
m = length(x(:));
n = length(knots);
X = repmat(x(:), 1, n);
T = repmat(knots, m, 1);
P = (X - T) .^ deg .* (X > T);
n = size(P, 2);
D = diff(eye(n), deg + 1) / (gamma(deg + 1) * dx ^ deg);
B = (-1) ^ (deg + 1) * P * D';


%--------------------------
function out = optiondefs()

defs = {
  
%name                     tab                   datatype    valid           userlevel     description
'nonnegativity'           'Constraints'         'boolean'   ''              'intermediate'    'Set to one to impose nonnegativity of the loading matrix.';
'nonnegativityalgorithm'  'Constraints'         'select'    {0 1 2}         'intermediate'    'Set to 0 for default (LS) update of each mode, 1 for LS (column update) 2, non-LS fast update (negative values forced to zero, 3 alternative LS nnls algorithm, and 4, alternative NMF algorithm.';
'nonnegativityslack'      'Constraints'         'double'    ''              'intermediate'    'Slack defines a number different from zero that will be the lower limit in nonnegativity when using algorithm =5';
'unimodality'             'Constraints'         'boolean'   ''              'intermediate'    'Set to one to have the columns unimodal (one local maximum).';
'exponential'             'Constraints'         'boolean'   ''              'intermediate'    'Set to one to have columns exponential.'; 
'orthogonal'              'Constraints'         'boolean'   ''              'intermediate'    'Set to one to have the loading B satisfy B''*B diagonal.'; 
'orthonormal'           	'Constraints'         'boolean'   ''              'intermediate'    'Set to one to have the loading B satisfy B''*B identity.';
'smoothness'              'Constraints'         'struct'    ''              'intermediate'    'Impose smoothness of columns using B-spline bases.';
'smoothness.weight'       'Smoothness Options'  'double'    'float(0:1)'    'intermediate'    'Set the value of weight to 1 for high smoothness. The closer to zero, the less smoothness.';
'fixed'                   'Constraints'         'struct'    ''              'intermediate'    'Fix certain elements to specified values (e.g. spectra, concentrations etc.).';
'fixed.position'          'Fixed Options'       'matrix'    ''              'intermediate'    'Example. First mode, A, is 5x3 and you want A(1,1) to be 2 and A(5,3) to 4. Let P = zeros(5,3);P(1,1)=1;P(5,3)=1;Set fixed.position = P; Let Af = zeros(5,3);Af(1,1) = 2;A(5,3) = 4; Set fixed.value = Af;';
'fixed.value'             'Fixed Options'       'vector'    ''              'intermediate'    'Example. First mode, A, is 5x3 and you want A(1,1) to be 2 and A(5,3) to 4. Let P = zeros(5,3);P(1,1)=1;P(5,3)=1;Set fixed.position = P; Let Af = zeros(5,3);Af(1,1) = 2;A(5,3) = 4; Set fixed.value = Af;';
'fixed.weight'            'Fixed Options'       'double'    'float(0:1)'    'intermediate'    'Example. First mode, A, is 5x3 and you want A(1,1) to be 2 and A(5,3) to 4. Let P = zeros(5,3);P(1,1)=1;P(5,3)=1;Set fixed.position = P; Let Af = zeros(5,3);Af(1,1) = 2;A(5,3) = 4; Set fixed.value = Af;';
'ridge'                   'Constraints'         'struct'    ''              'intermediate'    'Add a ridging in the regression step to speed up convergence.';
'ridge.weight'            'Ridge Options'       'double'    'float(0:1)'    'intermediate'    'Weight must be >0. The closer to 1, the higher the ridge. Ridging is useful when a problem is difficult to fit.';
'equality'                'Constraints'         'matrix'    ''              'intermediate'    'In finding B solving ||X-A*B''|| have B satisfy C*B = D (e.g. useful for imposing closure).';
'equality.G'              'Equality Options'    'matrix'    ''              'intermediate'    'Imposes that loading B satisfies equality.G*B'' = equality.H. Setting the weight to 1, the constraint is imposed exact. Between 0 and 1, the constraint is imposed softly.';
'equality.H'              'Equality Options'    'matrix'    ''              'intermediate'    'Imposes that loading B satisfies equality.G*B'' = equality.H. Setting the weight to 1, the constraint is imposed exact. Between 0 and 1, the constraint is imposed softly.';
'equality.weight'         'Equality Options'    'double'    'float(0:1)'    'intermediate'    'Imposes that loading B satisfies equality.G*B'' = equality.H. Setting the weight to 1, the constraint is imposed exact. Between 0 and 1, the constraint is imposed softly.';
'leftprod'                'Constraints'         'matrix'    ''              'intermediate'    'Given matrix C,boolean let B be of the form (C*D). Hence only D is computed.';
'rightprod'               'Constraints'         'matrix'    ''              'intermediate'    'Given matrix E, let B be of the form F*E. Hence only E is computed.';
'lae'                     'Constraints'         'boolean'   ''              'intermediate'    'Robust fit using Least Absolute Deviations.';
'lts'                     'Constraints'         'boolean'   ''              'intermediate'    'Robust fit using Least Trimmed Squares.';
'iterate_to_conv'         'Constraints'         'boolean'   ''              'intermediate'    'If set to 1, the least squares solution is found even if iterations are needed. Otherwise, the current estimate is only improved.';
'timeaxis'                'Constraints'         'matrix'    ''              'intermediate'    'Optional input for exponential constraints, to ensure that time constants are given on correct time-scale.';
'funcon'                  'Constraints'         'matrix'    ''              'intermediate'    'For imposing functional constraints. Overrules all other constraints.';
};

out = makesubops(defs);

