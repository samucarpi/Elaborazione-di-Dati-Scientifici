function results = selectvars(x,y,maxlv,options)
%SELECTVARS selects variables that are predictive.
%  The automated variable selection tries variable selection using both VIP
%  and selectivity ratio (SR) and then only presents the selection leading
%  to the best RMSECV. For both VIP and selectivity ratio the following
%  approach is adopted. In the first run, the variables with the R percent
%  lowest VIP (or SR) values are eliminated. If the model improves, this is
%  repeated and continuously so until the model doesn?t improve.
%
%  For certain types of data, it is best to remove a large fraction in each
%  run and for other types of data, a smaller fraction should be removed. In
%  order to test which fraction is appropriate to remove, the removal is
%  simply done using a number of different fraction. The values are given in
%  the option .fractionstotest and the default ones are [2 5 8 10 15 20 25
%  30 35 40 45]/100. Hence, from 2% to 45%.
%
%  The iterative improvement is done for each of these and only the results
%  with best RMSECV is used. To avoid overfitting, the setting
%  relativeimprovementtocontinue can be used to require that the model needs
%  to improve by a certain fraction in order to continue removing variables.
%  The default setting is zero. Hence, the algorithm will continue as long
%  as results do not get worse.
%
%  Y must contain only a single column or a single column listed as
%  included in a dataset, or contain multiple columns containing only 0 or
%  1 indicating class membership. In the latter case a PLSDA model is used
%  instead of a PLS model and the mean of VIP or SRATIO scores across 
%  classes is used in the iterative removal process.
%
% The algorithm will stop for each trial after a number of iterations.
% Default is 20.
%
% INPUTS:
%   x = X-Block calibration data, may be a dataset object.
%   y = Y-Block calibration data, may be a dataset object.
%   maxlv = designated maximum number of LVs.
%
% OPTIONAL INPUTS:
%  options = Options structure containing the fields:
%    display : [ {'off'} | 'on'] Governs screen display.
%       plot : [{'final'}| 'off'] Governs the level of plotting.
%     method : [{'auto'}|'vip'|'sratios'] Determines which variable selection
%              algorithm to use. Either VIP or Selectivity Ratio. When set
%              to 'auto', the best of the two is automatically chosen and
%              also the best fraction to remove is automatically chosen.
%              Hence, fractiontoremove is not active.
%    fractiontoremove : (default = 0.1) Determine the fraction size to remove with each iteration.
%     fractionstotest : A set of fractions (given as a vector) that defines
%                       what fractions are tested when running with method 'auto'.
%    relativeimprovementtocontinue : Default is zero meaning that the search
%                                    for a better model continues as long
%                                    as the current RMSECV is not worse
%                                    than the prior.
%    cvsplit : [method, splits] (default = ['vet' 6]) determine crossval method [{'vet'}|'loo'|'con'|'rnd'] and number of splits
%     cvopts : options structure for CROSSVAL function.
%    plsopts :  options structure for PLS function.
%    preprocessing : {[] []} preprocessing structures for x and y blocks
%                    used in PLS and crossval.
%    maxiter : (default = 20) the maximum number of iterations before
%              terminating the iteration loop.
%    waitbar : [ 'off' |{'on'}] Governs use of waitbars to show progress.
%
% OUTPUT:
%   results = a structure containing the results in the following fields:
%           use : the final selected indices which gave the best model,
%           fit : the RMSECV for the selected indicies
%           lvs : the number of latent variables which gives the best fit
%     intervals : a matrix containing the indices used for each interval,
%        rmsecv : the RMSECV in the last selection cycle for all intervals
%                 (these values were used to select the last interval).
%         numlv : the number of latent variables used in the model which gave
%                 the RMSECV values returned in numcv.
%          figh : figure handle of plot if options.plots = 'final'.
%
%
%I/O: model = selectvars(x,y,maxlv,options);
%
%See also: AUTO, CLASSCENTER, GSCALE, GSCALER, MEDCN, NORMALIZ, NPREPROCESS, POLYTRANSFORM, REGCON, RESCALE, SCALE

% Copyright © Eigenvector Research, Inc. 2017
% Licensee shall not re-compile, translate or convert "M-files"+ contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin == 0
  x = 'io';
end

if ischar(x)
  % Initialize the options structure
  options = [];
  options.display = 'off';
  options.plots = 'final';
  options.method = 'auto';
  options.fractiontoremove = .1;
  options.fractionstotest = [2 5 8 10 15 20 25 30 35 40 45]/100;
  options.relativeimprovementtocontinue = 0;
  options.cvsplit = {'vet' (6)};
  options.cvopts = crossval('options');
  options.cvopts.display = 'off';
  options.cvopts.plots = 'off';
  options.preprocessing = {'autoscale';'autoscale'};%Pushed into PLS and CV
  options.plsopts = pls('options');
  options.maxiter = 20;
  options.waitbar = 'on';
  
  results = options;
  if (nargout==0)
    clear results;
    evriio(mfilename,x,options);
  else
    results = evriio(mfilename,x,options);
  end
  return
