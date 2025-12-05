function out = closeconnection(obj,conn)
%EVRIDB/CLOSECONNECTION Close persistent evrdb database connection.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = 1;
connstr = getconnectionstring(obj);

if nargin<2 || isempty(conn)
  conn = getpersistentconnection(obj,connstr);
end

if ~strcmp(obj.keep_persistent,'yes')
  if ~isempty(conn)
    try
      if isjava(conn)
        conn.close;
      else
        %Assume ADO.
        Close(conn)
      end
    catch
      warning('EVRI:EvridbCloseDB','Closing database failed, database may already be closed.')
      out = 0;
    end
  end
  %Remove record from app data.
  saved_conn = getappdata(0,'evri_persistent_db_connections');
  if isempty(saved_conn)
    return
  end
  
  myloc = ismember(saved_conn(:,1),connstr);
  
  if any(myloc)
    saved_conn(myloc,:) = [];
    setappdata(0,'evri_persistent_db_connections',saved_conn);
  end
end
