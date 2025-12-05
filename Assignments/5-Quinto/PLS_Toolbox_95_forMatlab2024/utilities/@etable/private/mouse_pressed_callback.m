function [ output_args ] = mouse_pressed_callback(hObj,ev,fh,mytag,varargin)
%ETABLE/MOUSE_PRESSED_CALLBACK Check for right click and select column.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%javax.swing.SwingUtilities.isRightMouseButton(ev)

if nargin>4
  source = varargin{1};
else
  source = 'table';
end

%Click type.
click_type = 1;%Left.
mymods = evrijavamethodedt('getModifiers',ev);
if mymods==ev.BUTTON3_MASK
  %Right click.
  click_type = 2;%Right.
end
click_count = ev.getClickCount;

%Get copy of object.
obj = gettobj(fh,mytag);

%Don't do anything if we're disabled.
if strcmp(obj.disable_mouse_callbacks,'on')
  return
end

%Get row and row.
jt = obj.java_table;
mycol = jt.getSelectedColumns+1;
myrow = jt.getSelectedRows+1;

myfcn = [];

%Run code for particular source.
switch source
  case 'table'
    
    switch obj.cell_click_selection
      case 'row'
        %Select row.
        ncols = jt.getColumnCount;
        jt.setColumnSelectionInterval(0, ncols-1);
      case 'column'
        %Select column.
        nrows = jt.getRowCount;
        jt.setRowSelectionInterval(0, nrows-1);
    end
    
    myfcn = obj.table_mousepressed_callback;

  case 'row'
    %myfcn = obj.row_clicked_callback;
  case 'column'
    %myfcn = obj.column_clicked_callback;
end

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
