function [click_type, click_count] = get_click_info(ev)
%EVRITREE/GET_CLICK_INFO - Get click information.
%
% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Click type.
click_type = 1;%Left.
mymods = evrijavamethodedt('getModifiers',ev);
if mymods==ev.BUTTON3_MASK
  %Right click.
  click_type = 2;%Right.
end
click_count = ev.getClickCount;
