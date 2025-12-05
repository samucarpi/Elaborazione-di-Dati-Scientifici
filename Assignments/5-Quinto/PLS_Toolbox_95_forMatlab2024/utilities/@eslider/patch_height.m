function [ht,oversize] = patch_height(obj)
%PATCH_HEIGHT Return patch height in pixels and flag for oversize patch.
%I/O: [height,oversize] = patch_height(obj)

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

min_height = 10;
patch_height = (obj.page_size/obj.range)*obj.position(4);
oversize = patch_height<min_height;   %note if we had to make the slider larger for ease of use
if oversize
  patch_height = min_height;
end

%Convert patch height to vertical axis units.
ht = (patch_height/obj.position(4))*obj.range;
