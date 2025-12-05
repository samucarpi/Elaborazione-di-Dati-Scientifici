function [y,z,options,p,a] = datafit_engine(y,options)
%DATAFIT_ENGINE Asymmetric least squares with smoothing, baselining & robust fitting.
%  DATAFIT_ENGINE is used to A) provide a smoothed estimate (z) of the rows
%  of input (y) or B) a baselined estimate the rows of input (y). In each
%  case the objective function to be minimized is given by
%    O(z) = (y-z)'*W0*(y-z) + lambdas*z'*Ds'*Ws*Ds*z +
%           lambdae*(y-ye-z)'*We*(y-ye-z) + lambdab*(Pa-z)'*Wb*(Pa-z) (1).
%  The weights W are diagonal matrices with entries 0<w<1 allowing
%  individual points in the optimization to be weighted differently.
%  The penalty magnitude is given by the scalar lambda factors.
%
%  E.g., the first term in (1) includes W0 that has zeros where data are
%  missing and ones elsewhere.
%  The second term uses a smoothing operator Ds and penalty factor lambdas
%  to penalize roughness (by default Ds is the second difference operator).
%  The third term is used to include equality constriants with penalty
%  factor lambdae (if included) and
%  the fourth term allows for basis functions (P) to be used (if included).
%
%  A) Smoothing is obtained using options.trbflag = 'none' or 'middle'.
%     In this case the output (z), the smoothed estimate of (y) is likey
%     desired. Output yb = y - z would then correspond to fit residuals.
%     if options.trbflag = 'middle' a robust fitting strategy is used.
%
%  B) Baselining is obtained using options.trbflag = 'top' or 'bottom' via
%     an asymmetric least squares fitting strategy. In this case the output
%     (yb) is the baselined estimate of (y) and output (z) corresponds to
%     the baseline.
%  See additional information on (options.trbflag) below.
%
%  INPUT:
%      y = MxN matrix of ROW vectors to be smoothed/fit. Input (y) can be
%          class DataSet or double.
%
%  OUTPUTS:
%     yb = y - z
%      z = the smoothed estiamte of (y).
%
%  OPTIONAL INPUT:
%   options = struture array with the following fields:
%     display: [ 'off' | {'on'}] governs level of display (waitbar on/off).
%     trbflag: [ {'none'} | 'middle' | 'bottom' | 'top' ]
%              'none' runs the smoother once (see WSMOOTH),
%              'middle' uses robust least squares to fit a curve
%                to the middle of the data,
%              'bottom' uses asymmetric least squares to fit a curve to the 
%                bottom of the data (e.g., baselining spectra),
%              'top'    uses asymmetric least squares to fit a curve to the
%                top    of the data (e.g., fitting a Plank function).
%    parallel: [{true} | false] use parallel computing toolbox if available
%
%   Constraints, penalties and weights.
%          w0: {ones(1,N)} weights on the fit term:      (y-z)'*W0*(y-z);
%              [] if empty or not length N then 
%                 w0(y.include{2}) := 1 for (y) class DataSet or
%                 w0 := ones(1,N) for (y) class double.
%     lambdas: {1} Positive scalar defines how hard to smooth. Typically
%                 10 < lambdas <1e6 with large values giving more smoothing.
%          ws: {ones(1,N)} weights on the smoothing term lambdas*z'*Ds'*Ws*Ds*z;
%              [] if empty or not length N then ws := ones(1,N).
%      widths: {3} Smoothing window width for Ds (see SAVGOL). (Typically=3).
%      orders: {2} Smoothing polynomial order for Ds (see SAVGOL). (Typically=2).
%      derivs: {2} Smoothing derivative for Ds (see SAVGOL). (Typically=2).
%     lambdae: {0} Positive scalar defines how hard to fit to equality constraints.
%                  Typically 0 <= lambdae <1e6.
%          ye: {NaN(1,N)} non-NaN entries are the equality constraints on z,
%                  NaN entries are unconstrained.
%          we: {zeros(1,N)} weights on equality constraint term lambdae*(z-y-ye)'*We*(z-y-ye)
%                  we(isnan(ye)) = 0, we(~isnan(ye)) = 1.
%     lambdab: {0} Positive scalar defines how hard to fit to basis function(s).
%                  Typically 0 < lambdab <1e6.
%          wb: {zeros(1,N)} weights on basis function term lambdab*(z-Pa)'*Wb*(z-Pa)
%      orderp: {[]} polynomial order (scalar >=0) (see POLYBASIS).
%       knotp: {[]} (scalar integer >=1) integer defining the number of uniformly
%                     distributed INTERIOR knots there are then knotp+2 knots 
%                     positioned at t = linspace(1,N,knotp+2);  (see SMOOTHBASIS)
%                   (1xKt vector) defining manually placed knot positions on [1:N].
%                      Note: that knot positions must be such that there are
%                            at least 3 unique data points between eachknot.
%      basisp: {[]} NxKb custom basis. It is recommended that each column
%                     normalized to unit length (2-norm).
%      nonneg: {[0] | 1 } scalar indiacting if non-negativity should be
%                     applied to the coefficients on (options.basisp). The
%                     default is 0 = no.
%                   Kbx1 vector of indices (ones and zeros) indicating which
%                   coefficients should be non-negative. (See FASTERNNLS);         
%
%   Robust and asymmetric iterative fitting parameters.
%         tol: {[]} is the base fit tolerance (scalar). If empty it is
%                  estimated by the mean absolute deviation of
%                  y.data - savgol(y.data,3,1,0); (see MADAC).
%        tfac: {[1]} tolerance factor where res = (y.data-z)/(tol*tfac) is a 
%                  considered large residual.
%           p: {0.01} "asymmetry factor", where at each iteration
%                  w0 = (res>tol*tfac)*p+(res<=tol*tofac) .
%       ittol: {1e-3} relative tolerance exit criterion norm(w0-w0old)/norm(w0)<ittol.
%       itmax: {100} maximum iterations exit criterion.
%     timemax: {600} maximum time (s) for each row of y exit criterion.
%
%I/O: [yb,z,options]  = datafit_engine(y,options);
%     options = datafit_engine('options');
%
%See also: BASELINEW, WLSBASELINE, POLYBASIS, SMOOTHBASIS, WSMOOTH

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg

