function obj = clear(obj,target)
%ETABLE/CLEAR Get selected rows, columns, or cells.
% target : {'all' 'data' 'column_labels' 'row_header' 'callbacks'}

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get tables.
jt = obj.java_table;

if nargin<2
  target = {'data'};
end

if ~iscell(target)
  target = {target};
end

if length(target)==1 && strcmpi(target{1},'all')
  target = {'data' 'column_labels' 'row_header' 'callbacks'};
end

for i = target
  switch i{:}
    case 'data'
      mytbl = obj.table;
      cols = mytbl.getTable.getColumnCount;
      obj = set(obj,'data',repmat({' '},1,cols));
    case 'column_labels'
      mytbl = obj.table;
      cols = mytbl.getTable.getColumnCount;
      obj = set(obj,'column_labels',repmat({' '},1,cols));
    case 'row_header'
      obj = set(obj,'row_header_text','');
    case 'callbacks'
      obj = set(obj,'table_clicked_callback','');
      obj = set(obj,'table_doubleclicked_callback','');
      obj = set(obj,'table_mousepressed_callback','');
      obj = set(obj,'column_clicked_callback','');
      obj = set(obj,'column_doubleclicked_callback','');
      obj = set(obj,'row_clicked_callback','');
      obj = set(obj,'row_doubleclicked_callback','');
  end
  
end
