function regresdiagplot3d(sdist,odist,rdist,cutoffsd,cutoffod,cutoffrd,k,class,multi,labsd,labod,labresd,labels)

%REGRESDIAGPLOT3D is a 3D-outlier map which visualizes the orthogonal distance, 
% the score distance and the residual distance calculated in a PCR or PLSR analysis.
%
% I/O: regresdiagplot3D(sdist,odist,rdist,cutoffsd,cutoffrd,k,class,labsd,labod,labresd,labels)
%
% Example: out=rpcr(X,Y);
%          regresdiagplot3d(out.sd,out.od,out.resd,out.cutoff.sd,cutoff.od,...
%          out.cutoff.resd,out.k,out.class,1,out.labsd,out.labod,out.labresd,0)
%
% Uses function: putlabel
%
% Created on 09/04/2004 by S.Verboven
% Last revision: 30/01/2005
% 

%INITIALIZATION%
if nargin<13
    labels=0;
end
if nargin<10
    labsd=3;
    labod=3;
    labresd=3;
    labels=0;
end
if nargin==10 
    labsd=3
    labels=0;
    labresd=3;
    labod=3;
end
if nargin==11
    labels=0;
    labresd=3;
    labod=3;
end
if nargin==12
    labels=0;
    labresd=3;
end
if nargin<9
    error('A required input variable is missing!')
end
    
%all LTS-analysis in RPCR are intercept included!!!
% if ask==2 %multivariate analysis
%     %residual distances
%    
% else  %univariate analysis
%     %standardized residuals
%     cutoffz=2.5; 
% end
% cutoffxx=cutoffsd;
% cutoffxy=cutoffsd; 
% cutoffyy=cutoffod;
% cutoffyx=cutoffod;
% cutoffz=cutoffrd;
% x=sdist;
% y=odist;
% z=rdist; 


%%%%%%%MAIN FUNCTION%%%%%%%
set(gcf,'Name', '3D-Outlier map (regression)', 'NumberTitle', 'off');

%%%%%%%%Odist=0 not yet included in this standalone!!!!!!!!! included in
%%%%%%%%makeplot function!!!!

%orthogonal outlier
indorth=sdist<cutoffsd & odist>cutoffod;
%bad PCA leverage:
indbad=sdist>cutoffsd & odist>cutoffod;
%good PCA leverage:
indgood= sdist>cutoffsd & odist<cutoffod;

%bad regression leverage:
indbadreg=sdist>cutoffsd & rdist>cutoffrd;
%good  regression leverage:
indgoodreg= sdist>cutoffsd & rdist<cutoffrd;
%vertical regression outlier
if multi==0 %univariate case
    indvert=abs(rdist)>2.5;
else
    indvert=rdist>cutoffrd;
end

indunique=zeros(length(odist),1);
indtwice=zeros(length(odist),1);
indregular=zeros(length(odist),1);
indout=(indorth + indbad +indgood+ indvert + indgoodreg+indbadreg); %indices of all outliers
indunique(indout==1)=1;  %all indices of uniquely classified outliers
indtwice(indout>=2)=1; %all indices of outliers classified in PCA and PCR step
indregular(indout ==0)=1; %indices of outliers set to zero

%plotting them with different colours and markers
plot3(sdist(indregular~=0),odist(indregular~=0),rdist(indregular~=0),'ko','markerfacecolor',[0.75 0.75 0.75])
hold on

%unique outliers
if ~isempty(indorth)
    ind=indorth & indunique; 
    %ind=setdiff(indorth, indtwice);
    if ~isempty(ind)
        plot3(sdist(ind),odist(ind),rdist(ind),'yo','markerfacecolor','y')
    end
end

if ~isempty(indbad)
    ind= indbad &indunique;
   % ind=setdiff(indbad,indtwice);
    if ~isempty(ind)
            plot3(sdist(ind),odist(ind),rdist(ind),'ro','markerfacecolor','r')
    end
end
if ~isempty(indgood)
    ind= indgood & indunique;
    %ind=setdiff(indgood,indtwice);
    if ~isempty(ind)
        plot3(sdist(ind),odist(ind),rdist(ind),'bo','markerfacecolor','b')
    end
end
if ~isempty(indvert)
    ind= indvert & indunique;
    %ind=setdiff(indvert,indtwice);
    if ~isempty(ind)
        plot3(sdist(ind),odist(ind),rdist(ind),'y^','markerfacecolor','y')
    end
end
if ~isempty(indbadreg)
    ind=indbadreg & indunique;
    %ind=setdiff(indbadreg,indtwice);
    if ~isempty(ind)
        plot3(sdist(ind),odist(ind),rdist(ind),'r^','markerfacecolor','r')
    end
end
if ~isempty(indgoodreg)
    ind= indgoodreg & indunique;
    %ind=setdiff(indgoodreg,indtwice);
    if ~isempty(ind)
        plot3(sdist(ind),odist(ind),rdist(ind),'b^','markerfacecolor','b')
    end
end

%combined outliers
if ~isempty(indorth)&~isempty(indvert)
    ind=indvert & indorth & indtwice;
    if ~isempty(ind)
        plot3(sdist(ind),odist(ind),rdist(ind),'yd','markerfacecolor','y')
    end
