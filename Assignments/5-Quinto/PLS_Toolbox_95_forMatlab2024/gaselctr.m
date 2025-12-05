function [fit,pop,cavfit,cbfit] = gaselctr(x,y,varargin)
%GASELCTR Genetic algorithm for variable selection with PLS.
%  GASELCTR uses a genetic algorithm optimization to minimize cross
%  validation error for variable selection. Inputs are: (x) the predictor
%  block, (y) the predicted block, and an optional options structure
%  (options) containing the fields:
%        display: [ 'off' | {'on'} ]  Governs level of display to command window.
%          plots: [ 'none' | {'intermediate'} | 'replicates' | 'final' ] 
%                  Governs plots. 'final' gives only a final summary plot.
%                  'replicates' gives plots at the end of each replicate.
%                  'intermediate' gives plots during analysis. 'none' gives
%                  no plots.
%    windowfocus: [ {'off'} | 'on' ] Bring focus back to window, this is
%                  was on by default in older versions (not as option).
%        popsize: {64} the population size (16 <= popsize <= 256 and must
%                  be divisible by 4),
% maxgenerations: {100} the maximum number of generations (25<=mg<=500),
%   mutationrate: {0.005} the mutation rate (typically 0.001<=mr<=0.01),
%    windowwidth: {1} the number of variables in a window (integer window
%                  width) 
%    convergence: {50} per cent of population the same at convergence
%                  (typically 80), 
%   initialterms: {30} per cent terms included at initiation (10<=it<=50),
%      crossover: {2} breeding cross-over rule (cr = 1: single cross-over;
%                   cr = 2: double cross-over), 
%      alogrithm: [ 'mlr' | {'pls'} ] regression algorithm
%          ncomp: {10} maximum number of latent variables for PLS models,
%             cv: [ 'rnd' | {'con'} ] cross-validation option ('rnd':
%                   random subset cross-validation; 'con': contiguous block
%                   subset cross-validation),
%          split: {5} number of subsets to divide data into for cross-validation,
%           iter: {1} number of cross-validation iterations,
%  preprocessing: {[] []} a cell containing standard preprocessing
%                   structures for the X- and Y- blocks respectively (see PREPROCESS),
%       preapply: [ {0} | 1 ] If 1, preprocessing is applied to data prior to
%                   GA. This speeds up the performance of the selection,
%                   but my reduce the accuracy of the cross-validation
%                   results. Output "fit" values should only be compared to
%                   each other. A full cross-validation should be run
%                   after analysis to get more accurate RMSECV values.
%           reps: {1} the number of replicate runs to perform,
%         target: a two element vector [target_min target_max] describing
%                   the target range for number of variables/terms included in a
%                   model (n). Outside of this range, the penaltyslope
%                   option is applied by multiplying the fitness for each
%                   member of the population by: 
%                     penaltyslope*(target_min-n) when n<target_min, or
%                     penaltyslope*(n-target_max) when n>target_max. 
%                   Field "target" is used to bias models towards a given range
%                   of included variables (see penaltyslope below),
%      targetpct: {1} flag indicating if values in field "target" are given
%                   in percent of variables (1) or in absolute number
%                   of variables (0), and
%   penaltyslope: {0} the slope of the penalty function (see target above).
%
%  Output is a standard GENALG model structure (model). Type 'gaselctr help'
%  for more information.
%
%  Note: y can be either a column vector or a matrix.
%
%I/O: model = gaselctr(x,y,options);
%I/O: gaselctr demo
%
%See also: CALIBSEL, GENALG, GENALGPLOT, IPLS

%--Hidden help--
%  gaselctr also operates on data in the genalg gui by passing
%  the gui handle and an action (either "gogas" or "resum")
%  as in: gaselctr(handle,'resum')
%
%  if 'rm' is pls and y is a logical matrix, discriminate analysis
%  is used and models are selected based on a misclassification 
%  evaluation as fit.
%Additionally, the following is still valid:
%I/O: [fit,pop,avefit,bstfit] = gaselctr(x,y,options);

%Copyright Eigenvector Research, Inc. 1995
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% Modified 2/9/97,2/10/98 NBG
% Modified 4/30/98 BMW
% 10/27/00, nbg change in main loop to check if pop(i,:) is all zeros
% 2/22/01, jms -added "even-mutate" code to control variable selction "overgrowth"
%         -added "usergaweightfcn" to allow user-defined function for fit-biasing based on # variables selected
% 7/01 jms combined genalg routine and gaselctr into one. Allows call with
%   handle and action (will get required info from gui).
%  -added avefit and bstfit outputs
% 11/01/01 jms added discrim analysis if y is logical
% 12/06/01 jms added ability to pass genalg model structure instead of all the inputs
%  - converted all crossval calls to crossvus (to allow complete preprogui compatibility)
%  - fixed output - was giving ALL models (incl dups)
% 3/6/02 JMS modified to use dataset as input for x - allows better prepro compatibility
%  -allowed storage and fit recall for previously tried variable combos (only when doing contig. blocks)
% 4/19/02 JMS renamed crossvus to crossval, changed output order (misclassed)
% 12/17/02 JMS added test for no included variables (after intersection with original includ)
% 12/19/02 JMS fixed includ problems when working with windows instead of variables.
% 6/23/03 JMS fixed resume bug (numincluded and starttime not remembered)
%   -moved test for popsize not divisible by 4 (must always be run)
% 7/1/03 JMS fixed lv=1 bug with discrim anal
% 10/13/03 JMS added alternate windowing method (allows adjustable positions)
%   - y-block include{2} now used (was ignored before)
% 10/29/03 JMS renamed variable "unique" to avoid conflict with unique function
% 3/17/04 JMS added "all variables" fit calculation and display
% 3/15/05 JMS fixed memory leak (make copy of X prior to applying include)
% 5/18/05 JMS added better support for discrim crossval (use rmsecv which
%          can be biased by user through prior)
% 02/03/06 rsk make autoscale default for both x and y blocks.

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  options.name           = 'options';
  options.popsize        = 64;
  options.maxgenerations = 100;
  options.mutationrate   = 0.005;
  options.windowwidth    = 1;
  options.convergence    = 50;
  options.initialterms   = 30;
  options.crossover      = 2;
  options.algorithm      = 'pls';
  options.ncomp          = 10;
  options.cv             = 'con';
  options.split          = 5;
  options.iter           = 1;
  options.preprocessing  = {['autoscale'] ['autoscale']};
  options.preapply       = 0;
  options.reps           = 1;
  options.target         = [0 100];
  options.targetpct      = 1;
  options.penaltyslope   = 0;
  options.plots          = 'intermediate';
  options.display        = 'on';
  options.windowfocus    = 'off';

  if nargout==0; evriio(mfilename,x,options); else; fit = evriio(mfilename,x,options); end
  return; 
