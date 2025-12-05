function display(obj)
%EVRIDB/DISPLAY Display contents of object.
% Displays evridb database connection and query settings for given database type.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

conn_fields = {'location' 'dbname' 'create' 'driver' 'provider' ...
'use_authentication' 'username' 'pw' 'use_encryption' 'encryption_hash'...
'server' 'dsn'};

[rset,oset,uset]=getdbtypesettings(obj);
disp('EVRI Database Connection Object');
disp(['-----------------------------------'])
disp(sprintf('Type     : %s',obj.type));
disp(['-----------------------------------'])
if strcmp(obj.type,'generic') | isempty(obj.type)
  disp(['Connectoin Settings:'])
else
  disp(['Connectoin Settings (r = required, o = optional):'])
end

pad = 24;

for i = 1:length(conn_fields)
  if ~strcmp(obj.type,'generic') & ~isempty(obj.type)
    switch conn_fields{i}
      case rset
        setstr = 'r';
      case oset
        setstr = 'o';
      otherwise
        %Don't show unused connection settings.
        continue;
    end
  else
    setstr = '';
  end
  
  switch class(obj.(conn_fields{i}))
    case 'logical'
      %not used
    case 'char'
      disp(['  ' setstr ' ' conn_fields{i} repmat(' ',1,pad-length(conn_fields{i})) ': ' obj.(conn_fields{i})])
    otherwise
      %Assume numeric.
      disp(['  ' setstr ' ' conn_fields{i} repmat(' ',1,pad-length(conn_fields{i})) ': ' num2str(obj.(conn_fields{i}))])
  end
end

if length(obj.arguments)>1
  %Arguments sub list.
  disp(['-----------------------------------'])
  disp('Additional Connection Arguments:')
  for i = 1:length(obj.arguments)
    disp(['  name  : ' obj.arguments(i).name])
    disp(['  value : ' obj.arguments(i).value])
  end
end

%Query and return information.
disp(['-----------------------------------'])
disp(['Query Settings:'])

disp(['  keep_persistent' repmat(' ',1,pad-length('keep_persistent')) ': ' obj.keep_persistent])
disp(['  return_type' repmat(' ',1,pad-length('return_type')) ': ' obj.return_type])
disp(['  use_column_names' repmat(' ',1,pad-length('use_column_names')) ': ' obj.use_column_names])
disp(['  sql_string' repmat(' ',1,pad-length('sql_string')) ': ' obj.sql_string])
disp(['  query_waitbar' repmat(' ',1,pad-length('query_watibar')) ': ' obj.query_waitbar])
disp(['  null_as_nan' repmat(' ',1,pad-length('null_as_nan')) ': ' num2str(obj.null_as_nan)])
disp(['  decode_columns' repmat(' ',1,pad-length('decode_columns')) ': ' num2str(obj.decode_columns)])