%can call datafit_engine for EMSC - output P and a for potential calls from EMSC?
%loop over samples --> parfor
%need some help on optiondefs function
%output P for preprocessing and and a for part of the tool's analysis

%% Options
if nargin==0; y = 'io'; end
if ischar(y)
  options         = [];
  options.display = 'on';
  
  options.trbflag = 'none'; %'bottom', %'top', 'middle'
  options.parallel = true;
  options.widths  = 3;      % savgol width for Ds
  options.orders  = 2;      % savgol order for Ds
  options.derivs  = 2;      % savgol deriv for Ds 
  
  options.tol     = [];     % tolerance (residual)
  options.tfac    = 1;      % tol*tofac is threshold (mostly used for tol empty)
  options.p       = 0.01;   % asymmetry factor w0 = (res>tol*tfac)*p+(res<=tol*tofac)
  options.ittol   = 1e-3;   % norm(w0-w0old)/norm(w0)<ittol exit criterion
  options.itmax   = 100;    % max iterations exit criterion
  options.timemax = 600;    % max time (seconds) for each row of y exit criterion
  
  options.w0      = [];     % if empty or not length n it uses .include{2}
  options.lambdas = 1;      %  0 < penalty <1e6 Smoothness
  options.ws      = [];     % if empty it uses ones(1,n)
  options.lambdae = 0;      %  0 < penalty <1e6 Equality
  options.we      = [];     % if empty it uses zeros(1,n)
  options.ye      = [];     % if empty it uses NaN(1,n)
  options.lambdab = 0;      %  0 < penalty <1e6 Basis Functions
  options.wb      = [];     % if empty it uses ones(1,n)
  options.orderp  = [];     % polynomial order      for polybasis
  options.knotp   = [];     % spline knots (scalar) for smoothbasis
  options.basisp  = [];     % custom basis NxK
  options.nonneg  = [];     % scalar (yes/no), or Kbx1 vector for fastnnls

  options.definitions = @optiondefs;
  if nargout==0
    evriio(mfilename,y,options);
  else
    y = evriio(mfilename,y,options);
  end
  return;
end

