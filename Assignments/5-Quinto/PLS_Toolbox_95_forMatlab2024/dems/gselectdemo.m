echo on
% GSELECT Demo of the GSELECT function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The GSELECT function is used to allow the user to select data points on a
% plot. It is fairly generic in that it allows a variety of "modes" of
% selection and it operates on various graphics objects. It returns a
% binary (0/1) vector or array for each object on the current plot.
 
pause
%-------------------------------------------------
% To demonstrate, here is a plot of sine and cosine curves:
 
figure
 
x = 0:.2:pi*2; plot(x,sin(x),'-o',x,cos(x),'-o');
 
pause
%-------------------------------------------------
%Try selecting using the standard "rbbox" (rubber-band box)
 
pause
%-------------------------------------------------
echo off
title('Demo of "rbbox" mode: Click and drag a box around some of the points.') 
echo on
 
selected = gselect('rbbox');
 
echo off
title(' ') 
echo on
 
% the output variable "selected" is a cell with two vectors (one vector
% for each of the line objects)
 
selected
 
pause
%-------------------------------------------------
% We can look at an individual cell in selected to see which points were
% selected on each line indicated by 1s (ones):
 
selected{1}
 
selected{2}
 
% Now try using the 'ys' mode which allows selection of a range of
% y-values...
 
pause
%-------------------------------------------------
echo off
title('Demo of "ys" mode: Click and drag to select an x-range to select.') 
echo on
 
selected = gselect('ys');
 
echo off
title(' ') 
echo on
 
% Note the ranges you selected:
 
selected{1}
 
selected{2} 
 
pause
%-------------------------------------------------
% The order of the lines in the output will usually be in the order of most
% recently plotted backwards to first plotted (selected{1} is the second
% line, selected{2} is the first line)
% You can, however, specify a handle to select ON:
 
plot(x,cos(x),'g-');       %plot one line
hold on
h = plot(x,sin(x),'-o');    %plot another line, getting it's handle (h)
 
echo off
title('"polygon": Click to set a vertex, press the "Enter" key when done.') 
echo on
 
selected = gselect('polygon',h);       %use polygon selection to select items on h
 
echo off
title(' ') 
echo on
 
% This time "selected" is a cell of a single vector because we specified
% the handle we were interested in...
 
selected
 
pause
%-------------------------------------------------
% here's the details of your selection:
 
selected{1}
 
pause
%-------------------------------------------------
% There are many other modes (see "help gselect") and similar outputs are
% given for images.
 
pause
%-------------------------------------------------
hold off
clf
z = imagesc;             %get "default" image
colormap gray
axis ij image
data = get(z,'cdata');   %extract data for image 
 
selected = gselect('rbbox');
 
% Now "selected" is a cell containing an array the same size as the image:
 
selected
 
pause
%-------------------------------------------------
% This "selected" matrix can be used to modify the original data matrix.
% Just for fun, we'll invert this part of the image...
 
data(selected{1}) = 32-data(selected{1});
imagesc(data);
axis ij image
 
%End of GSELECT demo
 
echo off
 
   
