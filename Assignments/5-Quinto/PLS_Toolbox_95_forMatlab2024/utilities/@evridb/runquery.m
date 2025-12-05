function [out, varargout] = runquery(obj,sqlstr)
%EVRIDB/RUNQERY Run query on connection object.
% NOTE: Statement and recordsets should be closed in this function.
% Connection objects closed elsewhere.
%

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = [];
varargout = {[]};
if nargin<2 || isempty(sqlstr)
  %If no sql string provided then try to run saved string.
  sqlstr = obj.sql_string;
end

if isempty(sqlstr)
  warning('EVRI:EvridbNoSQLString','No SQL string provided.')
  return
end

conn = getconnection(obj);

%Make sure there are no extra spaces so we an determine what the first SQL
%element is, e.g., if SELECT we know we need to return a query.
sqlstr = strtrim(sqlstr);

if ismember(obj.type,obj.ms_types)
  %Check MS type connection.
  rs = conn.Execute(sqlstr); %Create recordset from query.
  if nargout ~=0
    if ~rs.EOF
      mytbl = rs.GetRows; %Cell array.
      column_names = '';
      
      try
        %Try to get field names from recordset.
        flds = rs.Fields;
        for i = 1:flds.Count
          column_names = [column_names {flds.Item(i-1).Name}];
        end
      catch
        column_names = '';
      end
      
      if ~isempty(column_names)
        %Output column names if possible.
        varargout{1} = column_names;
      end
      
      if strcmp(obj.use_column_names,'no')
        %Don't put column names in data.
        column_names = '';
      end
      
      rs.Close;
      mytbl = mytbl'; %Need to transpose.
      out = makedso(obj, mytbl, sqlstr, column_names);
    else
      out = {};
    end
  end
