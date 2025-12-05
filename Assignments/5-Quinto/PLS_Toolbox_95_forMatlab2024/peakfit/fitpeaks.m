function [peakdef,fval,exitflag,out,fit,res] = fitpeaks(peakdef,y,ax,options);
%FITPEAKS Peak fitting routine
% INPUTS:
%  peakdef = multi-record standard peak structure with the following fields:  
%      name: 'Peak'
%        id: double or character string peak identification.
%       fun: [ {'Gaussian'} | 'Lorentzian' | 'PVoigt1' | 'PVoigt2' | ...
%              'GaussianSkew' ]
%            defines the peak function.
%      param: []; 1xP vector of parameters for each peak function as listed
%            below. A descriptions of the functions and parameters are given in 
%            the Algorithm section of the FITPEAKS entry in the reference manual.
%          fun             param
%        --------------  --------------------------------
%        'Gaussian'      [height, position, width]
%                          width = standard deviation. Multiply by 
%                            2.3548 = 2*sqrt(2*(-log(0.5))) to get
%                          full-width at half-height (FWHM).
%        'Lorentzian'    [height, position, width]
%                          width = half-width. Multiply by 2 to get FWHM.
%        'PVoigt1'       [height, position, width, fraction Gaussian],
%                            where 0<fraction Gaussian<1.
%        'PVoigt2'       [height, position, width, fraction Gaussian],
%                            where 0<fraction Gaussian<1.
%        'GaussianSkew'  [height, position, width, skew parameter]
%
%         lb: []; Lower bounds on the function parameters.
%      penlb: []; Penalty wt for lower bounds, >=0, 0 implies LB not active.
%         ub: []; Upper bounds on the function parameters.
%      penub: []; Penalty wt for upper bounds, >=0, 0 implies UB not active.
%       area: []; Peak area (initially empty when input).
%
%          y = MxN measured responses with peaks to fit, each
%              row of y is fit to the peaks in peakdef.
%
%  OPTIONAL INPUTS:
%         ax = 1xN x-axis to fit to {default ax=1:N}.
%    options = structure array with the following fields:
%         display: [ 'off' | {'on'} ] governs level of display to command window.
%             wts: [ {[ ]} | [1xN] ] weights used to fit peaks in a
%                  weighted least-squares sense.
%                  If empty {default}, then the function SETWTS is called so
%                  that channels outside +- wf of all the peaks have zero
%                  weights (zero influence) on the fit.
%                  If not empty, wts must be a 1xN vector with entries
%                  0<=wts<=1.
%              wf: {2}, distance from peak max to deweight (see SETWTS).
%       optimopts: options structure from LMOPTIMIZEBND
%
%  OUTPUTS:
%    peakdefo = the input peak structure with parameters changed to
%              correspond to the best fit values.
%        fval = scalar value of the objective function evaluated at
%               termination of FITPEAKS.
%    exitflag = describes the exit condition (see LMOPTIMIZEBND).
%         out = structure array with information on the optimization/
%               fitting (see LMOPTIMIZEBND).
%         fit = model fit of the peaks, i.e it is the best fit to (y).
%         res = residuals of fit of the peaks.
%
%I/O: [peakdefo,fval,exitflag,out,fit,res] = fitpeaks(peakdef,y,ax,options);
%
%See also: PEAKFUNCTION, PEAKSTRUCT, SETWTS, TESTPEAKDEFS

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 4/19/04, 5/31/04 modified i/o to allow options, changed i2 loop to only use ~=0 penalties
%nbg 6/05 modified to call LMOPTIMIZEBND
%nbg 8/05 modified the help, added peak area calculation on output
%nbg 10/08 modified help to add wts, added SETWTS

if nargin == 0; peakdef = 'io'; end
varargin{1} = peakdef;
if ischar(varargin{1});
	options.name      = 'options';
	options.display   = 'on';                    %governs level of display.
  options.wts       = [];
  options.wf        = 2;
  options.optimopts = lmoptimizebnd('options');
    options.optimopts.display = 'off';
    %options.optimopts.stopcrit(1:2) = 1e-8;

  if nargout==0; clear peakdef; evriio(mfilename,varargin{1},options);
  else;               peakdef = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<4
  options = fitpeaks('options');
else
  options = reconopts(options,'fitpeaks');
end

[m,n]     = size(y); if m>1; error('Multi-row Y not yet enabled.'), end
if nargin<3
  ax      = 1:n;
elseif length(ax)~=n
  error('Input (ax) must have N elements for (y) M by N.')
else
  ax      = ax(:)';            %make it a row vector
end
if isempty(options.wts)
  options.wts = setwts(peakdef,ax,options.wf); %10/08 nbg
  %options.wts = ones(1,n); commented 10/08 nbg
else
  if length(options.wts)~=n
    error('Input (options.wts) must have the same number of elements as ax.')
  end
  options.wts = options.wts(:)';
end
% peakdef.name  = 'Peak';
% peakdef.id    = 1;
% peakdef.fun   = 'Gaussian';
% peakdef.param = [0     0   0]; %coef, position, spread
% peakdef.lb    = [0  -inf   0]; %lower bounds on param
% peakdef.penlb = [1e-4 1e-4 1e-4];
% peakdef.ub    = [inf inf inf]; %upper bounds on params
% peakdef.penub = [1e-4 1e-4 1e-4];
np        = length(peakdef);   %number of peaks to fit
inp       = 1:np;
for i1=1:np
  if isempty(lower(peakdef(i1).fun))
    inp   = setdiff(inp,i1);
  end
end
nparm     = zeros(np,1);       %number of parameters in each peak
for i1=inp
  nparm(i1) = length(peakdef(i1).param);
  switch lower(peakdef(i1).fun)
  case {'gaussian'}
  case {'lorentzian'}
  case {'pvoigt2'}
  case {'pvoigt1'}
  case {'gaussianskew'}
  otherwise
    error(['Peak definition ',peakdef(i1).id,' not recognized.'])
  end
end
nx        = sum(nparm);        %total number of parameters to estimate
nparm1    = cumsum([0;nparm]); %index keeper
x0        = zeros(nx,1);       %initial guess of peak location
xL        = x0;                %lower bounds on peak parameters
xU        = x0;                %upper bounds on peak parameters
options.optimopts.alow = x0;   %lower bounds penalty
options.optimopts.aup  = x0;   %upper bounds penalty        
for i1=inp
  if (nparm1(i1+1)-nparm1(i1))>0
    j1      = [nparm1(i1)+1:nparm1(i1+1)];
    x0(j1)  = peakdef(i1).param(:);
    xL(j1)  = peakdef(i1).lb(:);
    xU(j1)  = peakdef(i1).ub(:);
    options.optimopts.alow(j1) = peakdef(i1).penlb(:);
    options.optimopts.aup(j1)  = peakdef(i1).penub(:);
  end
end
j1        = find(~isfinite(xL));
xL(j1)    = 0;
options.optimopts.alow(j1) = 0;
j1        = find(~isfinite(xU));
xU(j1)    = 0;
options.optimopts.aup(j1)  = 0;

[x,fval,exitflag,out] = lmoptimizebnd(@peakerror,x0,xL,xU,options.optimopts, ...
                          peakdef,y,ax,options,nx,nparm,nparm1);

for i1=inp %parse the parameters back into the peak definitions
  if (nparm1(i1+1)-nparm1(i1))>0
    j1    = [nparm1(i1)+1:nparm1(i1+1)];
    peakdef(i1).param = x(j1);
  end
end
[fit,peakdef] = peakfunction(peakdef,ax);
res       = y-fit;
