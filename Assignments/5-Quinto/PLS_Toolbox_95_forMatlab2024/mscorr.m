function [sx,alpha,beta,xref] = mscorr(x,xref,mc,win,specmode,subind)
%MSCORR Multiplicative scatter/signal correction (MSC).
%  MSCORR performs multiplicative scatter correction (a.k.a. multiplicative
%  signal correction) on an input matrix of spectra (x) (class "double")
%  regressed against a reference spectra (xref) (class "double").
%  If (xref) is empty or omitted, the mean of (x) is used as the reference
%  (or median of (x) if algorithm = 'median').
%
% INPUTS:
%    x = input spectra (MxN, class double)
% OPTIONAL INPUTS:
%      xref = 1xN reference or "target" spectrum. If empty, mean or median
%             of (x) is used.
%        mc = [{1} | 0] flag indicating if an offset should be removed from 
%             the spectra (x) in addition to correcting multiplicative scaling.
%             1 = correct for offset {default}, and
%             0 = do not remove offset.
%       win = allows for scatter correction in spectral "windows" that can be
%             of different widths. Input (win) is a cell array with NK
%             elements corresponding to the number of windows desired. Each
%             cell of (win) contains the indices corresponding to each window
%             (i.e. this is not a moving window approach - see STDFIR). MSC
%             is then performed in each of the NK windows. (alpha and beta
%             are not assigned). If (win) is empty, the entire spectrum is
%             treated at once (standard approach).
%  specmode = defines which mode of the data is the spectral mode {default
%             = 2} and is only used when (x) contains 3 or more modes.
%    subind = specifies the indices within the included spectral variables
%             that are used to calculate the MSC correction; default is
%             that ALL included spectral variables are used. Correction is
%             always applied to the entire spectrum even if subind
%             indicates that only a sub-portion should be used to calculate
%             correction factors.
%   options = structure array with the following fields:
%    algorithm: [ {'leastsquares'} | 'median']  Specifies how spectrum scale
%             factors are determined. Default is by least squares regression
%             between each spectrum and the reference spectrum. 'median'
%             uses the median of the ratio between a spectrum and the
%             reference. Thus median is only appropriate if most values are
%             non-negative. If algorithm = 'median' then mc is set = 0.
%       robust: [{'none'} | 'lsq2top' ] Governs the use of robust least squares
%             if 'lsq2top' is used then "trbflag", "tsqlim", and "stopcrit" are
%             also used (see LSQ2TOP for descriptions of these fields).
%          res: [] Scalar (required with "lsq2top") this is input (res) to
%             the LSQ2TOP function.
%     trbflag: [ 'top' | 'bottom' | {'middle'}] Used only with lsq2top.
%      tsqlim: [ 0.99 ] Used only with lsq2top.
%   The fields mc, win, specmode, subind may be supplied as options fields:
%           mc: [{1} | 0]  See description above.
%          win: [{[]} | cell array]  See description above.
%     specmode: [{2}]  See description above.
%       subind: [vector]  See description above.
%
% OUTPUTS
%      sx = corrected spectra
%   alpha = the intercepts/offsets
%    beta = the multiplicative scatter factor/slope
%    xref = the reference spectrum used
%
%  To apply an MSC to new data, you must use the same xref as used on the
%  calibration data. If xref was empty or omitted, the xref output during
%  the calibration steps should be used as input on the test data:
%      [x_cal_s,alpha,beta,xref] = mscorr(x_cal);
%      [x_test_s] = mscorr(x_test,xref);
%  Note also that all other input settings (mc, win, etc.) must also be the
%  same on both the calibration and test data.
%
%I/O: [sx,alpha,beta,xref] = mscorr(x,xref)
%I/O: [sx,alpha,beta,xref] = mscorr(x,options)
%I/O: [sx,alpha,beta,xref] = mscorr(x,xref,options)
%I/O: [sx,alpha,beta,xref] = mscorr(x,xref,mc,win,specmode,subind)
%I/O: mscorr demo
%
%See also: FRPCR, STDFIR, STDGEN

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 3/99, 8/02
%rb, aug, 2003, Changes to enable Nway data:
%               Added input to specify what mode is spectral - default 2
%               Added initial check for nway. If so, then data are
%               rearranged so that specmode is columns & the rest rows.
%               Then MSC is just run on that and converted back to original
%               size
%jms 8/14/03 - added default xref (=mean(x))
%jms 2/17/04 - fixed help
%   - return non-mean-centered xref even if mc is 1
%jms 7/8/04 - do not do windowed mode if win is empty
%   -updated help
%jms 4/5/06 - handle beta=0 samples
%cem 10/23/06 - added optional input "subind": allows user to specify a
%   subset of the included spectral variables for calculating the MSC
%   correction factors

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  options.name          = 'options';
  options.algorithm     = 'leastsquares';
  options.mc            = 1;
  options.win           = [];
  options.specmode      = 2;
  options.subind        = [];
  options.robust        = 'none';   % [{'none'} | 'lsq2top' ] 
  options.res           = [];       % Scalar (required with "lsq2top")
  options.trbflag       = 'middle'; % [ 'top' | 'bottom' | {'middle'}]
  options.tsqlim        = 0.99;     % Used only with lsq2top.
  options.stopcrit      = [1e-4 1e-4 1000 360]; % Used only with lsq2top.
  options.initwt        = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; sx = evriio(mfilename,varargin{1},options); end
  return;
