function items = modelstatssummary(model,test,yindx,options)
%MODELSTATSSUMMARY Generate a succinct list of descriptive model statistics.
% Generally used for regression and classification models, this function
% generates a cell array of statistics and general results in a short
% format that can be superimposed on a figure.
% Results can either be returned as a cell array of strings or, using the
% options described below, plotted directly onto a figure.
%
% INPUTS:
%   model = Standard regression or classification model object
% OPTIONAL INPUTS:
%  Any of these inputs can be included or excluded, but they must be in
%  this order, if included.
%   test  = Standard prediction structure from applying the corresponding
%           model to new data. Output will include prediction statistics.
%   yindx = Index of which column of a multi-column y-block you wish 
%           statistics for. If omitted and more than one y-block column is
%           included in the model, an error will be thrown.
% options = A standard options structure with one or more of the
%           following fields:
%        hidden : [ {} ] Cell array of strings indicating which statistics
%                 should be hidden from the output. See 'list' option
%                 below.
%     showonfig : [ 'on' | 'off' | {'auto'}] Governs display of statistics
%                 directly on a figure in a mouse-movable axes. If 'auto',
%                 the figure display will be done only if no outputs were
%                 requested from the function call. If 'on', figure display
%                 will always be done. If 'off' no figure display will
%                 ever be done.
%           fig : [ ] Optional target figure to which the showonfig option
%                 should address the display. If empty, the current figure
%                 will be used. This option is only used if showonfig is
%                 not 'off'.
%      position : [ .5 .5 ] Relative position for text if shown on figure.
%                 Units are relative to the axes where [0,0] is the bottom
%                 left corner and [1,1] is the top right corner. Note that
%                 text is left and middle (top to bottom) justified so the
%                 position is actually the center left point for the text
%                 box.
% OUTPUTS:
%    items = Cell array of strings containing the model summary
%         information. Note that if not requested, the default options (see
%         above) will usually display the statistics directly on the
%         current figure.
%
% Other special calls:
%  The following strings can be used in place of "model" for additional
%  behaviors:
%  'list'  = returns a two-column list of strings where rows represent
%            statistics available for display. The first column contains a
%            keyword appropriate for inclusion in the "hidden" option (see
%            above). The second column contains a human-readable
%            description of the statistic. 
%    Example: list = modelstatssummary('list')
%
%  'showonfig' = displays the second input (a cell array of strings) on the
%                current figure. This can be used to display any
%                information on a figure with the same mouse-moveable
%                behavior as the standard statistics display.
%                Optional inputs include the figure handle (fig) and the
%                position for the text (position). See options above for
%                details on fig and position options.
%    Example: modelstatssummary('showonfig',mytext,fig,position)
%
%I/O: items = modelstatssummary(model)
%I/O: items = modelstatssummary(model,test,yindx,options)
%I/O: modelstatssummary(model,test,yindx,options)
%I/O: list = modelstatssummary('list')
%I/O: modelstatssummary('showonfig',mytext,fig,position)
%
%See also: COMPAREMODELS, MODELOPTIMIZER, MODLRDER, MODELSTRUCT, REPORTWRITER 

%Copyright Eigenvector Research, Inc. 2015
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0
  model = 'io';
end
if ischar(model) & ~isempty(model)
  switch model
    case 'list'
      %return a list of all items (and their descriptions) that this
      %function will generate. The first column is the keyword to include
      %in the "hidden" option (cell array of strings) to squlch the given
      %item
      items = {
        'lvs'     'Number of Components'
        'nodes'   'Number of Nodes'
        'rmsec'   'RMSEC'
        'rmsecv'  'RMSECV'
        'rmsep'   'RMSEP'
        'bias'    'Calibration Bias'
        'cvbias'  'CV Bias'
        'predbias' 'Prediction Bias'
        'r2c'      'R^2 (Cal)'
        'r2cv'     'R^2 (CV)'
        'r2p'      'R^2 (Pred)'
        'q2y'      'Q2Y'
        'r2y'      'R2Y'
        'ssc'      'Sensitivity/Specificity (Cal)'
        'sscv'     'Sensitivity/Specificity (CV)'
        'ssp'      'Sensitivity/Specificity (Pred)'
        };
      return
      
    case 'showonfig'
      if nargin<3
        yindx = gcf;
      end
      if nargin<4
        opts = reconopts([],mfilename);
        options = opts.position;
      end
      showonfig(test,yindx,options);
      return
      
    otherwise
      options = [];
      options.hidden = {'r2y' 'q2y'};
      options.showonfig = 'auto';
      options.fig = [];
      options.position = [.5 .5];
      if nargout==0; evriio(mfilename,model,options); else items = evriio(mfilename,model,options); end
      return
      
  end
