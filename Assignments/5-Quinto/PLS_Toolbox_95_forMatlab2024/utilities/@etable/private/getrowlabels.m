function [rhead, rowlbls] = getrowlabels(obj)
%ETABLE/GETROWLABELS Extract row labels from obj.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Change labels.
mydata = obj.data;

rlbls = {};
rhead = '';
if isdataset(mydata) && strcmp(obj.ds_use_row,'on')
  %Try and pull column labels out of dso.
  rlbls = str2cell(obj.data.label{1,1})';
  rhead = mydata.labelname{1};
end

%Get row names.
rowlbls = {};
if strcmp(obj.ds_use_row,'on')
  rowlbls = rlbls;
end

if isempty(rowlbls)
  rowlbls = obj.row_labels;
end

if isempty(rowlbls)
  rowlbls(1,1:size(mydata,1)) = deal({[]});
end

if isempty(rhead)
  rhead = obj.row_label_header;
end

if isempty(rhead)
  %Need at least a space to make an empty label.
  rhead = [];
end

rowlbls = rowlbls';