end

% If x is a dso then use include.
xorig = [];
usesDSO = 0;
if isdataset(x)
  xorig = x;
  incld = x.include;
  x = x.data(incld{:});
  usesDSO = 1;
end

options = reconopts([],mfilename);
switch nargin
  case 1
    % 1 non-char inputs: (x)
    if ~isnumeric(x)
      error('Input x must be a numeric');
    end
    xref      = [];
    mc        = options.mc;
    win       = options.win;
    specmode  = options.specmode;
    subind    = options.subind;
    algorithm = options.algorithm;
  case 2
    % 2 inputs: (x, xref)
    %           (x, options)
    if ~isnumeric(x)
      error('Input x must be a numeric');
    end
    if isstruct(xref)        % xref is options
      options = reconopts(xref,mfilename,{'classset','priorprob','rawmodel','strictthreshold'});
      xref     = [];
    elseif ~isnumeric(xref)  % xref is reference spectrum
      error('Input xref must be options struct or numeric array.')
    end
    mc        = options.mc;
    win       = options.win;
    specmode  = options.specmode;
    subind    = options.subind;
    algorithm = options.algorithm;
  case 3
    % 3 inputs: (x, xref, mc)
    %           (x, xref, options)
    if ~isnumeric(x) | ~isnumeric(xref)
      error('Input x, xref must all be numeric');
    end
    if isstruct(mc)          % mc is options
      options = reconopts(mc,mfilename,{'classset','priorprob','rawmodel','strictthreshold'});
      mc       = options.mc;
    elseif ~isnumeric(mc)    % mc is numerical flag
      error('Input mc must be options struct or numerical flag.')
    end
    win       = options.win;
    specmode  = options.specmode;
    subind    = options.subind;
    algorithm = options.algorithm;
  case 4
    % 4 inputs: (x, xref, mc, win)
    % 4 inputs: (x, xref, mc, options)
    if ~isnumeric(x) | ~isnumeric(xref)| ~isnumeric(mc)
      error('Input x, xref, mc must all be numeric');
    end
    if isstruct(win)  % win is options
      options = reconopts(win,mfilename);
      win     = options.win;
    elseif ~iscell(win)
      error('Input win must be cell.')
    end
    specmode  = options.specmode;
    subind    = options.subind;
    algorithm = options.algorithm;
  case 5
    % 5 inputs: (x, xref, mc, win, specmode)
    % 5 inputs: (x, xref, mc, win, options)
    if ~isnumeric(x) | ~isnumeric(xref)| ~isnumeric(mc)| ~(isempty(win)|iscell(win)|isnumeric(win))  % add isemptywin to next
      error('Input x, xref, mc, specmode must all be numeric, and win must be empty or cell.')
    end
    if isstruct(specmode)  % specmode is options
      options  = specmode;
      options  = reconopts(options,mfilename);
      specmode = options.specmode;
    elseif ~isnumeric(specmode)
      error('Input specmode must be numeric, and win must be empty or cell.')
    end
    subind    = options.subind;
    algorithm = options.algorithm;
  case 6
    % 6 inputs: (x, xref, mc, win, specmode, subind)
    if ~isnumeric(x) | ~isnumeric(xref)| ~isnumeric(mc)| ~(isempty(win)|iscell(win)|isnumeric(win))| ~isnumeric(specmode)| ~isnumeric(subind)
      error('Input x, xref, mc, specmode, subind must all be numeric, and win must be empty or cell.')
    end
    options = reconopts(options,mfilename);
    algorithm = options.algorithm;
