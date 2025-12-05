function [ output_args ] = mouse_pressed_callback(hObj,ev,fh,mytag,varargin)
%EVRITREE/MOUSE_PRESSED_CALLBACK Do some action when mouse pressed.
%  Usually indicates a drag could be starting.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%javax.swing.SwingUtilities.isRightMouseButton(ev)

return

% if nargin>4
%   source = varargin{1};
% else
%   source = 'tree';
% end
% 
% [click_type, click_count] = get_click_info(ev);
% 
% %Get copy of object.
% obj = gettobj(fh,mytag);
% 
% %Don't do anything if we're disabled.
% if strcmp(obj.disable_mouse_callbacks,'on')
%   return
% end
% 
% %Get row and row.
% jt = obj.java_table;
% mycol = jt.getSelectedColumns+1;
% myrow = jt.getSelectedRows+1;
% 
% myfcn = [];
% 
% %Run code for particular source.
% switch source
%   case 'table'
%     
%     switch obj.cell_click_selection
%       case 'row'
%         %Select row.
%         ncols = jt.getColumnCount;
%         jt.setColumnSelectionInterval(0, ncols-1);
%       case 'column'
%         %Select column.
%         nrows = jt.getRowCount;
%         jt.setRowSelectionInterval(0, nrows-1);
%     end
%     
%     myfcn = obj.table_mousepressed_callback;
% 
%   case 'row'
%     %myfcn = obj.row_clicked_callback;
%   case 'column'
%     %myfcn = obj.column_clicked_callback;
% end
% 
% %Run additional callbacks if needed.
% myvars = getmyvars(myfcn);
% if iscell(myfcn)
%     myfcn = myfcn{1};
% end
% if ~isempty(myfcn)
%   feval(myfcn,myvars{:});
% end
% 
% %---------------------------
% function myvars = getmyvars(myfcn)
% %Get function from object.
% 
% myvars = {};
% if length(myfcn)>1
%   myvars = myfcn(2:end);
%   myfcn = myfcn{1};
% end
