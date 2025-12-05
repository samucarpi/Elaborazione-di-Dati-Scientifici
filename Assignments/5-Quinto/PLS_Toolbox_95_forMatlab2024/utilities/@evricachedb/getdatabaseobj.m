function dbobj = getdatabaseobj(obj)
%EVRICACHEDB/GETDATABASEOBJ  Create default dbobject

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Using options here rather than 'modelcache('cachefolder')' avoids going
%through any cache object code.
opts = modelcache('options');

dbobj = evridb('type','derby');
dbobj.location = opts.cachefolder; %getcachefolder;%TODO: Find best way to save this.
dbobj.dbname = 'evri_cache_db';
dbobj.use_encryption = 'yes';
dbobj.encryption_hash = license;%TODO: Check this with compiled app.
dbobj.create = 'yes';
dbobj.keep_persistent = 'yes';
dbobj.null_as_nan = 0;%Speeds up parsing.
