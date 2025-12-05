function obj = setpatch(varargin)
%MAGNIFYTOOL/SETPATCH Open rbbox on target axis for user to indicate magnification (zoom) region.
% Just adds this info to obj then calls updatepatch to actually draw it.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = [];
for i = 1:nargin
  %Find object in inputs.
  if strcmp(class(varargin{i}),'magnifytool')
    obj = varargin{i};
  end
end

if isempty(obj) || isempty(obj.parent_figure) || ~ishandle(obj.parent_figure)
  %Nothing to work with.
  return
end

%The most up to date object is stored in the display axis so grab it and
%overwrite obj passed in.
obj = findmobj(obj);

obj = checktarget(obj);
if isempty(obj)
  return
end

%Get users initial window.
[px,py] = gselect('rbbox',obj.target_axis);

%Find button.
if ishandle(obj.parent_figure)
  bh = findobj(allchild(obj.parent_figure),'tag','pgtmagnify');
else
  %User may have closed figure during gselect.
  return
end

if ~isempty(px)
  obj.patch_xdata = px;
  obj.patch_ydata = py;
  if ~isempty(bh) && ishandle(bh)
    set(bh,'state','on')
    magnifytooltoggle(obj.parent_figure,1)
  end
else
  %User cancel.
  if ~isempty(bh) && ishandle(bh)
    set(bh,'state','off')
    magnifytooltoggle(obj.parent_figure,1)
  end
end

updatepatch(obj);



