function h = plotmonotonic(xdata,ydata,varargin)
%PLOTMONOTONIC Plot lines with breaks when the x-value "doubles-back" on itself.
% Creates an x,y plot in which each continuously increasing segment of x
% defines a separate line. When x has a negative slope, the given line
% segment is not shown. 
%INPUTS:
%   x  = vector of x-values for plot
%   y  = vector or array of y-values to plot against x
%OUTPUTS:
%   h  = vector of handles to objects created by plot.
%
%I/O: h = plotmonotonic(x,y)
%
%See also: PLOTGUI

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0
  xdata = 'io';
end
if ischar(xdata)
  options = [];
  if nargout==0; evriio(mfilename,xdata,options); else; h = evriio(mfilename,xdata,options); end
  return;
end

if size(xdata,1)==1
  xdata = xdata';
end
if size(ydata,1)==1 | size(ydata,2)==size(xdata,1)
  ydata = ydata';
end
if size(xdata,1)~=size(ydata,1)
  error('Vectors must be the same lengths.')
end

%locate double-back steps
finx = find(isfinite(xdata));
steps = zeros(length(xdata)-1,1);
steps(finx(1:end-1)) = sign(diff(xdata(finx)));
direction = sign(mean(steps));
backs = (steps==-direction);
newpos = cumsum([1 backs'+1]);  %locate new location of real points

if size(ydata,2)==1 & any(backs)
  %single vector do multiple lines with colors
  backs = [0; find(backs); length(ydata)];
  pnts = [];
  lines = {};
  for j=2:length(backs);
    %for each segment we've doubled-back on
    use = backs(j-1)+1:backs(j);
    switch length(use)
      case 1
        %only one point? just add to points
        pnts(end+1,1:3) = [xdata(use) ydata(use) j-1];
      otherwise
        %locate NaN surrounded single points within the vector
        excl = [0;find(isnan(xdata(use)));length(use)+1];
        excl = excl(diff(excl)==2)+1;
        if ~isempty(excl)
          %and add those as "points"
          expnts = [xdata(use(excl)) ydata(use(excl)) ones(length(excl),1)*j-1];
          pnts(end+(1:size(expnts,1)),1:3) = expnts;
        end
        %for everything else, add as a line to add
        luse = length(use);
        lines(end+1,1:3) = {xdata(use) ydata(use) j-1};
    end
    
  end
  
  %get color order
  clr = get(gca,'colororder');
  nc  = size(clr,1);
  %draw points (if any)
  h1 = [];
  vis = 'on';
  for j=1:size(pnts,1);
    h1(j,1) = line(pnts(j,1),pnts(j,2));
    set(h1(j),'color',clr(mod(pnts(j,3)-1,nc)+1,:),'marker','.','handlevisibility',vis);
    vis = 'off';
  end
  
  %draw lines (if any)
  h2 = [];
  vis = 'on';
  for j=1:size(lines,1);
    h2(j,1) = line(lines{j,1},lines{j,2});
    set(h2(j),'color',clr(mod(lines{j,3}-1,nc)+1,:),'handlevisibility',vis);
    vis = 'off';
  end
  
  h = [h1;h2];
  
else
  %replicate those nans into intermediate points
  newx  = nan(max(newpos),1);  %craete new larger vector (to pad with NaN between segements)
  newy  = nan(size(newx,1),size(ydata,2));
  newx(newpos,:) = xdata;  %insert original data into longer vector (leaving NaN's)
  newy(newpos,:) = ydata;
  xdata = newx;
  ydata = newy;
  
  %do plot
  linestyle = '-';
  h = plot(xdata,ydata,linestyle);
  
  %find orphened points
  excl = find(isnan(xdata));
  excl = excl(diff(excl)==2)+1;
  if ~isempty(excl)
    set(plot(xdata(excl),ydata(excl,:),'.'),'handlevisibility','off');
  end
  
end

if nargout==0
  clear h
end
