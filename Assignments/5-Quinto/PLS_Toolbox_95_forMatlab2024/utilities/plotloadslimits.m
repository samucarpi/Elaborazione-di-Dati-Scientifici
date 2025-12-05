function plotloadslimits(fig)
%PLOTLOADSLIMITS Adjust loadings plots for special settings
% Used by plotloads to handle special axis cases
%
%I/O: plotloadslimits(fig)

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS

if nargin<1;
  fig = gcf;
end

isplotgui   = strcmp(getappdata(fig,'figuretype'),'PlotGUI');
if isplotgui
  %call from plotgui figure
  ind         = getappdata(fig,'axismenuindex');
  lbls        = getappdata(fig,'axismenuvalues');

  for m = [2 1];
    switch m
      case 2
        linecmd = @hline;
      case 1
        linecmd = @vline;
    end
    lbl = lbls{m};
    
    %check if we've got specific selections
    if ~isa(lbl,'cell')
      lbl = {lbl};
    end
    if length(strmatch('VIP Scores',lbl))==length(lbl);
      h = linecmd(1,'r--');
      legendname(h,'Significance Threshold')
    elseif ~isempty(strmatch('Selectivity Ratio',lbl))
      [lim,cl] = getsellimit(fig);
      h = linecmd(lim,'r--');
      legendname(h,sprintf('%i%% Conf. Limit',cl*100))
    end
  end
  
else
  ind = {[] [] []};  %unkonwn selection (not a PlotGUI figure)
end

if isempty(ind{1}) | ind{1}>0;
  ax   = axis;
  rat  = (ax(2)-ax(1))/(ax(4)-ax(3));
  lvsl = (rat<5 & rat>0.2); %ratio of X to Y axes > 10% Don't use equal axes
else
  lvsl = 0;
end

% end

if lvsl
  axis equal
end

%---------------------------------------------
function [fstat,p] = getsellimit(fig)
fstat = nan;
p     = getappdata(fig,'limitsvalue')/100;
link  = plotgui('getlink',fig);
model = [];
if ishandle(link.source) & strcmp(get(link.source,'tag'),'analysis')
  modid = analysis('getobj','model',guidata(link.source));
  if ~isempty(modid) & isshareddata(modid)
    model = modid.object;
  end
else
  model = getappdata(fig,'modl');
end
if ismodel(model);
  m     = model.datasource{1}.include_size(1);
  fstat = ftest(1-p,m-2,m-3);
end
