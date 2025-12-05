function renameproject(obj,projectname,newname)
%EVRICACHEDB/RENAMEPROJECT Rename a project.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

dbo = obj.dbobject;

val = checkproject(obj,projectname);

if ~isempty(val)
  sqlstr = ['UPDATE evri_cache_db.project SET name= ''' newname  ''' WHERE projectID= ' num2str(val)];
  dbo.runquery(sqlstr);
  success = true;
end

checkproject(obj,'refresh_project_list');
checkcache(obj,'refresh_cache_list',val);
