echo on

% Demo of the VIPNWAY function
% This demonstration illustrates the use of the Variable  
% Importance of Projection of N-Way data in the PLS_Toolbox.
%
% This demonstration uses the same dataset that is used in the NPLS Demo
% If you have not already done so, please run through the NPLS Demo to 
% better understand the dataset and modeling technique

echo off


% Copyright Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

clear ans
echo on
 
% To run the demo hit any key after each pause
pause
%-------------------------------------------------

% The data we are going to work with is a fluorescence data set
% 268 samples of refined sugar was sampled directly from a sugar 
% plant and excitation-emission landscapes were measured of the
% sample dissolved in water. Also available is the lab quality
% measure color, which is a measure of the amount of impurities.
% We will develop a NPLS model that relates the fluorescence data to
% the physical property color. Such a model can be used to replace
% the tediuos, time-consuming, infrequent, expensive and chemical-consuming
% lab-measurement with an on-line method.

% Lets start by loading the data. Hit a key when
% you are ready.
pause
%-------------------------------------------------

load sugar.mat
X = sugar;

% The color information is stored in the .userdata field.
% Lets set the Y block
pause
%-------------------------------------------------

Y = sugar.userdata;

% Take a look at the dimensions of X and Y
pause
%-------------------------------------------------
whos X Y

% The required input for the VIPNWAY function is a NPLS model
% Before building a model, let's set some options for NPLS model
% The NPLS function will be used to construct the NPLS model.
%
% To get the options for this function run
%-------------------------------------------------

options = npls('options');

% See "npls help" to get the valid settings for these options.
%
% Turn off "display" and "plots"
pause
%-------------------------------------------------

options.display = 'off';
options.plots = 'none';


% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the NPLS function. Preprocessing
% can be performed explicitly at the command line, but this allows the
% NPLS function to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure will
% become a part of the standard model structure output by NPLS.
 pause
%-------------------------------------------------

prepro = preprocess('default', 'centering');
options.preprocessing{1} = prepro;
options.preprocessing{2} = prepro;


% Now lets build the NPLS model with 5 LV's using the npls function 
pause
%-------------------------------------------------
modelnpls = npls(X, Y, 5, options);


% To calculate VIP (Variable Importance of Projection) Scores, use the
% VIPNWAY function. The input for this function is a NPLS model. The output
% is a cell array with VIP Scores for each mode and each Y column
pause
%-------------------------------------------------
vip_scores = vipnway(modelnpls);

% Pull out the VIP scores for modes 2 and 3
pause
%-------------------------------------------------
mode2_VIPScores = vip_scores{1,1};
mode3_VIPScores = vip_scores{2,1};

% Plot VIP scores for Mode 2
pause
%-------------------------------------------------
figure
plot(1:size(mode2_VIPScores,1), mode2_VIPScores, 'linewidth', 2), hold on
title('VIP Scores Plot - Mode 2')
xlabel('Variable Number - Mode 2')
ylabel('VIP Score - Mode 2')

% Plot VIP scores for Mode 3
pause
%-------------------------------------------------
figure
plot(1:size(mode3_VIPScores,1), mode3_VIPScores, 'linewidth', 2), hold on
title('VIP Scores Plot - Mode 3')
xlabel('Variable Number - Mode 3')
ylabel('VIP Score - Mode 3')

%End of VIPNWAY Demo

echo off
