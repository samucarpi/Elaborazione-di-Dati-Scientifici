function h=dp(lc,flag)
%DP Draws a diagonal line on an existing figure.
%  DP draws a diagonal line on an existing figure from the
%  bottom left axis to the upper right axis. This is useful
%  for placing a line of "perfect prediction" on plots of
%  predicted versus known.
%  Optional input variable (lc) can be used to define the
%   line style and color as for normal plotting. For example,
%   dp('--b') plots a 45 degree diagonal dash blue line.
%   If (lc) is empty, the default line style is used.
%  Optional input (flag), when set to 1, flips the direction of the
%   diagonal line - going from top left axis to bottom right axis.
%  Output (h) is handle of the line object.
%
%I/O: h = dp(lc,flag);
%I/O: dp demo
%
%See also: ABLINE, ELLPS, HLINE, PLTTERN, PLTTERNF, VLINE, ZLINE

%Copyright Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%1/01 nbg changed 'See Also' to 'See also'
%4/02 jms added output of handle
%1/03 nbg added undocumented "flipped dp" option
%2/03 jms modified help and allowed single input to be either lc or flag

if nargin<1
  lc  = '-g';
  flag = 0;
else
  if nargin<2
    flag = 0;   %default flag (unless we find that lc was actually "flag")
  end
  if ~isempty(lc) & ~isstr(lc)
    flag = lc;
    lc = [];
  end
  if isempty(lc)
    lc  = '-g';
  end
end

if ischar(lc) & ismember(lc,evriio([],'validtopics'));
  varargin{1} = lc;
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; h = evriio(mfilename,varargin{1},options); end
  return; 
end

v     = axis;
ur = max([v(2) v(4)]);
ll = min([v(1) v(3)]);
switch flag
case 0
  if ishold
    h = plot([ll ur],[ll ur],lc);
  else
    hold on, h = plot([ll ur],[ll ur],lc); hold off
  end
case 1
  if ishold
    h = plot([ll ur],[ur ll],lc);
  else
    hold on, h = plot([ll ur],[ur ll],lc); hold off
  end
end

if nargout == 0; clear h; end  %don't return if not requested