end

% Do not use mean centering if using median algorithm
if strcmp(algorithm, 'median')
  mc = 0;
end

% Check if multiway
ndimsize = 0; % Flag for three-way
if ndims(x)>2
  if ~any([1:ndims(x)]==specmode) % specmode wrongly given
    specmode = 2;
  end
  % Reshape
  ndimsize = size(x);
  x = permute(x,[specmode 1:specmode-1 specmode+1:ndims(x)]);
  x = reshape(x,ndimsize(specmode),prod(ndimsize)/ndimsize(specmode))';
end

if size(x,2)==1
  error('MSC requires two or more variables to operate.')
end

if isempty(xref)
  if strcmp(algorithm, 'median')
    xf = x;
    xf(~isfinite(xf)) = -inf;
    xref = median(xf);      %use median of x (ignoring missing data)
  else
    [junk,xref] = mncn(x);  %use mean   of x (ignoring missing data)
    clear junk
  end
  %check xref for essentially zero values
  if max(abs(xref))<1e-10
    error('Data mean is zero. MSC cannot operate on mean-centered data.');
  end
else
  if max(abs(xref))<1e-10
    %user-supplied xref: check for essentially zero values
    evrierrordlg('Reference spectrum cannot be zero.');
    return;
  end
end

if usesDSO
  xref = xref(:,xorig.include{2});
end
[m,n]       = size(xref);
% if m>1&n>1
%   error('Input xref must be a vector')
% end
if ~isvector(xref)
  evrierrordlg('Input xref must be a vector');
  return;
end
% if n>m
%   xref      = xref(:); %make xref a column vector
%   m         = length(xref);
% end
if isrow(xref)
  xref      = xref(:); %make xref a column vector
  m         = length(xref);
end

if m~=size(x,2)      % m is the number of variables in xref
  evrierrordlg('Number of variables in input x differs from number of variables in xref')
%   error('Input xref length not compatible with x')
end

% specify "MSCind" array, which has the indeces of spectral variables that
% are to be used to determine the MSC alpha and beta correction factors
% if DSO subind would be x.include{2}
if ~isempty(subind) %use a specified subset of the included spectral variables..
  if min(subind)<1 || max(subind)>m
    evrierrordlg('Indicated index range (subind) is not valid for passed variables')
  end
  xref_sub    = xref(subind);
  x_sub       = x(:,subind);
  if isempty(options.initwt)
    options.initwt  = zeros(m,1);
    options.initwt(subind) = 1;
  end
else % just use all included spectral variables.. (make _sub variables just pointers to originals)
  xref_sub    = xref;
  x_sub       = x;
  if isempty(options.initwt)
    options.initwt  = ones(m,1);
  end
end

if length(options.initwt)~=m
  evrierrordlg('Options.initwt must be a vector with a length equal to the number of columns of (x).')
end
options.initwt  = options.initwt(:);

switch lower(options.robust)
case 'none'
case 'lsq2top'
  if isempty(options.res)
    %Note: could use std( savgol(mean/median,3,2,0)-mean/median )
    error('Input options.res must not be empty (see LSQ2TOP for additional help).')
  elseif options.res<=0
    error('Input options.res must be positive (see LSQ2TOP for additional help).')
  end
  optlsq2top          = lsq2top('options');
  optlsq2top.trbflag  = options.trbflag;
  optlsq2top.tsqlim   = options.tsqlim;
%   optlsq2top.stopcrit = optlsq2top.stopcrit;
  optlsq2top.initwt   = options.initwt;
otherwise
  evrierrordlg('Options.Robust not recognized.')
end

