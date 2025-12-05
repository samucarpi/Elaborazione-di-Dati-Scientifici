function [xf] = windowfilter(x,win,options)
%WINDOWFILTER Spectral filtering.
%  Rows of X are filtered using a windowed filtering.
%
%  INPUTS:
%      x = data of class 'double' or 'dataset'.
%          If 'dataset' it must x.type=='data' or 'image'.
%          If 'double' it must be MxN.
%    win = an odd integer corresponding to the window width of the filter.
%    dim = dimension (mode) of data to filter. If empty ([]) then default 
%          is to use dimension/mode 2. 
%
%  OPTIONAL INPUT:
%   algorithm = an string which will be used as the options.algorithm
%               input (only valid when options input is omitted)
%   options = structure array with the following fields:
%       display: [ {'off'} | 'on'] governs level of display (waitbar on/off).
%     algorithm: [ {'mean'} | 'median' | 'max' | 'min' | 'despike' | ...
%                  'meantrimmed' | 'mediantrimmed' ] governs filter method.
% mode/dimension: dimension (mode) of data to filter. Default is to use 
%                 dimension/mode 2. 
%       
%            Despike parameters:
%            tol: [ {2} ] If empty then despike uses the std(median(x)) within
%                   each window to define a tolerance within the window.
%                 If tol>0 scalar, then tol defines the tolerance for all
%                   the windows.
%                 If tol<=0, then tol is estimated by the mean absolute deviation
%                   of madc(x.data(:)) and is the tolerance used for all the windows.
%                   {default = 2}
%    dsthreshold: [ {2} ] Threshold used for the 'despike' algorithm. In contrast
%                   to replacing all values with the meidan (e.g., for
%                   options.algorithm = 'median'), 'despike' replaces only
%                   values outside |x-median(x)|>options.dsthreshold*options.tol 
%                   with the median. (see options.tol)
%        trbflag: [ {'middle'} | 'bottom' | 'top' ] top-ot-bottom flag
%                 For trbflag = 'middle' the filter replaces values outside
%                   |x-median(x)|>dsthreshold*options.tol) with the median.
%                 For trbflag = 'bottom' the filter replaces values outside
%                   (x-median(x))>dsthreshold*options.tol with the median.
%                 For trbflag = 'top' the filter replaces values outside
%                   (median(x)-x)>dsthreshold*soptions.tol with the median.
% 
%        Trimming parameters:
%          ntrim: when algorithm = 'meantrimmed' or 'mediantrimmed',
%                   (ntrim) is the input (n) to the functions MEANTRIMMED
%                   or MEDIANTRIMED {default = 2}.
%
%  OUTPUTS:
%     xf = Filtered spectra class 'dataset'.
%
%  Note that to allow robust statistics the filter is based on a moving
%  window (or box), and is slow compared to other filter methods.
%
%I/O: xf = windowfilter(x,win,options);
%I/O: xf = windowfilter(x,win,'algorithm');
%
%See also: LINE_FILTER, BOX_FILTER

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%NBG 8/08
%NBG 1/11 modified box_filter

%% Options and I/O
if nargin == 0; x = 'io'; end
if ischar(x)
  options = [];
  options.name    = 'options';
  options.display = 'off';
  options.algorithm   = 'Mean';
  options.mode = 2;
  options.ntrim   = 2;
  options.trbflag = 'Middle';
  options.tol     = 2;
  options.dsthreshold = 2;

  if nargout==0
    evriio(mfilename,x,options);
  else
    xf = evriio(mfilename,x,options);
  end
  return
end

if nargin<3               
  options  = [];%set default options
end

if ischar(options)
  alg = options;
  options = [];
  options.algorithm = alg;
end
options = reconopts(options,mfilename);

if nargin<2
  evrierrordlg('WINDOWFILTER requires at least 2 inputs.')
end

wasdso = isdataset(x);
if ~wasdso
  x   = dataset(x);
end
m   = size(x);
dimsData = numel(m);
if dimsData>2
  haveMultiway = 1;
else
  haveMultiway = 0;
end


%Check Inputs
if numel(win)~=1
  evrierrordlg('Window size (win) must be a scalar.')
end
if (win/2-floor(win/2))==0
  if strcmp(options.display,'on')
    disp(['Window size (win) must be odd.'])
    disp([' Changing (win) from ',int2str(win),' to ',int2str(win-1),'.'])
  end
  win = max([1 win-1]);
