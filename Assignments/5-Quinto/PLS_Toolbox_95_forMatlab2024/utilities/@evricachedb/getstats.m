function mystats = getstats(obj)
%EVRICACHEDB/GETSTATS Get basic information and stats on db for debugging.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mynodes = [];
dbo = obj.dbobject;

mystats = '';
mystats{end+1,1} = ['Location: ' dbo.location];
canconnect = dbo.test;
if ~canconnect
  mystats{end+1,1} = ['Connect: no'];
  return
end
mystats{end+1,1} = ['Connect: yes'];

qry = 'SELECT COUNT(projectid) FROM evri_cache_db.project';
tic;qout = dbo.runquery(qry);t2=toc;
mystats{end+1,1} = ['Project Count: ' num2str(qout{1})];

qry = 'SELECT COUNT(cacheid) FROM evri_cache_db.cache';
tic;qout = dbo.runquery(qry);t2=toc;
mystats{end+1,1} = ['Cache Item Count: ' num2str(qout{1}) '  (' num2str(t2) ' sec)' ];

qry = 'SELECT COUNT(sourceDataID) FROM evri_cache_db.sourceData';
tic;qout = dbo.runquery(qry);t2=toc;
mystats{end+1,1} = ['Source Data Count: ' num2str(qout{1}) '  (' num2str(t2) ' sec)' ];

qry = 'SELECT MAX(cachedate) FROM evri_cache_db.cache';
tic;qout = dbo.runquery(qry);t2=toc;
mystats{end+1,1} = ['Max Date: ' datestr(qout{1}) '  (' num2str(t2) ' sec)' ];

%Try one top level query "method" just to be sure they're running as
%expected. These methods are used by modelstruct. Probably don't need to
%test them all. Note that even if these run well the subqueries used to
%drill down into the cache could still show slow downs.
tic;mynodes = getlineage(obj);t2=toc;
mysize = whos('mynodes');
mysize = mysize.bytes/1000;
%mystats{end+1,1} = ['Get Lineage: ' num2str(size(mynodes,2)) '/' num2str(mysize)      'KB  (' num2str(t2) ' sec)' ];
mystats{end+1,1} = ['Get Lineage: ' num2str(size(mynodes,2)) '  (' num2str(t2) ' sec)' ];

% tic;mynodes = getdates(obj);t2=toc;
% mysize = whos('mynodes');
% mysize = mysize.bytes/1000;
% %mystats{end+1,1} = ['Get Dates: ' num2str(size(mynodes,2)) '/' num2str(mysize)      'KB  (' num2str(t2) ' sec)' ];
% mystats{end+1,1} = ['Get Dates: ' num2str(size(mynodes,2)) '  (' num2str(t2) ' sec)' ];

% tic;mynodes = gettypes(obj);t2=toc;
% mysize = whos('mynodes');
% mysize = mysize.bytes/1000;
% %mystats{end+1,1} = ['Get Types: ' num2str(size(mynodes,2)) '/' num2str(mysize)      'KB  (' num2str(t2) ' sec)' ];
% mystats{end+1,1} = ['Get Types: ' num2str(size(mynodes,2)) '  (' num2str(t2) ' sec)' ];
