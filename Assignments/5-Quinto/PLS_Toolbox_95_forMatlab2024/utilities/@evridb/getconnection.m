function conn = getconnection(obj)
%EVRIDB/GETCONNECTION Connect to database and return native connection object.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

conn = [];
connstr = getconnectionstring(obj);

if strcmp(obj.keep_persistent,'yes')
  %Get saved connection.
  conn = getpersistentconnection(obj,connstr);
  if ~isempty(conn)
    if strcmp(fullfile(obj.location,obj.dbname),conn.getDBName)
      %User has switched databases.
      return
    else
      conn = '';
    end
  end
end

if isempty(conn)
  %Establish new connection.
  conn = getconn(connstr,obj);
end

if strcmp(obj.keep_persistent,'yes')
  setpersistentconnection(obj,conn,connstr);
end

%----------------------------------------------
function conn = getconn(connstr,obj)
%Create connection object.

conn = [];
switch obj.type
  case obj.ms_types
    %ADO connection object.
    conn = actxserver('ADODB.Connection');
    %Open connection.
    conn.Open(connstr);
  case 'derby_mem'
    checkderby
    connection_props = java.util.Properties;
    connection_props.put('create','true');
    
    dblocation = fullfile(obj.location,obj.dbname);
    derby_driver = javaObject(obj.driver);
    conn = derby_driver.connect(connstr,connection_props);
    
  case 'derby'
    checkderby
    
    %Must set log file location or log file gets created in pwd every time
    %the object is created.

    p = java.lang.System.getProperties;
    try
      %Don't want this to be a fatal error, if it doesn't get set you just
      %end up with a derby.log file in your pwd.
      p.setProperty('derby.stream.error.file', fullfile(evridir,'derby.log'));
    end
    
    %Set local to English to avoid invalid territory error. Comment out for
    %now, only had to use this once for an eastern european customer. 
    %enLocale = java.util.Locale('en_US');
    %java.util.Locale.setDefault(enLocale);
    
    %Get base object, calling this way rather than using Class loader works
    %with dynamic class path. Class loader only works with static path for some
    %reason.
    %FIXME: May have to use static path for older versions of Matlab.
    derby_driver = javaObject(obj.driver);
    dblocation = fullfile(obj.location,obj.dbname);%Should be directory.
    
    %Set up connection properties, these properties are only used in the
    %connection object and do not set any properties on the database.
    connection_props = java.util.Properties;
    
    if strcmp(obj.use_encryption ,'yes')
      %This "database" property can be used when connecting via the URL
      %object (unlike most other properties).
      connection_props.put('dataEncryption','true');
      connection_props.put('bootPassword','evri914*');
    end
    
    %Test to see if this is ok to pass on creation before properties set.
    if strcmp(obj.use_authentication ,'yes')
      connection_props.put('user',obj.user_name);
      connection_props.put('password',obj.user_password);
    end
    
    %CREATE/CONNECT
    if exist(dblocation)==7
      conn = derby_driver.connect(connstr,connection_props);
    elseif strcmpi(obj.create,'yes')
      %Create a new DB.
      connection_props.put('create','true');
      conn = derby_driver.connect(connstr,connection_props);
      
      %Configure "database" properties.
      st = conn.createStatement;
 
      %Setting and Confirming requireAuthentication.
      if strcmp(obj.use_authentication,'yes')
        st.executeUpdate('CALL SYSCS_UTIL.SYSCS_SET_DATABASE_PROPERTY(''derby.connection.requireAuthentication'', ''true'')');
        st.executeUpdate('CALL SYSCS_UTIL.SYSCS_SET_DATABASE_PROPERTY(''derby.authentication.provider'', ''BUILTIN'')');
        st.executeUpdate(['CALL SYSCS_UTIL.SYSCS_SET_DATABASE_PROPERTY(''derby.user.' obj.username ''', ''' obj.pw ''')']);
      end
      
      %Don't allow use of java system props, this could override props set here.
      %This property ensures that a database's environment cannot be modified
      %by the environment in which it is booted.
      st.executeUpdate('CALL SYSCS_UTIL.SYSCS_SET_DATABASE_PROPERTY(''derby.database.propertiesOnly'',''true'')');
    else
      error(['Can''t locate Derby database at: ' dblocation ])
    end
    
  case 'h2'
    %Beta code for H2.
    h2_driver = javaObject(obj.driver);
    conn = h2_driver.connect(connstr,java.util.Properties);
  otherwise
    %NOTE: This may not work because of problems associated with
    %dynamically addinhg jar files after others have been instantiated.
    
    %This should work with jMySQL, Oracle, and other java connections.
%     dynamic_path = javaclasspath('-dynamic');
%     mytype = obj.type;
%     if strcmpi(obj.type,'jmysql')
%       mytype = 'mysql';
%     end
%     if isempty(strfind([dynamic_path{:}],mytype))
%       if ~isempty(obj.driver_jar_file)
%         %Add (jar) file to path.
%         javaaddpath(obj.driver_jar_file)
%       else
%         error(['Unable to locate driver for ' mytype ' type database. Driver .jar file not found on java class path. Add jar file to path with javaaddpath.m or by some other means.']);
%       end
%     end
    mydriver = javaObject(obj.driver);
    conn = mydriver.connect(connstr,java.util.Properties);
    
end

%---------------------------------------------------
function checkderby
%Check for derby.jar on classpath.

%Need to use -all for checking java class path. In newer versions of Matlab
%jars seem to end up on static path and checking dynamic path erroneously
%indicates derby is not available. 
%dynamic_path = javaclasspath('-dynamic');

mypath = javaclasspath('-all');

if isempty(strfind([mypath{:}],'derby'))
  error(['Unable to locate driver for derby type database. Try running evrijavasetup.']);
end
