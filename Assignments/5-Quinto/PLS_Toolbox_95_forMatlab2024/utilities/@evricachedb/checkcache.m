function val = checkcache(obj,item,prjID)
%EVRICACHEDB/CHECKCACHE Check for existing cache item.
% Return 'val' is ID number.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Keep lists of frequent queries so we can do quick compares and keep things
%speedy.

persistent  cacheitems

val = [];
dbo = obj.dbobject;

if ischar(item) && strcmp(item,'refresh_cache_list')
  %May have deleted a project so need to clear persistent var.
  cacheitems = [];
  return
end

%TODO: Cross-check project ID here and rebuild if needed.
if isempty(cacheitems)||isempty(cacheitems{1})
  cacheitems = dbo.runquery(['SELECT cacheID,name FROM evri_cache_db.cache WHERE projectID=' num2str(prjID)]);
  if isempty(cacheitems{1})
    %No items in database yet.
    return
  end
end

cidx = ismember(cacheitems(:,2),item.name);
if ~any(cidx)
  %none matched, check if the local cacheitems list needs to be updated
  nitems = dbo.runquery(['SELECT COUNT(projectID),MAX(cacheID) FROM evri_cache_db.cache WHERE projectID=' num2str(prjID)]);
  maxpid = nitems{2};
  nitems = nitems{1};
  
  if maxpid~=cacheitems{end,1} & length(cacheitems)~=nitems  %length of database different from local?
    %out of date, Refresh the list.
    cacheitems = dbo.runquery(['SELECT cacheID,name FROM evri_cache_db.cache WHERE projectID=' num2str(prjID)]);
    if isempty(cacheitems)
      %No items in database yet.
      return
    end
    cidx = ismember(cacheitems(:,2),item.name);
    if ~any(cidx)
      %This item isn't in database.
      return
    end
  else
    %We're up to date, must be that this item isn't in database.
    return
  end
end

val = cacheitems{cidx,1};
