function [matrix_resolved,dispmatopt,summatrix]=resolve_maps_2d_cor(purintx,purinty,purspecx,purspecy,...
  varlistx,varlisty,dispersionmat,options)
%RESOLVE_MAPS_2D_COR Helper function for corpsec.m to resolve contributions maps.
%
% INPUTS:
%         purint   : resolved contributions (x and y)
%         purspec  : resolved spectra (x and y)
%         varlist  : axis scales (x and y), only used for plotting.
%   dispersionmat  : dispersion matrix, only used for plotting.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%       plots       : ['off'|{'on'}] governs level of plotting.
%       offset      : [3] noise correction factor. One element defines
%                     offset for both x and y, two elements separately for
%                     x and y.
%       zlim1       : [0] z limit one is bottom cutt-off, lowest value plotted.
%       nlevel      : [3] nlevel for contour map, number of contours.
%       clrmap      : ['hot'] colormap.
%       dispersion  : [1] If not given, only weight matrix
%                         will be calculated, otherwise select one of
%                         the options below:
%                         1: standardized, offset corrected
%                         2: length sqrt(nrows), offset corrected
%                         3: purity about mean, offset corrected
%                         4: purity about origin, offset corrected
%                         5: asynchronous, offset corrected
%  OUTPUTS:
%       matrix_resolved = resolved contributions maps.
%
%I/O: matrix_resolved = resolve_maps_2d_cor(purintx,purinty,purspecx,purspecy,varlistx,varlisty,dispmat);
%I/O: matrix_resolved = resolve_maps_2d_cor(purintx,purinty,purspecx,purspecy,varlistx,varlisty,dispmat,options);
%
%See also: CORRSPEC, RESOLVE_SPECTRA_2D_COR

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; purintx = 'io'; end

if ischar(purintx);

  options = [];
  options.plots           = 'off';
  options.offset          = 3;
  options.zlim1           = 0;
  options.nlevel          = 3;
  options.clrmap          = 'hot';
  options.dispersion      = 1;
  if nargout==0
    evriio(mfilename,purintx,options);
  else
    matrix_resolved = evriio(mfilename,purintx,options);
  end
  return;
end;

if nargin == 4 | nargin == 7
  options = resolve_spectra_2d_cor('options');
end
options = reconopts(options,resolve_maps_2d_cor('options'));

%Get offsets.
if isscal(options.offset)
  options.offset = [options.offset options.offset];
end

%Put options into var names.
zlim1  = options.zlim1;
nlevel = options.nlevel;

%Call to colormap will open a figure so need to use following eval command.
clrmap = feval(options.clrmap,64);

%INITIALIZE

[npurvar,lengthx]=size(purspecx);
[npurvar,lengthy]=size(purspecy);

%RECONSTRUCT THE X AND Y DATA

dataxrec=purintx*purspecx;
datayrec=purinty*purspecy;

%RECONSTRUCT DISPERSON MATRIX

dispmatrec=datayrec'*dataxrec;

%CALCULATE DISPERSION MATRIX DEFINED BY OPTION
copts.dispersion = options.dispersion;
copts.offsetx = options.offset(1);
copts.offsety = options.offset(2);
dispmatopt=dispmat(dataxrec,datayrec,copts);

%CALCULATE RESOLVED DISPMATOPT's

r=[];

xfactors=purspecx;
yfactors=purspecy';

%%%TEMP TEST FOR NNLS

xfactors=xfactors.*(xfactors>0);
yfactors=yfactors.*(yfactors>0);

%%%TEMP

[xfactorss,yfactorss,b]=matra(xfactors,yfactors,dispmatrec);
if any(b<0);
  %disp ('nnls used!');disp(b)
  [xfactorss,yfactorss,b]=matra(xfactors,yfactors,dispmatrec,1);
  %disp(b);
end

xfactors=xfactorss;yfactors=yfactorss;
xfactors=xfactors.*(xfactors>0);
yfactors=yfactors.*(yfactors>0);
dispmatrec=dispmatrec.*(dispmatrec>0);

