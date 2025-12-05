function varargout = linkshareddata(source,action,dest,mycallback,userdata)
%LINKSHAREDDATA - Manage links to shared data objects.
% Adds, removes, and locates links between a shared data object and a
% graphical objects and/or another shared data objects.
%
% INPUTS:
%   source     - source shared object.
%   action     - ['add' | 'addsymmetric' | 'remove' | 'list' | 'find']. 
%                   'add' : adds link to source from dest. Must include
%                           'dest' and 'mycallback' inputs.
%          'addsymmetric' : adds link to source from dest and link back
%                           from source to dest. Requirements same as with
%                           'add' plus, dest must be a shared data object.
%                'remove' : disconnects link from dest from source.
%             'removeall' : disconnects all links on source handle.
%                  'list' : return a nx2 cell array list of shared data
%                           objects and names that a subscriber (handle) is
%                           linked to.
%                  'find' : return a list of all subscibers for given source.
%
% OPTIONAL INPUTS: (used only with 'add', 'addsymmetric', and 'remove' actions)
%   dest       - Destination object (handle or shared data object) to link
%                  to source. 
%   mycallback - Top-level function for update to shared data. Callbacks
%                  should be in the form of:
%                    myfunction('updateshareddata',dest,myobj,keyword,userdata)
%                  where 'myobj' is the updated shared data and
%                    myfunction('propupdateshareddata',dest,myobj,keyword,userdata)
%   userdata   - additional data to send with 'mycallback'
%
%I/O: linkshareddata(source,action,dest,mycallback,userdata)
%
%* Calls with shared data object passed first:
%I/O: linkshareddata(source,'add',dest,mycallback,userdata)
%I/O: linkshareddata(source,'addsymmetric',dest,mycallback,userdata)
%I/O: linkshareddata(source,'remove',dest)
%I/O: linkshareddata(source,'find')
%
%* Calls with an object handle passed first:
%I/O: linkshareddata(dest,'list')
%I/O: linkshareddata(dest,'removeall')
%
%See also: GETSHAREDDATA, REMOVESHAREDDATA, SEARCHSHAREDDATA, SETSHAREDDATA, UPDATEPROPSHAREDDATA

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%hidden action 'removeforce' : used only by removeshareddata to avoid recursion

if nargin<1;
  source = 'io';
end

if ischar(source) && ismember(source,evriio([],'validtopics'));
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,source,options); else; varargout = evriio(mfilename,source,options); end
  return;
end

if nargin<4;
  mycallback = '';
end
if nargin<5
  userdata = [];
end

%- - - - - - - - - - - - - - - - - - - - - - - - - 
if nargin==1 | strcmpi(action,'list')
  %input "source" will be a handle... List object names for given subscriber.
  if ~ishandle(source)
    error('Input source must be a valid object handle when action is "list".');
  end
  mydata  = getappdata(source,'linkeddata');
  names = {};
  for i = 1:length(mydata)
    if isvalid(mydata(i));
      nm = mydata(i).properties.name;
      if isempty(nm)
        nm = 'Unnamed';
      end
      nm = [nm  ' (' class(mydata(i).object) ')'];
    else
      nm = '** Deleted Object **';
    end
    names = [names; {mydata(i) nm}];
  end
  varargout{1} = names;
  return
end

%- - - - - - - - - - - - - - - - - - - - - - - - - 
if strcmpi(action,'removeall')
  %remove links to all items on a given handle
  if ~ishandle(source)
    error('Input source must be a valid object handle when action is "removeall".');
  end
  mydata  = getappdata(source,'linkeddata');
  for i = 1:length(mydata)
    linkshareddata(mydata(i),'remove',source);
  end
  return
end


%- - - - - - - - - - - - - - - - - - - - - - - - - 
%all other actions expect source to be a shareddata object
if ~isshareddata(source)
  error('First input must be a shared data object')
end

%Get parent info and find record.
parenth = source.source;
if isempty(parenth) | ~ishandle(parenth)
  mydata = [];
