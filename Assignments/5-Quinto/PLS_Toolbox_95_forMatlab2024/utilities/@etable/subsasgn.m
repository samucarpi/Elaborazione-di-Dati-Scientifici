function obj = subsasgn(obj,index,val)
%ETABLE/SUBSASGN Subscript assignment reference for ETABLE.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

feyld = index(1).subs; %Field name.

if strcmp(feyld,'data') & length(index)>1;
  %Shortcut to direct assign.
  index = index(2);
end

if length(index)>1;
  error(['Index error, can''t assign into field: ' feyld '.'])
else
  %Assign into data table. Using code from DSO.
  if ~strcmp(index(1).type,'.')
    if strcmp(index(1).type,'()')
      mydata = obj.data;
      if isdataset(mydata)
        x = mydata.data;
      else
        x = mydata;
      end
      
      val = subsasgn(x,index,val);
      
      if isdataset(mydata)
        mydata.data = val;
      else
        mydata = val;
      end
      obj.data = mydata;
      updatetable(obj);
    end
  else
    switch feyld
      case 'ts'
        %Don't allow change of timestamp, may use this for ID.
        return
      case 'column_format_silent'
        %Update column format without calling updatetable. Use this in the
        %case of conditional formatting, need a different format for data
        %being updated (silently change format of column/s then update
        %data).
        obj.column_format = val;
      case 'data_silent'
        %Add data to table using tablemodel so renderers don't get reset.
        obj.data = val;
        update_data_silent(obj);
      case 'column_label_silent'
        %Add data to table using tablemodel so renderers don't get reset.
        obj.column_labels = val;
        update_column_label_silent(obj);
      otherwise
        obj.(feyld) = val;
        jt = obj.java_table;
        switch feyld
          case 'autoresize'
            jt.setAutoResizeMode(jt.(obj.autoresize));  
          case 'column_header_height'
            %Adjust column header height.
            setscrollpanelsizing(obj,'colheader')
          case 'column_labels'
            updatecolumns(obj);
          case {'data' 'column_format' 'table_format'}
            updatetable(obj);
          case 'data_changed_callback'
            set(obj.table,'DataChangedCallback',{@data_changed_callback,obj.parent_figure,obj.tag});
          case 'editable'
            mtbl = obj.table;
            if strcmp(val,'on')
              mtbl.Editable = 1;
            else
              mtbl.Editable = 0;
            end
%             if strcmp(val,'on')
%               jt.setCellSelectionEnabled(true)
%             else
%               jt.setCellSelectionEnabled(false)
%             end
          case 'grid_color'
            tbl = obj.table;
            tbl.setGridColor(obj.grid_color)
          case 'table_fontname'
            setfont(obj,'table',[],obj.table_fontname,'','');
          case 'table_fontsize'
            setfont(obj,'table',[],'','',obj.table_fontsize);
          case 'table_fontstyle'
            setfont(obj,'table',[],'',obj.table_fontstyle,'');
          case 'position'
            set(obj.table_container,'position',obj.position);
          case 'row_labels'
            updaterows(obj);
          case 'row_header_text'
            setrowheadertext(obj)
          case 'row_header_width'
            setscrollpanelsizing(obj,'rowheader')
          case 'units'
            set(obj.table_container,'units',obj.units);
          case 'visible'
            set(obj.table_container,'visible',obj.visible);
          case {'table_clicked_callback' 'row_clicked_callback' 'column_clicked_callback' 'selection_changed_callback'}
            %If callbacks being assigned then be sure callbacks are there,
            %they sometimes won't be assigned if table not rendered
            %visually.
            addcallbacks(obj);
        end
    end
  end
end

if ~isempty(obj.table)
  %Save to parent figure if possible.
  setobj(obj)
end