end
% if ~isempty(indbad) & ~isempty(indvert)
%      ind=setdiff([indvert; indbad],indunique);
%      if ~isempty(ind)
%          plot3(sdist(ind),odist(ind),rdist(ind),'d','markerfacecolor',[0.5 0.5 0],'markeredgecolor',[0.5 0.5 0])
%      end
% end

% if ~isempty(indgood) & ~isempty(indvert)
%     %ind=indtwice(indtwice<=max(indbadreg) & indtwice<=max(indorth) );
%     ind=setdiff([indgood; indvert],indunique);
%     if ~isempty(ind)
%         plot3(sdist(ind),odist(ind),rdist(ind),'d','markerfacecolor',[0 1 1], 'markeredgecolor',[0 1 1])
%     end
% end

% if ~isempty(indbadreg) & ~isempty(indorth)
%     ind=setdiff([indbadreg; indorth],indunique);
%     if ~isempty(ind)
%         plot3(sdist(ind),odist(ind),rdist(ind),'d','markerfacecolor',[0.5 0.5 0], 'markeredgecolor',[0.5 0.5 0])
%     end
% end

% if ~isempty(indgood) & ~isempty(indvert)
%     ind=setdiff([indgood; indvert],indunique);
%     if ~isempty(ind)
%         plot3(sdist(ind),odist(ind),rdist(ind),'gd','markerfacecolor','g')
%     end
% end


if ~isempty(indgood)&~isempty(indgoodreg)
    ind=indgood & indgoodreg & indtwice;
    if ~isempty(ind)
        plot3(sdist(ind),odist(ind),rdist(ind),'bd','markerfacecolor','b')
    end
end

if ~isempty(indbadreg) & ~isempty(indgood)
    ind=indbadreg & indgood & indtwice;
    if ~isempty(ind)
        plot3(sdist(ind),odist(ind),rdist(ind),'md','markerfacecolor','m')
    end
end

if ~isempty(indbad) & ~isempty(indbadreg)
    ind=indbad & indbadreg & indtwice;
    if ~isempty(ind)
        plot3(sdist(ind),odist(ind),rdist(ind),'rd','markerfacecolor','r')
    end
end

if ~isempty(indbad) & ~isempty(indgoodreg)
    ind=indbad & indgoodreg & indtwice;
    if ~isempty(ind)
        plot3(sdist(ind),odist(ind),rdist(ind),'gd','markerfacecolor','g')
    end
end



% axhandle=gca;
% ylen=get(axhandle, 'Ylim');
% xlen=get(axhandle,'Xlim');
% zlen=get(axhandle,'Zlim');
% xrange=xlen(2)-xlen(1);
% upLimx=max(cutoffxx,xlen(2))+xrange*0.1;
% lowLimx=xlen(1)-xrange*0.1;
% yrange=ylen(2)-ylen(1);
% upLimy=ylen(2)+yrange*0.1;
% lowLimy=ylen(1)-yrange*0.1;
% zrange=zlen(2)-zlen(1);
% upLimz=max(cutoffz,zlen(2))+zrange*0.1;
% if cutoffz==2.5
%     lowLimz=min(-2.5,zlen(1))-zrange*0.1;
% else
%     lowLimz=min(cutoffz,zlen(1))-zrange*0.1;
% end
%     
% %axis square;
% set(gca, 'Xlim',[lowLimx upLimx],'Ylim',[lowLimy upLimy],'Zlim',[lowLimz,upLimz])
% hold on

xlabel('Score distance')
ylabel('Orthogonal distance')
if cutoffrd~=2.5
    zlabel('Residual distance')
else
    zlabel('Standardized Residual')
end
grid on


% 
% 
% %in XY-space
% %red plane "vertical" on x axis
% oppy=[upLimy:-0.01:lowLimy];
% n=length(oppy);
% h=(upLimz-lowLimz)/n;
% oppz=[lowLimz:h:upLimz];
% 
% X1=cutoffxx*ones(n);
% Y1=repmat(oppy,n,1);
% Z1=repmat([oppz(1:n-1)'; upLimz],1,n);
% surf(X1,Y1,Z1,'edgecolor','none','facecolor','r')
% alpha(0.3)
% 
% 
% %blue "horizontal" planes orthogonal on z-axis
% %in ZX and ZY-space
% oppx=[lowLimx:0.05:upLimx];
% n=length(oppx);
% X2=repmat(oppx,n,1);
% h=(upLimy-lowLimy)/n;
% oppy=[lowLimy:h:upLimy];
% Y2=repmat(oppy(1:n)',1,n);
% Z2=cutoffz*ones(n);
% surf(X2,Y2,Z2,'edgecolor','none','facecolor','b')
% alpha(0.3)
% 
% % in XY-space
% %green plane "vertical" on y axis
% oppx=[upLimx:-0.01:lowLimx];
% n=length(oppx);
% h=(upLimz-lowLimz)/n;
% oppz=[lowLimz:h:upLimz];
% X1=repmat(oppx,n,1);
% Y1=cutoffyy*ones(n);
% Z1=repmat([oppz(1:n-1)'; upLimz],1,n);
% surf(X1,Y1,Z1,'edgecolor','none','facecolor','g')
% alpha(0.3)
% 
% if multi==0 %univariate case
%     surf(X2,Y2,-Z2,'edgecolor','none','facecolor','b')
%     alpha(0.3)
% end

if labels~=0
    putlabel(sdist,odist,labels,rdist,labels)
else
    plotnumbers(sdist,odist,labsd,labod,5,rdist,labresd)
end
hold off