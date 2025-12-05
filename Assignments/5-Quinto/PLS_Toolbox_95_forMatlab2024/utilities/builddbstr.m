function str = builddbstr(dbstruct,options)
%BUILDDBSTR Builds a database connection string.
%  This function is unsupported and is meant as a "simple" database
%  connection tool. For more sophisticated connection tools and full
%  support please see the Matlab Database Toolbox. 
%
%  It is generally recommended that one use a Microsoft DSN (Data Source
%  Name) to establish connection on Windows platforms. These types of
%  connections tend to be easier to maintain and more secure. For more
%  information on DSN, see the Windows help entry for "ODBC". Unix
%  platforms should use JDBC, JDBC with MySQL is a "predefined" method and
%  is known to work with the MySQL JDBC 3.51 Driver.
%
%  Input can be:
%    1) A structure containing necessary information to construct one of
%       the predefined connections listed below. The output will be a
%       properly formatted connection string.
%    2) A string indicating a predefined structure to return. The output
%       will be a structure containing predefined values along with empty
%       fields that may need to be filled in. Fill in the EMPTY fields as
%       needed and the connection should work. The 'user' and 'pw' fields
%       are always present but may not be needed. This structure can be
%       passed directly to querydb.m. 
%    3) A structure with additional arg.value substructure fields necessary
%       for a connection to a non-predefined database connection. The
%       output will be a properly formatted connection string.
%
%  Input: (structure containing the following fields)
%    A connection will require one of more of the following fields. Empty
%    values are not used.
%
%    provider : only used by ADODB object so this will always be 'MSDASQL'.
%      driver : driver to be used for connection (these must be currently
%               installed on the machine, use the ODBC Manager from
%               Administrative Tools to view currently available drivers on
%               your machine. JDBC must have driver installed on Matlab
%               java class path.
%      dbname : database name (or service name).
%        user : user to connect in as, if empty not used.
%          pw : password for user, if empty not used.
%    location : Parent folder of database. Used with .dbname
%               for connecting to local Access databases
%               (parent\foler\databasename.mdb).
%      server : IP address for database (default location is 'localhost').
%         dsn : Data Source Name (set up on local computer using ODBC Manager from
%               Administrative Tools). If the database connection remains
%               static, this can be a simple way to manage the connection.
%               See the "ODBC" topic in Windows help for more information
%               on DSN.
%    arg.name : sub structure of additional arguments. This value must be a
%               sting of exactly what is required in the database 
%               connection string.
%   arg.value : sub structure of additional arguments. This value must be a
%               sting of exactly what is required in the database 
%               connection string.
%               
%         EXAMPLE: cnn.arg(1).name  = 'PORT';
%                  cnn.arg(1).value = '3306';
%                  cnn.arg(2).name  = 'SOCKET';
%                  cnn.arg(2).value = '123';
%  OPTIONS:
%       isodbc : [ {1} | 0 ] Use ODBC connection string formatting. This
%                should be set to 0 if using JDBC.
%
%  Predefined Database Connections:
%    1) Microsoft Access     : 'access'
%         Uses standard connection provided with windows (Microsoft Access
%         Driver (*.mdb)) and doesn't require UserID or PW if database
%         doesn't have them defined.
%    2) Microsoft SQL Server : 'mssql'
%         Not tested.
%    3) MySQL                : 'mysql'
%         Uses (MySQL ODBC 3.51 Driver) form mysql website. Must be
%         downloaded and installed before making connection.
%    4) Data Source Name     : 'dsn'
%         Uses a Data Source Name defined in Windows ODBC Data Source
%         Administrator dialog box. Although 'user' and 'pw' are returned
%         in the structure they are generally not needed for DSN
%         connections, this information is usually resides in the DSN
%         itself.
%    5) MySQL(JDBC)          : 'jmysql'
%         Uses (MySQL JDBC 3.51 Driver) form mysql website. Must be
%         downloaded and installed before making connection. The driver jar
%         file must be added to the Matlab java classpath.
%    6) All                  : 'all'
%         Show all available fields.
%
%    NOTE: Only DSN, MySQL, and Access have been tested and are known to
%    work. It is recommended that DSN be used when possible.
% 
%I/O: struct = builddbstr('access');%Retrieve default structure.
%I/O: connectionstring = builddbstr(dbstruct,options);%Build a connection string.
%
%See also: PARSEMIXED, QUERYDB

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%
%RSK 05/03/2006

if nargin<1; dbstruct = 'io'; end
if isa(dbstruct,'char') & ismember(dbstruct,evriio([],'validtopics'));
  options = [];
  options.isodbc = 1; %Use ODBC connection string formatting.
  if nargout==0; clear str; evriio(mfilename,dbstruct,options); else; str = evriio(mfilename,dbstruct,options); end
  return;
end

if nargin < 2
  options = builddbstr('options');
end
options = reconopts(options,'builddbstr');

if isstruct(dbstruct)
  str = makestr(dbstruct,options);
