function [columnheaders] = getcolumnlabels(obj)
%ETABLE/GETROWLABELS Extract column labels from obj or DSO.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get data.
mydata = obj.data;

clbls = {};
if isdataset(mydata) && strcmp(obj.ds_use_col,'on')
  %Try and pull column labels out of dso.
  clbls = str2cell(obj.data.label{2,1})';
end

%Get column names.
columnheaders = {};
if strcmp(obj.ds_use_col,'on')
  columnheaders = clbls;
end

if isempty(columnheaders)
  columnheaders = obj.column_labels;
end

if isempty(columnheaders)
  columnheaders(1,1:size(mydata,2)) = deal({[]});
end

if strcmp(obj.add_row_labels,'on')
  %Insert column of labels.
  [rhead, rowlbls] = getrowlabels(obj);
  columnheaders = [{rhead} columnheaders];
end
