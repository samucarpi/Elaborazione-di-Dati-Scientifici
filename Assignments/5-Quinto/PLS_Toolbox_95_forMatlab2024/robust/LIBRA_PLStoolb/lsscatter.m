function lsscatter(x,y,fitted,attrib)

%LSSCATTER makes a scatter plot with regression (LTS/LS) line
%  and tolerance band for bivariate data
%
% Required input arguments:
%      x : predictor variabele (without missing values)
%      y : response variabele
% fitted : fitted values corresponding with the regression
% attrib : string identifying the used method =  'LS', 'LTS'
%
% I/O: lsscatter(x,y,fitted,attrib)
%
% This function is part of LIBRA:  the Matlab Library for Robust Analysis,
% available at: 
%              http://wis.kuleuven.be/stat/robust.html
%
% Written by Nele Smets on : 26/11/2003
% Last Update: 06/07/2004


set(gcf,'Name', 'Scatter plot', 'NumberTitle', 'off');
[n,p]=size(x);
if p~=1 
    disp(['Scatter plot with regression line and tolerance band ',...
            'is only available for bivariate data'])
else
    x1 = x(1);
    xn = x(n);
    y1 = fitted(1);
    yn = fitted(n);
    dx = xn - x1;
    dy = yn - y1;
    slope = dy./dx;
    centerx = (x1 + xn)/2;
    centery = (y1 + yn)/2;
    maxx = max(x);
    minx = min(x);
    maxy = centery + slope.*(maxx - centerx);
    miny = centery - slope.*(centerx - minx);
    mx = [minx; maxx];
    my = [miny; maxy];  
    plot(x,y,'o'); 
    xrange=0.1*(abs(maxx-abs(minx)));
    yrange=0.2*(abs(maxy-abs(miny)+5));
    xlim([minx-xrange maxx+xrange])
    ylim([min([min(y) miny-2.5 miny+2.5])-yrange max([max(y) maxy-2.5 maxy+2.5])+yrange])
    hold on
    plot(mx,my,'-');
    plot(mx,my+2.5,'r:');
    plot(mx,my-2.5,'r:');
    hold off
    title(attrib)
end

 