for i=1:npurvar;
  d=yfactors(:,i)*xfactors(i,:);%dispersion matrix
  %d=d.*(d<=dispmatrec)+dispmatrec.*(dispmatrec<d);%substitues values
  %of dispmatrec in d
  %in case value in d is
  % larger
  m=(d>dispmatrec);d(m)=dispmatrec(m);
  w=d./dispmatrec;
  %w=w.*(w<=1)+(w>1);
  m=w>1;w(m)=1;
  %w=w.*(w>=0);
  w(w<0)=0;
  q=w.*dispmatopt;
  r=[r q];
end;
r=corrspecutilities('nan20',r);

incr=65/(nlevel+1);clrmapr=clrmap(round([incr:incr:64]),:);
summatrix=zeros(lengthy,lengthx);
for i=1:npurvar;
  summatrix=summatrix+matsplit(r,npurvar,i);
end;


lengthx=length(varlistx);lengthy=length(varlisty);
xlim=sort([varlistx(1) varlistx(lengthx)]);
ylim=sort([varlisty(1) varlisty(lengthy)]);
if varlistx(1)<varlistx(2);xdir='normal';else;xdir='reverse';end
if varlisty(1)<varlisty(2);ydir='normal';else;ydir='reverse';end

if strcmp(options.plots,'on')
  reset(gca);reset(clf);
  zlim1 = options.zlim1;

  colormap(clrmapr);
  subplot(2,2,1);
  %set(gca,'AspectRatio',[1 NaN],'XLim',xlim,'YLim',ylim,...
  set(gca,'PlotBoxAspectRatio',[1 1 1],'XLim',xlim,'YLim',ylim,...
    'TickDir','out','XDir',xdir,'YDir',ydir,'box','on');hold on;
  [a,b]=contour(varlistx,varlisty,limit(dispersionmat,zlim1),nlevel);
  title('original matrix');

  subplot(2,2,2);
  set(gca,'PlotBoxAspectRatio',[1 1 1],'XLim',xlim,'YLim',ylim,...
    'TickDir','out','XDir',xdir,'YDir',ydir,'box','on');hold on;
  contour(varlistx,varlisty,limit(dispmatopt,zlim1),nlevel);
  title('reconstructed matrix');

  subplot(2,2,3);
  set(gca,'PlotBoxAspectRatio',[1 1 1],'XLim',xlim,'YLim',ylim,...
    'TickDir','out','XDir',xdir,'YDir',ydir,'box','on');hold on;
  contour(varlistx,varlisty,limit(summatrix,zlim1),nlevel);
  title('sum resolved matrices');

  hold off
  subplot(2,2,4);plotcall(varlistx,varlisty,limit(r,zlim1),...
    npurvar,nlevel);axis('square');
  drawnow;

  title('overlay resolved matrices');
  drawnow;waitforbuttonpress%ginput(1);
  corrspecutilities('title4','resolved, scaled:')
  plotc4(varlistx,varlisty,limit(r,zlim1),npurvar,clrmap,nlevel);
end
for i=1:npurvar;
  index1=1+(i-1)*lengthx;
  index2=index1-1+lengthx;
  matrix_resolved{i}=r(:,index1:index2);
end;

%-----------------------------------------------------
function y=limit(x,limit1,limit2)
%LIMIT Replaces elements in x that are < limit1 and > limit 2.
% Replaces elements in x that are less than limit1 with the value limit1,
% and replaces elements in x that are greater than limit2 with the value
% limit2. If only one limit is needed, the other one can be left empty,
% or, in the case of limit2, left out.
%
%I/O: y=limit(x,limit1,limit2)
%
%See also: RESOLVE_MAPS_2D_COR

%Copyright Eigenvector Research, Inc. 2006-2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%ww  09/28/06

if nargin==2;limit2=[];end;

if ~isempty(limit1);
  array=x>limit1;
  x=(x.*array)+((~array)*limit1);
end;

if ~isempty(limit2);
  array=x<limit2;
  x=(x.*array)+((~array)*limit2);
end;
y=x;

%-----------------------------------------------------
function [xfactorss,yfactorss,b]=matra(xfactors,yfactors,dispmatrix,flagnns);
%MATRA Utility to calculate least squares approximation for dispmatrix. 
%
%function [xfactorss,yfactorss,b]=matra(xfactors,yfactors,dispmatrix,flagnns);
%calculates the coefficients to get the best least squares
%approximation of the matrix dispmatrix using the matrices
%yfactors(:,i)*xfactors(i,:).
%The presence of a 4th input argumant gives a non negative least squares
%solution.
%The first two output arguments are the scaled input arguments (scaled with b);
%The output argument b contains the scaling factors.

% Copyright © Eigenvector Research, Inc. 2006-2007
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%ww  09/28/06

 [nrow,ncol]=size(dispmatrix);
 npurvar=size(xfactors,1);
 matrecr=zeros(npurvar,nrow*ncol);
 for k=1:npurvar
    matrec=yfactors(:,k)*xfactors(k,:);
    matrecr(k,:)=reshape(matrec,1,nrow*ncol);
 end
 if nargin==4;
%    A=matrecr';
%    B=(reshape(dispmatrix,1,nrow*ncol))';
%    b=nnls(A,B);
     b=(fastnnls(matrecr',(reshape(dispmatrix,1,nrow*ncol))'))';
   else
     b=reshape(dispmatrix,1,nrow*ncol)/matrecr;
 end;
 xfactorss=xfactors;yfactorss=yfactors;
 for i=1:npurvar
     xfactorss(i,:)=xfactors(i,:)*sqrt(b(i));
     yfactorss(:,i)=yfactors(:,i)*sqrt(b(i));
 end;
 
%-----------------------------------------------------
function varargout=matsplit(a1,a2,a3);
%MATSPLIT Splits combined and factores matrices into nsub submatrices.
% It is assumed that the dimensions of matrix are: nrow,nsub*ncol,
% where nrow and ncol are the dimensions of the submatrices.
% The maximum number of submatrices is 12: n<=12.
%
%The function can be called in two different ways.
%for combined matrices:
%     [m1, m2, ... mnsub]=matsplit(matrix,nsub)
%          where matrix will be split into the nsub submatrics m1, m2, ...mnsub.
%     [summ]=matsplit(matrix,nsub,'sum')
%          where summ contains the sum of the submatrices.
%     [mn]=matsplit(matrix,nsub,n)
%          where the output will be only the nth submatrix
%
%for factored matrices:
%     [m1, m2, ... mnsub]=matsplit(xfactors,yfactors)
%          where the matrix will be split into nsub sumatrics m1, m2, ...mnsub.
%     [summ]=matsplit(xfactos,yfactors,'sum')
%          where summ contains the sum of the submatrices.
%     [mn]=matsplit(xfactors,yfactors,n)
%          where the output will be only the nth submatrix
%
%I/O: [m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12]=matsplit(a1,a2,a3)
%
%See also: RESOLVE_MAPS_2D_COR

%Copyright Eigenvector Research, Inc. 2006-2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%ww  09/28/06

if nargin==2;a3=[];end;
if length(a2)==1;

  %    combined matrix

  [nrow,ncol]=size(a1);
  ncolsub=ncol/a2;
  if rem(ncolsub,1);
    error...
      ('Improper use of function matsplit:# of submatrices is not right');
  end;

  if nargin==3&~isstr(a3);
    if a3>a2;error('Improper use of function matsplit: n<=nsub');end;
    index1=(a3-1)*ncolsub+1;index2=index1+ncolsub-1;
    %     m1=a1(:,index1:index2);
    varargout{1} = a1(:,index1:index2);
  else
    nsub=a2;
    for i=1:nsub;
      index1=(i-1)*ncolsub+1;index2=index1+ncolsub-1;
      %       eval(['m',num2str(i),'=zeros(nrow,ncolsub);']);
      %       eval(['m',num2str(i),'=a1(:,index1:index2);']);
      varargout{i} = a1(:,index1:index2);
    end;
  end;
else

  %    factored matrix;

  nsub=size(a1,1);
  if nargin==3&~isstr(a3);
    if a3>nsub;error('Improper use of function matsplit: n<=nsub');end;
    %     m1=a2(:,a3)*a1(a3,:);
    varargout{1} = a2(:,a3)*a1(a3,:);
  else
    for i=1:nsub;
      %       eval(['m',num2str(i),'=a2(:,i)*a1(i,:);']);
      varargout{i} = a2(:,i)*a1(i,:);
    end;
  end;

end;
if isstr(a3);
  %   [nrow,ncol]=size(m1);
  %   summatrix=zeros(nrow,ncol);
  %   for i=1:nsub
  %     eval(['summatrix=summatrix+m',num2str(i),';']);
  %     eval(['clear m',num2str(i),';']);
  %   end;
  varargout = {sum(cat(3,varargout{:}),3)};
end;

%------------------------------------------------------
function plotcall(varlistx,varlisty,xfactors,yfactors,nlevel)
%PLOTCALL Plots the resolved factored or combined matrices. 
% Plots xfactors and yfactors on top of each other in a contourmap, each
% with its own monochrome map, of which the chroma changes with z value. The
% x and y axes are given in varlistx and varlisty. The directions of the x
% and y axes in the plot are determined by the ascending or descending
% character of the varlists. Reversion can be obtained by using the function
% revdata. The arguments varlistx and varlisty are optional, but either none
% or both need to be given. The optional argument nlevel determines the
% number of contourlines in the plot, the default is 10.
%
%I/O: plotcall(varlistx,varlisty,xfactors,yfactors,nlevel)
%
%See also: RESOLVE_MAPS_2D_COR

%Copyright Eigenvector Research, Inc. 2006-2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%ww  09/28/06

%clg reset;clf reset;
a=[];
%colormap('default');
flagshort=0;
if size(varlistx,1)~=1 & size(varlistx,2)~=1;flagshort=1;end;

if nargin==2;
  yfactors=varlisty;xfactors=varlistx;
  nlevel=10;dirx='normal';diry='normal';
  varlistx=1:size(xfactors,2);varlisty=1:size(yfactors,1);
end;

if nargin==3;
  nlevel=xfactors;yfactors=varlisty;xfactors=varlistx;
  dirx='normal';diry='normal';
  varlistx=1:size(xfactors,2);varlisty=1:size(yfactors,1);
end;

if nargin==4;
  nlevel=10;
  if varlistx(1)<varlistx(2);dirx='normal';else;dirx='reverse';end;
  if varlisty(1)<varlisty(2);diry='normal';else;diry='reverse';end;
end;

if nargin==5;
  if varlistx(1)<varlistx(2);dirx='normal';else;dirx='reverse';end;
  if varlisty(1)<varlisty(2);diry='normal';else;diry='reverse';end;
end;


%SET THE AXES

if size(yfactors,1)==1 & size(yfactors,2)==1;
  [nrow,ncol]=size(xfactors);
  maxplot=yfactors;
  ncolsub=ncol/maxplot;
  flag=1;
  if flagshort;varlistx=1:ncolsub;varlisty=1:nrow;end;
else
  maxplot=size(xfactors,1);
  flag=0;
end;

xlim1=min(varlistx);xlim2=max(varlistx);
ylim1=min(varlisty);ylim2=max(varlisty);
if flag;
  zlim1=min(min(xfactors));
  zlim2=max(max(xfactors));
else
  zlim1=min(min(yfactors*xfactors));
  zlim2=max(max(yfactors*xfactors));
end;

%clrarray=round(1:(63/(nlevel-1)):64);
incr=65/(nlevel+1);clrarray=round(incr:incr:64);

done1=0;i=0;
while ~done1;
  %%%     clf;
  for j=1:maxplot;
    clrmap=mclrmap(j);
    if all(clrmap);clrmap=[0 0 0];end;
    i=i+1;
    if flag;
      index1=(i-1)*ncolsub+1;index2=index1+ncolsub-1;
      q=xfactors(:,index1:index2);
    else
      q=yfactors(:,i)*xfactors(i,:);
    end;
    %	set(gca,'AspectRatio',[1 NaN],'Xdir',dirx,'YDir',diry,...
    set(gca,'Xdir',dirx,'YDir',diry,...
      'XLim',[xlim1 xlim2],'YLim',[ylim1 ylim2],...
      'ZLim',[zlim1 zlim2],...
      'TickDir','out','box','on');hold on;
    [a,b]=contour(varlistx,varlisty,q,nlevel);hold off;
    set(b,'edgecolor',clrmap)
    drawnow; pause(0.05); % Replaces old line ('discard' option removed from Matlab): drawnow discard;
    if i==maxplot;done1=1;end;
  end;
  drawnow;
  watch0;
end;

%-----------------------------------------------
function clrmap=mclrmap(i)
%MCLRMAP Creates monochrome colormaps, but intensities are varied.
%Seven colors are defined, and are repeated when i>7
%
%I/O: clrmap=mclrmap(i)
%
%See also: PLOTCALL

%Copyright Eigenvector Research, Inc. 2006-2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%ww  09/28/06
i=rem(i,7);if i==0;i=1;end;

if i==1;basis=[1 1 1];end; % white
if i==2;basis=[1 0 0];end; % red
if i==3;basis=[0 1 0];end; % green
if i==4;basis=[0 0 1];end; % blue
if i==5;basis=[1 0 1];end; % magenta
if i==6;basis=[0 1 1];end; % cyan
if i==7;basis=[1 1 0];end; % yellow
%

%clrmap=zeros(64,3);

clrmap=basis;
%for i=64:-1:1;
%    f=(i-1)/63;
%    g=.5;
%    clrmap(i,:)=(f*(1-g)*basis)+g*basis;
%end;

%-------------------------------------------------
function watch0();
%WATCH0 Changes the mouse pointer into a crosshair.

%Copyright Eigenvector Research, Inc. 2006-2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%ww  09/28/06

set(gcf,'Name','');
set(gcf,'pointer','crosshair');
handle=uicontrol('Style','Text','units','normal',...
  'position', [0 .999 .001 .001]);
drawnow;
delete(handle)

%-------------------------------------------------
function plotc4(varlistx,varlisty,xfactors,yfactors,clrmap,nlevel,...
  flagfalsecolor,flagprint);
%function plotc4(varlistx,varlisty,xfactors,yfactors,clrmap,nlevel,...
%flagfalsecolor,flagprint);
%plots a contourplot of the factored or combined matrices in varlistx
%and varlisty, with the x and y axes as given in varlistx and varlisty.
%The directions of the x and y axes in the plot are determined by
%the ascending or descending character of the varlists. Reversion can be
%obtained by using the function revdata. The arguments varlistx and varlisty
%are optional, but either none or both need to be given.
%The optional argument clrlmap defines the colormap, with the default hot.
%The optional argument nlevel determines the number of contourlines in the
%plot, the default is 10. The optional argument flagfalsecolor results in
%false coloring for a value of 1. The function title4 can be used to get a
%title in the plots.

global PLOT4_STRING

%clf reset;
titlestring=PLOT4_STRING;clear global PLOT4_STRING;

%SET FLAG IF NO VARLISTS ARE GIVEN

flagshort=0;
if size(varlistx,1)~=1 & size(varlistx,2)~=1;flagshort=1;end;

if nargin==2;
  yfactors=varlisty;xfactors=varlistx;clrmap=hot;nlevel=10;
  varlistx=1:size(xfactors,2);varlisty=1:size(yfactors,1);
  %    dirx='normal';diry='normal';
  flagfalsecolor=0;flagprint=0;
end;

if nargin==3;
  clrmap=xfactors;yfactors=varlisty;xfactors=varlistx;nlevel=10;
  varlistx=1:size(xfactors,2);varlisty=1:size(yfactors,1);
  %    dirx='normal';diry='normal';
  flagfalsecolor=0;flagprint=0;
end;

if nargin==4;
  if flagshort;
    nlevel=yfactors;clrmap=xfactors;yfactors=varlisty;xfactors=varlistx;
    varlistx=1:size(xfactors,2);varlisty=1:size(yfactors,1);
    %        dirx='normal';diry='normal';
    flagfalsecolor=0;flagprint=0;
  else
    clrmap=hot;nlevel=10;;flagfalsecolor=0;
    %        dirx=vardir(varlistx);diry=vardir(varlisty);
    flagprint=0;
  end;
end;

if nargin==5;
  if flagshort;
    flagfalsecolor=clrmap;
    nlevel=yfactors;clrmap=xfactors;yfactors=varlisty;xfactors=varlistx;
    varlistx=1:size(xfactors,2);varlisty=1:size(yfactors,1);
    %        dirx='normal';diry='normal';
    flagprint=0;
  else
    nlevel=10;flagfalsecolor=0;flagprint=0;
    %       dirx=vardir(varlistx);diry=vardir(varlisty);
  end;
end;

if nargin==6;
  if flagshort;
    flagprint=nlevel; flagfalsecolor=clrmap;
    nlevel=yfactors;clrmap=xfactors;yfactors=varlisty;xfactors=varlistx;
    varlistx=1:size(xfactors,2);varlisty=1:size(yfactors,1);
    %        dirx='normal';diry='normal';
  else
    flagfalsecolor=0;flagprint=0;
    %        dirx=vardir(varlistx);diry=vardir(varlisty);
  end;
end;

if nargin==7;
  flagprint=0;
  %    dirx=vardir(varlistx);diry=vardir(varlisty);
end;

if nargin==8;
  %    dirx=vardir(varlistx);diry=vardir(varlisty);
end;

%SET THE AXES

colormap(clrmap);

if size(yfactors,1)==1 & size(yfactors,2)==1;
  [nrow,ncol]=size(xfactors);
  maxplot=yfactors;
  ncolsub=ncol/maxplot;
  flag=1;
  if flagshort;varlistx=1:ncolsub;varlisty=1:nrow;end;
else
  maxplot=size(xfactors,1);
  flag=0;
end;

xlim1=min(varlistx);xlim2=max(varlistx);
ylim1=min(varlisty);ylim2=max(varlisty);
%clrarray=round(1:(63/(nlevel-1)):64);
incr=65/(nlevel+1);clrarray=round(incr:incr:64);

done1=0;done2=0;i=0;
while ~done1;
  done2=0;j=0;clf;
  while ~done2;
    j=j+1;i=i+1;
    if flag;
      index1=(i-1)*ncolsub+1;index2=index1+ncolsub-1;
      q=xfactors(:,index1:index2);
    else
      q=yfactors(:,i)*xfactors(i,:);
    end;
    subplot(2,2,j);
    %set(gca,'AspectRatio',[1 NaN],'Xdir',...
    set(gca,'Xdir',...
      vardir(varlistx),'YDir',vardir(varlisty),...
      'XLim',[xlim1 xlim2],'YLim',[ylim1 ylim2],...
      'TickDir','out','box','on');axis('square');hold on;
    if flagfalsecolor
      set(gcf,'inverthardcopy','off');
      pcolor(varlistx,varlisty,q);shading flat;
      contour(varlistx,varlisty,q,nlevel,'k');
    else
      contour(varlistx,varlisty,q,nlevel);
    end;
    colormap(clrmap(clrarray,:));
    title([titlestring,num2str(i)]);
    if i==maxplot;done1=1;done2=1;end;
    if j==4;done2=1;end;
  end;
  if ~exist ('flagprint'); flagprint = 0; end;
  if flagprint == 1;
    print -dwin;
  else;evripause(1);waitforbuttonpress
  end;
end;
close

%-------------------------------------------------
function direction=vardir(varlist);
%function direction=vardir(varlist);
%results in the value 'normal ' when varlist is ascending and in 'reverse'
%when varlist is descending;

if varlist(1)<=varlist(2);direction='normal ';else;direction='reverse';end;
