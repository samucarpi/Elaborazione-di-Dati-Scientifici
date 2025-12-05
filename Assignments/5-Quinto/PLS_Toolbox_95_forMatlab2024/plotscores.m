function a = plotscores(modl,test,options)
%PLOTSCORES Extract and display score information from a model.
%  INPUT:
%       modl = a standard model structure. PLOTLOADS will extract the loads
%              (and other information) and labels for plotting.
%       pred = a standard prediction structure (e.g. output from PCA call:
%                pred  = pca(x,modl,options);).
%     scores = a MxK scores matrix of class "double".
%
%  OPTIONAL INPUTS:
%    options = structure array with the following fields:
%      plots: [ 'none' | 'final' | {'auto'} ]   governs plotting behavior
%                  'auto' makes plots if no output is requested.
%     figure: [ [] | (a valid figure number) ]  governs where plots are made
%                  figure = [] plots in a new figure window {default = []}.
%        sct: [ 0 | {1} ]    tells whether to plot cal with pred, sct = 1 
%                  plots original calibration data with prediction set {default = 1}.
%     knnscoredistance: [ 3 ] governs the inclusion of KNN score distance
%                  metric in factor-based methods. If >0, this option
%                  defines the number of neighbors to use in calculating
%                  the KNN Score Distance (see knnscoredistance function).
%                  If zero, KNN Score Distance is omitted from the scores.
%          title: [ {'off'} | 'on' ] governs inclusion of title on figures
%                  and in output DataSet. When 'on' text description of
%                  content (including source name) will be included on
%                  plots and in .title{1} field of output.
%   reducedstats: [ {'none'} | 'only' | 'both' ] governs reporting of
%                  statistics as "reduced" (normalized to confidence limit)
%                  when possible. 'both' returns both reduced and regular
%                  stats. 'only' returns only reduced stats. 'none' returns
%                  only regular stats.
%     showerrorbars: [ 0 | {1} ] governs default display of error bars
%                  (when available). If 1, error bars are shown
%                  automatically. If 0, user must use checkbox to enable
%                  error bar display.
%     autoclass: [{0} | 1 ] when enabled (1), classes are automatically
%                  assigned to samples using the density-based scanning
%                  method (see dbscan). Assignment is done by locating
%                  samples which are close to each other in the
%                  multivariate score space OR, if Sammon mapping has been
%                  done, in the reduced Sammon mapped space.
%     hiddenstats: {} list of statistics which should be hidden from scores
%                  plot right-click menu.
%
%     labels = a character or cell array with M rows containing sample labels, and
%    classes = a vector with M elements of class identifiers.
%
%  OUTPUT:
%     a = a dataset containing scores and label information that can be
%         passed to PLOTGUI.
%         With no output specified PLOTSCORES will create a scores plot.
%
%I/O: a = plotscores(modl,options);          %plots scores for a model structures
%I/O: a = plotscores(modl,pred,options);     %plots scores for model and pred structures
%I/O: a = plotscores(scores,labels,classes); %plots scores for scores matrices
%I/O: plotscores demo
%
%See also: ANALYSIS, KNNSCOREDISTANCE, MCR, MODELSTRUCT, MODELVIEWER, MPCA, PCA, PCR, PLOTEIGEN, PLOTGUI, PLOTLOADS, PLS

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS initial coding from DECOMPOSE 6/3/02
%nbg 9/02 changed help
%JMS fixed mpca bug
%jms 3/24/03 number of components in model from LOADS not SCORES
%jms 6/23/03 studentized residuals normalized based on included samples only
%  -don't give sample # if not there already (don't add an axisscale if empty)
%jms 7/22/03 fixed logic handling no-class test data
%JMS 8/20/03 added support for external helper functions for other model types
%JMS 2/3/04 removed unused code
%JMS 4/1/04 Expect model as appdata, not in handles structure
%jms 5/10/04 Added improved test for prediction structure passed as model
%rsk 8/2/04 added drawnow in output to fix redraw problem in R14 per jer fix in plotloads

%put into extensive help
%  Input (modl) can also be a valid GUI handle in which case a model
%   stored in the guidata 'model' or 'modl' field will be used.

if nargin == 0; modl = 'io'; end
varargin{1} = modl;
if ischar(varargin{1});
  options = [];
  options.name   = 'options';
  options.plots  = 'auto';
  options.figure = [];
  options.sct    = 1;
  options.showerrorbars = 1;
  options.knnscoredistance = 3;
  options.title = 'off';
  options.reducedstats = 'none'; 
  options.hiddenstats = {'r^2' 'r2y' 'q2y'};
  options.autoclass = false;
  if nargout==0; clear a; evriio(mfilename,varargin{1},options); else; a = evriio(mfilename,varargin{1},options); end
  return; 
end

