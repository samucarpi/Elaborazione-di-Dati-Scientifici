function roc = roccurve(yknown, ypred, options)
%ROCCURVE Calculate and display ROC curve(s) for yknown and ypred.
% ROC curves can be used to assess the specificity and sensitivity for
%  different predicted y-value thresholds, for input y known and predicted.
% 
% INPUTS:
%     yknown: nx1 logical vector, or 
%             nx1 vector of only 0's and another integer, or
%             nxm logical vector, or
%             dataset object with sample (row) class converted to logical, or
%             with yknown.data a logical array.
%      ypred: nxm double array, m columns of y predictions
%    options: optional structure which can include the following fields:
%      plots: [ 'none' | {'final'}]    governs plotting on/off
%     figure: [ 'new' | 'gui' | figure_handle ] governs location for plot.
%               'new' plots onto a new figure. 'gui' plots using noninteger
%               figure handle. A figure handle specifies the figure onto
%               which the plot should be made.
%  plotstyle: [ 'roc' | 'threshold' | {'all'} ] governs type of plots.
%                'roc' and 'threshold' give only the specified type of
%                plot. 'all' shows both types of plots on one figure (default).
%                Plot style can also be specified as 1 (which gives 'roc'
%                plots) or 2 (which gives 'threshold' plots)
%  threshold: [ [] ] Threshold value(s) to draw vertical dashed red line
%                in Threshold plot(s) and place red circle(s) at on the ROC
%                curve(s).
%    showauc: [{'on'} | 'off'] Controls drawing AUC value on ROC plot.
%
% OUTPUTS:
%   roc = dataset with the sensitivity/specificity data. 
%         roc(:, k) = specificity/sensitivity if k is odd/even. roc has
%         2*m columns, with roc(:,(j-1)*2+1) = Specificity for column m of
%         ypred, and roc(:,(j-1)*2+2) = Sensitivity for column m of ypred. 
%         The number of rows equals the number of unique predicted y values.
%
% Cases:
% If yknown is nx1 logical vector and ypred is nxm, then m roc curves are 
% produced, one for each column of ypred. roc is a dataset nx(2*m), 
% containing column-pairs of Specificity and Sensitivity for each yknown 
% vs. ypred pairing.
% If yknown is nxm logical and ypred is nxm then m roc curves are produced, 
% one for each pair of yknown and its corresponding ypred column.  roc is a 
% dataset nx(2*m).
% If yknown is multi-column, nxm, and ypred has a different number of 
% columns, nxp, then an error is thrown.
%
%I/O: roc = roccurve(yknown, ypred, options)
%
%See also: PLSDAROC

%Copyright Eigenvector Research 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; yknown = 'io'; end
if ischar(yknown);
  options = [];
  options.name  = 'options';
  options.plots = 'final';  %'none' 'final'
  options.figure = 'new';
  options.plotstyle = 'all'; %'roc','threshold','both'
  options.threshold = [];    % draw dashed red line at this(these) threshold(s)
  options.showauc = 'on';    % write AUC value on plot
  if nargout==0; evriio(mfilename,yknown,options); else; roc = evriio(mfilename,yknown,options); end
  return;
end

switch nargin
  case 1
    error('Input must contain at least two parameters, y and ypred');
  case 2
    options = [];
end
options = reconopts(options,'roccurve');

% If it is not already logical then convert it so
if ~isa(yknown,'logical')
  if isdataset(yknown)
    if ~isempty(yknown.class{1})
      % if it is a DSO with non-empty sample classes then pass to class2logical
      % to convert sample classes to logical array
      yknown = class2logical(yknown);  %force to be logical
      yknown = yknown.data;
    elseif islogical(yknown.data)
      % just use the logical data
      yknown = yknown.data;
    else
      yknown = []; % Can't find yknown.
    end
  else
    % it is not a logical and is not a dataset. Just convert it.
    yknown = class2logical(yknown);  %force to be logical
    yknown = yknown.data;
  end
  
end

if size(yknown,1)~=size(ypred,1)
  error('Input known and predicted must have the same number of rows');
end

m  = size(yknown, 1);
nk = size(yknown, 2);
np = size(ypred, 2);

if nk ~= 1 & nk ~= np
  error('Input y known must be nx1 logical or have same number of columns as y pred');
end

ypcols = 1:np;  % number of ypreds input

