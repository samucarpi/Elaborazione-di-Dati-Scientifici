function val = checkproject(obj,newproject)
%EVRICACHEDB/CHECKPROJECT Check for existing project.
% Returns ID of project.
% If newproject is 'refresh_project_list' then requeries persistent var.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Use existing list to keep things speedy for existing projects since they
%probably won't change much.
persistent myprojects

val = [];
dbo = obj.dbobject;

%If no project name given then use current project.
if nargin<2
  newproject = modelcache('projectfolder');
end

if (isempty(myprojects) || isempty(myprojects{1})) || strcmp(newproject,'refresh_project_list')
  myprojects = dbo.runquery('SELECT * FROM evri_cache_db.project');
  if isempty(myprojects{1}) || strcmp(newproject,'refresh_project_list')
    %No projects in database yet.
    return
  end
end

pidx = ismember(myprojects(:,2),newproject);
if ~any(pidx)
  %Refresh the list.
  myprojects = dbo.runquery('SELECT * FROM evri_cache_db.project');
  if isempty(myprojects)
    %No projects in database.
    return
  else
    pidx = ismember(myprojects(:,2),newproject);
    if ~any(pidx)
      %This project isn't in database.
      return
    end
  end
end

val = myprojects{pidx,1};

