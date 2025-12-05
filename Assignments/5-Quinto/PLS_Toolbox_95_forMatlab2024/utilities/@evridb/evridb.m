classdef evridb < matlab.mixin.SetGet
%EVRIDB Create EVRI Database object.
%  EVRIDB Object creates and or connects to given database. Only certain
%  properties are used for a given type of database connection. 
%    
%  NOTE: Unless otherwise noted, all values are strings.
%  PROPERTIES
%            type : type of connection (e.g., 'access' 'mysql' mssql').
%                   Determines what driver is used. When set, default values
%                   will be added to .provider, .driver, and .driver_jar_file
%                   where appropriate.
%  QUERY PROPERTIES:
%      sql_string : Stored SQL statement run if .execute is empty.
%     return_type : Specify how to return data, as DSO or Cell array.
% use_column_names : If return type = DSO, try to use column names as
%                    variable names in the DSO or the first row if cell
%                    output.
%   query_watibar : ['on'|'off'|{'auto'}] Show a waitbar when parsing jdbc
%                   record sets, 'auto' is set to show if larger than 1000
%                   records.
%     null_as_nan : [{1} | 0] Interpret null values in a numeric column as
%                   NaN. Set to 0 to help speed up query parsing.
%  decode_columns : [1 | {0}] Decode columns that have java data types that
%                   need to be converted to strings (like timestamp and date).
% 
%  CONNECTION PROPERTIES:
%        location : Folder containing database file (on local file system).
%          dbname : Database [file/folder] name.
%          create : Depending on type of database, create database is not
%                   already.
% keep_persistent : Do not close connection object after creation or query,
%                   stored (in appdata 0). When calling multiple times this can
%                   help reduce time to return results.
%          driver : driver to be used for connection (these must be currently
%                   installed on the machine, use the ODBC Manager from
%                   Administrative Tools to view currently available drivers on
%                   a Windows machine. JDBC must have driver location in
%                   .driver_jar_file.
% driver_jar_file : JDBC driver jar file location. This is added to the
%                   dynamic class path in Matlab.
%        provider : only used by ADODB object so this will always be 'MSDASQL'.
% use_authentication : Use user authentication when making connection, must
%                      provide .username and .pw.
%        username : user to connect as.
%              pw : password for user.
%  use_encryption : Whether or not to use database encryption (derby).
% encryption_hash : Hash key for encryption.
%          server : IP address for database (default location is 'localhost').
%             dsn : Data Source Name (set up on local computer using ODBC Manager from
%                   Administrative Tools). If the database connection remains
%                   static, this can be a simple way to manage the connection.
%                   See the "ODBC" topic in Windows help for more information
%                   on DSN.
%            port : Connection port number.
%  arguments.name : sub structure of additional arguments. This value must be a
%                   sting of exactly what is required in the database 
%                   connection string.
% arguments.value : sub structure of additional arguments. This value must be a
%                   sting of exactly what is required in the database 
%                   connection string.
%
%I/O: obj = evridb()

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%TODO: Create loadobj method if/when we change data types in fields. DONE
%TODO: Do SVN delete of subsasgn.m, not needed with prop validation and
%      mixing.SetGet  
%TODO: Have keep_persistent use uniqueid to locate connections

  properties
    %Type
    type (1,:) char {mustBeMember(type,{'generic' 'access' 'mssql' 'mysql' 'oracle' 'jmysql' 'derby' 'derby_mem' 'dsn'})} = 'generic'
    %Query info.
    sql_string (1,:) char = ''
    use_column_names {mustBeMember(use_column_names,{'yes','no'})} = 'no'
    return_type {mustBeMember(return_type,{'cell','dso'})} = 'cell';
    query_waitbar {mustBeMember(query_waitbar,{'yes','no','auto'})} = 'auto'
    null_as_nan (1,1) {mustBeNumericOrLogical(null_as_nan)} = 1
    decode_columns {mustBeNumericOrLogical(decode_columns)} = 0;
    %Connection info.
    location (1,:) char = ''
    dbname (1,:) char = ''
    create {mustBeMember(create,{'yes','no'})} = 'no'
    keep_persistent {mustBeMember(keep_persistent,{'yes','no'})} = 'no' %name change from .persistent to .keep_persisten in V2
    driver (1,:) char = ''
    driver_jar_file (1,:) char = ''
    provider (1,:) char = ''
    use_authentication {mustBeMember(use_authentication,{'yes','no'})} = 'no'
    username (1,:) char = ''
    pw (1,:) char = ''
    use_encryption {mustBeMember(use_encryption,{'yes','no'})} = 'no'
    encryption_hash (1,:) char = ''
    server (1,:) char = ''
    dsn (1,:) char = ''
    port (1,:) char = ''
    arguments (:,1) struct = struct('name',{},'value',{});
    use_custom_connection {mustBeMember(use_custom_connection,{'yes','no'})} = 'no'
    custom_connection_string (1,:) char = ''
    definitions = evridb.optiondefs
  end

  properties(GetAccess='public', SetAccess='private')
    evridb_version (1,1) double {mustBePositive} = 2.0 %Not shown in disp
    known_types (1,:) cell = {'generic' 'access' 'mssql' 'mysql' 'oracle' 'jmysql' 'derby' 'derby_mem' 'dsn'}
    ms_types (1,:) cell = {'generic' 'access' 'mssql' 'mysql' 'dsn'}

    date (1,6) double %Date of creation
    uniqueid (1,:) char = ''
  end

  methods
    function obj = evridb(varargin)
      %Main constructor.

      if isstruct(varargin{1})
        %Probably loading old object from loadobj().
        obj = makeFromStruct(obj,varargin{1})
        return
      end

      if (nargin > 0)
        % Use set() on name value pairs. 
        try
          set(obj, varargin{:});
        catch exception
          delete(obj);
          throw(exception);
        end
      end

      obj.uniqueid = char(java.util.UUID.randomUUID());
      obj.date = datevec(datetime);

    end

  end

  methods % get/set

    function set.type(obj,val)
      obj = setdriverdefault(obj,val);
      obj.type = val;
    end

  end

  methods (Static)
    function out = optiondefs()

      defs = {

      %name             tab              datatype        valid                   userlevel       description
      'type'            'Database Type'  'select'        {'generic' 'access' 'mssql' 'mysql' 'oracle' 'jmysql' 'derby'}  'novice'        'Determines driver and some default values.';
      'sql_string'      'SQL String'     'char'          ''                      'novice'        'Default SQL statement.';
      'use_column_names' 'Get Column Names' 'char'       {'on' 'off'}            'novice'        'Try to parse column names from SQL statement.';
      'return_type'     'Return Type'    'char'          {'cell' 'dso'}          'novice'        'Return a cell or DataSet Object.';
      'query_waitbar'   'Query Waitbar'  'select'        {'on' 'off' 'auto'}     'novice'        'Show a waitbar when parsing jdbc record sets, ''auto'' is set to show if larger than 100 records.';
      'null_as_nan'     'Nulls to NaN'   'select'        {1 0}                   'novice'        'Interpret null values in a numeric column as NaN. Set to 0 to help speed up query parsing.';
      'location'        'Location'       'char'          ''                      'novice'        'Directory location for local connections.';
      'dbname'          'Database Name'  'char'          ''                      'novice'        'Database name.';
      'create'          'Create Database' 'char'         ''                      'novice'        'Create database if does not exist.';
      'persistent'      'Persistent'     'char'          ''                      'novice'        'Keep connection object persistent in memory.';
      'driver'          'Driver'         'char'          ''                      'novice'        'Driver type.';
      'driver_jar_file' 'Driver File'    'char'          ''                      'novice'        'Driver jar file.';
      'provider'        'Provider'       'char'          ''                      'novice'        'Data Provider (Microsoft).';
      'use_authentication' 'Use Authentication' 'char'   {'on' 'off'}            'novice'        'User connection authenticaiton.';
      'username'        'User Name'      'char'          ''                      'novice'        'User Name';
      'pw'              'Password'       'char'          ''                      'novice'        'Password';
      'use_encryption'  'Use Encryption' 'char'          {'on' 'off'}            'novice'        'Use Encryption.';
      'encryption_hash' 'Encryption Hash' 'char'         ''                      'novice'        'Encryption Hash';
      'server'          'Server Address' 'char'          ''                      'novice'        'Server Address (IP or URL).';
      'dsn'             'DSN Name'       'char'          ''                      'novice'        'Data Source Name';
      'port'            'Port'           'char'          ''                      'novice'        'Port';
      'arguments'       'Arguments'      'struct'        ''                      'novice'        'Additional Arguments';
      'use_custom_connection' 'Use Custom Connection' 'char' {'on' 'off'}            'novice'        'Use Custom Connection';
      'custom_connection_string' 'Custom Connection String' 'char' ''            'novice'        'Custom Connection String';
      };

      out = makesubops(defs);
    end
  end
end

function obj = makeFromStruct(obj,orig)
  %Old objects will get loaded as structs so run through fields and assign
  %values into new object. 
  myfields = fieldnames(orig)';
  for fields_inds = myfields
    obj.(fields_inds{:}) = orig.(fields_inds{:});
  end

end
