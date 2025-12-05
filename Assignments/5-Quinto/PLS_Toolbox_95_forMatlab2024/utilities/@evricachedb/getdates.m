function mynodes = getdates(obj,pid)
%EVRICACHEDB/GETDATES Get list of item mod dates (by day) stored in db.
% Uses obj.date_source for either 'moddate' or 'cachedate' where
% cachedate will be the faster quiery but moddate uses modification date
% from the model/dataset.
% 

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mynodes = [];
dbo = obj.dbobject;

if nargin<2
  pid = checkproject(obj);%Get current projectID.
end

switch obj.date_source
  case 'moddate'
    %Get mod dates.
    mydates = getmoddates(obj,pid);
  case 'cachedate'
    mydates = getcachedates(obj,pid);
end

if isempty(mydates)
  %No data.
  return
end

%Get unique days and sort.
udates = unique(floor([mydates{:,1}]));
udates = sort(udates,obj.date_sort);

%Make node struct.
for i = 1:length(udates)
  thisdate = datestr(udates(i));
  mynodes(i).val = ['getdate_children|' thisdate];
  mynodes(i).nam = thisdate;
  mynodes(i).str = thisdate;
  mynodes(i).icn = '';
  mynodes(i).isl = false;
  mynodes(i).chd = '';%Can't use this in feval: ['getdate_children(''' thisdate ''',' num2str(pid) ',''' type ''')'];
end
