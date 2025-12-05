function h = stick(xdata, ydata, shiftfraction)
%STICK Plots stick graph.
%  Useful for Mass Spec data, plots "sticks" on y axis. Used with
%  plotguitypes.m. 
%
%  INPUTS:
%    xdata - vector of xdata.
%    ydata - vector or array of ydata.
%
%  OPTIONAL INPUTS:
%    shiftfraction - fraction of the average x data spacing to shift each
%                    spectrum so that spectra do no overlay each other.
%                    Default = 100. Value of zero disables shift.
%  OUTPUTS:
%    h - figure handle.
%
%I/O: h = stick(xdata,ydata,shiftfraction);
%
%See also: PLOTGUITYPES

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%rsk 04/27/06 created from Windig code.

if nargin ~= 2
  error('STICK requires 2 inputs.')
end
if nargin<3
  shiftfraction = 100;
end

ydims = ndims(ydata);
ysz   = size(ydata);
xsz   = size(xdata);

if ~isvec(xdata)
  error('STICK requires a vector input for xdata.')
end

if ydims>2
  error('STICK requires ydata input be 2D array or vector.')
end

%Transpose xdata to column vector if needed.
if xsz(2)>xsz(1)
  xdata = xdata';
end

%Transpose ydata if needed.
if ysz(2)==max(xsz)
  ydata = ydata';
end

colororder = get(gca,'ColorOrder');

%this code can be used to offset each stick by a little bit...
half  = size(ydata,2)/2;
if shiftfraction>0
  delta = min(diff(xdata))/half/shiftfraction;
else
  delta = 0;
end

%prepare x-axis
lengthspec = size(ydata,1)+2;
v  = [2*xdata(1)-xdata(2)  xdata'  2*xdata(end)-xdata(end-1)];
px = reshape([v;v;v],1,3*lengthspec);

%prepare y-vector
py = zeros(1,lengthspec*3);

holdstatus = get(gca,'nextplot');

try
  for i = 1:size(ydata,2)
    py(5:3:end-3) = ydata(:,i);  %insert THIS y into py
    switch i
      case 1
        %do NOT hold plot
      otherwise
        hold on
    end      
    h(i) = plot(px+delta*(i-half-.5), py);
  end
catch
end
set(h,{'color'},mat2cell(colororder(mod([1:size(ydata,2)]-1,length(colororder))+1,:),ones(1,size(ydata,2)),3));

set(gca,'nextplot',holdstatus)

if nargout==0
  clear h
end
