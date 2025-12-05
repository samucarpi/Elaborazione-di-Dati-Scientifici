function setpersistentconnection(obj,conn,connstr)
%EVRIDB/SETPERSISTENTCONNECTION Save evridb database connection to appdata 0.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

saved_conn = getappdata(0,'evri_persistent_db_connections');

if nargin<3
  connstr = getconnectionstring(obj);
end

if isempty(saved_conn)
  %Create new saved connection table.
  saved_conn = {connstr conn};
else
  %Check for old connection.
  myloc = ismember(saved_conn(:,1),connstr);
  
  if any(myloc)
    saved_conn{myloc,2} = conn;
  else
    saved_conn(end+1,:) = {connstr conn};
  end
end
setappdata(0,'evri_persistent_db_connections',saved_conn);