end

if nargin < 2;
  error('Incorrect number of inputs')
end

if isa(y,'char')
  % (fig,'action')  for GUI
  guifig    = x;     %first input is fig handle
  action    = y;     %second input is action
  gui       = 1;     %flag saying gui does exist
  
  garesultfig       = getappdata(guifig,'GAResultsPlot');   %get GAResultsPlot figure #
  
  % Variables set by GUI
  handles     = guidata(guifig);
  x           = getappdata(handles.gawindow,'xblock');              % x-block data
  y           = getappdata(handles.gawindow,'yblock');              % y-block data
  %FIXME: JEREMY
  modl        = getappdata(guifig,'modl');                          % model with settings
  varargin{1} = modl.detail.options;                                %extract options
    
  repcount       = get(handles.replicates,'userdata');              %Replicate count & max reps
  repdesired     = str2double(get(handles.replicates,'string'));

else

  action     = 'gogas';  %always starting (no resume possible w/command line version)
  guifig     = [];       %no figure # (non-interactive run)
  gui        = 0;        %flag saying no gui
  
  repcount   = 0;        %Replicate count & max reps

  garesultfig = [];
  allreps.ffit = [];          %initialize output vars
  allreps.gpop = [];
  
end

%only three or fewer inputs? Third may be an options structure or a model structure from genalg, try extracting it
if nargin <= 3;
  % (x,y)
  % (x,y,options)
  % (x,y,model)
  % (fig,'action')
  
  if isempty(varargin)
    varargin{1} = [];
  end        
  if ismodel(varargin{1}) & strcmpi(varargin{1}.modeltype,'genalg')
    varargin{1} = varargin{1}.detail.options;
  end
  
  options = reconopts(varargin{1},'gaselctr');
  
  if options.penaltyslope == 0;
    options.target = [-inf inf];
  else
    if options.targetpct; 
      if isa(x,'dataset');
        options.target(1:2) = options.target./100.*size(x.data,2); 
      else
        options.target(1:2) = options.target./100.*size(x,2); 
      end
    end
  end
  
  nopop    = options.popsize;
  maxgen   = options.maxgenerations;
  mut      = options.mutationrate;
  window   = options.windowwidth;
  if isfield(options,'windowmode')
    switch options.windowmode
      case 1
        winwidth = window;
        window = 1;
      otherwise
        winwidth = 0;  %fixed position windows
    end
  else
    winwidth = 0;  %fixed position windows
  end
  converge = options.convergence;
  begfrac  = options.initialterms/100;
  cross    = options.crossover;
  reg      = strcmp(options.algorithm,'pls');
  maxlv    = round(options.ncomp);
  cvopt    = strcmp(options.cv,'con');
  split    = options.split;
  iter     = options.iter;
  meancenter     = options.preprocessing;
  repdesired     = options.reps;
  target         = options.target;             %target # of variables
  targetpenality = options.penaltyslope;       %Penalty slope for off target
  preapply       = options.preapply;
  
else
  % (x,y,np,mg,mt,wn,cn,bf,cr,ml,cv,sp,it,mc,rp,pf)
  
  %backwards compatibility code
  
  %not three inputs, do we have enough to figure out what they wanted?
  if nargin < 13;
    error('Incorrect number of inputs');
  end
  
  %defaults for backwards compatibility
  if nargin < 14; varargin(14) = 1;  end   %meancenter
  
  % Set Metaparameters
  [nopop,maxgen,mut,window,converge,begfrac,cross,maxlv,cvopt,split,iter,meancenter] = deal(varargin{:});
  
  begfrac   = begfrac/100;   %Fraction of terms included in beginning
  reg       = 1;                %Regression method, 0 = MLR, 1 = PLS
  repdesired     = 1;           %desired reps
  target         = [0 100];     %target # of variables
  targetpenality = 0;           %Penalty slope for off target
  winwidth       = 0;           %unmoving windows
  preapply       = 0;
  
end

if isempty(garesultfig) & ismember(options.plots,{'intermediate'});
  garesultfig          = figure('Name','GA for Variable Selection Results',...
          'units','normalized',...
          'Pos',[0.4863    0.4753    0.4688    0.4167],...
          'Resize','On',...
          'tag','GAResultsPlot',...
          'NumberTitle','Off');;   %results plot
