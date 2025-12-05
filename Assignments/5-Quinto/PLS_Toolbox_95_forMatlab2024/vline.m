function h = vline(x,lc)
%VLINE Adds vertical lines to figure at specified locations.
%  VLINE draws a vertical line on an existing figure from
%  the bottom axis to the top axis at position(s) defined
%  by (x). (x) can be a scalar or vector. If (x) is not
%  supplied a line is drawn at 0 {default}.
%  Optional input variable (lc) can be used to define the
%  line style and color as in normal plotting (see PLOT).
%  If no input arguments are given, vline will draw a 
%  vertical green line at 0.
%  Output (h) is the handle(s) of line(s) drawn.
%
%  Example vline(2.5,'-r'); plots a vertical solid
%  red line at x = 2.5.   
%
%I/O: h = vline(x,lc);
%I/O: vline demo
%
%See also: ABLINE, DP, ELLPS, HLINE, PLTTERN, PLTTERNF, ZLINE

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
  lc  = '-g';
end
if nargin==1                 %1/01 nbg
  if isa(x,'char')
    lc = x;
    x  = 0;
  elseif isa(x,'double')
    lc = '-g';
  end
end

if isa(lc,'char') & ismember(lc,evriio([],'validtopics'));
  varargin{1} = lc;
  options = [];
  if nargout==0; clear h; evriio(mfilename,varargin{1},options); else; h = evriio(mfilename,varargin{1},options); end
  return; 
end

%if nargin<2
%  lc  = '-g';
%end
[m,n] = size(x);
if m>1&n>1
  error('Error - input must be a scaler or vector')
elseif n>1
  x   = x';
  m   = n;
end

v     = axis;
if ishold
  for ii=1:m
    h(ii) = plot([1 1]*x(ii,1),v(3:4),lc);
  end
else
  hold on
  for ii=1:m
    h(ii) = plot([1 1]*x(ii,1),v(3:4),lc);
  end
  hold off
end

if nargout == 0;
  clear h
end
