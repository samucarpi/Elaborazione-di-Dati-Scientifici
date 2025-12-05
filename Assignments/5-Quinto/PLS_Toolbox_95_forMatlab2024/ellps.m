function varargout = ellps(cnt,a,lc,ang,pax,zh)
%ELLPS Plots an ellipse on an existing figure.
%  The center of the ellipse is plotted at (cnt) [1 by 2]
%  and the ellipse size is given by (a), with the x-range
%  [a(1,1)] and y-range [a(1,2)].
%  Optional input variable (lc) defines the line style and color
%  as in normal plotting. Optional input (ang) allows rotation
%  of the ellips by an angle (ang) {default: ang = 0 radians}.
%  Optional output (h) is the handle of the created ellipse.
%
%Example: ellps([2 3],[4 1.5],':r');
%  plots a dotted ellipse with center (2,3), semimajor axis 4
%  parallel to the x-axis and semiminor 1.5 parallel to the y-axis.
%
%  Optional inputs (pax) and (zh) are used when plotting in a 3D
%  plot. (pax) defines the axis perpindicular to the plane of the
%  ellipse [1 = x axis, 2 = y axis, 3 = z axis], and (zh) defines
%  the distance along the (pax) axis to plot the ellipse.
%
%Example: ellps([2 3],[4 1.5],'-b',pi/4,3,2);
%  plots an ellipse in a plane perpindicular to the z axis at height z = 2.
%
%I/O: h = ellps(cnt,a,lc,ang,pax,zh);
%I/O: ellps demo
%
%See also: DP, HLINE, PLTTERN, PLTTERNF, VLINE, ZLINE

%Copyright Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified NBG 2/96, 11/96
%1/01 nbg changed 'See Also' to 'See also'
%10/02 jms added output option

if nargin == 0; cnt = 'io'; end
varargin{1} = cnt;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<3,  lc  = '-g'; end
if nargin<4,  ang = 0;    end
if nargin<5,  pax = 0;    end
if nargin<6,  zh  = 0;    end
z     = [0:0.1:2*3.15]';
x     = a(1)*cos(z)+cnt(1)*ones(size(z));
y     = a(2)*sin(z)+cnt(2)*ones(size(z));
if ang~=0
  ang = ang*ones(size(z));
  x   = a(1)*cos(z-ang).*cos(ang)-a(2)*sin(z-ang).*sin(ang);
  x   = x+cnt(1)*ones(size(z));
  y   = a(1)*cos(z-ang).*sin(ang)+a(2)*sin(z-ang).*cos(ang);
  y   = y+cnt(2)*ones(size(z));
end
if ishold
  h = plot(x,y,lc);
  if pax~=0
    zax = zeros(size(x));
    if pax==3
      h = plot3(x,y,zax,lc);
    elseif pax==2
      h = plot3(x,zax,y,lc);
    elseif pax==1
      h = plot3(zax,x,y,lc);
    end
  end
else
  if pax~=0
    zax = ones(size(x))*zh;
    if pax==3
      hold on, h = plot3(x,y,zax,lc); hold off
    elseif pax==2
      hold on, h = plot3(x,zax,y,lc); hold off
    elseif pax==1
      hold on, h = plot3(zax,x,y,lc); hold off
    end
  else
    hold on, h = plot(x,y,lc); hold off
  end
end

if nargout > 0;
  varargout = {h};
end
