function roc = plsdaroc(model,ycol,options)
%PLSDAROC Calculate and display ROC curves for PLSDA model.
% ROC curves can be used to assess the specificity and sensitivity possible
%  with different predicted y-value thresholds for a PLSDA model.
%
% INPUTS:
%   model = PLSDA model.
%    ycol = an optional index into the y-columns  used in the model (ycol)
%           [default = all columns], optional
% options = structure which can include the following fields:
%     plots:  [ 'none' | {'final'}]    governs plotting on/off
%     figure: [ 'new' | 'gui' | figure_handle ] governs location for plot. 'new'
%               plots onto a new figure. 'gui' plots using noninteger
%               figure handle. A figure handle specifies the figure onto
%               which the plot should be made.
%     plotstyle: [ 'roc' | 'threshold' | {'all'} ] governs type of plots.
%                'roc' and 'threshold' give only the specified type of
%                plot. 'all' shows both types of plots on one figure (default).
%                Plot style can also be specified as 1 (which gives 'roc'
%                plots) or 2 (which gives 'threshold' plots)
%    showauc: [{'on'} | 'off'] Controls drawing AUC value on ROC plot.
%             Note, clicking on the AUC text in the plot will remove it.
%
% OUTPUTS:
%  roc = dataset with the sensitivity/specificity data.
%       If model does not contain crossvalidation details then:
%         roc(:, k) = specificity/sensitivity if k is odd/even.
%       If model contains crossvalidation details then:
%         roc(:, k) = specificity/sensitivity of predictions if mod(k,4) = 1/2, or
%                     specificity/sensitivity of CV predictions if mod(k,4) = 3/4.
%       The number of rows equals the number of unique predicted y values.
%
%I/O: roc = plsdaroc(model,ycol,options)
%
%See also: DISCRIMPROB, PLSDA, PLSDTHRES, SIMCA

%Copyright Eigenvector Research 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 5/04
%jms 6/20/04 -show class associated with each y column
%jms 6/28/04 -hide NaN warnings
%jms 8/9/04  -fix bug when two samples have same predicted value
%    -adjust axes scale
%rsk 02/28/05 -Add nonint figure options to help manage windows with
%             -analysis.
%jms 08/16/05
%    -allow use of prediction structure for ROC curves
%    -use linear interpolation for non-measured intermediate threshold values
%    -don't hide numbertitle for non-gui call
%    -fixed mixed up order of axes on ROC curve
%jms 9/1/05
%    -fixed selection of which threshold to display when ycol is specified
%    -added 'plotstyle' option to show only ROC or THRESHOLD plots (default
%      is 'all')
%jms 9/05
%    -test for no positive or no negative samples and do not allow divide
%       by zero (just fill in NaNs)

if nargin == 0; model = 'io'; end
if ischar(model);
  options = [];
  options.name  = 'options';
  options.plots = 'final';  %'none' 'final'
  options.figure = 'new';
  options.plotstyle = 'all'; %'roc','threshold','both'
  options.showauc = 'on';    % write AUC value on plot
  if nargout==0; evriio(mfilename,model,options); else; roc = evriio(mfilename,model,options); end
  return;
end

switch nargin
  case 1
    % (model)
    options = [];
    ycol    = [];
  case 2
    % (model,ycol)
    % (model,options)
    % (figure,'stringcommand')
    if ~ismodel(model)
      % (figure,'stringcommand')
      feval(ycol,model)
      return
    end
    if isa(ycol,'struct');
      options = ycol;
      ycol    = [];
    else
      options = [];
    end
end
options = reconopts(options,'plsdaroc');

if ~ismodel(model) | ~ismember(lower(model.modeltype),{'plsda' 'plsda_pred' 'anndlda' 'anndlda_pred'})
  error('Input MODEL must be a standard PLSDA model structure');
end

%translate options.plotstyle numbers to strings
if ~isstr(options.plotstyle) & ~isempty(options.plotstyle)
  switch options.plotstyle
    case 1
      options.plotstyle = 'roc';
    case 2
      options.plotstyle = 'threshold';
    otherwise
      options.plotstyle = 'all';
  end
end

%grab info from model
pred    = model.pred{2};
y       = model.detail.data{2};
classes = model.detail.class{2,2};
classlookup = model.detail.classlookup{2,2};
thresholds = model.detail.threshold;

