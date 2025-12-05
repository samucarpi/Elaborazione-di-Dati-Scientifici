function [c,s,res] = als(x,c0,options)
%ALS Alternating Least Squares computational engine.
%  This function is intended primarily for use as the engine behind
%  other more full featured MCR programs. The only required inputs are x
%  and c0.
%
%  INPUTS:
%        x = the matrix to be decomposed as X = CS, and
%       c0 = a matrix, scalar or cell array value:
%            Matrix (c0): the initial guess for (c) or (s) depending on its size.
%            For X (M by N) then C is (M by K) and S is (K by N) where K is the
%            number of factors that is determined from the size of input (c0).
%            If (c0) is size (M by K) it is the initial guess for (c) (also if M==N).
%            If (c0) is size (K by N) it is the initial guess for (s).
%            Scalar (c0): represents the number of factors and will use the
%            algorithm specified by the initialguessmethod option to choose the
%            given number of items.
%            Cell array (c0): {k mode} where k is the number of factors and
%            mode of the data (1=rows, 2=columns) to select.
%
%  OPTIONAL INPUT:
%   options = structure with the following fields:
%   ----display and plotting----
%     display: [ 'off' | {'on'} ]      governs level of display to command window,
%       plots: [ 'none' | {'final'} ]  governs level of plotting,
%     waitbar: [ 'off' | 'on' | {'auto'} ] governs use of waitbar,
%   ----non-negativity constraints----
%        ccon: [ 'none' | 'reset' | 'fastnnls' | {'fasternnls'}]
%               non-negativity on contributions, (fasternnls = fast true
%               non-negative least-squares solution)
%     cconind: [ ]  For use with ccon='fastnnls' and 'fasternnls' only;
%              optionally indicates which factors or elements should be
%              nonegatively controlled. Can be either a vector indicating
%              which factors should be required to give non-negative
%              concentration results or a logical matrix (same size as c)
%              which indicates which elements should be non-negative.
%              Default (empty) indicates that all elements and factors
%              should be non-negative.
%        scon: [ 'none' | 'reset' | 'fastnnls' | {'fasternnls'}]
%               non-negativity on spectra, (fasternnls = fast true
%               non-negative least-squares solution)
%     sconind: [ ]  Same as cconind above except an indication of which
%              factors or elements of s should be non-negatively
%              controlled. If a logical matrix, must be the same size as s.
%              Used only if scon='fastnnls' or 'fasternnls'
%   ----equality constraints----
%          cc: [ ]  contribution equality constraints, must be a matrix
%              with M rows and up to K columns with NaN where equality
%              constraints are not applied and real value of the constraint
%              where they are applied. If fewer than K columns are
%              supplied, the missing columns will be filled in as
%              unconstrained.
%       ccwts: [inf]  a scalar value or a 1xK vector with elements
%              corresponding to weightings on constraints (0, no
%              constraint, 0<wt<inf imposes constraint "softly", and inf is
%              hard constrained). If a scalar value is passed for ccwts,
%              that value is applied for all K factors.
%          sc: [ ]  spectra equality constraints, must be a matrix with N
%              columns and up to K rows with NaN where equality contraints
%              are not applied and real value of the constraint where they
%              are applied.  If fewer than K rows are supplied, the missing
%              rows will be filled in as unconstrained.
%       scwts: [inf]  weighting for spectral equality constraints (see ccwts)
%    contrast: [ 'contributions' | 'spectra' | 'automatic' | {''} ] governs
%              the constraint to obtain contrast in spectra of
%              contributions/images. This constraint biases the answer
%              towards maximal contrast in spectra ('s') or concentrations
%              ('c') within the feasible bounds of the data. When the
%              assumption of pure variables is appropriate, as with MS
%              data, high contrast in spectra is expected and ('s') should
%              be chosen. When samples have distinct layers, such as with a
%              polymer laminate, high contrast in the contributions is
%              expected and ('c') should be chosen. The option ('a' or 'auto')
%              (automatic) depends on the initial estimate c0, which is
%              given by the user or by the use of initmode in the function
%              MCR. This option results in: ('c') when (c0) is size (K by
%              N) and MCR initmode==1 ('s') when (c0) is size (M by K) and
%              MCR initmode==2 An empty string imposes no constraint.
% contrastweight: [{0.05}]weighting used for contrast constraint. The
%              algorithm makes angles between vectors (spectra or
%              contributions) smaller by adding a portion (contrastweight)
%              to the vectors. For example, for one of the vectora (v1) it
%              would calculate:
%              (1-contrastweight)*v1 + contrastweight*mean(v)
%
%   ----closure constraints----
%     closure: [ ] indicates which factors should be constrained to sum to
%               unit concentration (closure is a constraint where the sum
%               of the columns of C must = 1). This option can be a scalar
%               "true" value to indicate that all components should be
%               constrained by closure, or a logical row vector indicating
%               with a "1" for each component that should be constrained.
%                  e.g. [ 0 1 1 0 0 ] = constrain components 2 and 3 of a
%                  five factor model with closure.
%               Additional rows can be added to constrain different sets of
%               components.
%                  e.g. [ 0 1 1 0 0 ; 0 0 0 1 1 ] = constrain components 2
%                  and 3 with closure and also components 4 and 5
%                  (separately).
%               Note that no checking is done to verify that these sets are
%               not in conflict.
%  closurewts: [ inf ] weighting for closure option. "inf" indicates hard
%               closure constraint. Value of 1 gives closure constraint
%               equal weight as one variable.
%   ----convergence and conditions----
%   condition: [{'none'}| 'norm' ] type of conditioning to perform on
%               S and C before each regression step. 'norm' conditions
%               each spectrum or contribution to its own norm.
%               Conditioning can help stabilize the regression when
%               factors are significantly different in magnitude.
%   normorder: [ {2} ] order of normalization applied to spectra (required
%               to assure convergence). Typical settings are:
%                   1  = normalize to unit area (1-norm)
%                   2  = normalize to unit length (2-norm) {default}
%                  inf = normalize to unit maximum (inf-norm)
%               This normalization is only applied to non-equality
%               constraned components as these are the ones with a
%               multiplicative ambiguity.
%        tolc: [ {1e-5} ]  tolerance on non-negativity for contributions,
%        tols: [ {1e-5} ]  tolerance on non-negativity for spectra,
%       ittol: [ {1e-8} ]  convergence tolerance,
%       itmax: [ {100} ]   maximum number of iterations,
%     timemax: [ {3600} ]  maximum time for iterations,
%    rankfail: [ 'drop' |{'reset'}| 'random' | 'fail' ]  how are rank
%              deficiencies handled:
%                drop   - drop deficient components from model
%                reset  - reset deficient components to initial guess
%                random - replace deficient components with random vector
%                fail   - stop analysis, give error
%   ----automatic initial guess----
%   initialguessmethod: [ 'distslct' | {'exteriorpts'} ] method used to
%                       find initial guess for (c) or (s)
%  initialguessminnorm: [0.03] approximate noise level, points with unit
%                       area smaller than this (as a fraction of the
%                       maximum value in x) are ignored during selection.
%   ----other----
%        sclc: [ ]  contribution scale axis,
%              vector with M elements otherwise 1:M is used,
%        scls: [ ]  spectra scale axis,
%              vector with N elements otherwise 1:N is used,
%  OUTPUTS:
%         c = are the estimated contributions, and
%         s = estimated pure component spectra.
%
%  Notes:
%   * Unconstrained factors have spectra scaled to unit length. This can
%     result in output spectra with different scales.
%
%I/O: [c,s] = als(x,c0,options);
%I/O: als demo
%
%See also: FASTERNNLS, MCR, PARAFAC, PCA

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%9/24/98 nbg (fixed case = 1 to case = 2 on line 337)
%10/22/98 nbg (changed how constraints are handled, and
%  modified call to fastnnls)
%2/99 nbg changed to allow initial estiamte of spectra
%11/00 nbg nnls ==> lsqnonneg
%05/01 nbg changed line 222 ccon=1 and c0 are spectra
%8/02 changed I/O, changed non-neg to reset instead of lsqnonneg
%7/24/03 jms -added missing ; on sc line
%   -added true reset of unrecognized ccon and scon to zero
%   -test for c as initial guess (do s first in that case)
%   -use new fastnnls (pass all data at once)
%   -added itmax option (split out from ittol). Old calls still work.
%   -added basic dataset object support
%10/16/03 jms
%   -squelched normalization warnings
%   -unknown entry for ccon/scon defaults to ls for initial guess
%12/01/03 jms
%   -added soft, weighted equality constraints
%   -added more diagnostic display output (controled by options.display)
%   -added better dataset support (expand results to match original data
%    size prior to sample or variable exclusion)
%12/12/03 jms
%   -added weighted baseline constraint method and blorder options
%02/26/04 rsk -convert to engine (MCR to ALS)
%03/26/04 jms -modified help
%04/14/04 jms -added test for all-zero soft constraints (not allowed)
%  -added support for true hard constraints (fastnnls and standard ls)
%  -do not normalize a factor's spectrum if EITHER contribution or
%     spectrum is equality constrained
%04/15/04 jms -added test for all zero constraints
%  -DO normalize a spectrum if a factor's spectrum or conc. constraints are
%     ONLY zeros (exception to do not norm if constrained)
%5/7/04 jms -fixed reduction of components bug associate with cczero and sczero
%     (needed to be reduced also)
%6/16/04 jms -removed extra distslct call
%7/21/04 jms -fixed soft/hard constraint problem which caused all
%      constraints to be "hard" with fastnnls

