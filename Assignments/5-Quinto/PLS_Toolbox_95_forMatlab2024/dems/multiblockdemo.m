echo on
%MULTIBLOCKDEMO Demo of the Multiblock function
 
echo off
%Copyright Eigenvector Research, Inc. 2015
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The MULTIBLOCK function is used to create or apply a multiblock model for
%  joining data. Multiple block data joining allows for two or more
%  datasets and or models to be joined and modeled. Model fields (e.g.,
%  Scores) are extracted into a dataset before joining.
%  
%  The Multiblock function is specific to joining data as new variables. It
%  will use information contained in each dataset to complete a join.
%
%  In a simple case where 2 or more datasets have matching sample names,
%  only the matching samples will be joined.
 
lbl = str2cell(sprintf('Row %d \n',[1:30]));

a = dataset(rand(20));
a.label{1} = lbl(11:end);


b = dataset(rand(30));
b.label{1} = lbl;
 
c = dataset(rand(10));
c.label{1} = lbl(11:20);

opts = multiblock('options');
[mbmod, joined_data] = multiblock({a b c},opts);

%Joined data will be 10 samples (11-20) with 60 variables.
size(joined_data)
joined_data.label{1}

pause
%-------------------------------------------------
% We can use the Multiblock model to join new data with the same label
% structure.
 
d = dataset(rand(20));
d.label{1} = lbl(11:end);
 
e = dataset(rand(30));
e.label{1} = lbl;
 
f = dataset(rand(10));
f.label{1} = lbl(10:19);%Change label indexing by one.
 
new_joined_data = multiblock({d e f},mbmod);
 
%Joined data will be 9 samples (11-19) since we changed sample naming by
%one space with 60 variables.
 
size(new_joined_data)
new_joined_data.label{1}
 
pause
%-------------------------------------------------
% Now lets simulate data with a time axisscale. Perhaps we have a process
% where IR Data collected every few minutes and Mass Spec data is
% collected at a much higher frequency every few seconds. Notice that we
% also introduce a small offset in the start and end of the sample
% collection (using first and second arguments to linspace).
%  
 
IRDS1 = dataset(rand(100,1000));
IRDS1.name = 'IR Data 1';
IRDS1.axisscale{1} = now+linspace(0,200,100)/24/60;
 
IRDS2 = dataset(rand(200,1000));
IRDS2.name = 'IR Data 2';
IRDS2.axisscale{1} = now+linspace(4,405,200)/24/60;
 
MSDS1 = dataset(rand(3000,50));
MSDS1.name = 'MS Data 1';
MSDS1.axisscale{1} = now+linspace(0,200,3000)/24/60;
 
MSDS2 = dataset(rand(3100,50));
MSDS2.name = 'MS Data 2';
MSDS2.axisscale{1} = now+linspace(4,205,3100)/24/60;
 
opts = multiblock('options');
[mbmod, joined_data] = multiblock({IRDS1 MSDS1 IRDS2 MSDS2},opts);

pause
%-------------------------------------------------
% Notice that we should expect the joined data to have a little less than
% 100 samples since that was our lowest frequency of collection and we had
% an offset (thereby dropping some samples at the beginning).
 
size(joined_data) %Expecting roughly 95 samples.
 
pause
%-------------------------------------------------
% Also notice that order of joining is preserved and that classes have been
% assigned to the variables relating them to the original data.
 
joined_data.name
 
joined_data.classlookup{2}
 
pause
%-------------------------------------------------
% Which IR Dataset is used as the low frequency data for basis of binning?
% Information is stored in .userdata field of joined_data:

joined_data.userdata.bin2scale.LF_datasource
 
pause
%-------------------------------------------------
% A model can also be joined to data. Fields in the model must be
% specified or a prompt will appear. 

ir_mod = pca(IRDS1,3,struct('display','off','plots','none'));

%Get default model fields.
[ir_fields] = getmodeloutputs(ir_mod,0);

ms_mod = pca(MSDS1,5,struct('display','off','plots','none'));

%Get default model fields.
[ms_fields] = getmodeloutputs(ms_mod,0);

%Add defalt fields to the multiblock options. Note the order of fields
%depends on the input. 
opts = multiblock('options');
opts.filter = {'' '' ms_fields ir_fields};
 
[mbmod, joined_data] = multiblock({IRDS1 MSDS1 ms_mod ir_mod},opts);
 
pause
%-------------------------------------------------
% Note the joined data will again be a little less than 100 samples with
% 1000 IR variables, 50 MS variables, 4 IR model fields and 6 MS model
% fields to make a total of 1060 variables.

size(joined_data)
 
pause
%-------------------------------------------------
% Monotonic axis scales will also be joined similar to time axis scales.
% This might be used in a situation where your axisscale is equally spaced
% (and increasing or decreasing) but not necessarily a timestamp.
 
a = dataset(rand(100,1000));
a.axisscale{1} = linspace(0,200,100);
 
b = dataset(rand(3000,50));
b.axisscale{1} = linspace(0,200,3000);
 
opts = multiblock('options');
 
[mbmod, joined_data] = multiblock({a b},opts);
 
pause
%-------------------------------------------------
% After you join data you may wish to automate joining new data and
% applying a model. To apply a model, add it to the .post_join_model option
% field. Below we'll create a model on our joined calibration data and add
% it to the options structure so it's automatically applied when we join
% new data. 
 
%Re-join the example data.
[mbmod, joined_data] = multiblock({IRDS1 MSDS1 IRDS2 MSDS2},opts);

%Create a simple PCA model on the joined data.
postJoinModel = pca(joined_data,4,struct('display','off','plots','none'));

%Add a post join model to multiblock model.
mbmod = multiblock(mbmod,postJoinModel); 
 
%Apply multiblock model to new data.
[joined_data_new, new_data_pred] = multiblock({IRDS1 MSDS1 IRDS2 MSDS2},mbmod);

pause
%-------------------------------------------------
% 


%End of MULTIBLOCKDEMO
 
echo off
