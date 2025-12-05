function fig = halfnormplot(doe, y, plottype)
%DOENORMALPLOT Produce Half-Normal or Normal plot from DOE dataset object.
%
%  INPUTS:
%    doe        = DOE dataset object.
%    y          = experimentally measured response values
%    plottype   = [ {'half-normal'} | 'normal' ] Indicates which plot type
%
%  Example:
%    halfnormplot(doe, y, 'half-normal');
%
%I/O: halfnormplot(doe, y, plottype)
%I/O: fig = halfnormplot(doe, y, plottype)
%
%See also: DOEGEN, DOEGUI

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<3
  plottype = 'half-normal';
end

normalplot = 0; % default is to use Half-Normal plot
if ~isempty(plottype) & strcmpi(plottype, 'normal')
  normalplot = 1;
end

if isdataset(y) % assume doe and y includes have same size
  ttl = y.label{2,1};
  y = y.data(y.include{1},y.include{2});
else
  ttl = '';
end

doedata = doe.data(doe.include{1},doe.include{2});
labels0 = doe.label{2}(doe.include{2},:);

nparam = size(doedata,2);
stdeff = nan(nparam,1);
for icol=1:nparam
  [mval, levels, ncount] = getgroupmeans(doedata, y, icol);
  stdeff(icol) = (mval(end) - mval(1));
end

ispos0 = stdeff>0;

if ~normalplot
  stdeff = abs(stdeff);
end
[stdeffsort sortind] = sort(stdeff);
ispos = ispos0(sortind);

labels0 = labels0(sortind,:);
labels = repmat(' ', size(labels0,1), size(labels0,2)+1);
for il=1:size(labels,1)
  labels(il,:) = sprintf(' %s', labels0(il,:));
end

qlim   = 3; %1.6;
if normalplot
  xi = 1:nparam;
  % use these z-values, as described at:
  % http://www.statsoft.com/textbook/statistics-glossary/n/#Normal%20Probability%20Plots
  % zj = phi^-1 [3*j-1)/(3*N+1)]
  prob = (3*xi-1)/(3*nparam+1);
  yval   = normdf('quantile', prob, 0, 1);
  
  % Get the point to draw line from origin through
  ipt1 = round(0.158*(nparam+1)); % point nearest -1 SD
  ipt2 = round(0.841*(nparam+1)); % point nearest +1 SD
  slope = (yval(ipt1)/stdeffsort(ipt1) + yval(ipt2)/stdeffsort(ipt2))/2;
else
  xi = 1:nparam;
  % http://www.statsoft.com/textbook/statistics-glossary/n/#Normal%20Probability%20Plots
  % convert the ranks into expected normal probability values, that is, 
  % the respective half-normal z values.
  prob = (3*nparam+3*xi-1)/(6*nparam+1);   % prob is approx (1+xi/n)/2
  yval   = normdf('quantile', prob, 0, 1); % phiinv_HN(y) = phiinv_N((1+y)/2)
  
% % Either way works. Only small diff is the p median values used (prob), 
% % which is not important.
%   prob = (3*xi-1)/(3*nparam+1);
%   yval  = halfnorminv(prob, 0, 1);

  % Get the point to draw line from origin through
  ipt = round(0.683*(nparam+1)); % point nearest +1 SD
  slope = yval(ipt)/stdeffsort(ipt);
end

% Make plot
fig = figure;
h1 = plot(stdeffsort(ispos), yval(ispos), 'o','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1], 'markersize',7);
hold on
h2 = plot(stdeffsort(~ispos), yval(~ispos), 'o','markerfacecolor',[0 0 1],'markeredgecolor',[1 1 1], 'markersize',7);
legendname(h1,'Positive Effect')
legendname(h2,'Negative Effect')
if normalplot
  plottitle = 'Normal Probability Plot';
  ylabel('Normal % Probability');
  % line([-qlim/slope qlim/slope], [-qlim qlim],'Color','r','LineWidth', 1)
else
  plottitle = 'Half-Normal Probability Plot';
  ylabel('Half-Normal % Probability');
  hl = line([0 qlim/slope], [0 qlim],'Color','r','LineWidth', 1);
  legendname(hl,'No-Effect Line');
end
h3 = plot(0,0,'yo:','MarkerSize',4,'MarkerFaceColor','y');
set(h3,'handlevisibility','off');
for i=1:nparam
  moveobj(text(stdeffsort(i), yval(i), labels(i,:)));
end
if isempty(ttl)
  title(plottitle)
else
  title(sprintf('%s %s',ttl,plottitle));
end
xlabel('Standardized Effect');

% The y-axis is z-value. Label it with corresponding cumulative
% distribution p-values for convenience.
if normalplot
  p = [0.001 0.003 0.01 0.02 0.05 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95 0.99 0.997 0.999];
  label = char('0.001', '0.003', '0.01', '0.02', '0.05', '0.1', '0.2',...
    '0.3', '0.4', '0.5', '0.6', '0.7', '0.8', '0.9', '0.95', '0.99', '0.997', '0.999');
  tick = normdf('quantile', p, 0, 1);
else
  p = [ 0.01 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95 0.99 0.997];
  label = char( '0.01', '0.1', '0.2',...
    '0.3', '0.4', '0.5', '0.6', '0.7', '0.8', '0.9', '0.95', '0.99', '0.997');
  tick = halfnorminv(p, 0, 1);
end

set(gca, 'YTick', tick, 'YTickLabel', label);

%--------------------------------------------------------------------------
function [mval, levels, ncount] = getgroupmeans(doedata, y, icol)
% Get mean y value of groups, members count of groups and factor levels
% associated with doe column icol

levels = unique(doedata(:,icol));
mval   = nan(size(levels)); %repmat(nan, size(levels));
ncount = nan(size(levels)); %repmat(nan, size(levels));

for i=1:length(levels)
  ii=doedata(:,icol)==levels(i);
  mval(i) = mean(y(ii));
  ncount(i) = sum(ii);
end

%--------------------------------------------------------------------------
% halfnorminv = @(p,mu,sigma) norminv(.5 + p/2,mu,sigma);
function [res] = halfnorminv(p,mu,sigma)
res = normdf('quantile', .5 + p/2,mu,sigma);

%--------------------------------------------------------------------------
% halfnormcdf = @(x,mu,sigma) normcdf(abs(x),mu,sigma) - .5;
function [res] = halfnormcdf(x,mu,sigma)
res = 2*normdf('cumulative', abs(x),mu,sigma) - 1;
