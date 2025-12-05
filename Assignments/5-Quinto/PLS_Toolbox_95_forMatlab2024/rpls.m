function [ results ] = rpls(x,y,ncomps,options)
%RPLS Recursive PLS is a variable selection algorithm using PLS/PCR.
%  Perform model-based variable selection based on PLS, iterative 
%  re-weighting of X by normalized regression coefficients. The final 
%  iteration, or the iteration which provides the lowest RMSECV is selected. 
%  rPLS has three modes: “specified”, “suggested”, and “surveyed”. The default 
%  is “specified” mode which will construct PLS models using the specified 
%  number of components (latent variables), ncomps, exclusively. 
%  The “suggested” mode runs PLS and crossval on the entire data, determines 
%  the most appropriate number of latent variables, and then proceeds with 
%  rPLS as in "specified" mode. The “surveyed” mode runs PLS from 1 latent 
%  variable to the maximum number of latent variables, the set of results 
%  with the lowest RMSECV value is returned. The “algorithm” options allows 
%  this function to behave as an rPLS or rPCR algorithm. The default is PLS, 
%  but options.algorithm=’pcr’ changes the algorithm to PCR.
%  Inputs are (X,Y) the X and Y data, (ncomps) the number of latent 
%  variables to be used (or maximum number of latent variables to be used 
%  in ‘suggested’ and ‘surveyed’ modes), (options) is the options 
%  structure for rPLS.
%  If Options.plots is ‘final’, a plot is given displaying the rPLS weights 
%  with an overlay of the mean sample for reference. The iteration number 
%  is displayed on the y-axis, and the dataset axisscale is on the x-axis, 
%  if X has no axisscale, then variable indexes is used.
%  Based on "Recursive weighted partial least squares (rPLS): an efficient 
%  variable selection method using PLS", Rinnan et al, J. Chemo. (2013).
%
%  INPUTS:
%    x = x-block (m x n) array or dataset to be analyzed using rPLS.
%    y = y-block (m x 1) array or dataset.
%    ncomps = number of factors (specified mode), or max number of
%             factors (surveyed mode).
%    options = a data structure containing all the options parameters
%      display   : [ 'off' | 'on' ] governs screen display (not
%                    implamented)
%      plots     : [ 'none' |{'final'}] governs plotting.
%      mode      : [{'specified'}|'suggested'|'surveyed'] governs the
%                    variant of rpls to use
%      algorithm : [{'pls'} | 'pcr' | 'mlr'] Defines regression algorithm to
%                    use. Selection is done for the specific algorithm.
%                    Note: MLR not implamented yet.
%      wtlimit   : [{1e-16}] Lower limit on weight for retained variables.
%      cvi       : {'vet' [] 1} Three element cell indicating the cross-validation
%                  leave-out settings to use {method splits iterations}. For valid
%                  modes, see the "cvi" input to crossval. If splits (the second
%                  element in the cell) is empty, the square root of the number of
%                  samples will be used. cvi can also be a vector (non-cell) of
%                  indices indicating leave-out groupings (see crossval for more
%                  info).
%      stopcrt   : [{1e-12}]stop criteria, stop if the relative difference between iterations,
%                  is less than the define value (default: 1e-12)
%      maxlv     : max number of latent variables to use in cross-validation (default: 10);
%      maxiter   : max number of rpls iterations (default: 100)
%      preprocessing : [{'none'}| 'meancenter' | 'autoscale'] defines preprocessing. 
%      waitbar: [ 'off' |{'on'}] Governs use of waitbars to show progress.
%
%  OUTPUTS:
%    results = a data sttucture containing the results including the
%              rmsecv, sets of selected indexes, and Regs.
%
%  I/O: results = rpls(X,Y,ncomps,options)
%
%See also: GASELCTR, GENALG, RPLS, SRATIO, VIP

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% BK 3/21/2017

if (nargin == 0)
  x = 'io';
