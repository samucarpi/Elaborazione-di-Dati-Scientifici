function [t,p] = makepancake(flag)
%MAKEPANCAKE Constructs the floating pancake plot.
%  OPTIONAL INPUT:
%    flag = [ {0} | 1 | 2 ] governs what is plotted.
%           flag==0 makes original floating pancake.
%           flag==1 makes two overlapped pancakes.
%           flag==2 makes two non-overlapped pancakes.
%
%  OUPUTS:
%    t = mx2 scores matrix.
%    p = 3x3 loadings matrix.
%
%I/O: [t,p] = makepancake;

%Copyright (c) Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%nbg
%nbg modified the help, change from script to function
%nbg 9/11/08 added optional input (flag)

if nargin<1
  flag = 0;
end

p = [0.7 0.1
     0.1 0.8
     0.2 0.05];
p = normaliz(p')';

t = [-1.0106    0.0975
      0.6145    0.0220
      0.5077   -0.1589
      1.6924   -0.1399
      0.5913    0.1109
     -0.6436   -0.2375
      0.3803    0.1953
     -1.0091    0.1422
     -0.0195   -0.2054
     -0.0482   -0.0664
      0.0000   -0.2969
     -0.3179   -0.5506
      1.0950    0.2466
     -1.8740   -0.1297
      0.4282    0.0818
      0.8956    0.0585
      0.7310    0.0054
      0.5779   -0.2510
      0.0403   -0.2368
      0.6771   -0.0936
      0.5689   -0.2965
     -0.2556   -0.2640
     -0.3775    0.3681
     -0.2959    0.0139
     -1.4751   -0.3043
     -0.2340   -0.0103
      0.1184   -0.2821
      0.3148   -0.3373
      1.4435   -0.0653
     -0.3510    0.2384
      0.6232    0.0322
      0.7990    0.1641
      0.9409   -0.2920
     -0.9921   -0.1152
      0.2120   -0.0656
      0.2379   -0.3033
     -1.0078   -0.3299
     -0.7420    0.2328
      1.0823    0.0028
     -0.1315   -0.1613];

switch flag
case 0
  %Get the data for the ellps
  f = figure;
  plot(t(:,1),t(:,2),'o')
  h = ellps([0 0],[2 0.5]);
  xe = get(h,'xdata');
  ye = get(h,'ydata');

  mx = [1.5 1 2];
  t2 = rescale([max(xe) min(ye)]*p',mx);
  p3 = normaliz(([0 0 1]*(eye(3)-p*p')))';
  qi = rescale([min(xe)/2 max(ye)/2]*[p]',mx);
  q  = rescale([min(xe)/2 max(ye)/2 1.5]*[p p3]',mx);

  p1 = rescale(max(xe)*p(:,1)',mx);
  p2 = rescale(max(ye)*p(:,2)',mx);
  x = rescale(t*p',mx);
  xe = rescale([xe' ye']*p',mx);

  figure(f)
  plot3(x(:,1),x(:,2),x(:,3),'og'), hold on
  axis([0 4 0 3 0 3])
  plot3(xe(:,1),xe(:,2),xe(:,3),'-k','linewidth',2), grid
  plot3([mx(1) p1(1)],[mx(2) p1(2)],[mx(3) p1(3)],'-b','linewidth',2)
  plot3([mx(1) p2(1)],[mx(2) p2(2)],[mx(3) p2(3)],'-b','linewidth',2)
  plot3([mx(1) t2(1)],[mx(2) t2(2)],[mx(3) t2(3)],'-r')
  plot3(t2(1),t2(2),t2(3),'or','markerfacecolor',[1 0 0])
  plot3([qi(1) q(1)],[qi(2) q(2)],[qi(3) q(3)],'-r')
  plot3(q(1),q(2),q(3),'or','markerfacecolor',[1 0 0])
  set(gca,'xtick',0:4,'ytick',0:3,'ztick',0:3)
  set(gcf,'color',[1 1 1])
  view(-29.5, 24)
  xlabel('Variable 1','FontSize',14,'FontName','Times')
  ylabel('Variable 2','FontSize',14,'FontName','Times')
  zlabel('Variable 3','FontSize',14,'FontName','Times')
  hold off
case 1
  %Get the data for the ellps
  f = figure;
  plot(t(:,1),t(:,2),'o')
  h = ellps([0 0],[2 0.5]);
  xe = get(h,'xdata');
  ye = get(h,'ydata');

  mx = [1.5 1 2];
  t2 = rescale([max(xe) min(ye)]*p',mx);
  p3 = normaliz(([0 0 1]*(eye(3)-p*p')))';
  qi = rescale([min(xe)/2 max(ye)/2]*[p]',mx);
  q  = rescale([min(xe)/2 max(ye)/2 1.5]*[p p3]',mx);

  p1 = rescale(max(xe)*p(:,1)',mx);
  p2 = rescale(max(ye)*p(:,2)',mx);
  x0 = rescale(t*p',mx);
  xf = rescale([xe' ye']*p',mx);

  figure(f)
  plot3(x0(:,1),x0(:,2),x0(:,3),'og','markerfacecolor',[0 0.6 0]), hold on
  axis([0 6 0 5 0 3])
  plot3(xf(:,1),xf(:,2),xf(:,3),'-k','linewidth',2)
  plot3([mx(1) p1(1)],[mx(2) p1(2)],[mx(3) p1(3)],'-b','linewidth',2)
  plot3([mx(1) p2(1)],[mx(2) p2(2)],[mx(3) p2(3)],'-b','linewidth',2)
  
  mx = [1.2 1.1 1.5];
  p  = p*[0.8   0.36;
          0.36 -0.8];
  t  = t*diag([0.8 1.4]);
  p1 = rescale(max(xe)*p(:,1)',mx);
  p2 = rescale(max(ye)*p(:,2)',mx);
  x  = rescale(t*p',mx);
  xe = rescale([xe' ye']*p',mx);

  figure(f)
  plot3(x(:,1),x(:,2),x(:,3),'^r','markerfacecolor',[0.8 0 0])
  axis([0 4 0 3 0 3])
  plot3(xe(:,1),xe(:,2),xe(:,3),'-k','linewidth',2), grid
  plot3([mx(1) p1(1)],[mx(2) p1(2)],[mx(3) p1(3)],'-b','linewidth',2)
  plot3([mx(1) p2(1)],[mx(2) p2(2)],[mx(3) p2(3)],'-b','linewidth',2)
  
  set(gca,'xtick',0:4,'ytick',0:3,'ztick',0:3)
  set(gcf,'color',[1 1 1])
  view(-29.5, 24)
  xlabel('Variable 1','FontSize',14,'FontName','Times')
  ylabel('Variable 2','FontSize',14,'FontName','Times')
  zlabel('Variable 3','FontSize',14,'FontName','Times')
  hold off
case 2
  %Get the data for the ellps
  f = figure;
  t = t*diag([0.8 0.9]);
  plot(t(:,1),t(:,2),'o')
  h = ellps([0 0],[2 0.5]);
  xe = get(h,'xdata');
  ye = get(h,'ydata');

  mx = [1.5 1 2];
  t2 = rescale([max(xe) min(ye)]*p',mx);
  p3 = normaliz(([0 0 1]*(eye(3)-p*p')))';
  qi = rescale([min(xe)/2 max(ye)/2]*[p]',mx);
  q  = rescale([min(xe)/2 max(ye)/2 1.5]*[p p3]',mx);

  p1 = rescale(max(xe)*p(:,1)',mx);
  p2 = rescale(max(ye)*p(:,2)',mx);
  x0 = rescale(t*p',mx);
  xf = rescale([xe' ye']*p',mx);

  figure(f)
  plot3(x0(:,1),x0(:,2),x0(:,3),'og','markerfacecolor',[0 0.6 0]), hold on
  axis([0 6 0 5 0 3])
  plot3(xf(:,1),xf(:,2),xf(:,3),'-k','linewidth',2)
  plot3([mx(1) p1(1)],[mx(2) p1(2)],[mx(3) p1(3)],'-b','linewidth',2)
  plot3([mx(1) p2(1)],[mx(2) p2(2)],[mx(3) p2(3)],'-b','linewidth',2)
  
  mx = [2.4 0.8 1.25];
  p  = p*[0.9   0.19;
          0.19 -0.9];
  t  = t*diag([0.8 1.1]);
  p1 = rescale(max(xe)*p(:,1)',mx);
  p2 = rescale(max(ye)*p(:,2)',mx);
  x  = rescale(t*p',mx);
  xe = rescale([xe' ye']*p',mx);

  figure(f)
  plot3(x(:,1),x(:,2),x(:,3),'^r','markerfacecolor',[0.8 0 0])
  axis([0 4 0 3 0 3])
  plot3(xe(:,1),xe(:,2),xe(:,3),'-k','linewidth',2), grid
  plot3([mx(1) p1(1)],[mx(2) p1(2)],[mx(3) p1(3)],'-b','linewidth',2)
  plot3([mx(1) p2(1)],[mx(2) p2(2)],[mx(3) p2(3)],'-b','linewidth',2)
  
  set(gca,'xtick',0:4,'ytick',0:3,'ztick',0:3)
  set(gcf,'color',[1 1 1])
  view(-29.5, 24)
  xlabel('Variable 1','FontSize',14,'FontName','Times')
  ylabel('Variable 2','FontSize',14,'FontName','Times')
  zlabel('Variable 3','FontSize',14,'FontName','Times')
  hold off
end
