function [val,varargout] = subsref(varargin)
%EVRIDB/SUBSREF Retrieve evridb information.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = varargin{1};
index = varargin{2};
feyld = index(1).subs; %Field name.
val = [];
varargout = {[]};

if length(index)>1 && ~ismember(feyld,{'arguments' 'runquery' 'Execute'});
  %Try generic indexing.
  try
    val = obj.(feyld)(index(2).subs{:});
  catch
    error(['Index error, can''t index into field: ' feyld '.'])
  end
end

switch feyld
  case 'arguments'
    %This code does not handle multi value subscripts may need to add that
    %functionality in future if there's a demand. Arguments are not widely used
    %currently.
    switch length(index)
      case 1
        val = obj.arguments;
      case 2
        val = obj.arguments(index(2).subs{:});
      case 3
        val = obj.arguments(index(2).subs{:}).(index(3).subs);
      otherwise
        error('Unable to index into .arguments field.')
    end
  case {'runquery' 'Execute'}
    %Run a query.
    if nargout==1
      val = runquery(obj,index(2).subs{:});
    elseif nargout>1
      %Allow fetch of column names.
      [val,cols] = runquery(obj,index(2).subs{:});
      varargout{1} = cols;
    else
      runquery(obj,index(2).subs{:});
      clear val
    end
  case 'getconnection'
    %Create and return a connection object.
    val = getconnection(obj);
  case {'testconnection' 'test' 'isvalid'}
    [val, myerr] = testconnection(obj);
    if ~val
      if nargout>1
        varargout{1} = myerr;
      else
        %Display error.
        disp(myerr)
      end
    end
  case {'closeconnection' 'close'}
    val = closeconnection(obj);
  case 'closeconnection_force'
    val = closeconnection_force(obj);
  case 'shutdown_derby'
    %Try a shutdown. 
    try
      %No check for driver, if it's not there then probably not started.
      derby_driver = org.apache.derby.jdbc.EmbeddedDriver;
      %This will always end with a sql error if no other errors occur first.
      myProps = java.util.Properties;
      myProps.put('shutdown','true');
      derby_driver.connect('jdbc:derby:',myProps);
    end
  case 'shutdown_derby_mem'
    %In memory drops are different. There will be an error message but this
    %indicates success. 
    try
      derby_driver = org.apache.derby.jdbc.EmbeddedDriver;
      conn = getconnection(obj);
      myProps = java.util.Properties;
      myProps.put('drop','true');
      derby_driver.connect(['jdbc:derby:' char(conn.getDBName)],myProps);
      disp("Java error indicates success.")
    end
  case 'ms_get_last'
    %Try to get last id from auto-increment ID value.
    conn = getconnection(obj);
    rs = conn.Execute(['SELECT LAST_INSERT_ID(' ');']);  %NOTE: split () to hide from release tests
    val = rs.GetRows;
    %Should be a number.
    val = str2num(val{:});
  case 'get_tables'
    val = '';
    if ismember(obj.type,obj.ms_types)
      %Get table names from ADO.
      cat = actxserver('ADOX.Catalog');
      cat.ActiveConnection = getconnection(obj);
      for i = 0:cat.Tables.count-1;
        if strcmp(cat.Tables.Item(i).Type,'TABLE')
          val = [val; {cat.Tables.Item(i).Name}];
        end
      end
      cat.delete
    else
      %Java search jdbc meta data for table names.
    end
  otherwise
    val = obj.(feyld);
end




