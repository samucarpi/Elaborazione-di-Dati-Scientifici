function out = getSSQTable(obj,parent,varargin)
%GETSSQTABLE Returns current SSQTable contents
%I/O: .getSSQTable()

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin~=2; error('Incorrect number of inputs'); end

handles = guidata(parent.handle);
modl = analysis('getobjdata','model',handles);
mytbl = getappdata(handles.analysis,'ssqtable');
if isempty(modl) | isempty(mytbl) | isempty(mytbl.data)
  out = {};
  return; 
end

out = mytbl.data;
lbls = mytbl.column_labels;
fmt = mytbl.column_format;

if isempty(out) | all(cellfun('isempty',strtrim(out)))
  out = {}; 
  return;
end

%format numerics
for j=1:length(fmt);
  if ~isempty(fmt{j})
    isnum = cellfun(@(item) isnumeric(item),out(:,j));
    new = cellfun(@(item) sprintf(fmt{j},item),out(isnum,j),'uniformoutput',0);
    out(isnum,j) = new;
  end
end

%add column headers
if length(lbls)==size(out,2);
  out = [lbls;out];
end
