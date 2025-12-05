function success = updatedescription(obj,itemname,newdescription)
%EVRICACHEDB/UPDATEDESCRIPTION Update cache item description.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

success = false;
dbo = obj.dbobject;

pid = checkproject(obj);%Get current projectID.
item.name = itemname;
val = checkcache(obj,item,pid);
if ~isempty(val)
%   sqlstr = ['UPDATE evri_cache_db.cache SET description= ''' newdescription  ''' WHERE projectID= ' num2str(pid) 'AND cacheID= ' num2str(val)];
%   dbo.runquery(sqlstr);
%   success = true;
  %Use prepared statement for santizing sql.
  sqlstr = ['UPDATE evri_cache_db.cache SET description= ? WHERE projectID= ? AND cacheID= ?'];
  val = jpreparedstatement(dbo,sqlstr,{newdescription pid val},{'String' 'Int' 'Int'});
  success = true;
  
end

