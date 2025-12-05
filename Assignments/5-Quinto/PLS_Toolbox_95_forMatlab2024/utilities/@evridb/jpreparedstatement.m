function out = jpreparedstatement(obj,sqlstr,vals,datatypes)
%EVRIDB/JPREPAREDSTATEMENT Bulk data manipulation via jdbc prepared statement in batch mode.
% The 'out' output is only the last ID (key) affected.
% INPUTS:
%   obj       - A evridb object.
%   sqlstr    - Should be in the form of "INSERT INTO table_name (col1, col2, col3, col3, ...) VALUES (?, ?, ?, ?,...)"
%   vals      - Cell array of values to insert.
%   datatypes - Cell array of strings datatypes {'String' 'String' 'BigDecimal' 'Int' ...}
%               must match the table definition.
%
% NOTE: Only tested with insert.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%TODO: Allow multiple keys to be returned. This works in ML 2007b (I think) and newer but not in older versions.
%TODO: Make this work for all types of statements including SELECT.

out = [];
conn = getconnection(obj);

getkeys = 0;
sqltype = lower(strtok(sqlstr,' '));
if ismember(sqltype,{'insert' 'update'})
  %Assume key IDs are wanted as outoput. Assume these keys are in first
  %"ID" column. May want to add additional inputs to function to specify
  %this.
  getkeys = 1;
end

try
  %Semicolon becomes syntax error in derby (maybe for other java dbs).
  if strcmp(obj.type,'derby')&&strcmp(';',sqlstr(end))
    sqlstr(end) = '';
  end
  
  if getkeys
    stmt = conn.createStatement(java.sql.ResultSet.TYPE_SCROLL_INSENSITIVE,java.sql.ResultSet.CONCUR_READ_ONLY);
    pst = conn.prepareStatement(sqlstr,stmt.RETURN_GENERATED_KEYS);
  else
    pst = conn.prepareStatement(sqlstr);
  end
  
  conn.setAutoCommit(false);
  
  for i = 1:size(vals,1) %rows
    for j = 1:size(vals,2) %cols
      val = vals{i,j};
      if isnan(val)
        pst.setNull(j,java.sql.Types.DOUBLE);
      else
        pst.(['set' datatypes{j}])(j,val);
      end
    end
    pst.addBatch;
  end
  pst.executeBatch;
  conn.commit;
  conn.setAutoCommit(true);
  
  if getkeys
    rs = pst.getGeneratedKeys;
  else
    rs = pst.getResultSet;
  end
  
  outcell = {};
  if strcmp(sqltype,'insert')
    for i = 1 : rs.getMetaData.getColumnCount
      %cols{i,1} = char(rs.getMetaData.getColumnName(i));
      %dt = rs.getMetaData.getColumnTypeName(i);%Slower if we need to use ismember below.
      dt = rs.getMetaData.getColumnType(i);%Use numeric datatype for speed.
      clh = org.apache.commons.dbutils.handlers.ColumnListHandler(i);
      thiscol = clh.handle(rs);
      if any(dt==[-7 -6 -5 2 3 4 5 6 7 8])
        if checkmlversion('<','7.5')
          %NOTE: 'double' function does not work on java bigdecimal
          %returned as key by jdbc in older versions of matlab (2007a and
          %older - java 1.5).
          outcell = {thiscol.get(thiscol.size-1).doubleValue};
        else
          %Numeric.
          thiscol = double(thiscol.toArray);
          outcell = [outcell num2cell(thiscol)];
        end
      else
        %Hope it gets into a string, most times it does.
        thiscol = thiscol.toArray;
        outcell = [outcell cell(thiscol)];
      end
    end
    
    out = outcell;
  else
    %UPDATE or DELETE
    
    %Don't make this a fatal error, returned info isn't always used.
    try
      %Return number of affected records.
      out = pst.getUpdateCount;
    end
  end
  
  if ~isempty(rs)
    rs.close;
  end
  
  pst.close;
  
catch
  %Get last error.
  le = lasterror;
  %Make sure all objects are closed.
  try
    if ~isempty(rs)
      rs.close;
    end
  end
  try
    pst.close;
  end
  try
    conn.setAutoCommit(true);
  end
  
  %Rethrow le.
  rethrow(le);
end

%Respects .presistent field.
closeconnection(obj,conn);


% -7	BIT
% -6	TINYINT
% -5	BIGINT
% -4	LONGVARBINARY
% -3	VARBINARY
% -2	BINARY
% -1	LONGVARCHAR
% 0	NULL
% 1	CHAR
% 2	NUMERIC
% 3	DECIMAL
% 4	INTEGER
% 5	SMALLINT
% 6	FLOAT
% 7	REAL
% 8	DOUBLE
% 12	VARCHAR
% 91	DATE
% 92	TIME
% 93	TIMESTAMP
% 1111 	OTHER