%if an actual model, grab cross-validation info
if ~ismember(lower(model.modeltype),{'plsda_pred','anndlda','anndlda_pred'})
  nlvs    = size(model.loads{2,1},2);
  cvpred  = model.detail.cvpred;
  
  %isolate the "correct" cvpred for the given # of factors
  if ~isempty(cvpred)
    cvpred = cvpred(:,:,nlvs);
  end
  estname = 'Estimated';
else
  %prediction from model, no cross-validation
  cvpred = [];
  estname = 'Predicted';
end

incl = y.include;

% Exclude samples where y is not known
yisknown = any(~isnan(y.data(incl{1},:)),2);
incl{1} = incl{1}(yisknown);

%see if the user specified the y-columns to view
if isempty(ycol)
  ycol = 1:length(incl{2});
end

lbl = {};
lbl2 = {};
allroc = [];
allthres = [];
for j = ycol;
  
  if ~isempty(classes);
    suffix = sprintf('(%s)',classlookup{[classlookup{:,1}]==classes(j),2});
  else
    suffix = [];
  end
  
  totalpos = sum(y.data(incl{1},incl{2}(j)));
  totalneg = length(incl{1})-totalpos;
  
  %calculate ESTIMATED (i.e. self-predicted) ROC
  [thres,order] = sort(pred(incl{1},incl{2}(j)));
  thres = thres+[diff(thres)/2;0];
  use           = incl{1}(order);
  %column 1 is specificity column 2 is sensitivity
  if totalneg>0;
    roc(:,1) = cumsum(~y.data(use,incl{2}(j)))/totalneg;
  else
    roc(:,1) = ones(length(use),1)*nan;
  end
  if totalpos>0;
    roc(:,2) = 1-cumsum(y.data(use,incl{2}(j)))/totalpos;
  else
    roc(:,2) = nan;
  end
  lbl = [lbl {sprintf('1-Specificity Y%i %s',incl{2}(j),suffix) sprintf('Sensitivity Y%i %s',incl{2}(j),suffix)}];
  lbl2 = [lbl2 {sprintf('Specificity Y%i %s',incl{2}(j),suffix) sprintf('Sensitivity Y%i %s',incl{2}(j),suffix)}];
  
  [allroc,allthres] = combineroc(allroc,allthres,roc,thres);
  
  if ~isempty(cvpred);
    %calculate CROSS-VALIDATED ROC
    [cvthres,order] = sort(cvpred(incl{1},incl{2}(j)));
    
    %Drop bad values
    bad        = ~isfinite(cvthres);
    cvthres(bad) = [];
    order(bad)   = [];
    
    use             = incl{1}(order);
    totalpos = sum(y.data(use,incl{2}(j)));  %may be different if we filtered some bad values
    totalneg = length(use)-totalpos;
    %     cvroc           = [cumsum(~y.data(use,incl{2}(j)))/totalneg 1-cumsum(y.data(use,incl{2}(j)))/totalpos];
    if totalneg>0;
      cvroc(:,1) = cumsum(~y.data(use,incl{2}(j)))/totalneg;
    else
      cvroc(:,1) = ones(length(use),1)*nan;
    end
    if totalpos>0;
      cvroc(:,2) = 1-cumsum(y.data(use,incl{2}(j)))/totalpos;
    else
      cvroc(:,2) = nan;
    end
    
    [allroc,allthres] = combineroc(allroc,allthres,cvroc,cvthres);
    lbl = [lbl {sprintf('CV 1-Specificity Y%i %s',incl{2}(j),suffix) sprintf('CV Sensitivity Y%i %s',incl{2}(j),suffix)}];
    lbl2 = [lbl2 {sprintf('CV Specificity Y%i %s',incl{2}(j),suffix) sprintf('CV Sensitivity Y%i %s',incl{2}(j),suffix)}];
  end
  
end

roc = allroc;
thres = allthres;

