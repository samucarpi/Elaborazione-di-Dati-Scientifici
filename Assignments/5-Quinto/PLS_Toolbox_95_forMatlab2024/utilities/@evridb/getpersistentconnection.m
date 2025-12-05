function conn = getpersistentconnection(obj,connstr)
%EVRIDB/GETPERSISTENTCONNECTION Check for saved connections.
%Both java and activex objects are referenced on copy so this should work
%as a way to preserve an open object so write operations are faster than
%opening and closing connection object continuously.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Connection is nx2 with first column as conn string and second column
%object.

conn = [];
saved_conn = getappdata(0,'evri_persistent_db_connections');
if isempty(saved_conn)
  return
end

if nargin<2
  connstr = getconnectionstring(obj);
end

myloc = ismember(saved_conn(:,1),connstr);

if any(myloc)
  conn = saved_conn{myloc,2};
else
  %No saved connections.
  return
end

%TODO: Finish and test this code.
if ismember(obj.type,obj.ms_types)
  %Check MS type connection.
  
else
  %Assume any other connection is jdbc or jdbc-like.
  if conn.isClosed
    conn = [];
  end
end
