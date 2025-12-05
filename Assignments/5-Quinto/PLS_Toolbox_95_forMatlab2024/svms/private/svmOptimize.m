function [results] = svmOptimize(x, y, args)
%SVMOPTIMIZE Search over parameter ranges using svmengine to perform CV to find optimal parameters
% The calculated CV quantity is:
%         misclassification rate (fraction), if classification,
%         mean squared error, if regression.
% parameters is a struct, for example, key "c" has dim 4x1, equal to (0.001, 0.1, 1, 10)
% Support up to 3 parameters from these: c, g, p (see
% getSupportedParameters)
% svmengine would check for 'v' arg, and if so apply the following. Thus
% users could use either form: ('c', '1'), or ('c', 1), or ('c', c_range), etc.
% Output:
% results.cvValues      : array of the CV results over the searched parameter ranges
% results.parameters    : parameters which were searched, in same order as dimensions of cvValues
% results.optimalArgs   : struct of the parameter values set which produces
% the optimal CV value
%
% The parameter optimization uses a parfor loop which takes advantage of
% the Parallel Computating Toolbox (PCT) if available. In that case the 
% initevripct function is called to start the PCT parpool of workers and to
% handle their synchronized access to the matlabprefs.mat file.
% If the PCT is not available then the parfor loop behaves like a for loop.
%
%I/O: out = svmOptimize(x, y, options);

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

cvi = args.cvi;
cvopts = crossval('options');
cvopts.preprocessing = 0;
cvopts.waitbartrigger = inf;

showwaitbar = strcmpi(args.waitbar,'on');
parameters = getSupportedParameters(args);

% Check if this is classification or regression
svmClassification = isclassification(args);

% Do not calculate probability estimates during the CV scan. Restore below.
if isfield(args, 'b')
  b_old = args.b;
  args.b = 0;
end

% There may be any number of parameters with ranges
% svmOptimize only scans over three at most.
% Assume that if a parameter was included then its value has length >= 1
pnames = fieldnames(parameters);
plen = size(fieldnames(parameters));
plen = plen(1);

results.best = struct;
p = cell(1,plen);
for i=1:plen
  p{i} = parameters.(pnames{i});
end

switch plen
  case 1
    n1 = length(p{1}); n2=1; n3=1;
  case 2
    n1 = length(p{1}); n2=length(p{2}); n3=1;
  case 3
    n1 = length(p{1}); n2=length(p{2}); n3=length(p{3});
  otherwise
    % unsupported parameter
end

ntotal = n1*n2*n3;
cvValue = ones(n1, n2, n3);
cvValue1 = nan(ntotal,1);
% Use CV quantitites misclassification and meanSquaredError, so want either
% to be as small as possible

if isfield(args,'q') & args.q==1
  isquiet = true;
else
  args.q  = 0;
  isquiet = false;
end

if ~isempty(cvi);
  if iscell(cvi) & length(cvi)==3 & ischar(cvi{1}) & strcmpi(cvi{1},'rnd') & cvi{3}==1
    %they HAPPENED to do {'rnd' s 1} ? Then use built-in random CV
    %(faster!) and disable EVRI CV.
    args.v = cvi{2};
    cvi = {};
  else
    %otherwise, turn OFF built-in random CV and disable recon opts
    args.v = 0;
    args.norecon = 1;
  end
end

ieq  = 0;  % counter for matching best results

