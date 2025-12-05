function obj = setdriverdefault(obj,newtype)
%EVRIDB/SETDRIVERDEFAULT Sets default driver and provider defaults for given db type.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<2
  newtype = obj.type;
end

switch newtype
  case 'access'
    obj.provider = 'MSDASQL';
    obj.driver   = '{Microsoft Access Driver (*.mdb, *.accdb)}';
  case 'dsn'
    obj.provider = 'MSDASQL';
  case 'mssql'
    obj.provider = 'MSDASQL';
    obj.driver   = '{SQL Server}';
  case 'mysql'
    obj.provider = 'MSDASQL';
    obj.driver   = 'MySQL ODBC 3.51 Driver';
  case 'jmysql'
    obj.provider = '';
    obj.driver   = 'com.mysql.jdbc.Driver';
    %MySQL driver naming includess version so use 'ls' to get name.
    obj.driver_jar_file = fullfile(fileparts(which('extensions_release.m')),'mysql','mysql.jar');
  case {'derby' 'derby_mem'}
    obj.provider = '';
    obj.driver   = 'org.apache.derby.jdbc.EmbeddedDriver';
    obj.driver_jar_file = fullfile(fileparts(which('extensions_release.m')),'derby','derby.jar');
  case 'h2'
    obj.provider = '';
    obj.driver   = 'org.h2.Driver';
    obj.driver_jar_file = fullfile(fileparts(which('extensions_release.m')),'h2','h2-1.2.143.jar');
  case 'oracle'
    obj.provider = '';
    obj.driver   = 'oracle.jdbc.driver.OracleDriver';
    obj.port  = '1521';
end
