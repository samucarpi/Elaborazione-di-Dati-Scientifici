function [data,h]  = plttern(data,linestyle,x1lab,x2lab,x3lab);
%PLTTERN Plots a 2D ternary diagram.
%  Given an input matrix (data) that is m by 3, PLTTERN plots the
%  corresponding ternary diagram. The three columns correspond
%  to three concentrations (>=0 and real). Concentrations are
%  normalized to 0 to 100 and are output in ternary coordinates
%  in the variable (tdata). The handle of the data points is also output as
%  (h).
%
%  Optional string input (linetype) defines the plot type to use (see
%  linetypes defined in PLOT command). Optional text inputs (x1lab),
%  (x2lab), and (x3lab) are used to put text labels on the axes. 
%  NOTE: All three label inputs must be supplied if any are supplied.
%
%Examples:
%    plttern(c,'gx')
%    plttern(c,'label1','label2','label3')
%    plttern(c,'gx','label1','label2','label3')
% 
%I/O: [tdata,h] = plttern(data,linestyle,x1lab,x2lab,x3lab);
%I/O: plttern demo
%
%See also: DP, ELLPS, HLINE, PLTTERNF, VLINE, ZLINE

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%nbg 11/00 changed label options
%nbg 8/02 check for nargout and suppress assignment
%jms 2/03 added hold on support and undocumented markerfacecolor and linestyle options
%jms 4/03 added documented linestyle option

if nargin == 0; data = 'io'; end
varargin{1} = data;
if ischar(varargin{1});
  options = [];
  options.markerfacecolor = 'r';
  options.linestyle = 'or';
  if nargout==0; clear data; evriio(mfilename,varargin{1},options); else; data = evriio(mfilename,varargin{1},options); end
  return; 
end

options = reconopts([],'plttern');
if nargin == 4;
  %data,x1lab,x2lab,x3lab
  x3lab = x2lab; 
  x2lab = x1lab;
  x1lab = linestyle;
  linestyle = options.linestyle;
else
  if nargin<5;
    x3lab = '';
  end
  if nargin<4;
    x2lab = '';
  end
  if nargin<3;
    x1lab = '';
  end
end
if nargin == 1;
  linestyle = options.linestyle;
end
options.linestyle = linestyle;

cop= 1;             %column option
cl = 1;				      %column width
ac = 'b';           %axis color
gc = 'c';           %grid color
gc2=  1;
bc = 'r';           %bar color
cc = 'or';
bw = 1;             %bar width
tl = 5;             %tick length

%figure

holdon = strcmp(get(gca,'NextPlot'),'add');
if ~holdon  %if hold was already on, don't do axes
  set(gcf,'color',[1 1 1])
  % plot grid
  for ii=20:20:80
    h = plot([ii (ii+(100-ii)*.5)],[0 (100-ii)*.866],gc);hold on
    gcol = get(h,'Color');
    set(h,'Color',gcol*gc2);
    h = plot([ii/2 (100-ii/2)],[ii ii]*.866,gc);
    gcol = get(h,'Color');
    set(h,'Color',gcol*gc2);
    h = plot([ii/2 ii],[ii*.866 0],gc);
    gcol = get(h,'Color');
    set(h,'Color',gcol*gc2);
  end
  % plot ternary axes
  plot([0 100],[0 0],ac)
  plot([0 50],[0 86.6],ac)
  plot([50 100],[86.6 0],ac)
  plot([0 100],[0 0],ac)
  % plot ticks
  for ii=20:20:80
    plot([ii ii+tl/2],[0 tl*.866],ac)                %x1 ticks
    plot([(100-ii/2-tl) (100-ii/2)],[ii ii]*.866,ac) %x2 ticks
    plot([ii/2 ii/2+tl/2],[ii (ii-tl)]*.866,ac)      %x3 ticks
  end
end
% plot data
[m,n] = size(data);
for ii=1:m
  data(ii,1:3) = data(ii,1:3)/sum(data(ii,1:3)')*100; %normalize
  data(ii,1)   = data(ii,1)+data(ii,2)*.5;
  data(ii,2)   = data(ii,2)*.866;
end
h = plot(data(:,1),data(:,2),options.linestyle,'markerfacecolor',options.markerfacecolor);

if ~holdon  %if hold was already on, don't do axes
  % tick labels
  for ii=0:20:100
    s = num2str(ii);
    text(ii-1,-5,s,'fontname','times','fontsize',14)                  %x1 label
    text((100-ii/2+5),ii*.866,s,'fontname','times','fontsize',14)     %x2 label
    text((50-ii/2-8),86.6-ii*.866,s,'fontname','times','fontsize',14) %x3 label
  end
  % axis labels
  if nargin>2
    text(50,-10,x1lab,'fontname','times','fontsize',14)
  end
  if nargin>2
    text(75+10,54*.866,x2lab,'fontname','times','fontsize',14)
  end
  if nargin>2
    text(25-18,90-50*.866,x3lab,'fontname','times','fontsize',14)
  end
  
  set(gca,'Visible','off')
  axis([0 100 0 90])
  hold off
  
end
data = data(:,1:2);

if nargout<1, clear data, end
