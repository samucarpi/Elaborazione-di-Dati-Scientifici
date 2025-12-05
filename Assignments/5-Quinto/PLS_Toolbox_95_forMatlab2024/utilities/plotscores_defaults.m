function [toplot,subplots,plottypes] = plotscores_defaults(modeltype,scores,options)
%PLOTSCORES_DEFAULTS Manage default scores plot settings.
% Manages default plots for scores plots based on model type and scores
% content. Inputs include (modeltype) the name of a valid model type (see
% the modeltype field of a standard model structure), and an optional
% scores DataSet object.
%
% Outputs are (toplot) a cell of cells where each sub-cell is a set of
% plotgui commands which will make the plot of choice. Note that if a cell
% is empty, the default plotgui plot will be created (first column vs.
% index).
% Second output (subplots) indicates if axes should be on the same figure
% in sub-plots (1) or on separate figures (0).
%
% Additional commands:
%  * With a string input 'settings' as modeltype, a GUI is presented allowing
%  the user to override the default plot choices.
%  * Options (set via setplspref) include:
%       subplots: [ 'off' |{'on'}] Controls subplots output flag. 'on'
%                  returns 1 for subplots output.
%       maxplots: [ 9 ] Limits maximum number of items in the toplot
%                  output. If the given model would return more than this
%                  number of items, the list is truncated to this length.
%           maxy: [ 10 ] Limits the maximum number of y-variables which will
%                  allow default plots of y vs. y on regression methods. If
%                  more than this number of y variables are present, none
%                  of the predicted vs. measured or residuals vs measured y
%                  values will be shown (even if they are included in the
%                  defaults).
%
%I/O: [toplot,subplots] = plotscores_defaults(modeltype,scores)
%I/O: [plottypes,subplots] = plotscores_defaults(modeltype)
%I/O: plotscores_defaults('settings')
%
%See also: ANALYSIS, PLOTSCORES 

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0;
  modeltype = 'io';
end
switch lower(modeltype)
  case evriio([],'validtopics')
    options = [];
    options.subplots = 'on';
    options.maxplots = 9;
    options.maxy     = 10;
    
    options.pca   = {'Q vs T2','PC1 vs PC2','PC1 vs Sample','sammon projection'};
    options.mcr   = {'All Scores','Q vs Sample'};
    options.pls   = {'Q vs T2','residuals vs leverage','cv predicted vs measured','PC1 vs PC2'};
    options.plsda = {'Q vs T2','cv predicted'};
    options.npls  = options.pls;
    options.pcr   = options.pls;
    options.mlr   = options.pls;
    options.cls   = options.pls;
    options.simca = {'Q vs T2','PC1 vs Sample'};
    options.lwr   = {'Q vs T2','residuals vs leverage','cv predicted vs measured'};
    options.svm   = {'cv predicted vs measured'};
    options.svmda = {'predicted'};
    options.batchmaturity   = {'T2 vs predicted','Q vs predicted','PC1 vs predicted'};
    options.ann   = {'CV Predicted vs Measured'};
    options.anndl = {'CV Predicted vs Measured'};
    options.tsne  = {'Embeddings for Component 1 vs Embeddings for Component 2', 'Embeddings for Component 1 vs Sample'};
    options.umap  = {'Embeddings for Component 1 vs Embeddings for Component 2', 'Embeddings for Component 1 vs Sample'};
    options.lda   = {'PC1 vs PC2', 'cv predicted vs measured'};
    
    if nargout==0; evriio(mfilename,modeltype,options); else; toplot = evriio(mfilename,modeltype,options); end
    return;
    
  case 'plottypes'
    toplot = {...
      'Q vs T2' ...
      'Q vs Sample' ...
      'PC1 vs PC2' 'PC1 vs PC3' 'PC1 vs PC4' 'PC2 vs PC3' 'PC2 vs PC4' 'PC3 vs PC4' ...
      'PC1 vs Sample' ...
      'All Scores' ...
      'CV Predicted vs Measured' ...
      'Predicted vs Measured' ...
      'Measured vs Predicted' ...
      'Measured vs CV Predicted' ...
      'Residuals vs Measured' ...
      'Residuals vs Leverage' ...
      'Predicted' ...
      'CV Predicted' ...
      'T2 vs Predicted' ...
      'Q vs Predicted' ...
      'PC1 vs Predicted' ...
      'Sammon Projection' ...
      'Embeddings for Component 1 vs Embeddings for Component 2' ...
      };
    return
    
  case 'settings'

    plotscores_defaults_gui;
    return
    
