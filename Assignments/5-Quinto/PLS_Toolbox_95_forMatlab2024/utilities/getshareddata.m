function myobj = getshareddata(source,action)
%GETSHAREDDATA - Retrieve shared data from a source.
%
%  INPUTS:
%    source - Shared data object or parent figure handle (Note: if source = handle then action = 'list').
%    action - [ {''} | 'handle' | 'list' | 'all' | 'private'] 
%               'handle' : returns handle to parent of shared data
%                 'list' : returns list all shared objects for given parent
%                          as an nx2 array. First column is ID and second
%                          column is properties.name (if present) and type.
%                  'all' : returns entire shared data object (see setshareddata).
%              'private' : returns data and silently (without notification
%                          of subscribers) clears out existing data.
%                          Requires caller to call setshareddata after
%                          modification but permits memory-friendly
%                          updating.
%
%  OUTPUTS:
%    myobj      - Stored data object.
%
%I/O: myobj = getshareddata(source,action)
%
%See also: LINKSHAREDDATA, REMOVESHAREDDATA, SEARCHSHAREDDATA, SETSHAREDDATA, UPDATEPROPSHAREDDATA

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1;
  sourceinfo = 'io';
end
if isa(source,'char');
  options = [];
  if nargout==0; clear myobj; evriio(mfilename,sourceinfo,options); else; myobj = evriio(mfilename,sourceinfo,options); end
  return;
end

if nargin<2
  action = '';
end

if isempty(source)
  %If calling with empty source, just return empty.
  myobj = [];
  return
end

%Find parent/source info.
lutable = getappdata(0,'shareddatalookup');
if ishandle(source)
  %gave handle to figure rather than ID
  action = 'list';
  parenth = source;
  if ~isempty(lutable)
    match = [lutable.source] == source;
    if ~any(match)
      %no matches
      source = [];
    else
      %one or more matches
      match = min(find(match));  %just return first
      source = lutable(match).item;
    end
  else
    source = [];
  end
elseif isshareddata(source)
  %gave shared data object ID
  if ~isempty(lutable)
    item = lutable([lutable.item] == source);
  else
    item = [];
  end
  if isempty(item)
    %no item by this ID? Probably deleted
    myobj = [];
    return
  end
  parenth = item.source;
else
  error('Source must shared data object.')
end

if isempty(parenth)
  if strcmpi(action,'list')
    myobj = '';
  else
    myobj = [];
  end
    return
elseif ~ishandle(parenth)
  myobj = [];
  return
end

switch lower(action)
  case 'id'
    
    myobj = source;
    
  case 'handle'

    myobj = parenth;

  case 'list'
    mydata = getappdata(parenth,'shareddata');
    if isempty(mydata)
      myobj = [];
      return
    end
    names = '';
    for i = 1:length(mydata)
      nm    = mydata(i).properties.name;
      if isempty(nm)
        nm = 'Unnamed';
      end
      names = [names; {mydata(i).id [nm ' (' class(mydata(i).object) ')']}];
    end
    myobj = names;

  case {'' 'all' 'private'}
    mydata = getappdata(parenth,'shareddata');
    if isempty(mydata)
      myobj = [];
      return
    end

    myrec  = find([mydata.id] == source);
    if isempty(myrec)
      myobj = [];
      return
    end
    switch action
      case 'all'
        myobj  = mydata(myrec);
      case 'private'
        myobj  = mydata(myrec).object;
        mydata(myrec).object = [];  %BLANK OUT record
        setappdata(parenth,'shareddata',mydata);
      otherwise
        myobj  = mydata(myrec).object;
    end
    
  otherwise
    error('unrecognized action')
    
end





