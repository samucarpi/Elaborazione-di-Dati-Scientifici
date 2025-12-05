function addcallbacks(obj)
%ETABLE/ADDCALLBACKS Add callbacks for cell, row, and column.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get Java table.
jt = obj.java_table;

%NOTE: Wrap all of these in try/catch because sometimes they will error out
%if table is not visible. 

try
  %---- Add click callbacks:
  %Go up to veiw port, to scrollpane then back down to view port and then row table.
  row_table = evrijavaobjectedt(jt.getParent.getParent.getRowHeader.getView);%Row table.
  % %http://www.mathworks.com/matlabcentral/newsreader/view_thread/294487#789661
  row_tableh = handle(row_table, 'CallbackProperties');%Wrap in handle so don't get warnings and cause mem leak.
  set(row_tableh,'MouseClickedCallback',{@mouse_clicked_callback,obj.parent_figure,obj.tag,'row'})
end

try
  %Function handle from object will be called.
  jth = handle(jt,'CallbackProperties');
  set(jth,'MouseClickedCallback',{@mouse_clicked_callback,obj.parent_figure,obj.tag,'table'})
  set(jth,'MousePressedCallback',{@mouse_pressed_callback,obj.parent_figure,obj.tag,'table'})
end

try
  %Column click callback. Same TODO as above.
  if ~isempty(jt.getParent.getParent.getColumnHeader)  %look for this problem now (rather than allowing it to throw an error)
    column_table = evrijavaobjectedt(jt.getParent.getParent.getColumnHeader.getView);%Will error here if table not visible.
    column_tableh = handle(column_table,'CallbackProperties');
    set(column_tableh,'MousePressedCallback',{@mouse_clicked_callback,obj.parent_figure,obj.tag,'column'})
  end
end

try
  if ~isempty(obj.selection_changed_callback) & ~isempty(jt.getSelectionModel)
    %Add selectyion changed callback.
    selectmod_row = evrijavaobjectedt(jt.getSelectionModel);
    selectmodh_row = handle(selectmod_row,'CallbackProperties');
    set(selectmodh_row,'ValueChangedCallback',{@selection_changed_callback,obj.parent_figure,obj.tag,'row'});
    
    selectmod_col = evrijavaobjectedt(jt.getColumnModel.getSelectionModel);
    selectmodh_col = handle(selectmod_col,'CallbackProperties');
    set(selectmodh_col,'ValueChangedCallback',{@selection_changed_callback,obj.parent_figure,obj.tag,'column'});
  end
end

try
  %Add data changed callback.
  if ~isempty(obj.data_changed_callback)
    set(obj.table,'DataChangedCallback',{@data_changed_callback,obj.parent_figure,obj.tag});
  end
end
  


  %NOTE: Don't do this:
  %   set(column_tableh,'MousePressedCallback',{@mouse_pressed_callback,obj})
  % Is a memory leak, Objet will remain in memory no matter what you do.
  %----
