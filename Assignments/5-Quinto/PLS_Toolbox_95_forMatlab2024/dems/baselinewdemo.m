echo on
% BASELINEWDEMO Demo of the BASELINEW function
 
echo off
% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The BASELINEW function is used to remove a broad baseline from
% the bottom of a spectrum.
 
% Consider the following data:
 
x   = [0.1:0.1:50];                  %axis scale
y   = [0.001*(x-20).^2+0.01*(x-20)]; %simulated baseline spectrum
 
figure, plot(x,y), title('Simulated Baseline Spectrum')
 
% This might represent the baseline that should be removed
% from a spectrum.
 
% Now add a high frequency component to the spectrum that 
% represents the desirable information and plot the results.
pause
%-------------------------------------------------
yhf = [0.1*exp(-(x-25).^2/20).*sin(2*pi*x*2).^2]; %simulated signal
 
plot(x,y,'b',x,y+yhf,'r'), legend('Baseline','Baseline w/ Signal','Location','NorthWest')
  
% In this case, the call to BASELINEW uses the following I/O:
% [y_b,b_b]= baselinew(y,x,width,order,res);
% We'll use a window width of 491, fit a second order polynomial
% in each window to the bottom of the spectrum, and the approximate
% noise level is given as 0.0001.
pause
%-------------------------------------------------
[y_b1,b_b1]= baselinew(y+yhf,x,491,2,0.0001);
 
% Now plot the results.
pause
%-------------------------------------------------
subplot(2,1,1), plot(x,y,  'b',x,b_b1,'r'), title('Baseline'), legend('Known','Estimated','Location','NorthWest')
subplot(2,1,2), plot(x,yhf,'b',x,y_b1,'r'), title('Signal'),   legend('Known','Estimated','Location','NorthWest')
 
% This isn't too bad. But remember, we need a pretty good
% estimate of the noise level near the baseline.
pause
%-------------------------------------------------
% The next example is a little bit different. First create
% a simulated spectrum with signal on the bottom and the
% baseline on the top.
 
y   = [0.5*sin(2*pi*x/40)+1];                        %baseline
yhf = [-0.2*exp(-(x-15).^2/20).*sin(2*pi*x*4).^2];   %signal
figure, plot(x,y,'b',x,y+yhf,'r'), legend('Baseline','Desired Signal','Location','SouthWest')
pause
%-------------------------------------------------
% Now the options structure for BASELINEW will be changed so
% that we can fit the polynomial to the top of the data instead
% of the bottom {default}.
 
options = baselinew('options')
options.trbflag = 'top';
 
% In this case, the call to BASELINEW uses the following I/O:
% [y_b,b_b]= baselinew(y,x,width,order,res,options);
% We'll use a window width of 101, fit a third order polynomial
% in each window to the bottom of the spectrum, and the approximate
% noise level is given as 0.0001.
 
[y_b2,b_b2] = baselinew(y+yhf,x,101,3,0.0001,options);
 
subplot(2,1,1), plot(x,y,  'b',x,b_b2,'r'), title('Baseline'), legend('Known','Estimated','Location','NorthEast')
subplot(2,1,2), plot(x,yhf,'b',x,y_b2,'r'), title('Signal'),   legend('Known','Estimated','Location','NorthEast'), shg
 
% This shows that the process isn't perfect, especially when the
% baseline is an odd-ball function.
 
% Be careful, some times small changes in the input can lead to
% very different results.
 
pause
%-------------------------------------------------
% One options is to add smoothing to the baseline.
 
options       = baselinew('options');
options.trbflag = 'top';
options.smooth = 1;
[y_b2a,b_b2a] = baselinew(y+yhf,x,21,3,0.00001,options);
 
subplot(2,1,1), plot(x,y,  'b',x,b_b2a,'r'), title('Baseline'), legend('Known','Estimated','Location','NorthEast')
subplot(2,1,2), plot(x,yhf,'b',x,y_b2a,'r'), title('Signal'),   legend('Known','Estimated','Location','NorthEast'), shg
 
% But this still isn't the best. The challenge here is that
% the "spectrum" and "baseline" covary in some windows.
 
pause
%-------------------------------------------------
% However, if we know that the baseline is a simple vector
% it can be input using (options.p). Here's an example where
% a perfect baseline is input.
 
options       = baselinew('options');
options.trbflag = 'top';
options.p     = y';
[y_b2a,b_b2a] = baselinew(y+yhf,x,[],[],0.0001,options);
 
subplot(2,1,1), plot(x,y,  'b',x,b_b2a,'r'), title('Baseline'), legend('Known','Estimated','Location','NorthEast')
subplot(2,1,2), plot(x,yhf,'b',x,y_b2a,'r'), title('Signal'),   legend('Known','Estimated','Location','NorthEast'), shg
 
% And the results are pretty good!
 
pause
%-------------------------------------------------
% In the case where the baseline is changing relatively slowly,
% a 0th order polynomial (a constant) can be fit in each window
% [the number of points in each window is defined by input (width)].
% So, consider the following situation
 
y   = [1 + 1e-7*mncn(x(:))'.^2];           %baseline
yhf = [0.2*exp(-(x-15).^2/20).*sin(2*pi*x*4).^2];   %signal
figure, plot(x,y,'b',x,y+yhf,'r'), legend('Baseline','Desired Signal','Location','NorthEast')
axis([0 50 0 1.25]), pause
%-------------------------------------------------
options         = baselinew('options');
options.trbflag = 'bottom';
options.tsqlim  = 0.9;
 
% In this case, the call to BASELINEW uses the following I/O:
% [y_b,b_b]= baselinew(y,x,width,order,res,options);
% Note that (res) is not used w/ 0th order so it will be
% input as an empty matrix [ ]. Input (x) is also not used.
% Input (width) is large because the baseline is ~flat.
 
[y_b3,b_b3] = baselinew(y+yhf,[],length(x)-1,0,[],options);
 
subplot(2,1,1), plot(x,y,  'b',x,b_b3,'r'), title('Baseline'), legend('Known','Estimated','Location','NorthEast')
subplot(2,1,2), plot(x,yhf,'b',x,y_b3,'r'), title('Signal'),   legend('Known','Estimated','Location','NorthEast'), shg
 
% The baseline isn't perfect, but the estimate is relatively fast.
 
%End of BASELINEWDEMO
 
echo off
