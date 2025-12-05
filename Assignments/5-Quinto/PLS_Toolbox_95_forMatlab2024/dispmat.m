function [c,meansx,meansy,stdsx,stdsy]=dispmat(x,y,options)
%DISPMAP Calculates the dispersion matrix of two spectral data sets.
%  Inputs x and y represent (nspectra*nvariables).
%
% INPUTS
%       x : (2-way array class "double" or "dataset") x-matrix for
%               dispersion matrix.
%       y : (2-way array class "double" or "dataset") y-matrix for
%               dispersion matrix.
%
% OPTIONAL INPUT options structure with one or more of the following fields
%       offsetx         : [0] offset for x.
%       offsety         : [0] offset for y.
%       dispersion      : [1] offset dispersion
%                         1: synchronous correlation
%                         2: asynchronous correlation
%                         3: synchronous covariance
%                         4: asynchronous covariance
%                         5: purity about origin
%                         6: purity about mean
% OUTPUT:
%     c      = dispersion matrix, as defined by options
%     meansx = mean of x
%     meansy = mean of y
%     stdsx  = standard deviation of x
%     stdsy  = standard deviation of y
%
%I/O: [c,meansx,meansy,stdsx,stdsy]=dispmat(x,y,options)
%
%See also: CORRSPEC

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%ww  09/28/06

if nargin == 0; x = 'io'; end

if ischar(x);

  options = [];
  options.offsetx    = 0;
  options.offsety    = 0;
  options.dispersion = 1;
  if nargout==0
    evriio(mfilename,x,options);
  else
    c = evriio(mfilename,x,options);
  end
  return;
end;  

if nargin < 3
  options = dispmat('options');
else
  options = reconopts(options,dispmat('options'));
end

