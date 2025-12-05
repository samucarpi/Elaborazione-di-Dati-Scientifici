function [ output_args ] = parsecache(cobj,list,pfolder)
%EVRICACHEDB/PARSECACHE Parse existing cache.
% Parse a cache file.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

listlen = length(list);
wh = waitbar(0,['Parsing Cache Items for Project: ' pfolder]);

for i = 1:listlen
  item = list(i);
  item.project = pfolder;
  addcacheitem(cobj,item,pfolder);
  waitbar(i/listlen,wh);
end

delete(wh)
