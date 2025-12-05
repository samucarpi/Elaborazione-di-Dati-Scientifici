function obj = etable(varargin)
%ETABLE/ETABLE Wrapper object for working with jtable in Matlab.
%
% Typical call usually with data and column headers.
%
% Calling with no inputs creates a figure and empty table.
% 
% NOTE: Not all properties are initialized. If using properties other than
% the following they may need to be assigned after object creation:
%   figure_parent
%   tag
%   data
%   column_labels
%   autoresize
%   custom_cell_renderer
%  
%
%I/O: obj = etable(varargin)
%I/O: obj = etable(data);%Create figure with table of data.
%I/O: obj = etable(data,'parent_figure',figh);
%
%See also: EVRITREE

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

% NOTE: We use this wrapper to contain all custom java calls so we can more
% easily monitor thread safety and manage code.
%


%TODO: Add more extensive documentation.
%TODO: Add test function.
%TODO: Might add code to toggle .add_row_labels field (during creation) if
%TODO: Add toolbar and/or add the following to context menu:
%         Plot
%         Copy/Paste
%         Export
%         Show Duplicates
%         Insert
%         Show Statistics
%         Filter (hide rows/columns by setting width/height)
%         Insert/Remvoe column or row
%TODO: For large matrix, add zoomed out "view" (representation of the
%      whole table) with box showing current table. Similar to magnify
%      tool. Show selection in "view" and maybe highlight other info. 
%TODO: Add "remove" column sorting.
%TODO: Add "insert row/column"

%FIXME: Callback code.



switch nargin
  case 0
    obj = getdefaults;
    obj = class(obj,'etable');
  otherwise
    if ischar(varargin{1}) && (strcmp(varargin{1},'update') || strcmp(varargin{1},'delete'))
      %Try to udpate the table on the figure.
      
      thisobj = findmyobj(varargin{2});
      
      if strcmp(varargin{1},'delete')
        delete(thisobj)
        return
      end
      
%       %Make check target.
%       thisobj = checktarget(thisobj);
%       if isempty(thisobj)
%         return
%       end
%       
%       %Find existing axis if possible.
%       dax = finddisplayax(thisobj.parent_figure);
%       
%       if isempty(dax)
%         %Display axis could have been manually added.
%         dax = thisobj.display_axis;
%       end
%       %Delete object if display axis is lost.
%       if isempty(dax) || ~ishandle(dax)
%         %We're in a bad state, delete the object.
%         delete(thisobj);
%         return
%       end
%       updateplots(thisobj);
%       updatepoints(thisobj);
      return
    end
    
    if ischar(varargin{1}) && strcmp(varargin{1},'wbm')
      %Window button motion.
      wbmfcn(varargin{2})
      return
    end
    
    if ischar(varargin{1}) && strcmp(varargin{1},'wbd')
      %Window button down.
      bdfcn(varargin{2})
      return
    end
    
    if ischar(varargin{1}) && strcmp(varargin{1},'bu')
      %Window button up.
      bufcn(varargin{2:end})
      return
    end
    
    obj = getdefaults;
    %Passing handles, data, and or value pairs.
    if ~ischar(varargin{1}) && (isnumeric(varargin{1})||isdataset(varargin{1}))
      %Passing data as first argument.
      obj.data = varargin{1};
      varargin = varargin(2:end);
    end
    
    if ~isempty(varargin) && ~ischar(varargin{1}) && iscell(varargin{1}) && ~isempty(varargin{1})
      %Passing labels as second argument.
      obj.column_labels = varargin{1};
      varargin = varargin(2:end);
    end
    
    property_argin = varargin;
    %Try to assign value pairs.
    incoming_props = {};
    while length(property_argin) >= 2,
      prop = property_argin{1};
      val = property_argin{2};
      incoming_props = [incoming_props {prop}];
      property_argin = property_argin(3:end);%Cut off first 2.
      if isfield(obj,prop)
        obj.(prop) = val;
      end
    end
    obj = class(obj,'etable');
    obj = initialize(obj,incoming_props);
end

%----------------------------
function obj = getdefaults
%Default values.
obj.etableversion         = 1.0;
obj.parent_figure         = [];%Parent figure.
obj.parent_object         = [];%Parent panel or button group.
obj.ts                    = now;

