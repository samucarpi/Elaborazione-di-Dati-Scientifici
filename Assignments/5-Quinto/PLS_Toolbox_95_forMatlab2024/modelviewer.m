function varargout=modelviewer(model,X,number,mode);
%MODELVIEWER Visualization tool for multi-way models.
%  Modelviewer provides a graphical view of a model by enabling
%  overview of scores, loadings, residuals etc. in one overall
%  figure. Individual modes can be assessed by clicking plots
%  and enlarged figures created by right-clicking plots.
%  INPUTS:
%     model = PARAFAC, Tucker, or NPLS standard model structure, and
%        x  = X-block: predictor block (MUST be the data that was used for fitting the model).
%  OUTPUT:
%     model = standard model structure (See MODELSTRUCT).
%
%I/O: model = modelviewer(model,x);  %plots model
%
%See also: MODELSTRUCT, PARAFAC, PLOTGUI, PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Three modes:
% modelviewer('subplot',i,j)
% makes a default subplot in a 4x4 grid so that subsequent plotting will take place there

%I/O: info = mwaplotter(model,X,num);
%
%  num =
%   1 : Line plot loadings
%   2 : Bar plot residuals
%   3 : Influence plot
%   4 : Corcondia (only parafac)
%   5 : Scatter of all scores
%   6 : Histogram of residuals
%   7 : Normal probability plot
%   8 : Raw Residuals
%   9 : Plot of model/rawdata (assuming first mode samples)
%   10: Variance of each component
%   11: Tucker core list (only tucker)
%   12: T vs U plot (only NPLS)
%   13: Pred vs Meas plot (only NPLS)
%   14: PARAFAC2 loadings 
%   15: PARAFAC2 loadings scaled
%   16: Splithalf quality (PARAFAC)
%   17: PARAFAC2 model quality (only PARAFAC2)
%   18: PARAFAC2 residual plot (replacing 8). Good for TICs and similar