showlimits = 1;  %assume we'll be showing confidence limits
if ~ismodel(modl) & prod(size(modl))>1;    %array instead of a model or a handle?
  %array inputs are (scores,labels,class) instead of (modl,test,options)
  switch nargin
    case 1
      scores  = modl;
      labels  = [];
      classes = [];
    case 2
      scores  = modl;
      labels  = test;
      classes = [];
    case 3
      scores  = modl;
      labels  = test;
      classes = options;
  end
  
  [m,n] = size(scores);
  
  if ~isempty(labels) & ((~iscell(labels) & size(labels,1)~=m) | (iscell(labels) & length(labels)~=m));
    error('Labels do not match number of samples (rows) in input SCORES');
  end
  
  if ~isempty(classes) & (length(classes)~=m);
    error('Classes do not match number of samples (rows) in input SCORES');
  end
  
  modl                  = modelstruct('pca');
  modl.loads{1}         = scores;
  modl.detail.label{1}  = labels;
  modl.detail.class{1}  = classes;
  modl.detail.includ{1} = 1:m;
  
  test = [];
  options = [];
  showlimits = 0;  %no info to give limits
  
else
  
  switch nargin
    case 1
      % (modl)
      options = [];
      test    = [];
    case 2
      % (modl,figure)  (handle,figure)
      % (modl,options)
      % (modl,test)
      if isnumeric(test)
        % (modl,figure)  (handle,figure)
        options        = [];
        options.figure = test;
        test           = [];
      elseif ~ismodel(test);
        % (modl,options)
        options = test;
        test = [];
      else
        % (modl,test)
        options = [];
      end
    case 3
      % (modl,test,options)
  end
  
  if ~ismodel(modl);
    
    handle = modl;
    if ~ishandle(handle)
      error('MODL input must be a valid model structure or valid object handle');
    end
    
    %extract info from object
    modl = getappdata(handle,'modl');
    if isempty(modl)
      modl = getappdata(handle,'model');
    end
    if isempty(modl);
      error('GUI object must have APPDATA of either "modl" or "model"');
    end  
    test = getappdata(handle,'test');
    if ~isfield(options,'figure') | isempty(options.figure);
      options.figure = handle;
    end
    
  end
end
options = reconopts(options,plotscores('options'));

if isempty(test);
  if isa(modl,'evrimodel') & modl.isprediction & ~isempty(modl.parent)
    test = modl;
    modl = test.parent;
  else
    options.sct = 0;
  end
end

if ~(~isempty(test) & options.sct==0) & ~ismodel(modl);
  error('Input MODL must be a standard model structure');
end
if ~isempty(test) & ~ismodel(test);
  error('Input TEST must be a standard model structure');
end
if modl.isprediction & ~isempty(test) & ismodel(test) & ~test.isprediction
  %model and test seem to be swapped
  temp = test;
  test = modl;
  modl = temp;
end

targetfn = ['plotscores_' lower(modl.modeltype)];     %see if there is a handler function
if exist(targetfn)    %found one, call it with appropriate inputs and outputs
  a = feval(targetfn,modl,test,options);
else
  if modl.isprediction
    error(['Prediction structures can only be plotted along with the original model structure']);
  else
    error(['Unable to plot scores for model type ' modl.modeltype]);
  end
end

%remove title if not wanted
if ~strcmpi(options.title,'on')
  a.title{1} = '';
end

