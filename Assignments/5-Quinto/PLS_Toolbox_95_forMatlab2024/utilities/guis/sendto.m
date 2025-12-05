function varargout = sendto(varargin)
%SENDTO Manages and creates "Send To" menus in GUIs.
% Handles "send-to" menus including both adding menus to an indicated
% handle and processing a send-to action.
%
% ADDING MENUS:
% The first form of the I/O adds and handles send to operations from a menu
% system. It includes the handle to a menu and a callback function handle
% or string. The available send-to menus are added to the indicated handle
% with the callback assigned for each. The callback should point to a
% function (or be a string callback) which will locate the data or
% shareddata relevent to the send action and call sendto to proces the
% action.
% 
% PROCESS SEND-TO:
% The second form of the I/O is used by the callback on a send-to item and
% includes the data (either numeric, dataset, or a shareddata object) to
% pass. It can also optionally include the send-to target (one of the items
% returned from the "list" command described below). If no target is
% included, the target identified by the current callback object is used.
%
% UPDATE MENU:
% The children of a send-to menu can be updated for the currently available
% tools by calling sendto with the string 'update' and the parent menu's
% handle.
%
% LIST METHODS:
% A call to sendto with no inputs returns a structure array describing all
% of the possible send-to targets.
%
%I/O: sendto(handle,callback)  %add send-to sub-menus to specified handle
%I/O: sendto(data)             %send data to send-to current target
%I/O: sendto(data,target)      %send data to send-to specific target
%I/O: sendto('update',handle)  %update status of all send-to children of handle
%I/O: list = sendto            %return list of possible send-to targets
%
%See also: ANALYSIS, EDITDS, PLOTGUI, SHAREDDATA

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0
  list = [];
  %List contains these fields:
  %   label  : string description to use for this item
  %   fn     : function name for target 
  %   method : type of load operation. 
  %             'drop' = standard drop method
  %             'input' = pass as input to function
  %   shareddata :  boolean flag indicating shared data is acceptable
  %               true = pass as shared data, 
  %              false = pass as raw data
  
  list = parsexml(which('sendto.xml'),1);
  try
    list = [list.item{:}];
  catch
    le = lasterror;
    le.message = ['Unable to load Send-To list. ' le.message];
    rethrow(le);
  end
  varargout = {list};
  return
end

%actual call to add menus OR to process a "send to" action
if ishandle(varargin{1}) & ~isshareddata(varargin{1}) & ~isdataset(varargin{1})
  %passed a handle? add children to given handle  
  addchildren(varargin{:});
elseif ~ischar(varargin{1})
  %passed a list item to process
  processlink(varargin{:});
else
  feval(varargin{:});
end

%---------------------------------------------------
function addchildren(varargin)
%add children to identified handle with indicated callback
% (h,fncall)

h = varargin{1};
if nargin<2
  fncall = '';
else
  fncall = varargin{2};
end

if isempty(fncall)
  fncall = 'sendto(getappdata(gcbf,''dataset''))';
end

%test if we can add menus to this item
if ~strcmp(get(h,'type'),'uimenu') & ~strcmp(get(h,'type'),'uicontextmenu')
  error('Cannot add Send To menus to this kind of object')
end
list = sendto;  %get list

%add menus
delete(get(h,'children'));
for j=1:length(list);
  h1 = uimenu(h,'label',list(j).label,'callback',fncall,'userdata',list(j),'separator',list(j).separator);
end
update(h);  %and update display and enabling

if isempty(get(h,'callback'))
  set(h,'callback',@update);
end

%--------------------------------------------------
function update(h,varargin)
%update the enable status of children based on whether the given fn exists

if nargin<1;
  h = gcbo;
end
children = get(h,'children');  %get list of all sub-menus

fig = findparent(h);
if ~isempty(fig);
  parenttag = get(fig,'tag');
else
  parenttag = '';
end

for j=1:length(children);
  %run through each and, if it appears to be a send to item, enable/disable
  %as appropriate
  item = get(children(j),'userdata');
  if isfield(item,'fn')
    if strcmpi(item.fn,parenttag)
      %do not show item if parent tag is same as this function name
      vis = 'off';
    else
      vis = 'on';
    end
    if exist(item.fn,'file')
      en = 'on';
    else
      en = 'off';
    end
    set(children(j),'enable',en,'visible',vis);
  end
end

%----------------------------------------------------
function h = findparent(h)

while ~isempty(h) & ishandle(h) & h~=0 & ~strcmp(get(h,'type'),'figure')
  h = get(h,'parent');
end
if ~isempty(h) & (~ishandle(h) | h==0)
  %if not a handle or the base object, return EMPTY
  h = [];
end

%----------------------------------------------------
function processlink(varargin)
% (item,data)
data = varargin{1};
if nargin>1
  item = varargin{2};
else
  item = get(gcbo,'userdata');
end

if ~item.shareddata & isshareddata(data)
  %if we're NOT allowed to pass shared data and this happens to be shared
  %data, extract object now
  data = data.object;
end

%actual methods to call shortcuts
switch item.method
  case 'drop'
    h = feval(item.fn);
    feval(item.fn,'drop',h,[],guidata(h),data);

  case 'input'
    feval(item.fn,data);
    
end


  
