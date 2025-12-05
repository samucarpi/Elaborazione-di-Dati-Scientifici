function purvarmixturedemo;
%Copyright (c) Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%GET MIXTURE DATA
 
[mixturedata,purecomponentmatrix,compositionmatrix]=createdata;
 
%LENGTH SCALED DATA;
 
lengtharray=sqrt(sum(mixturedata.*mixturedata));
lengthmatrix=lengtharray([1 1],:);
mixturedatascaled=mixturedata./lengthmatrix;
 
%PLOT DATA WITH PURE SPECTRUM VECTORS
 
hold off
close;plot(mixturedatascaled(1,:),mixturedatascaled(2,:),'k.',...
   [-.5 1.5],[0 0],'k',[0 0],[-.5 1.5],'k');
axis([-.5 1.5 -.5 1.5]);axis('square');
title('click mouse to set vector, right click to exit');
 
%LINE CONNECTION TWO MIXTURE SPECTRA 
 
hold on;plot([0 1],[1 0],'k-*');
 
%LINE CONNECTION TWO PURE COMPONENT SPECTRA
 
hold on;plot([-.5 1.5],[1.5 -.5],'k');
 
%VECTORS TO PURE VARIABLES
 
h=plot([mixturedatascaled(1,end) 0 mixturedatascaled(1,1)],...
    [mixturedatascaled(2,end) 0 mixturedatascaled(2,1)],'k-',...
    mixturedatascaled(1,end),mixturedatascaled(2,end),'ko',...
    mixturedatascaled(1,1),mixturedatascaled(2,1),'kv');
xlabel('\bfx_1');ylabel('\bfx_2');
 
set(h,'Markersize',10,'Linewidth',2);
 
%INTERACTIVE PART
 
 
h=[];h2=[];
while 1;
    [x,y,button]=ginput(1);
    if button~=1;close;return;end;
    delete(h);delete(h2);
    r=cart2pol(x,y); 
    spec_mix=[cos(r) sin(r)]*mixturedata;
    spec_mix=1+.5*spec_mix/max(spec_mix);
    x=linspace(1,1.5,length(spec_mix));
    plot([1 1 1.5],[1.5 1 1],'k');hold on;
    h=plot(1.3*[0 cos(r)],1.3*[0 sin(r)],'k-','erasemode','xor');
    set(h,'Linewidth',3.5);
    h2=plot(x,spec_mix,'k','erasemode','xor'); 
end;
    
 
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
 
function [mixturedata,purecomponentmatrix,compositionmatrix]=createdata(flagplot);
%mixturedata=createdata(flagplot);
%Creates simple mixture data set.
%The optional argumentflagplot plots the data
 
%DEFINE PURE SPECTRA
 
purecomponent1=.5*gauss(25,7,100)+gauss(50,7,100);	%spectrum first pure 
																	 	%component
purecomponent2=gauss(50,7,100)+.5*gauss(75,7,100);	%spectrum second pure
																		%component                                                                       
%NORMALIZE TO MAX 1
 
purecomponent1=purecomponent1/max(purecomponent1);
purecomponent2=purecomponent2/max(purecomponent2);
purecomponentmatrix=[purecomponent1;purecomponent2];
 
%DEFINE COMPOSITION
 
composition1=[.75 .25]';%contributions of pure components in first mixture
composition2=[.25 .75]';%contributions of pure components in second mixture
compositionmatrix=[composition1 composition2];
 
%CALCULATE MIXTURE DATA SET
 
mixturedata=compositionmatrix*purecomponentmatrix;
 
%PLOT DATA
 
if nargin;
   close;
   x=1:100;
   subplot(221);h=plot(x,purecomponent1,'r');title('Pure Component \bfA');
   set(h,'Linewidth',2);
   fignumber('a)',[.2 .15]);
   subplot(222);h=plot(x,purecomponent2,'b');title('Pure Component \bfB');
   set(h,'Linewidth',2);
   fignumber('b)',[.2 .15]);
   
   subplot(223);h=plot(...
      [25 25],[0 mixturedata(1,25)],'k',[75 75],[0 mixturedata(1,75)],'k',...
  x,.75*purecomponent1,'r',x,.25*purecomponent2,'b',...
  x,mixturedata(1,:),'k');
  set(h,'Linewidth',2);
   title(['\bfMIX_1: \rm0.75\bfA\rm+0.25\bfB']);
   h=text(25,mixturedata(1,25)+.1,'I_1');set(h,'Fontsize',12,'FontWeight','bold');
   h=text(75,mixturedata(1,75)+.1,'I_2');set(h,'Fontsize',12,'FontWeight','bold');
   fignumber('c)',[.2 .15]);
   
   subplot(224);h=plot(...
      [25 25],[0 mixturedata(2,25)],'k',[75 75],[0 mixturedata(2,75)],'k',...
      x,.25*purecomponent1,'r',x,.75*purecomponent2,'b',...
      x,mixturedata(2,:),'k');
  set(h,'Linewidth',2);
   title(['\bfMIX_2: \rm0.25\bfA\rm+0.75\bfB']);
   h=text(25,mixturedata(2,25)+.1,'I_3');set(h,'Fontsize',12,'FontWeight','bold');
   h=text(75,mixturedata(2,75)+.1,'I_4');set(h,'Fontsize',12,'FontWeight','bold');
   fignumber('d)',[.2 .15]);
   print -djpeg fig1.jpg
   
   pause
%-------------------------------------------------
   subplot(223);plot(x,mixturedata(1,:),'k');%,...
      %[25 25],[0 mixturedata(1,25)],'k',[75 75],[0 mixturedata(1,75)],'k');
   title(['mixture spectrum 1: .75 .25']);
   %text(25,mixturedata(1,25)+.004,'I1');
   %text(75,mixturedata(1,75)+.004,'I2');
   
      
   subplot(224);plot(x,mixturedata(2,:),'b');%,...
      %[25 25],[0 mixturedata(2,25)],'k',[75 75],[0 mixturedata(2,75)],'k');
   title(['mixture spectrum 2: .25 .75']);
   %text(25,mixturedata(2,25)+.004,'I1');
   %text(75,mixturedata(2,75)+.004,'I2');
 
 
   
end;
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function y=gauss(mean,std,npoints);
%calculates gaussian distribution
%y=gauss(mean,std,npoints);
 
x=1:npoints;
c=1/(std*sqrt(2*pi));
p=(x-mean)/std;
y=c*exp(-.5.*p.*p);
 
 
