function varargout = updatepropshareddata(source,action,propsin,keyword)
%UPDATEPROPSHAREDDATA - Make a change to shared data property and notify links.
%
%
% INPUT:
%   source     - Shared data object, or parent figure handle.
%   action     - ['add'|'remove'|'update'] actions that can be
%                performed.
%                   add    - *add one or more properties.
%                   remove - *remove one or more properties.
%                   update - *update one or more properties (same as 'add').
%
%                   *  = no output.
%
%   propsin    - if action is 'add' or 'update', propsin must be a structure
%                array with one or more fields and associated values. If
%                action is 'remove', propsin can be string or cell array to
%                act upon.
%   keyword    - (optional) argument (e.g., Sting) to pass to the update function.
%
%I/O: updatepropshareddata(source,action,propsin,keyword)
%
%See also: GETSHAREDDATA, LINKSHAREDDATA, REMOVESHAREDDATA, SEARCHSHAREDDATA, SETSHAREDDATA

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1;
  source = 'io';
end

switch lower(action)

  case {'add' 'remove' 'update'}
    %all standard calls here (faster if we catch them first)
    
    if nargin<4
      keyword = '';
    end
    if nargin<3
      propsin = '';
    end
    parenth = getshareddata(source,'handle');

    %Find shared data on source.
    if ~ishandle(parenth)
      %parent seems to have disappeared (prob. due to callback)
      varargout{1} = [];
      return;
    end
    mydata = getappdata(parenth,'shareddata');
    if isempty(mydata)
      warning('EVRI:ShareddataNotFound','Can''t find shared data for given source.')
      varargout{1} = [];
      return
    end
    myrec = find([mydata.id] == source);
    
    if ~isempty(myrec)
      myprops = mydata(myrec).properties;
    else
      error('Can not locate source ID');
    end
    
    editprops = 0;

    switch lower(action)
      case {'add' 'update'}
        if ~isstruct(propsin)
          error('Adding/updating properties to shared data must use structure as input.');
        end
        
        has_timestamp = isfield(propsin,'timestamp');
        if ~has_timestamp
          propsin.timestamp = now;
        end
        
        newfields = fieldnames(propsin);
        for i = 1:length(newfields)
          %If field already exists then it will be overwritten.
          myprops.(newfields{i}) = propsin.(newfields{i});
        end
        mydata(myrec).properties = myprops;
      
      case 'remove'
        if ~isstruct(propsin)
          if ischar(propsin)
            rfields = {propsin};
          end
        else
          rfields = fieldnames(propsin);
        end

        %do NOT allow removal of these properties
        rfields = setdiff(rfields,{'timestamp' 'removeaction' 'selection'});
        
        for i = 1:length(rfields)
          %Check to see if field exists then remove it.
          if isfield(myprops,rfields{i})
            myprops = rmfield(myprops,rfields{i});
          end
        end
        mydata(myrec).properties = myprops;
        
    end

    %Save new props.
    setappdata(parenth,'shareddata',mydata);

    if ~strcmp(keyword,'quiet')  %if not "short-circuited"
      %Pass all source info to update callback.
      for j = 1:length(mydata(myrec).links)
        if ~isempty(mydata(myrec).links(j).callback)
          feval(mydata(myrec).links(j).callback,'propupdateshareddata',mydata(myrec).links(j).handle,mydata(myrec),keyword,mydata(myrec).links(j).userdata)
        end
      end
    end

  case evriio([],'validtopics')
    %evriio here so doesn't get called every time to speed things up.
    options = [];
    if nargout==0; clear varargout; evriio(mfilename,source,options); else; varargout = evriio(mfilename,source,options); end
    return;

end


