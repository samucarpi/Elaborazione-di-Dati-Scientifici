%This is the Managing Data, Models, Plots and Interfaces in PLS_Toolbox Matlab Script that accompanies the course.

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Remove new lines from output
format compact

%% Create a simple object and see how it works.
% Create a new file, uncomment the code below and paste it in the file.
%
edit simplecar
% classdef simplecar
%   %SIMPLECAR Simple car class.
%    properties
%       Make
%       Model
%       Year
%       Mileage
%       FuelCapacity
%    end
%    methods
%       function obj = set.Mileage(obj,val)
%          if val<0
%            error('Mileage must be positive.');
%          else
%            obj.Mileage = val;
%          end
%       end
%       function r = getRange(obj)
%         if ~isempty(obj.Mileage) && ~isempty(obj.FuelCapacity)
%           r = obj.Mileage * obj.FuelCapacity;
%         end
%       end
%    end
% end


%% Look at some DataSet Object properties and methods.

% Show the main definition, note that DSO uses a different (older) format
% than that of the above but it functions exactly the same

cd(fileparts(which('dataset'))) %Look at methods in folder

edit dataset/dataset.m %See properties

% Notice properties are kept in a Matlab structure

% Look at an overloaded function (method)
edit dataset/isempty.m

% Load NIR data
load nir_data.mat

% Note if you double click on data in Matlab Workspace window it opens in
% the DataSet Editor

% Look at the information displayed at the Matlab command line
spec1


%% Explore a Simple DataSet (see DATASETDEMO)

t    = [0:0.1:10]';
x    = [cos(t) sin(t) exp(-t)];
vars = {'cos(t)';'sin(t)';'exp(-t)'};

h   = dataset(x)

isa(h,'dataset')

% Note the indexing used to manage "sets" of meta data
h.author   = 'Data Manager';        %sets the author field
h.label{2,1} = vars;                  %sets the labels for columns = dimension 2

% Add another label "set"
h.label{2,2}     = {'COS(t)';'SIN(t)';'EXP(-t)'};
h.labelname{2,2} = 'Variables Uppercase';

%NOTE: when using cell notation {2}, this is shorthand for {2,1}
h.labelname{2} = 'Variables Lowercase';       %sets the name of the label for columns
h.axisscale{1} = t;                 %sets the axis scale for rows = dimension 1
h.axisscalename{1} = 'Time';        %sets the name of the axis scale for rows
h.title{1}         = 'Time (s)';    %sets the title for rows
h.titlename{1}     = 'Time Axis';   %sets the titlename for rows
h.title{2} = 'f(t)';                %sets the title for columns
h.titlename{2} = 'Functions';       %sets the titlename for columns
h.userdata = 'Any additional information needed goes here.'; %use the .userdata field with any kind of variable.

%% Accessing Fields for Plotting
% Create a plot from the DataSet, use dot notation and indexing
figure
plot(h.axisscale{1},h.data)
xlabel(h.title{1})
legend(h.label{2},'best')

% Index into meta data
h.axisscale{1}(1:10)

%% Importing
% Most PLS_Toolbox importers import to DataSet and try to intelligently
% place labels, axisscales, and classes.

m = editds_defaultimportmethods
%  { 'Description'  'keyword/function' {Default_filetypes} {valid_filetypes} }
% You can add user-defined importers via 'editds_userimport.mat' on path.

% Try autoimport, this function will use valid file types field to select a
% suitable importer.

myds = autoimport(which('textreadrdata.txt')); %GUI opens
myds = textreadr(which('textreadrdata.txt')); %Direct read

%% Importing
% Build a custom data importer.
% Edit the editds_userimport.m file for an example of import code.

edit editds_userimport

% Use this to create your own importer:

% function newds = myimporter(filename)
% %MYIMPORTER Import XLS file and build a DataSet.
% % I/O: newds = myimporter(filename)
% 
% 
% if nargin<1 | isempty(filename)
%   %Query user for file location
%   [file,pathname] = evriuigetfile({'*.xls','XLS File with labels (*.xls)';'*.*','All Files (*.*)'});
%   if file == 0
%     data = [];  %exit without data
%   else
%     filename = [pathname,file];
%   end
% end
% 
% % Get full file location if on path, returns path if already present
% myfile = which(filename);
% 
% % Read in data
% [NUM,TXT,RAW] = xlsread(myfile);
% 
% % Initialize dataset
% newds = dataset(NUM);
% 
% % Add row labels
% newds.label{1,1} = TXT(3:end,1);
% 
% % Add column labels
% newds.label{2,1} = TXT(1,2:end);

% Add your new importer to the import methods for PLS_Toolbox via the
% editds_importmethods function. Note that we should leave the third column
% wiht an empty string so the default reader for XLS files continues to
% work. Add the following:

% list = {'RedBeer XLS File Format'      'myimporter'    {''}           {'xls'}};

% Now start browse and try importing from the File menu:

browse

% Note that variable name, we can change/fix that.

%% FAQ for useful DataSet commands

% How do I copy meta data from an old dataset to a new dataset?
% Use the copydsfields function:
x2    = x;
g = dataset(x2);
g = copydsfields(h,g,2)
% Does this work for models to data?
% Yes!

%---------------
% I have a new dataset but it has few more (missing) variables at the ends
% of data. How do I join this to data I imported already?
% Use the matchvars function:
x2    = [cos(t) sin(t) exp(-t) acos(t)];
g     = dataset(x2);
g.label{2} = {'cos(t)';'sin(t)';'exp(-t)';'acos(t)'};
matched_newdata = matchvars(h,g)
matched_newdata.label{2}
% Wow, that would be nice if it were automatically done in the GUI, like for predictions.
% It is!

%---------------
% I have a label (meta data) set I want to remove, how do I do that?
% Use the rmset method.
g = rmset(g,'label',2,1)

%---------------
% Is there an easy way to copy data and labels to the clipboard so I can
% paste the data into a spreadsheet?
% Sure, the copy_clipboard method does this.
copy_clipboard(h)
clipboard('paste')

%---------------
% I have some variables that I want to delete rather than exclude. I there
% a method for that?
% Use the delsamps method.
g = delsamps(g,4,2,2)

%---------------
% Are there methods for searching and sorting DataSets?
% Yes, 'search' and 'sortby' are used.

out = search(h,'label',2,1,'sin(t)')

[B,index] = sortby(h,'label',2,1)

%---------------
% How do I create image datasets?
% The DSO stores images "unfolded" so you need to use the 'buildimage'
% function on raw n-way data cubes
load smbread %250px x 250px x 5channel image
rawdata = bread.imagedata; %Get folded data
myimg = buildimage(rawdata,[1 2]); %Spatial (pixel) data is in first two modes [1 2], variables are in 3rd mode

%---------------
% Can I create a DSO from from a Matlab table array?
% Yes, use the table2dataset funciton. 


%% Preprocessing (see PREPROCESSDEMO)
% The goal of preprocessing is to remove variation you don't care about,
% i.e. clutter, in order to let the analysis focus on the variation you do
% care about
%
% PLS_Toolbox uses a stored set of instructions in a preprocessing
% structure

% List of methods
preprocess('keywords')

s = preprocess('default','mean center') %Create mean centering PP structure
s.calibrate %Calibrate instruction
s.apply %Apply to new data instruction
s.undo %If possible, how to undo preprocessing

% Multiple methods can be put into a preprocessing structure by adding
% additional strings in the 'default' call:

s = preprocess('default','normalize','mean center');

% Many preprocessing methods require that they be first used on calibration
% data before being applied to new data. Mean Center requires this for
% example

[spec1p , sp] = preprocess('calibrate', s, spec1);

spec2p = preprocess('apply', sp, spec2);

