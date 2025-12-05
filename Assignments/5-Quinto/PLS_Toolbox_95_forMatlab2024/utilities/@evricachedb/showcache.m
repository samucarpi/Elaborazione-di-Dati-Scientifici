function fig = showcache(obj)
%SHOWCACHE Open querytool with cache sql statement.
%
%

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

dbo = obj.dbobject;

fig = querytool(dbo);
sqtxt = getappdata(fig,'sqltext');
sqtxt.setText('SELECT * FROM evri_cache_db.cache');