end

% If options structure is empty, create one or if one exists, fill any missing entries.
if ((nargin < 4) | isempty(options))
  options = selectvars('options');
else
  options = reconopts(options,'selectvars');
end

% Make sure that crossval has the same preprocessing as in the PLS options.
options.plsopts.preprocessing = options.preprocessing;
options.cvopts.preprocessing = options.plsopts.preprocessing;
options.plsopts.plots = 'off'; % assign this? -> options.plot
options.plsopts.display = 'off'; % assign this? -> options.display

msg = '';
results = [];

% Check for DataSet object Y
originaldsoy = [];
isclassif = false;
if isdataset(y)
  if strcmp(y.author, 'class2logical')
    isclassif = true;
  end
  if ~isclassif &(size(y.include{2},2)>1)
    error('SELECTVARS is currently only supported for Y Dataset objects with a single column or a single column listed as included');
  end
  originaldsoy = y;
  y_incl = y.include;
  % Extract data from y for initial calculation.
  y = originaldsoy.data(y_incl{:});
else
  if size(y,2)>1
    % Is this a class logical matrix? Yes if all entries are either 0 or 1
    uniqy = unique(y(:));
    if isequal(uniqy', [0 1])
      isclassif = true;
    end
  end
  if ~isclassif & ((size(y,2))>1)
    error('SELECTVARS is currently only supported for Y (n x 1) matrices');
  end
  y_incl = {1:size(y,1) 1:size(y,2)};
end

% Check for DataSet object X (Do after checking y, to ensure row includes match
originaldsox = [];
originalsizex = size(x,2);
if isdataset(x)
  origXmean = mean(x.data);
  originaldsox = x;
  x_incl = x.include;
  
  if isclassif & ~isempty(originaldsoy)
    x_incl{1} = y_incl{1};
  end
  
  % Extract data from x for initial calculation.
  x = originaldsox.data(x_incl{:});
else
  x_incl = {1:size(x,1) 1:size(x,2)};
  origXmean = mean(x);
end  

% Set up waitbar
if strcmp(options.waitbar,'on')
  wh = waitbar(0,'Running SELECTVARS optimization, please wait... (close to cancel)','windowstyle', 'modal');
  lengthwait = length(options.fractionstotest)*2;
else
  wh = [];
end

maxlv = min(maxlv, rank(x));
try
  if strcmpi(options.method,'auto')
    optionsinner = options;
    optionsinner.plots = 'off';
    optionsinner.waitbar = 'off';
    optionsinner.method = 'vip';
    rm = [];
    count=0;
    for idx = options.fractionstotest
      count=count+1;
      if strcmp(options.waitbar,'on')
        whopen = UpdateWaitbar(wh,count/lengthwait);
        if ~whopen
          break
        end
      end
      optionsinner.fractiontoremove= idx;
      try
        res{count} = selectvars(x,y,maxlv,optionsinner);
        rm=[rm res{count}.fit];
      catch E
        rm=[rm inf]; % inf instead of nan for numerical comparison done later
      end
    end
    optionsinner.method = 'sratios';
    rm2 = [];
    count = 0;
    for idx = options.fractionstotest
      count=count+1;
      if strcmp(options.waitbar,'on')
        whopen = UpdateWaitbar(wh,(count+lengthwait/2)/lengthwait);
        if ~whopen
          break
        end
      end
      options.options.fractiontoremove = idx;
      try
        res2{count} = selectvars(x,y,maxlv,optionsinner);
        rm2=[rm2 res2{count}.fit];
      catch E2
        rm2=[rm2 inf]; % inf instead of nan for numerical comparison done later
      end
    end
    % check if res and res2 exist, they could have failed for all idx in
    % options.fractionstotest
    if ~(exist('res')==1) & ~(exist('res2')==1)
      error(['Both VIP and Selectivity Ratio failed. See detailed errors below:' newline newline ...
              'VIP error:' newline,...
              E.message, newline newline,...
              'Selectivity Ratio error:' newline,...
              E2.message]);
    end
    if min(rm)<=min(rm2) & exist('res')==1
      [a,b]=min(rm);
      results=res{b};
    elseif min(rm)>min(rm2) & exist('res2')==1
      [a,b]=min(rm2);
      results=res2{b};
    end
    UpdateWaitbar(wh,1);
    
  else
    UpdateWaitbar(wh,0.2);
    
    % Run initial model to get an RMSECV start value
    cvresult = crossval(x,y,'sim',options.cvsplit,maxlv,options.cvopts);
    if isclassif
      cvresult.rmsecv = mean(cvresult.rmsecv);
    end
    [rmsecv numlv] = min(cvresult.rmsecv);
    rmsecv_alldata = rmsecv;
    oldrmsecv = rmsecv*2;
    model = 1;
    
    idx = 1:size(x,2);
    oldidx = idx;
    oldx = x;
    RMSECV = [rmsecv];
    removed = 0;
    
    UpdateWaitbar(wh,0.3);
    iterations = 0;
    intervals = {idx};
    lvs=1;
    
    % Continue even if the next one is slightly worse
    while ((oldrmsecv > (1.00+options.relativeimprovementtocontinue)*rmsecv) & (iterations < options.maxiter))
      iterations = iterations + 1;
      % Store the last iteration
      oldmodel = model;
      oldrmsecv = rmsecv;
      oldidx = idx;
      oldx = x;
      oldlvs = lvs;
      % Do the next iteration
      if ~isclassif
        model = pls(x,y,maxlv,options.plsopts);
      else
        model = plsda(x,y,maxlv,options.plsopts);
      end
      
      switch (options.method)
        case ('vip')
          vip_scores = vip(model); % Get VIP scores
          if isclassif
            vip_scores = mean(vip_scores,2);
          end
          [a,b] = sort(vip_scores); % Sort the scores
          tohere = max(1,round(options.fractiontoremove*size(x,2))); % Remove at least 1
          removethese = b(1:tohere); % Select a first fraction to remove
        case ('sratios')
          [sr,fstat,bs,pp] = sratio(x,model);
          if isclassif
            sr = mean(sr);
          end
          if (size(sr,2)>1) % make sure sr is a column vector
            sr=sr';
          end
          [a,b] = sort(sr); % Sort the scores
          tohere = max(1,round(options.fractiontoremove*size(x,2))); % Remove at least 1
          removethese = b(1:tohere); % Select a first fraction to remove
        otherwise
          error('Unrecognized method selected in options.method.');
      end
      
      idx(removethese) = [];
      x(:,removethese) = [];
      % we need to see if too many variables were eliminated and if the
      % preprocessing can still be done, like a derivative. break if it
      % cannot be done and take previous results
      try
        preprocess('calibrate',options.cvopts.preprocessing{1},x);
      catch
        break
      end
      % Perform Crossval
      cvresult = crossval(x,y,'sim',options.cvsplit,min(maxlv,size(x,2)),options.cvopts);
      if isclassif
        cvresult.rmsecv = mean(cvresult.rmsecv);
      end
      [rmsecv, lvs] = min(cvresult.rmsecv); % Get the lowest rmsecv value
      RMSECV = [RMSECV rmsecv]; % Append to RMSECV
      numlv = [numlv lvs];
      intervals{iterations+1} = idx;
      removed = [removed 100*(1-length(idx)/originalsizex)]; % Add % removed with each iteration.
      
      whopen = UpdateWaitbar(wh,(0.3+(0.9*iterations/options.maxiter)));
      if ~whopen
        break
      end
    end
    % Construct the output structure.
    if iterations == options.maxiter % Then the last one was best
      results.use = idx;
      results.fit = rmsecv;
      results.lvs = lvs;
    else
      results.use = oldidx;
      results.fit = oldrmsecv;
      results.lvs = oldlvs;
    end
    %results.intervals = intervals; % <- this is not quite right yet
    results.rmsecv = RMSECV;
    results.rmsecv_all_variables = rmsecv_alldata;
    results.numlv = numlv;
    
    UpdateWaitbar(wh,1);
  end
  
  %Map index back out to included data.
  results.use = x_incl{2}(results.use);
  
  % Plot results in figures.
  if (strcmpi(options.plots,'final'))
    fig = figure;
    clf
    plot(origXmean); %plot(mean(originaldsox.data));
    hold on;
    bar(results.use,origXmean(:,results.use));
    hold off;
    axis('tight');
  else
    fig = [];
  end
  results.figh = fig;
  
  results.waitbarh = wh;
  
  % Close waitbar if it hasn't been closed already.
  if ~(isempty(wh)) & ishandle(wh)
    close(wh);
  end
  
catch
  myle = lasterror;
  if ~isempty(wh)
    if ishandle(wh)
      %Some error may have occured. Close waitbar and rethrow.
      try
        delete(wh)
      end
      rethrow(myle)
    else
      %User cancel but error occured. Assume it's an abort without error.
    end
  else
    %Error.
    rethrow(myle)
  end
end


%---------------------------------------------
function out = UpdateWaitbar(wh, val)
%Update waitbar.

out = 1;
if ~isempty(wh)
  if ~ishandle(wh)
    %User cancel.
    out = 0;
  else
    %Update waitbar.
    waitbar(val,wh);
  end
else
  %Not using waitbar.
  out = -1;
end

