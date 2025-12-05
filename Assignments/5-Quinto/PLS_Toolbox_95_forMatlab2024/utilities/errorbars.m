function h = errorbars(x,y,xe,ye,y_points,barends)
%ERRORBARS Error bar for Y vs X plots.
%  
%  INPUTS:
%     x = N element vector of X-axis (abscissa) data.
%     y = N element vector of Y-axis (ordinate) data.
%    xe = error for X measurements.
%          xe empty [] uses no error bars on x.
%          xe a 1x1 scalar uses same xe for all x: x-xe and x+xe.
%          xe a Nx1 vector uses each element as the error for the
%             corresponding element in x: x-xe and x+xe.
%          xe a Nx2 vector uses each row as the error for the
%             corresponding element in x: x-xe(:,1) and x+xe(:,2).
%    ye = error for Y measurements.
%          ye can be empty, scalar, Nx1, or Nx2 (see xe above).
%
%  OPTIONAL INPUTS:
%    y_points = boolean flag (zero or one) which indicates whether the y
%           points should be plotted as points along with the error bars.
%           If 0 (zero), points are not plotted. Default is 1 indicating
%           points will be plotted.
%    barends = boolean flag (zero or one) which indicates if bar ends
%           should be put onto the error bars. Default is one, indicating
%           bar ends should be shown.
%
%  OUTPUTS:
%       h = graphic handles of all graphical objects created on the plot
%
%Examples:
% errorbars(x,y,[],ye)
% errorbars(x,y,[],ye,0,0)   %no points or bar ends, only vertical bars
%
%I/O: h = errorbars(x,y,xe,ye,y_points,barends)
%
%See also: ANALYSIS, PCR

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%NBG


if nargin<3
  error('ERRORBARS requires at least 3 inputs.')
end

if nargin<4
  ye  = [];
end

if nargin<5
  y_points = 1;
end
if nargin<6
  barends = 1;
end

%test if vector?
x     = x(:);
y     = y(:);
n     = length(x);
if length(y)~=n, error('Input (y) must be same size as (x).'), end
if isempty(xe)
  %do nothing
elseif prod(size(xe))==1
  xe  = ones(n,2)*xe;
elseif length(xe)==n
  xe  = xe(:);
  xe  = xe(:,[1 1]);
elseif all(size(xe)==[n 2])
  %do nothing
else
  error('Input (xe) must be [], 1x1, Nx1, or Nx2.')
end
if isempty(ye)
  %do nothing
elseif prod(size(ye))==1
  ye  = ones(n,2)*ye;
elseif length(ye)==n
  ye  = ye(:);
  ye  = ye(:,[1 1]);
elseif all(size(ye)==[n 2])
  %do nothing
else
  error('Input (ye) must be [], 1x1, Nx1, or Nx2.')
end

hh = ishold;

%Add points into the middle
if y_points
  hp = plot(x,y,'ob','markerfacecolor',[0 0 1],'markeredgecolor',[1 1 1]);
else
  hp = [];
end

%Create the bars... this code uses a vectorized form of the data so we
%create everything in one object from a single vector for x and y. Creating
%those "xl" and "yl" vectors, we create 9 columns. These are split into
%three columns for each item:
%   [ main bar     bar bottom    bar top ]
%where the third column in each set is a column of NaN's to hide the
%connection to the next object.

%do horizontal (x) error bars
if ~isempty(xe)
  %if there are x-error values
  dd   = mean(xe(:))/3;
  xm   = [x x];
  vnan = x*nan;
  %create vectors with line segments all combined together
  xl   = [xm+xe*diag([-1 1]) vnan xm-xe vnan xm+xe vnan]';
  yl   = [y y vnan y-dd y+dd vnan y-dd y+dd vnan]';
  if ~barends
    xl = xl(1:3,:);
    yl = yl(1:3,:);
  end
  xl   = xl(:);
  yl   = yl(:);
  %add line object to plot
  hx   = line(xl(:),yl(:),'color',[0 0 0]);
else
  hx = [];
end

%do vertical (y) error bars
if ~isempty(ye)
  %if there are y-error values
  dd   = mean(mean(ye))/3;
  ym   = [y y];
  vnan = y*nan;
  %create vectors with line segments all combined together
  xl   = [x x vnan x-dd x+dd vnan x-dd x+dd vnan]';
  yl   = [ym+ye*diag([-1 1]) vnan ym-ye vnan ym+ye vnan]';
  if ~barends
    xl = xl(1:3,:);
    yl = yl(1:3,:);
  end
  xl   = xl(:);
  yl   = yl(:);
  %add line object to plot
  hy   = line(xl,yl,'color',[0 0 0]);
  set(hy,'zdata',xl.*0-1);  %put this BEHIND other objects
else
  hy = [];
end

if hh
  hold on
else
  hold off
end

if nargout>0
  %note handles to pass back to user
  h = [hx hy hp];
else
  clear h
end