end

%normal call, parse out inputs
switch nargin
  case 1
    % (modl)
    yindx   = [];
    test    = [];
    options = [];
  case 2
    % (modl,yindx)
    % (modl,test)
    % (modl,options)
    if isnumeric(test)
      % (modl,yindx)
      yindx   = test;
      test    = [];
      options = [];
    elseif ismodel(test)
      % (modl,test)
      yindx   = [];
      options = [];
    elseif isstruct(test)
      % (modl,options)
      options = test;
      test    = [];
      yindx   = [];
    else
      error('Inputs not recognized')
    end    
  case 3
    % (modl,yindx,options)
    % (modl,test,options)
    % (modl,test,yindx)
    if isnumeric(test) & ~isempty(test) & (isstruct(yindx) | isempty(yindx))
      % (modl,yindx,options)
      options = yindx;
      yindx = test;
      test = [];
    elseif ismodel(test)
      if isstruct(yindx) | isempty(yindx)
        % (modl,test,options)
        options = yindx;
        yindx = [];
      else
        % (modl,test,yindx)
        options = [];
      end
    else
      error('Inputs not recognized');
    end    
  case 4
    % (modl,test,yindx,options)
    % nothing need be done
end

%manage options
options = reconopts(options,mfilename);
hidden = options.hidden;

items = {};