%Base items.
obj.data                  = [];
obj.column_labels         = {};%If is empty, use DS labels if available.
obj.row_labels            = {};%If is empty, use DS labels if available.
obj.row_label_header      = '';%Column header for row labels (.labelname in a dataset).
obj.add_row_labels        = 'off';%Can't actually modify row headers so we have to fake it in Column one.

%Container props, all asigned through subsasgn.
obj.table_container       = [];%Table container handle.
obj.tag                   = 'etable';%Tag is used to find object so if using more than one table on figure use different tag.
obj.visible               = 'on';
obj.units                 = 'normalized';
obj.position              = [0 0 1 1];
obj.editable              = 'on';%Enable selections and clicks.
obj.data_changed_callback = '';

%Table props.
obj.table                 = [];%Matlab uitable object.
obj.java_table            = [];%Jtable object.
obj.java_parent           = [];%Java object if table is moved into parent java container (like a panel).
obj.column_model          = [];%Column model java object.
obj.column_sort           = 'on';%{'on' 'off' 'builtin'} Add sorting context menu items, 'builtin' = use jide table built in sorting, will not work on pre 2008a, may have unexpected behavior.
obj.copy_all             = 'on';%{'on' 'off'} Add copy all menu item that copyies column labels and data into system copy.
obj.ds_use_col            = 'on';%Use dataset column names.
obj.ds_use_row            = 'on';%Use dataset row names.
obj.cell_click_selection  = 'none';%'row' 'column' When click on cell, select a row or column, or nothing.
obj.column_header_height  = [];%empty = use default.
obj.row_height            = [];%empty = use default.
obj.row_header_width      = [];%Row header (right side row numbers) empty = use default.
obj.row_header_text       = '';%Text header for row header table. NOTE: This causes java error if table is closed without text being set to ''.
obj.row_multiselection    = 'on';%Allow multiple rows to be selected.
obj.custom_cell_renderer  = 'off';%Add custom cell renderer, if this is set then cell renderer is added during initialize (not sure if this is need to help speed things up or not).
obj.grid_color            = '';%empty = default.
obj.table_fontsize        = [];%Empty = default.
obj.table_fontstyle       = 'plain';%{'plain' 'bold' 'italic'}
obj.table_fontname        = '';%Empty = default.
obj.autoresize            = 'AUTO_RESIZE_OFF';%AUTO_RESIZE_OFF, AUTO_RESIZE_NEXT_COLUMN, AUTO_RESIZE_SUBSEQUENT_COLUMNS, AUTO_RESIZE_LAST_COLUMN, AUTO_RESIZE_ALL_COLUMNS
obj.table_format          = '';%Format of all data in table (all data must be numeric).
obj.column_format         = {};%Format specific columns, must be length of columns. All formatting occurs before data is added to table (see getdata).
obj.replace_nan_with      = '';%Replace NaN characters with different text.
%obj.disable_data_callback = 'off';%Turn off data change callback when updating data. Use this with large tables and or when programatially updating table.

%Callbacks, function handles only. Can use to add interaction with other contorls (highlight items in tree for instance).
obj.disable_mouse_callbacks       = 'off';%Disable callbacks from being run.
obj.table_clicked_callback        = '';
obj.table_doubleclicked_callback  = '';%Inconsistent behavior if table is editable.
obj.table_mousepressed_callback   = '';
obj.column_clicked_callback       = '';
obj.column_doubleclicked_callback = '';
obj.row_clicked_callback          = '';
obj.row_doubleclicked_callback    = '';
obj.selection_changed_callback    = '';%Selection in table changed.
obj.post_sort_callback            = '';%Called after sort is complete. Use for re-coloring cells for example.


%----------------------------
function wbmfcn(varargin)
%Window button motion function for table


%----------------------------
function bdfcn(varargin)
%Button down function for table.

%Find figure.
if nargin>0 && ishandle(varargin{1})
  f = ancestor(varargin{1},'figure');
else
  f = gcf;
end


%----------------------------
function bufcn(varargin)
%Button up function for marker to update drill points.

%Find figure.
if nargin>0 && ishandle(varargin{1})
  f = ancestor(varargin{1},'figure');
else
  f = gcf;
end


%----------------------------
%TEST



