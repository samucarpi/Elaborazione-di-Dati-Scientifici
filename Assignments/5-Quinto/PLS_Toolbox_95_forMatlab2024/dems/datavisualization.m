%This is the Data Visualization PLS_Toolbox Matlab Script that accompanies the course.

%Copyright Eigenvector Research, Inc. 2019
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Remove new lines from output
format compact

% OUTLINE:
% 
%     Overview and Motivation
%         Data Structures and Features
%         Exploratory vs. Explanatory
%         Practical Considerations
%         Basic Plotting Elements
%         Matlab and PLS_Toolbox Plotting Organization 
%     Plot Types
%         Popular types
%         Images
%     Custom Plotting
%         Defaults (Matlab, Plotgui)
%         Custom Class Symbols
%         Reverse Engineering
%         Fonts
%         Static Plots
%         Movies
%     Exporting
%         SVG vs Bitmap
%         Publications
%     Higher Order Data
%         Colorby
%         Layering
%         Tiled plots
%         Condensing Data with Factor Based Models
%         Slicing and Motion
%     Conclusions
%         Resources
%         Future Considerations

%% Data Structure

% Example of data
load wine
wine.table %Labels and data

%% Scatter plots

%Simple plot
h = scatter(1,1);
text(1,1,'Sample 1');

%Scatter plots show correlation
cla;%Clear current axes
scatter(wine.LifeEx,wine.HeartD);
xlabel('Life Expectancy (Years)')
ylabel('Heart Disease Rate (Cases/100,000/yr)')
text(wine.data(:,4), wine.data(:,5),wine.label{1})
title('Life Expectancy vs Heart Disease')

%Open plot editor
plotedit on 

%Scatter plot of pca on arch
load arch
%Create 3 PC model
options = pca('options');  % constructs a options structure for PCA
options.plots = 'none';
options.preprocessing = preprocess('default','autoscale');
model = pca(arch,3,options);
plotscores(model);
%Try decluttering labels with menu

%Add 3rd mode (z-axis to plot)
plotgui('update','axismenuindex',{1 2 3},'axismenuvalues',{1 2 3})

%Scatter plot considerations

%How to handle too much data.
%Reduce marker size.
load smbread;
model = pca(bread,3,options);
scores = model.scores;
subplot(2,2,1)
scatter(scores(:,1),scores(:,2));
title('Default With Too Much Overlap')
subplot(2,2,2)
scatter(scores(:,1),scores(:,2),'.','sizedata',1);
title('Reduce Marker Size')
subplot(2,2,3)
scatter(scores(:,1),scores(:,2),'MarkerEdgeAlpha', .01);
title('Add Transparency')
subplot(2,2,4)
scatter(scores((1:20:end),1),scores((1:20:end),2),'.','sizedata',1);
title('Down Sample to 5%')

%Use histograms
figure

%Right-click on data and select histogram for x and y data
plotgui(scores(:,1),scores(:,2));

%Other plot types, bivariate histogram
figure
histogram2(scores(:,1),scores(:,2),100)

%% Line plots
load wine
plotgui(wine)
set(gcf,'color','white')%Background color of figure
%Select first 3 variables, liquor, wine, and beer
%Not easy to see trends

%Try sub plots
figure('color','white')
plotgui(wine,'plottype','line','ViewLabels',1)
subplot(3,1,1)
plotgui(wine,'AxisMenuValues',{0 1})
subplot(3,1,2)
plotgui(wine,'AxisMenuValues',{0 2})
subplot(3,1,3)
plotgui(wine,'AxisMenuValues',{0 3})

%These axes could be linked so all plots have same axis scales and zooming
%scale but it doesn't make sense here
myaxes = findobj(gcf,'type','axes')
linkaxes(myaxes,'x')

%Plot spectra
load nir_data
plotgui(spec1,'plotby',0,'AxisMenuValues',{1 1})
set(gcf,'color','white')

