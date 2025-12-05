function varargout = setappdatas(handle,appdata,varargin)
%SETAPPDATAS Sets appdata properties for one or more object(s).
% Input (handle) is one or more valid handles {current figure will be used
% if handle is omitted} and (appdata) is either a structure with fields
% which  should be set as appdata properties of the given figure, OR a
% sequence of property/value pairs (as with a standard setappdata call) or
% by a cell array of property/value pairs.
%
% NOTE: This routine is used because, unlike SET, SETAPPDATA does not
%   allow a structure as an input, nor does it permit multiple handles to
%   be passed in. One or more objects' appdata can be copied from an old
%   handle to a new handle using:  
%     setappdatas(newobj,getappdata(oldobj))
%
%I/O:  setappdatas(handles,appdata)
%I/O:  setappdatas(handles,'property',value,'property',value,...)
%I/O:  setappdatas(handles,{'property',value,'property',value,...})
%I/O:  setappdatas(appdata)
%
%See also: SETAPPDATA

% Copyright Eigenvector Research, Inc. 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 4/2001
% jms 12/17/01 - discontinued use of fields

if nargin == 0; handle = 'io'; end
if ischar(handle);
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,handle,options); else; varargout{1} = evriio(mfilename,handle,options); end
  return; 
end

%if only one thing supplied, assume it is the appdata structure
if nargin==1;
  appdata=handle;
  handle=gcf;      %and assume we're working on the current figure
end;
if nargin>2
  appdata = [appdata varargin];
end;

if isstruct(appdata)
  %Loop through all fields and assign the value to the property
  for k=fieldnames(appdata)';
    for j=1:length(handle);
      setappdata(handle(j),k{:},getfield(appdata,k{:}));
    end
  end
elseif iscell(appdata)
  %cell array do as cell expansion into standard setappdata call
  for j=1:length(handle);
    for k=1:2:length(appdata)
      setappdata(handle(j),appdata{k:k+1});
    end
  end
else
  error('appdata must be a structure, a cell array of property/value pairs, or a sequence of property value pairs')
end
