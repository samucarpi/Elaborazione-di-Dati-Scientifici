function varargout = yscale(infscale,xrange,allaxes)
%YSCALE Rescales the y-axis limits on each subplot in a figure.
%  Each axes on a subplot is rescaled so that the y-scale tightly fits the
%  maximum and minimum of the displayed data. The input (infscale),
%  when set to 1 (one), also rescales each line object on each axes to
%  tightly fit the new limits (i.e. inf-scales each line object relative to
%  one another). Default is 0 (scale axis to data). The input (xrange)
%  uses the specified x-axis range for scaling rather than the current axis
%  settings.
%  If the single output (ax) is requested, the plots are not rescaled, but
%  the axis which would have been used is returned.
%  The optional third input (allaxes) rescales the specified axis or axes
%  handles. Default is to rescale all axes.
%
%I/O: yscale(infscale,xrange,allaxes)
%I/O: ax = yscale(infscale,xrange,allaxes)

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 5/03
%jms 7/03 evriio enabled

if nargin>0 & ischar(infscale);
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,infscale,options); else; varargout{1} = evriio(mfilename,infscale,options); end
  return; 
end

fig = get(0,'currentfigure');
if isempty(fig); return; end

if nargin<1;
  infscale = 0;
end
if nargin<2;
  xrange = [];
end
if nargin<3;
  allaxes = findobj(fig,'type','axes');
end

if nargout == 1;
  %prepare if they want an output
  varargout = {[]};
end

for axh = allaxes';
  %make axis tight to fit height of all curves
  set(fig,'currentaxes',axh);
  if isempty(xrange)
    ax = axis;
  else
    ax = [xrange 0 1];
  end
  children = get(axh,'children');
  
  mn = inf;
  mx = -inf;
  globalmax = -inf;
  globalmin = inf;
  for i = 1:length(children)
    if strcmp(get(children(i),'type'),'line')
      xdata = get(children(i),'xdata');
      ydata = get(children(i),'ydata');
      ind = (xdata>=ax(1) & xdata<=ax(2));
      if ~any(ind); continue; end
      lmn = min(ydata(ind));
      lmx = max(ydata(ind));
      if ~infscale
        mn = min(mn,lmn);
        mx = max(mx,lmx);
      else
        if infscale==2
          lmx = mean(ydata(ind));
        end
        if lmx==lmn; lmx = lmn+1; end
        ydata = (ydata-lmn)./(lmx-lmn);
        set(children(i),'ydata',ydata);
        mx = max(mx,max(ydata(ind)));
        globalmin = min(globalmin,min(ydata));
        globalmax = max(globalmax,max(ydata));
      end
    end
  end
  
  if ~infscale;  %rescale axis to fit data
    if isinf(mn); mn = ax(3); end
    if isinf(mx); mx = ax(4); end
    if mn==mx; 
      rng = 100;
    else
      rng = mx-mn;
    end
    mn = mn-rng*.05;
    mx = mx+rng*.05;
  else  %rescale data to 0-1
    mn = 0;
    mx = 1.01;

    %reset zoom scale
    temp = getappdata(gca,'matlab_graphics_resetplotview');
    if isfield(temp,'XLim')
      %new zoom mode looks here for unzoomed axes range
      temp.YLim = [globalmin globalmax];
      setappdata(gca,'matlab_graphics_resetplotview',temp);
    else
      axz = get(gca,'ZLabel');
      fullscale = getappdata(axz,'ZOOMAxesData');    %This is where zoom will look for the unzoomed axes range
      if ~isempty(fullscale);
        fullscale(3:4) = [globalmin globalmax];
        setappdata(axz,'ZOOMAxesData',fullscale);    %This is where zoom will look for the unzoomed axes range
      end
    end

  end

  if nargout==0
    axis([ax(1:2) mn mx]);
  else
    varargout{1}(end+1,:) = [ax(1:2) mn mx];
  end
  
end
