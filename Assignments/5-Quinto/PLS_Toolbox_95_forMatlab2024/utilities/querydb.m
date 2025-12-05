function out = querydb(connstr, sqlstr, options)
%QUERYDB Executes a query (sqlstr) on a database defined by connection string (connstr).
%  This function is unsupported and is meant as a "simple" database
%  connection tool. For more sophisticated connection tools and full
%  support please see the Matlab Database Toolbox.
%
%  INPUTS:
%     connstr : A connection string or a structure created using
%               builddbstr. See BUILDDBSTR for more information.
%               
%      sqlstr : A SQL statement to be executed on the connection. The SQL
%               statement must be of proper syntax or it will fail. Default
%               behavior is geared toward SELECT statements that return
%               values. If attempting to execute a SQL command that doesn't
%               return a value (e.g., CREATE TABLE) set the 'rtype' option
%               to 'none'.
%               NOTE: Use a separate program like Microsoft Access to
%               formulate the SQL statement. Access queries can require
%               some small changes in syntax. 
%
%  OPTIONS:
%           rtype : [{'dso'} | 'cell' | 'insert' |'none'] Return type, 
%                   default is return SQL recordset as a DataSet Object
%                   using parsemixed.m to parse data in. If 'cell' then a
%                   cell array is returned with all values. If 'insert'
%                   then function will execute an "INSERT" type query and
%                   attempt to return the Auto Number ID (as a scalar) of
%                   the row created. If 'none' function will execute query
%                   and return an empty.
%       varlabels : [ {'none'} | 'fieldnames' ] Defines what should be used
%                   as variable labels on output DataSet Object (only used
%                   when rtype is 'dso'). 'fieldnames' uses the SQL field
%                   names for variable labels. 
%        conntype : [ 'jdbc' | {'odbc'} ] Determines type of connection. 
%                   ODBC uses a Windows ADO with Matlab (descibed above).
%                   JDBC connections only work when jdbc class files are on
%                   static java path.
% getaccesstables : [ 'on' | {'off'} ] Short circuit to retrieve list of
%                   tables in Access database, similar to SHOW TABLES query
%                   in MySQL. Input 'sqlstr' will not be called when
%                   option is 'on'.
% getaccessfieldnames : [''] Short circuit to retrieve list of tables
%                       fieldnames. Input should be valid table name (string).
%
%  OUTPUT:
%         out : DataSet Object, Cell Array, or Scalar depending on 'rtype'.
%
%I/O: dso = querydb(connstr, sqlstr);
%I/O: cellarray = querydb(connstr, sqlstr, options);
%
%See also: BUILDDBSTR, PARSEMIXED

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%
%RSK 05/03/2006

if nargin<1; connstr = 'io'; end
if isa(connstr,'char') & ismember(connstr,evriio([],'validtopics'));
  options = [];
  options.rtype = 'dso';
  options.varnames = 'none';
  options.conntype = 'odbc';
  options.getaccesstables = 'off';
  options.getaccessfieldnames = '';
  if nargout==0; clear out; evriio(mfilename,connstr,options); else; out = evriio(mfilename,connstr,options); end
  return;
end

%Check inputs.
if nargin < 2
  error('QUERYDB requires at least 2 inputs.');
elseif nargin < 3
  options = querydb('options');
else
  options = reconopts(options,querydb('options'));
end

if isstruct(connstr)
  %If connection string is a structure then use builddbstr to make a
  %connection string out of it.
  if isfield(connstr,'jdbc') && strfind(lower(connstr.driver),'jdbc')
    connstr = builddbstr(connstr,struct('isodbc',0));
  else
    connstr = builddbstr(connstr);
  end
end

cn=[];

%Try connection.
try
  if strcmp(options.conntype,'odbc')
    %ADO connection object.
    cn = actxserver('ADODB.Connection');
    %Open connection.
    cn.Open(connstr);
  elseif strcmp(options.conntype,'jdbc')
    %NOTE: This code only works for classes on the static java class path. 
    import java.sql.*
    import java.lang.*
    cloader = java.lang.ClassLoader.getSystemClassLoader;%Specify loader.
    java.lang.Class.forName('com.mysql.jdbc.Driver',true,cloader);%Create driver class.
    cn = DriverManager.getConnection(connstr);
%   elseif strcmp(options.conntype,'oracle')
%     import java.sql.*
%     import java.lang.*
%     import oracle.jdbc.*
%     import oracle.jdbc.pool.*
%     cloader = java.lang.ClassLoader.getSystemClassLoader;%Specify loader.
%     java.lang.Class.forName('oracle.jdbc.driver.OracleDriver',true,cloader);%Create driver class.
%     cn = DriverManager.getConnection(connstr);
  end
catch
  %Get last error.
  myerror = lasterr;

  %Try closing and deleting whatever was created.
  closeconnection(cn)
  error(['QUERYDB could not establish connection. Check connection string. ' myerror]);
end

%Intercept call to SHOW TABLES for Access databases.
if strcmp(options.getaccesstables,'on')
  out = getaccesstables(cn,options);
  closeconnection(cn)
  return
end

%Intercept call to SHOW COLUMNS for Access databases.
if ~isempty(options.getaccessfieldnames)
  out = getaccessfieldnames(cn,options);
  closeconnection(cn)
  return
end

