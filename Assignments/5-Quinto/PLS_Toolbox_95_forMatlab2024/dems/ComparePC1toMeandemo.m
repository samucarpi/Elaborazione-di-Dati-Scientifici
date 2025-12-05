% ComparePC1toMeandemo dDemo

% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.

h0  = figure('Name','Information','Color',[1 1 1]);
h1  = axes('visible','off','xlim',[0 1],'ylim',[0 1], ...
           'position',[0.05 0.05 0.875 0.9]);
h2  = text(0.01,0.95,{'ComparePC1toMeandemo Demo of the effect of mean-centering';
                     'in Principal Components Analysis (PCA) models.';
                     ' ';
                     'To run the demo hit a "return" after each pause'}, ...
                     'verticalalignment','top','interpreter','tex');
             
g0  = text(0.8,0.05,'paused','color',[0.8 0.2 0.2],'backgroundcolor',[1 1 1]); 
set(g0,'visible','on'), pause, set(g0,'visible','off')
p0  = get(h0,'position');

set(h2,'string', ...
{'This demo shows an example of the effect of data centering';
 'on the subsequent PCA model.';
 ' ';
 'The example uses a very simple 21x2 data set \bf{X}\rm that has a';
 'mean far from zero and a small ammount of variance.';
 ' ';
 'Recall that the objective in PCA is to maximize the capture of';
 'sum-of-squares (ssq) and the first PC captures the most ssq';
 'that can be captured by a single linear factor.';
 ' ';
 'The \its\rm^{2}_{tot} = (total ssq) consists of \its\rm^{2}_{mean} = (ssq due to the mean)';
 'and \its\rm^{2}_{err} = (ssq about the mean) such that';
 '              \its\rm^{2}_{tot} = \its\rm^{2}_{mean} + \its\rm^{2}_{err} ';
 ' ';
 'We will start Example I by making a plot of Data Set A';
 'that has mean [20, 11.6].'});
set(g0,'visible','on'), pause, set(g0,'visible','off')
 
% Load data
load arch
x         = arch.data(43:63,[1 5]);  % Use the ANN calibration data
[m,n]     = size(x);                 % X is MxN
x         = x*diag(1./std(x));       % Scale the data
x         = scale(x,0.2*mean(x));
xa        = x;
ncomp     = 1;                       % Number of PCs
 a        = [0 0.75 0.85 0.9 0.95 1];                % Fraction of mean removed for PCA
 aa       = linspace(0,1,length(a));                 % Fraction of mean removed for centering example
 cols     = [peaksigmoid([ 0.5 0.5 20],aa)+0.5;
             peakgaussian([1 0.5 0.25],aa);
             peaksigmoid([-0.5 0.5 20],aa)+0.5]';
          
% Mean-center
xmean     = mean(x);                 % The mean is 1xN
xmncn     = x - ones(m(1),1)*xmean;  % Mean-centering subtracts the mean
ssqm      = zeros(length(a),1);      % Sum-of-squares for mean of non-centered data
ssx       = sum(sum(x.^2));          % Sum-of-squares for non-centered data
ssqo      = sum(sum(xmncn.^2));      % Sum-of-squares for mean-centered data

%% Effect of Mean Centering Example I
  dataname = char('A','B','C','D','E','F');
