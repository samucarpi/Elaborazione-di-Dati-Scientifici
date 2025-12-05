function [mytable, container] = evritable(parent,columnheaders,data,options)
%EVRITABLE - Create java table that works from ML 7.0.4+.
% Function sets an appdata field in parent figure with table handle under
% the name of options.tag.
%
% NOTE: This function creates the table only and does no further
% manipulation. Other helper functions/object should be employed to do
% advanced table manipulation.
%
% INPUTS:
%   parent        - Parent uipanel/fig.
%   columnheaders - Cell array of strings for column names.
%   data          - Data as cell array or double or dataset.
%
% OPTIONS:
%         tag : [{''}] Tag of table (string).
%    position : [{L B W H}] Position vector in pixels for intial position
%               of table.
% EXAMPLE:
%   fig = figure;
%   [mytable,mycontainer] = evritable(fig,{'a'},1)
%
%I/O: [mytable, container] = evritable(parent,columnheaders,data);
%
%See also: uitable

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%TODO: Check for thread safety.

if ischar(parent);
  options = [];
  options.tag                 = 'evritable';
  options.position            = []; %In pixels.
  if nargout==0; evriio(mfilename,parent,options); else; mytable = evriio(mfilename,parent,options); end
  return;
end

if nargin<4
  options = evritable('options');
end

options = reconopts(options,'evritable');

if ~iscell(data)
  data = mat2cell(data,ones(1,size(data,1)),ones(1,size(data,2)));
end

if isempty(columnheaders)
  columnheaders{1,size(data,2)} = deal('');
end

%pos = getpixelposition(parent);

[mytable, container] = uitable_o(options,'Parent',parent,'Data',data, 'ColumnNames',columnheaders);
mytable.setNumRows(size(data,1));
set(mytable,'units','normalized');

mytag = options.tag;
if isempty(mytag)
  mytag = 'evri_uitable';
end

%Save table object to appdata for easy reference.
setappdata(ancestor(parent,'figure'),mytag,mytable);

jtable = mytable.getTable;
%Yair does this for a bug in jtable.
jtable.putClientProperty('terminateEditOnFocusLost', java.lang.Boolean.TRUE);

% if ~isempty(which('TableSorter'))
%   % Add TableSorter as TableModel listener
%   sorter = TableSorter(jtable.getModel);  %(table.getTableModel);
%   %tablePeer = UitablePeer(sorter);  % This is not accepted by UitablePeer... - see comment above
%   jtable.setModel(sorter);
%   sorter.setTableHeader(jtable.getTableHeader);
%   
%   % Set the header tooltip (with sorting instructions)
%   jtable.getTableHeader.setToolTipText('<html>&nbsp;<b>Click</b> to sort up; <b>Shift-click</b> to sort down<br>&nbsp;<b>Ctrl-click</b> (or <b>Ctrl-Shift-click</b>) to sort secondary&nbsp;<br>&nbsp;<b>Click again</b> to change sort direction<br>&nbsp;<b>Click a third time</b> to return to unsorted view<br>&nbsp;<b>Right-click</b> to select entire column</html>');
% else
%   % Set the header tooltip (no sorting instructions...)
%   jtable.getTableHeader.setToolTipText('<html>&nbsp;<b>Click</b> to select entire column<br>&nbsp;<b>Ctrl-click</b> (or <b>Shift-click</b>) to select multiple columns&nbsp;</html>');
% end

%Store the uitable's handle within the pnContainer's userdata, for later use
% set(parent,'userdata',[get(parent,'userdata'), mytable]);  % add to parent userdata, so we have a handle for deletion
% 
% %Enable multiple row selection, auto-column resize, and auto-scrollbars
% scroll = mytable.TableScrollPane;
% scroll.setVerticalScrollBarPolicy(scroll.VERTICAL_SCROLLBAR_AS_NEEDED);
% scroll.setHorizontalScrollBarPolicy(scroll.HORIZONTAL_SCROLLBAR_AS_NEEDED);
% jtable.setSelectionMode(javax.swing.ListSelectionModel.MULTIPLE_INTERVAL_SELECTION);
% jtable.setAutoResizeMode(jtable.AUTO_RESIZE_SUBSEQUENT_COLUMNS)
% 
% %Set the jtable name based on the containing panel's tag
% if ~isempty(options.table_name)
%   jtable.setName(options.table_name);
% end
% 
% %Move the selection to first table cell (if any data available)
% if (jtable.getRowCount > 0)
%   jtable.changeSelection(0,0,false,false);
% end

%--------------------------------------------------------------------
function [t,c] = uitable_o(options, varargin)
%Overload to be backward compatible.
  
property_argin = varargin;
prop_struct = [];
%Try to assign value pairs.
while length(property_argin) >= 2
  prop_struct.(lower(property_argin{1})) = property_argin{2};
  property_argin = property_argin(3:end);
end

%2008a has new uitable which is way way better at handling large arrays so
%try to use that when possible.
if checkmlversion('<','7.6')
  if ~isfield(prop_struct,'columnname')
    [t,c] = uitable('parent',prop_struct.parent,'data',prop_struct.data);
  else
    [t,c] = uitable('parent',prop_struct.parent,'data',prop_struct.data,'ColumnNames',prop_struct.columnname);
  end
% CELLEDITCALLBACK not used, should be done in other function/object.
%   if isfield(prop_struct,'celleditcallback')
%     set(t,'DataChangedCallback',prop_struct.celleditcallback)
%   end
else
  [t,c] = uitable('v0',varargin{:});
end

set(c,'tag',options.tag);
if ~isempty(options.position)
  set(c,'units','pixels','position',options.position);
else 
  %Max out the table.
  set(c,'units','normalized','position',[0 0 1 1]);
end
  

      