end
% options struct
if ischar(x)
  options               = [];
  options.name          = 'options';
  options.display       = 'off'; % set it to 'on' later
  options.plots         = 'final'; % set it to 'final' later
  options.mode          = 'specified'; %[{'surveyed'}, 'suggested','specified']
  options.algorithm     = 'pls'; % [{'pls'},'pcr','mlr']
  options.wtlimit       = eps;%1.e-6;
  options.preprocessing = 'mean center';
  options.cvi           = {'vet' 3}; %{'vet' [] 1};
  options.stopcrt       = 1e-12; % stop criteria (relative difference, default 1e-6)
  options.maxlv         = 10; % for suggested mode.
  options.maxiter       = 100;
  options.waitbar = 'on';
  
  if nargout==0; evriio(mfilename,x,options); clear x; else; results = evriio(mfilename,x,options); end
  return;
end
  
% todo: make x & y be required, if ncomps is omitted, go automatic based on RMSECV?
specific = false;
if nargin<2
  error('both X & Y blocks are required for rPLS');
end
if nargin<3
end
% Input argument check
if nargin<4
  if isnumeric(ncomps)
    specific = true;
  end
  options = [];
end
options = reconopts(options,'rpls');
if ~(specific) & (ncomps>7) &(ismember(options.mode,{'surveyed','suggested'}))
  options.maxlv = ncomps;
else
  options.maxlv = 8; % for suggested mode the min # of max lvs is 8.
end

xOrig = x;
if ~isdataset(x)
  x = dataset(x);
end
if ~isdataset(y)
  y = dataset(y);
end

if ncomps>min(size(x.data))
  error(sprintf(['Cannot create models: ' num2str(4) ' latent variable exceeds matrix rank.' ]));
end

% safety checks
if isdataset(y)
  y = y(:,y.include{2});
end
if ((size(y,2))>1)
  error('rPLS is currently only supported for Y (n x 1) matrices');
  % todo: prompt the user to select one y measurement instead of an error
end

% Preprocessing
if isempty(options.preprocessing);
  options.preprocessing = {[] []};  %reinterpet as empty for both blocks
end
if ~isa(options.preprocessing,'cell')
  options.preprocessing = {options.preprocessing};
end
if length(options.preprocessing)==1;
  options.preprocessing = options.preprocessing([1 1]);
  % handling a special case where user passed only X preprocessing. This expands it to two for X and Y (same for both).
end

% Apply Preprocessing
  preprocessing = options.preprocessing;
  if mdcheck(x);
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess". Results may be affected by this action.'); end
    [flag,missmap,x] = mdcheck(x);
    if length(y.include{1}) ~= length(x.include{1})
      %copy any changes over to y-block
      y.include{1} = x.include{1};
    end
  end
  
  if ~isempty(preprocessing{2});
    y = preprocess('calibrate',preprocessing{2},y);
  end
  if ~isempty(preprocessing{1});
    x = preprocess('calibrate',preprocessing{1},x,y);
  end
  
  %Check INCLUD fields of X and Y
  i = intersect(x.include{1},y.include{1});
  if ( length(i)~=length(x.include{1,1}) | ...
    length(i)~=length(y.include{1,1}) )
    if strcmp(options.display,'on');
      warning('EVRI:IncludeIntersect','Samples included in data sets do not match. Using intersection.')
    end
    x.include{1,1} = i;
    y.include{1,1} = i;
  end
  
  [m,n] = size(x);
  includeIdxs = x.include{2};
  x = x(:,x.include{2}); % Hardwired 2nd mode.
  
% Set cross validation options
cvopts = crossval('options');
cvopts.display = 'off';
cvopts.plots = 'none';
cvopts.preprocessing = options.preprocessing;

% Make adjustments according to the selected algorithm (pls, pcr, & mlr)
switch (lower(options.algorithm))
  case 'pls'
    algopts = pls('options');
  case 'pcr'
    algopts = pcr('options');
  case 'mlr' %MLR is disabled for now (there are no comps for MLR).
    algopts = mlr('options');
    error(sprintf([options.algorithm ' is not implamented yet for rpls']));
  otherwise
    error(sprintf([options.algorithm ' is not a compatible algorithm for rpls']));
