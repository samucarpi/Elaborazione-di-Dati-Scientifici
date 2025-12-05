function fig = doeeffectsplot(doe, y, icol, alpha, options)
%DOEEFFECTSPLOT Create main effect or interaction plot, incl LSD bars.
% Main & Interaction Effects plots which contain Fisher's Least Significant
% Difference bars around the mean effect values.
%INPUTS:
%   doe    = DOE dataset object.
%   icol   = user selected doe column index. DOE columns are arranged as:
%            Factors first, then interactions.
%            For example: F1, F2, F3, F1xF2, F1xF3, F2xF3
%   alpha  = 0.05 for two-sided critical region
%   y      = experimentally measured response values
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           display: [ 'off' | {'on'} ]      governs level of display to command window.
%
% Example:
%  Use 'doegui' to create a doe object, for example with 3 factors (with 2 
%  or more levels) and including 2 term interactions.
%  Then run the following to set up:
%   icol=1;
%   alpha = 0.05;
%   y = rand(size(doe,1),1);           % create y, some expt result values 
%   [doe.data(:,icol) y]               % view Factor 1 and y values
%  Add the following to make significant difference between F1 groups
%   y  = y + doe.data(:,icol);
%
%I/O: doeeffectsplot(doe, y, icol, alpha)
%I/O: doeeffectsplot(doe, y, icol, alpha, options)
%
%See also: DOEGEN, DOEGUI

% Copyright © Eigenvector Research, Inc. 1994
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin == 0; doe = 'io'; end
if ischar(doe);
  options = [];
  options.display = 'on';
  if nargout==0; evriio(mfilename,doe,options); else; fig = evriio(mfilename,doe,options); end
  return; 
end

if nargin<5
  options = [];
end
options = reconopts(options,mfilename);

%multiple y's? do them one at a time
if length(y.include{2})>1
  for yi=y.include{2};
    fig(yi) = doeeffectsplot(doe, y(:,yi), icol, alpha, options);
  end
  return
end

%extract label and data
if isdataset(y)
  ylbl = y.label{2};
  if ~isempty(ylbl);
    ylbl = ylbl(y.include{2},:);
  else
    ylbl = '';
  end
  y = y.data.include{2};
else
  ylbl = '';
end
if isempty(ylbl)
  ylbl = 'Response';
end
ylbl = [ylbl sprintf(' (alpha = %3.2f)',alpha)];

% check for acceptable parameter values
[doe, icol, alpha, y] = checkparams(doe, icol, alpha, y);

% get anova quantities
anovares = anovadoe(doe,y);

% get group means, etc
[mval, levels, ncount] = getgroupmeans(doe, y, icol);

% get LSD
[lsd] = getlsd(anovares.mean_sq.error, ncount, alpha, options);

classidtype = doe.classid{2}(icol);
fig = [];
if strcmp(classidtype, 'Numeric') | strcmp(classidtype, 'Categorical')
  % is factor
  fig = plotfactor(doe, y, lsd, levels, mval, ncount, icol, ylbl);
elseif strcmp(classidtype, '2 Term Interaction')
  % is interaction
  fig = plotinteraction(doe, y, lsd, levels, mval, ncount, icol, ylbl);
else
  % unknown type
  error('Cannot show effects plot for "%s" factor type', classidtype);
end

%--------------------------------------------------------------------------
function [lsd] = getlsd(mse, ncount, alpha, options)
% Get LSD for confidence level 1-alpha, test with nu degrees of freedom
% where ncount is vector of data counts in each group
% INPUTS
% mse    = anova residual mean square error
% ncount = count of data in each group
% alpha  = 0.05 for two-sided critical region; or, convert to alpha/2 before
%          getting the critical t-value for the one-sided critical region
lsd = repmat(nan, size(ncount));
nsamp = sum(ncount);
k = length(ncount);
nu = nsamp - k;
ninv = ones(size(ncount))./ncount;
for ig = 1:length(ncount);
  hmeaninv   = (sum(ninv)-ninv(ig))/(k-1);
  sampfact = hmeaninv + ninv(ig);
  t2 = sqrt(mse*sampfact);
  
  tstat = ttestp(alpha/2, nu,2);
  lsd(ig) = tstat*t2;
  if strcmp(options.display,'on')
    disp(sprintf('LSD(%d) = %4.4g', ig, lsd(ig)));
  end
end

