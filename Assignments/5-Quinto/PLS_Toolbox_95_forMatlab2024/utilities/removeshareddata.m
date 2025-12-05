function varargout = removeshareddata(source,action)
%REMOVESHAREDDATA Remove shared data object from source and all links.
%
%  INPUTS:
%    source     - Source id number or parent object handle (Note: if source = handle then automatically use remove 'all').
%    action     - [{'standard'}* | 'all' | 'adopt' | 'clean'] (optional)
%                 standard - remove only source (source ID) and its links from given parent.
%                 all      - remove all sources and links for given (parent) handle.
%                 adopt    - remove only source and adopt out shared data
%                            to next existing subscriber (making it the new source).
%                 clean    - checks lookup table and removes nonexistent sources.
%
%  * NOTE: If only 'source' is given as input then 'removeAction' property
%          will be used if it exists.
%
%
%I/O: removeshareddata(source)
%I/O: removeshareddata(source,removeall)
%
%See also: GETSHAREDDATA, LINKSHAREDDATA, SEARCHSHAREDDATA, SETSHAREDDATA, UPDATEPROPSHAREDDATA

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1;
  source = 'io';
end

if (ischar(source) & strcmp(source,'clean')) | (nargin>1 & strcmp(action,'clean'))
  cleansource;
  return
end

if isa(source,'char');
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,source,options); else; varargout = evriio(mfilename,source,options); end
  return;
end

if nargin<2
  action = 'standard';
end

%Get parent info.
if ishandle(source)
  parenth = source;
  action  = 'all';
  source = [];
else
  parenth = getshareddata(source,'handle');
end

if isempty(parenth) | ~ishandle(parenth)
  %no parent found or non-valid parent? forget about it
  return
end

mydata = getappdata(parenth,'shareddata');
if isempty(mydata)
  warning('EVRI:ShareddataNotFound','Can''t find shared data for given source.')
  return
end

if ~isempty(source)
  %as long as we have a specific item to remove, check it's remove action
  myadopt = searchshareddata(source,'getval','removeAction');
  if nargin<2 && ~isempty(myadopt)
    action = myadopt;
  end
end

switch lower(action)
  case {'standard'}
    %Remove a single source and all linked data.
    myrec  = ([mydata.id] == source);
    if ~any(myrec)
      %Can't find any linked data so just return.
      return
    end

    %Remove links and call update with keyword.
    links = mydata(myrec).links;
    for i = 1:length(links)
      linkshareddata(source,'removeforce',links(i).handle)
      %Call update function with 'delete' keyword.
      feval(links(i).callback,'updateshareddata',links(i).handle,mydata(myrec),'delete',links(i).userdata)
    end

    %Remove source from parent. (we get the data again here in case one of
    %the "delete" callbacks removed the data already)
    mydata = getappdata(parenth,'shareddata');
    myrec  = ([mydata.id] == source);
    setappdata(parenth,'shareddata',mydata(~myrec));

    %Remove record from lookup table.
    lutable = getappdata(0,'shareddatalookup');
    lutable([lutable.item] == source) = [];
    setappdata(0,'shareddatalookup',lutable);

  case {'adopt'}
    %Remove a single source and all linked data.
    myrec  = ([mydata.id] == source);
    if ~any(myrec)
      %Can't find any linked data so just return.
      return
    end

    %Try to add data to viable subscriber.
    links = mydata(myrec).links;
    subscribers = [links.handle];
    newowner = subscribers(min(find(ishandle(subscribers) & subscribers~=parenth)));
    if ~isempty(newowner)
      setshareddata(source,newowner);
    else
      %Remove record from lookup table.
      lutable = getappdata(0,'shareddatalookup');
      lutable([lutable.item]==source) = [];
      setappdata(0,'shareddatalookup',lutable);
    end

    %Remove source from parent.
    setappdata(parenth,'shareddata',mydata(~myrec));

  case 'all'
    %Loop through all data objects in source and remove each one with
    %recursive call.
    for i = 1:length(mydata)
      removeshareddata(mydata(i).id,'standard');
    end
    cleansource
end

%-----------------------------------------------
function cleansource()
%Clean dead IDs (and handles) from lutable.

lutable = getappdata(0,'shareddatalookup');

keepids = [];
for i = 1:length(lutable)
  fig = lutable(i).source;
  if ishandle(fig)
    figdata = getappdata(fig,'shareddata');
    %Valid IDs still available for given fig.
    if ~isempty(figdata)
      keepids = [keepids double([figdata.id])];
    end
  end
end

lutable = lutable(ismember(double([lutable.item]),keepids));
setappdata(0,'shareddatalookup',lutable);

