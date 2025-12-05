function [result,fig] = splithalf(varargin)
%SPLITHALF performs splithalf validation of PARAFAC and PARAFAC2 models
%  A model is fitted on the whole dataset as well as on two independent
%  halfes. The resulting loadings are compared. If they are similar, the
%  number of components used is feasible.
%
% INPUTS:
%    x = data. Note that more than three samples have to be
%              in the data to do splithalf analysis
%    nocomp  = number of components to use in PARAFAC
%    options = is an optional structure that is used to enable advanced settings:
%
%           display : [{'on'}|'off'] governs display at command line
%             plots : [{'on'}|'off'] governs plotting
%           waitbar : [{'on'}|'off'] governs display of waitbar for
%                     splithalf looping (separate from modeloptions.waitbar
%                     which governs individual model building waitbars)
%       splitmethod : [{'default'}|'random'] [set to default to test AB/CD
%                     and AC/BD]. This means that the samples are arranged as
%                     [A B C D] and then first the first half (AB) is modelled
%                     and compared to the last half (CD). Independently, a
%                     model on the samples AC is compared to BD. The one of
%                     the two that works best (highest similarity) is
%                     plotted and used.
%                     Alternatively, set to 'random' to split the dataset
%                     randomly into two groups if your data are ordered, so that
%                     certain phenomena are only expected in certain parts,
%      modeloptions : for PARAFAC, the default options (parafac('options'))
%                     can be given or modified as desired. If you need to
%                     splithalf validate a PARAFAC2 models, simply input
%                     PARAFAC2 options (parafac2('options')).
%
%  OUTPUT:
%
%     result  = a structure containing the main results in results.splithalf.
%               The similarity between components is calculated by an uncorrected 
%               correlation (Tuckers congruence) for each pair of vectors 
%               in the variable modes. The similarity is measured using the 
%               best possible ordering of components in the two splits - 
%               because the components may not come out in the same order. 
%               Each vector in each splits is compared to each other by 
%               congruence and multiplied with the congruence of each vectors 
%               similarity to the overall model to correct for unreasonable 
%               solutions (where the overall model is different from the 
%               two splits). These similarities are then multiplied for 
%               each variable mode. So in a three-way array with samples 
%               in the first mode, the similarities are combined from two 
%               and three. The result is a number between 0 (bad) and 1 (perfect). 
%               It is saved in result.splithalf.quality and it is multiplied 
%               with 100 to turn it into a percentage in the figure.
%         fig = the figure number created for the plotted results (if any)
%
%I/O: [result,fig] = splithalf(x,ncomp,options)
%I/O: [result,fig] = splithalf(x,model,options); % If a model is given,
%                               modeloptions will be used from that
%I/O: fig = splithalf(result)  % Plot results
%
%See also: PARAFAC, PARAFAC2

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% To-do: Maybe implement each submodel with the result of the overall model

options =[];
if nargin == 0;
  varargin{1} = 'io';
end
if ischar(varargin{1});
  %special functions
  switch varargin{1}
    case 'showhide'
      showhide(varargin{2:end});
      return
      
    otherwise
      %evriio call
      options.display = 'on';
      options.plots = 'on';
      options.waitbar = 'on';
      options.splitmethod = 'default';
      options.modeloptions = parafac('options');
      if nargout==0;
        evriio(mfilename,varargin{1},options);
      else;
        result = evriio(mfilename,varargin{1},options);
      end
      return
      
  end
end

if nargin > 2;
  options = varargin{3};
else
  options = [];
end
options = reconopts(options,'splithalf');

% If old model is given instead of ncomp
modelknown = 0;
if nargin>1
  if isstruct(varargin{2});
    modelknown = 1;
    M = varargin{2}; % So we don't have to fit overall model again
    options.modeloptions = M.detail.options; % Use the modeloptions from the given model
    % Number of components
    varargin{2} = M.ncomp;
  end
end

% SET UP DEFAULT PARAMETERS
method = options.modeloptions.functionname;
samplemode = options.modeloptions.samplemode;

if nargin==1
  %do plot
  method = varargin{1}.overallmodel.modeltype;
  result = doplot(varargin{1},method);
  return
end