[m,n]          = size(y);
 % Handle DSO
if isa(y,'dataset')
  wasdso     = true;
else
  y          = dataset(y);
  wasdso     = false;
end

if nargin<2
  options    = datafit_engine('options');
end
if nargin<2              %set default options
  options    = datafit_engine('options');
else
  options    = reconopts(options,datafit_engine('options'));
end
if isempty(options.lambdas) || options.lambdas<=0 || any(options.w0<0)
  error('Input (options.lambdas) cannot be empty or <=0, (options.w0) cannot be <0.')
end
if options.lambdab<0 || any(options.wb<0)
  error('Input (options.lambdab) cannot be empty or <0, (options.wb) cannot be <0. ')
end
if options.lambdae<0 || any(options.we<0)
  error('Input (options.lambdae) cannot be empty or <0, (options.we) cannot be <0. ')
end

%% Initialize
if strcmpi(options.display,'on')
  hwait    = waitbar(0,'DataFit Engine Working.');
end

% Initialize weights
%  w0 is weights on (y-z)'*W0((y-z)
if isempty(options.w0) || length(options.w0)~=n %set initial weights W0 (use only included)
  if wasdso
    options.w0     = zeros(1,n);
    options.w0(y.include{2}) = 1;
  else
    options.w0     = ones(1,n);
  end
end
options.w0         = options.w0(:)';
%  ws is weights on ls z'*Ds'*Ws*Ds*z
if isempty(options.ws) || length(options.ws)~=n %set weights Ws
  options.ws       = ones(1,n);
end
options.ws   = options.ws(:)';
%  wb is weights on lb*(z-P*a)'*Wb*(z-P*a)
if isempty(options.wb) || length(options.wb)~=n %set weights Wb
  options.wb       = ones(1,n);
end
options.wb   = options.wb(:)';
% we is weights on le*(z-y-ye)'*We*(z-y-ye)
if isempty(options.ye) || options.lambdae==0
  options.lambdae  = 0;
  options.we       = zeros(1,n);
  options.ye       = zeros(1,n);
elseif length(options.ye)~=n
  error('Input (options.ye) must be length N.')
else
  if isempty(options.we)
    options.we     = ones(1,n);
  end
  options.we(isnan(options.ye)) = 0;
  options.ye(isnan(options.ye)) = 0;
end
options.we   = options.we(:)';
options.ye   = options.ye(:)';

% Initialize basis functions P if used
if all([isempty(options.orderp) isempty(options.knotp) isempty(options.basisp)]) || ...
       isempty(options.lambdab) || options.lambdab<=0
  usebasis         = false;
  options.lambdab  = 0;
  usenonneg        = false;
  p                = [];
  a                = [];
else
  if ~isempty(options.basisp)
    if size(options.basisp,1)~=n
      error('Input (options.basisp): size(options.basisp,1) must equal N')
    end
    if ~isempty(options.knotp)
      p            = [smoothbasis(1:n,options.knotp,options.orderp),options.basisp];
    elseif ~isempty(options.orderp)
      p            = [polybasis(1:n,options.orderp),options.basisp];
    else
      p            = options.basisp;
    end
    if isempty(options.nonneg)
      usenonneg    = false; %this input not included in subsequent calls
    else
      if isscalar(options.nonneg)
        if options.nonneg==0
          usenonneg  = false;
        else
          usenonneg  = true;
          options.nonneg = ones(size(options.basisp,2),1);
        end
      else
        if length(options.nonneg)~=size(options.basisp,2)
          error('Input (options.nonneg) must be a scalar or size(options.basisp,2)x1 vector of ones and zeros')
        end
        options.nonneg = options.nonneg(:);
        usenonneg    = true;    
      end
    end
  else
    if ~isempty(options.knotp)
      p            = smoothbasis(1:n,options.knotp,options.orderp);
    elseif ~isempty(options.orderp)
      p            = polybasis(1:n,options.orderp);
    end
    usenonneg      = false;
  end
  usebasis         = true;
  k                = size(p,2);
  if usenonneg
    kb             = k-length(options.nonneg);
  end
end

