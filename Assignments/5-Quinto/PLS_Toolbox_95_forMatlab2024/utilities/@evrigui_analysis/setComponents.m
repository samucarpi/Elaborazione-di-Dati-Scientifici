function out = setComponents(obj,parent,varargin)
%SETCOMPONENTS Chooses the number of components for the model.
%I/O: .setCompoents(n)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 3, nargin))
out = false;

handles = guidata(parent.handle);
if nargin<3 | isempty(varargin{1})
  analysis('autoselect_Callback',handles.analysis, [], handles)
  out = true;
  return
end
mytbl = getappdata(handles.analysis,'ssqtable');

jt = mytbl.java_table;
if varargin{1}<=jt.getRowCount
  %if table has this number of rows, use that approach (works for methods
  %with table)
  setselection(mytbl,'rows',varargin{1});
  analysis('ssqtable_Callback',handles.analysis, [], handles)
  out = true;
elseif ishandle(handles.pcsedit) & strcmpi(get(handles.pcsedit,'visible'),'on')
  %try appdata on pcsedit, if pcsedit is visible
  set(handles.pcsedit,'string',num2str(varargin{1}));
  setappdata(handles.pcsedit,'default',varargin{1});
  analysis('ssqtable_Callback',handles.analysis, [], handles)
  out = true;
else
  %neither seems valid, can't set it
  out = false;
end