%rb, jun, 2002 addd a 'close all' because apparently there are some problems when several modelviewers are open.
%jms 5/04/04 -added test for data not present (don't do certain plots)
%rb, apr, 2005, added percentage variance in title of figure

if nargin == 0;
    model = 'io';
end
varargin{1}=model;
if ischar(varargin{1})
    if ~strcmp(varargin{1},'makesubplot')
        options = [];
        if nargout==0;
            clear varargout;
            evriio(mfilename,varargin{1},options);
        else;
            varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
    end
end


if nargin<2
    error('MODELVIEWER takes two inputs. Type HELP MODELVIEWER')
end

typename = {'Parameters';'Residuals';'Data';'Auxiliary'};

if ismodel(model) % Define which plots to show depending on model type
    switch lower(model.modeltype)
        case {'parafac' 'parafac_pred'}
            col4plots = 4;
            if isfieldcheck(model,'model.detail.validation.splithalf.quality')
              qu = model.detail.validation.splithalf.quality;
              col4plots = [4 16];
            else
              qu=[];
            end
            typedef = {[1 5 3 10];[2 7 18 8];[9];col4plots};
        case {'tucker' 'tucker_pred'}
            typedef = {[1 5 3];[2 6 7 8];[9];[11]};
        case 'tucker - rotated'
            typedef = {[1 5 3];[2 6 7 8];[9];[11]};
        case {'npls' 'npls_pred'}
            typedef = {[1 5 3 12];[2 6 7 8];[9];[13]};
        case {'parafac2' 'parafac2_pred'}
            %typedef = {[1 5 3];[2 6 7 18];[9];[14 15 4 17]};
            typedef = {[1 5 3 10];[2 7 18 8];[9];[14 15 4]};
        otherwise
            error([' Modelviewer does not currently support ',upper(model.modeltype)])
    end
    if ~isempty(strfind(lower(model.modeltype),'_pred'));
      model.modeltype = regexprep(model.modeltype,'_PRED','');
    end
    if isempty(X)
        for j=1:length(typedef);
            typedef{j} = setdiff(typedef{j},[6 7 8]);
        end
    end
end

if ~ismodel(model) % Then it's not for plotting, but for setting up the subplots
    
    % Make a subwindow in the figure
    i = X;
    try
    j=number;
    end
    drawnow;
    %Fix for when focus lost on figure, need to have actual handle to figure
    %since gcf may be wrong figure altogether.
    if nargin>3 & ishandle(mode)
      %This (mode=figurehandle) should always be the case since the only
      %call of this type is made below.
      myfig = mode;
    else
      %Try our best to get the correct figure.
      myfig = findobj(0,'Tag','ModelViewerFig');
      myfig = myfig(end);
    end
    
    h1 = axes('Parent',myfig, ...
        'CameraUpVector',[0 1 0], ...
        'Color',[1 1 1], ...
        'CreateFcn','', ...
        'Position',[0.1+.24*(j-1) 1-(.03+i*.24) 0.16 0.16], ...
        'Units','Normalized', ...
        'XColor',[0 0 0], ...
        'XTick',[0 0.5 1], ...
        'XTickLabelMode','manual', ...
        'XTickMode','manual', ...
        'YColor',[0 0 0], ...
        'YTick',[0 0.5 1], ...
        'YTickLabelMode','manual', ...
        'YTickMode','manual', ...
        'ZColor',[0 0 0]);
      
      if checkmlversion('>=','9.5')%2018b or newer
        h1.Toolbar.Visible = 'off';
      end
    
elseif nargin<3 % Do all plots
    %close all
    % Make overall window
    h0 = figure('PaperPosition',[18 180 576 432], ...
        'PaperUnits','points', ...
        'Units','Normalized', ...
        'Position',[.1 .1 .7 .7], ...
        'ResizeFcn',@resizeFigure, ...
        'Resize','on', ...
        'Tag','ModelViewerFig', ...
        'menubar','none',...
        'ToolBar','figure', ...
        'DefaultaxesCreateFcn','plotedit(gcbf,''promoteoverlay'')', ...
        'UserData',{model,X});
    % Use system color scheme for figure:
    
    
    % Make help utility
    h4 = uicontrol('Parent',h0, ...
        'Units','normalized', ...
        'callback',['evrimsgbox({''This plot provides an overview of your model'';'' '';'' - Press the title of each plot to see a description of the plot'';'' - Press the axes of the plot e.g. to change mode'';'' - Abbreviations: F - Factor, M - Mode, S - Sample (only non-excluded ones)'';'' - Press red text to change the sample or factor'';'' - Right-click to spawn figure''  },''replace'');'],...
        'Style','pushbutton', ...
        'Tag','StaticText1', ...
        'HandleVisibility','off', ...
        'HorizontalAlignment','center', ...
        'Position',[0 0 0.04 0.05], ...
        'FontSize',11, ...
        'ToolTipString',['Explanation on how this plot works'], ...
        'handlevisibility','on', ...
        'String','?', ...
        'FontWeight','Bold');
    
    name = model.datasource{1}.name;
    
    % Add percentage variance explained in title
    vars = [];
    if isstruct(model.detail.ssq)
        try % for pf, pf2,t3
            vars = num2str(round(1000*model.detail.ssq.perc)/1000);
            name = [name,' - ',vars,'% explained'];
        catch
            vars = [];
        end
    end
    if isempty(vars)
        try % for npls
            vars = num2str(round(1000*model.detail.ssq(end,end))/1000);
            name = [name,' - ',vars,'% explained in Y'];
        end
    end
    try
        modnm=[model.modeltype,'(',num2str(size(model.loads{2},2)),') of ',name];
    catch
        modnm=[model.modeltype,' of ',name];
    end
    set(gcf,'Name',modnm);
    
    for j=1:4
        if j<4
            txt = ['This column contain plots related to ',lower(typename{j}),'. Press the title of each plot to see description and press the lower left help button to learn about the interactivity of the plots'];
        else
            txt = ['This column contain plots related to ',lower(typename{j}),' aspects. Press the title of each plot to see description and press the lower left help button to learn about the interactivity of the plots'];
        end
        h4 = uicontrol('Parent',h0, ...
            'Units','normalized', ...
            'Style','text', ...
            'Tag','StaticText1', ...
            'HandleVisibility','off', ...
            'HorizontalAlignment','center', ...
            'Position',[0.08+.24*(j-1) .95 0.2 0.038], ...
            'FontSize',11, ...
            'foregroundcolor','blue', ...
            'handlevisibility','on', ...
            'ToolTipString','Right-click for info', ...
            'ButtonDownFcn',['evrimsgbox(''',txt,''',''replace'');'], ...
            'String',typename{j}, ...
            'fontname','verdana',...
            'FontWeight','Bold');
        
        set(h4,'BackgroundColor',get(0,'DefaultUicontrolBackgroundColor'));
    end
    set(h0,'Color',get(0,'DefaultUicontrolBackgroundColor'));
    
    
    count = 0;
    for j=1:4
        for i=1:length(typedef{j})
            count = count+1;
            modelviewer('makesubplot',i,j,h0)
            mwaplotter(model,X,typedef{j}(i),1);
        end
    end
    
else % Plot only one of the type of plots (and do it for all modes)
    figure
    mwaplotter(model,X,number);
end

if nargout >0;
    varargout = {gcf};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function mwaplotter(model,X,num,mode);

%MWAPLOT plots multiway models
%
%  Based on a model structure and the associated data, the
%  different standard plots can be made:
%

%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001


if nargin == 4
    dosmallplot=1;
else
    dosmallplot=0;
end

if num==1  %Loading plot
    
    for m = 1:length(model.loads)
        if ~dosmallplot|m==mode % If no number defined, then it's only mode that's to be shown
            if dosmallplot
                modelviewertool(1,m);
            end
        end
    end
    
elseif num==2 %  Bar plot residuals
    
    for m = 1:length(model.ssqresiduals)
        if ~dosmallplot|m==mode
            modelviewertool(2,m);
        end
    end
    
elseif num==3 %  3 : Influence plot
    
    for m = 1:length(model.ssqresiduals)
        if ~dosmallplot|m==mode
            modelviewertool(3,m);
        end
    end
    
elseif num==4 %  4 : Corcondia
    modelviewertool(4,1);
    
elseif num==5 %  5 : Scatter of all scores
    
    for m = 1:length(model.ssqresiduals)
        if ~dosmallplot|m==mode
            modelviewertool(5,m);
        end
    end
    
elseif num==6 % Histogram of residuals
    modelviewertool(6,1);
    
    
elseif num==7 %  7 : Normal probability plot
    modelviewertool(7,1);
    
elseif num==8 %  Sq. Residuals across all but two modes (ONLY FOR THREE-WAY)
    
    modelviewertool(8,mode);
    
elseif num==9 %  9 : Plot of model (assuming the mode model.options.samplemodex is sample-mode)
    
    modelviewertool(9,mode);
    
elseif num==10 %  10 : Plot of the variance and unique variance of each component
    
    modelviewertool(10,mode);
    
elseif num==11 % Tucker core list
    
    modelviewertool(11,mode);
    
elseif num==12 %  12 : T vs U plot (only NPLS)
    modelviewertool(12,mode);
    
elseif num==13 %  13 : Pred vs Meas plot (only NPLS)
    modelviewertool(13,mode);
    
elseif num==14 %  14 : PARAFAC2 loadings
    modelviewertool(14,mode);
    
elseif num==15 %  15 : PARAFAC2 loadings scaled by 'concentration'
    modelviewertool(15,mode);

elseif num==16 %  16 : splithalf
    modelviewertool(16,mode);

elseif num==17 %  16 : PARAFAC2 model quality
    modelviewertool(17,mode);

elseif num==18 %  16 : PARAFAC2 residuals summed across all middle modes
    modelviewertool(18,mode);

end

%---------------------------------
function resizeFigure(varargin)
%Need to reposition buttons.

fig = varargin{1};

myobjs = {'scatter' 'resdata' 'rawdata'};

for i = 1:3
  myax = findobj(fig,'tag',myobjs{i});
  if ~isempty(myax)
    set(myax,'units','pixels');
    mypos = get(myax,'position');
    set(myax,'units','normalized');
    
    h2 = findobj(gcf,'tag',[myobjs{i} '_button']);
    set(h2,'Position',[mypos(1)+mypos(3)+10 mypos(2)+mypos(4)+5 25 20])
  end
end

