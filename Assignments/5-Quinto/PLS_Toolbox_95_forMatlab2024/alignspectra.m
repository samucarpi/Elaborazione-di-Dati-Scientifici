function varargout = alignspectra(varargin)
%ALIGNSPECTRA Calibrates wavelength scale using standard spectrum.
%  INPUTS:
%     x0: 1xN, axis of the standard instrument at t=0.
%     y0: 1xN, wavelength standard spectrum measured on the
%              standard instrument at t=0.
%     y1: 1xN, wavelength standard spectrum measured on the
%              field instrument at t>0.
%    win: window (number of channels) for piece-wise estimation
%         {odd integer}.
%    mx2: number of channels of maximum shift to consider.
%
%  OPTIONAL INPUTS:
%   options = structure array with the following fields:
%          plots: [ 'none' | {'final'} ] governs level of plotting.
%    interpolate: [ 'none' | {'linear'} | 'cubic' ] 
%      interpolate = 'none' uses the coarse scale given by (x0), and
%      interpolate ~= 'none' interpolates between points on (x0).
%                 Using other interpolation schemes can significantly
%                 increase the time required for computation. See INTERP1.
%          order: polynomial order for fitting (x1) to (x0) where
%                 (x1) is defined below {default = 2}.
%
%  OUTPUTS:
%      s: structure array with parameters used to apply the
%         wavelength calibration.
%      y: input (y1) calibrated to x0
%
%  Ideally, the peak locations (x0) would be valid for both the standard
%  and field instruments. However, these locations don't typically match
%  those for the field instrument even though the numbers in the scales are
%  identical. The result is that a plot of observed spectra from the two
%  instruments against the same axis (x0) appear shifted from one another. 
%    plot(x0,y0,'b',x0,y1,'r') %typically shows a shift
%    [s,y1b] = alignspectra(x0,y0,y1,win,mx2);
%    plot(x0,y0,'b',x0,y1b,'r') %shows y1 corrected for the shift, y1b
%
%  ALIGNSPECTRA finds a polynomial fit between (x0) and (x1) where (x1) is
%  determined by finding windows in (y1) that best match (y0).
%
%I/O:  [s,y] = alignspectra(x0,y0,y1,win,mx2,options)
%I/O:     y  = alignspectra(s,y1);      %apply previously calculated adjustment to new spectrum 
%
%See also: ALIGNMAT, ALIGNPEAKS, REGISTERSPEC, STDGEN

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 7/2006

% Because the correlation in each window might not be 100% accurate
% it might make sense to use a robust fitting procedure (or allow that
% option in the algorithm), nbg

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  options.name          = 'options';
  options.plots         = 'final';     %
  options.interpolate   = 'linear';    %'none' | 'interp' | 'cubic'
  options.order         = 2;
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

%Check for and perform "apply" if needed.
if nargin == 2 && isstruct(varargin{1})
  varargout{1} = axiscalize(varargin{1},varargin{2});
  return
end

%parse inputs
options = [];
if nargin==4 || (nargin==5 && isstruct(varargin{5}))
  if isdataset(varargin{1})
    x0 = varargin{1}.axisscale{2};
    y0 = varargin{1}.data;
    y1 = varargin{2};
    win = varargin{3};
    mx2 = varargin{4};
  else
    error('Unrecognized input format');
  end
  if nargin>4
    options = varargin{5};
  end
elseif nargin==5 || nargin==6
  x0  = varargin{1};
  y0  = varargin{2};
  y1  = varargin{3};
  win = varargin{4};
  mx2 = varargin{5};
  if nargin==6
    options = varargin{6};
  end
else
  error('Unrecognized input format');
end
options = reconopts(options,mfilename);

switch lower(options.interpolate)     
case {'none', 'linear', 'cubic'}
  %do nothing, these are ok
otherwise
  error('Input (options.interpolate) not recognized.')
end

%vectorize x and ys
x0 = x0(:);
y0 = y0(:);
y1 = y1(:);

%check sizes
if win/2-floor(win/2)~=0.5
  disp(['Input (win) must be odd, changing from win = ', ...
    int2str(win),' to ',int2str(win+1),'.'])
  win = win+1;