%Try executing the sql command.
try
  if strcmp(options.conntype,'odbc')
    temp = cn.Execute(sqlstr); %Create recordset from query.
    if strcmp(options.rtype,'none')
      %Not a return query (e.g., UPDATE) so don't return a value.
      ctemp = {};
    elseif strcmp(options.rtype,'insert')
      %INSERT query.
      try
        %Try to get last id from auto-increment ID value.
        ctemp = cn.Execute('SELECT LAST_INSERT_ID();');
        ctemp = ctemp.GetRows;
        %Should be a number.
        ctemp = str2num(ctemp{:});
      catch
        ctemp = {};
      end
    else
      ctemp = temp.GetRows;
      ctemp = ctemp'; %Need to transpose.
    end
    temp.Close;
  elseif strcmp(options.conntype,'jdbc')
    ctemp = javaqry(cn,sqlstr,options);
  end
catch
  error(['QUERYDB could not execute SQL string, check syntax. ' lasterr]);
  try
    temp.Close;
  end
  closeconnection(cn)
  return
end

if strcmp(options.rtype,'dso') & ~isempty(ctemp)
  try
    %Try pasemixed, return a cell if it bombs out.
    out = parsemixed(ctemp);

    %Try findsqlfields to extract variable names and use them in the dso.
    if strcmp(options.varnames,'fieldnames')
      varnames = findsqlfields(sqlstr);
      if ~isempty(varnames)
        try
          out.label{2} = varnames;
        catch
          warning('EVRI:QuerydbVarnames','Unable to add variable names to DSO.')
        end
      end
    end
  catch
    warning('EVRI:QuerydbParseFailure','QUERYDB unable to use parsemixed on SQL output. Results being returnted in cell array.');
    out = ctemp;
  end
else
  out = ctemp;
end

%Close connection and delete.
closeconnection(cn)

%---------------------------------------
function outcell = javaqry(cn,sqlstr,options)
%Run query with jdbc and return a cell of results.
try
  stmt = cn.createStatement;
  if strcmp(options.rtype,'none')
    %Not a return query (e.g., UPDATE) so don't return a value.
    stmt.executeUpdate(sqlstr);
    outcell = {};
  elseif strcmp(options.rtype,'insert')
    %INSERT query, try to get insert row ID from auto increment.
    stmt.executeUpdate(sqlstr);
    try
      outcell = stmt.getLastInsertID;
    catch
      outcell = {};
    end
  else
    rs = stmt.executeQuery(sqlstr);

    %Column info
    cols = {};
    strcols = [];
    numcols = [];
    for i = 1 : rs.getMetaData.getColumnCount
      cols{i,1} = char(rs.getMetaData.getColumnName(i));
      temptype = char(rs.getMetaData.getColumnClassName(i));
      %Make lists of string and numeric columns.
      if ~isempty(strfind(temptype,'String')) | ~isempty(strfind(temptype,'Date'))
        %Sting and date columns will be read in as strings.
        strcols = [strcols i];
      else
        %Assume everything else is a numeric column, replace any value that
        %can't be double with NaN.
        numcols = [numcols i];
      end
    end

    %Rows
    rs.last;
    numrows = rs.getRow;

    %Read data into cell array.
    %This is a slow process.
    %TODO: should be able to do this column wise.
    outcell = {};
    wh = waitbar(0,{['Parsing Result Set (Total Number Of Rows: ' num2str(numrows) ')'] '[close this window to return]'});

    for i = 1:numrows
      rs.absolute(i);%Move to row 'i'.
      for j = strcols
        outcell{i,j} = char(rs.getString(j));
      end
      for j = numcols
        try
          outcell{i,j} = double(rs.getDouble(j));
        catch
          %Replace value that couldn't be converted to double with NaN.
          outcell{i,j} = NaN;
        end
      end
      if rem(numrows,10)==0
        waitbar(i/numrows,wh)
        if ~ishandle(wh)
          rs.close
          stmt.close
          cn.close
          return
        end
      end
    end
    waitbar(1,wh)
    close(wh)
  end
catch
  myerror = lasterror;
  try
    close(wh);
  end
  try
    rs.close
  end
  try
    stmt.close
  end
  rethrow(myerror)
end

%Connection closed in main function.
try
  rs.close
end
try
  stmt.close
end

%---------------------------------------
function outcell = getaccesstables(cn,options)
%Get list of tables from Access database. Similar to SHOW TABLES in MySQL.

cat = actxserver('ADOX.Catalog');
cat.ActiveConnection = cn;

outcell = '';

for i = 0:cat.Tables.count-1;
  if strcmp(cat.Tables.Item(i).Type,'TABLE')
    outcell = [outcell; {cat.Tables.Item(i).Name}];
  end
end

cat.delete

%---------------------------------------
function outcell = getaccessfieldnames(cn,options)
%Get list of field names from Access table. Similar to SHOW COLUMNS in MySQL.

cat = actxserver('ADOX.Catalog');
cat.ActiveConnection = cn;

outcell = '';

for i = 0:cat.Tables.count-1;
  if strcmp(cat.Tables.Item(i).Name,options.getaccessfieldnames)
    %Found table, pull out columns.
    for j = 0:cat.Tables.Item(i).Columns.Count-1
      outcell = [outcell; {cat.Tables.Item(i).Columns.Item(j).Name}];
    end
  end
end

cat.delete

%---------------------------------------
function closeconnection(cn)
%Close a jdbc or ado connection.
try
  cn.close
end
try
  %Some ADO is case sensitive upper.
  cn.Close
end
try
  cn.quit
end
try
  cn.delete
end



