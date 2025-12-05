function varargout = alignpeaks(varargin)
%ALIGNPEAKS Calibrates wavelength scale using standard peaks.
%  INPUTS:
%     x0: 1xK, axis locations of peaks on the standard
%              instrument at t=0 (e.g., the true wavelength).
%     x1: 1xK, axis locations of peaks on the field
%              instrument at t>0, (e.g., the measured wavelength).
%     ax: 1xN, axis scale (e.g. wavelength scale corresponding
%              to the axis locations of the peaks, x0). Note that
%              the algorithm expects N>K.
%
%  OPTIONAL INPUTS:
%   options = structure array with the following fields:
%          plots: [ 'none' | {'final'} ] governs level of plotting.
%          order: polynomial order for fitting (x1) to (x0) where
%                 (x1) is defined below {default = 2}.
%
%  OUTPUT:
%      s: structure array with parameters used to apply the
%         wavelength calibration.
%
%  Ideally, the peak locations (x0) would be valid for both the standard
%  and field instruments. However, these locations don't typically match
%  those for the field instrument even though the numbers in the scales are
%  identical. The result is that a plot of observed spectra from the two
%  instruments against the same axis (x0) appear shifted from one another. 
%    plot(ax,y0,'b',ax,y1,'r')   %typically shows a shift
%    s    = alignpeaks(x0,x1,ax);  %calculate the wavelength axis transform
%    y10  = alignpeaks(s,y1);    %transform y1 to the standard x-axis
%    plot(ax,y0,'b',x0,y10,'r')  %shows y1 corrected for the shift, y10
%
%  ALIGNPEAKS finds a polynomial fit between (x0) and (x1), stores the
%  result in (s) and applies it to (x1) to give output (y).
%
%I/O:  s = alignpeaks(x0,x1,ax,options)
%I/O:  y = alignpeaks(s,y1) %apply to new data
%
%See also: ALIGNMAT, ALIGNSPECTRA, REGISTERSPEC, STDGEN

%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 8/2007

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  options.name          = 'options';
  options.plots         = 'final';
  options.order         = 2;
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

%Check for and perform "apply" if needed.
if nargin == 2 && isstruct(varargin{1})
  varargout{1} = axiscalize(varargin{1},varargin{2});
  return
end

if nargin<4
  options = alignpeaks('options');
else
  options = varargin{4};
end

varargout{1}.modeltype = 'alignpeaks';
varargout{1}.x  = varargin{3}(:)';
varargout{1}.x1 = [];
switch 1
  case 1
  x               = varargin{2}(:);
  y               = varargin{1}(:);
  p               = x(:,ones(1,options.order+1)).^(ones(length(x),1)* ...
                      [options.order:-1:0])\y;
  x               = varargin{3}(:); 
  varargout{1}.x1 = (x(:,ones(1,options.order+1)).^ ...
                      (ones(length(x),1)*[options.order:-1:0])*p)';
case 2
  [x,mx,sx]       = auto(varargin{2}(:));
  [y,my]          = mncn(varargin{1}(:));
  p               = x(:,ones(1,options.order)).^(ones(length(x),1)* ...
                      [options.order:-1:1])\y;
  varargout{1}.x1 = scale(varargin{3}(:),mx,sx);
  varargout{1}.x1 = rescale(varargout{1}.x1(:,ones(1,options.order)).^ ...
   (ones(length(varargin{3}),1)*[options.order:-1:1])*p,my)';
end
%display table of
% true measured predicted difference

% if strcmp(lower(options.plots),'final')
%   y             = range(varargin{1}(:))';
%   x             = scale([min(varargin{1}):y/100:max(varargin{1})]', ...
%         varargout{1}.mx,varargout{1}.sx);
%   y             = rescale(x(:,ones(1,options.order)).^ ...
%         (ones(length(x),1)*[varargout{1}.order:-1:1])* ...
%         varargout{1}.p,varargout{1}.my);
%   x             = rescale(x,varargout{1}.mx,varargout{1}.sx);
%   figure
%   plot(x,y,'-r','linewidth',2), hold on
%   plot(varargin{1},varargin{2},'ob','markerfacecolor',[0 0 1]), hold off
%   xlabel('Standard Peak Locations')
%   ylabel('Measured Peak Locations')
%   title([int2str(varargout{1}.order),' Order Polynomial Fit of Axes'])
% end

function [y] = axiscalize(s,y1);
%AXISCALIZE Applies wavelength calibration from AXISCAL
%  INPUTS:
%      s = structure output from AXISCAL.
%     y1 = spectra measured on field instrument at t>0.
%
%  OUTPUT:
%      y = spectra interpolated to the standard wavelength
%          axis measured at t=0.
%
%I/O: y = axiscalize(s,y1);
%
%See also: AXISCAL0, AXISCAL

%Copyright Eigenvector Research, Inc. 2006-2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 7/2007

y     = interp1(s.x1(:),y1,s.x(:),'linear','extrap')';
