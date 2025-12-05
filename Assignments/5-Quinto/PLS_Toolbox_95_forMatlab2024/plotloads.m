function a = plotloads(modl,options,classes)
%PLOTLOADS Extract and display loadings information from a model structure.
%  INPUT:
%    modl = a standard model structure. PLOTLOADS will extract the loads
%           (and other information) and labels for plotting.
%   loads = a NxK loadings matrix of class "double".
%
%  OPTIONAL INPUTS:
%    options = structure array with the following fields:
%      plots: [ 'none' | 'final' | {'auto'} ]   governs plotting behavior,
%             'auto' makes plots if no output is requested {default}, and
%     figure: []  governs where plots are made, when figure = [] plots are
%             made in a new figure window {default}, this can also be a valid
%             figure number (i.e. figure handle).
%       mode: [2] specifies which mode of loadings to plot. Default is 2
%             (columns of the original data). This only has
%             significance for multi-way data.
%      block: [1] specifies which block to plot loadings for. 1 = x-block,
%             2 = y-block. If specified block does not exist, an error will
%             be thrown.
%      title: [ {'off'} | 'on' ] governs inclusion of title on figures and
%             in output DataSet. When 'on' text description of content
%             (including source name) will be included on plots and in
%             .title{1} field of output.
%    undopre: [ {'no'} | 'yes' ] Undo preprocessing on loadings (to the
%             extent possible). Corrects loadings for scaling and some
%             other preprocessing effects. Note that this produces loadings
%             which are not the same as what the data will be projected
%             onto but unpreprocessed loadings may be more interpretable.
%
%     labels = a character or cell array with N rows containing sample labels, and
%    classes = a vector with N integer elements of class identifiers.
%
%  OUTPUT:
%     a = a dataset containing loadings and label information that can be
%         passed to PLOTGUI.
%         With no output specified PLOTLOADS will create a loads plot.
%
%I/O: a = plotloads(modl,options);          %plots loads for a model structures
%I/O: a = plotloads(loads,labels,classes);  %plots loads for loadings matrices
%I/O: plotloads demo
%
%See also: ANALYSIS, MCR, MODELSTRUCT, MODELVIEWER, MPCA, PCA, PCR, PLOTEIGEN, PLOTGUI, PLOTSCORES, PLS, SRATIO, VIP

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS initial coding from DECOMPOSE 6/3/02
%JMS revised input format 7/22/02
%nbg 8/02 changed help
%JMS 8/20/03 added support for external helper functions for other model types
%JMS 1/12/04 changed call for external helper functions to call plotloads_xxxx
%rsk 03/03/04 Add mcr and Q's to output.
%JMS 3/9/04 Add T^2 to output and fixed bug in test for empty Q
%JMS 3/12/04 Further identified T2 problem in PLS vs. PCA or PCR. Change to
%be made later.
%JMS 4/1/04 Expect model as appdata, not in handles structure
%jms 4/28/04 better handle missing T2/Q values
%jms 8/2/04 added drawnow in output to fix redraw problem in R14
%jms 12/22/04 fixed T^2 and Q %s
%BK 6/21/2016 - works with multi-way PLSDA

if nargin == 0; modl = 'io'; end
varargin{1} = modl;
if ischar(varargin{1})
  options = [];
  options.name   = 'options';
  options.plots  = 'auto';
  options.figure = [];
  options.mode   = 2;
  options.block  = 1;
  options.title  = 'off';
  options.undopre = 'off';
  if nargout==0; clear a; evriio(mfilename,varargin{1},options); else; a = evriio(mfilename,varargin{1},options); end
  return; 
end

if ~ismodel(modl) & prod(size(modl))>1    %array instead of a model or a handle?
  %array inputs are (loads,labels,classes) instead of (modl,options,classes)
  switch nargin
    case 1
      loads   = modl;
      labels  = [];
      classes = [];
    case 2
      loads   = modl;
      labels  = options;
      classes = [];
    case 3
      loads   = modl;
      labels  = options;
      %classes = classes;
  end
  
  [m,n] = size(loads);
  
  if ~isempty(labels) & ((~iscell(labels) & size(labels,1)~=m) | (iscell(labels) & length(labels)~=m))
    error('Labels do not match number of samples (rows) in input LOADS');
  end
  
  if ~isempty(classes) & (length(classes)~=m)
    error('Classes do not match number of samples (rows) in input LOADS');
  end
  
  modl                  = modelstruct('pca');
  modl.loads{2}         = loads;
  modl.detail.label{2}  = labels;
  modl.detail.class{2}  = classes;
  modl.detail.includ{2} = 1:m;
  modl.detail.includ{1} = 1:n;
  if ~isstruct(loads)
    modl.datasource{1}.size = size(loads);
  end
  options = [];
  
else
  
  switch nargin
    case 1
      % (modl)
      options = [];
    case 2
      % (modl,figure)  (handle,figure)
      % (modl,options)
      if ~isstruct(options)
        % (modl,figure)  (handle,figure)
        options.figure = options;
      else
        % (modl,options)
      end
  end
  
  if ~ismodel(modl)    %handle instead of model
    %Interpret inputs
    handle = modl;
    if ~ishandle(handle)
      error('MODL input must be a valid model structure or valid object handle');
    end
    
    %extract info from object
    modl = getmodel(handle);
%     modl = getappdata(handle,'modl');
%     if isempty(modl)
%       modl = getappdata(handle,'model');
%     end
    if isempty(modl)
      error('GUI object must have APPDATA of either "modl" or "model"');
    end  
  end
