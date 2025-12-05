function [results] = xgbOptimize(x, y, args)
%XGBOPTIMIZE Search over parameter ranges using xgbengine to perform CV to find optimal parameters
% The calculated CV quantity is:
%         misclassification rate (fraction), if classification,
%         mean squared error, if regression.
% parameters is a struct, for example, key max_depth could have dim 4x1, 
% equal to (1 2 3 4)
% Support up to 3 parameters from these: eta, max_depth, num_round
% 
% Output:
% results.cvValues      : array of the CV results over the searched parameter ranges
% results.parameters    : parameters which were searched, in same order as dimensions of cvValues
% results.optimalArgs   : struct of the parameter values set which produces
% the optimal CV value
%
%I/O: out = xgbOptimize(x, y, options);

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

% There may be any number of parameters with ranges
% xgbOptimize only scans over three at most.
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

cvValue = ones(n1, n2, n3);
% Use CV quantitites misclassification and meanSquaredError, so want either
% to be as small as possible

ntotal = n1.*n2.*n3;
prog = 0;  %index counting how many combinations we've tested already
ieq  = 0;  % counter for matching best results
if showwaitbar
  h = waitbar(0,'Performing Parameter Optimization... (Close to cancel)');
  set(h,'name','XGB Optimization');
else
  h = [];
end

try
    results.bestCV = Inf;
    lastupdate = now;
    starttime = now;
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
          if ~isempty(cvi)
            cvopts.rmoptions = args;
            % Compression was already applied (as was preprocessing)
            cvopts.rmoptions.compression = 'none';
            cvopts.rmoptions.preprocessing = {[] []};
            [press,cumpress,rmsecv,rmsec,cvpred,misclassed,reg] = crossval(x,y,'xgb',cvi,[],cvopts);
            if strcmp(args.xgbtype, 'xgbc')
              [misclassed, classids, texttable] = confusionmatrix(y,cvpred);
              % get weighted class error
              result = misclassed(:,6)'*misclassed(:,5)/sum(misclassed(:,5));
            elseif strcmp(args.xgbtype, 'xgbr')
              result = rmsecv;
            else
              result = nan;
            end
          else
            result = xgbengine(x, y, args);
          end
          
          cvValue(i1, i2, i3) = result;
          
          isBetter = result < results.bestCV;
          isEqual = result == results.bestCV;
          
          if isBetter                                %(result < results.bestCV)
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
          
          if isEqual                                %(result < results.bestCV)
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
          
          prog = prog+1;
          if ~isempty(h) & ((now-lastupdate)*60*60*24)>.5
            %show progress bar
            elap = (now-starttime)*60*60*24;
            est = round(elap*(ntotal-prog)/prog);
            drawnow;
            if ~ishandle(h)
              error('Model optimization aborted by user');
            end
            waitbar(prog./ntotal,h);
            if elap>3
              set(h,'name',['Est. Completion Time ' besttime(est)]);
            end
            lastupdate = now;
          end
          
        end
      end
    end
    
    if ieq>0
      % If there are multiple parameter settings giving the best result 
      % then choose which setting by selecting the smallest params (eta, 
      % max_depth, num_round)
      temp = repmat(0, plen, size(results.bestEq,2));
      for iv=1:plen
        pname = pnames{iv}; % want smallest param values from possibilities
        temp(iv,:) = log([results.bestEq.(pname)]);
%         if strcmpi(pname, 'n') | strcmpi(pname, 'g')
%           temp(iv,:) = -temp(iv,:); % For parameter which should maximize
%         end
      end
      
      imax = find(sum(temp)== min(sum(temp)));
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
  
catch
  %any errors? delete any waitbar and rethrow error
  le = lasterror;
  if ishandle(h)
    delete(h);
  end
  rethrow(le);
end

if ishandle(h)
  delete(h);
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
