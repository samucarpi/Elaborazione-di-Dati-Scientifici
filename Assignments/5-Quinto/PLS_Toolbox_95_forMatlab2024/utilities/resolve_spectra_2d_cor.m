function [purintx,purinty,purspecx,purspecy]= resolve_spectra_2d_cor...
  (purvarindexx,purvarindexy,datax,datay,varlistx,varlisty,cat,options);
%RESOLVE_SPECTRA_2D_COR Helper function for corpsec.m to resolve contributions and spectra.
%
% INPUTS:
%   purvarindex  : column vector of pure variable indices (x and y)
%   data         : raw data (x and y)
%   varlist      : *axis scales{2} (x and y), only used for plotting.
%   cat          : *axsis scale one.
%
% OUTPUT:
%       purint   : resolved contributions(x and y).
%       purspecx : resolved spectra (x and y).
%
% OPTIONAL INPUT options structure with one or more of the following fields
%       plots    : ['off'|{'on'}] governs level of plotting.
%
%I/O:[purintx,purinty,purspecx,purspecy]= resolve_spectra_2d_cor(purvarindexx,purvarindexy,datax,datay,varlistx,varlisty,cat,options)
%
%See also: CORRSPECENGINE, RESOLVE_MAPS_2D_COR

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%ww  09/28/06
if nargin == 0; purvarindexx = 'io'; end

if ischar(purvarindexx);

  options = [];
  options.plots           = 'on';     %Governs plots to make

  if nargout==0
    evriio(mfilename,purvarindexx,options);
  else
    purintx = evriio(mfilename,purvarindexx,options);
  end
  return;
end;

if nargin < 8
  options = resolve_spectra_2d_cor('options');
end
options = reconopts(options,resolve_spectra_2d_cor('options'));

%INITIALIZE

lengthx=size(datax,2);
lengthy=size(datay,2);
npurvar=length(purvarindexx);
xfactors=[];
yfactors=[];

%RESOLVE DATAX AND DATAY AND PLOT IF REQUESTED

[purspecx,purintx]=resolve(datax, [], purvarindexx);
[purspecy,purinty]=resolve(datay,[],purvarindexy);

if strcmp(options.plots,'on')
  %resloveh = figure;
  %plot4(x1,data.arg.purspec,c,[],options,resloveh);
  %if ishandle(resloveh)
  %  close(resloveh);
  %end
  corrspecutilities('title4','resolved x ');
  plot4(varlistx,purspecx,'@k');
  %resloveh = figure(2);
  %options.returnfig= 'off';
  %plot4_button(varlistx,purspecx,'@k',[],options,resloveh);
  %plot4_button(varlistx,purspecx,'@k',[],options,resloveh);
  %if ishandle(resloveh)
  %  close(resloveh);
  %end


  corrspecutilities('title4','resolved x ');
  %options.returnfig= 'off';
  %plot4_button(cat,purintx,'k*',[],options);
  plot4(cat,purintx,'k*');
  corrspecutilities('title4','resolved y ');
  %options.returnfig= 'off';
  %plot4_button(varlisty,purspecy,'@k',[],options);
  plot4(varlisty,purspecy,'@k');
  corrspecutilities('title4','resolved y ');
  %options.returnfig= 'off';
  %plot4_button(cat,purinty,'k*',[],options);
  plot4(cat,purinty,'k*');
  corrspecutilities('title4','pure variables x-y ');
  %options.returnfig= 'off';
  %plot4_button(purintx,purinty,'k*',[],options);
  plot4(purintx,purinty,'k*');
end;

%RECONSTRUCT DATAMATRICES

dataxrec=purintx*purspecx;
datayrec=purinty*purspecy;

%RECONSTRUCT DISPERSION MATRIX

dispmatrec=datayrec'*dataxrec;

