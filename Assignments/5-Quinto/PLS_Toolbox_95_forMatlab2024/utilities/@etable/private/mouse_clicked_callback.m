function [ output_args ] = mouse_clicked_callback(hObj,ev,fh,mytag,varargin)
%ETABLE/MOUSE_CLICKED_CALLBACK Click on table (not columns or rows).

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Check to see if there's a source input for where the click came from:
% source = table|column|row
if nargin>4
  source = varargin{1};
else
  source = 'table';
end

%Click type.
click_type = 1;%Left.
mymods = evrijavamethodedt('getModifiers',ev);

%Mac workaround for detecting right-click. Does not work on 15a and older.
ispopup = 0;
try
  if java.awt.event.MouseEvent.isPopupTrigger(ev)
    ispopup = 1;
  end
end

if ispopup | mymods==ev.BUTTON3_MASK
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
    myfcn = obj.table_clicked_callback;
    if click_count==2
      myfcn = obj.table_doubleclicked_callback;
    end
  case 'row'
    myfcn = obj.row_clicked_callback;
    if click_count==2
      myfcn = obj.row_doubleclicked_callback;
    end
  case 'column'
    myfcn = obj.column_clicked_callback;
    if click_count==2
      myfcn = obj.column_doubleclicked_callback;
    end
    if click_type==2
      %Make column under mouse click current selection so sorting works correctly.
      setselection(obj,'columns',jt.columnAtPoint(ev.getPoint)+1);
    end
end

if strcmp(obj.row_multiselection,'off')&~isempty(myrow)&length(myrow)>1
  setselection(obj,'rows',myrow(1))
end

%Run additional callbacks if needed.
myvars = getmyvars(myfcn);
if iscell(myfcn)
    myfcn = myfcn{1};
end

if ~isempty(myfcn)
  try
    feval(myfcn,myvars{:});
  catch
    try
      %Try calling with two inputs. This form is used by MCCTool.
      myfcn(hObj,ev,myvars{:})
    end
  end
end

%---------------------------
function myvars = getmyvars(myfcn)
%Get function from object.

myvars = {};
if length(myfcn)>1
  myvars = myfcn(2:end);
  myfcn = myfcn{1};
end


