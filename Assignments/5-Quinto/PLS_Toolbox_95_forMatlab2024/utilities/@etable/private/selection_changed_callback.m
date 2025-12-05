function [ output_args ] = selection_changed_callback(hObj,ev,fh,mytag,varargin)
%ETABLE/SELECTION_CHANGED_CALLBACK Table selection changed callbck.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Get copy of object.
obj = gettobj(fh,mytag);

%Table not available.
if isempty(obj)
  return
end

%Get row and row.
jt = obj.java_table;

%TODO: This is a possible hack to disable a column but to do it correctly
%you need to add a custom class to the table model.
% if strcmp(obj.editable,'on')
%   %Check to see if colum and or row is disabled.
%   if ~isempty(obj.disabled_columns)|~isempty(obj.disabled_rows) 
%     pcol = evrijavamethodedt('columnAtPoint',jt,ev.getPoint);
%     prow = evrijavamethodedt('rowAtPoint',jt,ev.getPoint);
%     if any(obj.disabled_columns==pcol) | any(obj.disabled_rows==prow)
%       jt.setEditable(false)
%     else
%       jt.setEditable(true)
%     end
%   else
%     %Make sure everything is editable.
%     jt.setEditable(true)
%   end
% end

myfcn = obj.selection_changed_callback;

%Run additional callbacks if needed.
myvars = getmyvars(myfcn);
if iscell(myfcn)
    myfcn = myfcn{1};
end
if ~isempty(myfcn)
  feval(myfcn,myvars{:});
end

%---------------------------
function myvars = getmyvars(myfcn)
%Get function from object.

myvars = {};
if length(myfcn)>1
  myvars = myfcn(2:end);
  myfcn = myfcn{1};
end