end

if options.tol<=0
  options.usertol  = madc(x.data(:));
elseif options.tol>0
  options.usertol  = options.tol;
else
  options.usertol  = [];
end

if options.mode>dimsData
  evrierrordlg('Mode/Dimension input is greater than dimension of data', 'WINDOW FILTER');
end

dataFixed = 0;
if options.mode==2
% do nothing
elseif options.mode==1 && ~haveMultiway
  xorig = x;
  x = x';
  dataFixed = 1;
end

if haveMultiway
  xorig = x;
  modes = 1:length(m);
  xnew = permute(x, modes([options.mode 1:options.mode-1 options.mode+1:end]));
  sizeXnew = size(xnew);
  xunfold = unfoldmw(xnew,1);
  x = xunfold';
  dataFixed = 1;
end
%% Algorithm
algo = options.algorithm;
cleanedAlgo = lower(algo(~isspace(algo)));
switch cleanedAlgo
case 'mean'
  hx  = 'meanx'; %@(x) mean(x,1); %make it 6.5 compatible
  hy  = 'meany'; %@(x) mean(x,2);
  hz  = 'meanz'; %@(x) mean(x,3);
case 'median'
  hx  = 'medianx'; %@(x) median(x,1);
  hy  = 'mediany'; %@(x) median(x,2);
  hz  = 'medianz'; %@(x) median(x,3);
case {'max','maximum'}
  hx  = 'maxx'; %@(x) max(x,[],1);
  hy  = 'maxy'; %@(x) max(x,[],2);
  hz  = 'maxz'; %@(x) max(x,[],3);
case {'min','minimum'}
  hx  = 'minx'; %@(x) min(x,[],1);
  hy  = 'miny'; %@(x) min(x,[],2);
  hz  = 'minz'; %@(x) min(x,[],3);
case {'meantrimmed','meantrim'}
  hx  = 'meantrimx'; %@(x)
  hy  = 'meantrimy'; %@(x)
  hz  = 'meantrimz'; %@(x)
case {'mediantrimmed','mediantrim'}
  hx  = 'mediantrimx'; %@(x)
  hy  = 'mediantrimy'; %@(x)
  hz  = 'mediantrimz'; %@(x)
case {'roll', 'roller'}
  hx  = 'rollx'; 
  hy  = 'rolly';
  hz  = 'rollz';
case 'meanbkg'
  hx  = 'meanbkgx';
  hy  = 'meanbkgy'; 
  hz  = 'meanbkgz';
case {'medianbkg'}
  hx  = 'medianbkgx'; 
  hy  = 'medianbkgy';
  hz  = 'medianbkgz';
case {'max','maximum'}
  hx  = 'maxbkgx';
  hy  = 'maxbkgy';
  hz  = 'maxbkgz';
case 'despike'
  hx  = 'despikex';
  hy  = 'despikey';
  hz  = 'despikez';
case {'minbkg','minimumbkg'}
  hx  = 'minbkgx'; 
  hy  = 'minbkgy';
  hz  = 'minbkgz';
otherwise
  error('Input (options.algorithm) not recognized.')
end

%% Run the filter
%create include mask to avoid using excluded items
imask = false(1,m(2));
imask(x.include{2}) = true;

%do analysis
xd    = x.data;
xf    = xd;
px    = (win-1)/2;

%do edges
for j1=1:px
  switch imask(j1)
  case true    %this point is included, process it
    subset   = 1:px+j1;
    subset   = subset(imask(subset));
    options.subset = subset-j1;
    xf(:,j1) = feval(hy,xd(:,subset),options);
  end
  switch imask(m(2)-j1)
  case true    %this point is included, process it
    subset   = m(2)-px-j1:m(2);
    subset   = subset(imask(subset));
    options.subset = subset-m(2)+j1-1;
    xf(:,m(2)-j1+1) = feval(hy,xd(:,subset),options);
  end
end

%do main body of spectra
main = px+1:m(2)-px;
main = main(imask(main)); %remove excluded variables from list
for j1=main
  subset   = j1-px:j1+px;
  subset   = subset(imask(subset));  %remove excluded variables
  options.subset = subset-j1;
  xf(:,j1) = feval(hy,xd(:,subset),options);
end