for i1=1:length(aa)
  if i1==1
    h10   = figure('Name','Example I','position',p0+[10 -10 0 0]);
    hmn   = plot([0 xmean(:,1)],[0 xmean(:,2)],'-','linewidth',4,'color',[0.929 0.694 0.125]); hold on
    axis([-4 25 -2.5 15])
    grid, hline(0,'k'), vline(0,'k')
    xlabel('\it{x}\rm_1')
    ylabel('\it{x}\rm_2'), figfont
    legend(hmn,'Mean Vector','location','northoutside')
    legend('autoupdate','off')
    g         = text(-3,11,sprintf('The mean vector is plotted from \n0,0 to the mean at 20,11.6'), ...
                  'backgroundcolor',[1 1 1],'margin',0.5);
    gp        = text(18,-4,'paused','color',[0.8 0.2 0.2], ...
                  'backgroundcolor',[1 1 1],'interpreter','tex'); 
    set(gp,'visible','on')
    pause
    set(gp,'visible','off')    
    
    text(15,5.5,{'           % of \its\rm^{2}_{tot}';
               '      \its\rm^{2}_{mean}       on PC 1'}, ...
               'backgroundcolor',[1 1 1]*0.8,'interpreter','tex','margin',0.5)
    text(14,14.5,'\bfX\rm not centered','interpreter','tex')
  else
    figure(h10)
  end
  xmncn       = scale(x,aa(i1)*xmean);
  ssqm(i1,1)  = m(1)*sum(((1-aa(i1))*xmean).^2);               % ssq due to mean
  ssqm(i1,2)  = sum(sum(xmncn.^2));                            % ssq for x as data are centered
  ssqm(i1,3)  = 100*ssqm(i1,1)/ssqm(i1,2);                     % % ssq due to the mean as data are centered
  ssq         = pcaengine(xmncn,ncomp,struct('display','off'));
  ssqm(i1,4)  = ssq(1,3);                                      % eigenvalue 1 as data are centered
  
  h = plot(xmncn(:,1),xmncn(:,2),'o','color',cols(i1,:),'markerfacecolor',cols(i1,:));
  text(mean(xmncn(:,1))-2,mean(xmncn(:,2))+1.5,sprintf('%s',dataname(i1)),'color',cols(i1,:))
  if i1>1
    set(hmn,'Xdata',[0 (1-aa(i1))*xmean(1)],'Ydata',[0 (1-aa(i1))*xmean(2)])
  end
  if i1==6
    text(24.75,4-i1,sprintf('%s        %3.1f            %3.1f',dataname(i1), ssqm(i1,3:4)), ...
      'HorizontalAlignment','right','backgroundcolor',[1 1 1],'color',cols(i1,:), ...
      'backgroundcolor',[1 1 1]*0.8)
  else
    text(24.8,4-i1,sprintf('%s      %3.1f            %3.1f',dataname(i1), ssqm(i1,3:4)), ...
      'HorizontalAlignment','right','backgroundcolor',[1 1 1],'color',cols(i1,:), ...
      'backgroundcolor',[1 1 1]*0.8)
  end, drawnow
  
  switch i1
  case 1
    g.String  = {'Data Set A has a large';
                 '(sum-of-squares due to the mean):';
                 '\its\rm^{2}_{mean} = 1.12e4 and';
                 'low (ssq about the mean):';
                 '\its\rm^{2}_{err} = 40.'};
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  case 2
    g.String  = {'Data Set B has a smaller';
                 '\its\rm^{2}_{mean} = 0.72e4 because it';
                 'is closer to the origin but it has';
                 'the same low \its\rm^{2}_{err} = 40.'};
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  case 3
    g.String  = {'As the data moves towards 0,0 the';
                 '\its\rm^{2}_{mean} decreases but the';
                 '\its\rm^{2}_{err} doesnot change.'};
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  case length(aa)
    legend('off')
    g.String  = {'When the data mean is 0,0, as in';
                 'Data Set F, the data have been';
                 'mean-centered (\its\rm^{2}_{mean} = 0).';
                 'Note that "varince" \its\rm^{2} is';
                 'defined as \its\rm^{2} = \its\rm^{2}_{err}/(\itM\rm-1).'};
  otherwise
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  end
end
text(2,-1,'\bfX\rm mean-centered','interpreter','tex')
set(gp,'visible','on','string','paused, Example I completed', ...
  'position',gp.Position-[6 0 0])
pause

figure(h0) 
set(h2,'string', ...
{'It''s always amazing how much ssq is associated with the';
 'mean for data that have not been centered.';
 ' ';
 'PCA maximizes capture of ssq for preprocessed data';
 'about the model origin. For Data Set A, the origin';
 'was a long ways from [0,0].';
 ' ';
 'For Data Set F, the origin was at [0,0] and the data were';
 'mean-centered. In this special case, the PCA eigenvalues';
 'are proportional to variance captured.'},'interpreter','tex');
 set(g0,'visible','on'), pause, set(g0,'visible','off')
 
