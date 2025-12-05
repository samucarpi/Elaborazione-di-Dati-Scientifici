function success = combineprojects(obj,fromprj,toprj)
%EVRICACHEDB/COMBINEPROJECTS Combine two projects. 
% Change all 'fromprj' cache items to 'toprj' items.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

dbo = obj.dbobject;

success = false;

from_id = checkproject(obj,fromprj);
to_id   = checkproject(obj,toprj);

if ~isempty(from_id)&&~isempty(to_id)
  sqlstr = ['UPDATE evri_cache_db.cache SET projectID= ' num2str(to_id)  ' WHERE projectID= ' num2str(from_id)];
  dbo.runquery(sqlstr);
  success = true;
end

checkproject(obj,'refresh_project_list');