else
  mydata  = getappdata(parenth,'shareddata');
end
if isempty(mydata)
  %can't find data or parent
  if ~strcmpi(action,'remove') & ~strcmpi(action,'removeforce')
    %add, list or find? error
    error('Can''t find shared data for given source.')
  else
    if ishandle(dest);
      %we were just removing it anyway, ignore the error but remove from dest links
      mylink  = getappdata(dest,'linkeddata');
      keepidx = source~=mylink;
      mylink  = mylink(keepidx);
      setappdata(dest,'linkeddata',mylink);
    end
    return
  end
end
myrec  = find([mydata.id] == source);

switch lower(action)
  case {'add' 'addsymmetric'}
    %Add destination object handle/s to subscribers field in source. If
    %it's not there already.

    if isshareddata(dest)
      %is shared data
      type = 'connection';
    else
      %is handle
      type = 'subscriber';
    end
    
    subrecs   = mydata(myrec).links;  %all links
    targentry = length(subrecs)+1;
    if ~isempty(subrecs)
      %see if we should replace an existing entry
      oftype = strmatch(type,{subrecs.type});
      if any(dest == [subrecs(oftype).handle])
        targentry = oftype([subrecs(oftype).handle]==dest);
      end
    end
    
    if ishandle(dest)%dest can be handle or SDO so just double handles.
      %Fix for 2014b, non-double handles cause problems with hgsave and linking to figures.
      dest = double(dest);
    end
    
    mydata(myrec).links(targentry).type = type;
    mydata(myrec).links(targentry).handle = dest;
    mydata(myrec).links(targentry).callback = mycallback;
    mydata(myrec).links(targentry).userdata = userdata;
    setappdata(parenth,'shareddata',mydata);
    
    switch type
      case 'subscriber'
        %Save link info in destination object.
        mylink = getappdata(dest,'linkeddata');
        if isempty(mylink)
          mylink = source;
        else
          mylink(end+1)= source;
        end
        setappdata(dest,'linkeddata',mylink);
      case 'connection'
        if strcmpi(action,'addsymmetric')
          %if adding symmetric links, add source to destination too
          linkshareddata(dest,'add',source,mycallback,userdata);
        end
    end

  case {'remove' 'removeforce'}
    if ~isempty(myrec)  %if not removed already

      %Remove link from source.
      subrecs = mydata(myrec).links;
      keepidx = logical([]);
      for j=1:length(subrecs);
        keepidx(j) = subrecs(j).handle~=dest;
      end
      mydata(myrec).links = subrecs(keepidx);
      setappdata(parenth,'shareddata',mydata);

      if ishandle(dest)
        %Remove link from destination.
        mylink  = getappdata(dest,'linkeddata');
        keepidx = source~=mylink;
        mylink  = mylink(keepidx);
        setappdata(dest,'linkeddata',mylink);
      elseif isshareddata(dest)
        %remove link from other shared data
        mylink  = getshareddata(dest,'all');
        if ~isempty(mylink) & isvalid(mylink.id) & any(getlinkarray(mylink.links)==source);
          %this is linked back to item we're removing...
          try
            linkshareddata(dest,'remove',source);
          catch
          end
        end
      end

      if strcmpi(action,'remove') & parenth==dest & ~isempty(source)
        %the object unlinking itself is the owner, consider this a "remove"
        removeshareddata(source);
      end
    end
    
  case 'find'
    %Locate all subscribers for a given object
    if isfield(mydata(myrec).links,'handle')
      v = getlinkarray(mydata(myrec).links);
%       v = [];
%       for j=1:length(mydata(myrec).links);
%         v(j) = double(mydata(myrec).links(j).handle);
%       end
      varargout(1) = {v};
    else
      varargout(1) = {[]};
    end
end

%--------------------------------------------------
function v = getlinkarray(linklist)
%Make a numeric array from link objects. Helps fix 2014b change from handle
%to obj.

v = [];
for j=1:length(linklist);
  v(j) = double(linklist(j).handle);
end