% Do actual fitting
order = length(size(varargin{1}));
options.modeloptions.display = 'off';
options.modeloptions.waitbar = 'off';
options.modeloptions.plots  = 'off';

% Make sure data are in a dataset
if ~isa(varargin{1},'dataset')% Then it's an SDO
  varargin{1}=dataset(varargin{1});
end

% Remove non-included samples already here. It seems that otherwise they
% get included in the analysis
inc = varargin{1}.include;
varargin{1}=varargin{1}(inc{:});

if size(varargin{1}.data,samplemode)<4
  error(' At least four samples are needed in order to perform splithalf analysis')
end
% Define split sets
if ischar(options.splitmethod)
  if strcmpi(options.splitmethod,'default')
    I  = size(varargin{1}.data,samplemode);
    i1 = round(I/4);
    i2 = round(I/2);
    i3 = i1+i2;
    split{1}.idx{1} = 1:i2;             % Split 1, A
    split{1}.idx{2} = i2+1:I;           % Split 1, B
    split{2}.idx{1} = [1:i1 i2+1:i3];   % Split 2, C
    split{2}.idx{2} = [i1+1:i2 i3+1:I]; % Split 2, D
  elseif strcmpi(options.splitmethod,'random')
    I  = size(varargin{1}.data,samplemode);
    idx = randperm(I);
    i1 = round(I/4);
    i2 = round(I/2);
    i3 = i1+i2;
    split{1}.idx{1} = idx(1:i2);             % Split 1, A
    split{1}.idx{2} = idx(i2+1:I);           % Split 1, B
    split{2}.idx{1} = idx([1:i1 i2+1:i3]);   % Split 2, C
    split{2}.idx{2} = idx([i1+1:i2 i3+1:I]); % Split 2, D
  else
    error('splitmethod %s not implemented',options.splitmethod)
  end
end

% Do overall model
if strcmpi(method,'parafac')
  if ~modelknown
    if strcmpi(options.display,'on')
      disp('Fitting overall model')
    end
    M = parafac(varargin{1},varargin{2},options.modeloptions);  % Overall model
  else
    if strcmpi(options.display,'on')
      disp('Model on all data already calculated')
    end
  end
elseif strcmpi(method,'parafac2')
  if ~modelknown
    if strcmpi(options.display,'on')
      disp('Fitting overall model')
    end
    M = parafac2(varargin{1},varargin{2},options.modeloptions);  % Overall model
  else
    if strcmpi(options.display,'on')
      disp('Model on all data already calculated')
    end
  end
end

% Calculate how many models we'll be doing
totalmods = 1;
complete = 1;  %start a 1 so the waitbar has something in it to start
for i = 1:length(split);
  totalmods = totalmods + length(split{i}.idx);
end

% Create waitbar and move to be above standard waitbar position
if strcmpi(options.waitbar,'on');
  wbh = waitbar(1/totalmods,'Performing Split Half Analysis (Close to Cancel)');
  set(wbh,'units','pixels');
  pos = get(wbh,'position');
  pos(2) = pos(2)+pos(4)*2;
  set(wbh,'position',pos);
  set(wbh,'closerequestFcn','delete(findall(0,''tag'',''TMWWaitbar''))')  %force ALL waitbars to be closed (so parafac call is cancelled too)
else
  wbh = [];
end

% Perform splithalf
try
  for i = 1:length(split)
    for j=1:length(split{i}.idx)
      if strcmp(options.display,'on')
        disp(['Fitting model ',num2str(j),' in split ',num2str(i)]);
      end
      X = varargin{1};
      X.include{samplemode} = split{i}.idx{j}; % Include only the relevant samples
      if strcmpi(method,'parafac')
        Model.split{i}.set{j} = parafac(X,varargin{2},options.modeloptions);  % Overall model
        
        % Match split model to overall model
        submodel = Model.split{i}.set{j};
        submodel = matchmodels(M,submodel,samplemode,method);
        Model.split{i}.set{j} = submodel;
      elseif strcmpi(method,'parafac2')
        Model.split{i}.set{j} = parafac2(X,varargin{2},options.modeloptions);  % Overall model
        
        % Match split model to overall model
        submodel = Model.split{i}.set{j};
        submodel = matchmodels(M,submodel,samplemode,method);
        Model.split{i}.set{j} = submodel;
      end
      if ~isempty(wbh)
        if ~ishandle(wbh)
          error('User Aborted Analysis');
        end
        complete = complete+1;
        waitbar(complete/totalmods,wbh)
      end
    end
  end
