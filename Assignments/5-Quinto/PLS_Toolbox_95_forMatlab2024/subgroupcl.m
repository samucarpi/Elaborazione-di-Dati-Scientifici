function h = subgroupcl(scrs,cl,options)
%SUBGROUPCL Displays a confidence ellipse for points in two- or three-dimensional plots.
% Draws a confidence ellipse around a group of points on a two-dimensional
% plot or a sphere in a three-dimensional plot. A 2- or 3-component PCA
% model is calculated to get the orientation and size of the ellipse and
% this is plotted on the current figure.
%
% First input is either (fig) the figure number on which ellipses should be
% drawn for all line objects on the currently selected axes, or (scrs) the
% two-column matrix of values of the points. An optional input is
% the confidence limit (cl) which defaults to 95 (= 95%).
%
% Output (h) is the handle of all the elipses/spheres drawn.
%
%I/O: h = subgroupcl(fig,cl)
%I/O: h = subgroupcl(scrs,cl)
%
%See also: PCAENGINE, TSQLIM

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS

if nargin==0; scrs = 'io';end
if ischar(scrs);
  options = [];
  options.spheresize = 15;
  if nargout==0; evriio(mfilename,scrs,options); else; h = evriio(mfilename,scrs,options); end
  return; 
end

if nargin<3
  options = [];
end
options = reconopts(options,mfilename);

%handle confidence limit input
if nargin<2;
  cl = 95;
end
cl(cl>1) = cl(cl>1)/100;  %convert xx.0 into 0.xx

if any(cl>1);  %still >1? must have been >100
  error('Confidence limit must be between 0 and 100');
end

%if first input was a handle to a PlotGUI target figure, draw ellipses
%around all objects using recursive calls
if prod(size(scrs))==1 & ishandle(scrs) & strcmp(get(scrs,'type'),'figure')
  h = doallobjects(scrs,cl);
  if nargout == 0
    clear h
  end
  return
end

%is actual data? do ellipse alone
if isdataset(scrs)
  incl = scrs.include;
  scrs = scrs.data(incl{:});
end

[m,n] = size(scrs);

%get PCA model
[scrs,mn] = mncn(scrs);
[ssq,datarank,loads] = pcaengine(scrs,min(n,3),struct('display','off'));

%If we have enough rank, calculate and draw ellipse
if datarank>1
  if n==2
    %2D
    ang   = atan(loads(2)/loads(1));
    cnt   = mn;
    
    for ncl = 1:length(cl);
      a      = sqrt( tsqlim(m,2,cl(ncl)) .* ssq(1:2,2)');
      hel = ellps(cnt,a,'g',ang);
      h(ncl) = hel;
      clr = 0.7*[1 1 1];
      xdat = get(hel,'xdata');
      ydat = get(hel,'ydata');
      npts = length(xdat);
      h(ncl) = patch(xdat,ydat,clr,'FaceColor',clr,'EdgeColor',clr,'facealpha',.2,'edgealpha',.8);
      delete(hel);
      legendname(h(ncl),[num2str(cl(ncl)*100) '% confidence ellipse']);
    end
  else
    %3D
    cnt   = mn;
    
    for ncl = 1:length(cl);
      a       = sqrt( tsqlim(m,2,cl(ncl)) .* ssq(1:3,2)');
      
      [x,y,z] = sphere(options.spheresize);
      x = x*a(1);
      y = y*a(2);
      z = z*a(3);
      
      p = [x(:) y(:) z(:)]*loads';
      x = reshape(p(:,1),size(x)) + cnt(1);
      y = reshape(p(:,2),size(x)) + cnt(2);
      z = reshape(p(:,3),size(x)) + cnt(3);
      
      clr = 0.7*[1 1 1];
      h(ncl) = surface(x,y,z,'FaceColor',clr,'EdgeColor',clr,'facealpha',.2,'edgealpha',.2);
      legendname(h(ncl),[num2str(cl(ncl)*100) '% confidence ellipse']);
    end
  end
else
  %rank deficient - can't do ellipse
  h = [];
end

if nargout==0;
  clear h
end

%------------------------------------------------
% draw ellipses for all objects on the current axes of a given figure
function allh = doallobjects(fig,cl)

figure(fig);
ax = get(fig,'currentaxes');
h  = findobj(ax,'type','line');
allh = [];
for j=1:length(h);
  if ~isempty(getappdata(h(j),'subgroupcl')) | strcmp(get(h(j),'visible'),'off')...
      | (strcmp(get(h(j),'Marker'),'none') & strcmp(get(h(j),'LineStyle'),'none'))
    continue;  %skip object - it was a previous ellipse
  end

  data = [get(h(j),'xdata')' get(h(j),'ydata')'];
  zdata = get(h(j),'zdata')';
  if ~isempty(zdata)
    data = [data zdata];
  end
  data(any(~isfinite(data),2),:) = []; %drop non-finite values
  if isempty(data)
    continue;
  end

  eh = subgroupcl(data,cl);  %%%NOTE: recursive call to subgroupcl
  setcolor(eh,get(h(j),'color'),get(h(j),'color'));
  for ehind = 1:length(eh);
    setappdata(eh(ehind),'subgroupcl',1);
  end

  allh = [allh;eh];

end


%------------------------------------------------------
function setcolor(handles,color,facecolor)
%SETCOLOR sets color on objects with sensitivity to what the object is

if nargin < 3;
  facecolor = [];
end

%settings for excluded points
for h = handles(:)';
  for p = {'color' 'edgecolor'}
    if isprop(h,p{:})
      set(h,p{:},color);
      break;
    end
  end
  if ~isempty(facecolor) 
    for p = {'markerfacecolor' 'facecolor'}
      if isprop(h,p{:}) & strcmp(class(get(h,p{:})),class(facecolor))
        set(h,p{:},facecolor)
        break;
      end
    end
  end
end