if nargin == 0; x = 'io'; end
if ischar(x);
    options = [];
    options.name    = 'options';
    options.display = 'on';
    options.plots   = 'final';
    options.waitbar = 'auto';
    options.ccon    = 'fasternnls';
    options.cconind = [];
    options.scon    = 'fasternnls';
    options.sconind = [];
    options.cc      = [];
    options.ccwts   = [inf];
    options.sc      = [];
    options.scwts   = [inf];
    options.sclc    = [];
    options.scls    = [];
    options.contrast = '';
    options.contrastweight=.05;
    options.closure = [];
    options.closurewts = inf;
    options.condition = 'none';
    options.normorder = 2;
    options.tolc    = 1e-5;  %tolerance on non-negativity for contributions
    options.tols    = 1e-5;  %tolerance on non-negativity for spectra
    options.ittol   = 1e-8;
    options.itmax   = 300;
    options.timemax = 3600;  %maximum time for iterations
    options.rankfail = 'reset';   %  [ 'drop' | 'abort' | 'reset' | 'random' ]
    options.cblorder = [];
    options.sblorder = [];
    options.initialguessmethod = 'exteriorpts'; % [ 'distslct' | {'exteriorpts'} ]
    options.initialguessminnorm = 0.03;
    options.definitions = @optiondefs;
    if nargout==0;
        evriio(mfilename,x,options);
    else
        c = evriio(mfilename,x,options);
    end
    return;
end

if nargin<3               %set default options
    options  = als('options');
else
    options = reconopts(options,als('options'));
end

starttime = now;  %note starting time

switch lower(options.ccon)
    case {1, 'nonneg','reset'}
        options.ccon = 1;
        if strcmpi(options.display,'on')
            disp('Non-Negativity on C (Reset)')
        end
    case {5, 'fasternnls'}
        options.ccon = 5;
        if strcmpi(options.display,'on')
            disp('Non-Negativity on C (Faster Least-Squares)')
        end
    case {2, 'fastnnls'}
        if isempty(options.cconind)
            options.ccon = 2;
        else
            options.ccon = 4;
        end
        if strcmpi(options.display,'on')
            disp('Non-Negativity on C (Fast Least-Squares)')
        end
    case {3, 'baseline'}
        options.ccon = 3;
        if strcmpi(options.display,'on')
            if ~isempty(options.cblorder)
                disp(['Non-Negativity on C (Baselined Weighted Reset, Order ' num2str(options.cblorder) ')'])
            else
                disp('Non-Negativity on C (Weighted Reset)')
            end
        end
    case {4, 'fastnnls_sel'}
        options.ccon = 4;
    case {0, 'none'}
        options.ccon = 0;
        if strcmpi(options.display,'on')
            disp('Sign of C is unconstrained')
        end
    case {7, 'unimodality&nonnegativity'}
        options.ccon = 7;
        opunimodc = constrainfit('options');
        opunimodc.type='unimodality';
    case {8, 'unimodality'}
        options.ccon = 8;
        opunimodc = constrainfit('options');
        opunimodc.type='unimodality_nonon';
    otherwise
        warning('EVRI:AlsCconInvalid','Option.ccon not recognized. Reset to ''none''.')
        options.ccon = 0;
end
switch lower(options.scon)
    case {1, 'nonneg','reset'}
        options.scon = 1;
        if strcmpi(options.display,'on')
            disp('Non-Negativity on S (Reset)')
        end
    case {5, 'fasternnls'}
        options.scon = 5;
        if strcmpi(options.display,'on')
            disp('Non-Negativity on S (Faster Least-Squares)')
        end
    case {2, 'fastnnls'}
        if isempty(options.sconind)
            options.scon = 2;
        else
            options.scon = 4;
        end
        if strcmpi(options.display,'on')
            disp('Non-Negativity on S (Fast Least-Squares)')
        end
    case {3, 'baseline'}
        options.scon = 3;
        if strcmpi(options.display,'on')
            if ~isempty(options.sblorder)
                disp(['Non-Negativity on S (Baselined Weighted Reset, Order ' num2str(options.sblorder) ')'])
            else
                disp('Non-Negativity on S (Weighted Reset)')
            end
        end
    case {4, 'fastnnls_sel'}
        options.scon = 4;
    case {0, 'none'}
        options.scon = 0;
        if strcmpi(options.display,'on')
            disp('Sign of S is unconstrained')
        end
    case {7, 'unimodality&nonnegativity'}
        options.scon = 7;
        opunimods = constrainfit('options');
        opunimods.type='unimodality';
    case {8, 'unimodality'}
        options.scon = 8;
        opunimods = constrainfit('options');
        opunimods.type='unimodality_nonon';
    otherwise
        warning('EVRI:AlsSconInvalid','Option.scon not recognized. Reset to ''none''.')
        options.scon = 0;