%  flag=0;
%  if options.dispersion==5;
%      options.dispersion=1;
%      flag=1;
%  end;
% 
% 
% [xscaled,meansx,stdsx]=transform(x,options.dispersion,options.offsetx);
% [yscaled,meansy,stdsy]=transform(y,options.dispersion,options.offsety);
% 
% c=(yscaled'*xscaled)/size(y,1);c=corrspecutilities('nan20',c);
% 
% c=(1+options.offsetx/100)*(1+options.offsety/100)*c;%correct, so that max is one
% 
% 
% if flag;c=sqrt(1-c.^2);end;

%INITIALIZATIONS

[nrowsx,ncolsx]=size(x);
[nrowsy,ncolsy]=size(y);


if (options.dispersion==2|options.dispersion==4);%asynchronous correlation
  [xscaled,meansx,stdsx]=transform(x,1,0);
  [yscaled,meansy,stdsy]=transform(y,1,0);
  
  if options.dispersion==4;
    xscaled=xscaled.*repmat(stdsx,nrowsx,1);
    yscaled=yscaled.*repmat(stdsy,nrowsy,1);
  end;
  
  c=(yscaled'*xscaled)/size(y,1);c=corrspecutilities('nan20',c);
  c=real(sqrt(1-c.^2));
  
  mx=max(meansx);
  my=max(meansy);
  ofsx=meansx./(meansx+(options.offsetx/100)*mx);
  ofsy=meansy./(meansy+(options.offsety/100)*mx);
%  (1+options.offsetx/100
  ofsx=ofsx*(1+options.offsetx/100);%max of weight is one
  ofsy=ofsy*(1+options.offsety/100);%max of weight is one
  
  c=c.*(ofsy'*ofsx);
  
  
  s=yscaled(1:end-1,1:end-1)'*xscaled(2:end,2:end)-yscaled(2:end,1:end-1)'*xscaled(1:end-1,2:end);
 %s=xscaled(1:end-1,1:end-1).;*xscaled(2:end,2:end)-xscaled(2:end,1:end-1).*xscaled(1:end-1,2:end);
  
  a=zeros(size(c));
  a(2:end,2:end)=s;
  c=c.*sign(a);
  %keyboard
%   mx=max(meansx);
%   my=max(meansy);
%   ofsx=meansx./(meansx+(options.offsetx/100)*mx);
%   ofsy=meansy./(meansy+(options.offsety/100)*mx);
%   c=c.*(ofsy'*ofsx);
  
else;
  if (options.dispersion==1|options.dispersion==3);option4transform=1;end;
  if options.dispersion==5;option4transform=4;end;
  if options.dispersion==6;option4transform=3;end;
  
  
  [xscaled,meansx,stdsx]=transform(x,option4transform,options.offsetx);
  [yscaled,meansy,stdsy]=transform(y,option4transform,options.offsety);
  
  if options.dispersion==3;
    xscaled=xscaled.*repmat(stdsx,nrowsx,1);
    yscaled=yscaled.*repmat(stdsy,nrowsy,1);
  end;
  
  c=(yscaled'*xscaled)/size(y,1);c=corrspecutilities('nan20',c);
  c=(1+options.offsetx/100)*(1+options.offsety/100)*c;%correct, so that max is one
end;


%c=(yscaled'*xscaled)/size(y,1);c=corrspecutilities('nan20',c);

%c=(1+options.offsetx/100)*(1+options.offsety/100)*c;%correct, so that max is one


%if flag;c=sqrt(1-c.^2);end;



%--------------------------------------------------------
function [xscaled,meansx,stdsx]=transform(x,option,offsetx)
%TRANSFORM Transforms the variables (columns) of a matrix.
%
%x represents the x data (nspectra*nvariables)
%option=1: standardized, offset corrected
%option=2: length sqrt(nrows), offset corrected
%option=3: purity about mean, offset corrected
%option=4: purity about origin, offset corrected
%offsetx is the offset for x,
%meansx is the mean of the data set x.
%stdsx is the standard deviation (function stdn!) of the data set x.
%The last two arguents are optional, their defaults are 1 and 0.
%The offset corrected correlation about the mean matrix can be calculated,
%after applying this function, by xscaled'*xscaled.
%The offset corrected correlation about the origin matrix can be calculated,
%after applying this function by, xscaled'*xscaled.
%The offset corrected purity about the mean matrix can be calculated,
%after applying this function by xscaled'*xscaled.
%The offset corrected purity about the origin matrix can be calculated,
%after applying this function by xscaled'*xscaled.
%
%
%calculate some statistics
%
% flagsparse=1;
% if issparse(x);flagsparse=1;x=full(x);end

% Copyright © Eigenvector Research, Inc. 2006-2007
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%ww  09/28/06

 if nargin==1;option=1;offsetx=0;end;
 if nargin==2;offsetx=0;end;

 [nrowx,ncolx]=size(x);
 meansx=mean(x);%stdsx=stdn(x);
 stdsx=std(x,1);

%%% if issparse(x);
%%%     [i,j]=find(x);
%%%     tic;     
%%%     f=full(meansx);
%%%     meansxmatrix=sparse(i,j,f(j),nrowx,ncolx,nrowx*ncolx);
%%%     disp(['means ' num2str(toc)]);tic;
%%%     f=full(stdsx);
%%%     stdsxmatrix=sparse(i,j,f(j),nrowx,ncolx,nzmax(stdsx)*nrowx);
%%%     disp(['std ' num2str(toc)]);
%%%   else  
     meansxmatrix=meansx(ones(nrowx,1),:);
     stdsxmatrix=stdsx(ones(nrowx,1),:);
%%% end;
 if offsetx~=0;
     meansxmatrix2=meansxmatrix+((offsetx/100)*max(max(meansxmatrix)));
 end;

%
%CORRELATION ABOUT MEAN
%
 if option==1;
     xscaled=(x-meansxmatrix)./zero21(stdsxmatrix);
     if offsetx~=0;
        a=meansxmatrix2==0;
%        disp('aaa')
         meansxmatrix(a)=zeros(1,sum(sum(a)));
         meansxmatrix2(a)=ones(1,sum(sum(a)));
         xscaled=(xscaled.*meansxmatrix)./meansxmatrix2; 
     end;
 end;
%
%CORRELATION ABOUT ORIGIN
%
 if option==2;
     if offsetx~=0;
         rssqx=sqrt((meansxmatrix2.*meansxmatrix2)+(stdsxmatrix.*stdsxmatrix));
       else
         rssqx=sqrt((meansxmatrix.*meansxmatrix)+(stdsxmatrix.*stdsxmatrix));
     end;
     xscaled=x./zero21(rssqx);
 end;
%
%PURITY ABOUT MEAN
%
 if option==3;
      if offsetx~=0;xscaled=(x-meansxmatrix)./zero21(meansxmatrix2);
        else
          xscaled=(x-meansxmatrix)./zero21(meansxmatrix);
      end;
 end;
%	
%PURITY ABOUT ORIGIN
%
 if option==4;
     if offsetx~=0;xscaled=x./zero21(meansxmatrix2);
       else
         xscaled=x./zero21(meansxmatrix);
     end;
 end;

%GET RED OF NaN

% xscaled=nan20(xscaled);

% if flagsparse;xscaled=sparse(xscaled);end;

%---------------------------------------------
function y=zero21(x)
%ZERO21 Substitutes 1's for 0's.
%
%I/O: y=zero21(x)
%
%See also: INF20, NAN20

%Copyright Eigenvector Research, Inc. 2006-2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%ww  09/28/06

if ~(any(any(x==0)));y=x;return;end

[nrow,ncol]=size(x); p=nrow*ncol;
xreshape=reshape(x,1,p); n=1:p;
% l=~isinf(xreshape);
l=(xreshape~=0);
a=n(l);b=xreshape(l);
y=ones(1,p);
y(a)=b;
y=reshape(y,nrow,ncol);