if strcmp(options.plots,'final');
  if ishandle(options.figure)
    figure(options.figure);
    clf;
  else
    if strcmp(options.figure,'gui')
      %Use noninteger handle so figs don't get crossed when using Analysis.
      ihandle = 'off';
      numbertitle = 'off';
    else
      ihandle = 'on';
      numbertitle = 'on';
    end
    figure('IntegerHandle', ihandle,'Name','Threshold/Roc Plot','NumberTitle',numbertitle)
  end
  rows = length(ycol);
  
  if strcmp(options.plotstyle,'all');
    cols = 2;
  else
    cols = 1;
  end
  
  cmh = findobj(gcf,'tag','axescontext');
  if isempty(cmh) | ~ishandle(cmh);
    cmh = uicontextmenu;
    set(cmh,'tag','axescontext');
    uimenu(cmh,'label','Spawn Full-Size','callback','spawnaxes');
  end
  set(gcf,'windowbuttondownfcn','plsdaroc(gcbf,''windowbuttondownfcn'');');
  
  for j = 1:length(ycol);
    
    if ~strcmp(options.plotstyle,'threshold');
      %Do ROC style plot
      subplot(rows,cols,(j-1)*cols+1)
      set(gca,'uicontextmenu',cmh);
      
      if ~isempty(thresholds)
        targpoint = findindx(thres,thresholds(ycol(j)));
      end
      
      if ~isempty(cvpred)
        h = plot((1-roc(:,(j-1)*4+1)),roc(:,(j-1)*4+2),'b.-',(1-roc(:,(j-1)*4+3)),roc(:,(j-1)*4+4),'g.-');
        legendname(h,{estname 'Cross-Validated'});
        hold on
        if ~isempty(thresholds)
          wrn = warning;
          warning off;
          xy1 = interp1(thres,roc(:,[(j-1)*4+1 (j-1)*4+2]),thresholds(ycol(j)),'linear');
          xy2 = interp1(thres,roc(:,[(j-1)*4+3 (j-1)*4+4]),thresholds(ycol(j)),'linear');
          warning(wrn);
          h = plot(1-xy1(1),xy1(2),'ro',1-xy2(1),xy2(2),'ro');
          legendname(h,{'Model Threshold'});
        end
        if j==1
          auc = getauc(roc);
          title(sprintf('%s (blue) and Cross-Validated (green) ROC', estname));
        end
        if strcmp(options.showauc, 'on')
          txtmsg = sprintf('AUC = %4.4f (C) / %4.4f (CV)', auc(1+2*(j-1)), auc(2+2*(j-1)));
          text(0.99, 0.0, txtmsg, 'VerticalAlignment', 'Bottom', 'HorizontalAlignment', 'Right', ...
            'FontSize', getdefaultfontsize-2, 'buttondownfcn', 'delete(gcbo)')
        end
        ylabel(lbl{(j-1)*4+2});
        xlabel(lbl{(j-1)*4+1});
      else
        h = plot(1-roc(:,(j-1)*2+1),roc(:,(j-1)*2+2),'.-');
        legendname(h,estname);
        hold on
        if ~isempty(thresholds)
          wrn = warning;
          warning off;
          xy1 = interp1(thres,roc(:,[(j-1)*2+1 (j-1)*2+2]),thresholds(ycol(j)),'linear');
          warning(wrn);
          h = plot(1-xy1(1),xy1(2),'ro');
          legendname(h,'Model Threshold');
        end
        if j==1
          auc = getauc(roc);
          title(sprintf('%s ROC ', estname));
        end
        if strcmp(options.showauc, 'on')
          txtmsg = sprintf('AUC = %4.4f', auc(j));
          text(0.99, 0.0, txtmsg, 'VerticalAlignment', 'Bottom', 'HorizontalAlignment', 'Right',...
            'FontSize', getdefaultfontsize-2, 'buttondownfcn', 'delete(gcbo)')
        end
        
        ylabel(lbl{(j-1)*2+2});
        xlabel(lbl{(j-1)*2+1});
      end
      axis([0 1.1 0 1.1]);
      legendname([ hline(0,'k'); vline(0,'k')],'Zero');
      legendname([ hline(1,'k'); vline(1,'k')],'Unity');
      legendname([ dp('k--') ],'50%');
      grid on
      set(h,'linewidth',2);
    end
    
    if ~strcmp(options.plotstyle,'roc');
      %Do Sens and Spec vs. threshold plot
      subplot(rows,cols,(j-1)*cols+cols)
      set(gca,'uicontextmenu',cmh);
      if ~isempty(cvpred)
        h = plot(thres,roc(:,(j-1)*4+1),'b-',thres,roc(:,(j-1)*4+2),'r-',...
          thres,roc(:,(j-1)*4+3),'b--',thres,roc(:,(j-1)*4+4),'r--');
        legendname(h,lbl2((j-1)*4+[1:4]));
        if j==1; title({[estname ' (Solid) and ' 'Cross-Validated (Dashed) Responses']}); end
        xlabel('Threshold (Y predicted)')
        ylabel({[lbl2{(j-1)*4+1} ' (blue)'] [lbl2{(j-1)*4+2} ' (red)']});
      else
        h = plot(thres,roc(:,(j-1)*2+1),'b-',thres,roc(:,(j-1)*2+2),'r-');
        legendname(h,lbl2((j-1)*2+[1:2]));
        if j==1; title([ estname ' Responses']); end
        xlabel('Threshold (Y predicted)')
        ylabel({[lbl2{(j-1)*2+1} ' (blue)'] [lbl2{(j-1)*2+2} ' (red)']});
      end
      if ~isempty(thresholds)
        h = vline(thresholds(ycol(j)),'r--');
        legendname(h,'Model Threshold');
      end
      grid on
      set(h,'linewidth',2);
    end
    
  end
