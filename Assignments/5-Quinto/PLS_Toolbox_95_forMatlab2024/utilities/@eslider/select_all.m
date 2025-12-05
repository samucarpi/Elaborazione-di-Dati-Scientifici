function select_all(obj)
%SELECT_ALL Select all eslider items.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

obj.selection = 1:obj.range;
subsasgn(obj,struct('subs','selection'),obj.selection);
%Call external update callback.
feval(obj.callbackfcn,'eslider_clear',obj)
