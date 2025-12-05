function model = parafac(varargin)

%PARAFAC Parallel factor analysis for n-way arrays.
%  PARAFAC decomposes an array of order K (where K >= 3, i.e. it has
%  K modes) into the summation over the outer product of K vectors.
%  Missing values must be NaN or Inf.
%
%  INPUTS:
%         x = the multi-way array to be decomposed
%     ncomp = the number of components to estimate. ncomp can also hold a
%             cell array of parameters such as {a,b,c} which will then be
%             used as starting point for the model. The cell array must be
%             the same length as the number of modes and element j contain
%             the scores/loadings for that mode. If one cell element is
%             empty, this mode is guessed based on the remaining modes.
%
%  OPTIONAL INPUTS:
%   initval = If a PARAFAC model is input, the data are fit to this model where
%             the loadings for the first mode (scores) are estimated.
%           = If the loadings are input (e.g. model.loads) these are used
%             as starting values. Type PARAFAC DOC for more help
%   options = is a structure that is used to enable constraints, weighted loss
%             function, govern plotting and display, and input stopping
%             criteria, etc. Type PARAFAC DOC for more help. The
%             constraints are defined per mode - options.constraints{2}
%             hold the constraints for mode 2 loadings. Type HELP
%             CONSTRAINFIT for help on how to set constraints.
%
%  OUTPUT:
%     model = standard model structure (See MODELSTRUCT), or
%     pred  = a structure with PARAFAC predictions [i.e. the loadings
%             for the first mode (scores) are estimated].
%
%  This routine uses alternating least squares (ALS) in combination with
%  a line search. For 3-way data, the intial estimate of the loadings is
%  obtained from the tri-linear decomposition (TLD).
%
%I/O: model   = parafac(x,ncomp,options); % identifies model (calibration step)
%I/O: options = parafac('options');               % returns a default options structure
%I/O: pred    = parafac(xnew,model);              % find scores for new samples given old model
%I/O: parafac demo
%
%See also: DATAHAT, EXPLODE, MODELVIEWER, MPCA, OUTERM, PARAFAC2
%PREPROCESS, TUCKER, UNFOLDM

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Rb, Mar, 2005, introduced new scaling of loadings in PARAFAC (set in
% options.scaletype


% Changes compared to old parafac algorithms
%   New ALS step speeding up the algorithm
%   New settings for constraints but otherwise everything in I/O as usual
%   The total sum of squares now takes weights and possible LAE loss into account
%   Tuckers congruence is included as a diagnostic in model.detail
%   (including a warning if it is too close to -1)
%  Included approximate unimodality

% To do: Search for regresconstr and fix


% EVRIIO SETTINGS
if nargin==0  % LAUNCH GUI
    analysis parafac
    return
end

model = [];

x = varargin{1};
% Define standard options etc.
if ischar(x)
  order = 3;
else
  order = ndims(x);
end

% Generate standard options
standardtol = [1e-6 1e-12 10000 60*60];
constraint = cell(order,1);
for i=1:order
    constraint{i} = constrainfit('options');
end
iterative.fractionold_w = 0;
iterative.cutoff_residuals = 3;
iterative.updatefreq = 100;
scaletype.value = 'norm';
scaletype.text = 'Choose the way to normalize loadings. Default ''norm'' sets to unit length, whereas ''max'' sets the max of the loads to 1. ''area'' sets the area to one. The variance will be in the sample mode loads';
standardoptions = struct('name','options','display','on','plots','final','waitbar','on','weights',[],'stopcriteria',[],'stopcrit',[0 0 0 0],...
    'init',0,'line',1,'algo','als','iterative',iterative,'validation',[],'auto_outlier',[],'scaletype',scaletype,'blockdetails','standard','coreconsist','on','samplemode',1);
standardoptions.preprocessing = {[]};     %See Preprocess
standardoptions.constraints = constraint;
standardoptions.definitions   = @optiondefs;

standardoptions.stopcriteria.relativechange = standardtol(1);
standardoptions.stopcriteria.absolutechange = standardtol(2);
standardoptions.stopcriteria.iterations = standardtol(3);
standardoptions.stopcriteria.seconds = standardtol(4);

standardoptions.auto_outlier.perform = 'off';
standardoptions.auto_outlier.critlevel = 5; % if any sample has a leverage or Q more than critlevel higher than the median, the sample is removed (one sample is removed at a time)
standardoptions.auto_outlier.samplenumberfactor = 1;
standardoptions.auto_outlier.samplefraction = .10; % If more than samplefraction of the samples are removed, increase the critical level
standardoptions.auto_outlier.help='critlevel: if any sample has a leverage or Q more than critlevel higher than the median, the sample is removed (one sample is removed at a time).samplenumberfactor is normally one. If less than 20 samples increase the critical level of leverage and Q by this factor in order not to remove too many samples on small datasets. samplefraction: If more than samplefraction of the samples are removed, increase the critical level';

standardoptions.validation.splithalf = 'off';
standardoptions.validation.split = 'default';
standardoptions.validation.help = 'Change split to random for data with no ordering. See SPLITHALF options for details';
if ischar(x)
    options=standardoptions;
    if nargout==0;
        clear model
        evriio(mfilename,x,options);
    else
        model = evriio(mfilename,x,options);
    end
    return;
end

% Filter standard options for possible user-defined modifications
standardoptions = reconopts(standardoptions,mfilename);
modeltype = 'parafac';

% ADDITIONAL SETTINGS
Show = 100; % How often are fit values shown
timespent0 = clock;
timespent = 0;
pf2opt = 0; % Dummy when pf2 is not fitted

% CHECK INPUT CONSISTENCY AND DEFINE ADDITIONAL METAPARAMETERS
if ~isa(x,'dataset')% Then it's a SDO
  x = dataset(x);
end
xsdo = x; % Save for plotting
inc  = x.includ;
x    = x(inc{:});

[x,nocomp,initval,options,oldmodel,xsize,order]            = checkinputstructure(modeltype,x,varargin{2:end});
options = reconopts(options,'parafac');
nocomp                                                     = nocompcheck(modeltype,nocomp,xsize,order);
[predictmode,nocomp,options]                               = predictcheck(oldmodel,modeltype,nocomp,options);

% Possibly identify outliers first
if strcmpi(options.auto_outlier.perform,'on')&~predictmode
    opt2=options;
    opt2.auto_outlier.perform='off';
    opt2.validation.splithalf='off';
    res = eemoutlier(x,nocomp,opt2);
    x    = x(res.SMPS,:,:);
    inc{1}=inc{1}(res.SMPS);
    xsize = size(x);
    xsdo.include{1}=inc{1}; % otherwise there'll be problems after als when fitting left out samples
end

if predictmode % Check if sample mode is one and the singleton dimension is missing
    expectedmodes = length(oldmodel.datasource{1}.size);
    if ndims(x) == expectedmodes-1  %if we have ONE less mode than the model was based on
        szx = size(x);
        szxsdo = size(xsdo);
        sm = oldmodel.detail.options.samplemode;
        nonsample = setdiff(1:expectedmodes,sm);
        if all(szx==oldmodel.datasource{1}.size(nonsample))    %this matches the variables dimensions
            szx = [szx(1:sm-1) 1 szx(sm:end)];  %new size with "1" inserted to appropriate place
            x = reshape(x,szx);  %reshape, adding the needed singleton dimension
        end
        if all(szxsdo==oldmodel.datasource{1}.size(nonsample))    %this matches the variables dimensions
            szxsdo = [szxsdo(1:sm-1) 1 szxsdo(sm:end)];  %new size with "1" inserted to appropriate place
            xsdo = reshape(xsdo,szxsdo);  %reshape, adding the needed singleton dimension
        end
    end
end

if predictmode % fix if include fields differ
    [x,xsize,xsdo]                                         = fixincl(x,xsdo,oldmodel,xsize,order);
end
[xmod,Missing,MissId]                                      = misscheck(x);
[options,DumpToScreen,plots,alllae,constraints]            = optionscheck(options,modeltype,standardoptions,order);
[DoWeight,WMax,W2,weights,oldweights,iter_rew,iter_w_conv] = weightcheck(options,order,xsize);
progr=0;
if strcmpi(options.waitbar,'on')
    hwait = waitbar(0,[' Fitting ',upper(modeltype),'. Please wait... (Close this figure to cancel analysis)']);
else
    hwait = [];
end
% checkpreprocessing

try
    [xmod,xsdo,prepro] = preprocesscheck(xmod,xsdo,options,predictmode,oldmodel);
catch
    if ishandle(hwait)
        close(hwait)
    end
    rethrow(lasterror)
end


%do a second-pass at checking for missing since preprocessing may have
%introduced more missing data
[xmod,Missing2,MissId2] = misscheck(dataset(xmod));
if Missing2
  %if found, reconcile it with the original missing information
  Missing = 1;
  MissId = union(MissId,MissId2);
end
xmod = xmod.data.include;  %extract data (always as xmod)

% INITIALIZE LOADINGS
constrain_implications = constraintsoptionsoverview(constraints,predictmode,options.samplemode);
if ismodel(oldmodel)
    % If old model given, constraints needs to be changed to fixed in
    % non-sample modes
    [loads,InitString,aux,constraints]=initloads(modeltype,oldmodel,order,Missing,nocomp,xsize,xmod,options.init,options,constrain_implications,xsdo.include);
else
    [loads,InitString,aux]            =initloads(modeltype,initval,order,Missing,nocomp,xsize,xmod,options.init,options,constrain_implications,xsdo.include);
end
[fit,rss,tssx] = residualssq(loads,Missing,MissId,xmod,order,weights,DoWeight,alllae);
[constraints]  = fixedweights(constraints,xsize,tssx);
loads = loads(:); % Make sure loads is vertical

% INITIALIZE ALS
flags = 0;
it = 0;
% for linesearch
oldloads=0;
lineparam.Delta = 4;
acc_pow=2;  % Extrapolate to the iteration^(1/acc_pow) ahead
acc_fail=0; % Indicate how many times acceleration have failed
max_fail=4; % Increase acc_pow with one after max_fail failure
lineparam.acc_pow=acc_pow;
lineparam.acc_fail=acc_fail;
lineparam.max_fail=max_fail;
relchange = 0;

% START ITERATIONS
displaycheck(DumpToScreen,nocomp,order,constraints,modeltype,options,Missing,MissId,xsize,DoWeight,iter_rew,InitString);
while ~flags
    it = it+1;
    oldfit = fit;
    
    % DO ALS
    [loads,out,diagnostics,constraints] = alsstep(loads,xmod,fit,constraints,xsize);
    
    % NORMALIZE LOADINGS
    loads = standardizeloads(loads,constraints,modeltype,options,constrain_implications);
   
    % CHECK FIT, DO LINESEARCH AND MODIFY DATA (weights, missing)
    [xmod,fit,weights,loads,oldloads,lineparam]= moddata(xmod,options,loads,oldloads,Missing,MissId,order,weights,DoWeight,alllae,iter_rew,it,lineparam,modeltype,xsize,WMax,W2);
    
    % CHECK CONVERGENCE
    oldrelchange = relchange;
    
    [flags,endtxt,constraints,pf2opt,relchange,abschange,timespent,isconverged,progr] = convergencecheck(it,fit,oldfit,timespent0,options,constraints,pf2opt,modeltype,loads,iter_rew,iter_w_conv,DumpToScreen,Show,flags,hwait,oldrelchange,progr);
    switch mod(it,50)
        case 0
            %every 25 iterations, do this
            drawnow % Inserted to avoid matlab getting hung up in calculations!
    end
end
options.constraints = constraints; % May contain updated parameters from functional constraints

% MAKE OUTPUT
%%%%%%%%%% ETXRA STEP IF THERE ARE NON-INCLUDED SAMPLES THAT NEED TO HAVE THEIR SCORES PREDICTED
[fit,res,tssqw] = residualssq(loads,Missing,MissId,xmod,order,weights,DoWeight,alllae);

if ~(length(xsdo.includ)<options.samplemode) % Can happen if the last mode is 
                               %sample mode and there is only one sample 
                               %(which can then not be missing - that would 
                               % be silly!)
    if length(xsdo.includ{options.samplemode})~=size(xsdo.data,options.samplemode)
        % Extract leftout data
        Xout = xsdo;
        Xout = delsamps(Xout,xsdo.includ{options.samplemode},options.samplemode,2);
        Xout.includ{options.samplemode} = [1:size(Xout.data,options.samplemode)]';
        inc = Xout.includ;
        Xout = Xout.data(inc{:});
        exclud = delsamps([1:size(xsdo.data,options.samplemode)]',xsdo.includ{options.samplemode});
        i = options.samplemode;
        % FIT PARAFAC
        if strcmpi(modeltype,'parafac')
            % Multiply the loads of all the orders together
            % except for the order to be estimated
            xuflo{i}=outerm(loads,i,1);
            % Regress the actual data on the estimate to get new loads in order i
            yout = unfoldmw(Xout,i)';
            aout = xuflo{i};
            for j = 1:size(Xout,i);
                missout = find(~isnan(yout(:,j)));
                %[x0out{i}(j,:)] = constrainfit(yout(missout,j)'*aout(missout,:),aout(missout,:)'*aout(missout,:),rand(size(Xout,i),nocomp),constraints{i});
                [x0out{i}(j,:)] = constrainfit(yout(missout,j)'*aout(missout,:),aout(missout,:)'*aout(missout,:),rand(1,nocomp),constraints{i});
            end
            x02 = loads;
            x02{i}=repmat(NaN,size(xsdo.data,i),nocomp);
            try
                x02{i}(xsdo.includ{i},:) = loads{i};
            catch
                x02{i}(xsdo.includ{i},:) = loads{i}(xsdo.includ{i},:);

            end
            x02{i}(exclud,:) = x0out{i};
            loads = x02;
        end
    end
end

aux = 0;
model = makeoutput(modeltype,order,loads,nocomp,inputname(1),xmod,xsdo,res,options.stopcrit,relchange,abschange,it,options,tssqw,fit,xsize,aux,timespent,oldmodel,predictmode,iter_rew,weights,InitString,Missing,prepro);
model.detail.converged.isconverged = isconverged;
model.detail.converged.message = endtxt;
if predictmode
  model.modeltype = 'PARAFAC_PRED';
end

if strcmpi(options.validation.splithalf,'on')
    if size(xmod,1)>3
        if DumpToScreen
            disp(' Performing splithalf analysis. Please wait ..')
        end
        opsh = struct('splitmethod',standardoptions.validation.split,'plots','off','display','off','waitbar','off');
        oldmodel = model;
        oldmodel.detail.options.validation.splithalf='off';
        oldmodel.detail.options.waitbar='off';
        oldmodel.detail.options.display='off';
        oldmodel.detail.options.plots='off';
        oldmodel.detail.options.auto_outlier.perform = 'off';
        [sh] = splithalf(xmod,oldmodel,opsh);
        model.detail.validation = sh;
        % triplequal = splithalf*coreconsist*fit (all >0 and <1)
        triplequal = model.detail.validation.splithalf.quality*(model.detail.ssq.perc/100)*(model.detail.coreconsistency.consistency/100);
        % The max of fit*split and fit*corecon in case one is weird
        doublequal = max([model.detail.validation.splithalf.quality*(model.detail.ssq.perc/100) (model.detail.ssq.perc/100)*(model.detail.coreconsistency.consistency/100)]);
        model.detail.validation.qualitycombined = [model.detail.validation.splithalf.quality triplequal doublequal];
        model.detail.validation.qualitycombined_help = 'Three numbers between zero and one. One means good and zero bad. First is splithalf quality. Second is EEMqual - splithalf*coreconsistency*fit - (all >0 and <1) which when high indicates that the model is nice from all three perspectives. The third is the max of fit*split and fit*corecon in case one is not useful. E.g. splithalf may not apply well when some samples contain unique information and core consistency may be close to or below zero when the number of components is very high';
    else
        if DumpToScreen
            disp(' Splithalf analysis not performed. More than three samples needed for splithalf analysis')
        end
        model.detail.validation.splithalf.quality = NaN;
        doublequal = max([(model.detail.ssq.perc/100)*(model.detail.coreconsistency.consistency/100)]);
        model.detail.validation.qualitycombined = [NaN NaN doublequal];
        model.detail.validation.qualitycombined_help = 'Three numbers between zero and one (only last one is given when splithalf analysis is not applied. One means good and zero bad. First is splithalf quality. Second is EEMqual - splithalf*coreconsistency*fit - (all >0 and <1) which when high indicates that the model is nice from all three perspectives. The third is the max of fit*split and fit*corecon in case one is not useful. E.g. splithalf may not apply well when some samples contain unique information and core consistency may be close to or below zero when data is noisy or sometimes when the number of components is very high';
    end
end

% Plot model
if strcmpi(options.waitbar,'on')
    if ishandle(hwait)
        close(hwait)
    end
end
if plots~=0
    %try
        modelviewer(model,x);
    %end
end
if DumpToScreen
    if isfield(model.detail,'tuckercongruence')
        phi = model.detail.tuckercongruence;
        if strcmpi(modeltype,'parafac')
            try
                if min(min(phi-diag(diag(phi))))<-.85
                    disp(' ')
                    disp(' WARNING, some factors are highly negatively correlated. This')
                    disp(' indicates a so-called two-factor degeneracy which means that')
                    disp(' the model is perhaps not valid. Try different preprocessing')
                    disp(' or Tucker modeling if less components can not explain the ')
                    disp(' data sufficiently well.')
                    disp(' ')
                    disp(' Note: If you are using constraints, you may get highly ')
                    disp(' correlated loadings because of that and then you should not')
                    disp(' be discouraged by this warning')
                    disp(' ')
                end
            end
        end
    end
end

%---------------------------------------------------------------------
function [x,nocomp,initval,options,oldmodel,xsize,order]=checkinputstructure(modeltype,varargin)
x = varargin{1};
xsize = size(x);
%xsize(find(xsize==1))=[]; % For two-way mcr
order = length(xsize);
initval =[];
options = [];
oldmodel = [];
% Check if options were given as third input instead of fourth and use that instead
if length(varargin)>3
    if ~ismodel(varargin{4}) & isstruct(varargin{4})
        options = varargin{4};
    end
end
if length(varargin)>2
    if ~ismodel(varargin{3}) & isstruct(varargin{3})
        options = varargin{3};
    elseif isempty(varargin{2})
        %if 3 is a model and 2 is empty, move 3 down to 2 to pick up
        % test below. This allows I/O: parafac(data,[],model,options)
        % which is used in some old code (and old users). Make it look
        % like:      parafac(data,model,[],options)  (which is valid!)
        varargin{2} = varargin{3};
    end
end
% Check if second input is model instead of components and compute nocomp
if length(varargin)>1
  nocomp = varargin{2};
else
  error('Number of components or a model to apply must be supplied')
end
if length(varargin)>1
    if ismodel(varargin{2})
        oldmodel = varargin{2};
        % Then nocomp is not given and needs to be defined
        switch lower(modeltype)
            case {'tucker','tucker - rotated'}
                for i=1:length(size(varargin{2}.loads))-1
                    nocomp(i) = size(varargin{2}.loads{i},2);
                end
            case {'parafac','parafac2','mcr'}
                nocomp = size(varargin{2}.loads{2},2);
        end
    elseif iscell(varargin{2}) % Cell of loads
        initval = varargin{2};
        % Then nocomp is not given and needs to be defined
        switch lower(modeltype)
            case {'tucker','tucker - rotated'}
                for i=1:length(varargin{2})-1
                    nocomp(i) = size(varargin{2}{i},2);
                end
            case {'parafac','parafac2'}
                nocomp=0;
                for i=1:length(varargin{2})
                    nocomp = max(nocomp,size(varargin{2}{i},2));
                end
        end
    elseif size(varargin{2},1)==xsize(1) % Then its MCR and initial scores are given
        initval = varargin{2};
        nocomp = size(initval,2);
    end
end
% Check if old model is given. If so, the order may be wrongly determined
% when only one new sample is input
if length(varargin)>1
    if ismodel(varargin{2})
        if strcmpi(varargin{2}.modeltype,modeltype) % Then it's a model struct
            if strcmpi(modeltype,'tucker')||strcmpi(modeltype,'tucker - rotated')
                ord = length(varargin{2}.loads)-1;
                for i=1:ord
                    nocomp(i) = size(varargin{2}.loads{i},2);
                end
            elseif strcmpi(modeltype,'parafac')||strcmpi(modeltype,'parafac2')
                ord = length(varargin{2}.loads);
                nocomp = size(varargin{2}.loads{2},2);
            else
                error(' Unknown modeltype in NWENGINE')
            end
            if order==ord-1;
                order = ord;
                xsizenew = ones(1,order);
                xsizenew([1:varargin{2}.detail.options.samplemode-1 varargin{2}.detail.options.samplemode+1:end])=xsize;
                xsize = xsizenew;
            elseif order ~=ord
                error(' Disagreement between order in input model and size of input data')
            end
        end
    elseif iscell(varargin{2}) % Then it may be a cell used inside PARAFAC2 when modeling with parafac
        if strcmpi(modeltype,'parafac')
            ord = length(varargin{2});
            nocomp =0;
            for i = 1:length(varargin{2})
                nocomp = max(nocomp,size(varargin{2}{i},2));
            end
            if order==ord-1;
                order = ord;
                xsize = [xsize 1];
            elseif order ~=ord
                error(' Disagreement between order in input model and size of input data')
            end
        end
    end
end

% Run the function that checks for old PARAFAC or MCR constraints
options = mwayopt(options,0);


%---------------------------------------------------------------------
function nocomp = nocompcheck(modeltype,nocomp,xsize,order)

% Chk noncomp correctly defined and initialize specific metaparameters
if strcmpi(modeltype,'tucker')
    if any(rem(nocomp,1))~=0
        error(' The input for the number of components must be integers in TUCKER')
    end
    if length(nocomp)~=length(xsize)
        error([' In TUCKER components must be specified for each mode, e.g. [2 4 ',num2str(3*ones(1,length(xsize)-2)),']'])
    end
    for i=1:order
        if prod(nocomp)/nocomp(i)<nocomp(i)&&nocomp(i)==max(nocomp(:));
            nocomp(i)= prod(nocomp)/nocomp(i);
            warning('EVRI:ParafacNcompLimit',[' Components in mode ',num2str(i),' has been set to ',num2str(nocomp(i)),' as additional components will not add to the fit'])
        end
    end
    if any(nocomp(:)>xsize(:))
        m = find(nocomp(:)>xsize(:));
        if length(m)>1
            warning('EVRI:ParafacNcompLimit',[' The number of components in modes ',num2str(m(:)'),' exceed the dimension of those modes'])
        else
            warning('EVRI:ParafacNcompLimit',[' The number of components in mode ',num2str(m),' exceed the dimension of that mode'])
        end
    end
elseif strcmpi(modeltype,'parafac')||strcmpi(modeltype,'parafac2')
    if length(nocomp)~=1||rem(nocomp,1)~=0
        error([' The input for the number of components must be an integer in ',upper(modeltype)])
    end
elseif length(xsize)==2 % Then its mcr
    if size(nocomp,1)==xsize(1) % Then its initial guess
        nocomp = size(nocomp,2); % nocomp is the number of columns
    end
else
    error('Modeltype not defined in parafac')
end

%---------------------------------------------------------------------
function [Fac,R,diagnostics,constraints] = alsstep(Factors,X,SSX,constraints,xsize)
dbg2 = 2;
xx=X;
N       = length(xsize);
if N==2 % Two-way fitting is simple
    [Fac{1,1},diagnostics{1},constraints{1}]=constrainfit(X*Factors{2},Factors{2}'*Factors{2},Factors{1},constraints{1});
    [Fac{2,1},diagnostics{2},constraints{2}]=constrainfit(X'*Fac{1},Fac{1}'*Fac{1},Factors{2},constraints{2});
    R = X-Fac{1}*Fac{2}';
    R = sum(R(:).^2);
else
    dimX    = xsize;
    X       = reshape(X,dimX(1),prod(dimX(2:end)));
    cdim    = [0 cumsum(dimX)];
    Fac     = Factors;
    A       = cat(1,Factors{:});
    F       = size(A,2);
    AtA     = zeros(F,F,N);
    for n = 2:N
        Ind            = cdim(n) + 1:cdim(n + 1);
        AtA(1:F,1:F,n) = A(Ind,1:F)' * A(Ind,1:F);
    end
    mode_off = double(not(logical(rem(N,2))));
    X        = reshape(X,prod(dimX(1:mode_off + 1)),prod(dimX(mode_off + 2:N)));
    Xtilde   = X * multiplekr(A,cdim,2 + mode_off:N);
    ind_1    = 1:dimX(1);
    
    % Fit mode one
    if mode_off
        K     = N/2 - 1;
        Y     = reshape(Xtilde,[dimX(1:2),F]);
        ind_2 = cdim(2) + 1:cdim(3);
        Aold = A(ind_1,1:F);
        for f = 1:F
            A(ind_1,f) = Y(:,:,f) * A(cdim(2) + 1:cdim(3),f);
        end
        %A(ind_1,1:F) = A(ind_1,1:F) * pinv(prod(AtA(:,:,2:N),3));
        [A(ind_1,1:F),diagnostics{1},constraints{1}]=constrainfit(A(ind_1,1:F),prod(AtA(:,:,2:N),3),Aold,constraints{1});
        AtA(:,:,1)   = A(ind_1,1:F)' * A(ind_1,1:F);
        Aold = A(ind_2,1:F);
        for f = 1:F
            A(ind_2,f) = (A(ind_1,f)' * Y(:,:,f))';
        end
        [A(ind_2,1:F),diagnostics{2},constraints{2}]=constrainfit(A(ind_2,1:F),prod(AtA(:,:,[1 3:N]),3),Aold,constraints{2});
        % A(ind_2,1:F) = A(ind_2,1:F) * pinv(prod(AtA(:,:,[1 3:N]),3));
        AtA(:,:,2)   = A(ind_2,1:F)' * A(ind_2,1:F);
        Fac{1}       = A(ind_1,1:F);
        Fac{2}       = A(ind_2,1:F);
    else
        %A(ind_1,1:F) = Xtilde * pinv(prod(AtA(:,:,2:N),3)); % Original
        %formulation - unconstrained
        [A(ind_1,1:F),diagnostics{1},constraints{1}]=constrainfit(Xtilde,prod(AtA(:,:,2:N),3),A(ind_1,1:F),constraints{1});
        LL = Factors;
        [fg,efg]=datahat2(LL,xx);
        AtA(:,:,1)   = A(ind_1,1:F)' * A(ind_1,1:F);
        K            = (N - 1)/2;
        Fac{1}       = A(ind_1,1:F);
    end
    Xtilde = (multiplekr(A,cdim,1:1 + mode_off)' * X)';
    for k = 1:K % Mode 2 to (order-1)
        a      = 2 * k + mode_off;
        b      = a + 1;
        Xtilde = reshape(Xtilde,prod(dimX(a:b)),F * prod(dimX(b + 1:N)));
        Stride = prod(dimX(b + 1:N));
        if k < K
            Z = multiplekr(A,cdim,b + 1:N);
            Y = zeros(dimX(a),dimX(b),F);
            for f = 1:F
                Y(:,:,f) = reshape(Xtilde(:,(f - 1) * Stride + 1:f * Stride) * Z(:,f),dimX(a),dimX(b));
            end
        else
            Y = reshape(Xtilde,[dimX(a),dimX(b),F]);
        end
        ind_a = cdim(a) + 1:cdim(b);
        ind_b = cdim(b) + 1:cdim(b + 1);
        Aold = A(ind_a,1:F); % Save old loadings before modifying
        for f = 1:F
            A(ind_a,f) = Y(:,:,f) * A(ind_b,f);
        end
        %  A(ind_a,1:F) = A(ind_a,1:F) * pinv(prod(AtA(:,:,[1:a - 1,b:N]),3)); %  Original
        % [A(ind_a,1:F),diagnostics{k+1},constraints{k+1}]=constrainfit(A(i
        % nd_a,1:F),prod(AtA(:,:,[1:a - 1,b:N]),3),A(ind_a,1:F),constraints{k+1});
        %[A(ind_a,1:F),diagnostics{k+1},constraints{k+1}]=constrainfit(A(ind_a,1:F),prod(AtA(:,:,[1:a - 1,b:N]),3),Aold,constraints{k+1});
        [A(ind_a,1:F),diagnostics{a},constraints{a}]=constrainfit(A(ind_a,1:F),prod(AtA(:,:,[1:a - 1,b:N]),3),Aold,constraints{a});
        
        %         if ffff
        %             LL{k+1}=A(ind_a,1:F);
        %             [fg,efg]=datahat(LL,xx);
        %             k+1,sum(efg(:).^2)
        %         end
        
        AtA(:,:,a)   = A(ind_a,1:F)' * A(ind_a,1:F);
        Aold = A(ind_b,1:F);
        for f = 1:F
            A(ind_b,f) = (A(ind_a,f)' * Y(:,:,f))';
        end
        if k == K
            R = A(ind_b,1:F);
        end
        % A(ind_b,1:F) = A(ind_b,1:F) * pinv(prod(AtA(:,:,[1:a,b + 1:N]),3)); % Original
        % [A(ind_b,1:F),diagnostics{end},constraints{end}]=constrainfit(A(ind_b,1:F),prod(AtA(:,:,[1:a,b + 1:N]),3),A(ind_b,1:F),constraints{end});
        %[A(ind_b,1:F),diagnostics{end},constraints{end}]=constrainfit(A(ind_b,1:F),prod(AtA(:,:,[1:a,b + 1:N]),3),Aold,constraints{end});
        [A(ind_b,1:F),diagnostics{b},constraints{b}]=constrainfit(A(ind_b,1:F),prod(AtA(:,:,[1:a,b + 1:N]),3),Aold,constraints{b});
        %         if ffff
        %             LL{end}=A(ind_b,1:F);
        %             [fg,efg]=datahat(LL,xx);
        %             3,sum(efg(:).^2)
        %         end
        AtA(:,:,b)   = A(ind_b,1:F)' * A(ind_b,1:F);
        Fac{a}       = A(ind_a,1:F);
        Fac{b}       = A(ind_b,1:F);
        if k < K
            Z = kr(A(ind_b,1:F),A(ind_a,1:F));
            Y = zeros(Stride,F);
            for f = 1:F
                Y(:,f) = (Z(:,f)' * Xtilde(:,(f - 1) * Stride + 1:f * Stride))';
            end
            Xtilde = Y;
        end
    end
    R = SSX - 2 * sum(diag(A(ind_b,1:F)' * R)) + sum(sum(prod(AtA,3),1),2);
end


%---------------------------------------------------------------------
function Z = multiplekr(Factors,cdim,ord)
% Compute multiple Khatri-Rao product.
% Author: Giorgio Tomasi
%         giorgio.tomasi@gmail.com
%
if isempty(ord)
    Z = [];
    return
end
dimX                  = diff(cdim);
cpro                  = cumprod(dimX(ord));
F                     = size(Factors,2);
Z                     = zeros(prod(dimX(ord)),F);
Z(1:dimX(ord(1)),1:F) = Factors(cdim(ord(1)) + 1:cdim(ord(1) + 1),1:F);
for m = 1:length(ord) - 1
    Z(1:cpro(m + 1),1:F) = kr(Factors(cdim(ord(m + 1)) + 1:cdim(ord(m + 1) + 1),1:F),Z(1:cpro(m),1:F));
end


%---------------------------------------------------------------------
function AB = kr(A,B)
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

% Copyright, 1998 -
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
% $ Version 2.01 $ May 2001 $ Error in helpfile - A and B reversed $ RB $ Not compiled $

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

%---------------------------------------------------------------------
function [ssq,ressq,tssqw,xest] = residualssq(loads,Missing,MissId,x,order,weights,DoWeight,alllae)

xest = datahat2(loads);
xsq = xest;
if DoWeight % Check to see if the fit has changed significantly
    if alllae
        xsq = abs((x-xsq).*weights);
    else
        xsq = ((x-xsq).*weights).^2;
    end
else
    if alllae
        xsq = abs(x-xsq);
    else
        xsq = (x-xsq).^2;
    end
end
if Missing
    xsq(MissId)=0;
end
ssq = sum(xsq(:));
if nargout>1
    ressq = cell(1,order);
    for i = 1:order
        xx = xsq;
        for j = 1:order
            if i ~= j
                xx = sum(xx,j);
            end
        end
        xx = squeeze(xx);
        ressq{i} = xx(:);
    end
end
if nargout>2
    if DoWeight
        if alllae
            tssqw = abs(x.*weights);
        else
            tssqw = (x.*weights).^2;
        end
    else
        if alllae
            tssqw = abs(x);
        else
            tssqw = x.^2;
        end
    end
    if Missing
        tssqw(MissId)=0;
    end
    
    tssqw = sum(tssqw(:));
end
if Missing
    xsq(MissId)=0;
end

%---------------------------------------------------------------------
function [x,Missing,MissId]=misscheck(x)
% CHECK FOR MISSING
switch 2
    case 1
        % Use simpler approach that does not take so long to compute
        % does not support missing. (NOTE: no longer faster than 2)
        if any(isnan(x.data(:)));
            Missing = 1;
            MissId  = find(isnan(x.data));
            meanX   = mean(x.data(find(~isnan(x.data))));
            x.data(MissId)=meanX;
        else
            Missing = 0;
            MissId = [];
        end
        
    case 2
        %supports missing data and mdcheck's "toomuch = 'exclude'" option
        mdop=mdcheck('options');
        mdop.max_missing = 0.9999;
        mdop.tolerance = [1e-4 10];
        flag = 0;
        try
            [flag,missmap] = mdcheck(squeeze(x),mdop);
        catch
            if findstr('too much missing data',lower(lasterr))
                error('Too much missing data to perform analysis');
            end
        end
        if flag
            Missing = 1;
            MissId  = find(missmap);
            meanX   = mean(x.data(~missmap));
            x.data(MissId)=meanX;
        else
            Missing = 0;
            MissId = [];
        end
        
    case 3
        % Even faster than 1, but does not support missing
        if any(isnan(x.data(:)));
            Missing = 1;
            missmap = isnan(x.data);
            MissId  = find(missmap);
            meanX   = mean(x.data(~missmap));
            x.data(MissId)=meanX;
        else
            Missing = 0;
            MissId = [];
        end
        
end


%---------------------------------------------------------------------
function [predictmode,nocomp,options] = predictcheck(oldmodel,modeltype,nocomp,options)

% Define if predicting or fitting new model
predictmode = 0;
if ismodel(oldmodel)
    if strcmpi(oldmodel.modeltype,modeltype) % Then it's a model struct
        predictmode = 1;
    else
        warning('EVRI:ParafacModelMismatch',[' Input fitted model (',upper(oldmodel.modeltype),') is not the same type as the function called (',upper(modeltype),')'])
    end
end
if predictmode
    % Take options from prior model if it exist (but exchange with input options if such are given)
    try
        newoptions = oldmodel.detail.options;  %use options from model
        for tocopy = {'blockdetails' 'plots' 'display' 'waitbar'};  %EXCEPT for these items
            newoptions.(tocopy{:}) = options.(tocopy{:});
        end
        options = newoptions;
        if strcmpi(modeltype,'parafac')||strcmpi(modeltype,'parafac2')
            nocomp = size(oldmodel.loads{2},2);
        elseif strcmp(lower(modeltype),'tucker')
            for i=1:length(oldmodel.loads)-1
                nocomp(i) = size(oldmodel.loads{i},2);
            end
        end
    end
    % Samplemode from model is used
    options.samplemode = oldmodel.detail.options.samplemode;
end


%---------------------------------------------------------------------
function [options,DumpToScreen,plots,alllae,constraints] = optionscheck(options,modeltype,standardoptions,order)

if isempty(options)
    options = standardoptions;
end
% Add any missing fields in options
if strcmpi(modeltype,'parafac')
    %    options = reconopts(options,parafac('options'));
    % disp('CHANGE THIS IN parafac')
    options = reconopts(options,parafac('options'));
elseif strcmpi(modeltype,'tucker')
    options = reconopts(options,tucker('options'));
elseif strcmpi(modeltype,'parafac2')
    options = reconopts(options,parafac2('options'));
else
    error('Modeltype not defined in NWENGINE - 2.5')
end
% Add scaletype because it's only given for parafac
try
    options.scaletype.value;
catch
    options.scaletype.value = 'norm';
end
%Handle Preprocessing
try
    if isempty(options.preprocessing);
        options.preprocessing = {[]};  %reinterpet as empty cell
    end
    if ~isa(options.preprocessing,'cell');
        options.preprocessing = {options.preprocessing};  %insert into cell
    end
catch
    options.preprocessing = {[]};  %reinterpet as empty cell
end
if strcmpi(modeltype,'parafac')|strcmpi(modeltype,'parafac2')
    if length(options.constraints)<order % wrong number of constraints
        for i=length(options.constraints)+1:order
            options.constraints{i}=standardoptions.constraints{1};
        end
        if strcmpi(options.display,'on')
            disp(' Constraints not properly defined (not defined for all modes) - adding defaults for missing constraints')
        end
    end
elseif strcmpi(modeltype,'tucker')|strcmpi(modeltype,'tucker - rotated')
    if length(options.constraints)<order+1 % wrong number of constraints
        oo = options.constraints{end}; % For the last mode (core)
        for i=length(options.constraints):order
            options.constraints{i}=standardoptions.constraints{1};
        end
        options.constraints{order+1}=oo;
        if strcmpi(options.display,'on')
            disp(' Constraints not properly defined (not defined for all modes + core) - using defaults for missing constraints')
        end
    end
else
    error('Modeltype not properly defined in NWENGINE')
end
DumpToScreen = options.display;
if strcmpi(DumpToScreen,'on')
    DumpToScreen = 1;
else
    DumpToScreen = 0;
end
plots = options.plots;
if strcmpi(plots,'on')||strcmpi(plots,'final')
    plots = 1;
elseif strcmpi(plots,'all')
    plots = 2;
else
    plots = 0;
end
constraints = options.constraints;
% For standard options through parafac(options), the order of X unknown hence dimension
% of constraints may be wrong. This is corrected below
if length(constraints)~=order
    for i=length(constraints)+1:order
        constraints{i}=constraints{i-1};
    end
end
alllae = 0; % binary for checking LAE fitting
cou = 0;
for i = 1:order
    try
        if isfield(constraints{i},'lae') & constraints{i}.lae
            cou = cou+1;
        end
    end
end
if cou==order
    alllae=1;
end
if ~ismember(options.blockdetails,{'compact','standard','all'})
    error(['OPTIONS.BLOCKDETAILS not recognized. Type: ''help ' modeltype ''''])
end

tol = options.stopcriteria;
usertol  = options.stopcrit;
for j=1:length(usertol);
    %run through vector assigning each non-zero item we've got
    if usertol(j)==0;
        continue;  %skip item if zero
    end
    switch j
        case 1
            tol.relativechange = usertol(1);
        case 2
            tol.absolutechange = usertol(2);
        case 3
            tol.iterations = usertol(3);
        case 4
            tol.seconds = usertol(4);
    end
end
tol = reconopts(tol,standardoptions.stopcriteria);  %insert any missing items
tol = [tol.relativechange tol.absolutechange tol.iterations tol.seconds];  %convert to vector (what is expected by everything else from here out)

options.stopcrit = tol;


%---------------------------------------------------------------------
function [DoWeight,WMax,W2,weights,oldweights,iter_rew,iter_w_conv] = weightcheck(options,order,xsize)

weights = options.weights;
WMax=0;
W2=0;
oldweights = 0;
iter_rew = 0;
iter_w_conv=0;
if length(size(weights))~=order
    DoWeight = 0;
elseif all(size(weights)==xsize)
    DoWeight = 1;
    WMax     = max(abs(weights(:)));
    W2       = weights.*weights;
else
    DoWeight = 0;
end

if strcmpi(weights,'iterative')
    DoWeight = 1;
    weights  = ones(xsize);
    oldweights = weights;
    WMax     = max(abs(weights(:)));
    W2       = weights.*weights;
    iter_rew = 1;
    iter_w_conv = sum(weights(:).^2);
end


%---------------------------------------------------------------------
function []=displaycheck(DumpToScreen,nocomp,order,constraints,modeltype,options,Missing,MissId,xsize,DoWeight,iter_rew,InitString)
% Show algorithmic settings etc.
if DumpToScreen
    disp(' '),disp([' Fitting new ',upper(modeltype),' ...'])
    txt=[];
    for i=1:order-1
        txt=[txt num2str(xsize(i)) ' x '];
    end
    txt=[txt num2str(xsize(order))];
    disp([' Input: ',num2str(order),'-way ',txt, ' array'])
    disp([' A ',num2str(nocomp),'-component model will be fitted'])
    for i=1:order
        disp([' Mode ',num2str(i),': ',lower(constraints{i}.type)])
    end
    tol = options.stopcrit;
    disp(' Convergence criteria:')
    disp([' Relative change in fit : ',num2str(tol(1))])
    disp([' Absolute change in fit : ',num2str(tol(2))])
    disp([' Maximum iterations     : ',num2str(tol(3))])
    w = fix(tol(4)/(60*60*24*7));
    d = fix((tol(4)-w*7*24*60*60)/(60*60*24));
    h = fix((tol(4)-w*7*24*60*60-w*24*60*60)/(60*60));
    m = fix((tol(4)-w*7*24*60*60-w*24*60*60-h*60*60)/(60));
    s = fix((tol(4)-w*7*24*60*60-w*24*60*60-h*60*60-m*60)/(1));
    tt = ' ';
    if w,tt = [tt,' ',num2str(w),'w;'];end
    if d,tt = [tt,' ',num2str(d),'d;'];end
    if h,tt = [tt,' ',num2str(h),'h;'];end
    if m,tt = [tt,' ',num2str(m),'m;'];  end
    tt = [tt,' ',num2str(s),'s.'];
    disp([' Maximum time           : ',tt])
    if strcmpi(modeltype,'parafac')
        if strcmpi(options.algo,'als')
            disp(' Algorithm : ALS')
        else
            disp([' Algorithm : ',upper(options.algo),' (no constraints possible)'])
        end
    end
    if Missing
        disp([' ', num2str(100*(length(MissId)/prod(xsize))),'% missing values']);
    else
        disp(' No missing values')
    end
    if DoWeight
        if iter_rew
            disp(' Iteratively re-weighted optimization will be performed')
        else
            disp(' Weighted optimization will be performed using input weights')
        end
    end
    disp(InitString)
end



%---------------------------------------------------------------------
function [xmod,fit,weights,loads,oldloads,lineparam]= moddata(xmod,options,loads,oldloads,Missing,MissId,order,weights,DoWeight,alllae,iter_rew,it,lineparam,modeltype,xsize,WMax,W2)

% GET FIT
[fit,out1,out2,xest] = residualssq(loads,Missing,MissId,xmod,order,weights,DoWeight,alllae);
% If Weighted regression is to be used, do majorization to make a transformed data array to be fitted in a least squares sense
if DoWeight && it > 1
    if iter_rew % Modify weights acc to residuals
        WMax     = max(abs(weights(:)));
        W2       = weights.*weights;
    end
    xmod = reshape(xest,xsize) + (WMax^(-2)*W2).*(xmod - reshape(xest,xsize));
    % GET FIT
    [fit,out1,out2,xest] = residualssq(loads,Missing,MissId,xmod,order,weights,DoWeight,alllae);
end
%Iterative preproc
if iter_rew && rem(it,options.iterative.updatefreq)==0% Modify weights acc to residuals - biweight of Tukey acc. to Phillips 1983
    oldweights = weights;
    weights = xmod-xest;
    weight(find(isnan(weights)))=0;
    s = median(weights(find(~isnan(weights))));
    weights(:) = (1./(1+((weights(:)/s)/2.8).^2));
    weights(find(isnan(weights)))= 0;
    iter_w_conv = sum((oldweights(:)-weights(:)).^2)/sum(oldweights(:).^2);
    % GET FIT
    [fit,out1,out2,xest] = residualssq(loads,Missing,MissId,xmod,order,weights,DoWeight,alllae);
end
% HANDLE MISSING
if Missing
    xmod(MissId)=xest(MissId);
end
% DO LINESEARCH
if (it/2 == round(it/2) && options.line == 1 && it>5)   % Every fifth iteration do a line search if ls == 1
    % for linesrch2 method (not used anymore)
    %     if it==5,
    %         lineparam.Delta = 5; % Steplength is initially set to 5
    %     end
    if ~strcmpi(modeltype,'parafac2') % Linesearch does not work for pf2 but it is implicitly done inside the pf models run in pf2
        %[loads,Delta] = linesrch(xmod,loads,oldloads,DoWeight,weights,alllae,Missing,MissId,Delta);
        lineparam.it = it;
        %         lll=1; % Choose new linesearch (1) or old (2)
        %         if lll==1
        [loads,lineparam] = linesrch(xmod,loads,oldloads,DoWeight,weights,alllae,Missing,MissId,lineparam);
        %         else
        %             [loads,lineparam] = linesrch2(xmod,loads,oldloads,DoWeight,weights,alllae,Missing,MissId,lineparam);
        %         end
        % GET FIT
        [fit,out1,out2,xest] = residualssq(loads,Missing,MissId,xmod,order,weights,DoWeight,alllae);
    end
else
    % Save the last estimates of the loads
    oldloads = loads;
end

%---------------------------------------------------------------------
function [loads,ScaleMode] = standardizeloads(loads,constraints,modeltype,options,constrain_implications);
%STANDARDIZELOADS Utility for standardizing loadings.
%

%Copyright Eigenvector Research, Inc. 2002-2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% rb, 20/9/04, removed scaling of tucker loads when core is constrained
% rb, 20/3/05, reversed the scaling in parafac so first is largest

if strcmpi(modeltype,'parafac')
    constrainedmodes     = constrain_implications.constrainedmodes;
    freetoscalemodes     = constrain_implications.freetoscalemodes;
    fixedmodes           = constrain_implications.fixmodes;
    if length(constrainedmodes)<length(loads)  % Can happen when you fit one sample to an existing model
        constrainedmodes     = [constrainedmodes 1];
        freetoscalemodes     = [freetoscalemodes 0];
    end
    ScaleMode = options.samplemode;
    if freetoscalemodes(ScaleMode)==0,
        ScaleMode = find(freetoscalemodes'==1);
        if isempty(ScaleMode)
            ScaleMode=0;
        end
    end
    if sum(freetoscalemodes==1)>1 % Else no scaling
        ScaleMode = ScaleMode(1);
        for i=1:length(loads)
            if (i ~=ScaleMode) && freetoscalemodes(i)
                if strcmpi(options.scaletype.value,'norm')
                    SS = sum(loads{i}.^2,1);
                    SS(find(SS==0))=1;% If a zero value is encountered
                    Scal = 1./sqrt(SS);
                    Scal = sign(sum(loads{i}.^3,1)).*Scal;
                    loads{i} = loads{i}*diag(Scal); % normalization leads to wrong model but that's corrected in the next update of the next mode, and for the last mode no normalization is performed, so that's ok, unless last mode is fixed.
                    loads{ScaleMode} = loads{ScaleMode}*diag(Scal.^(-1));%ii = i+1;
                elseif strcmpi(options.scaletype.value,'max')
                    [SS,out] = max(abs(loads{i}));
                    for i2=1:size(loads{i},2) % chk sign
                        if loads{i}(out(i2),i2)<0
                            SS(i2)=-SS(i2);
                        end
                    end
                    SS(find(SS==0))=1;% If a zero value is encountered
                    Scal = 1./(SS);
                    loads{i} = loads{i}*diag(Scal); % normalization leads to wrong model but that's corrected in the next update of the next mode, and for the last mode no normalization is performed, so that's ok, unless last mode is fixed.
                    loads{ScaleMode} = loads{ScaleMode}*diag(Scal.^(-1));%ii = i+1;
                elseif strcmpi(options.scaletype.value,'area')
                    SS = sum(loads{i},1);
                    SS(find(SS==0))=1;% If a zero value is encountered
                    Scal = 1./(SS);
                    Scal = sign(sum(loads{i}).^3).*Scal;
                    loads{i} = loads{i}*diag(Scal); % normalization leads to wrong model but that's corrected in the next update of the next mode, and for the last mode no normalization is performed, so that's ok, unless last mode is fixed.
                    loads{ScaleMode} = loads{ScaleMode}*diag(Scal.^(-1));%ii = i+1;
                else
                    error('The option field scaletype value must be set to ''norm'' or ''max''.')
                end
            end
        end
    else % Check if there are fixed elements in some modes so that some columns are fixed and other not and equalize the columns then
        if ~isempty(ScaleMode) % If there is a mode that can be scaled
            ScaleMode = ScaleMode(1);
            for i=1:length(loads)
                if (i ~=ScaleMode)
                    if ~isempty(constraints{i}.fixed.values)
                        vl = constraints{i}.fixed.values;
                        for f=1:size(loads{i},2)
                            if any(~isnan(vl(:,f)))
                                fxmodes(i,f) = 1;
                                nonfxmodes(i,f) = 0;
                            else
                                fxmodes(i,f) = 0;
                                nonfxmodes(i,f) = 1;
                            end
                        end
                    else
                        for f=1:size(loads{i},2)
                            fxmodes(i,f) = 0;
                            nonfxmodes(i,f) = 1;
                        end
                    end
                else
                    fxmodes(i,:) = repmat(0,1,size(loads{i},2));
                    nonfxmodes(i,:) = repmat(1,1,size(loads{i},2));
                end
                if constraints{i}.fixed.weight==-1 % Then completely fixed
                    fxmodes(i,1:size(loads{i},2))=1;
                end
            end
            % Now chk the average scale of fxmodes columns and make that the scale
            % of the nonfixed columns (put the scale in ScaleMode)
            fxcol = find(sum(fxmodes([1:ScaleMode-1 ScaleMode+1:end],:)));
            nonfxcol = find(sum(fxmodes([1:ScaleMode-1 ScaleMode+1:end],:))==0);
            if ~isempty(fxcol)
                for i=1:length(loads)
                    if (i ~=ScaleMode)
                        SS = sum(loads{i}.^2,1);
                        SS(find(SS==0))=1;% If a zero value is encountered
                        Scal = 1./sqrt(SS);
                        TargetScal = mean(Scal(fxcol)).^(-1);
                        loads{i}(:,nonfxcol) = loads{i}(:,nonfxcol)*diag(Scal(nonfxcol)*TargetScal); % normalization leads to wrong model but that's corrected in the next update of the next mode, and for the last mode no normalization is performed, so that's ok, unless last mode is fixed.
                        loads{ScaleMode}(:,nonfxcol) = loads{ScaleMode}(:,nonfxcol)*diag(Scal(nonfxcol).^(-1))*TargetScal;%ii = i+1;
                    end
                end
            end
        end
    end
    % Order the components
    if ~fixedmodes && ScaleMode
        SS = sum(loads{ScaleMode}.^2,1);
        [a,b]=sort(SS);
        for i=1:length(loads)
            loads{i} = loads{i}(:,flipud(b(:)));
        end
    end
else
    error('Modeltype not known in STANDARDIZELOADS')
end



%---------------------------------------------------------------------
function [flags,endtxt,constraints,pf2opt,relchange,abschange,timespent,isconverged,progr] = convergencecheck(it,fit,oldfit,timespent0,options,constraints,pf2opt,modeltype,loads,iter_rew,iter_w_conv,DumpToScreen,Show,flags,hwait,oldrelchange,progr)
endtxt = ' ';
isconverged=0;
%disp(sprintf('On iteration %g ALS fit = %g',iter,ssq));
if it > 3
    abschange = abs(oldfit-fit);
    relchange = abschange/fit;
    timespent = etime(clock,timespent0);
    if relchange < options.stopcrit(1)
        % Check if nonnegativity is obeyed. Otherwise shift to another
        % nonnegativity algorithm
        stop = 1;
        for cc=1:length(loads);
            try
                if strcmp(constraints{cc}.type,'nonnegativity')
                    if any(loads{cc}<0)
                        if constraints{cc}.nonnegativity.algorithmforglobalmodel==0
                            stop=0;
                            constraints{cc}.nonnegativity.algorithmforglobalmodel=1;
                            if strcmpi(modeltype,'parafac2')
                                pf2opt.constraints = constraints;
                            end
                        elseif constraints{cc}.nonnegativity.algorithmforglobalmodel==1
                            stop=0;
                            constraints{cc}.nonnegativity.algorithmforglobalmodel=2;
                            if strcmpi(modeltype,'parafac2')
                                pf2opt.constraints = constraints;
                            end
                        end
                    end
                end
            end
        end
        if stop % Nonnegativity ok, so go ahead and stop
            flags = 1;
            endtxt=' Iterations terminated based on relative change in fit error';
            isconverged=1;
        end
        % if iterative reweighting is used, check if weights converged
        % otherwise dont stop yet
        if iter_rew
            if iter_w_conv < 1e-4
                flags = 1;
                endtxt=' Iterations terminated based on relative change in fit error (and change in iterative weights)';
                isconverged=1;
            else
                flags = 0;
            end
        end
    elseif abschange < options.stopcrit(2)
        flags = 1;
        endtxt=' Iterations terminated based on absolute change in fit error (numbers got small). Hence, the algorithm did not converge. You may want to simply multiply your data by a big number to avoid stopping because of small absolute loss values';
        isconverged=0;
    elseif it > options.stopcrit(3)-1
        flags = 1;
        endtxt = ' Iterations terminated based on maximum iterations. Hence, the algorithm did not converge';
        isconverged=0;
    elseif timespent > options.stopcrit(4)
        flags = 1;
        endtxt = ' Iterations terminated based on maximum time. Hence, the algorithm did not converge';
        isconverged=0;
    elseif isnan(fit)
        flags = 1;
        endtxt = ' Non-feasible numerical solution. Hence, the algorithm did not converge';
        isconverged=0;
    elseif options.waitbar
        if ~ishandle(hwait);  %waitbar closed
            flags = 1;
            endtxt = ' NOTE - Iterations terminated by user prior to convergence. Hence, the algorithm did not converge';
            isconverged=0;
        else
            flags=0;
        end
    else
        flags = 0;
    end
    if flags==1
        if DumpToScreen
            disp(' '),disp('    Iteration    Rel. Change         Abs. Change         sum-sq residuals'),disp(' ')
            fprintf(' %9.0f       %12.10f        %12.10f        %12.10f    \n',it,relchange,abschange,fit);
            disp(' ')
            if ~isempty(findstr(endtxt,'the algorithm did not converge')) % Then show as a warning
                warning('EVRI:ParafacGeneral',endtxt)
            else
                disp(endtxt)
            end
        end
    end
else
    abschange = 0;
    timespent = 0;
    relchange = 0;
end
if rem(it,Show) == 0&&DumpToScreen
    if it == Show||rem(it,Show*30) == 0
        disp(' '),disp('    Iteration    Rel. Change         Abs. Change         sum-sq residuals'),disp(' ')
    end
    fprintf(' %9.0f       %12.10f        %12.10f        %12.10f    \n',it,relchange,abschange,fit);
    if options.plots==2|strcmpi(options.plots,'all')
        for pj=1:length(loads)
            subplot(floor((length(loads)+1)/2),2,pj)
            if strcmpi(modeltype,'parafac2')&&pj == 1
                plot(loads{1}.P{1}*loads{1}.H),axis tight
                title(['Mode 1 (only first slab)'])
            else
                plot(loads{pj}),axis tight
                title(['Mode ',num2str(pj)])
            end
        end
        drawnow
    end
end
if it>1
    if relchange~=0&&strcmpi(options.waitbar,'on')
        if ishandle(hwait)
            if iter_rew
                % MODIFY TAKING ITERATIVE WEIGHTS CHANGES INTO ACCOUNT
                r1=(1e-4/iter_w_conv).^.3;
                r2=(options.stopcrit(1)/relchange).^.3;
                waitbar( min(r1,r2),hwait)
            else
                try
                    oldprogr=progr;
                    progr=(options.stopcrit(1)/((relchange+oldrelchange)/2)).^.3;
                    progr=max([progr oldprogr]);
                catch
                    66
                    progr=(options.stopcrit(1)/((relchange+oldrelchange)/2)).^.3;
                end
                g=waitbar(progr,hwait);
            end
        end
    end
end



%---------------------------------------------------------------------
function [dA,lineparam] = linesrch(x,A,Ao,DoWeight,weights,alllae,Missing,MissId,lineparam)

%Copyright Eigenvector Research, Inc. 2005-2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

dbg=0;
acc_pow=lineparam.acc_pow;
acc_fail=lineparam.acc_fail;
max_fail=lineparam.max_fail;
it = lineparam.it;

Fitnow = fithis(A,x,DoWeight,weights,alllae,Missing,MissId);
acc=0;
dA = extrapol(A,Ao,it^(1/acc_pow));

Fitnew = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);
if Fitnew>Fitnow
    acc_fail=acc_fail+1;
    dA=A;
    if acc_fail==max_fail,
        acc_pow=acc_pow+1+1;
        acc_fail=0;
    end
end

lineparam.acc_pow=acc_pow;
lineparam.acc_fail=acc_fail;
lineparam.max_fail=max_fail;


%---------------------------------------------------------------------
function dA = extrapol(A,Ao,delta)

dA = A;
for i=1:length(A)
    if isstruct(A{i}) % Assuming that it's then parafac2
        dA{i}.H = Ao{i}.H+delta*(A{i}.H-Ao{i}.H);
        for j = 1:length(A{i}.P);
            dA{i}.P{j} = Ao{i}.P{j}+delta*(A{i}.P{j}-Ao{i}.P{j});
        end
    else
        dA{i} = Ao{i}+delta*(A{i}-Ao{i});
    end
end


%---------------------------------------------------------------------
function [dA,DeltaMin] = linesrch2(x,A,Ao,DoWeight,weights,alllae,Missing,MissId,Delta);

%Copyright Eigenvector Research, Inc. 2005-2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
DeltaMin = Delta;
Delt = Delta.Delta;
dbg=0;

if nargin<8
    Delt=5;
else
    Delt=max(2,Delt);
end

Fit1 = fithis(A,x,DoWeight,weights,alllae,Missing,MissId);
regx=[1 0 0 Fit1];
dA = extrapol2(A,Ao,Delt);
Fit2 = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);
regx=[regx;1 Delt Delt.^2 Fit2];

while Fit2>Fit1
    Delt=Delt*.6;
    dA = extrapol2(A,Ao,Delt);
    Fit2 = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);
    regx=[regx;1 Delt Delt.^2 Fit2];
end
dA = extrapol2(A,Ao,2*Delt);
Fit3 = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);
regx=[regx;1 2*Delt (2*Delt).^2 Fit3];
while Fit3<Fit2
    Delta=1.8*Delt;
    Fit2=Fit3;
    dA = extrapol2(A,Ao,Delt);
    Fit3 = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);
    regx=[regx;1 2*Delt (2*Delt).^2 Fit2];
end
% Add one point between the two smallest fits
[a,b]=sort(regx(:,4));
regx=regx(b,:);
Delta4=(regx(1,2)+regx(2,2))/2;
dA = extrapol2(A,Ao,Delta4);
Fit4 = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);
regx=[regx;1 Delta4 Delta4.^2 Fit4];

reg=pinv(regx(:,1:3))*regx(:,4);
%DeltaMin=2*reg(3);

DeltaMin.Delta=-reg(2)/(2*reg(3));
dA = extrapol2(A,Ao,DeltaMin.Delta);
Fit = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);

if dbg
    plot(regx(:,2),regx(:,4),'o'),
    hold on
    x=linspace(0,max(regx(:,2))*1.2);
    plot(x',[ones(100,1) x' x'.^2]*reg),
    hold off
    drawnow
    pause
end
% If Fit has not improved just pick the original
if Fit>Fit1
    dA = A;
end

%---------------------------------------------------------------------
function dA = extrapol2(A,Ao,delta)

dA = A;
for i=1:length(A)
    if isstruct(A{i}) % Assuming that it's then parafac2
        dA{i}.H = A{i}.H+delta*(A{i}.H-Ao{i}.H);
        for j = 1:length(A{i}.P);
            dA{i}.P{j} = A{i}.P{j}+delta*(A{i}.P{j}-Ao{i}.P{j});
        end
    else
        dA{i} = A{i}+delta*(A{i}-Ao{i});
    end
end


%---------------------------------------------------------------------
function fit = fithis(param,x,DoWeight,weights,alllae,Missing,MissId)
xest = datahat2(param);
%Iterative preproc
if DoWeight
    if alllae
        xsq = abs((x-datahat2(param)).*weights);
    else
        xsq = ((x-datahat2(param)).*weights).^2;
    end
else
    if alllae
        xsq = abs(x-datahat2(param));
    else
        xsq = (x-datahat2(param)).^2;
    end
end
if Missing
    xsq(MissId)=0;
end
fit = sum(xsq(:));

%---------------------------------------------------------------------
function [xmod,xsdo,prepro] = preprocesscheck(x,xsdo,options,predictmode,oldmodel);
xmod = x;
try
    if isempty(options.preprocessing);
        options.preprocessing = {[]};  %reinterpet as empty cell
    end
    if ~isa(options.preprocessing,'cell');
        options.preprocessing = {options.preprocessing};  %insert into cell
    end
catch
    options.preprocessing = {[]};  %reinterpet as empty cell
end
if ~predictmode
    %calibration mode preprocessing
    if ~isempty(options.preprocessing{1});
        try
            [xsdo] = preprocess('calibrate',options.preprocessing{1},xsdo);
            [xmod,prepro] = preprocess('calibrate',options.preprocessing{1},x);
        catch
            error('Unable to preprocess - selected preprocessing may not be valid for multi-way data');
        end
    else
        prepro = [];
    end
    prepro = {prepro}; %make into cell
else
    if ~isempty(oldmodel.detail.preprocessing);
        prepro = oldmodel.detail.preprocessing{1};
    else
        prepro = [];
    end
    if ~isempty(prepro);
        try
            xmod = preprocess('apply',prepro,xmod);
        catch
            error('Unable to preprocess - selected preprocessing may not be valid for multi-way data');
        end
    end
    prepro = {prepro}; %make into cell
end
xmod = xmod.data;



%---------------------------------------------------------------------
function model = makeoutput(modeltype,order,x0,nocomp,inputname,x,Xsdo,res,tol,relchange,abschange,iter,options,tssqw,ssq,xsize,aux,timespent,oldmodel,predictmode,iter_rew,weights,InitString,Missing,prepro);

% Save the model as a structured array
if strcmpi(modeltype,'parafac')
    model = modelstruct('PAR',order);
elseif strcmpi(modeltype,'tucker')
    model = modelstruct('TUC',order);
elseif strcmpi(modeltype,'parafac2')
    model = modelstruct('PA2',order);
else
    error('Modeltype not known in NWENGINE - 9')
end
model.date = date;
model.time = clock;
model.loads                = x0;
model.datasource{1} = getdatasource(Xsdo);
model.description{2} = ['Constructed on ',date,'at ',num2str(model.time(4)),':',num2str(model.time(5)),':',num2str(model.time(6))];
if strcmpi(modeltype,'parafac')
    if nocomp==1
        model.description{3} = [num2str(nocomp),' PARAFAC component'];
    else
        model.description{3} = [num2str(nocomp),' PARAFAC components'];
    end
elseif strcmpi(modeltype,'tucker')
    model.description{3} = [num2str(nocomp),' TUCKER components'];
elseif strcmpi(modeltype,'parafac2')
    if nocomp == 1
        model.description{3} = [num2str(nocomp),' PARAFAC2 component'];
    else
        model.description{3} = [num2str(nocomp),' PARAFAC2 components'];
    end
else
    error('Modeltype not known in parafac - 10')
end
model.datasource{1}.name = inputname;
model = copydsfields(Xsdo,model,[],{1 1});
Xsdo2 = Xsdo;
inc_allsamples = Xsdo2.include;
inc_allsamples{options.samplemode} = 1:size(Xsdo2,options.samplemode);
xhat = datahat2(x0);
Xsdo2 = Xsdo2.data(inc_allsamples{:});
rawres = Xsdo2-xhat;
if length(size(weights))==length(size(xhat))
    if all(size(weights)==size(xhat))
        rawres = (rawres.*weights);
    end
end
if Missing
    rawres(isnan(Xsdo2))=0;
end
if strcmpi(options.blockdetails,'all')
    model.detail.data{1} = Xsdo;
    model.pred{1} = xhat;
    model.detail.res{1} = rawres;
    if iter_rew
        model.detail.iteratively_found_weights=weights;
    end
end
% Make residual limits
if ~strcmpi(options.blockdetails,'compact')
    if ~predictmode
        inc_here=Xsdo.includ;
        resopts.algorithm = 'chi2';
        % Remove outliers but in other modes just take what's there
        % (removed variables are not there)
        for i=1:length(inc_here)
            if i~=options.samplemode
                inc_here{i}=1:size(rawres,i);
            end
        end
        try
            reslim95 = residuallimit(rawres(inc_here{:}),.95,resopts);
            reslim99 = residuallimit(rawres(inc_here{:}),.99,resopts);
            temp = [];
            temp.lim95 = reslim95;
            temp.lim99 = reslim99;
            model.detail.reslim = temp;
        end
    else
        model.detail.reslim  = oldmodel.detail.reslim;
        model.detail.coreconsistency.consistency = NaN;
    end
end
if strcmpi(modeltype,'parafac')
    if ~strcmpi(options.blockdetails,'compact')
        try
            if strcmpi(options.coreconsist,'on')
                x00 = x0;
                x00{options.samplemode} = x00{options.samplemode}(Xsdo.includ{options.samplemode},:);
                [Consistency,G,E] = corcondia(x,x00,weights,0);
                model.detail.coreconsistency.consistency = Consistency;
                model.detail.coreconsistency.core = G;
                model.detail.coreconsistency.detail = E;
                % Calculate Tuckers congruence coefficients
                model.detail.tuckercongruence = ncosine(x00,x00);
            end
        catch
            model.detail.coreconsistency = NaN;
        end
    end
    model.detail.algo = options.algo;
    model.detail.initialization = InitString;
end
% Make 'leverages'
for i=1:order
    if i==options.samplemode
        model.ssqresiduals{i} = repmat(NaN,size(Xsdo2,i),1);
        try
            incc = Xsdo.include{options.samplemode};
        catch
            incc = xsize(i); % May go wrong with include field if last mode is 1 sample in prediction mode
        end
        if length(incc)<size(Xsdo,options.samplemode)
            % Add all residuals including left-out samples
            resex = repmat(NaN,size(Xsdo,options.samplemode),1);
            rawres = permute(rawres,[options.samplemode 1:options.samplemode-1 options.samplemode+1:ndims(rawres)]);
            resex = sum(rawres(:,:)'.^2)'; 
            res{1}=resex;
        end
        model.ssqresiduals{i}=res{i};
    else
        model.ssqresiduals{i} = res{i};
    end
    if ~predictmode
        inc  = model.detail.includ{i,1};
        L = model.loads{i};
        if isstruct(L) % If so, then its parafac2 mode 1
            % Do leverage on average loadings
            LL = L.P{1}*L.H;
            for k=2:length(L.P)
                LL = LL+L.P{k}*L.H;
            end
            L = LL;
        end
        if size(L,1)>1
            if any(isnan(L(:)))
                model.tsqs{i,1} = nan(size(L,1),1);
            else
                LL = L*pinv(eps+L'*L/(size(L,1)-1));
                model.tsqs{i,1}       = sum(L.*LL,2);
            end
        else
            model.tsqs{i,1} = nan(size(L,1),1);
        end
        try
            if length(nocomp)>=i
                nc = nocomp(i); % For tucker
            else
                nc = nocomp(1);
            end
        catch
            nc = nocomp;
        end
        if length(model.detail.includ{i,1})>nocomp
            model.detail.tsqlim{i,1} = tsqlim(length(model.detail.includ{i,1}),nc,95);
        else
            model.detail.tsqlim{i,1} = NaN;
        end
    else % Predictmode => steal from old model and use old sample covariance for samples
        model.detail.tsqlim{i,1} = oldmodel.detail.tsqlim{i,1};
        if i~=oldmodel.detail.options.samplemode;
            model.tsqs{i,1}          = oldmodel.tsqs{i,1};
        else % For the samplemode calucalte new leverages based on old covariance
            L = model.loads{i};
            oldL = oldmodel.loads{i};
            inc  = oldmodel.detail.includ{i,1};
            if length(inc)>1
                LL = L*pinv(oldL(inc,:)'*oldL(inc,:)/(size(oldL(inc,:),1)-1));
                model.tsqs{i,1}  = sum(L.*LL,2);
            else
                model.tsqs{i,1}  = nan(size(L,1),1);
            end
        end
    end
    
end
model.detail.means{1,1}    = mean(Xsdo.data(Xsdo.includ{1},:)); %mean of X-block
model.detail.stds{1,1}     = std(Xsdo.data(Xsdo.includ{1},:));  %mean of X-block
model.detail.stopcrit      = tol;
model.detail.critfinal     = [relchange abschange iter timespent];
model.detail.options       = options;
model.detail.preprocessing = prepro;   %copy calibrated preprocessing info into model
if strcmpi(modeltype,'parafac')
    tssq = sum(x(:).^2); % Least squares total sum of squares for componentwise fit (unlike the total which is weighted)
    % Make a version of xhar where excluded samples are excluded
    x0_out = x0;
    if options.samplemode > length(size(x)) % Then the last mode is sample mode and is also singleton - hence, no missing samples
    else
        x0_out{options.samplemode}=x0_out{options.samplemode}(Xsdo.include{options.samplemode},:);
    end
    xhat = outerm(x0_out,0,1);
    xhatorthogonalized = xhat;
    for i = 1:nocomp
        xhatorthogonalized(:,i) = xhat(:,i) - xhat(:,[1:i-1 i+1:nocomp])*inv(xhat(:,[1:i-1 i+1:nocomp])'*xhat(:,[1:i-1 i+1:nocomp]))*(xhat(:,[1:i-1 i+1:nocomp])'*xhat(:,i));
    end
    ssxhat = sum(xhat.^2);
    ssxhatorth = sum(xhatorthogonalized.^2);
    ssxhat_rel_to_ssX = 100*(ssxhat/tssq);
    ssxhatorth_rel_to_ssX = 100*(ssxhatorth/tssq);
    ssxhat_rel_to_hat = 100*(ssxhat/sum(ssxhat));
    ssxhatorth_rel_to_hat = 100*(ssxhatorth/sum(ssxhat));
    s = dataset([ssxhat(:) ssxhat_rel_to_ssX(:) ssxhat_rel_to_hat(:) ssxhatorth(:) ssxhatorth_rel_to_ssX(:) ssxhatorth_rel_to_hat(:)]);
    s.name='Explained ssq per component';
    s.labelname{2} = 'Fit values';
    s.label{2}={'Sum of squares','Fit (% X)','Fit (% model)','Unique sum of squares','Unique Fit (% X)','Unique Fit (% model)'  };
    s.axisscale{1}= (1:nocomp)';
    s.axisscalename{1}= 'Component number';
    model.detail.ssq.total = tssqw;
    model.detail.ssq.residual = ssq;
    model.detail.ssq.percomponent = s;
    model.detail.ssq.perc = 100*(1-model.detail.ssq.residual/model.detail.ssq.total);
end



%---------------------------------------------------------------------
function [x0,InitString,aux,constraints]=initloads(modeltype,x0,order,Missing,nocomp,xsize,x,initialization,options,constrain_implications,inc);
%INITLOADS Utility for initializing loadings in PARAFAC, TUCKER etc.
% [x0,InitString,aux,constraints]=initloads(x0,order,Missing,nocomp,xsize,x
% ,initialization,options);

%Copyright Eigenvector Research, Inc. 2002-2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%rb,jul,2004, Bug using many components and tld initialization arrays

constraints = cell(order,1);
if iscell(x0) || ismodel(x0) || isstruct(x0)  % Old loadings given
    [x0,InitString,constraints]=oldloadsgiven(modeltype,x0,order,Missing,nocomp,xsize,x,initialization,options,inc);
    options.constraints = constraints;
elseif order==2 && size(x0,1)==xsize(1) % Then its mcr and input scores are given
    % Fit a model with fixed scores
    x02 = {x0,pinv(x)*x0};
    x0 = x02;
    InitString = ' Using input scores for initialization';
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
x0 = standardizeloads(x0,options.constraints,modeltype,options,constrain_implications);
if ~(exist('aux')==1)
    aux         = cell(order,1);
end

%---------------------------------------------------------------------
function [x0,InitString,constraints]=oldloadsgiven(modeltype,x0,order,Missing,nocomp,xsize,x,initialization,options,inc);
if strcmpi(modeltype,'parafac')||strcmpi(modeltype,'parafac2')
    
    if iscell(x0)
        allmodesgiven = 1;
        for i=1:length(x0)
            if isempty(x0{i})
                if allmodesgiven==0
                    error('The cell array of initial values must contain loadings for at least (all-1) modes')
                else
                    ithis = i;
                    allmodesgiven=0;
                end
            end
        end
        if allmodesgiven
            x0 = x0;
            InitString = ' Using old values for initialization';
        else
            Z = repmat(1,1,nocomp);
            for mo=order:-1:1
                if mo~=ithis
                    Z = krb(x0{mo},Z);
                end
            end
            xunf = permute(x,[ithis 1:ithis-1 ithis+1:order]);
            x0{ithis}=(xunf(:,:)*Z)*pinv(Z'*Z);
            InitString = [' Using old values for initialization (Mode ',num2str(ithis),' found from given loads'];
        end
        
        constraints = options.constraints;
        
    elseif ismodel(x0)
        
        if ~(strcmpi(x0.modeltype,'parafac')||strcmpi(x0.modeltype,'parafac2'))
            error([' Input x0 is not a ',upper(modeltype),' model (name in model structure should be ',upper(modeltype),')'])
        else
            % Use prior model given in x0 to extract loadings
            initloads = x0.loads;
            constraints = options.constraints;
            sampmode = x0.detail.options.samplemode;
            x0 = x0.loads;
            %set scores to random values (the actual size may be different from the old model scores)
            x0{options.samplemode} =rand(xsize(options.samplemode),nocomp);
            if strcmpi(modeltype,'parafac2')
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
                    o=constrainfit('options');
                    o.type = 'Dont change';
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
    elseif strcmpi(class(x0),'struct')
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
                    o=constrainfit('options');
                    o.type = 'Dont change';
                    o.fixed.weight = -1; % Skip update ('completely' fixed)
                    constraints{i} = o;
                else
                    o=constrainfit('options');
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
    if strcmpi(modeltype,'parafac2')&i==1
    else
        if (size(x0{i},1)~=size(x,i))&(size(x,i)~=1)
            % Size doesn't match but try to see if it is just due to excluded
            % samples
            try
                x0{i}= x0{i}(inc{i},:);
            end
            if (size(x0{i},1)~=size(x,i))&(size(x,i)~=1)
                error('Initial loadings given are not compatible with the size of the array')
            end
        end
    end
end

%---------------------------------------------------------------------
function varargout = manystarts(x,nocomp,modeltype,options,initialization)

aux =1;
if strcmpi(modeltype,'parafac')|strcmpi(modeltype,'parafac2')
    
    interimopt             = options;
    interimopt.stopcrit(3) = 80;
    interimopt.plots       = 'off';
    interimopt.display     = 'off';
    interimopt.waitbar     = 'off';
    
    if strcmpi(modeltype,'parafac')
        modeltype = 'parafac'; % Intermediate while testing;
    end
    
    interimopt.init   = 1;
    interimopt2 = interimopt;
    interimopt2.stopcrit(3) = 30; % To avoid that it gets too good a start!
    eval(['bestmodel = ',lower(modeltype),'(x,nocomp,0,interimopt2);']);
    allssq = bestmodel.detail.ssq.residual;
    aux = bestmodel.detail.options.constraints; %save these because they containt the current parameters in case of functional constraints
    for ccount = 2:initialization(1)
        if ccount<4
            interimopt.init = ccount;
        else
            interimopt.init = 3;
        end
        try 
            eval(['currentmodel = ',lower(modeltype),'(x,nocomp,interimopt);']);
        catch
            interimopt.init = 1;
            eval(['currentmodel = ',lower(modeltype),'(x,nocomp,interimopt);']);
        end
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

%---------------------------------------------------------------------
function varargout=rationalstart(x,nocomp,modeltype,options)
if strcmpi(modeltype,'parafac')||strcmpi(modeltype,'parafac2')
    xsize = size(x);
    if length(size(x)) == 3&& ~any(isnan(x(:)))&&~any(isinf(x(:))) &&~(sum(xsize<nocomp)>1) && ~any(xsize==1)
        % Initialize with TLD estimates
        m = tld(x,nocomp,0,0);
        x0 = m.loads;
        InitString = ' Using direct trilinear decomposition for initialization';
    elseif all(xsize>nocomp)&&~any(isnan(x(:)))&&~any(isinf(x(:))) % Use atld
        x0=atld(x,nocomp,0);
        InitString = ' Using fast approximation for initialization (ATLD)';
    else
        [x0,InitString]=semirationalstart(x,nocomp,modeltype);
    end
    varargout{1}=x0;
    varargout{2}=InitString;
    
elseif strcmpi(modeltype,'tucker')
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

%---------------------------------------------------------------------
function varargout=parafaconecompstart(x,nocomp,modeltype,options)

if strcmpi(modeltype,'parafac')||strcmpi(modeltype,'tucker')||strcmpi(modeltype,'parafac2')
    
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
        x = x-datahat2(model);
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


%---------------------------------------------------------------------
function varargout=semirationalstart(x,nocomp,modeltype)

if strcmpi(modeltype,'parafac')||strcmpi(modeltype,'parafac2')
    order = length(size(x));
    xsize = size(x);
    if ~any(isnan(x(:)))&&~any(isinf(x(:)))
        for j = 1:length(size(x))
            [u,s,v] = svds(reshape( permute(x,[j 1:j-1 j+1:order]),xsize(j),prod(xsize([1:j-1 j+1:order]))));
            x0{1,j} = u(:,1:min(nocomp,size(u,2)));
            if size(x0{1,j},2)<nocomp   % add extra columns because orthogonalization has removed some
                x0{1,j} = [x0{1,j} rand(xsize(j),nocomp-size(x0{1,j},2))];
            end
        end
    else % When missing data
        for j = 1:length(size(x))
            %[t,p,Mean,Fit,RelFit] = pcanipals(reshape( permute(x,[j 1:j-1 j+1:order]),xsize(j),prod(xsize([1:j-1 j+1:order]))),nocomp,0);
            t = pcanipals(reshape( permute(x,[j 1:j-1 j+1:order]),xsize(j),prod(xsize([1:j-1 j+1:order]))),nocomp,0);
            x0{1,j} = t;
            if size(x0{1,j},2)<nocomp   % add extra columns because orthogonalization has removed some
                x0{1,j} = [x0{1,j} rand(xsize(j),nocomp-size(x0{1,j},2))];
            end
        end
    end
    InitString = ' Using singular values for initialization';
    varargout{1}=x0;
    varargout{2}=InitString;
    
elseif strcmpi(modeltype,'tucker')
    order = length(size(x));
    xsize = size(x);
    if ~any(isnan(x(:)))&&~any(isinf(x(:)))
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
            t = pcanipals(reshape( permute(x,[j 1:j-1 j+1:order]),xsize(j),prod(xsize([1:j-1 j+1:order]))),nocomp(j),0);
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


%---------------------------------------------------------------------
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

%---------------------------------------------------------------------
function varargout=usecompression(x,nocomp,modeltype,options)

% options.display = 'off';
% options.plot    = 'off';
if strcmpi(modeltype,'parafac')||strcmpi(modeltype,'parafac2')
    data = x;
    xsize=size(data);
    
    % Compress successively
    for i=1:length(xsize)
        if strcmpi(modeltype,'parafac2')&&i==1
            disp(' Mode 1 not compressed in PARAFAC2')
            comp{i}.data=data;
        else
            disp([' Compressing data mode ',num2str(i)])
            comp{i}=compress(data,i,min(size(data,i),(nocomp + max(nocomp,4)))); 
            % generally take nocomp*2 but take nocomp+4 for low number of components
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
        if strcmpi(modeltype,'parafac2')&i==1;
            3;
        else
            if strcmpi(modeltype,'parafac');
                m = parafac(comp{i}.data,x0,op);
            else strcmpi(modeltype,'parafac2');
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



%---------------------------------------------------------------------
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

model = nmodel(loads);
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
    
    
    model = nmodel(loads);
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


%---------------------------------------------------------------------
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


%---------------------------------------------------------------------
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

%---------------------------------------------------------------------
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

I=size(X,1);
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


%---------------------------------------------------------------------
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

if (nargin < 3 | ~iscell(scl))
    scl = cell(1,3);
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
xhat = nmodel(loads);
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


%---------------------------------------------------------------------
function Vdd=simtrans(aa,bb,ev)
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


%---------------------------------------------------------------------
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



%---------------------------------------------------------------------
function y = nansum(x,mode)
nans = isnan(x);
i = find(nans);
x(i) = zeros(size(i));
x = permute(x,[mode 1:mode-1 mode+1:length(size(x))]);
x = reshape(x,size(x,1),prod(size(x))/size(x,1))';
y = sum(x);


%---------------------------------------------------------------------
function optionssetting = constraintsoptionsoverview(options,predictmode,samplemode);

constrainedmodes     = [];
freetoscalemodes     = [];
fixmodes             = 0;
for i=1:length(options)
    if strcmpi(options{i}.type,'unconstrained')
        constrainedmodes(i)=0;
    else
        constrainedmodes(i)=1;
    end
    if strcmpi(options{i}.type,'unconstrained')|strcmpi(options{i}.type,'nonnegativity')|strcmpi(options{i}.type,'unimodality')|strcmpi(options{i}.type,'unimodality_nonon')|strcmpi(options{i}.type,'orthogonality')|strcmpi(options{i}.type,'L1')|strcmpi(options{i}.type,'l1 penalty')
        freetoscalemodes(i)=1;
    else
        freetoscalemodes(i)=0;
    end
    if strcmpi(options{i}.type,'columnwise') % Then maybe fixed
        for i2=1:length(options{i}.columnconstraints)
            if any([3 5 6 20]==options{i}.columnconstraints{i2}(1))
                fixmodes = 1;
            end
        end
    elseif strcmpi(options{i}.type,'equality')|strcmpi(options{i}.type,'rightprod')
        fixmodes = 1;
    end
    if strcmpi(options{i}.type,'dont change')
        fixmodes = 1;
    end
end
if predictmode
    constrainedmodes([1:samplemode-1 samplemode+1:end])=1;
    freetoscalemodes([1:samplemode-1 samplemode+1:end])=0;
    fixmodes = 1;
end
optionssetting.constrainedmodes     = constrainedmodes;
optionssetting.freetoscalemodes     = freetoscalemodes;
optionssetting.fixmodes             = fixmodes;






%---------------------------------------------------------------------
function [MultPhi,Phis] = ncosine(factor1,factor2);
%NCOSINE multiple cosine/Tuckers congruence coefficient
%
% [MultPhi,Phis] = ncosine(factor1,factor2);
%
% ----------------------INPUT---------------------
%
% factor1   = cell array with loadings of one model
% factor2   = cell array with loadings of one (other) model
%     If factor1 and factor2 are identical then
%        the multiple cosine of a given solution is
%          estimated; otherwise the similarity of the
%          two different solutions is given
%
% ----------------------OUTPUT---------------------
%
% MultPhi   Is the multiple cosine of the model
% Phis      Is the cosine between components in
%          individual component matrices arranged
%          as [PhiA;PhiB ...]


if length(factor1)~=length(factor2)
    error(' factor1 and factor2 must hold components of same sizes in NCOSINE.M')
end

L1=factor1{1};
L2=factor2{1};
for f=1:size(L1,2)
    L1(:,f)=L1(:,f)/norm(L1(:,f));
    L2(:,f)=L2(:,f)/norm(L2(:,f));
end
%GT correction
Phis=L1'*L2;
MultPhi=Phis;

for i=2:length(factor1)
    L1=factor1{i};
    L2=factor2{i};
    for f=1:size(L1,2)
        L1(:,f)=L1(:,f)/norm(L1(:,f));
        L2(:,f)=L2(:,f)/norm(L2(:,f));
    end
    phi=(L1'*L2);
    MultPhi=MultPhi.*phi;
    Phis=[Phis;phi];
end



%---------------------------------------------------------------------
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
            Zm(1:Facprodc1,1:DimXprodc1)=kron(A',Zm(1:Facprodc0,1:DimXprodc0));
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

%---------------------------------------------------------------------
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

%---------------------------------------------------------------------
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

%---------------------------------------------------------------------
function [constraints]=fixedweights(constraints,xsize,tssx);
% Add corrected weights for fixed elements
for ci=1:length(constraints) % For each mode
    for cj = 1:length(constraints{ci}.columnconstraints) % for each component
        if any(constraints{ci}.columnconstraints{cj}==5) % Fixed elements
            if constraints{ci}.fixed.weight>0
                pos = ~isnan(constraints{ci}.fixed.values);
                val = constraints{ci}.fixed.values(pos);
                weight = constraints{ci}.fixed.weight;
                weight = weight*tssx/(prod(xsize)/xsize(ci)); %make weights relative to sum-squared signal of one average variable
                %normalize weights relative to sum-squared values of constraints
                sscon = sum(val.^2);
                sscon(sscon==0) = 1;
                weight = weight./sscon;
                constraints{ci}.fixed.weight_adjusted=weight;
            end
        end
    end
end



%---------------------------------------------------------------------
function AB = krb(A,B);
%KRB Khatri-Rao-Bro product
%
% The columnwise Khatri-Rao-Bro product (Harshman, J.Chemom., 2002, 198-205)
% For two matrices with similar column dimension the khatri-Rao-Bro product
% is krb(A,B) = [kron(A(:,1),B(:,1)) .... kron(A(:,F),B(:,F))]
%
% I/O AB = krb(A,B);
%
[I,F]=size(A);
[J,F1]=size(B);

if F~=F1
    error(' Error in krb.m - The matrices must have the same number of columns')
end

AB=zeros(I*J,F);
for f=1:F
    ab=B(:,f)*A(:,f).';
    AB(:,f)=ab(:);
end

%---------------------------------------------------------------------
function options = mwayopt(options,verb)

% Checks options structure. If structure is old PARAFAC or old MCR, it is
% transformed to new format. Choose verb = 1, for output on screen
%
%I/O options = mwayopt(options,verb);

if nargin<2
    verb = 0;
end
% Chk if old parafac options are used for constraints and change to new
% type

if verb
    disp(' Translating options into new form')
end
if ~isempty(options)
    if isfield(options,'constraints') % PARAFAC options
        if isfield(options.constraints{1},'functionname')
            for jj = 1:length(options.constraints) % Modify constraints for each mode
                myconstr = options.constraints{jj};
                if strcmp(myconstr.functionname,'regresconstr') ...
                        | ~isstruct(myconstr.nonnegativity) ...
                        | ~isstruct(myconstr.unimodality)
                    % Then its the old form
                    if verb;
                        disp([' Mode ',num2str(jj)])
                    end
                    onew = constrainfit('options');
                    if myconstr.nonnegativity
                        onew.type = 'nonnegativity';
                        onew.nonnegativity.algorithmforglobalmodel = myconstr.nonnegativity;
                        if verb
                            disp(['    Nonnegativity fixed'])
                        end
                    elseif myconstr.unimodality
                        onew.type = 'unimodality';
                        if verb
                            disp(['    Unimodality fixed'])
                        end
                        onew.type = 'unimodality';
                    elseif myconstr.orthogonal
                        onew.type = 'orthogonality';
                        if verb
                            disp(['    Orthogonality fixed'])
                        end
                    elseif isfieldcheck(myconstr,'opt.columnorthogonal') & myconstr.columnorthogonal
                        onew.type = 'column orthogonal';
                        if verb
                            disp(['    Column orthogonality fixed'])
                        end
                    else
                        if verb
                            disp(['    No modifications made in this mode'])
                        end
                    end
                    options.constraints{jj} = onew;
                end
            end
        end
        if verb
            disp(' ')
            disp(' ')
            disp(' Please note!!')
            disp(' Only nonnegativity, unimodality and orthogonality are handled.')
            disp(' For more advanced constraints rather use the new format directly')
            disp(' (type opt = parafac(''options'');')
        end
        
    end
end


if isfield(options,'functionname')
    if strcmpi(options.functionname,'mcr') % Then its the old form
        newoptions = parafac('options');
        if verb
            disp(' Options initmethod, confidencelimit not available in new MCR')
        end
        try
            if strcmpi(options.display,'off')
                newsoptions.display = 'off';
            end
        end
        try
            newoptions.plots = options.plots;
        end
        try
            newoptions.preprocessing = options.preprocessing;
        end
        try
            newoptions.blockdetails= options.blockdetails;
        end
        try
            newoptions.plots = options.plots;
        end
        
        try
            newoptions.crit(1:2) = options.alsoptions.ittol;
            newoptions.crit(3) = options.alsoptions.itmax;
            newoptions.crit(4) = options.alsoptions.timemax;
        end
        try
            if strcmpi(options.alsoptions.ccon,'fastnnls')
                newoptions.constraints{1}.type = 'nonnegativity';
                if verb
                    disp(['    Nonnegativity set in mode 1'])
                end
            end
        end
        try
            if ~isempty(options.alsoptions.cc)
                newoptions.constraints{1}.type = 'columnwise';
                if strcmpi(options.alsoptions.ccon,'fastnnls')
                    id = [5 1];
                else
                    id = 5;
                end
                idd{1} = id;
                for j=2:size(options.alsoptions.cc,1) % Number of columns
                    idd{j}=id;
                end
                newoptions.constraints{1}.columnconstraints=idd; % If three columns
            end
            newoptions.constraints{1}.fixed.values = options.alsoptions.ccon';
            newoptions.constraints{1}.fixed.weight = options.alsoptions.ccwts;
            if isinf(newoptions.constraints{1}.fixed.weight)
                newoptions.constraints{1}.fixed.weight=1;
            end
        end
        
        try
            if ~isempty(options.alsoptions.sc)
                newoptions.constraints{2}.type = 'columnwise';
                if strcmpi(options.alsoptions.scon,'fastnnls')
                    id = [5 1];
                else
                    id = 5;
                end
                idd{1} = id;
                for j=2:size(options.alsoptions.sc,1) % Number of columns
                    idd{j}=id;
                end
                newoptions.constraints{2}.columnconstraints=idd; % If three columns
            end
            newoptions.constraints{2}.fixed.values = options.alsoptions.scon';
            newoptions.constraints{2}.fixed.weight = options.alsoptions.scwts;
            if isinf(newoptions.constraints{2}.fixed.weight)
                newoptions.constraints{2}.fixed.weight=1;
            end
        end
        options = newoptions;
    end
end

%---------------------------------------------------------------------
function [x,xsize,Xsdo] = fixincl(x,Xsdo,model,xsize,ord)
inc=Xsdo.includ;
applyit=0;
for i=1:ord
    if i~=model.detail.options.samplemode
        if length(Xsdo.include{i,1})~=length(model.detail.includ{i,1}) ...
                || any(Xsdo.includ{i,1} ~= model.detail.includ{i,1});
            Xsdo.includ{i,1} = model.detail.includ{i,1};
            xsize(i)=length(model.detail.includ{i,1});
            inc=Xsdo.includ;
            applyit=1;
%             x = x(inc{:});  % Bad if applied twice (i.e., repeated for i=3)
        end
    end
end
% Sample mode is already excluded in the first mode in x, so if inc{1} is
% longer than size(x,1), fix it
if exist('inc')==1
    if length(inc{1})>size(x,1)|max(inc{1})>size(x,1)
        inc{1}=1:size(x,1);
    end
    % Hard exclude x using inc once after inc is set for all i
    if applyit
        x    = x(inc{:});
    end
end

% OLD - before bug of 2015 Dec 3
% for i=1:ord
%     if i~=model.detail.options.samplemode
%         if length(Xsdo.include{i,1})~=length(model.detail.includ{i,1}) ...
%                 || any(Xsdo.includ{i,1} ~= model.detail.includ{i,1});
%             Xsdo.includ{i,1} = model.detail.includ{i,1};
%             xsize(i)=length(model.detail.includ{i,1});
%             inc=Xsdo.includ;
%             x = x(inc{:});
%         end
%     end
% end

function [xhat,resids] = datahat2(model,data)
%DATAHAT2 Calculates the model estimate and residuals of the data.
%
% This is a speedup version for internal use in PARAFAC
%
%I/O: xhat = datahat2(model);                %estimates model fit of data
%I/O: [xhat,resids] = datahat2(model,data);  %estimates model fit of new data
%I/O: [xhat,resids] = datahat2(loadings,data); %estimate loadings fit of new data
%I/O: datahat demo
%

if iscell(model)
   xhat = nmodel(model);
else
   xhat = nmodel(model.loads);
end
if nargin>1
    resids = data-xhat;
end




%-----------------------------------------------------
function out = optiondefs()
defs = {
    %Name                         Tab             Datatype        Valid                         Userlevel       %Description
    'display'                     'Display'       'select'        {'on' 'off'}                  'novice'        'Turn text output to command window on or off';
    'plots'                       'Display'       'select'        {'final' 'all' 'off'}         'novice'        'Turn plotting of final model on or off. By choosing ''all'' you can choose to see the loadings as the iterations proceed. The final plot can also be produced using the function MODELVIEWER after the model has been fitted.';
    'weights'                     'Algorithm'     'matrix'        ''                            'advanced'      'Weight array for weighted least squares fitting. Must be the same size as data';
    'stopcriteria.relativechange'     'Algorithm'     'double'        'float'                       'intermediate'  'Stopping criteria: Relative change in model required for stop.'
    'stopcriteria.absolutechange'     'Algorithm'     'double'        'float'                       'intermediate'  'Stopping criteria: Absolute change in model required for stop.'
    'stopcriteria.iterations'         'Algorithm'     'double'        'int(1:inf)'                  'intermediate'  'Stopping criteria: Maximum number of iterations allowed.'
    'stopcriteria.seconds'            'Algorithm'     'double'        'float(1:inf)'                'intermediate'  'Stopping criteria: Maximum number of time (in seconds) allowed.'
    'init'                        'Algorithm'     'double'        'int(0:100)'                  'intermediate'  'Governs how the initial guess for the loadings is obtained. Mostly use 0 for default or 10 for models that are difficult to fit. See HTML documentation for details (>> doc parafac).';
    'line'                        'Algorithm'     'boolean'       ''                            'advanced'      'Turn line-search on or off ("off" is not normally recommended)';
    'iterative'                   'Iterative'     'struct'        ''                            'advanced'      'Settings for iterative reweighted least squares fitting (see help on weights).';
    'iterative.fractionold_w'     'Iterative'     'double'        'float'                       'advanced'      'Deafult 0. If > 0 (and <1) iteratively refined weights are linear combination of new and old weights. Used for stabilizing purposes but modification is not normally recommended.';
    'iterative.cutoff_residuals'  'Iterative'     'double'        'float'                       'advanced'      'Defines the cutoff for large residuals in terms of the number of robust standard deviations. Default is 3 meaning all residuals larger than 3 robust standard deviations are set to zero weight.';
    'iterative.updatefreq'        'Iterative'     'double'        'float'                       'advanced'      'To speed convergence, the iteratively refined weights are only updated infrequently (default every 100 iterations).';
    'scaletype.value'             'Scale Type'    'select'        {'norm' 'max' 'area'}                'advanced'      'Choose how to normalize the loadings. Default ''norm'' sets each loading vector to unit length, whereas ''max'' sets the maximum of each loading vector to 1. This will give Fmax values in fluorescence EEM data. ''area'' sets the area to one. The variance will be in the sample mode loadings.';
    'blockdetails'                'Display'       'select'        {'compact','standard','all'}  'novice'        'Governs amount of information returned in model. Compact means that only essential parameters are retained whereas e.g. residuals of X etc. are not kept.'
    'coreconsist'                 'Algorithm'     'select'        {'on' 'off'}                  'advanced'      'Governs calculation of core consistency (turning off may save time with large data sets and many components).';
    'samplemode'                  'Algorithm'     'double'        'int(1:inf)'                  'advanced'      'Defines which mode should be considered the sample (i.e. object) mode.';
    'preprocessing'               'Algorithm'     'cell(vector)'  ''                            'advanced'      'Preprocessing structures for each mode.';
    'constraints'                 'Algorithm'     'cell(vector)'  'loadfcn=optionsgui'          'novice'        'Used to employ constraints on the parameters (opens a separate instance of OptionsGUI).';
    'validation.split'            'Validation'    'select'         {'default' 'random'}         'advanced'        'Method used when performing split half analysis. Choose Random when the data is ordered.';
    'auto_outlier.perform'            'Outlier'       'select'         {'on' 'off'}                 'advanced'      'Perform outlier detection';
    'auto_outlier.critlevel'          'Outlier'       'double'        'int(1:inf)'                  'advanced'      'If any sample has a leverage or Q more than critlevel higher than the median, the sample is removed (one sample is removed at a time).';
    'auto_outlier.samplenumberfactor' 'Outlier'       'double'        'int(1:inf)'                  'advanced'      'Samplenumberfactor is normally one. If less than 20 samples increase the critical level of leverage and Q by this factor in order not to remove too many samples on small datasets.';
    'auto_outlier.samplefraction'     'Outlier'       'double'        'float(0.01:1)'               'advanced'      'If more than samplefraction of the samples are removed, increase the critical level.';
    };

options.rmlist = {'display' 'plots'};
out = makesubops(defs);

