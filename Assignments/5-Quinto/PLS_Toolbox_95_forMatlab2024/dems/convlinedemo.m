echo on
% CONVLINEDEMO Demo of the CONVLINE function
 
echo off
% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The CONV1 function is used to convolve row vectors of an MxN matrix X and
% a 1xW vector X2 [inputs (x) and (x2) to the CONV1 function respectively].
% It is typical that W is <N.
 
% In this example, two narrow peaks in X will be convolved with a
% triangular and a boxcar line-shape in X2 to produce a MxN result Y.
% The demo will also indicate the point at the ends of the result that
% correspond to a non-full window that are often subject to "end-effects."
 
% The first step is to create two narrow peaks [one Gaussian and one
% Lorentzian centered at 20.5 on an axis scale 1:40] and plot the results.
 
pause
 
ax    = 1:40;                            % Axis scale
x     = [peakgaussian(  [1 20.5 1],ax);  % Gaussian
         peaklorentzian([1 20.5 1],ax)]; % Lorentzian
  figure('Name','Peaks and Lines','color',[1 1 1]);
  subplot(2,1,1);
  plot(ax,x)
  axis([0 40 0 1])
  title('Narrow Peaks')
  xlabel('Axis Scale')
  legend('Gaussian','Lorentzian')
  legend('autoupdate','off')
    hh  = vline(20.5,'-k');
    set(hh,'LineWidth',0.5)
    uistack(hh,'bottom')
x     = dataset(x);

x2    = normaliz([[1 2 3 4 5 6 5 4 3 2 1]; % triangular line-shape
                   ones(1,11)],[],1);      % boxcar line-shape
  subplot(2,1,2);      
  plot(-5:5,x2,'o-')
  axis([-6 6 0 0.25])
  title('Normalized Line Shapes for Convolution')
  legend('triangular','boxcar')
  legend('autoupdate','off')
    hh  = vline(0,'-k');
    set(hh,'LineWidth',0.5)
    uistack(hh,'bottom')
 
% Note that x2 has two rows for convenience but the convolution will be
% performed for one row of x2 at a time.
 
% The next step is to peform the convolution and plot those results.
 
pause
  
[y1,d1] = convline(x,x2(1,:)); % convolve with triangular line-shape
[y2,d2] = convline(x,x2(2,:)); % convolve with boxcar line-shape
 
  figure('Name','Convolved Peaks','color',[1 1 1]);
  a1    = subplot(2,1,1);
  if isdataset(x)
    plot(ax,[x.data(1,:); y1.data(1,:); y2.data(1,:)])
  else
    plot(ax,[x(1,:); y1(1,:); y2(1,:)])
  end
  axis([0 40 0 1])
  title('Convolved Gaussian Peak')
  xlabel('Axis Scale')
  legend('Gaussian','Trianglular Line','Boxcar Line')
  legend('autoupdate','off')
    hh  = vline(20.5,'-k');
    set(hh,'LineWidth',0.5)
    uistack(hh,'bottom')
  a2    = subplot(2,1,2);
  if isdataset(x)
    plot(ax,[x.data(2,:); y1.data(2,:); y2.data(2,:)])
  else
    plot(ax,[x(2,:); y1(2,:); y2(2,:)])
  end
  axis([0 40 0 1])
  title('Convolved Lorentzian Peak')
  xlabel('Axis Scale')
  legend('Lorentzian','Trianglular Line','Boxcar Line')
  legend('autoupdate','off')
    hh  = vline(20.5,'-k');
    set(hh,'LineWidth',0.5)
    uistack(hh,'bottom') 
 
% Now add "x's" where the filter X2 is not a full width. These are the
% protions of the convolved result Y that should not be included in further
% analysis due to the potential for end -effects. (Of course, in this
% example, the ends correspond to zero signal and including themm is no
% big deal. However, in general the end should be excluded.)
 
pause
 
p     = (size(x2,2)-1)/2; % Size of window corresponding to non-full filter width
axes(a1), hold on
plot(1:p,    zeros(1,p),'xr')
plot(41-p:40,zeros(1,p),'xr')
axes(a2), hold on
plot(1:p,    zeros(1,p),'xr')
plot(41-p:40,zeros(1,p),'xr')
 
% The "x's" correspond to a window with a non-full filter width that 
% could potentially be affected by end effects. Because the filter X2
% is 11 channels wide, the 5 points on each end are excluded.
 
% What if the filter is of even length? Create X2 with an even number of
% elements and redo the example.
 
pause
 
x2    = normaliz([[1 2 3 4 5 5 4 3 2 1]; % triangular line-shape
                   ones(1,10)],[],1);    % boxcar line-shape
[y1,d1] = convline(x,x2(1,:)); % convolve with triangular line-shape
[y2,d2] = convline(x,x2(2,:)); % convolve with boxcar line-shape
 
  figure('Name','Convolved Peaks','color',[1 1 1]);
  subplot(2,1,1);
  plot(ax,[x(1,:); y1(1,:); y2(1,:)])
  axis([0 40 0 1]), hold on
  title('Convolved Gaussian Peak')
  xlabel('Axis Scale')
  legend('Gaussian','Trianglular Line','Boxcar Line')
  legend('autoupdate','off')
    hh  = vline([20 20.5],'-k');
    set(hh,'LineWidth',0.5)
    uistack(hh,'bottom')
  p     = (size(x2,2))/2-1;
  plot(1:p,    zeros(1,p),'xr')
  plot(40-p:40,zeros(1,p+1),'xr')
  a2    = subplot(2,1,2);
  plot(ax,[x(2,:); y1(2,:); y2(2,:)])
  axis([0 40 0 1]), hold on
  title('Convolved Lorentzian Peak')
  xlabel('Axis Scale')
  legend('Lorentzian','Trianglular Line','Boxcar Line')
  legend('autoupdate','off')
    hh  = vline([20 20.5],'-k');
    set(hh,'LineWidth',0.5)
    uistack(hh,'bottom')                 
  plot(1:p,    zeros(1,p),'xr')
  plot(40-p:40,zeros(1,p+1),'xr')

% The "x's" correspond to a window with a non-full filter width that 
% could potentially be affected by end effects. Because the filter X2
% is an even 10 channels wide, the 4 points on the left end and 5 points
% on the right end are excluded, AND the peak is shifted left 1/2 a channel.
 
%End of CONV1DEMO
 
%See Also: conv, savgol

echo off
