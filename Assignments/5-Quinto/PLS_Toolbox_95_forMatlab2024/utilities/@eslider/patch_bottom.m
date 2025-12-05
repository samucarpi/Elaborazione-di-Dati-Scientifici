function bt = patch_bottom(obj)
%PATCH_BOTTOM Returns position of bottom of patch.
%I/O: bt = patch_bottom(obj)

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Patch bottom should be (value[top of patch]+patch height).
[ht,oversize] = patch_height(obj);
bt = obj.value - 1 + ht;
if oversize
  %if oversized, CENTER window on bt: bottom = (value+(patch height/2)
  bt = bt-ht/2;
end
if bt > obj.range + ht
  bt = obj.range + ht;
elseif bt<ht
  bt = ht;
end