%Highlight a line. 
figure
rawdata = spec1.data;
h = plot(rawdata');%Note the line object
axis(gca,[123.91 147.75 0.1586 0.26939]);%Zoom
h(1).LineWidth = 8;%Highlight 1st line with width

%Line plot y axis limit changes
plotgui(wine,'AxisMenuValues',{0 4},'ViewLabels',1)
myaxis = axis;
%Life expectancy differences aren't easy to see when y has 0 limit
myaxis(3) = 0;
axis(myaxis)

%% Bar plot
load plsdata
options = xgb('options');
options.display = 'off';
options.plots = 'none';
options.preprocessing{1} = preprocess('default','mean center');
model = xgb(xblock1,yblock1,options);
fs = model.detail.xgb.featurescores;
fsids = model.detail.xgb.featureIDs;
% Show feature importance, this is a measure of each variable's
% importance to the tree ensemble construction.
%Horizontal chart not sorted.
barh(1:length(fs), fs)

%Sort and add labels.
figure
ax = axes;
[sfs, isort] = sort(fs, 'ascend');
barh(ax,1:length(sfs), sfs);
ylabel('Variable Score')
xlabel('Gain')
varlabs = xblock1.label{2};
set(ax,'ytick',[1:length(sfs)],'yticklabel',varlabs(isort,:),'userdata',isort(sfs>0))

% Good use of vertical bar chart where month is used on X axis

% Create data for childhood disease cases
measles = [38556 24472 14556 18060 19549 8122 28541 7880 3283 4135 7953 1884];
mumps = [20178 23536 34561 37395 36072 32237 18597 9408 6005 6268 8963 13882];
chickenPox = [37140 32169 37533 39103 33244 23269 16737 5411 3435 6052 12825 23332];
% Create a vertical bar chart using the bar function
figure
bar(1:12, [measles' mumps' chickenPox'], 1)
% Set the axis limits
axis([0 13 0 40000])
set(gca, 'XTick', 1:12)
% Add title and axis labels
title('Childhood diseases by month')
xlabel('Month')
ylabel('Cases (in thousands)')
% Add a legend
legend('Measles', 'Mumps', 'Chicken pox')

%Example of stacked bar plot with spectra 
load nir_shootout_2002.mat;
options = pca('options');  % constructs a options structure for PCA
options.plots = 'none';
pp = preprocess('default','mean center');
options.preprocessing = {pp};
model = pca(calibrate_1,4,options);

datap = preprocess('apply',model.detail.preprocessing{1},calibrate_1.data);
varcap(datap.data,model.loads{2,1});


%% Stick plot
%MS data displayed as a tiny bar chart
load MS_time_resolved
MS_time_resolved.description
MS_time_resolved.axistype
plotgui(MS_time_resolved,'plotby',1)

%% Dendrogram

load arch
arch = arch(1:3:size(arch,1),:); %smaller data set
opts = cluster('options');
opts.algorithm = 'kmeans';

%Vertical ordering doesn't make a difference with respect to distances between samples
results1 = cluster(arch,opts);

%Small subset
load arch
arch = arch([8 10 11 15 18]);
results2 = cluster(arch,opts);

%%Correlation Maps
load wine
corrmap(wine)

%% Wordcloud
% Follow the pdf2text demo to see wordcloud in action

oldState = pause('off');
pdf2textdemo
pause(oldState)


%% Images
% image vs imagesc
imgdata = [0 2 4 6; 8 10 12 14; 16 18 20 22];
figure
subplot(2,1,1)
image(imgdata)
title(gca,'Plot Using IMAGE')
colorbar
subplot(2,1,2)
imagesc(imgdata)
title(gca,'Plot Using IMAGESC')
colorbar
set(gcf,'color','white')

%Show jpeg image
imgdata = imread('EchoRidgeClouds.jpeg','jpeg');
figure
imagesc(imgdata)
%Build image dataset
imgdso = buildimage(imgdata);

%Demo with 5 channel multivariate image.
figure
load smbread
h = plotgui(bread,'plotby',2,'densitybinsmin',512)

% Interactively shift color map. 
% http://wiki.eigenvector.com/index.php?title=Working_with_false-color_images

%Open histogram manually or with code below
histcontrast('create',h)


%% Defaults

%Show Matlab defaults

defaults = get(groot,'factory') %List all factory-defined property values
sdefaults = get(groot,'factoryScatter') %List all factory-defined property values for a specific object (scatter)
sdefaults_ScatterLineWidth = get(groot,'factoryScatterLineWidth') %List factory-defined value for the specified property (scatter line width).

%All figures will have white background because set at root level. 
set(groot,'defaultFigureColor','white')

%Try setting root then figure level defaults.
f = figure
set(groot,'defaultLineLineWidth',2)
plot(rand(10))

%Now set line width for the figure
set(f,'defaultLineLineWidth',5)
plot(rand(10))

%Line defaults
sdefaults = get(f,'factoryLine')

%Marker size
set(f,'defaultLineMarkerSize',40)

%Line width
set(f,'defaultLineLineWidth',8)

%See new defaults
sdefaults = get(f,'factoryLine')

plot(rand(10),'-o')

%Try other settings at figure level
set(f,'defaultLineMarkerEdgeColor','k')
set(f,'defaultLineMarkerFaceColor','yellow')
set(f,'defaultScatterMarkerFaceColor','green')

plot(rand(10),'-o')

%% Plotgui Defaults

%Plotgui defaults may or may not take precedence depending on the
%situation. 
load wine
plotgui(wine,'new','viewlabels',1)


%Make label angel 45 degrees on a plot
plotgui('viewlabelangle',45)

%A different way of setting viewing angle.
setappdata(gcf,'viewlabelangle',15)
plotgui('update')

%Make 45 degree angle the default.
setplspref('plotgui','viewlabelangle',45)

close all
plotgui(wine,'new','viewlabels',1)

%% Class symbols
load arch
plotgui(arch)
%Right-click on marker and select Symbol Style > Custom...
symbolstyle

%% Reverse engineering
%Use the code from above to search appdata and object hierarchy for ideas.

%% Font size

% The getdefaultfontsize function is used extensively to adjust font sizes.
% However, it is not used everywhere and some experimentation may be needed
% to achieve specific sizing.

setplspref('getdefaultfontsize','normal',14)

%% Static plots
load arch
plotgui(arch,'plotby',1,'plottype','line','ViewLabels',1)

plotgui('spawn',gcf)

%% Movies

%Impress the management with a movie. Below we create the EVRI logo then
%use the campos function to change view position. Then use the getframe and
%movie functions to create the movie. 

close all
plslogo
x = 55;
y = 20;
z = 22;
campos([x y z])
i = 0;
for a = -10:.5:10
  i = i+1;
  campos([x,y-a ,z-a])
  drawnow
  pause(.2)
  %Using axes rather than figure doesn't work well for movie. It seems too
  %zoomed in.
  %F(i) = getframe(gca);
  F(i) = getframe(gcf);
end

fig = figure;
movie(fig,F,2)

%Write to file
v = VideoWriter('LogoDemo','MPEG-4');
open(v);
writeVideo(v,F)
close(v)

%% Exporting and Saving
close all
surf(peaks)
print(gcf, 'PeaksEPS','-depsc');

%% Subplots
load arch;
model = pca(auto(arch),4,struct('display','off','plots','none'));
plotscores(model) % create subplots from plot controls menu

% Make subplots 2 x 2
fig = plotgui('new', arch, 'plotby', 2);
plotgui('menuselection','ViewSubplots4')
 
% Set sub plots for 4 elements
myaxes = findobj(fig,'type','axes')
for i = 1:4
  axes(myaxes(i)); %Make axes current
  plotgui('axismenuvalues',{[0] [i]});
end
plotgui('update','viewclasses', 1, 'figure', fig);


%% Resources

% Matlab examples:
%   www.mathworks.com/products/matlab/plot-gallery.html

% General plotting examples and challenges:
%   www.data-to-viz.com

% Design discussion:
%   www.visualcinnamon.com/resources/learning-data-visualization