figure(h0) 
set(h2,'string', ...
{'Note that the % \its\rm^{2}_{tot} captured on PC 1 is > the % ';
 'captured by  \its\rm^{2}_{mean} and this needs a couple comments.';
 ' ';
 '1) The first PC, \bfp\rm_{1}, is not the mean. However, when \its\rm^{2}_{tot} in a ';
 '   non-centered data set is dominated by \its\rm^{2}_{mean}, \bfp\rm_{1} will point';
 '   in the direction of the mean. Recall that PCA captures ssq';
 '   for for preprocessed data about the model origin.';
 ' ';
 '2) The ssq on PC 1 is based on \bf{t}\rm_{1}\bf{p}\rm_{1}'' where \bft\rm_{1} = \bfX\rm\bfp\rm_{1}''';
 '   and is given by \its\rm^{2}_{1} = tr[(\bf{t}\rm_{1}\bf{p}\rm_{1}'')''(\bf{t}\rm_{1}\bf{p}\rm_{1}''].  In contrast,';
 '   \its\rm^{2}_{mean} = tr[(\bf1x\rm''_{mean})''(\bf1x\rm''_{mean})] where \bf1\rm is a vector of ones';
 '   and \bfx\rm_{mean} is the mean. Using \bf{t}\rm, instead of \bf1\rm provides,';
 '   more flexibility. The result is that \its\rm^{2}_{1} >= \its\rm^{2}_{mean}.'});
 set(g0,'visible','on'), pause, set(g0,'visible','off') 
 
figure(h0) 
set(h2,'string', ...
{'To emphasize some of the observations above, a similar analysis';
 'for Data Set E is shown next in Example II.';
 ' ';
 'In this case, the starting mean of the data is closer to 0,0';
 'and \its\rm^{2}_{tot} is less influence by the mean compared to';
 'Data Set A in Example I.'});
set(g0,'visible','on'), pause, set(g0,'visible','off') 
 
% Mean-center
x         = x - aa(end-1)*ones(m(1),1)*xmean;  % A --> E
xmean     = mean(x);                 % The mean is 1xN
xmncn     = x - ones(m(1),1)*xmean;  % Mean-centering subtracts the mean
ssqm      = zeros(length(a),1);      % Sum-of-squares for mean of non-centered data
ssx       = sum(sum(x.^2));          % Sum-of-squares for non-centered data
ssqo      = sum(sum(xmncn.^2));      % Sum-of-squares for mean-centered data
p         = zeros(n,length(aa));
%% Effect of Mean Centering Example II
  dataname = char('1','2','3','4','5','6');
