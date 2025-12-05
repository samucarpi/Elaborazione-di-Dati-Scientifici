function [modl] = b3spline(varargin)
%B3SPLINE Univariate spline fit and prediction.
%  Curve fitting using second order splines where
%  yi = f(xi) for i=1,...,M. See (options.algorithm)
%  for more information.
%
%  INPUTS:
%    x = Mx1 vector of independent variable values.
%    y = Mx1 vector of corresponding dependendent variable
%        values.
%    t = defines the number of knots or knot positions.
%      t = 1x1 scalar integer defining the number of uniformly
%          distributed INTERIOR knots. There will be t+2
%          knots positioned at
%          modl.t = linspace(min(x),max(x),t+2)';
%      t = Kx1 vector defining manually placed knot positions,
%          where modl.t = sort(t);
%          Note that knot positions need not be uniform, and
%          that t(1) can be <min(x) and t(K) can be >max(x).
%      Note that knot positions must be such that there are
%          at least 3 unique data points between each knot
%           tk,tk+1 for k=1,...,K.
%
%  OPTIONAL INPUT:
%   options = structure with the following fields:
%     display: [ 'off' | {'on'} ] level of display to command window.
%       plots: [ 'none' | {'final'} ]  governs level of plotting.
%               if 'final' and calibrating a model, the plot shows
%               plot(xi,yi) and plot(xi,f(xi),'-') with knots.
%   algorithm: [ {'b3spline'} | 'b3_0' | 'b3_01' ]; fitting algorithm
%              'b3spline': fits quadradic polynomials f{k,k+1} to the
%                data between knots tk, k=1,...,K, subject to 
%                 f{k,k+1}(tk+1)  = f{k+1,k+2}(tk+1) and
%                 f'{k,k+1}(tk+1) = f'{k+1,k+2}(tk+1) for k=1,...,K-1.
%              'b3_0': is the same as 'b3spline' but also constrains
%                the ends to 0: f{1,2}(t1) = 0 and f{K-1,K}(tK) = 0.
%              'b3_01': is 'b3_0' but also constrains the derivatives
%                at the ends to 0: f'{1,2}(t1) = 0 and f'{K-1,K}(tK) = 0.
%
%  OUTPUTS:
%   modl  = standard model structure containing the spline model (See MODELSTRUCT).
%   pred  = structure array with predictions
%   valid = structure array with predictions
%
%I/O: modl  = b3spline(x,y,t,options);   %identifies model (calibration step)
%I/O: pred  = b3spline(x,modl,options);  %makes predictions with a new X-block
%I/O: valid = b3spline(x,y,modl,options);%makes predictions with new X- & Y-block
%I/O: options = b3spline('options');     %returns a default options structure
%I/O: b3spline demo
%
%See also: 

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Initial coding by: nbg 10/06

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  options.name      = 'options';
  options.display   = 'on';
  options.plots     = 'final';
  options.algorithm = 'b3spline'; %'b3_0', 'b3_01'
  options.functionname = 'b3spline';
  if nargout==0; evriio(mfilename,varargin{1},options);
  else; modl = evriio(mfilename,varargin{1},options); end
  return;
end

