function varargout = searchshareddata(source,action,propsin,iscurrent)
%SEARCHSHAREDDATA - Search properties of shared data.
%
%
% INPUT:
%   source     - Shared data object or parent figure handle.
%   action     - ['list'|'find'|'get'|'getval'|'query'] actions that can be
%                performed.
%                   list      - list all properties for a given source, output
%                               is a cell array of strings.
%
%                                 propsList = searchshareddata(sdObject,'list');
%
%                   find      - find all sources on a given parent with a
%                               given property**, output is a nx2 cell array
%                               with id in first column and prop value in
%                               second.
%                               
%                                 itmes = searchshareddata(figHandle,'find','itemType');
%
%                   get       - get properties structure for given sourceID.
%                               
%                                 propsStruct = searchshareddata(sdObject,'get');
%                                 propsStruct = sdObject.properties;%Same as above. 
%
%                   getval    - find the value of a given property** for a given
%                               source, ouput is a single value.
%
%                                 propVal = searchshareddata(sdObject,'getval','itemType');
%
%                   query     - find sources of a given parent where all
%                               properties in propsin exist and are equal,
%                               output is a shareddeddata array.
%
%                                 searchProps.itemReadOnly = 0;
%                                 sdObjectArray = searchshareddata(figHandle,'query',searchProps);
%
%                   querydata - return shareddata of a given parent where all
%                               properties in propsin exist and are equal,
%                               if more than one valid data object then
%                               error.
%
%                                 searchProps.itemReadOnly = 0;
%                                 sdObjectArray = searchshareddata(figHandle,'query',searchProps);
%                                 %error if more than one item found.
%
%                   ** = 'propsin' can only be a string for a single field name.
%
%   propsin    - [string | structure] depending on 'action' (see above).
%
%   iscurrent  - [1 | 0] if passed, use 'itemIsCurrent' property field in
%                conjunction with propsin.
%
%  OUTPUTS:
%   out       - Depends on input.
%
%I/O: out = searchshareddata(source,action,propsin,iscurrent)
%I/O: out = searchshareddata(sourceID,'list');              % return cell array of strings with property field names.
%I/O: out = searchshareddata(handle,'find','property');     % return nx2 cell array of objects with given property
%I/O: out = searchshareddata(sourceID,'get');               % return a structure of all information
%I/O: out = searchshareddata(sourceID,'getval','property'); % return value of given property
%I/O: out = searchshareddata(handle,'query',propsin,iscurrent); % return one or more shared data object/s.
%I/O: out = searchshareddata(handle,'querydata',propsin,iscurrent); % 'out' is shared data.
%
%See also: GETSHAREDDATA, LINKSHAREDDATA, REMOVESHAREDDATA, SETSHAREDDATA, UPDATEPROPSHAREDDATA

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1;
  action = 'io';
end
if nargin==1
  %Assume evriio call.
  action = source;
end
switch lower(action)
  case {'list' 'find' 'get' 'getval' 'query'}
    if nargin<4
      iscurrent = [];
    end
    if nargin<3
      propsin = '';
    end

    myprops = [];

    %Get parent handle.
    if ishandle(source)
      parenth = source;
    else
      parenth = getshareddata(source,'handle');
    end

    %Find shared data on source.
    mydata = getappdata(parenth,'shareddata');
    if isempty(mydata)
      %warning('Can''t find shared data for given source.')
      varargout{1} = [];
      return
    end

    if ~ishandle(source)
      %Get properties.
      myrec = find([mydata.id] == source);

      if ~isempty(myrec)
        myprops = mydata(myrec).properties;
      end
    end
end

switch lower(action)
  case 'list'
    %List all properties for given souce.
    if ~isempty(myprops)
      myfields = fieldnames(myprops);
    else
      myfields = '';
    end
    varargout{1} = myfields;
    
  case 'find'
    %Find all data objects for given parent with property listed in
    %'propsin' input.
    myvals = '';
    for i = 1:length(mydata)
      if isfield(mydata(i).properties,propsin)
        myvals = [myvals; {mydata(i).id mydata(i).properties.(propsin)}];
      end
    end
    varargout{1} = myvals;
    
  case 'get'
    %Get properties structure for given sourceID.
    varargout{1} = myprops;
    
  case 'getval'
    %Get value of property.
    if ~isempty(myprops) && isfield(myprops,propsin)
      val = myprops.(propsin);
    else
      val = [];
    end
    varargout{1} = val;
    
  case 'query'
    %Get all data objects for given properties with equal values.
    myids = {};
    if isempty(propsin)
      %If searching for empty then return all IDs for given handle.
      varargout{1} = [mydata.id];
      return
    end
    
    if ~isstruct(propsin)
      myitem = propsin;
      propsin = [];
      propsin.itemType = myitem;
    end

    if ~isempty(iscurrent) && ~isfield(propsin,'itemIsCurrent')
      propsin.itemIsCurrent = iscurrent;
    end

    for i = 1:length(mydata)
      status = isrecord(mydata(i).properties,propsin);
      if status
        myids{end+1} = mydata(i).id;
      end
    end
      myids = [myids{:}];
    varargout{1} = myids;

  case 'querydata'
    if nargin<4
      iscurrent = [];
    end
    myids = searchshareddata(source,'query',propsin,iscurrent);
    if isempty(myids)
      varargout{1} = {};
    end
    if length(myids)>1
      error('More than one shared data object found for given handle.')
    end
    varargout{1} = getshareddata(myids);
    

  case evriio([],'validtopics')
    %evriio here so doesn't get called every time to speed things up.
    options = [];
    if nargout==0; clear varargout; evriio(mfilename,action,options); else; varargout = evriio(mfilename,action,options); end
    return;

end

%----------------------------------------------
%local fast comparison
function out = isrecord(a,b)

out = false;   %start off assuming there will be a difference

bfyld = fieldnames(b);  %get fields we're searching for

for j=1:length(bfyld)
  if ~isfield(a,bfyld{j})
    %doesn't exist in "a"? exit now with false
    return
  end

  %get values for both fields
  afv = a.(bfyld{j});
  bfv = b.(bfyld{j});
  
  %if not character or numeric, use comparevars on THIS field ONLY
  if ischar(bfv) 
    if ~ischar(afv) | ~strcmp(bfv,afv);
      return
    end
  elseif isnumeric(bfv)
    if ~isa(afv,class(bfv)) | ndims(afv)~=ndims(bfv) | any(size(afv)~=size(bfv)) | any(afv~=bfv)
      return;
    end
  else
    if ~comparevars(afv,bfv);
      %not the same? exit now with "false"
      return
    end
  end
end

%we ONLY make it here if nothing triggered the "stop" sign
out = true;
    
    

