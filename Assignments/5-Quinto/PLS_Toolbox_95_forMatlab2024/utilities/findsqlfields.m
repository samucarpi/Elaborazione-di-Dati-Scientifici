function out = findsqlfields(sqlstr,options)
%FINDSQLFIELDS Find field names from SQL string for use as "variable" names in a dataset.

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<2;
  options = [];
  options.usetablename = 1;
end

str = lower(sqlstr);
str = str(strfind(str,'select')+6:strfind(str,'from')-1);
str = textscan(str,'%s','delimiter',',');
str = str{1};
str = strtrim(str);

if strcmp(str,'*')
  warning('EVRI:FindsqlfieldsNoFields','FINDSQLFIELDS can''t extract field names from a SQL ''SELECT *'' statement.');
  out = '';
  return
end

if options.usetablename
  %Remove table names from strings.
  for i = 1:length(str)
    str{i} = str{i}(strfind(str{i},'.')+1:end);
  end
end

out = str;
  
  
