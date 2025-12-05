function val = addproject(obj,newproject)
%EVRICACHEDB/ADDPROJECT Subscript assignment reference for evridb.
%  The 'val' returned should be database ID number for 'newproject'.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

val = [];
dbo = obj.dbobject;

val = checkproject(obj,newproject);

if isempty(val)
  %Must use prepared statement here so inputs get sanitized by java.
  sqlstr = ['INSERT INTO evri_cache_db.project (name, folder) VALUES (?,?)'];
  val = jpreparedstatement(dbo,sqlstr,{newproject fullfile(modelcache('cachefolder'),newproject)},{'String','String'});
  val = val{:};
  
  %sqlstr = ['INSERT INTO evri_cache_db.project (name, folder) VALUES (''' newproject ''', ''' fullfile(modelcache('cachefolder'),newproject) ''')'];
  %val = dbo.runquery(sqlstr);%Get ID back.
end