if dataFixed
  if ~haveMultiway
    xf = xf';
    x = xorig;
  elseif haveMultiway
    xf = xf';
    xf_reshape = reshape(xf, sizeXnew);
    xf = ipermute(xf_reshape, modes([options.mode 1:options.mode-1 options.mode+1:end]));
    x = xorig;
  end
end

if wasdso
  %now move filtered result back into dataset and return as output
  x.data = xf;
  xf = x;
end

%% Functions ---------------------------------
function y = meanx(x,opt)         %MeanK
y   = mean(x,1);
function y = meany(x,opt)
y   = mean(x,2);
function y = meanz(x,opt)
y   = mean(x,3);

function y = meanbkgx(x,opt)      %MeanBkgK
y   = x(opt.subset==0,:) - mean(x,1);
function y = meanbkgy(x,opt)
y   = x(:,opt.subset==0) - mean(x,2);

function y = medianx(x,opt)       %MedianK
y   = median(x,1);
function y = mediany(x,opt)
y   = median(x,2);
function y = medianz(x,opt)
y   = median(x,3);

function y = medianbkgx(x,opt)    %MedianBkgK
y   = x(opt.subset==0,:) - median(x,1);
function y = medianbkgy(x,opt)
y   = x(:,opt.subset==0) - median(x,2);
% function y = medianzbkg(x,opt)

function y = maxx(x,opt)          %MaxK
y   = max(x,[],1);
function y = maxy(x,opt)
y   = max(x,[],2);
function y = maxz(x,opt)
y   = max(x,[],3);

function y = maxbkgx(x,opt)       %MaxBkgK
y   = x(opt.subset==0,:) - max(x,[],1);
function y = maxbkgy(x,opt)
y   = x(:,opt.subset==0) - max(x,[],2);

function y = minx(x,opt)          %MinK
y   = min(x,[],1);
function y = miny(x,opt)
y   = min(x,[],2);
function y = minz(x,opt)
y   = min(x,[],3);

function y = minbkgx(x,opt)       %MinBkgK
y   = x(opt.subset==0,:) - min(x,[],1);
function y = minbkgy(x,opt)
y   = x(:,opt.subset==0) - min(x,[],2);

function y = meantrimx(x,opt)
y    = meantrimmed(x,opt.ntrim,1);
function y = meantrimy(x,opt)
y    = meantrimmed(x,opt.ntrim,2);
function y = meantrimz(x,opt)
y    = meantrimmed(x,opt.ntrim,3);

function y = mediantrimx(x,opt)
y    = mediantrimmed(x,opt.ntrim,1);
function y = mediantrimy(x,opt)
y    = mediantrimmed(x,opt.ntrim,2);
function y = mediantrimz(x,opt)
y    = mediantrimmed(x,opt.ntrim,3);

function y = despikex(x,opt)
y    = despiken(x,1,opt);
function y = despikey(x,opt)
y    = despiken(x,2,opt);
function y = despikez(x,opt)
y    = despiken(x,3,opt);

function y = despiken(x,mode,opt)
yf   = median(x,mode);
if isempty(opt.usertol)
  sd = std(yf,1,mode);
else
  sd = opt.usertol;
end
y    = nindex(x,ceil(size(x,mode)/2),mode);
switch lower(opt.trbflag)
case 'middle'
  k  = abs(yf-y)./sd>opt.dsthreshold;
case 'bottom'
  k  = (y-yf)./sd>opt.dsthreshold;
case 'top'
  k  = (yf-y)./sd>opt.dsthreshold;
end
y(k) = yf(k);

function y = rolly(x,opt)  %not vectorized and not documented
[m,n] = size(x);
r     = max(opt.subset)^2; 
j     = find(opt.subset==0);
k     = opt.subset.^2;
y     = x(:,j);
[y0,i] = min(x(:,1:j) - ones(m,1)*sqrt(max([r - k(1:j);zeros(1,j)])),    [],2);
y0     = y0 + ones(m,1)*sqrt(max([r - (i-j).^2,zeros(m,1)],[],2));

[y1,i] = min(x(:,j:n) - ones(m,1)*sqrt(max([r - k(j:n);zeros(1,n-j+1)])),[],2);
y1     = y1 + ones(m,1)*sqrt(max([r - (i-1).^2,zeros(m,1)],[],2));
y     = y-mean([y0,y1],2);
