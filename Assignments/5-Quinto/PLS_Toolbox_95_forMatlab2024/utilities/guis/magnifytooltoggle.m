function magnifytooltoggle(fig,icononly)
%MAGNIFYTOOLTOGGLE Toggle magnify tool on and off.
%
% NOTE: Old behavior was to redraw magnify box on click (w/ no toggle)
% but toggle on/off seems like more logical work-flow.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

bh = findobj(allchild(fig),'tag','pgtmagnify');
if isempty(bh)
  return
end

if nargin<2
  icononly=0;
end

if strcmpi(get(bh,'state'),'on')
  %Turn on magnify.
  set(bh,'cdata',gettbicons('zoomtool_pressed'));
  if ~icononly
    magnifytool(fig);
  end
else
  %Turn off magnify.
  set(bh,'cdata',gettbicons('zoomtool'));
  if ~icononly
    magnifytool('delete',fig);
  end 
end

%magnifytool('update',fig);