end

%Extract info if x is a dataset
useinclude = 0;
origxsz = size(x);
if isa(x,'dataset');
    %get include information
    xincl = x.include;
    %get axisscale info (if no scl included in options)
    if isempty(options.sclc)
        if ~isempty(x.axisscale{1})
            options.sclc = x.axisscale{1}(xincl{1});
        else
            options.sclc = xincl{1};
        end
    end
    if isempty(options.scls)
        if ~isempty(x.axisscale{2})
            options.scls = x.axisscale{2}(xincl{2});
        else
            options.scls = xincl{2};
        end
    end
    %extract data
    x = x.data(xincl{:});
    useinclude = 1;
end
[m,n]   = size(x);
ssqx    = sum(sum(x.^2));

%Handle c0 dataset
if isa(c0,'dataset');
    c0incl = c0.include;
    if useinclude  %if x was a dataset, use include from x
        if size(c0,1)==origxsz(1)
            c0incl{1} = xincl{1};
        elseif size(c0,2)==origxsz(2)
            c0incl{2} = xincl{2};
        end
    end
    c0 = c0.data(c0incl{:});
end
%trim various items if given in original dataset units (we may have excluded some samples or variables)
if useinclude
    if size(c0,1)==origxsz(1)
        c0 = c0(xincl{1},:);
    elseif size(c0,2)==origxsz(2)
        c0 = c0(:,xincl{2});
    end
    if size(options.cc,1)==origxsz(1)
        options.cc = options.cc(xincl{1},:);
    end
    if size(options.sc,2)==origxsz(2)
        options.sc = options.sc(:,xincl{2});
    end
end

%automatic initial guess mode
if iscell(c0)
    if length(c0)>1
        mode = c0{2};
    else
        mode = 1;
    end
    c0 = c0{1};
else
    mode = 1;
