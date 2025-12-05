function plotbiplotlimits(fig)
%PLOTLOADSLIMITS Adjust biplot settings.
%
% NOTE: This function is only called from within plotgui/plotds and acts on
% the current axes.
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
  %Set axis based on truebiplot property.
  [mydata,mylink] = plotgui('getdataset',fig);

  if mylink.properties.trueBiPlot
    %if "on" - do axis equal
    axis equal
  else
    %if "off" - do axis normal
    axis normal
  end

end

