function [y_b,b_b] = baselinew(y,x,width,order,res,options)
%BASELINEW Baseline using windowed polynomial filter.
% BASELINEW fits a polynomial "baseline" to the bottom (or top) of a curve
% (e.g. a spectrum) by recursively calling LSQ2TOP. It uses a windowed
% approach and can be considered a filter or baseline (low frequency)
% removal algorithm. The window width required depends on the frequency of
% the low frequency component (baseline). Wide windows and low order
% polynomials are often used. See LSQ2TOP for more details on the polynomial
% fit algorithm. Inputs include the curve(s) to be fit (dependent variable)
% y, the axis to fit against (the independent variable) x [e.g. y = P(x)],
% the window width width (an odd integer), the polynomial order order, and
% an approximate noise level in the curve res. Note that y can be MxN where
% x is 1xN. The optional input options is discussed below.
%
%  INPUTS:
%        y  = matrix of ROW vectors to be baselined, MxN [class double].
%        x  = axis scale, 1xN vector {if empty it is set to 1:N}.
%    width  = window width specifying the number of points in the filter
%             {if (width) is empty no windowing is used}.
%    order  = order of polynomial [scalar] to fit {if (order) is empty
%             (options.p) must not be empty; see below}.
%      res  = approximate fit residual [scalar] {if empty it is set to
%             5% of fit of all data to x}.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields (see LSQ2TOPB):
%     display: [ 'off' | {'on'} ] governs level of display to command window.
%           p: [ ], if not empty, (options.p) is a NxK matrix of
%              basis vectors and it supersedes input (order).
%      smooth: [], if >0 this adds smoothing by adding a penalty to the
%              magnitude of the 2nd derivative. (empty or <=0 means no smooth)
%     trbflag: [ 'top' | {'bottom'} ] top or bottom flag, tells algorithm
%              to fit to the top or bottom of the data cloud.
%      tsqlim: [ 0.99 ]               limit that governs whether a data point is
%              outside the fit residual defined by input (res).
%    stopcrit: [1e-4 1e-4 1000 360]   stopping criteria, iteration is continued
%              until one of the stopping criterion is met
%              [(rel tol) (abs tol) (max # iterations) (max time [seconds])].
%      initwt: []; empty or 1xN vector of initial weights (0<=w<=1).
%
%  OUTPUTS:
%      y_b  = matrix of baselined ROW vectors, MxN, and
%      b_b  = matrix of baselines, MxN.
%
%Example: if (y) is a 5 by 100 matrix then
%   y_b = baselinew(y,[],25,3,0.01);
%  gives a 5 by 100 matrix of baselined row vectors from an
%  25-point cubic polynomial fit of each row of (y).
%
%  Note: This function has been speeded up from the original 
%  release in Version 3.5. However, the least squares fit is
%  still time consuming.
%  Note: If (order) is set to 0, BASELINEW calls MED2TOP
%  that speeds up the algorithm considerably and the input
%  (res) is not used [it can be empty].
%
%I/O: [y_b,b_b]= baselinew(y,x,width,order,res,options);
%I/O: options = baselinew('options');
%I/O: baselinew demo
%
%See also: BASELINE, LAMSEL, LSQ2TOP, LSQ2TOPB, MED2TOP, MSCORR, SAVGOL, STDFIR, WLSBASELINE

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 4/04 modified SAVGOL to create BASELINEW
%nbg 8/5/05 changed help "initwt: []; empty or Mx1" to "1xN"
%nbg 8/5/05 added initial wts from an initial SAVGOL to help speed it up
%nbg 8/10/05 using wts from previous window to seed next window's wts
%nbg 8/12/05 added code to call MED2TOP
%nbg 10/30/05 allowed for options.p and order=[]
%nbg 11/1/05 added options.smooth
%nbg 2/1/06 added " | width==0" to "if nargin<3 | width==0"
%nbg 2/7/06 changed order and opts.p so that opts.p supersedes order

if nargin == 0; y  = 'io'; end
varargin{1}        = y;
if ischar(y);
  options          = [];
  options.name     = 'options';
  options.display  = 'on';
  options.p        = [];
  options.smooth   = [];
  options.trbflag  = 'bottom'; %'top';
  options.tsqlim   = 0.99;
  options.stopcrit = [1e-4 1e-4 1000 360];
  options.initwt   = [];

  if nargout==0; 
    evriio(mfilename,varargin{1},options); 
  else
    y_b   = evriio(mfilename,varargin{1},options); 
  end
  return; 
end
warning off backtrace

if nargin<1
  error('BASELINEW requires at least 1 input.')
end
[m,n]     = size(y);

if nargin<6               %set default options
  options = baselinew('options');
else
  options = reconopts(options,baselinew('options'));
end
if nargin<5
  res     = 0;
elseif isempty(res)
  res     = 0;
end
if nargin<4  %nbg 10/31/05
  order   = [];            %default order
end
if isempty(order)
  if isempty(options.p)
    error('Both (order) and (options.p) can not both be empty.')
  end
end
if nargin<3 | width==0
  width   = [ ];  %default width
end
if ~isempty(width)
  if width/2-round(width/2)==0
    width = width-1;
  end
end
if ~isempty(options.p)
  x       = [];
elseif nargin<2 & isempty(options.p)
  x       = 1:n;
elseif isempty(x) & isempty(options.p)
  x       = 1:n;
else
  if prod(size(x))>length(x) | prod(size(x))==1
    error('For (y) MxN, input (x) must be a vector with N elements.')
  end
  if length(x)~=n
    error('For (y) MxN, input (x) must be a vector with N elements.')
  end
end
if isempty(options.initwt)
  options.initwt = ones(1,n);
end
switch lower(options.display)
case 'on'
  hwait   = waitbar(0,'BASELINEW computing baseline');
end
tsqst     = ttestp(1-options.tsqlim,5000,2);

if isempty(width) %non-windowed approach
  switch lower(options.display)
  case 'on'
    waitbar(0.01,hwait);
  end
  if order==0 & isempty(options.p) %Calls MED2TOP
    b_b       = zeros(m,n);
    for i0=1:m
      [temp,resid] = med2top(y(i0,:)',options);
      b_b(i0,:)    = temp(:)';
      switch lower(options.display)
      case 'on'
        waitbar(i0/m,hwait)
      end
    end
  elseif isempty(order) & ~isempty(options.p)
    b_b       = zeros(m,n);
    %opts      = options;
    for i0=1:m
      temp      = lsq2topb([],y(i0,:)',[],res,options);
      b_b(i0,:) = temp(:)';
      switch lower(options.display)
      case 'on'
        waitbar(i0/m,hwait)
      end
    end
  else
    x         = x(:);
    b_b       = zeros(m,n);
    %opts      = options;
    for i0=1:m
      temp      = lsq2topb(x',y(i0,:)',order,res,options);
      b_b(i0,:) = temp(:)';
      switch lower(options.display)
      case 'on'
        waitbar(i0/m,hwait)
      end
    end
  end
else %windowed approach
  p         = (width-1)/2;
  if order==0 & isempty(options.p) %Calls MED2TOP
    opts    = options;
    switch lower(options.display)
    case 'on'
      waitbar(0.01,hwait);
    end
    for i0=1:m
      i1    = p+1;     %left side (might change to shrink the window)
      opts.initwt     = options.initwt(i1-p:i1+p);    
      [b,resid]       = med2top(y(i0,i1-p:i1+p)',opts);
      b_b(i0,i1-p:i1) = b;

      for i1=p+2:n-p-1   %middle
        opts.initwt   = options.initwt(i1-p:i1+p);
        switch lower(options.trbflag)
        case 'bottom'
          tsq         = resid(2:end)/sqrt(mean(resid(2:end).^2));
          opts.initwt(find(tsq>=tsqst)) = 0;
        case 'top'
          tsq         = resid(2:end)/sqrt(mean(resid(2:end).^2));
          opts.initwt(find(tsq<=tsqst)) = 0;
        end      
        [b,resid]     = med2top(y(i0,i1-p:i1+p)',opts);
        b_b(i0,i1)    = b;
      end

      i1    = n-p;     %right side
      opts.initwt = options.initwt(i1-p:i1+p);
      switch lower(options.trbflag)
      case 'bottom'
        tsq           = resid(2:end)/sqrt(mean(resid(2:end).^2));
        opts.initwt(find(tsq>=tsqst)) = 0;
      case 'top'
        tsq           = resid(2:end)/sqrt(mean(resid(2:end).^2));
        opts.initwt(find(tsq<=tsqst)) = 0;
      end
      b               = med2top(y(i0,i1-p:i1+p)',opts);
      b_b(i0,i1:i1+p) = b;
      switch lower(options.display)
      case 'on'
        waitbar(i0/m,hwait)
      end
    end  
  else %Calls LSQ2TOP
    x         = x(:);
    b_b       = zeros(m,n);
    opts      = options;
    switch lower(options.display)
    case 'on'
      waitbar(0.01,hwait);
    end  
    for i0=1:m
      i1      = p+1;     %left side
      opts.initwt = options.initwt(i1-p:i1+p);
      if ~isempty(options.p), opts.p = options.p(i1-p:i1+p,:); end
      b = lsq2topb(x(i1-p:i1+p),y(i0,i1-p:i1+p),order,res,opts);
      b_b(i0,i1-p:i1) = b(1:p+1)';

      i1      = n-p;     %right side
      opts.initwt = options.initwt(i1-p:i1+p);
      if ~isempty(options.p), opts.p = options.p(i1-p:i1+p,:); end
      b       = lsq2topb(x(i1-p:i1+p),y(i0,i1-p:i1+p),order,res,opts);
      b_b(i0,i1:i1+p) =  b(end-p:end)';
    end
    for i0=1:m
      opts.initwt  = options.initwt(i1-p:i1+p);
      for i1=p+2:n-p-1   %middle
        if ~isempty(options.p), opts.p = options.p(i1-p:i1+p,:); end
        [b,resnorm,resid,opts] = lsq2topb(x(i1-p:i1+p),y(i0,i1-p:i1+p),order,res,opts);
        b_b(i0,i1) = b(p+1);
        %opts.initwt  = [min([opts.initwt(2:end)'+0.1; ones(1,width-1)]) initwt(i1+p)];
      end
      switch lower(options.display)
      case 'on'
        waitbar(i0/m,hwait)
      end
    end
  end
end
y_b       = y-b_b;
switch lower(options.display)
case 'on'
  close(hwait);
end
