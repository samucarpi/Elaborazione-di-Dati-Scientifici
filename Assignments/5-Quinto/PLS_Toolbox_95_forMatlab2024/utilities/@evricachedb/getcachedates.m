function out = getcachedates(obj,pid,flag,mydatenum)
%EVRICACHEDB/GETCACHEDATES Get list of item cache dates (per day) stored in db.
% Input 'flag' (0/1) will add additional cache item information to output.
% Input 'mydatenum' specifies date to search for and cut's query time down.
%
% NOTE: Uses cache date not mod date so quicker.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

dbo = obj.dbobject;
out = [];

if nargin<2
  pid = checkproject(obj);%Get current projectID.
end
if nargin<3
  flag = 0;
end
if nargin<4
  mydatenum = '';
end

%Main query.
qry = ['SELECT C.cacheID, C.cacheDate FROM evri_cache_db.cache C '...
  'WHERE C.projectID = ' num2str(pid)];

if ~isempty(mydatenum)
  usedate = [' AND C.cacheDate >= ' num2str(mydatenum) ' '...
  'AND C.cacheDate < ' num2str(mydatenum+1)];
else
  usedate = '';
end

qry = [qry usedate];

% %Add date.
% if ~isempty(mydatenum)
%   qry = [qry ' AND C.cacheDate=' num2str(mydatenum)];
% end

if flag
  %Get other cache data for given project.
  qry2 = ['SELECT C.cacheID, C.name, C.type, C.description FROM evri_cache_db.cache C '...
    'WHERE C.projectID = ' num2str(pid)];
  qry2 = [qry2 usedate];
  cdata = dbo.runquery(qry2);
end

mydata = dbo.runquery(qry);
if isempty(mydata{1})
  return
end

mydata = [[mydata{:,1}]; [mydata{:,2}]]';
sids = unique(mydata(:,1));
out = [];
for i = 1:length(sids)
  this_data = mydata(sids(i)==mydata(:,1),2)';
  if isempty(this_data)
    continue;
  end
  if flag
    out = [out;{datenum(this_data)} cdata(ismember([cdata{:,1}],sids(i)),:)];
  else
    out = [out; {datenum(this_data)} {sids(i)}];
  end
end
