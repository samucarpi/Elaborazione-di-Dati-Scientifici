function [x,fval,exitflag,out] = lmoptimizebnd(fun,x0,xlow,xup,options,varargin)
%LMOPTIMIZEBND Bounded Levenberg-Marquardt non-linear optimization
%  Starting at (x0) LMOPTIMIZEBND finds (x) that minimizes the function
%  defined by the function handle (fun). Inputs (xlow) and (xup) can be used
%  to provide lower and upper bounds on the solution (x). The function (fun)
%  must supply the Jacobian and Hessian i.e. they are not estimated by
%  LMOPTIMIZEBND.
%
%  INPUTS:
%         fun = function handle, the call to fun is
%                 [fval,jacobian,hessian] = fun(x)
%               [see documentation in manual for tips on writing (fun)].
%           (fval) is a scalar objective function value,
%           (jacobian) is a Nx1 vector of Jacobian values, and
%           (hessian) is a NxN matrix of Hessian values.
%          x0 = Nx1 initial guess of the function parameters.
%        xlow = Nx1 corresponding lower bounds on (x). See options.alow.
%               If an element of (xlow) == -inf, it is unbounded on the low side.
%         xup = Nx1 corresponding upper bounds on (x). See options.aup.
%               If an element of (xup) == inf, it is unbounded on the high side.
%
%  OPTIONAL INPUTS:
%     options = structure array with the following fields:
%               (if options is empty [ ], the defaults are used)
%       display: [ 'off' | {'on'} ]      governs level of display to
%                command window.
%      dispfreq: 10 , display every nth iteration {default=10}.
%      stopcrit: [1e-8 1e-10 10000 3600]  defines the stopping criteria as
%                [(relative tolerance) (absolute tolerance) (maximum number
%                of iterations) (maximum time in seconds)].
%             x: [ {'off'} | 'on' ] saves x at each step.
%          fval: [ {'off'} | 'on' ] saves fval at each step.
%      Jacobian: [ {'off'} | 'on' ] saves last evaluation of the Jacobian.
%       Hessian: [ {'off'} | 'on' ] saves last evaluation of the Hessian.
%          alow: [], Nx1 vector of penalty weights for lower bound,
%                 {default = ones(N,1)}.
%                 If an element is zero, that parameter is not bounded.
%           aup: [], Nx1 vector of penalty weights for upper bound
%                 {default = ones(N,1)}.
%                 If an element is zero, that parameter is not bounded.
%     (see Reference Manual entry for additional options used to
%      control the optimization)
%
%      params = comma separated list of additional parameters passed to the
%               objective function (fun), the call to (fun) is
%                 [fval,jacobian,hessian] = fun(x,params1,params2,...).
%
%  OUTPUTS:
%           x = Nx1 vector of parameter value(s) at the function minimum.
%        fval = scalar value of the function evaluated at (x).
%    exitflag = describes the exit condition with the following values
%               1: converged to a solution (x) based on one of the
%                  tolerance criteria
%               0: convergence terminated based on maximum iterations
%                  or maximum time.
%         out = structure array with the following fields:
%     critfinal: final values of the stopping criteria (see
%                options.stopcrit above).
%             x: intermediate values of (x) if options.x=='on'.
%          fval: intermediate values of (fval) if options.fval=='on'.
%      Jacobian: last evaluation of the Jacobian if options.Jacobian=='on'.
%       Hessian: last evaluation of the Hessian if options.Hessian=='on'.
%
%I/O: [x,fval,exitflag,out] = lmoptimizebnd(fun,x0,xlow,xup,options,params);
%
%See also: FUNCTION_HANDLE, LMOPTIMIZE

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NBG modified LMOPTIMIZE 6/05

if nargin<1
  error('LMOPTIMIZEBND requires at least 1 input.')
end
if nargin == 0; fun = 'io'; end
if ischar(fun);
  options = [];
  options.name     = 'options';
  options.display  = 'on';
  options.dispfreq = 10;
  options.stopcrit = [1e-8 1e-10 10000 3600];
  options.x        = 'off';
  options.fval     = 'off';
  options.Jacobian = 'off';
  options.Hessian  = 'off';
  options.alow     = [];
  options.aup      = [];
  options.ncond    = 1e6;        %max condition number for Hessian
  options.lamb     = [1e-6 0.9 1.5];
    %lamb(1): damping factor * biggest eigenvalue of H is added damping
    %lamb(2): lamb(1) = lamb(1)/lamb(2) causes deceleration in line search
    %lamb(3): lamb(1) = lamb(1)/lamb(3) causes acceleration in line search
  options.ramb     = [1e-4 0.5 1e-5];
    %ramb(1): if fullstep not < options.ramb(1)*[newton step] back up
    %ramb(2): if fullstep nearly a newton step, accelerate
    %ramb(3): if linesearch rejected, make a small movement
  options.kmax     = 50;        %max steps in line search
  if nargout==0; 
    evriio(mfilename,fun,options); 
  else
    x = evriio(mfilename,fun,options); 
  end
  return; 