if ~strcmpi(options.reducedstats,'none')
  %check for reduced stats option
  lbls = str2cell(a.label{2},1);
  qresind = max(find(~cellfun('isempty',regexp(lbls,'^Q Residuals?[^Reduced]','ignorecase'))));
  t2ind   = max(find(~cellfun('isempty',regexp(lbls,'^Hotelling T\^2?[^Reduced]','ignorecase'))));
  qresindred = max(find(~cellfun('isempty',regexp(lbls,'^Q Residuals Reduced','ignorecase'))));
  t2indred   = max(find(~cellfun('isempty',regexp(lbls,'^Hotelling T\^2 Reduced','ignorecase'))));
  toadd = [];
  lbladd = {};
  insertpoint = max([qresind t2ind]);
  if isfieldcheck(modl.detail,'detail.options.confidencelimit')
    plevel = sprintf(' (p=%4.3f)',modl.detail.options.confidencelimit);
  else
    plevel = '';
  end
  if isfield(modl.detail,'reslim')
    lim = modl.detail.reslim;
    if isstruct(lim) & isfield(lim,'lim95')
      lim = {lim.lim95(1)};
      plevel = ' (p=0.950)';
    end
    if isempty(qresindred) & ~isempty(qresind) & ~isempty(lim) & iscell(lim) & ~isempty(lim{1})
      lim = lim{1};
      qres = a.data(:,qresind)/lim;
      toadd = qres;
      mylbl = lbls{qresind};
      lip   = regexp(mylbl,'(');
      if isempty(lip); 
        mylbl(end+1) = ' ';
        lip = length(mylbl)+1; 
      end
      lbladd{end+1} = [mylbl(1:lip-1) 'Reduced' plevel ' ' mylbl(lip:end)];
    else
      qresind = [];  %IGNORE this q res (didn't add reduced for some reason)
    end
  end
  if isfield(modl.detail,'tsqlim')
    lim = modl.detail.tsqlim;
    if isstruct(lim) & isfield(lim,'lim95')
      lim = {lim.lim95(1)};
      plevel = ' (p=0.950)';
    end
    if isempty(t2indred) & ~isempty(t2ind) & ~isempty(lim) & iscell(lim) & ~isempty(lim{1})
      lim = lim{1};
      t2res = a.data(:,t2ind)/lim;
      toadd = [toadd t2res];
      mylbl = lbls{t2ind};
      lip   = regexp(mylbl,'(');
      if isempty(lip); 
        mylbl(end+1) = ' ';
        lip = length(mylbl)+1; 
      end
      lbladd{end+1} = [mylbl(1:lip-1) 'Reduced' plevel ' ' mylbl(lip:end)];
    else
      t2ind = [];  %IGNORE this t2 (didn't add reduced for some reason)
    end
  end
  if ~isempty(toadd)
    a = [a(:,1:insertpoint) toadd a(:,insertpoint+1:end)];
    for j=1:length(lbladd);
      a.label{2}{insertpoint+j} = lbladd{j};
    end
  end
  if strcmpi(options.reducedstats,'only') & (~isempty(qresind) | ~isempty(t2ind))
    %hard-delete the raw q residuals and T2 limits (if there)
    a = delsamps(a,[qresind t2ind],2,2);
  end
end

% Adopt image data if MIA toolbox is available.
if evriio('mia')
  if isempty(test)
    a = inheritimage(a,modl);
  else
    if options.sct
      a = inheritimage(a,{modl test});
    else
      a = inheritimage(a,test);
    end
  end
end

%add comment to history saying where this came from
if isempty(test)
  a.history = sprintf('Scores for model "%s"',uniquename(modl));
elseif ~options.sct
  a.history = sprintf('Scores for predictions "%s"',uniquename(test));
else
  a.history = sprintf('Scores for model "%s" and predictions "%s"',uniquename(modl),uniquename(test));
end

if (options.sct | isempty(test)) & isfield(modl.detail,'cvi') & ~isempty(modl.detail.cvi)
  %add cross-validation set information (if available)
  cvi = modl.detail.cvi;
  cvi(end+1:size(a,1)) = 0;  %add zeros for all other samples (test samples at end)
  lu = {-1 'Calibration'; -2 'Test'; 0 'Unused'};
  for j=unique(cvi(cvi>0))
    lu(end+1,1:2) = {j sprintf('Leave-Out Set %i',j)};
  end
  a = updateset(a,'class',1,cvi,'Cross-validation Sets',lu);
end

% If no outputs OR anything other than "none" or "auto", do plot
if (~strcmp(options.plots,'none') & nargout == 0) | ~any(strcmp(options.plots,{'none','auto'}));
  if isempty(options.figure);
    target = {'new'};
  else
    target = {'figure' options.figure};
  end
    %get appropriate limits value from model (if options includes confidence
  %limit setting)
  limitsvalue = 95;  %default limits value
  if isfieldcheck('modl.detail.options.confidencelimit',modl);
    limitsvalue = modl.detail.options.confidencelimit*100;
  end
  h = plotgui(a,target{:},'name','Scores','plotby',2,'validplotby',[2],'viewclasses',1,'conflimits',showlimits,'limitsvalue',limitsvalue,'viewlabels',0,'viewaxislines',[1 1 1]);
  
  obj = [];
 
  %add show cal with test checkbox
  if ~isempty(test);
    obj.(['sct' num2str(double(h))]) = ...
      {'style','checkbox','string','Show Cal Data with Test','value',options.sct,'userdata',h,...
      'tooltip','Show calibration data along with test data.',...
      'callback',['plotscores(get(gcbo,''userdata''),struct(''sct'',get(gcbo,''value'')))']};
  end
  
  %add error bars checkbox
  showerrorbars = getappdata(h,'showerrorbars');
  if isempty(showerrorbars); showerrorbars = options.showerrorbars; end
  obj.(['showerrorbars' num2str(double(h))]) = ...
    {'style','checkbox','string','Show Error Bars','value',showerrorbars,'userdata',h,...
    'tooltip','Show error bars when available.',...
    'updatecallback','set(h,''value'',min([1 getappdata(targfig,''showerrorbars'')]))',...
    'callback','setappdata(getappdata(gcbf,''target''),''showerrorbars'',get(gcbo,''value''));plotgui(''update'',''figure'',getappdata(gcbf,''target''))'};

  setappdata(h,'modl',modl);
  setappdata(h,'test',test);
  setappdata(h,'sct',options.sct);
  setappdata(h,'showerrorbars',showerrorbars);
  
  if showlimits
    pltcmd = ['plotscoreslimits(targfig,targfig)'];
  else
    pltcmd = [];
  end
  plotgui('update','figure',h,'plotcommand',pltcmd,'uicontrol',obj);
  drawnow
  clear a
end