%----------------------------------------
function [purspec,purint] = resolve(data,data2,purvarindex,varlist,flagconts,flagcontv,cat)
%RESOLVE Resolves mixture data using pure variables.
% Is a simplisma function to resolve the mixture, using the pure variables.
% If the last 4 arguments are not available, no plots are made.
% For information about the arguments execute the function simarg.

%
%initialize
%
[ncas, nvar] = size (data);% setpurvar = zeros (nvar, 1);
temp = purvarindex;
%
%ask how many pure variables to use
%
npurdefault = length (temp);
if npurdefault == 0; return; end;
if nargin == 7;
  npur = input (['# of pure variables to use [',...
    (int2str (npurdefault)) , '] > ']);
  if isempty (npur); npur = npurdefault; end;
  if npur == 0; return; end;
  %     if npur < length (setpurvar);
  %         temp ((npur + 1) : (length (setpurvar))) = [];
  if npur < length (temp);
    temp ((npur + 1) : (length (temp))) = [];
  end;
else
  npur = npurdefault;
end
%
%resolve spectra
%
purematrix = (data (:, temp));
%

if isempty (data2); purspec=purematrix\data;
else purspec=purematrix\data2;
end;
%
%normalize the resolved spectra
%
%%% purspec = norma (purspec);
%
%resolve intensities
%
if isempty (data2); purint=data/purspec;
else purint=data2/purspec;
end;

%SCALE

if isempty(data2);tsi=sum(data')';else;tsi=sum(data2')';end;
a=purint\tsi;
purint=purint*diag(a);
purspec=inv(diag(a))*purspec;
%
if nargin == 3;return;end;
%
%plot the spectra and the intensities
%
% close;
% if flagconts == 1; linetype = '@-k'; else linetype = '@|k'; end;
% close;plot4 (varlist, purspec, linetype);close;
% if flagcontv == 1; linetype = '@-k'; else linetype = '@*k'; end;
% plot4 (cat, purint, linetype);close;
% disp ('pure variable     corr. coeff.');
% for i = 1 : npur; 
  %   a = varlist (purvarindex (i));
  %   temp=  corrcoef ((purematrix (:, i)), (purint (:, i)));
  %   temp=temp(2);
  %b(i) = corr ((purematrix (:, i)), (purint (:, i)));
  %fprintf ('  %5.0f            %8.4f\n',a,b(i));
% end;
% meanb=mean(b);
% fprintf('average correlation: %8.4f\n',meanb);

%---------------------------------------------
function plot4 (x,y, linetype, flagsave)
%
%plot4 (x,y, linetype, flagsave) makes 4 plots at a time of the separate
%rows or columns in x and y. The linetype is the same as in the plot
%function, with two one additions:
%1) linetype | results in bargraphs.
%2) the addition of the @ character in linetype results in effects to
%accomadate plots of spectra:
%       a) the original order of x is preserved in the plot (ascending
%          or descending) to so that, for example, wavenumbers can be
%          plotted in descending order.
%       b) a line is drawn at y=0;
%If a - sign is typed, the spectrum counter will be reset so that instead
% of spectrum n, n+1, n+2 and n+3, the spectra n-2, n-1, n and n+1 will
% be plotted.
%Typing q will result in quit.
%The title is by default the sequence number. If the function title4
%is used prior to plot4, the string defined by title4 will be added
%to the title; The fourth, optional, argument, with a value one
%results in printing the plots by issuing the print -dwin command.
%Also see title4


global PLOT4_STRING

%INITIALIZATIONS

titlestring=PLOT4_STRING;clear global PLOT4_STRING;
flagmultistring=0;
if size(titlestring,1)>1;flagmultistring=1;end;
flagxdir=0;
% printmen

[m, n]= size (x);j=0;
if nargin == 1;  [m, n] = size (x); y = x; x = 1: m; linetype = '-';end;
if nargin == 2; linetype = '-';
  [m, n] = size (x);
  if isstr (y); linetype = y; y = x; x = 1: m;
  else
    [p, q] = size (y);
    if (p + q) == 2;
      linetype = '-'; y = x; x = 1: m; flagsave = 1;
    end;
  end;
