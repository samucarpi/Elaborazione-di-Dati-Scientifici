echo on
%SPLITCALTESTDEMO Demo of the SPLITCALTEST function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
%
% SPLITCALTEST is used to divide a dataset up into Calibration and Test
% sets. The goal is to divide the dataset in such a manner that the
% calibration set includes a very representative set of samples, such that
% a model built from this calibration set would be very similar to the 
% model built from the whole dataset.
%
% To use SPLITCALTEST you must first build a PCA or PLS model (or any model 
% which populates model.scores) using the dataset, specifying the desired
% number of principal components or latent variables, and preprocessing.
% SPLITCALTEST then splits the samples based on the scores from the input 
% model, returning a vector indicating sample membership of the calibration
% and test sets.
%
pause
%-------------------------------------------------
%
% To demonstrate SPLITCALTEST we use an 'xblock' dataset consisting of two
% distinct clusters of samples.
% We first build a PCA model using preprocessing appropriate to the data, 
% and the specify using 2 PCs.
%
nsamp = 400;
ncomp = 2;
xblock = dataset([rand(nsamp/2, 20); 2*rand(nsamp/2,20)]) ;
optspca = pca('options');
optspca.display = 'off';
optspca.plots   = 'none';
pre = preprocess('default','mean center');
optspca.preprocessing{1} = pre;
model = pca(xblock, ncomp, optspca);

% Next, apply SPLITCALTEST to the model, specifying that fraction=0.2 of
% the samples will be Calibration samples and the remainder will be Test.
% We first use the Kennard-Stone method to split the data set.
pause
%-------------------------------------------------
%  SPLITCALTEST using 'kennardstone' method
options = splitcaltest('options');
options.algorithm = 'kennardstone';
options.fraction = 0.2;
x = splitcaltest(model,options);

% The output from SPLITCALTEST is a struct object with two fields:
% x.class      : identifies whether a sample belongs to the Calibration 
%                 set (-1) or the Test set (-2).
% x.classlookup: provides labels for these classes.
%
% We could use this splitting of the dataset into calibration and test sets
% by adding the returned class to the dataset:
xblock.class{1} = x.class;
xblock.classname{1} = 'Cal/Test';

% We can now view the sample scores and the Cal/Test assignment:
%
pause
%-------------------------------------------------
%
scores = model.scores;

cal  = x.class ==-1;
test = x.class ==-2;
figure;plot(scores(test,1), scores(test,2), 'rv', 'MarkerFaceColor', 'r');hold on
plot(scores(cal,1), scores(cal,2), 'ko',  'MarkerFaceColor', 'k');
title(sprintf('Identification of Cal and Test sets using %s algorithm', options.algorithm))
xlabel('PC1');ylabel('PC2')
legend('Test', 'Cal') 

% This shows how calibration samples span both clusters and include the
% extreme samples. It is important to include the data extremes in the 
% calibration set if the model is to be similar to a model built from the 
% entire dataset.
%
pause
%-------------------------------------------------

% The splitting of the dataset is now repeated, using the 
% "Nearest Neighbor Thinning" algorithm ('reducennsamples')
pause
%-------------------------------------------------
%
%  SPLITCALTEST using 'reducennsamples' method
options = splitcaltest('options');
options.algorithm = 'reducennsamples';
options.fraction = .2;
x = splitcaltest(model,options);

% We could again use this splitting of the dataset into calibration and 
% test sets by adding the returned class to the dataset:
xblock.class{1} = x.class;
xblock.classname{1} = 'Cal/Test';

% Now view the sample scores and the Cal/Test assignment:
pause
%-------------------------------------------------
cal = x.class ==-1;
test = x.class ==-2;
figure;plot(scores(test,1), scores(test,2), 'rv', 'MarkerFaceColor', 'r');hold on
plot(scores(cal,1), scores(cal,2), 'ko',  'MarkerFaceColor', 'k');
title(sprintf('Identification of Cal and Test sets using %s algorithm', options.algorithm))
xlabel('PC1');ylabel('PC2')
legend('Test', 'Cal') 

% This also shows how calibration samples span both clusters. Both methods
% provide a Calibration data set which spans the entire data set but the 
% 'kennardstone' calibration samples are slightly more uniformly distributed 
% over the data. 
%
pause
%-------------------------------------------------
%
% Note:
% 1) If a matrix or DataSet are passed in place of a 
% model, it is assumed to contain the scores for the data. 
%
% A second example using a dataset object demonstrates the ability to keep
% replicated samples together during the splitting process.
%
% We use a dataset with size 500x2, 500 samples with 2 variables. The 
% samples consist of 250 paired replicates. The paired samples in a 
% replicate pair are made to be slightly different for convenience when 
% viewing the data. 

pause
%-------------------------------------------------
m = 250;          % number of replicated pairs of samples
n = 2;            % number of variables
k = 1/10;         % fraction of all samples to be assigned as calibration
usereplicate = 1;

% Set options for splitcaltest 
options = splitcaltest('options');
options.algorithm = 'kennardstone';
options.fraction = k; % fraction of data to be set to calibrations

if usereplicate
  options.usereplicates = 1;
  options.repidclass    = 1;
else
  options.usereplicates = 0;
  options.repidclass    = [];
end
 
% Generate a sample dataset
X0= 10*randn(m,n);
Xn = [X0; X0+ones(size(X0))];

% Create IDs for class identifying replicates
id=1:m; id = id';
id0 = [id; id];

repidclass = options.repidclass;
xdso = dataset(Xn);
if ~isempty(repidclass)
  xdso.classid{1, repidclass} = id0'; % dso with replicates ids as classset
end
 
% Now use splitcaltest on this dataset
pause
%------------------------------------
setassignment = splitcaltest(xdso,options);
xcal  = setassignment.class==(-1);
xtest = setassignment.class==(-2);
xzero = setassignment.class==(0);
echo off
disp(sprintf('There are %d total points', length(xcal)))
disp(sprintf('There are %d cal points', sum(xcal)))
disp(sprintf('There are %d test points', sum(xtest)))
disp(sprintf('There are %d excluded points', sum(xzero)))
disp(sprintf('m = %d, nrep = 2, k = %f', m, k))
echo on

x = xdso.data;
figure; 
        plot(x(xcal,1), x(xcal,2),'ks','markerfacecolor','k', 'markersize', 4);
        hold on;
        plot(x(xtest,1), x(xtest,2),'r.'); %hold on;
%         plot(x(xcal,1), x(xcal,2),'ks','markerfacecolor','k', 'markersize', 2);
title(sprintf('splitcaltest, with %s algorithm', options.algorithm)); 
legend('Cal', 'Test') 
disp('done')
 
% The two samples belonging to each replicate pair are both assigned to either 
% the Calibration or the Test set.

%End of SPLITCALTESTDEMO
echo off