end

options = reconopts(options,plotloads('options'));

if ~ismodel(modl)
  error('Input MODL must be a standard model structure');
end

%make sure options.block isn't > # of blocks
if isfield(modl,'loads') & options.block>size(modl.loads,2)
  error('The model does not contain loadings for the specified block.');
end

plotby = 2;  %default plotby (if we even plot this)

type = lower(modl.modeltype);
type = regexprep(type,'_pred','');
switch type
  case {'pca','pls','pcr','plsda','mpca','cls','lwr','maf','mdf'} 
    %One of the "standard" model types listed above
    if (strcmp(type,'plsda') && length(modl.datasource{1,1}.size) > 2 )
      a = feval('plotloads_npls',modl,options); % Multi-way plsda model, uses npls
    else
      a = plotloads_builtin(modl,options);
    end
    
  case {'lreg' 'lregda'}
    a = getlreg(modl,type);
  case {'lda'}
    a = plotloads_lda(modl,options);
  case 'clsti'
    a = plotloads_clsti(modl,options);
    
  otherwise  %not one of the "standard" model types? %also 'mcr' and'als_sit'
    
    targetfn = ['plotloads_' type];     %see if there is a handler function
    if exist(targetfn)                  %found one, call it with appropriate inputs and outputs
      a = feval(targetfn,modl,options);
    else
      error(['Unable to plot loadings for model type ' modl.modeltype]);
    end
    
end

%remove title if not wanted
if ~strcmpi(options.title,'on')
  a.title{1} = '';
end

%add comment to history saying where this came from
a.history = sprintf('Mode %i Block %i Loadings for model "%s"',options.mode, options.block, uniquename(modl));

% If no outputs OR anything other than "none" or "auto", do plot
if (~strcmp(options.plots,'none') & nargout == 0) | ~any(strcmp(options.plots,{'none','auto'}))
  
  if isempty(options.figure)
    target = {'new'};
  else
    target = {'figure' options.figure};
  end
  h = plotgui(a,target{:},'name','Variables/Loadings','plotby',plotby,'validplotby',[2],'viewclasses',1,'plotcommand',['plotloadslimits(targfig);'],'conflimits',0,'viewlabels',0,'viewaxislines',[1 1 1]);
  drawnow
  setappdata(h,'modl',modl);
%   handles      = guidata(h);
%   handles.modl = modl;
%   guidata(h,handles);
  
  clear a
end

%----------------------------------
function [modl] = getmodel(handles)

modl = [];
if ~isempty(handles)
  if ishandle(handles)
    %Check for shared data.
    myid = searchshareddata(handles,'query','model',1);
    modl = getshareddata(myid);
    if isempty(modl)
      modl = getappdata(handles,'modl');
    end
    if isempty(modl)
      modl = getappdata(handles,'model');
    end
    if strcmpi(modl.modeltype,'clsti')
      %pass prediction object to plotloads_clsti function not model object
      guiObj = evrigui(handles);
      modl = guiObj.getPrediction;
    end
  elseif ismodel(handles)  %handles IS the model!
    modl = handles;
  end
end

%--------------------------------------------------------------------------
% Function to support LREGDA
function rpe = getlreg(modl,type)
theta = modl.detail.lreg.theta(1:end,:);   % include intercept
%     theta = modl.detail.lreg.theta(2:end,:);   % no intercept
a = dataset(theta);
inclvar = modl.detail.include{2,1};
if ~isempty(modl.detail.label{2,1})
  lab2 = modl.detail.label{2,1}(inclvar,:);
  lab21 = repmat('-', size(lab2(1,:))); % add intercept
  lab2 = [lab21(1,:);lab2];             % add intercept
  a.label{1,1} = lab2; %modl.detail.label{2,1};
else
  lab2 = repmat('var_', length(inclvar)+1, 1); % add intercept
  lab2 = [lab2 num2str([0 inclvar]')];         % add intercept
  a.label{1,1} = lab2;
end

% any excluded ...
cl = setdiff(unique(modl.detail.class{1,1,modl.options.classset}(modl.detail.include{1})),0);
cllookup = modl.detail.classlookup{1,1,modl.detail.options.classset};
cllbl = cllookup(findindx([cllookup{:,1}],cl),2);

zz = string(modl.classification.classids');
zz = strcat('theta ( ', zz, ' )');
a.label{2,1} = char(zz);

temp = modl.datasource{1}.name;
if isempty(temp)
  a.name               = 'LREGDA Model Parameters (theta)';
else
  a.name               = ['LREGDA Model Parameters for ',temp];
end

if ~isempty(modl.detail.axisscale{2,1})
  tmpas  = modl.detail.axisscale{2,1}(inclvar);
  tmpas0 = tmpas(1) - 1.e-6 * (tmpas(2)-tmpas(1));
  tmpas  = [tmpas0 tmpas];           % add entry for intercept
  a.axisscale{1,1} = tmpas; 
else
  %       a.axisscale{1,1} = modl.detail.includ{2,1};  % no entry for intercept
  a.axisscale{1,1} = [0 modl.detail.includ{2,1}];  % variavles; add entry for intercept
end
if ~isempty(modl.detail.axisscalename{2,1})
  a.axisscalename{1,1}   = modl.detail.axisscalename{2,1}; %
else
  a.axisscalename{1,1}   = 'Variable';
end

% Don't show the bias terms (though they are in the plot dataset)
a.include{1}(1) = [];

a.title{1,1}           = 'LREGDA Model Parameters'; %a.name;
rpe = a;