for i1=1:length(a)
  if i1==1
    h20   = figure('Name','Example II','position',p0+[20 -20 0 0]);
    hmn   = plot([0 xmean(:,1)],[0 xmean(:,2)],'-','linewidth',4,'color',[0.929 0.694 0.125]); hold on
    axis([-4 22 -2.5 10])
    grid, hline(0,'k'), vline(0,'k')
    xlabel('\it{x}\rm_1')
    ylabel('\it{x}\rm_2'), figfont
    legend(hmn,'Mean Vector','location','northwest')
    legend('autoupdate','off')
    g      = text(-3,8,{'The mean vector is plotted from';'0,0 to the mean at 4,2.3'}, ...
                  'backgroundcolor',[1 1 1]);
    gp     = text(18,-4,'paused','color',[0.8 0.2 0.2], ...
                  'backgroundcolor',[1 1 1]);
    pause, set(gp,'visible','off')
    text(14.5,5.5,{'            % of \its\rm^{2}_{tot}';
               '      \its\rm^{2}_{mean}       on PC 1'}, ...
               'backgroundcolor',[1 1 1]*0.8,'interpreter','tex','margin',0.5)
    text(4,5,'\bfX\rm not centered','interpreter','tex')
  else
    figure(h20)
  end
  xmncn       = scale(x,a(i1)*xmean);
  ssqm(i1,1)  = m(1)*sum(((1-a(i1))*xmean).^2);                % ssq due to mean
  ssqm(i1,2)  = sum(sum(xmncn.^2));                            % ssq for x as data are centered
  ssqm(i1,3)  = 100*ssqm(i1,1)/ssqm(i1,2);                     % % ssq due to the mean as data are centered
  [ssq,dk,loads] = pcaengine(xmncn,ncomp,struct('display','off'));
  p(:,i1)     = loads(:,1);
  ssqm(i1,4)  = ssq(1,3);                                      % eigenvalue 1 as data are centered
  
  h = plot(xmncn(:,1),xmncn(:,2),'o','color',cols(i1,:),'markerfacecolor',cols(i1,:));
  text(mean(xmncn(:,1))-2,mean(xmncn(:,2))+1.5,sprintf('%s',dataname(i1)),'color',cols(i1,:))
  if i1>1
    set(hmn,'Xdata',[0 (1-aa(i1))*xmean(1)],'Ydata',[0 (1-aa(i1))*xmean(2)])
  end
  if i1<5
    text(23.29,5-i1,sprintf('%s        %3.1f            %3.1f',dataname(i1), ssqm(i1,3:4)), ...
      'HorizontalAlignment','right','backgroundcolor',[1 1 1],'margin',3,'color',cols(i1,:), ...
      'backgroundcolor',[1 1 1]*0.8)
  else
    text(23.29,5-i1,sprintf('%s          %3.1f            %3.1f',dataname(i1), ssqm(i1,3:4)), ...
      'HorizontalAlignment','right','backgroundcolor',[1 1 1],'margin',3,'color',cols(i1,:), ...
      'backgroundcolor',[1 1 1]*0.8)
  end
  drawnow
  
  switch i1
  case 1
    g.String  = {'Data Set 1 the same as Data Set E shown previously';
                 'and has sum-of-squaresdue to the mean of (449)';
                 'and ssq about the mean (40).'};
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  case 2
    g.String  = {'Data Set 2 has a smaller sum-of-squares';
                 'due to the mean (28) is much smaller but';
                 'the same low ssq about the mean (40).'};
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  case 3
    g.String  = {'As the data moves towards 0,0 PC 1 moves';
                 'away from the mean and towards PC 1 of';
                 'the centered data.'};
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  case length(aa)
    legend('off')
    g.String  = {'As \itf\rm = \its\rm^{2}_{tot}/\its\rm^{2}_{err}';
                 'decreases the more PC 1 looks like the mean.'};
  otherwise
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  end
end
text(2,-1,'\bfX\rm mean-centered','interpreter','tex')
set(gp,'visible','on','string','paused in Example II', ...
  'position',gp.Position-[6 0 0])
pause, set(gp,'visible','off')

figure(h0) 
set(h2,'string', ...
{'The data sets were plotted on the same scale as the first';
 'example to allow an easy comparison of the two examples.';
 'In this example, the ratio of';
 '   \itf\rm = \its\rm^{2}_{tot}/\its\rm^{2}_{err}';
 'is lower than in the first example.';
 ' ';
 'It is observed that as \itf\rm increases the more PC 1';
 'will look like the mean and this should make intuitive'
 'sense because PC 1 maximizes capture of ssq about the';
 'model origin.';
 ' ';
 'Additionally, to see this let''s plot the \bfx\rm_{mean} and \bfp\rm_{1}';
 'for each data set in this example.'});
set(g0,'visible','on'), pause, set(g0,'visible','off') 
 
xmenn     = normaliz(xmean)*1.2;
for i1=1:length(aa)
  if i1==1
    h13   = figure('Name','Loadings for Part II','position',p0+[-30 30 0 0]);
    hmn   = plot(1,1,'.','visible','off'); hold on
%     hmn   = plot([0 xmenn(:,1)],[0 xmenn(:,2)],'-','linewidth',4,'color',[0.9 0.64 0.1]); hold on
    axis([0 1 0 1]), axis square
    ah    = annotation('arrow',[.2112 .6395],[0.1079 0.4395],'Color',[0.9 0.64 0.1], ...
              'linewidth',4);
    xlabel('PC 1 Loadings on \it{x}\rm_1'), grid
    ylabel('PC 1 Loadings on \it{x}\rm_2'), figfont
    text(0.56,0.23,{'\itDirection\rm of',' the Mean'},'color',[0.9 0.64 0.1], ...
      'backgroundcolor',[1 1 1]*0.9)
    g     = text(0.05,0.8,{'The scaled mean vector is plotted in the';
                           '\itDirection\rm of the mean'}, ...
                           'interpreter','tex','backgroundcolor',[1 1 1]);
    gp    = text(0.8,-0.08,'paused','color',[0.8 0.2 0.2],'backgroundcolor',[1 1 1]);  
    pause, set(gp,'visible','off')
  else
    figure(h13)
  end
  h   = plot([0 p(1,i1)],[0 p(2,i1)],'-','color',cols(i1,:));
  text(p(1,i1)*1.025,p(2,i1)*1.025,dataname(i1))
    
  switch i1
  case 1
    g.String  = {'Data Set 1 is Data Set E shown priviously';
                 'and has \its\rm^{2}_{mean} = 449';
                 'and \itf\rm = \its\rm^{2}_{err} = 40'};
    title('Loadings on \bf{p}\rm_1','interpreter','tex')
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  case 2
    g.String  = {'Data Set g has a smaller \its\rm^{2}_{mean} = 28';
                 'but the same low \itf\rm = \its\rm^{2}_{err} = 40'};
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  case 3
    g.String  = {'As the data moves towards 0,0 PC 1 moves';
                 'away from the mean and towards PC 1 of';
                 'the centered data'};
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  case length(a)
    legend('off')
    g.String  = {'Therefore, as ';
                 '\itf\rm = \its\rm^{2}_{tot}/\its\rm^{2}_{err}';
                 'increases, the more PC 1';
                 'looks like the mean.'};
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  otherwise
    set(gp,'visible','on'), pause, set(gp,'visible','off')
  end