end

%reconcile options
if nargin<3; options = []; end
options = reconopts(options,mfilename);

%initialize settings
subplots = strcmp(options.subplots,'on');  
toplot = {};
plottypes = {};
modeltype = lower(modeltype);

%determine what to show
if isfield(options,modeltype);
  %given modeltype settings defined in options? use those, otherwise use
  %empty set above
  plottypes = options.(modeltype);
end

if nargin<2;
  %handles I/O: ('pca')  with no actual scores. Just returns list of plottypes
  toplot = plottypes;
  return
end

%convert from plot type to information on how to create that plot
for j=1:length(plottypes)
  switch lower(plottypes{j})

    case 'q vs t2'
      x = max(strmatch('Hotelling',scores.label{2}));
      y = max(strmatch('Q Residuals',scores.label{2}));
      if isempty(x) | isempty(y); continue; end
      toplot = [toplot;{{'axismenuvalues',{x,y,0},'showlimits',1}}];

    case 'q vs sample'
      x = 0;
      y = max(strmatch('Q Residuals',scores.label{2}));
      if isempty(x) | isempty(y); continue; end
      toplot = [toplot;{{'axismenuvalues',{x,y,0},'showlimits',1}}];

    case {'pc1 vs pc2' 'pc1 vs pc3' 'pc1 vs pc4' 'pc2 vs pc3' 'pc2 vs pc4' 'pc3 vs pc4'}
      targets = [str2num(plottypes{j}(3)) str2num(plottypes{j}(end))];
      x = strmatch('Scores on',scores.label{2});
      if length(x)<max(targets); continue; end  %1 PC or not found, skip
      toplot = [toplot;{{'axismenuvalues',{x(targets(1)) x(targets(2)) 0}}}];

    case 'sammon projection'
      x = strmatch('Sammon Proj',scores.label{2});
      if isempty(x); continue; end  %1 PC or not found, skip
      x = mat2cell(x,ones(1,length(x)),1)';
      if length(x)==1
        %only one sammon projection axis? show vs. index
        x = {0 x{1}};
      end
      toplot = [toplot;{{'axismenuvalues',x}}];
      
    case 'pc1 vs sample'
      toplot = [toplot;{{'axismenuvalues',{0 1 0}}}];

    case 'pc1 vs predicted'
      x = strmatch('Y Predicted',scores.label{2});
      y = 1;
      if any(any(isnan(scores.data(scores.include{1},x))))
        %no measured values for some included samples? (i.e. test samples!)
        x = [];  %revert to vs. index
      end
      if isempty(x);
        x = 0;
      end
      x = x(1);
      toplot = [toplot;{{'axismenuvalues',{x y 0}}}];

    case 't2 vs predicted'
      x = strmatch('Y Predicted',scores.label{2});
      y = max(strmatch('Hotelling',scores.label{2}));
      if isempty(x) | isempty(y); continue; end
      if any(any(isnan(scores.data(scores.include{1},x))))
        %no measured values for some included samples? (i.e. test samples!)
        x = [];  %revert to vs. index
      end
      if isempty(x);
        x = 0;
      end
      x = x(1);
      toplot = [toplot;{{'axismenuvalues',{x y 0}}}];

    case 'q vs predicted'
      x = strmatch('Y Predicted',scores.label{2});
      y = max(strmatch('Q Residuals',scores.label{2}));
      if isempty(x) | isempty(y); continue; end
      if any(any(isnan(scores.data(scores.include{1},x))))
        %no measured values for some included samples? (i.e. test samples!)
        x = [];  %revert to vs. index
      end
      if isempty(x);
        x = 0;
      end
      x = x(1);
      toplot = [toplot;{{'axismenuvalues',{x y 0}}}];

    case 'all scores'
      x = strmatch('Scores on',scores.label{2});
      if isempty(x); continue; end  %none found, skip
      toplot = [toplot;{{'axismenuvalues',{0 x 0}}}];

    case {'cv predicted vs measured' 'measured vs cv predicted'}
      x = strmatch('Y Measured',scores.label{2});
      y = strmatch('Y CV Predicted',scores.label{2});
      if isempty(y) | any(any(isnan(scores.data(scores.include{1},y))));
        y = strmatch('Y Predicted',scores.label{2});
      end
      if any(any(isnan(scores.data(scores.include{1},x))))
        %no measured values for some included samples? (i.e. test samples!)
        x = [];  %revert to vs. index
      end
      if isempty(x);
        x = zeros(1,length(y));
      end
      if isempty(x) | isempty(y); continue; end
      if length(y)>options.maxy; continue; end
      if strcmpi(plottypes{j}(1),'m')
        %measured vs. ____ : swap x and y
        temp = y;
        y = x;
        x = temp;
      end
      if strcmpi(modeltype,'plsda') & length(y)==2
        y = y(1);  %if 2-class PLSDA, ONLY show ONE prediction plot since they are mirrored
      end
      for k=1:length(y);
        toplot = [toplot;{{'axismenuvalues',{x(k) y(k) 0}}}];
      end

    case {'predicted vs measured' 'measured vs predicted'}
      x = strmatch('Y Measured',scores.label{2});
      y = strmatch('Y Predicted',scores.label{2});
      if isempty(y); continue; end
      if length(y)>options.maxy; continue; end
      if any(any(isnan(scores.data(scores.include{1},x))))
        %no measured values for some included samples? (i.e. test samples!)
        x = [];  %revert to vs. index
      end
      if isempty(x);
        x = zeros(1,length(y));
      end
      if strcmpi(plottypes{j}(1),'m')
        %measured vs. ____ : swap x and y
        temp = y;
        y = x;
        x = temp;
      end
      if strcmpi(modeltype,'plsda') & length(y)==2
        y = y(1);  %if 2-class PLSDA, ONLY show ONE prediction plot since they are mirrored
      end
      for k=1:length(y);
        toplot = [toplot;{{'axismenuvalues',{x(k) y(k) 0}}}];
      end

    case 'cv predicted'
      y = strmatch('Y CV Predicted',scores.label{2});
      if isempty(y) | any(any(isnan(scores.data(scores.include{1},y))));
        y = strmatch('Y Predicted',scores.label{2});
      end
      x = zeros(1,length(y));
      if isempty(x) | isempty(y); continue; end
      if length(y)>options.maxy; continue; end
      if strcmpi(modeltype,'plsda') & length(y)==2
        y = y(1);  %if 2-class PLSDA, ONLY show ONE prediction plot since they are mirrored
      end
      for k=1:length(y);
        toplot = [toplot;{{'axismenuvalues',{x(k) y(k) 0}}}];
      end

    case 'predicted'
      y = strmatch('Y Predicted',scores.label{2});
      x = zeros(1,length(y));
      if isempty(x) | isempty(y); continue; end
      if length(y)>options.maxy; continue; end
      if strcmpi(modeltype,'plsda') & length(y)==2
        y = y(1);  %if 2-class PLSDA, ONLY show ONE prediction plot since they are mirrored
      end
      for k=1:length(y);
        toplot = [toplot;{{'axismenuvalues',{x(k) y(k) 0}}}];
      end

    case 'residuals vs measured'
      x = strmatch('Y Measured',scores.label{2});
      y = strmatch('Y Residual',scores.label{2});
      if isempty(x) | isempty(y); continue; end
      if length(y)>options.maxy; continue; end
      if strcmpi(modeltype,'plsda') & length(y)==2
        y = y(1);  %if 2-class PLSDA, ONLY show ONE prediction plot since they are mirrored
      end
      for k=1:length(y);
        toplot = [toplot;{{'axismenuvalues',{x(k) y(k) 0}}}];
      end

    case 'residuals vs leverage'
      x = strmatch('Leverage',scores.label{2});
      y = strmatch('Y Stdnt Residual',scores.label{2});
      if isempty(x) | isempty(y); continue; end
      if length(y)>options.maxy; continue; end
      toplot = [toplot;{{'axismenuvalues',{x y 0}}}];
      
    case 'embeddings for component 1 vs embeddings for component 2'
      targets = [str2num(plottypes{j}(26)) str2num(plottypes{j}(end))];
      x = strmatch('Embeddings',scores.label{2});
      if length(x)<max(targets); continue; end  %1 component or not found, skip
      toplot = [toplot;{{'axismenuvalues',{x(targets(1)) x(targets(2)) 0}}}];
      
  end
end

if isempty(toplot)
  toplot = {{}};  %default is "as-is" plot of everything
end

toplot = toplot(1:min(end,options.maxplots));
