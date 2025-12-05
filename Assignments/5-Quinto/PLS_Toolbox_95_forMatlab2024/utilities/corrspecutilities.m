function varargout = corrspecutilities(varargin)
%CORRSEPCUTILITIES Contains utility functions for corrspec functions.

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

try
  switch lower(varargin{1})
    case evriio([],'validtopics')
      options = [];
      if nargout==0
        evriio(mfilename,varargin{1},options)
      else
        varargout{1} = evriio(mfilename,varargin{1},options);
      end
      return;
    otherwise
      if nargin==1

      elseif nargout == 0;
        %normal calls with a function
        feval(varargin{:}); % FEVAL switchyard
      else
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
      end
  end
catch
  if ~isempty(gcbf);
    set(gcbf,'pointer','arrow');  %no "handles" exist here so try setting callback figure
  end
  erdlgpls(lasterr,[upper(mfilename) ' Error']);
end

% --------------------------------------------------------------------
function setxdir(x)
%SETXDIR sets correct Xdir
%argument x determined direction. For simple plot, no arguments needed.

if nargin;
  if x(1)<x(2);set(gca,'Xdir','Normal');else;set(gca,'Xdir','Reverse');end;
  return;
end;


h=get(gca,'Children');
for i=1:length(h);
  if strcmp(get(h(i),'Type'),'line');
    x=get(h(i),'Xdata');
    if length(x)>1;
      if x(1)<x(2);set(gca,'Xdir','Normal');else;set(gca,'Xdir','Reverse');end;
      break;
    end;

  end;
end;

% --------------------------------------------------------------------
function setydir(y)
%SETYDIR sets correct Ydir
%argument y determined direction. For simple plot, no arguments needed.

if nargin;
  if y(1)<y(2);set(gca,'Ydir','Normal');else;set(gca,'Ydir','Reverse');end;
  return;
end;


h=get(gca,'Children');
for i=1:length(h);
  if strcmp(get(h(i),'Type'),'line');
    y=get(h(i),'Ydata');
    if length(y)>1;
      if y(1)<y(2);set(gca,'Ydir','Normal');else;set(gca,'Ydir','Reverse');end;
      break;
    end;

  end;
end;

% --------------------------------------------------------------------
function y=nan20(x,k)
%NAN20 Returns 0's for NaN's when 1 input argument is given.
%Defining k gives the value n for NaN
%
%I/O: y=nan20(x,k)
%
%See also: INF20, ZERO21

%Copyright Eigenvector Research, Inc. 2006-2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%ww  09/28/06

if nargin==1;k=0;end;
if ~(any(any(isnan(x))));y=x;return;end
[nrow,ncol]=size(x); p=nrow*ncol;
xreshape=reshape(x,1,p); n=1:p;
l=~isnan(xreshape);
a=n(l);b=xreshape(l);
y=k*ones(1,p);
y(a)=b;
y=reshape(y,nrow,ncol);

% --------------------------------------------------------------------
function weight=getweight2(datax,datay,purvarindexx,purvarindexy,offsetx,offsety)
%GETWEIGHT2

% Copyright © Eigenvector Research, Inc. 2006-2007
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%ww  09/28/06


[nrowsx,ncolsx]=size(datax);
[nrowsy,ncolsy]=size(datay);

meandatax=mean(datax);
meandataxmat=meandatax(ones(1,nrowsx),:);
corrx=meandataxmat./(meandataxmat+((offsetx/100)*max(meandatax)));
meandatay=mean(datay);
meandataymat=meandatay(ones(1,nrowsy),:);
corry=meandataymat./(meandataymat+((offsety/100)*max(meandatay)));
dispxy1=datay'*datax;
%dispxy2=(sqrt(corry).*datay)'*(sqrt(corrx).*datax);
corrx=(1+offsetx/100)*corrx;%correct so that max is one
corry=(1+offsety/100)*corry;%correct so that max is one




dispxy2=(corry.*datay)'*(corrx.*datax);%offset corrected data
%dispxy2=dispxy1;

%dispxy2=dispxy1;%%%%%%%%%%%%%%%%%%%%%%

npurvar=length(purvarindexx);
if isempty(purvarindexx)
  weight=ones(ncolsy,ncolsx);
  return
end;

dispxy2_old=dispxy2;%%%%%%%%%%%%%%%%%
for i=1:npurvar;

  %dispxy2=dispxy1;;%$$$$$$$$$$$$$$$$$$$$$$$$$

  a=dispxy2(:,purvarindexx(i));
  b=dispxy2(purvarindexy(i),:);
  dispxy2=dispxy2-((a*b)/dispxy2(purvarindexy(i),purvarindexx(i)));
end;

%weight=dispxy2./dispxy1;
%dispxy2(dispxy2<0)=0;
%dispxy2_old(dispxy2_old<0)=0;

%dispxy2_old=dispxy1;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
weight=dispxy2./(dispxy2_old);
%weight=dispxy2./(dispxy1);%%%%%%%%
%weight=weight.*(corry'*corrx);


weight=weight.*(weight>0);
weight=corrspecutilities('nan20',weight);
weight=inf20(weight);

%--------------------------------------------
function y=inf20(x)
%INF20 Substitutes 0's for Inf's.
%
%I/O: y=inf20(x)
%
%See also: NAN20, ZERO21

%Copyright Eigenvector Research, Inc. 2006-2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%ww  09/28/06

if ~(any(any(isinf(x))));y=x;return;end

[nrow,ncol]=size(x); p=nrow*ncol;
xreshape=reshape(x,1,p); n=1:p;
l=~isinf(xreshape);
a=n(l);b=xreshape(l);
y=zeros(1,p);
y(a)=b;
y=reshape(y,nrow,ncol);

% --------------------------------------------------------------------
function resetview;
%returns to main plot
callback_string=['[a,b]=view;n=30;z1=linspace(a,0,n);',...
  'z2=linspace(b,90,n);t=1/n;',...
  'for i=1:n;',...
  'view(z1(i),z2(i));drawnow;',...
  'end;'];


h=uicontrol(gcf,'string','reset view','callback',callback_string);
set(h,'units','normalize','position',[.92 .9 .05 .0476]);

% --------------------------------------------------------------------
function title4(string1,string2);
%function title4(string);
%plots a title in plot4 and plotc4.
global PLOT4_STRING SUBTITLE_STRING

SUBTTITLE_STRING=[];

if size(string1,1)>1;
  PLOT4_STRING=string1;
else
  PLOT4_STRING=[string1,' '];
end;

if nargin==2;SUBTITLE_STRING=string2;end;

% --------------------------------------------------------------------
function [x_include1_common,y_include1_common]=get_include_common(xspec,yspec);

%get common include part of rows

include_common=intersect(xspec.include{1},yspec.include{1});

%get common part of axisscale{1}

axisscale_common=intersect(xspec.axisscale{1}(include_common),yspec.axisscale{1}(include_common));
[junk, x_include1_common]=intersect(xspec.axisscale{1},axisscale_common);
[junk, y_include1_common]=intersect(yspec.axisscale{1},axisscale_common);