else
  
  %Run query with jdbc and return a cell of results.
  try
    %TODO: Could cache statement object here to be reused.
    
    %Want static result set. Updates done with SQL (text) via statement.execute
    %and not on recordset object so don't need to update the result set
    %after it's been queried so use CONCUR_READ_ONLY for safety.
    %
    %TYPE_SCROLL_INSENSITIVE
    %A cursor that can be used to scroll in various ways through a
    %ResultSet. This type of cursor is insensitive to changes made to the
    %database while it is open. It contains rows that satisfy the query
    %when the query was processed or when data is fetched.
    %CONCUR_READ_ONLY
    %A ResultSet that can only be used for reading data out of the
    %database. This is the default setting.
    %http://publib.boulder.ibm.com/infocenter/iseries/v5r3/index.jsp?topic=/rzaha/rsltchar.htm
    
    stmt = conn.createStatement(java.sql.ResultSet.TYPE_SCROLL_INSENSITIVE,java.sql.ResultSet.CONCUR_READ_ONLY);
    stmt.setFetchSize(100);%Can help with speed but doesn't seem to have a big impact.
    %Semicolon becomes syntax error in derby (maybe for other java dbs).
    if strcmp(obj.type,'derby')&&strcmp(';',sqlstr(end))
      sqlstr(end) = '';
    end
    
    %Determine type of sql statement so know if we want keys back.
    sqltype = lower(strtok(sqlstr,' '));
    if ismember(sqltype,{'insert' 'update'})
      isreturn = stmt.execute(sqlstr,stmt.RETURN_GENERATED_KEYS);%
    else
      isreturn = stmt.execute(sqlstr);%Returns true if there's a return result.
    end
    
    if nargout ~= 0
      switch sqltype
        case 'insert'
          try
            %Try to retun last ID.
            keyrs = stmt.getGeneratedKeys;
            if ~isempty(keyrs)
              keyrs.last;
              out = keyrs.getInt(1);
              keyrs.close;
            end
          catch
            try
              keyrs.close;
            end
            out ={};
          end
        case 'update'
          try
            %Return count of rows affected.
            out = stmt.getUpdateCount;
            %MySQL has stmt.getLastInsertID; but we should use universal
            %jdbc calls.
          catch
            out = {};
          end
          %No rs so just close stmt.
          stmt.close;
        otherwise
          %Return the record set if there is one.
          if isreturn
            %Parse the record set.
            rs = stmt.getResultSet;
            
            %Column info
            cols = {};
            %strcols = [];
            %numcols = [];
            
            outcell = {};
            for i = 1 : rs.getMetaData.getColumnCount
              cols{i,1} = char(rs.getMetaData.getColumnName(i));
              clh = org.apache.commons.dbutils.handlers.ColumnListHandler(i);
              try
                rs.beforeFirst;%Rewind (shold work for all jdbc).
              catch
                try
                  rs.absolute(0);%Rewind resultset (works for derby).
                catch
                  try
                    rs.first;%Rewind (works for mysql j connector).
                  end
                end
              end
              thiscol = clh.handle(rs);
              thiscol = cell(thiscol.toArray);
              if obj.decode_columns
                thiscol = decode_column(thiscol);
              end
              outcell = [outcell thiscol];
            end
            
            %Close in order, rs then stmt.
            rs.close
            stmt.close
            out = makedso(obj, outcell, sqlstr,cols');
            if isempty(out)
              %Need to do this because dbutils doesn't add an empty. Remove
              %this if dbuitils doens't work out.
              out = {[]};
            end
          else
            %No recordset return result create,alter,drop... but user still
            %wants an ouput so try to give them rows affected count.
            try
              %Return count of rows affected.
              %stmt.getGeneratedKeys;
              %newid = stmt.getInt(1);
              out = stmt.getUpdateCount;
              %MySQL has stmt.getLastInsertID; but not using it here.
            catch
              out = {};
            end
            %No rs so just close stmt.
            stmt.close;
          end
      end
    end
  catch
    %Get last error.
    le = lasterror;
    %Make sure all objects are closed.
    try
      rs.close;
    end
    try
      stmt.close;
    end
    %     try
    %       if ishandle(wh)
    %         waitbar(1,wh)
    %         close(wh)
    %       end
    %     end
    
    try
      if strfind(le.message,'Encountered ";"')
        %Probably a semicolon problem.
        disp(['SQL statement may have syntax error related to ";" at the end of a statement. '...
          'Derby and possibly other jdbc systems do not tolerate ";" terminators.']);
      end
    end
    %Rethrow le.
    rethrow(le);
  end
end

%Respects .presistent field.
closeconnection(obj,conn);

%------------------------------------------
function mydso = makedso(obj, incell, sqlstr, column_names)
%MAKEDSO Make DSO from cell array.
mydso = incell;
if isempty(incell)
  return
end
varnames = [];
if strcmp(obj.use_column_names,'yes')
  if isempty(column_names)
    %If we didn't get column names then try to find them in sql statement.
    varnames = findsqlfields(sqlstr);
  else
    varnames = column_names;
  end
  %Append varnames to top of incell and parsemixed should figure it out but
  %don't make it a fatal error if the concat doesn't work.
  try
    incell = [varnames;incell];
  end
end

if strcmp(obj.return_type,'dso')
  try
    %Try pasemixed, return a cell if it bombs out.
    mydso = parsemixed(incell);
  catch
    warning('EVRI:EvridbSQLOutputParse','QUERYDB unable to use parsemixed on SQL output. Results being returned in cell array.');
    mydso = incell;
  end
else
  %Cell array.
  if strcmp(obj.use_column_names,'yes') && ~isempty(varnames)
    try
      mydso = [varnames;mydso];
    catch
      warning('EVRI:EvridbVarNames','Unable to add variable names to output.')
    end
  end
  
end

%------------------------------------------
function newcol = decode_column(mycol)
%Decode column from Java data type to string.
%NOTE: May need to add more than just .toString if we come accross other
%datatypes that need special handling.

newcol = mycol;

if isempty(mycol);
  return
end

fval = mycol{1};%First value.

if isjava(fval)
  mytype = class(fval);
else
  return
end

%Prealocate for speed.
newcol = cell(length(mycol),1);

%Try to convert to string. Numeric values should have been converted by
%ColumnListHandler toArray and Matlab.
myerr = 0;%Only show one warning per column.
for i = 1:length(mycol)
  try
    newcol{i} = char(mycol{i}.toString);
  catch
    myerr = 1;
  end
end

if myerr
  warning('EVRI:EvridbQueryRecordset','There was an error changing query recordset to string. Check column datatype in table.')
end