elseif ischar(dbstruct)
  str = makestruct(dbstruct);
end

%----------------------------------------------
function outstr = makestr(instruct,options)
%Make a connection string.
outstr = '';
if ispc & options.isodbc
  for i = fieldnames(instruct)'
    switch i{:}
      case 'provider'
        if isfield(instruct,'provider') & ~isempty(instruct.provider)
          outstr = [outstr 'PROVIDER=' instruct.provider ';'];
        end
      case 'driver'
        if isfield(instruct,'driver') & ~isempty(instruct.driver)
          outstr = [outstr 'DRIVER=' instruct.driver ';'];
        end
      case 'dbname'
        if isfield(instruct,'dbname') & ~isempty(instruct.dbname)
          outstr = [outstr 'DATABASE=' instruct.dbname ';'];
        end
      case 'user'
        if isfield(instruct,'user') & ~isempty(instruct.user)
          outstr = [outstr 'UID=' instruct.user ';'];
        end
      case 'pw'
        if isfield(instruct,'pw') & ~isempty(instruct.pw)
          outstr = [outstr 'PWD=' instruct.pw ';'];
        end
      case 'location'
        if isfield(instruct,'location') & ~isempty(instruct.location) & ~isempty(instruct.dbname)
          outstr = [outstr 'DBQ=' fullfile(instruct.location,instruct.dbname) ';'];
        end
      case 'server'
        if isfield(instruct,'server') & ~isempty(instruct.server)
          outstr = [outstr 'SERVER=' instruct.server ';'];
        end
      case 'dsn'
        if isfield(instruct,'dsn') & ~isempty(instruct.dsn)
          outstr = [outstr 'DSN=' instruct.dsn ';'];
        end
      case 'arg'
        if isfield(instruct,'arg') & ~isempty(instruct.arg)
          for j = 1:length(instruct.arg)
            outstr = [outstr instruct.arg(j).name '=' instruct.arg(j).value ';'];
          end
        end
    end
  end
else
  switch instruct.driver
    case 'mysql'
      %Try making a mysql jdbc connection string.
      outstr = ['jdbc:mysql://' instruct.server '/' instruct.dbname '?user=' instruct.user '&password=' instruct.pw];
    case 'derby'
      %Derby database is just folder so location is parent folder and dbname
      %is acutal database folder name.
      %Derby may require other information but it is passed to the
      %connection object in a java properties structure.
      outstr = ['jdbc:derby:' fullfile(instruct.location,instruct.dbname)];
    case 'oracle'
      %Try making a Oracle jdbc connection string.
      %Get port.
      port = '1521';
      if isfield(instruct,'arg')
        %Connection needs port argument. Will use 1521 as default.
        for i = 1:length(instruct.arg)
          if strcmp(lower(instruct.arg(i).name),'port')
            port = num2str(instruct.arg(i).value);
          end
        end
      end
      %jdbc:oracle:<drivertype>:<user>/<password>@<database>
      %jdbc:oracle:thin:scott/tiger@myhost:1521:orcl
      outstr = ['jdbc:oracle:thin:' instruct.user '/' instruct.pw '@' insturct.server ':' port ':' instruct.dbname];
  end
end

%----------------------------------------------
function outstruct = makestruct(instr)
%Make a template structure for given db type.

%NOTE: This may need to change if Unix platforms are supported.
if ispc
  outstruct.provider = 'MSDASQL';
end

switch instr
  case 'access'
    outstruct.driver   = '{Microsoft Access Driver (*.mdb)}';
    outstruct.location = ''; %This is parent folder of the .mdb file used to construct the 'DBQ' input for Access connection.
    outstruct.dbname   = ''; %This is the .mdb used with .location for 'DBQ'.
  case 'dsn'
    outstruct.dsn      = '';  
  case 'mssql'
    outstruct.driver   = '{SQL Server}';
    outstruct.server   = '';
    outstruct.dbname   = '';
  case 'mysql'
    outstruct.driver   = 'MySQL ODBC 3.51 Driver';
    outstruct.server   = '';
    outstruct.dbname   = '';
  case 'jmysql'
    outstruct.driver   = 'com.mysql.jdbc.Driver';
    outstruct.server   = '';
    outstruct.dbname   = '';
    if isfield(outstruct,'provider')
      outstruct = rmfield(outstruct,'provider');
    end
  case 'derby'
    %Derby database is just folder so location is parent folder and dbname
    %is acutal database folder name.
    outstruct.driver   = 'org.apache.derby.jdbc.EmbeddedDriver';
    outstruct.location = '';
    outstruct.dbname   = '';
  case 'all'
    outstruct.driver   = '';
    outstruct.server   = '';
    outstruct.dbname   = '';
    outstruct.user     = '';
    outstruct.pw       = '';
    outstruct.location = '';
    outstruct.dsn      = '';
                
end

%Standard for all connections. If empty then not used.
outstruct.user = '';
outstruct.pw   = '';