%% Initialize smoothing operator
[r,ds]       = savgol(1:n,options.widths,options.orders,options.derivs,struct('tails','weighted')); %r is temporary
ws           = options.lambdas*options.ws;
ws([1 end])  = options.p*ws([1 end]);
ws           = ds*spdiag(ws)*ds';
we           = options.lambdae*options.we;
wb           = options.lambdab*options.wb;

%% Initial fit for z, same as options.trbflag = 'none'
if usebasis
  d1         = spdiag(options.w0 + wb + we) + ws;
  d2         = spdiag(wb)*p;
  r          = [d1 -d2; -d2' p'*d2];
  switch lower(options.trbflag)
  case {'none','middle'}
    if usenonneg
      z        = fasternnls(full(r),[y.data*spdiag(options.w0) + ...
                   options.ye(ones(m,1),:)*spdiag(we), zeros(m,k)]', ...
                   [],[],[],[zeros(size(d1,1),1); zeros(kb,1); options.nonneg])';
    else
      r        = chol(r);
      z        = [y.data*spdiag(options.w0) + ...
                   options.ye(ones(m,1),:)*spdiag(we), zeros(m,k)]/r/r';
    end
  case {'bottom','top'}
    if usenonneg
      z        = fasternnls(full(r),[y.data*spdiag(options.w0) + ...
                   (y.data-options.ye(ones(m,1),:))*spdiag(we), zeros(m,k)]', ...
                   [],[],[],[zeros(size(d1,1),1); zeros(kb,1); options.nonneg])';
    else
      r        = chol(r);
      z        = [y.data*spdiag(options.w0) + ...
                   (y.data-options.ye(ones(m,1),:))*spdiag(we), zeros(m,k)]/r/r';
    end
  end
  a          = z(:,end-k+1:end);
  z          = z(:,1:end-k);
else
  r          = chol(spdiag(options.w0 + we) + ws);
  switch lower(options.trbflag)
  case {'none','middle'}
    z          = (y.data*spdiag(options.w0) + ...
                 options.ye(ones(m,1),:)*spdiag(we))/r/r';
  case {'bottom','top'}
    z          = (y.data*spdiag(options.w0) + ...
                 (y.data-options.ye(ones(m,1),:))*spdiag(we))/r/r';
  end
end

% Get an estimate for options.tol
switch lower(options.trbflag)
case {'middle','top','bottom'}
  if isempty(options.tol)
    options.tol    = y.data - savgol(y.data,3,1,0);
    options.tol    = madc(options.tol(:,y.include{2}));
    if m>1
      options.tol  = madc(options.tol(:));
    end
  end
  tol        = options.tol*options.tfac; %anisoptropy limit
  tmfac      = 3600*24; %time limit
end

%% Main loop for assymetric estimate

if options.parallel
  initevripct;    % Start parpool if available
end

switch lower(options.trbflag)
case {'top','bottom'}
  switch lower(options.trbflag)
  case 'top'
    sg       = -1;
  case 'bottom'
    sg       =  1;
  end
  if usebasis 
    if ~usenonneg
      parfor i1=1:m %110818
        w0old        = options.w0;
        stim         = now;
        for i2=1:options.itmax      
          tmp        = sg*(y.data(i1,:)-z(i1,:))/tol;
          w0         = (tmp>1)*options.p + (tmp<=1);
          d1         = spdiag(w0 + wb.*w0 + we) + ws;
          d2         = spdiag(wb.*w0)*p;
          r          = chol([d1 -d2; -d2' p'*d2]);
          d2         = [y.data(i1,:).*w0 + ...
                       (y.data(i1,:)-options.ye).*we, zeros(1,k)]/r/r';
          a(i1,:)    = d2(:,end-k+1:end);
          z(i1,:)    = d2(:,1:end-k);

          if norm(w0old-w0)/norm(w0)<options.ittol || (now-stim)*tmfac>options.timemax
            break;
          end
          w0old = w0;
        end
