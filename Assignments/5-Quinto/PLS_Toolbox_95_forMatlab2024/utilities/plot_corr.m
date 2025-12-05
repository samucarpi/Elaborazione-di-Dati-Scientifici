function plot_corr(x,y,matrix,clrmap,flag_false_color,nlevel)
%PLOT_CORR Plotting utility for corrspec.
%INPUTS
%                  x: x-axis for map to be plotted
%                  y: y-axis for map to be plotted
%             matrix: dispersion matrix
%             clrmap: colormap used. HAS TO BE CALLED WITH ARGUMENT, E.G. HOT(64)
%   flag_false_color: flag to turn on false coloring
%             nlevel: number of levels of contour maps
%
%I/O: plot_corr(x,y,matrix,clrmap,flag_false_color,nlevel)
%
%See also: CORRSPEC, CORRSPECENGINE, DISPMAT

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%WW 10/01/2007

%INITIALIZATIONS

if nargin<6;nlevel=3;end;
if nargin<5;flag_false_color=0;end;
if nargin<4;clrmap=hot;end;

colormap(zeros(64,3));
colormap(clrmap);
%clrmap2=colormap;
%clrmap2=clrmap;
%colormap(clrmap2);

[nrows,ncols]=size(matrix);
incr=65/(nlevel+1);clrarray1=round(incr:incr:64);

%PREPARE COR MATRICES TO BE PLOTTED

set(gcf,'renderer','zbuffer');
if flag_false_color;
    surf(x,y,matrix);shading flat;
    colormap(clrmap);
    colorbar
    hold on;
    contour3(x,y,matrix,nlevel,'k');
else;
   colormap(clrmap(clrarray1,:));
   contour3(x,y,matrix,nlevel);%whole matrix
   colorbar
end;
corrspecutilities('setxdir');corrspecutilities('setydir')
hold off;
view(0,90);
axis([sort([x(1) x(end)]) sort([y(1) y(end)])]);
axis vis3d;
corrspecutilities('setxdir',x);corrspecutilities('setydir',y);
drawnow
%colorbar
%colormap(clrmap2);
colorbar
%colormap(clrmap2);
return
