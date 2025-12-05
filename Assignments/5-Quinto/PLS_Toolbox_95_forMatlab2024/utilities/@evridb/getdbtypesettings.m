function [required_settings, optional_settings, unused_settings] = getdbtypesettings(obj)
%GETDBTYPESETTINGS Get list of required, optional, and not used settings for given database type.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

required_settings = {};
optional_settings = {'username' 'pw' 'persistent'};
unused_settings = fieldnames(obj)';

switch obj.type
  case 'access'
    required_settings{end+1} = 'provider';
    required_settings{end+1} = 'driver';
    required_settings{end+1} = 'location';
    required_settings{end+1} = 'dbname';
  case 'dsn'
    required_settings{end+1} = 'provider';
    required_settings{end+1} = 'dsn';  
  case 'mssql'
    required_settings{end+1} = 'provider';
    required_settings{end+1} = 'driver';
    required_settings{end+1} = 'server';
    required_settings{end+1} = 'dbname';
  case 'mysql'
    %Use ODBC driver.
    required_settings{end+1} = 'provider';
    required_settings{end+1} = 'driver';
    required_settings{end+1} = 'server';
    required_settings{end+1} = 'dbname';
  case 'jmysql'
    %Use jdbc driver.
    required_settings{end+1} = 'driver';
    required_settings{end+1} = 'server';
    required_settings{end+1} = 'dbname';
  case {'derby' 'h2'}
    required_settings{end+1} = 'driver';
    required_settings{end+1} = 'location';
    required_settings{end+1} = 'dbname';
    optional_settings{end+1} = 'create';
    optional_settings{end+1} = 'use_encryption';
    optional_settings{end+1} = 'encryption_hash';
    optional_settings{end+1} = 'use_authentication';
  case 'oracle'
    required_settings{end+1} = 'driver';
    required_settings{end+1} = 'server';
    required_settings{end+1} = 'dbname';
    required_settings{end+1} = 'port';
end

%Update unused list.
unused_settings = unused_settings(~ismember(unused_settings,required_settings));
unused_settings = unused_settings(~ismember(unused_settings,optional_settings));