%         if strcmpi(options.display,'on')
%           waitbar(i1/m,hwait)
%         end
      end
    else 
      parfor i1=1:m %110818
        w0old        = options.w0;
        stim         = now;
        for i2=1:options.itmax      
          tmp        = sg*(y.data(i1,:)-z(i1,:))/tol;
          w0         = (tmp>1)*options.p + (tmp<=1);
          d1         = spdiag(w0 + wb.*w0 + we) + ws;
          d2         = spdiag(wb.*w0)*p;
          
          r          = [d1 -d2; -d2' p'*d2];
          d2         = fasternnls(full(r),[y.data(i1,:).*w0 + ...
                         (y.data(i1,:)-options.ye).*we, zeros(1,k)]', ...
                         [],[],[],[zeros(size(d1,1),1); zeros(kb,1); options.nonneg])';
          a(i1,:)    = d2(:,end-k+1:end);
          z(i1,:)    = d2(:,1:end-k);

          if norm(w0old-w0)/norm(w0)<options.ittol || (now-stim)*tmfac>options.timemax
            break;
          end
          w0old = w0;
        end
%         if strcmpi(options.display,'on')
%           waitbar(i1/m,hwait)
%         end
      end
    end
  else
    parfor i1=1:m %110818
      w0old        = options.w0;
      stim         = now;
      for i2=1:options.itmax      
        tmp        = sg*(y.data(i1,:)-z(i1,:))/tol;
        w0         = (tmp>1)*options.p + (tmp<=1);
        r          = chol(spdiag(w0 + we) + ws);
        z(i1,:)    = (y.data(i1,:).*w0 + ...
                     (y.data(i1,:)-options.ye).*we)/r/r';

        if norm(w0old-w0)/norm(w0)<options.ittol || (now-stim)*tmfac>options.timemax
          break;
        end
        w0old = w0;
      end
%       if strcmpi(options.display,'on')
%         waitbar(i1/m,hwait)
%       end
    end
  end
case 'middle'
  if usebasis
    if ~usenonneg
      parfor i1=1:m %110818
        w0old        = options.w0;
        stim         = now;
        for i2=1:options.itmax      
          tmp        = abs(y.data(i1,:)-z(i1,:))/tol;
          w0         = (tmp>1)*options.p + (tmp<=1);
          d1         = spdiag(w0 + wb.*w0 + we) + ws;
          d2         = spdiag(wb.*w0)*p;
          r          = chol([d1 -d2; -d2' p'*d2]);
          d2         = [y.data(i1,:).*w0 + options.ye.*we, zeros(1,k)]/r/r';
          a(i1,:)    = d2(:,end-k+1:end);
          z(i1,:)    = d2(:,1:end-k);

          if norm(w0old-w0)/norm(w0)<options.ittol || (now-stim)*tmfac>options.timemax
            break;
          end
          w0old = w0;
        end
%         if strcmpi(options.display,'on')
%           waitbar(i1/m,hwait)
%         end
      end
    else
      parfor i1=1:m %110818
        w0old        = options.w0;
        stim         = now;
        for i2=1:options.itmax      
          tmp        = abs(y.data(i1,:)-z(i1,:))/tol;
          w0         = (tmp>1)*options.p + (tmp<=1);
          d1         = spdiag(w0 + wb.*w0 + we) + ws;
          d2         = spdiag(wb.*w0)*p;
          
          r          = [d1 -d2; -d2' p'*d2];
          d2         = fasternnls(full(r),[y.data(i1,:).*w0 + ...
                         options.ye.*we, zeros(1,k)]', ...
                         [],[],[],[zeros(size(d1,1),1); zeros(kb,1); options.nonneg])';
          a(i1,:)    = d2(:,end-k+1:end);
          z(i1,:)    = d2(:,1:end-k);

          if norm(w0old-w0)/norm(w0)<options.ittol || (now-stim)*tmfac>options.timemax
            break;
          end
          w0old = w0;
        end
%         if strcmpi(options.display,'on')
%           waitbar(i1/m,hwait)
%         end
      end
    end
  else
    parfor i1=1:m %110818
      w0old        = options.w0;
      stim         = now;
      for i2=1:options.itmax      
        tmp        = abs(y.data(i1,:)-z(i1,:))/tol;
        w0         = (tmp>1)*options.p + (tmp<=1);
        r          = chol(spdiag(w0 + we) + ws);
        z(i1,:)    = (y.data(i1,:).*w0 + options.ye.*we)/r/r';

        if norm(w0old-w0)/norm(w0)<options.ittol || (now-stim)*tmfac>options.timemax
          break;
        end
        w0old = w0;
      end
