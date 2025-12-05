function id = shareddata(varargin)
%SHAREDDATA/SHAREDDATA Create a shared data link ID.
% SHAREDDATA objects allow access to data or other object from multiple
% applications without creating additional copies of the given object.
% Various user-defined properties can also be associated with the object.
% In addition, they allow the triggering of actions (or just notification)
% whenever the object itself or its properties are modified. Each
% application wanting to be notified on changes to a shareddata object has
% a "link" to the shareddata object.
%
% Creating Shareddata:
%  Initial creation of a shareddata object is generally done by supplying 
%  a location to store the object (source) and the actual object to share
%  (object) plus optional properties:
%        id = shareddata(source,object,properties)
%
%  Shareddata objects have the following properties
%
%     .object : actual data/object contents of shareddata object
%     .links  : structure array containing linking applications
%               information. See below for linking actions.
%     .source : [Read Only] handle to graphical object in which the
%               shareddata object contents are currently stored 
%   .siblings : [Read Only] two-column cell array containing all other
%               shareddata objects stored in the same source (first column)
%               and their names (second column).
% .properties : Structure array with various predefined and user-defined
%               properties. All shareddata objects have the following
%               default properties:
%                 .timestamp    : date stamp of shareddata object creation
%                 .name         : string with optional name
%                 .removeAction : defines how to handle removing of object
%
%               Shareddata objects which contain DataSet objects also have
%               the predefined property:
%                 .selection  : cell array containing the indicies of which
%                               elements of the DataSet are currently
%                               selected in each mode {rows, columns, ...}
%
%               The user may define any other properties they need for the
%               applications using the shared data.
%
%               The "removeAction" property specifies how deletion of the
%               "source" object should be handled. If removeAction =
%               'adopt', then the shareddata object is moved from the
%               source to the next valid object in the link list.
%               Otherwise, the data is removed and all links are closed
%               with "remove" actions to callbacks (see links below).
%
%               Properties can be modified using standard indexing:
%                  id.properties.name = 'new name'
%               Note that some properties cannot be modified once initially
%               created (.timestamp, .removeAction)
%               Modifying a property normally triggers a "properties
%               update" action. However, using the fieldname
%               "propertiesquiet" instead of "properties" will silence any
%               updates. This is useful when updating both data and
%               properties when only ONE actions trigger is desired.
%
% Links:
% * Links are stored as a structure array containing the type of link (used
%   internally only), the handle of the linked application, the callback
%   function (see below), and user-defined data (userdata).
%
% * Creating links to a given shareddata object:
%       id.links.add(handle,'mycallback')
%       id.links.add(handle,'mycallback',userdata)  %w/optional userdata
%   where handle is the graphical object handle to link to, and
%   'mycallback' is a string naming the function which will manage the
%   callbacks for changes to this shareddata object. The named function
%   must allow callbacks in the form of:
%       myfunction('updateshareddata',handle,id,keyword,userdata)
%       myfunction('propupdateshareddata',handle,id,keyword,userdata)
%   where 'id' is the updated shared data, handle is the handle of the
%   linked figure, keyword is a keyword explaining what has changed, and
%   userdata is the userdata defined in the linking call (if any).
%  
% * Removing links to a given shareddata object:
%       id.links.remove(handle)
%   where handle is the graphical object handle to remove from the links.
%   If this is the last link to an object or the object has a property
%   "removeAction" as anything but 'adopt', the shareddata is deleted and
%   all other links are closed to the object.
%
% Finding Shared Data:
%   Calling Shareddata with the input of one or more figure handles (or
%   other graphical object handle) will return all shareddata objects with
%   that/those object(s) as the source. Calling with an empty matrix will
%   return all the current shared data objects in any figure.
%
%I/O: id = shareddata           %return empty object
%I/O: id = shareddata(source,obj,properties)  %assign and return object
%I/O: ids = shareddata(source)  %get all shareddata associated with source 
%I/O: ids = shareddata([])      %get all shareddata objects

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

switch nargin
  case 0
    %create shared data link object
    id.id = now+rand(1);
    id.shareddataversion = 1.0;
    id = class(id,'shareddata');
    
  case 1
    %passing a single input goes here - this is assumed to be either a
    %shareddata object itself OR a handle to a figure (or such) that we're
    %supposed to get all shared data for
    
    removeshareddata('clean');
    if isa(varargin{1},'shareddata')
      %passed a shared data object? Just return it
      id = varargin{1};
      return;
    end
    if isa(varargin{1},'matlab.ui.Figure');
      varargin{1} = double(varargin{1});
    end
    if ~isnumeric(varargin{1})
      error('Unrecognized input format')
    end
    switch length(varargin{1})
      case 0
        %empty value - get ALL shared data objects
        list = getappdata(0,'shareddatalookup');
        if ~isempty(list)
          id = [list.item];
        else
          id = shareddata;
          id = id([]);
        end
      case 1
        %single handle
        if ~ishandle(varargin{1})
          id = shareddata;
          id = id([]);
        else
          list = getshareddata(varargin{1});
          if ~isempty(list)
            id = [list{:,1}];
          else
            id = shareddata;
            id = id([]);
          end
        end
      otherwise
        %vector or matrix? create vector of shared data objects
        varargin{1} = varargin{1}(ishandle(varargin{1}));
        id = shareddata;
        for j=1:length(varargin{1})
          id = [id;shareddata(varargin{1}(j))];
        end
    end
    
  otherwise
    %call setshareddata directly (it will return an ID from a null call here)
    id = setshareddata(varargin{:});
    
end