end
algopts.display = 'off';
algopts.plots = 'none';
% NB: Only mean-center during cycling, and similarly for CV
algopts.preprocessing = {'mean center','mean center'}; 
cvopts.preprocessing = algopts.preprocessing;

% Set up waitbar
if strcmp(options.waitbar,'on')
  wh = waitbar(0,'Running RPLS, please wait... (Close to Cancel)', 'windowstyle', 'modal');
else
  wh = [];
end

switch (options.mode)
  case 'specified' % run rPLS only using the specified number of comps.
    if ~(isempty(wh))
      if ~(ishandle(wh))
        error('User aborted import');
      end
        waitbar(0.5,wh);
    end
    
    ncomp = ncomps;
    [results] = rplsProcess(x,y,ncomp,algopts,cvopts,options);
    
  case 'suggested' % run PLS & CV on the data, determine ncomps & then perform rPLS.
    if ~(isempty(wh))
      if ~(ishandle(wh))
        error('User aborted import');
      end
        waitbar(0.5,wh);
    end
      
    switch (lower(options.algorithm ))
      case 'pls'
        model = pls(x,y,options.maxlv,algopts);
      case 'pcr'
        model = pcr(x,y,options.maxlv,algopts);
      case 'mlr'
        model = mlr(x,y,options.maxlv,algopts);
    end
    model = crossval(x.data,y,model,options.cvi,options.maxlv,cvopts);
    ncomp = choosecomp(model);
    [results] = rplsProcess(x,y,ncomp,algopts,cvopts,options);
    
  case 'surveyed' % run rPLS on all cases from 1 to options.maxlv comps, & get the best model.
    n = 0;  
    for ncomp=options.maxlv:-1:1
      n = n+1;
      [resultZ(ncomp)] = rplsProcess(x,y,ncomp,algopts,cvopts,options);
      % Update waitbar
      if ~(isempty(wh))
        if ~(ishandle(wh))
          error('User aborted import');
        end
        waitbar(n/options.maxlv,wh);
      end
    end
    rmses = zeros(1,length(resultZ));
    for i=1:length(rmses)
      rmses(1,i) =resultZ(i).RMSECVs(1,resultZ(i).selected); 
    end
    [useV,useI] = min(rmses); % index the results with the lowest RMSECV
    results=resultZ(useI); % return indexed results.
    
  otherwise % unrecignized mode
    error(sprintf([options.mode ' is not a recignized mode for rpls']));
end

results = ExpandResults(results, includeIdxs,n);

% Close waitbar if it hasn't been closed already.
if ~(isempty(wh)) & ishandle(wh)
  close(wh)
end

