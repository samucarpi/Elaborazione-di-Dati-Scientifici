function outstr = getconnectionstring(obj)
%EVRIDB/GETCONNECTIONSTRING Create connection string from obj.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

outstr = '';

if strcmp(obj.use_custom_connection, 'yes') && ~isempty(obj.custom_connection)
  %Use custom connection string override.
  outstr = obj.custom_connection_string;
end

switch obj.type
  case obj.ms_types
    for i = fieldnames(obj)'
      switch i{:}
        case 'provider'
          if ~isempty(obj.provider)
            outstr = [outstr 'PROVIDER=' obj.provider ';'];
          end
        case 'driver'
          if ~isempty(obj.driver)
            outstr = [outstr 'DRIVER=' obj.driver ';'];
          end
        case 'dbname'
          if ~isempty(obj.dbname) & ~strcmp(obj.type,'access')
            outstr = [outstr 'DATABASE=' obj.dbname ';'];
          end
        case 'username'
          if ~isempty(obj.username)
            outstr = [outstr 'UID=' obj.username ';'];
          end
        case 'pw'
          if ~isempty(obj.pw)
            outstr = [outstr 'PWD=' obj.pw ';'];
          end
        case 'location'
          if ~isempty(obj.location) & ~isempty(obj.dbname) & strcmp(obj.type,'access')
            outstr = [outstr 'DBQ=' fullfile(obj.location,obj.dbname) ';'];
          end
        case 'server'
          if ~isempty(obj.server)
            outstr = [outstr 'SERVER=' obj.server ';'];
          end
        case 'dsn'
          if ~isempty(obj.dsn)
            outstr = [outstr 'DSN=' obj.dsn ';'];
          end
      end
    end
  case 'jmysql'
    %Try making a mysql jdbc connection string.
    outstr = ['jdbc:mysql://' obj.server '/' obj.dbname '?user=' obj.username '&password=' obj.pw];
  case 'derby'
    %Derby database is just folder so location is parent folder and dbname
    %is acutal database folder name.
    %Derby may require other information but it is passed to the
    %connection unused_settingsect in a java properties structure.
    outstr = ['jdbc:derby:' fullfile(obj.location,obj.dbname)];
  case 'derby_mem'
    %Derby database is in memory only.
    %Derby may require other information but it is passed to the
    %connection unused_settingsect in a java properties structure.
    outstr = ['jdbc:derby:memory:' obj.dbname];
  case 'h2'
    %H2 similar to derby, just a file.
    outstr = ['jdbc:h2:' fullfile(obj.location,obj.dbname)];
  case 'oracle'
    %Connection needs port argument. Use 1521 as default.
    if isempty(obj.port)
      obj.port = '1521';
    end
    
    %jdbc:oracle:<drivertype>:<user>/<password>@<database>
    %jdbc:oracle:thin:scott/tiger@myhost:1521:orcl
    outstr = ['jdbc:oracle:thin:' obj.username '/' obj.pw '@' obj.server ':' obj.port ':' obj.dbname];
  otherwise
    %Make half-ass attempt to create jdbc-like connstr.
    outstr = ['jdbc:' obj.type '://' obj.server ':' obj.port '/' obj.dbname];
    
end

%Add arguments.
if ~isempty(obj.arguments) & ~strcmp(obj.type,'derby')
  %Get delimiter.
  if strcmp(obj.type,'jmysql')
    dlm = '&';
  else
    dlm = ';';
  end
  if ~strcmp(outstr(end),dlm)
    outstr(end+1) = dlm;
  end
  for j = 1:length(obj.arguments)
    if ~isempty(obj.arguments(j).name)
      outstr = [outstr obj.arguments(j).name '=' obj.arguments(j).value dlm];
    end
  end
end
