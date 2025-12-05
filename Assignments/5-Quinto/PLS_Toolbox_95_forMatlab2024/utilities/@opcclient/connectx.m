function obj = connectx(obj, ipaddress, domain, username, password, serverprogid)
%OPCCLIENT/CONNECT Client connection function. Also adds default group.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

disp(sprintf('Connect using IP: %s, domain = %s, username = %s, password = %s, serverprogid = %s', ipaddress, domain, username, password, serverprogid));
%opc.connect('10.0.2.15', 'localhost', 'testuser', 'test', 'Matrikon.OPC.Simulation');

jclient = obj.jclient;
jclient.connect(ipaddress, domain, username, password, serverprogid);

obj.groupname = char(jclient.getDefaultGroupName);
group = jclient.getDefaultGroup;

