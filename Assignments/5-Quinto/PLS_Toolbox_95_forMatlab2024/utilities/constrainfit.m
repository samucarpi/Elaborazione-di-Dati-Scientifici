function [A,diagnostics,options]=constrainfit(XB,BtB,Aold,options)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%CONSTRAINFIT finds A minimizing ||X-A*B'|| subject to constraints, given XB and BtB
%I/O: [A,diagnostics]=constrainfit(XB,BtB,Aold,options);
%I/O: [A,diagnostics]=constrainfit(XB,BtB,Aold);  %unconstrained
%
% XB      IxF matrix = X*B
% BtB     FxF matrix = B'*B
% Aold    IxF initial loadings (to be optimized)
% options.type
%         provides quick access to most important settings
%         'unconstrained'   - do unconstrained fit of A
%         'nonnegativity'   - A is all nonnegative
%         'nonneg_comp'     - A is compressed and the decompressed loading should all nonnegative
%         'unimodality'     - A has unimodal columns AND nonnegativity
%         'unimodality_nonon' - A has unimodal columns only - no nonnegativity is imposed
%         'orthogonality'   - A is orthogonal (A'*A = I)
%         'columnorthogonal'- A has orthogonal columns (A'*A = diagonal)
%         'equality'        - columns in A are subject to equality
%                             constraints (see options.equality for necessary
%                             settings)
%         'exponential'     - Columns are mono-exponentials
%         'rightprod'       - A has the form F*D, where D is predefined
%                             (must be set in
%                             options.advanced.linearconstraints.matrix).
%                             if A is constrained as F*D
%                             where D is predefined then columnwise
%                             constraints are applied to the columns of F.
%                             Hence options.columnconstraints must be set
%                             appropriately.
%         'L1 penalty'      - A is estimated using a constraint that |A|<
%                             lambda (options.L1.lambda).
%         'columnwise'      - A has other constraints than the above. These
%                             have to be defined in options (see below).
%
% options provides detailed settings for algorithm
%
%         .columnconstraints = cell vector {a,b,c, ... d}. Each element a, b, etc
%         corresponds to one column of B. The elements are vectors of
%         length equal to the number of constraints imposed. e.g. if
%         a = [4 2]; it means that the first factor should be
%         constrained by nonnegativty and smoothness. Example.
%         A four component-PARAFAC model. In mode three we
%         want to constrain component one and two to be smooth.
%         The third column is to be above -30 and be unimodal. The fourth
%         column is unconstrained. This is defined as follows.
%
%         opt.type = 'columnwise';
%         opt = constrainfit('options');
%         opt.columnconstraints{1}  = 4    ; % Factor 1
%         opt.columnconstraints{2}  = 4    ; % Factor 2
%         opt.columnconstraints{3}  = [2 3]; % Factor 3
%         opt.columnconstraints{4}  = 0    ; % Factor 4
%         opt.inequality.scalar(3) = -30;
%
%         a = 0 : Unconstrained
%         a = 1 : Nonnegativity
%         a = 2 : Unimodality
%         a = 3 : Inequality (every element >= scalar). Scalar has to be in
%                 options.inequality.scalar. This is a vector of size
%                 F, one scalar for each factor
%         a = 4 : Smoothness
%                 - options.smoothness.operator can be used to hold
%                 operator that imposes smoothness (for speeding up).
%                 - options.smoothness.alpha (0<alpha<1). Set to 0 means no
%                 smoothness while setting to 1 means high degree of
%                 smoothness.
%         a = 5 : Fixed elements. The elements that are fixed are defined
%                 in options.fixed.
%                 - options.fixed.values is a matrix same size as loadings
%                 with the actual numbers to be fixed in the correspoding
%                 positions. The remaining positions must be NaN
%                 - options.fixed.weight (0<weight<1). Zero means not imposed
%                 whereas one means completely fixed.
%         a = 6 : Not applicable
%         a = 7 : Approximate unimodality. Set weight in
%                 options.unimodality.weight. weight==1: exact unimodality
%                                             weight==0: no unimodality
%         a = 8 : Normalize the loading vectors to norm one
%         a = 20: Functional constraint. Using simple pre- or userdefined
%                 functions, any functional constraint can be imposed on
%                 individual columns. For example, that one column is
%                 exponential. Functional constraints require that a
%                 function is written that calculates the function for
%                 given parameters (type HELP FITGAUSS for an example). As
%                 an example it will be shown how to set up the use of
%                 fitting the second loading vector as being Gaussian:
%
%                 NumberFactors=3;
%                 options.functional=cell(NumberFactors,1);
%                 ToFix = 2; % This constraint is for the second column
%                 options.functional{ToFix}.functionhandle = @fitgauss;
%                 % Define starting parameters
%                 center = 100;width = 100;height = .1;
%                 options.functional{ToFix}.parameters = [center width height];
%                 options.functional{ToFix}.additional=[]; % no additional input
%
%         When a column has more than one constraint these are generally
%         imposed sequentially starting with the first one in
%         options.columnconstraint. For most constraints, the order of
%         constraints will not be important. Advise is to input constraints
%         with smaller numbers first.
%
%         .functionhandle (for functional constraints)
%
% EXAMPLES
% Unconstrained : [A]=constrainfit(XB,BtB,Aold);
% Nonnegative   : opt = constrainfit('options');opt.type='nonnegativity';
%                 [A]=constrainfit(XB,BtB,Aold,opt);
% Second column unimodal:
%    opt = constrainfit('options');opt.type='columnwise';opt.columnconstraints={0;2;0}; % If three columns
%    [A]=constrainfit(XB,BtB,Aold,opt);
%



% NOTES FOR LATER. ASSUMES Bold is known. Requires operator for smoothness
% calculated elsewhere to be fast
%
% Incorporate check for isa(h, 'function_handle') for functional
% constraints (outside this algorithm to speed it up)
%
% Include the smooth-operator outside so only has to be calculated once
% Check size of options.smoothness.alpha (0<1) outside
%
% Chck number of inequality.scalar is suitable. As many as number of
% components appr. needed
% Chk that columnconstraint is not too short (add zeros)


% INITIAL SETTINGS
if nargin == 0;
    XB = 'io';
end
standardoptions.type = 'unconstrained';
standardoptions.columnconstraints = cell(1,1);
standardoptions.inequality.scalar = 0;
standardoptions.nonnegativity.algorithmforglobalmodel = 0;
standardoptions.orth.scale = [];
standardoptions.smoothness.operator=[];
standardoptions.smoothness.alpha = .5;
standardoptions.fixed.values = [];
standardoptions.fixed.weight = 0;
standardoptions.advanced.linearconstraints.matrix = [];
standardoptions.advanced.linearconstraints.readme = 'If A is IxF, then .matrix must be an SxF matrix D and A is then estimated as G*D. E.g. set the prededfined matrix D = [1 1 0; 0 0 1], then the first and second of the three columns in A will be identical (G*D where G is to be estimated)';
standardoptions.equality.C=[];
standardoptions.equality.d=[];
standardoptions.equality.readme = 'Solves for loading matrix A subject to A(i,:)*C'' = d for all i. Hence if you want closure and have three factors, set C=[1 1 1] and d=1';
standardoptions.compression.base = [];
standardoptions.compression.readme = 'Holds the orthogonal basis used for compressing original data. Used when imposing nonnegativity of the uncompressed data but while fitting the compressed data';
standardoptions.unimodality.weight = 1;
standardoptions.L1.penalty = 1;
standardoptions.functional = cell(1,1);
standardoptions.functional{1}.functionhandle = ' ';
standardoptions.functional{1}.parameters  = [];
standardoptions.functional{1}.additional = ' ';
standardoptions.definitions = @optiondefs;
standardoptions.functionname = 'constrainfit';

%options.functional.options = lmoptimize('options');

if ischar(XB)
    if nargout==0;
        clear varargout;
        % Filter standard options for possible user-defined modifications
        standardoptions = evriio('constrainfit','options',standardoptions);
        evriio(mfilename,XB,standardoptions);
    else
        A = evriio(mfilename,XB,standardoptions);
    end
    return;
end

%handle old-form non-negativity constraint
if isfieldcheck(options,'options.nonnegativity') & ~isstruct(options.nonnegativity)
    options.nonnegativity.algorithmforglobalmodel = options.nonnegativity;
end

% Add missing fields
options = reconopts(options,standardoptions);
if nargin<4
    options = constrainfit('options');
end

% RUN IT
diagnostics = [];
switch lower(options.type)
    case 'unconstrained'
        A = XB*pinv(BtB');
    case 'nonnegativity'
        try
            A = nonnegmethods(XB,BtB,Aold,options.nonnegativity.algorithmforglobalmodel);
            [A,diagnostics.convergence] = chkfeasible(A,Aold);
        catch
            A = Aold;
        end
        case 'nonneg_comp'
        Als = XB*pinv(BtB');
        if isempty(options.compression.base)
            error('No basis given in the "standardoptions.compression.base"');
        else
            U = options.compression.base;
        end
        if size(U,2)~=size(Als,1)
            error('The basis in "standardoptions.compression.base" must have as many columns as rows in the loading matrix');
        end
        % Truncate decompressed loading matrix
        UA = U*Als;
        UA(find(UA<0))=0;
        % Recompress
        A = U'*UA;
        if any(sum(abs(A))<1e-8*max(sum(abs(A))))
            A = .01*A+.99*Als;
        end
    case 'unimodality'
        F = size(BtB,2);
        A = Aold;
        for f=1:F
            btb=BtB(f,f);
            bX=XB(:,f)'-BtB(f,[1:f-1 f+1:F])*A(:,[1:f-1 f+1:F])';
            beta=(pinv(btb)*bX)';
            beta=ulsr(beta,1);
            A(:,f)=beta(:);
        end;
        [A,diagnostics.convergence] = chkfeasible(A,Aold);
    case 'unimodality_nonon'
        F = size(BtB,2);
        A = Aold;
        for f=1:F
            btb=BtB(f,f);
            bX=XB(:,f)'-BtB(f,[1:f-1 f+1:F])*A(:,[1:f-1 f+1:F])';
            beta=(pinv(btb)*bX)';
            beta=ulsr(beta,0);
            A(:,f)=beta(:);
        end
        [A,diagnostics.convergence] = chkfeasible(A,Aold);
    case 'orthogonality'
        A=(((XB'*XB)^(-.5))*XB')';
    case 'columnwise'
        [A,options] = columnwise(XB,BtB,Aold,options);
    case 'equality'
        A = repmat(NaN,size(Aold));
        for i=1:size(Aold,1)
            A(i,:)=lse(BtB,XB(i,:)',options.equality.C,options.equality.d)';
        end
    case 'columnorthogonal'
        [A,diagnostics.convergence,options] = orthnormregress(XB,BtB,Aold,options);
    case 'l1 penalty'
        A = nnsmrew(XB',BtB,Aold,options.L1.penalty);
        if any(sum(A)<eps*100);
            A = .1*A+.9*Aold;
        end
    case  'exponential'
        F = size(BtB,2);
        for f=1:F
            btb=BtB(f,f);
            bX=XB(:,f)'-BtB(f,[1:f-1 f+1:F])*Aold(:,[1:f-1 f+1:F])';
            beta=(pinv(btb)*bX)';
            betaold = beta;
            fun     = 'fitexp';
            opt     = optimset;
            opt     = optimset(options,'Display','off');
            try
                x0      = options.functional{f}.parameters;
            catch
                x0=rand(1,2);
            end
            if isempty(x0);
                x0=rand(1,2);
            end
            try
                additional = options.functional{f}.additional;
            catch
                additional = ' ';
            end
            if isempty(additional)||strcmp(additional,' ')
                additional = beta;
            else
                additional = {beta;additional(:)};
            end
            [x,fval,exitflag,out] = fminsearch(fun,x0,opt,additional);
            options.functional{f}.parameters = x;
            %eval(['[fval,beta] = ',fun,'(x,betaold);']);
            %eval(['[fval0,beta0] = ',fun,'(x0,betaold);'])
            [fval,beta] = feval(fun,x,betaold);
            [fval0,beta0] = feval(fun,x0,betaold);
            
            %[fval-fval0]'
            if fval>fval0
                beta = beta0;
                disp('Functional constraint update didn''t go too well')
            else
                options.functional{f}.parameters = x;
            end
            A(:,f)=beta(:);
        end
    case 'rightprod'
        linearconstraints = options.advanced.linearconstraints; % Save them for later
        Anow = Aold;
        % Linear constraints
        if ~isempty(options.advanced.linearconstraints.matrix) % Then linear constraints A = F*D
            D = linearconstraints.matrix;
            XBnew = XB*D';
            BtBnew = D*BtB*D';
            Aoldnew = Anow*pinv(D);
            newoptions = options;
            newoptions.advanced.linearconstraints.matrix=[];
            newoptions.type = 'columnwise';
            if length(newoptions.columnconstraints)~=size(Aoldnew,2)
                newoptions.columnconstraints = cell(1,size(Aoldnew,2));
                for i=1:size(Aoldnew,2)
                    newoptions.columnconstraints{i}=0;
                end
                warning('EVRI:ConstrainfitColumns',[' Columnwise constraints have not been defined in options.columnconstraints in terms of the ',num2str(size(Aoldnew,2)),' estimated columns of the loadings'])
            end
            % Run with the linear constraints imposed
            [A,diagnostics,newoptions]=constrainfit(XBnew,BtBnew,Aoldnew,newoptions);
            Anow = A*D;
        else
            error('The matrix in constraintsoptions.advanced.linearconstraints.matrix must be defined')
        end
        % Make sure all the constraints are retained
        options = newoptions;
        options.type = 'rightprod';
        options.advanced.linearconstraints = linearconstraints;
        A = Anow;
    case 'dont change'
        A = Aold;
    otherwise
        error(['OPTIONS.TYPE (',options.type,') not recognized in CONSTRAINFIT (check spelling)'])
end



function [A,options] = columnwise(XB,BtB,Aold,options)
if isempty(options.columnconstraints{1})|options.columnconstraints{1}~=30 % Then it's the whole matrix
    F = size(BtB,2);
    options.columnconstraints{1};
    for f=1:F
        btb=BtB(f,f);
        bX=XB(:,f)'-BtB(f,[1:f-1 f+1:F])*Aold(:,[1:f-1 f+1:F])';
        try
            beta=(pinv(btb)*bX)';
        catch
            beta = Aold(:,f);
        end
        constra_now = options.columnconstraints{f};
        for i=1:length(constra_now)
            switch constra_now(i)
                case 0 % Unconstrained
                    
                case 1 % Nonnegativity
                    oldbeta = beta;
                    beta(beta<0)=0;
                    if all(abs(beta)<(eps*100))
                        beta = .5*beta+.5*oldbeta;
                    end
                    
                case 2; % Unimodality
                    beta=ulsr(beta,0);
                    
                case 3 % Inequality
                    scalar = options.inequality.scalar(f);
                    beta(beta<scalar)=scalar;
                    
                case 4 % Smoothness
                    if isempty(options.smoothness.operator)
                        J = length(beta);
                        o=ones(J,1);
                        P=spdiags([-o 3*o -3*o o],[-2:1],J,J);
                        P=full(P(3:J-1,:));
                        PtP=P'*P;
                        alpha = options.smoothness.alpha;
                        weight = (exp(alpha*4)-1); % Ensures that alpha 0=> and that alpha 1=> very high
                        smoother = pinv((1)*eye(J)+weight*PtP);
                        options.smoothness.operator = smoother;
                    else
                        smoother = options.smoothness.operator;
                    end
                    beta = smoother*beta(:);
                    
                case 5 % Fixed elements
                    if options.fixed.weight== -1 % Exactly fixed
                        id = ~isnan(options.fixed.values(:,f));
                        beta(id)=options.fixed.values(id,f);
                    else % Softly fixed. Only need to consider those that 
                         % are fixed. Since columnwise constraints are 
                         % imposed, it is simple to update and numerically 
                         % stable
                        pos = ~isnan(options.fixed.values(:,f));
                        val = options.fixed.values(pos,f);
                        I = eye(length(find(pos)));
                        weight = options.fixed.weight;
                        if any(pos)
                            beta = beta(:);
                            w = max(min(1,options.fixed.weight),0);
                            beta(pos) = pinv([I*(1-w);w*I])*[beta(pos)*(1-w);w*val(:)];
                        end
                    end
                    
                case 6 % Gaussian
                    [b,beta] = fungaussian([rand(1) round(length(beta)/2) rand(1)],beta,[1:length(beta)],ones(size(beta)));
                    
                case 7; % Approximate unimodality acc to Bro & Sidiropoulos 1998
                    beta2=ulsr(beta,0);
                    w = options.unimodality.weight;
                    % As w is between 0,1, we need to redefine it
                    w = w*sum(beta(:));
                    beta = 1/(1+w)*(beta+w*beta2);
                    
                case 8 % normalize
                    beta = beta/norm(beta(:));
                    
                case 20; % Functional columnwise
                    
                    betaold = beta;
                    fun     = options.functional{f}.functionhandle;
                    opt     = optimset;
                    opt     = optimset(options,'Display','off');
                    x0      = options.functional{f}.parameters;
                    additional = options.functional{f}.additional;
                    if isempty(additional)||strcmp(additional,' ')
                        additional = beta;
                    else
                        additional = {beta;additional(:)};
                    end
                    [x,fval,exitflag,out] = fminsearch(fun,x0,opt,additional);
                    options.functional{f}.parameters = x;
                    [fval,beta]=feval(fun,x,betaold);
                    [fval0,beta0]=feval(fun,x0,betaold);
                    %[fval-fval0]'
                    if fval>fval0
                        beta = beta0;
                        disp('Functional constraint update didn''t go too well')
                    else
                        options.functional{f}.parameters = x;
                    end
                otherwise
                    error(' Unrecognized problem in CONSTRAINFIT')
            end
        end
        A(:,f)=beta(:);
    end
else
    error('No no')
    % Functional matrixwise
    options.functional.addparameters{1}={X,A,B};
    of = options.functional;
    fminopt = optimset('display','off','MaxFunEvals',10);
    newparam = fminsearch(of.functionname,of.parameters,fminopt,of.addparameters);
    [out,B] = feval(of.functionname,newparam,of.addparameters);
    options.functional.parameters = newparam;
end



function A = nonnegmethods(XB,BtB,Aold,nonnegativityalgorithm)
A = repmat(NaN,size(Aold));
% Use LS through row-wise
if nonnegativityalgorithm == 0
    kj=1; % Use new version of nnls
    if kj==1
        A = fasternnls(BtB,XB')';
       else
        for k = 1:size(XB,1)
            A(k,:) = CrossProdFastNnls(BtB,XB(k,:)')';
            % B(k,:) = lsqnonneg(A,X(:,k),B(k,:)')';  % Alternative but actually
            % seems slower although it ought to be faster. Maybe bad initial
            % values makes it less good
        end
    end
    % Use column-wise LS updating one column at a time
elseif nonnegativityalgorithm == 1
    F = size(BtB,2);
    for f=1:F
        btb=BtB(f,f);
        bX=XB(:,f)'-BtB(f,[1:f-1 f+1:F])*Aold(:,[1:f-1 f+1:F])';
        beta=(pinv(btb)*bX)';
        beta(beta<0)=0;
        A(:,f)=beta(:);
    end  % Use non-LS setting negative numbers to zero
elseif nonnegativityalgorithm == 2
    A = (pinv(BtB)*XB')';
    A(A<0) = 0;
    % Use alternative algorithm % Nonnegative matrix factorization
elseif nonnegativityalgorithm == 3
    A = nmf(XB',BtB,Aold);
else
    error('nonnegativityalgorithm not defined correctly (0 or 2 allowed. Use options.type=''columnwise'' for columnwise update)')
end


function [B,FeasibilityProblems] = chkfeasible(B,Bold)
if any(sum(abs(B),1)==0); % If a column becomes only zeros the algorithm gets instable, hence the estimate is weighted with the prior estimate. This should circumvent numerical problems during the iterations
    FeasibilityProblems='Some loading columns were all zero and have been partially replaced by prior estimate';
    B = .9*B+.1*Bold;
elseif any(B(:)<0)
    FeasibilityProblems='Negative loadings partially corrected';
    B = .9*B+.1*Bold;
elseif any(isnan(B(:))|isinf(B(:)))
    if any(isnan(B(:)))
        FeasibilityProblems='Some elements turned into NaN';
        B(isnan(B(:)))=rand(size(B(isnan(B(:)))));
    else
        FeasibilityProblems='Some elements turned into Inf';
        B(isinf(B(:)))=rand(size(B(isnan(B(:)))));
    end
else
    FeasibilityProblems='No problems with nonnegativity';
end


function [b,All,MaxML]=ulsr(x,NonNeg)
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
All=All(:,2:I+1);
% Allmin=All;
% Allmax=All;
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
itmax = 3*n;%lowered compared to real version to speed up

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


function [A,flag,options] = orthnormregress(XB,BtB,Aold,options);
A = Aold;
Aold = 2*Aold+1;
it = 0;
F=size(XB,2);
if isempty(options.orth.scale)
    scales = ones(size(BtB,1),1);
else
    scales=options.orth.scale;
end
while sum(sum((Aold-A).^2))/sum(sum((Aold).^2))>1e-5 & it < 10
    it = it+1;
    Aold = A;
    xb = XB*diag(scales);
    A=(((xb'*xb)^(-.5))*xb')';
    for i=1:F
        btb=BtB(i,i);
        bx=XB(:,i)'-BtB(i,[1:i-1 i+1:F])*A(:,[1:i-1 i+1:F])';
        beta=(pinv(btb)*bx)';
        scales(i)=inv(A(:,i)'*A(:,i))*(A(:,i)'*beta);
    end
end
A = A*diag(scales);
options.orth.scale = scales;
if it>9
    flag = 'Orthogonal columns did not converge';
else
    flag = ['Orthogonal columns converged in ',num2str(it),' iterations'];
end


function b=lse(XtX,Xty,C,d);

%LEAST SQUARES REGRESSION SUBJECT TO EQUALITY CONSTRAINTS
%
% Solves min||y-X*b|| subject to C*b = d
%
% I/O  b=lse(XtX,Xty,C,d);
%
% Copyright Rasmus Bro, 2002

Rank=rank(XtX)-rank(C);
if Rank==0;
    Z=zeros(size(XtX,2));
else
    Z=eye(size(C,2))-pinv(C)*C;
end
if sum(sum(abs(d)))==0 % All calculations including d eliminated if d=0
    if Rank>0
        %             b=simpls1(X*Z,y,Rank);
        %             b=b(Rank,:)';
        b=pinv(Z'*XtX*Z)*Xty;
    else
        b=zeros(size(XtX,2),1);
    end
else
    % b=pinv(C)*d+pinv(X*Z)*(y-X*(C\d)); =
    % b=pinv(C)*d+  pinv(X*Z)*y              - pinv(X*Z)*X*(C\d)); =
    b=pinv(C)*d +  pinv(Z'*(XtX)*Z)*(Z'*Xty) - pinv(Z'*(XtX)*Z)*((Z'*XtX)*(C\d));
end


function B = nmf(AtX,AtA,Bold);
% Nonnegative matrix factorization
AtABt = AtA*Bold';
B = Bold;
B=B.*(AtX'./(AtABt'+eps));

function B = nnsmrew(AtX,AtA,B,lambda)
%%
% Non-negative sparse matrix regression
% using element-wise coordinate descent
% Given X, A, find B to
% min ||X-A*B.'||_2^2 + lambda*sum(sum(abs(B)))
%
% Subject to: B(j,f) >= 0 for all j and f
%
% N. Sidiropoulos, August 2009
% nikos@telecom.tuc.gr
% Modified: Speed up by Evrim Acar, October 2011.

F=size(AtX,1);
DontShowOutput = 1;
maxit=100;
convcrit = 1e-6;
showfitafter=1;
it=0;
Oldfit=1e100;
Diff=1e100;
alpha = diag(AtA)';
normXsqr = sum(alpha(:)); % No access to raw X so we just replace with something else as that part of the loss function is constant anyway

while Diff>convcrit && it<maxit
    it=it+1;
    for f=1:F,
        data = AtX(f,:) - AtA(f,:)*B' + alpha(f)*B(:,f)';                     
        data = data-lambda/2;
        id = data>0;
        B(id,f) = data(id)'/alpha(f);
        B(data<=0,f)=0;       
    end
    %fit= normXsqr + sum(AtB(:).^2)      - 2*sum(X(:).*AtB(:)) + lambda*sum(abs(B(:)));
    % Not possible, but do it like this
    fit = normXsqr + sum(diag(B*AtA*B')) - 2*sum(sum(AtX.*B')) + lambda*sum(abs(B(:)));
%    if Oldfit < fit
%         disp(['*** bummer! *** ',num2str(Oldfit-fit)])
%    end
    Diff=abs(Oldfit-fit)/fit;
    Oldfit=fit;

    if ~DontShowOutput
        % Output text
        if rem(it,showfitafter)==0
            disp([' NNSMREW Iterations:', num2str(it),' fit: ',num2str(fit)])
        end
    end

end
for i=1:size(B,2)
    B(:,i)=B(:,i)/max(eps*100,norm(B(:,i)));
end
%--------------------------
function out = optiondefs()

defs = {
    
%name                                   tab                   datatype    valid           userlevel     description
'type'                                  'Constraints'         'select'   {'unconstrained' 'nonnegativity' 'unimodality' 'unimodality_nonon' 'orthogonality' 'columnorthogonal' 'exponential'}       'novice'                '''unconstrained'' - do unconstrained fit of A; ''nonnegativity'' - A is all nonnegative; ''unimodality'' - A has unimodal columns AND nonnegativity; ''orthogonality'' - A is orthogonal (A''*A = I); ''columnorthogonal''- A has orthogonal columns (A''*A = diagonal); ''unimodality_nonon'' - A has unimodal columns only - no nonnegativity is imposed; ''exponential'' - Columns are mono-exponentials ';
%'columnconstraints'                     'Constraints'        ''         ''         'intermediate'    '';
%'inequality.scalar'                     'Constraints'         'double'    'int(1:inf)'    'intermediate'    '';
%'nonnegativity.algorithmforglobalmodel'	'Constraints'         'double'    'int(0:inf)'    'intermediate'    '';
%'orth.scale'                            'Constraints'         'matrix'    ''              'intermediate'    '';
%'smoothness.operator'                   'Constraints'         'matrix'    ''              'intermediate'    '';
%'smoothness.alpha'                      'Constraints'         'double'    'float(0:1)'    'intermediate'    '';
%'fixed.values'                          'Fixed Options'       'vector'    ''              'intermediate'    'Example. First mode, A, is 5x3 and you want A(1,1) to be 2 and A(5,3) to 4. Let P = zeros(5,3);P(1,1)=1;P(5,3)=1;Set fixed.position = P; Let Af = zeros(5,3);Af(1,1) = 2;A(5,3) = 4; Set fixed.value = Af;';
%'fixed.weight'                          'Fixed Options'       'double'    'float(0:1)'    'intermediate'    'Example. First mode, A, is 5x3 and you want A(1,1) to be 2 and A(5,3) to 4. Let P = zeros(5,3);P(1,1)=1;P(5,3)=1;Set fixed.position = P; Let Af = zeros(5,3);Af(1,1) = 2;A(5,3) = 4; Set fixed.value = Af;';
%'advanced.linearconstraints.matrix'     'Constraints'         'matrix'    ''              'intermediate'    '';
%'L1.penalty                             'Constraints'         'double'    'float(0:Inf)'  'intermediate'    '';
%'equality.C'                            'Constraints'         'matrix'    ''              'intermediate'    '';
%'equality.d'                            'Constraints'         'matrix'    ''              'intermediate'    '';
%'unimodality.weight'                    'Constraints'         'double'    'float(0:1)'    'intermediate'    '';
};

out = makesubops(defs);

