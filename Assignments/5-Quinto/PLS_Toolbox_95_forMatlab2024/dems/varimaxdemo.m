echo on
%VARIMAXDEMO Demo of the VARIMAX function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%nbg 1/23/04 removed varcap because the scores were not orthogonal
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The VARIMAX function can be used to perform an orthogonal rotation
 
load arch
arch.includ{1} = 1:63;             %keep only samples 1:63, 64:75 are test samples
 
options = pca('options')
 
options.display       = 'off';
options.plots         = 'none';
options.preprocessing = {preprocess('default','autoscale')};
 
% Construct a PCA model of the arch data set
 
model = pca(arch,4,options);
 
pause
%-------------------------------------------------
% Perform the VARIMAX rotation
 
vloads  = varimax(model.loads{2});  % perform VARIMAX rotation
 
pause
%-------------------------------------------------
% Note that the variamax loadings are orthogonal:
 
vloads'*vloads
 
pause
%-------------------------------------------------
% Next we'll get scores (vscores) on the rotated loadings (vloads). 
 
% Apply the model's preprocessing to all the data in arch and
% project the scaled data onto the rotated loadings (vloads).
 
datap   = preprocess('apply',model.detail.preprocessing{1},arch);
vscores = datap.data(1:63,:)*vloads;  % project autoscaled data onto vloads
%vscores = datap.data(1:63,:)/vloads'; % projection when vloads not orthogonal
 
pause
%-------------------------------------------------
% Examine the loadings on the first factor:
 
figure
subplot(2,1,1), bar(model.loads{2}(:,1)), set(gca,'xticklabel',char(arch.label{2,1}))
title('Loadings on Factor 1'), ylabel('PCA'), hline
subplot(2,1,2), bar(vloads(:,1)), set(gca,'xticklabel',char(arch.label{2,1}))
ylabel('VARIMAX'), hline
 
% The loadings on PC 1 from PCA captures differences between
%   Fe, Ti, Ba, Ca, Mn, Sr and Zr from K and Rb.
% The loadings for Factor 1 from the VARMIAX rotation captures differences between
%   Fe, Ti, Ca, Mn and Sr from Zr.
 
% The other loadings have changed quite a bit too!
 
pause
%-------------------------------------------------
% Examine the scores on the first factor:
 
figure
subplot(2,1,1)
plot(1:10,model.loads{1}(1:10,1),'o','markerfacecolor',[0 0 1]), hold on
plot(11:19,model.loads{1}(11:19,1),'sr','markerfacecolor',[1 0 0])
plot(20:42,model.loads{1}(20:42,1),'dg','markerfacecolor',[0 0.5 0])
plot(43:63,model.loads{1}(43:63,1),'^k','markerfacecolor',[0.1 0.1 0.1]), hline
text([2 12 21 44],[2.8 2.8 2.8 1],char('K','BL','SH','ANA')), vline([10.5 19.5 42.5])
title('Scores on Factor 1'), ylabel('PCA')
subplot(2,1,2), plot(vscores(:,1)), xlabel('Sample Index')
plot(1:10,vscores(1:10,1),'o','markerfacecolor',[0 0 1]), hold on
plot(11:19,vscores(11:19,1),'sr','markerfacecolor',[1 0 0])
plot(20:42,vscores(20:42,1),'dg','markerfacecolor',[0 0.5 0])
plot(43:63,vscores(43:63,1),'^k','markerfacecolor',[0.1 0.1 0.1]), hline
text([2 12 21 44],[1 2.8 2.8 1],char('K','BL','SH','ANA')), vline([10.5 19.5 42.5])
ylabel('VARIMAX')
 
% The scores in PCA splits BL and SH from ANA w/ K ~in the middle.
% The scores from VARIMAX splits SH from K and ANA w/ BL ~in the middle.
 
pause
%-------------------------------------------------
% Other ways to examine the differences are given here. It is recommended
% that the user run this demo as "varimaxdemo", rather than "varimax demo"
% so that the data are available in the base workspace. Then the following
% tools can be explored:
 
% plotscores(model)            % plot the PCA scores {Note: options.sct = 1}
% plotscores(vscores,arch(1:63,:).label{1,1},arch(1:63,:).class{1,1}) % plot the rotated scores
 
% plotloads(model)                        % plot the PCA loadings
% plotloads(vloads,arch.label{2,1})       % plot the rotated loadings
 
%End of VARIMAXDEMO
 
echo off
