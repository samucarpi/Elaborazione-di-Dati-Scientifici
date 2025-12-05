echo on
%EXTERIORPTSDEMO Demo of the EXTERIORPTS function
 
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
% The EXTERIORPTS function is used to select the most unique samples (or
% variables) in a dataset. These are the points which are on the "exterior"
% of the data cloud and represent the most unique samples, from a
% multivariate points of view.
%  
% As an example, consider the Raman_Time_Resolved data which is a
% continuous reaction monitored by Raman.
% 
% The beginning of the data starts with starting materials, which go
% through an intermediate which then becomes the final product. If we look
% at the scores from a PCA model of this data, we see this trend.
 
pause
%-------------------------------------------------
 
load raman_time_resolved
 
m = pca(raman_time_resolved,2,struct('plots','none','display','off'));
scores = m.loads{1};
 
figure
plot(scores(:,1),scores(:,2),'o'), hold on
 
% The reaction starts with the points at the bottom right and progresses up
% to the top left.
 
pause
%-------------------------------------------------
% Call EXTERIORPTS - here that we are passing the ORIGINAL data, not the
% PCA scores. We are only using the scores plot to simplify the
% multidimentional space such that you can see what exteriorpts is doing.
% Exteriorpts is operating in the n-dimentional space of all data.
 
isel = exteriorpts(raman_time_resolved,3)  %select 3 points

% the three points selected are shown - we can superimpose these on the
% plot...
 
pause
%-------------------------------------------------
 
plot(scores(isel,1),scores(isel,2),'o','markerfacecolor',[0 0 1])
a    = '  '; a = [a(ones(length(isel),1),:), int2str(isel(:))];
text(scores(isel,1),scores(isel,2),a)
 
% The filled circles show the samples that were selected. Note that the
% first and last points were selected, since these represent the most
% chemically different samples, plus the third point is selected since this
% represents the sample with the largest amount of intermediate (relative
% to the other components).
 
%End of EXTERIORPTSDEMO
 
echo off
