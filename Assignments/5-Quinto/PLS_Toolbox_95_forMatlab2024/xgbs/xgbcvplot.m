function h0 = xgbcvplot(model, plotParams,fig)
%XGBCVPLOT Plot results of an XGB/XGBDA model parameter optimization search
% Produces a contour plot of the CV results of searching over XGB parameters
% for the optimal XGB parameter set. Inputs include (model) the model to
% plot.
% plotParams: cell array indicating the parameters over which to plot. The 
% plot uses the specified plotParams or over the first two available 
% parameter ranges if plotParams is not supplied.
%
% fig: Optional third input specifies the figure onto which the plot should be
% created. When omitted or empty [], new figure is opened.
%
% If the supplied model does not contain optimization search information,
% no plot is created and the output (fig) is empty.
%
% Example: h1 = xgbcvplot(model, {'eta' 'max_depth'})
% opens a new plot showing contour plot of rmsecv for gamma and epsilon ranges
%
%I/O: fig = xgbcvplot(model,plotParams,fig)

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isempty(model)
  %no model passed?
  if nargin<3
    error('Figure handle must be passed if no model is passed');
  end
  model = getappdata(fig,'model');
  if isempty(model)
    return
  end
end

if nargin <=2
  fig = [];
end

scan = model.detail.xgb.cvscan;
if isempty(scan)
  %nothing to plot
  if nargout==0; clear h0; end
  return
end

scanParams = fieldnames(scan.parameters);  % Scanned params
% scanParams order is: eta, max_depth,  
% This is as determined by default opts for xgbengine.
% This also identifies the dimensions in scan.cvValues.
scanParams = scanParams(:);

% set plotParams
inputPlotParams = 0;
if nargin==1 | ~exist('plotParams', 'var') | isempty(plotParams) | length(plotParams(:))<=1
  plotParams = scanParams; % set plotParams to all available
else
  % convert given plotParams to single char form
  inputPlotParams = 1;
%   plotParams = getSingleCharParams(plotParams(:));
%   plotParams = plotParams(:);
end

% set mask = 0 denoting singleton dimension in scan.cvValues
% don't plot dimensions with fewer than 2 values
npars = length(scanParams);
mask = logical(ones(npars,1));
for i=1:npars
  nvals = length(scan.parameters.(scanParams{i}));
  if nvals<2
    mask(i) = 0;   % remove dimensions with fewer than 2 values
  end
end

% handle repeat pressing of forward arrow on plot
presscount = 0;
if ~isempty(fig)
  presscount = updatepresscount(fig);
  setappdata(fig,'model',model);
end

% If the xgb model had y-preprocessing then the cv values (rmsecv) were calculated using preprocessed data
% Correct rmsecv by multiplying by std. dev.. Note, we can only correct in the case of 'Autoscale'.
if ~isclassification(scan.optimalArgs) ...
    & ~isempty(model.detail.preprocessing{2}) ...
    & strcmp(model.detail.preprocessing{2}.keyword, 'Autoscale') ...
    & ~isempty(model.detail.preprocessing{2}.out{2})
  stddev = model.detail.preprocessing{2}.out{2};
  scan.cvValues = scan.cvValues*stddev;
end

% Find intersection of plotParams and masked scanParams
scanMaskParams = scanParams(mask);
useParams  = intersect(plotParams, scanMaskParams);
nUse       = length(useParams);

% If input > 2 params just use the first two
if inputPlotParams & nUse>2
  useParams = useParams(1:2);
  nUse = 2;
end

if nUse < 1
  if nargout==0; clear h0; end
  h0 = [];
  return % only plots if there are two parameter ranges.
  
elseif nUse==1
  if nargout==0; clear h0; end
  h0 = [];
  return; % Currently only plots if there are two parameter ranges.
  
elseif nUse==2
  % contour plot as is, using first two parameters
  i1 = find(strcmpi(scanParams, useParams{1}));
  i2 = find(strcmpi(scanParams, useParams{2}));
  [zz ind1] = min(abs(scan.parameters.(scanParams{i1})-scan.best.(scanParams{i1}))); % index of best first param
  [zz ind2] = min(abs(scan.parameters.(scanParams{i2})-scan.best.(scanParams{i2}))); % index of best second param

  i3 = 6/(i1*i2);
  if ndims(scan.cvValues)==2
    plotfield = permute(scan.cvValues, [i1 i2]);
  elseif ndims(scan.cvValues)==3
    [zz ind3] = min(abs(scan.parameters.(scanParams{i3})-scan.best.(scanParams{i3}))); % index of best first param
    plotfield = permute(scan.cvValues, [i1 i2 i3]);
    plotfield = plotfield(:,:,ind3);
  end
    dim1 = scan.parameters.(scanParams{i1});
  dim2 = scan.parameters.(scanParams{i2});    
  % contour(z) plots rows as horizontals, so z(m,n) plots with m varying along y axis, hence transpose
  
  if length(dim1) > 1 & length(dim2) > 1
    h0 = getfigure(fig);
