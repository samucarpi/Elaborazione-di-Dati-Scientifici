function mynode = uitreenode_o(val,desc,iconloc,isleaf)
%EVRITREE/UITREENODE_O Overload for uitreenode.
%UITREENODE('v0', Value, Description, Icon, Leaf)

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if checkmlversion('>=','7.6')
  %Have to use the 'v0' switch in 2008b plus.
  mynode = uitreenode('v0',val, desc, iconloc, isleaf);
else
  mynode = uitreenode(val, desc, iconloc, isleaf);
end