end

if ~isa(x,'dataset');
  x = dataset(x);       %create a dataset from x if it isn't already
end
if isa(y,'dataset');
  y = y.data(:,y.include{2});           %extract data from y if it IS a dataset
end
if size(y,1) ~= size(x.data,1);
  error('X and Y blocks must have equal numbers of samples');
end

%check for discrim mode 
discrim   = islogical(y);

%see if pre-apply of preprocessing was requested - if so, do it now
if preapply & iscell(meancenter);
  %note - need to only handle normal preprocessing options since "preapply"
  %will never be called by old-style gaselectr code
  y = double(y); %convert to double (for preprocessing to work)
  y = preprocess('calibrate',meancenter{2},y);
  x = preprocess('calibrate',meancenter{1},x,y);
  meancenter = 0;  %clear preprocessing (crossval can skip it)
end

%Check to see that nopop is divisible by 4
dp1        = nopop/4;
if ceil(dp1) ~= dp1
  nopop   = ceil(dp1)*4;
  if strcmp(options.display,'on')
    disp('Population size not divisible by 4')
    disp(sprintf('Resizing to a population of %g',nopop));
  end
end

originclud = x.includ;      %store original includ info to limit var selection later
[m,n]      = size(x.data);  %note: do not use inlclud here because we want to base var selection on whole matrix (in case of var grouping)

if reg == 1;
  regmthd = 'sim';
else
  regmthd = 'mlr';
  maxlv   = 1;
end

%calculate all-variables results
%Start with setting up cross-val settings (only used for "all variables" test)
if cvopt
  cvind = {'con' split iter};  
else
  cvind = {'rnd' split iter};
end
% if ~discrim;
  [press,cumpress,allvarsfit] = crossval(x,y,regmthd,cvind,maxlv,0,meancenter);
  allvarsfit = min(allvarsfit,[],2);  %best all-vars model at these crossval settings
% else
%   [junk,junk,junk,junk,junk,allvarsfit] = crossval(x,y,regmthd,cvind,maxlv,0,meancenter,{});
%   allvarsfit = min(mean(allvarsfit{1}));  %best all-vars model at these crossval settings
% end

%initialize timer if this is the first rep
if repcount==0; starttime = now; end                             

while repcount<repdesired;
  repcount=repcount+1;

  rand('state',sum(100*clock));  %regenerate the random seed
  
  if strcmp(action,'gogas')
    
    gcount    = 1;
    specsplit = ceil(n/window);

    %locate completely excluded windows
    numincluded = [];
    for j = 1:specsplit
      numincluded(j) = sum(find(originclud{2}>=((j-1)*window+1) & originclud{2}<=(j*window)));
    end
    
    if gui; setappdata(handles.gawindow,'specsplit',specsplit); end
    
    %Generate initial population
    pop     = rand(nopop,specsplit);
    pop(:,numincluded==0) = 1;   %zero out windows without included variables
    pop     = pop<begfrac;
    
    for i=find(sum(pop,2)==0)';    %any with no variables should have ONE variable set
      j = shuffle(find(numincluded(:)>0));
      pop(i,j(1)) = 1;   %invert ONE of the included windows/variables
    end
    
%     for i = find(sum(pop,2)<1)';
%         colm        = ceil(rand(1)*specsplit);
%         pop(i,colm) = 1;
%     end
    
    dups      = 0;
    cavterms  = zeros(1,maxgen);
    cavfit    = zeros(1,maxgen);
    cbfit     = zeros(1,maxgen);    
    
  elseif strcmp(action,'resum')  
    
    z         = getappdata(handles.gawindow,'resumeinfo');    %get stored resume info
    
    fit       = z.fit;
    pop       = z.pop;
    gcount    = z.gcount;
    dups      = z.dups;
    cavfit    = z.cavfit;
    cbfit     = z.cbfit;
    cavterms  = z.cavterms;
    numincluded = z.numincluded;
    starttime = z.starttime;
    
    specsplit = getappdata(handles.gawindow,'specsplit');
    
    setappdata(handles.gawindow,'resumeinfo',[])    %clear resume info
    
  end
  
  if gui;
    %update replicates label 
    set(handles.replicatestext,'string',['Replicate Runs: ',num2str(repcount),' of ']);
  end
  
  %Set limit on number of duplicates in population
  maxdups = ceil(nopop*converge/100);
  
  %Iterate until dups > maxdups
  % Main Loop
  while dups < maxdups
    drawnow
    
    %see if we've been told to stop, if so, save and break out
    if gui;
      if ~isempty(get(handles.stop,'UserData')) &  get(handles.stop,'UserData') >= 1
        clear z
        z.fit      = fit;
        z.pop      = pop;
        z.gcount   = gcount;
        z.dups     = dups;
        z.cavfit   = cavfit;
        z.cbfit    = cbfit;
        z.cavterms = cavterms;
        z.numincluded = numincluded;
        z.starttime = starttime;
        
        setappdata(handles.gawindow,'resumeinfo',z)    %store resume info
        
        set(handles.replicates,'UserData',repcount-1);
        
        return
      end
    end
    
    if (ishandle(garesultfig) & ~gui & mod(gcount,5)==0);
      
      setappdata(garesultfig,'fit',fit);
      setappdata(garesultfig,'pop',pop);
      setappdata(garesultfig,'gcount',gcount);
      setappdata(garesultfig,'dups',dups);
      setappdata(garesultfig,'cavfit',cavfit);
      setappdata(garesultfig,'cbfit',cbfit);
      setappdata(garesultfig,'cavterms',cavterms);
      
    end
    
    %Shuffle data and form calibration and test sets
