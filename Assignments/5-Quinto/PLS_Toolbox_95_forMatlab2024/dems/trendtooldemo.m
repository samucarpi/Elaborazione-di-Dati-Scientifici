echo on
%TRENDTOOLDEMO Demo of the Trendtool GUI
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause

pause
%-------------------------------------------------
% Load data:
load cancer

disp(cancer.description)

pause
%-------------------------------------------------
% TRENDTOOL is designed to display bi-modal data, either a matrix
% or a dataset object for a (qualitative) visual exploration.
% In the command line, type >>trendtool(cancer);

% For this example we'll plot one dataset and review it.
 
opts = trendtool('options');  % constructs a options structure.

% the options structure created is optional to use the trendool GUI,
% and it can be used like this: >>trendtool(cancer,opt);

pause
%-------------------------------------------------
% Call the TRENDTOOL GUI and view the data.
 
trendtool(cancer);
 
% The data has been passed to TRENDTOOL to be plotted.

% You can type: >>trendtool and you will be prompted to load data
% either from the workspace or from a file.
 
pause
%-------------------------------------------------
% Three figures should appear onscreen:
% The first figure it titled 'TrendTool Data View',
% the second figure is titled 'Trend View',
% the third is the 'Plot controls' control window.

pause
%-------------------------------------------------
% Right-click on the plot of the 'Data View' figure and choose
% 'Add Marker' to view the corresponding 'heights' in the other dimension,
% in the 'Trend View' figure.

pause
%-------------------------------------------------
% You can also drag the marker left or right in the
% 'TrendTool Data View' and the 'Trend View' figure
% will update accordingly.

% You may also add multiple markers to view multiple 'slices' at once.

pause
%-------------------------------------------------
% Right-click on the marker itself and you can convert the marker into
% a pair of markers using the other selectable modes.

% 'Area' mode, for example is used to view the integreated area between
% the pair of markers. Which can be moved around the figure.

pause
%-------------------------------------------------
% Other buttons you can use is to flip the x-axis direction,
% update the trendtool, or display both modes of the data simultaneously
% using a waterfall plot.
% You may even choose to save the markers for future use.

% Hover the mouse over a button for details.

%End of TRENDTOOLDEMO
 
echo off