end

if nargout>0;
  %make dataset of roc
  roc = dataset(roc);
  roc.userdata.auc = getauc(roc.data);
  roc.axisscale{1}     = thres;
  roc.axisscalename{1} = 'Threshold';
  roc.label{1}         = num2str(thres);
  roc.labelname{1}     = 'Threshold';
  roc.label{2}         = lbl;
else
  clear roc
end

%--------------------------------------------------------------
function [allroc,allthres] = combineroc(allroc,allthres,roc,thres)

%drop duplicate thresholds and take higher ROC value for those points
[thres,use] = unique(thres);
roc = roc(use,:);
if size(roc,1)==1
  %if all the thresholds were the same, we end up with ONE row here
  %indicating this is invalid probability curve - store placeholder info.
  if isempty(allroc)
    %first one we're saving (AND it is empty)
    allroc = roc;
    allthres = unique(thres);
  else
    %previously saved rows exist - make this match using repmat
    allroc = [allroc repmat(roc,size(allroc,1),1)];
  end
  return
end

if isempty(allroc);
  %first one we're storing
  allthres = unique(thres);
  allroc = interp1(thres,roc,allthres);
  return
end

wn = warning;
warning off
threscomb = unique([allthres; thres]);
if length(allthres)>1
  %allthres looks normal
  allroc    = interp1(allthres,allroc,threscomb,'linear',nan);
else
  %up until now, all stored ROCs have been a single value without valid
  %information so just replicate what is just NaNs
  allroc    = repmat(allroc,length(threscomb),1);
end
roc       = interp1(thres,roc,threscomb);
allroc    = [allroc roc];
allthres  = threscomb;
warning(wn)


%-----------------------------------------------------------------
function windowbuttondownfcn(targfig)

if strcmp(get(targfig,'selectiontype'),'open');
  %double-click
  set(gca,'linewidth',.5);
  spawnaxes;
else
  %single-click
  if isempty(findobj(allchild(targfig),'tag','doubleclicknotice'))
    %give double-click notice
    curax = get(targfig,'currentaxes');  %note current axes so we can make them current again later
    noticeax = axes(...
      'visible','off',...
      'color',get(targfig,'color'),...
      'position',[1 0 .001 .001],...
      'tag','doubleclicknoticeaxes');
    notice = text(0,0,'Double-click axes to view in new window.');
    set(notice,...
      'horizontalalignment','right',...
      'VerticalAlignment','bottom',...
      'color',[.66 0 0],...
      'fontsize',10,...
      'tag','doubleclicknotice',...
      'buttondownfcn','delete(gcbo);');
    set(noticeax,'handlevisibility','off');
    set(targfig,'currentaxes',curax);   %reset current axes back to real ones
    
    %create timer to automatically clear notice after some period of time
    delobj_timer('doubleclicknoticetimer',notice,4);
  end
end
%--------------------------------------------------------------
function auc = getauc(rocdata)
% Calculate area under ROC curve(s).
% Input matrix should have pairs of columns, 1-specificity and sensitivity,
% where each pair defines an ROC curve.

if min(size(rocdata))==1 | ~isnumeric(rocdata)
  auc = NaN;
  return
end
m    = size(rocdata,1);
nroc = size(rocdata,2)/2;
auc = nan(1,nroc);

for iroc=1:nroc
  x1 = rocdata(:, 2*iroc-1);
  y1 = rocdata(:, 2*iroc);
  maskin    = ~isnan(x1);
  x1nn      = x1(maskin);
  y1nn      = y1(maskin);
  % ensure x ranges from 0 to 1
  if x1nn(1) > eps
    x1nn(1) = 0;
  end
  if x1nn(end) < 1-eps
    x1nn(end) = 1;
  end
  auc(iroc) = trapz(x1nn,y1nn);
end


