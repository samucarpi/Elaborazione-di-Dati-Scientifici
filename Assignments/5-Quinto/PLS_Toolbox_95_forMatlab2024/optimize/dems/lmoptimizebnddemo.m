echo on
%LMOPTIMIZEBNDDEMO Demo of the LMOPTIMIZEBND function
 
echo off
%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The objective of this demo is to find (x) that minimizes
% the Rosenbrock banana function:
%    f(x(1),x(2)) = 100*(x(1)^2-x(2))^2+(x(1)-1)^2 
% under the constraint that x(2) must be > 1.1.
% The true minimum is at the point x = [1,1].
% But first let's plot the response surface.
 
%  Make a surface plot of the banana function
 
figure('color',[1 1 1])
ax1     = [-1.5:0.1:1.5];     ax2     = [-1.5:0.1:2];
[a1,a2] = meshgrid(ax1,ax2);
alpha   = 10;
fval    = 10*alpha*(a1.*a1-a2).^2 + (a1-1).^2; %Banana function
mesh(a1,a2,fval), xlabel('x_1'), ylabel('x_2')
x0      = [-0.5 1.75];
axis([-2 2 -2 2 0 1500]), view(125,45), zline(x0(1),x0(2),'r'), zline(1,1,'b')
text(x0(1),x0(2),1500,'Starting Point')
text(1,1,1500,'Optimum'), drawnow
 
pause
%-------------------------------------------------
% Make a contour plot of the banana function
 
figure('color',[1 1 1])
contour(ax1,ax2,fval,10.^[0.2:0.2:log10(max(max(fval)))])
xlabel('x_1'), ylabel('x_2'), hold on
plot(1,1,'ob','markerfacecolor',[0 0 1],'markersize',6)
plot(x0(1),x0(2),'or','markersize',6,'markerfacecolor',[1 0 0])
vline(0.9,'r')
text(0.92,-0.2,'Upper Boundary')
text(x0(1),x0(2),' Initial Guess')
text(1,1,' Optimum'), drawnow
 
% Next we'll run the optimizer on to estimate the optimum
 
pause
%-------------------------------------------------
% Get the options and turn off the display back to the
% Command window, and turn on the saving of the intermediate
% results so that they can be plotted.
 
options   = lmoptimizebnd('options');
options.x = 'on'; options.Jacobian = 'on'; options.Hessian = 'on';
options.display = 'off';
options.alow    = [0 0]; %x(1) and x(2) unbounded on low side
options.aup     = [1 0]; %x(1) bounded on high side and x(2) unbounded on high side
 
pause
%-------------------------------------------------
% Run LMOPTIMIZEBND
[x,fval,exitflag,out] = lmoptimizebnd(@banana,x0,[0 0],[0.9 0],options);
plot(out.x(:,1),out.x(:,2),'-o','color',[0.4 0.7 0.4],'markersize',2, ...
  'markerfacecolor',[0 0.5 0],'markeredgecolor',[0 0.5 0]), shg
 
% The optimizer finds a bounded estimate at
 disp(x)
 
%End of LMOPTIMIZEBNDDEMO
%
%See also: LMOPTIMIZE
 
echo off