end
if nargin<5 | isempty(options) %set default options
  options  = lmoptimizebnd('options');
else
  options = reconopts(options,lmoptimizebnd('options'));
end
if nargin<6
  varargin = cell(0);
end

%Initialization
x0               = x0(:)'; %Make x a row vector
n                = length(x0);
x                = x0;
if isempty(varargin)
  fval           = feval(fun,x);             %fval
else
  fval           = feval(fun,x,varargin{:}); %fval   
end
fvalold          = fval;
if nargin<3|isempty(xlow)
  xlow           = zeros(1,n);
  options.alow   = zeros(1,n);
else
  xlow           = xlow(:)';
end
if isempty(options.alow)
  options.alow   = ones(1,n);
elseif n~=length(options.alow)
  error('Number of elements in (x) and (options.alow) must be the same.')
end
if any(options.alow<0)
  error('All elements in (options.alow) must be >=0.')
end
i1               = find(~isfinite(xlow));
if ~isempty(i1)
  xlow(i1)       = zeros(1,length(i1));
  options.alow(i1) = zeros(1,length(i1));
end
i1lo             = find(options.alow>0);
if ~isempty(i1lo)
  if any(xlow(i1lo)>x0(i1lo))
    disp(' ')
    disp(['Parameter(s): ',int2str(i1lo(find(xlow(i1lo)>x0(i1lo))))])
    error('All active lower bounds must be < x0.') 
  end
end
options.alow     = options.alow(:);
if nargin<4|isempty(xup)
  xup            = zeros(1,n);
  options.aup    = zeros(1,n);
else
  xup            = xup(:)';
end
if isempty(options.aup)
  options.aup    = ones(1,n);
elseif n~=length(options.aup)
  error('Number of elements in (x) and (options.aup) must be the same.')
end
if any(options.aup<0)
  error('All elements in (options.aup) must be >=0.')
end
i1               = find(~isfinite(xup));
if ~isempty(i1)
  xup(i1)        = zeros(1,length(i1));
  options.aup(i1) = zeros(1,length(i1));
end
i1up             = find(options.aup>0);
if ~isempty(i1up)
  if any(xup(i1up)<x0(i1up))
    disp(' ')
    disp(['Parameter(s): ',int2str(i1up(find(xup(i1up)<x0(i1up))))])
    error('All active upper bounds must be > x0.')
  end
end
options.aup      = options.aup(:);
out.critfinal    = zeros(1,4);
out.critfinal(1) = inf;
out.critfinal(2) = inf;
out.critfinal(3) = 0;
tx               = strcmpi(options.x,'on');
if tx
  out.x          = zeros(options.stopcrit(3),length(x0))*NaN;
else
  out.x          = [];  
end
tfval            = strcmpi(options.fval,'on');
if tfval
  out.fval       = zeros(options.stopcrit(3),1)*NaN;
else
  out.fval       = [];  