figure
subplot(2,1,1)
plot(spec2.data')
title('Original Data')
subplot(2,1,2)
plot(spec2p.data')
title('Preprocessed Data')

%% Preprocessing Window

% Open data in PP GUI
[spec1p , sp] = preprocess(spec1)

% Settings seen from GUIs are usually part of the .userdata in the PP
% structure

%% FAQ for Preprocessing

% What if I want to do a simple mathematical operation for preprocessing?
% Use 'arithmetic' preprocessing.
s = preprocess('default','arithmetic')
s.userdata.operation = 'multiply'
s.userdata.constant = 100

a = preprocess('calibrate',s,rand(5))
a.data

%---------------
% Can a user create their own custom preprocessing?
% Of course, see:
% http://wiki.eigenvector.com/index.php?title=User_Defined_Preprocessing

%---------------
% What preprocessing method should I use for my data?
% Ahh, that's a tough question. Have a look at chapter 7 the tutorial:
pls_toolboxhelp

% Try different preprocessing and settings. The Model Optimizer is a
% good way of accomplishing this:
%http://wiki.eigenvector.com/index.php?title=Modeloptimizergui

%% Model Object (see EVRIMODELDEMO)
% EVRIMODEL Object manages all methods and properties for building,
% manipulating, and reviewing models.

model = evrimodel('pls') %Empty PLS model object
% Note properties

% Load demo data, set ncomp and preprocessing
load plsdata
model.x = xblock1;
model.y = yblock1;
model.ncomp = 3;
model.options.preprocessing = {'autoscale' 'autoscale'};

% Run calibrate method to actually build model
model = model.calibrate;

model.iscalibrated

%% Model Object Info
% Display model info
model

%% Model Object Plots
% With this newly calibrated model, we can request things like scores
% plots

model.plotscores
% model.plotloads
% model.ploteigen

% Or the Q residuals for the first 5 samples

model.q(1:5)

% What data was used to create a model
model.datasource{1}
model.datasource{2}

model.x %Doesn't have X data because it wasn't saved in simple case.

%% Model Object Predictions
% When a model is applied to new data, the output is an applied model, also
% known as a prediction object.

% Using the .apply method and passing the data we want to apply the model
% to (xblock2, in this case)

pred = model.apply(xblock2);

pred.isprediction

% The original model is generally stored in the .parent field so the model
% could be re-applied

orginal_model = pred.parent
xblock3 = dataset(rand(100,20));
pred2 = orginal_model.apply(xblock2)

% If we are applying a regression model (as we are in this case), we can
% also pass the "measured" y-block values so that we can get RMSEP and
% other information

test = model.apply(xblock2,yblock2);


%% Model Object Exporting and Saving

% Simplest way is to save to .mat file
save('mymodel','model')
%clear model
%load mymodel

% Export to human readable format (m-code, XML, ASCII) using dialog
savemodelas(model)

% Export a regression vector (PLS, PCR and MLR)
exportmodelregvec(model)

%% Model Object Options
% Options are "optional" inputs to the function method. They are held in a
% structure that can be modified before calibration.
model = evrimodel('lwr') %Empty LWR model object

% Options
opts = model.options

% Options can be set via an options structure
% opts.algorithm = 'pls';
% model.optoions = opts;

% The can be set direction as well. For example, we could modify the
% algorithm option to use 'pls' rather than 'pcr' (the default)
model.options.algorithm  = 'pls';

% Meta parameters are inputs that are generally required. They are set with
% dot notation on the model object. For example, with LWR the "local"
% calibration points (npts) are set via model
model.npts = 20;
model.ncomp = 5;

%% FAQ for Model Object

% There's a lot of functionality to a model object, where's a good place to
% learn more?

% http://wiki.eigenvector.com/index.php?title=EVRIModel_Objects

%---------------
% How do I add crossvalidation?

% Before calibration:
model.crossvalidate(cvi,ncomp)

% After calibration you usually need to supply data since it's not kept
% with model object by default
model = model.crossvalidate(xblock1,'vet',10)

%---------------
% How can I get classification results from a model?
model.classification

%---------------
% How can I save data with the model?
model.options.blockdetails = 'all'; %Prior to calibration
model = model.calibrate;
model.x %Holds X block now

%---------------
% Can you use the modelcache with EVRIMODEL objects?

% Yes, the following command will turn modelcaching on for evrimodels
setplspref('evrimodel','usecache',1)

%---------------
% What is the modelcache?
% Modelcache is an archiving system that's automatically used by the model
% building interface (analysis window). It stores the model, data, and any
% predictions when a model is calculated.

%---------------
% What model types can be used with evrimodel?

m = evrimodel;
m.validmodeltypes

%---------------
% How do I know what to set?
% The .inputs method returns a cell array of strings indicating which
% properties can be set for the model in its current state. 
model.inputs

%% Plots
% Plotting in PLS_Toolbox is done primarily through the plotgui function.

% Basic plotting command
load arch
fig = plotgui(arch)

%Plotgui usually works on current figure.

% Plotting by a single variable (Fe) vs sample
% Let's choose a few variables via indexing
plotgui('axismenuvalues',{[0] [2 3 7]})

% All variables
plotgui('axismenuvalues',{[0] [1:10]})

% Go back to single variable and add labels
plotgui('axismenuvalues',{[0] [1]},'ViewLabels',1)

% Show classes
plotgui('update','viewclasses',1)

% Declutter warning shows
plotgui('declutter',1) %Full declutter

% Plot by rows to show metal content per sample
plotgui('plotby',1)

% This would make more sense as bar chart
plotgui('plottype','bar')

%% Advanced Plots

% Reset
try
  close(fig)
end
fig = plotgui(arch)

% Make subplots 2 x 2
plotgui('menuselection','ViewSubplots4')

% Set sub plots for 4 elements
myaxes = findobj(fig,'type','axes')
for i = 1:4
  axes(myaxes(i)); %Make axes current
  plotgui('axismenuvalues',{[0] [i]},'viewclasses',1)
end

% Get the data that's currently plotted
mydata = plotgui('getdataset',fig)

% Change size of figure
mypos = get(fig,'position')
set(fig,'Position',[mypos(1) mypos(2) mypos(3)+100 mypos(4)+100])
shg %Bring figure forward

% Reset
try
  close(fig)
end
fig = plotgui(arch)

% More class manipulation
plotgui('update','viewclasses',1)
% Add outline of class members
plotgui('menuselection','ConnectClassMethodOutline')
% Show legend
legend('show')

% Reset
try
  close(fig)
end
fig = plotgui(arch)

% Add a custom button to the plotgui Plot Controls to duplicate figure
myobj.mybtn = {'style', 'pushbutton', 'string', 'New Fig', 'callback', 'plotgui(''duplicate'',gcf)'}
% A a custom button to set up figure with several commands (aka shortcut)
myobj.mybtn2= {'style', 'pushbutton', 'string', 'Plot Nums', 'callback', 'plotgui(''viewnumbers'',1,''ViewLabels'',1,''viewclasses'',1);legend(''show'')'};
plotgui('update','uicontrol',myobj)

% Note that you could use your own functions in the callback.

% Reset
try
  close(fig)
end

% Plots are linked (through shareddata) when you 'duplicate' with plotgui.
fig = plotgui(arch)
fig2 = plotgui('duplicate',fig)

% Change plot on fig2.
plotgui('axismenuvalues',{[0] [2 3 7]})
plotgui('ViewLabels',1)

%Make selection on fig.
plotgui('setselection','set',{[20:60] []},fig);

%Make fancy selection (ANA quary) using search.
close(fig2);
idx = search(arch,'label',1,1,'ANA*');
figure(fig); %Make figure current.
plotgui('setselection','set',{find(idx) []},fig);
plotgui('ViewLabels',1)


%% FAQ PlotGUI

% How do I change background color?
figuretheme(fig,'k') % w/k/d/g black (k) is good for images

% How do I plot images?
% Plotgui automatically recognizes datasets of 'type' = 'image'
load smbread
plotgui(bread)

% How do I open a new plot?
fig = plotgui('new',bread)

% How can I create a "static" plot not controlled by plotGUI?
plotgui('spawn',fig)

% How do I find out how to do things with plotgui commands?
% Look at the appdata fields of the figure to see various command settings.
getappdata(fig)

% These settings are, in general, particular to the current axes.
% Also look at the default options
doptions = plotgui('defaultoptions')

% Look at the more possible commands to send to the plotgui in the
% 'menuselection' sub function (around line 320). The commands will be in
% the switch->menu case statement. Not all of them will work from the
% command line but most will. You can also put a stop in at this function
% to see how it's being called.

matlab.desktop.editor.openAndGoToFunction(which('plotgui'),'menuselection')

% How do I add a toolbar button to plotGUI?
% Use evriaddon: http://wiki.eigenvector.com/index.php?title=Working_With_EVRIADDON#Adding_an_PLOTGUI_Toolbar_Button

%% Controlling Interfaces
% Eigenvector GUI Control (EVRIGUI) objects allow the creation and control
% of various Eigenvector graphical user interfaces (GUIs).
% http://wiki.eigenvector.com/index.php?title=Analysis_EVRIGUI_Object

% Use EVRIGUI to create an Analysis window.
analysis_gui_object = evrigui('analysis');

% Use interface method to show all methods
analysis_gui_object.interface

% Use .setMethod to set to PCA
analysis_gui_object.setMethod('pca') %Note window title change

% Now load cal data
analysis_gui_object.setXblock(arch);

% Get current preprocessing
curent_pp = analysis_gui_object.getXPreprocessing

% Set preprocessing
analysis_gui_object.setXPreprocessing('autoscale');

%Set crossvalidation{ 'vet' splits blindsize}
analysis_gui_object.setCrossvalidation('vet',10,10) 

% Calibrate a model
analysis_gui_object.calibrate;

% How many components were chosen
comps = analysis_gui_object.getComponents

% One comp seems wrong. Look at Eigenvalue plot
fig = analysis_gui_object.pressButton('ploteigen')

% Use plotgui command and set to eigenvalues vs PCs
plotgui('axismenuvalues',{[0] [1]})

% Change to 3 components to capture knee
analysis_gui_object.setComponents(3);

%Recalculate
analysis_gui_object.calibrate;

% Get list of buttons we can use to make plots
analysis_gui_object.getButtons

% Let's make a scores plot
fig = analysis_gui_object.pressButton('plotscores')

%% FAQ EVRIGUI

% What other interfaces can be used?
% http://wiki.eigenvector.com/index.php?title=Browse_EVRIGUI_Object
% http://wiki.eigenvector.com/index.php?title=TrendTool_EVRIGUI_Object

% How can I get my object without created a new one?
% Use the -reuse flag.

obj = evrigui('analysis','-reuse')

% How can I access the figure handle?
% Use the .handle property.

figurehandle = obj.handle;

%% Reporting Results (REPORTWRITERDEMO)
%

% Close all figures
close all force
load wine

% Make a model with default plots
model  = pca(wine,2);

% Need a picture of Bill
billimg = imread('http://ontherealny.com/wp-content/uploads/2013/01/OfficeSpace.jpg');
billimg = buildimage(billimg);
plotgui('new',billimg,'axismenuvalues',{[0] [1 2 3]});
title('Bill');

% Open eigen plot as well
model.ploteigen

% Get handles to all figures and model then send them to reportwriter
allfigs = findobj(0,'type','figure');
allfigs = num2cell(allfigs);
allfigs{end+1} = model;

% Make report
fname = reportwriter('html',allfigs,'TPS Report');

%Even easier if we have handle to our analysis figure (created above for
%example)
opts = reportwriter('options');
opts.autocreateplots = 'yes';
reportwriter('html',analysis_gui_object.handle,'Sample Report',opts)

% Modify reportwriter.css to change color and formatting.
edit(fullfile(fname(1:end-5),'reportwriter.css'))

%Go with grayish palette
% background-color:#d5dbdb;
% background-color:#cccccc; 
% background-color:#333333;
% Save and reload.

% Modify "master" reportwriter.css to always use changes
which reportwriter.css