h = [];   % initialize outside of try/catch
try
  if isoneclasssvm(args) ; % ------------------------------------------
    results = optimisesvmoc(x, y, pnames, p, args);
  else
    results.bestCV = Inf;
    lastupdate = now;
    starttime = now;
    % Use a single unrolled loop for PCT, instead of nested loops
    argsall = repmat(args, 1, ntotal);
    ii = 0;
    for i1 = 1:n1
      for i2 = 1:n2
        for i3 = 1:n3
          ii = ii+1;
          argsall(ii).(pnames{1}) = p{1}(i1);
          if plen>1
            argsall(ii).(pnames{2}) = p{2}(i2);
          end
          if plen>2
            argsall(ii).(pnames{3}) = p{3}(i3);
          end
        end
      end
    end
    
    if checkmlversion('>','9.1')
      % Matlab ver. 9.2 or later can use PCT's DataQueue. (9.2 is R2017a)
      matlab92plus = true;    
    else
      matlab92plus = false;
    end
    
    hasgcp = initevripct;            % init evriio on workers
    
    % set up parfor progress monitor
    nProgressStepSize = ceil(ntotal/10);
    D = [];
    if showwaitbar
      if hasgcp
        if matlab92plus       % Can use DataQueue?
          h = waitbar(0, 'Performing Parameter Optimization...');
          D = parallel.pool.DataQueue;
          afterEach(D, @nUpdateWaitbar);
          pp = 1;
        end
      else
        % no PCT R2017a or later. Use standard waitbar
        h = waitbar(0,'Performing Parameter Optimization... (Close to cancel)');
        set(h,'name','SVM Optimization');
      end
    end

    % parameter optimization loop
    parfor ii = 1:ntotal
      if showwaitbar & (mod(ii, nProgressStepSize) == 0)
        if hasgcp
          if matlab92plus
            send(D, ii);
          end
        else
          % No PCT, so standard waitbar. Note parfor iterates decreasing
          if ~isempty(h) % ((now-lastupdate)*60*60*24)>.5  (not in parfor!)
            %show progress bar
            elap = (now-starttime)*60*60*24;
            i2 = ntotal -ii + 1; % account for parfor index runs in reverse
            est = round(elap*(ntotal-i2)/i2);
            drawnow;
            if ~ishandle(h)
              error('Model optimization aborted by user');
            end
            waitbar(i2./ntotal,h);
            if elap>3
              set(h,'name',['Est. Completion Time ' besttime(est)]);
            end
          end
        end
      end
      
      args1 = argsall(ii);
      cvopts1 = cvopts;
      i1 = floor((ii-1)/(n2*n3));
      itmp = (ii-1) - i1*n2*n3;
      i2 = floor(itmp/n3);
      i3 = mod(itmp,n3);
      if ~isempty(cvi)
        cvopts1.rmoptions = args1;
        % Compression was already applied (as was preprocessing)
        cvopts1.rmoptions.compression = 'none';
        cvopts1.rmoptions.preprocessing = {[] []};
        [cvpress,cvcumpress,rmsecv] =  crossval(x,y,'svm',cvi,[],cvopts1);
        result = rmsecv;
      else
        result = svmengine(x, y, args1);
      end
      if ~isquiet
        printParams(pnames, p, i1+1, i2+1, i3+1, plen)
      end
      
      cvValue1(ii) = result;
    end         % end parfor loop

    for i1 = 1:n1
      args.(pnames{1}) = p{1}(i1);
      for i2 = 1:n2
        if plen>1
          args.(pnames{2}) = p{2}(i2);
        end
        for i3 = 1:n3
          if plen>2
            args.(pnames{3}) = p{3}(i3);
          end
          
          ix = (i1-1)*n2*n3 + (i2-1)*n3 + i3;
          cvValue(i1, i2, i3) = cvValue1(ix);
          result = cvValue1(ix);
          isBetter = result < results.bestCV;
          isEqual = result == results.bestCV;
          
          if isBetter
            results.bestCV = result;
            ieq = 0;
            results.bestEq = [];
            
            switch plen
              case 1
                results.best.(pnames{1}) = p{1}(i1);
              case 2
                results.best.(pnames{1}) = p{1}(i1);
                results.best.(pnames{2}) = p{2}(i2);
              case 3
                results.best.(pnames{1}) = p{1}(i1);
                results.best.(pnames{2}) = p{2}(i2);
                results.best.(pnames{3}) = p{3}(i3);
              otherwise
                % unsupported parameter
            end
          end
          
          if isEqual
            ieq = ieq + 1;
            
            switch plen
              case 1
                results.bestEq(ieq).(pnames{1}) = p{1}(i1);
              case 2
                results.bestEq(ieq).(pnames{1}) = p{1}(i1);
                results.bestEq(ieq).(pnames{2}) = p{2}(i2);
              case 3
                results.bestEq(ieq).(pnames{1}) = p{1}(i1);
                results.bestEq(ieq).(pnames{2}) = p{2}(i2);
                results.bestEq(ieq).(pnames{3}) = p{3}(i3);
              otherwise
                % unsupported parameter
            end
          end          
        end
      end
    end
    
    if ieq>0
      temp = repmat(0, plen, size(results.bestEq,2));
      for iv=1:plen
        pname = pnames{iv};     % want largest param values from possibilities
        temp(iv,:) = log([results.bestEq.(pname)]);
        if strcmpi(pname, 'n') | strcmpi(pname, 'g')
          temp(iv,:) = -temp(iv,:); % Want smallest gamma or nu from possibilities
        end
      end
      
      imax = find(sum(temp)== max(sum(temp)));
      bestparams = results.bestEq(imax(1));
      switch plen
        case 1
          results.best.(pnames{1}) = bestparams.(pnames{1});
        case 2
          results.best.(pnames{1}) = bestparams.(pnames{1});
          results.best.(pnames{2}) = bestparams.(pnames{2});
        case 3
          results.best.(pnames{1}) = bestparams.(pnames{1});
          results.best.(pnames{2}) = bestparams.(pnames{2});
          results.best.(pnames{3}) = bestparams.(pnames{3});
        otherwise
          % unsupported parameter
      end
    end
    
    results.cvValues   = cvValue;
  end; %--------------------------------------------- if isoneclasssvm
  
