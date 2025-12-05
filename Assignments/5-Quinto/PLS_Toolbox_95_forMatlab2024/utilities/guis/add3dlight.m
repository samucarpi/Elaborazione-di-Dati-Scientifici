function add3dlight(axh,corner,side,top)
%ADD3DLIGHT Adds lighting to a 3D surface to improve appearance.
%
%I/O: add3dlight(axh,corner,side,top)

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1;
  axh = [];
end
if nargin<2
  corner = 1;
end
if nargin<3
  side = 1;
end
if nargin<4
  top = 1;
end

if isempty(axh)
  axh = get(gcf,'currentaxes');
end

ax = [get(axh,'xlim') get(axh,'ylim') get(axh,'zlim')];
sideclr    = [1 1 1]*(1-(.75/side));
cornerclr  = [1 1 1]*(1-(.75/corner));
topclr     = [1 1 1]*(1-(.12/top));
style = 'local';
c = [ax(1)-(ax(2)-ax(1))*.2  ax(2)+(ax(2)-ax(1))*.2  ax(3)-(ax(4)-ax(3))*.2  ax(4)+(ax(4)-ax(3))*.2  ax(5)-(ax(6)-ax(5))*.2  ax(6)+(ax(6)-ax(5))*.2  ];
h = [mean(ax(1:2)) mean(ax(3:4)) mean(ax(5:6))];

delete(findobj(axh,'type','light'));
if corner
  light('parent',axh,'position',[c(1) c(3) c(6)],'style',style,'color',cornerclr)
  light('parent',axh,'position',[c(2) c(3) c(6)],'style',style,'color',cornerclr)
  light('parent',axh,'position',[c(1) c(4) c(6)],'style',style,'color',cornerclr)
  light('parent',axh,'position',[c(2) c(4) c(6)],'style',style,'color',cornerclr)
end
if side
  light('parent',axh,'position',[h(1) c(3) h(3)],'style',style,'color',sideclr)
  light('parent',axh,'position',[h(1) c(4) h(3)],'style',style,'color',sideclr)
  light('parent',axh,'position',[c(1) h(2) h(3)],'style',style,'color',sideclr)
  light('parent',axh,'position',[c(2) h(2) h(3)],'style',style,'color',sideclr)
end
if top
  light('parent',axh,'position',[h(1) h(2) c(6)],'style',style,'color',topclr);
end  
lighting(axh,'phong')
shading(axh,'interp')