% Plot figure showing results, the rPLS weights
if (strcmpi(options.plots,'final'))
  fh = figure;
  if isa(xOrig,'dataset')
  try % to use dso axisscale
    sz = 1:size(results.selectedIdxs,2);
    axisscale = xOrig.axisscale{2};
    h = imagesc(axisscale,sz,log(results.cumulativeReg));
  catch % couldn't add axisscale.
    h = imagesc(log(results.cumulativeReg));
  end
  else
    h = imagesc(log(results.cumulativeReg));
  end
  title('rPLS log weights (variables vs. iterations)')
  ylabel('Iteration Number')
  colorbar
  set(gca,'ydir','normal');
  set(gca, 'CLim', [log(options.wtlimit), log(max(max(results.cumulativeReg)))]);
  
  hold on;
  if isa(xOrig,'dataset')
    unitAvgSpec = mean(xOrig.data,1)/max(abs(mean(xOrig.data,1)));
  else
    unitAvgSpec = mean(xOrig,1)/max(abs(mean(xOrig,1)));
  end
  % scale the Unit spec to fit the imagesc.
  l = length(results.RMSECVs);
  l = floor(l*0.5);
  a = (length(results.RMSECVs) - l);%*0.5;
  pSpec = unitAvgSpec*a + l;
  if isa(xOrig,'dataset')
    try % to use dso axisscale
      if ~isempty(axisscale)
        plot(axisscale,pSpec,'r','linewidth',2);
      else
        plot(pSpec,'r','linewidth',2);
      end
    catch
      plot(pSpec,'r','linewidth',2);
    end
  else
    plot(pSpec,'r','linewidth',2);
  end
  
  % show the optimal iteration value
  optimaliter = results.selected;
  abline(0, optimaliter,'color','g','linestyle','--')
  hold off;
  legend('Mean','Optimal Iteration','Location','NorthEast')
  
  % second figure shows RMSECV
  fh2 = figure;
  ptcvresults = log(results.cumulativeReg);
  ptcvresults(ptcvresults<log(options.wtlimit))=-inf;
  for i = 1: size(results.cumulativeReg,1)
    tmp = ptcvresults(i,:);
    tmp(tmp>(-inf)) = results.RMSECVs(1,i);
    ptcvresults(i,:) = tmp;
  end
  
  h2 = imagesc(ptcvresults);
  set(gca,'ydir','normal');
  clrmap = colormap(gca);
  clrmap(1,:)=[1,1,1];
  clrmap(2,:)=[0.5,0.5,0.5];
  colormap(gca,clrmap);
  set(gca, 'CLim', [ 0 , max(max(ptcvresults))]);
  title('RMSECV (variables vs. iterations)')
  ylabel('Iteration Number')
  colorbar
  hold on;
  plot(pSpec,'r','linewidth',2);
  % show the optimal iteration value
  optimaliter = results.selected;
  abline(0, optimaliter,'color','g','linestyle','--')
  hold off;
  legend('Mean','Optimal Iteration','Location','NorthEast')
  results.figh = [fh fh2];
else
  results.figh = [];
end

end

%--------------------------------------------------------------------------
function [results] = rplsProcess(x,y,ncomp,algopts,cvopts,options)
lastDiffs = repmat(NaN,1,100);
% Convert to dataset if not already
if ~isa(x,'dataset')    % keep x as a dataset
  x = dataset(x);
end
xNew     = x;
userinclvars = x.include{2};  % User-included vars
wts = repmat(0,1,length(userinclvars)); %size(x,2));