%translate options.plotstyle numbers to strings
if ~ischar(options.plotstyle) & ~isempty(options.plotstyle)
  switch options.plotstyle
    case 1
      options.plotstyle = 'roc';
    case 2
      options.plotstyle = 'threshold';
    otherwise
      options.plotstyle = 'all';
  end
end

thresholds = options.threshold;
if ~isempty(thresholds) & numel(thresholds)<np
  thresholds = repmat(thresholds(1), size(ypcols));
end

estname = 'Predicted';
lbl = {};
lbl2 = {};
allroc = [];
allthres = [];
for j = 1:np;
  ypredcol = ypred(:,j);
  if nk==np
    yknowncol = yknown(:,j);     % must be single col yknown
    lbl = [lbl {sprintf('1-Specificity Y%i YP%i',j,j) sprintf('Sensitivity Y%i YP%i',j,j)}];
    lbl2 = [lbl2 {sprintf('Specificity Y%i YP%i',j,j) sprintf('Sensitivity Y%i YP%i',j,j)}];
  else
    yknowncol = yknown;     % must be single col yknown
    lbl = [lbl {sprintf('1-Specificity Y YP%i',j) sprintf('Sensitivity Y YP%i',j)}];
    lbl2 = [lbl2 {sprintf('Specificity Y YP%i',j) sprintf('Sensitivity Y YP%i',j)}];
  end
  [roc, thres] = roc1(yknowncol, ypredcol);
  
  [allroc,allthres] = combineroc(allroc,allthres,roc,thres);
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
  for j = 1:length(ypcols);
    if ~strcmp(options.plotstyle,'threshold');
      %Do ROC style plot
      subplot(np,cols,(j-1)*cols+1)
      set(gca,'uicontextmenu',cmh);
      
      if ~isempty(thresholds)
        targpoint = findindx(thres,thresholds(ypcols(j)));
      end
      % roc(:,k) = specificity if k is odd, sensitivity if k is even
      h = plot((1-roc(:,(j-1)*2+1)),roc(:,(j-1)*2+2),'.-');
      legendname(h,estname);
      hold on
      if ~isempty(thresholds)
        wrn = warning;
        warning off;
        xy1 = interp1(thres,roc(:,[(j-1)*2+2 (j-1)*2+1]),thresholds(ypcols(j)),'linear');
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
        text(0.99, 0.0, txtmsg, 'VerticalAlignment', 'Bottom', 'HorizontalAlignment', 'Right')
      end
      ylabel(lbl{(j-1)*2+2});
      xlabel(lbl{(j-1)*2+1});
      
      axis([0 1.1 0 1.1]);
      legendname([ hline(0,'k'); vline(0,'k')],'Zero');
      legendname([ hline(1,'k'); vline(1,'k')],'Unity');
      legendname([ dp('k--') ],'50%');
      grid on
      set(h,'linewidth',2);
    end
    
    if ~strcmp(options.plotstyle,'roc');
      %Do Sens and Spec vs. threshold plot
      subplot(np,cols,(j-1)*cols+cols)
      set(gca,'uicontextmenu',cmh);
      h = plot(thres,(roc(:,(j-1)*2+1)),'b-',thres,roc(:,(j-1)*2+2),'r-');
      legendname(h,lbl2((j-1)*2+[1:2]));
      if j==1; title([ estname ' Responses']); end
      xlabel('Threshold (Y predicted)')
      ylabel({[lbl2{(j-1)*2+1} ' (blue)'] [lbl2{(j-1)*2+2} ' (red)']});
      if ~isempty(thresholds)
        h = vline(thresholds(ypcols(j)),'r--');
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

%--------------------------------------------------------------------------
function [roc, thres] = roc1(yknowncol, ypredcol)
% Get roc curve quantities for yknown (logical) and ypred, each size nx1
nrow = size(yknowncol,1);
totalpos = sum(yknowncol);
totalneg = nrow -totalpos;

%calculate ESTIMATED (i.e. self-predicted) ROC
[thres,order] = sort(ypredcol);
thres = thres+[diff(thres)/2;0];

%column 1 is specificity column 2 is sensitivity
if totalneg>0;
  roc(:,1) = cumsum(~yknowncol(order))/totalneg;  % TN/N, specificity
else
  roc(:,1) = ones(length(order),1)*nan;
end
if totalpos>0;
  roc(:,2) = 1-cumsum(yknowncol(order))/totalpos; % 1-FN/P = TP/P, sensitivity
else
  roc(:,2) = nan;
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

