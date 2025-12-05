function varargout = pcolormap(data,xlbl,ylbl,maxdat,mindat);
%PCOLORMAP Pseudocolor plot with labels and colorbar.
%  PCOLORMAP produces a pseudocolor map of the m by n input matrix
%  (data) with labels. (data) can be class "double" or "dataset".
%
%  Optional inputs are:
%  (xlbl) a character array with m rows of sample labels
%    if empty no labels are included, if ==1 then xlbl = int2str([1:m]');
%    [xlbl = int2str([1:m]') used when size(xlbl,1)~=m],
%  (ylbl) a character array with n rows of variable labels
%    if empty no labels are included, if ==1 then ylbl = int2str([1:n]');
%    [ylbl = int2str([1:n]') used when size(ylbl,1)~=n],
%  (maxdat) a user defined maximum for scaling the color scale
%    {default = max(max(data))}, and
%  (mindat) a user defined minimum for scaling the color scale
%    {default = min(min(data))}.
%
%I/O: pcolormap(data,maxdat,mindat);           %pcolor w/ labels for data of class "dataset"
%I/O: pcolormap(data,xlbl,ylbl,maxdat,mindat); %pcolor w/ labels for data of class "double"
%I/O: pcolormap demo
%
%See also: CORRMAP, PCOLOR, RWB

%Copyright Eigenvector Research, Inc. 2000
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%nbg added dso 8/02
%nbg changed lbling and added 4/8/04

if nargin == 0; data = 'io'; end
varargin{1} = data;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<1
  error('PCOLORMAP requires at least 1 input.')
end

warning off backtrace

switch class(data)
case 'dataset'
  if nargin>3
    error('Number of arguments is <= 3 when data is class "dataset".')
  end
  if nargin<2
    maxdat = max(max(data.data(data.includ{1,1},data.includ{2,1})));
  elseif isempty(xlbl)
    maxdat = max(max(data.data(data.includ{1,1},data.includ{2,1})));
  else
    maxdat = xlbl;
  	if maxdat<max(max(data.data(data.includ{1,1},data.includ{2,1})))
      warning('EVRI:Pcolormap','maximum in data exceeds maxdat')
    end
  end
  if nargin<3
    mindat = min(min(data.data(data.includ{1,1},data.includ{2,1})));
  elseif isempty(ylbl)
    mindat = min(min(data.data(data.includ{1,1},data.includ{2,1})));
	else
    mindat = ylbl;
    if mindat>min(min(data.data(data.includ{1,1},data.includ{2,1})))
      warning('EVRI:Pcolormap','minimum in data less than mindat')
    end
  end
  if isempty(data.label{1,1})
    xlbl = int2str(data.includ{1,1}');
  else
    xlbl = data.label{1,1}(data.includ{1,1},:);
  end  
  if isempty(data.label{2,1})
    ylbl = int2str(data.includ{2,1}');
  else
    ylbl = data.label{2,1}(data.includ{2,1},:);
  end
  data = data.data(data.includ{1,1},data.includ{2,1});
  [m,n]  = size(data);
case 'double'
  [m,n]  = size(data);
	if nargin<2
    xlbl = ' ';
    xlbl = xlbl(ones(m,1),1);
  elseif xlbl==1
    xlbl = int2str([1:m]');
	elseif isempty(xlbl)
    xlbl = ' ';
    xlbl = xlbl(ones(m,1),1);
	elseif size(xlbl,1)~=m
    warning('EVRI:Pcolormap','Length of (xlbl) does not = number of rows.')
    xlbl = int2str([1:m]');
	else
    xlbl = deblank(xlbl);
	end
	if nargin<3
    ylbl = ' ';
    ylbl = ylbl(ones(n,1),1);
  elseif ylbl==1
    ylbl = int2str([1:n]');
	elseif isempty(ylbl)
    ylbl = ' ';
    ylbl = ylbl(ones(n,1),1);
	elseif size(ylbl,1)~=n
    warning('EVRI:Pcolormap','Length of (ylbl) does not = number of columns.')
    ylbl = int2str([1:n]');
	else
    ylbl = deblank(ylbl);
	end
	if nargin<4
    maxdat = max(max(data)');
	elseif isempty(maxdat)
    maxdat = max(max(data)');
	elseif maxdat<max(max(data)')
    warning('EVRI:Pcolormap','maximum in data exceeds maxdat')
	end
	if nargin<5
    mindat = min(min(data)');
	elseif isempty(mindat)
    mindat = min(min(data)');
	elseif mindat>min(min(data)')
    warning('EVRI:Pcolormap','minimum in data less than mindat')
	end
otherwise
  error('Input (data) must be class "double" or "dataset".')
end

warning backtrace

figure
data   = [data ones(m,1)*maxdat; ones(1,n+1)*mindat];

h      = pcolor(0.5:1:n+0.5,0.5:1:m+0.5,data); colormap('rwb')
if n>20|m>20
  set(findobj(h,'edgecolor',[0 0 0]),'edgecolor','none')
end
set(gca,'XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[])

if n>50
  fsy = 7;
  osy = size(ylbl,2)*m/50;
elseif n>20
  fsy = 9;
  osy = size(ylbl,2)*m/40;
else
  fsy = 12;
  osy = size(ylbl,2)*m/30;
end
if m>50
  fsx = 7;
  osx = size(xlbl,2)*n/50;
elseif m>20
  fsx = 9;
  osx = size(xlbl,2)*n/40;
else
  fsx = 12;
  osx = size(xlbl,2)*n/30;
end

text(-osx*0.95*ones(m,1),1:m,xlbl,'FontSize',fsx)
text(1:n,-osy*0.95*ones(n,1),ylbl,'Rotation',90,'FontSize',fsy)

axis([-osx n+0.5 -osy m+0.5])
colorbar
