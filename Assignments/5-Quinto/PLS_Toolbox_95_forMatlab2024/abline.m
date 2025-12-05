function h = abline(slope,intercept,varargin)
%ABLINE Draws a line on the current axes with a given slope and intercept.
%  Inputs are the slope (slope) and intercept (intercept) of the line to
%  draw.
%  If a 3D plot is shown, slope and intercept can be 2-element vectors
%  describing the slope and intercept of the line in the y- and z- dimensions.
%  Optional line style information can also be included. For more information
%  on linestyle information, see help on the LINE command.
%  The output (h) is the handle of the plotted line object.
%
%Example:
%  plot(1:10,3*(1:10),'ob')
%  abline(3,-1,'color','r','linestyle',':')
%
%I/O: h = abline(slope,intercept)
%I/O: h = abline(slope,intercept,...)  %additional linestyle information
%
%See also: DP, HLINE, VLINE, ZLINE

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 1/05
%JMS 3/1/05 -added evriio code
%NBG 9/08 modified help

if nargin<1; slope = 'io'; end
if isa(slope,'char');
  options = [];
  if nargout==0; clear h; evriio(mfilename,slope,options); else; h = evriio(mfilename,slope,options); end
  return; 
end

if nargin<3;
  varargin = {'color','r'};
end

%get current axes
x = get(gca,'xlim');
y = get(gca,'ylim');
z = get(gca,'zlim');

%draw line
if length(slope)==1;
  h = line(x,x*slope+intercept,varargin{:});
else
  h = line(x,x*slope(1)+intercept(1),x*slope(2)+intercept(2),varargin{:});
end

%reset axes to original values
set(gca,'xlim',x,'ylim',y,'zlim',z);

if nargout==0;
  clear h
end