end
set(gp,'visible','on','string','paused, Example II completed', ...
  'position',[0.63 0.06 0])
set(g0,'visible','on'), pause, set(g0,'visible','off') 

%%Example III
ab        = 1-logspace(-8,-1,1000);
ssq3      = zeros(length(ab),4);
xmean     = mean(xa);
xmenn     = normaliz(xmean);
ssq0      = sum(sum(mncn(xa).^2));
 
for i1=1:length(ab)
  xmncn       = scale(xa,ab(i1)*xmean);
  ssq3(i1,1)  = m(1)*sum(((1-ab(i1))*xmean).^2);     % ssq due to mean
  ssq3(i1,2)  = sum(sum(xmncn.^2));                  % ssq for x as data are centered
  ssq3(i1,3)  = ssq3(i1,1)/ssq0;          % (ssq due to the mean)/(ssq about the mean)/
  [ssq,dk,loads] = pcaengine(xmncn,ncomp,struct('display','off'));
  ssq3(i1,4)  = acos(xmenn*loads(:,1))*180/pi;       % angle between mean and PC 1
end
h13       = figure('Name','Example I','position',p0+[40 -40 0 0]);
h         = plot(ssq3(:,3),ssq3(:,4),'linewidth',4);
axis([0 2.75 0 15]), grid
fstat     = ftest(0.05,size(x,1),size(x,1)-1);
hline(ssq3(findindx(ssq3(:,3),fstat),4),'r')
set(vline(fstat,'r'),'ydata',[0 10])
uistack(h,'top')
title('Angle Between PC 1 and The Mean')
xlabel('\itf\rm = \its\rm^{2}_{mean}/\its\rm^{2}_{err}','interpreter','tex')
ylabel('Angle Between \bfx\rm_{mean} and \bfp\rm_{1} (degrees)')
figfont
text(0.3,13,{'The maximum angle between PC 1 and';
             'the mean is 14.9 degrees when \itf\rm = 0.';
             'The angle is 1.1 degrees when \itf\rm = 2.1 (= \itf\rm_{95% CL})'}, ...
             'interpreter','tex','backgroundcolor',[1 1 1])
gp    = text(02.5,-1,'paused','color',[0.8 0.2 0.2], ...
                  'backgroundcolor',[1 1 1]);  
pause, set(gp,'visible','off')


figure(h0) 
set(h2,'string', ...
{'The example clearly shows that PC 1 does not generally';
 'point in the direction of the mean for non-centered data.';
 'However, as expected, as the ratio';
 '   \itf\rm = \its\rm^{2}_{tot}/\its\rm^{2}_{err}';
 'increases, the angle between PC 1 and the mean decreases.';
 ' ';
 'When \itr\rm > 2.1, the angle between PC 1 and the mean';
 'was small for this example (i.e., they point in nearly';
 'the same direction when \itr\rm > 2.1).'}, ...
 'interpreter','tex','backgroundcolor',[1 1 1]);
set(g0,'visible','on')
g0.String = 'Example Completed';
g0.Position = [0.5 0.05 0];
 
disp(' ')
disp('ComparePC1toMeandemo completed.')
