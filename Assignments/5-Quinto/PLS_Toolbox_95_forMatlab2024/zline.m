function h = zline(x,y,lc)
%ZLINE Adds vertical lines to 3D figure at specified locations.
%  ZLINE draws a vertical line on an existing 3D figure from the
%  bottom axis to the top axis at position or positions defined
%  by (x) and (y) which can be a scalar or vector.
%  Optional input variable (lc) can be used to define the line
%  style and color as in normal plotting.
%
%Example: zline(2.5,1.2,'-r'); plots a vertical solid red line at
%  x = 2.5 and y = 1.2.
%
%  If no input arguments are given, zline will draw a vertical green
%  line at 0,0.  
%  Output (h) is handle(s) of line(s) drawn.
%
%I/O: h = zline(x,y,lc);
%
%See also: ABLINE, DP, ELLPS, HLINE, PLTTERN, PLTTERNF, VLINE

%Copyright Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified 2/97 NBG
%Modified 3/98 BMW
%11/00 nbg changed see also
%1/01 nbg changed 'See Also' to 'See also' and allowed for lc
%4/02 jms added output of handle(s)

if nargin==0
  x   = 0;
  y   = 0;
  lc  = '-g';
end
if nargin==1                 %1/01 nbg
  if isa(x,'char')
    lc = x;
    x  = 0;
    y  = 0;
  elseif isa(x,'double')
    y  = 0;
    lc = '-g';
  end
end
if nargin==2                 %8/02 nbg
  lc = '-g';
end

if isa(lc,'char') & ismember(lc,evriio([],'validtopics'));
  varargin{1} = lc;
  options = [];
  if nargout==0; clear h; evriio(mfilename,varargin{1},options); else; h = evriio(mfilename,varargin{1},options); end
  return; 
end

[m,n]   = size(x);
if m>1&n>1
  error('Error - input (x) must be a scaler or vector.')
end
x       = x(:); m = length(x);

[my,n] = size(y);
if my>1&n>1
  error('Error - input (y) must be a scaler or vector.')
end
y       = y(:); my = length(y);

if m~=my
  error('Error - inputs (x) and (y) must be of same length.')
end

v     = axis;
if length(v)<6;
  h = [];   %not 3D plot? don't do anything!
else
  if ishold
    for ii=1:m
      h(ii) = plot3([1 1]*x(ii,1),[1 1]*y(ii,1),v(5:6),lc);
    end
  else
    hold on
    for ii=1:m
      h(ii) = plot3([1 1]*x(ii,1),[1 1]*y(ii,1),v(5:6),lc);
    end
    hold off
  end
end

if nargout==0;
  clear h
end