%     disp(sprintf('At generation %g the number of duplicates is %g',gcount,dups));
    
    avterms  = mean(sum(pop'));
    cavterms(gcount) = avterms;
    %     disp(sprintf('The average number of terms is %g',avterms));
    %     disp(sprintf('The fewest number of terms is %g',min(sum(pop'))));
    
    if strcmp(options.display,'on')
      disp(sprintf('Generation %g: using %g to %g terms (mean: %g) %g duplicates ',gcount,min(sum(pop')),max(sum(pop')),avterms,dups));
    end
    
    dups     = 0;
    fit    = zeros(maxlv,nopop);
    
    %Test each model in population
    drawnow
    for kk = 1:iter       %Number of iterations
      cvind  = floor(([1:m]'-1)/(m/split))+1;  
      if cvopt == 0   %0 = random
        %randomize the contents of blocks
        cvind  = shuffle(cvind); 
      else            %1 = contiguous
        %randomize only the start position of blocks
        rind=floor(rand*m/split);
        cvind = cvind([rind+2:end 1:rind+1]);
      end
      for i = 1:nopop
        %Check to see that model isn't a repeat
        dflag = 0;
        if i > 1
          for ii = 1:i-1
            dif = sum(abs(pop(i,:) - pop(ii,:)));
            if dif == 0
              dflag = 1;
              fit(:,i) = fit(:,ii);
            end
          end
        end
        
        if dflag == 1;
          if kk == 1
            dups = dups + 1;
          end
        elseif dflag == 0;
          
          %Select the proper columns for use in modeling
          inds = find(pop(i,:))*window;
          [smi,sni] = size(inds);
          if inds(1) <= n
            ninds = [inds(1)-window+1:inds(1)];
          else
            ninds = [inds(1)-window+1:n];
          end
          for aaa = 2:sni
            if inds(aaa) <= n
              ninds = [ninds [inds(aaa)-window+1:inds(aaa)]];
            else
              ninds = [ninds [inds(aaa)-window+1:n]];
            end
          end
          ninds = unique(min(max(repmat([-winwidth:winwidth]',1,length(ninds))+repmat(ninds,winwidth*2+1,1),1),n))';
          
          %mark them in includ
          xuse = x;  %make copy so we don't explode the DSO history
          xuse.includ{2} = intersect(ninds,originclud{2});
          mxx            = length(xuse.includ{1});
          nxx            = length(xuse.includ{2});
          
          lvs = min([mxx nxx,maxlv]);     %note maxlv = 1 for mlr so lvs will = 1 too
          if nxx==0
            fit(:,i) = Inf;
          else
            % If y is a matrix (size(y,2)>1) then the mean is derived from the results.
            if ~discrim;
              [press,cumpress] = crossval(xuse,y,regmthd,cvind,lvs,0,meancenter);
              if size(y,2)>1; cumpress = mean(cumpress,1); end   %mean for all y's
              fit(1:length(cumpress),i) = fit(1:length(cumpress),i) + (sqrt(cumpress/m))';
              fit(length(cumpress)+1:end,i) = Inf;  %"really bad fit" for uncalculated models
            else
              [press,cumpress,rmsecv] = crossval(xuse,y,regmthd,cvind,lvs,0,meancenter,{});
              if size(y,2)>1; rmsecv = mean(rmsecv,1); end   %mean for all y's
              fit(1:size(rmsecv,2),i) = fit(1:size(rmsecv,2),i) + rmsecv';
              fit(size(rmsecv,2)+1:end,i) = Inf;  %"really bad fit" for uncalculated models
              %               [press,cumpress,rmsecv,rmsec,cvypred,misclassed] = crossval(xuse,y,regmthd,cvind,lvs,0,meancenter,{});
              %               fit(1:size(misclassed{1},2),i) = fit(1:size(misclassed{1},2),i) + mean(misclassed{1})';
              %               fit(size(misclassed{1},2)+1:end,i) = Inf;  %"really bad fit" for uncalculated models
            end
          end
          
          if ismember(options.plots,{'intermediate'}) & ~ishandle(garesultfig); break; end;
          
%           figure(fig)
%           subplot(2,2,1);
%           hold on
%           plot(length(ninds),min(fit(:,i))./kk,'k.');
%           hold off
%           if mod(i,round(nopop/5))==0; drawnow; end

          if gui; 
            setappdata(handles.stop,'stillrunning',now);           %store last update ("still running!") time
            setappdata(handles.stop,'resultsfig',garesultfig);           
          end
          
        end
      end
      if ismember(options.plots,{'intermediate'}) & ~ishandle(garesultfig); break; end;
    end
    if ismember(options.plots,{'intermediate'}) & ~ishandle(garesultfig); break; end;
    
    fit = fit ./ iter;
    
    %Sort models based on fitness
    drawnow
    if reg == 1
      if maxlv ==1
        mfit       = fit;
      else
        mfit       = min(fit);
      end
    else
      mfit = fit;
    end
    
    %Weighting function based on # of selected variables
    weightedmfit   = mfit.*limitgapop(sum(pop'),target,targetpenality);
    [junk,ind]     = sort(weightedmfit);    %sort by user-weighted fit values
    mfit           = mfit(ind);       %then sort real list using indicies from user-weighted fit
    %Above lines replace following old code:
    %[mfit,ind]    = sort(mfit);
    
    %     disp(sprintf('The best fitness is %g',mfit(1)));
    cbfit(gcount)  = mfit(1);
    %     disp(sprintf('The average fitness is %g',mean(mfit)));
    
    
    if strcmp(options.display,'on')
      disp(sprintf('    Fitness: Mean %g   Best %g',mean(mfit),mfit(1)));
    end
    
    cavfit(gcount) = mean(mfit);
    pop            = pop(ind,:);

    sumpop         = sum(pop');
    mnfit          = min(mfit); 
    mxfit          = max(mfit);

    if ismember(options.plots,{'intermediate'})
      if strcmpi(options.windowfocus,'on')
        figure(garesultfig)
      end
      
      ax1 = subplot(2,2,1,'parent',garesultfig);
      plot(ax1,sumpop,mfit,'og')
      yline_loop(ax1,allvarsfit,'r--')
    end
    
    %add penalized values, if weight function is penalizing any points
    penalize = limitgapop(sumpop,target,targetpenality);
    if ismember(options.plots,{'intermediate'})
      if any(penalize~=1);
        hold(ax1,'on')
        plot(ax1,sumpop,mfit.*penalize,'r.');
      end
      hold(ax1,'off')

      dfit           = mxfit - mnfit; if dfit == 0, dfit=1; end
      axis(ax1,[min(sumpop)-1 max(sumpop)+1 mnfit-dfit/10 mxfit+dfit/10])
      if window > 1
        xlabel(ax1,'Number of Windows')
        s = sprintf('Fitness vs. # of Windows at Generation %g',gcount);
      else
        xlabel(ax1,'Number of Variables')
        s = sprintf('Fitness vs. # of Variables at Generation %g',gcount);
      end
      title(ax1,s)
      ylabel(ax1,'Fitness')
      set(ax1,'FontSize',9)
      set(get(ax1,'Ylabel'),'FontSize',9)
      set(get(ax1,'Title'),'FontSize',9)
      set(get(ax1,'Xlabel'),'FontSize',9)
      
      ax2 = subplot(2,2,2,'parent',garesultfig);
      plot(ax2,1:gcount,cavfit(1:gcount),1:gcount,cbfit(1:gcount))
      yline_loop(ax2,allvarsfit,'r--')
      xlabel(ax2,'Generation')
      ylabel(ax2,'Average and Best Fitness')
      title(ax2,'Evolution of Average and Best Fitness')
      set(ax2,'FontSize',9)
      set(get(ax2,'Ylabel'),'FontSize',9)
      set(get(ax2,'Title'),'FontSize',9)
      set(get(ax2,'Xlabel'),'FontSize',9)
      ax = axis(ax2);
      axis(ax2,[1 max(2,gcount) ax(3:4)])

      ax3 = subplot(2,2,3,'parent',garesultfig);
      plot(ax3,cavterms(1:gcount))
      xlabel(ax3,'Generation')
      if window > 1
        ylabel(ax3,'Average Windows Used')
        title(ax3,'Evolution of Number of Windows')
      else
        ylabel(ax3,'Average Variables Used')
        title(ax3,'Evolution of Number of Variables')
      end
      set(ax3,'FontSize',9)
      set(get(ax3,'Ylabel'),'FontSize',9)
      set(get(ax3,'Title'),'FontSize',9)
      set(get(ax3,'Xlabel'),'FontSize',9)
      ax = axis(ax3);
      axis(ax3,[1 max(2,gcount) ax(3:4)])
      
      ax4 = subplot(2,2,4,'parent',garesultfig);
      bar(ax4,sum(pop))
      if window > 1
        xlabel(ax4,'Window Number')
        ylabel(ax4,'Models Including Window')
        s = sprintf('Models with Window at Generation %g',gcount);
      else
        xlabel(ax4,'Variable Number')
        ylabel(ax4,'Models Including Variable')
        s = sprintf('Models with Variable at Generation %g',gcount);
      end
      title(ax4,s)
      axis(ax4,[0 ceil(n/window)+1 0 nopop+2])
      set(ax4,'FontSize',9)
      set(get(ax4,'Ylabel'),'FontSize',9)
      set(get(ax4,'Title'),'FontSize',9)
      set(get(ax4,'Xlabel'),'FontSize',9)
      drawnow
    end
    
    % Check to see if maxgen has been met
    if gcount >= maxgen
      dups = maxdups;
    end
    
    % Breed best half of population and replace worst half
    pop(1:nopop/2,:) = shuffle(pop(1:nopop/2,:));
    pop((nopop/2)+1:nopop,:) = pop(1:nopop/2,:);
    for i = 1:nopop/4
      for j = 1:cross
        %Select twist point at random
        tp = ceil(rand(1)*(specsplit-1));
        %Twist pairs and replace
        p1 = (nopop/2)+(i*2)-1;
        p2 = (nopop/2)+(i*2);
        p1rep = [pop(p1,1:tp) pop(p2,tp+1:specsplit)];
        p2rep = [pop(p2,1:tp) pop(p1,tp+1:specsplit)];
        pop(p1,:) = p1rep;
        pop(p2,:) = p2rep;
      end
    end
    
    %Mutate the population if dups < maxdups
    if dups < maxdups
      mutatemask=rand(nopop,specsplit)<mut;           %identify positions to change
      
      if 1;
        %"evenmutate" : tendency to keep same # of variables included (chance of adding = # already there)
        
        addmask=rand(nopop,specsplit)<(mean(pop')'*ones(1,specsplit));
        %specify type of change (1=add, 0=remove) chance of add is = ratio of ones already there
        
        pop=(pop | (addmask & mutatemask));             %spots to be mutated ADDED, OR with current mask
        %  note:   ^^^^^^^^^^^^^^^^^^^^^^ will be 1 only if both addmask AND mutatemask are 1
        %     and then that position will be set to 1 no matter what pop was
        pop=(pop & ~(~addmask & mutatemask));           %spots to be mutated REMOVED, AND with current mask
        %  note:   ^^^^^^^^^^^^^^^^^^^^^^^^ will only be 0 IF addmask is 0 and mutatemask is 1
        %     which says "set position to 0" (when anded with pop). Otherwise it will be 1 implying
        %     "leave position alone"
        
      else
        %JMS - vectorized code 2/22/01
        pop=xor(pop,mutatemask);              %random mutate (trends towards 50% included)
      end
    end
    
    pop(:,numincluded==0) = 0;   %zero out windows without included variables
    for i=find(sum(pop,2)==0)';                %jms 12/19/02 new test 
      %for i=1:nopop                %nbg 10/27/00, start, check if any row of pop all zero,
      %       if sum(pop(i,:))==0
      j = shuffle(find(numincluded(:)>0));
      pop(i,j(1)) = 1;   %invert ONE of the included windows/variables
      %       end
    end                          %nbg 10/27/00, end

    gcount = gcount + 1;
  end
  %End of Main Loop
  
  if ismember(options.plots,{'intermediate'}) & ~ishandle(garesultfig); 
    if gui;
      ffit=[]; gpop=[]; 
    else
      error('run aborted by figure close')
    end
  end;
  
  if dups >= maxdups
    if gui; set([handles.stop handles.resume],'Enable','Off'); end          %turn off "stop" button and resume button until we're done with final analysis
    drawnow
    %Extract unique models from final population
    fpop = zeros(nopop-dups,specsplit);
    uniq = 0; dups = 0;
    for i = 1:nopop
      dflag = 0;
      if i > 1
        for ii = 1:i-1
          dif = sum(abs(pop(i,:) - pop(ii,:)));
          if dif == 0
            dflag = 1;
          end
        end
      end
      if dflag == 1
        dups = dups + 1;
      else
        uniq = uniq + 1;
        fpop(uniq,:) = pop(i,:);
      end
    end
    if strcmp(options.display,'on')
      disp(sprintf('There are %g unique models in final population',uniq));
    end
    %Testing final population
    if reg == 1
      fit = zeros(maxlv,uniq);
    else
      fit = zeros(1,uniq);
    end
    if strcmp(options.display,'on')
      disp('Now testing models in final population')
    end
    
    if cvopt == 0;
      finaliter = 3*iter;     %do final iterations 3x for random
    else
      finaliter = 1;
    end
    for kk = 1:finaliter       %Number of iterations
      cvind  = floor(([1:m]'-1)/(m/split))+1;  
      if cvopt == 0   %0 = random
        %randomize the contents of blocks
        cvind  = shuffle(cvind); 
      else            %1 = contiguous
        %randomize only the start position of blocks
        rind=floor(rand*m/split);
        cvind = cvind([rind+2:end 1:rind+1]);
      end
      for i=1:uniq
        %Select the proper columns for use in modeling
        inds      = find(fpop(i,:))*window;
        [smi,sni] = size(inds);
        if inds(1)<=n
          ninds = [inds(1)-window+1:inds(1)];
        else
          ninds = [inds(1)-window+1:n];
        end
        for aaa=2:sni
          if inds(aaa) <= n
            ninds = [ninds [inds(aaa)-window+1:inds(aaa)]];
          else
            ninds = [ninds [inds(aaa)-window+1:n]];
          end
        end
        
        %mark them in includ
        x.includ{2} = intersect(ninds,originclud{2});
        mxx         = length(x.includ{1});
        nxx         = length(x.includ{2});
        
        lvs = min([nxx,maxlv]);     %note maxlv = 1 for mlr so lvs will = 1 too
        if ~discrim;
          % If y is a matrix (size(y,2)>1) then the mean is derived from the results.
          try
            [press,cumpress] = crossval(x,y,regmthd,cvind,lvs,0,meancenter);
            if size(y,2)>1; cumpress = mean(cumpress,1); end   %mean for all y's
            fit(1:length(cumpress),i) = fit(1:length(cumpress),i) + (sqrt(cumpress/m)/finaliter)';
            fit(length(cumpress)+1:lvs,i) = Inf;
            %             fit(1:lvs,i) = fit(1:lvs,i) + (sqrt(cumpress/m)/finaliter)';
          catch
            fit(1:lvs,i) = Inf;   %can't do crossval? mark as really bad model
          end
        else
          try
            [press,cumpress,rmsecv,rmsec,cvypred,misclassed] = crossval(x,y,regmthd,cvind,lvs,0,meancenter,{});
            if size(y,2)>1; rmsecv = mean(rmsecv,1); end   %mean for all y's
            fit(1:length(rmsecv),i) = fit(1:length(rmsecv),i) + (rmsecv'/finaliter);
            fit(length(rmsecv)+1:lvs,i) = Inf;
            %             fit(1:lvs,i) = fit(1:lvs,i) + rmsecv'/finaliter;
            %             fit(1:lvs,i) = fit(1:lvs,i) + mean(misclassed{1})'/finaliter;
          catch
            fit(1:lvs,i) = Inf;   %can't do crossval? mark as really bad model
          end
        end
        if lvs < maxlv
          fit(lvs+1:maxlv,i) = Inf;     %models for which we didn't have enough vars for are also really bad ones
        end
        
        if kk == finaliter
          if reg == 1
            [mf,ind] = min(fit(:,i));
            s = sprintf('Number %g fitness is %g at %g LVs',i,mf,ind);
          else
            s = sprintf('Number %g fitness is %g',i,min(fit(:,i)));
          end
          if strcmp(options.display,'on')
            disp(s)
          end
        end
      end
    end
    if reg==1
      if size(fit,1)==1 %modified 2/10/98
        mfit = fit;
      else
        mfit = min(fit,[],1);
      end %end modification 2/10/98
    else
      mfit = fit;
    end
    [mfit,ind] = sort(mfit);
    if strcmp(options.display,'on')
      disp(sprintf('The best fitness is %g',mfit(1)));
      disp(sprintf('The average fitness is %g',mean(mfit)));
    end
    fpop       = fpop(ind,:);
    ffit       = mfit;
    % Translate the population (in terms of windows) into the
    % actual variables used in the final population.
    if window == 1
      gpop = fpop;
    else
      gpop = zeros(uniq,n);
      for jk = 1:uniq
        inds = find(fpop(jk,:))*window;
        [smi,sni] = size(inds);
        if inds(1) <= n
          ninds = [inds(1)-window+1:inds(1)];
        else
          ninds = [inds(1)-window+1:n];
        end
        for aaa = 2:sni
          if inds(aaa) <= n
            ninds = [ninds [inds(aaa)-window+1:inds(aaa)]];
          else
            ninds = [ninds [inds(aaa)-window+1:n]];
          end
        end
        [snmi,snni] = size(ninds);
        ninds = intersect(ninds,originclud{2});
        gpop(jk,ninds) = 1;
      end
    end
    
    cbfit(gcount)    = mfit(1);
    cavfit(gcount)   = mean(mfit);
    cavterms(gcount) = mean(sum(fpop'));
    
    sumpop         = sum(fpop');
    mnfit          = min(mfit); 
    mxfit          = max(mfit);
    dfit           = mxfit - mnfit; if dfit == 0, dfit=1; end

    if ismember(options.plots,{'intermediate','replicates'}) ...
        | (ismember(options.plots,{'final'}) & repcount==repdesired)
      if isempty(garesultfig);
        garesultfig = figure('Name','GA for Variable Selection Results',...
          'units','normalized',...
          'Pos',[0.4863    0.4753    0.4688    0.4167],...
          'Resize','On',...
          'tag','GAResultsPlot',...
          'NumberTitle','Off');;   %results plot
      else
        figure(garesultfig)
      end
      ax1 = subplot(2,2,1,'parent',garesultfig);
      plot(ax1,sumpop,mfit,'og')
      yline_loop(ax1,allvarsfit,'r--');
      axis(ax1,[min(sumpop)-1 max(sumpop)+1 mnfit-dfit/10 mxfit+dfit/10])
      if window > 1
        xlabel(ax1,'Number of Windows')
        s = sprintf('Fitness vs. # of Windows at Generation %g',gcount);
      else
        xlabel(ax1,'Number of Variables')
        s = sprintf('Fitness vs. # of Variables at Generation %g',gcount);
      end
      title(ax1,s)
      ylabel(ax1,'Fitness')
      set(ax1,'FontSize',9)
      set(get(ax1,'Ylabel'),'FontSize',9)
      set(get(ax1,'Title'),'FontSize',9)
      set(get(ax1,'Xlabel'),'FontSize',9)

      ax2 = subplot(2,2,2,'parent',garesultfig);
      plot(ax2,1:gcount,cavfit(1:gcount),1:gcount,cbfit(1:gcount))
      yline_loop(ax2,allvarsfit,'r--');
      xlabel(ax2,'Generation')
      ylabel(ax2,'Average and Best Fitness')
      title(ax2,'Evolution of Average and Best Fitness')
      set(ax2,'FontSize',9)
      set(get(ax2,'Ylabel'),'FontSize',9)
      set(get(ax2,'Title'),'FontSize',9)
      set(get(ax2,'Xlabel'),'FontSize',9)
      ax = axis(ax2);
      axis(ax2,[1 max(2,gcount) ax(3:4)])

      ax3 = subplot(2,2,3,'parent',garesultfig);
      plot(ax3,cavterms(1:gcount))
      xlabel(ax3,'Generation')
      if window > 1
        ylabel(ax3,'Average Windows Used')
        title('Evolution of Number of Windows')
      else
        ylabel(ax3,'Average Variables Used')
        title('Evolution of Number of Variables')
      end
      set(ax3,'FontSize',9)
      set(get(ax3,'Ylabel'),'FontSize',9)
      set(get(ax3,'Title'),'FontSize',9)
      set(get(ax3,'Xlabel'),'FontSize',9)
      ax = axis(ax3);
      axis(ax3,[1 max(2,gcount) ax(3:4)])
      
      ax4 = subplot(2,2,4,'parent',garesultfig);
      bar(ax4,sum(fpop))
      if window > 1
        xlabel(ax4,'Window Number')
        ylabel(ax4,'Models Including Window')
        s = sprintf('Models with Window at Generation %g',gcount);
      else
        xlabel(ax4,'Variable Number')
        ylabel(ax4,'Models Including Variable')
        s = sprintf('Models with Variable at Generation %g',gcount);
      end
      title(ax4,s)
      axis(ax4,[0 ceil(n/window)+1 0 uniq+2])
      set(ax4,'FontSize',9)
      set(get(ax4,'Ylabel'),'FontSize',9)
      set(get(ax4,'Title'),'FontSize',9)
      set(get(ax4,'Xlabel'),'FontSize',9)
      drawnow
    end
    
  end    
  
  if gui
    allreps.ffit   = getappdata(guifig,'ffit');
    allreps.gpop   = getappdata(guifig,'gpop');
    allreps.cavfit = getappdata(guifig,'cavfit');
    allreps.cbfit  = getappdata(guifig,'cbfit');
  end
  
  allreps.ffit = [allreps.ffit ffit];
  allreps.gpop = [allreps.gpop;gpop];
  if repcount > 1;
    if length(cavfit) < size(allreps.cavfit,2);
      allreps.cavfit = allreps.cavfit(:,1:length(cavfit));
      allreps.cbfit  = allreps.cbfit(:,1:length(cbfit));
    else
      cavfit = cavfit(1:size(allreps.cavfit,2));
      cbfit  = cbfit(1:size(allreps.cbfit,2));
    end
    allreps.cavfit(repcount,:) = cavfit;
    allreps.cbfit(repcount,:)  = cbfit;
  else
    allreps.cavfit = cavfit;
    allreps.cbfit  = cbfit;
  end
  
  if gui
    setappdata(guifig,'ffit',allreps.ffit)
    setappdata(guifig,'gpop',allreps.gpop)
    setappdata(guifig,'cavfit',allreps.cavfit)
    setappdata(guifig,'cbfit',allreps.cbfit)
    
    set(handles.stop,'Enable','On');             %turn "stop" button back on
    set(handles.replicatestext,'string',['Replicate Runs: ',num2str(repcount),' of ']);
  else
    if ismember(options.plots,{'intermediate','replicates','final'}) & ishandle(garesultfig);
      setappdata(garesultfig,'allfit',allreps.ffit)
      setappdata(garesultfig,'allpop',allreps.gpop)
      setappdata(garesultfig,'allavfit',allreps.cavfit)
      setappdata(garesultfig,'allbfit',allreps.cbfit)    
    end  
  end  
  if ismember(options.plots,{'intermediate'}) & ~ishandle(garesultfig); break; end;
  
  if strcmp(options.display,'on')
    disp(' ')
    disp(sprintf('  ******* Done with replicate %g of %g (Est. Time Remaining: %s) *******',repcount,repdesired,besttime(((now-starttime)*60*60*24/repcount)*(repdesired-repcount))))
    disp(' ')
  end
  
  action='gogas';                            %and make next rep look like a new start
  
end

if gui
  set(handles.replicatestext,'string',['Replicate Runs:']);     %reset replicate label
end


if nargout > 1;
  fit    = allreps.ffit;      %the actual output variables
  pop    = allreps.gpop;
  cavfit = allreps.cavfit;
  cbfit  = allreps.cbfit;
else
  modl             = modelstruct('genalg');
  modl.datasource  = {getdatasource(x) getdatasource(y)};
  modl.date        = date;    %date
  modl.time        = clock;   %time
  modl.rmsecv      = allreps.ffit;  %fit
  modl.icol        = allreps.gpop;  %pop
  modl.detail.avefit   = allreps.cavfit;
  modl.detail.bestfit  = allreps.cbfit;
  modl.detail.allvarsfit = allvarsfit;
  modl.detail.options  = options;
  fit = modl;
end

%--------------------------------------------------------------------------------------------------
function out=limitgapop(selected,target,slope)
%LIMITGAPOP calculate scaling for fit results based on the # of selected variables
%  <IN>  selected     : vector containing # of selected indicies for each individual in population
%        target       : target # of variables to include. A single value will target that value. 
%             A two element target array will allow any # between the two values without penalty
%        slope        : penalization slope (penalization per # of variables off of target) [default: 0.01]
% <OUT>       out     : scaling factor for each individual in population
%
% I/O:  out = limitgapop(selected,target,slope)

%make target two items if only one target specified
if length(target)==1; 
  target=[target target]; 
end
target=sort(target);    %put target range in increasing order

%start with no penalty
out = ones(size(selected));    
if slope > 0;
  if isfinite(target(2))
    %calculate penalty for above target individuals
    out = out + (selected>target(2)).*abs(selected-target(2))*slope;
  end
  if isfinite(target(1))
    %calculate penaltiy for below target individuals
    out = out + (selected<target(1)).*abs(selected-target(1))*slope;
  end
end

%--------------------------------------------------------------------------------------------------
function out = besttime(time)
% BESTTIME  returns a string describing the time interval provided (in seconds)
%  usage:  string=besttime(time)
%  where time is the time interval to be described (in seconds)
%  string is the output string (eg. 95 seconds gives "1.5 minutes")
units='seconds';

if all(abs(time/60)<1);
  units='seconds';
else;
  if all(abs(time/60/60)<1.5);
    units='minutes';
    time=time/60;
  else;
    if all(abs(time/60/60/24)<1.5);
      units='hours';
      time=time/60/60;
    else;
      units='days';
      time=time/60/60/24;
    end
  end
end

out=[num2str(round(time*10)/10) ' ' units];

%--------------------------------------------------------------------------------------------------
function yline_loop(myax,allvarsfit,linespec)
% Loop over call to yline. This is needed for MATLAB 2020b. Newer versions
% of yline can take multiple values for the line (second input). 

% TODO: This loop can be removed in the future. 
disp('yline loop')
for i = 1:length(allvarsfit)
  yline(myax,allvarsfit(i),linespec);
end