end;
if nargin == 3;
  if isstr (y); linetype = y; y = x; x = 1 : m; flagsave = 1; end;
  if ~isstr (linetype); linetype = '-'; flagsave = 1; end;
end;

%EXTRACT PROPER INFORMATION OUT OF LINETYPE

if any(linetype=='@');
  flagxdir=1;
  linetype=linetype(linetype~='@');
  if isempty(linetype);linetype='-';end;
else
  flagdirx=0;
end;

l = length (linetype); color2 = 'k';
if l > 1; color2 = linetype (:, (linetype ~= '|')); end;

[x,y]=lineup(x,y);maxplot=size(y,2);
if size(x,2)==1;flag1x=1;else;flag1x=0;;end;
drawnow;
set(gcf,'name','Click in Figure to continue');
done1=0;done2=0;i=0;
while ~done1;
  done2=0;j=0;
  subplot(221);cla;set(gca,'Visible','off');
  subplot(222);cla;set(gca,'Visible','off');
  subplot(223);cla;set(gca,'Visible','off');
  subplot(224);cla;set(gca,'Visible','off');

  while ~done2;
    j=j+1;i=i+1;
    if flag1x;ix=1;else;ix=i;end;
    if ~any(linetype=='|');
      minx=min(x(:,ix));maxx=max(x(:,ix));
      subplot(2,2,j);
      if flagxdir;
        plot ([minx maxx],[0,0],'k',x(:,ix),y(:,i),linetype);
        set(gca,'Xdir',vardir(x));
        myaxis(x(:,ix),y(:,i));
      else
        plot (x(:,ix),y(:,i),linetype);
        %              plot ([minx maxx],[0,0],'k',x(:,ix),y(:,i),linetype);
      end;

      if flagmultistring;
        %title(titlestring(i,:));
        title_string=[num2str(i),'/',num2str(maxplot)];

        title(title_string);
        xlabel(titlestring(i,:));
      else
        %title([titlestring,num2str(i),'/',num2str(maxplot)]);
        title_string=[num2str(i),'/',num2str(maxplot)];

        title(title_string);
        %title([num2str(i),'/',num2str(maxplot)]);
        xlabel(titlestring);
      end;
    else
      subplot(2,2,j);[temp1,temp2]=lbar(x(:,ix),y(:,i));
      %if ~strcmp(whatcolordef,'none')&strcmp(color2,'w');color2='k';end;
      plot (temp1, temp2, color2);
      myaxis(x(:,ix),y(:,i));
      if flagmultistring;
        %            title(titlestring(i,:));
        xlabel(titlestring(i,:));
      else
        %            title([titlestring,num2str(i),num2str(maxplot)]);
        title([num2str(i),'/',num2str(maxplot)]);
        xlabel(titlestring);
      end;

      if flagxdir;set(gca,'Xdir',vardir(x));end;
    end;
    if i==maxplot;done1=1;done2=1;end;
    if j==4;done2=1;end;
  end;
  if ~exist ('flagsave'); flagsave = 0; end;
  if flagsave == 1;
    print -dwinc;
  else;
    try;[a,b,c]=ginput(1);catch;close;return;end;%wwginput
    %try;waitforbuttonpress;catch;close;return;end;%wwginput
    if isempty(a);a=0;end;
    if isempty(b);b=0;end;
    if isempty(c);c=0;end;
    if c==45;i=i-6;if i<0;i=0;end;end;
    if c==113;break;end;

  end;
end;
%%%%%%%close
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [xl,yl]=lineup(x,y);
%function [xl,yl]=lineup(x,y);
%lineup matrices so that they have the same # of rows.
%If x and y are (row or column) arrays columns will result


