function obj = initialize(obj,incoming_props)
%ETABLE/INITIALIZE Set initial info of object.
% Build initial table and add static features. Use updatetable and or
% sub-functions to add additional dynamic items.

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Need data and figure to do anything.
if isempty(obj.data)
  %Make 1 empty cell.
  obj.data = {' '};
end

warningtoggle;%Turn off unwanted warnings.

if isempty(obj.parent_figure)
  obj.parent_figure = figure('tag','etable_default_figure');
end

%Get data and make it into cell array for uitable.
mydata = getdata(obj);

%Get column names.
columnheaders = getcolumnlabels(obj);


myparent = obj.parent_figure;
if ~isempty(obj.parent_object)
  myparent = obj.parent_object;
end

%Create the table.
if isempty(columnheaders)
  [obj.table, obj.table_container] = uitable_o('Parent',myparent,'Data',mydata);
else
  %Make the table.
  [obj.table, obj.table_container] = uitable_o('Parent',myparent,'Data',mydata, 'ColumnNames',columnheaders);
end

%If > 7.6 make sure object are on EDT.
obj.java_table = evrijavaobjectedt(get(obj.table,'Table'));

%Set initial properties.
set(obj.table_container,'tag',obj.tag,'visible',obj.visible,'units',obj.units,'position',obj.position)

%---- Set up the jtable.
jtable = obj.java_table;
%Yair does this for a bug in jtable, not sure why.
jtable.putClientProperty('terminateEditOnFocusLost', java.lang.Boolean.TRUE);
%Set cell selection to most liberal setting, this might mess up some
%methods but guessing that would be rare and user may be interacting with
%table and external application/s.
jtable.setSelectionMode(javax.swing.ListSelectionModel.MULTIPLE_INTERVAL_SELECTION);
%Set column resize mode.
jtable.setAutoResizeMode(jtable.(obj.autoresize))
drawnow
if strcmp(obj.custom_cell_renderer,'on')
  %Set cell renderer for each column now, might save time.
  colcount = size(mydata,2);
  for i = 1:colcount
    getcustomcellrenderer(obj,i);%Add custom cell renderer for each column.
  end
end
drawnow
%---- 

%FIXME:
if ~isempty(incoming_props)
  %Parse these props.
  toparse = {};%List of props to assign.
end

%Add sorting if needed.
addcolumnsorting(obj)

drawnow

setobj(obj)
updatetable(obj)

%Add click/datachange callbacks. It must be here so datachange callback
%doesn't get called for every single cell when first adding data above.
addcallbacks(obj)