catch
  %any errors? delete any waitbar and rethrow error
  le = lasterror;
  if exist('h') & ishandle(h)
    delete(h);
  end
  rethrow(le);
end

if exist('h') & ishandle(h)
  delete(h);
end

% Restore original probability estimates
if isfield(args, 'b')
  args.b = b_old;
end
% load bestArgs with the optimal param values, and remove 'v' field.
bestArgs = args;
pNames = fieldnames(results.best);
for ip=1:length(pNames)
  fld = pNames{ip};
  bestArgs.(fld) = results.best.(fld);
end
bestArgs.v = 0;  %FORCES cross-val mode off
results.optimalArgs = bestArgs;

results.parameters = parameters;


%----------------------------------
% nUpdateWaitbar must be an inner function of svmOptimize
  function nUpdateWaitbar(pp)
    waitbar(pp/ntotal, h);
    pp = pp + 1;
  end
end

%-------------------------------------------------------------------
function printParams(pnames, p, i1, i2, i3, plen)
switch plen
  case 1
    disp(sprintf('i1; %s:   %.0f;    %.8g', i1, pnames{1}, p{1}(i1)));
  case 2
    disp(sprintf('i1, i2; %s, %s:   %.0f, %.0f;    %.8g, %.8g', pnames{1}, pnames{2}, i1, i2, p{1}(i1), p{2}(i2)));
  case 3
    disp(sprintf('i1, i2, i3; %s, %s, %s:   %.0f, %.0f, %.0f;    %.8g, %.8g, %.8g', pnames{1}, pnames{2}, pnames{3}, i1, i2, i3, p{1}(i1), p{2}(i2), p{3}(i3)));
  otherwise
    % unsupported parameter
end
end

%--------------------------------------------------------------------------
function results = optimisesvmoc(x, y, pnames, p, args)
results = [];
results.best.g = -1;
results.bestCV = Inf;

% set threshold over nu
alpha = 0.05;

if isempty(intersect(pnames, 'g'))
  error('Sorry, can only optimize one-class SVM over gamma');
else
  igamma = ismember(pnames, 'g');
end
if isempty(intersect(pnames, 'n'))
  error('Sorry, no nu value was specified for one-class SVM');
else
  inu = find(ismember(pnames, 'n'));
end

gammas = p{igamma};
n1 = length(gammas);
nu = p{inu};

cvValue = ones(n1,1);
for ig=1:n1
  args.g = gammas(ig);
  result = svmengine(x, y, args);
  cvValue(ig) = result;
end

results.cvValues   = cvValue;

cvValueMin = min(cvValue);
[gammasdesc, igammasdesc] = sort(gammas, 'descend');
cvValuesdesc = cvValue(igammasdesc)';

if cvValueMin > 0.8
  msg = sprintf('One-class SVM: search for optimal gamma value finds no CV ');
  msg = [msg sprintf('\nmisclassification values which are smaller than %2.1f.', 0.8)];
  msg = [msg sprintf('\nTry using smaller gamma values.')];
  error(msg);
end

% search from largest gamma to smallest.
% Choose first encountered gamma which has cvvalue < 1.25*cvmin, or
% if none found, then chose the gamma which gives smallest cvValue
mincvfactor = 1.25;
for ig=1:n1
  if cvValuesdesc(ig) < mincvfactor*cvValueMin
    break
  end
end

results.bestCV = cvValuesdesc(ig); % Not necessarily best cv value but is
results.best.g = gammasdesc(ig);   % cv value assoc with gamma chosen
end