catch
  le = lasterror;
  if ~isempty(wbh) & ishandle(wbh)
    delete(wbh);
  end
  rethrow(le)
end

if ~isempty(wbh) & ishandle(wbh)
  delete(wbh);
end

for i=1:order
  if i~=samplemode
    if ~(i==1 & strcmp(method,'parafac2')) % Skip first shifting mode in PARAFAC2
      % Do congruence
      for s = 1:length(split)
        ccc = nm(Model.split{s}.set{1}.loads{i})'*nm(Model.split{s}.set{2}.loads{i});
        ccc2 = nm(Model.split{s}.set{1}.loads{i})'*nm(M.loads{i}); % Also compare to overall model
        ccc3 = nm(Model.split{s}.set{2}.loads{i})'*nm(M.loads{i}); % Also compare to overall model
        correlations{i}.split{s} = ccc.*ccc2.*ccc3;
      end
    end
  end
end

% Make a combined overall quality index
for s=1:length(split)
  ind{s} = repmat(NaN,1,varargin{2});
  quality{s}=0;
  qual{s}=ones(varargin{2},varargin{2});
  for i=1:order
    if i~=samplemode
      if ~(strcmpi(method,'parafac2')&i==1)
        qual{s}=qual{s}.*correlations{i}.split{s};
      end
    end
  end
end
% Chk which combination of factors in the two splits are best
permu = perms([1:varargin{2}]);
for s=1:length(split)
  for j = 1:size(permu,1)
    %check
    thisqual = 1;
    for k =1:varargin{2}
      thisqual = thisqual*qual{s}(k,permu(j,k));
    end
    if abs(thisqual)>quality{s}
      quality{s} = thisqual;
      ind{s} = [1:varargin{2};permu(j,:)];
    end
  end
end

bestqual = quality{1};
best = 1;
for s=2:length(split)
  if abs(quality{s})>abs(bestqual)
    best = s;
    bestqual = quality{s};
  end
end
result.splithalf.quality = bestqual;
result.splithalf.bestsplit = best;

result.overallmodel = M;
result.samplesets   = split;
result.splitmodels  = Model;
result.correlations = correlations;

if strcmpi(options.plots,'on')
  fig = doplot(result,method);
else
  fig = [];
end

%----------------------------------------------------
function fig = doplot(result,method)

samplemode = result.overallmodel.detail.options.samplemode;
order = length(result.overallmodel.loads);

fig = figure('toolbar','none','name','Split Half Results');
counter=0;
if strcmpi(method,'parafac')
  howmanymodes = order-1;
elseif strcmpi(method,'parafac2')
  howmanymodes = order-2;
else
  error('Something went wrong here, I am afraid')
