function [x,fval,exitflag,out] = lmoptimize(fun,x0,options,varargin)
%LMOPTIMIZE Levenberg-Marquardt non-linear optimization
%  Starting at (x0) LMOPTIMIZE finds (x) that minimizes the function
%  defined by the function handle (fun).
%
%  INPUTS:
%         fun = function handle, the call to fun is
%                 [fval,jacobian,hessian] = fun(x)
%               [see documentation in manual for tips on writing (fun)].
%           (fval) is a scalar objective function value,
%           (jacobian) is a Nx1 vector of Jacobian values, and
%           (hessian) is a NxN matrix of Hessian values.
%          x0 = Nx1 initial guess of the function parameters.
%
%  OPTIONAL INPUTS:
%     options = structure array with the following fields:
%               (if options is empty [ ], the defaults are used)
%       display: [ 'off' | {'on'} ] governs level of display to the
%                command window.
%      dispfreq: n, an integer display every nth iteration {default, n=10}.
%      stopcrit: [1e-8 1e-10 10000 3600]  defines the stopping criteria as
%                [(relative tolerance) (absolute tolerance) (maximum number
%                of iterations) (maximum time in seconds)].
%             x: [ {'off'} | 'on' ] saves x at each step.
%          fval: [ {'off'} | 'on' ] saves fval at each step.
%      Jacobian: [ {'off'} | 'on' ] saves last evaluation of the Jacobian.
%       Hessian: [ {'off'} | 'on' ] saves last evaluation of the Hessian.
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
%I/O: [x,fval,exitflag,out] = lmoptimize(fun,x0,options,params);
%
%See also: FUNCTION_HANDLE, LMOPTIMIZEBND  

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NBG 1/05, modified GN_1STEP 6/05

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
  options.ncond    = 1e4;       %max condition number for Hessian
  options.lamb     = [1e-6 0.9 1.5]; %[0.01 0.7 1.5];
    %lamb(1): damping factor * biggest eigenvalue of H is added damping
    %lamb(2): lamb(1) = lamb(1)/lamb(2) causes deceleration in line search
    %lamb(3): lamb(1) = lamb(1)/lamb(3) causes acceleration in line search
  options.ramb     = [1e-4 0.5 1e-5];
    %ramb(1): if fullstep not < options.ramb(1)*[linear step] back up
    %ramb(2): if fullstep nearly a linear step, accelerate
    %ramb(3): if linesearch rejected, make a small movement
  options.kmax     = 50;        %max steps in line search
  if nargout==0; 
    evriio(mfilename,fun,options); 
  else
    x = evriio(mfilename,fun,options); 
  end
  return; 
end
if nargin<3 | isempty(options) %set default options
  options  = lmoptimize('options');
else
  options = reconopts(options,lmoptimize('options'));
end
if nargin<4
  varargin = cell(0);
end

%Initialization
x0               = x0(:)'; %Make x a row vector
x                = x0;
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
if isempty(varargin)
  fvalold        = feval(fun,x);
else
  fvalold        = feval(fun,x,varargin{:});  
end
out.Jacobian     = [];
out.Hessian      = [];
t0               = clock;
dispits          = 0;
%Main While Loop
while all(out.critfinal(1:2)> options.stopcrit(1:2))&...
      all(out.critfinal(3:4)<=options.stopcrit(3:4))
  out.critfinal(3) = out.critfinal(3)+1;
  if isempty(varargin)
    [fval,j,h] = feval(fun,x);             %fval, Jacobian, Hessian
  else
    [fval,j,h] = feval(fun,x,varargin{:}); %fval, Jacobian, Hessian    
  end
  [u,s1,v]  = svd(h);               %SVD of H for estimating inverse
  s1        = diag(s1); %disp(s1(1)/s1(end))
  %s1(find(s1<s1(1)/options.ncond)) = s1(1)/options.ncond;  %eliminates <=0 values of s1 and makes good cond

  dx        = -(u*diag(1./(s1+options.lamb(1)*s1(1)))*v')*j; %full step size
  xfs       = x+dx';                                  %x w/ full step
  if isempty(varargin)
    fvalfs  = feval(fun,xfs);                         %fval at xfs
  else
    fvalfs  = feval(fun,xfs,varargin{:});             %fval at xfs    
  end
  dxrat     = (fval-fvalfs)/(-j'*dx+1e-8);          %fullstep/newton step
  k1        = 0;
  while (k1<options.kmax)&(dxrat<options.ramb(1))  %Line Search
    k1      = k1+1;
    options.lamb(1) = options.lamb(1)/options.lamb(2); %shrink the step
    dx      = -(u*diag(1./(s1+options.lamb(1)*s1))*v')*j; %new full step size
    xfs     = x+dx';                              %new x w/ full step
    if isempty(varargin)
      fvalfs  = feval(fun,xfs);                         %new fval at xfs
    else
      fvalfs  = feval(fun,xfs,varargin{:});             %new fval at xfs
    end
    dxrat   = (fval-fvalfs)/(-j'*dx+1e-8);        %new fullstep/newton step
  end
  if k1==options.kmax
    xnew    = x + options.ramb(3)*dx'/(norm(dx)+1e-8); %reject the step
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
  if strcmp(lower(options.display),'on')&dispits>=options.dispfreq
    disp(sprintf('%d %0.5g',out.critfinal(3),fval))
    dispits         = 0;
  end
  x                 = xnew;
  if tfval, out.fval(out.critfinal(3)) = fval; end
  if tx,    out.x(out.critfinal(3),:)  = x;    end
end
if strcmp(lower(options.Jacobian),'on') | strcmp(lower(options.Hessian),'on')
  if isempty(varargin)
    [fval,j,h]      = feval(fun,x);             %fval, Jacobian, Hessian
  else
    [fval,j,h]      = feval(fun,x,varargin{:}); %fval, Jacobian, Hessian    
  end
  if strcmp(lower(options.Jacobian),'on')
    out.Jacobian    = j;
  end
  if strcmp(lower(options.Hessian),'on')
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