if isempty(win)
  switch lower(options.robust)
  case 'none'
    if mc==0  %NOT including offset
      alpha = zeros(size(x,1),1);
      if strcmp(algorithm, 'median')
        ratios  = scale(x_sub,zeros(1,size(x_sub,2)),xref_sub');
        ratios(~isfinite(ratios)) = -inf;
        mratios = median(ratios,2);
        beta    = mratios;
      else
        beta    = (x_sub/xref_sub');
      end
      beta(beta==0) = 1;  %filter out zeros (to avoid divide by zero error)
      sx          = x./beta(:,ones(1,size(x,2)));

    else  %including mean centering i.e offset (alpha)
      [sx,alpha]  = mncn(x_sub');
      [xrefmc,mx] = mncn(xref_sub);
      beta        = (xrefmc\sx)';
      beta(beta==0) = 1;  %filter out zeros (to avoid divide by zero error)
      alpha       = (alpha-mx*beta')';
      sx          = (x-alpha(:,ones(1,m)));  % Calc using two lines to reduce peak memory usage
      sx          = sx./beta(:,ones(1,m));   % associated with temp arrays alpha and beta.

      % x_true     = (x_measured - (x_measured_mean - ref_mean*beta))/beta
      % x_measured = (x_true - ref_mean)*beta + x_measured_mean
      % (x_measured - x_measured_mean) = (x_true - ref_mean)*beta
      % So, when x_measured = 0
      % x_true     = (0 - (0 - ref_mean*beta))/beta
      % x_true     = ref_mean

    end
  case 'lsq2top'  %  disp('lsq2top')

    mm          = size(x_sub);
    if mc==0      %0 = do not remove offset
      beta      = zeros(mm(1),1);
      for i1=1:size(x,1)
        [beta(i1),resnorm,residual] = ...
                  lsq2top(xref_sub,x_sub(i1,:)',[],options.res,optlsq2top);
      end
      alpha     = zeros(size(x,1),1);
      sx        = x./beta(:,ones(1,m));
    else          %1 = correct for offset
      beta      = zeros(2,mm(1));
      alpha     = ones(mm(2),1);
      for i1=1:size(x,1)
        [beta(:,i1),resnorm,residual] = ...
          lsq2top([xref_sub,alpha],x_sub(i1,:)',[],options.res,optlsq2top);
      end
      alpha     = beta(2,:)';
      beta      = beta(1,:)';
      sx        = (x-alpha(:,ones(1,m)));  % Calc using two lines to reduce peak memory usage
      sx        = sx./beta(:,ones(1,m));   % associated with temp arrays alpha and beta.
    end
  end
else %assumes using a windowed approach
  alpha         = 'NaN';
  beta          = 'NaN';
  sx            = x;
  
  %LWL added to convert double array of indices to cell array 
  if isnumeric(win)
    if iscolumn(win)
      win = win';
    end
    new_win = win;% Add a new isolating point end
    end_value = new_win(end);
    new_win(end+1) = end_value+2;
    idx = find(diff(new_win) ~= 1); % Find indexes of isolating points
    [m,n] = size(idx);
    start_idx = 1 ; % Set start index
    for bb = 1:n
      end_idx = idx(bb); % Set end index
      region = new_win(start_idx:end_idx); % Find consecuative sequences
      start_idx = end_idx + 1; % update start index for the next consecuitive sequence
      window_cell(bb,1) = {region};
    end
    win = window_cell;
  end
  
  for ii=1:length(win)
    sx(:,win{ii}) = mscorr(x(:,win{ii}),xref(win{ii},1),mc);
  end
end

% If data were threeway, turn them back
if ~all(ndimsize==0)
  sx = reshape(sx',ndimsize([specmode 1:specmode-1 specmode+1:length(ndimsize)]));
  sx = ipermute(sx,[specmode 1:specmode-1 specmode+1:length(ndimsize)]);
end

if ~isempty(xorig) & isdataset(xorig)
  %if we started with a DSO, re-insert back into DSO
  if anyexcluded(xorig)
    xorig.data(:) = nan;  %block out all data
    xorig.data(incld{:}) = sx;  %insert scaled data (included columns only)
  else
    xorig.data = sx;
  end
  sx = xorig;
end