end
for i=1:order
  if i~=samplemode
    if ~(strcmpi(method,'parafac2')&i==1);
      counter = counter+1;
      subplot(howmanymodes,1,counter)
      a=plot(nm(result.overallmodel.loads{i}),'color',[1 1 1]*0.2,'linewidth',7);
      % Turn of legends for all but the first line
      for ac=2:length(a)
        set(get(get(a(ac),'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % Exclude line from legend
      end
      if counter==1
        
        %result.splithalf.quality
        % qu = result.splithalf.details{f}.overall.quality;
        % qu = result.overall.quality;
        qu = result.splithalf.quality;
        title(['Similarity measure of splits and overall model ',num2str(.1*round(1000*qu)),'%'],'Fontsize',14,'Fontweight','bold');
      end
      hold on;
      lw = 3;
      kk = .5;
      whichone = result.splithalf.bestsplit;
      b = plot(nm(result.splitmodels.split{whichone}.set{1}.loads{i}),'--','color',[kk kk 1],'linewidth',lw);
      c = plot(nm(result.splitmodels.split{whichone}.set{2}.loads{i}),'-','color',[kk kk 1 ],'linewidth',lw);
      % Turn of legends for all but the first line
      for ac=2:length(b)
        set(get(get(b(ac),'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % Exclude line from legend
      end
      % Turn of legends for all but the first line
      for ac=2:length(c)
        set(get(get(c(ac),'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % Exclude line from legend
      end
      axis tight
      xlabel(['Mode ',num2str(i)],'Fontsize',14,'Fontweight','bold');
      legend({'Overall model';'Set 1';'Set 2'})
      set(a,'tag','a')
      set(b,'tag','b')
      set(c,'tag','c')
      ha = uicontrol('Parent',fig, ...
        'Units','normalized', ...
        'callback','splithalf(''showhide'',''a'');',...
        'Style','pushbutton', ...
        'Tag','StaticText1', ...
        'HandleVisibility','off', ...
        'HorizontalAlignment','center', ...
        'Position',[0.01 0.01 0.20 0.05], ...
        'FontSize',10, ...
        'ToolTipString',['Toggle the loadings of the overall model'], ...
        'handlevisibility','on', ...
        'String','Overall');
      
      hb = uicontrol('Parent',fig, ...
        'Units','normalized', ...
        'callback','splithalf(''showhide'',''b'');',...
        'Style','pushbutton', ...
        'Tag','StaticText1', ...
        'HandleVisibility','off', ...
        'HorizontalAlignment','center', ...
        'Position',[0.22 0.01 0.20 0.05], ...
        'FontSize',10, ...
        'ToolTipString',['Toggle the loadings of the first half of the data'], ...
        'handlevisibility','on', ...
        'String','Set 1');
      
      hd = uicontrol('Parent',fig, ...
        'Units','normalized', ...
        'callback','splithalf(''showhide'',''c'');',...
        'Style','pushbutton', ...
        'Tag','StaticText1', ...
        'HandleVisibility','off', ...
        'HorizontalAlignment','center', ...
        'Position',[0.43 0.01 0.20 0.05], ...
        'FontSize',10, ...
        'ToolTipString',['Toggle the loadings of the second half of the data'], ...
        'handlevisibility','on', ...
        'String','Set 2');
      hold off
    end
  end
end

%-----------------------------------------------------------------
function Xn = nm(X)

Xn=X;
for i=1:size(X,2)
  Xn(:,i)=Xn(:,i)/norm(Xn(:,i));
end

Xn = Xn * diag(sign(sum(Xn.^3)));

%-----------------------------------------------------------------
function showhide(item)

aa = findobj('tag',item);
try
  for i=1:length(aa),
    if strcmpi(get(aa(i),'visible'),'on'),
      set(aa(i),'visible','off');
    else
      set(aa(i),'visible','on');
    end
  end
catch
  %throw no error!!
end


function submodel = matchmodels(overall,submodel,samplemode,method);
% permutes the components in the parafac model submodel so
% that it fits with the overall model.

NumbComp=overall.ncomp;
order = length(overall.loads);
ccc = ones(NumbComp,NumbComp);
for i=1:order
  if i~=samplemode
    if ~(strcmp(method,'parafac2') & i==1)
      % Do congruence
      try
        ccc = ccc.*(nm(overall.loads{i})'*nm(submodel.loads{i}));
      catch % if overall model contains excluded samples, hence doesn't fit
        inc = overall.detail.include{i};
        ccc = ccc.*(nm(overall.loads{i}(inc,:))'*nm(submodel.loads{i}));
      end
    end
  end
end

% Chk which combination of factors in the two splits are best
permu = perms([1:NumbComp]);
bestsofar = [1:NumbComp];
E = eye(NumbComp);
E = E(:,bestsofar);
bestmatch = sum(sum(E.*ccc));
for i=1:size(permu,1)
  E = eye(NumbComp);
  E = E(:,permu(i,:));
  thismatch = sum(sum(E.*ccc));
  if thismatch>bestmatch
    bestmatch = thismatch;
    bestsofar = permu(i,:);
  end
end
E = eye(NumbComp);
E = E(:,bestsofar);
for i=1:order
  if strcmpi(method,'parafac2')&i==1
    submodel.loads{1}.H = submodel.loads{1}.H*E;
    for k=1:length(submodel.loads{1}.P)
      submodel.loads{1}.P{k} = submodel.loads{1}.P{k}*E;
    end
  else
    submodel.loads{i} = submodel.loads{i}*E;
  end
end