%     [c,h] = contourf(log10(dim1),log10(dim2),plotfield');  clabel(c,h), colorbar
    [c,h] = contourf(dim1,dim2,plotfield');  clabel(c,h), colorbar
    hold on;
    
    if length(unique(plotfield))==1
      plottext = ['Constant Value = ' num2str(max(max(plotfield)))];
      h=text(0.2,0.5, plottext); %log10(dim1)(floor(length(dim1)/2)), log10(dim2)(floor(length(dim2)/2)), plottext);
    else
      plottext = 'x';
      h=text(dim1(ind1), dim2(ind2), plottext);
      set(h,'color',[0 0 0],'erasemode','xor','fontweight','bold','fontsize',16,'horizontalAlignment','center', 'VerticalAlignment', 'middle')
    end
    xlabel([ scanParams{i1} ]);
    ylabel([ scanParams{i2} ]);
    hold off;
  else
    if nargout==0; clear h0; end
    return
  end
   
elseif nUse == 3
    % contour plot using first two parameters or use plotParams if two suitable params are given
  i1 = find(strcmpi(scanParams, useParams{1}));
  i2 = find(strcmpi(scanParams, useParams{2}));
  i3 = 6/(i1*i2);
  
  % cycle through views of CV result data in the 3-param case only
  i1 = mod(i1-1+presscount,3)+1;
  i2 = mod(i2-1+presscount,3)+1;
  i3 = mod(i3-1+presscount,3)+1;
  
  [zz ind1] = min(abs(scan.parameters.(scanParams{i1})-(scan.best.(scanParams{i1})))); % index of best first param
  [zz ind2] = min(abs(scan.parameters.(scanParams{i2})-(scan.best.(scanParams{i2})))); % index of best second param
  [zz ind3] = min(abs(scan.parameters.(scanParams{i3})-(scan.best.(scanParams{i3})))); % index of best third param
  plotfield = permute(scan.cvValues, [i1 i2 i3]);
  dim1 = scan.parameters.(scanParams{i1});
  dim2 = scan.parameters.(scanParams{i2});
  
  if length(dim1) > 1 & length(dim2) > 1
    h0 = getfigure(fig);
   if length(unique(plotfield(:,:,ind3)))==1
     % Avoid R2014a bug in contourf which does not set the axis limits
     isconstantfld = true;
     plotfield(1,1,ind3) = plotfield(1,1,ind3)-100*eps;
    [c,h] = contour(dim1,dim2,plotfield(:,:,ind3)', 0);  clabel(c,h)
   else
    % contour(z) plots rows as horizontals, so z(m,n) plots with m varying along y axis, hence transpose
    [c,h] = contourf(dim1,dim2,plotfield(:,:,ind3)');  clabel(c,h), colorbar
     isconstantfld = false;
   end
    hold on;
    
    if isconstantfld
      plottext = ['Constant Value = ' num2str(max(max(plotfield(:,:,ind3))))];
      h=text(mean(dim1), mean(dim2), plottext); 
      set(h,'color',[0 0 0],'erasemode','xor','fontweight','bold','fontsize',16,'horizontalAlignment','center', 'VerticalAlignment', 'middle')
    else
      plottext = 'x';
      h=text(dim1(ind1), dim2(ind2), plottext);
      set(h,'color',[0 0 0],'erasemode','xor','fontweight','bold','fontsize',16,'horizontalAlignment','center', 'VerticalAlignment', 'middle')
    end
    
    xlabel([ scanParams{i1} ], 'interpreter', 'none');
    ylabel([ scanParams{i2} ], 'interpreter', 'none');
    
    hold off;
    
    if isempty(findobj(h0,'tag','xgbcvplottoolbar'))
      %if no toolbar found on figure, create it now
      tlb = {'FrwdArrow'    'nextplot'    'xgbcvplot([],{},gcbf)'    'enable'    'View Next Parameter Combination'    'off'    'push'};
      toolbar(h0,'',tlb,'xgbcvplottoolbar');
    end    
  else
    if nargout==0; clear h0; end
    return
  end
else 
  return % only plot for cases of two or three param ranges
end

% Add title
if(nUse>2) | ((inputPlotParams & nUse==2)&length(scanParams(:))>2)
  val = scan.best.(scanParams{i3});
  if isnumeric(val)   % Ensure this value is char
    val = num2str(val);
  end
  plotValueTitle = [scanParams{i3} '=' val];
else
  plotValueTitle = '';
end 

if isclassification(scan.optimalArgs)
  xgbTypeName = 'XGB Classif';
  if ~isempty(plotValueTitle)
    plotTitle = [xgbTypeName '. Cross-validation: Misclassification Fraction, (' plotValueTitle ')'];
  else
    plotTitle = [xgbTypeName '. Cross-validation: Misclassification Fraction.' ];
  end
else
  xgbTypeName = 'XGB';
  if ~isempty(plotValueTitle)
  plotTitle = [xgbTypeName '. Cross-validation: Root Mean Sq. Error, (' plotValueTitle ')'];
  else
  plotTitle = [xgbTypeName '. Cross-validation: Root Mean Sq. Error.' ];
  end
end
title(plotTitle, 'interpreter', 'none');

if nargout==0; clear h0; end


%--------------------------------------------------
function h0 = getfigure(fig)

if isempty(fig)
  h0 = figure;  %new, integer handled figure
elseif ~ishandle(fig) & isnan(fig)
  h0 = figure('integerhandle','off');  %new NON-integer handled figure
else  %existing figure
  figure(fig);
  h0 = fig;
end
cla
hold off

%--------------------------------------------------------------------------
function presscount = updatepresscount(fig)
% keep counter of how many times the cvplot button was selected
if ~isempty(fig)
  if isappdata(fig, 'presscount')
    presscount = getappdata(fig, 'presscount') +1;
    setappdata(fig, 'presscount', presscount);
  else
    presscount = 1;
    setappdata(fig, 'presscount', presscount);
  end
end