count = 1;
first = true;
lastDiff = options.stopcrt*2; % ensure the while loop will execute at least once
while (lastDiff>options.stopcrt & count <= options.maxiter)
  if strcmpi(options.display,'on')
    disp(sprintf('count = %d', count))
  end
  switch (lower(options.algorithm))
    case 'pls'
      model = pls(xNew,y,ncomp,algopts);
    case 'pcr'
      model = pcr(xNew,y,ncomp,algopts);
    case 'mlr'
      model = mlr(xNew,y,ncomp,algopts);
  end
  
  wts        = abs(model.reg');
  iLRVs(count,:) = wts; %normaliz(abs(model.reg),0,inf)';
  if (count==1)
    cLRVs(count,:) = iLRVs(count,:);%model.reg;
  else
     cLRVs(count,:) = cLRVs(count-1,:).*wts; 
  end
  cLRVs(count,:) = cLRVs(count,:)/max(cLRVs(count,:));
  
  %retainvars = wts > options.wtlimit;
  %newinclvars = retainvars;
  
  %keepvars = userinclvars(abs(model.reg') > options.wtlimit);
  ikeepvars = cLRVs(count,:)>options.wtlimit; %abs(model.reg') > options.wtlimit;
  
  %xLast = xNew;
  xNew.data(:,userinclvars) = xNew.data(:,userinclvars) * diag(wts); %diag(normaliz(abs(model.reg'),0,inf)');

  % crossval only uses user-included and retained vars
  options.maxlv = min( length(userinclvars(ikeepvars)), options.maxlv);
  model = crossval(x.data(x.include{1},userinclvars(ikeepvars)),y,model,options.cvi,options.maxlv,cvopts);
  cvResult(count) = model.detail.rmsecv(ncomp);

%   %regNew = model.reg;
%   %vTemp = log(cLRVs(count,:));
%   vTemp = cLRVs(count,:)>eps;%vTemp>log(eps);
%   if (size(vTemp,1)>1)
%     vTemp = vTemp';
%   end
   
  idxs{count} = userinclvars(ikeepvars);%find(vTemp); %indexes
  if(length(idxs{count})<ncomp) % added safegaurd
    cLRVs(count,:)=[];
    iLRVs(count,:)=[];
    idxs(count)=[];
    break;
    if strcmpi(options.display,'on')
      disp(' *** breaking because length(idxs{count})<ncomp')
    end
  end
  
  % if # of variables didn't change from last iteration, skip it
  if ((first == true) & (count>1))
    first = false;
  end
    
  % if the number of variables didn't reduce, skip calculating RMSECV
  if (~first) %& (length(idxs{count}) == length(idxs{count-1}))
    %copy RMSECV from last, update lastDiff, regLast, count and skip.
    %rmsecvs(count)=rmsecvs(count-1);
    lastDiffs(count) = (sum(sum(((x.data(x.include{1},userinclvars)*cLRVs(count,:)')...
      -(x.data(x.include{1},userinclvars)*cLRVs(count-1,:)')).^2)));  %fChange!
    
    lastDiff = lastDiffs(count);
    %identicalSets = identicalSets + 1;
    %regLast = regNew;
    %     count = count+1;
    %     continue;
    %   else
    %     cvmodel = crossval(x(:,idxs{count}),y,options.algorithm,options.cvi,ncomp,cvopts);
    if(length(idxs{count}) == length(idxs{count-1}))
      identicalSets = identicalSets + 1;
    else
      identicalSets = 1;
    end
  end
  
%   % TODO: have a section here for surveyed mode (you want all rmsecvs)
%   rmsecvs(count) = cvmodel.rmsecv(ncomp);
  rmsecvs(count) = cvResult(count);
  
  if count == 1
    lastDiffs(count) = NaN;
    identicalSets = 1;
%   else
%     lastDiffs(count) = (sum(sum(((x.data(x.include{1},userinclvars)*cLRVs(count,:)')...
%         -(x.data(x.include{1},userinclvars)*cLRVs(count-1,:)')).^2)));  % tempdos
%     
%     lastDiff = lastDiffs(count);
%     if(length(idxs{count}) == length(idxs{count-1}))
%       identicalSets = identicalSets + 1; % iteration count for the # of iterations the idx set hasn't reduced
%     else
%       identicalSets = 1;
%     end
  end
  
  % if the idx set can't reduce further or hasn't reduced in a while terminate the loop.
  if (length(idxs{count})==ncomp) | (identicalSets>=5)
    if strcmpi(options.display,'on')
      disp('Stopping due to length(idxs{count})==ncomp) OR (identicalSets>=5)')
    end
    break;
  end
  if abs(lastDiffs(count)/lastDiffs(1)) < 1.e-6
      if strcmpi(options.display,'on')
        disp('Stopping due to small difference in X between cycles')
      end
      break;
  end
  %regLast = regNew;
  count = count+1;
end

% Figure out which iteration was best using RMSECV
[useV,useI] = min(rmsecvs); % Use only min for now.

results.LVsUsed = ncomp;
results.selected = useI;
results.RMSECVs = rmsecvs;
results.iterativeReg = iLRVs;
results.cumulativeReg = cLRVs;
results.selectedIdxs = idxs;
results.regDifferences = lastDiffs;
end

function results = ExpandResults(results, includeIdxs,fullSz)
results.iterativeReg = ExpandField(results.iterativeReg, includeIdxs, fullSz);
results.cumulativeReg = ExpandField(results.cumulativeReg, includeIdxs, fullSz);
results.selectedIdxs = CorrectIdxs(results.selectedIdxs,includeIdxs);
end

function temp = ExpandField(field, includeIdxs, fullSz)
temp = nan(size(field,1),fullSz);
temp(:,includeIdxs) = field;
end

function field = CorrectIdxs(field,includeIdxs)
for i = 1: size(field,2)
  field{1,i} = includeIdxs(field{1,i});
end
end