%--------------------------------------------------------------------------
function fig = plotfactor(doe, y, lsd, levels, mval, ncount, icol, ylbl)
facs = doe.userdata.DOE.col_ID{icol};
xrng = max(levels) -min(levels);
yrng = max(mval) -min(mval);
xmin = levels(1) - xrng*0.1; xmax = levels(end) + xrng*0.1;
% ymin = min(mval) - yrng*0.1; ymax = max(mval) + yrng*0.1;
ymin = min(y) - yrng*0.1; ymax = max(y) + yrng*0.1;
fig = figure;
plot(levels, mval, 'LineWidth',3)
hold on
for ig = 1:length(ncount)
  lsdo2 = lsd(ig)/2;
  mylin = line([levels(ig) levels(ig)], [mval(ig)-lsdo2 mval(ig)+lsdo2]);
  set(mylin,'Color', 'k');
  set(mylin, 'LineWidth', 1);
end
% plot(doe.data(:,icol), y, '.r')
axis([xmin xmax ymin ymax]);

title(sprintf('%.10s Main Effect', doe.label{2}(facs(1),:)));
xlabel('Levels'); ylabel(sprintf('%s',ylbl));

%--------------------------------------------------------------------------
function  fig = plotinteraction(doe, y, lsd, levels, mval, ncount, icol, ylbl)
% plot interaction
facs = doe.userdata.DOE.col_ID{icol};
xrng = max(levels(:,2)) -min(levels(:,2));
yrng = max(mval) -min(mval);
xmin = min(levels(:,2)) - xrng*0.1; xmax = max(levels(:,2)) + xrng*0.1;
% ymin = min(mval) - yrng*0.1; ymax = max(mval) + yrng*0.1;
ymin = min(mval) - yrng*0.2; ymax = max(mval) + yrng*0.1;
[f1levs, ii, jj] = unique(levels(:,1));
legs = cell(length(f1levs),1);
fig = figure;
colororder = [
  0.00  0.00  1.00
  0.00  1.00  0.00
  1.00  0.00  0.00
  0.00  0.75  0.75
  0.75  0.00  0.75
  0.75  0.75  0.00
  0.25  0.25  0.25];
set(gca, 'ColorOrder', colororder)
hold all;
for f1=1:length(f1levs)
  kk = jj==f1;
  plot(levels(kk,2), mval(kk), 'LineWidth',3);
  legs{f1} = sprintf('%.10s lev %2.2g', doe.label{2}(facs(1),:), f1levs(f1));
end
legend(legs); %,'Location','NorthEastOutside')
for f1=1:length(f1levs)
  kk = jj==f1;
  lsdo2 = lsd(kk)/2;
  mylin = line([levels(kk,2)'; levels(kk,2)'], [(mval(kk)-lsdo2)'; (mval(kk)+lsdo2)']);
  set(mylin,'Color', 'k');
  set(mylin, 'LineWidth', 1);
end
axis([xmin xmax ymin ymax]);
title(sprintf('%s Interaction Plot', doe.label{2}(icol,:) ));
xlabel(sprintf('%.10s Levels', doe.label{2}(facs(2),:))); ylabel(sprintf('%s',ylbl));

%--------------------------------------------------------------------------
function [doe, icol, alpha, y] = checkparams(doe, icol, alpha, y)
if isempty(doe)
  error('Input parameter doe is empty');
elseif isempty(icol)
  icol = 1;
elseif isempty(alpha)
  alpha = 0.05;
elseif isempty(y)
  error('Input parameter y is empty');
end

if ~isstruct(doe.userdata) | ~isstruct(doe.userdata.DOE)
  error('Input doe is not a DOE object');
elseif  ~ismember(icol,doe.include{2})
  error('icol (= %d) is not a valid column index of doe', icol);
elseif ~(alpha>=0 & alpha<=1)
  error('alpha (= %4.4g) must be in range [0,1]', alpha);
elseif ~isnumeric(y) | length(y)~=size(doe,1)
  error('y must be numeric vector with length = number of rows of doe')
end

%--------------------------------------------------------------------------
function [mval, levels, ncount] = getgroupmeans(doe, y, icol)
% Get mean y value of groups, members count of groups and factor levels
% associated with doe column icol
classidtype = doe.classid{2}(icol);

facs = doe.userdata.DOE.col_ID{icol};

if strcmp(classidtype, 'Numeric') | strcmp(classidtype, 'Categorical')
  % is factor
  levels = unique(doe.data(:,icol));
  mval   = repmat(nan, size(levels));
  ncount = repmat(nan, size(levels));
  
  
  for i=1:length(levels)
    ii=doe.data(:,icol)==levels(i);
    mval(i) = mean(y(ii));
    ncount(i) = sum(ii);
  end
elseif strcmp(classidtype, '2 Term Interaction')
  % is interaction
  [levels, ii, jj] = unique(doe.data(:,facs), 'rows');
  nlevs = size(levels,1);
  mval   = repmat(nan,nlevs, 1);
  ncount = repmat(nan,nlevs, 1);
  for i=1:nlevs
    inds      = jj==i;
    mval(i)   = mean( y(inds) );
    ncount(i) = sum(inds);
  end
end