%Check Inputs
%I/O: modl  = b3spline(x,y,t,options);    %calibrates the model
%I/O: pred  = b3spline(x,modl,options);   %makes preds with a new X-block
%I/O: valid = b3spline(x,y,modl,options); %makes preds with new X & Y
switch nargin
case 2  %two inputs
  %I/O: pred  = b3spline(x,model);
  if ismodel(varargin{2})
    varargin = {varargin{1}, [], varargin{2}, []};
  else
    error(['Input (t) is missing. Type: ''help ' mfilename '''']);      
  end
case 3  %three inputs
  %I/O:  modl  = b3spline(x,y,t)
  %I/O:  pred  = b3spline(x,model,options)
  %I/O:  valid = b3spline(x,y,model)
  if ismodel(varargin{2});
    %I/O:  pred  = b3spline(x,model,options)
    varargin = {varargin{1}, [], varargin{2}, varargin{3}};
  end
case 4   %four inputs
  %I/O: modl  = b3spline(x,y,t,options)
  %I/O: valid = b3spline(x,y,modl,options)
otherwise
  error('inputs or input order not recognized.')
end
if nargin<4
  varargin{4} = [];
end
varargin{4} = reconopts(varargin{4},mfilename);%Fill in any missing options values.
%End of Checking inputs

%Predict or Calibrate
if ismodel(varargin{3}) %varargin{3} is a model, prediction mode
  %I/O: valid = b3spline(x,y,modl,options);
  %I/O: pred  = b3spline(x,modl,options);
  modl = modelstruct('b3spline',1);
  modl.info = 'B3 Spline Prediction Results';
  modl.date = date;
  modl.time = clock;
  [datasource{1:2}] = getdatasource(varargin{1:2});
  modl.datasource = datasource;

  m    = length(varargin{1});
  switch lower(varargin{3}.detail.options.algorithm)
  case 'b3spline'
    i2 = find(varargin{1}>=varargin{3}.t(1) & ...
              varargin{1}<=varargin{3}.t(end));
    modl.pred{2} = ones(m,1)*NaN;
    if length(i2)<m & strcmpi(varargin{4}.display,'on');
      warning('EVRI:B3splineExtrapolatedAsNaN','extrapolated points set to "NaN".')
    end
    if isempty(i2)
      warning('EVRI:B3splineAllAreExtrapolated','all pts in (x) are extrapolated points.')
    end
    basis = b3splineb(varargin{1},varargin{3});
    modl.pred{2} = basis*varargin{3}.reg;
  case {'b3_0', 'b3_01'}
    i2    = find(varargin{1}>=varargin{3}.t(1) & ...
                 varargin{1}<=varargin{3}.t(end));
    modl.pred{2} = zeros(m,1);
    basis = b3splineb(varargin{1}(i2),varargin{3});
    modl.pred{2}(i2) = basis*varargin{3}.reg;
  end
else %varargin{3} is a scalar integer or vector of knots, cal mode
  %I/O: valid = b3spline(x,y,t,options);
  modl = modelstruct('b3spline');
  modl.date = date;
  modl.time = clock;
  [datasource{1:2}] = getdatasource(varargin{1:2});
  modl.datasource = datasource;
    
  modl.detail.options = varargin{4};
  varargin{1} = varargin{1}(:);
  varargin{2} = varargin{2}(:);
  [varargin{1},i1] = sort(varargin{1});
  varargin{2} = varargin{2}(i1);
  m           = length(varargin{1});
  if prod(size(varargin{3}))==1 %Input (t) is a scalar integer
    %then it must be an integer defining number of uniformly spaced knots
    if varargin{3}>=m-2
%       if lower(varargin{4}.display)=='on'
      if strcmpi(varargin{4}.display,'on')
        warning('EVRI:B3splineTInvalid','input (t) must be <= number of data points-3.')
        disp([' (t) reset from ',int2str(varargin{3}),' to ',int2str(m-3),'.'])
      end
      varargin{3} = m-3;
    end
    modl.t = linspace(min(varargin{1}),max(varargin{1}),varargin{3}+2)';
  else %Input (t) is a vector t(1)<=min(x) max(x)<=t(K) for k=1,...,K
    varargin{3} = sort(varargin{3}(:));
    if varargin{3}(1)>min(varargin{1}) & strcmpi(varargin{4}.display,'on')
      warning('EVRI:B3splineTInvalid','note that t(1) > min(x).')
    end
    if varargin{3}(end)<max(varargin{1}) & strcmpi(varargin{4}.display,'on')
      warning('EVRI:B3splineTInvalid','note that t(K) > max(x).')
    end
    if length(varargin{3})>=m-2
      error('length of input (t) must be <= number of data points-3.')
    end
    modl.t = varargin{3};
  end

  k      = length(modl.t)-2;   %Number of knots
  modl.description = {['B3Spline Model with ',int2str(k),' knots.']; ...
    '';''}; %{3x1 cell}
  modl.m = length(varargin{1}); %temporary, should be able to get from include field
  
  switch lower(varargin{4}.algorithm)
  case 'b3spline'
    [basis,l0,l1] = b3splineb(varargin{1},modl);
    modl.reg      = zeros(5*k+3,5*k+3);
    modl.reg(1:3*(k+1),1:3*(k+1))     = basis'*basis;
    modl.reg(1:3*(k+1),3*(k+1)+1:end) = [l0' l1'];
    modl.reg(3*(k+1)+1:end,1:3*(k+1)) = [l0; l1];
    modl.reg  = modl.reg\[basis'*varargin{2}; zeros(2*k,1)];
    modl.reg  = modl.reg(1:3*(k+1));
  case 'b3_0'
    [basis,l0,l1] = b3splineb(varargin{1},modl);
    modl.reg      = zeros(5*k+5,5*k+5);
    modl.reg(1:3*(k+1),1:3*(k+1))       = basis'*basis;
    modl.reg(1:3*(k+1),3*(k+1)+1:end-2) = [l0' l1'];
    modl.reg(3*(k+1)+1:end-2,1:3*(k+1)) = [l0; l1];
    modl.reg(end-1,3)                   = 1; %f(t1)  = 0;
    modl.reg(3,end-1)                   = 1; %f(t1)  = 0;
    modl.reg(end,3*k+1:3*(k+1))         = 1; %f(tK)  = 0;
    modl.reg(3*k+1:3*(k+1),end)         = 1; %f(tK)  = 0;
    modl.reg  = modl.reg\[basis'*varargin{2}; zeros(2*k+2,1)];
    modl.reg  = modl.reg(1:3*(k+1));
  case 'b3_01'
    [basis,l0,l1] = b3splineb(varargin{1},modl);
    modl.reg      = zeros(5*k+7,5*k+7);
    modl.reg(1:3*(k+1),1:3*(k+1))       = basis'*basis;
    modl.reg(1:3*(k+1),3*(k+1)+1:end-4) = [l0' l1'];
    modl.reg(3*(k+1)+1:end-4,1:3*(k+1)) = [l0; l1];
    modl.reg(end-3,3)                   = 1; %f(t1)  = 0;
    modl.reg(end-2,2)                   = 1; %f'(t1) = 0;
    modl.reg(3,end-3)                   = 1; %f(t1)  = 0;
    modl.reg(2,end-2)                   = 1; %f'(t1) = 0;    
    modl.reg(end-1,3*k+1:3*(k+1))       = 1; %f(tK)  = 0;
    modl.reg(end,3*k+1:3*k+2)           = [2 1]; %f'(tK) = 0;
    modl.reg(3*k+1:3*(k+1),end-1)       = 1; %f(tK)  = 0;
    modl.reg(3*k+1:3*k+2,end)           = [2 1]; %f'(tK) = 0;
    modl.reg  = modl.reg\[basis'*varargin{2}; zeros(2*k+4,1)];
    modl.reg  = modl.reg(1:3*(k+1));
  end, %clear l0 l1
  modl.pred{2} = basis*modl.reg;
  
  %add model details?
  % modl.datasource: {[1x1 struct]  [1x1 struct]}
  % modl.date: ''
  % modl.time: []
  % modl.info: ''
  % modl.reg       = [];
  % modl.pred      = {[]  []};
  % modl.ssqresiduals: {2x2 cell}
  % modl.detail: [1x1 struct]
  % modl.description: {3x1 cell}
  switch lower(varargin{4}.plots)
  case 'final'
    varargin{4}.display  = 'off';
    figure, plot(varargin{1},modl.pred{2}), hold on
    prd  = b3spline(modl.t,modl,varargin{4});
    plot(modl.t(2:end-1),prd.pred{2}(2:end-1),'or','markerfacecolor',[1 0 0])
    plot(modl.t([1 end]),prd.pred{2}([1 end]),'or','markerfacecolor',[1 0.7 0.7])  
    plot(varargin{1},varargin{2},'.')
    xlabel('X'), ylabel('Y')
    title([varargin{4}.algorithm,' fit with ',int2str(k),' knots.'], ...
      'interpreter','none')
    hold off
    shg
  end
end %Prediction or Calibration

function [basis,l0,l1] = b3splineb(x,modl)
% (x) are data points
% (modl.t) is a vector of knot positions w/ boundaries
m      = length(x);              %Number of data pts
k      = length(modl.t)-2;       %Number of knots
dt     = diff(modl.t);           %Distance between knots
basis  = zeros(m,(k+1)*3);  %Spline Basis
for i1=1:k+1
  i2   = find(x>=modl.t(i1)&x<modl.t(i1+1));
  z    = (x(i2)-modl.t(i1))/dt(i1);
  basis(i2,(i1-1)*3+1:i1*3) = [z.^2 z ones(length(z),1)];
end
i2     = find(x>=modl.t(k+1)&x<=modl.t(k+2));
z      = (x(i2)-modl.t(i1))/dt(i1);
basis(i2,(i1-1)*3+1:i1*3) = [z.^2 z ones(length(z),1)];
if nargout>1 %Set boundary basis matrices
  l0   = zeros(k,(k+1)*3);
  l1   = l0;
  for i1=1:k
    l0(i1,(i1-1)*3+1:i1*3+3)  = [1 1 1 0 0 -1];
    l1(i1,(i1-1)*3+1:i1*3+2)  = [2 1 0 0 -1];
  end
end
  
