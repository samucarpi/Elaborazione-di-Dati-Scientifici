function expandrow(obj,myrow)
%EVRITREE/EXPANDROW Expand tree row 'myrow'.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = get_evritree_obj(obj);

evrijavamethodedt('expandRow',obj.java_tree,myrow);
