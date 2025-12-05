function h = hline(y,lc)
%HLINE Adds horizontal lines to figure at specified locations.
%  HLINE draws a horizontal line on an existing figure
%  from the left axis to the right axis at a height, or
%  heights, defined by (y) which can be a scalar or vector. 
%  The optional input variable (lc) can be used to define the 
%  line style and color as in normal plotting. Example:
%  hline(1.4,'--b'); plots a horizontal dashed
%  blue line at y = 1.4. If no input arguments are given,
%  hline will draw a horizontal green line at 0.
%  Output (h) is handle(s) of line(s) drawn.
%
%I/O: h = hline(y,lc);
%
%See also: ABLINE, BOXPLOT, DP, ELLPS, PLTTERN, PLTTERNF, VLINE, ZLINE

%Copyright Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified 2/97 NBG
%Modified 3/98 BMW
%nbg 11/00 modified see also
%1/01 nbg changed 'See Also' to 'See also' and allow lc input
%4/02 jms added output of line handle(s)

if nargin==0
  y   = 0;
  lc  = '-g';
end
if nargin==1                 %1/01 nbg
  if isa(y,'char')
    lc = y;
    y  = 0;
  elseif isa(y,'double')
    lc = '-g';
  end
end

if ischar(lc) & ismember(lc,evriio([],'validtopics'));
  varargin{1} = lc;
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; h = evriio(mfilename,varargin{1},options); end
  return; 
end

[m,n] = size(y);
if m>1&n>1
  error('Error - input must be a scaler or vector')
elseif n>1
  y   = y';
  m   = n;
end

v     = axis;
if ishold
  for ii=1:m
    h(ii) = plot(v(1:2),[1 1]*y(ii,1),lc);
  end
else
  hold on
  for ii=1:m
    h(ii) = plot(v(1:2),[1 1]*y(ii,1),lc);
  end
  hold off
end

if nargout == 0;
  clear h
end
