echo on
% SPEREADRDEMO Demo of the SPEREADR importer function
 
echo off
%Copyright Eigenvector Research, Inc. 2018
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause


pause
%-------------------------------------------------
% Introduction: SPEREADR is used to import Princeton Instruments SPE files
% into the workspace.


pause
%-------------------------------------------------
% Options structure (optional): You may choose to create an options
% structure for spereadr by calling SPEREADR using 'options' as an input
% argument. You may view then view the contents and adjust variables as
% needed (see the file header and or the SPEREADR wiki page for more
% details regarding the options structure.
options = spereadr('options');
options


pause
%-------------------------------------------------
% We are going to set dsomode to 'img' (the default). If MIA_Toolbox is
% installed, this will create an image type DSO. However, if MIA_Toolbox is
% not installed, a standard DSO will still be created.

options.dsomode = 'img';


pause
%-------------------------------------------------
% About importing a file: If you wish to browse for a file, simply call on
% SPEREADR without any input argument:
%
% mydata = spereadr();
%
% You will be prompted to select a .spe file to load and the created DSO
% will be stored in the output variable ('mydata' in this case).
%
% Alternatively, you may specify the file:
%
% mydata = spereadr('demodata.spe');
%
% Or specify a file with an options structure: 
%
% mydata = spereadr('demodata.spe',options);


pause
%-------------------------------------------------
% Import a file: For the purpose of this demo the file 'demodata.spe' and
% the options structure will be used to demonstrate SPEREADR. By default a
% waitbar will appear displaying progress. Depending on the number or
% Frames and Region(s) of Interest (ROI(s)) in the SPE file, loading may
% take some time.

% mydata = spereadr('demodata.spe',options);

% Note: To cancel importing an SPE file at anytime, close the waitbar.


pause
%-------------------------------------------------
% Display data (Part 1): Displaying the image depends on the DSO type.
% To check the DSO type, inspect the .type field. If the value is 'data',
% then it is a data DSO. If the value is 'image', then it is an image DSO.
 
% mydata.type;
 
% For image DSOs plot using the PLOTGUI function:
 
% figure(); plotgui(mydata);
 
% Using 'demodata.spe' to create 'mydata' image DSO. You should see what
% appears to be two images in a PLOTGUI figure. This data contains a single
% Frame and two ROIs, the region between the two ROIs is filled with NaNs.
%
% If mydata is a data DSO, PLOTGUI may not produce a correct view of
% the data. It will default to a summary view and plot a Mean (see the
% PlotGUI Control Panel).

pause
%-------------------------------------------------
%End of PLSDEMO
 
echo off