end
if mx2>win/2
  mx2_new = floor((floor(win/2)-1)/2)*2+1;
  disp(['Input (mx2) must be < 1/2 window width, changing from mx2 = ', ...
    int2str(mx2),' to ',int2str(mx2_new),'.'])
  mx2 = mx2_new;
end

w2  = (win-1)/2;
m   = [w2+mx2+1:length(x0)-w2-mx2];
z1  = zeros(length(m),1);
ij1 = [-w2-mx2:w2+mx2];
j2  = [-mx2:mx2];
j1  = 0;
for ii=m
  %coarse scale
  j1 = j1+1;
  ij = [ii-w2:ii+w2];
  ik = ij'*ones(1,2*mx2+1) + ones(length(ij),1)*j2;
  rr = corrcoef([y0(ij),y1(ik)]);
  [rr,i0] = max(rr(1,2:end));
  %fine scale
  switch lower(options.interpolate)
  case 'none'
    z1(j1) = x0(ii+j2(i0));      
  case {'linear', 'cubic'}
    myinterp = lower(options.interpolate);
    if strcmp(options.interpolate,'cubic')
      myinterp = 'pchip';%Need to convert to pchip for 2014a+ (pchip is the same as cubic).
    end
    i0  = fminsearch(@(z) alignspecfun(z,y0(ij), ...
      ij1,y1(ik(1):ik(end)),w2,myinterp),j2(i0));
    z1(j1) = interp1(ij1,x0(ik(1):ik(end)),i0,myinterp);
  otherwise
    error('Input (options.interpolate) not recognized.')
  end
end


s.modeltype = 'alignspectra';
s.x  = x0';
s.x1 = [];
s.y0 = y0';
s.interpolate = lower(options.interpolate);

switch 1
  case 1
  y    = x0(m); y = y(:);
  p    = z1(:,ones(1,options.order+1)).^(ones(length(z1),1)*[options.order:-1:0])\y;
  z1   = x0(:);
  s.x1 = (z1(:,ones(1,options.order+1)).^(ones(length(z1),1)*[options.order:-1:0])*p)';
case 2
  [x,mx,sx] = auto(z1);
  [y,my]    = mncn(x0(m));
  p         = x(:,ones(1,options.order)).^(ones(length(x),1)*[options.order:-1:1])\y;
  s.x1 = scale(x0(:),mx,sx);
  s.x1 = rescale(s.x1(:,ones(1,options.order)).^ ...
    (ones(length(x0),1)*[options.order:-1:1])*p,my)';
end

y_corr = axiscalize(s,y1);

varargout = {s y_corr};

% if strcmp(lower(options.plots),'final')
%   plot(x0,y0,'b',x0,varargout{2},'r')
% end

function [y] = axiscalize(s,y1);
%AXISCALIZE Applies wavelength calibration from ALIGNSPECTRA
%  INPUTS:
%      s = structure output from ALIGNSPECTRA.
%     y1 = spectra measured on field instrument at t>0.
%
%  OUTPUT:
%      y = spectra interpolated to the standard wavelength
%          axis measured at t=0.
%
%I/O: y = axiscalize(s,y1);
%
%See also: AXISCAL0, ALIGNSPECTRA

%Copyright Eigenvector Research, Inc. 2006-2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 7/2007

y     = interp1(s.x1(:),y1,s.x(:),'linear','extrap')';

function res = alignspecfun(z,y0,x1,y1,w2,algorithm)
%ALIGNSPECFUN Objective funtion optimized in AXISCAL.
%  This function is called by AXISCAL and is not intended
%  for general use.
%
%I/O: res = alignspecfun(z,y0,x1,y1,w2,algorithm);

%Copyright Eigenvector Research, Inc. 2001-2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg (original written 7/01)
%nbg 12/29/05 commented I/O check
%nbg 8/06 modified alignmatfun to alignspecfun

%The call from AXISCAL is
%  i0  = fminsearch(@(z) alignspecfun(z,y0(ij), ...
%       ij1,y1(ik(1):ik(end)),w2,'cubic'),j2(i0));

if z-floor(z)==0.5, z = z+0.001; end
rr  = interp1(x1,y1,round(z-w2):round(z+w2),lower(algorithm));
rr  = corrcoef(y0,rr(:));
res = 1-rr(2);