end
out.Jacobian     = [];
out.Hessian      = [];
t0               = clock;
dispits          = 0;
%Main While Loop
while all(out.critfinal(1:2)> options.stopcrit(1:2))&...
      all(out.critfinal(3:4)< options.stopcrit(3:4))
  out.critfinal(3) = out.critfinal(3)+1;
  if isempty(varargin)
    [fval,j,h]   = feval(fun,x);             %fval, Jacobian, Hessian
  else
    [fval,j,h]   = feval(fun,x,varargin{:}); %fval, Jacobian, Hessian    
  end
  [fvall,jl,hl]  = glowbound(x,options.alow,xlow);
  [fvalu,ju,hu]  = gupbound(x,options.aup,xup);
  fval           = fval+fvall+fvalu;
  j              = j+jl+ju;
  h              = h+hl+hu;
  [u,s1,v]       = svd(h);               %SVD of H for estimating inverse
  s1             = diag(s1);
  dx        = -(u*diag(1./(s1+options.lamb(1)*s1(1)))*v')*j; %full step size
  xfs       = x+dx';                                  %x w/ full step
  if any(xfs(i1lo)<xlow(i1lo))|any(xfs(i1up)>xup(i1up))
    ibd     = find(xfs(i1lo)<xlow(i1lo));
    dx(i1lo(ibd))  = (xlow(i1lo(ibd))-x(i1lo(ibd)))*0.9; 
    ibd     = find(xfs(i1up)>xup(i1up));
    dx(i1up(ibd))  = (xup(i1up(ibd)) -x(i1up(ibd)))*0.9;    
    xfs       = x+dx';
  end
    
  if isempty(varargin)
    fvalfs  = feval(fun,xfs);                         %fval at xfs
  else
    fvalfs  = feval(fun,xfs,varargin{:});             %fval at xfs    
  end
  fvall     = glowbound(x,options.alow,xlow);
  fvalu     = gupbound(x,options.aup,xup);
  fvalfs    = fvalfs+fvall+fvalu;
  dxrat     = (fval-fvalfs)/(-j'*dx+1e-8);          %fullstep/newton step
  k1        = 0;
  while (k1<options.kmax)&(dxrat<options.ramb(1))  %Line Search
    k1      = k1+1;
    options.lamb(1) = max(options.lamb(1)/options.lamb(2),1); %shrink the step
    dx      = -(u*diag(1./(s1+options.lamb(1)*s1))*v')*j; %new full step size
    xfs     = x+dx';
    if any(xfs(i1lo)<xlow(i1lo))|any(xfs(i1up)>xup(i1up))
      ibd   = find(xfs(i1lo)<xlow(i1lo));
      dx(i1lo(ibd))  = (xlow(i1lo(ibd))-x(i1lo(ibd)))*0.9; 
      ibd   = find(xfs(i1up)>xup(i1up));
      dx(i1up(ibd))  = (xup(i1up(ibd)) -x(i1up(ibd)))*0.9;    
    end
    xfs     = x+dx';                              %new x w/ full step
    if isempty(varargin)
      fvalfs  = feval(fun,xfs);                         %new fval at xfs
    else
      fvalfs  = feval(fun,xfs,varargin{:});                %new fval at xfs
    end
    fvall   = glowbound(x,options.alow,xlow);
    fvalu   = gupbound(x,options.aup,xup);  
    fvalfs  = fvalfs+fvall+fvalu;    
    dxrat   = (fval-fvalfs)/(-j'*dx+1e-8);       %new fullstep/newton step
  end
  if k1==options.kmax
    xnew    = x + 2*options.stopcrit(1)*dx'/(norm(dx)+1e-8); %reject the step
    options.lamb(1) = options.lamb(1)/options.lamb(2);
  else
    xnew    = xfs;
    fval    = fvalfs;
  end
  if dxrat>options.ramb(2)
    %options.lamb(1) = options.lamb(1)/options.lamb(3); 
    options.lamb(1) = min(1,max(options.lamb(1)/options.lamb(3),1/options.ncond));
  end
  out.critfinal(2)  = abs(fval-fvalold);
  out.critfinal(1)  = out.critfinal(2)./fvalold;
  out.critfinal(4)  = etime(clock,t0);
  dispits           = dispits+1;
  fvalold           = fval;
  if strcmpi(options.display,'on')&dispits>=options.dispfreq
    disp(sprintf('%d %0.5g',out.critfinal(3),fval))
    dispits         = 0;
  end
  x                 = xnew;
  if tfval, out.fval(out.critfinal(3)) = fval; end
  if tx,    out.x(out.critfinal(3),:)  = x;    end
end
if strcmpi(options.Jacobian,'on') | strcmpi(options.Hessian,'on')
  if isempty(varargin)
    [fval,j,h]      = feval(fun,x);             %fval, Jacobian, Hessian
  else
    [fval,j,h]      = feval(fun,x,varargin{:}); %fval, Jacobian, Hessian    
  end
  if strcmpi(options.Jacobian,'on')
    out.Jacobian    = j;
  end
  if strcmpi(options.Hessian,'on')
    out.Hessian     = h;
  end
end
if tx,    out.x     = out.x(1:out.critfinal(3),:); end
if tfval, out.fval  = out.fval(1:out.critfinal(3),:); end
exitflag    = [];
if any(out.critfinal(1:2)<=options.stopcrit(1:2))
  exitflag  = 1;
elseif any(out.critfinal(3:4)>options.stopcrit(3:4))
  exitflag  = 0;
end
