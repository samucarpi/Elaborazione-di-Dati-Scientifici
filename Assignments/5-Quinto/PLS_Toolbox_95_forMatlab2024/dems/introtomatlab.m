%This is the Introduction to Matlab Script that accompanies the course.

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%% Try it boxes
disp('Hello world')


%% Start Matlab
% Show some basic commands.

%Version information
ver

%Current date
date

%Computer information
computer

%% Help Browser
% Help documentation

%Open help
doc

%Open help to specific page
doc pca

%% Matlab Editor
% Explore Matlab editor

%Edit a specific file
edit introtomatlab

%% The Matlab Path
% Explore the Matlab path

%Show current path
path

%Find the path of a specific file
which pca

%Find the path of all files of the same name.
which doc -all

%% who and whos Commands

load plsdata

who

whos

%% Entering Data at the Command Line
% Review of entering numeric data at the command line

a = 3.14; % Scalar

b = [1 2 3] % vector

c = [1; 2; 3] % column vector

d = b' % transpose to column vector

e = [1 2 3; 4 5 6; 7 8 9] % array 

f = [b', c, 2*c] % nested commands

g = [1:5] % vector equally spaced

h  = 10:2:20 % vector by 2s

id = eye(3) % identity matrix

zr = zeros(4) % array of zeros

on = ones(2) % array of ones

%% Mathematical Operations
% Vectors and matrices must have compatible dimensions

b = [1 2 3] % vector
 
c = [1; 2; 3]% column vector
 
d = b + c' % vector + vector
 
e = b * c % vector x vector
 
f = ones(3) * d' % matrix x vector

%% Indexing (Colon)
% Indexing (subscripts), use the colon(:) to define ranges

a = reshape([1:30],[5 6])'

b = a(1:2,1:2) % selects 2x2 submatrix of A

c = a(:,4) % selects column 4 of A

d = a(4:5,2:5) % selects 2x4 submatrix of A

%% Indexing into Three-way (and higher) Arrays

x = round(rand(3,5,2)*10) % create 3D array

x(:,:,2) = ones(3,5)*5 % assign new value to "slab"

%% Types of Data

a = 3; % double precision floating point 

b = uint8(12); % unsigned 8-bit integer 

c = 'barry'; % character array

whos

%% Other Types of Data
% Everything is an array!

myname = ['bill smith';'bob jones ']; % Note padding with space character

myname = ['bill smith';'bob jones'] % cause error

%% Cell Arrays
% Cell arrays are like egg cartons, good for heterogeneous data, even data
% of different types 

x = cell(4,1); % create empty

x{1} = rand(4,5); % add array

x{2} = rand(10,5); % add another array of different size

x{3} = 'abc' % add a character array

%% Structure Arrays
% Structures have fields and values

mystruct.name = 'billy';

mystruct.data = [1 4 6; 7 9 10];

mystruct.date = date;

mystruct

a = mystruct.data % Pull value from field

%% Import Data
% Read Redbeerdata.xls into Matlab.

myfile = which('Redbeerdata.xls') % location if on path

xlsread(myfile) % read the file

% Read into a variable!
xlsdata = xlsread(myfile)

% What outputs are there
help xlsread

% Try again with additional outputs
[NUM,TXT,RAW] = xlsread(myfile)

%% Clean Up Data
% Let's tidy up the data we imported using indexing and rename our
% variables to something easier to understand 

raw_data = NUM

variable_labels = TXT(1,2:end) % Note how we index

sample_labels = TXT(3:end,1) % Note how we index

clear TXT RAW NUM


%% Exploring Data
% Look at the data by indexing into it

% What's the strongest beer?
raw_data(:,3)
max(raw_data(:,3))

% What's the weakest beer?
min(raw_data(:,3))

% What's the average beer strength?
mean(raw_data(:,3))

% What's the strength in ABV? 
raw_data(:,3)/.789

%% Simple Plots
% Make some simple plots of the data

%Plot strength
plot(raw_data(:,3))

%Add title
title('Beer Data')

%Add labels
ax = gca %#ok<*NOPTS>
xticks([1:1:6]) %Fix for half step on ticks, default ticks look weird.
ax.XTickLabel = sample_labels
ax.XTickLabelRotation = 90

%Add a y axis label
ylabel('Alcohol  (%w/w)') 

%% Dataset Object (DSO)
% Make a Dataset Object with our example beer data.

% Initiate DSO with our raw data
beerds = dataset(raw_data)

% Add row labels
beerds.label{1,1} = sample_labels

% Add column labels
beerds.label{2,1} = variable_labels

% Add a class for style of beer
beerds.classid{1,1} = {'ale' 'lager' 'ale' 'ale' 'lager' 'lager'}
beerds.classid{1,2} = {'brown' 'gold' 'gold' 'brown' 'dark' 'dark'}

%% Exploring the Dataset

% Show formatted text table
beerds.table

% Show a statistical summary of columns
summary(beerds)

% Show class membership
classsummary(beerds)

% Open DataSet Editor
editds(beerds)

%% Make a Function
% Take commands used so far and create a function that takes a file name as input and returns a dataset

edit myfunction

%Copy and paste the commented code below then uncomment it in the
%function.

% function newds = myfunction(filename)
% %MYFUNCTION Import XLS file and build a DataSet.
% % I/O: newds = myfunction(filename)
% 
% % Get full file location if on path
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

%Test the function.
beerds = myfunction('Redbeerdata.xls')

%% Review of Function
% Note the workspace.

%Show help
help myfunction

%Find files that mention XLS in the first H1 help line
lookfor XLS




%% Saving Variables from Workspace
% Take commands used so far and create a function that takes a file name as input and returns a dataset

% Save all variables to alldata.mat
save alldata

% Save a single variable to BeerData.mat
save BeerData beerds

%% Clearing Variables from the Workspace

% Clear everything!
clear

% Clear specific variables
clear a b c

% Keep specific variables
clearvars -except arch

%% Loading Saved Data to the Workspace
% Will load any MAT file on the Matlab path

load BeerData

%% Working with Table Arrays
% Matlab continues to expand the use of table arrays 

myfile = which('Redbeerdata.xls')

% Use readtable function on redbeer xls file
T = readtable(myfile)

% Remove first empty row
T(1,:) =[]

% Convert to dataset
beerds = table2dataset(T)

%% Command Line Help

help xlsread

lookfor xls

which xlsread

doc xlsread

docsearch xlsread

%% PLS_Toolbox specific help commands 

%Show main help window
helppls

%Show I/O for function
pcr io

%Show all help 
pcr help

%Show options inputs
pcr options

%% Plotting and Graphics
% Try some of the advanced Matlab plotting features

%From Matlab help
[X,Y] = meshgrid(-8:.5:8);
R = sqrt(X.^2 + Y.^2) + eps;
Z = sin(R)./R;
C = gradient(Z);

figure
mesh(X,Y,Z,C)

%Use the rotate tool to view

%Want a smarter plotting command designed for use with datasets?

%Try using plotgui

load arch
arch
plotgui(arch)

%Notice y-axisscale, turn on labels and classes.

%% Helpful Commands with dir()

%Change to demo folder
cd(fileparts(which('pcademo')))

% Only retrieve xls files from the directory 
files = dir('*.xls')

%% Matlab and no Loops
% The following code does the same thing

%Loop through list and mulitply
x = [ 1 2 3 4 5 ]; % vector of values to multiply
y = zeros(size(x)); % initialize new vector
for i = 1 : numel(x) % for each index 
  y(i) = x(i)*2; %double value
end % end of loop

%% Do single call with element-wise multiplication
x = [ 1 2 3 4 5 ]; % vector of values to square 
y = x.*2; % double all values


%% Hands-on example
clear

%Read in arch data as a table object
myTable = readtable('arch_csv.csv');

%Convert table to a DataSet Object
myDSO = table2dataset(myTable);

%Get labels from DataSet Object
myLabels = myDSO.label{1,1};

%%Convert the labels to a cell array so we can use split function
myLabels_fixed = str2cell(myLabels);

%Use split function to split labels at the dash
myLabels_split = split(myLabels_fixed, '-');

%Get the part of label that is before the dash
myClasses = myLabels_split(:,1);

%Assign this to my class field
myDSO.class{1,1} = myClasses;
myDSO.classname{1,1} = 'Quarry';

%Split the last 12 samples into a separate DataSet Object to use for validation
myValDSO  = myDSO(64:end);
%OR use class name to split
%myValDSO = myDSO.('s');

%Create a DSO with just the calibration data
myCalDSO = myDSO(1:63,:);
%OR use class names
%myCalDSO = [myDSO.('K'); myDSO.('BL'); myDSO.('SH'); myDSO.('ANA')];

%% Creating classes example from labels
clear
load arch

%Pretend we're missing class information in the Arch dataset but we have a
%label set that has information about the quarry location (then a dash and
%then a sample number). We'd like to "parse" this label set to obtain class
%information.

%Our label set as a character array
ourLbls = ['K-AVG ';'K-1B  ';'K-2   ';'K-3A  ';'K-1C  ';'K-1D  ';'K-3B  ';'K-4R  ';...
  'K-4B  ';'K-1A  ';'BL-AV1';'BL-AV9';'BL-2  ';'BL-3  ';'BL-6  ';'BL-7  ';'BL-AV7';...
  'BL-1  ';'BL-8  ';'SH-1  ';'SH-15 ';'SH-S1 ';'SH-68 ';'SH-2  ';'SH-3  ';'SH-5  ';...
  'SH-13 ';'SH-II7';'SH-V18';'SH-IL1';'SH-IL1';'SH-II1';'SH-V12';'SH-V24';'SH-II5';...
  'SH-IIK';'SH-IL1';'SH-V12';'SH-I10';'SH-I13';'SH-V14';'SH-II7';'ANA-2 ';'ANA-3 ';...
  'ANA-4 ';'ANA-5 ';'ANA-6 ';'ANA-7 ';'ANA-8 ';'ANA-9 ';'ANA-1 ';'ANA-1 ';'ANA-1 ';...
  'ANA-1 ';'ANA-1 ';'ANA-1 ';'ANA-1 ';'ANA-1 ';'ANA-1 ';'ANA-1 ';'ANA-1 ';'ANA-2 ';...
  'ANA-2 ';'s1    ';'s2    ';'s3    ';'s4    ';'s5    ';'s6    ';'s7    ';'s8    ';...
  's9    ';'s10   ';'s11   ';'s12   '];
%You can aslo grab the label information from the DSO
%ourLbls = dataset.label{1,1};

%Convert the labels to a cell array so we can use strfind to locate the
%dashes in the names. 
ourLbls_fixed = str2cell(ourLbls);

%Use the strfind command to find dashes. Note the last samples have no
%dashes so the returned cell array will be empty.
dashPositions = strfind(ourLbls_fixed, '-'); 

%Preallocate a cell array that will hold our class names. This isn't
%completely necessary but will help performance (preallocation often helps
%performance in Matlab).
classNamesToUse = cell(75,1);

%Loop through our fixed labels cell array and create class names
% and populate our classNames cells array
for bb = 1:length(ourLbls_fixed)
  thisLbl = ourLbls_fixed{bb,:}; %Grab one label at a time
  thisDashPosition = dashPositions{bb}; %Get dash position for this particular label
  if isempty(thisDashPosition) %if no dash is found then this is an unknown sample
    thisClassName = 'Class 0'; %so assign it as Class 0
  else
    thisClassName = thisLbl(1:thisDashPosition-1); %Grab the first position in label all the way to our dash postion minus one
  end
  classNamesToUse{bb,1} = thisClassName; 
end

%Insert Class Names into DataSet Object
arch.class{1,2} = classNamesToUse;

%Give Class Set a name
arch.classname{1,2} = 'Quarry from Sample Labels';

%% Starting and Using GUIs

browse

pca

%% Other Items 

%Note popularity vs python and R (and Java), the scientific programming languages. 
web('http://pypl.github.io/PYPL.html','-browser')

% Turn warnings off
evriwarningswitch


