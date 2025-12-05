echo off
%RPCADEMO Demonstrates the Robust PCA functions
echo on
clc
 
% This is a demonstration of the 'rpca'  functions
% in the PLS_Toolbox.  Just follow along and hit the return
% key when when you are ready to go on.
echo off
 
%Copyright Eigenvector Research, Inc. 2002
%
%sv 01/05
 
echo on
 
% For this demo to run correctly the data set 'rpcadata'
% must be available, along with the functions 'rpca', 'mcdcov',
% 'makeplot', 'screeplot', 'scorediagplot' and 'rrmse'.
 
% Now hit any key to continue (do this each time you are ready
% to go on).
 
pause 
%-------------------------------------------------
% First we must load the data set RPCADATA.
 
load pcadata
 
% To find out what we have just loaded, use the 'whos' function
pause
%-------------------------------------------------
whos
 
% So we have two data sets of different sizes, part1 and part2.
% The first part has 300 samples and the second part
% has 200 samples.  Both of course have 10 variables.
% Lets take a look at part1 first. Hit a key when ready for a plot.
pause
%-------------------------------------------------
plot(part1.data);
title('Data for PCA example, Part 1')
xlabel('Time')
ylabel('Variable Values')
pause
%-------------------------------------------------
 
% This looks pretty messy, so lets use PCA to simplfy the
% picture.  The first thing we want to do is use the
% autoscale function 'auto' since the variables span such a large
% size range. We'll have to tell autoscale to use a robust technique 
% with the data through the options.
 
aoptions = auto('options');
aoptions.algorithm = 'robust';
[ax,mx,stdx,msg] = auto(part1.data,aoptions);
 
% We can now plot the autoscaled data to see if that looks
% any better.
pause
%-------------------------------------------------
plot(ax);
title('Autoscaled Data for PCA example, Part 1')
xlabel('Time')
ylabel('Variable Values')
pause
%-------------------------------------------------
% If anything, this looks worse, so lets try out the pca modelling.
 
pause
%-------------------------------------------------
 
rpcaoptions = pca('options');
rpcaoptions.display = 'off';
rpcaoptions.plots = 'none';
rpcaoptions.algorithm = 'robustpca';
rpcaoptions.preprocessing = {[]};
 
% In this data set 4 principal components is a good choice.
% If you want to make a comparison with the classical pca 
% set the options 'algorithm' in the functioncall equal to 'svd'.
pause
%-------------------------------------------------
 
part1auto = part1;
part1auto.data = ax;
rpcamodel = pca(part1auto,4,rpcaoptions);
 
pause

%-------------------------------------------------
% We now have a PCA model with 4 PCs.  We might
% also want to look at some of the scores vectors plotted against
% each other.  We can do this using the 'plotscores' function.
pause
%-------------------------------------------------
 
plotscores(rpcamodel)
 
% In this plot, the outliers are marked in red and the included samples are
% in black. You can view pairs of scores, or view the T2 or Q values by
% selecting the appropriate line in the Plot Controls.
% Try ploting the first vs. second PCs and some other combinations.
% You can also do 3-D plots using 3 of the PCs. The routine 
% will plot them with the sample number if you want, but it is 
% pretty messy!
 
pause
%-------------------------------------------------
plotloads(rpcamodel)
 
% Now say that we'd like to compare the data from part2 to
% the data from part 1 using the PCA model from part1.
% The first step is to use the same scaling with the part 2 data.
 
spart2 = scale(part2.data,mx,stdx);
 
pause
%-------------------------------------------------
% Note how we have used the means and standard deviations from
% part1 to scale part2.  We can now use the 'pcapro' function
% to compare the data sets.
 
pause
%-------------------------------------------------
[newscores,resids,tsqs] = pcapro(spart2,rpcamodel,1);
 
pause
%End of RPCADEMO
%
%See also: ROBPCA, RPCR
 
echo off
