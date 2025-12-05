function [ output_args ] = drag(obj)
%DRAG Dragging patch, update  value.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Value should never be outside of range.
[ht,oversize] = patch_height(obj);
if oversize
  %oversized patch requires grabbing the MIDDLE of the patch object
  val = -round(mean(get(obj.patch,'ydata')));
else
  val = -round(max(get(obj.patch,'ydata')));
end

if val<1
  val = 1;
elseif val > obj.range
  val = obj.range;
end
%Set value.
obj.value = val;
%Call external update callback.
feval(obj.callbackfcn,'eslider_update',obj)
%Save object.
setappdata(obj.parent,'eslider',obj);
