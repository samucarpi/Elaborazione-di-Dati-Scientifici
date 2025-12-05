function hideaxistext(ax,varargin)
%HIDEAXISTEXT Hides text objects which are outside the current axis limits.
% When plots are zoomed, lines and symbols are "trimmed" by the limits on
% the axis. Text object, however, are not. This function hides text objects
% which are outside the current axis limits and shows objects which are
% inside the limits.
%
%I/O: hideaxistext(ax)

% Copyright © Eigenvector Research, Inc. 2013
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<1
  fig = get(0,'currentfigure');
  if isempty(fig)
    return;
  end
  ax = get(fig,'currentaxes');
  if isempty(ax)
    return;
  end
end

txh = findall(ax,'type','text');
if isempty(txh); return; end
pos = get(txh,'position');
if ~iscell(pos)
  pos = {pos};
end
ext = zeros(length(pos),4);
% ext = get(txh,'extent');
pos = cat(1,pos{:});
% ext = cat(1,ext{:});
right  = pos(:,1)+ext(:,3);
left   = pos(:,1);
top    = pos(:,2)+ext(:,4);
bottom = pos(:,2);

dvis = cellfun(@(s) strcmp(s,'on'),getdefaultvisibility(txh))';

xlim = get(ax,'xlim');
ylim = get(ax,'ylim');
zlim = get(ax,'zlim');

hide = (left<xlim(1) | right>xlim(2) | bottom<ylim(1) | top>ylim(2));
set(txh(hide),'visible','off');
set(txh(~hide & dvis),'visible','on');

if checkmlversion('>','7.2')
  set(zoom,'ActionPostCallback',@zoomupdate);
  set(pan,'ActionPostCallback',@zoomupdate);
end

%--------------------------------------------------
function zoomupdate(fig,varargin)

hideaxistext(get(fig,'currentaxes'));

%--------------------------------------------------
function out = getdefaultvisibility(h)

out = cell(1,length(h));
for j=1:length(h);
  out{j} = getappdata(h(j),'defaultvisibility');
  if isempty(out{j})
    out{j} = get(h(j),'visible');
    setappdata(h(j),'defaultvisibility',out{j});
  end
end
