function varargout = manrotate(varargin)
%MANROTATE Graphical interface to manually rotate model loadings.
% Shows the score vs. score scatter plot and model loadings and allows a
% user to "rotate" the loadings. The loadings (shown as two colored lines
% in the score/score plot) can be dragged through different angles
% observing the resulting loading shape in the loadings plot (Loadings are
% always kept orthogonal.)
%
% This interface is useful to identify a loading "shapes" which point
% towards, and orthogonal to, a given sample cluster or direction. The
% rotated loading vectors can be saved to the workspace using the toolbar
% save button.
% 
% INPUT:
%   model = a PCA, PLS or similar model structure
% OPTIONAL INPUT:
%   lvs = a two-element vector specifying which LVs to plot and rotate
%
%I/O: manrotate(model,lvs)
%
%See also: PCA, PLS, VARIMAX

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin == 0; varargin{1} = 'io'; end
if nargin==1 && ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

if nargin>0 & ismodel(varargin{1});
  %create figure and prep for GUI
  if nargin>1;
    pc = varargin{2};
  else
    pc = [1 2];
  end
  if nargin>2;
    fig = varargin{3};
  else
    fig = figure('units','normalized','toolbar','none');
    pos = get(fig,'position');
    factor = .8;
    set(fig,'position',pos+[-pos(3)/(1+factor) 0 pos(3)*factor 0]);
  end
  setappdata(fig,'model',varargin{1});
  setappdata(fig,'pcs',pc);
  subplot(1,2,2);
  set(gca,'tag','loads');  %tag so plotgui won't plot on this axis
  subplot(1,2,1);
  axis equal
  scrs = plotscores(varargin{1});
  plotgui('update','figure',fig,scrs,'viewclasses',1,'axismenuvalues',{pc(1) pc(2) 0},...
    'axismenuenable',[0 0 0],...
    'validplotby',[2],...
    'showcontrols',0,...
    'plotcommand','manrotate(''prepplot'',targfig)');
  manrotate('setangle',fig,0);
  set(findobj(fig,'tag','PlotGUITargetMenu'),'visible','off')
  
  toolbar(fig,'',{
    'scores' 'savescores' 'manrotate(''savescores'',gcbf)' 'enable' 'Save rotated scores' 'off' 'push'
    'loads' 'saveloads' 'manrotate(''saveloadings'',gcbf)' 'enable' 'Save rotated loadings' 'off' 'push'
    });
  return
end

switch varargin{1}
    %----------------------------------------------------------
  case 'prepplot'
    %called each time the PLOTGUI figure is updated
    ax = axis;
    
    if ax(1)>=0;
      ax(1) = -ax(2);
      axis(ax);
    end
    if ax(3)>=0;
      ax(3) = -ax(4);
      axis(ax);
    end
    fig = varargin{2};    
    angle = 0;
    setappdata(fig,'currentangle',angle);
    x = [0 min(abs(ax))]';
    y = [0 0]';
    
    corder = get(gca,'colororder');
    hold on;
    hline(0,'k--');
    vline(0,'k--');
    h1 = plot(x,y,'b-','linewidth',4,'tag','factor1');
    set(h1,'color',corder(1,:));
    data = rotate([x y],pi/2);
    h2 = plot(data(:,1),data(:,2),'g-','linewidth',4,'tag','factor2');
    set(h2,'color',corder(2,:));
    hold off
    moveobj('angle',h1);
    setappdata(h1,'buttonmotionfcn','manrotate(''setangle'',gcbf,dataangle)');
    moveobj('link',h2,h1);
    
    manrotate('setangle',fig,angle)

    %----------------------------------------------------------
  case 'setangle'
    %sets the current angle and updates the loadings plot
    fig = varargin{2};
    angle = varargin{3};

    setappdata(fig,'currentangle',angle);
    pcs = getappdata(fig,'pcs');
    model = getappdata(fig,'model');    
    
    %adjust second PC vector to be 90 degrees from first
    h1 = findobj(gca,'tag','factor1');
    h2 = findobj(gca,'tag','factor2');
    xdata = get(h1,'xdata');
    ydata = get(h1,'ydata');
    rdata = rotate([xdata(:) ydata(:)],pi/2);
    set(h2,'xdata',rdata(:,1),'ydata',rdata(:,2));

    %do plot of rotated loadings
    axh = get(fig,'currentaxes');
    loadsaxh = findobj(fig,'tag','loads');
    set(fig,'currentaxes',loadsaxh);
    axisscale = model.detail.axisscale{2,1};
    if isempty(axisscale);
      axisscale = 1:model.datasource{1}.size(2);
    end
    rotloads = rotate(model.loads{2}(:,pcs),pi*2-angle);
    plot(axisscale(model.detail.includ{2}),rotloads)
    title(sprintf('New Loadings (Angle: %f)',angle/pi*180));
    set(gca,'tag','loads');

    setappdata(fig,'loadings',rotloads);  %save rotated loadings to figure appdata

    %make sure original axes have focus again
    set(fig,'currentaxes',axh);

    %----------------------------------------------------------
  case 'saveloadings'
    loadings = getappdata(varargin{2},'loadings');
    svdlgpls(loadings,'Save rotated loadings to...','loads');
   
    %----------------------------------------------------------
  case 'savescores'
    fig = varargin{2};
    angle = getappdata(fig,'currentangle');
    pcs   = getappdata(fig,'pcs');
    model = getappdata(fig,'model');    
    
    %calculate rotated scores
    scores = rotate(model.loads{1}(:,pcs),pi*2-angle);
    svdlgpls(scores,'Save rotated loadings to...','scores');

end

%-------------------------------------------------------
function data = rotate(data,angle)

if ~isempty(angle);
  T = [cos(angle) sin(angle);-sin(angle) cos(angle)];
  data = data*T;
end