%       if strcmpi(options.display,'on')
%         waitbar(i1/m,hwait)
%       end
    end
  end
end

if ~wasdso
  y = y.data-z;
else
  z = copydsfields(y,dataset(z));
  y.data = y.data-z.data;
end

if strcmpi(options.display,'on')
  close(hwait)
end

function out = optiondefs

defs = {
  %name                    tab           datatype      valid                            userlevel       description
  'display'                'Display'     'select'      {'off' 'on'}                     'novice'        'Governs level of display. ''on'' displays waitbar.';
  'trbflag'                'Algorithm'   'select'      {'none' 'middle' 'bottom' 'top'} 'intermediate'  'Smooth, Robust smooth, Baseline bottom of data, Baseline to top of data.';
  'w0'                     'Weights W0'  'double'       []                              'intermediate'  'Weights on fit term: (y-z)''*W0*(y-z), 0<w0<1.';
  'lambdas'            'Smooth penalty'  'double'       []                              'novice'        'Smoothing penalty: Typically 10 < lambdas <1e6.';
  'ws'                     'Weights Ws'  'double'       []                              'intermediate'  'Weights on smooth term: lambdas*z''*Ds''*Ws*Ds*z, 0<ws<1';
  'widths'           'Smoothing window'  'double'       []                              'advanced'      'Smoothing window width for Ds (see SAVGOL). (Typically=3).';
  'orders'            'Smoothing order'  'double'       []                              'advanced'      'Smoothing polynomial order for Ds (see SAVGOL). (Typically=2).';
  'derivs'       'Smoothing derivative'  'double'       []                              'advanced'      'Smoothing derivative for Ds (see SAVGOL). (Typically=2).';
  'lambdae'          'Equality penalty'  'double'       []                              'intermediate'  'Equality penalty: Typically 0 < lambdae <1e6.';
  'ye'           'Equality Constraints'  'double'       []                              'intermediate'  '1xN vector of equality constraints on z, non-NaN entries are the equality constraints, Nan entries are unconstrained.';
  'we'                     'Weights We'  'double'       []                              'intermediate'  'Weights on equality constraint term: lambdae*(z-y-ye)''*We*(z-y-ye), 0<we<1.';
  'lambdab'             'Basis Penalty'  'double'       []                              'novice'        'Basis Penalty: Typically 0 < lambdab <1e6.';
  'wb'                     'Weights Wb'  'double'       []                              'intermediate'  'Weights on basis function term: lambdab*(z-Pa)''*Wb*(z-Pa), 0<wb<1.';
  'orderp'                'Basis Order'  'double'       []                              'novice'        'Basis function polynomial order (integer scalar >=0) (see POLYBASIS).';
  'knotp'          'Number of B3 knots'  'double'       []                              'intermediate'  'Number of interior B3 spline knots (integer scalar >=1) (see SMOOTHBASIS).';
  'basisp'               'Custom basis'  'double'       []                              'advanced'      'NxK set of K custom basis functions.';
  'tol'                 'Fit tolerance'  'double'       []                              'intermediate'  'Fit tolerance (scalar). If empty it is estimated by the mean absolute deviation of y.data - savgol(y.data,3,1,0); (trgflag ~= ''none'') (see MADAC).';
  'tfac'             'Tolerance factor'  'double'       []                              'intermediate'  'Tolerance factorwhere res = (y.data-z)/(tol*tfac) is considered a large residual (trgflag ~= ''none'').';
  'p'                'Asymmetry factor'  'double'       []                              'intermediate'  'Asymmetry factor", where at each iterationw0 = (res>tol*tfac)*p+(res<=tol*tofac) (trgflag ~= ''none'')';
  'ittol'               'Exit Criteria'  'double'       []                              'intermediate'  'Relative change-of-fit convergence criterion (trgflag ~= ''none''): norm(w0-w0old)/norm(w0)<ittol';
  'itmax'               'Exit Criteria'  'double'       []                              'intermediate'  'Maximum iterations allowed per row of input(y)  (trgflag ~= ''none'').';
  'timemax'             'Exit Criteria'  'double'       []                              'intermediate'  'Maximum time (in seconds) permitted for row of input(y) (trgflag ~= ''none'').';
  };
out = makesubops(defs);