[nrowx,ncolx]=size(x);
[nrowy,ncoly]=size(y);
if nrowx==1;x=x';temp=nrowx;nrowx=ncolx;ncolx=temp;end;
if nrowy==1;y=y';temp=nrowy;nrowy=ncoly;ncoly=temp;end;
if (nrowx==nrowy)&(ncolx==ncoly);yl=y;xl=x;end;
if nrowx==nrowy;xl=x;yl=y;return;end;
if nrowx==ncoly;xl=x;yl=y';return;end
if ncolx==nrowy;xl=x';yl=y;return;end;
if ncolx==ncoly;xl=x';yl=y';return;end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function  v = myaxis (x, y);
%
%function v = myaxis (x, y)
%sets the axis function for plotting spectra,
%so that the x values cover the whole x-axis, and so that the
%minimum value on the y-axis is zero, or min (y) . The maximum of
%the y-axis is 1.1 * max (y). If the outputargument is used, the function
%only returns the values, and does not set the axes.


%if nargout==1;if (any(any(imag(y))));return;end;end;

if nargin==2;
  if (any(any(imag(y))));v=[0 1 0 1];return;end;
end;


if nargin==0;
  %     a=axis;x=a(1:2);y=a(3:4);
  h=get(gca,'Children');
  minx=inf;
  maxx=-inf;
  miny=inf;
  maxy=-inf;
  for i=1:length(h);
    if strcmp(get(h(i),'type'),'line');
      x=get(h(i),'Xdata');
      if min(x)<minx;minx=min(x);end;
      if max(x)>maxx;maxx=max(x);end;
      y=get(h(i),'Ydata');
      if min(y)<miny;miny=min(y);end;
      if max(y)>maxy;maxy=max(y);end;
    end;
  end;
  x=[minx maxx];y=[miny maxy];
end;
[m, n] = size (y);
v(1)=min(x);v(2)=max(x);
temp = min (min (y));
maxmaxy = max (max (y));
v(4)=maxmaxy+.1*abs(maxmaxy);
v (3) = min (0, temp);
v=corrspecutilities('nan20',v);
if v(3) < 0; v (3) = v (3) - (.1 *abs(maxmaxy)); end
if v(1)==v(2);v(1)=v(1)-1;v(2)=v(2)+1;end;
if v(3)==v(4);v(3)=v(3)-1;v(4)=v(4)+1;end;

if nargout==0;axis(v);end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [xo,yo] = lbar(x,y)
%function [xo,yo] = lbar(x,y)
%is an adaptation of the function bar,
%with the difference that the bars are lines.
%lbar(y) draws a bar graph of the elements of vector y.
%lbar(x,y) draws a bar graph of the elements in vector y at
%the locations specified in x.
%[xx,yy] = bar(x,y) does not draw a graph, but returns vectors
%x and y such that plot(xx,yy) is the bar chart.

n = length(x);
if nargin == 1
  y = x;
  x = 1:n;
end
x = x(:);
y = y(:);
nn = 3*n;
yy = zeros(nn+1,1);
xx = yy;
yy(2:3:nn) = y;
%yy(3:3:nn) = y;
delta = (max(x) - min(x)) / (n-1);
t = x(:)' - 0.5*delta;
xx(1:3:nn) = x;
xx(2:3:nn) = x;
xx(3:3:nn) = x;
xx(nn+1) = xx(nn);
if nargout == 0
  plot(xx,yy,'k')
  axy = axis;axis;
  if axy(1)==x(1);axy(1)=axy(1)-1;end;
  if axy(2)==x(length(x));axy(2)=axy(2)+1;end;
  hold on; plot([axy(1) axy(2)],[0 0],'k'); hold off;
else
  xo = xx;
  yo = yy;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function direction=vardir(varlist);
%function direction=vardir(varlist);
%results in the value 'normal ' when varlist is ascending and in 'reverse'
%when varlist is descending;

if varlist(1)<=varlist(2);direction='normal ';else;direction='reverse';end;

