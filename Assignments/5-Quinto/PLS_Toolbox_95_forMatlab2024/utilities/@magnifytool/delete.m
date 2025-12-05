function delete(varargin)
%MAGNIFYTOOL/DELETE Delete object.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

for i = 1:nargin
  if strcmp(class(varargin{i}),'magnifytool')
    obj = varargin{i};
  end
end

%Get latest object.
obj = findmobj(obj);
if isempty(obj)
  return
end

%Check if should delete display axis or not.
if ~obj.display_delete
  dax = [];%Do not delete and don't resize parent.
else
  dax = finddisplayax(obj.parent_figure);
end

%Delete display axis.
if ~isempty(dax) && ishandle(dax)
  delete(dax);
end

if ishandle(obj.patch_handle)
  %Delete patch.
  delete(obj.patch_handle);
end

if ishandle(obj.resize_handle)
  %Delete patch.
  delete(obj.resize_handle);
end

%Set button to off.
bh = findobj(allchild(obj.parent_figure),'tag','pgtmagnify');
if ~isempty(bh) && ishandle(bh)
  set(bh,'state','off')
  magnifytooltoggle(obj.parent_figure,1)
end

%Delete display axis.
dtax = findobj(obj.parent_figure,'tag','drill_display');
if isempty(dtax)
  if ~isempty(dax)
    %Retrun plot so single.
    subplot(1,1,1,obj.target_axis);
    %Resize figure back.
    fpos = get(obj.parent_figure,'position');
    if ~isempty(obj.parent_figure_oposition)
      oldpos = obj.parent_figure_oposition;
      fpos(3) = oldpos(3);
      %fpos(4) = oldpos(4);
    else
      %Best guess.
      fpos(3) = fpos(3)/2;
    end
    set(obj.parent_figure,'position',fpos);
  end
else
  %Retrun plot to magnify tool 1x2.
  subplot(1,2,1,obj.target_axis);
  subplot(1,2,2,dtax);
end

%Remove context menu.
cm = findobj(obj.parent_figure,'tag','magnify_contextmenu');
if ~isempty(cm) && ishandle(cm)
  delete(cm);
end
