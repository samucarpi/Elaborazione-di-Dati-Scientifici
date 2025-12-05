function myid = setshareddata(source,newobj,props)
%SETSHAREDDATA - Change/add source data and call update code for linked data.
%
%  INPUTS:
%    source     - [handle | shared data object] If adding a new shared data
%                 object, then source = handle of parent object. If setting
%                 existing data to a new object then handle should be ID
%                 number.
%    newobj     - new data object OR handle. If handle then adopt all data
%                 (and subscirbers) to new handle.
%  OPTIONAL INPUTS:
%    props      - properties structure. When "adding" new shared data,
%                 props becomes .properties field of shared data structure.
%                 If "updating" a shared data object, props is passed to
%                 the updateshareddata function.
%    keyword    - when updating shared data, this value indicates what
%                 change was made in the content. It takes the place of the
%                 PROPS input.
%
%  OUTPUTS:
%   myid        - Unique ID number of shared data object.
%
%  NOTE: When update callback function is called, the function will receive
%  entire source structure, see below:
%
% Source information structure:
%   .id        - unique id of object.
%   .object    - data object.
%   .links     - substructure containing:
%                  .type     - type of link:
%                              subscriber - viewing object.
%                              connection - shared data object connection.
%                  .handle   - handle to subscribing object.
%                  .callback - function that is called to notified when
%                              data object is updated or property is
%                              changed. The function must contain two
%                              subfunctions, 'updateshareddata' and
%                              'propupdateshareddata'. Each function will
%                              receive the handle of the subscriber and the
%                              source information structure (as defined
%                              here).
%                  .userdata - additional data to be passed to update
%                              functions.
%   .properties - struture array containging various content-specific
%                 fields
%
%I/O: myid = setshareddata(source,newobj,props)      %adding new
%I/O: myid = setshareddata(source,newobj,keyword)    %updating 
%
%See also:  GETSHAREDDATA, LINKSHAREDDATA, REMOVESHAREDDATA, SEARCHSHAREDDATA, UPDATEPROPSHAREDDATA

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1;
  source = 'io';
end
if isa(source,'char');
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,source,options); else; varargout = evriio(mfilename,source,options); end
  return;
end

if nargin<3
  props = [];
end

%Get lookup table.
lutable = getappdata(0,'shareddatalookup');

%Note: We use a lookup table in appdata 0 to make it easier to "adopt" out
%subcribers if/when needed.

%If source is a handle then add shared data. Otherwise, update.
if ishandle(source)
  %Add new shared data to a HANDLE
  myid    = shareddata;
  mydata  = getappdata(source,'shareddata');
  newrec  = length(mydata)+1;
  %Note: don't check for duplicates becuase may need to have "copies" of
  %data objects on a parent.
  
  %add content-specific properties
  switch class(newobj)
    case 'dataset'
      %dataset object
      if ~isfield(props,'selection')
        %add selection information
        props.selection = cell(1,ndims(newobj));
      end
    case 'struct'
      if isfield(newobj,'modeltype')
        %model structure
      end
    case 'shareddata'
      error('Cannot re-share a shared data object')
    otherwise
      %other items
  end
  
  %add universal properties
  props.timestamp = now;  %used to track propogation of changes
  if ~isfield(props,'name')
    props.name = '';
  end
  if ~isfield(props,'removeAction')
    props.removeAction = 'standard';
  end
  
  mydata(newrec).id          = myid;
  mydata(newrec).object      = newobj;
  mydata(newrec).links       = [];
  mydata(newrec).properties  = props;

  setappdata(source,'shareddata',mydata);

  %Update lookup table.
  newrec = struct('item',myid,'source',source);
  if isempty(lutable)
    lutable = newrec;
  else
    lutable(1,end+1) = newrec;
  end
  setappdata(0,'shareddatalookup',lutable);
  
  %Record history of this object (if enabled)
  if isdataset(newobj)
    recordchange(newobj);
  end
  
elseif isshareddata(source)
  %source is an ID, update the contents of the ID
  parenth = getshareddata(source,'handle');
  mydata  = getappdata(parenth,'shareddata');

  if isempty(mydata)
    error('Can''t find shared data for given source.')
  end

  myrec  = ([mydata.id] == source);

  if ishandle(newobj)
    %Adopt out data to new handle.
    mvdata = mydata(myrec);%Data to move.
    
    newdata  = getappdata(newobj,'shareddata');
    if isempty(newdata)
      newdata = mvdata;
    else
      newdata(end+1) = mvdata;
    end
    setappdata(newobj,'shareddata',newdata);
    
    %This is a swap of parent object and not a true removal so don't use
    %removeshareddata here.
    mydata = mydata(~myrec);%Remove it from current parent.
    setappdata(parenth,'shareddata',mydata);

    %Update lookup table.
    lutable([lutable.item]==source).source = newobj;
    
    setappdata(0,'shareddatalookup',lutable);
    
    %Remove link if needed, must do it here after lu table update or we get
    %the wrong parent.
    linkshareddata(source,'remove',parenth)
    
    myid = source;
    
  else

    %log changes
    if isdataset(newobj)
      recordchange(newobj,mydata(myrec).object);
    end
    
    %Update object.
    mydata(myrec).object = newobj;
    
    %Update the data now, then call update callback.
    setappdata(parenth,'shareddata',mydata); 

    %check for no keyword (passed as "props")
    if isempty(props)
      props = '';
    end
    if isstruct(props)
      error('Properties can only be updated through updatepropshareddata')
    end      
    keyword = props;
    
    %Pass all source info to update callback.
    keepidx= [];
    for i = 1:length(mydata(myrec).links)
      if ishandle(mydata(myrec).links(i).handle)
        if ~isempty(mydata(myrec).links(i).callback)
          feval(mydata(myrec).links(i).callback,'updateshareddata',mydata(myrec).links(i).handle,mydata(myrec),keyword,mydata(myrec).links(i).userdata);
        end
        keepidx = [keepidx 1];
      else
        %Remove nonexistent subscriber and save outside of loop.
        keepidx = [keepidx 0];%Make sure this is logical.
      end
    end
    if ~any(keepidx)
      mydata(myrec).links = mydata(myrec).links(logical(keepidx));
      setappdata(parenth,'shareddata',mydata); 
    end
    myid = source;%return same sourceid
  end
else
  error('Source must be a valid object handle.')
end

%Clean the lookup table.
removeshareddata([],'clean')

if nargout==0
  clear myid
end