if ~isempty(model) & model.isyused
  %check for batchmaturity
  if strcmpi(model.modeltype,'batchmaturity')
    model = model.submodelreg;
  end
  
  if isempty(yindx)
    %if user didn't specify yindx, see if we can infer it from the model
    if model.datasource{2}.include_size(2)>1
      error('Model built on more than one y-block column, y index must be supplied')
    end
    yindx = model.detail.include{2,2};  %use y-include as yindx
  end
  
  %got a model, do a lookup from y-column to actual included columns
  incllu(model.detail.includ{2,2}) = 1:length(model.detail.includ{2,2});
  yindx(yindx>0) = incllu(yindx(yindx>0));  %for non-zero items, locate ACTUAL y-column
  if (length(yindx)==1 & yindx~=0) | any(yindx==0) | yindx(1)==yindx(2)
    %if the same y-column is on both X and Y axes (or either is an index)
    yindx(yindx==0) = [];  %drop zero indexes (so we're left only with the one real value
    yindx = yindx(1);
    if ~ismember(model.modeltype,{'MLR' 'CLS' 'SVM' 'SVMDA' 'ANN' 'ANNDA' 'ANNDL' 'ANNDLDA' 'LWR' 'XGB' 'XGBDA' 'LREGDA' 'ENSEMBLE'});
      switch lower(model.modeltype)
        case 'pcr'
          lvname = 'Principal Component';
        otherwise
          lvname = 'Latent Variable';
      end
      nlvs = size(model.loads{2,1},2);
      if ~ismember('lvs',hidden)
        if nlvs ~= 1;
          items{end+1} = [num2str(nlvs) ' ' lvname 's'];
        else
          items{end+1} = [num2str(nlvs) ' ' lvname];
        end
      end
    % LWR
    elseif strcmpi(model.modeltype,'LWR')
      nlvs = size(model.loads{2,1},2);
      if ~ismember('lvs',hidden)
        lvname = 'Principal Component';
        lvs = model.detail.lvs;
        if lvs ~= 1;
          items{end+1} = [num2str(lvs) ' ' lvname 's'];
        else
          items{end+1} = [num2str(lvs) ' ' lvname];
        end
        
        items{end+1} = [ num2str(model.detail.npts) ' Local Points'];
        
        opts = model.detail.options;
        if strcmpi(opts.algorithm, 'pcr') | strcmpi(opts.algorithm, 'pls')
          items{end+1} = [upper(opts.algorithm) ' Local Model'];
          
          if strcmpi(opts.algorithm, 'pls')
            lvname = 'Local Latent Variable';
          else
            lvname = 'Local Principal Component';
          end
          reglvs = opts.reglvs;
          if isempty(reglvs)
            reglvs = lvs;
          end
          % local lvs
          if reglvs ~= 1;
            items{end+1} = [num2str(reglvs) ' ' lvname 's'];
          else
            items{end+1} = [num2str(reglvs) ' ' lvname];
          end
        end
      end
      
    elseif ismember(model.modeltype,{'ANN' 'ANNDA'})
      nlvs = model.detail.options.nhid1;
      if ~ismember('nodes',hidden)
        if model.detail.options.nhid2>0
          items{end+1} = [num2str(nlvs) ' Nodes (Layer 1)'];
          items{end+1} = [num2str(model.detail.options.nhid2) ' Nodes (Layer 2)'];
        else
          items{end+1} = [num2str(nlvs) ' Nodes'];
        end
      end
    elseif ismember (model.modeltype,{'ANNDL','ANNDLDA'})
      nlvs = getanndlnhidone(model);
    else
      nlvs = 1;  %MLR and CLS info is always in first column
    end
    
    if ~model.isclassification
      %regression models
      if ~isempty(model.detail.rmsec) & ~ismember('rmsec',hidden)
        items{end+1} = ['RMSEC = ' num2str(model.detail.rmsec(yindx,min(end,nlvs))')];
      end
      if ~isempty(model.detail.rmsecv) & ~ismember('rmsecv',hidden)
        items{end+1} = ['RMSECV = ' num2str(model.detail.rmsecv(yindx,min(end,nlvs))')];
      end
      if ~isempty(test) & isfield(test.detail,'rmsep') & ~isempty(test.detail.rmsep)  & ~ismember('rmsep',hidden)
        items{end+1} = ['RMSEP = ' num2str(test.detail.rmsep(yindx,min(end,nlvs))')];
      elseif isfield(model.detail,'rmsep') & ~isempty(model.detail.rmsep)  & ~ismember('rmsep',hidden)
        items{end+1} = ['RMSEP = ' num2str(model.detail.rmsep(yindx,min(end,nlvs))')];
      end
      if isfieldcheck(model,'model.detail.bias') & ~isempty(model.detail.bias) & ~ismember('bias',hidden)
        items{end+1} = ['Calibration Bias = ' num2str(model.detail.bias(yindx,min(end,nlvs))')];
      end
      if isfieldcheck(model,'model.detail.cvbias') & ~isempty(model.detail.cvbias) & ~ismember('cvbias',hidden)
        items{end+1} = ['CV Bias = ' num2str(model.detail.cvbias(yindx,min(end,nlvs))')];
      end
      if ~isempty(test) & isfield(test.detail,'predbias') & ~isempty(test.detail.predbias) & ~ismember('predbias',hidden)
        items{end+1} = ['Prediction Bias = ' num2str(test.detail.predbias(yindx,min(end,nlvs))')];
      end

      showr2c = false;
      showr2cv = false;
      if isfieldcheck(model,'model.detail.r2c') & ~isempty(model.detail.r2c) & ~ismember('r2c',hidden)
        showr2c = true;
      end
      if isfieldcheck(model,'model.detail.r2cv') & ~isempty(model.detail.r2cv) & ~ismember('r2cv',hidden)
        showr2cv = true;
      end
      if showr2c
        if showr2cv
          items{end+1} = sprintf('R^2 (Cal,CV) = %0.3f, %0.3f',model.detail.r2c(yindx,min(end,nlvs)),model.detail.r2cv(yindx,min(end,nlvs)));
        else
          items{end+1} = sprintf('R^2 (Cal) = %0.3f',model.detail.r2c(yindx,min(end,nlvs)));
        end
      elseif showr2cv
        items{end+1} = sprintf('R^2 (CV) = %0.3f',model.detail.r2cv(yindx,min(end,nlvs)));
      end
      
      showr2y = false;
      showq2y = false;
      if isfieldcheck(model,'model.detail.r2y') & ~isempty(model.detail.r2y) & ~ismember('r2y',hidden)
        showr2y = true;
      end
      if isfieldcheck(model,'model.detail.q2y') & ~isempty(model.detail.q2y) & ~ismember('q2y',hidden)
        showq2y = true;
      end
      if showr2y
        if showq2y
          items{end+1} = sprintf('R2Y,Q2Y = %0.3f, %0.3f',model.detail.r2y(yindx,min(end,nlvs)),model.detail.q2y(yindx,min(end,nlvs)));
        else
          items{end+1} = sprintf('R2Y = %0.3f',model.detail.r2y(yindx,min(end,nlvs)));
        end
      elseif showq2y
        items{end+1} = sprintf('Q2Y = %0.3f',model.detail.q2y(yindx,min(end,nlvs)));
      end
      
      if ~isempty(test) & isfield(test.detail,'r2p') & ~isempty(test.detail.r2p) & ~ismember('r2p',hidden)
        items{end+1} = sprintf('R^2 (Pred) = %0.3f',test.detail.r2p(yindx,min(end,nlvs)));
      end
      
    else  %classification models
      if ~isempty(model.detail.misclassedc) & ~ismember('ssc',hidden)
        items{end+1} = sprintf('Sensitivity (Cal) = %01.3f',(1 - model.detail.misclassedc{yindx}(2,min(end,nlvs))));
        items{end+1} = sprintf('Specificity (Cal) = %01.3f',(1 - model.detail.misclassedc{yindx}(1,min(end,nlvs))));
      end
      if ~isempty(model.detail.misclassedcv) & ~ismember('sscv',hidden)
        items{end+1} = sprintf('Sensitivity (CV) = %01.3f',(1 - model.detail.misclassedcv{yindx}(2,min(end,nlvs))));
        items{end+1} = sprintf('Specificity (CV) = %01.3f',(1 - model.detail.misclassedcv{yindx}(1,min(end,nlvs))));
      end
      if ~ismember('ssp',hidden)
        if ~isempty(test) & isfield(test.detail,'misclassedp') & ~isempty(test.detail.misclassedp)
          items{end+1} = sprintf('Sensitivity (Pred) = %01.3f',(1 - test.detail.misclassedp{yindx}(2,min(end,nlvs))));
          items{end+1} = sprintf('Specificity (Pred) = %01.3f',(1 - test.detail.misclassedp{yindx}(1,min(end,nlvs))));
        elseif ~isempty(model.detail.misclassedp)
          items{end+1} = sprintf('Sensitivity (Pred) = %01.3f',(1 - model.detail.misclassedp{yindx}(2,min(end,nlvs))));
          items{end+1} = sprintf('Specificity (Pred) = %01.3f',(1 - model.detail.misclassedp{yindx}(1,min(end,nlvs))));
        end
      end
    end
    
  end
  
  %see if we need to show this on the figure
  if strcmpi(options.showonfig,'on') | (strcmpi(options.showonfig,'auto') & nargout==0)
    if isempty(options.fig)
      options.fig = gcf;
    end
    if isempty(options.position)
      options.position = [.5 .5];
    end
    showonfig(items,options.fig,options.position)
    if nargout==0
      clear items
    end
  end
  
end

%--------------------------------------------------------------
function showonfig(labels,fig,position)
%take a cell array of labels and display them in a (movable) axes on a figure

if length(position)==1
  position(2) = position(1);
end
if length(position)>2
  error('position for text is not valid')
end
if ~ishandle(fig)
  error('figure handle is not valid')
end

axes('visible','off','tag','fitinfoaxes','XLimMode','manual','YLimMode','manual','ZLimMode','manual');
texth = text(position(1),position(2),labels);
set(texth,'horizontalalign','left','backgroundColor',[1 1 1],'EdgeColor',[0 0 0],'tag','fitinfo');
moveobj('on',texth);
moveobj('noresize',texth);

%find existing FitInfoMenu or create a new one if it doesn't exist
mycontext = findobj(fig,'tag','fitinfomenu');
if isempty(mycontext);
  mycontext = uicontextmenu('tag','fitinfomenu');
end
mycontext = mycontext(1);
set(texth,'uicontextmenu',mycontext);
delete(allchild(mycontext));  %remove previous menu entries
uimenu(mycontext,'tag','clearlimits','label','Remove','callback','plotscoreslimits(''hideonfig'',get(gcbo,''parent''));');