end
if prod(size(c0))==1;
    ncomp = c0(1);
    %get initial guess from data
    if strcmp( options.initialguessmethod, 'exteriorpts')
        minnormval = options.initialguessminnorm;
        extopts = exteriorpts('options');
        extopts.minnorm = minnormval;
        extopts.selectdim = mode;
        pure = exteriorpts(x,ncomp, extopts);
    else
        pure = distslct(mncn(permute(x,[mode setdiff(1:2,mode)])),ncomp);
    end
    if mode==1
        c0   = x(pure,:);
        if strcmpi(options.display,'on')
            disp(['Initial guess from rows: ' num2str(pure(:)')])
        end
    else
        c0   = x(:,pure);
        if strcmpi(options.display,'on')
            disp(['Initial guess from columns: ' num2str(pure(:)')])
        end
    end
end

%manual initial guess (and drop-down from automatic)
if size(c0,1)==m & (size(c0,1)>size(c0,2))
    ka    = size(c0,2);  %initial guess for contribution
    s0    = [];
    c0initg = true;
    contrastauto='s';
elseif size(c0,2)==n
    ka    = size(c0,1);  %initial guess for spectra
    s0    = c0;
    c0    = [];
    c0initg = false;
    contrastauto='c';
else
    error('c0 must be size(x,1) by #factors or #factors by size(x,2)')
end

%check if we're going to have problems with fasternnls and full-rank
%Fasternnls can't tell if you're passing x'x or just x if C or S is
%square (same number of components as variables or samples, respectively).
%So set a flag to avoid the problem.
forceCxtx = false;
forceSxtx = false;
if options.ccon==5
    %if using fasternnls...
    if all(size(c0)==ka)
        %C is going to be square?
        forceSxtx = true;  %force x'x with S
    end
    if all(size(s0)==ka)
        %S is going to be square?
        forceCxtx = true;  %force x'x with C
    end
end

if strcmpi(options.contrast,'a') | strcmpi(options.contrast,'auto')  %auto mode?
    options.contrast = contrastauto;  %copy automatic setting over given setting
end

if ismember(lower(options.contrast),{'spectrum' 'spectra' 's'})
    options.contrast = 's';
    mean4c=sum(x,2);
    mean4c=mean4c/sqrt(sum(mean4c.^2));
    %mean4c=mean4c/sqrt(sum(mean4c));
elseif ismember(lower(options.contrast),{'image' 'contributions' 'concentrations' 'contribution' 'concentration' 'c'})
    options.contrast = 'c';
    mean4s=sum(x,1);
    mean4s=mean4s/sqrt(sum(mean4s.^2));
    %mean4s=mean4s/sqrt(sum(mean4s))
end;


if isempty(options.sclc)
    options.sclc = 1:m;
elseif length(options.sclc)~=m
    options.sclc = 1:m;
end
if isempty(options.scls)
    options.scls = 1:n;
elseif length(options.scls)~=n
    options.scls = 1:n;
end

%check max iterations and tolerance options
itmax = ceil(options.itmax);
if isempty(itmax) || itmax<1;
    error('ITMAX must be a non-zero positive number of iterations');
end
if itmax == 1;
    if strcmpi(options.display,'on')
        disp('Prediction mode - Fixing to initial guess')
    end
    if c0initg;  %initial guess for c
        options.cc = c0;
        options.ccwts = inf;
        options.sc = [];
        options.scwts = inf;
    else
        options.sc = s0;
        options.scwts = inf;
        options.cc = [];
        options.ccwts = inf;
    end
    itmax = 2;  %do twice - once for initial guess, then again for accurate regression
end
itmin = options.ittol;
if isempty(itmin);
    error('ITTOL must be a non-zero positive tolerance.');
end
if itmin>1;  %Backwards compatibility - old form call where iterations are passed as ittol?
    itmax = itmin;       %use it as itmax
    opts  = als('options');
    itmin = opts.ittol;  %and use default ittol
end

if isempty(options.tolc) || options.tolc<0
    options.tolc  = 1e-5;  %tolerance on non-negativity for contributions
end
if isempty(options.tols) || options.tols<0
    options.tols  = 1e-5;  %tolerance on non-negativity for spectra
end

%- - - - - - - - - - - - - - - -
%Determine type and location of equality constraints
%evaluate equality constraints
% location and type of C constraints
ccaugx = [];
ccaugy = [];
if isempty(options.cc)
    ccons = false;
else
    if size(options.cc,1)~=m
        error('Contribution equality constraints (cc) must have same number of rows as are in x')
    elseif size(options.cc,2)>ka
        error('Contribution equality constraints (options.cc) has more columns than the model has factors')
    elseif size(options.cc,2)<ka
        if strcmpi(options.display,'on')
            disp(['Contribution equality constraints expanded to match number of factors. Unspecified components are unconstrained.'])
        end
        options.cc(:,end+1:ka) = nan; %everything else is considered to be unconstrained
    end
    jc = isfinite(options.cc);
    if any(any(jc))
        ccons = true;
    else
        ccons = false;
    end
end
if ccons
    ccwts = options.ccwts(:)';
    if ~isempty(ccwts) && length(ccwts)~=1 && length(ccwts)~=ka
        error('options.ccwts must be a scalar value or a vector equal in length to the number of factors');
    elseif isempty(ccwts)
        ccwts = ones(1,ka)*inf;
    elseif length(ccwts)==1;
        ccwts = ones(1,ka)*ccwts;
    end
    ccwts = ccwts*ssqx/n; %make weights relative to sum-squared signal of one average variable
    
    %normalize weights relative to sum-squared values of constraints
    temp = options.cc;
    temp(~jc) = 0;
    ssq = sum(temp.^2,1);
    ssq(ssq==0) = 1;
    ccwts = ccwts./ssq;
    
    ccsoft = isfinite(ccwts) & ccwts>0 & any(jc);    %components with soft constraints
    cchard = isinf(ccwts) & any(jc);                 %components with hard constraints
    
    %look for any equality constraint which is only zeros (NaNs are OK)
    for j=1:size(options.cc,2);
        cczero(1,j) = all(options.cc(isfinite(options.cc(:,j)),j)==0);
        bad = cczero(1,j) & ~any(isnan(options.cc(:,j)));
        if bad
            error(['Equality constraints can not be entirely zero (all-zero contribution constraint on factor ' num2str(j) ')'])
        end
    end
    
    if any(ccsoft)
        %extract augmenting columns for soft constraints
        ccaugx = options.cc(:,ccsoft)*diag(ccwts(ccsoft));
        ccaugx(isnan(ccaugx)) = 0;  %insert zeros for NaNs
        %test for all-zero soft constraints (not allowed)
        if any(ccsoft & cczero)
            error(['Soft constraints can only be used with non-zero constraints (all-zero contribution constraint on factor(s) ' num2str(find(ccsoft & cczero)) ')'])
        end
        ccaugy = diag(ccwts.*ccsoft);
        ccaugy = ccaugy(:,ccsoft);
        
        if strcmpi(options.display,'on')
            disp(['Soft Equality Constraints on C: component(s) ' num2str(find(ccsoft))])
        end
    end
    
    if any(cchard) && strcmpi(options.display,'on')
        disp(['Hard Equality Constraints on C: component(s) ' num2str(find(cchard))])
    end
    
    %create a map of the hard-constrained contributions - used for calls to fastnnls
    cchardmap = [];
    if any(cchard)
        cchardmap = options.cc*nan;
        cchardmap(:,cchard) = options.cc(:,cchard);
    end
    
else
    ccsoft = false(1,ka);
    cchard = ccsoft;
    cczero = ccsoft;
    cchardmap = [];
end

%check for closure constraints
ccclosure = zeros(1,ka);
if ~isempty(options.closure)
    if numel(options.closure)==1
        options.closure = true(1,ka);
    end
    if size(options.closure,2)<ka;
        error('options.closure must have as many columns as there are factors in the model');
    end
    if ~islogical(options.closure)
        options.closure = logical(options.closure);
    end
    if ~isinf(options.closurewts);
        for k=1:size(options.closure,1);
            ccaugy(1:ka,end+1) = 0;
            ccaugy(find(options.closure(k,:)),end) = options.closurewts;
            ccaugx(1:m,end+1)  = options.closurewts;
        end
    end
    ccclosure = sum(options.closure,1)>0;
    
    if strcmpi(options.display,'on')
        for k=1:size(options.closure,1);
            disp(['Closure constraint on components : ' num2str(find(options.closure(k,:)))])
        end
    end
end


% location and type of S constraints
scaugx = [];
scaugy = [];
if isempty(options.sc)
    scons = false;
else
    if size(options.sc,2)~=n
        error('Spectral equality constraints (options.sc) must have same number of columns as are in x')
    elseif size(options.sc,1)>ka
        error('Spectral equality constraints (options.sc) has more rows than the model has factors')
    elseif size(options.sc,1)<ka
        if strcmpi(options.display,'on')
            disp(['Spectral equality constraints expanded to match number of factors. Unspecified components are unconstrained.'])
        end
        options.sc(end+1:ka,:) = nan; %everything else is considered to be unconstrained
    end
    js  = isfinite(options.sc);
    if any(any(js))
        scons = true;
    else
        scons = false;
    end
end
if scons
    scwts = options.scwts(:)';
    if ~isempty(scwts) && length(scwts)~=1 && length(scwts)~=ka
        error('options.scwts must be a scalar value or a vector equal in length to the number of factors');
    elseif isempty(scwts);
        scwts = ones(1,ka)*inf;
    elseif length(scwts)==1;
        scwts = ones(1,ka)*scwts;
    end
    scwts = scwts*ssqx/m; %make weights relative to sum-squared signal of one average sample
    
    %normalize weights relative to sum-squared values of constraints
    temp = options.sc;
    temp(~js) = 0;
    ssq = sum(temp.^2,2)';
    ssq(ssq==0) = 1;
    scwts = scwts./ssq;
    
    scsoft = isfinite(scwts) & scwts>0 & any(js');    %components with soft constraints
    schard = isinf(scwts) & any(js');                 %components with hard constraints
    
    %look for any equality constraint which is only zeros (NaNs are OK)
    for j=1:size(options.sc,1);
        sczero(1,j) = all(options.sc(j,isfinite(options.sc(j,:)))==0);
        bad = sczero(1,j) & ~any(isnan(options.sc(j,:)));
        if bad
            error(['Equality constraints can not be entirely zero (all-zero spectral constraint on factor ' num2str(j) ')'])
        end
    end
    for j=1:size(options.sc,1);
        sczero(1,j) = (sum(options.sc(j,isfinite(options.sc(j,:))))==0);
    end
    
    if any(scsoft)
        %extract augmenting rows for soft constraints
        scaugx = diag(scwts(scsoft))*options.sc(scsoft,:);
        scaugx(isnan(scaugx)) = 0;  %insert zeros for NaNs
        %test for all-zero soft constraints (not allowed
        if any(scsoft & sczero)
            error(['Soft constraints can only be used with non-zero constraints (all-zero scores constraint on factor(s) ' num2str(find(scsoft & sczero)) ')'])
        end
        scaugy = diag(scwts.*scsoft);
        scaugy = scaugy(scsoft,:);
        if strcmpi(options.display,'on')
            disp(['Soft Equality Constraints on S: component(s) ' num2str(find(scsoft))])
        end
    end
    
    if any(schard) && strcmpi(options.display,'on')
        disp(['Hard Equality Constraints on S: component(s) ' num2str(find(schard))])
    end
    
    overlap = (scsoft | schard) & (ccsoft | cchard);
    if ~isempty(cchardmap)
        overlap = any(cchardmap(:,overlap)>0 & ~isnan(cchardmap(:,overlap)));
    end
    if any(overlap) && strcmpi(options.display,'on')
        disp('WARNING: Contribution and spectral constraints detected on the same factor');
        disp('    Difficulties may occur if these are inconsistent constraints')
    end
    
    %create a map of the hard-constrained contributions - used for calls to fastnnls
    schardmap = [];
    if any(schard)
        schardmap = options.sc*nan;
        schardmap(schard,:) = options.sc(schard,:);
    end
    
else
    scsoft = false(1,ka);
    schard = scsoft;
    sczero = scsoft;
    schardmap = [];
end

%prepare soft-constraint x-blocks (done ONCE for speed - might be more memory intensive)
if ~isempty(ccaugx)
    xctemp = [x ccaugx];
else
    xctemp = x;
end
if ~isempty(scaugx);
    xstemp = [x;scaugx];
else
    xstemp = x;
end

%prepare local/factor-specific non-negativity constraints
if ~isempty(options.cconind)
    logicalcon = islogical(options.cconind) | all(ismember(unique(options.cconind(:)),[0 1]));
    if ~any(size(options.cconind)==1)
        %matrix
        if ~logicalcon
            error('Option cconind must be type logical when matrix is given');
        end
        %logical array or array with only 0 and 1
        if any(size(options.cconind)~=[m ka])
            error('Option cconind does not match size of c matrix (# factors or # of samples)')
        end
    else
        %vector of factors to use
        if logicalcon
            options.cconind = find(options.cconind);
        end
        options.cconind(options.cconind>ka | options.cconind<0) = [];
        temp = false(m,ka);
        temp(:,options.cconind) = true;
        options.cconind = temp;
    end
end
if ~isempty(options.sconind)
    logicalcon = islogical(options.sconind) | all(ismember(unique(options.sconind(:)),[0 1]));
    if ~any(size(options.sconind)==1)
        %matrix
        if ~logicalcon
            error('Option sconind must be type logical when matrix is given');
        end
        %logical array or array with only 0 and 1
        if any(size(options.sconind)~=[ka n])
            error('Option sconind does not match size of s matrix (# factors or # of variables)')
        end
    else
        %vector of factors to use
        if logicalcon
            options.sconind = find(options.sconind);
        end
        options.sconind(options.sconind>ka | options.sconind<0) = [];
        temp = false(ka,n);
        temp(options.sconind,:) = true;
        options.sconind = temp;
    end
end




%- - - - - - - - - - - - - - - -
%MAIN ALS LOOP

cblorder = generatebaseline(size(x,1),options.cblorder);
sblorder = generatebaseline(size(x,2),options.sblorder);

nreset = 0;
c = c0;
s = s0;
ress = 1e5;
resc = 1e5;
waitbarhandle = [];
oldcomplete = 0;
it  = 0;
while it<itmax
    %--C--
    if it>0 || ~c0initg  %skip this the first time through unless the initial guess was for S
        %augment soft-constraints onto most recent S approx.
        if ~isempty(ccaugy);
            stemp = [s ccaugy];
        else
            stemp = s;
        end
        switch options.condition
            case 'norm'
                %calculate conditioning and apply
                A = sqrt(sum(stemp'.^2));
                A(A==0) = 1;
                Ainv = diag(1./A);
                stemp = Ainv*stemp;
        end
        %calculate fixed portion for hard-constraints
        if any(cchard) && options.ccon~=2 && options.ccon~=4 && options.ccon~=5
            eqtemp = options.cc(:,cchard);
            eqtemp(isnan(eqtemp))=0;
            eqtemp = eqtemp*stemp(cchard,:);
        else
            eqtemp = 0;
        end
        %solve for contribution
        switch options.ccon
            case 0
                c = (xctemp-eqtemp)/stemp;
            case 1
                c = (xctemp-eqtemp)/stemp;
                c(c<-options.tolc) = 0;
            case 2
                c = fastnnls(stemp',xctemp',options.tolc,c',cchardmap')';
            case 4
                c = fastnnls_sel(stemp',xctemp',options.tolc,c',cchardmap',options.cconind')';
            case 5
                switch forceCxtx
                    case true
                        %force use of x'x and x'y (since we can't tell the difference
                        xctemp = xctemp*stemp';
                        stemp  = stemp*stemp';
                end
                c = fasternnls(stemp',xctemp',options.tolc,c',cchardmap',options.cconind')';
            case 3
                c = (xctemp-eqtemp)/stemp;
                if ~isempty(cblorder)
                    bldata = wlsbaseline(c',cblorder,struct('nonneg','yes'));
                else
                    bldata = c';
                end
                
                for k = 1:ka;
                    bad      = bldata(k,:)<-options.tols;
                    tempscl  = std(bldata(k,:));
                    temp     = -bldata(k,bad)/tempscl;
                    c(bad,k) = c(bad,k)+(temp-(temp./(1+temp.^(1.001))))'.*tempscl;
                end
            case 7 % unimodality and nonnegativity
                if isempty(c) % Because it is empty at first iteration
                    c = zeros(size(xctemp,1),size(stemp,1));
                end
                c = constrainfit(xctemp*stemp',stemp*stemp',c,opunimodc);
            case 8 % unimodality
                if isempty(c) % Because it is empty at first iteration
                    c = zeros(size(xctemp,1),size(stemp,1));
                end
                c = constrainfit(xctemp*stemp',stemp*stemp',c,opunimodc);
        end
        %remove conditioning from result
        switch options.condition
            case 'norm'
                c = c*Ainv;
        end
        if strcmpi(options.contrast,'s')  %'s' constraint means mix concentrations
            lngth = sqrt(sum(c.^2));
            lngth(lngth==0) = 1;
            c = c*diag(1./lngth);
            c = (1-options.contrastweight)*c+mean4c*ones(1,ka)*...
                options.contrastweight;%contrast in spectra
            c = c*diag(lngth);
            
        end
        %use reset for hard-constrained components (w/other than fastnnls)
        if options.ccon~=2 && options.ccon~=4 && options.ccon~=5
            c(~isnan(cchardmap)) = cchardmap(~isnan(cchardmap));
            %       for j = find(cchard);
            %         c(jc(:,j),j) = options.cc(jc(:,j),j);
            %       end
        end
        if it>0
            %test for all-zero components
            allzero = sum(abs(c),1)==0;
            if any(allzero);
                switch options.rankfail
                    case 'reset'  %reset failing components to initial guess values
                        c(:,allzero) = c0(:,allzero);
                        nreset = nreset + sum(allzero);
                        if nreset>5*ka;
                            warning('EVRI:AlsConverganceProblem','ALS will not converge with the given number of factors and initial guess - Dropping rank-deficient components');
                            options.rankfail = 'drop';
                        end
                    case 'random'  %reset failing components to random vector
                        if options.ccon>0
                            c(:,allzero) = rand(size(c,1),sum(allzero));
                        else
                            c(:,allzero) = randn(size(c,1),sum(allzero));
                        end
                        if nreset>5*ka;
                            warning('EVRI:AlsConverganceProblem','ALS will not converge with the given number of factors and initial guess - Dropping rank-deficient components');
                            options.rankfail = 'drop';
                        end
                    case 'drop'   %drop all-zero components
                        %ka,c,s,options.cc,jc,ccsoft,cchard,scsoft,schard,ccaugx,ccaugy,options.sc,js,scaugx,scaugy
                        ka = ka - sum(allzero);
                        if ka<1
                            error('ALS will not converge with the given number of factors and initial guess');
                        end
                        c = c(:,~allzero);
                        s = s(~allzero,:);
                        c0 = c0(:,~allzero);
                        s0 = s0(~allzero,:);
                        cold = cold(:,~allzero);
                        sold = sold(~allzero,:);
                        if ccons
                            options.cc = options.cc(:,~allzero);
                            jc = jc(:,~allzero);    %NOTE: may be able to remove jc from down here
                            if any(cchard)
                                if any(cchard(~allzero))
                                    cchardmap = cchardmap(:,~allzero);
                                else  %nothing left with hard constraints?
                                    cchardmap = [];
                                end
                            end
                        end
                        if ~isempty(ccaugy)
                            ccaugy = ccaugy(~allzero,:);
                        end
                        if scons
                            options.sc = options.sc(~allzero,:);
                            js = js(:,~allzero);
                            if any(schard)
                                if any(schard(~allzero))
                                    schardmap = schardmap(~allzero,:);
                                else  %nothing left with hard constraints?
                                    schardmap = [];
                                end
                            end
                        end
                        if ~isempty(scaugy)
                            scaugy = scaugy(:,~allzero);
                        end
                        ccsoft = ccsoft(~allzero);
                        cchard = cchard(~allzero);
                        scsoft = scsoft(~allzero);
                        schard = schard(~allzero);
                        cczero = cczero(~allzero);
                        sczero = sczero(~allzero);
                        ccclosure = ccclosure(~allzero);
                        % Fix options.c, options.sconind. remove row/columns
                        if ~isempty(options.sconind)
                            options.sconind = options.sconind(~allzero,:);
                        end
                        if ~isempty(options.cconind)
                            options.cconind = options.cconind(:,~allzero);
                        end
                        forceCxtx = false;
                        forceSxtx = false;
                        
                        if strcmpi(options.display,'on')
                            disp(['All-zero component dropped. Total components now ' num2str(ka)]);
                        end
                    case 'fail'
                        error('ALS will not converge with the given number of factors and initial guess')
                end
            end
        end
        if isinf(options.closurewts) & any(ccclosure);
            for k=1:size(options.closure,1);
                inds = find(options.closure(k,:));
                c(:,inds) = normaliz(c(:,inds),[],1);
            end
        end
    end
    
    %--S--
    if it>0 | c0initg  %skip this the first time through unless the initial guess was for C
        %augment soft-constraints onto most recent C approx.
        if ~isempty(scaugy);
            ctemp = [c;scaugy];
        else
            ctemp = c;
        end
        switch options.condition
            case 'norm'
                %calculate conditioning and apply
                A     = sqrt(sum(ctemp.^2));
                A(A==0) = 1;
                Ainv  = diag(1./A);
                ctemp = ctemp*Ainv;
        end
        %calculate fixed portion for hard-constraints
        if any(schard) && options.ccon~=2 && options.ccon~=4 && options.ccon~=5
            eqtemp = options.sc(schard,:);
            eqtemp(isnan(eqtemp))=0;
            eqtemp = ctemp(:,schard)*eqtemp;
        else
            eqtemp = 0;
        end
        switch options.scon %solve for spectra
            case 0
                s = ctemp\(xstemp-eqtemp);
            case 1
                s = ctemp\(xstemp-eqtemp);
                s(s<-options.tols) = 0;
            case 2
                s = fastnnls(ctemp,xstemp,options.tols,s,schardmap);
            case 4
                s = fastnnls_sel(ctemp,xstemp,options.tols,s,schardmap,options.sconind);
            case 5
                switch forceSxtx
                    case true
                        %force use of x'x and x'y (since we can't tell the difference
                        xstemp = ctemp'*xstemp;
                        ctemp  = ctemp'*ctemp;
                end
                s = fasternnls(ctemp,xstemp,options.tols,s,schardmap,options.sconind);
            case 3
                s = ctemp\(xstemp-eqtemp);
                if ~isempty(sblorder)
                    bldata = wlsbaseline(s,sblorder,struct('nonneg','yes'));
                else
                    bldata = s;
                end
                
                for k = 1:ka;
                    bad      = bldata(k,:)<-options.tols;
                    tempscl  = std(bldata(k,:));
                    temp     = -bldata(k,bad)/tempscl;
                    s(k,bad) = s(k,bad)+(temp-(temp./(1+temp.^(1.001)))).*tempscl;
                end
                
            case 7 % unimodality and nonnegativity
                if isempty(s) % Because it is empty at first iteration
                    s = zeros(size(xstemp,1),size(ctemp,2));
                end
                s = constrainfit(xstemp'*ctemp,ctemp'*ctemp,s',opunimods)';
            case 8 % unimodality
                if isempty(s) % Because it is empty at first iteration
                    s = zeros(size(xstemp,1),size(ctemp,1));
                end
                s = constrainfit(xstemp'*ctemp,ctemp'*ctemp,s',opunimods)';
        end
        %remove conditioning from result
        switch options.condition
            case 'norm'
                s = Ainv*s;
        end
        if strcmpi(options.contrast,'c')  %'c' constraint means mix spectra
            lngth = sqrt(sum(s.^2,2));
            lngth(lngth==0) = 1;
            s = diag(1./lngth)*s;
            s = (1-options.contrastweight)*s+ones(ka,1)*mean4s*options.contrastweight;
            s = diag(lngth)*s;%contrast in images
        end
        %use reset for hard-constrained components
        if options.scon~=2 && options.scon~=4 && options.scon~=5
            s(~isnan(schardmap)) = schardmap(~isnan(schardmap));
            %       for j = find(schard);
            %         s(j,js(j,:)) = options.sc(j,js(j,:));
            %       end
        end
        
        if it>0
            %test for all-zero components
            allzero = sum(abs(s),2)==0;
            if any(allzero);
                switch options.rankfail
                    case 'reset'  %reset failing components to initial guess values
                        s(allzero,:) = s0(allzero,:);
                        nreset = nreset + sum(allzero);
                        if nreset>5*ka;
                            warning('EVRI:AlsConverganceProblem','ALS will not converge with the given number of factors and initial guess - Dropping rank-deficient components');
                            options.rankfail = 'drop';
                        end
                    case 'random'  %reset failing components to random vector
                        if options.scon>0
                            s(allzero,:) = rand(sum(allzero),size(s,2));
                        else
                            s(allzero,:) = randn(sum(allzero),size(s,2));
                        end
                        nreset = nreset+sum(allzero);
                        if nreset>5*ka;
                            warning('EVRI:AlsConverganceProblem','ALS will not converge with the given number of factors and initial guess - Dropping rank-deficient components');
                            options.rankfail = 'drop';
                        end
                    case 'drop'   %drop all-zero components
                        %ka,c,s,options.cc,jc,ccsoft,cchard,scsoft,schard,ccaugx,ccaugy,options.sc,js,scaugx,scaugy
                        ka = ka - sum(allzero);
                        if ka<1
                            error('ALS will not converge with the given number of factors and initial guess');
                        end
                        c = c(:,~allzero);
                        s = s(~allzero,:);
                        c0 = c0(:,~allzero);
                        s0 = s0(~allzero,:);
                        cold = cold(:,~allzero);
                        sold = sold(~allzero,:);
                        if ccons
                            options.cc = options.cc(:,~allzero);
                            jc = jc(:,~allzero);
                            if any(cchard)
                                if any(cchard(~allzero))
                                    cchardmap = cchardmap(:,~allzero);
                                else  %nothing left with hard constraints?
                                    cchardmap = [];
                                end
                            end
                        end
                        if ~isempty(ccaugy)
                            ccaugy = ccaugy(~allzero,:);
                        end
                        if scons
                            options.sc = options.sc(~allzero,:);
                            js = js(:,~allzero);
                            if any(schard)
                                if any(schard(~allzero))
                                    schardmap = schardmap(~allzero,:);
                                else  %nothing left with hard constraints?
                                    schardmap = [];
                                end
                            end
                        end
                        if ~isempty(scaugy)
                            scaugy = scaugy(:,~allzero);
                        end
                        ccsoft = ccsoft(~allzero);
                        cchard = cchard(~allzero);
                        scsoft = scsoft(~allzero);
                        schard = schard(~allzero);
                        cczero = cczero(~allzero);
                        sczero = sczero(~allzero);
                        ccclosure = ccclosure(~allzero);
                        % Fix options.c, options.sconind. remove row/columns
                        if ~isempty(options.sconind)
                            options.sconind = options.sconind(~allzero,:);
                        end
                        if ~isempty(options.cconind)
                            options.cconind = options.cconind(:,~allzero);
                        end
                        forceCxtx = false;
                        forceSxtx = false;
                        
                        if strcmp(lower(options.display),'on')
                            disp(['All-zero component dropped. Total components now ' num2str(ka)]);
                        end
                    case 'fail'
                        error('ALS will not converge with the given number of factors and initial guess')
                end
            end
        end
        %normalize unconstrained factors
        %     tonorm = ~schard & ~cchard;
        %     tonorm = ~schard;
        tonorm = ~(schard & ~sczero) & ~(cchard & ~cczero) & ~ccsoft & ~ccclosure;
        if any(tonorm)
            s(tonorm,:) = normaliz(s(tonorm,:),0,options.normorder);
        end
    end
    
    %--Evaluate fit--
    it     = it+1;
    %first time through? Initialization loop - just remember current values
    if it==1;
        cold = c;
        sold = s;
        if c0initg
            s0 = s;
        else
            c0 = c;
        end
    elseif (options.ittol<1)&(mod(it,2)==0)
        %change this to only test residuals for locations where
        % equality constraints ain't
        rescn = sum(sqrt(sum(cold.^2,1)));
        ressn = sum(sqrt(sum(sold.^2,2)));
        resc = sum(sqrt(sum((c-cold).^2,1)))/rescn/ka;
        ress = sum(sqrt(sum((s-sold).^2,2)))/ressn/ka;
        
        if (ress<itmin)&(resc<itmin)
            break
        else
            cold = c;
            sold = s;
        end
    end
    
    %--Evaluate elapsed time--
    if (now-starttime)*60*60*24>options.timemax;
        break
    end
    
    %--Display waitbar--
    if ~strcmp(options.waitbar,'off')
        elap = (now-starttime)*60*60*24;
        if ~isempty(waitbarhandle) | strcmp(options.waitbar,'on') | elap>2;  %>5 seconds elapsed? show waitbar
            if ress==0 | resc==0;
                complete = [it/itmax elap/options.timemax];
            else
                complete = [itmin/ress itmin/resc it/itmax elap/options.timemax];
            end
            complete = double(max(complete));
            if isempty(waitbarhandle);
                waitbarhandle = waitbar(complete,'Calculating MCR model... (Close to cancel analysis)');
            else
                if ~ishandle(waitbarhandle)
                    %waitbar closed? stop now
                    warning('EVRI:AlsIterationsTerminated','Iterations terminated by user prior to convergence');
                    break;
                end
                waitbar(complete);
            end
            %     set(waitbarhandle,'name',['Est. Time Remaining: ' besttime(est)])
        end
    end
    
end

%----------------------------------------
%Finished, do display and calculate outputs

if ~scons & ~ccons & ~any(ccclosure);
    [junk,order] = sort(-sum(c,1));
    c = c(:,order);
    s = s(order,:);
end

if strcmp(lower(options.display),'on')
    if (now-starttime)*60*60*24>options.timemax
        disp('Terminated based on maximum time');
    elseif it>=itmax;
        %     disp('Terminated based on maximum iterations');
        disp(sprintf('Terminated based on maximum iterations (%d)',options.itmax))
    else
        disp('Terminated based on change in fit');
    end
    disp(['Elapsed time: ' besttime((now-starttime)*60*60*24)])
end
if ~isempty(waitbarhandle) & ishandle(waitbarhandle);
    close(waitbarhandle);
end

res = (x-c*s).^2;
switch lower(options.plots)
    case 'final'
        figure
        subplot(2,1,1), plot(options.sclc,sum(res,2))
        xlabel('Contribution Profile'), ylabel('\bfC\rm Sum Squared Residuals')
        title(sprintf('ALS Results after %d iterations',it))
        subplot(2,1,2), plot(options.scls,sum(res,1))
        xlabel('Spectral Profile'),      ylabel('\bfS\rm Sum Squared Residuals')
        
        figure
        subplot(2,1,1), plot(options.sclc,c)
        xlabel('Contribution Profile'), ylabel('\bfC')
        title(sprintf('ALS Results after %d iterations',it))
        subplot(2,1,2), plot(options.scls,s)
        xlabel('Spectral Profile'),      ylabel('\bfS')
end
switch lower(options.display)
    case 'on'
        ssqres = sum(sum(res,2));
        disp(sprintf('Residual (RMSE) %3.6e', sqrt(ssqres)))
        disp(sprintf('Unmodelled Variance is %g percent', ssqres*100/ssqx))
end

%resize c and s to match original variable size (pad with zeros - we might
%later revise this to do a projection for the excluded samples)
if useinclude;
    
    %replace excluded samples with zeros
    temp = zeros(origxsz(1),size(c,2));
    temp(xincl{1},:) = c;
    c = temp;
    
    %replace excluded variables with zeros
    temp = zeros(size(s,1),origxsz(2));
    temp(:,xincl{2}) = s;
    s = temp;
end

%------------------------------------------------------------------
function blorder = generatebaseline(sz,order)
%create baseline basis

basis = 0:sz-1;
blorder = [];
for j = 0:order;
    blorder(end+1,:) = normaliz(basis.^j,[],1);
    if j>0;
        blorder(end+1,:) = fliplr(blorder(end,:));
    end
end

%--------------------------
function out = optiondefs()

defs = {
    
%name                    tab                datatype        valid                            userlevel       description
'display'                'Display'          'char'          {'on' 'off'}                     'intermediate'  'Governs level of display.';
'plots'                  'Display'          'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
'waitbar'                'Display'          'select'        {'off' 'on' 'auto'}              'novice'        'Governs use of waitbar (''auto'' enables waitbar if the analysis will be a long one).';

'ccon'                   'Non-Negativity'   'select'        {'none' 'reset' 'fastnnls' 'fasternnls' 'baseline'}     'novice'        'Non-negativity constraints on contributions (fastnnls = true least-squares solution, fasternnls = true least squares and faster than fastnnls, reset = fast but less accurate, baseline = non-negativity to a baseline).';
'scon'                   'Non-Negativity'   'select'        {'none' 'reset' 'fastnnls' 'fasternnls' 'baseline'}     'novice'        'Non-negativity constraints on spectra (none = non-negativity relaxed, fastnnls = true least-squares solution, fasternnls = true least squares and faster than fastnnls, reset = fast but less accurate, baseline = non-negativity to a baseline).';

'contrast'               'Contrast'         'select'        {'contributions' 'spectra' 'auto' ''}                 'intermediate'  'Introduces a constraint to obtain contrast in spectra of contributions/images. This constraint biases the answer towards maximal contrast in spectra (''spectra'') or contributions (''contributions'') within the feasible bounds of the data. When the assumption of pure variables is appropriate, as with MS data, high contrast in spectra is expected and (''spectra'') should be chosen. When samples have distinct layers, such as with a polymer laminate, high contrast in the contributions is expected and (''contributions'') should be chosen. An empty string imposes no constraint. ''auto'' automatically chooses based on mode of initial guess.'

'closure'                'Closure'          'select'        {[] 1}                           'novice'        'indicates whether factors should be constrained to sum to unit concentration. Value of "1" indicates all components must sum to 1.'

'cc'                     'Equality'         'matrix'        ''                               'intermediate'  'Contribution equality constraints, MxK matrix with NaN where equality constraints are not applied and real value of the constraint where they are applied.';
'ccwts'                  'Equality'         'double'        ''                               'intermediate'  'Scalar defining weighting on contribution equality constraints (0, no constraint, 0<wt<inf imposes constraint "softly", and inf is hard constrained).';
'sc'                     'Equality'         'matrix'        ''                               'intermediate'  'Spectra equality constraints, KxN matrix with NaN where equality contraints are not applied and real value of the constraint where they are applied.';
'scwts'                  'Equality'         'double'        ''                               'intermediate'  'Scalar defining weighting on spectral equality constraints (0, no constraint, 0<wt<inf imposes constraint "softly", and inf is hard constrained).';

'sclc'                   'Settings'         'vector'        ''                               'intermediate'  'Contribution scale axis, vector with M elements otherwise 1:M is used.';
'scls'                   'Settings'         'vector'        ''                               'intermediate'  'Spectra scale axis, vector with N elements otherwise 1:N is used.';
'condition'              'Settings'         'select'        {'none' 'norm'}                  'intermediate'  'Type of conditioning to perform on S and C before each regression step. ''norm'' conditions each spectrum or contribution to its own norm. Conditioning can help stabilize the regression when factors are significantly different in magnitude.';
'normorder'              'Settings'         'select'        {1 2 inf}                         'intermediate'  'order of normalization applied to spectra (to assure convergence). 1 = unit area, 2 = unit length, inf = unit maximum. This normalization is only applied to non-equality constraned components as these are the ones with amultiplicative ambiguity.';
'tolc'                   'Settings'         'double'        ''                               'advanced'      'Tolerance on non-negativity for contributions.';
'tols'                   'Settings'         'double'        ''                               'advanced'      'Tolerance on non-negativity for spectra.';
'cblorder'               'Settings'         'double'        ''                               'intermediate'  'Order of polynomial baseline when using ccon=''baseline''.';
'sblorder'               'Settings'         'double'        ''                               'intermediate'  'Order of polynomial baseline when using scon=''baseline''.';
'ittol'                  'Settings'         'double'        ''                               'advanced'      'Convergence tolerance (change in fit).';
'itmax'                  'Settings'         'double'        ''                               'intermediate'  'Maximum number of iterations.';
'timemax'                'Settings'         'double'        ''                               'advanced'      'Maximum time for iterations in seconds.';
'rankfail'               'Settings'         'select'        {'drop' 'reset' 'random' 'fail'} 'intermediate'  ['How are rank deficiencies handled:' 10 13 ' drop   - drop deficient components from model' 10 13 ' reset  - reset deficient components to initial guess' 10 13 ' random - replace deficient components with random vector' 10 13 ' fail   - stop analysis, give error.']

'initialguessmethod'     'Initial Guess'   'select'        {'none' 'exteriorpts'  'distslct'} 'novice'       'Initial guess (exteriorpts=Identifies points on the exterior of a data space; distslct=selects samples on outside of data space using Euclidean distance).';
'initialguessminnorm'    'Initial Guess'   'double'        ''                                'novice'        'Min norm value when using (exteriorpts) initial guess method';

};

out = makesubops(defs);
